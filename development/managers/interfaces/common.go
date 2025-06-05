package interfaces

import (
	"context"
)

// BaseManager définit l'interface de base pour tous les managers
type BaseManager interface {
	HealthCheck(ctx context.Context) error
	Initialize(ctx context.Context) error
	Cleanup() error
}

// Initializer définit l'interface d'initialisation
type Initializer interface {
	Initialize(ctx context.Context) error
}

// HealthChecker définit l'interface de vérification de santé
type HealthChecker interface {
	HealthCheck(ctx context.Context) error
}

// Cleaner définit l'interface de nettoyage
type Cleaner interface {
	Cleanup() error
}
