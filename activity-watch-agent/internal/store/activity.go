package store

import (
	"context"
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"os/user"
	"runtime"
	"sort"
	"strings"
	"time"

	"billing/activity-watch-agent/internal/collector"
	"billing/activity-watch-agent/internal/identifier"
)

type ApplicationTotal struct {
	Name           string `json:"name"`
	Classification string `json:"classification"`
	Seconds        int64  `json:"seconds"`
}

type DailySummaryPayload struct {
	WorkDateLocal  string             `json:"work_date_local"`
	Timezone       string             `json:"timezone"`
	FirstActiveAt  *string            `json:"first_active_at_utc,omitempty"`
	LastActiveAt   *string            `json:"last_active_at_utc,omitempty"`
	ActiveSeconds  int64              `json:"active_seconds"`
	IdleSeconds    int64              `json:"idle_seconds"`
	LockedSeconds  int64              `json:"locked_seconds"`
	OfflineSeconds int64              `json:"offline_seconds"`
	UnknownSeconds int64              `json:"unknown_seconds"`
	InputSeconds   int64              `json:"input_seconds"`
	BrowserSeconds int64              `json:"browser_seconds"`
	TrackedSeconds int64              `json:"tracked_seconds"`
	Applications   []ApplicationTotal `json:"applications"`
	Revision       int                `json:"revision"`
}

func (s *SQLCipherStore) StartSession(ctx context.Context, deviceID string, at time.Time) error {
	if strings.TrimSpace(deviceID) == "" {
		return errors.New("device identifier is required for collection")
	}
	sessionID, err := identifier.New()
	if err != nil {
		return err
	}
	localHash := sha256.Sum256([]byte("activity-watch-local-user:" + deviceID))
	localUserID := hex.EncodeToString(localHash[:16])
	identity := "unknown"
	if current, currentErr := user.Current(); currentErr == nil {
		identity = current.Uid + ":" + current.Username
	}
	identityHash := sha256.Sum256([]byte(identity))
	now := at.UTC().Format(time.RFC3339Nano)
	timezone := timezoneName(at)
	_, offset := at.Zone()
	consentHash := sha256.Sum256([]byte("activity-watch-consent-v1"))
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("begin session: %w", err)
	}
	defer tx.Rollback()
	_, err = tx.ExecContext(ctx, `
INSERT INTO local_users (
    id, server_user_id, company_id, device_id, platform, os_user_identity_hash,
    timezone, consent_policy_version, consent_text_hash, consented_at_utc,
    created_at_utc, last_authenticated_at_utc
) VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, ?, ?, ?)
ON CONFLICT(server_user_id, device_id) DO UPDATE SET
    platform = excluded.platform, os_user_identity_hash = excluded.os_user_identity_hash,
    timezone = excluded.timezone, consent_revoked_at_utc = NULL,
    last_authenticated_at_utc = excluded.last_authenticated_at_utc`,
		localUserID, deviceID, "device-scope", deviceID, platformName(),
		hex.EncodeToString(identityHash[:]), timezone, hex.EncodeToString(consentHash[:]), now, now, now)
	if err != nil {
		return fmt.Errorf("upsert local collection identity: %w", err)
	}
	_, err = tx.ExecContext(ctx, `
UPDATE device_sessions
SET ended_at_utc = ?, end_reason = 'crash-recovery', is_finalized = 1
WHERE local_user_id = ? AND is_finalized = 0`, now, localUserID)
	if err != nil {
		return fmt.Errorf("recover prior session: %w", err)
	}
	_, err = tx.ExecContext(ctx, `
INSERT INTO device_sessions (
    id, local_user_id, boot_id, started_at_utc, start_monotonic_ms,
    start_reason, agent_version, policy_version, timezone,
    timezone_offset_minutes, is_finalized, created_at_utc
) VALUES (?, ?, ?, ?, 0, 'agent-start', '1', 1, ?, ?, 0, ?)`,
		sessionID, localUserID, sessionID, now, timezone, offset/60, now)
	if err != nil {
		return fmt.Errorf("create device session: %w", err)
	}
	if err := tx.Commit(); err != nil {
		return fmt.Errorf("commit device session: %w", err)
	}
	s.localUserID = localUserID
	s.deviceID = deviceID
	s.sessionID = sessionID
	s.activitySegmentID = ""
	s.applicationSegmentID = ""
	return nil
}

