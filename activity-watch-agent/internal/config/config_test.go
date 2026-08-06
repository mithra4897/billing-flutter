package config

import (
	"path/filepath"
	"testing"
	"time"
)

func validConfig(t *testing.T) Config {
	t.Helper()
	root := t.TempDir()
	return Config{
		ServiceName: "BillingActivityWatch",
		Database: DatabaseConfig{
			Path:    filepath.Join(root, "activity_watch.db"),
			KeyFile: filepath.Join(root, "database.key"),
		},
		Control: ControlConfig{
			LogoutRequestPath: filepath.Join(root, "logout.request"),
			PollInterval:      Duration{time.Second},
		},
		Collection: CollectionConfig{HeartbeatInterval: Duration{time.Minute}},
		Sync: SyncConfig{
			Enabled:        true,
			URL:            "https://erp.example.com/api/v1/activity-watch/batches",
			DeviceID:       "device-1",
			CredentialFile: filepath.Join(root, "device.credential"),
			Interval:       Duration{30 * time.Second},
			BatchSize:      100,
			RequestTimeout: Duration{15 * time.Second},
			BaseRetryDelay: Duration{30 * time.Second},
			MaxRetryDelay:  Duration{30 * time.Minute},
		},
		ShutdownFlushTimeout: Duration{8 * time.Second},
	}
}

func TestValidateAcceptsSecureConfiguration(t *testing.T) {
	if err := validConfig(t).Validate(); err != nil {
		t.Fatalf("Validate() error = %v", err)
	}
}

func TestValidateAllowsDisabledUploaderWithoutEndpoint(t *testing.T) {
	cfg := validConfig(t)
	cfg.Sync.Enabled = false
	cfg.Sync.URL = ""
	cfg.Sync.DeviceID = ""
	cfg.Sync.CredentialFile = ""
	if err := cfg.Validate(); err != nil {
		t.Fatalf("Validate() error = %v", err)
	}
}

func TestValidateRejectsInsecureRemoteEndpoint(t *testing.T) {
	cfg := validConfig(t)
	cfg.Sync.URL = "http://erp.example.com/api/v1/activity-watch/batches"
	if err := cfg.Validate(); err == nil {
		t.Fatal("Validate() expected an HTTPS error")
	}
}

func TestValidateRejectsUnboundedBatch(t *testing.T) {
	cfg := validConfig(t)
	cfg.Sync.BatchSize = 501
	if err := cfg.Validate(); err == nil {
		t.Fatal("Validate() expected a batch size error")
	}
}
