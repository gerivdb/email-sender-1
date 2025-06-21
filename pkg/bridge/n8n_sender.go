package bridge

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"time"

	"github.com/cenkalti/backoff/v4"
)

// N8NSender interface définit les méthodes pour envoyer des requêtes vers N8N
type N8NSender interface {
	TriggerWorkflow(id string, data map[string]interface{}) error
	TriggerWorkflowWithContext(ctx context.Context, id string, data map[string]interface{}) (*WorkflowResponse, error)
	Health() error
	SetConfig(config N8NClientConfig)
}

// N8NClientConfig contient la configuration du client N8N
type N8NClientConfig struct {
	BaseURL        string        `json:"base_url" yaml:"base_url"`
	APIKey         string        `json:"api_key" yaml:"api_key"`
	Timeout        time.Duration `json:"timeout" yaml:"timeout"`
	MaxRetries     int           `json:"max_retries" yaml:"max_retries"`
	RetryDelay     time.Duration `json:"retry_delay" yaml:"retry_delay"`
	CircuitBreaker bool          `json:"circuit_breaker" yaml:"circuit_breaker"`
}

// N8NClient implémente l'interface N8NSender
type N8NClient struct {
	config     N8NClientConfig
	httpClient *http.Client
	baseURL    *url.URL
}

// WorkflowTriggerRequest structure pour déclencher un workflow N8N
type WorkflowTriggerRequest struct {
	WorkflowID string                 `json:"workflowId"`
	Data       map[string]interface{} `json:"data"`
	Source     string                 `json:"source,omitempty"`
}

// WorkflowResponse réponse de N8N pour l'exécution d'un workflow
type WorkflowResponse struct {
	Success     bool                   `json:"success"`
	ExecutionID string                 `json:"executionId,omitempty"`
	Data        map[string]interface{} `json:"data,omitempty"`
	Error       string                 `json:"error,omitempty"`
}

// NewN8NClient crée une nouvelle instance du client N8N
func NewN8NClient(config N8NClientConfig) (*N8NClient, error) {
	if config.BaseURL == "" {
		return nil, fmt.Errorf("base_url is required")
	}

	baseURL, err := url.Parse(config.BaseURL)
	if err != nil {
		return nil, fmt.Errorf("invalid base_url: %w", err)
	}
	if baseURL.Scheme == "" || baseURL.Host == "" {
		return nil, fmt.Errorf("invalid base_url: scheme and host are required for BaseURL (e.g., http://localhost:5678), got scheme='%s', host='%s'", baseURL.Scheme, baseURL.Host)
	}

	// Valeurs par défaut
	if config.Timeout == 0 {
		config.Timeout = 30 * time.Second
	}
	if config.MaxRetries == 0 {
		config.MaxRetries = 3
	}
	if config.RetryDelay == 0 {
		config.RetryDelay = 1 * time.Second
	}

	httpClient := &http.Client{
		Timeout: config.Timeout,
	}

	return &N8NClient{
		config:     config,
		httpClient: httpClient,
		baseURL:    baseURL,
	}, nil
}

// TriggerWorkflow déclenche un workflow N8N (version simple)
func (c *N8NClient) TriggerWorkflow(id string, data map[string]interface{}) error {
	ctx := context.Background()
	_, err := c.TriggerWorkflowWithContext(ctx, id, data)
	return err
}

// TriggerWorkflowWithContext déclenche un workflow N8N avec contexte et retry logic
func (c *N8NClient) TriggerWorkflowWithContext(ctx context.Context, id string, data map[string]interface{}) (*WorkflowResponse, error) {
	if id == "" {
		return nil, fmt.Errorf("workflow ID cannot be empty")
	}

	request := WorkflowTriggerRequest{
		WorkflowID: id,
		Data:       data,
		Source:     "go-manager",
	}

	var response *WorkflowResponse
	var lastErr error

	// Configuration backoff pour retry logic
	backoffConfig := backoff.NewExponentialBackOff()
	backoffConfig.InitialInterval = c.config.RetryDelay
	backoffConfig.MaxElapsedTime = time.Duration(c.config.MaxRetries) * c.config.RetryDelay

	operation := func() error {
		resp, err := c.sendRequest(ctx, "POST", "/api/v1/workflows/trigger", request)
		if err != nil {
			lastErr = err
			return err
		}
		response = resp
		return nil
	}

	err := backoff.Retry(operation, backoff.WithContext(backoffConfig, ctx))
	if err != nil {
		return nil, fmt.Errorf("failed to trigger workflow after retries: %w", lastErr)
	}

	return response, nil
}

// sendRequest envoie une requête HTTP vers N8N
func (c *N8NClient) sendRequest(ctx context.Context, method, endpoint string, payload interface{}) (*WorkflowResponse, error) {
	// Construire l'URL complète
	fullURL := c.baseURL.ResolveReference(&url.URL{Path: endpoint})

	// Encoder le payload en JSON
	var body io.Reader
	if payload != nil {
		jsonData, err := json.Marshal(payload)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal payload: %w", err)
		}
		body = bytes.NewBuffer(jsonData)
	}

	// Créer la requête HTTP
	req, err := http.NewRequestWithContext(ctx, method, fullURL.String(), body)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	// Headers
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")
	req.Header.Set("User-Agent", "go-manager/1.0")

	if c.config.APIKey != "" {
		req.Header.Set("Authorization", "Bearer "+c.config.APIKey)
	}

	// Envoyer la requête
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	// Lire la réponse
	responseBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	// Vérifier le code de statut
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return &WorkflowResponse{
			Success: false,
			Error:   fmt.Sprintf("HTTP %d: %s", resp.StatusCode, string(responseBody)),
		}, nil
	}

	// Décoder la réponse JSON
	var workflowResp WorkflowResponse
	if err := json.Unmarshal(responseBody, &workflowResp); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return &workflowResp, nil
}

// Health vérifie la santé de la connexion N8N
func (c *N8NClient) Health() error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, "GET", c.baseURL.ResolveReference(&url.URL{Path: "/healthz"}).String(), nil)
	if err != nil {
		return fmt.Errorf("failed to create health check request: %w", err)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("health check failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("health check failed with status: %d", resp.StatusCode)
	}

	return nil
}

// SetConfig met à jour la configuration du client
func (c *N8NClient) SetConfig(config N8NClientConfig) {
	c.config = config
	c.httpClient.Timeout = config.Timeout

	if baseURL, err := url.Parse(config.BaseURL); err == nil {
		c.baseURL = baseURL
	}
}

// GetConfig retourne la configuration actuelle
func (c *N8NClient) GetConfig() N8NClientConfig {
	return c.config
}
