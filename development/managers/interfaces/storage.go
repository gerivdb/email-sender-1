package interfaces

import "context"

// StorageManager interface pour la gestion du stockage
type StorageManager interface {
	BaseManager
	SaveDependencyMetadata(ctx context.Context, metadata *DependencyMetadata) error
	GetDependencyMetadata(ctx context.Context, name string) (*DependencyMetadata, error)
	QueryDependencies(ctx context.Context, query string) ([]*DependencyMetadata, error)
	StoreObject(ctx context.Context, key string, obj interface{}) error
	GetObject(ctx context.Context, key string, obj interface{}) error
	DeleteObject(ctx context.Context, key string) error
	ListObjects(ctx context.Context, prefix string) ([]string, error)
	GetPostgreSQLConnection() (interface{}, error)
	GetQdrantConnection() (interface{}, error)
	RunMigrations(ctx context.Context) error
}
