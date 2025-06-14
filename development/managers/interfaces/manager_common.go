package interfaces

import (
	"context"
	"time"
)

// ManagerInterface définit l'interface commune pour tous les managers de l'écosystème
type ManagerInterface interface {
	// Lifecycle methods
	Initialize(ctx context.Context, config interface{}) error
	Start(ctx context.Context) error
	Stop(ctx context.Context) error

	// Status and monitoring
	GetStatus() ManagerStatus
	GetMetrics() ManagerMetrics
	ValidateConfig(config interface{}) error

	// Identity
	GetID() string
	GetName() string
	GetVersion() string

	// Health check
	Health(ctx context.Context) error
}

// BaseManager définit les méthodes de base communes à tous les managers
type BaseManager interface {
	GetID() string
	GetName() string
	GetVersion() string
	GetStatus() ManagerStatus
	Health(ctx context.Context) error
}

// ManagerStatus représente l'état d'un manager
type ManagerStatus struct {
	Name      string        `json:"name"`
	Status    string        `json:"status"` // "initializing", "running", "stopped", "error", "healthy"
	LastCheck time.Time     `json:"last_check"`
	Errors    []string      `json:"errors"`
	Uptime    time.Duration `json:"uptime"`
}

// ManagerMetrics représente les métriques d'un manager
type ManagerMetrics struct {
	Name         string            `json:"name"`
	Uptime       time.Duration     `json:"uptime"`
	RequestCount int64             `json:"request_count"`
	ErrorCount   int64             `json:"error_count"`
	LastRequest  time.Time         `json:"last_request"`
	CustomData   map[string]string `json:"custom_data"`
}

// ManagerConfig représente la configuration de base d'un manager
type ManagerConfig struct {
	Name       string                 `yaml:"name" json:"name"`
	Version    string                 `yaml:"version" json:"version"`
	Enabled    bool                   `yaml:"enabled" json:"enabled"`
	Debug      bool                   `yaml:"debug" json:"debug"`
	LogLevel   string                 `yaml:"log_level" json:"log_level"`
	Timeout    time.Duration          `yaml:"timeout" json:"timeout"`
	CustomData map[string]interface{} `yaml:"custom_data" json:"custom_data"`
}

// ManagerRegistry interface pour la découverte automatique de managers
type ManagerRegistry interface {
	RegisterManager(name string, manager ManagerInterface) error
	UnregisterManager(name string) error
	GetManager(name string) (ManagerInterface, error)
	ListManagers() []string
	GetAllManagers() map[string]ManagerInterface
}

// EventBus interface pour la communication inter-managers
type EventBus interface {
	Publish(ctx context.Context, event *ManagerEvent) error
	Subscribe(ctx context.Context, eventType string, handler EventHandler) error
	Unsubscribe(ctx context.Context, eventType string, handler EventHandler) error
}

// ManagerEvent représente un événement du système
type ManagerEvent struct {
	ID        string                 `json:"id"`
	Type      string                 `json:"type"`
	Source    string                 `json:"source"`
	Target    string                 `json:"target,omitempty"`
	Timestamp time.Time              `json:"timestamp"`
	Data      map[string]interface{} `json:"data"`
}

// EventHandler définit le type de fonction pour gérer les événements
type EventHandler func(ctx context.Context, event *ManagerEvent) error

// Coordinator interface pour la coordination des managers
type Coordinator interface {
	RegisterManager(name string, manager ManagerInterface) error
	UnregisterManager(name string) error
	StartAll(ctx context.Context) error
	StopAll(ctx context.Context) error
	GetAllManagersStatus() map[string]ManagerStatus
	HealthCheck(ctx context.Context) error
}