func (s *SQLCipherStore) RecordObservation(ctx context.Context, observation collector.Snapshot, idleThreshold time.Duration) error {
	if s.sessionID == "" {
		return errors.New("collection session is not started")
	}
	at := observation.ObservedAt.UTC()
	if at.IsZero() {
		at = time.Now().UTC()
	}
	state := observation.State
	if !validActivityState(state) {
		state = "unknown"
	}
	networkState := observation.NetworkState
	if !validNetworkState(networkState) {
		networkState = "unknown"
	}
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("begin activity observation: %w", err)
	}
	defer tx.Rollback()
	if err := s.writeActivitySegment(ctx, tx, state, networkState, observation.InputDetected, at, observation.IdleFor, idleThreshold); err != nil {
		return err
	}
	application := strings.TrimSpace(observation.ExecutableName)
	if application == "" {
		application = strings.TrimSpace(observation.ApplicationName)
	}
	if state != "active" {
		application = ""
	}
	if err := s.writeApplicationSegment(ctx, tx, application, observation.Classification, at); err != nil {
		return err
	}
	if err := tx.Commit(); err != nil {
		return fmt.Errorf("commit activity observation: %w", err)
	}
	return nil
}

func (s *SQLCipherStore) writeActivitySegment(ctx context.Context, tx *sql.Tx, state, networkState string, inputDetected bool, at time.Time, idleFor, idleThreshold time.Duration) error {
	formatted := at.Format(time.RFC3339Nano)
	lastInput := at.Add(-idleFor).Format(time.RFC3339Nano)
	if s.activitySegmentID != "" && s.activityState == state && s.activityNetworkState == networkState && s.activityInputDetected == inputDetected {
		duration := nonNegativeSeconds(at.Sub(s.activityStartedAt))
		_, err := tx.ExecContext(ctx, `UPDATE activity_segments SET ended_at_utc = ?, duration_seconds = ?, last_input_at_utc = ? WHERE id = ?`, formatted, duration, lastInput, s.activitySegmentID)
		return wrapUpdateError("extend activity segment", err)
	}
	if s.activitySegmentID != "" {
		duration := nonNegativeSeconds(at.Sub(s.activityStartedAt))
		if _, err := tx.ExecContext(ctx, `UPDATE activity_segments SET ended_at_utc = ?, duration_seconds = ? WHERE id = ?`, formatted, duration, s.activitySegmentID); err != nil {
			return fmt.Errorf("close activity segment: %w", err)
		}
	}
	id, err := identifier.New()
	if err != nil {
		return err
	}
	_, err = tx.ExecContext(ctx, `
INSERT INTO activity_segments (
    id, session_id, activity_state, network_state, started_at_utc, ended_at_utc,
    duration_seconds, last_input_at_utc, idle_threshold_seconds, input_detected, created_at_utc
) VALUES (?, ?, ?, ?, ?, ?, 0, ?, ?, ?, ?)`, id, s.sessionID, state, networkState, formatted, formatted, lastInput, int64(idleThreshold/time.Second), inputDetected, formatted)
	if err != nil {
		return fmt.Errorf("create activity segment: %w", err)
	}
	s.activitySegmentID, s.activityState, s.activityStartedAt = id, state, at
	s.activityNetworkState = networkState
	s.activityInputDetected = inputDetected
	return nil
}

func (s *SQLCipherStore) writeApplicationSegment(ctx context.Context, tx *sql.Tx, application, classification string, at time.Time) error {
	formatted := at.Format(time.RFC3339Nano)
	if s.applicationSegmentID != "" && s.applicationName == application && application != "" {
		duration := nonNegativeSeconds(at.Sub(s.applicationStartedAt))
		_, err := tx.ExecContext(ctx, `UPDATE application_segments SET ended_at_utc = ?, duration_seconds = ? WHERE id = ?`, formatted, duration, s.applicationSegmentID)
		return wrapUpdateError("extend application segment", err)
	}
	if s.applicationSegmentID != "" {
		duration := nonNegativeSeconds(at.Sub(s.applicationStartedAt))
		if _, err := tx.ExecContext(ctx, `UPDATE application_segments SET ended_at_utc = ?, duration_seconds = ? WHERE id = ?`, formatted, duration, s.applicationSegmentID); err != nil {
			return fmt.Errorf("close application segment: %w", err)
		}
		s.applicationSegmentID = ""
		s.applicationName = ""
	}
	if application == "" {
		return nil
	}
	if !validClassification(classification) {
		classification = "unclassified"
	}
	id, err := identifier.New()
	if err != nil {
		return err
	}
	fingerprint := sha256.Sum256([]byte(strings.ToLower(application)))
	_, err = tx.ExecContext(ctx, `
INSERT INTO application_segments (
    id, session_id, process_fingerprint, process_name, executable_name,
    classification, started_at_utc, ended_at_utc, duration_seconds, created_at_utc
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, ?)`, id, s.sessionID,
		hex.EncodeToString(fingerprint[:]), application, application, classification, formatted, formatted, formatted)
	if err != nil {
		return fmt.Errorf("create application segment: %w", err)
	}
	s.applicationSegmentID, s.applicationName, s.applicationStartedAt = id, application, at
	return nil
}

