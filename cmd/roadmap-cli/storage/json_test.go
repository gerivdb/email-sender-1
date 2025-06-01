package storage

import (
	"os"
	"path/filepath"
	"testing"
	"time"

	"email_sender/cmd/roadmap-cli/types"

	"github.com/google/uuid"
)

func TestJSONStorage_CreateItem(t *testing.T) {
	// Create temporary file for testing
	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "test_roadmap.json")

	storage, err := NewJSONStorage(testFile)
	if err != nil {
		t.Fatalf("Failed to create JSON storage: %v", err)
	}
	defer storage.Close()

	// Test item creation
	title := "Test Item"
	description := "Test Description"
	priority := "high"
	targetDate := time.Now().AddDate(0, 0, 30)

	item, err := storage.CreateItem(title, description, priority, targetDate)
	if err != nil {
		t.Fatalf("Failed to create item: %v", err)
	}
	// Validate item properties
	if item.Title != title {
		t.Errorf("Expected title %s, got %s", title, item.Title)
	}
	if item.Description != description {
		t.Errorf("Expected description %s, got %s", description, item.Description)
	}
	if item.Priority != types.Priority(priority) {
		t.Errorf("Expected priority %s, got %s", priority, item.Priority)
	}
	if item.Status != types.StatusPlanned {
		t.Errorf("Expected status planned, got %s", item.Status)
	}

	// Validate UUID format
	if _, err := uuid.Parse(item.ID); err != nil {
		t.Errorf("Invalid UUID format: %s", item.ID)
	}
}

func TestJSONStorage_CreateMilestone(t *testing.T) {
	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "test_roadmap.json")

	storage, err := NewJSONStorage(testFile)
	if err != nil {
		t.Fatalf("Failed to create JSON storage: %v", err)
	}
	defer storage.Close()

	title := "Test Milestone"
	description := "Test Milestone Description"
	targetDate := time.Now().AddDate(0, 0, 60)

	milestone, err := storage.CreateMilestone(title, description, targetDate)
	if err != nil {
		t.Fatalf("Failed to create milestone: %v", err)
	}

	if milestone.Title != title {
		t.Errorf("Expected title %s, got %s", title, milestone.Title)
	}
	if milestone.Description != description {
		t.Errorf("Expected description %s, got %s", description, milestone.Description)
	}
}

func TestJSONStorage_GetItems(t *testing.T) {
	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "test_roadmap.json")

	storage, err := NewJSONStorage(testFile)
	if err != nil {
		t.Fatalf("Failed to create JSON storage: %v", err)
	}
	defer storage.Close()

	// Create multiple items
	items := []struct {
		title    string
		priority string
	}{
		{"Item 1", "high"},
		{"Item 2", "medium"},
		{"Item 3", "low"},
	}

	for _, item := range items {
		_, err := storage.CreateItem(item.title, "Description", item.priority, time.Now().AddDate(0, 0, 30))
		if err != nil {
			t.Fatalf("Failed to create item: %v", err)
		}
	}

	// Retrieve items
	retrievedItems, err := storage.GetAllItems()
	if err != nil {
		t.Fatalf("Failed to get items: %v", err)
	}

	if len(retrievedItems) != len(items) {
		t.Errorf("Expected %d items, got %d", len(items), len(retrievedItems))
	}
}

func TestJSONStorage_Persistence(t *testing.T) {
	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "test_roadmap.json")

	// Create storage and add an item
	storage1, err := NewJSONStorage(testFile)
	if err != nil {
		t.Fatalf("Failed to create JSON storage: %v", err)
	}

	item, err := storage1.CreateItem("Persistent Item", "Description", "medium", time.Now().AddDate(0, 0, 30))
	if err != nil {
		t.Fatalf("Failed to create item: %v", err)
	}
	storage1.Close()

	// Verify file exists
	if _, err := os.Stat(testFile); os.IsNotExist(err) {
		t.Fatal("Storage file was not created")
	}

	// Create new storage instance and verify item persists
	storage2, err := NewJSONStorage(testFile)
	if err != nil {
		t.Fatalf("Failed to recreate JSON storage: %v", err)
	}
	defer storage2.Close()

	items, err := storage2.GetAllItems()
	if err != nil {
		t.Fatalf("Failed to get items: %v", err)
	}

	if len(items) != 1 {
		t.Errorf("Expected 1 item, got %d", len(items))
	}

	if items[0].ID != item.ID {
		t.Errorf("Item ID mismatch: expected %s, got %s", item.ID, items[0].ID)
	}
}

