package pairing

import (
	"bytes"
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"time"

	"billing/activity-watch-agent/internal/config"
	"billing/activity-watch-agent/internal/provision"
)

const (
	bundleVersion   = 1
	maxBundleSize   = 8192
	maxResponseSize = 65536
)

type Bundle struct {
	Version      int    `json:"version"`
	PairingURL   string `json:"pairing_url"`
	PairingToken string `json:"pairing_token"`
	Platform     string `json:"platform"`
}

type Result struct {
	DeviceID string
}

type exchangeResponse struct {
	Success bool         `json:"success"`
	Message string       `json:"message"`
	Data    exchangeData `json:"data"`
}

type exchangeData struct {
	DeviceID      string `json:"device_id"`
	BatchURL      string `json:"batch_url"`
	RetentionDays int    `json:"retention_days"`
}

func Apply(ctx context.Context, bundlePath, configPath string, client *http.Client) (Result, error) {
	if !filepath.IsAbs(bundlePath) || !filepath.IsAbs(configPath) {
		return Result{}, errors.New("pairing bundle and configuration paths must be absolute")
	}
	bundle, err := readBundle(bundlePath)
	if err != nil {
		return Result{}, err
	}
	if err := validateBundle(bundle); err != nil {
		return Result{}, err
	}
	cfg, err := config.Load(configPath)
	if err != nil {
		return Result{}, err
	}
	if err := ensureProvisioned(ctx, cfg); err != nil {
		return Result{}, err
	}
	if client == nil {
		client = &http.Client{Timeout: 20 * time.Second}
	}
	candidatePath := cfg.Sync.CredentialFile + ".pairing-candidate"
	credential, err := loadOrCreateCandidate(candidatePath)
	if err != nil {
		return Result{}, err
	}
	paired, err := exchange(ctx, client, bundle, credential)
	if err != nil {
		return Result{}, err
	}
	if err := validateExchange(paired); err != nil {
		return Result{}, err
	}
	if err := atomicWrite(cfg.Sync.CredentialFile, []byte(credential), 0o600); err != nil {
		return Result{}, fmt.Errorf("store paired credential: %w", err)
	}
	cfg.Sync.Enabled = true
	cfg.Sync.DeviceID = paired.DeviceID
	cfg.Sync.URL = paired.BatchURL
	cfg.Collection.Disabled = false
	if paired.RetentionDays > 0 {
		cfg.Collection.RetentionDays = paired.RetentionDays
	}
	encoded, err := json.MarshalIndent(cfg, "", "  ")
	if err != nil {
		return Result{}, fmt.Errorf("encode paired configuration: %w", err)
	}
	encoded = append(encoded, '\n')
	if err := atomicWrite(configPath, encoded, 0o600); err != nil {
		return Result{}, fmt.Errorf("store paired configuration: %w", err)
	}
	if err := os.Remove(candidatePath); err != nil && !errors.Is(err, os.ErrNotExist) {
		return Result{}, fmt.Errorf("remove pairing candidate: %w", err)
	}
	if err := os.Remove(bundlePath); err != nil && !errors.Is(err, os.ErrNotExist) {
		return Result{}, fmt.Errorf("remove consumed pairing bundle: %w", err)
	}
	return Result{DeviceID: paired.DeviceID}, nil
}

func readBundle(path string) (Bundle, error) {
	var bundle Bundle
	file, err := os.Open(path)
	if err != nil {
		return bundle, fmt.Errorf("open pairing bundle: %w", err)
	}
	defer file.Close()
	data, err := io.ReadAll(io.LimitReader(file, maxBundleSize+1))
	if err != nil {
		return bundle, fmt.Errorf("read pairing bundle: %w", err)
	}
	if len(data) > maxBundleSize {
		return bundle, errors.New("pairing bundle exceeds 8 KiB")
	}
	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&bundle); err != nil {
		return bundle, fmt.Errorf("decode pairing bundle: %w", err)
	}
	if decoder.Decode(&struct{}{}) != io.EOF {
		return bundle, errors.New("pairing bundle must contain one JSON object")
	}
	return bundle, nil
}

func validateBundle(bundle Bundle) error {
	if bundle.Version != bundleVersion {
		return errors.New("unsupported pairing bundle version")
	}
	if len(bundle.PairingToken) != 64 || strings.ContainsAny(bundle.PairingToken, "\r\n \t") {
		return errors.New("pairing token must contain exactly 64 non-space characters")
	}
	if bundle.Platform != platformName() {
		return fmt.Errorf("pairing bundle is for %s, not %s", bundle.Platform, platformName())
	}
	return validateRemoteURL(bundle.PairingURL, "pairing_url")
}

