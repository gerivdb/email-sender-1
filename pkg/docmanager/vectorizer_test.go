// SPDX-License-Identifier: MIT
// Package docmanager - Vectorizer Implementation Tests
package docmanager

import (
	"fmt"
	"testing"
)

// TASK ATOMIQUE 3.1.5.3.2 - Test QDrant implementation behavioral compliance

// TestVectorizer_InterfaceCompliance teste la conformité des interfaces
func TestVectorizer_InterfaceCompliance(t *testing.T) {
	// Test que MemoryVectorizer implémente DocumentVectorizer
	var _ DocumentVectorizer = &MemoryVectorizer{}

	// Test que QDrantVectorizer implémente DocumentVectorizer
	var _ DocumentVectorizer = &QDrantVectorizer{}

	t.Log("All vectorizer implementations satisfy DocumentVectorizer interface")
}

// TestMemoryVectorizer_BasicOperations teste les opérations de base
func TestMemoryVectorizer_BasicOperations(t *testing.T) {
	config := VectorizerConfig{
		Provider:   "memory",
		VectorSize: 384,
		Model:      "test-model",
	}

	vectorizer := NewMemoryVectorizer(config)

	// Test GenerateEmbedding
	embedding, err := vectorizer.GenerateEmbedding("test text")
	if err != nil {
		t.Fatalf("GenerateEmbedding failed: %v", err)
	}

	if len(embedding) != 384 {
		t.Errorf("Expected embedding size 384, got %d", len(embedding))
	}

	// Test IndexDocument
	doc := &Document{
		ID:      "test-doc-1",
		Path:    "/test/doc.md",
		Content: []byte("Test document content"),
		Version: 1,
	}

	err = vectorizer.IndexDocument(doc)
	if err != nil {
		t.Fatalf("IndexDocument failed: %v", err)
	}

	// Test SearchSimilar
	searchVector, _ := vectorizer.GenerateEmbedding("search query")
	results, err := vectorizer.SearchSimilar(searchVector, 5)
	if err != nil {
		t.Fatalf("SearchSimilar failed: %v", err)
	}

	if len(results) == 0 {
		t.Error("SearchSimilar should return at least one result")
	}

	if results[0].ID != doc.ID {
		t.Errorf("Expected first result ID %s, got %s", doc.ID, results[0].ID)
	}

	// Test RemoveDocument
	err = vectorizer.RemoveDocument(doc.ID)
	if err != nil {
		t.Fatalf("RemoveDocument failed: %v", err)
	}

	// Vérifier que le document a été supprimé
	results, err = vectorizer.SearchSimilar(searchVector, 5)
	if err != nil {
		t.Fatalf("SearchSimilar after removal failed: %v", err)
	}

	if len(results) > 0 {
		t.Error("SearchSimilar should return no results after removal")
	}
}

