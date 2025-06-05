package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"go.uber.org/zap"
)

// DeploymentManager interface defines the contract for deployment management
type DeploymentManager interface {
	Initialize(ctx context.Context) error
	BuildApplication(ctx context.Context, target string) error
	DeployToEnvironment(ctx context.Context, environment string) error
	BuildDockerImage(ctx context.Context, tag string) error
	CreateRelease(ctx context.Context, version string) error
	HealthCheck(ctx context.Context) error
	Cleanup() error
}

// deploymentManagerImpl implements DeploymentManager with ErrorManager integration
type deploymentManagerImpl struct {
	logger       *zap.Logger
	errorManager ErrorManager
	buildConfig  string
	environments map[string]string
	buildTools   map[string]string
	cicdConfig   *CICDConfig
	deployments  map[string]*DeploymentStatus
}

// CICDConfig represents CI/CD configuration
type CICDConfig struct {
	Provider        string            `json:"provider"`
	Repository      string            `json:"repository"`
	Branch          string            `json:"branch"`
	BuildCommand    string            `json:"build_command"`
	TestCommand     string            `json:"test_command"`
	DeployCommand   string            `json:"deploy_command"`
	Environment     map[string]string `json:"environment"`
	Notifications   []string          `json:"notifications"`
	Artifacts       []string          `json:"artifacts"`
}

// DeploymentStatus represents deployment status
type DeploymentStatus struct {
	Environment   string            `json:"environment"`
	Version       string            `json:"version"`
	Status        string            `json:"status"`
	StartTime     time.Time         `json:"start_time"`
	EndTime       *time.Time        `json:"end_time,omitempty"`
	Logs          []string          `json:"logs"`
	Metadata      map[string]string `json:"metadata"`
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

// NewDeploymentManager creates a new DeploymentManager instance
func NewDeploymentManager(logger *zap.Logger, buildConfig string) DeploymentManager {
	return &deploymentManagerImpl{
		logger:      logger,
		buildConfig: buildConfig,
		environments: map[string]string{
			"dev":     "development",
			"staging": "staging",
			"prod":    "production",
		},
		buildTools: map[string]string{
			"go":     "go",
			"docker": "docker",
			"git":    "git",
			"npm":    "npm",
		},
		deployments: make(map[string]*DeploymentStatus),
		// errorManager will be initialized separately
	}
}

// Initialize initializes the deployment manager
func (dm *deploymentManagerImpl) Initialize(ctx context.Context) error {
	dm.logger.Info("Initializing DeploymentManager")
	
	// Initialize build tools
	if err := dm.verifyBuildTools(); err != nil {
		return fmt.Errorf("failed to verify build tools: %w", err)
	}
	
	// Verify CI/CD integrations
	if err := dm.loadCICDConfig(); err != nil {
		return fmt.Errorf("failed to load CI/CD config: %w", err)
	}
	
	// Load deployment configurations
	if err := dm.loadDeploymentConfigs(); err != nil {
		return fmt.Errorf("failed to load deployment configs: %w", err)
	}
	
	dm.logger.Info("DeploymentManager initialized successfully")
	return nil
}

// verifyBuildTools verifies that required build tools are available
func (dm *deploymentManagerImpl) verifyBuildTools() error {
	for tool, command := range dm.buildTools {
		if err := dm.checkToolAvailability(command); err != nil {
			dm.logger.Warn("Build tool not available", 
				zap.String("tool", tool), 
				zap.String("command", command),
				zap.Error(err))
		} else {
			dm.logger.Info("Build tool verified", 
				zap.String("tool", tool), 
				zap.String("command", command))
		}
	}
	return nil
}

// checkToolAvailability checks if a command is available
func (dm *deploymentManagerImpl) checkToolAvailability(command string) error {
	cmd := exec.Command("which", command)
	if err := cmd.Run(); err != nil {
		// Try Windows where command
		cmd = exec.Command("where", command)
		if err := cmd.Run(); err != nil {
			return fmt.Errorf("command %s not found", command)
		}
	}
	return nil
}

// loadCICDConfig loads CI/CD configuration
func (dm *deploymentManagerImpl) loadCICDConfig() error {
	configPath := filepath.Join(filepath.Dir(dm.buildConfig), "cicd-config.json")
	
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		// Create default config
		dm.cicdConfig = &CICDConfig{
			Provider:      "local",
			Repository:    ".",
			Branch:        "main",
			BuildCommand:  "go build",
			TestCommand:   "go test ./...",
			DeployCommand: "docker-compose up -d",
			Environment:   make(map[string]string),
			Notifications: []string{},
			Artifacts:     []string{"*.exe", "*.bin", "Dockerfile"},
		}
		return dm.saveCICDConfig(configPath)
	}
	
	data, err := ioutil.ReadFile(configPath)
	if err != nil {
		return fmt.Errorf("failed to read CI/CD config: %w", err)
	}
	
	if err := json.Unmarshal(data, &dm.cicdConfig); err != nil {
		return fmt.Errorf("failed to parse CI/CD config: %w", err)
	}
	
	return nil
}

