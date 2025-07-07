// Package infrastructure provides tools for automated infrastructure management
// within the AdvancedAutonomyManager ecosystem.
package infrastructure

import (
	"context"
	"fmt"
	"sync"
	"time"
)

// StartupSequencer handles the ordered startup of infrastructure services
type StartupSequencer struct {
	serviceGraph    *ServiceDependencyGraph
	healthMonitor   *HealthMonitor
	containerClient ContainerManagerClient
	logger          Logger
}

// StartupSequencerConfig defines configuration for the startup sequencer
type StartupSequencerConfig struct {
	MaxParallelServices int           `json:"max_parallel_services"` // Maximum services to start in parallel
	DefaultTimeout      time.Duration `json:"default_timeout"`       // Default service startup timeout
	RetryAttempts       int           `json:"retry_attempts"`        // Number of retry attempts on failure
	RetryDelay          time.Duration `json:"retry_delay"`           // Delay between retry attempts
}

// StartupSequenceResult contains the results of a startup sequence
type StartupSequenceResult struct {
	ServiceResults map[string]*ServiceStartupResult `json:"service_results"`
	TotalTime      time.Duration                    `json:"total_time"`
	StartOrder     []string                         `json:"start_order"`
	Successful     bool                             `json:"successful"`
	ErrorMessage   string                           `json:"error_message,omitempty"`
}

// ServiceStartupResult contains the result of starting a single service
type ServiceStartupResult struct {
	Service      string        `json:"service"`
	StartTime    time.Time     `json:"start_time"`
	Duration     time.Duration `json:"duration"`
	Successful   bool          `json:"successful"`
	HealthStatus bool          `json:"health_status"`
	RetryCount   int           `json:"retry_count"`
	Error        string        `json:"error,omitempty"`
}

// NewStartupSequencer creates a new startup sequencer
func NewStartupSequencer(
	serviceGraph *ServiceDependencyGraph,
	healthMonitor *HealthMonitor,
	containerClient ContainerManagerClient,
	logger Logger,
) *StartupSequencer {
	return &StartupSequencer{
		serviceGraph:    serviceGraph,
		healthMonitor:   healthMonitor,
		containerClient: containerClient,
		logger:          logger,
	}
}

// StartServices starts services in the correct dependency order
func (s *StartupSequencer) StartServices(
	ctx context.Context,
	services []string,
	config *StartupSequencerConfig,
) (*StartupSequenceResult, error) {
	startTime := time.Now()
	s.logger.Info("Starting services in sequence", "services", services)

	// Use default config if none provided
	if config == nil {
		config = &StartupSequencerConfig{
			MaxParallelServices: 3,
			DefaultTimeout:      60 * time.Second,
			RetryAttempts:       3,
			RetryDelay:          5 * time.Second,
		}
	}

	// Get services in dependency order
	orderedServices, err := s.serviceGraph.GetStartOrder(services)
	if err != nil {
		s.logger.Error("Failed to determine service start order", "error", err)
		return nil, fmt.Errorf("failed to determine service start order: %w", err)
	}

	result := &StartupSequenceResult{
		ServiceResults: make(map[string]*ServiceStartupResult),
		StartOrder:     orderedServices,
		Successful:     true,
	}

	// Group services that can be started in parallel
	serviceLayers := s.groupServicesByLayer(orderedServices)

	// Start each layer of services
	for layerIndex, layer := range serviceLayers {
		s.logger.Info("Starting service layer", "layer", layerIndex+1, "services", layer)

		// Start services in this layer in parallel
		var wg sync.WaitGroup
		var mu sync.Mutex

		for _, service := range layer {
			wg.Add(1)

			go func(svc string) {
				defer wg.Done()

				serviceResult := &ServiceStartupResult{
					Service:    svc,
					StartTime:  time.Now(),
					Successful: false,
					RetryCount: 0,
				}

				// Try to start service with retries
				var startErr error
				for attempt := 0; attempt < config.RetryAttempts; attempt++ {
					if attempt > 0 {
						s.logger.Info("Retrying service start",
							"service", svc,
							"attempt", attempt+1,
							"max_attempts", config.RetryAttempts)
						time.Sleep(config.RetryDelay)
					}

					// Start the service
					startErr = s.containerClient.StartContainers(ctx, []string{svc})
					if startErr == nil {
						// Wait for service to be healthy
						healthy := s.waitForServiceHealth(ctx, svc, config.DefaultTimeout)

						serviceResult.Successful = true
						serviceResult.HealthStatus = healthy

						if !healthy {
							s.logger.Warn("Service started but not yet healthy", "service", svc)
						}

						break
					}

					serviceResult.RetryCount++
				}

				// Record error if all attempts failed
				if startErr != nil {
					serviceResult.Error = startErr.Error()
					s.logger.Error("Failed to start service after retries",
						"service", svc,
						"attempts", config.RetryAttempts,
						"error", startErr)
				}

				serviceResult.Duration = time.Since(serviceResult.StartTime)

				// Store result
				mu.Lock()
				result.ServiceResults[svc] = serviceResult
				if !serviceResult.Successful {
					result.Successful = false
				}
				mu.Unlock()
			}(service)
		}

		// Wait for all services in this layer to be processed
		wg.Wait()

		// If any service in this layer failed, abort further layers
		if !result.Successful {
			result.ErrorMessage = "One or more services failed to start"
			break
		}
	}

	result.TotalTime = time.Since(startTime)
	s.logger.Info("Service startup sequence completed",
		"duration", result.TotalTime,
		"success", result.Successful)

	return result, nil
}

