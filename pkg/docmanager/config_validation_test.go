// SPDX-License-Identifier: MIT
// Package docmanager : tests pour la validation de configuration
// TASK ATOMIQUE 3.3.1.1.2 - Configuration validation enhancement tests

package docmanager

import (
	"context"
	"os"
	"strings"
	"testing"
	"time"
)

// TestConfig_DatabaseURLValidation teste la validation des URLs de base de données
func TestConfig_DatabaseURLValidation(t *testing.T) {
	tests := []struct {
		name        string
		config      Config
		shouldError bool
		errorField  string
	}{
		{
			name: "valid postgres URL",
			config: Config{
				DatabaseURL:   "postgres://user:pass@localhost:5432/dbname",
				RedisURL:      "redis://localhost:6379",
				QDrantURL:     "http://localhost:6333",
				SyncInterval:  time.Minute,
				DefaultBranch: "main",
			},
			shouldError: false,
		},
		{
			name: "valid postgresql URL",
			config: Config{
				DatabaseURL:   "postgresql://user:pass@localhost:5432/dbname?sslmode=disable",
				RedisURL:      "redis://localhost:6379",
				QDrantURL:     "http://localhost:6333",
				SyncInterval:  time.Minute,
				DefaultBranch: "main",
			},
			shouldError: false,
		},
		{
			name: "empty database URL",
			config: Config{
				DatabaseURL:   "",
				RedisURL:      "redis://localhost:6379",
				QDrantURL:     "http://localhost:6333",
				SyncInterval:  time.Minute,
				DefaultBranch: "main",
			},
			shouldError: true,
			errorField:  "DatabaseURL",
		},
		{
			name: "invalid database URL scheme",
			config: Config{
				DatabaseURL:   "mysql://user:pass@localhost:3306/dbname",
				RedisURL:      "redis://localhost:6379",
				QDrantURL:     "http://localhost:6333",
				SyncInterval:  time.Minute,
				DefaultBranch: "main",
			},
			shouldError: true,
			errorField:  "DatabaseURL",
		},
		{
			name: "malformed database URL",
			config: Config{
				DatabaseURL:   "not-a-url",
				RedisURL:      "redis://localhost:6379",
				QDrantURL:     "http://localhost:6333",
				SyncInterval:  time.Minute,
				DefaultBranch: "main",
			},
			shouldError: true,
			errorField:  "DatabaseURL",
		},
		{
			name: "database URL without host",
			config: Config{
				DatabaseURL:   "postgres://user:pass@/dbname",
				RedisURL:      "redis://localhost:6379",
				QDrantURL:     "http://localhost:6333",
				SyncInterval:  time.Minute,
				DefaultBranch: "main",
			},
			shouldError: true,
			errorField:  "DatabaseURL",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.config.Validate()

			if tt.shouldError {
				if err == nil {
					t.Errorf("expected error for test '%s', but got none", tt.name)
				} else if tt.errorField != "" {
					// Check if error mentions the expected field
					if !strings.Contains(err.Error(), tt.errorField) {
						t.Errorf("expected error to mention field '%s', but got: %v", tt.errorField, err)
					}
				}
			} else {
				if err != nil {
					t.Errorf("unexpected error for test '%s': %v", tt.name, err)
				}
			}
		})
	}
}

// TestConfig_RedisURLValidation teste la validation des URLs Redis
func TestConfig_RedisURLValidation(t *testing.T) {
	tests := []struct {
		name        string
		redisURL    string
		shouldError bool
	}{
		{"valid redis URL", "redis://localhost:6379", false},
		{"valid rediss URL", "rediss://localhost:6379", false},
		{"redis with auth", "redis://user:pass@localhost:6379", false},
		{"redis with database", "redis://localhost:6379/0", false},
		{"empty redis URL", "", true},
		{"invalid scheme", "http://localhost:6379", true},
		{"malformed URL", "not-a-url", true},
		{"redis without host", "redis://", true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			config := Config{
				DatabaseURL:   "postgres://localhost:5432/test",
				RedisURL:      tt.redisURL,
				QDrantURL:     "http://localhost:6333",
				SyncInterval:  time.Minute,
				DefaultBranch: "main",
			}

			err := config.Validate()

			if tt.shouldError {
				if err == nil {
					t.Errorf("expected error for redis URL '%s', but got none", tt.redisURL)
				}
			} else {
				if err != nil {
					t.Errorf("unexpected error for redis URL '%s': %v", tt.redisURL, err)
				}
			}
		})
	}
}

