package control

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
)

type LogoutMarker struct {
	path string
}

func NewLogoutMarker(path string) LogoutMarker {
	return LogoutMarker{path: path}
}

func (m LogoutMarker) Signal() error {
	if err := os.MkdirAll(filepath.Dir(m.path), 0o750); err != nil {
		return fmt.Errorf("create control directory: %w", err)
	}
	file, err := os.OpenFile(m.path, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0o600)
	if err != nil {
		return fmt.Errorf("create logout request: %w", err)
	}
	if _, err := file.WriteString("logout\n"); err != nil {
		file.Close()
		return fmt.Errorf("write logout request: %w", err)
	}
	if err := file.Sync(); err != nil {
		file.Close()
		return fmt.Errorf("sync logout request: %w", err)
	}
	return file.Close()
}

func (m LogoutMarker) Consume() (bool, error) {
	err := os.Remove(m.path)
	if err == nil {
		return true, nil
	}
	if errors.Is(err, os.ErrNotExist) {
		return false, nil
	}
	return false, fmt.Errorf("consume logout request: %w", err)
}