func (s *SQLCipherStore) RecordInventory(ctx context.Context, inventoryType string, items []collector.InventoryItem, at time.Time) error {
	if s.sessionID == "" || (inventoryType != "processes" && inventoryType != "system-services") {
		return errors.New("invalid inventory snapshot")
	}
	if len(items) > 500 {
		items = items[:500]
	}
	sort.Slice(items, func(i, j int) bool {
		if items[i].Name == items[j].Name {
			return items[i].State < items[j].State
		}
		return items[i].Name < items[j].Name
	})
	payload, err := json.Marshal(struct {
		InventoryType string                    `json:"inventory_type"`
		CapturedAt    string                    `json:"captured_at_utc"`
		ItemCount     int                       `json:"item_count"`
		Items         []collector.InventoryItem `json:"items"`
	}{inventoryType, at.UTC().Format(time.RFC3339Nano), len(items), items})
	if err != nil {
		return fmt.Errorf("encode inventory: %w", err)
	}
	hash := sha256.Sum256(payload)
	hashText := hex.EncodeToString(hash[:])
	var exists int
	err = s.db.QueryRowContext(ctx, `SELECT 1 FROM inventory_snapshots WHERE session_id = ? AND inventory_type = ? AND snapshot_hash = ? LIMIT 1`, s.sessionID, inventoryType, hashText).Scan(&exists)
	if err == nil {
		return nil
	}
	if !errors.Is(err, sql.ErrNoRows) {
		return fmt.Errorf("check inventory snapshot: %w", err)
	}
	id, err := identifier.New()
	if err != nil {
		return err
	}
	ciphertext, nonce, tag, err := encryptPayload(s.payloadKey, payload)
	if err != nil {
		return err
	}
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	formatted := at.UTC().Format(time.RFC3339Nano)
	_, err = tx.ExecContext(ctx, `
INSERT INTO inventory_snapshots (
    id, session_id, inventory_type, snapshot_hash, item_count,
    payload_encrypted, payload_nonce, payload_tag, captured_at_utc, created_at_utc
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`, id, s.sessionID, inventoryType, hashText, len(items), ciphertext, nonce, tag, formatted, formatted)
	if err != nil {
		return fmt.Errorf("insert inventory snapshot: %w", err)
	}
	if err := s.queueOutbox(ctx, tx, "inventory-snapshot", id, payload, formatted, "inventory-snapshot:"+id); err != nil {
		return err
	}
	return tx.Commit()
}

