package roadmapconnector

import (
	"testing"
)

func TestRoadmapConnector(t *testing.T) {
	// Test creating a new connector
	connector := NewRoadmapConnector("https://example.com/api", "test-token")
	if connector == nil {
		t.Fatal("Failed to create RoadmapConnector")
	}

	// Test connection validation
	err := connector.Connect()
	if err != nil {
		t.Fatalf("Connect failed: %v", err)
	}

	// Test connection with empty URL
	invalidConnector := NewRoadmapConnector("", "test-token")
	err = invalidConnector.Connect()
	if err == nil {
		t.Error("Expected error for empty URL, got nil")
	}

	// Test connection with empty token
	invalidConnector = NewRoadmapConnector("https://example.com/api", "")
	err = invalidConnector.Connect()
	if err == nil {
		t.Error("Expected error for empty token, got nil")
	}
}
