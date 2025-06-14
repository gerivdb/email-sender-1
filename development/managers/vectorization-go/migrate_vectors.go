package vectorization

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"go.uber.org/zap"
)

// VectorMigrator gère la migration des vecteurs depuis Python vers Go
type VectorMigrator struct {
	pythonDataPath string
	targetClient   *VectorClient
	batchSize      int
	logger         *zap.Logger
	errorHandler   *ErrorHandler
	stats          MigrationStats
	mutex          sync.RWMutex
}

// MigrationStats contient les statistiques de migration
type MigrationStats struct {
	TotalVectors      int           `json:"total_vectors"`
	MigratedVectors   int           `json:"migrated_vectors"`
	FailedVectors     int           `json:"failed_vectors"`
	StartTime         time.Time     `json:"start_time"`
	EndTime           time.Time     `json:"end_time"`
	Duration          time.Duration `json:"duration"`
	BytesProcessed    int64         `json:"bytes_processed"`
	ErrorsEncountered []string      `json:"errors_encountered"`
}

// PythonVectorData représente la structure des données vectorielles Python
type PythonVectorData struct {
	ID       string                 `json:"id"`
	Vector   []float32              `json:"vector"`
	Metadata map[string]interface{} `json:"metadata"`
	Source   string                 `json:"source"`
}

// MigrationConfig configure la migration
type MigrationConfig struct {
	BatchSize             int    `yaml:"batch_size"`
	MaxWorkers            int    `yaml:"max_workers"`
	InputFormat           string `yaml:"input_format"` // "json", "pickle", "csv"
	ValidateVectors       bool   `yaml:"validate_vectors"`
	BackupBeforeMigration bool   `yaml:"backup_before_migration"`
	ContinueOnError       bool   `yaml:"continue_on_error"`
}

// NewVectorMigrator crée un nouveau migrateur de vecteurs
func NewVectorMigrator(pythonDataPath string, targetClient *VectorClient, config MigrationConfig, logger *zap.Logger) *VectorMigrator {
	errorHandler := NewErrorHandler(DefaultRetryConfig(), logger)

	return &VectorMigrator{
		pythonDataPath: pythonDataPath,
		targetClient:   targetClient,
		batchSize:      config.BatchSize,
		logger:         logger,
		errorHandler:   errorHandler,
		stats: MigrationStats{
			StartTime: time.Now(),
		},
	}
}

// MigratePythonVectors migre tous les vecteurs Python vers Go
func (vm *VectorMigrator) MigratePythonVectors(ctx context.Context) error {
	vm.logger.Info("Début de la migration des vecteurs Python",
		zap.String("source_path", vm.pythonDataPath),
		zap.Int("batch_size", vm.batchSize))

	vm.stats.StartTime = time.Now()

	// Étape 1: Lire les vecteurs depuis les fichiers Python
	vectors, err := vm.readPythonVectors()
	if err != nil {
		return fmt.Errorf("échec lecture vecteurs Python: %w", err)
	}

	vm.updateStats(func(stats *MigrationStats) {
		stats.TotalVectors = len(vectors)
	})

	vm.logger.Info("Vecteurs Python chargés",
		zap.Int("total_count", len(vectors)))

	// Étape 2: Validation des vecteurs si activée
	if err := vm.validateVectors(vectors); err != nil {
		return fmt.Errorf("échec validation vecteurs: %w", err)
	}

	// Étape 3: Migration par lots
	if err := vm.migrateBatches(ctx, vectors); err != nil {
		return fmt.Errorf("échec migration par lots: %w", err)
	}

	// Finaliser les statistiques
	vm.updateStats(func(stats *MigrationStats) {
		stats.EndTime = time.Now()
		stats.Duration = stats.EndTime.Sub(stats.StartTime)
	})

	vm.logger.Info("Migration terminée avec succès",
		zap.Int("total_vectors", vm.stats.TotalVectors),
		zap.Int("migrated_vectors", vm.stats.MigratedVectors),
		zap.Int("failed_vectors", vm.stats.FailedVectors),
		zap.Duration("duration", vm.stats.Duration))

	return nil
}

// readPythonVectors lit les vecteurs depuis les fichiers Python
func (vm *VectorMigrator) readPythonVectors() ([]Vector, error) {
	vm.logger.Info("Lecture des fichiers de vecteurs Python",
		zap.String("path", vm.pythonDataPath))

	var allVectors []Vector

	// Parcourir le répertoire pour trouver les fichiers de vecteurs
	err := filepath.Walk(vm.pythonDataPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Traiter seulement les fichiers JSON pour le moment
		if !info.IsDir() && strings.HasSuffix(strings.ToLower(path), ".json") {
			vectors, err := vm.readJSONVectorFile(path)
			if err != nil {
				vm.logger.Warn("Erreur lecture fichier",
					zap.String("file", path),
					zap.Error(err))
				return nil // Continuer avec les autres fichiers
			}
			allVectors = append(allVectors, vectors...)
		}

		return nil
	})

	if err != nil {
		return nil, fmt.Errorf("erreur parcours répertoire: %w", err)
	}

	vm.logger.Info("Lecture terminée",
		zap.Int("total_vectors", len(allVectors)),
		zap.String("source", vm.pythonDataPath))

	return allVectors, nil
}

