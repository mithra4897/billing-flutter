package syncer

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"strings"
	"testing"
	"time"

	"billing/activity-watch-agent/internal/store"
)

func TestFlushUploadsBoundedBatchAndMarksSynced(t *testing.T) {
	repository := &fakeRepository{items: []store.OutboxItem{
		{ID: "1", IdempotencyKey: "key-1"},
		{ID: "2", IdempotencyKey: "key-2"},
		{ID: "3", IdempotencyKey: "key-3"},
	}}
	client := &http.Client{Transport: roundTripFunc(func(request *http.Request) (*http.Response, error) {
		if got := request.Header.Get("Authorization"); got != "Bearer device-secret" {
			t.Errorf("Authorization = %q", got)
		}
		if got := request.Header.Get("X-Device-Id"); got != "device-1" {
			t.Errorf("X-Device-Id = %q", got)
		}
		var body batchRequest
		if err := json.NewDecoder(request.Body).Decode(&body); err != nil {
			t.Errorf("decode body: %v", err)
		}
		if len(body.Items) != 2 {
			t.Errorf("items = %d, want 2", len(body.Items))
		}
		return response(http.StatusAccepted, nil), nil
	})}

	synchronizer := testSynchronizer(repository, client)
	synchronizer.config.BatchSize = 2
	count, err := synchronizer.Flush(context.Background())
	if err != nil {
		t.Fatalf("Flush() error = %v", err)
	}
	if count != 2 {
		t.Fatalf("Flush() count = %d, want 2", count)
	}
	if len(repository.synced) != 2 || repository.claimLimit != 2 {
		t.Fatalf("synced = %v, claim limit = %d", repository.synced, repository.claimLimit)
	}
}

func TestFlushSchedulesRetryFromServerHeader(t *testing.T) {
	repository := &fakeRepository{items: []store.OutboxItem{{ID: "1", IdempotencyKey: "key-1"}}}
	client := &http.Client{Transport: roundTripFunc(func(_ *http.Request) (*http.Response, error) {
		return response(http.StatusTooManyRequests, http.Header{"Retry-After": []string{"120"}}), nil
	})}

	synchronizer := testSynchronizer(repository, client)
	_, err := synchronizer.Flush(context.Background())
	if err == nil {
		t.Fatal("Flush() expected retryable error")
	}
	want := synchronizer.now().Add(2 * time.Minute)
	if !repository.retryAt.Equal(want) || repository.retryCode != "http-429" {
		t.Fatalf("retry = %v %q, want %v http-429", repository.retryAt, repository.retryCode, want)
	}
}

func TestFlushMarksAuthenticationFailurePermanent(t *testing.T) {
	repository := &fakeRepository{items: []store.OutboxItem{{ID: "1", IdempotencyKey: "key-1"}}}
	client := &http.Client{Transport: roundTripFunc(func(_ *http.Request) (*http.Response, error) {
		return response(http.StatusUnauthorized, nil), nil
	})}

	synchronizer := testSynchronizer(repository, client)
	_, err := synchronizer.Flush(context.Background())
	if err == nil {
		t.Fatal("Flush() expected permanent error")
	}
	if repository.permanentCode != "http-401" {
		t.Fatalf("permanent code = %q", repository.permanentCode)
	}
}

func TestBackoffIsCapped(t *testing.T) {
	repository := &fakeRepository{}
	synchronizer := testSynchronizer(repository, http.DefaultClient)
	synchronizer.jitter = func() float64 { return 1 }
	got := synchronizer.backoff([]store.OutboxItem{{AttemptCount: 20}})
	if got != synchronizer.config.MaxRetryDelay {
		t.Fatalf("backoff = %v, want %v", got, synchronizer.config.MaxRetryDelay)
	}
}

func testSynchronizer(repository *fakeRepository, client *http.Client) *Synchronizer {
	fixedNow := time.Date(2026, 8, 6, 12, 0, 0, 0, time.UTC)
	value := New(repository, client, Config{
		Enabled:        true,
		URL:            "https://erp.example.test/api/v1/activity-watch/batches",
		DeviceID:       "device-1",
		Credential:     "device-secret",
		BatchSize:      100,
		BaseRetryDelay: time.Second,
		MaxRetryDelay:  5 * time.Minute,
	})
	value.now = func() time.Time { return fixedNow }
	value.jitter = func() float64 { return 0.5 }
	return value
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (function roundTripFunc) RoundTrip(request *http.Request) (*http.Response, error) {
	return function(request)
}

func response(status int, headers http.Header) *http.Response {
	if headers == nil {
		headers = make(http.Header)
	}
	return &http.Response{
		StatusCode: status,
		Header:     headers,
		Body:       io.NopCloser(strings.NewReader("")),
	}
}

type fakeRepository struct {
	items         []store.OutboxItem
	claimLimit    int
	synced        []string
	retryAt       time.Time
	retryCode     string
	permanentCode string
}

func (f *fakeRepository) RecordSystemEvent(context.Context, store.SystemEvent) error { return nil }
func (f *fakeRepository) RecoverProcessing(context.Context, time.Time) error         { return nil }
func (f *fakeRepository) ClaimReadyBatch(_ context.Context, _ time.Time, limit int) ([]store.OutboxItem, error) {
	f.claimLimit = limit
	if len(f.items) > limit {
		return f.items[:limit], nil
	}
	return f.items, nil
}
func (f *fakeRepository) MarkSynced(_ context.Context, ids []string, _ time.Time) error {
	f.synced = append([]string(nil), ids...)
	return nil
}
func (f *fakeRepository) MarkRetry(_ context.Context, _ []string, next time.Time, code string) error {
	f.retryAt = next
	f.retryCode = code
	return nil
}
func (f *fakeRepository) MarkPermanentFailure(_ context.Context, _ []string, code string) error {
	f.permanentCode = code
	return nil
}
func (f *fakeRepository) Close() error { return nil }
