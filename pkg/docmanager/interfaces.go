// SPDX-License-Identifier: MIT
// Package docmanager : interfaces Repository, Cache, Vectorizer, Document (v65B)
package docmanager

import (
	"context"
	"errors"
	"time"
)

// Erreurs communes
var (
	ErrDocumentNotFound      = errors.New("document not found")
	ErrRepositoryUnavailable = errors.New("repository unavailable")
	ErrCacheUnavailable      = errors.New("cache unavailable")
	ErrVectorizerUnavailable = errors.New("vectorizer unavailable")
	ErrInvalidDocument       = errors.New("invalid document")
	ErrDuplicateDocument     = errors.New("duplicate document")
)

// Repository abstraction pour la persistance documentaire
type Repository interface {
	// Méthodes existantes
	Store(doc *Document) error
	Retrieve(id string) (*Document, error)
	Search(query SearchQuery) ([]*Document, error)
	Save(doc *Document) error         // Alias pour Store
	Get(id string) (*Document, error) // Alias pour Retrieve
	Delete(id string) error
	List() ([]*Document, error)

	// TASK ATOMIQUE 3.2.1.2.2 - Enhanced repository operations
	StoreWithContext(ctx context.Context, doc *Document) error
	RetrieveWithContext(ctx context.Context, id string) (*Document, error)
	SearchWithContext(ctx context.Context, query SearchQuery) ([]*Document, error)
	DeleteWithContext(ctx context.Context, id string) error
	Batch(ctx context.Context, operations []Operation) ([]BatchResult, error)
	Transaction(ctx context.Context, fn func(TransactionContext) error) error
}

// Cache abstraction pour le cache documentaire
type Cache interface {
	Set(key string, value *Document) error
	Get(key string) (*Document, bool) // Pattern idiomatique Go pour caches
	Delete(key string) error
	// Extension pour compatibility avec DocumentCache
	SetWithTTL(key string, doc *Document, ttl time.Duration) error
	GetDocument(key string) (*Document, bool)
	Clear() error
	Stats() CacheStats
}

// Vectorizer abstraction pour l’indexation sémantique
type Vectorizer interface {
	Index(doc *Document) error
	SearchVector(query string, topK int) ([]*Document, error)
	// Extension pour compatibility avec DocumentVectorizer
	GenerateEmbedding(text string) ([]float64, error)
	SearchSimilar(vector []float64, limit int) ([]*Document, error)
	IndexDocument(doc *Document) error
	RemoveDocument(id string) error
}

// SearchQuery pour la recherche documentaire
type SearchQuery struct {
	Text     string
	Managers []string
	Tags     []string
	Language string
}

// TASK ATOMIQUE 3.1.1.5 - Interface Domain Separation

// MICRO-TASK 3.1.1.5.2 - Interfaces spécialisées par domaine fonctionnel

// DocumentPersistence interface spécialisée pour la persistence
type DocumentPersistence interface {
	Store(doc *Document) error
	Retrieve(id string) (*Document, error)
	Delete(id string) error
	Exists(id string) (bool, error)
}

// DocumentCaching interface spécialisée pour le cache
type DocumentCaching interface {
	Cache(key string, doc *Document) error
	GetCached(key string) (*Document, bool)
	InvalidateCache(key string) error
	ClearCache() error
}

// DocumentVectorization interface spécialisée pour la vectorisation
type DocumentVectorization interface {
	Vectorize(doc *Document) ([]float64, error)
	SearchBySimilarity(vector []float64, limit int) ([]*Document, error)
	UpdateVector(docID string, vector []float64) error
	DeleteVector(docID string) error
}

// DocumentSearch interface spécialisée pour la recherche
type DocumentSearch interface {
	Search(query SearchQuery) ([]*Document, error)
	FullTextSearch(text string) ([]*Document, error)
	SearchByManager(manager string) ([]*Document, error)
	SearchByTags(tags []string) ([]*Document, error)
}

// DocumentSynchronization interface spécialisée pour la synchronisation
type DocumentSynchronization interface {
	SyncAcrossBranches(docID string) error
	GetBranchStatus(branch string) (BranchDocStatus, error)
	MergeDocumentation(fromBranch, toBranch string) error
	ResolveConflicts(conflicts []*DocumentConflict) error
}

// DocumentPathTracking interface spécialisée pour le tracking de paths
type DocumentPathTracking interface {
	HandleFileMove(oldPath, newPath string) error
	UpdateReferences(oldPath, newPath string) error
	ValidatePathIntegrity() error
	GetDocumentPaths() (map[string]string, error)
}

// Supporting types for specialized interfaces

type BranchDocStatus struct {
	Branch        string
	LastSync      time.Time
	ConflictCount int
	Status        string
}

// DocumentConflict already defined in conflict_resolver.go

// TASK ATOMIQUE 3.1.2 - Open/Closed Principle - Extension Framework

// MICRO-TASK 3.1.2.1.1 - Interface extensibilité design

// PluginInfo informations sur un plugin
type PluginInfo struct {
	Name        string
	Version     string
	Description string
	Author      string
	Enabled     bool
}

// PluginInterface interface générique pour les plugins
type PluginInterface interface {
	Name() string
	Version() string
	Initialize() error
	Execute(ctx context.Context, input interface{}) (interface{}, error)
	Shutdown() error
}

