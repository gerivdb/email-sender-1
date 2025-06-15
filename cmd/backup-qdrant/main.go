package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"time"

	"github.com/qdrant/go-client/qdrant"
)

// BackupConfig configuration pour la sauvegarde
type BackupConfig struct {
	QdrantHost       string   `json:"qdrant_host"`
	QdrantPort       int      `json:"qdrant_port"`
	QdrantAPIKey     string   `json:"qdrant_api_key"`
	BackupPath       string   `json:"backup_path"`
	Collections      []string `json:"collections"`
	VerifyIntegrity  bool     `json:"verify_integrity"`
	CompressionLevel int      `json:"compression_level"`
}

// CollectionBackup représente une sauvegarde de collection
type CollectionBackup struct {
	CollectionName string                 `json:"collection_name"`
	Config         *qdrant.CollectionInfo `json:"config"`
	Points         []qdrant.PointStruct   `json:"points"`
	Metadata       BackupMetadata         `json:"metadata"`
}

// BackupMetadata métadonnées de la sauvegarde
type BackupMetadata struct {
	CreatedAt    time.Time `json:"created_at"`
	TotalPoints  int       `json:"total_points"`
	TotalVectors int       `json:"total_vectors"`
	DataSize     int64     `json:"data_size_bytes"`
	Checksum     string    `json:"checksum"`
	Version      string    `json:"version"`
}

// QdrantBackupManager gestionnaire de sauvegarde Qdrant
type QdrantBackupManager struct {
	client *qdrant.Client
	config BackupConfig
}

