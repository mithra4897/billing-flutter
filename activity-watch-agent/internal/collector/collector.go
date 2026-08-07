package collector

import (
	"context"
	"errors"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"runtime"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"
)

type Snapshot struct {
	State           string
	IdleFor         time.Duration
	ApplicationName string
	ExecutableName  string
	Classification  string
	InputDetected   bool
	NetworkState    string
	ObservedAt      time.Time
}

type InventoryItem struct {
	Name  string `json:"name"`
	State string `json:"state,omitempty"`
}

type Observer interface {
	Sample(context.Context, time.Time, time.Duration) (Snapshot, error)
	ProcessInventory(context.Context) ([]InventoryItem, error)
	ServiceInventory(context.Context) ([]InventoryItem, error)
}

type commandRunner interface {
	Output(context.Context, string, ...string) ([]byte, error)
}

type execRunner struct{}

func (execRunner) Output(ctx context.Context, name string, arguments ...string) ([]byte, error) {
	commandContext, cancel := context.WithTimeout(ctx, 3*time.Second)
	defer cancel()
	command := exec.CommandContext(commandContext, name, arguments...)
	return command.Output()
}

type OSObserver struct {
	goos             string
	runner           commandRunner
	inputMu          sync.Mutex
	lastInputAt      time.Time
	hasInputBaseline bool
}

func NewOSObserver() *OSObserver {
	return &OSObserver{goos: runtime.GOOS, runner: execRunner{}}
}

func (o *OSObserver) Sample(ctx context.Context, at time.Time, idleThreshold time.Duration) (Snapshot, error) {
	idle, idleErr := o.idleDuration(ctx)
	locked, lockErr := o.locked(ctx)
	application, appErr := o.foregroundApplication(ctx)
	state := "unknown"
	switch {
	case locked:
		state = "locked"
	case idleErr == nil && idle >= idleThreshold:
		state = "idle"
	case idleErr == nil:
		state = "active"
	}
	executable := filepath.Base(strings.TrimSpace(application))
	result := Snapshot{
		State:           state,
		IdleFor:         idle,
		ApplicationName: executable,
		ExecutableName:  executable,
		Classification:  ClassifyApplication(executable),
		InputDetected:   state == "active" && o.detectInput(at.UTC(), idle),
		NetworkState:    networkState(),
		ObservedAt:      at.UTC(),
	}
	return result, errors.Join(idleErr, lockErr, appErr)
}

// detectInput reports only that input occurred between samples. It never
// observes or stores a key, click, button, or pointer coordinate.
func (o *OSObserver) detectInput(at time.Time, idleFor time.Duration) bool {
	o.inputMu.Lock()
	defer o.inputMu.Unlock()
	lastInputAt := at.Add(-idleFor)
	detected := o.hasInputBaseline && lastInputAt.After(o.lastInputAt.Add(time.Millisecond))
	o.lastInputAt = lastInputAt
	o.hasInputBaseline = true
	return detected
}

func networkState() string {
	interfaces, err := net.Interfaces()
	if err != nil {
		return "unknown"
	}
	for _, networkInterface := range interfaces {
		if networkInterface.Flags&net.FlagUp != 0 && networkInterface.Flags&net.FlagLoopback == 0 {
			return "online"
		}
	}
	return "offline"
}

func (o *OSObserver) ProcessInventory(ctx context.Context) ([]InventoryItem, error) {
	var output []byte
	var err error
	switch o.goos {
	case "windows":
		output, err = o.runner.Output(ctx, "powershell.exe", "-NoProfile", "-NonInteractive", "-Command", "Get-Process | Select-Object -ExpandProperty ProcessName")
	default:
		output, err = o.runner.Output(ctx, "ps", "-axo", "comm=")
	}
	if err != nil {
		return nil, err
	}
	return canonicalItems(strings.Split(string(output), "\n"), false), nil
}

