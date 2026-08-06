package agent

import (
	"context"
	"fmt"
	"time"

	"billing/activity-watch-agent/internal/store"
)

type Flusher interface {
	Flush(context.Context) (int, error)
}

type LogoutControl interface {
	Consume() (bool, error)
}

type Config struct {
	HeartbeatInterval   time.Duration
	SyncInterval        time.Duration
	ControlPollInterval time.Duration
	ShutdownTimeout     time.Duration
}

type Runner struct {
	repository store.Repository
	flusher    Flusher
	control    LogoutControl
	config     Config
	now        func() time.Time
	logError   func(string, error)
}

func NewRunner(repository store.Repository, flusher Flusher, control LogoutControl, config Config) *Runner {
	return &Runner{
		repository: repository,
		flusher:    flusher,
		control:    control,
		config:     config,
		now:        time.Now,
		logError:   func(string, error) {},
	}
}

func (r *Runner) SetErrorLogger(logger func(string, error)) {
	if logger != nil {
		r.logError = logger
	}
}

func (r *Runner) Run(ctx context.Context) error {
	now := r.now().UTC()
	if err := r.repository.RecoverProcessing(ctx, now); err != nil {
		return fmt.Errorf("recover service state: %w", err)
	}
	if err := r.record(ctx, "agent-start", now); err != nil {
		return err
	}
	if _, err := r.flusher.Flush(ctx); err != nil {
		r.logError("initial synchronization", err)
	}

	heartbeatTicker := time.NewTicker(r.config.HeartbeatInterval)
	syncTicker := time.NewTicker(r.config.SyncInterval)
	controlTicker := time.NewTicker(r.config.ControlPollInterval)
	defer heartbeatTicker.Stop()
	defer syncTicker.Stop()
	defer controlTicker.Stop()

	for {
		select {
		case <-ctx.Done():
			return r.shutdown()
		case at := <-heartbeatTicker.C:
			if err := r.record(ctx, "agent-heartbeat", at.UTC()); err != nil {
				r.logError("record heartbeat", err)
			}
		case <-syncTicker.C:
			if _, err := r.flusher.Flush(ctx); err != nil {
				r.logError("periodic synchronization", err)
			}
		case <-controlTicker.C:
			if err := r.consumeControl(ctx); err != nil {
				r.logError("consume service control", err)
			}
		}
	}
}

func (r *Runner) consumeControl(ctx context.Context) error {
	logout, err := r.control.Consume()
	if err != nil || !logout {
		return err
	}
	if err := r.record(ctx, "user-logout", r.now().UTC()); err != nil {
		return err
	}
	if _, err := r.flusher.Flush(ctx); err != nil {
		return fmt.Errorf("logout synchronization: %w", err)
	}
	return nil
}

func (r *Runner) shutdown() error {
	ctx, cancel := context.WithTimeout(context.Background(), r.config.ShutdownTimeout)
	defer cancel()
	var firstError error
	if err := r.record(ctx, "agent-stop", r.now().UTC()); err != nil {
		firstError = err
	}
	if _, err := r.flusher.Flush(ctx); err != nil && firstError == nil {
		firstError = fmt.Errorf("final synchronization: %w", err)
	}
	return firstError
}

func (r *Runner) record(ctx context.Context, eventType string, occurredAt time.Time) error {
	return r.repository.RecordSystemEvent(ctx, store.SystemEvent{
		Type:       eventType,
		OccurredAt: occurredAt,
	})
}
