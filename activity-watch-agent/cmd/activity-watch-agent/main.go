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
	"billing/activity-watch-agent/internal/collector"
	"billing/activity-watch-agent/internal/config"
	"billing/activity-watch-agent/internal/control"
	"billing/activity-watch-agent/internal/pairing"
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
	bundlePath := flags.String("bundle", "", "absolute path to a .billingawpair file")
	if err := flags.Parse(arguments[2:]); err != nil {
		return err
	}
	if *configPath == "" || !filepath.IsAbs(*configPath) {
		return errors.New("--config must be an absolute path")
	}
	if command == "bootstrap" {
		return bootstrap(*configPath)
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
	if command == "pair" {
		if *bundlePath == "" || !filepath.IsAbs(*bundlePath) {
			return errors.New("--bundle must be an absolute path")
		}
		result, err := pairing.Apply(context.Background(), *bundlePath, *configPath, nil)
		if err != nil {
			return fmt.Errorf("pair Activity Watch agent: %w", err)
		}
		cfg, err = config.Load(*configPath)
		if err != nil {
			return err
		}
		if err := activateService(cfg, *configPath); err != nil {
			return fmt.Errorf("activate paired service: %w", err)
		}
		fmt.Printf("Activity Watch connected: %s\n", result.DeviceID)
		return nil
	}

	program := &serviceProgram{config: cfg}
	nativeService, err := newNativeService(program, cfg, *configPath)
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
	if !p.config.Collection.Disabled && p.config.Sync.Enabled {
		runner.ConfigureCollection(collector.NewOSObserver(), database, agent.CollectionConfig{
			DeviceID:                 p.config.Sync.DeviceID,
			SampleInterval:           p.config.Collection.SampleInterval.Duration,
			IdleThreshold:            p.config.Collection.IdleThreshold.Duration,
			ProcessInventoryInterval: p.config.Collection.ProcessInventoryInterval.Duration,
			ServiceInventoryInterval: p.config.Collection.ServiceInventoryInterval.Duration,
			SummaryInterval:          p.config.Collection.SummaryInterval.Duration,
			RetentionDays:            p.config.Collection.RetentionDays,
		})
	}

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
	return errors.New("usage: activity-watch-agent <bootstrap|pair|provision|install|uninstall|start|stop|restart|status|run|signal-logout> --config /absolute/path/config.json [--bundle /absolute/path/device.billingawpair]")
}

func bootstrap(configPath string) error {
	cfg, err := config.Load(configPath)
	if errors.Is(err, os.ErrNotExist) {
		cfg = config.NewUnpaired(filepath.Dir(configPath))
		if err := config.WriteNew(configPath, cfg); err != nil {
			return err
		}
	} else if err != nil {
		return err
	}
	databaseExists := pathExists(cfg.Database.Path)
	keyExists := pathExists(cfg.Database.KeyFile)
	if databaseExists != keyExists {
		return errors.New("database and key must either both exist or both be absent")
	}
	if !databaseExists {
		if _, err := provision.Create(context.Background(), cfg); err != nil {
			return err
		}
	}
	if err := activateService(cfg, configPath); err != nil {
		return err
	}
	fmt.Println("Activity Watch agent installed and ready for ERP pairing.")
	return nil
}

func pathExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

func activateService(cfg config.Config, configPath string) error {
	program := &serviceProgram{config: cfg}
	nativeService, err := newNativeService(program, cfg, configPath)
	if err != nil {
		return err
	}
	status, statusErr := nativeService.Status()
	if statusErr != nil {
		if err := service.Control(nativeService, "install"); err != nil {
			return err
		}
		return service.Control(nativeService, "start")
	}
	if status == service.StatusRunning {
		return service.Control(nativeService, "restart")
	}
	return service.Control(nativeService, "start")
}

func newNativeService(program *serviceProgram, cfg config.Config, configPath string) (service.Service, error) {
	return service.New(program, &service.Config{
		Name:        cfg.ServiceName,
		DisplayName: "Billing Activity Watch",
		Description: serviceDescription,
		Arguments:   []string{"run", "--config", configPath},
		Option: service.KeyValue{
			"Restart":     "on-failure",
			"UserService": true,
		},
	})
}

func clearBytes(value []byte) {
	for index := range value {
		value[index] = 0
	}
}