// ExtensibleManagerType interface pour les managers extensibles
type ExtensibleManagerType interface {
	RegisterPlugin(plugin PluginInterface) error
	UnregisterPlugin(name string) error
	ListPlugins() []PluginInfo
	GetPlugin(name string) (PluginInterface, error)
}

// MICRO-TASK 3.1.2.2.1 - Cache strategy interface

// EvictionType types de politiques d'éviction
type EvictionType int

const (
	LRU EvictionType = iota
	LFU
	TTL_BASED
	CUSTOM
)

// CacheStrategy interface pour les stratégies de cache
type CacheStrategy interface {
	ShouldCache(doc *Document) bool
	CalculateTTL(doc *Document) time.Duration
	EvictionPolicy() EvictionType
	OnCacheHit(key string)
	OnCacheMiss(key string)
}

// MICRO-TASK 3.1.2.3.1 - Vectorizer strategy interface

// VectorizationStrategy interface pour les stratégies de vectorisation
type VectorizationStrategy interface {
	GenerateEmbedding(text string) ([]float64, error)
	SupportedModels() []string
	OptimalDimensions() int
	ModelName() string
	RequiresAPIKey() bool
}

// VectorizationConfig configuration pour la vectorisation
type VectorizationConfig struct {
	Strategy   string
	ModelName  string
	Dimensions int
	APIKey     string
	Endpoint   string
	Options    map[string]interface{}
}

// TASK ATOMIQUE 3.1.4 - Interface Segregation Principle - Specialized Interfaces

// MICRO-TASK 3.1.4.1.1 - BranchAware Interface Enhancement

// BranchAware interface spécialisée pour la gestion de branches
type BranchAware interface {
	SyncAcrossBranches(ctx context.Context) error
	GetBranchStatus(branch string) (BranchDocStatus, error)
	MergeDocumentation(fromBranch, toBranch string) error
}

// MICRO-TASK 3.1.4.2.1 - PathResilient Interface Enhancement

// PathResilient interface spécialisée pour la gestion résiliente des paths
type PathResilient interface {
	TrackFileMove(oldPath, newPath string) error
	CalculateContentHash(filePath string) (string, error)
	UpdateAllReferences(oldPath, newPath string) error
	HealthCheck() (*PathHealthReport, error)
}

// MICRO-TASK 3.1.4.3.1 - CacheAware Interface Creation

// CacheMetrics métriques de performance du cache
type CacheMetrics struct {
	HitRatio      float64
	MissCount     int64
	EvictionCount int64
	MemoryUsage   int64
}

// CacheAware interface spécialisée pour la gestion du cache
type CacheAware interface {
	EnableCaching(strategy CacheStrategy) error
	DisableCaching() error
	GetCacheMetrics() CacheMetrics
	InvalidateCache(pattern string) error
}

// MICRO-TASK 3.1.4.4.1 - MetricsAware Interface Creation

// MetricsFormat format d'export des métriques
type MetricsFormat int

const (
	JSON_FORMAT MetricsFormat = iota
	PROMETHEUS_FORMAT
	CSV_FORMAT
	PLAIN_TEXT_FORMAT
)

// DocumentationMetrics métriques de documentation
type DocumentationMetrics struct {
	DocumentsProcessed    int64
	AverageProcessingTime time.Duration
	ErrorRate             float64
	CacheHitRatio         float64
	LastCollectionTime    time.Time
	TotalMemoryUsage      int64
	ActiveConnections     int
}

// MetricsAware interface spécialisée pour la collecte de métriques
type MetricsAware interface {
	CollectMetrics() DocumentationMetrics
	ResetMetrics() error
	SetMetricsInterval(interval time.Duration) error
	ExportMetrics(format MetricsFormat) ([]byte, error)
}

// TASK ATOMIQUE 3.2.1.1.2 - Interface method enhancement

// HealthStatus statut de santé d'un manager
type HealthStatus struct {
	Status    string
	LastCheck time.Time
	Issues    []string
	Details   map[string]interface{}
}

// ManagerMetrics métriques d'un manager
type ManagerMetrics struct {
	RequestCount        int64
	AverageResponseTime time.Duration
	ErrorCount          int64
	LastProcessedAt     time.Time
	ResourceUsage       map[string]interface{}
	Status              string
}

// ManagerType interface de base pour tous les managers du système
type ManagerType interface {
	Initialize(ctx context.Context) error
	Process(ctx context.Context, data interface{}) (interface{}, error)
	Shutdown() error
	Health() HealthStatus
	Metrics() ManagerMetrics
}

// TASK ATOMIQUE 3.2.1.2.2 - Enhanced repository operations

// Operation représente une opération de repository en batch
type Operation struct {
	Type     OperationType
	Document *Document
	ID       string
	Query    *SearchQuery
	Metadata map[string]interface{}
}

// OperationType type d'opération pour les batch operations
type OperationType int

const (
	OperationStore OperationType = iota
	OperationUpdate
	OperationDelete
	OperationRetrieve
)

// BatchResult résultat d'une opération batch
type BatchResult struct {
	Success     bool
	OperationID string
	Document    *Document
	Error       error
	ProcessedAt time.Time
}

// TransactionContext contexte pour les transactions
type TransactionContext interface {
	Repository
	Commit() error
	Rollback() error
	IsDone() bool
}