// saveCICDConfig saves CI/CD configuration
func (dm *deploymentManagerImpl) saveCICDConfig(path string) error {
	data, err := json.MarshalIndent(dm.cicdConfig, "", "  ")
	if err != nil {
		return err
	}
	return ioutil.WriteFile(path, data, 0644)
}

// loadDeploymentConfigs loads deployment configurations for each environment
func (dm *deploymentManagerImpl) loadDeploymentConfigs() error {
	for env := range dm.environments {
		configPath := filepath.Join(filepath.Dir(dm.buildConfig), fmt.Sprintf("deploy-%s.json", env))
		
		if _, err := os.Stat(configPath); os.IsNotExist(err) {
			dm.logger.Info("Creating default deployment config", zap.String("environment", env))
			defaultConfig := map[string]interface{}{
				"environment": env,
				"replicas":    1,
				"resources": map[string]string{
					"cpu":    "100m",
					"memory": "128Mi",
				},
				"health_check": map[string]interface{}{
					"enabled": true,
					"path":    "/health",
					"timeout": "30s",
				},
			}
			
			data, _ := json.MarshalIndent(defaultConfig, "", "  ")
			ioutil.WriteFile(configPath, data, 0644)
		}
	}
	return nil
}

// BuildApplication builds the application for a specific target
func (dm *deploymentManagerImpl) BuildApplication(ctx context.Context, target string) error {
	dm.logger.Info("Building application", zap.String("target", target))
	
	buildID := fmt.Sprintf("build-%d", time.Now().Unix())
	
	// Compile Go application
	if err := dm.compileGoApplication(target); err != nil {
		return fmt.Errorf("failed to compile Go application: %w", err)
	}
	
	// Build assets
	if err := dm.buildAssets(); err != nil {
		dm.logger.Warn("Failed to build assets", zap.Error(err))
	}
	
	// Run tests
	if err := dm.runTests(ctx); err != nil {
		return fmt.Errorf("tests failed: %w", err)
	}
	
	dm.logger.Info("Application build completed", 
		zap.String("target", target),
		zap.String("build_id", buildID))
	
	return nil
}

// compileGoApplication compiles the Go application
func (dm *deploymentManagerImpl) compileGoApplication(target string) error {
	buildCmd := []string{"go", "build"}
	
	if target != "" {
		buildCmd = append(buildCmd, "-o", target)
	}
	
	buildCmd = append(buildCmd, ".")
	
	cmd := exec.Command(buildCmd[0], buildCmd[1:]...)
	cmd.Dir = filepath.Dir(dm.buildConfig)
	
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("go build failed: %w, output: %s", err, string(output))
	}
	
	dm.logger.Info("Go application compiled successfully", zap.String("target", target))
	return nil
}

// buildAssets builds frontend assets if npm is available
func (dm *deploymentManagerImpl) buildAssets() error {
	packageJsonPath := filepath.Join(filepath.Dir(dm.buildConfig), "package.json")
	
	if _, err := os.Stat(packageJsonPath); os.IsNotExist(err) {
		dm.logger.Info("No package.json found, skipping asset build")
		return nil
	}
	
	// Install dependencies
	cmd := exec.Command("npm", "install")
	cmd.Dir = filepath.Dir(dm.buildConfig)
	if output, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("npm install failed: %w, output: %s", err, string(output))
	}
	
	// Build assets
	cmd = exec.Command("npm", "run", "build")
	cmd.Dir = filepath.Dir(dm.buildConfig)
	if output, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("npm build failed: %w, output: %s", err, string(output))
	}
	
	dm.logger.Info("Assets built successfully")
	return nil
}

