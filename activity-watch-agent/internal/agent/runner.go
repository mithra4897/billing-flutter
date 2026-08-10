package agent

import (
	"context"
	"fmt"
	"time"

	"billing/activity-watch-agent/internal/collector"
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

type CollectionConfig struct {
	DeviceID                 string
	SampleInterval           time.Duration
	IdleThreshold            time.Duration
	ProcessInventoryInterval time.Duration
	ServiceInventoryInterval time.Duration
	SummaryInterval          time.Duration
	RetentionDays            int
}

type ActivityRecorder interface {
	StartSession(context.Context, string, time.Time) error
	RecordObservation(context.Context, collector.Snapshot, time.Duration) error
	RecordInventory(context.Context, string, []collector.InventoryItem, time.Time) error
	PrepareDailySummary(context.Context, time.Time) error
	FinalizeSession(context.Context, time.Time, string) error
	PurgeExpired(context.Context, time.Time) error
	RequeueAuthenticationFailures(context.Context, time.Time) error
}

type Runner struct {
	repository       store.Repository
	flusher          Flusher
	control          LogoutControl
	config           Config
	now              func() time.Time
	logError         func(string, error)
	observer         collector.Observer
	recorder         ActivityRecorder
	collection       CollectionConfig
	collectionActive bool
	lastSampleAt     time.Time
	lastState        string
	lastTimezone     string
	lastUTCOffset    int
}

func (r *Runner) ConfigureCollection(observer collector.Observer, recorder ActivityRecorder, config CollectionConfig) {
	r.observer = observer
	r.recorder = recorder
	r.collection = config
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
	localNow := r.now()
	now := localNow.UTC()
	if err := r.repository.RecoverProcessing(ctx, now); err != nil {
		return fmt.Errorf("recover service state: %w", err)
	}
	if r.observer != nil && r.recorder != nil {
		if err := r.recorder.StartSession(ctx, r.collection.DeviceID, localNow); err != nil {
			return fmt.Errorf("start collection session: %w", err)
		}
		r.collectionActive = true
		if err := r.recorder.RequeueAuthenticationFailures(ctx, now); err != nil {
			r.logError("requeue credential failures", err)
		}
		if err := r.recorder.PurgeExpired(ctx, now.AddDate(0, 0, -r.collection.RetentionDays)); err != nil {
			r.logError("purge expired activity", err)
		}
		r.sample(ctx, localNow)
		r.inventory(ctx, "processes", localNow)
		r.inventory(ctx, "system-services", localNow)
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
	var sampleTicker, processTicker, serviceTicker, summaryTicker *time.Ticker
	var sampleC, processC, serviceC, summaryC <-chan time.Time
	if r.collectionActive {
		sampleTicker = time.NewTicker(r.collection.SampleInterval)
		processTicker = time.NewTicker(r.collection.ProcessInventoryInterval)
		serviceTicker = time.NewTicker(r.collection.ServiceInventoryInterval)
		summaryTicker = time.NewTicker(r.collection.SummaryInterval)
		sampleC, processC, serviceC, summaryC = sampleTicker.C, processTicker.C, serviceTicker.C, summaryTicker.C
	}
	defer heartbeatTicker.Stop()
	defer syncTicker.Stop()
	defer controlTicker.Stop()
	if sampleTicker != nil {
		defer sampleTicker.Stop()
	}
	if processTicker != nil {
		defer processTicker.Stop()
	}
	if serviceTicker != nil {
		defer serviceTicker.Stop()
	}
	if summaryTicker != nil {
		defer summaryTicker.Stop()
	}

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
		case at := <-sampleC:
			if r.collectionActive {
				r.sample(ctx, at)
			}
		case at := <-processC:
			if r.collectionActive {
				r.inventory(ctx, "processes", at)
			}
		case at := <-serviceC:
			if r.collectionActive {
				r.inventory(ctx, "system-services", at)
			}
		case at := <-summaryC:
			if r.collectionActive {
				if err := r.recorder.PrepareDailySummary(ctx, at); err != nil {
					r.logError("prepare daily summary", err)
				} else if _, err := r.flusher.Flush(ctx); err != nil {
					r.logError("summary synchronization", err)
				}
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
	if r.collectionActive {
		now := r.now()
		if err := r.recorder.PrepareDailySummary(ctx, now); err != nil {
			return err
		}
		if err := r.recorder.FinalizeSession(ctx, now, "logout"); err != nil {
			return err
		}
		// A user logout ends the current session, but the service remains alive.
		// Start a fresh local session so activity continues to be collected and
		// durably saved until the device/service is actually shut down.
		if err := r.recorder.StartSession(ctx, r.collection.DeviceID, now); err != nil {
			return fmt.Errorf("restart collection session after logout: %w", err)
		}
		r.collectionActive = true
	}
	if err := r.flushPending(ctx); err != nil {
		return fmt.Errorf("logout synchronization: %w", err)
	}
	return nil
}

func (r *Runner) shutdown() error {
	ctx, cancel := context.WithTimeout(context.Background(), r.config.ShutdownTimeout)
	defer cancel()
	var firstError error
	if r.collectionActive {
		now := r.now()
		if err := r.recorder.PrepareDailySummary(ctx, now); err != nil {
			firstError = err
		}
		if err := r.recorder.FinalizeSession(ctx, now, "service-stop"); err != nil && firstError == nil {
			firstError = err
		}
	}
	if err := r.record(ctx, "agent-stop", r.now().UTC()); err != nil {
		firstError = err
	}
	if err := r.flushPending(ctx); err != nil && firstError == nil {
		firstError = fmt.Errorf("final synchronization: %w", err)
	}
	return firstError
}

// flushPending drains the durable outbox rather than uploading only one batch.
// This is used at lifecycle boundaries so logout and service shutdown do not
// leave older locally saved summaries waiting for the next agent start.
func (r *Runner) flushPending(ctx context.Context) error {
	for {
		count, err := r.flusher.Flush(ctx)
		if err != nil {
			return err
		}
		if count == 0 {
			return nil
		}
	}
}

func (r *Runner) sample(ctx context.Context, at time.Time) {
	localAt := at
	_, offset := localAt.Zone()
	if r.lastTimezone != "" && (r.lastTimezone != localAt.Location().String() || r.lastUTCOffset != offset) {
		if err := r.record(ctx, "timezone-change", at.UTC()); err != nil {
			r.logError("record timezone change", err)
		}
	}
	r.lastTimezone, r.lastUTCOffset = localAt.Location().String(), offset
	if !r.lastSampleAt.IsZero() && at.Sub(r.lastSampleAt) > 3*r.collection.SampleInterval {
		sleepAt := r.lastSampleAt.Add(r.collection.SampleInterval)
		sleeping := collector.Snapshot{State: "sleeping", ObservedAt: sleepAt.UTC()}
		if err := r.recorder.RecordObservation(ctx, sleeping, r.collection.IdleThreshold); err != nil {
			r.logError("record inferred sleep", err)
		}
		if err := r.record(ctx, "sleep", sleepAt.UTC()); err != nil {
			r.logError("record sleep", err)
		}
		if err := r.record(ctx, "resume", at.UTC()); err != nil {
			r.logError("record resume", err)
		}
	}
	snapshot, err := r.observer.Sample(ctx, at, r.collection.IdleThreshold)
	if snapshot.State == "locked" && r.lastState != "locked" {
		if eventErr := r.record(ctx, "lock", at.UTC()); eventErr != nil {
			r.logError("record lock", eventErr)
		}
	} else if r.lastState == "locked" && snapshot.State != "locked" {
		if eventErr := r.record(ctx, "unlock", at.UTC()); eventErr != nil {
			r.logError("record unlock", eventErr)
		}
	}
	if recordErr := r.recorder.RecordObservation(ctx, snapshot, r.collection.IdleThreshold); recordErr != nil {
		r.logError("record activity sample", recordErr)
	}
	if err != nil {
		r.logError("collect activity sample", err)
	}
	r.lastSampleAt = at
	r.lastState = snapshot.State
}

func (r *Runner) inventory(ctx context.Context, inventoryType string, at time.Time) {
	var items []collector.InventoryItem
	var err error
	if inventoryType == "processes" {
		items, err = r.observer.ProcessInventory(ctx)
	} else {
		items, err = r.observer.ServiceInventory(ctx)
	}
	if err != nil {
		r.logError("collect "+inventoryType+" inventory", err)
		return
	}
	if err := r.recorder.RecordInventory(ctx, inventoryType, items, at); err != nil {
		r.logError("record "+inventoryType+" inventory", err)
	}
}

func (r *Runner) record(ctx context.Context, eventType string, occurredAt time.Time) error {
	return r.repository.RecordSystemEvent(ctx, store.SystemEvent{
		Type:       eventType,
		OccurredAt: occurredAt,
	})
}
