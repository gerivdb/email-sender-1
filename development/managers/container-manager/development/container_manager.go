package main

import (
	"context"
	"fmt"
	"log"
	"os/exec"
	"strings"
	"time"

	"go.uber.org/zap"
)

// ContainerManager interface defines the contract for container management
type ContainerManager interface {
	Initialize(ctx context.Context) error
	StartContainers(ctx context.Context, services []string) error
	StopContainers(ctx context.Context, services []string) error
	GetContainerStatus(ctx context.Context, service string) (string, error)
	GetContainerLogs(ctx context.Context, service string) ([]string, error)
	ValidateForContainerization(ctx context.Context, dependencies []Dependency) (*ContainerValidationResult, error)
	OptimizeForContainer(ctx context.Context, dependencies []Dependency) (*ContainerOptimization, error)
	BuildImage(ctx context.Context, imageName string, dockerfile string) error
	PushImage(ctx context.Context, imageName string) error
	PullImage(ctx context.Context, imageName string) error
	CreateNetwork(ctx context.Context, networkName string) error
	CreateVolume(ctx context.Context, volumeName string) error
	HealthCheck(ctx context.Context) error
	Cleanup() error
}

// Dependency represents a dependency to validate for containerization
type Dependency struct {
	Name    string `json:"name"`
	Version string `json:"version"`
	Path    string `json:"path,omitempty"`
	Type    string `json:"type,omitempty"` // "binary", "library", "config", etc.
}

// ContainerValidationResult represents container validation results
type ContainerValidationResult struct {
	Compatible      bool      `json:"compatible"`
	Timestamp       time.Time `json:"timestamp"`
	Issues          []string  `json:"issues"`
	Recommendations []string  `json:"recommendations"`
	RequiredImages  []string  `json:"required_images"`
	EstimatedSize   int64     `json:"estimated_size_mb"`
}

// ContainerOptimization represents container optimization results
type ContainerOptimization struct {
	OptimizedDeps []Dependency `json:"optimized_dependencies"`
	SpaceSaved    int64        `json:"space_saved_mb"`
	LayerCount    int          `json:"layer_count"`
	Timestamp     time.Time    `json:"timestamp"`
	Dockerfile    string       `json:"dockerfile"`
	BuildArgs     []string     `json:"build_args"`
}

// ContainerInfo represents information about a container
type ContainerInfo struct {
	ID       string            `json:"id"`
	Name     string            `json:"name"`
	Image    string            `json:"image"`
	Status   string            `json:"status"`
	Ports    map[string]string `json:"ports"`
	Networks []string          `json:"networks"`
	Volumes  []string          `json:"volumes"`
	Created  time.Time         `json:"created"`
}

// containerManagerImpl implements ContainerManager with ErrorManager integration
type containerManagerImpl struct {
	logger       *zap.Logger
	errorManager ErrorManager
	dockerHost   string
	composeFile  string
	dockerPath   string
	composePath  string
}

// ErrorManager interface for local implementation
type ErrorManager interface {
	ProcessError(ctx context.Context, err error, component, operation string, hooks *ErrorHooks) error
	CatalogError(ctx context.Context, entry *ErrorEntry) error
	ValidateErrorEntry(entry *ErrorEntry) error
}

// ErrorEntry represents an error entry
type ErrorEntry struct {
	ID        string `json:"id"`
	Timestamp string `json:"timestamp"`
	Level     string `json:"level"`
	Component string `json:"component"`
	Operation string `json:"operation"`
	Message   string `json:"message"`
	Details   string `json:"details,omitempty"`
}

// ErrorHooks for error processing
type ErrorHooks struct {
	PreProcess  func(error) error
	PostProcess func(error) error
}

// NewContainerManager creates a new ContainerManager instance
func NewContainerManager(logger *zap.Logger, dockerHost, composeFile string) ContainerManager {
	return &containerManagerImpl{
		logger:      logger,
		dockerHost:  dockerHost,
		composeFile: composeFile,
		dockerPath:  "docker",         // Default docker command
		composePath: "docker-compose", // Default docker-compose command
	}
}

