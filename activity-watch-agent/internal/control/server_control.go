package control

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

// ServerLogoutControl polls the ERP server for a flush signal.
// It is used when the ERP runs as a web application and cannot
// invoke the agent executable directly.
type ServerLogoutControl struct {
	httpClient *http.Client
	controlURL string
	deviceID   string
	credential string
}

// NewServerLogoutControl creates a ServerLogoutControl.
// controlURL must be the absolute URL of the GET /activity-watch/control endpoint.
func NewServerLogoutControl(httpClient *http.Client, controlURL, deviceID, credential string) *ServerLogoutControl {
	return &ServerLogoutControl{
		httpClient: httpClient,
		controlURL: controlURL,
		deviceID:   deviceID,
		credential: credential,
	}
}

type controlResponse struct {
	Success bool `json:"success"`
	Data    struct {
		Flush bool `json:"flush"`
	} `json:"data"`
}

type acknowledgementResponse struct {
	Success bool `json:"success"`
	Data    struct {
		Acknowledged bool `json:"acknowledged"`
	} `json:"data"`
}

// Consume polls the server and returns true when the server requests a flush.
// It does not reset the flag; Acknowledge clears it only after the runner has
// successfully drained the complete outbox.
func (s *ServerLogoutControl) Consume() (bool, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, s.controlURL, nil)
	if err != nil {
		return false, fmt.Errorf("build control request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+s.credential)
	req.Header.Set("X-Device-Id", s.deviceID)

	resp, err := s.httpClient.Do(req)
	if err != nil {
		// Network errors are transient — don't treat as a hard failure.
		return false, fmt.Errorf("control poll: %w", err)
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))

	if resp.StatusCode == http.StatusUnauthorized || resp.StatusCode == http.StatusForbidden {
		return false, fmt.Errorf("control poll: device credential rejected (%d)", resp.StatusCode)
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		detail := strings.TrimSpace(string(body))
		if len(detail) > 200 {
			detail = detail[:200]
		}
		return false, fmt.Errorf("control poll: unexpected status %d: %s", resp.StatusCode, detail)
	}

	var parsed controlResponse
	if err := json.Unmarshal(body, &parsed); err != nil {
		return false, fmt.Errorf("control poll: decode response: %w", err)
	}
	if !parsed.Success {
		return false, errors.New("control poll: server did not report success")
	}
	return parsed.Data.Flush, nil
}

// Acknowledge clears the server flush flag after the runner has drained the
// complete local outbox. It is intentionally separate from batch upload so an
// empty outbox and exact batch-size multiples complete correctly.
func (s *ServerLogoutControl) Acknowledge(ctx context.Context) error {
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()

	url := strings.TrimSuffix(s.controlURL, "/") + "/acknowledge"
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, nil)
	if err != nil {
		return fmt.Errorf("build control acknowledgement: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+s.credential)
	req.Header.Set("X-Device-Id", s.deviceID)

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("control acknowledgement: %w", err)
	}
	defer resp.Body.Close()
	body, readErr := io.ReadAll(io.LimitReader(resp.Body, 4097))
	if readErr != nil {
		return fmt.Errorf("control acknowledgement: read response: %w", readErr)
	}
	if len(body) > 4096 {
		return errors.New("control acknowledgement: response exceeds 4096 bytes")
	}
	if resp.StatusCode == http.StatusUnauthorized || resp.StatusCode == http.StatusForbidden {
		return fmt.Errorf("control acknowledgement: device credential rejected (%d)", resp.StatusCode)
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("control acknowledgement: unexpected status %d", resp.StatusCode)
	}

	var parsed acknowledgementResponse
	if err := json.Unmarshal(body, &parsed); err != nil {
		return fmt.Errorf("control acknowledgement: decode response: %w", err)
	}
	if !parsed.Success || !parsed.Data.Acknowledged {
		return errors.New("control acknowledgement: server did not confirm completion")
	}
	return nil
}