func (o *OSObserver) ServiceInventory(ctx context.Context) ([]InventoryItem, error) {
	var output []byte
	var err error
	switch o.goos {
	case "windows":
		output, err = o.runner.Output(ctx, "powershell.exe", "-NoProfile", "-NonInteractive", "-Command", `Get-Service | ForEach-Object { "$($_.Name)|$($_.Status)" }`)
	case "darwin":
		output, err = o.runner.Output(ctx, "launchctl", "list")
	default:
		output, err = o.runner.Output(ctx, "systemctl", "list-units", "--type=service", "--all", "--no-legend", "--no-pager", "--plain")
	}
	if err != nil {
		return nil, err
	}
	if o.goos == "darwin" {
		return launchdItems(strings.Split(string(output), "\n")), nil
	}
	return canonicalItems(strings.Split(string(output), "\n"), true), nil
}

func (o *OSObserver) idleDuration(ctx context.Context) (time.Duration, error) {
	switch o.goos {
	case "darwin":
		output, err := o.runner.Output(ctx, "ioreg", "-c", "IOHIDSystem")
		if err != nil {
			return 0, err
		}
		match := regexp.MustCompile(`HIDIdleTime"\s*=\s*([0-9]+)`).FindSubmatch(output)
		if len(match) != 2 {
			return 0, errors.New("macOS idle duration unavailable")
		}
		nanoseconds, err := strconv.ParseInt(string(match[1]), 10, 64)
		return time.Duration(nanoseconds), err
	case "windows":
		script := `$s='using System;using System.Runtime.InteropServices;public class I{[StructLayout(LayoutKind.Sequential)]public struct L{public uint cbSize;public uint dwTime;}[DllImport("user32.dll")]public static extern bool GetLastInputInfo(ref L p);}';Add-Type $s;$i=New-Object I+L;$i.cbSize=[Runtime.InteropServices.Marshal]::SizeOf($i);[I]::GetLastInputInfo([ref]$i)|Out-Null;[Environment]::TickCount64-$i.dwTime`
		output, err := o.runner.Output(ctx, "powershell.exe", "-NoProfile", "-NonInteractive", "-Command", script)
		if err != nil {
			return 0, err
		}
		milliseconds, err := strconv.ParseInt(strings.TrimSpace(string(output)), 10, 64)
		return time.Duration(milliseconds) * time.Millisecond, err
	default:
		output, err := o.runner.Output(ctx, "xprintidle")
		if err != nil {
			return 0, err
		}
		milliseconds, err := strconv.ParseInt(strings.TrimSpace(string(output)), 10, 64)
		return time.Duration(milliseconds) * time.Millisecond, err
	}
}

func (o *OSObserver) foregroundApplication(ctx context.Context) (string, error) {
	switch o.goos {
	case "darwin":
		output, err := o.runner.Output(ctx, "osascript", "-e", `tell application "System Events" to get name of first application process whose frontmost is true`)
		return strings.TrimSpace(string(output)), err
	case "windows":
		script := `$s='using System;using System.Runtime.InteropServices;public class W{[DllImport("user32.dll")]public static extern IntPtr GetForegroundWindow();[DllImport("user32.dll")]public static extern uint GetWindowThreadProcessId(IntPtr h,out uint p);}';Add-Type $s;$p=0;[W]::GetWindowThreadProcessId([W]::GetForegroundWindow(),[ref]$p)|Out-Null;(Get-Process -Id $p).ProcessName`
		output, err := o.runner.Output(ctx, "powershell.exe", "-NoProfile", "-NonInteractive", "-Command", script)
		return strings.TrimSpace(string(output)), err
	default:
		window, err := o.runner.Output(ctx, "xdotool", "getactivewindow", "getwindowpid")
		if err != nil {
			return "", err
		}
		pid := strings.TrimSpace(string(window))
		output, err := o.runner.Output(ctx, "ps", "-p", pid, "-o", "comm=")
		return strings.TrimSpace(string(output)), err
	}
}

