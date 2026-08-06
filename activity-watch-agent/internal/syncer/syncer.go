package syncer

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"math"
	"net/http"
	"strconv"
	"strings"
	"time"

	"billing/activity-watch-agent/internal/store"
)

type Config struct {
	Enabled        bool
	URL            string
	DeviceID       string
	Credential     string
	BatchSize      int
	BaseRetryDelay time.Duration
	MaxRetryDelay  time.Duration
}

type Synchronizer struct {
	repository store.Repository
	httpClient *http.Client
	config     Config
	now        func() time.Time
	jitter     func() float64
}

type batchRequest struct {
	DeviceID string             `json:"device_id"`
	Items    []store.OutboxItem `json:"items"`
}

func New(repository store.Repository, httpClient *http.Client, config Config) *Synchronizer {
	return &Synchronizer{
		repository: repository,
		httpClient: httpClient,
		config:     config,
		now:        time.Now,
		jitter:     func() float64 { return 0.5 },
	}
}

func (s *Synchronizer) Flush(ctx context.Context) (int, error) {
	if !s.config.Enabled {
		return 0, nil
	}
	now := s.now().UTC()
	items, err := s.repository.ClaimReadyBatch(ctx, now, s.config.BatchSize)
	if err != nil || len(items) == 0 {
		return 0, err
	}
	ids := make([]string, len(items))
	for index, item := range items {
		ids[index] = item.ID
	}

	body, err := json.Marshal(batchRequest{DeviceID: s.config.DeviceID, Items: items})
	if err != nil {
		return 0, s.markRetry(ctx, items, ids, "encode-failed", 0, err)
	}
	request, err := http.NewRequestWithContext(ctx, http.MethodPost, s.config.URL, bytes.NewReader(body))
	if err != nil {
		return 0, s.markRetry(ctx, items, ids, "request-failed", 0, err)
	}
	request.Header.Set("Authorization", "Bearer "+s.config.Credential)
	request.Header.Set("Content-Type", "application/json")
	request.Header.Set("X-Device-Id", s.config.DeviceID)
	request.Header.Set("Idempotency-Key", batchIdempotencyKey(items))

	response, err := s.httpClient.Do(request)
	if err != nil {
		return 0, s.markRetry(ctx, items, ids, "network-error", 0, err)
	}
	defer response.Body.Close()
	_, _ = io.Copy(io.Discard, io.LimitReader(response.Body, 64*1024))

	switch {
	case response.StatusCode >= 200 && response.StatusCode < 300:
		if err := s.repository.MarkSynced(ctx, ids, now); err != nil {
			return 0, err
		}
		return len(items), nil
	case response.StatusCode == http.StatusConflict:
		if err := s.repository.MarkSynced(ctx, ids, now); err != nil {
			return 0, err
		}
		return len(items), nil
	case response.StatusCode == http.StatusRequestTimeout ||
		response.StatusCode == http.StatusTooManyRequests ||
		response.StatusCode >= 500:
		retryAfter := parseRetryAfter(response.Header.Get("Retry-After"), now)
		code := "http-" + strconv.Itoa(response.StatusCode)
		return 0, s.markRetry(ctx, items, ids, code, retryAfter, fmt.Errorf("retryable upload response %d", response.StatusCode))
	default:
		code := "http-" + strconv.Itoa(response.StatusCode)
		if err := s.repository.MarkPermanentFailure(ctx, ids, code); err != nil {
			return 0, err
		}
		return 0, fmt.Errorf("permanent upload response %d", response.StatusCode)
	}
}

func (s *Synchronizer) markRetry(
	ctx context.Context,
	items []store.OutboxItem,
	ids []string,
	code string,
	retryAfter time.Duration,
	cause error,
) error {
	delay := retryAfter
	if delay <= 0 {
		delay = s.backoff(items)
	}
	if delay > s.config.MaxRetryDelay {
		delay = s.config.MaxRetryDelay
	}
	if err := s.repository.MarkRetry(ctx, ids, s.now().UTC().Add(delay), code); err != nil {
		return errors.Join(cause, err)
	}
	return cause
}

func (s *Synchronizer) backoff(items []store.OutboxItem) time.Duration {
	maximumAttempts := 0
	for _, item := range items {
		if item.AttemptCount > maximumAttempts {
			maximumAttempts = item.AttemptCount
		}
	}
	exponent := min(maximumAttempts, 20)
	delay := float64(s.config.BaseRetryDelay) * math.Pow(2, float64(exponent))
	// Keep jitter within ±20%; injected randomness makes this deterministic in tests.
	delay *= 0.8 + 0.4*min(max(s.jitter(), 0), 1)
	if delay > float64(s.config.MaxRetryDelay) {
		return s.config.MaxRetryDelay
	}
	return time.Duration(delay)
}

func batchIdempotencyKey(items []store.OutboxItem) string {
	hash := sha256.New()
	for _, item := range items {
		hash.Write([]byte(item.IdempotencyKey))
		hash.Write([]byte{0})
	}
	return hex.EncodeToString(hash.Sum(nil))
}

func parseRetryAfter(value string, now time.Time) time.Duration {
	value = strings.TrimSpace(value)
	if value == "" {
		return 0
	}
	if seconds, err := strconv.Atoi(value); err == nil && seconds >= 0 {
		return time.Duration(seconds) * time.Second
	}
	when, err := http.ParseTime(value)
	if err != nil || !when.After(now) {
		return 0
	}
	return when.Sub(now)
}
