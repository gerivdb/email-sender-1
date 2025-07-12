package dependency

import "github.com/gerivdb/email-sender-1/development/managers/interfaces"

// Exemple d'utilisation des types importés
type DependencyManagerInterface interface {
	GetMetadata() interfaces.DependencyMetadata
	SetMetadata(meta interfaces.DependencyMetadata)
	BuildImage(config interfaces.ImageBuildConfig) error
	GetDeploymentConfig() interfaces.DeploymentConfig
	GetEnvironmentDependency() interfaces.EnvironmentDependency
	// ... autres méthodes
}
