package pairing

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"billing/activity-watch-agent/internal/config"
)

func TestApplyPairsProvisionsAndWritesProtectedFiles(t *testing.T) {
	root := t.TempDir()
	token := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	var exchangedCredential string
	client := &http.Client{Transport: roundTripFunc(func(request *http.Request) (*http.Response, error) {
		var body map[string]string
		if err := json.NewDecoder(request.Body).Decode(&body); err != nil {
			t.Fatal(err)
		}
		if body["pairing_token"] != token || body["platform"] != platformName() {
			t.Fatalf("pairing body = %#v", body)
		}
		exchangedCredential = body["device_credential"]
		if len(exchangedCredential) != 64 {
			t.Fatalf("generated credential length = %d", len(exchangedCredential))
		}
		return &http.Response{
			StatusCode: http.StatusOK,
			Header:     make(http.Header),
			Body: io.NopCloser(strings.NewReader(
				`{"success":true,"message":"paired","data":{"device_id":"device-1","batch_url":"http://127.0.0.1/batches","retention_days":90}}`,
			)),
		}, nil
	})}

	cfg := testConfig(root)
	configPath := filepath.Join(root, "activity-watch-agent.config.json")
	writeJSON(t, configPath, cfg)
	bundlePath := filepath.Join(root, "device.billingawpair")
	writeJSON(t, bundlePath, Bundle{Version: 1, PairingURL: "http://127.0.0.1/pair", PairingToken: token, Platform: platformName()})

	result, err := Apply(context.Background(), bundlePath, configPath, client)
	if err != nil {
		t.Fatal(err)
	}
	if result.DeviceID != "device-1" {
		t.Fatalf("device ID = %q", result.DeviceID)
	}
	if _, err := os.Stat(bundlePath); !os.IsNotExist(err) {
		t.Fatalf("pairing bundle should be removed, stat error = %v", err)
	}
	if _, err := os.Stat(cfg.Sync.CredentialFile + ".pairing-candidate"); !os.IsNotExist(err) {
		t.Fatalf("pairing candidate should be removed, stat error = %v", err)
	}
	loaded, err := config.Load(configPath)
	if err != nil {
		t.Fatal(err)
	}
	if !loaded.Sync.Enabled || loaded.Sync.DeviceID != "device-1" || loaded.Collection.Disabled {
		t.Fatalf("paired config = %#v", loaded)
	}
	stored, err := os.ReadFile(cfg.Sync.CredentialFile)
	if err != nil || string(stored) != exchangedCredential {
		t.Fatalf("credential write error/value = %v/%q", err, string(stored))
	}
	if info, err := os.Stat(cfg.Sync.CredentialFile); err != nil || info.Mode().Perm()&0o077 != 0 {
		t.Fatalf("credential permissions error/mode = %v/%v", err, info.Mode().Perm())
	}
	if _, err := os.Stat(cfg.Database.Path); err != nil {
		t.Fatalf("database was not provisioned: %v", err)
	}
}

func TestValidateBundleRejectsRemoteHTTP(t *testing.T) {
	err := validateBundle(Bundle{
		Version: 1, PairingURL: "http://erp.example.com/api/v1/activity-watch/pair",
		PairingToken: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
		Platform:     platformName(),
	})
	if err == nil {
		t.Fatal("expected remote HTTP pairing URL to be rejected")
	}
}

func TestPairingCandidateIsStableAcrossRetries(t *testing.T) {
	path := filepath.Join(t.TempDir(), "secrets", "candidate")
	first, err := loadOrCreateCandidate(path)
	if err != nil {
		t.Fatal(err)
	}
	second, err := loadOrCreateCandidate(path)
	if err != nil {
		t.Fatal(err)
	}
	if first != second || len(first) != 64 {
		t.Fatalf("candidate retry values differ or are invalid: %d/%d", len(first), len(second))
	}
}

func testConfig(root string) config.Config {
	return config.Config{
		ServiceName: "BillingActivityWatchTest",
		Database: config.DatabaseConfig{
			Path: filepath.Join(root, "data", "activity_watch.db"), KeyFile: filepath.Join(root, "secrets", "database.key"),
		},
		Control: config.ControlConfig{
			LogoutRequestPath: filepath.Join(root, "control", "logout.request"), PollInterval: config.Duration{Duration: time.Second},
		},
		Collection: config.CollectionConfig{
			Disabled: true, HeartbeatInterval: config.Duration{Duration: time.Minute},
		},
		Sync: config.SyncConfig{
			Enabled: false, URL: "https://erp.example.com/api/v1/activity-watch/batches",
			CredentialFile: filepath.Join(root, "secrets", "device.credential"),
			Interval:       config.Duration{Duration: time.Minute}, BatchSize: 100,
			RequestTimeout: config.Duration{Duration: time.Second}, BaseRetryDelay: config.Duration{Duration: time.Second},
			MaxRetryDelay: config.Duration{Duration: time.Minute},
		},
		ShutdownFlushTimeout: config.Duration{Duration: time.Second},
	}
}

func writeJSON(t *testing.T, path string, value any) {
	t.Helper()
	data, err := json.Marshal(value)
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, data, 0o600); err != nil {
		t.Fatal(err)
	}
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (function roundTripFunc) RoundTrip(request *http.Request) (*http.Response, error) {
	return function(request)
}
