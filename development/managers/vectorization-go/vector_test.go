package vectorization

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"testing"
	"time"

	"go.uber.org/zap"
)

// TestVectorClient_CreateCollection teste la création de collection
func TestVectorClient_CreateCollection(t *testing.T) {
	logger := zap.NewNop()
	config := VectorConfig{
		Host:           "localhost",
		Port:           6333,
		CollectionName: "test_collection",
		VectorSize:     384,
		Distance:       "cosine",
	}

	client, err := NewVectorClient(config, logger)
	if err != nil {
		t.Fatalf("Erreur création client: %v", err)
	}

	ctx := context.Background()
	err = client.CreateCollection(ctx)
	if err != nil {
		t.Errorf("Erreur création collection: %v", err)
	}
}

// TestVectorClient_UpsertVectors teste l'insertion de vecteurs
func TestVectorClient_UpsertVectors(t *testing.T) {
	logger := zap.NewNop()
	config := VectorConfig{
		Host:           "localhost",
		Port:           6333,
		CollectionName: "test_collection",
		VectorSize:     3,
		Distance:       "cosine",
	}

	client, err := NewVectorClient(config, logger)
	if err != nil {
		t.Fatalf("Erreur création client: %v", err)
	}

	// Test cas nominal: 100 vecteurs valides
	vectors := make([]Vector, 100)
	for i := 0; i < 100; i++ {
		vectors[i] = Vector{
			ID:     fmt.Sprintf("vector_%d", i),
			Values: []float32{float32(i), float32(i + 1), float32(i + 2)},
			Metadata: map[string]interface{}{
				"index": i,
			},
		}
	}

	ctx := context.Background()
	err = client.UpsertVectors(ctx, vectors)
	if err != nil {
		t.Errorf("Erreur insertion vecteurs: %v", err)
	}

	// Test cas limite: vecteur avec taille incorrecte
	invalidVector := Vector{
		ID:     "invalid",
		Values: []float32{1.0, 2.0}, // Taille incorrecte (2 au lieu de 3)
	}

	err = client.UpsertVectors(ctx, []Vector{invalidVector})
	if err == nil {
		t.Error("Attendu une erreur pour vecteur de taille incorrecte")
	}
}

// TestVectorClient_SearchVectors teste la recherche de similarité
func TestVectorClient_SearchVectors(t *testing.T) {
	logger := zap.NewNop()
	config := VectorConfig{
		Host:           "localhost",
		Port:           6333,
		CollectionName: "test_collection",
		VectorSize:     3,
		Distance:       "cosine",
	}

	client, err := NewVectorClient(config, logger)
	if err != nil {
		t.Fatalf("Erreur création client: %v", err)
	}

	// Test recherche de similarité
	query := Vector{
		ID:     "query",
		Values: []float32{1.0, 2.0, 3.0},
	}

	ctx := context.Background()
	results, err := client.SearchVectors(ctx, query, 5)
	if err != nil {
		t.Errorf("Erreur recherche vecteurs: %v", err)
	}

	if len(results) > 5 {
		t.Errorf("Trop de résultats: attendu <= 5, obtenu %d", len(results))
	}

	// Vérifier que les scores sont triés par ordre décroissant
	for i := 1; i < len(results); i++ {
		if results[i-1].Score < results[i].Score {
			t.Error("Résultats mal triés")
		}
	}
}

// TestVectorOperations_BatchUpsert teste l'insertion par lots
func TestVectorOperations_BatchUpsert(t *testing.T) {
	logger := zap.NewNop()
	config := VectorConfig{
		Host:           "localhost",
		Port:           6333,
		CollectionName: "test_collection",
		VectorSize:     3,
		BatchSize:      10,
	}

	client, err := NewVectorClient(config, logger)
	if err != nil {
		t.Fatalf("Erreur création client: %v", err)
	}

	operations := NewVectorOperations(client)

	// Créer 25 vecteurs (2.5 lots)
	vectors := make([]Vector, 25)
	for i := 0; i < 25; i++ {
		vectors[i] = Vector{
			ID:     fmt.Sprintf("batch_vector_%d", i),
			Values: []float32{float32(i), float32(i + 1), float32(i + 2)},
		}
	}

	ctx := context.Background()
	err = operations.BatchUpsertVectors(ctx, vectors)
	if err != nil {
		t.Errorf("Erreur insertion par lots: %v", err)
	}
}

