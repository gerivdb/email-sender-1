// filepath: d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\planning-ecosystem-sync\tools\roadmap-connector\roadmap_manager_connector.go
package roadmapconnector

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"time"
)

// RoadmapManagerConnector provides interface with existing Roadmap Manager
type RoadmapManagerConnector struct {
	baseURL    string
	httpClient *http.Client
	auth       *AuthenticationManager
	mapper     *DataMapper
	logger     *log.Logger
	config     *ConnectorConfig
	stats      *ConnectorStats
}

// ConnectorConfig holds configuration for Roadmap Manager connection
type ConnectorConfig struct {
	BaseURL       string        `yaml:"base_url"`
	Timeout       time.Duration `yaml:"timeout"`
	MaxRetries    int           `yaml:"max_retries"`
	RateLimit     int           `yaml:"rate_limit"`
	EnableCache   bool          `yaml:"enable_cache"`
	CacheTTL      time.Duration `yaml:"cache_ttl"`
	EnableMetrics bool          `yaml:"enable_metrics"`
	DebugMode     bool          `yaml:"debug_mode"`
}

// ConnectorStats tracks connector performance metrics
type ConnectorStats struct {
	TotalRequests   int64         `json:"total_requests"`
	SuccessfulSyncs int64         `json:"successful_syncs"`
	FailedSyncs     int64         `json:"failed_syncs"`
	AverageLatency  time.Duration `json:"average_latency"`
	LastSyncTime    time.Time     `json:"last_sync_time"`
	ErrorRate       float64       `json:"error_rate"`
	DataTransferred int64         `json:"data_transferred"`
}

// RoadmapPlan represents a plan in the Roadmap Manager format
type RoadmapPlan struct {
	ID        string                 `json:"id"`
	Title     string                 `json:"title"`
	Version   string                 `json:"version"`
	Status    string                 `json:"status"`
	Progress  float64                `json:"progress"`
	Phases    []RoadmapPhase         `json:"phases"`
	Metadata  map[string]interface{} `json:"metadata"`
	CreatedAt time.Time              `json:"created_at"`
	UpdatedAt time.Time              `json:"updated_at"`
	Tags      []string               `json:"tags"`
	Owner     string                 `json:"owner"`
	Priority  int                    `json:"priority"`
}

// RoadmapPhase represents a phase in the roadmap
type RoadmapPhase struct {
	ID           string        `json:"id"`
	Name         string        `json:"name"`
	Description  string        `json:"description"`
	Status       string        `json:"status"`
	Progress     float64       `json:"progress"`
	Tasks        []RoadmapTask `json:"tasks"`
	StartDate    *time.Time    `json:"start_date,omitempty"`
	EndDate      *time.Time    `json:"end_date,omitempty"`
	Dependencies []string      `json:"dependencies"`
}

// RoadmapTask represents a task in the roadmap
type RoadmapTask struct {
	ID             string     `json:"id"`
	Title          string     `json:"title"`
	Description    string     `json:"description"`
	Status         string     `json:"status"`
	Priority       int        `json:"priority"`
	Assignee       string     `json:"assignee"`
	EstimatedHours int        `json:"estimated_hours"`
	ActualHours    int        `json:"actual_hours"`
	Tags           []string   `json:"tags"`
	CreatedAt      time.Time  `json:"created_at"`
	UpdatedAt      time.Time  `json:"updated_at"`
	DueDate        *time.Time `json:"due_date,omitempty"`
	Dependencies   []string   `json:"dependencies"`
}

// SyncResponse represents the response from sync operations
type SyncResponse struct {
	Success      bool                   `json:"success"`
	Message      string                 `json:"message"`
	SyncID       string                 `json:"sync_id"`
	ChangesCount int                    `json:"changes_count"`
	Conflicts    []ConflictInfo         `json:"conflicts,omitempty"`
	Metadata     map[string]interface{} `json:"metadata"`
	Timestamp    time.Time              `json:"timestamp"`
}

// ConflictInfo represents conflict information
type ConflictInfo struct {
	ID          string      `json:"id"`
	Type        string      `json:"type"`
	Description string      `json:"description"`
	LocalValue  interface{} `json:"local_value"`
	RemoteValue interface{} `json:"remote_value"`
	Resolution  string      `json:"resolution,omitempty"`
}

