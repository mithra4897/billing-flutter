//go:build windows

package collector

import (
	"encoding/csv"
	"errors"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"
	"unsafe"

	"golang.org/x/sys/windows"
)

const (
	processQueryLimitedInformation = 0x1000
	desktopReadObjects             = 0x0001
	uoiName                        = 2
)

var (
	user32                     = windows.NewLazySystemDLL("user32.dll")
	kernel32                   = windows.NewLazySystemDLL("kernel32.dll")
	procGetTickCount           = kernel32.NewProc("GetTickCount")
	procGetCursorPos           = user32.NewProc("GetCursorPos")
	procGetLastInputInfo       = user32.NewProc("GetLastInputInfo")
	procGetForegroundWindow    = user32.NewProc("GetForegroundWindow")
	procGetWindowText          = user32.NewProc("GetWindowTextW")
	procGetWindowThreadProcess = user32.NewProc("GetWindowThreadProcessId")
	procOpenInputDesktop       = user32.NewProc("OpenInputDesktop")
	procCloseDesktop           = user32.NewProc("CloseDesktop")
	procGetUserObjectInfo      = user32.NewProc("GetUserObjectInformationW")
)

type point struct{ x, y int32 }

type lastInputInfo struct {
	cbSize uint32
	dwTime uint32
}

func windowsPointerPosition() (string, error) {
	var position point
	result, _, callErr := procGetCursorPos.Call(uintptr(unsafe.Pointer(&position)))
	if result == 0 {
		return "", callErr
	}
	// The caller compares this opaque value only to determine movement; it is
	// never persisted as a coordinate.
	return strconv.FormatInt(int64(position.x), 10) + "," + strconv.FormatInt(int64(position.y), 10), nil
}

func windowsProcessInventory() ([]InventoryItem, error) {
	command := exec.Command("tasklist.exe", "/FO", "CSV", "/NH")
	output, err := command.Output()
	if err != nil {
		return nil, err
	}
	rows, err := csv.NewReader(strings.NewReader(string(output))).ReadAll()
	if err != nil {
		return nil, err
	}
	items := make([]InventoryItem, 0, len(rows))
	for _, row := range rows {
		if len(row) == 0 || strings.TrimSpace(row[0]) == "" {
			continue
		}
		items = append(items, InventoryItem{Name: strings.TrimSpace(row[0])})
	}
	return canonicalItems(itemsToNames(items), false), nil
}

func windowsIdleDuration() (time.Duration, error) {
	info := lastInputInfo{cbSize: uint32(unsafe.Sizeof(lastInputInfo{}))}
	result, _, callErr := procGetLastInputInfo.Call(uintptr(unsafe.Pointer(&info)))
	if result == 0 {
		return 0, callErr
	}
	ticks, _, _ := procGetTickCount.Call()
	return time.Duration(uint32(ticks)-info.dwTime) * time.Millisecond, nil
}

func windowsForegroundApplication() (string, string, error) {
	handle, _, callErr := procGetForegroundWindow.Call()
	if handle == 0 {
		return "", "", callErr
	}
	var processID uint32
	procGetWindowThreadProcess.Call(handle, uintptr(unsafe.Pointer(&processID)))
	if processID == 0 {
		return "", "", errors.New("Windows foreground process is unavailable")
	}
	name, err := windowsProcessName(processID)
	if err != nil {
		return "", "", err
	}
	titleBuffer := make([]uint16, 512)
	procGetWindowText.Call(handle, uintptr(unsafe.Pointer(&titleBuffer[0])), uintptr(len(titleBuffer)))
	return name, windows.UTF16ToString(titleBuffer), nil
}

func windowsSessionLocked() (bool, error) {
	desktop, _, callErr := procOpenInputDesktop.Call(0, 0, desktopReadObjects)
	if desktop == 0 {
		return false, callErr
	}
	defer procCloseDesktop.Call(desktop)
	length := uint32(0)
	procGetUserObjectInfo.Call(desktop, uoiName, 0, 0, uintptr(unsafe.Pointer(&length)))
	if length == 0 {
		return false, errors.New("Windows input desktop name is unavailable")
	}
	name := make([]uint16, length/2)
	result, _, infoErr := procGetUserObjectInfo.Call(
		desktop,
		uoiName,
		uintptr(unsafe.Pointer(&name[0])),
		uintptr(length),
		uintptr(unsafe.Pointer(&length)),
	)
	if result == 0 {
		return false, infoErr
	}
	return !strings.EqualFold(windows.UTF16ToString(name), "Default"), nil
}

func windowsProcessName(processID uint32) (string, error) {
	handle, err := windows.OpenProcess(processQueryLimitedInformation, false, processID)
	if err != nil {
		return "", err
	}
	defer windows.CloseHandle(handle)
	buffer := make([]uint16, windows.MAX_PATH)
	length := uint32(len(buffer))
	if err := windows.QueryFullProcessImageName(handle, 0, &buffer[0], &length); err != nil {
		return "", err
	}
	return filepath.Base(windows.UTF16ToString(buffer[:length])), nil
}

func itemsToNames(items []InventoryItem) []string {
	names := make([]string, len(items))
	for index, item := range items {
		names[index] = item.Name
	}
	return names
}
