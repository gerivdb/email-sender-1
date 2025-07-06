package integration_manager

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/google/uuid"
	"github.com/sirupsen/logrus"

	"github.com/gerivdb/email-sender-1/development/managers/interfaces"
)

// ===== API Management =====

func (im *IntegrationManagerImpl) RegisterAPI(ctx context.Context, api *interfaces.APIEndpoint) error {
	if api == nil {
		return fmt.Errorf("api endpoint cannot be nil")
	}

	im.mutex.Lock()
	defer im.mutex.Unlock()

	// Generate ID if not provided
	if api.ID == "" {
		api.ID = uuid.New().String()
	}

	// Check if API already exists
	if _, exists := im.apis[api.ID]; exists {
		return fmt.Errorf("API endpoint with ID %s already exists", api.ID)
	}

	// Validate API endpoint
	if err := im.validateAPIEndpoint(api); err != nil {
		return fmt.Errorf("invalid API endpoint: %w", err)
	}

	// Set timestamps and defaults
	now := time.Now()
	api.CreatedAt = now
	api.UpdatedAt = now

	if api.Timeout == 0 {
		api.Timeout = 30 * time.Second
	}
	if api.RetryCount == 0 {
		api.RetryCount = 3
	}

	// Store API endpoint
	im.apis[api.ID] = api

	// Initialize API status
	im.apiStatuses[api.ID] = &interfaces.APIStatus{
		IsAvailable:  false,
		LastCheck:    time.Now(),
		ResponseTime: 0,
		ErrorCount:   0,
		SuccessCount: 0,
		SuccessRate:  0,
	}

	im.logger.WithFields(logrus.Fields{
		"api_id":   api.ID,
		"api_name": api.Name,
		"api_url":  api.URL,
		"method":   api.Method,
	}).Info("API endpoint registered successfully")

	return nil
}

func (im *IntegrationManagerImpl) UpdateAPI(ctx context.Context, apiID string, api *interfaces.APIEndpoint) error {
	if api == nil {
		return fmt.Errorf("api endpoint cannot be nil")
	}

	im.mutex.Lock()
	defer im.mutex.Unlock()

	// Check if API exists
	existing, exists := im.apis[apiID]
	if !exists {
		return fmt.Errorf("API endpoint with ID %s not found", apiID)
	}

	// Validate API endpoint
	if err := im.validateAPIEndpoint(api); err != nil {
		return fmt.Errorf("invalid API endpoint: %w", err)
	}

	// Preserve original ID and creation time
	api.ID = apiID
	api.CreatedAt = existing.CreatedAt
	api.UpdatedAt = time.Now()

	// Update API endpoint
	im.apis[apiID] = api

	im.logger.WithFields(logrus.Fields{
		"api_id":   apiID,
		"api_name": api.Name,
	}).Info("API endpoint updated successfully")

	return nil
}

func (im *IntegrationManagerImpl) DeactivateAPI(ctx context.Context, apiID string) error {
	im.mutex.Lock()
	defer im.mutex.Unlock()

	// Check if API exists
	api, exists := im.apis[apiID]
	if !exists {
		return fmt.Errorf("API endpoint with ID %s not found", apiID)
	}

	// Deactivate API
	api.IsActive = false
	api.UpdatedAt = time.Now()

	im.logger.WithField("api_id", apiID).Info("API endpoint deactivated successfully")

	return nil
}

