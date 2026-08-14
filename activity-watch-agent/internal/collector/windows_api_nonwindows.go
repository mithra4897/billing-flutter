//go:build !windows

package collector

import (
	"errors"
	"time"
)

// These fallbacks keep non-Windows agent builds independent of the Windows
// native collector implementation. They are unreachable outside a Windows
// runtime switch and fail closed if invoked unexpectedly.
func windowsPointerPosition() (string, error) {
	return "", errors.New("Windows pointer position is unavailable")
}

func windowsProcessInventory() ([]InventoryItem, error) {
	return nil, errors.New("Windows process inventory is unavailable")
}

func windowsIdleDuration() (time.Duration, error) {
	return 0, errors.New("Windows idle duration is unavailable")
}

func windowsForegroundApplication() (string, string, error) {
	return "", "", errors.New("Windows foreground application is unavailable")
}

func windowsSessionLocked() (bool, error) {
	return false, errors.New("Windows lock state is unavailable")
}
