package store

import (
	"context"
	"encoding/json"
	"testing"
	"time"

	"billing/activity-watch-agent/internal/collector"
)

func TestActivityCollectionConsolidatesAndBuildsSummary(t *testing.T) {
	path, key := createTestDatabase(t)
	database, err := OpenSQLCipher(context.Background(), path, key)
	if err != nil {
		t.Fatal(err)
	}
	defer database.Close()
	ctx := context.Background()
	start := time.Date(2026, 8, 7, 9, 0, 0, 0, time.UTC)
	if err := database.StartSession(ctx, "device-1", start); err != nil {
		t.Fatal(err)
	}
	active := collector.Snapshot{State: "active", ExecutableName: "Code", Classification: "development", ObservedAt: start}
	if err := database.RecordObservation(ctx, active, 5*time.Minute); err != nil {
		t.Fatal(err)
	}
	active.ObservedAt = start.Add(15 * time.Second)
	if err := database.RecordObservation(ctx, active, 5*time.Minute); err != nil {
		t.Fatal(err)
	}
	idle := collector.Snapshot{State: "idle", IdleFor: 5 * time.Minute, ObservedAt: start.Add(30 * time.Second)}
	if err := database.RecordObservation(ctx, idle, 5*time.Minute); err != nil {
		t.Fatal(err)
	}

	var activityCount, applicationCount int
	if err := database.db.QueryRow("SELECT count(*) FROM activity_segments").Scan(&activityCount); err != nil {
		t.Fatal(err)
	}
	if err := database.db.QueryRow("SELECT count(*) FROM application_segments").Scan(&applicationCount); err != nil {
		t.Fatal(err)
	}
	if activityCount != 2 || applicationCount != 1 {
		t.Fatalf("activity/application counts = %d/%d, want 2/1", activityCount, applicationCount)
	}
	if err := database.PrepareDailySummary(ctx, start.Add(30*time.Second)); err != nil {
		t.Fatal(err)
	}
	items, err := database.ClaimReadyBatch(ctx, start.Add(time.Minute), 100)
	if err != nil {
		t.Fatal(err)
	}
	var summary DailySummaryPayload
	found := false
	for _, item := range items {
		if item.EntityType != "daily-summary" {
			continue
		}
		found = true
		if err := json.Unmarshal(item.Metadata, &summary); err != nil {
			t.Fatal(err)
		}
	}
	if !found || summary.ActiveSeconds != 30 || summary.TrackedSeconds != 30 {
		t.Fatalf("summary = %#v", summary)
	}
	if len(summary.Applications) != 1 || summary.Applications[0].Name != "Code" || summary.Applications[0].Seconds != 30 {
		t.Fatalf("application summary = %#v", summary.Applications)
	}
}

func TestTimezoneNameUsesOffsetForGenericLocalLocation(t *testing.T) {
	at := time.Date(2026, 8, 7, 12, 0, 0, 0, time.FixedZone("Local", 5*60*60+30*60))
	if got := timezoneName(at); got != "+05:30" {
		t.Fatalf("timezoneName() = %q, want +05:30", got)
	}
}

func TestDailySummaryClipsSegmentsAtLocalMidnight(t *testing.T) {
	path, key := createTestDatabase(t)
	database, err := OpenSQLCipher(context.Background(), path, key)
	if err != nil {
		t.Fatal(err)
	}
	defer database.Close()
	ctx := context.Background()
	start := time.Date(2026, 8, 7, 23, 59, 0, 0, time.UTC)
	if err := database.StartSession(ctx, "device-midnight", start); err != nil {
		t.Fatal(err)
	}
	observation := collector.Snapshot{
		State: "active", NetworkState: "offline", ExecutableName: "Code",
		Classification: "development", ObservedAt: start,
	}
	if err := database.RecordObservation(ctx, observation, 5*time.Minute); err != nil {
		t.Fatal(err)
	}
	afterMidnight := start.Add(2 * time.Minute)
	observation.ObservedAt = afterMidnight
	if err := database.RecordObservation(ctx, observation, 5*time.Minute); err != nil {
		t.Fatal(err)
	}
	if err := database.PrepareDailySummary(ctx, afterMidnight); err != nil {
		t.Fatal(err)
	}

	var active, offline int64
	if err := database.db.QueryRow(`
SELECT active_seconds, offline_seconds FROM daily_summaries
WHERE work_date_local = '2026-08-08'`).Scan(&active, &offline); err != nil {
		t.Fatal(err)
	}
	if active != 60 || offline != 60 {
		t.Fatalf("current-day active/offline seconds = %d/%d, want 60/60", active, offline)
	}
	items, err := database.ClaimReadyBatch(ctx, afterMidnight.Add(time.Minute), 10)
	if err != nil {
		t.Fatal(err)
	}
	var summary DailySummaryPayload
	if len(items) != 1 || json.Unmarshal(items[0].Metadata, &summary) != nil {
		t.Fatalf("expected one readable daily summary, got %#v", items)
	}
	if len(summary.Applications) != 1 || summary.Applications[0].Seconds != 60 {
		t.Fatalf("current-day application summary = %#v, want 60 seconds", summary.Applications)
	}
}