// TestMemoryVectorizer_AdvancedOperations teste les opérations avancées
func TestMemoryVectorizer_AdvancedOperations(t *testing.T) {
	config := VectorizerConfig{
		Provider:   "memory",
		VectorSize: 256,
		Model:      "advanced-model",
	}

	vectorizer := NewMemoryVectorizer(config)

	// Test GenerateEmbeddingWithOptions
	options := VectorizationOptions{
		Model:           "custom-model",
		MaxTokens:       512,
		ChunkSize:       100,
		NormalizeVector: true,
	}

	embedding, metadata, err := vectorizer.GenerateEmbeddingWithOptions("test text", options)
	if err != nil {
		t.Fatalf("GenerateEmbeddingWithOptions failed: %v", err)
	}

	if len(embedding) != 256 {
		t.Errorf("Expected embedding size 256, got %d", len(embedding))
	}

	if metadata.VectorSize != 256 {
		t.Errorf("Expected metadata vector size 256, got %d", metadata.VectorSize)
	}

	if metadata.EmbeddingType != "memory" {
		t.Errorf("Expected embedding type 'memory', got %s", metadata.EmbeddingType)
	}

	// Test SearchSimilarWithOptions
	doc := &Document{
		ID:      "advanced-doc",
		Path:    "/advanced/doc.md",
		Content: []byte("Advanced document content"),
		Version: 1,
	}

	err = vectorizer.IndexDocument(doc)
	if err != nil {
		t.Fatalf("IndexDocument failed: %v", err)
	}

	searchOptions := SearchOptions{
		Limit:           10,
		MinScore:        0.5,
		IncludeMetadata: true,
	}

	results, err := vectorizer.SearchSimilarWithOptions(embedding, searchOptions)
	if err != nil {
		t.Fatalf("SearchSimilarWithOptions failed: %v", err)
	}

	if len(results) == 0 {
		t.Error("SearchSimilarWithOptions should return at least one result")
	}

	result := results[0]
	if result.Document.ID != doc.ID {
		t.Errorf("Expected result document ID %s, got %s", doc.ID, result.Document.ID)
	}

	if result.Score < searchOptions.MinScore {
		t.Errorf("Result score %f is below minimum %f", result.Score, searchOptions.MinScore)
	}

	if result.Rank != 1 {
		t.Errorf("Expected first result rank 1, got %d", result.Rank)
	}

	// Test GetIndexStats
	stats, err := vectorizer.GetIndexStats()
	if err != nil {
		t.Fatalf("GetIndexStats failed: %v", err)
	}

	if stats.TotalDocuments != 1 {
		t.Errorf("Expected 1 document in stats, got %d", stats.TotalDocuments)
	}

	if stats.VectorDimension != 256 {
		t.Errorf("Expected vector dimension 256, got %d", stats.VectorDimension)
	}
}

// TestQDrantVectorizer_MockOperations teste les opérations QDrant avec mock
func TestQDrantVectorizer_MockOperations(t *testing.T) {
	config := VectorizerConfig{
		Provider:   "qdrant",
		Host:       "mock",
		Collection: "test-collection",
		VectorSize: 512,
		Model:      "qdrant-model",
	}

	vectorizer, err := NewQDrantVectorizer(config)
	if err != nil {
		t.Fatalf("NewQDrantVectorizer failed: %v", err)
	}
	defer vectorizer.Close()

	// Test connexion
	if !vectorizer.IsConnected() {
		t.Error("Vectorizer should be connected")
	}

	err = vectorizer.Ping()
	if err != nil {
		t.Fatalf("Ping failed: %v", err)
	}

	// Test GenerateEmbedding
	embedding, err := vectorizer.GenerateEmbedding("qdrant test text")
	if err != nil {
		t.Fatalf("GenerateEmbedding failed: %v", err)
	}

	if len(embedding) != 512 {
		t.Errorf("Expected embedding size 512, got %d", len(embedding))
	}

	// Test IndexDocument
	doc := &Document{
		ID:      "qdrant-doc-1",
		Path:    "/qdrant/doc.md",
		Content: []byte("QDrant document content"),
		Metadata: map[string]interface{}{
			"category": "test",
			"priority": 1,
		},
		Version: 1,
	}

	err = vectorizer.IndexDocument(doc)
	if err != nil {
		t.Fatalf("IndexDocument failed: %v", err)
	}

	// Test SearchSimilar
	searchVector, _ := vectorizer.GenerateEmbedding("search in qdrant")
	results, err := vectorizer.SearchSimilar(searchVector, 5)
	if err != nil {
		t.Fatalf("SearchSimilar failed: %v", err)
	}

	if len(results) == 0 {
		t.Error("SearchSimilar should return at least one result")
	}

	foundDoc := results[0]
	if foundDoc.ID != doc.ID {
		t.Errorf("Expected result ID %s, got %s", doc.ID, foundDoc.ID)
	}

	// Vérifier que les métadonnées sont préservées
	if foundDoc.Metadata == nil {
		t.Error("Document metadata should be preserved")
	} else {
		if category, ok := foundDoc.Metadata["category"]; !ok || category != "test" {
			t.Error("Category metadata not preserved correctly")
		}
	}

	// Test SearchByText
	textResults, err := vectorizer.SearchByText("qdrant content", 3)
	if err != nil {
		t.Fatalf("SearchByText failed: %v", err)
	}

	if len(textResults) == 0 {
		t.Error("SearchByText should return at least one result")
	}

	// Test UpdateDocument
	doc.Content = []byte("Updated QDrant document content")
	doc.Version = 2

	err = vectorizer.UpdateDocument(doc)
	if err != nil {
		t.Fatalf("UpdateDocument failed: %v", err)
	}

	// Test GetIndexStats
	stats, err := vectorizer.GetIndexStats()
	if err != nil {
		t.Fatalf("GetIndexStats failed: %v", err)
	}

	if stats.TotalDocuments != 1 {
		t.Errorf("Expected 1 document in stats, got %d", stats.TotalDocuments)
	}

	if stats.VectorDimension != 512 {
		t.Errorf("Expected vector dimension 512, got %d", stats.VectorDimension)
	}

	// Test GetHealth
	health, err := vectorizer.GetHealth()
	if err != nil {
		t.Fatalf("GetHealth failed: %v", err)
	}

	if status, ok := health["status"]; !ok || status != "ok" {
		t.Error("Health status should be 'ok'")
	}

	// Test RemoveDocument
	err = vectorizer.RemoveDocument(doc.ID)
	if err != nil {
		t.Fatalf("RemoveDocument failed: %v", err)
	}

	// Vérifier que le document a été supprimé
	results, err = vectorizer.SearchSimilar(searchVector, 5)
	if err != nil {
		t.Fatalf("SearchSimilar after removal failed: %v", err)
	}

	if len(results) > 0 {
		t.Error("SearchSimilar should return no results after removal")
	}
}