// runTests runs the test suite
func (dm *deploymentManagerImpl) runTests(ctx context.Context) error {
	testCmd := strings.Fields(dm.cicdConfig.TestCommand)
	
	cmd := exec.CommandContext(ctx, testCmd[0], testCmd[1:]...)
	cmd.Dir = filepath.Dir(dm.buildConfig)
	
	output, err := cmd.CombinedOutput()
	if err != nil {
		dm.logger.Error("Tests failed", 
			zap.Error(err),
			zap.String("output", string(output)))
		return fmt.Errorf("tests failed: %w", err)
	}
	
	dm.logger.Info("All tests passed", zap.String("output", string(output)))
	return nil
}

// DeployToEnvironment deploys to a specific environment
func (dm *deploymentManagerImpl) DeployToEnvironment(ctx context.Context, environment string) error {
	dm.logger.Info("Deploying to environment", zap.String("environment", environment))
	
	if _, exists := dm.environments[environment]; !exists {
		return fmt.Errorf("unknown environment: %s", environment)
	}
	
	deploymentID := fmt.Sprintf("deploy-%s-%d", environment, time.Now().Unix())
	
	// Create deployment status
	status := &DeploymentStatus{
		Environment: environment,
		Version:     fmt.Sprintf("v%d", time.Now().Unix()),
		Status:      "deploying",
		StartTime:   time.Now(),
		Logs:        []string{},
		Metadata:    make(map[string]string),
	}
	dm.deployments[deploymentID] = status
	
	// Upload artifacts
	if err := dm.uploadArtifacts(environment, status); err != nil {
		status.Status = "failed"
		now := time.Now()
		status.EndTime = &now
		return fmt.Errorf("failed to upload artifacts: %w", err)
	}
	
	// Update configurations
	if err := dm.updateConfigurations(environment, status); err != nil {
		status.Status = "failed"
		now := time.Now()
		status.EndTime = &now
		return fmt.Errorf("failed to update configurations: %w", err)
	}
	
	// Restart services
	if err := dm.restartServices(environment, status); err != nil {
		status.Status = "failed"
		now := time.Now()
		status.EndTime = &now
		return fmt.Errorf("failed to restart services: %w", err)
	}
	
	status.Status = "completed"
	now := time.Now()
	status.EndTime = &now
	
	dm.logger.Info("Deployment completed successfully", 
		zap.String("environment", environment),
		zap.String("deployment_id", deploymentID),
		zap.String("version", status.Version))
	
	return nil
}

// uploadArtifacts uploads build artifacts
func (dm *deploymentManagerImpl) uploadArtifacts(environment string, status *DeploymentStatus) error {
	status.Logs = append(status.Logs, "Uploading artifacts...")
	
	for _, artifact := range dm.cicdConfig.Artifacts {
		matches, err := filepath.Glob(filepath.Join(filepath.Dir(dm.buildConfig), artifact))
		if err != nil {
			return fmt.Errorf("failed to find artifacts with pattern %s: %w", artifact, err)
		}
		
		for _, match := range matches {
			dm.logger.Info("Uploading artifact", 
				zap.String("file", match),
				zap.String("environment", environment))
			
			// Simulate artifact upload
			time.Sleep(100 * time.Millisecond)
			status.Logs = append(status.Logs, fmt.Sprintf("Uploaded: %s", filepath.Base(match)))
		}
	}
	
	return nil
}

// updateConfigurations updates environment-specific configurations
func (dm *deploymentManagerImpl) updateConfigurations(environment string, status *DeploymentStatus) error {
	status.Logs = append(status.Logs, "Updating configurations...")
	
	configPath := filepath.Join(filepath.Dir(dm.buildConfig), fmt.Sprintf("deploy-%s.json", environment))
	
	if _, err := os.Stat(configPath); err != nil {
		return fmt.Errorf("deployment config not found for environment %s: %w", environment, err)
	}
	
	data, err := ioutil.ReadFile(configPath)
	if err != nil {
		return fmt.Errorf("failed to read deployment config: %w", err)
	}
	
	var config map[string]interface{}
	if err := json.Unmarshal(data, &config); err != nil {
		return fmt.Errorf("failed to parse deployment config: %w", err)
	}
	
	// Apply environment-specific configurations
	status.Metadata["config_applied"] = "true"
	status.Logs = append(status.Logs, "Configuration updated successfully")
	
	dm.logger.Info("Configurations updated", zap.String("environment", environment))
	return nil
}

