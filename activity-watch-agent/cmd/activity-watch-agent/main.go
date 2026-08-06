package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/kardianos/service"

	"billing/activity-watch-agent/internal/agent"
	"billing/activity-watch-agent/internal/config"
	"billing/activity-watch-agent/internal/control"
	"billing/activity-watch-agent/internal/provision"
	"billing/activity-watch-agent/internal/secret"
	"billing/activity-watch-agent/internal/store"
	"billing/activity-watch-agent/internal/syncer"
)

const serviceDescription = "Consent-gated Activity Watch local persistence and synchronization service."

func main() {
	if err := run(os.Args); err != nil {
		log.Print(err)
		os.Exit(1)
	}
}

func run(arguments []string) error {
	if len(arguments) < 2 {
		return usageError()
	}
	command := arguments[1]
	flags := flag.NewFlagSet(command, flag.ContinueOnError)
	configPath := flags.String("config", "", "absolute path to the service configuration")
	if err := flags.Parse(arguments[2:]); err != nil {
		return err
	}
	if *configPath == "" || !filepath.IsAbs(*configPath) {
		return errors.New("--config must be an absolute path")
	}
	cfg, err := config.Load(*configPath)
	if err != nil {
		return err
	}

	if command == "signal-logout" {
		return control.NewLogoutMarker(cfg.Control.LogoutRequestPath).Signal()
	}
	if command == "provision" {
		result, err := provision.Create(context.Background(), cfg)
		if err != nil {
			return fmt.Errorf("provision Activity Watch storage: %w", err)
		}
		fmt.Printf("Provisioned encrypted Activity Watch database: %s\n", result.DatabasePath)
		return nil
	}

	program := &serviceProgram{config: cfg}
	serviceConfig := &service.Config{
		Name:        cfg.ServiceName,
		DisplayName: "Billing Activity Watch",
		Description: serviceDescription,
		Arguments:   []string{"run", "--config", *configPath},
		Option: service.KeyValue{
			"Restart": "on-failure",
		},
	}
	nativeService, err := service.New(program, serviceConfig)
	if err != nil {
		return fmt.Errorf("create native service: %w", err)
	}

	switch command {
	case "run":
		return nativeService.Run()
	case "install", "uninstall", "start", "stop", "restart":
		if err := service.Control(nativeService, command); err != nil {
			return fmt.Errorf("service %s: %w", command, err)
		}
		return nil
	case "status":
		status, err := nativeService.Status()
		if err != nil {
			return fmt.Errorf("service status: %w", err)
		}
		fmt.Println(statusText(status))
		return nil
	default:
		return usageError()
	}
}

type serviceProgram struct {
	config config.Config

	mu     sync.Mutex
	cancel context.CancelFunc
	done   chan error
	store  *store.SQLCipherStore
}

func (p *serviceProgram) Start(service.Service) error {
	p.mu.Lock()
	defer p.mu.Unlock()
	if p.cancel != nil {
		return errors.New("service is already running")
	}

	provider := secret.FileProvider{}
	key, err := provider.DatabaseKey(p.config.Database.KeyFile)
	if err != nil {
		return fmt.Errorf("load database key: %w", err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	database, err := store.OpenSQLCipher(ctx, p.config.Database.Path, key)
	clearBytes(key)
	if err != nil {
		cancel()
		return err
	}

	credential := ""
	if p.config.Sync.Enabled {
		credential, err = provider.DeviceCredential(p.config.Sync.CredentialFile)
		if err != nil {
			database.Close()
			cancel()
			return fmt.Errorf("load device credential: %w", err)
		}
	}
	httpClient := &http.Client{Timeout: p.config.Sync.RequestTimeout.Duration}
	uploader := syncer.New(database, httpClient, syncer.Config{
		Enabled:        p.config.Sync.Enabled,
		URL:            p.config.Sync.URL,
		DeviceID:       p.config.Sync.DeviceID,
		Credential:     credential,
		BatchSize:      p.config.Sync.BatchSize,
		BaseRetryDelay: p.config.Sync.BaseRetryDelay.Duration,
		MaxRetryDelay:  p.config.Sync.MaxRetryDelay.Duration,
	})
	runner := agent.NewRunner(
		database,
		uploader,
		control.NewLogoutMarker(p.config.Control.LogoutRequestPath),
		agent.Config{
			HeartbeatInterval:   p.config.Collection.HeartbeatInterval.Duration,
			SyncInterval:        p.config.Sync.Interval.Duration,
			ControlPollInterval: p.config.Control.PollInterval.Duration,
			ShutdownTimeout:     p.config.ShutdownFlushTimeout.Duration,
		},
	)
	runner.SetErrorLogger(func(operation string, err error) {
		log.Printf("activity-watch service: %s failed: %v", operation, err)
	})

	p.cancel = cancel
	done := make(chan error, 1)
	p.done = done
	p.store = database
	go func(completed chan<- error) {
		runError := runner.Run(ctx)
		completed <- runError
		if runError != nil && ctx.Err() == nil {
			log.Printf("activity-watch service terminated unexpectedly: %v", runError)
			os.Exit(1)
		}
	}(done)
	return nil
}

func (p *serviceProgram) Stop(service.Service) error {
	p.mu.Lock()
	if p.cancel == nil {
		p.mu.Unlock()
		return nil
	}
	cancel := p.cancel
	done := p.done
	database := p.store
	p.cancel = nil
	p.done = nil
	p.store = nil
	p.mu.Unlock()

	cancel()
	wait := p.config.ShutdownFlushTimeout.Duration + 2*time.Second
	var runError error
	select {
	case runError = <-done:
	case <-time.After(wait):
		runError = errors.New("service shutdown exceeded its deadline")
	}
	if errors.Is(runError, context.Canceled) {
		runError = nil
	}
	closeError := database.Close()
	return errors.Join(runError, closeError)
}

func statusText(status service.Status) string {
	switch status {
	case service.StatusRunning:
		return "running"
	case service.StatusStopped:
		return "stopped"
	default:
		return "unknown"
	}
}

func usageError() error {
	return errors.New("usage: activity-watch-agent <provision|install|uninstall|start|stop|restart|status|run|signal-logout> --config /absolute/path/config.json")
}

func clearBytes(value []byte) {
	for index := range value {
		value[index] = 0
	}
}