func (s *SQLCipherStore) PrepareDailySummary(ctx context.Context, at time.Time) error {
	if s.localUserID == "" {
		return nil
	}
	if err := s.extendOpenSegments(ctx, at.UTC()); err != nil {
		return err
	}
	location := at.Location()
	localStart := time.Date(at.Year(), at.Month(), at.Day(), 0, 0, 0, 0, location)
	start, end := localStart.UTC(), localStart.AddDate(0, 0, 1).UTC()
	payload, summaryID, revision, err := s.aggregateSummary(ctx, localStart.Format("2006-01-02"), timezoneName(at), start, end)
	if err != nil {
		return err
	}
	payload.Revision = revision
	encoded, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("encode daily summary: %w", err)
	}
	checksum := sha256.Sum256(encoded)
	now := at.UTC().Format(time.RFC3339Nano)
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	_, err = tx.ExecContext(ctx, `
INSERT INTO daily_summaries (
    id, local_user_id, device_id, work_date_local, timezone, policy_version,
    first_active_at_utc, last_active_at_utc, active_seconds, idle_seconds,
    locked_seconds, offline_seconds, unknown_seconds, input_seconds, browser_seconds,
    tracked_seconds, summary_checksum,
    revision, is_finalized, created_at_utc, updated_at_utc
) VALUES (?, ?, ?, ?, ?, 1, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?)
ON CONFLICT(local_user_id, device_id, work_date_local) DO UPDATE SET
    first_active_at_utc = excluded.first_active_at_utc,
    last_active_at_utc = excluded.last_active_at_utc,
    active_seconds = excluded.active_seconds, idle_seconds = excluded.idle_seconds,
    locked_seconds = excluded.locked_seconds, offline_seconds = excluded.offline_seconds,
    unknown_seconds = excluded.unknown_seconds, input_seconds = excluded.input_seconds,
    browser_seconds = excluded.browser_seconds,
    tracked_seconds = excluded.tracked_seconds, summary_checksum = excluded.summary_checksum,
    revision = excluded.revision, updated_at_utc = excluded.updated_at_utc`,
		summaryID, s.localUserID, s.deviceID, payload.WorkDateLocal, payload.Timezone,
		payload.FirstActiveAt, payload.LastActiveAt, payload.ActiveSeconds, payload.IdleSeconds,
		payload.LockedSeconds, payload.OfflineSeconds, payload.UnknownSeconds, payload.InputSeconds,
		payload.BrowserSeconds, payload.TrackedSeconds,
		hex.EncodeToString(checksum[:]), revision, now, now)
	if err != nil {
		return fmt.Errorf("upsert daily summary: %w", err)
	}
	outboxID, err := identifier.New()
	if err != nil {
		return err
	}
	if err := s.queueOutboxWithID(ctx, tx, outboxID, "daily-summary", summaryID, encoded, now, fmt.Sprintf("daily-summary:%s:%d", summaryID, revision)); err != nil {
		return err
	}
	return tx.Commit()
}

func (s *SQLCipherStore) extendOpenSegments(ctx context.Context, at time.Time) error {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	formatted := at.Format(time.RFC3339Nano)
	if s.activitySegmentID != "" {
		if _, err := tx.ExecContext(ctx, `UPDATE activity_segments SET ended_at_utc = ?, duration_seconds = ? WHERE id = ?`, formatted, nonNegativeSeconds(at.Sub(s.activityStartedAt)), s.activitySegmentID); err != nil {
			return fmt.Errorf("extend current activity for summary: %w", err)
		}
	}
	if s.applicationSegmentID != "" {
		if _, err := tx.ExecContext(ctx, `UPDATE application_segments SET ended_at_utc = ?, duration_seconds = ? WHERE id = ?`, formatted, nonNegativeSeconds(at.Sub(s.applicationStartedAt)), s.applicationSegmentID); err != nil {
			return fmt.Errorf("extend current application for summary: %w", err)
		}
	}
	return tx.Commit()
}

