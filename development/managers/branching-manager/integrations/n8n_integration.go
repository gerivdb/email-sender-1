package integrations

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/gerivdb/email-sender-1/development/managers/branching-manager/interfaces"
)

// N8NIntegration handles integration with n8n workflow automation
type N8NIntegration struct {
	client     *http.Client
	baseURL    string
	apiKey     string
	webhookURL string
	workflows  map[string]string
	secret     string
}

// N8NConfig holds n8n integration configuration
type N8NConfig struct {
	BaseURL    string
	APIKey     string
	WebhookURL string
	Workflows  map[string]string
	Secret     string
	Timeout    time.Duration
}

// N8NWorkflowExecution represents a workflow execution
type N8NWorkflowExecution struct {
	ID         string                 `json:"id"`
	WorkflowID string                 `json:"workflowId"`
	Status     string                 `json:"status"`
	StartedAt  time.Time              `json:"startedAt"`
	FinishedAt *time.Time             `json:"finishedAt,omitempty"`
	Data       map[string]interface{} `json:"data"`
	Error      string                 `json:"error,omitempty"`
}

// N8NWebhookPayload represents webhook payload structure
type N8NWebhookPayload struct {
	EventType  string                 `json:"eventType"`
	EntityType string                 `json:"entityType"`
	EntityID   string                 `json:"entityId"`
	Timestamp  time.Time              `json:"timestamp"`
	Data       map[string]interface{} `json:"data"`
	Metadata   map[string]interface{} `json:"metadata"`
	Signature  string                 `json:"signature,omitempty"`
}

// NewN8NIntegration creates a new n8n integration
func NewN8NIntegration(config *N8NConfig) *N8NIntegration {
	client := &http.Client{
		Timeout: config.Timeout,
	}

	return &N8NIntegration{
		client:     client,
		baseURL:    config.BaseURL,
		apiKey:     config.APIKey,
		webhookURL: config.WebhookURL,
		workflows:  config.Workflows,
		secret:     config.Secret,
	}
}

// TriggerSessionCreatedWorkflow triggers workflow when a session is created
func (n *N8NIntegration) TriggerSessionCreatedWorkflow(ctx context.Context, session *interfaces.Session) error {
	workflowName := "session_created"
	workflowID, exists := n.workflows[workflowName]
	if !exists {
		return fmt.Errorf("workflow %s not configured", workflowName)
	}

	payload := map[string]interface{}{
		"session": map[string]interface{}{
			"id":         session.ID,
			"scope":      session.Scope,
			"status":     session.Status,
			"duration":   session.Duration.String(),
			"created_at": session.CreatedAt,
			"metadata":   session.Metadata,
		},
		"trigger_source": "branching_manager",
		"timestamp":      time.Now(),
	}

	return n.executeWorkflow(ctx, workflowID, payload)
}

// TriggerBranchCreatedWorkflow triggers workflow when a branch is created
func (n *N8NIntegration) TriggerBranchCreatedWorkflow(ctx context.Context, branch *interfaces.Branch) error {
	workflowName := "branch_created"
	workflowID, exists := n.workflows[workflowName]
	if !exists {
		// Use webhook if no specific workflow configured
		return n.sendWebhook(ctx, "branch_created", "branch", branch.ID, map[string]interface{}{
			"branch": map[string]interface{}{
				"id":          branch.ID,
				"name":        branch.Name,
				"base_branch": branch.BaseBranch,
				"status":      branch.Status,
				"session_id":  branch.SessionID,
				"created_at":  branch.CreatedAt,
				"git_hash":    branch.GitHash,
				"metadata":    branch.Metadata,
			},
		})
	}

	payload := map[string]interface{}{
		"branch": map[string]interface{}{
			"id":          branch.ID,
			"name":        branch.Name,
			"base_branch": branch.BaseBranch,
			"status":      branch.Status,
			"session_id":  branch.SessionID,
			"created_at":  branch.CreatedAt,
			"git_hash":    branch.GitHash,
			"metadata":    branch.Metadata,
		},
		"trigger_source": "branching_manager",
		"timestamp":      time.Now(),
	}

	return n.executeWorkflow(ctx, workflowID, payload)
}

