package gitworkflowmanager

import (
	"context"
	"fmt"
	"log"
	"sync"
	"time"

	"github.com/gerivdb/email-sender-1/git-workflow-manager/internal/branch"
	"github.com/gerivdb/email-sender-1/git-workflow-manager/internal/commit"
	"github.com/gerivdb/email-sender-1/git-workflow-manager/internal/pr"
	"github.com/gerivdb/email-sender-1/git-workflow-manager/internal/webhook"
	"github.com/gerivdb/email-sender-1/managers/interfaces"
)

// GitWorkflowManagerImpl implements the GitWorkflowManager interface
type GitWorkflowManagerImpl struct {
	// BaseManager implementation
	id       string
	name     string
	status   string
	config   map[string]interface{}
	metadata map[string]interface{}
	mu       sync.RWMutex

	// Dependencies
	errorManager   interfaces.ErrorManager
	configManager  interfaces.ConfigManager
	storageManager interfaces.StorageManager

	// Internal managers
	branchManager  *branch.Manager
	commitManager  *commit.Manager
	prManager      *pr.Manager
	webhookManager *webhook.Manager

	// Configuration
	repoPath      string
	workflowType  interfaces.WorkflowType
	githubToken   string
	webhookConfig map[string]interface{}
}

// NewGitWorkflowManager creates a new GitWorkflowManager instance
func NewGitWorkflowManager(
	errorManager interfaces.ErrorManager,
	configManager interfaces.ConfigManager,
	storageManager interfaces.StorageManager,
	config map[string]interface{},
) (*GitWorkflowManagerImpl, error) {

	// Validate required dependencies
	if errorManager == nil {
		return nil, fmt.Errorf("errorManager is required")
	}
	if configManager == nil {
		return nil, fmt.Errorf("configManager is required")
	}
	if storageManager == nil {
		return nil, fmt.Errorf("storageManager is required")
	}

	// Extract configuration
	repoPath, _ := config["repo_path"].(string)
	if repoPath == "" {
		repoPath = "."
	}

	workflowTypeStr, _ := config["workflow_type"].(string)
	workflowType := interfaces.WorkflowType(workflowTypeStr)
	if workflowType == "" {
		workflowType = interfaces.WorkflowTypeGitFlow
	}

	githubToken, _ := config["github_token"].(string)
	webhookConfig, _ := config["webhook"].(map[string]interface{})
	if webhookConfig == nil {
		webhookConfig = make(map[string]interface{})
	}

	// Create manager instance
	manager := &GitWorkflowManagerImpl{
		id:             fmt.Sprintf("git-workflow-manager-%d", time.Now().Unix()),
		name:           "GitWorkflowManager",
		status:         "initializing",
		config:         config,
		metadata:       make(map[string]interface{}),
		errorManager:   errorManager,
		configManager:  configManager,
		storageManager: storageManager,
		repoPath:       repoPath,
		workflowType:   workflowType,
		githubToken:    githubToken,
		webhookConfig:  webhookConfig,
	}

	// Initialize internal managers
	var err error

	manager.branchManager, err = branch.NewManager(repoPath, errorManager)
	if err != nil {
		return nil, fmt.Errorf("failed to create branch manager: %w", err)
	}

	manager.commitManager, err = commit.NewManager(repoPath, errorManager)
	if err != nil {
		return nil, fmt.Errorf("failed to create commit manager: %w", err)
	}

	manager.prManager, err = pr.NewManager(githubToken, errorManager)
	if err != nil {
		return nil, fmt.Errorf("failed to create PR manager: %w", err)
	}

	manager.webhookManager, err = webhook.NewManager(webhookConfig, errorManager)
	if err != nil {
		return nil, fmt.Errorf("failed to create webhook manager: %w", err)
	}

	manager.status = "ready"

	log.Printf("GitWorkflowManager initialized successfully with ID: %s", manager.id)
	return manager, nil
}

// BaseManager implementation
func (g *GitWorkflowManagerImpl) GetID() string {
	g.mu.RLock()
	defer g.mu.RUnlock()
	return g.id
}

func (g *GitWorkflowManagerImpl) GetName() string {
	g.mu.RLock()
	defer g.mu.RUnlock()
	return g.name
}

func (g *GitWorkflowManagerImpl) GetStatus() string {
	g.mu.RLock()
	defer g.mu.RUnlock()
	return g.status
}

