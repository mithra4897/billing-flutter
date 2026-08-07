package config

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"time"
)

type Duration struct {
	time.Duration
}

func (d *Duration) UnmarshalJSON(data []byte) error {
	var value string
	if err := json.Unmarshal(data, &value); err != nil {
		return errors.New("duration must be a quoted value such as 30s")
	}
	parsed, err := time.ParseDuration(value)
	if err != nil {
		return fmt.Errorf("invalid duration %q: %w", value, err)
	}
	d.Duration = parsed
	return nil
}

type Config struct {
	ServiceName          string           `json:"service_name"`
	Database             DatabaseConfig   `json:"database"`
	Control              ControlConfig    `json:"control"`
	Collection           CollectionConfig `json:"collection"`
	Sync                 SyncConfig       `json:"sync"`
	ShutdownFlushTimeout Duration         `json:"shutdown_flush_timeout"`
}

type DatabaseConfig struct {
	Path    string `json:"path"`
	KeyFile string `json:"key_file"`
}

type ControlConfig struct {
	LogoutRequestPath string   `json:"logout_request_path"`
	PollInterval      Duration `json:"poll_interval"`
}

type CollectionConfig struct {
	Disabled                 bool     `json:"disabled"`
	HeartbeatInterval        Duration `json:"heartbeat_interval"`
	SampleInterval           Duration `json:"sample_interval"`
	IdleThreshold            Duration `json:"idle_threshold"`
	ProcessInventoryInterval Duration `json:"process_inventory_interval"`
	ServiceInventoryInterval Duration `json:"service_inventory_interval"`
	SummaryInterval          Duration `json:"summary_interval"`
	RetentionDays            int      `json:"retention_days"`
}

type SyncConfig struct {
	Enabled        bool     `json:"enabled"`
	URL            string   `json:"url"`
	DeviceID       string   `json:"device_id"`
	CredentialFile string   `json:"credential_file"`
	Interval       Duration `json:"interval"`
	BatchSize      int      `json:"batch_size"`
	RequestTimeout Duration `json:"request_timeout"`
	BaseRetryDelay Duration `json:"base_retry_delay"`
	MaxRetryDelay  Duration `json:"max_retry_delay"`
}

func Load(path string) (Config, error) {
	var cfg Config
	if !filepath.IsAbs(path) {
		return cfg, errors.New("configuration path must be absolute")
	}
	data, err := os.ReadFile(path)
	if err != nil {
		return cfg, fmt.Errorf("read configuration: %w", err)
	}
	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&cfg); err != nil {
		return cfg, fmt.Errorf("decode configuration: %w", err)
	}
	cfg.applyDefaults()
	if err := cfg.Validate(); err != nil {
		return cfg, err
	}
	return cfg, nil
}

func (c *Config) applyDefaults() {
	if c.Collection.SampleInterval.Duration == 0 {
		c.Collection.SampleInterval.Duration = 15 * time.Second
	}
	if c.Collection.IdleThreshold.Duration == 0 {
		c.Collection.IdleThreshold.Duration = 5 * time.Minute
	}
	if c.Collection.ProcessInventoryInterval.Duration == 0 {
		c.Collection.ProcessInventoryInterval.Duration = 5 * time.Minute
	}
	if c.Collection.ServiceInventoryInterval.Duration == 0 {
		c.Collection.ServiceInventoryInterval.Duration = 15 * time.Minute
	}
	if c.Collection.SummaryInterval.Duration == 0 {
		c.Collection.SummaryInterval.Duration = 15 * time.Minute
	}
	if c.Collection.RetentionDays == 0 {
		c.Collection.RetentionDays = 90
	}
}

func (c Config) Validate() error {
	c.applyDefaults()
	if strings.TrimSpace(c.ServiceName) == "" {
		return errors.New("service_name is required")
	}
	if err := requireAbsolute("database.path", c.Database.Path); err != nil {
		return err
	}
	if err := requireAbsolute("database.key_file", c.Database.KeyFile); err != nil {
		return err
	}
	if err := requireAbsolute("control.logout_request_path", c.Control.LogoutRequestPath); err != nil {
		return err
	}
	if c.Control.PollInterval.Duration < 250*time.Millisecond {
		return errors.New("control.poll_interval must be at least 250ms")
	}
	if c.Collection.HeartbeatInterval.Duration < time.Minute {
		return errors.New("collection.heartbeat_interval must be at least 1m")
	}
	if c.Collection.SampleInterval.Duration < 5*time.Second || c.Collection.SampleInterval.Duration > time.Minute {
		return errors.New("collection.sample_interval must be between 5s and 1m")
	}
	if c.Collection.IdleThreshold.Duration < time.Minute || c.Collection.IdleThreshold.Duration > time.Hour {
		return errors.New("collection.idle_threshold must be between 1m and 1h")
	}
	if c.Collection.ProcessInventoryInterval.Duration < time.Minute {
		return errors.New("collection.process_inventory_interval must be at least 1m")
	}
	if c.Collection.ServiceInventoryInterval.Duration < time.Minute {
		return errors.New("collection.service_inventory_interval must be at least 1m")
	}
	if c.Collection.SummaryInterval.Duration < time.Minute || c.Collection.SummaryInterval.Duration > time.Hour {
		return errors.New("collection.summary_interval must be between 1m and 1h")
	}
	if c.Collection.RetentionDays < 1 || c.Collection.RetentionDays > 365 {
		return errors.New("collection.retention_days must be between 1 and 365")
	}
	if c.ShutdownFlushTimeout.Duration <= 0 || c.ShutdownFlushTimeout.Duration > time.Minute {
		return errors.New("shutdown_flush_timeout must be greater than 0 and at most 1m")
	}
	if c.Sync.Interval.Duration <= 0 {
		return errors.New("sync.interval must be greater than 0")
	}
	if c.Sync.BatchSize < 1 || c.Sync.BatchSize > 500 {
		return errors.New("sync.batch_size must be between 1 and 500")
	}
	if c.Sync.RequestTimeout.Duration <= 0 || c.Sync.RequestTimeout.Duration > time.Minute {
		return errors.New("sync.request_timeout must be greater than 0 and at most 1m")
	}
	if c.Sync.BaseRetryDelay.Duration <= 0 {
		return errors.New("sync.base_retry_delay must be greater than 0")
	}
	if c.Sync.MaxRetryDelay.Duration < c.Sync.BaseRetryDelay.Duration {
		return errors.New("sync.max_retry_delay must be at least sync.base_retry_delay")
	}
	if !c.Sync.Enabled {
		return nil
	}
	if err := requireAbsolute("sync.credential_file", c.Sync.CredentialFile); err != nil {
		return err
	}
	if strings.TrimSpace(c.Sync.DeviceID) == "" {
		return errors.New("sync.device_id is required when synchronization is enabled")
	}
	parsed, err := url.Parse(c.Sync.URL)
	if err != nil || parsed.Host == "" {
		return errors.New("sync.url must be an absolute HTTP(S) URL")
	}
	if parsed.Scheme != "https" && !(parsed.Scheme == "http" && isLoopbackHost(parsed.Hostname())) {
		return errors.New("sync.url must use HTTPS except for loopback development")
	}
	return nil
}

func requireAbsolute(name, value string) error {
	if strings.TrimSpace(value) == "" || !filepath.IsAbs(value) {
		return fmt.Errorf("%s must be an absolute path", name)
	}
	return nil
}

func isLoopbackHost(host string) bool {
	return host == "localhost" || host == "127.0.0.1" || host == "::1"
}