// Initialize initializes the container manager
func (cm *containerManagerImpl) Initialize(ctx context.Context) error {
	cm.logger.Info("Initializing ContainerManager")

	// Verify Docker is available
	if err := cm.verifyDocker(ctx); err != nil {
		return fmt.Errorf("failed to verify Docker: %w", err)
	}

	// Verify Docker Compose is available
	if err := cm.verifyDockerCompose(ctx); err != nil {
		return fmt.Errorf("failed to verify Docker Compose: %w", err)
	}

	// Load and validate docker-compose configuration
	if cm.composeFile != "" {
		if err := cm.validateComposeFile(ctx); err != nil {
			return fmt.Errorf("failed to validate compose file: %w", err)
		}
	}

	cm.logger.Info("ContainerManager initialized successfully")
	return nil
}

// verifyDocker checks if Docker is available and running
func (cm *containerManagerImpl) verifyDocker(ctx context.Context) error {
	cmd := exec.CommandContext(ctx, cm.dockerPath, "version", "--format", "{{.Client.Version}}")
	output, err := cmd.Output()
	if err != nil {
		return fmt.Errorf("Docker not available: %w", err)
	}

	version := strings.TrimSpace(string(output))
	cm.logger.Info("Docker verified", zap.String("version", version))

	// Test Docker daemon connection
	cmd = exec.CommandContext(ctx, cm.dockerPath, "info")
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("Docker daemon not accessible: %w", err)
	}

	return nil
}

// verifyDockerCompose checks if Docker Compose is available
func (cm *containerManagerImpl) verifyDockerCompose(ctx context.Context) error {
	cmd := exec.CommandContext(ctx, cm.composePath, "version", "--short")
	output, err := cmd.Output()
	if err != nil {
		return fmt.Errorf("Docker Compose not available: %w", err)
	}

	version := strings.TrimSpace(string(output))
	cm.logger.Info("Docker Compose verified", zap.String("version", version))

	return nil
}

// validateComposeFile validates the docker-compose configuration
func (cm *containerManagerImpl) validateComposeFile(ctx context.Context) error {
	if cm.composeFile == "" {
		return nil
	}

	cmd := exec.CommandContext(ctx, cm.composePath, "-f", cm.composeFile, "config", "--quiet")
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("invalid docker-compose file: %w", err)
	}

	cm.logger.Info("Docker Compose file validated", zap.String("file", cm.composeFile))
	return nil
}

// StartContainers starts specified containers
func (cm *containerManagerImpl) StartContainers(ctx context.Context, services []string) error {
	cm.logger.Info("Starting containers", zap.Strings("services", services))

	if cm.composeFile == "" {
		return fmt.Errorf("no compose file configured")
	}

	args := []string{"-f", cm.composeFile, "up", "-d"}
	if len(services) > 0 {
		args = append(args, services...)
	}

	cmd := exec.CommandContext(ctx, cm.composePath, args...)
	output, err := cmd.CombinedOutput()

	if err != nil {
		cm.logger.Error("Failed to start containers", zap.Error(err), zap.String("output", string(output)))
		return fmt.Errorf("failed to start containers: %w", err)
	}

	cm.logger.Info("Containers started successfully", zap.String("output", string(output)))
	return nil
}

// StopContainers stops specified containers
func (cm *containerManagerImpl) StopContainers(ctx context.Context, services []string) error {
	cm.logger.Info("Stopping containers", zap.Strings("services", services))

	if cm.composeFile == "" {
		return fmt.Errorf("no compose file configured")
	}

	args := []string{"-f", cm.composeFile, "down"}
	if len(services) > 0 {
		// For specific services, use stop instead of down
		args = []string{"-f", cm.composeFile, "stop"}
		args = append(args, services...)
	}

	cmd := exec.CommandContext(ctx, cm.composePath, args...)
	output, err := cmd.CombinedOutput()

	if err != nil {
		cm.logger.Error("Failed to stop containers", zap.Error(err), zap.String("output", string(output)))
		return fmt.Errorf("failed to stop containers: %w", err)
	}

	cm.logger.Info("Containers stopped successfully", zap.String("output", string(output)))
	return nil
}