func (g *GitWorkflowManagerImpl) GetConfig() map[string]interface{} {
	g.mu.RLock()
	defer g.mu.RUnlock()

	configCopy := make(map[string]interface{})
	for k, v := range g.config {
		configCopy[k] = v
	}
	return configCopy
}

func (g *GitWorkflowManagerImpl) UpdateConfig(config map[string]interface{}) error {
	g.mu.Lock()
	defer g.mu.Unlock()

	for k, v := range config {
		g.config[k] = v
	}

	log.Printf("GitWorkflowManager config updated")
	return nil
}

func (g *GitWorkflowManagerImpl) GetMetadata() map[string]interface{} {
	g.mu.RLock()
	defer g.mu.RUnlock()

	metadataCopy := make(map[string]interface{})
	for k, v := range g.metadata {
		metadataCopy[k] = v
	}
	return metadataCopy
}

func (g *GitWorkflowManagerImpl) SetMetadata(key string, value interface{}) error {
	g.mu.Lock()
	defer g.mu.Unlock()

	g.metadata[key] = value
	log.Printf("GitWorkflowManager metadata set: %s", key)
	return nil
}

func (g *GitWorkflowManagerImpl) Health() error {
	g.mu.RLock()
	status := g.status
	g.mu.RUnlock()

	if status != "ready" {
		return fmt.Errorf("manager is not ready, current status: %s", status)
	}

	// Check internal managers health
	if err := g.branchManager.Health(); err != nil {
		return fmt.Errorf("branch manager health check failed: %w", err)
	}

	if err := g.commitManager.Health(); err != nil {
		return fmt.Errorf("commit manager health check failed: %w", err)
	}

	return nil
}

// BaseManager interface implementation
func (g *GitWorkflowManagerImpl) HealthCheck(ctx context.Context) error {
	return g.Health()
}

func (g *GitWorkflowManagerImpl) Initialize(ctx context.Context) error {
	g.mu.Lock()
	defer g.mu.Unlock()

	if g.status == "ready" {
		return nil // Already initialized
	}

	g.status = "ready"
	log.Printf("GitWorkflowManager initialized")
	return nil
}

func (g *GitWorkflowManagerImpl) Shutdown(ctx context.Context) error {
	g.mu.Lock()
	defer g.mu.Unlock()

	g.status = "shutting_down"

	// Shutdown internal managers
	if g.branchManager != nil {
		if err := g.branchManager.Shutdown(ctx); err != nil {
			log.Printf("Error shutting down branch manager: %v", err)
		}
	}

	if g.commitManager != nil {
		if err := g.commitManager.Shutdown(ctx); err != nil {
			log.Printf("Error shutting down commit manager: %v", err)
		}
	}

	if g.prManager != nil {
		if err := g.prManager.Shutdown(ctx); err != nil {
			log.Printf("Error shutting down PR manager: %v", err)
		}
	}

	if g.webhookManager != nil {
		if err := g.webhookManager.Shutdown(ctx); err != nil {
			log.Printf("Error shutting down webhook manager: %v", err)
		}
	}

	g.status = "shutdown"
	log.Printf("GitWorkflowManager shutdown completed")
	return nil
}

func (g *GitWorkflowManagerImpl) Cleanup() error {
	g.mu.Lock()
	defer g.mu.Unlock()

	// Cleanup any temporary resources
	// Reset status to allow reinitialization
	g.status = "cleaned"

	log.Printf("GitWorkflowManager cleanup completed")
	return nil
}

// Branch Management implementation
func (g *GitWorkflowManagerImpl) CreateBranch(ctx context.Context, branchName string, sourceBranch string) error {
	return g.branchManager.CreateBranch(ctx, branchName, sourceBranch)
}

func (g *GitWorkflowManagerImpl) SwitchBranch(ctx context.Context, branchName string) error {
	return g.branchManager.SwitchBranch(ctx, branchName)
}

func (g *GitWorkflowManagerImpl) DeleteBranch(ctx context.Context, branchName string, force bool) error {
	return g.branchManager.DeleteBranch(ctx, branchName, force)
}

func (g *GitWorkflowManagerImpl) ListBranches(ctx context.Context) ([]string, error) {
	return g.branchManager.ListBranches(ctx)
}

func (g *GitWorkflowManagerImpl) GetCurrentBranch(ctx context.Context) (string, error) {
	return g.branchManager.GetCurrentBranch(ctx)
}