// waitForServiceHealth waits for a service to become healthy with timeout
func (s *StartupSequencer) waitForServiceHealth(
	ctx context.Context,
	service string,
	timeout time.Duration,
) bool {
	deadline := time.Now().Add(timeout)
	ticker := time.NewTicker(2 * time.Second)
	defer ticker.Stop()

	for {
		if time.Now().After(deadline) {
			s.logger.Warn("Health check timed out", "service", service, "timeout", timeout)
			return false
		}

		// Check service health
		healthy, err := s.healthMonitor.CheckServiceHealth(ctx, service)
		if err == nil && healthy {
			return true
		}

		select {
		case <-ctx.Done():
			s.logger.Error("Context cancelled while waiting for service health", "service", service)
			return false
		case <-ticker.C:
			// Continue checking
		}
	}
}

// groupServicesByLayer groups services into layers that can be started in parallel
func (s *StartupSequencer) groupServicesByLayer(orderedServices []string) [][]string {
	// Build dependency map for quick lookups
	dependencyMap := make(map[string]map[string]bool)

	// Initialize empty sets for each service
	for _, service := range orderedServices {
		dependencyMap[service] = make(map[string]bool)
	}

	// Fill in dependency sets
	for _, service := range orderedServices {
		deps, exists := s.serviceGraph.GetDependencies(service)
		if exists {
			for _, dep := range deps {
				dependencyMap[service][dep] = true
			}
		}
	}

	// Group services into layers
	var layers [][]string
	remaining := make(map[string]bool)

	// Initialize remaining services
	for _, service := range orderedServices {
		remaining[service] = true
	}

	// Process services until none remain
	for len(remaining) > 0 {
		// Find services with no unprocessed dependencies
		var currentLayer []string

		for service := range remaining {
			hasDeps := false
			for dep := range dependencyMap[service] {
				if remaining[dep] {
					hasDeps = true
					break
				}
			}

			if !hasDeps {
				currentLayer = append(currentLayer, service)
			}
		}

		// If we couldn't find any services for this layer, there must be a cycle
		if len(currentLayer) == 0 {
			s.logger.Error("Dependency cycle detected during layer grouping")
			break
		}

		// Add current layer to results
		layers = append(layers, currentLayer)

		// Remove processed services
		for _, service := range currentLayer {
			delete(remaining, service)
		}
	}

	return layers
}
