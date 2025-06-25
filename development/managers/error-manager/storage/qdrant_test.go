package errormanager_test

import (
	"os"
	"testing"

	errormanager "github.com/gerivdb/email-sender-1/managers/error-manager"
)

func TestStoreErrorVector(t *testing.T) {
	endpoint := os.Getenv("QDRANT_ENDPOINT")
	if endpoint == "" {
		t.Skip("QDRANT_ENDPOINT environment variable is not set")
	}

	err := errormanager.InitializeQdrant(endpoint)
	if err != nil {
		t.Fatalf("Failed to initialize Qdrant: %v", err)
	}

	vector := []float32{0.1, 0.2, 0.3}
	payload := map[string]interface{}{
		"id":      "123e4567-e89b-12d3-a456-426614174000",
		"message": "Test error message",
		"module":  "test-module",
	}

	err = errormanager.StoreErrorVector("project_errors_vectors", vector, payload)
	if err != nil {
		t.Errorf("Failed to store error vector: %v", err)
	}
}
