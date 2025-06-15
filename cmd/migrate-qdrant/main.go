package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/qdrant/go-client/qdrant"
)

// MigrationConfig configuration pour la migration
type MigrationConfig struct {
	SourceQdrant  QdrantConfig `json:"source_qdrant"`
	TargetQdrant  QdrantConfig `json:"target_qdrant"`
	BackupPath    string       `json:"backup_path"`
	Collections   []string     `json:"collections"`
	BatchSize     int          `json:"batch_size"`
	ValidateAfter bool         `json:"validate_after"`
	DryRun        bool         `json:"dry_run"`
}

// QdrantConfig configuration d'une instance Qdrant
type QdrantConfig struct {
	Host   string `json:"host"`
	Port   int    `json:"port"`
	APIKey string `json:"api_key"`
}

// MigrationResult résultat d'une migration
type MigrationResult struct {
	CollectionName   string        `json:"collection_name"`
	SourcePoints     int           `json:"source_points"`
	MigratedPoints   int           `json:"migrated_points"`
	FailedPoints     int           `json:"failed_points"`
	Duration         time.Duration `json:"duration"`
	ValidationPassed bool          `json:"validation_passed"`
	Errors           []string      `json:"errors"`
}

// QdrantMigrator gestionnaire de migration Qdrant
type QdrantMigrator struct {
	sourceClient *qdrant.Client
	targetClient *qdrant.Client
	config       MigrationConfig
}