func exchange(ctx context.Context, client *http.Client, bundle Bundle, credential string) (exchangeData, error) {
	payload, _ := json.Marshal(map[string]string{
		"pairing_token":     bundle.PairingToken,
		"platform":          bundle.Platform,
		"agent_version":     "1",
		"device_credential": credential,
	})
	request, err := http.NewRequestWithContext(ctx, http.MethodPost, bundle.PairingURL, bytes.NewReader(payload))
	if err != nil {
		return exchangeData{}, fmt.Errorf("create pairing request: %w", err)
	}
	request.Header.Set("Content-Type", "application/json")
	response, err := client.Do(request)
	if err != nil {
		return exchangeData{}, fmt.Errorf("exchange pairing token: %w", err)
	}
	defer response.Body.Close()
	body, err := io.ReadAll(io.LimitReader(response.Body, maxResponseSize+1))
	if err != nil {
		return exchangeData{}, fmt.Errorf("read pairing response: %w", err)
	}
	if len(body) > maxResponseSize {
		return exchangeData{}, errors.New("pairing response exceeds 64 KiB")
	}
	var envelope exchangeResponse
	if err := json.Unmarshal(body, &envelope); err != nil {
		return exchangeData{}, fmt.Errorf("decode pairing response (HTTP %d)", response.StatusCode)
	}
	if response.StatusCode < 200 || response.StatusCode >= 300 || !envelope.Success {
		message := strings.TrimSpace(envelope.Message)
		if message == "" {
			message = "pairing request was rejected"
		}
		return exchangeData{}, fmt.Errorf("%s (HTTP %d)", message, response.StatusCode)
	}
	return envelope.Data, nil
}

func validateExchange(data exchangeData) error {
	if strings.TrimSpace(data.DeviceID) == "" {
		return errors.New("pairing response is missing device_id")
	}
	if data.RetentionDays < 1 || data.RetentionDays > 365 {
		return errors.New("pairing response contains invalid retention_days")
	}
	return validateRemoteURL(data.BatchURL, "batch_url")
}

func generateCredential() (string, error) {
	random := make([]byte, 32)
	if _, err := io.ReadFull(rand.Reader, random); err != nil {
		return "", fmt.Errorf("generate device credential: %w", err)
	}
	return hex.EncodeToString(random), nil
}

func loadOrCreateCandidate(path string) (string, error) {
	data, err := os.ReadFile(path)
	if err == nil {
		credential := strings.TrimSpace(string(data))
		if len(credential) == 64 && isAlphanumeric(credential) {
			return credential, nil
		}
	} else if !errors.Is(err, os.ErrNotExist) {
		return "", fmt.Errorf("read pairing candidate: %w", err)
	}
	credential, err := generateCredential()
	if err != nil {
		return "", err
	}
	if err := atomicWrite(path, []byte(credential), 0o600); err != nil {
		return "", fmt.Errorf("store pairing candidate: %w", err)
	}
	return credential, nil
}

func isAlphanumeric(value string) bool {
	for _, character := range value {
		if !(character >= 'a' && character <= 'z') && !(character >= 'A' && character <= 'Z') && !(character >= '0' && character <= '9') {
			return false
		}
	}
	return true
}

func ensureProvisioned(ctx context.Context, cfg config.Config) error {
	databaseExists := exists(cfg.Database.Path)
	keyExists := exists(cfg.Database.KeyFile)
	if databaseExists != keyExists {
		return errors.New("database and key must either both exist or both be absent")
	}
	if databaseExists {
		return nil
	}
	_, err := provision.Create(ctx, cfg)
	return err
}

func exists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

func atomicWrite(target string, data []byte, mode os.FileMode) error {
	if err := os.MkdirAll(filepath.Dir(target), 0o700); err != nil {
		return err
	}
	file, err := os.CreateTemp(filepath.Dir(target), ".activity-watch-pair-*")
	if err != nil {
		return err
	}
	temporary := file.Name()
	defer os.Remove(temporary)
	if err := file.Chmod(mode); err != nil {
		file.Close()
		return err
	}
	if _, err := file.Write(data); err != nil {
		file.Close()
		return err
	}
	if err := file.Sync(); err != nil {
		file.Close()
		return err
	}
	if err := file.Close(); err != nil {
		return err
	}
	return os.Rename(temporary, target)
}

func validateRemoteURL(value, field string) error {
	parsed, err := url.Parse(value)
	if err != nil || parsed.Host == "" || parsed.User != nil {
		return fmt.Errorf("%s must be an absolute HTTP(S) URL without user information", field)
	}
	if parsed.Scheme != "https" && !(parsed.Scheme == "http" && isDevelopmentHTTPHost(parsed.Hostname())) {
		return fmt.Errorf("%s must use HTTPS except for approved development hosts", field)
	}
	return nil
}

func isDevelopmentHTTPHost(host string) bool {
	return host == "localhost" || host == "127.0.0.1" || host == "::1" || host == "bill.local" || host == "192.168.31.83"
}

func platformName() string {
	if runtime.GOOS == "darwin" {
		return "macos"
	}
	return runtime.GOOS
}
