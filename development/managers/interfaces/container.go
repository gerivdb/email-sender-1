package interfaces

import "context"

// ContainerManager interface pour la gestion des conteneurs
type ContainerManager interface {
	BaseManager
	ValidateForContainerization(ctx context.Context, deps []string) error
	OptimizeForContainer(ctx context.Context, config map[string]interface{}) error
	BuildImage(ctx context.Context, config map[string]interface{}) error
	DeployContainer(ctx context.Context, config map[string]interface{}) error
}