// TestVectorMigrator_Migration teste la migration complète
func TestVectorMigrator_Migration(t *testing.T) {
	// Créer un répertoire temporaire avec des données de test
	tempDir := t.TempDir()

	// Créer un fichier JSON de test
	testData := `[
		{
			"id": "test_1",
			"vector": [1.0, 2.0, 3.0],
			"metadata": {"source": "test"}
		},
		{
			"id": "test_2", 
			"vector": [4.0, 5.0, 6.0],
			"metadata": {"source": "test"}
		}
	]`

	testFile := filepath.Join(tempDir, "test_vectors.json")
	err := os.WriteFile(testFile, []byte(testData), 0644)
	if err != nil {
		t.Fatalf("Erreur création fichier test: %v", err)
	}

	// Configuration de migration
	logger := zap.NewNop()
	clientConfig := VectorConfig{
		Host:           "localhost",
		Port:           6333,
		CollectionName: "test_migration",
		VectorSize:     3,
	}

	client, err := NewVectorClient(clientConfig, logger)
	if err != nil {
		t.Fatalf("Erreur création client: %v", err)
	}

	migrationConfig := MigrationConfig{
		BatchSize:       1,
		ValidateVectors: true,
	}

	migrator := NewVectorMigrator(tempDir, client, migrationConfig, logger)

	// Test migration
	ctx := context.Background()
	err = migrator.MigratePythonVectors(ctx)
	if err != nil {
		t.Errorf("Erreur migration: %v", err)
	}

	// Vérifier les statistiques
	stats := migrator.GetMigrationStats()
	if stats.TotalVectors != 2 {
		t.Errorf("Attendu 2 vecteurs, obtenu %d", stats.TotalVectors)
	}

	if stats.MigratedVectors != 2 {
		t.Errorf("Attendu 2 vecteurs migrés, obtenu %d", stats.MigratedVectors)
	}
}

// TestErrorHandler_RetryLogic teste la logique de retry
func TestErrorHandler_RetryLogic(t *testing.T) {
	logger := zap.NewNop()
	config := RetryConfig{
		MaxAttempts:   3,
		InitialDelay:  10 * time.Millisecond,
		BackoffFactor: 2.0,
	}

	handler := NewErrorHandler(config, logger)

	// Test avec opération qui échoue toujours
	attempts := 0
	err := handler.ExecuteWithRetry(context.Background(), "test_operation", func() error {
		attempts++
		return fmt.Errorf("erreur test")
	})

	if err == nil {
		t.Error("Attendu une erreur après tous les retries")
	}

	if attempts != 3 {
		t.Errorf("Attendu 3 tentatives, obtenu %d", attempts)
	}

	// Test avec opération qui réussit au 2ème essai
	attempts = 0
	err = handler.ExecuteWithRetry(context.Background(), "test_operation", func() error {
		attempts++
		if attempts < 2 {
			return fmt.Errorf("erreur temporaire")
		}
		return nil
	})

	if err != nil {
		t.Errorf("Attendu succès au 2ème essai: %v", err)
	}

	if attempts != 2 {
		t.Errorf("Attendu 2 tentatives, obtenu %d", attempts)
	}
}

// TestCircuitBreaker teste le circuit breaker
func TestCircuitBreaker(t *testing.T) {
	logger := zap.NewNop()
	cb := NewCircuitBreaker(2, 100*time.Millisecond, logger)

	// Test état initial (fermé)
	if cb.GetState() != "closed" {
		t.Error("État initial devrait être 'closed'")
	}

	// Provoquer des échecs pour ouvrir le circuit
	for i := 0; i < 2; i++ {
		err := cb.Execute("test", func() error {
			return fmt.Errorf("erreur test")
		})
		if err == nil {
			t.Error("Attendu une erreur")
		}
	}

	// Le circuit devrait être ouvert maintenant
	if cb.GetState() != "open" {
		t.Error("Circuit devrait être ouvert après 2 échecs")
	}

	// Tester que les opérations sont rejetées
	err := cb.Execute("test", func() error {
		return nil
	})
	if err == nil {
		t.Error("Opération devrait être rejetée avec circuit ouvert")
	}

	// Attendre la réinitialisation
	time.Sleep(150 * time.Millisecond)

	// Test réinitialisation avec succès
	err = cb.Execute("test", func() error {
		return nil
	})
	if err != nil {
		t.Errorf("Opération devrait réussir après réinitialisation: %v", err)
	}

	if cb.GetState() != "closed" {
		t.Error("Circuit devrait être fermé après succès")
	}
}

// BenchmarkVectorOperations teste les performances
func BenchmarkVectorOperations(b *testing.B) {
	logger := zap.NewNop()
	config := VectorConfig{
		Host:           "localhost",
		Port:           6333,
		CollectionName: "benchmark",
		VectorSize:     384,
		BatchSize:      100,
	}

	client, err := NewVectorClient(config, logger)
	if err != nil {
		b.Fatalf("Erreur création client: %v", err)
	}

	operations := NewVectorOperations(client)

	// Créer des vecteurs de test
	vectors := make([]Vector, 1000)
	for i := 0; i < 1000; i++ {
		values := make([]float32, 384)
		for j := range values {
			values[j] = float32(i + j)
		}
		vectors[i] = Vector{
			ID:     fmt.Sprintf("bench_vector_%d", i),
			Values: values,
		}
	}

	ctx := context.Background()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = operations.BatchUpsertVectors(ctx, vectors)
	}
}
