package client

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"time"

	"email_sender/pkg/bridge/serialization"
)

// N8NClient interface pour communication avec N8N
type N8NClient interface {
	ExecuteWorkflow(ctx context.Context, request *WorkflowExecutionRequest) (*WorkflowExecutionResponse, error)
	GetWorkflow(ctx context.Context, workflowID string) (*serialization.WorkflowData, error)
	CreateWorkflow(ctx context.Context, workflow *serialization.WorkflowData) (*serialization.WorkflowData, error)
	UpdateWorkflow(ctx context.Context, workflow *serialization.WorkflowData) (*serialization.WorkflowData, error)
	DeleteWorkflow(ctx context.Context, workflowID string) error
	ListWorkflows(ctx context.Context, filters *WorkflowFilters) ([]*WorkflowSummary, error)
	GetExecutionStatus(ctx context.Context, executionID string) (*ExecutionStatus, error)
	CancelExecution(ctx context.Context, executionID string) error
}

// HTTPN8NClient implémentation HTTP du client N8N
type HTTPN8NClient struct {
	config     *ClientConfig
	httpClient *http.Client
	serializer serialization.WorkflowSerializer
	baseURL    *url.URL
}

// NewHTTPN8NClient crée un nouveau client HTTP N8N
func NewHTTPN8NClient(config *ClientConfig, serializer serialization.WorkflowSerializer) (N8NClient, error) {
	if config == nil {
		return nil, fmt.Errorf("client config cannot be nil")
	}

	if err := config.Validate(); err != nil {
		return nil, fmt.Errorf("invalid client config: %w", err)
	}

	baseURL, err := url.Parse(config.BaseURL)
	if err != nil {
		return nil, fmt.Errorf("invalid base URL: %w", err)
	}

	httpClient := &http.Client{
		Timeout: config.Timeout,
		Transport: &http.Transport{
			MaxIdleConns:          config.MaxIdleConns,
			MaxIdleConnsPerHost:   config.MaxIdleConnsPerHost,
			IdleConnTimeout:       config.IdleConnTimeout,
			DisableKeepAlives:     config.DisableKeepAlives,
			TLSHandshakeTimeout:   config.TLSHandshakeTimeout,
			ResponseHeaderTimeout: config.ResponseHeaderTimeout,
		},
	}

	return &HTTPN8NClient{
		config:     config,
		httpClient: httpClient,
		serializer: serializer,
		baseURL:    baseURL,
	}, nil
}

// ExecuteWorkflow exécute un workflow dans N8N
func (c *HTTPN8NClient) ExecuteWorkflow(ctx context.Context, request *WorkflowExecutionRequest) (*WorkflowExecutionResponse, error) {
	if request == nil {
		return nil, fmt.Errorf("execution request cannot be nil")
	}

	endpoint := fmt.Sprintf("/api/v1/workflows/%s/execute", request.WorkflowID)

	reqBody, err := json.Marshal(request)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	resp, err := c.doRequest(ctx, "POST", endpoint, reqBody)
	if err != nil {
		return nil, fmt.Errorf("execution request failed: %w", err)
	}
	defer resp.Body.Close()

	var response WorkflowExecutionResponse
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return &response, nil
}

