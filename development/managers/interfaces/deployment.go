package interfaces

import "context"

// DeploymentManager interface pour la gestion des déploiements
type DeploymentManager interface {
	BaseManager
	CheckDeploymentReadiness(ctx context.Context, env string) error
	GenerateDeploymentPlan(ctx context.Context, config map[string]interface{}) (string, error)
	ExecuteDeployment(ctx context.Context, plan string) error
	RollbackDeployment(ctx context.Context, version string) error
}
