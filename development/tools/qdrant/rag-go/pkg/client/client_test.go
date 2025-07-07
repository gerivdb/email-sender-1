// Package client_test contient les tests pour le package client
package client_test

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"rag-go-system/pkg/client"
)

func TestNewQdrantClient(t *testing.T) {
	// Test avec URL valide
	c, err := client.NewQdrantClient("http://localhost:6333")
	if err != nil {
		t.Errorf("NewQdrantClient() error = %v, wantErr nil", err)
	}
	if c == nil {
		t.Error("NewQdrantClient() client est nil, attendu non nil")
	}

	// Test avec URL invalide
	c, err = client.NewQdrantClient("://invalid-url")
	if err == nil {
		t.Error("NewQdrantClient() avec URL invalide, attendu erreur, reçu nil")
	}
	if c != nil {
		t.Error("NewQdrantClient() avec URL invalide, client attendu nil")
	}

	// Test avec options personnalisées
	c, err = client.NewQdrantClient(
		"http://localhost:6333",
		client.WithTimeout(5*time.Second),
		client.WithHeader("X-Custom", "Value"),
	)
	if err != nil {
		t.Errorf("NewQdrantClient() avec options error = %v, wantErr nil", err)
	}
	if c.HTTPClient.Timeout != 5*time.Second {
		t.Errorf("Timeout non appliqué, reçu %v, attendu %v", c.HTTPClient.Timeout, 5*time.Second)
	}
	if c.DefaultHeaders["X-Custom"] != "Value" {
		t.Errorf("Header personnalisé non appliqué, reçu %v, attendu %v", c.DefaultHeaders["X-Custom"], "Value")
	}
}

func TestHealthCheck(t *testing.T) {
	// Serveur de test qui répond toujours OK
	okServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/healthz" {
			w.WriteHeader(http.StatusOK)
			w.Write([]byte(`{"status":"ok"}`))
		}
	}))
	defer okServer.Close()

	// Serveur de test qui répond toujours en erreur
	errorServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/healthz" {
			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte(`{"status":"error"}`))
		}
	}))
	defer errorServer.Close()

	// Test avec serveur OK
	c, _ := client.NewQdrantClient(okServer.URL)
	if err := c.HealthCheck(); err != nil {
		t.Errorf("HealthCheck() error = %v, wantErr nil", err)
	}

	// Test avec serveur en erreur
	c, _ = client.NewQdrantClient(errorServer.URL)
	if err := c.HealthCheck(); err == nil {
		t.Error("HealthCheck() avec serveur en erreur, attendu erreur, reçu nil")
	}

	// Test avec serveur inexistant
	c, _ = client.NewQdrantClient("http://localhost:12345")
	if err := c.HealthCheck(); err == nil {
		t.Error("HealthCheck() avec serveur inexistant, attendu erreur, reçu nil")
	}
}

func TestIsAlive(t *testing.T) {
	// Serveur de test qui répond toujours OK
	okServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/" {
			w.WriteHeader(http.StatusOK)
		}
	}))
	defer okServer.Close()

	// Serveur de test qui répond toujours en erreur
	errorServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/" {
			w.WriteHeader(http.StatusInternalServerError)
		}
	}))
	defer errorServer.Close()

	// Test avec serveur OK
	c, _ := client.NewQdrantClient(okServer.URL)
	if !c.IsAlive() {
		t.Error("IsAlive() = false, attendu true")
	}

	// Test avec serveur en erreur
	c, _ = client.NewQdrantClient(errorServer.URL)
	if c.IsAlive() {
		t.Error("IsAlive() = true, attendu false")
	}

	// Test avec serveur inexistant
	c, _ = client.NewQdrantClient("http://localhost:12345")
	if c.IsAlive() {
		t.Error("IsAlive() avec serveur inexistant = true, attendu false")
	}
}

func TestWithRetry(t *testing.T) {
	// Test réussite au premier essai
	count := 0
	err := client.WithRetry(3, func() error {
		count++
		return nil
	})
	if err != nil {
		t.Errorf("WithRetry() error = %v, wantErr nil", err)
	}
	if count != 1 {
		t.Errorf("WithRetry() count = %d, want 1", count)
	}

	// Test échec puis réussite
	count = 0
	err = client.WithRetry(3, func() error {
		count++
		if count < 2 {
			return client.NewQdrantConnectionError("erreur temporaire", nil)
		}
		return nil
	})
	if err != nil {
		t.Errorf("WithRetry() error = %v, wantErr nil", err)
	}
	if count != 2 {
		t.Errorf("WithRetry() count = %d, want 2", count)
	}

	// Test échec permanent
	count = 0
	err = client.WithRetry(2, func() error {
		count++
		return client.NewQdrantConnectionError("erreur permanente", nil)
	})
	if err == nil {
		t.Error("WithRetry() error = nil, attendu erreur")
	}
	if count != 3 { // Tentative initiale + 2 retries
		t.Errorf("WithRetry() count = %d, want 3", count)
	}
}
