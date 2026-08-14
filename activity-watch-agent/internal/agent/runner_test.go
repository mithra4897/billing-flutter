package agent

import (
	"context"
	"sync"
	"testing"
	"time"

	"billing/activity-watch-agent/internal/store"
)

func TestRunnerFlushesLogoutWithoutStoppingService(t *testing.T) {
	repository := &runnerRepository{}
	flusher := &runnerFlusher{called: make(chan struct{}, 10)}
	control := &runnerControl{}
	runner := NewRunner(repository, flusher, control, Config{
		HeartbeatInterval:   time.Hour,
		ControlPollInterval: 5 * time.Millisecond,
		ShutdownTimeout:     time.Second,
	})
	ctx, cancel := context.WithCancel(context.Background())
	done := make(chan error, 1)
	go func() { done <- runner.Run(ctx) }()

	// ERP logout is the sole upload boundary; startup must not flush.
	select {
	case <-flusher.called:
		t.Fatal("runner synchronized before logout")
	case <-time.After(20 * time.Millisecond):
	}
	control.mu.Lock()
	control.logout = true
	control.mu.Unlock()
	select {
	case <-flusher.called:
	case <-time.After(time.Second):
		t.Fatal("timed out waiting for logout synchronization")
	}
	select {
	case err := <-done:
		t.Fatalf("runner stopped on logout: %v", err)
	default:
	}

	cancel()
	select {
	case err := <-done:
		if err != nil {
			t.Fatalf("Run() error = %v", err)
		}
	case <-time.After(time.Second):
		t.Fatal("timed out waiting for runner shutdown")
	}

	events := repository.eventTypes()
	if !contains(events, "agent-start") || !contains(events, "user-logout") || !contains(events, "agent-stop") {
		t.Fatalf("events = %v", events)
	}
}

func TestRunnerFlushPendingDrainsEveryBatch(t *testing.T) {
	flusher := &countingFlusher{counts: []int{3, 2, 0}}
	runner := NewRunner(nil, flusher, nil, Config{})

	if err := runner.flushPending(context.Background()); err != nil {
		t.Fatalf("flushPending() error = %v", err)
	}
	if flusher.calls != 3 {
		t.Fatalf("Flush() calls = %d, want 3", flusher.calls)
	}
}

type runnerRepository struct {
	mu     sync.Mutex
	events []store.SystemEvent
}

func (f *runnerRepository) RecordSystemEvent(_ context.Context, event store.SystemEvent) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.events = append(f.events, event)
	return nil
}
func (f *runnerRepository) eventTypes() []string {
	f.mu.Lock()
	defer f.mu.Unlock()
	values := make([]string, len(f.events))
	for index, event := range f.events {
		values[index] = event.Type
	}
	return values
}
func (f *runnerRepository) RecoverProcessing(context.Context, time.Time) error { return nil }
func (f *runnerRepository) ClaimReadyBatch(context.Context, time.Time, int) ([]store.OutboxItem, error) {
	return nil, nil
}
func (f *runnerRepository) MarkSynced(context.Context, []string, time.Time) error { return nil }
func (f *runnerRepository) MarkRetry(context.Context, []string, time.Time, string) error {
	return nil
}
func (f *runnerRepository) MarkPermanentFailure(context.Context, []string, string) error {
	return nil
}
func (f *runnerRepository) Close() error { return nil }

type runnerFlusher struct {
	called chan struct{}
}

func (f *runnerFlusher) Flush(context.Context) (int, error) {
	f.called <- struct{}{}
	return 0, nil
}

type countingFlusher struct {
	counts []int
	calls  int
}

func (f *countingFlusher) Flush(context.Context) (int, error) {
	count := f.counts[f.calls]
	f.calls++
	return count, nil
}

type runnerControl struct {
	mu     sync.Mutex
	logout bool
}

func (f *runnerControl) Consume() (bool, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	value := f.logout
	f.logout = false
	return value, nil
}

func contains(values []string, expected string) bool {
	for _, value := range values {
		if value == expected {
			return true
		}
	}
	return false
}
