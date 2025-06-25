package storage

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/lib/pq"
	_ "github.com/lib/pq"
	"github.com/email-sender-manager/interfaces"
)

// StorageManagerImpl implémente StorageManager
type StorageManagerImpl struct {
	id            string
	name          string
	version       string
	status        interfaces.ManagerStatus
	config        *StorageConfig
	db            *sql.DB
	qdrant        QdrantClient
	cache         map[string]interface{}
	cacheMutex    sync.RWMutex
	logger        *log.Logger
	migrations    *MigrationManager
	isInitialized bool
	mu            sync.RWMutex

	// Phase 4.2.1: Ajout des capacités de vectorisation
	vectorizer         VectorizationEngine     // Moteur de vectorisation pour auto-indexation
	configIndexer      *ConfigurationIndexer   // Indexeur de fichiers de configuration
	schemaVectorizer   *SchemaVectorizer       // Vectoriseur de schémas de base de données
	semanticSearcher   *SemanticSearcher       // Recherche sémantique dans les configurations
	vectorizationEnabled bool                  // Flag d'activation de la vectorisation
}

// StorageConfig configuration pour le gestionnaire de stockage
type StorageConfig struct {
	PostgreSQL PostgreSQLConfig `json:"postgresql"`
	Qdrant     QdrantConfig     `json:"qdrant"`
	Cache      CacheConfig      `json:"cache"`
	Migrations MigrationsConfig `json:"migrations"`
}

// PostgreSQLConfig configuration PostgreSQL
type PostgreSQLConfig struct {
	Host         string `json:"host"`
	Port         int    `json:"port"`
	Database     string `json:"database"`
	Username     string `json:"username"`
	Password     string `json:"password"`
	SSLMode      string `json:"ssl_mode"`
	MaxOpenConns int    `json:"max_open_conns"`
	MaxIdleConns int    `json:"max_idle_conns"`
	MaxLifetime  string `json:"max_lifetime"`
}

// QdrantConfig configuration Qdrant
type QdrantConfig struct {
	Host    string `json:"host"`
	Port    int    `json:"port"`
	APIKey  string `json:"api_key"`
	Timeout string `json:"timeout"`
}

// CacheConfig configuration cache
type CacheConfig struct {
	MaxSize    int    `json:"max_size"`
	TTL        string `json:"ttl"`
	CleanupInt string `json:"cleanup_interval"`
}

// MigrationsConfig configuration migrations
type MigrationsConfig struct {
	Path       string `json:"path"`
	AutoRun    bool   `json:"auto_run"`
	TableName  string `json:"table_name"`
}

// QdrantClient interface pour Qdrant
type QdrantClient interface {
	Connect(ctx context.Context) error
	StoreVector(ctx context.Context, collection string, id string, vector []float32, payload map[string]interface{}) error
	SearchVector(ctx context.Context, collection string, vector []float32, limit int) ([]QdrantSearchResult, error)
	DeleteVector(ctx context.Context, collection string, id string) error
	Close() error
}

// QdrantSearchResult résultat de recherche Qdrant
type QdrantSearchResult struct {
	ID      string                 `json:"id"`
	Score   float32                `json:"score"`
	Payload map[string]interface{} `json:"payload"`
}

// MigrationManager gère les migrations de base de données
type MigrationManager struct {
	db        *sql.DB
	config    MigrationsConfig
	logger    *log.Logger
	tableName string
}

// NewStorageManager crée une nouvelle instance du gestionnaire de stockage
func NewStorageManager() interfaces.StorageManager {
	config := loadStorageConfig()
	
	manager := &StorageManagerImpl{
		id:      uuid.New().String(),
		name:    "storage-manager",
		version: "1.0.0",
		status:  interfaces.StatusStopped,
		config:  config,
		cache:   make(map[string]interface{}),
		logger:  log.New(os.Stdout, "[STORAGE] ", log.LstdFlags|log.Lshortfile),
	}

	return manager
}

