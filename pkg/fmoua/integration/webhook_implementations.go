// Package integration provides webhook implementation components
package integration

import (
	"bytes"
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"crypto/tls"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"sync"
	"time"

	"go.uber.org/zap"

	"email_sender/pkg/fmoua/types"
)

// HTTPWebhookServer implements WebhookServer interface using HTTP
type HTTPWebhookServer struct {
	config   types.WebhookServerConfig
	server   *http.Server
	mux      *http.ServeMux
	logger   *zap.Logger
	stats    WebhookServerStats
	statsMu  sync.RWMutex
}

// NewHTTPWebhookServer creates a new HTTP webhook server
func NewHTTPWebhookServer(config types.WebhookServerConfig, logger *zap.Logger) *HTTPWebhookServer {
	mux := http.NewServeMux()
	
	server := &http.Server{
		Addr:         fmt.Sprintf("%s:%d", config.Host, config.Port),
		Handler:      mux,
		ReadTimeout:  config.ReadTimeout,
		WriteTimeout: config.WriteTimeout,
		IdleTimeout:  config.IdleTimeout,
	}

	if config.TLS && config.CertFile != "" && config.KeyFile != "" {
		server.TLSConfig = &tls.Config{
			MinVersion: tls.VersionTLS12,
		}
	}

	return &HTTPWebhookServer{
		config: config,
		server: server,
		mux:    mux,
		logger: logger,
		stats:  WebhookServerStats{},
	}
}

// Start starts the webhook server
func (s *HTTPWebhookServer) Start(ctx context.Context) error {
	go func() {
		var err error
		if s.config.TLS && s.config.CertFile != "" && s.config.KeyFile != "" {
			err = s.server.ListenAndServeTLS(s.config.CertFile, s.config.KeyFile)
		} else {
			err = s.server.ListenAndServe()
		}
		
		if err != nil && err != http.ErrServerClosed {
			s.logger.Error("Webhook server error", zap.Error(err))
		}
	}()

	s.logger.Info("Webhook server started", 
		zap.String("address", s.server.Addr),
		zap.Bool("tls", s.config.TLS))
	
	return nil
}

// Stop stops the webhook server
func (s *HTTPWebhookServer) Stop(ctx context.Context) error {
	return s.server.Shutdown(ctx)
}

// RegisterHandler registers a webhook handler for a specific path
func (s *HTTPWebhookServer) RegisterHandler(path string, handler http.HandlerFunc) {
	wrappedHandler := s.wrapHandler(handler)
	s.mux.HandleFunc(path, wrappedHandler)
	
	s.statsMu.Lock()
	s.stats.ActiveHandlers++
	s.statsMu.Unlock()
	
	s.logger.Info("Webhook handler registered", zap.String("path", path))
}

// GetStats returns server statistics
func (s *HTTPWebhookServer) GetStats() WebhookServerStats {
	s.statsMu.RLock()
	defer s.statsMu.RUnlock()
	return s.stats
}

func (s *HTTPWebhookServer) wrapHandler(handler http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		
		s.statsMu.Lock()
		s.stats.RequestsTotal++
		s.stats.LastRequest = start
		s.statsMu.Unlock()

		// Create response writer wrapper to capture status
		wrapper := &responseWriter{ResponseWriter: w, statusCode: 200}
		
		defer func() {
			duration := time.Since(start)
			
			s.statsMu.Lock()
			if wrapper.statusCode >= 200 && wrapper.statusCode < 300 {
				s.stats.RequestsSuccess++
			} else {
				s.stats.RequestsError++
			}
			
			// Update average latency
			totalRequests := s.stats.RequestsTotal
			s.stats.AverageLatency = (s.stats.AverageLatency*float64(totalRequests-1) + 
				duration.Seconds()*1000) / float64(totalRequests)
			s.statsMu.Unlock()
		}()

		handler(wrapper, r)
	}
}

type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}

// HTTPWebhookClient implements WebhookClient interface using HTTP
type HTTPWebhookClient struct {
	config     types.WebhookClientConfig
	httpClient *http.Client
	logger     *zap.Logger
	stats      WebhookClientStats
	statsMu    sync.RWMutex
}

// NewHTTPWebhookClient creates a new HTTP webhook client
func NewHTTPWebhookClient(config types.WebhookClientConfig, logger *zap.Logger) *HTTPWebhookClient {
	httpClient := &http.Client{
		Timeout: config.Timeout,
		Transport: &http.Transport{
			MaxIdleConns:        100,
			MaxIdleConnsPerHost: 10,
			IdleConnTimeout:     90 * time.Second,
		},
	}

	return &HTTPWebhookClient{
		config:     config,
		httpClient: httpClient,
		logger:     logger,
		stats:      WebhookClientStats{},
	}
}