// GetContainerStatus returns the status of a container
func (cm *containerManagerImpl) GetContainerStatus(ctx context.Context, service string) (string, error) {
	cm.logger.Info("Getting container status", zap.String("service", service))

	// First try with docker-compose
	if cm.composeFile != "" {
		cmd := exec.CommandContext(ctx, cm.composePath, "-f", cm.composeFile, "ps", "-q", service)
		output, err := cmd.Output()
		if err == nil && len(output) > 0 {
			containerID := strings.TrimSpace(string(output))
			return cm.getDockerContainerStatus(ctx, containerID)
		}
	}

	// Fallback to direct docker command
	cmd := exec.CommandContext(ctx, cm.dockerPath, "ps", "-a", "--filter", fmt.Sprintf("name=%s", service), "--format", "{{.Status}}")
	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("failed to get container status: %w", err)
	}

	status := strings.TrimSpace(string(output))
	if status == "" {
		return "not found", nil
	}

	return status, nil
}

// getDockerContainerStatus gets status from container ID
func (cm *containerManagerImpl) getDockerContainerStatus(ctx context.Context, containerID string) (string, error) {
	cmd := exec.CommandContext(ctx, cm.dockerPath, "inspect", "--format", "{{.State.Status}}", containerID)
	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("failed to inspect container: %w", err)
	}

	return strings.TrimSpace(string(output)), nil
}

// GetContainerLogs retrieves logs from a container
func (cm *containerManagerImpl) GetContainerLogs(ctx context.Context, service string) ([]string, error) {
	cm.logger.Info("Getting container logs", zap.String("service", service))

	var cmd *exec.Cmd
	if cm.composeFile != "" {
		cmd = exec.CommandContext(ctx, cm.composePath, "-f", cm.composeFile, "logs", "--tail=100", service)
	} else {
		cmd = exec.CommandContext(ctx, cm.dockerPath, "logs", "--tail=100", service)
	}

	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to get container logs: %w", err)
	}

	lines := strings.Split(string(output), "\n")
	var cleanLines []string
	for _, line := range lines {
		if strings.TrimSpace(line) != "" {
			cleanLines = append(cleanLines, line)
		}
	}

	return cleanLines, nil
}

// ValidateForContainerization validates dependencies for container deployment
func (cm *containerManagerImpl) ValidateForContainerization(ctx context.Context, dependencies []Dependency) (*ContainerValidationResult, error) {
	cm.logger.Info("Validating dependencies for containerization", zap.Int("count", len(dependencies)))

	result := &ContainerValidationResult{
		Compatible:      true,
		Timestamp:       time.Now(),
		Issues:          []string{},
		Recommendations: []string{},
		RequiredImages:  []string{},
		EstimatedSize:   0,
	}

	baseImageSize := int64(100) // Base image size in MB
	result.EstimatedSize = baseImageSize

	for _, dep := range dependencies {
		// Analyze dependency for container compatibility
		if err := cm.validateDependency(dep, result); err != nil {
			cm.logger.Warn("Dependency validation issue", zap.String("dependency", dep.Name), zap.Error(err))
			result.Issues = append(result.Issues, fmt.Sprintf("%s: %s", dep.Name, err.Error()))
		}
	}

	// Add general recommendations
	if len(dependencies) > 50 {
		result.Recommendations = append(result.Recommendations, "Consider using multi-stage builds to reduce image size")
	}

	if result.EstimatedSize > 1000 { // > 1GB
		result.Recommendations = append(result.Recommendations, "Image size is large, consider optimizing dependencies")
	}

	// Mark as incompatible if there are critical issues
	if len(result.Issues) > 0 {
		for _, issue := range result.Issues {
			if strings.Contains(strings.ToLower(issue), "critical") || strings.Contains(strings.ToLower(issue), "incompatible") {
				result.Compatible = false
				break
			}
		}
	}

	cm.logger.Info("Container validation completed",
		zap.Bool("compatible", result.Compatible),
		zap.Int("issues", len(result.Issues)),
		zap.Int64("estimated_size_mb", result.EstimatedSize))

	return result, nil
}

