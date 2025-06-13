package integrations

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"time"

	"github.com/gerivdb/email-sender-1/development/managers/branching-manager/interfaces"
)

// MCPGatewayIntegration handles integration with MCP (Model Context Protocol) Gateway
type MCPGatewayIntegration struct {
	client      *http.Client
	baseURL     string
	apiKey      string
	endpoints   map[string]string
	rateLimiter *RateLimiter
}

// MCPGatewayConfig holds MCP Gateway configuration
type MCPGatewayConfig struct {
	BaseURL   string
	APIKey    string
	Endpoints map[string]string
	Timeout   time.Duration
	RateLimit int // requests per minute
}

// MCPResponse represents a standard MCP Gateway response
type MCPResponse struct {
	Success   bool                   `json:"success"`
	Data      interface{}            `json:"data,omitempty"`
	Error     string                 `json:"error,omitempty"`
	Metadata  map[string]interface{} `json:"metadata,omitempty"`
	Timestamp time.Time              `json:"timestamp"`
}

// MCPSessionRequest represents a session creation request
type MCPSessionRequest struct {
	Scope     string                 `json:"scope"`
	Duration  string                 `json:"duration"`
	Metadata  map[string]interface{} `json:"metadata"`
	UserID    string                 `json:"user_id,omitempty"`
	ProjectID string                 `json:"project_id,omitempty"`
}

// MCPBranchRequest represents a branch creation request
type MCPBranchRequest struct {
	Name       string                 `json:"name"`
	BaseBranch string                 `json:"base_branch"`
	SessionID  string                 `json:"session_id"`
	Dimensions []string               `json:"dimensions,omitempty"`
	Tags       []string               `json:"tags,omitempty"`
	Metadata   map[string]interface{} `json:"metadata"`
}

// MCPEventRequest represents an event registration request
type MCPEventRequest struct {
	EventType string                 `json:"event_type"`
	Source    string                 `json:"source"`
	BranchID  string                 `json:"branch_id,omitempty"`
	SessionID string                 `json:"session_id,omitempty"`
	Payload   map[string]interface{} `json:"payload"`
}

// MCPSnapshotRequest represents a snapshot creation request
type MCPSnapshotRequest struct {
	BranchID       string                 `json:"branch_id"`
	GitHash        string                 `json:"git_hash"`
	ChangesSummary string                 `json:"changes_summary"`
	TagName        string                 `json:"tag_name,omitempty"`
	Metadata       map[string]interface{} `json:"metadata"`
}

// RateLimiter implements simple rate limiting
type RateLimiter struct {
	tokens    chan struct{}
	ticker    *time.Ticker
	rateLimit int
}

// NewRateLimiter creates a new rate limiter
func NewRateLimiter(requestsPerMinute int) *RateLimiter {
	rl := &RateLimiter{
		tokens:    make(chan struct{}, requestsPerMinute),
		ticker:    time.NewTicker(time.Minute / time.Duration(requestsPerMinute)),
		rateLimit: requestsPerMinute,
	}

	// Fill the bucket initially
	for i := 0; i < requestsPerMinute; i++ {
		rl.tokens <- struct{}{}
	}

	// Refill tokens
	go func() {
		for range rl.ticker.C {
			select {
			case rl.tokens <- struct{}{}:
			default:
			}
		}
	}()

	return rl
}

// Wait waits for a token to become available
func (rl *RateLimiter) Wait(ctx context.Context) error {
	select {
	case <-rl.tokens:
		return nil
	case <-ctx.Done():
		return ctx.Err()
	}
}

// NewMCPGatewayIntegration creates a new MCP Gateway integration
func NewMCPGatewayIntegration(config *MCPGatewayConfig) *MCPGatewayIntegration {
	client := &http.Client{
		Timeout: config.Timeout,
	}

	var rateLimiter *RateLimiter
	if config.RateLimit > 0 {
		rateLimiter = NewRateLimiter(config.RateLimit)
	}

	return &MCPGatewayIntegration{
		client:      client,
		baseURL:     config.BaseURL,
		apiKey:      config.APIKey,
		endpoints:   config.Endpoints,
		rateLimiter: rateLimiter,
	}
}