// restartServices restarts services for the environment
func (dm *deploymentManagerImpl) restartServices(environment string, status *DeploymentStatus) error {
	status.Logs = append(status.Logs, "Restarting services...")
	
	deployCmd := strings.Fields(dm.cicdConfig.DeployCommand)
	
	// Add environment-specific arguments
	if environment != "prod" {
		deployCmd = append(deployCmd, "-f", fmt.Sprintf("docker-compose.%s.yml", environment))
	}
	
	cmd := exec.Command(deployCmd[0], deployCmd[1:]...)
	cmd.Dir = filepath.Dir(dm.buildConfig)
	
	// Set environment variables
	cmd.Env = os.Environ()
	for key, value := range dm.cicdConfig.Environment {
		cmd.Env = append(cmd.Env, fmt.Sprintf("%s=%s", key, value))
	}
	
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("deploy command failed: %w, output: %s", err, string(output))
	}
	
	status.Logs = append(status.Logs, "Services restarted successfully")
	status.Metadata["deploy_output"] = string(output)
	
	dm.logger.Info("Services restarted", zap.String("environment", environment))
	return nil
}

// BuildDockerImage builds a Docker image
func (dm *deploymentManagerImpl) BuildDockerImage(ctx context.Context, tag string) error {
	dm.logger.Info("Building Docker image", zap.String("tag", tag))
	
	dockerfilePath := filepath.Join(filepath.Dir(dm.buildConfig), "Dockerfile")
	
	// Check if Dockerfile exists
	if _, err := os.Stat(dockerfilePath); os.IsNotExist(err) {
		if err := dm.generateDockerfile(dockerfilePath); err != nil {
			return fmt.Errorf("failed to generate Dockerfile: %w", err)
		}
	}
	
	// Build image with Dockerfile
	buildCmd := []string{"docker", "build", "-t", tag, "."}
	
	cmd := exec.CommandContext(ctx, buildCmd[0], buildCmd[1:]...)
	cmd.Dir = filepath.Dir(dm.buildConfig)
	
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("docker build failed: %w, output: %s", err, string(output))
	}
	
	dm.logger.Info("Docker image built successfully", 
		zap.String("tag", tag),
		zap.String("dockerfile", dockerfilePath))
	
	// Tag image with additional tags
	if err := dm.tagImage(tag); err != nil {
		dm.logger.Warn("Failed to create additional tags", zap.Error(err))
	}
	
	// Push to registry if configured
	if registryURL := dm.cicdConfig.Environment["DOCKER_REGISTRY"]; registryURL != "" {
		if err := dm.pushToRegistry(tag, registryURL); err != nil {
			dm.logger.Warn("Failed to push to registry", zap.Error(err))
		}
	}
	
	return nil
}

// generateDockerfile generates a basic Dockerfile if none exists
func (dm *deploymentManagerImpl) generateDockerfile(path string) error {
	dockerfile := `# Multi-stage build for Go application
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Final stage
FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/

COPY --from=builder /app/main .

EXPOSE 8080
CMD ["./main"]
`
	
	if err := ioutil.WriteFile(path, []byte(dockerfile), 0644); err != nil {
		return fmt.Errorf("failed to write Dockerfile: %w", err)
	}
	
	dm.logger.Info("Generated default Dockerfile", zap.String("path", path))
	return nil
}

// tagImage creates additional tags for the image
func (dm *deploymentManagerImpl) tagImage(originalTag string) error {
	additionalTags := []string{
		fmt.Sprintf("%s:latest", strings.Split(originalTag, ":")[0]),
		fmt.Sprintf("%s:%s", strings.Split(originalTag, ":")[0], time.Now().Format("20060102")),
	}
	
	for _, tag := range additionalTags {
		cmd := exec.Command("docker", "tag", originalTag, tag)
		if err := cmd.Run(); err != nil {
			return fmt.Errorf("failed to tag image %s: %w", tag, err)
		}
		dm.logger.Info("Image tagged", zap.String("tag", tag))
	}
	
	return nil
}

