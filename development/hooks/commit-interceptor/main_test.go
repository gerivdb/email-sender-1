// development/hooks/commit-interceptor/main_test.go
package commit_interceptor

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestCommitInterceptor_HandlePreCommit(t *testing.T) {
	// Create test interceptor
	config := getDefaultConfig()
	config.TestMode = true // Enable test mode to avoid actual Git operations
	interceptor := &CommitInterceptor{
		branchingManager: NewBranchingManager(config),
		analyzer:         NewCommitAnalyzer(config),
		router:           NewBranchRouter(config),
		config:           config,
	}

	// Create test payload
	payload := GitWebhookPayload{
		Commits: []struct {
			ID        string    `json:"id"`
			Message   string    `json:"message"`
			Timestamp time.Time `json:"timestamp"`
			Author    struct {
				Name  string `json:"name"`
				Email string `json:"email"`
			} `json:"author"`
			Added    []string `json:"added"`
			Removed  []string `json:"removed"`
			Modified []string `json:"modified"`
		}{
			{
				ID:        "abc123",
				Message:   "feat: add new user authentication",
				Timestamp: time.Now(),
				Author: struct {
					Name  string `json:"name"`
					Email string `json:"email"`
				}{
					Name:  "Test User",
					Email: "test@example.com",
				},
				Added:    []string{"auth.go", "user.go"},
				Modified: []string{"main.go"},
			},
		},
		Repository: struct {
			Name     string `json:"name"`
			FullName string `json:"full_name"`
		}{
			Name:     "test-repo",
			FullName: "user/test-repo",
		},
		Ref: "refs/heads/main",
	}

	jsonPayload, _ := json.Marshal(payload)

	// Create test request
	req := httptest.NewRequest("POST", "/hooks/pre-commit", bytes.NewReader(jsonPayload))
	req.Header.Set("Content-Type", "application/json")

	// Create response recorder
	rr := httptest.NewRecorder()

	// Call handler
	interceptor.HandlePreCommit(rr, req)

	// Check response
	if rr.Code != http.StatusOK {
		t.Errorf("Expected status code %d, got %d", http.StatusOK, rr.Code)
	}

	responseBody := rr.Body.String()
	if responseBody == "" {
		t.Error("Expected response body, got empty string")
	}
}

func TestCommitInterceptor_HandlePostCommit(t *testing.T) {
	config := getDefaultConfig()
	config.TestMode = true // Enable test mode to avoid actual Git operations
	interceptor := &CommitInterceptor{
		branchingManager: NewBranchingManager(config),
		analyzer:         NewCommitAnalyzer(config),
		router:           NewBranchRouter(config),
		config:           config,
	}

	// Create simple test payload
	payload := GitWebhookPayload{
		Commits: []struct {
			ID        string    `json:"id"`
			Message   string    `json:"message"`
			Timestamp time.Time `json:"timestamp"`
			Author    struct {
				Name  string `json:"name"`
				Email string `json:"email"`
			} `json:"author"`
			Added    []string `json:"added"`
			Removed  []string `json:"removed"`
			Modified []string `json:"modified"`
		}{
			{
				ID:      "def456",
				Message: "fix: resolve authentication bug",
				Author: struct {
					Name  string `json:"name"`
					Email string `json:"email"`
				}{
					Name:  "Test User",
					Email: "test@example.com",
				},
				Modified: []string{"auth.go"},
			},
		},
	}

	jsonPayload, _ := json.Marshal(payload)
	req := httptest.NewRequest("POST", "/hooks/post-commit", bytes.NewReader(jsonPayload))
	rr := httptest.NewRecorder()

	interceptor.HandlePostCommit(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("Expected status code %d, got %d", http.StatusOK, rr.Code)
	}
}

func TestCommitInterceptor_HandleHealth(t *testing.T) {
	config := getDefaultConfig()
	config.TestMode = true // Enable test mode for consistency
	interceptor := &CommitInterceptor{
		config: config,
	}

	req := httptest.NewRequest("GET", "/health", nil)
	rr := httptest.NewRecorder()

	interceptor.HandleHealth(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("Expected status code %d, got %d", http.StatusOK, rr.Code)
	}

	if rr.Body.String() != "OK" {
		t.Errorf("Expected 'OK', got '%s'", rr.Body.String())
	}
}

func TestCommitInterceptor_SetupRoutes(t *testing.T) {
	config := getDefaultConfig()
	config.TestMode = true // Enable test mode for consistency
	interceptor := &CommitInterceptor{
		config: config,
	}

	router := interceptor.setupRoutes()

	// Test that routes are properly configured
	routes := []string{
		"/hooks/pre-commit",
		"/hooks/post-commit",
		"/health",
		"/metrics",
	}

	for _, route := range routes {
		req := httptest.NewRequest("GET", route, nil)
		rr := httptest.NewRecorder()
		router.ServeHTTP(rr, req)

		// Should not get 404 for configured routes
		if rr.Code == http.StatusNotFound {
			t.Errorf("Route %s returned 404, should be configured", route)
		}
	}
}
