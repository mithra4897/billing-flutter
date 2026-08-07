package collector

import (
	"testing"
	"time"
)

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
