package interfaces

import (
	"context"
)

// BaseManager définit l'interface de base pour tous les managers

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

// ErrorManager interface pour la gestion des erreurs
type ErrorManager interface {
	BaseManager
	LogError(ctx context.Context, component, message string, err error) error
	ProcessError(ctx context.Context, component, operation string, err error) error
}

// ConfigManager interface pour la gestion de configuration
type ConfigManager interface {
	BaseManager
	GetString(key string) (string, error)
	GetInt(key string) (int, error)
	GetBool(key string) (bool, error)
	Get(key string) interface{}
	Set(key string, value interface{}) error
	GetAll() map[string]interface{}
}
