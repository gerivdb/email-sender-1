package roadmapconnector

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

// APIAnalyzer analyzes existing Roadmap Manager API
type APIAnalyzer struct {
	baseURL    string
	httpClient *http.Client
	logger     Logger
}

// APIEndpoint represents an analyzed API endpoint
type APIEndpoint struct {
	Path        string            `json:"path"`
	Method      string            `json:"method"`
	Description string            `json:"description"`
	Parameters  []APIParameter    `json:"parameters"`
	Responses   []APIResponse     `json:"responses"`
	Headers     map[string]string `json:"headers"`
	Available   bool              `json:"available"`
	Version     string            `json:"version"`
	Deprecated  bool              `json:"deprecated"`
}

// APIParameter represents an API parameter
type APIParameter struct {
	Name        string      `json:"name"`
	Type        string      `json:"type"`
	Required    bool        `json:"required"`
	Description string      `json:"description"`
	Default     interface{} `json:"default,omitempty"`
	Example     interface{} `json:"example,omitempty"`
}

// APIResponse represents an API response
type APIResponse struct {
	StatusCode  int                    `json:"status_code"`
	Description string                 `json:"description"`
	Schema      map[string]interface{} `json:"schema,omitempty"`
	Example     interface{}            `json:"example,omitempty"`
}

// APIAnalysisResult contains the analysis results
type APIAnalysisResult struct {
	BaseURL    string                 `json:"base_url"`
	Version    string                 `json:"version"`
	Endpoints  []APIEndpoint          `json:"endpoints"`
	Schemas    map[string]interface{} `json:"schemas"`
	Security   SecurityInfo           `json:"security"`
	RateLimit  RateLimitInfo          `json:"rate_limit"`
	Features   []string               `json:"features"`
	AnalyzedAt time.Time              `json:"analyzed_at"`
	Compatible bool                   `json:"compatible"`
	Issues     []string               `json:"issues"`
}

// SecurityInfo represents security configuration
type SecurityInfo struct {
	AuthType     string   `json:"auth_type"`
	RequiredAuth bool     `json:"required_auth"`
	Schemes      []string `json:"schemes"`
	Scopes       []string `json:"scopes"`
}

// RateLimitInfo represents rate limiting information
type RateLimitInfo struct {
	Enabled           bool     `json:"enabled"`
	RequestsPerMinute int      `json:"requests_per_minute"`
	RequestsPerHour   int      `json:"requests_per_hour"`
	Headers           []string `json:"headers"`
}

// Logger interface for API analyzer
type Logger interface {
	Printf(format string, args ...interface{})
	Info(msg string)
	Error(msg string)
	Debug(msg string)
}

// NewAPIAnalyzer creates a new API analyzer
func NewAPIAnalyzer(baseURL string, logger Logger) *APIAnalyzer {
	return &APIAnalyzer{
		baseURL: strings.TrimRight(baseURL, "/"),
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
		logger: logger,
	}
}

// AnalyzeAPI performs comprehensive analysis of the Roadmap Manager API
func (aa *APIAnalyzer) AnalyzeAPI(ctx context.Context) (*APIAnalysisResult, error) {
	aa.logger.Printf("🔍 Starting API analysis for %s", aa.baseURL)

	result := &APIAnalysisResult{
		BaseURL:    aa.baseURL,
		AnalyzedAt: time.Now(),
		Compatible: true,
		Issues:     []string{},
		Features:   []string{},
	}

	// Analyze OpenAPI specification if available
	if err := aa.analyzeOpenAPISpec(ctx, result); err != nil {
		aa.logger.Printf("⚠️  OpenAPI spec analysis failed: %v", err)
		result.Issues = append(result.Issues, fmt.Sprintf("OpenAPI spec not available: %v", err))
	}

	// Discover endpoints by probing common paths
	if err := aa.discoverEndpoints(ctx, result); err != nil {
		aa.logger.Printf("⚠️  Endpoint discovery failed: %v", err)
		result.Issues = append(result.Issues, fmt.Sprintf("Endpoint discovery failed: %v", err))
	}

	// Analyze authentication requirements
	if err := aa.analyzeAuthentication(ctx, result); err != nil {
		aa.logger.Printf("⚠️  Authentication analysis failed: %v", err)
		result.Issues = append(result.Issues, fmt.Sprintf("Authentication analysis failed: %v", err))
	}

	// Analyze rate limiting
	if err := aa.analyzeRateLimit(ctx, result); err != nil {
		aa.logger.Printf("⚠️  Rate limit analysis failed: %v", err)
		result.Issues = append(result.Issues, fmt.Sprintf("Rate limit analysis failed: %v", err))
	}

	// Check compatibility with our requirements
	aa.checkCompatibility(result)

	aa.logger.Printf("✅ API analysis completed - Compatible: %v, Issues: %d",
		result.Compatible, len(result.Issues))

	return result, nil
}

