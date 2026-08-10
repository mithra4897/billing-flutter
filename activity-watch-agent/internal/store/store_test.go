package store

import (
	"context"
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestOpenSQLCipherUpgradesVersionOneInputMetrics(t *testing.T) {
	path := filepath.Join(t.TempDir(), "activity_watch_v1.db")
	key := make([]byte, 32)
	for index := range key {
		key[index] = byte(index + 1)
	}
	query := url.Values{}
	query.Set("_pragma_key", fmt.Sprintf("x'%s'", hex.EncodeToString(key)))
	database, err := sql.Open("sqlite3", path+"?"+query.Encode())
	if err != nil {
		t.Fatal(err)
	}
	for _, current := range schemaStatements {
		legacy := strings.ReplaceAll(current, "\n    input_detected INTEGER NOT NULL DEFAULT 0 CHECK (input_detected IN (0, 1)),", "")
		legacy = strings.ReplaceAll(legacy, "\n    keyboard_detected INTEGER NOT NULL DEFAULT 0 CHECK (keyboard_detected IN (0, 1)),", "")
		legacy = strings.ReplaceAll(legacy, "\n    mouse_detected INTEGER NOT NULL DEFAULT 0 CHECK (mouse_detected IN (0, 1)),", "")
		legacy = strings.ReplaceAll(legacy, "\n    input_seconds INTEGER NOT NULL DEFAULT 0 CHECK (input_seconds >= 0),", "")
		legacy = strings.ReplaceAll(legacy, "\n    keyboard_active_seconds INTEGER NOT NULL DEFAULT 0 CHECK (keyboard_active_seconds >= 0),", "")
		legacy = strings.ReplaceAll(legacy, "\n    mouse_active_seconds INTEGER NOT NULL DEFAULT 0 CHECK (mouse_active_seconds >= 0),", "")
		legacy = strings.ReplaceAll(legacy, "\n    browser_seconds INTEGER NOT NULL DEFAULT 0 CHECK (browser_seconds >= 0),", "")
		if _, err := database.Exec(legacy); err != nil {
			database.Close()
			t.Fatal(err)
		}
	}
	if _, err := database.Exec(`PRAGMA user_version = 1`); err != nil {
		database.Close()
		t.Fatal(err)
	}
	if err := database.Close(); err != nil {
		t.Fatal(err)
	}

	upgraded, err := OpenSQLCipher(context.Background(), path, key)
	if err != nil {
		t.Fatal(err)
	}
	defer upgraded.Close()
	var version int
	if err := upgraded.db.QueryRow(`PRAGMA user_version`).Scan(&version); err != nil || version != 3 {
		t.Fatalf("schema version = %d, error = %v", version, err)
	}
}

func TestOpenSQLCipherUpgradesVersionTwoMonitoringMetrics(t *testing.T) {
	path := filepath.Join(t.TempDir(), "activity_watch_v2.db")
	key := make([]byte, 32)
	for index := range key {
		key[index] = byte(index + 1)
	}
	query := url.Values{}
	query.Set("_pragma_key", fmt.Sprintf("x'%s'", hex.EncodeToString(key)))
	database, err := sql.Open("sqlite3", path+"?"+query.Encode())
	if err != nil {
		t.Fatal(err)
	}
	for _, current := range schemaStatements {
		legacy := strings.ReplaceAll(current, "\n    keyboard_detected INTEGER NOT NULL DEFAULT 0 CHECK (keyboard_detected IN (0, 1)),", "")
		legacy = strings.ReplaceAll(legacy, "\n    mouse_detected INTEGER NOT NULL DEFAULT 0 CHECK (mouse_detected IN (0, 1)),", "")
		legacy = strings.ReplaceAll(legacy, "\n    keyboard_active_seconds INTEGER NOT NULL DEFAULT 0 CHECK (keyboard_active_seconds >= 0),", "")
		legacy = strings.ReplaceAll(legacy, "\n    mouse_active_seconds INTEGER NOT NULL DEFAULT 0 CHECK (mouse_active_seconds >= 0),", "")
		if _, err := database.Exec(legacy); err != nil {
			database.Close()
			t.Fatal(err)
		}
	}
	if _, err := database.Exec(`PRAGMA user_version = 2`); err != nil {
		database.Close()
		t.Fatal(err)
	}
	if err := database.Close(); err != nil {
		t.Fatal(err)
	}
	upgraded, err := OpenSQLCipher(context.Background(), path, key)
	if err != nil {
		t.Fatal(err)
	}
	defer upgraded.Close()
	var version int
	if err := upgraded.db.QueryRow(`PRAGMA user_version`).Scan(&version); err != nil || version != 3 {
		t.Fatalf("schema version = %d, error = %v", version, err)
	}
}

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
		payload, nonce, tag, err := encryptPayload(database.payloadKey, []byte(`{"work_date_local":"2026-08-06"}`))
		if err != nil {
			t.Fatal(err)
		}
		_, err = database.db.Exec(`
INSERT INTO sync_outbox (
    id, entity_type, entity_id, operation, payload_encrypted, payload_nonce,
    payload_tag, payload_checksum, idempotency_key, status, created_at_utc
) VALUES (?, 'daily-summary', ?, 'upsert', ?, ?, ?, ?, ?, 'pending', ?)`,
			fmt.Sprintf("item-%d", index),
			fmt.Sprintf("entity-%d", index),
			payload,
			nonce,
			tag,
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
	statements := append([]string(nil), schemaStatements...)
	statements = append(statements, fmt.Sprintf(`PRAGMA user_version = %d`, SupportedSchemaVersion))
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
