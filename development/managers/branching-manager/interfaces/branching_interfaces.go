package interfaces

import (
	"context"
	"time"
)

// BaseManager provides the foundation for all managers
type BaseManager interface {
	Start(ctx context.Context) error
	Stop() error
	IsHealthy() bool
	GetStatus() string
}

// StorageManager handles data storage operations
type StorageManager interface {
	BaseManager
	Store(key string, value interface{}) error
	Retrieve(key string) (interface{}, error)
	Delete(key string) error
}

// ErrorManager handles error management and recovery
type ErrorManager interface {
	BaseManager
	HandleError(err error) error
	RecordError(err error)
	GetErrorHistory() []error
}

// ContextualMemoryManager manages contextual memory operations
type ContextualMemoryManager interface {
	BaseManager
	StoreContext(ctx context.Context, data interface{}) error
	RetrieveContext(id string) (interface{}, error)
}

// Session represents a branching session
type Session struct {
	ID        string
	Name      string
	StartTime time.Time
	EndTime   *time.Time
	State     SessionState
	Metadata  map[string]interface{}
}

// SessionState represents the state of a session
type SessionState int

const (
	SessionStateActive SessionState = iota
	SessionStatePaused
	SessionStateArchived
	SessionStateCompleted
)

// BranchingEvent represents an event in the branching system
type BranchingEvent struct {
	ID        string
	Type      EventType
	Timestamp time.Time
	Data      interface{}
	Source    string
}

// EventType represents the type of branching event
type EventType int

const (
	EventTypeSessionCreated EventType = iota
	EventTypeSessionEnded
	EventTypeBranchCreated
	EventTypeBranchMerged
	EventTypeCommitMade
)

// TemporalSnapshot represents a point-in-time snapshot
type TemporalSnapshot struct {
	ID        string
	Timestamp time.Time
	State     interface{}
	Metadata  map[string]interface{}
}

// QuantumBranch represents a quantum superposition branch
type QuantumBranch struct {
	ID            string
	Superposition map[string]interface{}
	Collapsed     bool
	EntangledWith []string
}

// BranchingManager is the main interface for the branching manager
type BranchingManager interface {
	BaseManager

	// Session management
	CreateSession(name string) (*Session, error)
	GetSession(id string) (*Session, error)
	EndSession(id string) error

	// Event processing
	ProcessEvent(event *BranchingEvent) error

	// Temporal operations
	CreateSnapshot(sessionID string) (*TemporalSnapshot, error)
	RestoreFromSnapshot(snapshotID string) error

	// Quantum operations
	CreateQuantumBranch(sessionID string) (*QuantumBranch, error)
	CollapseQuantumBranch(branchID string, state interface{}) error
}
