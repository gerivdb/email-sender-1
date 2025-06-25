// Manager Toolkit - Tool Registry System
// Version: 3.0.0
// Provides automatic tool registration and conflict detection

package registry

import (
	"context"
	"fmt"
	"sync"

	"github.com/gerivdb/email-sender-1/tools/core/toolkit"
)

// Global registry instance for automatic registration
var globalRegistry *ToolRegistry

// RegisterGlobalTool registers a tool with the global registry
func RegisterGlobalTool(op toolkit.Operation, tool toolkit.ToolkitOperation) error {
	if globalRegistry == nil {
		globalRegistry = NewToolRegistry()
	}
	return globalRegistry.Register(op, tool)
}

// GetGlobalRegistry returns the global tool registry
func GetGlobalRegistry() *ToolRegistry {
	if globalRegistry == nil {
		globalRegistry = NewToolRegistry()
	}
	return globalRegistry
}

// ToolRegistry manages automatic tool registration and conflict prevention
type ToolRegistry struct {
	tools     map[toolkit.Operation]toolkit.ToolkitOperation
	conflicts map[string][]string
	mutex     sync.RWMutex
}

// NewToolRegistry creates a new tool registry
func NewToolRegistry() *ToolRegistry {
	return &ToolRegistry{
		tools:     make(map[toolkit.Operation]toolkit.ToolkitOperation),
		conflicts: make(map[string][]string),
	}
}

// Register registers a new tool with conflict detection
func (tr *ToolRegistry) Register(op toolkit.Operation, tool toolkit.ToolkitOperation) error {
	tr.mutex.Lock()
	defer tr.mutex.Unlock()

	// Check if operation already exists
	if existingTool, exists := tr.tools[op]; exists {
		return fmt.Errorf("operation %s already registered by tool %s", op, existingTool.String())
	}

	// Validate the tool
	ctx := context.Background()
	if err := tool.Validate(ctx); err != nil {
		return fmt.Errorf("tool validation failed for operation %s: %w", op, err)
	}

	// Check for naming conflicts
	toolName := tool.String()
	for existingOp, existingTool := range tr.tools {
		if existingTool.String() == toolName {
			tr.conflicts[toolName] = append(tr.conflicts[toolName], string(existingOp), string(op))
			return fmt.Errorf("tool name conflict: %s already used by operation %s", toolName, existingOp)
		}
	}

	// Register the tool
	tr.tools[op] = tool
	return nil
}

// GetTool retrieves a tool by operation
func (tr *ToolRegistry) GetTool(op toolkit.Operation) (toolkit.ToolkitOperation, error) {
	tr.mutex.RLock()
	defer tr.mutex.RUnlock()

	tool, exists := tr.tools[op]
	if !exists {
		return nil, fmt.Errorf("operation %s not registered", op)
	}

	return tool, nil
}

// ListOperations returns all registered operations
func (tr *ToolRegistry) ListOperations() []toolkit.Operation {
	tr.mutex.RLock()
	defer tr.mutex.RUnlock()

	operations := make([]toolkit.Operation, 0, len(tr.tools))
	for op := range tr.tools {
		operations = append(operations, op)
	}

	return operations
}

// GetConflicts returns all detected naming conflicts
func (tr *ToolRegistry) GetConflicts() map[string][]string {
	tr.mutex.RLock()
	defer tr.mutex.RUnlock()

	conflicts := make(map[string][]string)
	for name, ops := range tr.conflicts {
		conflicts[name] = make([]string, len(ops))
		copy(conflicts[name], ops)
	}

	return conflicts
}

// Validate performs comprehensive validation of all registered tools
func (tr *ToolRegistry) Validate(ctx context.Context) error {
	tr.mutex.RLock()
	defer tr.mutex.RUnlock()

	for op, tool := range tr.tools {
		if err := tool.HealthCheck(ctx); err != nil {
			return fmt.Errorf("health check failed for operation %s: %w", op, err)
		}
	}

	return nil
}
