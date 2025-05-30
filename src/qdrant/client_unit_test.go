package qdrant_test

import (
	"testing"

	"email_sender/src/qdrant"
)

// Unit tests that don't require a running Qdrant server

func TestQdrantClient_NewClient(t *testing.T) {
	client := qdrant.NewQdrantClient("http://localhost:6333")

	if client == nil {
		t.Fatal("NewQdrantClient returned nil")
	}

	if client.BaseURL != "http://localhost:6333" {
		t.Errorf("Expected BaseURL to be 'http://localhost:6333', got '%s'", client.BaseURL)
	}

	if client.HTTPClient == nil {
		t.Error("HTTPClient should not be nil")
	}
}

func TestQdrantClient_NewClientWithCustomURL(t *testing.T) {
	customURL := "https://my-qdrant.example.com:8443"
	client := qdrant.NewQdrantClient(customURL)

	if client.BaseURL != customURL {
		t.Errorf("Expected BaseURL to be '%s', got '%s'", customURL, client.BaseURL)
	}
}

func TestSearchRequest_Structure(t *testing.T) {
	// Test that SearchRequest structure is correctly defined
	vector := []float32{1.0, 2.0, 3.0}
	req := qdrant.SearchRequest{
		Vector:      vector,
		Limit:       10,
		WithPayload: true,
	}

	if len(req.Vector) != 3 {
		t.Errorf("Expected vector length 3, got %d", len(req.Vector))
	}

	if req.Limit != 10 {
		t.Errorf("Expected limit 10, got %d", req.Limit)
	}

	if !req.WithPayload {
		t.Error("WithPayload should be true")
	}
}

func TestPoint_Structure(t *testing.T) {
	// Test that Point structure is correctly defined
	point := qdrant.Point{
		ID:     "test-id",
		Vector: []float32{1.0, 2.0, 3.0},
		Payload: map[string]interface{}{
			"key": "value",
		},
	}

	if point.ID != "test-id" {
		t.Errorf("Expected ID 'test-id', got '%v'", point.ID)
	}

	if len(point.Vector) != 3 {
		t.Errorf("Expected vector length 3, got %d", len(point.Vector))
	}

	if point.Payload["key"] != "value" {
		t.Errorf("Expected payload key 'value', got '%v'", point.Payload["key"])
	}
}