// GetWorkflow récupère un workflow depuis N8N
func (c *HTTPN8NClient) GetWorkflow(ctx context.Context, workflowID string) (*serialization.WorkflowData, error) {
	if workflowID == "" {
		return nil, fmt.Errorf("workflow ID cannot be empty")
	}

	endpoint := fmt.Sprintf("/api/v1/workflows/%s", workflowID)
	resp, err := c.doRequest(ctx, "GET", endpoint, nil)
	if err != nil {
		return nil, fmt.Errorf("get workflow request failed: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	workflow, err := c.serializer.DeserializeFromN8N(respBody)
	if err != nil {
		return nil, fmt.Errorf("failed to deserialize workflow: %w", err)
	}

	return workflow, nil
}

// CreateWorkflow crée un nouveau workflow dans N8N
func (c *HTTPN8NClient) CreateWorkflow(ctx context.Context, workflow *serialization.WorkflowData) (*serialization.WorkflowData, error) {
	if workflow == nil {
		return nil, fmt.Errorf("workflow cannot be nil")
	}

	reqBody, err := c.serializer.SerializeToN8N(workflow)
	if err != nil {
		return nil, fmt.Errorf("failed to serialize workflow: %w", err)
	}

	resp, err := c.doRequest(ctx, "POST", "/api/v1/workflows", reqBody)
	if err != nil {
		return nil, fmt.Errorf("create workflow request failed: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	createdWorkflow, err := c.serializer.DeserializeFromN8N(respBody)
	if err != nil {
		return nil, fmt.Errorf("failed to deserialize created workflow: %w", err)
	}

	return createdWorkflow, nil
}

// UpdateWorkflow met à jour un workflow dans N8N
func (c *HTTPN8NClient) UpdateWorkflow(ctx context.Context, workflow *serialization.WorkflowData) (*serialization.WorkflowData, error) {
	if workflow == nil {
		return nil, fmt.Errorf("workflow cannot be nil")
	}

	if workflow.ID == "" {
		return nil, fmt.Errorf("workflow ID cannot be empty for update")
	}

	reqBody, err := c.serializer.SerializeToN8N(workflow)
	if err != nil {
		return nil, fmt.Errorf("failed to serialize workflow: %w", err)
	}

	endpoint := fmt.Sprintf("/api/v1/workflows/%s", workflow.ID)
	resp, err := c.doRequest(ctx, "PUT", endpoint, reqBody)
	if err != nil {
		return nil, fmt.Errorf("update workflow request failed: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	updatedWorkflow, err := c.serializer.DeserializeFromN8N(respBody)
	if err != nil {
		return nil, fmt.Errorf("failed to deserialize updated workflow: %w", err)
	}

	return updatedWorkflow, nil
}

// DeleteWorkflow supprime un workflow dans N8N
func (c *HTTPN8NClient) DeleteWorkflow(ctx context.Context, workflowID string) error {
	if workflowID == "" {
		return fmt.Errorf("workflow ID cannot be empty")
	}

	endpoint := fmt.Sprintf("/api/v1/workflows/%s", workflowID)
	resp, err := c.doRequest(ctx, "DELETE", endpoint, nil)
	if err != nil {
		return fmt.Errorf("delete workflow request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusNoContent {
		return fmt.Errorf("delete workflow failed with status: %d", resp.StatusCode)
	}

	return nil
}

// ListWorkflows liste les workflows avec filtres
func (c *HTTPN8NClient) ListWorkflows(ctx context.Context, filters *WorkflowFilters) ([]*WorkflowSummary, error) {
	endpoint := "/api/v1/workflows"

	if filters != nil {
		queryParams := filters.ToQueryParams()
		if len(queryParams) > 0 {
			endpoint += "?" + queryParams.Encode()
		}
	}

	resp, err := c.doRequest(ctx, "GET", endpoint, nil)
	if err != nil {
		return nil, fmt.Errorf("list workflows request failed: %w", err)
	}
	defer resp.Body.Close()

	var response struct {
		Data []*WorkflowSummary `json:"data"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return response.Data, nil
}

// GetExecutionStatus récupère le statut d'une exécution
func (c *HTTPN8NClient) GetExecutionStatus(ctx context.Context, executionID string) (*ExecutionStatus, error) {
	if executionID == "" {
		return nil, fmt.Errorf("execution ID cannot be empty")
	}

	endpoint := fmt.Sprintf("/api/v1/executions/%s", executionID)
	resp, err := c.doRequest(ctx, "GET", endpoint, nil)
	if err != nil {
		return nil, fmt.Errorf("get execution status request failed: %w", err)
	}
	defer resp.Body.Close()

	var status ExecutionStatus
	if err := json.NewDecoder(resp.Body).Decode(&status); err != nil {
		return nil, fmt.Errorf("failed to decode execution status: %w", err)
	}

	return &status, nil
}

// CancelExecution annule une exécution en cours
func (c *HTTPN8NClient) CancelExecution(ctx context.Context, executionID string) error {
	if executionID == "" {
		return fmt.Errorf("execution ID cannot be empty")
	}

	endpoint := fmt.Sprintf("/api/v1/executions/%s/cancel", executionID)
	resp, err := c.doRequest(ctx, "POST", endpoint, nil)
	if err != nil {
		return fmt.Errorf("cancel execution request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("cancel execution failed with status: %d", resp.StatusCode)
	}

	return nil
}

// doRequest effectue une requête HTTP avec retry et headers standard
func (c *HTTPN8NClient) doRequest(ctx context.Context, method, endpoint string, body []byte) (*http.Response, error) {
	fullURL := c.baseURL.ResolveReference(&url.URL{Path: endpoint})
	var reqBody io.Reader
	if body != nil {
		reqBody = bytes.NewReader(body)
	}

	req, err := http.NewRequestWithContext(ctx, method, fullURL.String(), reqBody)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	// Headers standard
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")
	req.Header.Set("User-Agent", fmt.Sprintf("n8n-go-bridge/%s", c.config.Version))

	// Authentification
	if c.config.APIKey != "" {
		req.Header.Set("X-N8N-API-KEY", c.config.APIKey)
	}

	if c.config.BearerToken != "" {
		req.Header.Set("Authorization", "Bearer "+c.config.BearerToken)
	}

	// Headers personnalisés
	for key, value := range c.config.CustomHeaders {
		req.Header.Set(key, value)
	}

	// Retry logic
	var lastErr error
	for attempt := 0; attempt <= c.config.MaxRetries; attempt++ {
		if attempt > 0 {
			// Backoff exponentiel
			backoff := time.Duration(attempt) * c.config.RetryDelay
			select {
			case <-ctx.Done():
				return nil, ctx.Err()
			case <-time.After(backoff):
			}

			// Re-créer le body si nécessaire
			if body != nil {
				reqBody = bytes.NewReader(body)
				req.Body = io.NopCloser(reqBody)
			}
		}

		resp, err := c.httpClient.Do(req)
		if err != nil {
			lastErr = err
			continue
		}

		// Vérifier si c'est un succès ou une erreur retriable
		if c.isRetriableError(resp.StatusCode) && attempt < c.config.MaxRetries {
			resp.Body.Close()
			lastErr = fmt.Errorf("retriable error: status %d", resp.StatusCode)
			continue
		}

		return resp, nil
	}

	return nil, fmt.Errorf("request failed after %d attempts: %w", c.config.MaxRetries+1, lastErr)
}

// isRetriableError détermine si une erreur HTTP est retriable
func (c *HTTPN8NClient) isRetriableError(statusCode int) bool {
	switch statusCode {
	case http.StatusTooManyRequests,
		http.StatusInternalServerError,
		http.StatusBadGateway,
		http.StatusServiceUnavailable,
		http.StatusGatewayTimeout:
		return true
	default:
		return false
	}
}
