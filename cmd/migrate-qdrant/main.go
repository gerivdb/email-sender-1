package main

import (
	"context"
	"fmt"
	"log"

	"github.com/qdrant/go-client/qdrant"
)

// QdrantMigrator gestionnaire de migration Qdrant
type QdrantMigrator struct {
	sourceClient *qdrant.Client
	targetClient *qdrant.Client
}

// NewQdrantMigrator crée un nouveau migrateur
func NewQdrantMigrator(sourceHost string, sourcePort int, targetHost string, targetPort int) (*QdrantMigrator, error) {
	// Configuration source
	sourceConfig := &qdrant.Config{
		Host: sourceHost,
		Port: sourcePort,
	}

	// Configuration target
	targetConfig := &qdrant.Config{
		Host: targetHost,
		Port: targetPort,
	}

	// Créer les clients
	sourceClient, err := qdrant.NewClient(sourceConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to create source client: %w", err)
	}

	targetClient, err := qdrant.NewClient(targetConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to create target client: %w", err)
	}

	return &QdrantMigrator{
		sourceClient: sourceClient,
		targetClient: targetClient,
	}, nil
}

// MigrateCollection migre une collection depuis la source vers la target
func (qm *QdrantMigrator) MigrateCollection(ctx context.Context, collectionName string) error {
	log.Printf("Testing migration for collection: %s", collectionName)

	// Vérifier si la collection existe sur la source
	sourceInfo, err := qm.sourceClient.GetCollectionInfo(ctx, collectionName)
	if err != nil {
		return fmt.Errorf("failed to get source collection info: %w", err)
	}

	log.Printf("✅ Source collection info retrieved for: %s (vectors: %d, points: %d)",
		collectionName,
		sourceInfo.GetVectorsCount(),
		sourceInfo.GetPointsCount())

	// Vérifier si la collection existe sur la target
	targetExists, err := qm.targetClient.CollectionExists(ctx, collectionName)
	if err != nil {
		return fmt.Errorf("failed to check target collection existence: %w", err)
	}

	if targetExists {
		log.Printf("✅ Target collection %s already exists", collectionName)
	} else {
		log.Printf("📝 Target collection %s does not exist (would need creation)", collectionName)
	}

	return nil
}

func main() {
	log.Println("🚀 Starting Qdrant Migration Tool")

	// Configuration par défaut
	sourceHost := "localhost"
	sourcePort := 6333
	targetHost := "localhost"
	targetPort := 6334

	// Créer le migrateur
	migrator, err := NewQdrantMigrator(sourceHost, sourcePort, targetHost, targetPort)
	if err != nil {
		log.Fatalf("Failed to create migrator: %v", err)
	}

	log.Printf("✅ Migrator created successfully")

	// Test avec une collection par défaut
	ctx := context.Background()
	testCollection := "test_collection"

	err = migrator.MigrateCollection(ctx, testCollection)
	if err != nil {
		log.Printf("❌ Migration test failed: %v", err)
	} else {
		log.Printf("✅ Migration test completed successfully")
	}

	fmt.Println("🎉 migrate-qdrant structure test - COMPLETED")
}