// analyzeOpenAPISpec attempts to retrieve and analyze OpenAPI specification
func (aa *APIAnalyzer) analyzeOpenAPISpec(ctx context.Context, result *APIAnalysisResult) error {
	specPaths := []string{
		"/swagger.json",
		"/api/swagger.json",
		"/api/v1/swagger.json",
		"/openapi.json",
		"/api/openapi.json",
		"/api/v1/openapi.json",
		"/docs/swagger.json",
	}

	for _, path := range specPaths {
		url := fmt.Sprintf("%s%s", aa.baseURL, path)

		req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
		if err != nil {
			continue
		}

		req.Header.Set("Accept", "application/json")

		resp, err := aa.httpClient.Do(req)
		if err != nil {
			continue
		}
		defer resp.Body.Close()

		if resp.StatusCode == http.StatusOK {
			body, err := io.ReadAll(resp.Body)
			if err != nil {
				continue
			}

			var spec map[string]interface{}
			if err := json.Unmarshal(body, &spec); err != nil {
				continue
			}

			// Extract version
			if info, ok := spec["info"].(map[string]interface{}); ok {
				if version, ok := info["version"].(string); ok {
					result.Version = version
				}
			}

			// Extract endpoints
			if paths, ok := spec["paths"].(map[string]interface{}); ok {
				for path, pathData := range paths {
					if pathInfo, ok := pathData.(map[string]interface{}); ok {
						for method, methodData := range pathInfo {
							endpoint := aa.parseEndpointFromSpec(path, method, methodData)
							result.Endpoints = append(result.Endpoints, endpoint)
						}
					}
				}
			}

			// Extract schemas
			if components, ok := spec["components"].(map[string]interface{}); ok {
				if schemas, ok := components["schemas"].(map[string]interface{}); ok {
					result.Schemas = schemas
				}
			}

			result.Features = append(result.Features, "OpenAPI specification available")
			return nil
		}
	}

	return fmt.Errorf("no OpenAPI specification found")
}

// discoverEndpoints probes for common API endpoints
func (aa *APIAnalyzer) discoverEndpoints(ctx context.Context, result *APIAnalysisResult) error {
	commonEndpoints := []struct {
		path   string
		method string
		desc   string
	}{
		{"/api/v1/health", "GET", "Health check endpoint"},
		{"/api/v1/plans", "GET", "List plans"},
		{"/api/v1/plans", "POST", "Create plan"},
		{"/api/v1/plans/{id}", "GET", "Get plan by ID"},
		{"/api/v1/plans/{id}", "PUT", "Update plan"},
		{"/api/v1/plans/{id}", "DELETE", "Delete plan"},
		{"/api/v1/tasks", "GET", "List tasks"},
		{"/api/v1/tasks", "POST", "Create task"},
		{"/api/v1/tasks/{id}", "GET", "Get task by ID"},
		{"/api/v1/tasks/{id}", "PUT", "Update task"},
		{"/api/v1/sync", "POST", "Trigger synchronization"},
		{"/api/v1/status", "GET", "Get system status"},
		{"/api/v1/metrics", "GET", "Get metrics"},
	}

	for _, ep := range commonEndpoints {
		available := aa.probeEndpoint(ctx, ep.path, ep.method)

		endpoint := APIEndpoint{
			Path:        ep.path,
			Method:      ep.method,
			Description: ep.desc,
			Available:   available,
		}

		if available {
			result.Features = append(result.Features, fmt.Sprintf("%s %s available", ep.method, ep.path))
		}

		result.Endpoints = append(result.Endpoints, endpoint)
	}

	return nil
}

// probeEndpoint checks if an endpoint is available
func (aa *APIAnalyzer) probeEndpoint(ctx context.Context, path, method string) bool {
	url := fmt.Sprintf("%s%s", aa.baseURL, path)

	// Replace path parameters with placeholder values for testing
	url = strings.ReplaceAll(url, "{id}", "test-id")
	url = strings.ReplaceAll(url, "{planId}", "test-plan-id")

	req, err := http.NewRequestWithContext(ctx, method, url, nil)
	if err != nil {
		return false
	}

	resp, err := aa.httpClient.Do(req)
	if err != nil {
		return false
	}
	defer resp.Body.Close()

	// Consider endpoint available if it's not 404 Not Found
	return resp.StatusCode != http.StatusNotFound
}