func (o *OSObserver) locked(ctx context.Context) (bool, error) {
	switch o.goos {
	case "darwin":
		// CGSession was removed from some recent macOS releases. IORegistry
		// exposes the same console lock state without relying on a private path.
		output, err := o.runner.Output(ctx, "ioreg", "-n", "Root", "-d1")
		if err != nil {
			return false, err
		}
		value := string(output)
		if strings.Contains(value, "IOConsoleLocked = Yes") || strings.Contains(value, "CGSSessionScreenIsLocked = 1") {
			return true, nil
		}
		if strings.Contains(value, "IOConsoleLocked = No") || strings.Contains(value, "CGSSessionScreenIsLocked = 0") {
			return false, nil
		}
		// Some macOS versions omit both fields. Continue with idle/foreground
		// detection instead of failing every sample; lock state remains unknown.
		return false, nil
	case "windows":
		script := `$session=(Get-Process -Id $PID).SessionId;$locked=Get-Process LogonUI -ErrorAction SilentlyContinue | Where-Object { $_.SessionId -eq $session };if($locked){'true'}else{'false'}`
		output, err := o.runner.Output(ctx, "powershell.exe", "-NoProfile", "-NonInteractive", "-Command", script)
		if err != nil {
			return false, err
		}
		return strings.EqualFold(strings.TrimSpace(string(output)), "true"), nil
	default:
		sessionID := strings.TrimSpace(os.Getenv("XDG_SESSION_ID"))
		if sessionID == "" {
			return false, errors.New("Linux desktop session is unavailable")
		}
		output, err := o.runner.Output(ctx, "loginctl", "show-session", sessionID, "-p", "LockedHint", "--value")
		if err != nil {
			return false, err
		}
		return strings.EqualFold(strings.TrimSpace(string(output)), "yes"), nil
	}
}

func ClassifyApplication(name string) string {
	value := strings.ToLower(filepath.Base(strings.TrimSpace(name)))
	value = strings.TrimSuffix(value, filepath.Ext(value))
	classifications := map[string]string{
		"chrome": "browser", "google chrome": "browser", "msedge": "browser", "firefox": "browser", "safari": "browser",
		"code": "development", "visual studio code": "development", "devenv": "development", "xcode": "development", "android studio": "development", "terminal": "development", "iterm2": "development",
		"slack": "communication", "teams": "communication", "microsoft teams": "communication", "zoom": "communication", "outlook": "communication", "mail": "communication",
		"finder": "system", "explorer": "system", "system settings": "system", "system preferences": "system",
	}
	if category, found := classifications[value]; found {
		return category
	}
	return "unclassified"
}

func launchdItems(lines []string) []InventoryItem {
	items := make([]string, 0, len(lines))
	for _, line := range lines {
		fields := strings.Fields(line)
		if len(fields) >= 3 && fields[2] != "Label" {
			items = append(items, fields[2])
		}
	}
	return canonicalItems(items, false)
}

func canonicalItems(lines []string, withState bool) []InventoryItem {
	byName := make(map[string]InventoryItem, len(lines))
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		fields := strings.Fields(trimmed)
		if len(fields) == 0 {
			continue
		}
		name := fields[0]
		state := ""
		if !withState {
			name = filepath.Base(trimmed)
		} else if strings.Contains(line, "|") {
			parts := strings.SplitN(line, "|", 2)
			name, state = strings.TrimSpace(parts[0]), strings.TrimSpace(parts[1])
		} else if withState && len(fields) > 2 {
			state = fields[2]
		}
		if name != "" {
			byName[strings.ToLower(name)] = InventoryItem{Name: name, State: state}
		}
	}
	keys := make([]string, 0, len(byName))
	for key := range byName {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	items := make([]InventoryItem, 0, len(keys))
	for _, key := range keys {
		items = append(items, byName[key])
	}
	return items
}