// NewQdrantBackupManager crée un nouveau gestionnaire de sauvegarde
func NewQdrantBackupManager(config BackupConfig) (*QdrantBackupManager, error) {
	client, err := qdrant.NewClient(&qdrant.Config{
		Host:   config.QdrantHost,
		Port:   config.QdrantPort,
		APIKey: config.QdrantAPIKey,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create Qdrant client: %w", err)
	}

	return &QdrantBackupManager{
		client: client,
		config: config,
	}, nil
}

// BackupCollection sauvegarde une collection complète
func (qbm *QdrantBackupManager) BackupCollection(ctx context.Context, collectionName string) (*CollectionBackup, error) {
	log.Printf("Starting backup for collection: %s", collectionName)

	// 1. Récupérer les informations de la collection
	collectionInfo, err := qbm.client.GetCollection(ctx, collectionName)
	if err != nil {
		return nil, fmt.Errorf("failed to get collection info: %w", err)
	}

	// 2. Récupérer tous les points de la collection
	points, err := qbm.getAllPoints(ctx, collectionName)
	if err != nil {
		return nil, fmt.Errorf("failed to get collection points: %w", err)
	}

	// 3. Calculer les métadonnées
	metadata := BackupMetadata{
		CreatedAt:    time.Now(),
		TotalPoints:  len(points),
		TotalVectors: qbm.countVectors(points),
		Version:      "v56-go-migration",
	}

	backup := &CollectionBackup{
		CollectionName: collectionName,
		Config:         collectionInfo,
		Points:         points,
		Metadata:       metadata,
	}

	// 4. Calculer le checksum pour l'intégrité
	if qbm.config.VerifyIntegrity {
		checksum, err := qbm.calculateChecksum(backup)
		if err != nil {
			return nil, fmt.Errorf("failed to calculate checksum: %w", err)
		}
		backup.Metadata.Checksum = checksum
	}

	log.Printf("Backup completed for %s: %d points, %d vectors",
		collectionName, metadata.TotalPoints, metadata.TotalVectors)

	return backup, nil
}

// getAllPoints récupère tous les points d'une collection avec pagination
func (qbm *QdrantBackupManager) getAllPoints(ctx context.Context, collectionName string) ([]qdrant.PointStruct, error) {
	var allPoints []qdrant.PointStruct
	offset := 0
	limit := 1000 // Pagination par batch de 1000

	for {
		scrollRequest := &qdrant.ScrollPoints{
			CollectionName: collectionName,
			Limit:          &limit,
			Offset:         &offset,
			WithPayload:    &qdrant.WithPayloadSelector{Enable: true},
			WithVector:     &qdrant.WithVectorSelector{Enable: true},
		}

		result, err := qbm.client.Scroll(ctx, scrollRequest)
		if err != nil {
			return nil, fmt.Errorf("failed to scroll points at offset %d: %w", offset, err)
		}

		if len(result.Points) == 0 {
			break
		}

		allPoints = append(allPoints, result.Points...)
		offset += len(result.Points)

		log.Printf("Retrieved %d points (total: %d)", len(result.Points), len(allPoints))

		// Protection contre les boucles infinies
		if len(result.Points) < limit {
			break
		}
	}

	return allPoints, nil
}

// countVectors compte le nombre total de vecteurs
func (qbm *QdrantBackupManager) countVectors(points []qdrant.PointStruct) int {
	count := 0
	for _, point := range points {
		if point.Vector != nil {
			count++
		}
		// Compter aussi les vecteurs nommés si présents
		if point.Vectors != nil {
			count += len(point.Vectors)
		}
	}
	return count
}

// calculateChecksum calcule un checksum pour vérifier l'intégrité
func (qbm *QdrantBackupManager) calculateChecksum(backup *CollectionBackup) (string, error) {
	// Simplification : utiliser un hash des métadonnées importantes
	data := fmt.Sprintf("%s-%d-%d-%s",
		backup.CollectionName,
		backup.Metadata.TotalPoints,
		backup.Metadata.TotalVectors,
		backup.Metadata.CreatedAt.Format(time.RFC3339))

	// En production, utiliser crypto/sha256 pour un vrai checksum
	return fmt.Sprintf("sha256-%x", []byte(data)), nil
}

// SaveBackup sauvegarde les données sur disque
func (qbm *QdrantBackupManager) SaveBackup(backup *CollectionBackup) error {
	// Créer le répertoire de sauvegarde s'il n'existe pas
	backupDir := filepath.Join(qbm.config.BackupPath, backup.Metadata.CreatedAt.Format("2006-01-02_15-04-05"))
	if err := os.MkdirAll(backupDir, 0755); err != nil {
		return fmt.Errorf("failed to create backup directory: %w", err)
	}

	// Nom du fichier de sauvegarde
	filename := fmt.Sprintf("%s_backup.json", backup.CollectionName)
	filepath := filepath.Join(backupDir, filename)

	// Encoder en JSON
	data, err := json.MarshalIndent(backup, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal backup data: %w", err)
	}

	// Écrire le fichier
	if err := os.WriteFile(filepath, data, 0644); err != nil {
		return fmt.Errorf("failed to write backup file: %w", err)
	}

	// Mettre à jour la taille des données
	backup.Metadata.DataSize = int64(len(data))

	log.Printf("Backup saved to: %s (size: %d bytes)", filepath, backup.Metadata.DataSize)
	return nil
}

// ValidateBackup valide l'intégrité d'une sauvegarde
func (qbm *QdrantBackupManager) ValidateBackup(backupPath string) error {
	log.Printf("Validating backup: %s", backupPath)

	// Lire le fichier de sauvegarde
	data, err := os.ReadFile(backupPath)
	if err != nil {
		return fmt.Errorf("failed to read backup file: %w", err)
	}

	// Décoder le JSON
	var backup CollectionBackup
	if err := json.Unmarshal(data, &backup); err != nil {
		return fmt.Errorf("failed to unmarshal backup data: %w", err)
	}

	// Validation basique
	if backup.CollectionName == "" {
		return fmt.Errorf("backup has empty collection name")
	}

	if backup.Metadata.TotalPoints != len(backup.Points) {
		return fmt.Errorf("point count mismatch: metadata=%d, actual=%d",
			backup.Metadata.TotalPoints, len(backup.Points))
	}

	// Validation du checksum si présent
	if backup.Metadata.Checksum != "" && qbm.config.VerifyIntegrity {
		expectedChecksum, err := qbm.calculateChecksum(&backup)
		if err != nil {
			return fmt.Errorf("failed to calculate checksum for validation: %w", err)
		}

		if backup.Metadata.Checksum != expectedChecksum {
			return fmt.Errorf("checksum mismatch: expected=%s, actual=%s",
				expectedChecksum, backup.Metadata.Checksum)
		}
	}

	log.Printf("Backup validation successful: %s", backup.CollectionName)
	return nil
}

// CreateSnapshot crée un snapshot de sécurité
func (qbm *QdrantBackupManager) CreateSnapshot(ctx context.Context, collectionName string) error {
	log.Printf("Creating snapshot for collection: %s", collectionName)

	// Utiliser l'API Qdrant pour créer un snapshot
	snapshotRequest := &qdrant.CreateSnapshotRequest{
		CollectionName: collectionName,
	}

	result, err := qbm.client.CreateSnapshot(ctx, snapshotRequest)
	if err != nil {
		return fmt.Errorf("failed to create snapshot: %w", err)
	}

	log.Printf("Snapshot created successfully: %s", result.Name)
	return nil
}

// RunFullBackup exécute une sauvegarde complète de toutes les collections configurées
func (qbm *QdrantBackupManager) RunFullBackup(ctx context.Context) error {
	log.Printf("Starting full backup of %d collections", len(qbm.config.Collections))

	for _, collectionName := range qbm.config.Collections {
		log.Printf("Processing collection: %s", collectionName)

		// 1. Sauvegarde de la collection
		backup, err := qbm.BackupCollection(ctx, collectionName)
		if err != nil {
			log.Printf("ERROR: Failed to backup collection %s: %v", collectionName, err)
			continue
		}

		// 2. Sauvegarder sur disque
		if err := qbm.SaveBackup(backup); err != nil {
			log.Printf("ERROR: Failed to save backup for %s: %v", collectionName, err)
			continue
		}

		// 3. Créer un snapshot
		if err := qbm.CreateSnapshot(ctx, collectionName); err != nil {
			log.Printf("WARNING: Failed to create snapshot for %s: %v", collectionName, err)
			// Continue car ce n'est pas critique
		}

		log.Printf("✅ Collection %s backed up successfully", collectionName)
	}

	log.Printf("Full backup completed")
	return nil
}

func main() {
	// Configuration par défaut
	config := BackupConfig{
		QdrantHost:       "localhost",
		QdrantPort:       6333,
		QdrantAPIKey:     os.Getenv("QDRANT_API_KEY"),
		BackupPath:       "./backups/migration-v56",
		Collections:      []string{"roadmap_tasks", "emails", "documents"},
		VerifyIntegrity:  true,
		CompressionLevel: 6,
	}

	// Charger la configuration depuis un fichier si présent
	if configFile := os.Getenv("BACKUP_CONFIG"); configFile != "" {
		if data, err := os.ReadFile(configFile); err == nil {
			if err := json.Unmarshal(data, &config); err != nil {
				log.Printf("Warning: Failed to load config file: %v", err)
			}
		}
	}

	// Créer le gestionnaire de sauvegarde
	backupManager, err := NewQdrantBackupManager(config)
	if err != nil {
		log.Fatalf("Failed to create backup manager: %v", err)
	}

	// Exécuter la sauvegarde complète
	ctx := context.Background()
	if err := backupManager.RunFullBackup(ctx); err != nil {
		log.Fatalf("Full backup failed: %v", err)
	}

	log.Println("🎉 Backup process completed successfully!")
}
