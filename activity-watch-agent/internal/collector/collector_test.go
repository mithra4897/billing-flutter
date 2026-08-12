package collector

import (
	"context"
	"encoding/base64"
	"encoding/binary"
	"testing"
	"time"
	"unicode/utf16"
)

type sequenceCommandRunner struct {
	outputs [][]byte
	args    [][]string
}

func (r *sequenceCommandRunner) Output(_ context.Context, _ string, args ...string) ([]byte, error) {
	r.args = append(r.args, args)
	output := r.outputs[0]
	r.outputs = r.outputs[1:]
	return output, nil
}

func TestEncodePowerShellCommandPreservesUSBFilterQuotes(t *testing.T) {
	encoded := encodePowerShellCommand(windowsUSBScript)
	raw, err := base64.StdEncoding.DecodeString(encoded)
	if err != nil {
		t.Fatal(err)
	}
	if len(raw)%2 != 0 {
		t.Fatalf("encoded PowerShell byte count = %d, want an even UTF-16LE length", len(raw))
	}
	units := make([]uint16, len(raw)/2)
	for index := range units {
		units[index] = binary.LittleEndian.Uint16(raw[index*2:])
	}
	if decoded := string(utf16.Decode(units)); decoded != windowsUSBScript {
		t.Fatal("encoded PowerShell command did not round-trip exactly")
	}
}

func TestDetectInputReportsOnlyNewInputTimestamp(t *testing.T) {
	observer := &OSObserver{}
	at := time.Date(2026, 8, 7, 12, 0, 0, 0, time.UTC)
	if observer.detectInput(at, 2*time.Second) {
		t.Fatal("first sample must establish a baseline")
	}
	if observer.detectInput(at.Add(15*time.Second), 17*time.Second) {
		t.Fatal("unchanged last-input timestamp must not report input")
	}
	if !observer.detectInput(at.Add(30*time.Second), time.Second) {
		t.Fatal("new last-input timestamp must report input")
	}
}

func TestClassifyApplicationUsesExecutableNameOnly(t *testing.T) {
	tests := map[string]string{
		"Google Chrome.app": "browser",
		"Code.exe":          "development",
		"Slack":             "communication",
		"unknown-tool":      "unclassified",
	}
	for name, expected := range tests {
		if actual := ClassifyApplication(name); actual != expected {
			t.Fatalf("ClassifyApplication(%q) = %q, want %q", name, actual, expected)
		}
	}
}

func TestBrowserTitleOnlyAllowsRecognizedBrowser(t *testing.T) {
	if got := browserTitle("browser", "  ERP Dashboard  "); got != "ERP Dashboard" {
		t.Fatalf("browser title = %q", got)
	}
	if got := browserTitle("development", "Secret editor title"); got != "" {
		t.Fatalf("non-browser title must be excluded, got %q", got)
	}
}

func TestCanonicalItemsDeduplicatesAndSorts(t *testing.T) {
	items := canonicalItems([]string{"zeta", "Alpha", "alpha", ""}, false)
	if len(items) != 2 || items[0].Name != "alpha" || items[1].Name != "zeta" {
		t.Fatalf("items = %#v", items)
	}
}

func TestLaunchdItemsUsesLabelsNotProcessIdentifiers(t *testing.T) {
	items := launchdItems([]string{"PID Status Label", "123 0 com.example.worker", "- 0 com.example.timer"})
	if len(items) != 2 || items[0].Name != "com.example.timer" || items[1].Name != "com.example.worker" {
		t.Fatalf("items = %#v", items)
	}
}

func TestObserveUSBBaselinesThenReportsAddedMetadata(t *testing.T) {
	first := []byte(`{"total_ports":4,"used_ports":1,"devices":[{"id":"USB\\VID_1","name":"USB disk","manufacturer":"Example"}],"drives":[{"drive_letter":"E:","volume_label":"WORK","capacity_bytes":1000,"free_bytes":400}],"files":[{"drive_letter":"E:","relative_path":"existing.txt","size_bytes":10,"modified_at_utc":"2026-08-12T09:00:00Z"}],"files_truncated":false}`)
	second := []byte(`{"total_ports":4,"used_ports":1,"devices":[{"id":"USB\\VID_1","name":"USB disk","manufacturer":"Example"}],"drives":[{"drive_letter":"E:","volume_label":"WORK","capacity_bytes":1000,"free_bytes":350}],"files":[{"drive_letter":"E:","relative_path":"existing.txt","size_bytes":10,"modified_at_utc":"2026-08-12T09:00:00Z"},{"drive_letter":"E:","relative_path":"reports\\new.csv","size_bytes":50,"modified_at_utc":"2026-08-12T09:01:00Z"}],"files_truncated":false}`)
	disconnected := []byte(`{"total_ports":4,"used_ports":0,"devices":[],"drives":[],"files":[],"files_truncated":false}`)
	reconnected := first
	runner := &sequenceCommandRunner{outputs: [][]byte{first, second, disconnected, reconnected}}
	observer := &OSObserver{goos: "windows", runner: runner}
	at := time.Date(2026, 8, 12, 9, 0, 0, 0, time.UTC)
	baseline, err := observer.ObserveUSB(context.Background(), at)
	if err != nil || len(baseline.FileEvents) != 0 {
		t.Fatalf("baseline observation = %#v, error = %v", baseline, err)
	}
	observed, err := observer.ObserveUSB(context.Background(), at.Add(time.Minute))
	if err != nil {
		t.Fatal(err)
	}
	if observed.TotalPorts != 4 || observed.UsedPorts != 1 || len(observed.FileEvents) != 1 {
		t.Fatalf("USB observation = %#v", observed)
	}
	if observed.FileEvents[0].Operation != "added" || observed.FileEvents[0].Name != "new.csv" {
		t.Fatalf("USB file event = %#v", observed.FileEvents[0])
	}
	if len(observed.Devices) == 0 || observed.Devices[0].ObservedDurationSeconds != 60 {
		t.Fatalf("USB devices = %#v", observed.Devices)
	}
	unplugged, err := observer.ObserveUSB(context.Background(), at.Add(2*time.Minute))
	if err != nil || len(unplugged.FileEvents) != 0 {
		t.Fatalf("unplugged observation must not report all files deleted: %#v / %v", unplugged, err)
	}
	replugged, err := observer.ObserveUSB(context.Background(), at.Add(3*time.Minute))
	if err != nil || len(replugged.FileEvents) != 0 {
		t.Fatalf("reconnected drive must establish a fresh baseline: %#v / %v", replugged, err)
	}
	if len(runner.args) != 4 || len(runner.args[0]) < 2 || runner.args[0][len(runner.args[0])-2] != "-EncodedCommand" {
		t.Fatalf("USB collector PowerShell arguments = %#v", runner.args)
	}
}
