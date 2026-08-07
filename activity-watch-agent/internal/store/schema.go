package store

// schemaStatements mirrors the version-2 Flutter Activity Watch schema. It is
// kept in Go because provisioning must run before the Flutter application is
// available; provision tests verify the resulting database with the shared
// store verifier.
var schemaStatements = []string{
	`CREATE TABLE local_users (
    id TEXT PRIMARY KEY, server_user_id TEXT NOT NULL, employee_id TEXT,
    company_id TEXT NOT NULL, branch_id TEXT, device_id TEXT NOT NULL,
    platform TEXT NOT NULL CHECK (platform IN ('windows','macos','linux','android','ios','chromeos','other')),
    os_version TEXT, device_name TEXT, os_user_identity_hash TEXT NOT NULL,
    timezone TEXT NOT NULL, consent_policy_version INTEGER NOT NULL,
    consent_text_hash TEXT NOT NULL, consented_at_utc TEXT NOT NULL,
    consent_revoked_at_utc TEXT, created_at_utc TEXT NOT NULL,
    last_authenticated_at_utc TEXT, UNIQUE (server_user_id, device_id)
)`,
	`CREATE TABLE device_sessions (
    id TEXT PRIMARY KEY, local_user_id TEXT NOT NULL, os_session_id TEXT,
    boot_id TEXT NOT NULL, started_at_utc TEXT NOT NULL, ended_at_utc TEXT,
    start_monotonic_ms INTEGER NOT NULL, end_monotonic_ms INTEGER,
    start_reason TEXT NOT NULL, end_reason TEXT, agent_version TEXT NOT NULL,
    policy_version INTEGER NOT NULL, timezone TEXT NOT NULL,
    timezone_offset_minutes INTEGER NOT NULL, is_finalized INTEGER NOT NULL DEFAULT 0 CHECK (is_finalized IN (0, 1)),
    created_at_utc TEXT NOT NULL,
    FOREIGN KEY (local_user_id) REFERENCES local_users(id) ON DELETE RESTRICT
)`,
	`CREATE TABLE activity_segments (
    id TEXT PRIMARY KEY, session_id TEXT NOT NULL,
    activity_state TEXT NOT NULL CHECK (activity_state IN ('active','idle','locked','sleeping','logged_out','unknown')),
    network_state TEXT NOT NULL DEFAULT 'unknown' CHECK (network_state IN ('online','offline','unknown')),
    started_at_utc TEXT NOT NULL, ended_at_utc TEXT, start_monotonic_ms INTEGER,
    end_monotonic_ms INTEGER, duration_seconds INTEGER CHECK (duration_seconds IS NULL OR duration_seconds >= 0),
    last_input_at_utc TEXT, idle_threshold_seconds INTEGER NOT NULL,
    input_detected INTEGER NOT NULL DEFAULT 0 CHECK (input_detected IN (0, 1)),
    confidence TEXT NOT NULL DEFAULT 'confirmed' CHECK (confidence IN ('confirmed','inferred','uncertain')),
    created_at_utc TEXT NOT NULL,
    FOREIGN KEY (session_id) REFERENCES device_sessions(id) ON DELETE CASCADE
)`,
	`CREATE TABLE application_segments (
    id TEXT PRIMARY KEY, session_id TEXT NOT NULL, process_fingerprint TEXT NOT NULL,
    process_name TEXT NOT NULL, executable_name TEXT, executable_path_encrypted BLOB,
    path_nonce BLOB, path_tag BLOB, publisher TEXT, signature_status TEXT,
    classification TEXT NOT NULL DEFAULT 'unclassified' CHECK (classification IN ('productive','communication','development','browser','system','entertainment','unclassified')),
    window_title_encrypted BLOB, title_nonce BLOB, title_tag BLOB,
    started_at_utc TEXT NOT NULL, ended_at_utc TEXT, start_monotonic_ms INTEGER,
    end_monotonic_ms INTEGER, duration_seconds INTEGER CHECK (duration_seconds IS NULL OR duration_seconds >= 0),
    created_at_utc TEXT NOT NULL,
    FOREIGN KEY (session_id) REFERENCES device_sessions(id) ON DELETE CASCADE
)`,
	`CREATE TABLE browser_activity_segments (
    id TEXT PRIMARY KEY, session_id TEXT NOT NULL, browser_name TEXT NOT NULL,
    domain_hmac TEXT, tab_title_encrypted BLOB, title_nonce BLOB, title_tag BLOB,
    keyword_rule_id TEXT, category TEXT, started_at_utc TEXT NOT NULL,
    ended_at_utc TEXT, duration_seconds INTEGER CHECK (duration_seconds IS NULL OR duration_seconds >= 0),
    privacy_disposition TEXT NOT NULL DEFAULT 'category-only' CHECK (privacy_disposition IN ('category-only','raw-title-local','excluded')),
    created_at_utc TEXT NOT NULL,
    FOREIGN KEY (session_id) REFERENCES device_sessions(id) ON DELETE CASCADE
)`,
	`CREATE TABLE inventory_snapshots (
    id TEXT PRIMARY KEY, session_id TEXT NOT NULL,
    inventory_type TEXT NOT NULL CHECK (inventory_type IN ('processes','system-services')),
    snapshot_hash TEXT NOT NULL, item_count INTEGER NOT NULL CHECK (item_count >= 0),
    payload_encrypted BLOB NOT NULL, payload_nonce BLOB NOT NULL, payload_tag BLOB NOT NULL,
    captured_at_utc TEXT NOT NULL, created_at_utc TEXT NOT NULL,
    UNIQUE (session_id, inventory_type, snapshot_hash),
    FOREIGN KEY (session_id) REFERENCES device_sessions(id) ON DELETE CASCADE
)`,
	`CREATE TABLE system_events (
    id TEXT PRIMARY KEY, session_id TEXT, boot_id TEXT, event_type TEXT NOT NULL,
    event_at_utc TEXT NOT NULL, monotonic_ms INTEGER, metadata_encrypted BLOB,
    metadata_nonce BLOB, metadata_tag BLOB, created_at_utc TEXT NOT NULL,
    FOREIGN KEY (session_id) REFERENCES device_sessions(id) ON DELETE CASCADE
)`,
	`CREATE TABLE daily_summaries (
    id TEXT PRIMARY KEY, local_user_id TEXT NOT NULL, device_id TEXT NOT NULL,
    work_date_local TEXT NOT NULL, timezone TEXT NOT NULL, policy_version INTEGER NOT NULL,
    first_active_at_utc TEXT, last_active_at_utc TEXT,
    active_seconds INTEGER NOT NULL DEFAULT 0 CHECK (active_seconds >= 0),
    idle_seconds INTEGER NOT NULL DEFAULT 0 CHECK (idle_seconds >= 0),
    locked_seconds INTEGER NOT NULL DEFAULT 0 CHECK (locked_seconds >= 0),
    sleep_seconds INTEGER NOT NULL DEFAULT 0 CHECK (sleep_seconds >= 0),
    offline_seconds INTEGER NOT NULL DEFAULT 0 CHECK (offline_seconds >= 0),
    unknown_seconds INTEGER NOT NULL DEFAULT 0 CHECK (unknown_seconds >= 0),
    input_seconds INTEGER NOT NULL DEFAULT 0 CHECK (input_seconds >= 0),
    browser_seconds INTEGER NOT NULL DEFAULT 0 CHECK (browser_seconds >= 0),
    tracked_seconds INTEGER NOT NULL DEFAULT 0 CHECK (tracked_seconds >= 0),
    application_summary_encrypted BLOB, application_summary_nonce BLOB,
    application_summary_tag BLOB, browser_summary_encrypted BLOB,
    browser_summary_nonce BLOB, browser_summary_tag BLOB,
    inventory_summary_encrypted BLOB, inventory_summary_nonce BLOB,
    inventory_summary_tag BLOB, summary_checksum TEXT NOT NULL,
    revision INTEGER NOT NULL DEFAULT 1 CHECK (revision > 0),
    is_finalized INTEGER NOT NULL DEFAULT 0 CHECK (is_finalized IN (0, 1)),
    created_at_utc TEXT NOT NULL, updated_at_utc TEXT NOT NULL,
    UNIQUE (local_user_id, device_id, work_date_local),
    FOREIGN KEY (local_user_id) REFERENCES local_users(id) ON DELETE RESTRICT
)`,
	`CREATE TABLE sync_outbox (
    id TEXT PRIMARY KEY, entity_type TEXT NOT NULL, entity_id TEXT NOT NULL,
    operation TEXT NOT NULL, payload_encrypted BLOB NOT NULL,
    payload_nonce BLOB NOT NULL, payload_tag BLOB NOT NULL,
    payload_checksum TEXT NOT NULL, idempotency_key TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','processing','synced','retry','permanently-failed')),
    attempt_count INTEGER NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
    next_attempt_at_utc TEXT, last_attempt_at_utc TEXT, last_http_status INTEGER,
    last_error_code TEXT, response_checksum TEXT, created_at_utc TEXT NOT NULL,
    synced_at_utc TEXT
)`,
	`CREATE TABLE agent_state (
    key TEXT PRIMARY KEY,
    state_group TEXT NOT NULL CHECK (state_group IN ('schema','policy','keyword-rules','settings','health')),
    value_encrypted BLOB NOT NULL, value_nonce BLOB NOT NULL, value_tag BLOB NOT NULL,
    server_version INTEGER, updated_at_utc TEXT NOT NULL
)`,
	`CREATE INDEX idx_device_sessions_user_started ON device_sessions(local_user_id, started_at_utc)`,
	`CREATE INDEX idx_activity_segments_session_started ON activity_segments(session_id, started_at_utc)`,
	`CREATE INDEX idx_activity_segments_state_started ON activity_segments(activity_state, started_at_utc)`,
	`CREATE INDEX idx_application_segments_session_started ON application_segments(session_id, started_at_utc)`,
	`CREATE INDEX idx_browser_segments_session_started ON browser_activity_segments(session_id, started_at_utc)`,
	`CREATE INDEX idx_inventory_session_type_captured ON inventory_snapshots(session_id, inventory_type, captured_at_utc)`,
	`CREATE INDEX idx_system_events_session_event ON system_events(session_id, event_at_utc)`,
	`CREATE INDEX idx_system_events_type_event ON system_events(event_type, event_at_utc)`,
	`CREATE INDEX idx_daily_summaries_user_date ON daily_summaries(local_user_id, work_date_local)`,
	`CREATE INDEX idx_sync_outbox_dispatch ON sync_outbox(status, next_attempt_at_utc)`,
	`CREATE INDEX idx_agent_state_group ON agent_state(state_group, updated_at_utc)`,
}