func TestJSONStorage_UpdateItemStatus(t *testing.T) {
	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "test_roadmap.json")

	storage, err := NewJSONStorage(testFile)
	if err != nil {
		t.Fatalf("Failed to create JSON storage: %v", err)
	}
	defer storage.Close()

	// Create an item
	item, err := storage.CreateItem("Test Item", "Description", "medium", time.Now().AddDate(0, 0, 30))
	if err != nil {
		t.Fatalf("Failed to create item: %v", err)
	}

	// Update status
	err = storage.UpdateItemStatus(item.ID, "in-progress", 50)
	if err != nil {
		t.Fatalf("Failed to update item status: %v", err)
	}

	// Verify update
	items, err := storage.GetAllItems()
	if err != nil {
		t.Fatalf("Failed to get items: %v", err)
	}

	found := false
	for _, retrievedItem := range items {
		if retrievedItem.ID == item.ID {
			if retrievedItem.Status != "in-progress" {
				t.Errorf("Expected status 'in-progress', got '%s'", retrievedItem.Status)
			}
			found = true
			break
		}
	}

	if !found {
		t.Error("Updated item not found")
	}
}

func TestJSONStorage_CreateEnrichedItems(t *testing.T) {
	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "test_enriched_roadmap.json")

	storage, err := NewJSONStorage(testFile)
	if err != nil {
		t.Fatalf("Failed to create JSON storage: %v", err)
	}
	defer storage.Close()

	// Create test enriched items
	enrichedOptions := []types.EnrichedItemOptions{
		{
			Title:         "Enhanced Task 1",
			Description:   "First enriched task",
			Priority:      "high",
			Status:        "planned",
			TargetDate:    time.Now().AddDate(0, 0, 30),
			Complexity:    "medium",
			RiskLevel:     "low",
			Effort:        5,
			BusinessValue: 8,
			TechnicalDebt: 2,
			Tools:         []string{"Go", "Docker"},
			Prerequisites: []string{"Setup environment"},
			Tags:          []string{"backend", "api"},
		},
		{
			Title:         "Enhanced Task 2",
			Description:   "Second enriched task",
			Priority:      "medium",
			Status:        "planned",
			TargetDate:    time.Now().AddDate(0, 0, 45),
			Complexity:    "high",
			RiskLevel:     "medium",
			Effort:        8,
			BusinessValue: 6,
			TechnicalDebt: 3,
			Tools:         []string{"React", "TypeScript"},
			Prerequisites: []string{"Backend API", "Database schema"},
			Tags:          []string{"frontend", "ui"},
		},
	}

	// Test batch creation
	createdItems, err := storage.CreateEnrichedItems(enrichedOptions)
	if err != nil {
		t.Fatalf("Failed to create enriched items: %v", err)
	}

	// Validate batch creation
	if len(createdItems) != len(enrichedOptions) {
		t.Errorf("Expected %d items, got %d", len(enrichedOptions), len(createdItems))
	}

	// Validate first item
	item1 := createdItems[0]
	if item1.Title != "Enhanced Task 1" {
		t.Errorf("Expected title 'Enhanced Task 1', got %s", item1.Title)
	}
	if item1.Complexity != "medium" {
		t.Errorf("Expected complexity 'medium', got %s", item1.Complexity)
	}
	if item1.RiskLevel != "low" {
		t.Errorf("Expected risk level 'low', got %s", item1.RiskLevel)
	}
	if len(item1.Tools) != 2 {
		t.Errorf("Expected 2 tools, got %d", len(item1.Tools))
	}
	if item1.Effort != 5 {
		t.Errorf("Expected effort 5, got %d", item1.Effort)
	}

	// Validate second item
	item2 := createdItems[1]
	if item2.Title != "Enhanced Task 2" {
		t.Errorf("Expected title 'Enhanced Task 2', got %s", item2.Title)
	}
	if len(item2.Prerequisites) != 2 {
		t.Errorf("Expected 2 prerequisites, got %d", len(item2.Prerequisites))
	}

	// Verify items are persisted
	allItems, err := storage.GetAllItems()
	if err != nil {
		t.Fatalf("Failed to get all items: %v", err)
	}

	if len(allItems) != 2 {
		t.Errorf("Expected 2 persisted items, got %d", len(allItems))
	}

	// Validate UUIDs are unique
	if allItems[0].ID == allItems[1].ID {
		t.Error("Item IDs should be unique")
	}
}
