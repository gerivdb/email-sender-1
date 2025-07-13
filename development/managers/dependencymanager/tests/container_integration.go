package tests

import (
	"context"
	"fmt" // Keep fmt for Sprintf

	"github.com/gerivdb/email-sender-1/development/managers/interfaces"
	"github.com/gerivdb/email-sender-1/projet/cred"
)

// initializeContainerIntegration sets up container manager integration
func initializeContainerIntegration(m *cred.GoModManager) error { // Added m as parameter
	// Check if container manager is already initialized
	if m.ContainerManager != nil { // Access directly
		return nil
	}

	m.Logger.Info("Initializing container integration...") // Use m.Logger
	// In a real implementation, this would use a factory or service locator
	// to get an instance of the ContainerManager

	// For now we'll just log this step
	m.Logger.Info("Container integration initialized successfully") // Use m.Logger
	return nil
}

// validateDependenciesForContainer checks if the current dependencies are container-compatible
func validateDependenciesForContainer(m *cred.GoModManager, ctx context.Context, dependencies []interfaces.Dependency) (*interfaces.ContainerValidationResult, error) { // Added m as parameter
	if m.ContainerManager == nil { // Access directly
		return nil, fmt.Errorf("ContainerManager not initialized")
	}

	m.Logger.Info(fmt.Sprintf("Validating %d dependencies for container compatibility", len(dependencies))) // Use m.Logger

	// Use the container manager to validate dependencies
	result, err := m.ContainerManager.ValidateForContainerization(ctx, dependencies) // Access directly
	if err != nil {
		m.Logger.Error(fmt.Sprintf("Error validating dependencies for containerization: %v", err)) // Use m.Logger
		return nil, err
	}

	// Log the validation results
	m.Logger.Info(fmt.Sprintf("Container validation results - Compatible: %v, Issues: %d",
		result.IsValid, len(result.ValidationErrors))) // Use m.Logger

	return result, nil
}

// optimizeDependenciesForContainer optimizes dependencies for container environments
func optimizeDependenciesForContainer(m *cred.GoModManager, ctx context.Context, dependencies []interfaces.Dependency) (*interfaces.ContainerOptimization, error) { // Added m as parameter
	if m.ContainerManager == nil { // Access directly
		return nil, fmt.Errorf("ContainerManager not initialized")
	}

	m.Logger.Info(fmt.Sprintf("Optimizing %d dependencies for container environment", len(dependencies))) // Use m.Logger

	// Use the container manager to optimize dependencies
	optimization, err := m.ContainerManager.OptimizeForContainer(ctx, dependencies) // Access directly
	if err != nil {
		m.Logger.Error(fmt.Sprintf("Error optimizing dependencies for container: %v", err)) // Use m.Logger
		return nil, err
	}

	// Log the optimization results
	m.Logger.Info(fmt.Sprintf("Container optimization results - Type: %s, Difficulty: %s",
		optimization.Type, optimization.Difficulty)) // Use m.Logger

	return optimization, nil
}

// generateDockerfileFromDependencies creates a Dockerfile based on the project's dependencies
func generateDockerfileFromDependencies(m *cred.GoModManager, ctx context.Context, dependencies []interfaces.Dependency) (string, error) { // Added m as parameter
	if m.ContainerManager == nil { // Access directly
		return "", fmt.Errorf("ContainerManager not initialized")
	}

	m.Logger.Info("Generating Dockerfile based on current dependencies") // Use m.Logger

	// Optimize dependencies for container environment
	optimization, err := optimizeDependenciesForContainer(m, ctx, dependencies) // Call local function
	if err != nil {
		m.Logger.Error(fmt.Sprintf("Error optimizing dependencies: %v", err)) // Use m.Logger
		return "", err
	}

	// Generate a basic Dockerfile based on optimization
	dockerfile := fmt.Sprintf("# Generated Dockerfile based on dependency optimization\n# Optimization type: %s\n# Description: %s\n",
		optimization.Type, optimization.Description)

	m.Logger.Info("Successfully generated Dockerfile from dependencies") // Use m.Logger
	return dockerfile, nil
}

// getDependencyContainerStatus checks container compatibility status for the current project
func getDependencyContainerStatus(m *cred.GoModManager, ctx context.Context) (string, error) { // Added m as parameter
	// Get current dependencies
	deps, err := m.List()
	if err != nil {
		m.Logger.Error(fmt.Sprintf("Error listing dependencies: %v", err)) // Use m.Logger
		return "", fmt.Errorf("failed to list dependencies: %v", err)
	}

	// Convert to standard Dependency type expected by ContainerManager
	var dependencies []interfaces.Dependency
	for _, dep := range deps {
		dependencies = append(dependencies, interfaces.Dependency{
			Name:       dep.Name,
			Version:    dep.Version,
			Repository: dep.Repository,
		})
	}

	// Validate dependencies for container compatibility
	result, err := validateDependenciesForContainer(m, ctx, dependencies) // Call local function
	if err != nil {
		return "", err
	}

	// Generate a human-readable status message
	var status string
	if result.IsValid {
		status = "COMPATIBLE - All dependencies are container-compatible"
	} else {
		status = fmt.Sprintf("ISSUES DETECTED - %d compatibility issues found", len(result.ValidationErrors))
		if len(result.ValidationErrors) > 0 {
			status += "\n\nIssues:\n"
			for i, issue := range result.ValidationErrors {
				status += fmt.Sprintf("%d. %s\n", i+1, issue)
			}
		}
		if len(result.Recommendations) > 0 {
			status += "\nRecommendations:\n"
			for i, rec := range result.Recommendations {
				status += fmt.Sprintf("%d. %s\n", i+1, rec)
			}
		}
	}

	return status, nil
}
