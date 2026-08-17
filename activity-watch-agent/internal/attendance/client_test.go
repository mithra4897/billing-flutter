package attendance

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"sync/atomic"
	"testing"
	"time"
)

func TestCheckInPersistsAndRetriesOriginalEvent(t *testing.T) {
	var attempts atomic.Int32
	var receivedTimes []string
	httpClient := &http.Client{Transport: roundTripFunc(func(request *http.Request) (*http.Response, error) {
		if request.URL.Path != "/api/v1/activity-watch/attendance" {
			t.Fatalf("unexpected path %s", request.URL.Path)
		}
		if request.Header.Get("Authorization") != "Bearer credential" || request.Header.Get("X-Device-Id") != "device-1" {
			t.Fatal("device authentication headers were not sent")
		}
		var body map[string]string
		if err := json.NewDecoder(request.Body).Decode(&body); err != nil {
			t.Fatal(err)
		}
		receivedTimes = append(receivedTimes, body["event_at_utc"])
		if attempts.Add(1) == 1 {
			return response(http.StatusServiceUnavailable, "offline"), nil
		}
		return response(http.StatusAccepted, ""), nil
	})}

	pendingPath := filepath.Join(t.TempDir(), "attendance.pending")
	firstSeen := time.Date(2026, 8, 17, 9, 15, 0, 0, time.FixedZone("IST", 5*60*60+30*60))
	client := New(httpClient, "https://example.test/api/v1/activity-watch/batches", "device-1", "credential", pendingPath)
	if err := client.CheckIn(context.Background(), firstSeen); err == nil {
		t.Fatal("expected first request to fail")
	}
	if _, err := os.Stat(pendingPath); err != nil {
		t.Fatalf("pending check-in was not persisted: %v", err)
	}

	// Simulate a service restart and a later heartbeat on the same local day.
	restarted := New(httpClient, "https://example.test/api/v1/activity-watch/batches", "device-1", "credential", pendingPath)
	if err := restarted.CheckIn(context.Background(), firstSeen.Add(2*time.Hour)); err != nil {
		t.Fatal(err)
	}
	if receivedTimes[0] != receivedTimes[1] {
		t.Fatalf("retry changed original event time: %v", receivedTimes)
	}
	if _, err := os.Stat(pendingPath); !os.IsNotExist(err) {
		t.Fatalf("successful pending request was not cleared: %v", err)
	}
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (function roundTripFunc) RoundTrip(request *http.Request) (*http.Response, error) {
	return function(request)
}

func response(status int, body string) *http.Response {
	return &http.Response{
		StatusCode: status,
		Body:       io.NopCloser(strings.NewReader(body)),
		Header:     make(http.Header),
	}
}