// Send sends a webhook synchronously
func (c *HTTPWebhookClient) Send(ctx context.Context, endpoint *WebhookEndpoint, payload []byte) (*WebhookDelivery, error) {
	delivery := &WebhookDelivery{
		ID:          generateWebhookID(),
		EndpointID:  endpoint.ID,
		Status:      "pending",
		Attempts:    0,
		LastAttempt: time.Now(),
	}

	var lastErr error
	for attempt := 1; attempt <= endpoint.MaxRetries; attempt++ {
		delivery.Attempts = attempt
		delivery.LastAttempt = time.Now()

		start := time.Now()
		err := c.sendRequest(ctx, endpoint, payload, delivery)
		delivery.Duration = time.Since(start)

		if err == nil {
			delivery.Status = "success"
			c.recordDelivery(true, delivery.Duration)
			return delivery, nil
		}

		lastErr = err
		delivery.Error = err.Error()

		if attempt < endpoint.MaxRetries {
			// Calculate retry delay with exponential backoff
			retryDelay := endpoint.RetryDelay * time.Duration(attempt)
			if retryDelay > c.config.MaxRetryDelay {
				retryDelay = c.config.MaxRetryDelay
			}
			
			delivery.NextAttempt = time.Now().Add(retryDelay)
			delivery.Status = "retrying"
			
			select {
			case <-time.After(retryDelay):
				continue
			case <-ctx.Done():
				delivery.Status = "failed"
				delivery.Error = "context cancelled"
				c.recordDelivery(false, delivery.Duration)
				return delivery, ctx.Err()
			}
		}
	}

	delivery.Status = "failed"
	c.recordDelivery(false, delivery.Duration)
	return delivery, lastErr
}

// SendAsync sends a webhook asynchronously
func (c *HTTPWebhookClient) SendAsync(ctx context.Context, endpoint *WebhookEndpoint, payload []byte) error {
	go func() {
		_, err := c.Send(ctx, endpoint, payload)
		if err != nil {
			c.logger.Error("Async webhook delivery failed", 
				zap.String("endpoint_id", endpoint.ID),
				zap.String("url", endpoint.URL),
				zap.Error(err))
		}
	}()
	return nil
}

// GetStats returns client statistics
func (c *HTTPWebhookClient) GetStats() WebhookClientStats {
	c.statsMu.RLock()
	defer c.statsMu.RUnlock()
	return c.stats
}

func (c *HTTPWebhookClient) sendRequest(ctx context.Context, endpoint *WebhookEndpoint, payload []byte, delivery *WebhookDelivery) error {
	req, err := http.NewRequestWithContext(ctx, endpoint.Method, endpoint.URL, bytes.NewReader(payload))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	// Set headers
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("User-Agent", "FMOUA-WebhookManager/1.0")
	
	for key, value := range endpoint.Headers {
		req.Header.Set(key, value)
	}

	// Add authentication headers if secret is provided
	if endpoint.Secret != "" {
		auth := NewHMACWebhookAuthenticator()
		authHeaders := auth.GetHeaders(payload, endpoint.Secret)
		for key, value := range authHeaders {
			req.Header.Set(key, value)
		}
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	delivery.StatusCode = resp.StatusCode

	// Read response body
	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		delivery.Response = "failed to read response"
	} else {
		delivery.Response = string(respBody)
	}

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("webhook request failed with status %d: %s", resp.StatusCode, delivery.Response)
	}

	return nil
}

func (c *HTTPWebhookClient) recordDelivery(success bool, duration time.Duration) {
	c.statsMu.Lock()
	defer c.statsMu.Unlock()

	c.stats.DeliveriesTotal++
	c.stats.LastDelivery = time.Now()

	if success {
		c.stats.DeliveriesSuccess++
	} else {
		c.stats.DeliveriesFailed++
	}

	// Update average latency
	total := c.stats.DeliveriesTotal
	c.stats.AverageLatency = (c.stats.AverageLatency*float64(total-1) + 
		duration.Seconds()*1000) / float64(total)
}

// JSONWebhookTransformer implements WebhookTransformer for JSON payloads
type JSONWebhookTransformer struct{}

// NewJSONWebhookTransformer creates a new JSON webhook transformer
func NewJSONWebhookTransformer() *JSONWebhookTransformer {
	return &JSONWebhookTransformer{}
}

// Transform transforms a webhook event to JSON payload
func (t *JSONWebhookTransformer) Transform(event *WebhookEvent, endpoint *WebhookEndpoint) ([]byte, error) {
	payload := map[string]interface{}{
		"id":        event.ID,
		"type":      event.Type,
		"source":    event.Source,
		"timestamp": event.Timestamp.Format(time.RFC3339),
		"data":      event.Data,
	}

	if len(event.Headers) > 0 {
		payload["headers"] = event.Headers
	}

	return json.Marshal(payload)
}

// GetContentType returns the content type for JSON payloads
func (t *JSONWebhookTransformer) GetContentType() string {
	return "application/json"
}

// HMACWebhookAuthenticator implements WebhookAuthenticator using HMAC-SHA256
type HMACWebhookAuthenticator struct{}

// NewHMACWebhookAuthenticator creates a new HMAC webhook authenticator
func NewHMACWebhookAuthenticator() *HMACWebhookAuthenticator {
	return &HMACWebhookAuthenticator{}
}

// Sign signs a payload using HMAC-SHA256
func (a *HMACWebhookAuthenticator) Sign(payload []byte, secret string) (string, error) {
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write(payload)
	signature := hex.EncodeToString(mac.Sum(nil))
	return fmt.Sprintf("sha256=%s", signature), nil
}

// Verify verifies a payload signature using HMAC-SHA256
func (a *HMACWebhookAuthenticator) Verify(payload []byte, signature string, secret string) bool {
	expectedSignature, err := a.Sign(payload, secret)
	if err != nil {
		return false
	}
	return hmac.Equal([]byte(signature), []byte(expectedSignature))
}

// GetHeaders returns authentication headers for a payload
func (a *HMACWebhookAuthenticator) GetHeaders(payload []byte, secret string) map[string]string {
	signature, err := a.Sign(payload, secret)
	if err != nil {
		return map[string]string{}
	}

	return map[string]string{
		"X-Webhook-Signature": signature,
		"X-Webhook-Timestamp": fmt.Sprintf("%d", time.Now().Unix()),
	}
}