// analyzeAuthentication determines authentication requirements
func (aa *APIAnalyzer) analyzeAuthentication(ctx context.Context, result *APIAnalysisResult) error {
	// Test various authentication methods
	authMethods := []string{
		"api-key",
		"bearer-token",
		"basic-auth",
		"oauth2",
	}

	// Probe health endpoint without auth
	healthURL := fmt.Sprintf("%s/api/v1/health", aa.baseURL)
	req, err := http.NewRequestWithContext(ctx, "GET", healthURL, nil)
	if err == nil {
		resp, err := aa.httpClient.Do(req)
		if err == nil {
			defer resp.Body.Close()

			if resp.StatusCode == http.StatusUnauthorized {
				result.Security.RequiredAuth = true

				// Check WWW-Authenticate header for auth type
				if authHeader := resp.Header.Get("WWW-Authenticate"); authHeader != "" {
					if strings.Contains(strings.ToLower(authHeader), "bearer") {
						result.Security.AuthType = "bearer"
					} else if strings.Contains(strings.ToLower(authHeader), "basic") {
						result.Security.AuthType = "basic"
					}
				}
			} else {
				result.Security.RequiredAuth = false
				result.Security.AuthType = "none"
			}
		}
	}

	result.Security.Schemes = authMethods
	return nil
}

// analyzeRateLimit determines rate limiting configuration
func (aa *APIAnalyzer) analyzeRateLimit(ctx context.Context, result *APIAnalysisResult) error {
	// Make a request to check for rate limit headers
	url := fmt.Sprintf("%s/api/v1/health", aa.baseURL)
	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return err
	}

	resp, err := aa.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	// Check for common rate limit headers
	rateLimitHeaders := []string{
		"X-RateLimit-Limit",
		"X-RateLimit-Remaining",
		"X-RateLimit-Reset",
		"RateLimit-Limit",
		"RateLimit-Remaining",
		"RateLimit-Reset",
	}

	foundHeaders := []string{}
	for _, header := range rateLimitHeaders {
		if value := resp.Header.Get(header); value != "" {
			foundHeaders = append(foundHeaders, header)
		}
	}

	if len(foundHeaders) > 0 {
		result.RateLimit.Enabled = true
		result.RateLimit.Headers = foundHeaders
		result.Features = append(result.Features, "Rate limiting detected")
	}

	return nil
}

// parseEndpointFromSpec parses endpoint information from OpenAPI spec
func (aa *APIAnalyzer) parseEndpointFromSpec(path, method string, methodData interface{}) APIEndpoint {
	endpoint := APIEndpoint{
		Path:   path,
		Method: strings.ToUpper(method),
	}

	if data, ok := methodData.(map[string]interface{}); ok {
		if summary, ok := data["summary"].(string); ok {
			endpoint.Description = summary
		}

		if deprecated, ok := data["deprecated"].(bool); ok {
			endpoint.Deprecated = deprecated
		}

		// Parse parameters
		if params, ok := data["parameters"].([]interface{}); ok {
			for _, param := range params {
				if paramData, ok := param.(map[string]interface{}); ok {
					apiParam := APIParameter{
						Name: paramData["name"].(string),
						Type: paramData["type"].(string),
					}
					if required, ok := paramData["required"].(bool); ok {
						apiParam.Required = required
					}
					endpoint.Parameters = append(endpoint.Parameters, apiParam)
				}
			}
		}
		// Parse responses
		if responses, ok := data["responses"].(map[string]interface{}); ok {
			for _, respData := range responses {
				if respInfo, ok := respData.(map[string]interface{}); ok {
					response := APIResponse{
						Description: respInfo["description"].(string),
					}
					endpoint.Responses = append(endpoint.Responses, response)
				}
			}
		}
	}

	return endpoint
}

// checkCompatibility checks if the API is compatible with our requirements
func (aa *APIAnalyzer) checkCompatibility(result *APIAnalysisResult) {
	requiredEndpoints := []string{
		"GET /api/v1/plans",
		"POST /api/v1/plans",
		"GET /api/v1/plans/{id}",
		"PUT /api/v1/plans/{id}",
		"GET /api/v1/tasks",
		"POST /api/v1/tasks",
	}

	availableEndpoints := make(map[string]bool)
	for _, endpoint := range result.Endpoints {
		key := fmt.Sprintf("%s %s", endpoint.Method, endpoint.Path)
		availableEndpoints[key] = endpoint.Available
	}

	missing := []string{}
	for _, required := range requiredEndpoints {
		if !availableEndpoints[required] {
			missing = append(missing, required)
		}
	}

	if len(missing) > 0 {
		result.Compatible = false
		for _, endpoint := range missing {
			result.Issues = append(result.Issues, fmt.Sprintf("Required endpoint not available: %s", endpoint))
		}
	}

	// Check API version compatibility
	if result.Version != "" && result.Version < "1.0" {
		result.Compatible = false
		result.Issues = append(result.Issues, fmt.Sprintf("API version %s may not be compatible", result.Version))
	}
}
