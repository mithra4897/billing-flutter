package secret

import (
	"encoding/base64"
	"os"
	"path/filepath"
	"runtime"
	"testing"
)

func TestDatabaseKeyReadsProtectedBase64URL(t *testing.T) {
	path := filepath.Join(t.TempDir(), "database.key")
	want := make([]byte, 32)
	for index := range want {
		want[index] = byte(index)
	}
	if err := os.WriteFile(path, []byte(base64.RawURLEncoding.EncodeToString(want)), 0o600); err != nil {
		t.Fatal(err)
	}
	got, err := (FileProvider{}).DatabaseKey(path)
	if err != nil {
		t.Fatalf("DatabaseKey() error = %v", err)
	}
	if string(got) != string(want) {
		t.Fatal("DatabaseKey() returned unexpected key")
	}
}

func TestDatabaseKeyRejectsBroadUnixPermissions(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("Unix permission bits are not authoritative on Windows")
	}
	path := filepath.Join(t.TempDir(), "database.key")
	if err := os.WriteFile(path, []byte(base64.RawURLEncoding.EncodeToString(make([]byte, 32))), 0o644); err != nil {
		t.Fatal(err)
	}
	if _, err := (FileProvider{}).DatabaseKey(path); err == nil {
		t.Fatal("DatabaseKey() expected a permission error")
	}
}
