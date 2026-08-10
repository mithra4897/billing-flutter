package store

import (
	"context"
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/url"
	"os"
	"sort"
	"strings"
	"time"

	_ "github.com/mutecomm/go-sqlcipher/v4"

	"billing/activity-watch-agent/internal/identifier"
)

const SupportedSchemaVersion = 3

var expectedTables = []string{
	"activity_segments",
	"agent_state",
	"application_segments",
	"browser_activity_segments",
	"daily_summaries",
	"device_sessions",
	"inventory_snapshots",
	"local_users",
	"sync_outbox",
	"system_events",
}

type SystemEvent struct {
	Type       string
	OccurredAt time.Time
	BootID     string
}

type OutboxItem struct {
	ID             string          `json:"id"`
	EntityType     string          `json:"entity_type"`
	EntityID       string          `json:"entity_id"`
	Operation      string          `json:"operation"`
	Payload        []byte          `json:"payload_encrypted"`
	Nonce          []byte          `json:"payload_nonce"`
	Tag            []byte          `json:"payload_tag"`
	Checksum       string          `json:"payload_checksum"`
	IdempotencyKey string          `json:"idempotency_key"`
	AttemptCount   int             `json:"attempt_count"`
	Metadata       json.RawMessage `json:"metadata,omitempty"`
}

type Repository interface {
	RecordSystemEvent(context.Context, SystemEvent) error
	RecoverProcessing(context.Context, time.Time) error
	ClaimReadyBatch(context.Context, time.Time, int) ([]OutboxItem, error)
	MarkSynced(context.Context, []string, time.Time) error
	MarkRetry(context.Context, []string, time.Time, string) error
	MarkPermanentFailure(context.Context, []string, string) error
	Close() error
}

type SQLCipherStore struct {
	db                       *sql.DB
	payloadKey               []byte
	deviceID                 string
	localUserID              string
	sessionID                string
	activitySegmentID        string
	activityState            string
	activityNetworkState     string
	activityInputDetected    bool
	activityKeyboardDetected bool
	activityMouseDetected    bool
	activityStartedAt        time.Time
	applicationSegmentID     string
	applicationName          string
	applicationTitle         string
	applicationStartedAt     time.Time
}

func OpenSQLCipher(ctx context.Context, path string, key []byte) (*SQLCipherStore, error) {
	if len(key) != 32 {
		return nil, errors.New("SQLCipher key must contain exactly 32 bytes")
	}
	if _, err := os.Stat(path); err != nil {
		return nil, fmt.Errorf("inspect provisioned database: %w", err)
	}

	db, err := openDatabase(path, key)
	if err != nil {
		return nil, err
	}
	store := &SQLCipherStore{
		db:         db,
		payloadKey: append([]byte(nil), key...),
	}
	if err := store.verify(ctx); err != nil {
		db.Close()
		return nil, err
	}
	return store, nil
}

func openDatabase(path string, key []byte) (*sql.DB, error) {
	query := url.Values{}
	query.Set("_pragma_key", fmt.Sprintf("x'%s'", hex.EncodeToString(key)))
	query.Set("_pragma_cipher_page_size", "4096")
	query.Set("_busy_timeout", "5000")
	query.Set("_foreign_keys", "on")
	db, err := sql.Open("sqlite3", path+"?"+query.Encode())
	if err != nil {
		return nil, errors.New("open encrypted database")
	}
	db.SetMaxOpenConns(1)
	db.SetMaxIdleConns(1)
	return db, nil
}

func (s *SQLCipherStore) verify(ctx context.Context) error {
	if err := verifyCipherRuntime(ctx, s.db); err != nil {
		return err
	}
	if err := configureConnection(ctx, s.db); err != nil {
		return err
	}

	var schemaVersion int
	if err := s.db.QueryRowContext(ctx, "PRAGMA user_version").Scan(&schemaVersion); err != nil {
		return errors.New("read schema version")
	}
	if schemaVersion == 1 {
		if err := s.upgradeVersionOne(ctx); err != nil {
			return err
		}
		schemaVersion = 2
	}
	if schemaVersion == 2 {
		if err := s.upgradeVersionTwo(ctx); err != nil {
			return err
		}
		schemaVersion = 3
	}
	if schemaVersion != SupportedSchemaVersion {
		return fmt.Errorf("unsupported Activity Watch schema version %d", schemaVersion)
	}

	rows, err := s.db.QueryContext(ctx, "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name")
	if err != nil {
		return errors.New("read schema tables")
	}
	defer rows.Close()
	var actual []string
	for rows.Next() {
		var name string
		if err := rows.Scan(&name); err != nil {
			return errors.New("scan schema table")
		}
		actual = append(actual, name)
	}
	if err := rows.Err(); err != nil {
		return errors.New("iterate schema tables")
	}
	sort.Strings(actual)
	if strings.Join(actual, "\n") != strings.Join(expectedTables, "\n") {
		return errors.New("database does not contain the approved 10-table Activity Watch schema")
	}
	return nil
}

