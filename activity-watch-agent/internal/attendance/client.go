package attendance

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"sort"
	"strings"
	"sync"
	"time"
)

type Client struct {
	httpClient  *http.Client
	url         string
	deviceID    string
	credential  string
	pendingPath string
	mu          sync.Mutex
}

func New(httpClient *http.Client, batchURL, deviceID, credential, pendingPath string) *Client {
	return &Client{
		httpClient:  httpClient,
		url:         strings.TrimSuffix(batchURL, "/batches") + "/attendance",
		deviceID:    deviceID,
		credential:  credential,
		pendingPath: pendingPath,
	}
}

// CheckIn durably queues one first-seen event per local day before sending it.
// A service restart or temporary network failure therefore keeps the original
// check-in time, while the server's employee/date unique key remains the final
// duplicate guard.
func (c *Client) CheckIn(ctx context.Context, at time.Time) error {
	c.mu.Lock()
	defer c.mu.Unlock()

	pending, err := c.loadPending()
	if err != nil {
		return err
	}
	date := at.Format("2006-01-02")
	if _, exists := pending[date]; !exists {
		pending[date] = at.UTC().Format(time.RFC3339Nano)
		if err := c.savePending(pending); err != nil {
			return err
		}
	}

	dates := make([]string, 0, len(pending))
	for pendingDate := range pending {
		dates = append(dates, pendingDate)
	}
	sort.Strings(dates)
	for _, pendingDate := range dates {
		pendingAt, err := time.Parse(time.RFC3339Nano, pending[pendingDate])
		if err != nil {
			return fmt.Errorf("parse pending attendance for %s: %w", pendingDate, err)
		}
		if err := c.send(ctx, "check_in", pendingAt, pendingDate); err != nil {
			return err
		}
		delete(pending, pendingDate)
		if err := c.savePending(pending); err != nil {
			return err
		}
	}
	return nil
}

func (c *Client) CheckOut(ctx context.Context, at time.Time) error {
	return c.send(ctx, "check_out", at, at.Format("2006-01-02"))
}

func (c *Client) send(ctx context.Context, eventType string, at time.Time, localDate string) error {
	body, _ := json.Marshal(map[string]string{"event_type": eventType, "event_at_utc": at.UTC().Format(time.RFC3339Nano)})
	request, err := http.NewRequestWithContext(ctx, http.MethodPost, c.url, bytes.NewReader(body))
	if err != nil {
		return err
	}
	request.Header.Set("Authorization", "Bearer "+c.credential)
	request.Header.Set("X-Device-Id", c.deviceID)
	request.Header.Set("Content-Type", "application/json")
	hash := sha256.Sum256([]byte(c.deviceID + "\x00" + eventType + "\x00" + localDate))
	request.Header.Set("Idempotency-Key", hex.EncodeToString(hash[:]))
	response, err := c.httpClient.Do(request)
	if err != nil {
		return err
	}
	defer response.Body.Close()
	if response.StatusCode >= 200 && response.StatusCode < 300 {
		return nil
	}
	detail, _ := io.ReadAll(io.LimitReader(response.Body, 1024))
	return fmt.Errorf("attendance response %d: %s", response.StatusCode, strings.TrimSpace(string(detail)))
}

func (c *Client) loadPending() (map[string]string, error) {
	pending := make(map[string]string)
	if c.pendingPath == "" {
		return pending, nil
	}
	data, err := os.ReadFile(c.pendingPath)
	if err != nil {
		if os.IsNotExist(err) {
			return pending, nil
		}
		return nil, fmt.Errorf("read pending attendance: %w", err)
	}
	if err := json.Unmarshal(data, &pending); err != nil {
		return nil, fmt.Errorf("decode pending attendance: %w", err)
	}
	return pending, nil
}

func (c *Client) savePending(pending map[string]string) error {
	if c.pendingPath == "" {
		return nil
	}
	if len(pending) == 0 {
		if err := os.Remove(c.pendingPath); err != nil && !os.IsNotExist(err) {
			return fmt.Errorf("clear pending attendance: %w", err)
		}
		return nil
	}
	data, err := json.Marshal(pending)
	if err != nil {
		return err
	}
	temporaryPath := c.pendingPath + ".tmp"
	if err := os.WriteFile(temporaryPath, data, 0o600); err != nil {
		return fmt.Errorf("write pending attendance: %w", err)
	}
	if err := os.Rename(temporaryPath, c.pendingPath); err != nil {
		return fmt.Errorf("commit pending attendance: %w", err)
	}
	return nil
}