// loadStorageConfig charge la configuration depuis les variables d'environnement
func loadStorageConfig() *StorageConfig {
	return &StorageConfig{
		PostgreSQL: PostgreSQLConfig{
			Host:         getEnv("POSTGRES_HOST", "localhost"),
			Port:         getEnvInt("POSTGRES_PORT", 5432),
			Database:     getEnv("POSTGRES_DB", "email_sender"),
			Username:     getEnv("POSTGRES_USER", "postgres"),
			Password:     getEnv("POSTGRES_PASSWORD", ""),
			SSLMode:      getEnv("POSTGRES_SSL_MODE", "disable"),
			MaxOpenConns: getEnvInt("POSTGRES_MAX_OPEN_CONNS", 25),
			MaxIdleConns: getEnvInt("POSTGRES_MAX_IDLE_CONNS", 25),
			MaxLifetime:  getEnv("POSTGRES_MAX_LIFETIME", "5m"),
		},
		Qdrant: QdrantConfig{
			Host:    getEnv("QDRANT_HOST", "localhost"),
			Port:    getEnvInt("QDRANT_PORT", 6333),
			APIKey:  getEnv("QDRANT_API_KEY", ""),
			Timeout: getEnv("QDRANT_TIMEOUT", "30s"),
		},
		Cache: CacheConfig{
			MaxSize:    getEnvInt("CACHE_MAX_SIZE", 1000),
			TTL:        getEnv("CACHE_TTL", "1h"),
			CleanupInt: getEnv("CACHE_CLEANUP_INTERVAL", "10m"),
		},
		Migrations: MigrationsConfig{
			Path:      getEnv("MIGRATIONS_PATH", "./migrations"),
			AutoRun:   getEnvBool("MIGRATIONS_AUTO_RUN", true),
			TableName: getEnv("MIGRATIONS_TABLE", "schema_migrations"),
		},
	}
}// Interface compliance methods

// GetID retourne l'ID du manager
func (sm *StorageManagerImpl) GetID() string {
	return sm.id
}

// GetName retourne le nom du manager
func (sm *StorageManagerImpl) GetName() string {
	return sm.name
}

// GetVersion retourne la version du manager
func (sm *StorageManagerImpl) GetVersion() string {
	return sm.version
}

// GetStatus retourne le statut du manager
func (sm *StorageManagerImpl) GetStatus() interfaces.ManagerStatus {
	sm.mu.RLock()
	defer sm.mu.RUnlock()
	return sm.status
}

// Initialize initialise le gestionnaire de stockage
func (sm *StorageManagerImpl) Initialize(ctx context.Context) error {
	sm.mu.Lock()
	defer sm.mu.Unlock()

	if sm.isInitialized {
		return nil
	}

	sm.logger.Println("Initializing Storage Manager...")
	sm.status = interfaces.StatusStarting

	// Initialiser PostgreSQL
	if err := sm.initPostgreSQL(ctx); err != nil {
		sm.status = interfaces.StatusError
		return fmt.Errorf("failed to initialize PostgreSQL: %w", err)
	}

	// Initialiser Qdrant
	if err := sm.initQdrant(ctx); err != nil {
		sm.status = interfaces.StatusError
		return fmt.Errorf("failed to initialize Qdrant: %w", err)
	}

	// Initialiser les migrations
	if err := sm.initMigrations(ctx); err != nil {
		sm.status = interfaces.StatusError
		return fmt.Errorf("failed to initialize migrations: %w", err)
	}

	// Exécuter les migrations si configuré
	if sm.config.Migrations.AutoRun {
		if err := sm.RunMigrations(ctx); err != nil {
			sm.logger.Printf("Warning: Failed to run migrations: %v", err)
		}
	}

	sm.isInitialized = true
	sm.status = interfaces.StatusRunning
	sm.logger.Println("Storage Manager initialized successfully")
	return nil
}

// Start démarre le gestionnaire de stockage
func (sm *StorageManagerImpl) Start(ctx context.Context) error {
	if !sm.isInitialized {
		if err := sm.Initialize(ctx); err != nil {
			return err
		}
	}

	sm.mu.Lock()
	defer sm.mu.Unlock()

	if sm.status == interfaces.StatusRunning {
		return nil
	}

	sm.status = interfaces.StatusRunning
	sm.logger.Println("Storage Manager started")
	return nil
}

// Stop arrête le gestionnaire de stockage
func (sm *StorageManagerImpl) Stop(ctx context.Context) error {
	sm.mu.Lock()
	defer sm.mu.Unlock()

	sm.logger.Println("Stopping Storage Manager...")
	sm.status = interfaces.StatusStopping

	// Fermer les connexions
	if sm.db != nil {
		if err := sm.db.Close(); err != nil {
			sm.logger.Printf("Error closing database: %v", err)
		}
	}

	if sm.qdrant != nil {
		if err := sm.qdrant.Close(); err != nil {
			sm.logger.Printf("Error closing Qdrant: %v", err)
		}
	}

	sm.status = interfaces.StatusStopped
	sm.logger.Println("Storage Manager stopped")
	return nil
}

// Health vérifie la santé du gestionnaire
func (sm *StorageManagerImpl) Health(ctx context.Context) error {
	sm.mu.RLock()
	defer sm.mu.RUnlock()

	if sm.status != interfaces.StatusRunning {
		return fmt.Errorf("storage manager is not running, status: %v", sm.status)
	}

	// Vérifier PostgreSQL
	if sm.db != nil {
		if err := sm.db.PingContext(ctx); err != nil {
			return fmt.Errorf("PostgreSQL health check failed: %w", err)
		}
	}

	// Vérifier le cache
	sm.cacheMutex.RLock()
	cacheSize := len(sm.cache)
	sm.cacheMutex.RUnlock()

	sm.logger.Printf("Health check passed - Cache size: %d", cacheSize)
	return nil
}// Storage operations methods

