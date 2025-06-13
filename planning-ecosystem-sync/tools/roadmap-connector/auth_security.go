package roadmapconnector

import (
	"context"
	"crypto/tls"
	"encoding/base64"
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"
)

// AuthenticationManager handles authentication with the Roadmap Manager
type AuthenticationManager struct {
	config      *ConnectorConfig
	credentials *Credentials
	tokenCache  *TokenCache
	logger      Logger
}

// Credentials stores authentication credentials
type Credentials struct {
	Type          AuthType          `yaml:"type"`
	APIKey        string            `yaml:"api_key,omitempty"`
	Username      string            `yaml:"username,omitempty"`
	Password      string            `yaml:"password,omitempty"`
	BearerToken   string            `yaml:"bearer_token,omitempty"`
	OAuth2        *OAuth2Config     `yaml:"oauth2,omitempty"`
	CustomHeaders map[string]string `yaml:"custom_headers,omitempty"`
	TLS           *TLSConfig        `yaml:"tls,omitempty"`
}

// AuthType represents different authentication types
type AuthType string

const (
	AuthTypeNone   AuthType = "none"
	AuthTypeAPIKey AuthType = "api_key"
	AuthTypeBasic  AuthType = "basic"
	AuthTypeBearer AuthType = "bearer"
	AuthTypeOAuth2 AuthType = "oauth2"
	AuthTypeCustom AuthType = "custom"
)

// OAuth2Config contains OAuth2 configuration
type OAuth2Config struct {
	ClientID     string   `yaml:"client_id"`
	ClientSecret string   `yaml:"client_secret"`
	TokenURL     string   `yaml:"token_url"`
	Scopes       []string `yaml:"scopes"`
	GrantType    string   `yaml:"grant_type"`
}

// TLSConfig contains TLS configuration
type TLSConfig struct {
	InsecureSkipVerify bool   `yaml:"insecure_skip_verify"`
	CertFile           string `yaml:"cert_file,omitempty"`
	KeyFile            string `yaml:"key_file,omitempty"`
	CAFile             string `yaml:"ca_file,omitempty"`
}

// TokenCache stores authentication tokens
type TokenCache struct {
	AccessToken  string    `json:"access_token"`
	RefreshToken string    `json:"refresh_token,omitempty"`
	TokenType    string    `json:"token_type"`
	ExpiresAt    time.Time `json:"expires_at"`
	Scopes       []string  `json:"scopes,omitempty"`
}

// SecurityValidator validates security configurations
type SecurityValidator struct {
	config *SecurityConfig
	logger Logger
}

// SecurityConfig defines security requirements
type SecurityConfig struct {
	RequireHTTPS         bool     `yaml:"require_https"`
	AllowedCipherSuites  []string `yaml:"allowed_cipher_suites"`
	MinTLSVersion        string   `yaml:"min_tls_version"`
	MaxRequestSize       int64    `yaml:"max_request_size"`
	RateLimitByIP        bool     `yaml:"rate_limit_by_ip"`
	AllowedOrigins       []string `yaml:"allowed_origins"`
	RequiredHeaders      []string `yaml:"required_headers"`
	SensitiveDataMasking bool     `yaml:"sensitive_data_masking"`
}

// NewAuthenticationManager creates a new authentication manager
func NewAuthenticationManager(config *ConnectorConfig) *AuthenticationManager {
	return &AuthenticationManager{
		config:      config,
		credentials: loadCredentialsFromEnv(),
		tokenCache:  &TokenCache{},
		logger:      &DefaultLogger{},
	}
}

// Initialize sets up authentication
func (am *AuthenticationManager) Initialize(ctx context.Context) error {
	am.logger.Printf("🔐 Initializing authentication manager")

	// Validate credentials
	if err := am.validateCredentials(); err != nil {
		return fmt.Errorf("credential validation failed: %w", err)
	}

	// Setup TLS configuration if specified
	if am.credentials.TLS != nil {
		if err := am.configureTLS(); err != nil {
			return fmt.Errorf("TLS configuration failed: %w", err)
		}
	}

	// Perform initial authentication based on type
	switch am.credentials.Type {
	case AuthTypeOAuth2:
		if err := am.authenticateOAuth2(ctx); err != nil {
			return fmt.Errorf("OAuth2 authentication failed: %w", err)
		}
	case AuthTypeBearer:
		if err := am.validateBearerToken(ctx); err != nil {
			return fmt.Errorf("bearer token validation failed: %w", err)
		}
	case AuthTypeAPIKey:
		if err := am.validateAPIKey(ctx); err != nil {
			return fmt.Errorf("API key validation failed: %w", err)
		}
	}

	am.logger.Printf("✅ Authentication manager initialized successfully")
	return nil
}

