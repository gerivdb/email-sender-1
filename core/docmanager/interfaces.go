// core/docmanager/interfaces.go
// Interfaces principales et types de base pour DocManager v66

package docmanager

import (
	"context"
	"time"
)

// Interface principale de gestion documentaire
type DocumentManager interface {
	CreateDocument(ctx context.Context, doc *Document) error
	UpdateDocument(ctx context.Context, doc *Document) error
	DeleteDocument(ctx context.Context, id string) error
	GetDocument(ctx context.Context, id string) (*Document, error)
}

// Intégration des managers
type ManagerIntegrator interface {
	RegisterManager(manager ManagerType) error
	SyncManager(ctx context.Context, managerName string) error
	GetManagerStatus(managerName string) ManagerStatus
}

// Gestion multi-branches
type BranchAware interface {
	SyncAcrossBranches(ctx context.Context) error
	GetBranchStatus(branch string) BranchDocStatus
	MergeDocumentation(fromBranch, toBranch string) error
}

// Résilience aux déplacements de fichiers
type PathResilient interface {
	HandleFileMove(oldPath, newPath string) error
	UpdateReferences(oldPath, newPath string) error
	ValidatePathIntegrity() error
}

// Abstraction du repository documentaire
type Repository interface {
	Store(ctx context.Context, doc *Document) error
	Retrieve(ctx context.Context, id string) (*Document, error)
	Search(ctx context.Context, query SearchQuery) ([]*Document, error)
}

// Types de base (stubs pour Phase 1)
type Config struct {
	DatabaseURL   string
	RedisURL      string
	QDrantURL     string
	SyncInterval  time.Duration
	PathTracking  bool
	AutoResolve   bool
	CrossBranch   bool
	DefaultBranch string
}

type Cache interface{}
type Vectorizer interface{}
type PathTracker struct{}
type BranchSynchronizer struct{}
type ManagerType string
type ManagerStatus struct{}
type BranchDocStatus struct{}
type Document struct{}
type SearchQuery struct{}
