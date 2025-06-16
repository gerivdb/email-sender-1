package integration

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"email_sender/pkg/fmoua/types"

	"go.uber.org/zap"
)

// Test webhook server handler wrapping to improve wrapHandler coverage
func TestHTTPWebhookServer_WrapHandler_Coverage(t *testing.T) {
	// Create a webhook server with proper config
	config := types.WebhookServerConfig{
		Host:         "localhost",
		Port:         8080,
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  60 * time.Second,
	}
	logger := zap.NewNop()
	server := NewHTTPWebhookServer(config, logger)

	// Create a test handler that exercises different response codes
	testHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/success":
			w.WriteHeader(http.StatusOK)
			w.Write([]byte("success"))
		case "/created":
			w.WriteHeader(http.StatusCreated)
			w.Write([]byte("created"))
		case "/error":
			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte("error"))
		case "/not-found":
			w.WriteHeader(http.StatusNotFound)
			w.Write([]byte("not found"))
		default:
			w.WriteHeader(http.StatusAccepted)
			w.Write([]byte("default"))
		}
	})

	// Get the wrapped handler
	wrappedHandler := server.wrapHandler(testHandler)

	// Test various request combinations
	testCases := []struct {
		name         string
		method       string
		path         string
		expectedCode int
	}{
		{"GET success", "GET", "/success", http.StatusOK},
		{"POST created", "POST", "/created", http.StatusCreated},
		{"PUT error", "PUT", "/error", http.StatusInternalServerError},
		{"DELETE not found", "DELETE", "/not-found", http.StatusNotFound},
		{"PATCH default", "PATCH", "/default", http.StatusAccepted},
		{"HEAD success", "HEAD", "/success", http.StatusOK},
		{"OPTIONS error", "OPTIONS", "/error", http.StatusInternalServerError},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			req := httptest.NewRequest(tc.method, tc.path, nil)
			w := httptest.NewRecorder()

			wrappedHandler.ServeHTTP(w, req)

			if w.Code != tc.expectedCode {
				t.Errorf("Expected status %d, got %d", tc.expectedCode, w.Code)
			}
		})
	}
}

// Test responseWriter WriteHeader method directly
func TestResponseWriter_WriteHeader_Complete(t *testing.T) {
	// Test WriteHeader directly
	t.Run("WriteHeader_DirectCall", func(t *testing.T) {
		recorder := httptest.NewRecorder()
		rw := &responseWriter{
			ResponseWriter: recorder,
			statusCode:     200,
		}
		// Test initial WriteHeader call
		rw.WriteHeader(http.StatusCreated)
		if rw.statusCode != http.StatusCreated {
			t.Errorf("Expected status code %d, got %d", http.StatusCreated, rw.statusCode)
		}

		// Test subsequent WriteHeader calls should be ignored
		rw.WriteHeader(http.StatusBadRequest)
		if rw.statusCode != http.StatusCreated {
			t.Errorf("Expected status code to remain %d, got %d", http.StatusCreated, rw.statusCode)
		}

		// Verify the underlying ResponseWriter received the first status
		if recorder.Code != http.StatusCreated {
			t.Errorf("Expected recorder status %d, got %d", http.StatusCreated, recorder.Code)
		}
	})

	// Test WriteHeader through HTTP handler chain
	t.Run("WriteHeader_ThroughHandler", func(t *testing.T) {
		config := types.WebhookServerConfig{
			Host:         "localhost",
			Port:         8080,
			ReadTimeout:  30 * time.Second,
			WriteTimeout: 30 * time.Second,
			IdleTimeout:  60 * time.Second,
		}
		logger := zap.NewNop()
		server := NewHTTPWebhookServer(config, logger)

		// Handler that calls WriteHeader multiple times
		testHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(http.StatusAccepted)
			w.WriteHeader(http.StatusConflict) // This should be ignored
			w.Write([]byte("response"))
		})

		wrappedHandler := server.wrapHandler(testHandler)

		req := httptest.NewRequest("POST", "/test", nil)
		w := httptest.NewRecorder()

		wrappedHandler.ServeHTTP(w, req)

		// Should get the first status code only
		if w.Code != http.StatusAccepted {
			t.Errorf("Expected status %d, got %d", http.StatusAccepted, w.Code)
		}
	})
}