// SaveDependencyMetadata sauvegarde les métadonnées de dépendance
func (sm *StorageManagerImpl) SaveDependencyMetadata(ctx context.Context, metadata *interfaces.DependencyMetadata) error {
	if !sm.isInitialized {
		return fmt.Errorf("storage manager not initialized")
	}

	// Sauvegarder en base de données
	query := `
		INSERT INTO dependency_metadata (name, version, description, dependencies, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6)
		ON CONFLICT (name, version) 
		DO UPDATE SET 
			description = EXCLUDED.description,
			dependencies = EXCLUDED.dependencies,
			updated_at = EXCLUDED.updated_at
	`

	dependenciesJSON, err := json.Marshal(metadata.Dependencies)
	if err != nil {
		return fmt.Errorf("failed to marshal dependencies: %w", err)
	}

	now := time.Now()
	_, err = sm.db.ExecContext(ctx, query,
		metadata.Name, metadata.Version, metadata.Description,
		dependenciesJSON, now, now)
	if err != nil {
		return fmt.Errorf("failed to save dependency metadata: %w", err)
	}

	// Mettre en cache
	cacheKey := fmt.Sprintf("dep_meta:%s:%s", metadata.Name, metadata.Version)
	sm.setCache(cacheKey, metadata)

	sm.logger.Printf("Saved dependency metadata: %s@%s", metadata.Name, metadata.Version)
	return nil
}

// GetDependencyMetadata récupère les métadonnées de dépendance
func (sm *StorageManagerImpl) GetDependencyMetadata(ctx context.Context, name string) (*interfaces.DependencyMetadata, error) {
	if !sm.isInitialized {
		return nil, fmt.Errorf("storage manager not initialized")
	}

	// Vérifier le cache d'abord
	cacheKey := fmt.Sprintf("dep_meta:%s", name)
	if cached := sm.getCache(cacheKey); cached != nil {
		if metadata, ok := cached.(*interfaces.DependencyMetadata); ok {
			return metadata, nil
		}
	}

	// Requête en base de données
	query := `
		SELECT name, version, description, dependencies, created_at, updated_at
		FROM dependency_metadata 
		WHERE name = $1 
		ORDER BY created_at DESC 
		LIMIT 1
	`

	var metadata interfaces.DependencyMetadata
	var dependenciesJSON []byte
	var createdAt, updatedAt time.Time

	err := sm.db.QueryRowContext(ctx, query, name).Scan(
		&metadata.Name, &metadata.Version, &metadata.Description,
		&dependenciesJSON, &createdAt, &updatedAt)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("dependency metadata not found: %s", name)
		}
		return nil, fmt.Errorf("failed to get dependency metadata: %w", err)
	}

	if err := json.Unmarshal(dependenciesJSON, &metadata.Dependencies); err != nil {
		return nil, fmt.Errorf("failed to unmarshal dependencies: %w", err)
	}

	// Mettre en cache
	sm.setCache(cacheKey, &metadata)

	return &metadata, nil
}

// === PHASE 4.2.1: INTERFACES DE VECTORISATION POUR STORAGE MANAGER ===

// VectorizationEngine interface pour le moteur de vectorisation
type VectorizationEngine interface {
	GenerateEmbedding(ctx context.Context, text string) ([]float32, error)
	GenerateConfigEmbedding(ctx context.Context, config interface{}) ([]float32, error)
	GenerateSchemaEmbedding(ctx context.Context, schema DatabaseSchema) ([]float32, error)
}

// ConfigurationIndexer gère l'auto-indexation des fichiers de configuration
type ConfigurationIndexer struct {
	vectorizer       VectorizationEngine
	qdrant          QdrantClient
	watchedPaths    []string
	indexedConfigs  map[string]*ConfigMetadata
	mu              sync.RWMutex
	logger          *log.Logger
}

// ConfigMetadata métadonnées d'un fichier de configuration indexé
type ConfigMetadata struct {
	FilePath     string                 `json:"file_path"`
	ConfigType   string                 `json:"config_type"`   // json, yaml, env, etc.
	LastModified time.Time              `json:"last_modified"`
	Embedding    []float32              `json:"embedding"`
	Content      map[string]interface{} `json:"content"`
	Tags         []string               `json:"tags"`
	Schema       string                 `json:"schema,omitempty"`
}

// SchemaVectorizer gère la vectorisation des schémas de base de données
type SchemaVectorizer struct {
	vectorizer       VectorizationEngine
	qdrant          QdrantClient
	schemas         map[string]*DatabaseSchema
	schemaEmbeddings map[string][]float32
	mu              sync.RWMutex
	logger          *log.Logger
}