func (s *SQLCipherStore) aggregateSummary(ctx context.Context, workDate, timezone string, start, end time.Time) (DailySummaryPayload, string, int, error) {
	payload := DailySummaryPayload{WorkDateLocal: workDate, Timezone: timezone, Applications: []ApplicationTotal{}}
	startText := start.Format(time.RFC3339Nano)
	endText := end.Format(time.RFC3339Nano)
	rows, err := s.db.QueryContext(ctx, `
SELECT activity_state,
       COALESCE(SUM(CAST(MAX(0, ROUND(
           (MIN(julianday(a.ended_at_utc), julianday(?)) -
            MAX(julianday(a.started_at_utc), julianday(?))) * 86400
       )) AS INTEGER)), 0),
       MIN(CASE WHEN julianday(a.started_at_utc) < julianday(?) THEN ? ELSE a.started_at_utc END),
       MAX(CASE WHEN julianday(a.ended_at_utc) > julianday(?) THEN ? ELSE a.ended_at_utc END)
FROM activity_segments a JOIN device_sessions d ON d.id = a.session_id
WHERE d.local_user_id = ?
  AND julianday(a.started_at_utc) < julianday(?)
  AND julianday(a.ended_at_utc) > julianday(?)
GROUP BY activity_state`, endText, startText, startText, startText, endText, endText,
		s.localUserID, endText, startText)
	if err != nil {
		return payload, "", 0, fmt.Errorf("aggregate activity summary: %w", err)
	}
	for rows.Next() {
		var state string
		var seconds int64
		var first, last sql.NullString
		if err := rows.Scan(&state, &seconds, &first, &last); err != nil {
			rows.Close()
			return payload, "", 0, err
		}
		switch state {
		case "active":
			payload.ActiveSeconds = seconds
			if first.Valid {
				payload.FirstActiveAt = &first.String
			}
			if last.Valid {
				payload.LastActiveAt = &last.String
			}
		case "idle":
			payload.IdleSeconds = seconds
		case "locked":
			payload.LockedSeconds = seconds
		default:
			payload.UnknownSeconds += seconds
		}
	}
	rows.Close()
	if err := s.db.QueryRowContext(ctx, `
SELECT COALESCE(SUM(CAST(MAX(0, ROUND(
           (MIN(julianday(a.ended_at_utc), julianday(?)) -
            MAX(julianday(a.started_at_utc), julianday(?))) * 86400
       )) AS INTEGER)), 0)
FROM activity_segments a JOIN device_sessions d ON d.id = a.session_id
WHERE d.local_user_id = ? AND a.network_state = 'offline'
  AND julianday(a.started_at_utc) < julianday(?)
  AND julianday(a.ended_at_utc) > julianday(?)`, endText, startText, s.localUserID,
		endText, startText).Scan(&payload.OfflineSeconds); err != nil {
		return payload, "", 0, fmt.Errorf("aggregate offline summary: %w", err)
	}
	payload.TrackedSeconds = payload.ActiveSeconds + payload.IdleSeconds + payload.LockedSeconds + payload.UnknownSeconds
	if err := s.db.QueryRowContext(ctx, `
SELECT COALESCE(SUM(CAST(MAX(0, ROUND(
           (MIN(julianday(a.ended_at_utc), julianday(?)) -
            MAX(julianday(a.started_at_utc), julianday(?))) * 86400
       )) AS INTEGER)), 0)
FROM activity_segments a JOIN device_sessions d ON d.id = a.session_id
WHERE d.local_user_id = ? AND a.input_detected = 1
  AND julianday(a.started_at_utc) < julianday(?)
  AND julianday(a.ended_at_utc) > julianday(?)`, endText, startText, s.localUserID,
		endText, startText).Scan(&payload.InputSeconds); err != nil {
		return payload, "", 0, fmt.Errorf("aggregate input summary: %w", err)
	}
	appRows, err := s.db.QueryContext(ctx, `
SELECT a.executable_name, a.classification,
       COALESCE(SUM(CAST(MAX(0, ROUND(
           (MIN(julianday(a.ended_at_utc), julianday(?)) -
            MAX(julianday(a.started_at_utc), julianday(?))) * 86400
       )) AS INTEGER)), 0)
FROM application_segments a JOIN device_sessions d ON d.id = a.session_id
WHERE d.local_user_id = ?
  AND julianday(a.started_at_utc) < julianday(?)
  AND julianday(a.ended_at_utc) > julianday(?)
GROUP BY executable_name, classification ORDER BY 3 DESC LIMIT 50`, endText, startText,
		s.localUserID, endText, startText)
	if err != nil {
		return payload, "", 0, fmt.Errorf("aggregate application summary: %w", err)
	}
	for appRows.Next() {
		var total ApplicationTotal
		if err := appRows.Scan(&total.Name, &total.Classification, &total.Seconds); err != nil {
			appRows.Close()
			return payload, "", 0, err
		}
		payload.Applications = append(payload.Applications, total)
		if total.Classification == "browser" {
			payload.BrowserSeconds += total.Seconds
		}
	}
	appRows.Close()
	var summaryID string
	var revision int
	err = s.db.QueryRowContext(ctx, `SELECT id, revision FROM daily_summaries WHERE local_user_id = ? AND device_id = ? AND work_date_local = ?`, s.localUserID, s.deviceID, workDate).Scan(&summaryID, &revision)
	if errors.Is(err, sql.ErrNoRows) {
		summaryID, err = identifier.New()
		revision = 1
	} else {
		revision++
	}
	return payload, summaryID, revision, err
}