// TestQDrantVectorizer_AdvancedSearch teste la recherche avancée
func TestQDrantVectorizer_AdvancedSearch(t *testing.T) {
	config := VectorizerConfig{
		Provider:   "qdrant",
		Host:       "mock",
		Collection: "advanced-collection",
		VectorSize: 256,
		Model:      "advanced-qdrant-model",
	}

	vectorizer, err := NewQDrantVectorizer(config)
	if err != nil {
		t.Fatalf("NewQDrantVectorizer failed: %v", err)
	}
	defer vectorizer.Close()

	// Indexer plusieurs documents
	docs := []*Document{
		{
			ID:      "doc-1",
			Path:    "/test/doc1.md",
			Content: []byte("First document content"),
			Metadata: map[string]interface{}{
				"category": "documentation",
				"priority": 1,
			},
			Version: 1,
		},
		{
			ID:      "doc-2",
			Path:    "/test/doc2.md",
			Content: []byte("Second document content"),
			Metadata: map[string]interface{}{
				"category": "tutorial",
				"priority": 2,
			},
			Version: 1,
		},
		{
			ID:      "doc-3",
			Path:    "/test/doc3.md",
			Content: []byte("Third document content"),
			Metadata: map[string]interface{}{
				"category": "documentation",
				"priority": 3,
			},
			Version: 1,
		},
	}

	for _, doc := range docs {
		err := vectorizer.IndexDocument(doc)
		if err != nil {
			t.Fatalf("IndexDocument failed for %s: %v", doc.ID, err)
		}
	}

	// Test SearchSimilarWithOptions avec options avancées
	searchVector, _ := vectorizer.GenerateEmbedding("search for documents")

	searchOptions := SearchOptions{
		Limit:           2,
		MinScore:        0.1,
		IncludeMetadata: true,
		FilterBy: map[string]interface{}{
			"category": "documentation",
		},
	}

	results, err := vectorizer.SearchSimilarWithOptions(searchVector, searchOptions)
	if err != nil {
		t.Fatalf("SearchSimilarWithOptions failed: %v", err)
	}

	if len(results) > searchOptions.Limit {
		t.Errorf("Results exceed limit: got %d, expected max %d", len(results), searchOptions.Limit)
	}

	// Vérifier les scores minimums
	for _, result := range results {
		if result.Score < searchOptions.MinScore {
			t.Errorf("Result score %f is below minimum %f", result.Score, searchOptions.MinScore)
		}

		if result.Rank == 0 {
			t.Error("Result rank should be > 0")
		}

		// Vérifier les métadonnées
		if result.Metadata.EmbeddingType != "qdrant" {
			t.Errorf("Expected embedding type 'qdrant', got %s", result.Metadata.EmbeddingType)
		}

		if result.Metadata.VectorSize != 256 {
			t.Errorf("Expected vector size 256, got %d", result.Metadata.VectorSize)
		}
	}

	// Test SearchByTextWithOptions
	textSearchOptions := SearchOptions{
		Limit:           3,
		MinScore:        0.0,
		IncludeMetadata: true,
	}

	textResults, err := vectorizer.SearchByTextWithOptions("document content", textSearchOptions)
	if err != nil {
		t.Fatalf("SearchByTextWithOptions failed: %v", err)
	}

	if len(textResults) == 0 {
		t.Error("SearchByTextWithOptions should return at least one result")
	}

	// Vérifier que les résultats sont triés par score (décroissant)
	for i := 1; i < len(textResults); i++ {
		if textResults[i].Score > textResults[i-1].Score {
			t.Error("Results should be sorted by score in descending order")
		}
	}
}

