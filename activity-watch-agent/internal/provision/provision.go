package provision

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"

	"billing/activity-watch-agent/internal/config"
	"billing/activity-watch-agent/internal/store"
)

type Result struct {
	DatabasePath string
	KeyPath      string
}

// Create creates a new database/key pair without overwriting any configured
// target. It uses temp files plus atomic hard links so a concurrent creator
// cannot replace an existing database or secret file.
func Create(ctx context.Context, cfg config.Config) (Result, error) {
	return create(ctx, cfg, rand.Reader)
}

func create(ctx context.Context, cfg config.Config, random io.Reader) (Result, error) {
	if err := cfg.Validate(); err != nil {
		return Result{}, err
	}
	if err := rejectExisting(cfg.Database.Path, "database"); err != nil {
		return Result{}, err
	}
	if err := rejectExisting(cfg.Database.KeyFile, "database key"); err != nil {
		return Result{}, err
	}
	for _, path := range []string{cfg.Database.Path, cfg.Database.KeyFile, cfg.Control.LogoutRequestPath} {
		if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
			return Result{}, fmt.Errorf("create parent directory: %w", err)
		}
	}

	key := make([]byte, 32)
	if _, err := io.ReadFull(random, key); err != nil {
		return Result{}, fmt.Errorf("generate database key: %w", err)
	}
	defer clear(key)

	keyTemp, err := writeKeyTemp(cfg.Database.KeyFile, key)
	if err != nil {
		return Result{}, err
	}
	defer removeIfPresent(keyTemp)

	databaseTemp, err := createDatabaseTemp(ctx, cfg.Database.Path, key)
	if err != nil {
		return Result{}, err
	}
	defer removeIfPresent(databaseTemp)

	if err := linkNew(databaseTemp, cfg.Database.Path); err != nil {
		return Result{}, fmt.Errorf("publish database: %w", err)
	}
	databaseTemp = ""
	if err := linkNew(keyTemp, cfg.Database.KeyFile); err != nil {
		removeIfPresent(cfg.Database.Path)
		return Result{}, fmt.Errorf("publish database key: %w", err)
	}
	keyTemp = ""

	return Result{DatabasePath: cfg.Database.Path, KeyPath: cfg.Database.KeyFile}, nil
}

func rejectExisting(path, name string) error {
	_, err := os.Lstat(path)
	if err == nil {
		return fmt.Errorf("%s already exists: %s", name, path)
	}
	if !errors.Is(err, os.ErrNotExist) {
		return fmt.Errorf("inspect %s: %w", name, err)
	}
	return nil
}

func writeKeyTemp(target string, key []byte) (string, error) {
	file, err := os.CreateTemp(filepath.Dir(target), ".activity-watch-key-*")
	if err != nil {
		return "", fmt.Errorf("create temporary database key: %w", err)
	}
	path := file.Name()
	if err := file.Chmod(0o600); err != nil {
		file.Close()
		removeIfPresent(path)
		return "", fmt.Errorf("protect temporary database key: %w", err)
	}
	if _, err := file.WriteString(hex.EncodeToString(key)); err != nil {
		file.Close()
		removeIfPresent(path)
		return "", fmt.Errorf("write temporary database key: %w", err)
	}
	if err := file.Close(); err != nil {
		removeIfPresent(path)
		return "", fmt.Errorf("close temporary database key: %w", err)
	}
	return path, nil
}

func createDatabaseTemp(ctx context.Context, target string, key []byte) (string, error) {
	file, err := os.CreateTemp(filepath.Dir(target), ".activity-watch-db-*")
	if err != nil {
		return "", fmt.Errorf("create temporary database: %w", err)
	}
	path := file.Name()
	if err := file.Chmod(0o600); err != nil {
		file.Close()
		removeIfPresent(path)
		return "", fmt.Errorf("protect temporary database: %w", err)
	}
	if err := file.Close(); err != nil {
		removeIfPresent(path)
		return "", fmt.Errorf("close temporary database: %w", err)
	}
	if err := store.ProvisionSQLCipher(ctx, path, key); err != nil {
		removeIfPresent(path)
		return "", err
	}
	return path, nil
}

func linkNew(source, target string) error {
	if err := os.Link(source, target); err != nil {
		return err
	}
	if err := os.Remove(source); err != nil {
		_ = os.Remove(target)
		return err
	}
	return nil
}

func removeIfPresent(path string) {
	if path != "" {
		_ = os.Remove(path)
	}
}

func clear(value []byte) {
	for index := range value {
		value[index] = 0
	}
}
