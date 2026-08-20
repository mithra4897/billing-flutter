package control

import "context"

// CombinedLogoutControl checks a primary control first (file-based), then
// falls back to a secondary control (server-based). Either returning true
// triggers the logout flush. This allows both desktop (signal-logout binary)
// and web (server-driven) ERP clients to work simultaneously.
type CombinedLogoutControl struct {
	primary             LogoutControl
	secondary           LogoutControl
	pendingAcknowledger LogoutAcknowledger
}

// LogoutControl is the interface satisfied by LogoutMarker and ServerLogoutControl.
type LogoutControl interface {
	Consume() (bool, error)
}

type LogoutAcknowledger interface {
	Acknowledge(context.Context) error
}

// NewCombinedLogoutControl returns a control that checks primary first, then
// secondary if primary returns false.
func NewCombinedLogoutControl(primary, secondary LogoutControl) *CombinedLogoutControl {
	return &CombinedLogoutControl{primary: primary, secondary: secondary}
}

func (c *CombinedLogoutControl) Consume() (bool, error) {
	c.pendingAcknowledger = nil
	if triggered, err := c.primary.Consume(); err != nil || triggered {
		if triggered {
			c.pendingAcknowledger, _ = c.primary.(LogoutAcknowledger)
		}
		return triggered, err
	}
	triggered, err := c.secondary.Consume()
	if triggered {
		c.pendingAcknowledger, _ = c.secondary.(LogoutAcknowledger)
	}
	return triggered, err
}

func (c *CombinedLogoutControl) Acknowledge(ctx context.Context) error {
	if c.pendingAcknowledger == nil {
		return nil
	}
	if err := c.pendingAcknowledger.Acknowledge(ctx); err != nil {
		return err
	}
	c.pendingAcknowledger = nil
	return nil
}