// Commit Management implementation
func (g *GitWorkflowManagerImpl) ValidateCommitMessage(message string) error {
	return g.commitManager.ValidateCommitMessage(message)
}

func (g *GitWorkflowManagerImpl) CreateTimestampedCommit(ctx context.Context, message string, files []string) (*interfaces.CommitInfo, error) {
	return g.commitManager.CreateTimestampedCommit(ctx, message, files)
}

func (g *GitWorkflowManagerImpl) GetCommitHistory(ctx context.Context, branch string, limit int) ([]*interfaces.CommitInfo, error) {
	return g.commitManager.GetCommitHistory(ctx, branch, limit)
}

func (g *GitWorkflowManagerImpl) GetLastCommit(ctx context.Context, branch string) (*interfaces.CommitInfo, error) {
	return g.commitManager.GetLastCommit(ctx, branch)
}

// Sub-branch Management implementation
func (g *GitWorkflowManagerImpl) CreateSubBranch(ctx context.Context, subBranchName string, parentBranch string, workflowType interfaces.WorkflowType) (*interfaces.SubBranchInfo, error) {
	return g.branchManager.CreateSubBranch(ctx, subBranchName, parentBranch, workflowType)
}

func (g *GitWorkflowManagerImpl) MergeSubBranch(ctx context.Context, subBranchName string, targetBranch string, deleteAfterMerge bool) error {
	return g.branchManager.MergeSubBranch(ctx, subBranchName, targetBranch, deleteAfterMerge)
}

func (g *GitWorkflowManagerImpl) ListSubBranches(ctx context.Context, parentBranch string) ([]*interfaces.SubBranchInfo, error) {
	return g.branchManager.ListSubBranches(ctx, parentBranch)
}

// Pull Request Management implementation
func (g *GitWorkflowManagerImpl) CreatePullRequest(ctx context.Context, title, description, sourceBranch, targetBranch string) (*interfaces.PullRequestInfo, error) {
	return g.prManager.CreatePullRequest(ctx, title, description, sourceBranch, targetBranch)
}

func (g *GitWorkflowManagerImpl) GetPullRequestStatus(ctx context.Context, prID int) (*interfaces.PullRequestInfo, error) {
	return g.prManager.GetPullRequestStatus(ctx, prID)
}

func (g *GitWorkflowManagerImpl) ListPullRequests(ctx context.Context, status string) ([]*interfaces.PullRequestInfo, error) {
	return g.prManager.ListPullRequests(ctx, status)
}

// Webhook Integration implementation
func (g *GitWorkflowManagerImpl) SendWebhook(ctx context.Context, event string, payload *interfaces.WebhookPayload) error {
	return g.webhookManager.SendWebhook(ctx, event, payload)
}

func (g *GitWorkflowManagerImpl) ConfigureWebhook(ctx context.Context, url string, events []string, secret string) error {
	return g.webhookManager.ConfigureWebhook(ctx, url, events, secret)
}

func (g *GitWorkflowManagerImpl) ListWebhooks(ctx context.Context) ([]map[string]interface{}, error) {
	return g.webhookManager.ListWebhooks(ctx)
}

// Workflow Operations implementation
func (g *GitWorkflowManagerImpl) ExecuteWorkflow(ctx context.Context, workflowType interfaces.WorkflowType, parameters map[string]interface{}) error {
	// Implementation will be added based on workflow type
	switch workflowType {
	case interfaces.WorkflowTypeGitFlow:
		return g.executeGitFlowWorkflow(ctx, parameters)
	case interfaces.WorkflowTypeGitHubFlow:
		return g.executeGitHubFlowWorkflow(ctx, parameters)
	case interfaces.WorkflowTypeFeatureBranch:
		return g.executeFeatureBranchWorkflow(ctx, parameters)
	default:
		return fmt.Errorf("unsupported workflow type: %s", workflowType)
	}
}

func (g *GitWorkflowManagerImpl) ValidateWorkflow(ctx context.Context, workflowType interfaces.WorkflowType) error {
	// Basic workflow validation
	switch workflowType {
	case interfaces.WorkflowTypeGitFlow, interfaces.WorkflowTypeGitHubFlow, interfaces.WorkflowTypeFeatureBranch:
		return nil
	default:
		return fmt.Errorf("invalid workflow type: %s", workflowType)
	}
}