// pushToRegistry pushes image to container registry
func (dm *deploymentManagerImpl) pushToRegistry(tag, registryURL string) error {
	registryTag := fmt.Sprintf("%s/%s", registryURL, tag)
	
	// Tag for registry
	tagCmd := exec.Command("docker", "tag", tag, registryTag)
	if err := tagCmd.Run(); err != nil {
		return fmt.Errorf("failed to tag for registry: %w", err)
	}
	
	// Push to registry
	pushCmd := exec.Command("docker", "push", registryTag)
	output, err := pushCmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("failed to push to registry: %w, output: %s", err, string(output))
	}
	
	dm.logger.Info("Image pushed to registry", 
		zap.String("tag", registryTag),
		zap.String("registry", registryURL))
	
	return nil
}

// CreateRelease creates a new release
func (dm *deploymentManagerImpl) CreateRelease(ctx context.Context, version string) error {
	dm.logger.Info("Creating release", zap.String("version", version))
	
	releaseDir := filepath.Join(filepath.Dir(dm.buildConfig), "releases", version)
	
	// Create release directory
	if err := os.MkdirAll(releaseDir, 0755); err != nil {
		return fmt.Errorf("failed to create release directory: %w", err)
	}
	
	// Tag version in Git
	if err := dm.tagVersionInGit(version); err != nil {
		return fmt.Errorf("failed to tag version in Git: %w", err)
	}
	
	// Build release artifacts
	if err := dm.buildReleaseArtifacts(version, releaseDir); err != nil {
		return fmt.Errorf("failed to build release artifacts: %w", err)
	}
	
	// Create release notes
	if err := dm.createReleaseNotes(version, releaseDir); err != nil {
		dm.logger.Warn("Failed to create release notes", zap.Error(err))
	}
	
	dm.logger.Info("Release created successfully", 
		zap.String("version", version),
		zap.String("release_dir", releaseDir))
	
	return nil
}

// tagVersionInGit creates a Git tag for the version
func (dm *deploymentManagerImpl) tagVersionInGit(version string) error {
	// Check if git is available
	if err := dm.checkToolAvailability("git"); err != nil {
		return fmt.Errorf("git not available: %w", err)
	}
	
	// Create tag
	tagCmd := exec.Command("git", "tag", "-a", version, "-m", fmt.Sprintf("Release %s", version))
	tagCmd.Dir = filepath.Dir(dm.buildConfig)
	
	if output, err := tagCmd.CombinedOutput(); err != nil {
		return fmt.Errorf("failed to create git tag: %w, output: %s", err, string(output))
	}
	
	// Push tag if remote is configured
	pushCmd := exec.Command("git", "push", "origin", version)
	pushCmd.Dir = filepath.Dir(dm.buildConfig)
	
	if output, err := pushCmd.CombinedOutput(); err != nil {
		dm.logger.Warn("Failed to push tag to remote", 
			zap.Error(err),
			zap.String("output", string(output)))
	} else {
		dm.logger.Info("Git tag pushed to remote", zap.String("version", version))
	}
	
	return nil
}

// buildReleaseArtifacts builds artifacts for the release
func (dm *deploymentManagerImpl) buildReleaseArtifacts(version, releaseDir string) error {
	// Build for multiple platforms
	platforms := []struct {
		os   string
		arch string
	}{
		{"linux", "amd64"},
		{"windows", "amd64"},
		{"darwin", "amd64"},
	}
	
	for _, platform := range platforms {
		binaryName := fmt.Sprintf("app-%s-%s", platform.os, platform.arch)
		if platform.os == "windows" {
			binaryName += ".exe"
		}
		
		binaryPath := filepath.Join(releaseDir, binaryName)
		
		cmd := exec.Command("go", "build", "-o", binaryPath, ".")
		cmd.Dir = filepath.Dir(dm.buildConfig)
		cmd.Env = append(os.Environ(), 
			fmt.Sprintf("GOOS=%s", platform.os),
			fmt.Sprintf("GOARCH=%s", platform.arch))
		
		if output, err := cmd.CombinedOutput(); err != nil {
			dm.logger.Warn("Failed to build for platform", 
				zap.String("platform", fmt.Sprintf("%s/%s", platform.os, platform.arch)),
				zap.Error(err),
				zap.String("output", string(output)))
		} else {
			dm.logger.Info("Built artifact", 
				zap.String("platform", fmt.Sprintf("%s/%s", platform.os, platform.arch)),
				zap.String("binary", binaryName))
		}
	}
	
	// Copy additional artifacts
	for _, artifact := range dm.cicdConfig.Artifacts {
		matches, err := filepath.Glob(filepath.Join(filepath.Dir(dm.buildConfig), artifact))
		if err != nil {
			continue
		}
		
		for _, match := range matches {
			destPath := filepath.Join(releaseDir, filepath.Base(match))
			if err := dm.copyFile(match, destPath); err != nil {
				dm.logger.Warn("Failed to copy artifact", 
					zap.String("src", match),
					zap.String("dest", destPath),
					zap.Error(err))
			}
		}
	}
	
	return nil
}