// AddAuthHeaders adds authentication headers to HTTP request
func (am *AuthenticationManager) AddAuthHeaders(req *http.Request) error {
	switch am.credentials.Type {
	case AuthTypeNone:
		// No authentication required
		return nil

	case AuthTypeAPIKey:
		if am.credentials.APIKey == "" {
			return fmt.Errorf("API key not configured")
		}
		req.Header.Set("X-API-Key", am.credentials.APIKey)

	case AuthTypeBasic:
		if am.credentials.Username == "" || am.credentials.Password == "" {
			return fmt.Errorf("username and password required for basic auth")
		}
		auth := base64.StdEncoding.EncodeToString(
			[]byte(am.credentials.Username + ":" + am.credentials.Password))
		req.Header.Set("Authorization", "Basic "+auth)

	case AuthTypeBearer:
		token := am.credentials.BearerToken
		if am.tokenCache.AccessToken != "" && time.Now().Before(am.tokenCache.ExpiresAt) {
			token = am.tokenCache.AccessToken
		}
		if token == "" {
			return fmt.Errorf("bearer token not available")
		}
		req.Header.Set("Authorization", "Bearer "+token)

	case AuthTypeOAuth2:
		if am.tokenCache.AccessToken == "" || time.Now().After(am.tokenCache.ExpiresAt) {
			if err := am.refreshOAuth2Token(); err != nil {
				return fmt.Errorf("failed to refresh OAuth2 token: %w", err)
			}
		}
		req.Header.Set("Authorization", "Bearer "+am.tokenCache.AccessToken)

	case AuthTypeCustom:
		for key, value := range am.credentials.CustomHeaders {
			req.Header.Set(key, value)
		}

	default:
		return fmt.Errorf("unsupported authentication type: %s", am.credentials.Type)
	}

	// Add common security headers
	req.Header.Set("User-Agent", "PlanningEcosystem-Sync/1.0")
	req.Header.Set("Accept", "application/json")

	return nil
}

// validateCredentials checks if credentials are properly configured
func (am *AuthenticationManager) validateCredentials() error {
	if am.credentials == nil {
		return fmt.Errorf("credentials not configured")
	}

	switch am.credentials.Type {
	case AuthTypeAPIKey:
		if am.credentials.APIKey == "" {
			return fmt.Errorf("API key is required but not provided")
		}

	case AuthTypeBasic:
		if am.credentials.Username == "" || am.credentials.Password == "" {
			return fmt.Errorf("username and password are required for basic auth")
		}

	case AuthTypeBearer:
		if am.credentials.BearerToken == "" {
			return fmt.Errorf("bearer token is required but not provided")
		}

	case AuthTypeOAuth2:
		if am.credentials.OAuth2 == nil {
			return fmt.Errorf("OAuth2 configuration is required")
		}
		if am.credentials.OAuth2.ClientID == "" || am.credentials.OAuth2.ClientSecret == "" {
			return fmt.Errorf("OAuth2 client ID and secret are required")
		}
		if am.credentials.OAuth2.TokenURL == "" {
			return fmt.Errorf("OAuth2 token URL is required")
		}

	case AuthTypeCustom:
		if len(am.credentials.CustomHeaders) == 0 {
			return fmt.Errorf("custom headers are required for custom auth")
		}
	}

	return nil
}