// TriggerBranchMergedWorkflow triggers workflow when a branch is merged
func (n *N8NIntegration) TriggerBranchMergedWorkflow(ctx context.Context, mergeResult *interfaces.GitMergeResult, sourceBranch, targetBranch string) error {
	workflowName := "branch_merged"
	workflowID, exists := n.workflows[workflowName]
	if !exists {
		return n.sendWebhook(ctx, "branch_merged", "merge", mergeResult.MergeCommit, map[string]interface{}{
			"merge_result": map[string]interface{}{
				"success":        mergeResult.Success,
				"merge_commit":   mergeResult.MergeCommit,
				"merged_at":      mergeResult.MergedAt,
				"source_branch":  sourceBranch,
				"target_branch":  targetBranch,
				"conflict_files": mergeResult.ConflictFiles,
				"error_message":  mergeResult.ErrorMessage,
			},
		})
	}

	payload := map[string]interface{}{
		"merge_result": map[string]interface{}{
			"success":        mergeResult.Success,
			"merge_commit":   mergeResult.MergeCommit,
			"merged_at":      mergeResult.MergedAt,
			"source_branch":  sourceBranch,
			"target_branch":  targetBranch,
			"conflict_files": mergeResult.ConflictFiles,
			"error_message":  mergeResult.ErrorMessage,
		},
		"trigger_source": "branching_manager",
		"timestamp":      time.Now(),
	}

	return n.executeWorkflow(ctx, workflowID, payload)
}

// TriggerSnapshotCreatedWorkflow triggers workflow when a temporal snapshot is created
func (n *N8NIntegration) TriggerSnapshotCreatedWorkflow(ctx context.Context, snapshot *interfaces.TemporalSnapshot) error {
	workflowName := "snapshot_created"
	workflowID, exists := n.workflows[workflowName]
	if !exists {
		return n.sendWebhook(ctx, "snapshot_created", "snapshot", snapshot.ID, map[string]interface{}{
			"snapshot": map[string]interface{}{
				"id":              snapshot.ID,
				"branch_id":       snapshot.BranchID,
				"git_hash":        snapshot.GitHash,
				"timestamp":       snapshot.Timestamp,
				"changes_summary": snapshot.ChangesSummary,
				"tag_name":        snapshot.TagName,
				"metadata":        snapshot.Metadata,
			},
		})
	}

	payload := map[string]interface{}{
		"snapshot": map[string]interface{}{
			"id":              snapshot.ID,
			"branch_id":       snapshot.BranchID,
			"git_hash":        snapshot.GitHash,
			"timestamp":       snapshot.Timestamp,
			"changes_summary": snapshot.ChangesSummary,
			"tag_name":        snapshot.TagName,
			"metadata":        snapshot.Metadata,
		},
		"trigger_source": "branching_manager",
		"timestamp":      time.Now(),
	}

	return n.executeWorkflow(ctx, workflowID, payload)
}

// TriggerQuantumBranchCreatedWorkflow triggers workflow for quantum branch creation
func (n *N8NIntegration) TriggerQuantumBranchCreatedWorkflow(ctx context.Context, quantumBranch *interfaces.QuantumBranch) error {
	workflowName := "quantum_branch_created"
	workflowID, exists := n.workflows[workflowName]
	if !exists {
		return n.sendWebhook(ctx, "quantum_branch_created", "quantum_branch", quantumBranch.ID, map[string]interface{}{
			"quantum_branch": n.serializeQuantumBranch(quantumBranch),
		})
	}

	payload := map[string]interface{}{
		"quantum_branch": n.serializeQuantumBranch(quantumBranch),
		"trigger_source": "branching_manager",
		"timestamp":      time.Now(),
	}

	return n.executeWorkflow(ctx, workflowID, payload)
}