func (im *IntegrationManagerImpl) CallAPI(ctx context.Context, apiID string, request *interfaces.APIRequest) (*interfaces.APIResponse, error) {
	im.mutex.RLock()
	api, exists := im.apis[apiID]
	im.mutex.RUnlock()

	if !exists {
		return nil, fmt.Errorf("API endpoint with ID %s not found", apiID)
	}

	if !api.IsActive {
		return nil, fmt.Errorf("API endpoint %s is not active", apiID)
	}

	startTime := time.Now()

	// Build request
	httpReq, err := im.buildHTTPRequest(ctx, api, request)
	if err != nil {
		im.updateAPIStats(apiID, false, 0)
		return nil, fmt.Errorf("failed to build HTTP request: %w", err)
	}

	// Execute request with retries
	var resp *http.Response
	var lastErr error

	for attempt := 0; attempt <= api.RetryCount; attempt++ {
		if attempt > 0 {
			im.logger.WithFields(logrus.Fields{
				"api_id":  apiID,
				"attempt": attempt,
			}).Warn("Retrying API call")

			// Wait before retry with exponential backoff
			backoff := time.Duration(attempt) * time.Second
			time.Sleep(backoff)
		}

		resp, lastErr = im.httpClient.Do(httpReq)
		if lastErr == nil {
			break
		}
	}

	if lastErr != nil {
		im.updateAPIStats(apiID, false, time.Since(startTime))
		return nil, fmt.Errorf("API call failed after %d retries: %w", api.RetryCount, lastErr)
	}

	defer resp.Body.Close()

	// Read response body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		im.updateAPIStats(apiID, false, time.Since(startTime))
		return nil, fmt.Errorf("failed to read response body: %w", err)
	}

	duration := time.Since(startTime)
	success := resp.StatusCode >= 200 && resp.StatusCode < 300

	// Update API statistics
	im.updateAPIStats(apiID, success, duration)

	// Update last called time
	im.mutex.Lock()
	now := time.Now()
	api.LastCalled = &now
	im.mutex.Unlock()

	// Parse response body
	var responseBody interface{}
	if len(body) > 0 {
		if err := json.Unmarshal(body, &responseBody); err != nil {
			// If JSON parsing fails, store as string
			responseBody = string(body)
		}
	}

	// Build API response
	apiResponse := &interfaces.APIResponse{
		StatusCode: resp.StatusCode,
		Body:       responseBody,
		Headers:    make(map[string]string),
		Duration:   duration,
		Timestamp:  startTime,
	}

	// Copy response headers
	for key, values := range resp.Header {
		if len(values) > 0 {
			apiResponse.Headers[key] = values[0]
		}
	}

	im.logger.WithFields(logrus.Fields{
		"api_id":      apiID,
		"status_code": resp.StatusCode,
		"duration":    duration,
		"success":     success,
	}).Info("API call completed")

	return apiResponse, nil
}

func (im *IntegrationManagerImpl) GetAPIStatus(ctx context.Context, apiID string) (*interfaces.APIStatus, error) {
	im.mutex.RLock()
	defer im.mutex.RUnlock()

	status, exists := im.apiStatuses[apiID]
	if !exists {
		return nil, fmt.Errorf("API status for ID %s not found", apiID)
	}

	// Return a copy to prevent external modification
	statusCopy := *status
	return &statusCopy, nil
}

// ===== Helper Methods for API Management =====

func (im *IntegrationManagerImpl) validateAPIEndpoint(api *interfaces.APIEndpoint) error {
	if api.Name == "" {
		return fmt.Errorf("API name is required")
	}

	if api.URL == "" {
		return fmt.Errorf("API URL is required")
	}

	if api.Method == "" {
		return fmt.Errorf("API method is required")
	}

	// Validate HTTP method
	validMethods := []string{"GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"}
	methodValid := false
	for _, validMethod := range validMethods {
		if api.Method == validMethod {
			methodValid = true
			break
		}
	}

	if !methodValid {
		return fmt.Errorf("invalid HTTP method: %s", api.Method)
	}

	return nil
}

func (im *IntegrationManagerImpl) buildHTTPRequest(ctx context.Context, api *interfaces.APIEndpoint, request *interfaces.APIRequest) (*http.Request, error) {
	var body io.Reader

	// Handle request body
	if request != nil && request.Body != nil {
		bodyBytes, err := json.Marshal(request.Body)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal request body: %w", err)
		}
		body = bytes.NewReader(bodyBytes)
	}

	// Create HTTP request
	httpReq, err := http.NewRequestWithContext(ctx, api.Method, api.URL, body)
	if err != nil {
		return nil, fmt.Errorf("failed to create HTTP request: %w", err)
	}

	// Set default headers
	if body != nil {
		httpReq.Header.Set("Content-Type", "application/json")
	}
	httpReq.Header.Set("User-Agent", "Integration-Manager/1.0.0")

	// Set API endpoint headers
	if api.Headers != nil {
		for key, value := range api.Headers {
			httpReq.Header.Set(key, value)
		}
	}

	// Set request headers
	if request != nil && request.Headers != nil {
		for key, value := range request.Headers {
			httpReq.Header.Set(key, value)
		}
	}

	// Handle authentication
	if api.Auth != nil {
		if err := im.setAuthentication(httpReq, api.Auth); err != nil {
			return nil, fmt.Errorf("failed to set authentication: %w", err)
		}
	}

	// Handle query parameters
	if request != nil && request.Params != nil {
		q := httpReq.URL.Query()
		for key, value := range request.Params {
			q.Add(key, value)
		}
		httpReq.URL.RawQuery = q.Encode()
	}

	return httpReq, nil
}

