// Package infrastructure provides tools for automated infrastructure management
// within the AdvancedAutonomyManager ecosystem.
package infrastructure

import (
	"errors"
	"sync"
)

// ServiceDependencyGraphConfig defines the configuration for the service dependency graph
type ServiceDependencyGraphConfig struct {
	Dependencies    map[string][]string `json:"dependencies"`     // Service dependencies
	HealthChecks    map[string]string   `json:"health_checks"`    // Health check endpoints
	StartupTimeouts map[string]string   `json:"startup_timeouts"` // Startup timeouts
}

// NewServiceDependencyGraph creates a new service dependency graph
func NewServiceDependencyGraph(config *ServiceDependencyGraphConfig) (*ServiceDependencyGraph, error) {
	if config == nil {
		return &ServiceDependencyGraph{
			dependencies: make(map[string][]string),
			lock:         sync.RWMutex{},
		}, nil
	}

	return &ServiceDependencyGraph{
		dependencies: config.Dependencies,
		lock:         sync.RWMutex{},
	}, nil
}

// AddService adds a service to the dependency graph
func (g *ServiceDependencyGraph) AddService(service string, dependencies []string) {
	g.lock.Lock()
	defer g.lock.Unlock()

	g.dependencies[service] = dependencies
}

// GetDependencies returns the dependencies for a service
func (g *ServiceDependencyGraph) GetDependencies(service string) ([]string, bool) {
	g.lock.RLock()
	defer g.lock.RUnlock()

	deps, exists := g.dependencies[service]
	return deps, exists
}

// GetDependents returns the services that depend on the given service
func (g *ServiceDependencyGraph) GetDependents(service string) []string {
	g.lock.RLock()
	defer g.lock.RUnlock()

	var dependents []string
	for svc, deps := range g.dependencies {
		for _, dep := range deps {
			if dep == service {
				dependents = append(dependents, svc)
				break
			}
		}
	}

	return dependents
}

// GetAllServices returns all services in the graph
func (g *ServiceDependencyGraph) GetAllServices() []string {
	g.lock.RLock()
	defer g.lock.RUnlock()

	services := make(map[string]bool)

	// Add all services as keys
	for service := range g.dependencies {
		services[service] = true
	}

	// Add all dependencies
	for _, deps := range g.dependencies {
		for _, dep := range deps {
			services[dep] = true
		}
	}

	// Convert to slice
	result := make([]string, 0, len(services))
	for service := range services {
		result = append(result, service)
	}

	return result
}

// HasCycles checks if the dependency graph has cycles
func (g *ServiceDependencyGraph) HasCycles() bool {
	g.lock.RLock()
	defer g.lock.RUnlock()

	// Get all services
	services := make(map[string]bool)
	for service := range g.dependencies {
		services[service] = true
	}
	for _, deps := range g.dependencies {
		for _, dep := range deps {
			services[dep] = true
		}
	}

	// DFS for cycle detection
	visited := make(map[string]bool)
	recStack := make(map[string]bool)

	var checkCycle func(string) bool
	checkCycle = func(node string) bool {
		if !visited[node] {
			visited[node] = true
			recStack[node] = true

			if deps, exists := g.dependencies[node]; exists {
				for _, dep := range deps {
					if !visited[dep] && checkCycle(dep) {
						return true
					} else if recStack[dep] {
						return true
					}
				}
			}
		}

		recStack[node] = false
		return false
	}

	// Check each service
	for service := range services {
		if !visited[service] {
			if checkCycle(service) {
				return true
			}
		}
	}

	return false
}

// GetStartOrder returns the services in dependency order for startup
func (g *ServiceDependencyGraph) GetStartOrder(services []string) ([]string, error) {
	g.lock.RLock()
	defer g.lock.RUnlock()

	// Check for cycles first
	if g.HasCycles() {
		return nil, errors.New("dependency cycle detected")
	}

	// Create a service set for quick lookups
	serviceSet := make(map[string]bool)
	for _, service := range services {
		serviceSet[service] = true
	}

	// Build dependency graph and count incoming edges
	inDegree := make(map[string]int)
	graph := make(map[string][]string)

	// Initialize in-degree counts
	for service := range serviceSet {
		inDegree[service] = 0
		graph[service] = []string{}
	}

	// Count dependencies and build graph
	for service := range serviceSet {
		if deps, exists := g.dependencies[service]; exists {
			for _, dep := range deps {
				if serviceSet[dep] {
					graph[dep] = append(graph[dep], service)
					inDegree[service]++
				}
			}
		}
	}

	// Topological sort
	var result []string
	var queue []string

	// Start with nodes having no dependencies
	for service := range serviceSet {
		if inDegree[service] == 0 {
			queue = append(queue, service)
		}
	}

	// Process queue
	for len(queue) > 0 {
		service := queue[0]
		queue = queue[1:]
		result = append(result, service)

		for _, dependent := range graph[service] {
			inDegree[dependent]--
			if inDegree[dependent] == 0 {
				queue = append(queue, dependent)
			}
		}
	}

	// Ensure all services were processed
	if len(result) != len(services) {
		return nil, errors.New("could not determine valid startup order")
	}

	return result, nil
}

// GetShutdownOrder returns the services in reverse dependency order for shutdown
func (g *ServiceDependencyGraph) GetShutdownOrder(services []string) ([]string, error) {
	startOrder, err := g.GetStartOrder(services)
	if err != nil {
		return nil, err
	}

	// Reverse the order
	n := len(startOrder)
	shutdownOrder := make([]string, n)
	for i := 0; i < n; i++ {
		shutdownOrder[i] = startOrder[n-i-1]
	}

	return shutdownOrder, nil
}