// configureTLS sets up TLS configuration
func (am *AuthenticationManager) configureTLS() error {
	tlsConfig := &tls.Config{
		InsecureSkipVerify: am.credentials.TLS.InsecureSkipVerify,
	}

	// Set minimum TLS version
	switch am.credentials.TLS.CAFile {
	case "1.2":
		tlsConfig.MinVersion = tls.VersionTLS12
	case "1.3":
		tlsConfig.MinVersion = tls.VersionTLS13
	default:
		tlsConfig.MinVersion = tls.VersionTLS12
	}

	// Load client certificates if specified
	if am.credentials.TLS.CertFile != "" && am.credentials.TLS.KeyFile != "" {
		cert, err := tls.LoadX509KeyPair(am.credentials.TLS.CertFile, am.credentials.TLS.KeyFile)
		if err != nil {
			return fmt.Errorf("failed to load client certificate: %w", err)
		}
		tlsConfig.Certificates = []tls.Certificate{cert}
	}

	return nil
}

// authenticateOAuth2 performs OAuth2 authentication
func (am *AuthenticationManager) authenticateOAuth2(ctx context.Context) error {
	oauth := am.credentials.OAuth2

	// Prepare token request
	data := fmt.Sprintf("grant_type=%s&client_id=%s&client_secret=%s",
		oauth.GrantType, oauth.ClientID, oauth.ClientSecret)

	if len(oauth.Scopes) > 0 {
		data += "&scope=" + strings.Join(oauth.Scopes, " ")
	}

	req, err := http.NewRequestWithContext(ctx, "POST", oauth.TokenURL,
		strings.NewReader(data))
	if err != nil {
		return fmt.Errorf("failed to create token request: %w", err)
	}

	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("token request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("token request failed with status %d", resp.StatusCode)
	}

	// Parse token response (simplified - would need proper JSON parsing)
	am.tokenCache.AccessToken = "oauth2_token_placeholder"
	am.tokenCache.TokenType = "Bearer"
	am.tokenCache.ExpiresAt = time.Now().Add(1 * time.Hour)

	return nil
}

