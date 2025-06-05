package errormanager_test

import (
	"os"
	"testing"
	"time"

	errormanager "github.com/email-sender/managers/error-manager"
)

func TestPersistErrorToSQL(t *testing.T) {
	connStr := os.Getenv("POSTGRES_CONN_STR")
	if connStr == "" {
		t.Skip("POSTGRES_CONN_STR environment variable is not set")
	}

	err := errormanager.InitializePostgres(connStr)
	if err != nil {
		t.Fatalf("Failed to initialize PostgreSQL: %v", err)
	}

	entry := errormanager.ErrorEntry{
		ID:            "123e4567-e89b-12d3-a456-426614174000",
		Timestamp:     time.Now(),
		Message:       "Test error message",
		StackTrace:    "Test stack trace",
		Module:        "test-module",
		ErrorCode:     "E001",
		ManagerContext: "{\"key\": \"value\"}",
		Severity:      "ERROR",	}

	err = errormanager.PersistErrorToSQL(entry)
	if err != nil {
		t.Errorf("Failed to persist error to SQL: %v", err)
	}
}