// validateDependency validates a single dependency for containerization
func (cm *containerManagerImpl) validateDependency(dep Dependency, result *ContainerValidationResult) error {
	// Estimate size based on dependency type and name
	var estimatedSize int64 = 10 // Default 10MB

	switch dep.Type {
	case "binary":
		estimatedSize = 50
	case "library":
		estimatedSize = 5
	case "config":
		estimatedSize = 1
	default:
		// Estimate based on name patterns
		if strings.Contains(dep.Name, "runtime") || strings.Contains(dep.Name, "engine") {
			estimatedSize = 100
		} else if strings.Contains(dep.Name, "dev") || strings.Contains(dep.Name, "tool") {
			estimatedSize = 25
		}
	}

	result.EstimatedSize += estimatedSize

	// Check for known problematic dependencies
	problematicPatterns := []string{"gui", "desktop", "x11", "display"}
	for _, pattern := range problematicPatterns {
		if strings.Contains(strings.ToLower(dep.Name), pattern) {
			return fmt.Errorf("may require GUI components not suitable for containers")
		}
	}

	// Check for dependencies that might need specific base images
	if strings.Contains(dep.Name, "python") {
		result.RequiredImages = append(result.RequiredImages, "python:3.9")
	} else if strings.Contains(dep.Name, "node") || strings.Contains(dep.Name, "npm") {
		result.RequiredImages = append(result.RequiredImages, "node:16")
	} else if strings.Contains(dep.Name, "go") || strings.Contains(dep.Name, "golang") {
		result.RequiredImages = append(result.RequiredImages, "golang:1.19")
	}

	return nil
}

// OptimizeForContainer optimizes dependencies for container deployment
func (cm *containerManagerImpl) OptimizeForContainer(ctx context.Context, dependencies []Dependency) (*ContainerOptimization, error) {
	cm.logger.Info("Optimizing dependencies for container", zap.Int("count", len(dependencies)))

	optimization := &ContainerOptimization{
		OptimizedDeps: make([]Dependency, 0),
		SpaceSaved:    0,
		LayerCount:    1,
		Timestamp:     time.Now(),
		BuildArgs:     []string{},
	}

	// Optimize dependencies
	for _, dep := range dependencies {
		optimizedDep := cm.optimizeDependency(dep)
		optimization.OptimizedDeps = append(optimization.OptimizedDeps, optimizedDep)

		// Calculate space saved (simplified calculation)
		if optimizedDep.Type == "optimized" {
			optimization.SpaceSaved += 10 // 10MB saved per optimized dependency
		}
	}

	// Generate optimized Dockerfile
	optimization.Dockerfile = cm.generateOptimizedDockerfile(optimization.OptimizedDeps)

	// Calculate layer count based on optimization
	optimization.LayerCount = cm.calculateOptimalLayers(optimization.OptimizedDeps)

	cm.logger.Info("Container optimization completed",
		zap.Int("optimized_deps", len(optimization.OptimizedDeps)),
		zap.Int64("space_saved_mb", optimization.SpaceSaved),
		zap.Int("layer_count", optimization.LayerCount))

	return optimization, nil
}

// optimizeDependency optimizes a single dependency for container use
func (cm *containerManagerImpl) optimizeDependency(dep Dependency) Dependency {
	optimized := dep

	// Mark development dependencies for removal in production
	if strings.Contains(strings.ToLower(dep.Name), "dev") ||
		strings.Contains(strings.ToLower(dep.Name), "test") ||
		strings.Contains(strings.ToLower(dep.Name), "debug") {
		optimized.Type = "dev-only"
	}

	// Optimize version specifications
	if dep.Version == "latest" {
		optimized.Version = "stable" // Use stable instead of latest for better reproducibility
		optimized.Type = "optimized"
	}

	return optimized
}