func (g *GitWorkflowManagerImpl) GetWorkflowStatus(ctx context.Context) (map[string]interface{}, error) {
	status := make(map[string]interface{})

	currentBranch, err := g.GetCurrentBranch(ctx)
	if err != nil {
		return nil, err
	}

	status["current_branch"] = currentBranch
	status["workflow_type"] = string(g.workflowType)
	status["repo_path"] = g.repoPath
	status["status"] = g.status

	return status, nil
}

// Configuration Management implementation
func (g *GitWorkflowManagerImpl) SetWorkflowConfiguration(ctx context.Context, config map[string]interface{}) error {
	g.mu.Lock()
	defer g.mu.Unlock()

	for k, v := range config {
		g.config[k] = v
	}

	// Update workflow type if provided
	if workflowTypeStr, ok := config["workflow_type"].(string); ok {
		g.workflowType = interfaces.WorkflowType(workflowTypeStr)
	}

	return nil
}

func (g *GitWorkflowManagerImpl) GetWorkflowConfiguration(ctx context.Context) (map[string]interface{}, error) {
	return g.GetConfig(), nil
}

func (g *GitWorkflowManagerImpl) ResetWorkflowConfiguration(ctx context.Context) error {
	g.mu.Lock()
	defer g.mu.Unlock()

	// Reset to default configuration
	g.config = map[string]interface{}{
		"workflow_type": string(interfaces.WorkflowTypeGitFlow),
		"repo_path":     ".",
	}

	g.workflowType = interfaces.WorkflowTypeGitFlow

	return nil
}

// Workflow implementations (stubs for now)
func (g *GitWorkflowManagerImpl) executeGitFlowWorkflow(ctx context.Context, parameters map[string]interface{}) error {
	// TODO: Implement GitFlow workflow
	return fmt.Errorf("GitFlow workflow not yet implemented")
}

func (g *GitWorkflowManagerImpl) executeGitHubFlowWorkflow(ctx context.Context, parameters map[string]interface{}) error {
	// TODO: Implement GitHub Flow workflow
	return fmt.Errorf("GitHub Flow workflow not yet implemented")
}

func (g *GitWorkflowManagerImpl) executeFeatureBranchWorkflow(ctx context.Context, parameters map[string]interface{}) error {
	// TODO: Implement Feature Branch workflow
	return fmt.Errorf("feature Branch workflow not yet implemented")
}

// Factory implementation
type GitWorkflowManagerFactory struct{}

func NewGitWorkflowManagerFactory() *GitWorkflowManagerFactory {
	return &GitWorkflowManagerFactory{}
}

func (f *GitWorkflowManagerFactory) CreateGitWorkflowManager(ctx context.Context, config map[string]interface{}) (interfaces.GitWorkflowManager, error) {
	// Extract dependencies from config (these would be injected)
	errorManager, _ := config["error_manager"].(interfaces.ErrorManager)
	configManager, _ := config["config_manager"].(interfaces.ConfigManager)
	storageManager, _ := config["storage_manager"].(interfaces.StorageManager)

	if errorManager == nil || configManager == nil || storageManager == nil {
		return nil, fmt.Errorf("required managers not provided in config")
	}

	return NewGitWorkflowManager(errorManager, configManager, storageManager, config)
}

func (f *GitWorkflowManagerFactory) ValidateConfiguration(config map[string]interface{}) error {
	// Validate required configuration fields
	requiredFields := []string{"repo_path"}

	for _, field := range requiredFields {
		if _, exists := config[field]; !exists {
			return fmt.Errorf("required configuration field missing: %s", field)
		}
	}

	// Validate workflow type if provided
	if workflowTypeStr, ok := config["workflow_type"].(string); ok {
		workflowType := interfaces.WorkflowType(workflowTypeStr)
		switch workflowType {
		case interfaces.WorkflowTypeGitFlow, interfaces.WorkflowTypeGitHubFlow, interfaces.WorkflowTypeFeatureBranch, interfaces.WorkflowTypeCustom:
			// Valid
		default:
			return fmt.Errorf("invalid workflow type: %s", workflowType)
		}
	}

	return nil
}

func (f *GitWorkflowManagerFactory) GetDefaultConfiguration() map[string]interface{} {
	return map[string]interface{}{
		"repo_path":     ".",
		"workflow_type": string(interfaces.WorkflowTypeGitFlow),
		"github_token":  "",
		"webhook": map[string]interface{}{
			"enabled": false,
			"url":     "",
			"events":  []string{"push", "pull_request"},
		},
	}
}