func (im *IntegrationManagerImpl) setAuthentication(req *http.Request, auth *interfaces.APIAuth) error {
	switch auth.Type {
	case "bearer":
		if token, ok := auth.Config["token"].(string); ok {
			req.Header.Set("Authorization", "Bearer "+token)
		} else {
			return fmt.Errorf("bearer token not found in auth config")
		}
	case "basic":
		if username, ok := auth.Config["username"].(string); ok {
			if password, ok := auth.Config["password"].(string); ok {
				req.SetBasicAuth(username, password)
			} else {
				return fmt.Errorf("password not found in auth config")
			}
		} else {
			return fmt.Errorf("username not found in auth config")
		}
	case "api_key":
		if key, ok := auth.Config["key"].(string); ok {
			if header, ok := auth.Config["header"].(string); ok {
				req.Header.Set(header, key)
			} else {
				req.Header.Set("X-API-Key", key)
			}
		} else {
			return fmt.Errorf("API key not found in auth config")
		}
	default:
		return fmt.Errorf("unsupported authentication type: %s", auth.Type)
	}

	return nil
}

func (im *IntegrationManagerImpl) updateAPIStats(apiID string, success bool, duration time.Duration) {
	im.mutex.Lock()
	defer im.mutex.Unlock()

	status, exists := im.apiStatuses[apiID]
	if !exists {
		return
	}

	status.LastCheck = time.Now()
	status.ResponseTime = duration

	if success {
		status.SuccessCount++
		status.IsAvailable = true
	} else {
		status.ErrorCount++
		status.IsAvailable = false
	}

	// Calculate success rate
	totalCalls := status.SuccessCount + status.ErrorCount
	if totalCalls > 0 {
		status.SuccessRate = float64(status.SuccessCount) / float64(totalCalls) * 100
	}
}

// ===== API Health Checking =====

func (im *IntegrationManagerImpl) checkAPIHealth(ctx context.Context) {
	im.mutex.RLock()
	apis := make([]*interfaces.APIEndpoint, 0, len(im.apis))
	for _, api := range im.apis {
		if api.IsActive {
			apis = append(apis, api)
		}
	}
	im.mutex.RUnlock()

	for _, api := range apis {
		go im.performHealthCheck(ctx, api)
	}
}

func (im *IntegrationManagerImpl) performHealthCheck(ctx context.Context, api *interfaces.APIEndpoint) {
	startTime := time.Now()

	// Create a simple GET request for health check
	req, err := http.NewRequestWithContext(ctx, "GET", api.URL, nil)
	if err != nil {
		im.updateAPIStats(api.ID, false, time.Since(startTime))
		return
	}

	// Set authentication if required
	if api.Auth != nil {
		if err := im.setAuthentication(req, api.Auth); err != nil {
			im.updateAPIStats(api.ID, false, time.Since(startTime))
			return
		}
	}

	// Set headers
	if api.Headers != nil {
		for key, value := range api.Headers {
			req.Header.Set(key, value)
		}
	}

	// Perform request
	resp, err := im.httpClient.Do(req)
	if err != nil {
		im.updateAPIStats(api.ID, false, time.Since(startTime))
		return
	}
	defer resp.Body.Close()

	duration := time.Since(startTime)
	success := resp.StatusCode >= 200 && resp.StatusCode < 500 // 5xx errors indicate server issues

	im.updateAPIStats(api.ID, success, duration)

	im.logger.WithFields(logrus.Fields{
		"api_id":      api.ID,
		"api_name":    api.Name,
		"status_code": resp.StatusCode,
		"duration":    duration,
		"success":     success,
	}).Debug("API health check completed")
}
