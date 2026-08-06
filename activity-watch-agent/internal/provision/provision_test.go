package provision

import (
	"bytes"
	"context"
	"os"
	"path/filepath"
	"runtime"
	"testing"
	"time"

	"billing/activity-watch-agent/internal/config"
	"billing/activity-watch-agent/internal/secret"
	"billing/activity-watch-agent/internal/store"
)

func TestCreateBuildsProtectedDatabaseKeyPair(t *testing.T) {
	root := t.TempDir()
	cfg := provisionConfig(root)
	key := bytes.Repeat([]byte{7}, 32)
	result, err := create(context.Background(), cfg, bytes.NewReader(key))
	if err != nil {
		t.Fatalf("create() error = %v", err)
	}
	if result.DatabasePath != cfg.Database.Path || result.KeyPath != cfg.Database.KeyFile {
		t.Fatalf("unexpected result: %#v", result)
	}
	if _, err := os.Stat(cfg.Control.LogoutRequestPath); !os.IsNotExist(err) {
		t.Fatalf("logout marker should not exist before a logout signal: %v", err)
	}
	if _, err := os.Stat(filepath.Dir(cfg.Control.LogoutRequestPath)); err != nil {
		t.Fatalf("logout parent was not created: %v", err)
	}
	if runtime.GOOS != "windows" {
		info, err := os.Stat(cfg.Database.KeyFile)
		if err != nil {
			t.Fatal(err)
		}
		if info.Mode().Perm() != 0o600 {
			t.Fatalf("key permissions = %o, want 600", info.Mode().Perm())
		}
	}
	loadedKey, err := (secret.FileProvider{}).DatabaseKey(cfg.Database.KeyFile)
	if err != nil {
		t.Fatalf("DatabaseKey() error = %v", err)
	}
	if !bytes.Equal(loadedKey, key) {
		t.Fatal("provisioned key does not match generated key")
	}
	database, err := store.OpenSQLCipher(context.Background(), cfg.Database.Path, loadedKey)
	if err != nil {
		t.Fatalf("OpenSQLCipher() error = %v", err)
	}
	database.Close()
}

func TestCreateRefusesExistingDatabaseWithoutChangingIt(t *testing.T) {
	root := t.TempDir()
	cfg := provisionConfig(root)
	if err := os.MkdirAll(filepath.Dir(cfg.Database.Path), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(cfg.Database.Path, []byte("preserve-me"), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := create(context.Background(), cfg, bytes.NewReader(bytes.Repeat([]byte{1}, 32))); err == nil {
		t.Fatal("create() expected existing database error")
	}
	contents, err := os.ReadFile(cfg.Database.Path)
	if err != nil {
		t.Fatal(err)
	}
	if string(contents) != "preserve-me" {
		t.Fatal("existing database was modified")
	}
	if _, err := os.Stat(cfg.Database.KeyFile); !os.IsNotExist(err) {
		t.Fatalf("key was created despite existing database: %v", err)
	}
}

func provisionConfig(root string) config.Config {
	return config.Config{
		ServiceName: "BillingActivityWatch",
		Database: config.DatabaseConfig{
			Path:    filepath.Join(root, "database", "activity_watch.db"),
			KeyFile: filepath.Join(root, "secrets", "activity_watch.key"),
		},
		Control: config.ControlConfig{
			LogoutRequestPath: filepath.Join(root, "control", "logout.request"),
			PollInterval:      config.Duration{Duration: time.Second},
		},
		Collection: config.CollectionConfig{HeartbeatInterval: config.Duration{Duration: time.Minute}},
		Sync: config.SyncConfig{
			Enabled:        false,
			Interval:       config.Duration{Duration: time.Minute},
			BatchSize:      100,
			RequestTimeout: config.Duration{Duration: time.Second},
			BaseRetryDelay: config.Duration{Duration: time.Second},
			MaxRetryDelay:  config.Duration{Duration: time.Minute},
		},
		ShutdownFlushTimeout: config.Duration{Duration: time.Second},
	}
}