// TestVectorizerProvider_Factory teste le factory de vectorizers
func TestVectorizerProvider_Factory(t *testing.T) {
	provider := NewDefaultVectorizerProvider()

	// Test SupportedProviders
	providers := provider.SupportedProviders()
	if len(providers) == 0 {
		t.Error("Should have at least one supported provider")
	}

	expectedProviders := map[string]bool{
		"memory": false,
		"qdrant": false,
	}

	for _, p := range providers {
		if _, exists := expectedProviders[p]; exists {
			expectedProviders[p] = true
		}
	}

	for provider, found := range expectedProviders {
		if !found {
			t.Errorf("Expected provider %s not found", provider)
		}
	}

	// Test CreateVectorizer avec memory
	memoryConfig := VectorizerConfig{
		Provider:   "memory",
		VectorSize: 128,
		Model:      "test-memory",
	}

	memoryVectorizer, err := provider.CreateVectorizer(memoryConfig)
	if err != nil {
		t.Fatalf("CreateVectorizer for memory failed: %v", err)
	}

	if memoryVectorizer == nil {
		t.Error("Memory vectorizer should not be nil")
	}

	// Test CreateVectorizer avec qdrant
	qdrantConfig := VectorizerConfig{
		Provider:   "qdrant",
		Host:       "mock",
		Collection: "test-factory",
		VectorSize: 256,
		Model:      "test-qdrant",
	}

	qdrantVectorizer, err := provider.CreateVectorizer(qdrantConfig)
	if err != nil {
		t.Fatalf("CreateVectorizer for qdrant failed: %v", err)
	}

	if qdrantVectorizer == nil {
		t.Error("QDrant vectorizer should not be nil")
	}

	// Test CreateVectorizer avec provider inconnu (fallback to memory)
	unknownConfig := VectorizerConfig{
		Provider:   "unknown",
		VectorSize: 64,
		Model:      "test-unknown",
	}

	fallbackVectorizer, err := provider.CreateVectorizer(unknownConfig)
	if err != nil {
		t.Fatalf("CreateVectorizer fallback failed: %v", err)
	}

	if fallbackVectorizer == nil {
		t.Error("Fallback vectorizer should not be nil")
	}

	// Test ValidateConfig
	validConfig := VectorizerConfig{
		Provider:   "memory",
		VectorSize: 128,
	}

	err = provider.ValidateConfig(validConfig)
	if err != nil {
		t.Errorf("ValidateConfig should pass for valid config: %v", err)
	}

	invalidConfig := VectorizerConfig{
		Provider:   "",
		VectorSize: 0,
	}

	err = provider.ValidateConfig(invalidConfig)
	if err == nil {
		t.Error("ValidateConfig should fail for invalid config")
	}
}