// generateOptimizedDockerfile generates an optimized Dockerfile
func (cm *containerManagerImpl) generateOptimizedDockerfile(deps []Dependency) string {
	var dockerfile strings.Builder

	// Multi-stage build setup
	dockerfile.WriteString("# Multi-stage build for optimized image\n")
	dockerfile.WriteString("FROM golang:1.19-alpine AS builder\n\n")

	// Set working directory
	dockerfile.WriteString("WORKDIR /app\n\n")

	// Copy dependency files first (for better caching)
	dockerfile.WriteString("# Copy dependency files\n")
	dockerfile.WriteString("COPY go.mod go.sum ./\n")
	dockerfile.WriteString("RUN go mod download\n\n")

	// Copy source code
	dockerfile.WriteString("# Copy source code\n")
	dockerfile.WriteString("COPY . .\n\n")

	// Build application
	dockerfile.WriteString("# Build application\n")
	dockerfile.WriteString("RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .\n\n")

	// Production stage
	dockerfile.WriteString("# Production stage\n")
	dockerfile.WriteString("FROM alpine:latest\n\n")

	// Install runtime dependencies only
	dockerfile.WriteString("# Install runtime dependencies\n")
	runtimeDeps := []string{}
	for _, dep := range deps {
		if dep.Type != "dev-only" && !strings.Contains(dep.Name, "build") {
			runtimeDeps = append(runtimeDeps, dep.Name)
		}
	}

	if len(runtimeDeps) > 0 {
		dockerfile.WriteString("RUN apk --no-cache add ")
		dockerfile.WriteString(strings.Join(runtimeDeps, " "))
		dockerfile.WriteString("\n\n")
	}

	// Copy application
	dockerfile.WriteString("# Copy application from builder\n")
	dockerfile.WriteString("COPY --from=builder /app/main /usr/local/bin/main\n\n")

	// Set entry point
	dockerfile.WriteString("# Set entry point\n")
	dockerfile.WriteString("ENTRYPOINT [\"/usr/local/bin/main\"]\n")

	return dockerfile.String()
}

// calculateOptimalLayers calculates the optimal number of Docker layers
func (cm *containerManagerImpl) calculateOptimalLayers(deps []Dependency) int {
	// Base layers: base image, dependencies, application
	layers := 3

	// Add layers for different types of dependencies
	types := make(map[string]bool)
	for _, dep := range deps {
		if dep.Type != "" {
			types[dep.Type] = true
		}
	}

	// Add one layer per dependency type
	layers += len(types)

	// Cap at reasonable maximum
	if layers > 10 {
		layers = 10
	}

	return layers
}

// BuildImage builds a Docker image
func (cm *containerManagerImpl) BuildImage(ctx context.Context, imageName string, dockerfile string) error {
	cm.logger.Info("Building Docker image", zap.String("image", imageName))

	args := []string{"build", "-t", imageName}
	if dockerfile != "" {
		args = append(args, "-f", dockerfile)
	}
	args = append(args, ".")

	cmd := exec.CommandContext(ctx, cm.dockerPath, args...)
	output, err := cmd.CombinedOutput()

	if err != nil {
		cm.logger.Error("Failed to build image", zap.Error(err), zap.String("output", string(output)))
		return fmt.Errorf("failed to build image: %w", err)
	}

	cm.logger.Info("Image built successfully", zap.String("image", imageName))
	return nil
}