func (s *SQLCipherStore) FinalizeSession(ctx context.Context, at time.Time, reason string) error {
	if s.sessionID == "" {
		return nil
	}
	now := at.UTC().Format(time.RFC3339Nano)
	_, err := s.db.ExecContext(ctx, `UPDATE device_sessions SET ended_at_utc = ?, end_reason = ?, is_finalized = 1 WHERE id = ?`, now, reason, s.sessionID)
	if err != nil {
		return fmt.Errorf("finalize device session: %w", err)
	}
	return nil
}

func (s *SQLCipherStore) PurgeExpired(ctx context.Context, cutoff time.Time) error {
	formatted := cutoff.UTC().Format(time.RFC3339Nano)
	statements := []string{
		`DELETE FROM sync_outbox WHERE id IN (SELECT id FROM sync_outbox WHERE status = 'synced' AND synced_at_utc < ? LIMIT 5000)`,
		`DELETE FROM device_sessions WHERE id IN (SELECT id FROM device_sessions WHERE is_finalized = 1 AND ended_at_utc < ? LIMIT 5000)`,
		`DELETE FROM system_events WHERE id IN (SELECT id FROM system_events WHERE event_at_utc < ? LIMIT 5000)`,
		`DELETE FROM daily_summaries WHERE id IN (SELECT id FROM daily_summaries WHERE updated_at_utc < ? LIMIT 5000)`,
	}
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	for _, statement := range statements {
		if _, err := tx.ExecContext(ctx, statement, formatted); err != nil {
			return fmt.Errorf("purge expired activity: %w", err)
		}
	}
	return tx.Commit()
}

func (s *SQLCipherStore) RequeueAuthenticationFailures(ctx context.Context, at time.Time) error {
	_, err := s.db.ExecContext(ctx, `
UPDATE sync_outbox SET status = 'retry', next_attempt_at_utc = ?, last_error_code = 'credential-refreshed'
WHERE status = 'permanently-failed' AND last_error_code IN ('http-401', 'http-403')`, at.UTC().Format(time.RFC3339Nano))
	return wrapUpdateError("requeue authentication failures", err)
}

func (s *SQLCipherStore) queueOutbox(ctx context.Context, tx *sql.Tx, entityType, entityID string, payload []byte, createdAt, idempotency string) error {
	id, err := identifier.New()
	if err != nil {
		return err
	}
	return s.queueOutboxWithID(ctx, tx, id, entityType, entityID, payload, createdAt, idempotency)
}

func (s *SQLCipherStore) queueOutboxWithID(ctx context.Context, tx *sql.Tx, id, entityType, entityID string, payload []byte, createdAt, idempotency string) error {
	ciphertext, nonce, tag, err := encryptPayload(s.payloadKey, payload)
	if err != nil {
		return err
	}
	checksum := sha256.Sum256(ciphertext)
	_, err = tx.ExecContext(ctx, `
INSERT INTO sync_outbox (
    id, entity_type, entity_id, operation, payload_encrypted, payload_nonce,
    payload_tag, payload_checksum, idempotency_key, status, created_at_utc
) VALUES (?, ?, ?, 'upsert', ?, ?, ?, ?, ?, 'pending', ?)`, id, entityType, entityID,
		ciphertext, nonce, tag, hex.EncodeToString(checksum[:]), idempotency, createdAt)
	if err != nil {
		return fmt.Errorf("queue %s: %w", entityType, err)
	}
	return nil
}

func validActivityState(value string) bool {
	switch value {
	case "active", "idle", "locked", "sleeping", "logged_out", "unknown":
		return true
	}
	return false
}

func validClassification(value string) bool {
	switch value {
	case "productive", "communication", "development", "browser", "system", "entertainment", "unclassified":
		return true
	}
	return false
}

func validNetworkState(value string) bool {
	switch value {
	case "online", "offline", "unknown":
		return true
	}
	return false
}

func nonNegativeSeconds(duration time.Duration) int64 {
	if duration <= 0 {
		return 0
	}
	return int64(duration / time.Second)
}

func platformName() string {
	switch runtime.GOOS {
	case "darwin":
		return "macos"
	case "windows", "linux":
		return runtime.GOOS
	default:
		return "other"
	}
}

func timezoneName(at time.Time) string {
	name := at.Location().String()
	if name != "" && name != "Local" {
		return name
	}
	_, offset := at.Zone()
	sign := "+"
	if offset < 0 {
		sign = "-"
		offset = -offset
	}
	return fmt.Sprintf("%s%02d:%02d", sign, offset/3600, (offset%3600)/60)
}
