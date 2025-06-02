package ingestion

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// MockRAGClient for testing
type MockRAGClient struct {
	indexedItems []IndexedItem
	healthy      bool
}

type IndexedItem struct {
	ID          string
	Title       string
	Description string
	Metadata    map[string]interface{}
}

func (m *MockRAGClient) IndexRoadmapItem(ctx context.Context, itemID, title, description string, metadata map[string]interface{}) error {
	m.indexedItems = append(m.indexedItems, IndexedItem{
		ID:          itemID,
		Title:       title,
		Description: description,
		Metadata:    metadata,
	})
	return nil
}

func (m *MockRAGClient) HealthCheck(ctx context.Context) error {
	if !m.healthy {
		return context.DeadlineExceeded
	}
	return nil
}

func TestPlanIngester_Creation(t *testing.T) {
	mockRAG := &MockRAGClient{healthy: true}
	ingester := NewPlanIngester("test-dir", mockRAG)

	if ingester == nil {
		t.Fatal("Failed to create plan ingester")
	}

	if ingester.plansDir != "test-dir" {
		t.Errorf("Expected plans dir 'test-dir', got '%s'", ingester.plansDir)
	}
}

func TestPlanChunk_Creation(t *testing.T) {
	ingester := NewPlanIngester("", nil)

	ingester.createChunk("test-plan.md", "Test Header", "# Test Header", "header", 1, 1)

	if len(ingester.chunks) != 1 {
		t.Fatalf("Expected 1 chunk, got %d", len(ingester.chunks))
	}

	chunk := ingester.chunks[0]
	if chunk.PlanFile != "test-plan.md" {
		t.Errorf("Expected plan file 'test-plan.md', got '%s'", chunk.PlanFile)
	}

	if chunk.Type != "header" {
		t.Errorf("Expected type 'header', got '%s'", chunk.Type)
	}

	if chunk.Level != 1 {
		t.Errorf("Expected level 1, got %d", chunk.Level)
	}
}

func TestPlanIngester_ProcessMarkdown(t *testing.T) {
	// Create a temporary markdown file for testing
	tempDir := t.TempDir()
	testFile := filepath.Join(tempDir, "test-plan.md")

	testContent := `# Main Header

This is a section with some content.

## Sub Header

- [ ] Task item 1
- [x] Completed task
- Regular list item
- Another item

### Deep Header

Some more content here.
This depends on completion of other tasks.`

	err := os.WriteFile(testFile, []byte(testContent), 0644)
	if err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	ingester := NewPlanIngester("", nil)
	ctx := context.Background()

	err = ingester.processPlanFile(ctx, testFile)
	if err != nil {
		t.Fatalf("Failed to process plan file: %v", err)
	}

	// Verify chunks were created
	if len(ingester.chunks) == 0 {
		t.Fatal("No chunks were created")
	}

	// Check for different chunk types
	hasHeader := false
	hasTask := false
	hasListItem := false
	hasSection := false

	for _, chunk := range ingester.chunks {
		switch chunk.Type {
		case "header":
			hasHeader = true
		case "task":
			hasTask = true
		case "list_item":
			hasListItem = true
		case "section":
			hasSection = true
		}
	}

	if !hasHeader {
		t.Error("No header chunks found")
	}
	if !hasTask {
		t.Error("No task chunks found")
	}
	if !hasListItem {
		t.Error("No list item chunks found")
	}
	if !hasSection {
		t.Error("No section chunks found")
	}
}

func TestDependencyExtraction(t *testing.T) {
	ingester := NewPlanIngester("", nil)

	// Add chunks with dependency patterns
	ingester.createChunk("test.md", "Task 1", "This task depends on plan-dev-v15", "task", 0, 1)
	ingester.createChunk("test.md", "Task 2", "Requires completion of \"Database Setup\"", "task", 0, 2)
	ingester.createChunk("test.md", "Task 3", "Normal task without dependencies", "task", 0, 3)

	dependenciesFound := ingester.extractDependencies()

	if dependenciesFound == 0 {
		t.Error("No dependencies found, expected at least some")
	}

	// Check that chunks have dependencies
	foundDependencies := false
	for _, chunk := range ingester.chunks {
		if len(chunk.Dependencies) > 0 {
			foundDependencies = true
			break
		}
	}

	if !foundDependencies {
		t.Error("No chunks have dependencies assigned")
	}
}