// NewQdrantMigrator crée un nouveau gestionnaire de migration
func NewQdrantMigrator(config MigrationConfig) (*QdrantMigrator, error) {
	// Client source
	sourceClient, err := qdrant.NewClient(&qdrant.Config{
		Host:   config.SourceQdrant.Host,
		Port:   config.SourceQdrant.Port,
		APIKey: config.SourceQdrant.APIKey,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create source Qdrant client: %w", err)
	}

	// Client target (peut être le même que source)
	targetClient, err := qdrant.NewClient(&qdrant.Config{
		Host:   config.TargetQdrant.Host,
		Port:   config.TargetQdrant.Port,
		APIKey: config.TargetQdrant.APIKey,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create target Qdrant client: %w", err)
	}

	return &QdrantMigrator{
		sourceClient: sourceClient,
		targetClient: targetClient,
		config:       config,
	}, nil
}

// MigrateCollection migre une collection vers le nouveau format
func (qm *QdrantMigrator) MigrateCollection(ctx context.Context, collectionName string) (*MigrationResult, error) {
	startTime := time.Now()
	result := &MigrationResult{
		CollectionName: collectionName,
		Errors:         []string{},
	}

	log.Printf("Starting migration for collection: %s", collectionName)

	// 1. Récupérer les informations de la collection source
	sourceInfo, err := qm.sourceClient.GetCollection(ctx, collectionName)
	if err != nil {
		return result, fmt.Errorf("failed to get source collection info: %w", err)
	}

	// 2. Créer ou mettre à jour la collection target
	if err := qm.ensureTargetCollection(ctx, collectionName, sourceInfo); err != nil {
		return result, fmt.Errorf("failed to ensure target collection: %w", err)
	}

	// 3. Migrer les points par batch
	migratedCount, failedCount, errors := qm.migratePoints(ctx, collectionName)
	result.MigratedPoints = migratedCount
	result.FailedPoints = failedCount
	result.Errors = errors

	// 4. Compter les points source pour validation
	sourcePoints, err := qm.countSourcePoints(ctx, collectionName)
	if err != nil {
		result.Errors = append(result.Errors, fmt.Sprintf("Failed to count source points: %v", err))
	} else {
		result.SourcePoints = sourcePoints
	}

	result.Duration = time.Since(startTime)

	// 5. Validation post-migration si demandée
	if qm.config.ValidateAfter {
		validationPassed, validationErrors := qm.validateMigration(ctx, collectionName, result)
		result.ValidationPassed = validationPassed
		result.Errors = append(result.Errors, validationErrors...)
	}

	log.Printf("Migration completed for %s: %d/%d points migrated in %v",
		collectionName, result.MigratedPoints, result.SourcePoints, result.Duration)

	return result, nil
}

// ensureTargetCollection s'assure que la collection target existe et est configurée correctement
func (qm *QdrantMigrator) ensureTargetCollection(ctx context.Context, collectionName string, sourceInfo *qdrant.CollectionInfo) error {
	if qm.config.DryRun {
		log.Printf("DRY RUN: Would ensure target collection %s", collectionName)
		return nil
	}

	// Vérifier si la collection existe déjà
	_, err := qm.targetClient.GetCollection(ctx, collectionName)
	if err == nil {
		log.Printf("Target collection %s already exists", collectionName)
		return nil
	}

	// Créer la collection avec la même configuration que la source
	createRequest := &qdrant.CreateCollection{
		CollectionName: collectionName,
		VectorsConfig: qdrant.VectorsConfig{
			Params: &qdrant.VectorParams{
				Size:     sourceInfo.Config.Params.VectorSize,
				Distance: sourceInfo.Config.Params.Distance,
			},
		},
		// Optimisations pour le nouveau format Go
		OptimizersConfig: &qdrant.OptimizersConfig{
			DefaultSegmentNumber:   &[]uint64{6}[0], // Plus de segments pour de meilleures perfs
			MaxSegmentSize:         &[]uint64{100000}[0],
			MemmapThreshold:        &[]uint64{50000}[0],
			IndexingThreshold:      &[]uint64{10000}[0],
			FlushIntervalSec:       &[]uint64{30}[0],
			MaxOptimizationThreads: &[]uint64{4}[0],
		},
		// Configuration HNSW optimisée
		HnswConfig: &qdrant.HnswConfig{
			M:                 &[]uint64{16}[0],
			EfConstruct:       &[]uint64{100}[0],
			FullScanThreshold: &[]uint64{10000}[0],
		},
	}

	if err := qm.targetClient.CreateCollection(ctx, createRequest); err != nil {
		return fmt.Errorf("failed to create target collection: %w", err)
	}

	log.Printf("✅ Target collection %s created successfully", collectionName)
	return nil
}

// migratePoints migre tous les points d'une collection par batch
func (qm *QdrantMigrator) migratePoints(ctx context.Context, collectionName string) (int, int, []string) {
	var totalMigrated, totalFailed int
	var errors []string

	offset := 0
	batchSize := qm.config.BatchSize
	if batchSize <= 0 {
		batchSize = 1000
	}

	for {
		// Récupérer un batch de points
		scrollRequest := &qdrant.ScrollPoints{
			CollectionName: collectionName,
			Limit:          &batchSize,
			Offset:         &offset,
			WithPayload:    &qdrant.WithPayloadSelector{Enable: true},
			WithVector:     &qdrant.WithVectorSelector{Enable: true},
		}

		result, err := qm.sourceClient.Scroll(ctx, scrollRequest)
		if err != nil {
			errorMsg := fmt.Sprintf("Failed to scroll points at offset %d: %v", offset, err)
			errors = append(errors, errorMsg)
			log.Printf("ERROR: %s", errorMsg)
			break
		}

		if len(result.Points) == 0 {
			break
		}

		// Migrer ce batch
		migrated, failed, batchErrors := qm.migrateBatch(ctx, collectionName, result.Points)
		totalMigrated += migrated
		totalFailed += failed
		errors = append(errors, batchErrors...)

		offset += len(result.Points)
		log.Printf("Migrated batch: %d points (total: %d migrated, %d failed)",
			len(result.Points), totalMigrated, totalFailed)

		// Protection contre les boucles infinies
		if len(result.Points) < batchSize {
			break
		}
	}

	return totalMigrated, totalFailed, errors
}

// migrateBatch migre un batch de points
func (qm *QdrantMigrator) migrateBatch(ctx context.Context, collectionName string, points []qdrant.PointStruct) (int, int, []string) {
	if qm.config.DryRun {
		log.Printf("DRY RUN: Would migrate %d points", len(points))
		return len(points), 0, []string{}
	}

	var migrated, failed int
	var errors []string

	// Préparer les points pour l'insertion avec optimisations Go
	optimizedPoints := qm.optimizePointsForGo(points)

	// Insérer par batch
	upsertRequest := &qdrant.UpsertPoints{
		CollectionName: collectionName,
		Points:         optimizedPoints,
		Wait:           &[]bool{false}[0], // Insertion asynchrone pour de meilleures perfs
	}

	if err := qm.targetClient.Upsert(ctx, upsertRequest); err != nil {
		errorMsg := fmt.Sprintf("Failed to upsert batch: %v", err)
		errors = append(errors, errorMsg)
		failed = len(points)
		log.Printf("ERROR: %s", errorMsg)
	} else {
		migrated = len(points)
	}

	return migrated, failed, errors
}

// optimizePointsForGo optimise les points pour le nouveau client Go
func (qm *QdrantMigrator) optimizePointsForGo(points []qdrant.PointStruct) []qdrant.PointStruct {
	optimized := make([]qdrant.PointStruct, len(points))

	for i, point := range points {
		optimized[i] = point

		// Optimisations spécifiques au format Go v56
		if optimized[i].Payload == nil {
			optimized[i].Payload = make(map[string]interface{})
		}

		// Ajouter des métadonnées de migration
		optimized[i].Payload["_migration_version"] = "v56-go"
		optimized[i].Payload["_migrated_at"] = time.Now().Unix()

		// Optimiser le payload pour de meilleures performances de recherche
		if category, exists := optimized[i].Payload["category"]; exists {
			// Normaliser les catégories pour une recherche plus efficace
			if categoryStr, ok := category.(string); ok {
				optimized[i].Payload["category_normalized"] = strings.ToLower(categoryStr)
			}
		}
	}

	return optimized
}

// countSourcePoints compte le nombre total de points dans la collection source
func (qm *QdrantMigrator) countSourcePoints(ctx context.Context, collectionName string) (int, error) {
	info, err := qm.sourceClient.GetCollection(ctx, collectionName)
	if err != nil {
		return 0, err
	}

	// Utiliser le count de la collection si disponible
	if info.PointsCount != nil {
		return int(*info.PointsCount), nil
	}

	// Sinon, compter manuellement (plus lent)
	return qm.manualCount(ctx, collectionName)
}

// manualCount compte manuellement les points (fallback)
func (qm *QdrantMigrator) manualCount(ctx context.Context, collectionName string) (int, error) {
	count := 0
	offset := 0
	limit := 1000

	for {
		scrollRequest := &qdrant.ScrollPoints{
			CollectionName: collectionName,
			Limit:          &limit,
			Offset:         &offset,
			WithPayload:    &qdrant.WithPayloadSelector{Enable: false},
			WithVector:     &qdrant.WithVectorSelector{Enable: false},
		}

		result, err := qm.sourceClient.Scroll(ctx, scrollRequest)
		if err != nil {
			return 0, err
		}

		if len(result.Points) == 0 {
			break
		}

		count += len(result.Points)
		offset += len(result.Points)

		if len(result.Points) < limit {
			break
		}
	}

	return count, nil
}

// validateMigration valide que la migration s'est bien passée
func (qm *QdrantMigrator) validateMigration(ctx context.Context, collectionName string, result *MigrationResult) (bool, []string) {
	var errors []string
	passed := true

	log.Printf("Validating migration for collection: %s", collectionName)

	// 1. Vérifier le nombre de points
	targetInfo, err := qm.targetClient.GetCollection(ctx, collectionName)
	if err != nil {
		errors = append(errors, fmt.Sprintf("Failed to get target collection info: %v", err))
		passed = false
	} else if targetInfo.PointsCount != nil {
		targetCount := int(*targetInfo.PointsCount)
		if targetCount != result.MigratedPoints {
			errors = append(errors, fmt.Sprintf("Point count mismatch: expected %d, got %d",
				result.MigratedPoints, targetCount))
			passed = false
		}
	}

	// 2. Test de recherche sémantique
	if searchPassed, searchErrors := qm.testSemanticSearch(ctx, collectionName); !searchPassed {
		errors = append(errors, searchErrors...)
		passed = false
	}

	// 3. Vérification de la qualité des données
	if qualityPassed, qualityErrors := qm.validateDataQuality(ctx, collectionName); !qualityPassed {
		errors = append(errors, qualityErrors...)
		passed = false
	}

	return passed, errors
}

// testSemanticSearch teste la recherche sémantique sur la collection migrée
func (qm *QdrantMigrator) testSemanticSearch(ctx context.Context, collectionName string) (bool, []string) {
	var errors []string

	// Vecteur de test (384 dimensions avec des valeurs normalisées)
	testVector := make([]float32, 384)
	for i := range testVector {
		testVector[i] = 0.1 // Valeur test simple
	}

	searchRequest := &qdrant.SearchPoints{
		CollectionName: collectionName,
		Vector:         testVector,
		Limit:          10,
		WithPayload:    &qdrant.WithPayloadSelector{Enable: true},
	}

	results, err := qm.targetClient.Search(ctx, searchRequest)
	if err != nil {
		errors = append(errors, fmt.Sprintf("Semantic search test failed: %v", err))
		return false, errors
	}

	if len(results) == 0 {
		errors = append(errors, "Semantic search returned no results")
		return false, errors
	}

	log.Printf("✅ Semantic search test passed: %d results", len(results))
	return true, errors
}

// validateDataQuality valide la qualité des données migrées
func (qm *QdrantMigrator) validateDataQuality(ctx context.Context, collectionName string) (bool, []string) {
	var errors []string
	passed := true

	// Échantillonner quelques points pour validation
	scrollRequest := &qdrant.ScrollPoints{
		CollectionName: collectionName,
		Limit:          &[]int{100}[0],
		WithPayload:    &qdrant.WithPayloadSelector{Enable: true},
		WithVector:     &qdrant.WithVectorSelector{Enable: true},
	}

	result, err := qm.targetClient.Scroll(ctx, scrollRequest)
	if err != nil {
		errors = append(errors, fmt.Sprintf("Failed to sample points for quality check: %v", err))
		return false, errors
	}

	// Vérifier que les points ont les bonnes métadonnées de migration
	for _, point := range result.Points {
		if point.Payload == nil {
			errors = append(errors, fmt.Sprintf("Point %v has no payload", point.Id))
			passed = false
			continue
		}

		// Vérifier les métadonnées de migration
		if migrationVersion, exists := point.Payload["_migration_version"]; !exists {
			errors = append(errors, fmt.Sprintf("Point %v missing migration version", point.Id))
			passed = false
		} else if migrationVersion != "v56-go" {
			errors = append(errors, fmt.Sprintf("Point %v has wrong migration version: %v", point.Id, migrationVersion))
			passed = false
		}

		// Vérifier que le vecteur est présent
		if point.Vector == nil {
			errors = append(errors, fmt.Sprintf("Point %v has no vector", point.Id))
			passed = false
		}
	}

	if passed {
		log.Printf("✅ Data quality validation passed for %d sample points", len(result.Points))
	}

	return passed, errors
}

// RunMigration exécute la migration complète
func (qm *QdrantMigrator) RunMigration(ctx context.Context) ([]MigrationResult, error) {
	log.Printf("Starting migration of %d collections", len(qm.config.Collections))

	var results []MigrationResult

	for _, collectionName := range qm.config.Collections {
		log.Printf("Processing collection: %s", collectionName)

		result, err := qm.MigrateCollection(ctx, collectionName)
		if err != nil {
			log.Printf("ERROR: Migration failed for %s: %v", collectionName, err)
			if result != nil {
				result.Errors = append(result.Errors, err.Error())
			} else {
				result = &MigrationResult{
					CollectionName: collectionName,
					Errors:         []string{err.Error()},
				}
			}
		}

		results = append(results, *result)

		// Pause entre les migrations pour éviter la surcharge
		time.Sleep(5 * time.Second)
	}

	// Générer un rapport de migration
	if err := qm.generateMigrationReport(results); err != nil {
		log.Printf("Warning: Failed to generate migration report: %v", err)
	}

	log.Printf("Migration completed for all collections")
	return results, nil
}

// generateMigrationReport génère un rapport de migration
func (qm *QdrantMigrator) generateMigrationReport(results []MigrationResult) error {
	reportPath := filepath.Join(qm.config.BackupPath, "migration_report.json")

	report := map[string]interface{}{
		"timestamp":   time.Now().Format(time.RFC3339),
		"version":     "v56-go-migration",
		"collections": results,
		"total_points": func() int {
			total := 0
			for _, r := range results {
				total += r.MigratedPoints
			}
			return total
		}(),
	}

	data, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(reportPath, data, 0644)
}

func main() {
	// Configuration par défaut
	config := MigrationConfig{
		SourceQdrant: QdrantConfig{
			Host:   "localhost",
			Port:   6333,
			APIKey: os.Getenv("QDRANT_API_KEY"),
		},
		TargetQdrant: QdrantConfig{
			Host:   "localhost",
			Port:   6333,
			APIKey: os.Getenv("QDRANT_API_KEY"),
		},
		BackupPath:    "./backups/migration-v56",
		Collections:   []string{"roadmap_tasks", "emails", "documents"},
		BatchSize:     1000,
		ValidateAfter: true,
		DryRun:        false,
	}

	// Charger la configuration depuis un fichier si présent
	if configFile := os.Getenv("MIGRATION_CONFIG"); configFile != "" {
		if data, err := os.ReadFile(configFile); err == nil {
			if err := json.Unmarshal(data, &config); err != nil {
				log.Printf("Warning: Failed to load config file: %v", err)
			}
		}
	}

	// Mode dry run si demandé
	if os.Getenv("DRY_RUN") == "true" {
		config.DryRun = true
		log.Println("🔍 Running in DRY RUN mode")
	}

	// Créer le gestionnaire de migration
	migrator, err := NewQdrantMigrator(config)
	if err != nil {
		log.Fatalf("Failed to create migrator: %v", err)
	}

	// Exécuter la migration
	ctx := context.Background()
	results, err := migrator.RunMigration(ctx)
	if err != nil {
		log.Fatalf("Migration failed: %v", err)
	}

	// Afficher le résumé
	log.Println("\n📊 Migration Summary:")
	log.Println("=" * 50)
	for _, result := range results {
		status := "✅"
		if result.FailedPoints > 0 || len(result.Errors) > 0 {
			status = "❌"
		}
		log.Printf("%s %s: %d/%d points migrated (%v)",
			status, result.CollectionName, result.MigratedPoints, result.SourcePoints, result.Duration)

		if len(result.Errors) > 0 {
			log.Printf("   Errors: %v", result.Errors)
		}
	}

	log.Println("\n🎉 Migration process completed!")
}