func (s *SQLCipherStore) upgradeVersionTwo(ctx context.Context) error {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("begin Activity Watch schema v3 upgrade: %w", err)
	}
	defer tx.Rollback()
	statements := []string{
		`ALTER TABLE activity_segments ADD COLUMN keyboard_detected INTEGER NOT NULL DEFAULT 0 CHECK (keyboard_detected IN (0, 1))`,
		`ALTER TABLE activity_segments ADD COLUMN mouse_detected INTEGER NOT NULL DEFAULT 0 CHECK (mouse_detected IN (0, 1))`,
		`ALTER TABLE daily_summaries ADD COLUMN keyboard_active_seconds INTEGER NOT NULL DEFAULT 0 CHECK (keyboard_active_seconds >= 0)`,
		`ALTER TABLE daily_summaries ADD COLUMN mouse_active_seconds INTEGER NOT NULL DEFAULT 0 CHECK (mouse_active_seconds >= 0)`,
	}
	for _, statement := range statements {
		if _, err := tx.ExecContext(ctx, statement); err != nil {
			return fmt.Errorf("upgrade Activity Watch schema to v3: %w", err)
		}
	}
	if _, err := tx.ExecContext(ctx, `PRAGMA user_version = 3`); err != nil {
		return fmt.Errorf("record Activity Watch schema v3 upgrade: %w", err)
	}
	return tx.Commit()
}

func (s *SQLCipherStore) upgradeVersionOne(ctx context.Context) error {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("begin Activity Watch schema upgrade: %w", err)
	}
	defer tx.Rollback()
	statements := []string{
		`ALTER TABLE activity_segments ADD COLUMN input_detected INTEGER NOT NULL DEFAULT 0 CHECK (input_detected IN (0, 1))`,
		`ALTER TABLE daily_summaries ADD COLUMN input_seconds INTEGER NOT NULL DEFAULT 0 CHECK (input_seconds >= 0)`,
		`ALTER TABLE daily_summaries ADD COLUMN browser_seconds INTEGER NOT NULL DEFAULT 0 CHECK (browser_seconds >= 0)`,
	}
	for _, statement := range statements {
		if _, err := tx.ExecContext(ctx, statement); err != nil {
			return fmt.Errorf("upgrade Activity Watch schema: %w", err)
		}
	}
	if _, err := tx.ExecContext(ctx, `PRAGMA user_version = 2`); err != nil {
		return fmt.Errorf("record Activity Watch schema upgrade: %w", err)
	}
	return tx.Commit()
}

func verifyCipherRuntime(ctx context.Context, db *sql.DB) error {
	var cipherVersion string
	if err := db.QueryRowContext(ctx, "PRAGMA cipher_version").Scan(&cipherVersion); err != nil || strings.TrimSpace(cipherVersion) == "" {
		return errors.New("SQLCipher runtime verification failed")
	}
	return nil
}

func configureConnection(ctx context.Context, db *sql.DB) error {
	if _, err := db.ExecContext(ctx, "PRAGMA foreign_keys = ON"); err != nil {
		return errors.New("enable foreign keys")
	}
	if _, err := db.ExecContext(ctx, "PRAGMA secure_delete = ON"); err != nil {
		return errors.New("enable secure deletion")
	}
	if _, err := db.ExecContext(ctx, "PRAGMA synchronous = FULL"); err != nil {
		return errors.New("configure synchronous writes")
	}
	var journalMode string
	if err := db.QueryRowContext(ctx, "PRAGMA journal_mode = WAL").Scan(&journalMode); err != nil {
		return fmt.Errorf("configure WAL: %w", err)
	}
	if strings.ToLower(journalMode) != "wal" {
		return fmt.Errorf("configure WAL: database selected %q mode", journalMode)
	}
	return nil
}