// readJSONVectorFile lit un fichier JSON contenant des vecteurs
func (vm *VectorMigrator) readJSONVectorFile(filePath string) ([]Vector, error) {
	data, err := ioutil.ReadFile(filePath)
	if err != nil {
		return nil, fmt.Errorf("erreur lecture fichier %s: %w", filePath, err)
	}

	vm.updateStats(func(stats *MigrationStats) {
		stats.BytesProcessed += int64(len(data))
	})

	// Essayer de parser comme un tableau de vecteurs
	var pythonVectors []PythonVectorData
	if err := json.Unmarshal(data, &pythonVectors); err != nil {
		// Essayer de parser comme un seul vecteur
		var singleVector PythonVectorData
		if err2 := json.Unmarshal(data, &singleVector); err2 != nil {
			return nil, fmt.Errorf("erreur parsing JSON %s: %w", filePath, err)
		}
		pythonVectors = []PythonVectorData{singleVector}
	}

	// Convertir au format Go
	vectors := make([]Vector, 0, len(pythonVectors))
	for _, pv := range pythonVectors {
		vector := Vector{
			ID:       pv.ID,
			Values:   pv.Vector,
			Metadata: pv.Metadata,
		}

		// Ajouter des métadonnées de migration
		if vector.Metadata == nil {
			vector.Metadata = make(map[string]interface{})
		}
		vector.Metadata["migrated_from"] = "python"
		vector.Metadata["source_file"] = filepath.Base(filePath)
		vector.Metadata["migration_time"] = time.Now()

		vectors = append(vectors, vector)
	}

	vm.logger.Debug("Fichier JSON traité",
		zap.String("file", filePath),
		zap.Int("vectors_count", len(vectors)))

	return vectors, nil
}

// validateVectors valide les vecteurs avant migration
func (vm *VectorMigrator) validateVectors(vectors []Vector) error {
	vm.logger.Info("Validation des vecteurs", zap.Int("count", len(vectors)))

	expectedSize := vm.targetClient.config.VectorSize
	var errors []string

	for i, vector := range vectors {
		if err := ValidateVector(vector, expectedSize); err != nil {
			errorMsg := fmt.Sprintf("vecteur %d (ID: %s): %s", i, vector.ID, err.Error())
			errors = append(errors, errorMsg)

			if len(errors) > 10 { // Limiter le nombre d'erreurs affichées
				break
			}
		}
	}

	if len(errors) > 0 {
		vm.updateStats(func(stats *MigrationStats) {
			stats.ErrorsEncountered = append(stats.ErrorsEncountered, errors...)
		})

		return fmt.Errorf("validation échouée: %d erreurs détectées, exemples: %v",
			len(errors), errors[:min(3, len(errors))])
	}

	vm.logger.Info("Validation réussie", zap.Int("vectors_validated", len(vectors)))
	return nil
}

// migrateBatches migre les vecteurs par lots
func (vm *VectorMigrator) migrateBatches(ctx context.Context, vectors []Vector) error {
	batchSize := vm.batchSize
	if batchSize <= 0 {
		batchSize = 100
	}

	vm.logger.Info("Début migration par lots",
		zap.Int("total_vectors", len(vectors)),
		zap.Int("batch_size", batchSize))

	// Traitement par lots
	for i := 0; i < len(vectors); i += batchSize {
		end := i + batchSize
		if end > len(vectors) {
			end = len(vectors)
		}

		batch := vectors[i:end]
		batchNumber := (i / batchSize) + 1
		totalBatches := (len(vectors) + batchSize - 1) / batchSize

		vm.logger.Info("Traitement du lot",
			zap.Int("batch_number", batchNumber),
			zap.Int("total_batches", totalBatches),
			zap.Int("batch_size", len(batch)))

		// Migrer le lot avec retry
		err := vm.errorHandler.ExecuteWithRetry(ctx, "migrate_batch", func() error {
			return vm.targetClient.UpsertVectors(ctx, batch)
		})

		if err != nil {
			vm.updateStats(func(stats *MigrationStats) {
				stats.FailedVectors += len(batch)
				stats.ErrorsEncountered = append(stats.ErrorsEncountered,
					fmt.Sprintf("lot %d: %s", batchNumber, err.Error()))
			})

			vm.logger.Error("Échec migration du lot",
				zap.Int("batch_number", batchNumber),
				zap.Error(err))

			return fmt.Errorf("échec lot %d: %w", batchNumber, err)
		}

		// Mettre à jour les statistiques
		vm.updateStats(func(stats *MigrationStats) {
			stats.MigratedVectors += len(batch)
		})

		vm.logger.Info("Lot migré avec succès",
			zap.Int("batch_number", batchNumber),
			zap.Int("vectors_migrated", len(batch)))
	}

	return nil
}

// GetMigrationStats retourne les statistiques actuelles de migration
func (vm *VectorMigrator) GetMigrationStats() MigrationStats {
	vm.mutex.RLock()
	defer vm.mutex.RUnlock()
	return vm.stats
}

// updateStats met à jour les statistiques de manière thread-safe
func (vm *VectorMigrator) updateStats(updater func(*MigrationStats)) {
	vm.mutex.Lock()
	defer vm.mutex.Unlock()
	updater(&vm.stats)
}

// ExportMigrationReport exporte un rapport de migration
func (vm *VectorMigrator) ExportMigrationReport(outputPath string) error {
	vm.mutex.RLock()
	stats := vm.stats
	vm.mutex.RUnlock()

	reportData, err := json.MarshalIndent(stats, "", "  ")
	if err != nil {
		return fmt.Errorf("erreur sérialisation rapport: %w", err)
	}

	if err := ioutil.WriteFile(outputPath, reportData, 0644); err != nil {
		return fmt.Errorf("erreur écriture rapport: %w", err)
	}

	vm.logger.Info("Rapport de migration exporté",
		zap.String("output_path", outputPath))

	return nil
}

// min retourne le minimum entre deux entiers
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