// PushImage pushes a Docker image to a registry
func (cm *containerManagerImpl) PushImage(ctx context.Context, imageName string) error {
	cm.logger.Info("Pushing Docker image", zap.String("image", imageName))

	cmd := exec.CommandContext(ctx, cm.dockerPath, "push", imageName)
	output, err := cmd.CombinedOutput()

	if err != nil {
		cm.logger.Error("Failed to push image", zap.Error(err), zap.String("output", string(output)))
		return fmt.Errorf("failed to push image: %w", err)
	}

	cm.logger.Info("Image pushed successfully", zap.String("image", imageName))
	return nil
}

// PullImage pulls a Docker image from a registry
func (cm *containerManagerImpl) PullImage(ctx context.Context, imageName string) error {
	cm.logger.Info("Pulling Docker image", zap.String("image", imageName))

	cmd := exec.CommandContext(ctx, cm.dockerPath, "pull", imageName)
	output, err := cmd.CombinedOutput()

	if err != nil {
		cm.logger.Error("Failed to pull image", zap.Error(err), zap.String("output", string(output)))
		return fmt.Errorf("failed to pull image: %w", err)
	}

	cm.logger.Info("Image pulled successfully", zap.String("image", imageName))
	return nil
}

// CreateNetwork creates a Docker network
func (cm *containerManagerImpl) CreateNetwork(ctx context.Context, networkName string) error {
	cm.logger.Info("Creating Docker network", zap.String("network", networkName))

	cmd := exec.CommandContext(ctx, cm.dockerPath, "network", "create", networkName)
	output, err := cmd.CombinedOutput()

	if err != nil && !strings.Contains(string(output), "already exists") {
		cm.logger.Error("Failed to create network", zap.Error(err), zap.String("output", string(output)))
		return fmt.Errorf("failed to create network: %w", err)
	}

	cm.logger.Info("Network created successfully", zap.String("network", networkName))
	return nil
}

// CreateVolume creates a Docker volume
func (cm *containerManagerImpl) CreateVolume(ctx context.Context, volumeName string) error {
	cm.logger.Info("Creating Docker volume", zap.String("volume", volumeName))

	cmd := exec.CommandContext(ctx, cm.dockerPath, "volume", "create", volumeName)
	output, err := cmd.CombinedOutput()

	if err != nil && !strings.Contains(string(output), "already exists") {
		cm.logger.Error("Failed to create volume", zap.Error(err), zap.String("output", string(output)))
		return fmt.Errorf("failed to create volume: %w", err)
	}

	cm.logger.Info("Volume created successfully", zap.String("volume", volumeName))
	return nil
}

// HealthCheck performs health check on containers
func (cm *containerManagerImpl) HealthCheck(ctx context.Context) error {
	cm.logger.Info("Performing container health check")

	// Check Docker daemon
	if err := cm.verifyDocker(ctx); err != nil {
		return fmt.Errorf("Docker health check failed: %w", err)
	}

	// Check Docker Compose if configured
	if cm.composeFile != "" {
		if err := cm.verifyDockerCompose(ctx); err != nil {
			return fmt.Errorf("Docker Compose health check failed: %w", err)
		}

		// Check compose file validity
		if err := cm.validateComposeFile(ctx); err != nil {
			return fmt.Errorf("Compose file validation failed: %w", err)
		}
	}

	cm.logger.Info("Container health check passed")
	return nil
}

// Cleanup cleans up container resources
func (cm *containerManagerImpl) Cleanup() error {
	cm.logger.Info("Cleaning up ContainerManager resources")

	// In a real implementation, you might want to:
	// - Stop development containers
	// - Clean up unused images
	// - Remove temporary volumes
	// But this should be done carefully to avoid affecting other applications

	cm.logger.Info("ContainerManager cleanup completed")
	return nil
}

func main() {
	logger, _ := zap.NewDevelopment()
	defer logger.Sync()

	cm := NewContainerManager(logger, "unix:///var/run/docker.sock", "./docker-compose.yml")

	ctx := context.Background()
	if err := cm.Initialize(ctx); err != nil {
		log.Fatalf("Failed to initialize ContainerManager: %v", err)
	}

	logger.Info("ContainerManager initialized successfully")
}