// RegisterSession registers a session with MCP Gateway
func (m *MCPGatewayIntegration) RegisterSession(ctx context.Context, session *interfaces.Session) error {
	endpoint := m.getEndpoint("sessions")

	request := &MCPSessionRequest{
		Scope:    session.Scope,
		Duration: session.Duration.String(),
		Metadata: session.Metadata,
	}

	// Add user and project context if available
	if userID, exists := session.Metadata["user_id"]; exists {
		if uid, ok := userID.(string); ok {
			request.UserID = uid
		}
	}
	if projectID, exists := session.Metadata["project_id"]; exists {
		if pid, ok := projectID.(string); ok {
			request.ProjectID = pid
		}
	}

	response, err := m.makeRequest(ctx, "POST", endpoint, request)
	if err != nil {
		return fmt.Errorf("failed to register session: %v", err)
	}

	if !response.Success {
		return fmt.Errorf("session registration failed: %s", response.Error)
	}

	return nil
}

// RegisterBranch registers a branch with MCP Gateway
func (m *MCPGatewayIntegration) RegisterBranch(ctx context.Context, branch *interfaces.Branch) error {
	endpoint := m.getEndpoint("branches")

	request := &MCPBranchRequest{
		Name:       branch.Name,
		BaseBranch: branch.BaseBranch,
		SessionID:  branch.SessionID,
		Metadata:   branch.Metadata,
	}

	// Add dimensions and tags if available
	if dimensions, exists := branch.Metadata["dimensions"]; exists {
		if dims, ok := dimensions.([]string); ok {
			request.Dimensions = dims
		}
	}
	if tags, exists := branch.Metadata["tags"]; exists {
		if t, ok := tags.([]string); ok {
			request.Tags = t
		}
	}

	response, err := m.makeRequest(ctx, "POST", endpoint, request)
	if err != nil {
		return fmt.Errorf("failed to register branch: %v", err)
	}

	if !response.Success {
		return fmt.Errorf("branch registration failed: %s", response.Error)
	}

	return nil
}

// RegisterEvent registers an event with MCP Gateway
func (m *MCPGatewayIntegration) RegisterEvent(ctx context.Context, event *interfaces.BranchingEvent) error {
	endpoint := m.getEndpoint("events")

	request := &MCPEventRequest{
		EventType: string(event.Type),
		Source:    event.Source,
		BranchID:  event.BranchID,
		SessionID: event.SessionID,
		Payload:   event.Payload,
	}

	response, err := m.makeRequest(ctx, "POST", endpoint, request)
	if err != nil {
		return fmt.Errorf("failed to register event: %v", err)
	}

	if !response.Success {
		return fmt.Errorf("event registration failed: %s", response.Error)
	}

	return nil
}

// RegisterSnapshot registers a temporal snapshot with MCP Gateway
func (m *MCPGatewayIntegration) RegisterSnapshot(ctx context.Context, snapshot *interfaces.TemporalSnapshot) error {
	endpoint := m.getEndpoint("snapshots")

	request := &MCPSnapshotRequest{
		BranchID:       snapshot.BranchID,
		GitHash:        snapshot.GitHash,
		ChangesSummary: snapshot.ChangesSummary,
		TagName:        snapshot.TagName,
		Metadata:       snapshot.Metadata,
	}

	response, err := m.makeRequest(ctx, "POST", endpoint, request)
	if err != nil {
		return fmt.Errorf("failed to register snapshot: %v", err)
	}

	if !response.Success {
		return fmt.Errorf("snapshot registration failed: %s", response.Error)
	}

	return nil
}

