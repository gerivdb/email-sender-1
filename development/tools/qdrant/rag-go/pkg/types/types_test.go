package types_test

import (
	"testing"
	"time"

	"rag-go-system/pkg/types"
)

// TestDocument tests the Document struct
func TestDocument(t *testing.T) {
	// Test creation
	doc := types.NewDocument("Test content")
	if doc.Content != "Test content" {
		t.Errorf("Expected content 'Test content', got '%s'", doc.Content)
	}

	// Test validation
	if err := doc.Validate(); err != nil {
		t.Errorf("Expected valid document, got error: %v", err)
	}

	// Test metadata
	doc.SetMetadata("key", "value")
	value, exists := doc.GetMetadata("key")
	if !exists {
		t.Error("Expected metadata key to exist")
	}
	if value != "value" {
		t.Errorf("Expected metadata value 'value', got '%v'", value)
	}

	// Test source
	doc.SetSource("test-source")
	if doc.GetSource() != "test-source" {
		t.Errorf("Expected source 'test-source', got '%s'", doc.GetSource())
	}

	// Test timestamps
	now := time.Now()
	doc.SetCreatedAt(now)
	createdAt := doc.GetCreatedAt()
	if createdAt == nil {
		t.Error("Expected non-nil created_at timestamp")
	} else if !createdAt.Equal(now) {
		t.Errorf("Expected created_at %v, got %v", now, *createdAt)
	}

	// Test JSON serialization
	data, err := doc.ToJSON()
	if err != nil {
		t.Errorf("Expected successful JSON serialization, got error: %v", err)
	}

	// Test JSON deserialization
	newDoc := &types.Document{}
	if err := newDoc.FromJSON(data); err != nil {
		t.Errorf("Expected successful JSON deserialization, got error: %v", err)
	}

	// Test vector dimension
	vector := make([]float32, 384)
	doc.SetVector(vector)
	if dim := doc.GetVectorDimension(); dim != 384 {
		t.Errorf("Expected vector dimension 384, got %d", dim)
	}
}

// TestSearchResult tests the SearchResult struct
func TestSearchResult(t *testing.T) {
	// Test creation
	doc := types.NewDocument("Test content")
	result := types.NewSearchResult(doc, 0.95, 1)
	if result.Score != 0.95 {
		t.Errorf("Expected score 0.95, got %f", result.Score)
	}

	// Test validation
	if err := result.Validate(); err != nil {
		t.Errorf("Expected valid search result, got error: %v", err)
	}

	// Test relevance check
	if !result.IsRelevant(0.9) {
		t.Errorf("Expected result to be relevant with threshold 0.9")
	}
	if result.IsRelevant(0.96) {
		t.Errorf("Expected result to not be relevant with threshold 0.96")
	}

	// Test snippet generation
	snippet := result.GenerateSnippet("Test", 50)
	if snippet != "Test content" {
		t.Errorf("Expected snippet 'Test content', got '%s'", snippet)
	}

	// Test JSON serialization
	data, err := result.ToJSON()
	if err != nil {
		t.Errorf("Expected successful JSON serialization, got error: %v", err)
	}

	// Test JSON deserialization
	newResult := &types.SearchResult{}
	if err := newResult.FromJSON(data); err != nil {
		t.Errorf("Expected successful JSON deserialization, got error: %v", err)
	}
}