// TestConfig_QDrantURLValidation teste la validation des URLs QDrant
func TestConfig_QDrantURLValidation(t *testing.T) {
	tests := []struct {
		name        string
		qdrantURL   string
		shouldError bool
	}{
		{"valid http URL", "http://localhost:6333", false},
		{"valid https URL", "https://qdrant.example.com:6333", false},
		{"http with path", "http://localhost:6333/collections", false},
		{"empty qdrant URL", "", true},
		{"invalid scheme", "grpc://localhost:6334", true},
		{"malformed URL", "not-a-url", true},
		{"qdrant without host", "http://", true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			config := Config{
				DatabaseURL:   "postgres://localhost:5432/test",
				RedisURL:      "redis://localhost:6379",
				QDrantURL:     tt.qdrantURL,
				SyncInterval:  time.Minute,
				DefaultBranch: "main",
			}

			err := config.Validate()

			if tt.shouldError {
				if err == nil {
					t.Errorf("expected error for qdrant URL '%s', but got none", tt.qdrantURL)
				}
			} else {
				if err != nil {
					t.Errorf("unexpected error for qdrant URL '%s': %v", tt.qdrantURL, err)
				}
			}
		})
	}
}

// TestConfig_InfluxDBURLValidation teste la validation des URLs InfluxDB (optionnel)
func TestConfig_InfluxDBURLValidation(t *testing.T) {
	tests := []struct {
		name        string
		influxURL   string
		shouldError bool
	}{
		{"empty influx URL (optional)", "", false},
		{"valid http URL", "http://localhost:8086", false},
		{"valid https URL", "https://influx.example.com:8086", false},
		{"http with database", "http://localhost:8086/query?db=mydb", false},
		{"invalid scheme", "influx://localhost:8086", true},
		{"malformed URL", "not-a-url", true},
		{"influx without host", "http://", true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			config := Config{
				DatabaseURL:   "postgres://localhost:5432/test",
				RedisURL:      "redis://localhost:6379",
				QDrantURL:     "http://localhost:6333",
				InfluxDBURL:   tt.influxURL,
				SyncInterval:  time.Minute,
				DefaultBranch: "main",
			}

			err := config.Validate()

			if tt.shouldError {
				if err == nil {
					t.Errorf("expected error for influx URL '%s', but got none", tt.influxURL)
				}
			} else {
				if err != nil {
					t.Errorf("unexpected error for influx URL '%s': %v", tt.influxURL, err)
				}
			}
		})
	}
}

// TestConfig_SyncIntervalValidation teste la validation des intervalles de synchronisation
func TestConfig_SyncIntervalValidation(t *testing.T) {
	tests := []struct {
		name        string
		interval    time.Duration
		shouldError bool
	}{
		{"valid 1 second", time.Second, false},
		{"valid 1 minute", time.Minute, false},
		{"valid 1 hour", time.Hour, false},
		{"zero interval", 0, true},
		{"negative interval", -time.Second, true},
		{"too short interval", 500 * time.Millisecond, true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			config := Config{
				DatabaseURL:   "postgres://localhost:5432/test",
				RedisURL:      "redis://localhost:6379",
				QDrantURL:     "http://localhost:6333",
				SyncInterval:  tt.interval,
				DefaultBranch: "main",
			}

			err := config.Validate()

			if tt.shouldError {
				if err == nil {
					t.Errorf("expected error for sync interval '%s', but got none", tt.interval)
				}
			} else {
				if err != nil {
					t.Errorf("unexpected error for sync interval '%s': %v", tt.interval, err)
				}
			}
		})
	}
}

// TestConfig_DefaultBranchValidation teste la validation des noms de branche
func TestConfig_DefaultBranchValidation(t *testing.T) {
	tests := []struct {
		name        string
		branch      string
		shouldError bool
	}{
		{"valid main", "main", false},
		{"valid master", "master", false},
		{"valid dev", "dev", false},
		{"valid feature branch", "feature/new-feature", false},
		{"valid numbered branch", "release-1.0", false},
		{"empty branch", "", true},
		{"branch with double dots", "feature..branch", true},
		{"branch with double slashes", "feature//branch", true},
		{"branch starting with dot", ".hidden", true},
		{"branch ending with slash", "feature/", true},
		{"invalid characters", "feature@branch", true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			config := Config{
				DatabaseURL:   "postgres://localhost:5432/test",
				RedisURL:      "redis://localhost:6379",
				QDrantURL:     "http://localhost:6333",
				SyncInterval:  time.Minute,
				DefaultBranch: tt.branch,
			}

			err := config.Validate()

			if tt.shouldError {
				if err == nil {
					t.Errorf("expected error for branch '%s', but got none", tt.branch)
				}
			} else {
				if err != nil {
					t.Errorf("unexpected error for branch '%s': %v", tt.branch, err)
				}
			}
		})
	}
}