// GetSessions retrieves sessions from MCP Gateway
func (m *MCPGatewayIntegration) GetSessions(ctx context.Context, filters map[string]string) ([]*interfaces.Session, error) {
	endpoint := m.getEndpoint("sessions")

	// Build query parameters
	queryParams := url.Values{}
	for key, value := range filters {
		queryParams.Add(key, value)
	}

	if len(queryParams) > 0 {
		endpoint += "?" + queryParams.Encode()
	}

	response, err := m.makeRequest(ctx, "GET", endpoint, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to get sessions: %v", err)
	}

	if !response.Success {
		return nil, fmt.Errorf("get sessions failed: %s", response.Error)
	}

	// Parse response data
	var sessions []*interfaces.Session
	if data, ok := response.Data.([]interface{}); ok {
		for _, item := range data {
			if sessionData, ok := item.(map[string]interface{}); ok {
				session := parseSessionFromMCP(sessionData)
				if session != nil {
					sessions = append(sessions, session)
				}
			}
		}
	}

	return sessions, nil
}

// GetBranches retrieves branches from MCP Gateway
func (m *MCPGatewayIntegration) GetBranches(ctx context.Context, filters map[string]string) ([]*interfaces.Branch, error) {
	endpoint := m.getEndpoint("branches")

	// Build query parameters
	queryParams := url.Values{}
	for key, value := range filters {
		queryParams.Add(key, value)
	}

	if len(queryParams) > 0 {
		endpoint += "?" + queryParams.Encode()
	}

	response, err := m.makeRequest(ctx, "GET", endpoint, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to get branches: %v", err)
	}

	if !response.Success {
		return nil, fmt.Errorf("get branches failed: %s", response.Error)
	}

	// Parse response data
	var branches []*interfaces.Branch
	if data, ok := response.Data.([]interface{}); ok {
		for _, item := range data {
			if branchData, ok := item.(map[string]interface{}); ok {
				branch := parseBranchFromMCP(branchData)
				if branch != nil {
					branches = append(branches, branch)
				}
			}
		}
	}

	return branches, nil
}

// GetEvents retrieves events from MCP Gateway
func (m *MCPGatewayIntegration) GetEvents(ctx context.Context, filters map[string]string) ([]*interfaces.BranchingEvent, error) {
	endpoint := m.getEndpoint("events")

	// Build query parameters
	queryParams := url.Values{}
	for key, value := range filters {
		queryParams.Add(key, value)
	}

	if len(queryParams) > 0 {
		endpoint += "?" + queryParams.Encode()
	}

	response, err := m.makeRequest(ctx, "GET", endpoint, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to get events: %v", err)
	}

	if !response.Success {
		return nil, fmt.Errorf("get events failed: %s", response.Error)
	}

	// Parse response data
	var events []*interfaces.BranchingEvent
	if data, ok := response.Data.([]interface{}); ok {
		for _, item := range data {
			if eventData, ok := item.(map[string]interface{}); ok {
				event := parseEventFromMCP(eventData)
				if event != nil {
					events = append(events, event)
				}
			}
		}
	}

	return events, nil
}

// UpdateSessionStatus updates session status via MCP Gateway
func (m *MCPGatewayIntegration) UpdateSessionStatus(ctx context.Context, sessionID string, status interfaces.SessionStatus) error {
	endpoint := fmt.Sprintf("%s/%s/status", m.getEndpoint("sessions"), sessionID)

	request := map[string]interface{}{
		"status": status,
	}

	response, err := m.makeRequest(ctx, "PUT", endpoint, request)
	if err != nil {
		return fmt.Errorf("failed to update session status: %v", err)
	}

	if !response.Success {
		return fmt.Errorf("session status update failed: %s", response.Error)
	}

	return nil
}

// UpdateBranchStatus updates branch status via MCP Gateway
func (m *MCPGatewayIntegration) UpdateBranchStatus(ctx context.Context, branchID string, status interfaces.BranchStatus) error {
	endpoint := fmt.Sprintf("%s/%s/status", m.getEndpoint("branches"), branchID)

	request := map[string]interface{}{
		"status": status,
	}

	response, err := m.makeRequest(ctx, "PUT", endpoint, request)
	if err != nil {
		return fmt.Errorf("failed to update branch status: %v", err)
	}

	if !response.Success {
		return fmt.Errorf("branch status update failed: %s", response.Error)
	}

	return nil
}

