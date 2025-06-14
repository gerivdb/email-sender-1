package vectorization

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"
)

// Test configuration for integration tests
func getTestConfig() VectorConfig {
	config := DefaultConfig()
	config.CollectionName = "test_collection_" + time.Now().Format("20060102_150405")
	config.VectorSize = 128 // Smaller for tests
	return config
}

func TestDefaultConfig(t *testing.T) {
	config := DefaultConfig()

	assert.Equal(t, "localhost", config.Host)
	assert.Equal(t, 6333, config.Port)
	assert.Equal(t, "email_vectors", config.CollectionName)
	assert.Equal(t, 384, config.VectorSize)
	assert.Equal(t, "cosine", config.Distance)
	assert.Equal(t, 30, config.Timeout)
}

func TestNewVectorClient(t *testing.T) {
	config := getTestConfig()
	logger, _ := zap.NewDevelopment()

	client, err := NewVectorClient(config, logger)

	// This might fail if Qdrant is not running, which is expected in CI
	if err != nil {
		t.Skipf("Qdrant not available: %v", err)
	}

	assert.NoError(t, err)
	assert.NotNil(t, client)
	assert.Equal(t, config.Host, client.config.Host)
	assert.Equal(t, config.Port, client.config.Port)
}

func TestNewVectorClientWithNilLogger(t *testing.T) {
	config := getTestConfig()

	client, err := NewVectorClient(config, nil)

	// This might fail if Qdrant is not running
	if err != nil {
		t.Skipf("Qdrant not available: %v", err)
	}

	assert.NoError(t, err)
	assert.NotNil(t, client)
	assert.NotNil(t, client.logger)
}

func TestGenerateTestVectors(t *testing.T) {
	vectors := GenerateTestVectors(10, 128)

	assert.Len(t, vectors, 10)

	for i, vector := range vectors {
		assert.Len(t, vector.Vector, 128)
		assert.NotEmpty(t, vector.ID)
		assert.Equal(t, "test_generation", vector.Source)
		assert.Contains(t, vector.Payload, "index")
		assert.Equal(t, i, vector.Payload["index"])
		assert.Contains(t, vector.Payload, "description")
		assert.Contains(t, vector.Payload, "category")
		assert.Contains(t, vector.Payload, "timestamp")
	}
}

func TestSaveAndLoadVectorsJSON(t *testing.T) {
	// Generate test data
	originalVectors := GenerateTestVectors(5, 64)

	// Create temp file
	tempFile := "test_vectors.json"
	defer os.Remove(tempFile)

	// Save vectors
	err := SaveVectorsToJSON(originalVectors, tempFile)
	require.NoError(t, err)

	// Load vectors
	loadedVectors, err := LoadVectorsFromJSON(tempFile)
	require.NoError(t, err)

	// Compare
	assert.Len(t, loadedVectors, len(originalVectors))

	for i, loaded := range loadedVectors {
		original := originalVectors[i]
		assert.Equal(t, original.ID, loaded.ID)
		assert.Equal(t, original.Vector, loaded.Vector)
		assert.Equal(t, original.Source, loaded.Source)
		assert.Equal(t, original.Payload["index"], loaded.Payload["index"])
		assert.Equal(t, original.Payload["description"], loaded.Payload["description"])
	}
}

func TestConvertPayloadFunctions(t *testing.T) {
	originalPayload := map[string]interface{}{
		"string_val":  "test",
		"int_val":     42,
		"int64_val":   int64(123),
		"float_val":   3.14,
		"bool_val":    true,
		"unknown_val": []string{"array"}, // Should be converted to string
	}

	// Convert to Qdrant format and back
	qdrantPayload := convertPayload(originalPayload)
	convertedBack := convertPayloadBack(qdrantPayload)

	assert.Equal(t, originalPayload["string_val"], convertedBack["string_val"])
	assert.Equal(t, int64(42), convertedBack["int_val"]) // Converted to int64
	assert.Equal(t, originalPayload["int64_val"], convertedBack["int64_val"])
	assert.Equal(t, originalPayload["float_val"], convertedBack["float_val"])
	assert.Equal(t, originalPayload["bool_val"], convertedBack["bool_val"])
	assert.Equal(t, "[array]", convertedBack["unknown_val"]) // Converted to string
}

// Integration tests - these require a running Qdrant instance
func TestVectorClientIntegration(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}

	config := getTestConfig()
	logger, _ := zap.NewDevelopment()

	client, err := NewVectorClient(config, logger)
	if err != nil {
		t.Skipf("Qdrant not available for integration tests: %v", err)
	}

	ctx := context.Background()

	// Clean up at the end
	defer func() {
		_ = client.DeleteCollection(ctx)
		_ = client.Close()
	}()

	t.Run("CreateCollection", func(t *testing.T) {
		err := client.CreateCollection(ctx)
		assert.NoError(t, err)
	})

	t.Run("GetCollectionInfo", func(t *testing.T) {
		info, err := client.GetCollectionInfo(ctx)
		assert.NoError(t, err)
		assert.NotNil(t, info)
		assert.Equal(t, config.CollectionName, info.GetConfig().GetParams().GetVectorsConfig().GetSize())
	})

	t.Run("UpsertAndSearchVectors", func(t *testing.T) {
		// Generate and upsert test vectors
		testVectors := GenerateTestVectors(10, config.VectorSize)

		err := client.UpsertVectors(ctx, testVectors)
		assert.NoError(t, err)

		// Wait a bit for indexing
		time.Sleep(100 * time.Millisecond)

		// Search for similar vectors using the first vector as query
		results, err := client.SearchSimilar(ctx, testVectors[0].Vector, 5)
		assert.NoError(t, err)
		assert.NotEmpty(t, results)

		// The first result should be the exact match
		if len(results) > 0 {
			assert.Equal(t, testVectors[0].ID, results[0].ID)
		}
	})

	t.Run("DeleteCollection", func(t *testing.T) {
		err := client.DeleteCollection(ctx)
		assert.NoError(t, err)
	})
}

// Benchmark tests
func BenchmarkGenerateTestVectors(b *testing.B) {
	for i := 0; i < b.N; i++ {
		GenerateTestVectors(100, 384)
	}
}

func BenchmarkConvertPayload(b *testing.B) {
	payload := map[string]interface{}{
		"string_val": "test",
		"int_val":    42,
		"float_val":  3.14,
		"bool_val":   true,
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		qdrantPayload := convertPayload(payload)
		_ = convertPayloadBack(qdrantPayload)
	}
}

// Example test to demonstrate usage
func ExampleVectorClient() {
	config := DefaultConfig()
	config.CollectionName = "example_collection"

	logger, _ := zap.NewDevelopment()
	client, err := NewVectorClient(config, logger)
	if err != nil {
		panic(err)
	}
	defer client.Close()

	ctx := context.Background()

	// Create collection
	if err := client.CreateCollection(ctx); err != nil {
		panic(err)
	}

	// Generate and insert test vectors
	vectors := GenerateTestVectors(100, 384)
	if err := client.UpsertVectors(ctx, vectors); err != nil {
		panic(err)
	}

	// Search for similar vectors
	results, err := client.SearchSimilar(ctx, vectors[0].Vector, 10)
	if err != nil {
		panic(err)
	}

	logger.Info("Search completed", zap.Int("results", len(results)))

	// Clean up
	if err := client.DeleteCollection(ctx); err != nil {
		panic(err)
	}
}