// NewRoadmapManagerConnector creates a new connector instance
func NewRoadmapManagerConnector(config *ConnectorConfig) *RoadmapManagerConnector {
	return &RoadmapManagerConnector{
		baseURL: config.BaseURL,
		httpClient: &http.Client{
			Timeout: config.Timeout,
		},
		auth:   NewAuthenticationManager(config),
		mapper: NewDataMapper(),
		logger: log.New(log.Writer(), "[RoadmapConnector] ", log.LstdFlags),
		config: config,
		stats:  &ConnectorStats{},
	}
}

// Initialize sets up the connector and validates connectivity
func (rmc *RoadmapManagerConnector) Initialize(ctx context.Context) error {
	rmc.logger.Printf("🔗 Initializing Roadmap Manager Connector to %s", rmc.baseURL)

	// Test connectivity
	if err := rmc.testConnectivity(ctx); err != nil {
		return fmt.Errorf("connectivity test failed: %w", err)
	}

	// Initialize authentication
	if err := rmc.auth.Initialize(ctx); err != nil {
		return fmt.Errorf("authentication initialization failed: %w", err)
	}

	// Validate API endpoints
	if err := rmc.validateAPIEndpoints(ctx); err != nil {
		return fmt.Errorf("API endpoint validation failed: %w", err)
	}

	rmc.logger.Printf("✅ Roadmap Manager Connector initialized successfully")
	return nil
}

// SyncPlanToRoadmapManager synchronizes a plan to the Roadmap Manager
func (rmc *RoadmapManagerConnector) SyncPlanToRoadmapManager(ctx context.Context, dynamicPlan interface{}) (*SyncResponse, error) {
	startTime := time.Now()
	rmc.stats.TotalRequests++

	rmc.logger.Printf("🔄 Starting sync to Roadmap Manager for plan")

	// Convert dynamic plan to roadmap format
	roadmapPlan, err := rmc.mapper.ConvertToRoadmapFormat(dynamicPlan)
	if err != nil {
		rmc.stats.FailedSyncs++
		return nil, fmt.Errorf("format conversion failed: %w", err)
	}

	// Send to Roadmap Manager
	response, err := rmc.sendPlanToRoadmapManager(ctx, roadmapPlan)
	if err != nil {
		rmc.stats.FailedSyncs++
		return nil, fmt.Errorf("sync to roadmap manager failed: %w", err)
	}

	// Update statistics
	duration := time.Since(startTime)
	rmc.updateStats(duration, true)

	rmc.logger.Printf("✅ Successfully synced plan to Roadmap Manager in %v", duration)
	return response, nil
}

// SyncFromRoadmapManager fetches updates from the Roadmap Manager
func (rmc *RoadmapManagerConnector) SyncFromRoadmapManager(ctx context.Context, planID string) (*RoadmapPlan, error) {
	startTime := time.Now()
	rmc.stats.TotalRequests++

	rmc.logger.Printf("🔄 Fetching plan %s from Roadmap Manager", planID)

	// Fetch plan from Roadmap Manager
	roadmapPlan, err := rmc.fetchPlanFromRoadmapManager(ctx, planID)
	if err != nil {
		rmc.stats.FailedSyncs++
		return nil, fmt.Errorf("fetch from roadmap manager failed: %w", err)
	}

	// Update statistics
	duration := time.Since(startTime)
	rmc.updateStats(duration, true)

	rmc.logger.Printf("✅ Successfully fetched plan from Roadmap Manager in %v", duration)
	return roadmapPlan, nil
}

// sendPlanToRoadmapManager sends a plan to the Roadmap Manager API
func (rmc *RoadmapManagerConnector) sendPlanToRoadmapManager(ctx context.Context, plan *RoadmapPlan) (*SyncResponse, error) {
	endpoint := fmt.Sprintf("%s/api/v1/plans", rmc.baseURL)

	// Prepare request payload
	payload, err := json.Marshal(plan)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal plan: %w", err)
	}

	// Create HTTP request
	req, err := http.NewRequestWithContext(ctx, "POST", endpoint, bytes.NewBuffer(payload))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	// Set headers
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")

	// Add authentication
	if err := rmc.auth.AddAuthHeaders(req); err != nil {
		return nil, fmt.Errorf("failed to add auth headers: %w", err)
	}

	// Send request
	resp, err := rmc.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	// Read response
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	// Check status code
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return nil, fmt.Errorf("API request failed with status %d: %s", resp.StatusCode, string(body))
	}

	// Parse response
	var syncResponse SyncResponse
	if err := json.Unmarshal(body, &syncResponse); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	return &syncResponse, nil
}