// GetMetrics retrieves metrics from MCP Gateway
func (m *MCPGatewayIntegration) GetMetrics(ctx context.Context, metricType string, timeRange *interfaces.TimeRange) (map[string]interface{}, error) {
	endpoint := fmt.Sprintf("%s/metrics", m.baseURL)

	queryParams := url.Values{}
	queryParams.Add("type", metricType)
	if timeRange != nil {
		queryParams.Add("start", timeRange.Start.Format(time.RFC3339))
		queryParams.Add("end", timeRange.End.Format(time.RFC3339))
	}

	endpoint += "?" + queryParams.Encode()

	response, err := m.makeRequest(ctx, "GET", endpoint, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to get metrics: %v", err)
	}

	if !response.Success {
		return nil, fmt.Errorf("get metrics failed: %s", response.Error)
	}

	if metrics, ok := response.Data.(map[string]interface{}); ok {
		return metrics, nil
	}

	return nil, fmt.Errorf("invalid metrics response format")
}

// NotifyQuantumBranchCreated notifies MCP Gateway of quantum branch creation
func (m *MCPGatewayIntegration) NotifyQuantumBranchCreated(ctx context.Context, quantumBranch *interfaces.QuantumBranch) error {
	endpoint := fmt.Sprintf("%s/quantum-branches", m.baseURL)

	request := map[string]interface{}{
		"id":          quantumBranch.ID,
		"name":        quantumBranch.Name,
		"description": quantumBranch.Description,
		"base_branch": quantumBranch.BaseBranch,
		"status":      quantumBranch.Status,
		"approaches":  serializeApproaches(quantumBranch.Approaches),
		"metadata":    quantumBranch.Metadata,
	}

	response, err := m.makeRequest(ctx, "POST", endpoint, request)
	if err != nil {
		return fmt.Errorf("failed to notify quantum branch creation: %v", err)
	}

	if !response.Success {
		return fmt.Errorf("quantum branch notification failed: %s", response.Error)
	}

	return nil
}

// makeRequest makes an HTTP request to MCP Gateway
func (m *MCPGatewayIntegration) makeRequest(ctx context.Context, method, endpoint string, payload interface{}) (*MCPResponse, error) {
	// Apply rate limiting
	if m.rateLimiter != nil {
		if err := m.rateLimiter.Wait(ctx); err != nil {
			return nil, fmt.Errorf("rate limit exceeded: %v", err)
		}
	}

	var body io.Reader
	if payload != nil {
		jsonData, err := json.Marshal(payload)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal payload: %v", err)
		}
		body = bytes.NewBuffer(jsonData)
	}

	req, err := http.NewRequestWithContext(ctx, method, endpoint, body)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %v", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("User-Agent", "BranchingManager/1.0")
	if m.apiKey != "" {
		req.Header.Set("Authorization", "Bearer "+m.apiKey)
	}

	resp, err := m.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to make request: %v", err)
	}
	defer resp.Body.Close()

	var mcpResponse MCPResponse
	if err := json.NewDecoder(resp.Body).Decode(&mcpResponse); err != nil {
		return nil, fmt.Errorf("failed to decode response: %v", err)
	}

	// Set success based on HTTP status if not explicitly set
	if resp.StatusCode >= 200 && resp.StatusCode < 300 {
		if mcpResponse.Error == "" {
			mcpResponse.Success = true
		}
	}

	return &mcpResponse, nil
}

// getEndpoint gets the full endpoint URL for a given endpoint name
func (m *MCPGatewayIntegration) getEndpoint(endpointName string) string {
	if endpoint, exists := m.endpoints[endpointName]; exists {
		return m.baseURL + endpoint
	}
	// Fallback to default pattern
	return fmt.Sprintf("%s/api/v1/%s", m.baseURL, endpointName)
}

// Health checks the MCP Gateway health
func (m *MCPGatewayIntegration) Health(ctx context.Context) error {
	endpoint := fmt.Sprintf("%s/health", m.baseURL)

	response, err := m.makeRequest(ctx, "GET", endpoint, nil)
	if err != nil {
		return fmt.Errorf("MCP Gateway health check failed: %v", err)
	}

	if !response.Success {
		return fmt.Errorf("MCP Gateway health check failed: %s", response.Error)
	}

	return nil
}

