package interfaces

// Exemple d'utilisation des types importés
type DependencyManagerInterface interface {
	GetMetadata() DependencyMetadata
	SetMetadata(meta DependencyMetadata)
	BuildImage(config ImageBuildConfig) error
	GetDeploymentConfig() DeploymentConfig
	GetEnvironmentDependency() EnvironmentDependency
	// ... autres méthodes
}

type (
	DependencyMetadata    interface{}
	ImageBuildConfig      interface{}
	DeploymentConfig      interface{}
	EnvironmentDependency interface{}
)