// BenchmarkMemoryVectorizer_Operations benchmark des opérations memory
func BenchmarkMemoryVectorizer_Operations(b *testing.B) {
	config := VectorizerConfig{
		Provider:   "memory",
		VectorSize: 384,
		Model:      "bench-model",
	}

	vectorizer := NewMemoryVectorizer(config)

	doc := &Document{
		ID:      "bench-doc",
		Path:    "/bench/doc.md",
		Content: []byte("Benchmark document content for testing performance"),
		Version: 1,
	}

	b.ResetTimer()

	b.Run("GenerateEmbedding", func(b *testing.B) {
		for i := 0; i < b.N; i++ {
			_, err := vectorizer.GenerateEmbedding("benchmark text")
			if err != nil {
				b.Fatalf("GenerateEmbedding failed: %v", err)
			}
		}
	})

	b.Run("IndexDocument", func(b *testing.B) {
		for i := 0; i < b.N; i++ {
			doc.ID = fmt.Sprintf("bench-doc-%d", i)
			err := vectorizer.IndexDocument(doc)
			if err != nil {
				b.Fatalf("IndexDocument failed: %v", err)
			}
		}
	})

	b.Run("SearchSimilar", func(b *testing.B) {
		vector, _ := vectorizer.GenerateEmbedding("search query")
		b.ResetTimer()

		for i := 0; i < b.N; i++ {
			_, err := vectorizer.SearchSimilar(vector, 10)
			if err != nil {
				b.Fatalf("SearchSimilar failed: %v", err)
			}
		}
	})
}

// BenchmarkQDrantVectorizer_Operations benchmark des opérations QDrant
func BenchmarkQDrantVectorizer_Operations(b *testing.B) {
	config := VectorizerConfig{
		Provider:   "qdrant",
		Host:       "mock",
		Collection: "bench-collection",
		VectorSize: 512,
		Model:      "bench-qdrant",
	}

	vectorizer, err := NewQDrantVectorizer(config)
	if err != nil {
		b.Fatalf("NewQDrantVectorizer failed: %v", err)
	}
	defer vectorizer.Close()

	doc := &Document{
		ID:      "bench-qdrant-doc",
		Path:    "/bench/qdrant-doc.md",
		Content: []byte("QDrant benchmark document content for testing performance"),
		Version: 1,
	}

	b.ResetTimer()

	b.Run("GenerateEmbedding", func(b *testing.B) {
		for i := 0; i < b.N; i++ {
			_, err := vectorizer.GenerateEmbedding("qdrant benchmark text")
			if err != nil {
				b.Fatalf("GenerateEmbedding failed: %v", err)
			}
		}
	})

	b.Run("IndexDocument", func(b *testing.B) {
		for i := 0; i < b.N; i++ {
			doc.ID = fmt.Sprintf("bench-qdrant-doc-%d", i)
			err := vectorizer.IndexDocument(doc)
			if err != nil {
				b.Fatalf("IndexDocument failed: %v", err)
			}
		}
	})

	b.Run("SearchSimilar", func(b *testing.B) {
		vector, _ := vectorizer.GenerateEmbedding("qdrant search query")
		b.ResetTimer()

		for i := 0; i < b.N; i++ {
			_, err := vectorizer.SearchSimilar(vector, 10)
			if err != nil {
				b.Fatalf("SearchSimilar failed: %v", err)
			}
		}
	})
}