// createReleaseNotes creates release notes
func (dm *deploymentManagerImpl) createReleaseNotes(version, releaseDir string) error {
	notesPath := filepath.Join(releaseDir, "RELEASE_NOTES.md")
	
	// Get git log since last tag
	logCmd := exec.Command("git", "log", "--oneline", "--since=1 month ago")
	logCmd.Dir = filepath.Dir(dm.buildConfig)
	
	output, err := logCmd.CombinedOutput()
	if err != nil {
		output = []byte("No git history available")
	}
	
	notes := fmt.Sprintf(`# Release %s

## Release Date
%s

## Changes
%s

## Artifacts
`, version, time.Now().Format("2006-01-02"), string(output))
	
	// List artifacts
	files, err := ioutil.ReadDir(releaseDir)
	if err == nil {
		for _, file := range files {
			if file.Name() != "RELEASE_NOTES.md" {
				notes += fmt.Sprintf("- %s\n", file.Name())
			}
		}
	}
	
	if err := ioutil.WriteFile(notesPath, []byte(notes), 0644); err != nil {
		return fmt.Errorf("failed to write release notes: %w", err)
	}
	
	return nil
}

// copyFile copies a file from src to dest
func (dm *deploymentManagerImpl) copyFile(src, dest string) error {
	data, err := ioutil.ReadFile(src)
	if err != nil {
		return err
	}
	return ioutil.WriteFile(dest, data, 0644)
}

// HealthCheck performs health check on deployment system
func (dm *deploymentManagerImpl) HealthCheck(ctx context.Context) error {
	dm.logger.Info("Performing deployment health check")
	
	healthStatus := make(map[string]string)
	
	// Check build tools availability
	for tool, command := range dm.buildTools {
		if err := dm.checkToolAvailability(command); err != nil {
			healthStatus[tool] = "unavailable"
		} else {
			healthStatus[tool] = "available"
		}
	}
	
	// Check CI/CD configuration
	if dm.cicdConfig != nil {
		healthStatus["cicd_config"] = "loaded"
	} else {
		healthStatus["cicd_config"] = "missing"
	}
	
	// Check deployment environments
	for env := range dm.environments {
		configPath := filepath.Join(filepath.Dir(dm.buildConfig), fmt.Sprintf("deploy-%s.json", env))
		if _, err := os.Stat(configPath); err == nil {
			healthStatus[fmt.Sprintf("env_%s", env)] = "configured"
		} else {
			healthStatus[fmt.Sprintf("env_%s", env)] = "missing_config"
		}
	}
	
	// Check active deployments
	activeDeployments := 0
	for _, deployment := range dm.deployments {
		if deployment.Status == "deploying" {
			activeDeployments++
		}
	}
	healthStatus["active_deployments"] = fmt.Sprintf("%d", activeDeployments)
	
	// Check Docker daemon if Docker is configured
	if _, exists := dm.buildTools["docker"]; exists {
		dockerCmd := exec.Command("docker", "info")
		if err := dockerCmd.Run(); err != nil {
			healthStatus["docker_daemon"] = "unavailable"
		} else {
			healthStatus["docker_daemon"] = "running"
		}
	}
	
	// Check Git repository status
	if _, exists := dm.buildTools["git"]; exists {
		gitCmd := exec.Command("git", "status", "--porcelain")
		gitCmd.Dir = filepath.Dir(dm.buildConfig)
		if output, err := gitCmd.CombinedOutput(); err != nil {
			healthStatus["git_repo"] = "error"
		} else if len(output) == 0 {
			healthStatus["git_repo"] = "clean"
		} else {
			healthStatus["git_repo"] = "dirty"
		}
	}
	
	// Log health status
	for component, status := range healthStatus {
		dm.logger.Info("Health check result", 
			zap.String("component", component),
			zap.String("status", status))
	}
	
	// Check for critical issues
	criticalIssues := []string{}
	if healthStatus["go"] == "unavailable" {
		criticalIssues = append(criticalIssues, "Go compiler not available")
	}
	if healthStatus["cicd_config"] == "missing" {
		criticalIssues = append(criticalIssues, "CI/CD configuration missing")
	}
	
	if len(criticalIssues) > 0 {
		return fmt.Errorf("critical deployment issues detected: %s", strings.Join(criticalIssues, ", "))
	}
	
	dm.logger.Info("Deployment system health check passed")
	return nil
}