// Helper functions for parsing MCP responses

func parseSessionFromMCP(data map[string]interface{}) *interfaces.Session {
	session := &interfaces.Session{}

	if id, ok := data["id"].(string); ok {
		session.ID = id
	}
	if scope, ok := data["scope"].(string); ok {
		session.Scope = scope
	}
	if status, ok := data["status"].(string); ok {
		session.Status = interfaces.SessionStatus(status)
	}
	if duration, ok := data["duration"].(string); ok {
		if d, err := time.ParseDuration(duration); err == nil {
			session.Duration = d
		}
	}
	if createdAt, ok := data["created_at"].(string); ok {
		if t, err := time.Parse(time.RFC3339, createdAt); err == nil {
			session.CreatedAt = t
		}
	}
	if updatedAt, ok := data["updated_at"].(string); ok {
		if t, err := time.Parse(time.RFC3339, updatedAt); err == nil {
			session.UpdatedAt = t
		}
	}
	if metadata, ok := data["metadata"].(map[string]interface{}); ok {
		session.Metadata = metadata
	}

	return session
}

func parseBranchFromMCP(data map[string]interface{}) *interfaces.Branch {
	branch := &interfaces.Branch{}

	if id, ok := data["id"].(string); ok {
		branch.ID = id
	}
	if sessionID, ok := data["session_id"].(string); ok {
		branch.SessionID = sessionID
	}
	if name, ok := data["name"].(string); ok {
		branch.Name = name
	}
	if baseBranch, ok := data["base_branch"].(string); ok {
		branch.BaseBranch = baseBranch
	}
	if status, ok := data["status"].(string); ok {
		branch.Status = interfaces.BranchStatus(status)
	}
	if createdAt, ok := data["created_at"].(string); ok {
		if t, err := time.Parse(time.RFC3339, createdAt); err == nil {
			branch.CreatedAt = t
		}
	}
	if updatedAt, ok := data["updated_at"].(string); ok {
		if t, err := time.Parse(time.RFC3339, updatedAt); err == nil {
			branch.UpdatedAt = t
		}
	}
	if gitHash, ok := data["git_hash"].(string); ok {
		branch.GitHash = gitHash
	}
	if metadata, ok := data["metadata"].(map[string]interface{}); ok {
		branch.Metadata = metadata
	}

	return branch
}

func parseEventFromMCP(data map[string]interface{}) *interfaces.BranchingEvent {
	event := &interfaces.BranchingEvent{}

	if id, ok := data["id"].(string); ok {
		event.ID = id
	}
	if eventType, ok := data["event_type"].(string); ok {
		event.Type = interfaces.EventType(eventType)
	}
	if source, ok := data["source"].(string); ok {
		event.Source = source
	}
	if branchID, ok := data["branch_id"].(string); ok {
		event.BranchID = branchID
	}
	if sessionID, ok := data["session_id"].(string); ok {
		event.SessionID = sessionID
	}
	if timestamp, ok := data["timestamp"].(string); ok {
		if t, err := time.Parse(time.RFC3339, timestamp); err == nil {
			event.Timestamp = t
		}
	}
	if payload, ok := data["payload"].(map[string]interface{}); ok {
		event.Payload = payload
	}
	if processed, ok := data["processed"].(bool); ok {
		event.Processed = processed
	}

	return event
}

func serializeApproaches(approaches []*interfaces.BranchApproach) []map[string]interface{} {
	serialized := make([]map[string]interface{}, len(approaches))
	for i, approach := range approaches {
		serialized[i] = map[string]interface{}{
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
	return serialized
}

// Close closes the MCP Gateway integration and cleans up resources
func (m *MCPGatewayIntegration) Close() error {
	if m.rateLimiter != nil && m.rateLimiter.ticker != nil {
		m.rateLimiter.ticker.Stop()
	}
	return nil
}