func TestInventorySnapshotDeduplicatesCanonicalPayload(t *testing.T) {
	path, key := createTestDatabase(t)
	database, err := OpenSQLCipher(context.Background(), path, key)
	if err != nil {
		t.Fatal(err)
	}
	defer database.Close()
	ctx := context.Background()
	at := time.Date(2026, 8, 7, 9, 0, 0, 0, time.UTC)
	if err := database.StartSession(ctx, "device-1", at); err != nil {
		t.Fatal(err)
	}
	items := []collector.InventoryItem{{Name: "beta"}, {Name: "alpha"}}
	if err := database.RecordInventory(ctx, "processes", items, at); err != nil {
		t.Fatal(err)
	}
	if err := database.RecordInventory(ctx, "processes", []collector.InventoryItem{{Name: "alpha"}, {Name: "beta"}}, at); err != nil {
		t.Fatal(err)
	}
	var snapshots int
	if err := database.db.QueryRow("SELECT count(*) FROM inventory_snapshots").Scan(&snapshots); err != nil {
		t.Fatal(err)
	}
	if snapshots != 1 {
		t.Fatalf("snapshot count = %d, want 1", snapshots)
	}
}

func TestRequeueAuthenticationFailuresOnlyRecoversCredentials(t *testing.T) {
	path, key := createTestDatabase(t)
	database, err := OpenSQLCipher(context.Background(), path, key)
	if err != nil {
		t.Fatal(err)
	}
	defer database.Close()
	created := time.Date(2026, 8, 7, 9, 0, 0, 0, time.UTC).Format(time.RFC3339Nano)
	for id, code := range map[string]string{"auth": "http-401", "invalid": "http-422"} {
		_, err := database.db.Exec(`
INSERT INTO sync_outbox (
    id, entity_type, entity_id, operation, payload_encrypted, payload_nonce,
    payload_tag, payload_checksum, idempotency_key, status, last_error_code, created_at_utc
) VALUES (?, 'test', ?, 'upsert', ?, ?, ?, 'checksum', ?, 'permanently-failed', ?, ?)`,
			id, id, []byte{1}, []byte{1}, []byte{1}, id, code, created)
		if err != nil {
			t.Fatal(err)
		}
	}
	if err := database.RequeueAuthenticationFailures(context.Background(), time.Now()); err != nil {
		t.Fatal(err)
	}
	var authStatus, invalidStatus string
	_ = database.db.QueryRow("SELECT status FROM sync_outbox WHERE id = 'auth'").Scan(&authStatus)
	_ = database.db.QueryRow("SELECT status FROM sync_outbox WHERE id = 'invalid'").Scan(&invalidStatus)
	if authStatus != "retry" || invalidStatus != "permanently-failed" {
		t.Fatalf("statuses = %q/%q", authStatus, invalidStatus)
	}
}

func TestPurgeExpiredKeepsUnsyncedOutbox(t *testing.T) {
	path, key := createTestDatabase(t)
	database, err := OpenSQLCipher(context.Background(), path, key)
	if err != nil {
		t.Fatal(err)
	}
	defer database.Close()
	ctx := context.Background()
	old := time.Date(2026, 4, 1, 9, 0, 0, 0, time.UTC)
	if err := database.RecordSystemEvent(ctx, SystemEvent{Type: "old-event", OccurredAt: old}); err != nil {
		t.Fatal(err)
	}
	items, err := database.ClaimReadyBatch(ctx, old.Add(time.Minute), 10)
	if err != nil {
		t.Fatal(err)
	}
	if err := database.MarkSynced(ctx, []string{items[0].ID}, old.Add(time.Minute)); err != nil {
		t.Fatal(err)
	}
	if err := database.RecordSystemEvent(ctx, SystemEvent{Type: "pending-event", OccurredAt: old}); err != nil {
		t.Fatal(err)
	}
	if err := database.PurgeExpired(ctx, time.Date(2026, 5, 1, 0, 0, 0, 0, time.UTC)); err != nil {
		t.Fatal(err)
	}
	var synced, pending int
	_ = database.db.QueryRow("SELECT count(*) FROM sync_outbox WHERE status = 'synced'").Scan(&synced)
	_ = database.db.QueryRow("SELECT count(*) FROM sync_outbox WHERE status = 'pending'").Scan(&pending)
	if synced != 0 || pending != 1 {
		t.Fatalf("synced/pending outbox counts = %d/%d, want 0/1", synced, pending)
	}
}