// TestCollection tests the Collection struct
func TestCollection(t *testing.T) {
	// Test creation
	collection := types.NewCollection("test-collection", 384, types.DistanceCosine)
	if collection.Name != "test-collection" {
		t.Errorf("Expected name 'test-collection', got '%s'", collection.Name)
	}

	// Test validation
	if err := collection.Validate(); err != nil {
		t.Errorf("Expected valid collection, got error: %v", err)
	}

	// Test document count
	collection.UpdateDocumentCount(10)
	if collection.DocumentCount != 10 {
		t.Errorf("Expected document count 10, got %d", collection.DocumentCount)
	}

	// Test increment document count
	collection.IncrementDocumentCount(5)
	if collection.DocumentCount != 15 {
		t.Errorf("Expected document count 15, got %d", collection.DocumentCount)
	}

	// Test JSON serialization
	data, err := collection.ToJSON()
	if err != nil {
		t.Errorf("Expected successful JSON serialization, got error: %v", err)
	}

	// Test JSON deserialization
	newCollection := &types.Collection{}
	if err := newCollection.FromJSON(data); err != nil {
		t.Errorf("Expected successful JSON deserialization, got error: %v", err)
	}

	// Test emptiness check
	if collection.IsEmpty() {
		t.Errorf("Expected collection to not be empty")
	}

	// Test age
	age := collection.GetAge()
	if age < 0 {
		t.Errorf("Expected non-negative age, got %v", age)
	}
}

// TestCollectionManager tests the CollectionManager struct
func TestCollectionManager(t *testing.T) {
	// Test creation
	manager := types.NewCollectionManager()
	if manager.GetCollectionCount() != 0 {
		t.Errorf("Expected empty collection manager, got %d collections", manager.GetCollectionCount())
	}

	// Test create collection
	config := types.CollectionConfig{
		Name:       "test-collection",
		VectorSize: 384,
		Distance:   types.DistanceCosine,
	}
	collection, err := manager.CreateCollection(config)
	if err != nil {
		t.Errorf("Expected successful collection creation, got error: %v", err)
	}
	if collection.Name != "test-collection" {
		t.Errorf("Expected name 'test-collection', got '%s'", collection.Name)
	}

	// Test get collection
	retrieved, err := manager.GetCollection("test-collection")
	if err != nil {
		t.Errorf("Expected successful collection retrieval, got error: %v", err)
	}
	if retrieved.Name != "test-collection" {
		t.Errorf("Expected name 'test-collection', got '%s'", retrieved.Name)
	}

	// Test collection exists
	if !manager.CollectionExists("test-collection") {
		t.Errorf("Expected collection to exist")
	}
	if manager.CollectionExists("non-existent") {
		t.Errorf("Expected collection to not exist")
	}

	// Test list collections
	collections := manager.ListCollections()
	if len(collections) != 1 {
		t.Errorf("Expected 1 collection, got %d", len(collections))
	}

	// Test update document count
	err = manager.UpdateDocumentCount("test-collection", 10)
	if err != nil {
		t.Errorf("Expected successful document count update, got error: %v", err)
	}
	retrieved, _ = manager.GetCollection("test-collection")
	if retrieved.DocumentCount != 10 {
		t.Errorf("Expected document count 10, got %d", retrieved.DocumentCount)
	}

	// Test increment document count
	err = manager.IncrementDocumentCount("test-collection", 5)
	if err != nil {
		t.Errorf("Expected successful document count increment, got error: %v", err)
	}
	retrieved, _ = manager.GetCollection("test-collection")
	if retrieved.DocumentCount != 15 {
		t.Errorf("Expected document count 15, got %d", retrieved.DocumentCount)
	}

	// Test update collection
	updated := types.NewCollection("test-collection", 512, types.DistanceEuclidean)
	err = manager.UpdateCollection("test-collection", updated)
	if err != nil {
		t.Errorf("Expected successful collection update, got error: %v", err)
	}
	retrieved, _ = manager.GetCollection("test-collection")
	if retrieved.VectorSize != 512 {
		t.Errorf("Expected vector size 512, got %d", retrieved.VectorSize)
	}
	if retrieved.Distance != types.DistanceEuclidean {
		t.Errorf("Expected distance 'euclidean', got '%s'", retrieved.Distance)
	}

	// Test delete collection
	err = manager.DeleteCollection("test-collection")
	if err != nil {
		t.Errorf("Expected successful collection deletion, got error: %v", err)
	}
	if manager.CollectionExists("test-collection") {
		t.Errorf("Expected collection to be deleted")
	}
}