// TriggerApproachCompletedWorkflow triggers workflow when a quantum approach is completed
func (n *N8NIntegration) TriggerApproachCompletedWorkflow(ctx context.Context, result *interfaces.ApproachResult) error {
	workflowName := "approach_completed"
	workflowID, exists := n.workflows[workflowName]
	if !exists {
		return n.sendWebhook(ctx, "approach_completed", "approach_result", result.ApproachID, map[string]interface{}{
			"approach_result": map[string]interface{}{
				"approach_id":      result.ApproachID,
				"success":          result.Success,
				"score":            result.Score,
				"confidence":       result.Confidence,
				"execution_time":   result.ExecutionTime,
				"branches_created": result.BranchesCreated,
				"commits_made":     result.CommitsMade,
				"tests_passed":     result.TestsPassed,
				"error_message":    result.ErrorMessage,
				"metadata":         result.Metadata,
			},
		})
	}

	payload := map[string]interface{}{
		"approach_result": map[string]interface{}{
			"approach_id":      result.ApproachID,
			"success":          result.Success,
			"score":            result.Score,
			"confidence":       result.Confidence,
			"execution_time":   result.ExecutionTime,
			"branches_created": result.BranchesCreated,
			"commits_made":     result.CommitsMade,
			"tests_passed":     result.TestsPassed,
			"error_message":    result.ErrorMessage,
			"metadata":         result.Metadata,
		},
		"trigger_source": "branching_manager",
		"timestamp":      time.Now(),
	}

	return n.executeWorkflow(ctx, workflowID, payload)
}

// TriggerBranchingCodeExecutedWorkflow triggers workflow when branching code is executed
func (n *N8NIntegration) TriggerBranchingCodeExecutedWorkflow(ctx context.Context, result *interfaces.ExecutionResult) error {
	payload := map[string]interface{}{
		"execution_result": map[string]interface{}{
			"config_id":        result.ConfigID,
			"success":          result.Success,
			"execution_time":   result.ExecutionTime,
			"duration":         result.Duration.String(),
			"branches_created": result.BranchesCreated,
			"error_message":    result.ErrorMessage,
			"metadata":         result.Metadata,
		},
		"trigger_source": "branching_manager",
		"timestamp":      time.Now(),
	}

	return n.sendWebhook(ctx, "branching_code_executed", "execution_result", result.ConfigID, payload)
}

// executeWorkflow executes a specific n8n workflow
func (n *N8NIntegration) executeWorkflow(ctx context.Context, workflowID string, data map[string]interface{}) error {
	url := fmt.Sprintf("%s/api/v1/workflows/%s/execute", n.baseURL, workflowID)

	payload := map[string]interface{}{
		"data": data,
	}

	jsonData, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal workflow payload: %v", err)
	}

	req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("failed to create workflow request: %v", err)
	}

	req.Header.Set("Content-Type", "application/json")
	if n.apiKey != "" {
		req.Header.Set("X-N8N-API-KEY", n.apiKey)
	}

	resp, err := n.client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to execute workflow: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.StatusCode != 201 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("workflow execution failed with status %d: %s", resp.StatusCode, string(body))
	}

	return nil
}

// sendWebhook sends a webhook to n8n
func (n *N8NIntegration) sendWebhook(ctx context.Context, eventType, entityType, entityID string, data map[string]interface{}) error {
	if n.webhookURL == "" {
		return fmt.Errorf("webhook URL not configured")
	}

	payload := &N8NWebhookPayload{
		EventType:  eventType,
		EntityType: entityType,
		EntityID:   entityID,
		Timestamp:  time.Now(),
		Data:       data,
		Metadata: map[string]interface{}{
			"source":  "branching_manager",
			"version": "1.0.0",
		},
	}

	// Add signature if secret is configured
	if n.secret != "" {
		payload.Signature = n.generateSignature(payload)
	}

	jsonData, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal webhook payload: %v", err)
	}

	req, err := http.NewRequestWithContext(ctx, "POST", n.webhookURL, bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("failed to create webhook request: %v", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("User-Agent", "BranchingManager/1.0")

	resp, err := n.client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send webhook: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.StatusCode != 201 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("webhook failed with status %d: %s", resp.StatusCode, string(body))
	}

	return nil
}

