package control_test

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"billing/activity-watch-agent/internal/control"
)

func TestServerLogoutControl_Consume_FlushTrue(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("Authorization") != "Bearer testcred" || r.Header.Get("X-Device-Id") != "dev-1" {
			w.WriteHeader(http.StatusUnauthorized)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"success":true,"data":{"flush":true}}`))
	}))
	defer server.Close()

	ctrl := control.NewServerLogoutControl(server.Client(), server.URL, "dev-1", "testcred")
	flush, err := ctrl.Consume()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !flush {
		t.Error("expected flush=true")
	}
}

func TestServerLogoutControl_Consume_FlushFalse(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"success":true,"data":{"flush":false}}`))
	}))
	defer server.Close()

	ctrl := control.NewServerLogoutControl(server.Client(), server.URL, "dev-1", "cred")
	flush, err := ctrl.Consume()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if flush {
		t.Error("expected flush=false")
	}
}

func TestServerLogoutControl_Acknowledge(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost || r.URL.Path != "/activity-watch/control/acknowledge" {
			t.Fatalf("request = %s %s", r.Method, r.URL.Path)
		}
		if r.Header.Get("Authorization") != "Bearer testcred" || r.Header.Get("X-Device-Id") != "dev-1" {
			w.WriteHeader(http.StatusUnauthorized)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"success":true,"data":{"acknowledged":true}}`))
	}))
	defer server.Close()

	ctrl := control.NewServerLogoutControl(server.Client(), server.URL+"/activity-watch/control", "dev-1", "testcred")
	if err := ctrl.Acknowledge(context.Background()); err != nil {
		t.Fatalf("Acknowledge() error = %v", err)
	}
}

func TestServerLogoutControl_Consume_ServerError(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("internal error"))
	}))
	defer server.Close()

	ctrl := control.NewServerLogoutControl(server.Client(), server.URL, "dev-1", "cred")
	flush, err := ctrl.Consume()
	if err == nil {
		t.Error("expected an error on 500 response")
	}
	if flush {
		t.Error("expected flush=false on error")
	}
}

func TestServerLogoutControl_Consume_Unauthorized(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusUnauthorized)
	}))
	defer server.Close()

	ctrl := control.NewServerLogoutControl(server.Client(), server.URL, "dev-1", "bad-cred")
	flush, err := ctrl.Consume()
	if err == nil {
		t.Error("expected error on 401")
	}
	if flush {
		t.Error("expected flush=false on 401")
	}
}