// fetchPlanFromRoadmapManager retrieves a plan from the Roadmap Manager API
func (rmc *RoadmapManagerConnector) fetchPlanFromRoadmapManager(ctx context.Context, planID string) (*RoadmapPlan, error) {
	endpoint := fmt.Sprintf("%s/api/v1/plans/%s", rmc.baseURL, url.QueryEscape(planID))

	// Create HTTP request
	req, err := http.NewRequestWithContext(ctx, "GET", endpoint, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	// Set headers
	req.Header.Set("Accept", "application/json")

	// Add authentication
	if err := rmc.auth.AddAuthHeaders(req); err != nil {
		return nil, fmt.Errorf("failed to add auth headers: %w", err)
	}

	// Send request
	resp, err := rmc.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	// Read response
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	// Check status code
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return nil, fmt.Errorf("API request failed with status %d: %s", resp.StatusCode, string(body))
	}

	// Parse response
	var plan RoadmapPlan
	if err := json.Unmarshal(body, &plan); err != nil {
		return nil, fmt.Errorf("failed to parse plan: %w", err)
	}

	return &plan, nil
}

// testConnectivity tests basic connectivity to the Roadmap Manager
func (rmc *RoadmapManagerConnector) testConnectivity(ctx context.Context) error {
	endpoint := fmt.Sprintf("%s/api/v1/health", rmc.baseURL)

	req, err := http.NewRequestWithContext(ctx, "GET", endpoint, nil)
	if err != nil {
		return fmt.Errorf("failed to create health check request: %w", err)
	}

	resp, err := rmc.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("health check request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("health check failed with status %d", resp.StatusCode)
	}

	return nil
}

// validateAPIEndpoints validates that required API endpoints are available
func (rmc *RoadmapManagerConnector) validateAPIEndpoints(ctx context.Context) error {
	endpoints := []string{
		"/api/v1/plans",
		"/api/v1/tasks",
		"/api/v1/sync",
	}

	for _, endpoint := range endpoints {
		url := fmt.Sprintf("%s%s", rmc.baseURL, endpoint)
		req, err := http.NewRequestWithContext(ctx, "OPTIONS", url, nil)
		if err != nil {
			return fmt.Errorf("failed to create validation request for %s: %w", endpoint, err)
		}

		resp, err := rmc.httpClient.Do(req)
		if err != nil {
			return fmt.Errorf("validation request failed for %s: %w", endpoint, err)
		}
		resp.Body.Close()

		if resp.StatusCode == http.StatusNotFound {
			return fmt.Errorf("required endpoint %s not found", endpoint)
		}
	}

	return nil
}

// updateStats updates connector statistics
func (rmc *RoadmapManagerConnector) updateStats(duration time.Duration, success bool) {
	if success {
		rmc.stats.SuccessfulSyncs++
	} else {
		rmc.stats.FailedSyncs++
	}

	// Update average latency
	total := rmc.stats.SuccessfulSyncs + rmc.stats.FailedSyncs
	if total > 0 {
		currentAvg := rmc.stats.AverageLatency
		rmc.stats.AverageLatency = time.Duration((int64(currentAvg)*(total-1) + int64(duration)) / total)
	}

	// Update error rate
	if total > 0 {
		rmc.stats.ErrorRate = float64(rmc.stats.FailedSyncs) / float64(total) * 100
	}

	rmc.stats.LastSyncTime = time.Now()
}

// GetStats returns current connector statistics
func (rmc *RoadmapManagerConnector) GetStats() *ConnectorStats {
	return rmc.stats
}

// Close cleanly shuts down the connector
func (rmc *RoadmapManagerConnector) Close() error {
	rmc.logger.Printf("🔌 Closing Roadmap Manager Connector")

	// Close HTTP client if needed
	if transport, ok := rmc.httpClient.Transport.(*http.Transport); ok {
		transport.CloseIdleConnections()
	}

	return nil
}
