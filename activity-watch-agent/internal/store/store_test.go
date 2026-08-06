package store

import (
	"context"
	"crypto/aes"
	"crypto/cipher"
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/url"
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestOpenSQLCipherVerifiesEncryptionAndApprovedSchema(t *testing.T) {
	path, key := createTestDatabase(t)
	ctx := context.Background()
	database, err := OpenSQLCipher(ctx, path, key)
	if err != nil {
		t.Fatalf("OpenSQLCipher() error = %v", err)
	}
	defer database.Close()

	if err := database.RecordSystemEvent(ctx, SystemEvent{
		Type:       "agent-start",
		OccurredAt: time.Date(2026, 8, 6, 12, 0, 0, 0, time.UTC),
	}); err != nil {
		t.Fatalf("RecordSystemEvent() error = %v", err)
	}
	var eventCount int
	if err := database.db.QueryRow("SELECT count(*) FROM system_events").Scan(&eventCount); err != nil {
		t.Fatal(err)
	}
	if eventCount != 1 {
		t.Fatalf("event count = %d, want 1", eventCount)
	}
	var ciphertext []byte
	var nonce []byte
	var tag []byte
	var checksum string
	var idempotencyKey string
	if err := database.db.QueryRow(
		"SELECT payload_encrypted, payload_nonce, payload_tag, payload_checksum, idempotency_key FROM sync_outbox",
	).Scan(&ciphertext, &nonce, &tag, &checksum, &idempotencyKey); err != nil {
		t.Fatal(err)
	}
	if string(ciphertext) == `{"event_type":"agent-start","occurred_at_utc":"2026-08-06T12:00:00Z"}` {
		t.Fatal("queued payload must not be stored as plaintext")
	}
	plaintext, err := decryptPayload(database.payloadKey, ciphertext, nonce, tag)
	if err != nil {
		t.Fatalf("decrypt queued payload: %v", err)
	}
	var queued struct {
		EventType  string `json:"event_type"`
		OccurredAt string `json:"occurred_at_utc"`
	}
	if err := json.Unmarshal(plaintext, &queued); err != nil {
		t.Fatalf("decode queued payload: %v", err)
	}
	if queued.EventType != "agent-start" || queued.OccurredAt != "2026-08-06T12:00:00Z" {
		t.Fatalf("queued payload = %#v", queued)
	}
	expectedChecksum := sha256.Sum256(ciphertext)
	if checksum != hex.EncodeToString(expectedChecksum[:]) || idempotencyKey == "" {
		t.Fatalf("queued checksum/idempotency key must be present: %q / %q", checksum, idempotencyKey)
	}

	file, err := os.Open(path)
	if err != nil {
		t.Fatal(err)
	}
	header := make([]byte, 16)
	if _, err := file.Read(header); err != nil {
		file.Close()
		t.Fatal(err)
	}
	file.Close()
	if string(header) == "SQLite format 3\x00" {
		t.Fatal("database has a plaintext SQLite header")
	}
}

func TestOpenSQLCipherRejectsWrongKey(t *testing.T) {
	path, _ := createTestDatabase(t)
	if _, err := OpenSQLCipher(context.Background(), path, make([]byte, 32)); err == nil {
		t.Fatal("OpenSQLCipher() expected wrong-key failure")
	}
}

func TestProvisionSQLCipherCreatesApprovedEncryptedSchema(t *testing.T) {
	path := filepath.Join(t.TempDir(), "activity_watch.db")
	key := make([]byte, 32)
	for index := range key {
		key[index] = byte(index + 1)
	}
	if err := ProvisionSQLCipher(context.Background(), path, key); err != nil {
		t.Fatalf("ProvisionSQLCipher() error = %v", err)
	}
	database, err := OpenSQLCipher(context.Background(), path, key)
	if err != nil {
		t.Fatalf("OpenSQLCipher() error = %v", err)
	}
	defer database.Close()

	var indexCount int
	if err := database.db.QueryRow("SELECT count(*) FROM sqlite_master WHERE type = 'index' AND name NOT LIKE 'sqlite_autoindex%'").Scan(&indexCount); err != nil {
		t.Fatal(err)
	}
	if indexCount != 11 {
		t.Fatalf("index count = %d, want 11", indexCount)
	}
}

func TestClaimReadyBatchUsesLimitAndTransitionsState(t *testing.T) {
	path, key := createTestDatabase(t)
	database, err := OpenSQLCipher(context.Background(), path, key)
	if err != nil {
		t.Fatal(err)
	}
	defer database.Close()
	now := time.Date(2026, 8, 6, 12, 0, 0, 0, time.UTC)
	for index := 0; index < 3; index++ {
		created := now.Add(time.Duration(index) * time.Second).Format(time.RFC3339Nano)
		_, err := database.db.Exec(`
INSERT INTO sync_outbox (
    id, entity_type, entity_id, operation, payload_encrypted, payload_nonce,
    payload_tag, payload_checksum, idempotency_key, status, created_at_utc
) VALUES (?, 'daily-summary', ?, 'upsert', ?, ?, ?, ?, ?, 'pending', ?)`,
			fmt.Sprintf("item-%d", index),
			fmt.Sprintf("entity-%d", index),
			[]byte{byte(index)},
			[]byte{1},
			[]byte{2},
			fmt.Sprintf("checksum-%d", index),
			fmt.Sprintf("idempotency-%d", index),
			created,
		)
		if err != nil {
			t.Fatal(err)
		}
	}

	items, err := database.ClaimReadyBatch(context.Background(), now, 2)
	if err != nil {
		t.Fatalf("ClaimReadyBatch() error = %v", err)
	}
	if len(items) != 2 || items[0].ID != "item-0" || items[1].ID != "item-1" {
		t.Fatalf("claimed items = %#v", items)
	}
	if err := database.MarkRetry(
		context.Background(),
		[]string{"item-0", "item-1"},
		now.Add(time.Minute),
		"network-error",
	); err != nil {
		t.Fatal(err)
	}
	var status string
	var attempts int
	if err := database.db.QueryRow(
		"SELECT status, attempt_count FROM sync_outbox WHERE id = 'item-0'",
	).Scan(&status, &attempts); err != nil {
		t.Fatal(err)
	}
	if status != "retry" || attempts != 1 {
		t.Fatalf("status = %q, attempts = %d", status, attempts)
	}
}

func createTestDatabase(t *testing.T) (string, []byte) {
	t.Helper()
	path := filepath.Join(t.TempDir(), "activity_watch.db")
	key := make([]byte, 32)
	for index := range key {
		key[index] = byte(index + 1)
	}
	query := url.Values{}
	query.Set("_pragma_key", fmt.Sprintf("x'%s'", hex.EncodeToString(key)))
	query.Set("_pragma_cipher_page_size", "4096")
	database, err := sql.Open("sqlite3", path+"?"+query.Encode())
	if err != nil {
		t.Fatal(err)
	}
	statements := []string{
		`CREATE TABLE local_users (id TEXT PRIMARY KEY)`,
		`CREATE TABLE device_sessions (id TEXT PRIMARY KEY)`,
		`CREATE TABLE activity_segments (id TEXT PRIMARY KEY)`,
		`CREATE TABLE application_segments (id TEXT PRIMARY KEY)`,
		`CREATE TABLE browser_activity_segments (id TEXT PRIMARY KEY)`,
		`CREATE TABLE inventory_snapshots (id TEXT PRIMARY KEY)`,
		`CREATE TABLE system_events (
            id TEXT PRIMARY KEY,
            session_id TEXT,
            boot_id TEXT,
            event_type TEXT NOT NULL,
            event_at_utc TEXT NOT NULL,
            monotonic_ms INTEGER,
            metadata_encrypted BLOB,
            metadata_nonce BLOB,
            metadata_tag BLOB,
            created_at_utc TEXT NOT NULL
        )`,
		`CREATE TABLE daily_summaries (id TEXT PRIMARY KEY)`,
		`CREATE TABLE sync_outbox (
            id TEXT PRIMARY KEY,
            entity_type TEXT NOT NULL,
            entity_id TEXT NOT NULL,
            operation TEXT NOT NULL,
            payload_encrypted BLOB NOT NULL,
            payload_nonce BLOB NOT NULL,
            payload_tag BLOB NOT NULL,
            payload_checksum TEXT NOT NULL,
            idempotency_key TEXT NOT NULL UNIQUE,
            status TEXT NOT NULL DEFAULT 'pending',
            attempt_count INTEGER NOT NULL DEFAULT 0,
            next_attempt_at_utc TEXT,
            last_attempt_at_utc TEXT,
            last_http_status INTEGER,
            last_error_code TEXT,
            response_checksum TEXT,
            created_at_utc TEXT NOT NULL,
            synced_at_utc TEXT
        )`,
		`CREATE TABLE agent_state (key TEXT PRIMARY KEY)`,
		`CREATE INDEX idx_sync_outbox_dispatch ON sync_outbox(status, next_attempt_at_utc)`,
		`PRAGMA user_version = 1`,
	}
	for _, statement := range statements {
		if _, err := database.Exec(statement); err != nil {
			database.Close()
			t.Fatal(err)
		}
	}
	if err := database.Close(); err != nil {
		t.Fatal(err)
	}
	return path, key
}

func decryptPayload(key, ciphertext, nonce, tag []byte) ([]byte, error) {
	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, err
	}
	aead, err := cipher.NewGCM(block)
	if err != nil {
		return nil, err
	}
	return aead.Open(nil, nonce, append(ciphertext, tag...), nil)
}
