package control

import (
	"path/filepath"
	"testing"
)

func TestLogoutMarkerConsumesSignalOnce(t *testing.T) {
	marker := NewLogoutMarker(filepath.Join(t.TempDir(), "control", "logout.request"))
	if err := marker.Signal(); err != nil {
		t.Fatalf("Signal() error = %v", err)
	}
	consumed, err := marker.Consume()
	if err != nil || !consumed {
		t.Fatalf("Consume() = %v, %v", consumed, err)
	}
	consumed, err = marker.Consume()
	if err != nil || consumed {
		t.Fatalf("second Consume() = %v, %v", consumed, err)
	}
}