// validateBearerToken validates the bearer token
func (am *AuthenticationManager) validateBearerToken(ctx context.Context) error {
	// Create a test request to validate the token
	testURL := fmt.Sprintf("%s/api/v1/health", am.config.BaseURL)
	req, err := http.NewRequestWithContext(ctx, "GET", testURL, nil)
	if err != nil {
		return fmt.Errorf("failed to create validation request: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+am.credentials.BearerToken)

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("token validation request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusUnauthorized {
		return fmt.Errorf("bearer token is invalid")
	}

	return nil
}

// validateAPIKey validates the API key
func (am *AuthenticationManager) validateAPIKey(ctx context.Context) error {
	testURL := fmt.Sprintf("%s/api/v1/health", am.config.BaseURL)
	req, err := http.NewRequestWithContext(ctx, "GET", testURL, nil)
	if err != nil {
		return fmt.Errorf("failed to create validation request: %w", err)
	}

	req.Header.Set("X-API-Key", am.credentials.APIKey)

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("API key validation request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusUnauthorized {
		return fmt.Errorf("API key is invalid")
	}

	return nil
}

// refreshOAuth2Token refreshes the OAuth2 access token
func (am *AuthenticationManager) refreshOAuth2Token() error {
	if am.tokenCache.RefreshToken == "" {
		return am.authenticateOAuth2(context.Background())
	}

	// Implement refresh token logic here
	// For now, just re-authenticate
	return am.authenticateOAuth2(context.Background())
}

// loadCredentialsFromEnv loads credentials from environment variables
func loadCredentialsFromEnv() *Credentials {
	authType := os.Getenv("ROADMAP_AUTH_TYPE")
	if authType == "" {
		authType = "none"
	}

	creds := &Credentials{
		Type: AuthType(authType),
	}

	switch creds.Type {
	case AuthTypeAPIKey:
		creds.APIKey = os.Getenv("ROADMAP_API_KEY")

	case AuthTypeBasic:
		creds.Username = os.Getenv("ROADMAP_USERNAME")
		creds.Password = os.Getenv("ROADMAP_PASSWORD")

	case AuthTypeBearer:
		creds.BearerToken = os.Getenv("ROADMAP_BEARER_TOKEN")

	case AuthTypeOAuth2:
		creds.OAuth2 = &OAuth2Config{
			ClientID:     os.Getenv("ROADMAP_OAUTH_CLIENT_ID"),
			ClientSecret: os.Getenv("ROADMAP_OAUTH_CLIENT_SECRET"),
			TokenURL:     os.Getenv("ROADMAP_OAUTH_TOKEN_URL"),
			GrantType:    "client_credentials",
		}

		if scopes := os.Getenv("ROADMAP_OAUTH_SCOPES"); scopes != "" {
			creds.OAuth2.Scopes = strings.Split(scopes, ",")
		}
	}

	// TLS configuration
	if os.Getenv("ROADMAP_TLS_INSECURE") == "true" {
		creds.TLS = &TLSConfig{
			InsecureSkipVerify: true,
		}
	}

	if certFile := os.Getenv("ROADMAP_TLS_CERT"); certFile != "" {
		if creds.TLS == nil {
			creds.TLS = &TLSConfig{}
		}
		creds.TLS.CertFile = certFile
		creds.TLS.KeyFile = os.Getenv("ROADMAP_TLS_KEY")
		creds.TLS.CAFile = os.Getenv("ROADMAP_TLS_CA")
	}

	return creds
}

// NewSecurityValidator creates a new security validator
func NewSecurityValidator(config *SecurityConfig, logger Logger) *SecurityValidator {
	return &SecurityValidator{
		config: config,
		logger: logger,
	}
}

// ValidateRequest validates a request for security compliance
func (sv *SecurityValidator) ValidateRequest(req *http.Request) error {
	// Check HTTPS requirement
	if sv.config.RequireHTTPS && req.URL.Scheme != "https" {
		return fmt.Errorf("HTTPS is required but request uses %s", req.URL.Scheme)
	}

	// Check request size
	if req.ContentLength > sv.config.MaxRequestSize {
		return fmt.Errorf("request size %d exceeds maximum allowed %d",
			req.ContentLength, sv.config.MaxRequestSize)
	}

	// Check required headers
	for _, header := range sv.config.RequiredHeaders {
		if req.Header.Get(header) == "" {
			return fmt.Errorf("required header %s is missing", header)
		}
	}

	// Check origin if specified
	if len(sv.config.AllowedOrigins) > 0 {
		origin := req.Header.Get("Origin")
		if origin != "" {
			allowed := false
			for _, allowedOrigin := range sv.config.AllowedOrigins {
				if origin == allowedOrigin {
					allowed = true
					break
				}
			}
			if !allowed {
				return fmt.Errorf("origin %s is not allowed", origin)
			}
		}
	}

	return nil
}

// SanitizeCredentials removes sensitive data from credentials for logging
func (am *AuthenticationManager) SanitizeCredentials(creds *Credentials) map[string]interface{} {
	sanitized := map[string]interface{}{
		"type": creds.Type,
	}

	if creds.Username != "" {
		sanitized["username"] = creds.Username
	}

	if creds.APIKey != "" {
		sanitized["api_key"] = maskSensitiveValue(creds.APIKey)
	}

	if creds.BearerToken != "" {
		sanitized["bearer_token"] = maskSensitiveValue(creds.BearerToken)
	}

	if creds.OAuth2 != nil {
		sanitized["oauth2"] = map[string]interface{}{
			"client_id":  creds.OAuth2.ClientID,
			"token_url":  creds.OAuth2.TokenURL,
			"grant_type": creds.OAuth2.GrantType,
			"scopes":     creds.OAuth2.Scopes,
		}
	}

	return sanitized
}

// maskSensitiveValue masks sensitive values for safe logging
func maskSensitiveValue(value string) string {
	if len(value) <= 4 {
		return "****"
	}
	return value[:2] + strings.Repeat("*", len(value)-4) + value[len(value)-2:]
}

// DefaultLogger provides a basic logger implementation
type DefaultLogger struct{}

func (dl *DefaultLogger) Printf(format string, args ...interface{}) {
	fmt.Printf(format+"\n", args...)
}

func (dl *DefaultLogger) Info(msg string) {
	fmt.Printf("INFO: %s\n", msg)
}

func (dl *DefaultLogger) Error(msg string) {
	fmt.Printf("ERROR: %s\n", msg)
}

func (dl *DefaultLogger) Debug(msg string) {
	fmt.Printf("DEBUG: %s\n", msg)
}
