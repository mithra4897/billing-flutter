package control

import (
	"context"
	"testing"
)

func TestCombinedLogoutControlAcknowledgesTriggeredSecondary(t *testing.T) {
	primary := &fakeLogoutControl{}
	secondary := &fakeLogoutControl{triggered: true}
	combined := NewCombinedLogoutControl(primary, secondary)

	triggered, err := combined.Consume()
	if err != nil || !triggered {
		t.Fatalf("Consume() = %v, %v; want true, nil", triggered, err)
	}
	if err := combined.Acknowledge(context.Background()); err != nil {
		t.Fatalf("Acknowledge() error = %v", err)
	}
	if primary.acknowledgements != 0 || secondary.acknowledgements != 1 {
		t.Fatalf("acknowledgements = primary %d, secondary %d", primary.acknowledgements, secondary.acknowledgements)
	}
}

func TestCombinedLogoutControlDoesNotAcknowledgeLocalOnlyTrigger(t *testing.T) {
	primary := &localOnlyControl{triggered: true}
	secondary := &fakeLogoutControl{}
	combined := NewCombinedLogoutControl(primary, secondary)

	triggered, err := combined.Consume()
	if err != nil || !triggered {
		t.Fatalf("Consume() = %v, %v; want true, nil", triggered, err)
	}
	if err := combined.Acknowledge(context.Background()); err != nil {
		t.Fatalf("Acknowledge() error = %v", err)
	}
	if secondary.acknowledgements != 0 {
		t.Fatalf("secondary acknowledgements = %d, want 0", secondary.acknowledgements)
	}
}

type fakeLogoutControl struct {
	triggered        bool
	acknowledgements int
}

func (f *fakeLogoutControl) Consume() (bool, error) {
	triggered := f.triggered
	f.triggered = false
	return triggered, nil
}

func (f *fakeLogoutControl) Acknowledge(context.Context) error {
	f.acknowledgements++
	return nil
}

type localOnlyControl struct {
	triggered bool
}

func (f *localOnlyControl) Consume() (bool, error) {
	triggered := f.triggered
	f.triggered = false
	return triggered, nil
}
