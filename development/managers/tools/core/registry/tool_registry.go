// Manager Toolkit - Tool Registry System
// Version: 3.0.0
// Provides automatic tool registration and conflict detection

package registry

import (
	"context"
	"fmt"
	"sync"

<<<<<<< HEAD
	"EMAIL_SENDER_1/tools/core/toolkit"
=======
	"github.com/email-sender/tools/core/platform" // Changed to platform
>>>>>>> origin/jules/fix-build-errors-and-cycles
)

// Global registry instance for automatic registration
var globalRegistry *ToolRegistry

// RegisterGlobalTool registers a tool with the global registry
func RegisterGlobalTool(op platform.Operation, tool platform.ToolkitOperation) error { // Use platform types
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
	tools     map[platform.Operation]platform.ToolkitOperation // Use platform types
	conflicts map[string][]string
	mutex     sync.RWMutex
}

// NewToolRegistry creates a new tool registry
func NewToolRegistry() *ToolRegistry {
	return &ToolRegistry{
		tools:     make(map[platform.Operation]platform.ToolkitOperation), // Use platform types
		conflicts: make(map[string][]string),
	}
}

// Register registers a new tool with conflict detection
func (tr *ToolRegistry) Register(op platform.Operation, tool platform.ToolkitOperation) error { // Use platform types
	tr.mutex.Lock()
	defer tr.mutex.Unlock()

	// Check if operation already exists
	if existingTool, exists := tr.tools[op]; exists {
		return fmt.Errorf("operation %s already registered by tool %s", op, existingTool.String())
	}

	// Validate the tool
	ctx := context.Background() // Consider passing context if tool validation needs it
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
func (tr *ToolRegistry) GetTool(op platform.Operation) (platform.ToolkitOperation, error) { // Use platform types
	tr.mutex.RLock()
	defer tr.mutex.RUnlock()

	tool, exists := tr.tools[op]
	if !exists {
		return nil, fmt.Errorf("operation %s not registered", op)
	}

	return tool, nil
}

// ListOperations returns all registered operations
func (tr *ToolRegistry) ListOperations() []platform.Operation { // Use platform types
	tr.mutex.RLock()
	defer tr.mutex.RUnlock()

	operations := make([]platform.Operation, 0, len(tr.tools)) // Use platform types
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