func TestRAGIndexing(t *testing.T) {
	mockRAG := &MockRAGClient{healthy: true}
	ingester := NewPlanIngester("", mockRAG)

	// Add some test chunks
	ingester.createChunk("test.md", "Header 1", "# Test Header", "header", 1, 1)
	ingester.createChunk("test.md", "Task 1", "- [ ] Do something", "task", 0, 2)

	ctx := context.Background()
	err := ingester.indexChunksInRAG(ctx)
	if err != nil {
		t.Fatalf("Failed to index chunks in RAG: %v", err)
	}

	if len(mockRAG.indexedItems) != 2 {
		t.Errorf("Expected 2 indexed items, got %d", len(mockRAG.indexedItems))
	}

	// Verify indexed content
	for _, item := range mockRAG.indexedItems {
		if !strings.Contains(item.Title, "test.md") {
			t.Error("Indexed title should contain plan file name")
		}

		if item.Metadata["source"] != "plan_ingestion" {
			t.Error("Indexed item should have source metadata")
		}
	}
}

func TestRAGUnavailable(t *testing.T) {
	mockRAG := &MockRAGClient{healthy: false}
	ingester := NewPlanIngester("", mockRAG)

	// Add a test chunk
	ingester.createChunk("test.md", "Header 1", "# Test Header", "header", 1, 1)

	ctx := context.Background()
	err := ingester.indexChunksInRAG(ctx)
	if err == nil {
		t.Error("Expected error when RAG is unavailable")
	}
}

func TestSearchChunks(t *testing.T) {
	ingester := NewPlanIngester("", nil)

	// Add test chunks
	ingester.createChunk("test.md", "API Development", "Build REST API", "task", 0, 1)
	ingester.createChunk("test.md", "Database Setup", "Configure database", "task", 0, 2)
	ingester.createChunk("test.md", "UI Development", "Build frontend", "task", 0, 3)

	// Search for API-related chunks
	results := ingester.SearchChunks("API")

	if len(results) != 1 {
		t.Errorf("Expected 1 result for 'API', got %d", len(results))
	}

	if results[0].Title != "API Development" {
		t.Errorf("Expected 'API Development', got '%s'", results[0].Title)
	}

	// Search for non-existent content
	results = ingester.SearchChunks("NonExistent")
	if len(results) != 0 {
		t.Errorf("Expected 0 results for non-existent query, got %d", len(results))
	}
}

func TestIngestionSummary(t *testing.T) {
	ingester := NewPlanIngester("", nil)

	// Add varied test chunks
	ingester.createChunk("plan1.md", "Header 1", "# Header", "header", 1, 1)
	ingester.createChunk("plan1.md", "Task 1", "- [ ] Task", "task", 0, 2)
	ingester.createChunk("plan2.md", "Header 2", "## Header", "header", 2, 1)
	ingester.createChunk("plan2.md", "List Item", "- Item", "list_item", 0, 2)

	summary := ingester.GetIngestionSummary()

	totalChunks, ok := summary["total_chunks"].(int)
	if !ok || totalChunks != 4 {
		t.Errorf("Expected 4 total chunks, got %v", summary["total_chunks"])
	}

	chunkTypes, ok := summary["chunk_types"].(map[string]int)
	if !ok {
		t.Fatal("chunk_types not found in summary")
	}

	if chunkTypes["header"] != 2 {
		t.Errorf("Expected 2 headers, got %d", chunkTypes["header"])
	}

	if chunkTypes["task"] != 1 {
		t.Errorf("Expected 1 task, got %d", chunkTypes["task"])
	}

	planFiles, ok := summary["plan_files"].(map[string]int)
	if !ok {
		t.Fatal("plan_files not found in summary")
	}

	if planFiles["plan1.md"] != 2 {
		t.Errorf("Expected 2 chunks for plan1.md, got %d", planFiles["plan1.md"])
	}

	if planFiles["plan2.md"] != 2 {
		t.Errorf("Expected 2 chunks for plan2.md, got %d", planFiles["plan2.md"])
	}
}
