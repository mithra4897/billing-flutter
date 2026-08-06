package store

import (
	"context"
	"errors"
	"fmt"
)

// ProvisionSQLCipher initializes an empty database path with the approved
// Activity Watch schema. The caller owns creating and atomically publishing the
// database file, so this function never overwrites an existing target.
func ProvisionSQLCipher(ctx context.Context, path string, key []byte) error {
	if len(key) != 32 {
		return errors.New("SQLCipher key must contain exactly 32 bytes")
	}
	db, err := openDatabase(path, key)
	if err != nil {
		return err
	}
	defer db.Close()

	if err := verifyCipherRuntime(ctx, db); err != nil {
		return err
	}
	if err := configureConnection(ctx, db); err != nil {
		return err
	}
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("begin schema provisioning: %w", err)
	}
	defer tx.Rollback()
	for _, statement := range schemaStatements {
		if _, err := tx.ExecContext(ctx, statement); err != nil {
			return fmt.Errorf("create Activity Watch schema: %w", err)
		}
	}
	if _, err := tx.ExecContext(ctx, fmt.Sprintf("PRAGMA user_version = %d", SupportedSchemaVersion)); err != nil {
		return fmt.Errorf("set Activity Watch schema version: %w", err)
	}
	if err := tx.Commit(); err != nil {
		return fmt.Errorf("commit Activity Watch schema: %w", err)
	}

	store := &SQLCipherStore{db: db}
	return store.verify(ctx)
}