func (s *SQLCipherStore) RecordSystemEvent(ctx context.Context, event SystemEvent) error {
	id, err := identifier.New()
	if err != nil {
		return err
	}
	occurredAt := event.OccurredAt.UTC().Format(time.RFC3339Nano)
	payload, err := json.Marshal(struct {
		EventType  string `json:"event_type"`
		OccurredAt string `json:"occurred_at_utc"`
	}{
		EventType:  event.Type,
		OccurredAt: occurredAt,
	})
	if err != nil {
		return fmt.Errorf("encode system event: %w", err)
	}
	ciphertext, nonce, tag, err := encryptPayload(s.payloadKey, payload)
	if err != nil {
		return fmt.Errorf("encrypt system event: %w", err)
	}
	checksum := sha256.Sum256(ciphertext)
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("begin system event: %w", err)
	}
	defer tx.Rollback()
	_, err = tx.ExecContext(ctx, `
INSERT INTO system_events (
    id, boot_id, event_type, event_at_utc, created_at_utc
) VALUES (?, NULLIF(?, ''), ?, ?, ?)`, id, event.BootID, event.Type, occurredAt, occurredAt)
	if err != nil {
		return fmt.Errorf("record system event: %w", err)
	}
	_, err = tx.ExecContext(ctx, `
INSERT INTO sync_outbox (
    id, entity_type, entity_id, operation, payload_encrypted, payload_nonce,
    payload_tag, payload_checksum, idempotency_key, status, created_at_utc
) VALUES (?, 'system-event', ?, 'upsert', ?, ?, ?, ?, ?, 'pending', ?)`,
		id, id, ciphertext, nonce, tag, hex.EncodeToString(checksum[:]), "system-event:"+id, occurredAt)
	if err != nil {
		return fmt.Errorf("queue system event: %w", err)
	}
	if err := tx.Commit(); err != nil {
		return fmt.Errorf("commit system event: %w", err)
	}
	return nil
}

func (s *SQLCipherStore) RecoverProcessing(ctx context.Context, now time.Time) error {
	_, err := s.db.ExecContext(ctx, `
UPDATE sync_outbox
SET status = 'retry', next_attempt_at_utc = ?, last_error_code = 'service-restart'
WHERE status = 'processing'`, now.UTC().Format(time.RFC3339Nano))
	if err != nil {
		return fmt.Errorf("recover processing outbox records: %w", err)
	}
	return nil
}

func (s *SQLCipherStore) ClaimReadyBatch(ctx context.Context, now time.Time, limit int) ([]OutboxItem, error) {
	if limit < 1 || limit > 500 {
		return nil, errors.New("batch limit must be between 1 and 500")
	}
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return nil, fmt.Errorf("begin outbox claim: %w", err)
	}
	defer tx.Rollback()

	rows, err := tx.QueryContext(ctx, `
SELECT id, entity_type, entity_id, operation, payload_encrypted,
       payload_nonce, payload_tag, payload_checksum, idempotency_key,
       attempt_count
FROM sync_outbox
WHERE status IN ('pending', 'retry')
  AND (next_attempt_at_utc IS NULL OR next_attempt_at_utc <= ?)
ORDER BY next_attempt_at_utc IS NOT NULL, next_attempt_at_utc, created_at_utc
LIMIT ?`, now.UTC().Format(time.RFC3339Nano), limit)
	if err != nil {
		return nil, fmt.Errorf("select ready outbox batch: %w", err)
	}
	var items []OutboxItem
	for rows.Next() {
		var item OutboxItem
		if err := rows.Scan(
			&item.ID,
			&item.EntityType,
			&item.EntityID,
			&item.Operation,
			&item.Payload,
			&item.Nonce,
			&item.Tag,
			&item.Checksum,
			&item.IdempotencyKey,
			&item.AttemptCount,
		); err != nil {
			rows.Close()
			return nil, fmt.Errorf("scan outbox item: %w", err)
		}
		if metadataAllowed(item.EntityType) {
			plaintext, decryptErr := decryptPayload(s.payloadKey, item.Payload, item.Nonce, item.Tag)
			if decryptErr != nil || !json.Valid(plaintext) {
				rows.Close()
				return nil, fmt.Errorf("decode outbox metadata for %s", item.ID)
			}
			item.Metadata = append(json.RawMessage(nil), plaintext...)
		}
		items = append(items, item)
	}
	if err := rows.Close(); err != nil {
		return nil, fmt.Errorf("close outbox rows: %w", err)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate outbox batch: %w", err)
	}
	if len(items) == 0 {
		if err := tx.Commit(); err != nil {
			return nil, fmt.Errorf("commit empty outbox claim: %w", err)
		}
		return nil, nil
	}

	ids := itemIDs(items)
	query, arguments := inQuery(
		"UPDATE sync_outbox SET status = 'processing', last_attempt_at_utc = ? WHERE id IN (%s)",
		ids,
		now.UTC().Format(time.RFC3339Nano),
	)
	if _, err := tx.ExecContext(ctx, query, arguments...); err != nil {
		return nil, fmt.Errorf("claim outbox batch: %w", err)
	}
	if err := tx.Commit(); err != nil {
		return nil, fmt.Errorf("commit outbox claim: %w", err)
	}
	return items, nil
}

