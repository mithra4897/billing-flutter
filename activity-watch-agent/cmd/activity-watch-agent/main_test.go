package main

import (
	"context"
	"path/filepath"
	"testing"
	"time"

	"billing/activity-watch-agent/internal/config"
	"billing/activity-watch-agent/internal/provision"
)

func TestServiceProgramStopsWithinConfiguredDeadline(t *testing.T) {
	root := t.TempDir()
	cfg := config.Config{
		ServiceName: "BillingActivityWatchTest",
		Database: config.DatabaseConfig{
			Path:    filepath.Join(root, "data", "activity_watch.db"),
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
	if _, err := provision.Create(context.Background(), cfg); err != nil {
		t.Fatalf("provision.Create() error = %v", err)
	}

	program := &serviceProgram{config: cfg}
	if err := program.Start(nil); err != nil {
		t.Fatalf("Start() error = %v", err)
	}
	started := time.Now()
	if err := program.Stop(nil); err != nil {
		t.Fatalf("Stop() error = %v", err)
	}
	if elapsed := time.Since(started); elapsed > 2*time.Second {
		t.Fatalf("Stop() took %s, want less than 2s", elapsed)
	}
}
