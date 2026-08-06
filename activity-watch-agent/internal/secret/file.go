package secret

import (
	"encoding/base64"
	"encoding/hex"
	"errors"
	"fmt"
	"os"
	"runtime"
	"strings"
)

type FileProvider struct{}

func (FileProvider) DatabaseKey(path string) ([]byte, error) {
	value, err := readProtected(path)
	if err != nil {
		return nil, err
	}
	key, err := decodeKey(strings.TrimSpace(string(value)))
	clear(value)
	if err != nil {
		return nil, err
	}
	return key, nil
}

func (FileProvider) DeviceCredential(path string) (string, error) {
	value, err := readProtected(path)
	if err != nil {
		return "", err
	}
	defer clear(value)
	credential := strings.TrimSpace(string(value))
	if credential == "" {
		return "", errors.New("device credential is empty")
	}
	if strings.ContainsAny(credential, "\r\n") {
		return "", errors.New("device credential must be one line")
	}
	return credential, nil
}

func readProtected(path string) ([]byte, error) {
	info, err := os.Stat(path)
	if err != nil {
		return nil, fmt.Errorf("inspect secret file: %w", err)
	}
	if !info.Mode().IsRegular() {
		return nil, errors.New("secret path must be a regular file")
	}
	if runtime.GOOS != "windows" && info.Mode().Perm()&0o077 != 0 {
		return nil, errors.New("secret file permissions must deny group and other access")
	}
	value, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read secret file: %w", err)
	}
	return value, nil
}

func decodeKey(value string) ([]byte, error) {
	var (
		key []byte
		err error
	)
	if len(value) == 64 {
		key, err = hex.DecodeString(value)
	} else {
		key, err = base64.RawURLEncoding.DecodeString(strings.TrimRight(value, "="))
	}
	if err != nil || len(key) != 32 {
		clear(key)
		return nil, errors.New("database key must encode exactly 32 bytes")
	}
	return key, nil
}

func clear(value []byte) {
	for index := range value {
		value[index] = 0
	}
}
