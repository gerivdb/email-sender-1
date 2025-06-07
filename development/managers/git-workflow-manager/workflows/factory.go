package workflows

import (
	"fmt"

	"github.com/email-sender/managers/interfaces"
)

// WorkflowFactory creates workflow instances based on workflow type
type WorkflowFactory struct {
	manager interfaces.GitWorkflowManager
}

// NewWorkflowFactory creates a new workflow factory
func NewWorkflowFactory(manager interfaces.GitWorkflowManager) *WorkflowFactory {
	return &WorkflowFactory{
		manager: manager,
	}
}

// CreateWorkflow creates a workflow instance based on the specified type
func (f *WorkflowFactory) CreateWorkflow(workflowType interfaces.WorkflowType, config map[string]interface{}) (Workflow, error) {
	switch workflowType {
	case interfaces.WorkflowTypeGitFlow:
		return NewGitFlowWorkflow(f.manager), nil
		
	case interfaces.WorkflowTypeGitHubFlow:
		return NewGitHubFlowWorkflow(f.manager), nil
		
	case interfaces.WorkflowTypeFeatureBranch:
		mainBranch := "main"
		if mb, ok := config["main_branch"].(string); ok && mb != "" {
			mainBranch = mb
		}
		workflow := NewFeatureBranchWorkflow(f.manager, mainBranch)
		
		// Configure cleanup policy if specified
		if enabled, ok := config["auto_cleanup"].(bool); ok {
			days := 30
			if d, ok := config["cleanup_days"].(int); ok && d > 0 {
				days = d
			}
			workflow.SetCleanupPolicy(enabled, days)
		}
		
		return workflow, nil
		
	case interfaces.WorkflowTypeCustom:
		return NewCustomWorkflow(f.manager, config), nil
		
	default:
		return nil, fmt.Errorf("unsupported workflow type: %v", workflowType)
	}
}

// GetAvailableWorkflows returns a list of available workflow types
func (f *WorkflowFactory) GetAvailableWorkflows() []interfaces.WorkflowType {
	return []interfaces.WorkflowType{
		interfaces.WorkflowTypeGitFlow,
		interfaces.WorkflowTypeGitHubFlow,
		interfaces.WorkflowTypeFeatureBranch,
		interfaces.WorkflowTypeCustom,
	}
}

// GetWorkflowDescription returns a description of the specified workflow type
func (f *WorkflowFactory) GetWorkflowDescription(workflowType interfaces.WorkflowType) string {
	switch workflowType {
	case interfaces.WorkflowTypeGitFlow:
		return "GitFlow workflow with feature, release, and hotfix branches from develop and main"
		
	case interfaces.WorkflowTypeGitHubFlow:
		return "GitHub Flow workflow with simple branching from main and continuous deployment"
		
	case interfaces.WorkflowTypeFeatureBranch:
		return "Feature branch workflow with flexible branching and automated cleanup"
		
	case interfaces.WorkflowTypeCustom:
		return "Custom workflow with user-defined rules and conventions"
		
	default:
		return "Unknown workflow type"
	}
}

// Workflow interface defines common operations for all workflow types
type Workflow interface {
	// GetWorkflowType returns the workflow type
	GetWorkflowType() interfaces.WorkflowType
	
	// GetBranchingStrategy returns a description of the branching strategy
	GetBranchingStrategy() string
	
	// ValidateBranchName validates if a branch name follows workflow conventions
	ValidateBranchName(branchName string) error
}