// GetWorkflowStatus gets the status of a workflow execution
func (n *N8NIntegration) GetWorkflowStatus(ctx context.Context, executionID string) (*N8NWorkflowExecution, error) {
	url := fmt.Sprintf("%s/api/v1/executions/%s", n.baseURL, executionID)

	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %v", err)
	}

	if n.apiKey != "" {
		req.Header.Set("X-N8N-API-KEY", n.apiKey)
	}

	resp, err := n.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to get workflow status: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("failed to get workflow status: %s", string(body))
	}

	var execution N8NWorkflowExecution
	if err := json.NewDecoder(resp.Body).Decode(&execution); err != nil {
		return nil, fmt.Errorf("failed to decode workflow execution: %v", err)
	}

	return &execution, nil
}

// ListWorkflows lists available workflows
func (n *N8NIntegration) ListWorkflows(ctx context.Context) ([]map[string]interface{}, error) {
	url := fmt.Sprintf("%s/api/v1/workflows", n.baseURL)

	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %v", err)
	}

	if n.apiKey != "" {
		req.Header.Set("X-N8N-API-KEY", n.apiKey)
	}

	resp, err := n.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to list workflows: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("failed to list workflows: %s", string(body))
	}

	var workflows []map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&workflows); err != nil {
		return nil, fmt.Errorf("failed to decode workflows: %v", err)
	}

	return workflows, nil
}

// Health checks the n8n integration health
func (n *N8NIntegration) Health(ctx context.Context) error {
	url := fmt.Sprintf("%s/healthz", n.baseURL)

	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return fmt.Errorf("failed to create health check request: %v", err)
	}

	resp, err := n.client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to check n8n health: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return fmt.Errorf("n8n health check failed with status: %d", resp.StatusCode)
	}

	return nil
}

// serializeQuantumBranch serializes a quantum branch for n8n workflow
func (n *N8NIntegration) serializeQuantumBranch(qb *interfaces.QuantumBranch) map[string]interface{} {
	approaches := make([]map[string]interface{}, len(qb.Approaches))
	for i, approach := range qb.Approaches {
		approaches[i] = map[string]interface{}{
			"id":           approach.ID,
			"name":         approach.Name,
			"branch_name":  approach.BranchName,
			"strategy":     approach.Strategy,
			"status":       approach.Status,
			"score":        approach.Score,
			"confidence":   approach.Confidence,
			"created_at":   approach.CreatedAt,
			"completed_at": approach.CompletedAt,
			"metadata":     approach.Metadata,
		}
	}

	return map[string]interface{}{
		"id":          qb.ID,
		"name":        qb.Name,
		"description": qb.Description,
		"base_branch": qb.BaseBranch,
		"status":      qb.Status,
		"created_at":  qb.CreatedAt,
		"updated_at":  qb.UpdatedAt,
		"approaches":  approaches,
		"metadata":    qb.Metadata,
	}
}

// generateSignature generates a signature for webhook payload
func (n *N8NIntegration) generateSignature(payload *N8NWebhookPayload) string {
	// In production, use HMAC-SHA256 with the secret
	// For now, return a simple hash
	return fmt.Sprintf("sha256=%x", simpleHash(fmt.Sprintf("%s%s%s", payload.EventType, payload.EntityID, n.secret)))
}

// simpleHash creates a simple hash (replace with proper HMAC in production)
func simpleHash(s string) uint32 {
	h := uint32(0)
	for _, c := range s {
		h = h*31 + uint32(c)
	}
	return h
}