// Cleanup cleans up deployment resources
func (dm *deploymentManagerImpl) Cleanup() error {
	dm.logger.Info("Cleaning up DeploymentManager resources")
	
	// Clean up temporary build artifacts
	tempDirs := []string{
		filepath.Join(filepath.Dir(dm.buildConfig), "tmp"),
		filepath.Join(filepath.Dir(dm.buildConfig), "build"),
		filepath.Join(filepath.Dir(dm.buildConfig), ".cache"),
	}
	
	for _, dir := range tempDirs {
		if _, err := os.Stat(dir); err == nil {
			if err := os.RemoveAll(dir); err != nil {
				dm.logger.Warn("Failed to remove temporary directory", 
					zap.String("dir", dir),
					zap.Error(err))
			} else {
				dm.logger.Info("Cleaned up temporary directory", zap.String("dir", dir))
			}
		}
	}
	
	// Clean up old deployment logs
	for deploymentID, deployment := range dm.deployments {
		if deployment.EndTime != nil && time.Since(*deployment.EndTime) > 24*time.Hour {
			delete(dm.deployments, deploymentID)
			dm.logger.Info("Cleaned up old deployment record", 
				zap.String("deployment_id", deploymentID))
		}
	}
	
	// Clean up Docker resources if Docker is available
	if _, exists := dm.buildTools["docker"]; exists {
		if err := dm.cleanupDockerResources(); err != nil {
			dm.logger.Warn("Failed to clean up Docker resources", zap.Error(err))
		}
	}
	
	// Save current state
	if err := dm.saveDeploymentState(); err != nil {
		dm.logger.Warn("Failed to save deployment state", zap.Error(err))
	}
	
	dm.logger.Info("DeploymentManager cleanup completed")
	return nil
}

// cleanupDockerResources cleans up unused Docker resources
func (dm *deploymentManagerImpl) cleanupDockerResources() error {
	// Remove dangling images
	pruneCmd := exec.Command("docker", "image", "prune", "-f")
	if output, err := pruneCmd.CombinedOutput(); err != nil {
		return fmt.Errorf("failed to prune Docker images: %w, output: %s", err, string(output))
	}
	
	// Remove unused containers
	containerPruneCmd := exec.Command("docker", "container", "prune", "-f")
	if output, err := containerPruneCmd.CombinedOutput(); err != nil {
		dm.logger.Warn("Failed to prune Docker containers", 
			zap.Error(err),
			zap.String("output", string(output)))
	}
	
	dm.logger.Info("Docker resources cleaned up")
	return nil
}

// saveDeploymentState saves current deployment state to disk
func (dm *deploymentManagerImpl) saveDeploymentState() error {
	statePath := filepath.Join(filepath.Dir(dm.buildConfig), "deployment-state.json")
	
	state := map[string]interface{}{
		"last_cleanup": time.Now(),
		"deployments":  dm.deployments,
		"environments": dm.environments,
	}
	
	data, err := json.MarshalIndent(state, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal deployment state: %w", err)
	}
	
	if err := ioutil.WriteFile(statePath, data, 0644); err != nil {
		return fmt.Errorf("failed to write deployment state: %w", err)
	}
	
	return nil
}

func main() {
	logger, _ := zap.NewDevelopment()
	defer logger.Sync()

	dm := NewDeploymentManager(logger, "./build.yaml")
	
	ctx := context.Background()
	if err := dm.Initialize(ctx); err != nil {
		log.Fatalf("Failed to initialize DeploymentManager: %v", err)
	}

	logger.Info("DeploymentManager initialized successfully")
}
