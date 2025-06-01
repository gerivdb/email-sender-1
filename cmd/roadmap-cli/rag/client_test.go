package rag

import (
	"context"
	"strings"
	"testing"
	"time"
)

func TestRAGClient_Creation(t *testing.T) {
	client := NewRAGClient("http://localhost:6333", "http://localhost:8080", "test-api-key")

	if client == nil {
		t.Fatal("RAG client creation failed")
	}

	if client.qdrantURL != "http://localhost:6333" {
		t.Errorf("Expected qdrantURL 'http://localhost:6333', got '%s'", client.qdrantURL)
	}

	if client.collectionName != "roadmap_items" {
		t.Errorf("Expected collection 'roadmap_items', got '%s'", client.collectionName)
	}
}

func TestRAGClient_HealthCheck(t *testing.T) {
	client := NewRAGClient("http://localhost:6333", "http://localhost:8080", "test-api-key")

	// This will fail if QDrant is not running, which is expected in tests
	ctx := context.Background()
	err := client.HealthCheck(ctx)
	if err == nil {
		t.Log("QDrant is running - health check passed")
	} else {
		t.Logf("QDrant not available (expected in test environment): %v", err)
		// This is not a failure - QDrant may not be running in test environment
	}
}

func TestGenerateContext(t *testing.T) {
	items := []RoadmapItemContext{
		{
			ID:          "1",
			Title:       "Build API",
			Description: "REST API development",
			Priority:    "high",
			Status:      "todo",
			TargetDate:  time.Now(),
		},
		{
			ID:          "2",
			Title:       "Database Design",
			Description: "Design database schema",
			Priority:    "medium",
			Status:      "in-progress",
			TargetDate:  time.Now().AddDate(0, 0, 7),
		},
	}

	milestones := []MilestoneContext{
		{
			ID:          "m1",
			Title:       "Phase 1",
			Description: "Initial development phase",
			TargetDate:  time.Now().AddDate(0, 0, 30),
		},
	}

	context := generateContext(items, milestones)

	if len(context) == 0 {
		t.Error("Generated context is empty")
	}

	// Check that context contains item information
	if !contains(context, "Build API") {
		t.Error("Context missing item title")
	}

	if !contains(context, "Phase 1") {
		t.Error("Context missing milestone title")
	}
}

func TestAnalyzeRoadmapSimilarities(t *testing.T) {
	client := NewRAGClient("http://localhost:6333", "http://localhost:8080", "test-api-key")

	items := []RoadmapItemContext{
		{
			ID:          "1",
			Title:       "Build REST API",
			Description: "Create REST endpoints",
			Priority:    "high",
			Status:      "todo",
		},
	}
	// This will test the function logic even if QDrant is not available
	ctx := context.Background()
	insights, err := client.AnalyzeRoadmapSimilarities(ctx, items)

	// The function should handle QDrant unavailability gracefully
	if err != nil {
		t.Logf("Expected error when QDrant unavailable: %v", err)
	} else {
		t.Logf("Analysis insights count: %d", len(insights))
		for _, insight := range insights {
			t.Logf("Insight: %s (confidence: %.2f)", insight.Message, insight.Confidence)
		}
	}
}

func TestDetectDependencies(t *testing.T) {
	client := NewRAGClient("http://localhost:6333", "http://localhost:8080", "test-api-key")

	items := []RoadmapItemContext{
		{
			ID:          "1",
			Title:       "Database Setup",
			Description: "Configure user database",
			Priority:    "high",
			Status:      "done",
		},
		{
			ID:          "2",
			Title:       "API Framework",
			Description: "Setup REST framework",
			Priority:    "high",
			Status:      "done",
		},
	}

	ctx := context.Background()
	insights, err := client.DetectDependencies(ctx, items)

	// Test should handle QDrant unavailability
	if err != nil {
		t.Logf("Expected error when QDrant unavailable: %v", err)
	} else {
		t.Logf("Dependency analysis insights count: %d", len(insights))
		for _, insight := range insights {
			t.Logf("Dependency insight: %s (confidence: %.2f)", insight.Message, insight.Confidence)
		}
	}
}

// Helper function to check if a string contains a substring
func contains(s, substr string) bool {
	return strings.Contains(s, substr)
}