// TestConfig_EnvironmentVariableSubstitution teste la substitution des variables d'environnement
func TestConfig_EnvironmentVariableSubstitution(t *testing.T) {
	// Set up test environment variables
	os.Setenv("TEST_DB_HOST", "testhost")
	os.Setenv("TEST_DB_PORT", "5432")
	os.Setenv("TEST_DB_NAME", "testdb")
	defer func() {
		os.Unsetenv("TEST_DB_HOST")
		os.Unsetenv("TEST_DB_PORT")
		os.Unsetenv("TEST_DB_NAME")
	}()

	tests := []struct {
		name        string
		configURL   string
		expectedURL string
	}{
		{
			name:        "substitute ${VAR} format",
			configURL:   "postgres://user:pass@${TEST_DB_HOST}:${TEST_DB_PORT}/${TEST_DB_NAME}",
			expectedURL: "postgres://user:pass@testhost:5432/testdb",
		},
		{
			name:        "substitute $VAR format",
			configURL:   "postgres://user:pass@$TEST_DB_HOST:$TEST_DB_PORT/$TEST_DB_NAME",
			expectedURL: "postgres://user:pass@testhost:5432/testdb",
		},
		{
			name:        "mixed format",
			configURL:   "postgres://user:pass@${TEST_DB_HOST}:$TEST_DB_PORT/${TEST_DB_NAME}",
			expectedURL: "postgres://user:pass@testhost:5432/testdb",
		},
		{
			name:        "undefined variable remains unchanged",
			configURL:   "postgres://user:pass@${UNDEFINED_VAR}:5432/testdb",
			expectedURL: "postgres://user:pass@${UNDEFINED_VAR}:5432/testdb",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			config := Config{
				DatabaseURL:   tt.configURL,
				RedisURL:      "redis://localhost:6379",
				QDrantURL:     "http://localhost:6333",
				SyncInterval:  time.Minute,
				DefaultBranch: "main",
			}

			substituted := config.substituteEnvironmentVariables()

			if substituted.DatabaseURL != tt.expectedURL {
				t.Errorf("expected URL '%s', got '%s'", tt.expectedURL, substituted.DatabaseURL)
			}
		})
	}
}

// TestConfig_ValidateDetailed teste la validation détaillée avec résultats complets
func TestConfig_ValidateDetailed(t *testing.T) {
	config := Config{
		DatabaseURL:   "postgres://user:pass@localhost:5432/test",
		RedisURL:      "redis://localhost:6379",
		QDrantURL:     "http://localhost:6333",
		SyncInterval:  5 * time.Second, // Short interval to trigger warning
		DefaultBranch: "feature/test",  // Non-standard branch to trigger warning
	}

	result := config.ValidateDetailed()

	if !result.IsValid {
		t.Errorf("expected valid configuration, but got errors: %v", result.Errors)
	}

	// Should have warnings about short interval and non-standard branch
	if len(result.Warnings) == 0 {
		t.Error("expected warnings for short interval and non-standard branch")
	}
	// Check for specific warnings
	hasIntervalWarning := false
	hasBranchWarning := false
	for _, warning := range result.Warnings {
		if strings.Contains(warning, "short sync interval") {
			hasIntervalWarning = true
		}
		if strings.Contains(warning, "Non-standard default branch") {
			hasBranchWarning = true
		}
	}

	if !hasIntervalWarning {
		t.Error("expected warning about short sync interval")
	}
	if !hasBranchWarning {
		t.Error("expected warning about non-standard branch name")
	}
}

// TestConfig_TestConnectivity teste la vérification de connectivité
func TestConfig_TestConnectivity(t *testing.T) {
	// Note: Ce test nécessite que les services soient réellement disponibles
	// En environnement de test, nous testons juste que la méthode ne panic pas
	config := Config{
		DatabaseURL:   "postgres://localhost:5432/test",
		RedisURL:      "redis://localhost:6379",
		QDrantURL:     "http://localhost:6333",
		SyncInterval:  time.Minute,
		DefaultBranch: "main",
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// La méthode ne devrait pas paniquer même si les services ne sont pas disponibles
	results := config.TestConnectivity(ctx)

	// Vérifier que tous les services attendus sont testés
	expectedServices := []string{"database", "redis", "qdrant"}
	for _, service := range expectedServices {
		if _, exists := results[service]; !exists {
			t.Errorf("expected connectivity test for service '%s'", service)
		}
	}

	// InfluxDB est optionnel, ne devrait pas être testé si pas configuré
	if _, exists := results["influxdb"]; exists {
		t.Error("InfluxDB connectivity should not be tested when URL is empty")
	}
}

// TestConfig_TestConnectivity_WithInfluxDB teste la connectivité avec InfluxDB configuré
func TestConfig_TestConnectivity_WithInfluxDB(t *testing.T) {
	config := Config{
		DatabaseURL:   "postgres://localhost:5432/test",
		RedisURL:      "redis://localhost:6379",
		QDrantURL:     "http://localhost:6333",
		InfluxDBURL:   "http://localhost:8086",
		SyncInterval:  time.Minute,
		DefaultBranch: "main",
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	results := config.TestConnectivity(ctx)
	// InfluxDB devrait être testé maintenant
	if _, exists := results["influxdb"]; !exists {
		t.Error("expected InfluxDB connectivity test when URL is configured")
	}
}