func (s *SQLCipherStore) MarkSynced(ctx context.Context, ids []string, now time.Time) error {
	if len(ids) == 0 {
		return nil
	}
	query, arguments := inQuery(
		"UPDATE sync_outbox SET status = 'synced', synced_at_utc = ?, last_error_code = NULL WHERE id IN (%s)",
		ids,
		now.UTC().Format(time.RFC3339Nano),
	)
	_, err := s.db.ExecContext(ctx, query, arguments...)
	return wrapUpdateError("mark outbox batch synced", err)
}

func (s *SQLCipherStore) MarkRetry(ctx context.Context, ids []string, next time.Time, code string) error {
	if len(ids) == 0 {
		return nil
	}
	query, arguments := inQuery(
		"UPDATE sync_outbox SET status = 'retry', attempt_count = attempt_count + 1, next_attempt_at_utc = ?, last_error_code = ? WHERE id IN (%s)",
		ids,
		next.UTC().Format(time.RFC3339Nano),
		code,
	)
	_, err := s.db.ExecContext(ctx, query, arguments...)
	return wrapUpdateError("schedule outbox retry", err)
}

func (s *SQLCipherStore) MarkPermanentFailure(ctx context.Context, ids []string, code string) error {
	if len(ids) == 0 {
		return nil
	}
	query, arguments := inQuery(
		"UPDATE sync_outbox SET status = 'permanently-failed', attempt_count = attempt_count + 1, last_error_code = ? WHERE id IN (%s)",
		ids,
		code,
	)
	_, err := s.db.ExecContext(ctx, query, arguments...)
	return wrapUpdateError("mark outbox batch permanently failed", err)
}

func (s *SQLCipherStore) Close() error {
	clearBytes(s.payloadKey)
	return s.db.Close()
}

func encryptPayload(key []byte, plaintext []byte) ([]byte, []byte, []byte, error) {
	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, nil, nil, fmt.Errorf("create AES cipher: %w", err)
	}
	aead, err := cipher.NewGCM(block)
	if err != nil {
		return nil, nil, nil, fmt.Errorf("create AES-GCM: %w", err)
	}
	nonce := make([]byte, aead.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return nil, nil, nil, fmt.Errorf("read random nonce: %w", err)
	}
	sealed := aead.Seal(nil, nonce, plaintext, nil)
	tagStart := len(sealed) - aead.Overhead()
	return sealed[:tagStart], nonce, sealed[tagStart:], nil
}

func decryptPayload(key, ciphertext, nonce, tag []byte) ([]byte, error) {
	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, fmt.Errorf("create AES cipher: %w", err)
	}
	aead, err := cipher.NewGCM(block)
	if err != nil {
		return nil, fmt.Errorf("create AES-GCM: %w", err)
	}
	if len(nonce) != aead.NonceSize() || len(tag) != aead.Overhead() {
		return nil, errors.New("invalid AES-GCM nonce or tag length")
	}
	sealed := make([]byte, 0, len(ciphertext)+len(tag))
	sealed = append(sealed, ciphertext...)
	sealed = append(sealed, tag...)
	return aead.Open(nil, nonce, sealed, nil)
}

func metadataAllowed(entityType string) bool {
	switch entityType {
	case "system-event", "daily-summary", "inventory-snapshot":
		return true
	default:
		return false
	}
}

func clearBytes(value []byte) {
	for index := range value {
		value[index] = 0
	}
}

func itemIDs(items []OutboxItem) []string {
	ids := make([]string, len(items))
	for index, item := range items {
		ids[index] = item.ID
	}
	return ids
}

func inQuery(template string, ids []string, leading ...any) (string, []any) {
	placeholders := make([]string, len(ids))
	arguments := make([]any, 0, len(leading)+len(ids))
	arguments = append(arguments, leading...)
	for index, id := range ids {
		placeholders[index] = "?"
		arguments = append(arguments, id)
	}
	return fmt.Sprintf(template, strings.Join(placeholders, ",")), arguments
}

func wrapUpdateError(operation string, err error) error {
	if err == nil {
		return nil
	}
	return fmt.Errorf("%s: %w", operation, err)
}