// DatabaseSchema représente un schéma de base de données
type DatabaseSchema struct {
	Name        string              `json:"name"`
	Tables      []TableSchema       `json:"tables"`
	Relations   []RelationSchema    `json:"relations"`
	Indexes     []IndexSchema       `json:"indexes"`
	Constraints []ConstraintSchema  `json:"constraints"`
	Version     string              `json:"version"`
	CreatedAt   time.Time           `json:"created_at"`
	UpdatedAt   time.Time           `json:"updated_at"`
}

// TableSchema représente un schéma de table
type TableSchema struct {
	Name        string         `json:"name"`
	Columns     []ColumnSchema `json:"columns"`
	PrimaryKey  []string       `json:"primary_key"`
	ForeignKeys []ForeignKey   `json:"foreign_keys"`
	Indexes     []string       `json:"indexes"`
	Comment     string         `json:"comment,omitempty"`
}

// ColumnSchema représente un schéma de colonne
type ColumnSchema struct {
	Name         string `json:"name"`
	Type         string `json:"type"`
	Nullable     bool   `json:"nullable"`
	DefaultValue string `json:"default_value,omitempty"`
	Comment      string `json:"comment,omitempty"`
}

// RelationSchema représente une relation entre tables
type RelationSchema struct {
	FromTable  string `json:"from_table"`
	ToTable    string `json:"to_table"`
	FromColumn string `json:"from_column"`
	ToColumn   string `json:"to_column"`
	Type       string `json:"type"` // one-to-one, one-to-many, many-to-many
}

// IndexSchema représente un index
type IndexSchema struct {
	Name    string   `json:"name"`
	Table   string   `json:"table"`
	Columns []string `json:"columns"`
	Unique  bool     `json:"unique"`
	Type    string   `json:"type"`
}

// ConstraintSchema représente une contrainte
type ConstraintSchema struct {
	Name   string `json:"name"`
	Table  string `json:"table"`
	Type   string `json:"type"`   // CHECK, UNIQUE, NOT NULL, etc.
	Detail string `json:"detail"` // détails de la contrainte
}

// ForeignKey représente une clé étrangère
type ForeignKey struct {
	Column          string `json:"column"`
	ReferencedTable string `json:"referenced_table"`
	ReferencedColumn string `json:"referenced_column"`
	OnDelete        string `json:"on_delete,omitempty"`
	OnUpdate        string `json:"on_update,omitempty"`
}

// SemanticSearcher gère la recherche sémantique dans les configurations
type SemanticSearcher struct {
	vectorizer     VectorizationEngine
	qdrant        QdrantClient
	configIndexer *ConfigurationIndexer
	schemaVectorizer *SchemaVectorizer
	logger        *log.Logger
}

// SearchResult représente un résultat de recherche sémantique
type SearchResult struct {
	Type        string                 `json:"type"`        // config, schema, table, etc.
	ID          string                 `json:"id"`
	Name        string                 `json:"name"`
	Score       float32                `json:"score"`
	Content     map[string]interface{} `json:"content"`
	Metadata    map[string]interface{} `json:"metadata"`
	Path        string                 `json:"path,omitempty"`
	Description string                 `json:"description,omitempty"`
}

// StorageVectorization interface pour les capacités de vectorisation du Storage Manager
type StorageVectorization interface {
	// Phase 4.2.1.1: Auto-indexation des fichiers de configuration
	IndexConfiguration(ctx context.Context, filePath string) error
	UpdateConfigurationIndex(ctx context.Context, filePath string) error
	RemoveConfigurationIndex(ctx context.Context, filePath string) error
	WatchConfigurationDirectory(ctx context.Context, dirPath string) error
	
	// Phase 4.2.1.2: Vectorisation des schémas de base de données
	IndexDatabaseSchema(ctx context.Context, schemaName string) error
	UpdateSchemaIndex(ctx context.Context, schemaName string) error
	GetSchemaEmbedding(ctx context.Context, schemaName string) ([]float32, error)
	FindSimilarSchemas(ctx context.Context, schemaName string, threshold float64) ([]SearchResult, error)
	
	// Phase 4.2.1.3: Recherche sémantique dans les configurations
	SearchConfigurations(ctx context.Context, query string, limit int) ([]SearchResult, error)
	SearchSchemas(ctx context.Context, query string, limit int) ([]SearchResult, error)
	SearchTables(ctx context.Context, query string, limit int) ([]SearchResult, error)
	SearchAll(ctx context.Context, query string, limit int) ([]SearchResult, error)
	
	// Méthodes de gestion
	EnableVectorization() error
	DisableVectorization() error
	GetVectorizationStatus() bool
	GetVectorizationMetrics() VectorizationMetrics
}
