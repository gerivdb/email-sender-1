package middleware

import (
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// AuthMethod représente les méthodes d'authentification supportées
type AuthMethod string

const (
	AuthMethodJWT    AuthMethod = "jwt"
	AuthMethodAPIKey AuthMethod = "api_key"
	AuthMethodBasic  AuthMethod = "basic"
	AuthMethodNone   AuthMethod = "none"
)

// Claims structure pour JWT tokens
type Claims struct {
	UserID      string   `json:"user_id"`
	Username    string   `json:"username"`
	Roles       []string `json:"roles"`
	Permissions []string `json:"permissions"`
	APIKeyID    string   `json:"api_key_id,omitempty"`
	IssuedAt    int64    `json:"iat"`
	ExpiresAt   int64    `json:"exp"`
	jwt.RegisteredClaims
}

// APIKey structure pour gestion des clés API
type APIKey struct {
	ID          string     `json:"id"`
	Key         string     `json:"key"`
	Name        string     `json:"name"`
	UserID      string     `json:"user_id"`
	Permissions []string   `json:"permissions"`
	CreatedAt   time.Time  `json:"created_at"`
	ExpiresAt   *time.Time `json:"expires_at,omitempty"`
	LastUsedAt  *time.Time `json:"last_used_at,omitempty"`
	IsActive    bool       `json:"is_active"`
	RateLimit   *RateLimit `json:"rate_limit,omitempty"`
}

// RateLimit configuration pour limitation des requêtes
type RateLimit struct {
	RequestsPerMinute int           `json:"requests_per_minute"`
	RequestsPerHour   int           `json:"requests_per_hour"`
	BurstLimit        int           `json:"burst_limit"`
	WindowDuration    time.Duration `json:"window_duration"`
}

// AuthContext contient les informations d'authentification pour une requête
type AuthContext struct {
	Method      AuthMethod `json:"method"`
	UserID      string     `json:"user_id"`
	Username    string     `json:"username"`
	Roles       []string   `json:"roles"`
	Permissions []string   `json:"permissions"`
	APIKeyID    string     `json:"api_key_id,omitempty"`
	IssuedAt    time.Time  `json:"issued_at"`
	ExpiresAt   time.Time  `json:"expires_at"`
	RequestID   string     `json:"request_id"`
}

// AuthConfig configuration pour le middleware d'authentification
type AuthConfig struct {
	// JWT Configuration
	JWTSecret     string        `yaml:"jwt_secret" env:"JWT_SECRET"`
	JWTExpiration time.Duration `yaml:"jwt_expiration" env:"JWT_EXPIRATION" default:"24h"`
	JWTIssuer     string        `yaml:"jwt_issuer" env:"JWT_ISSUER" default:"n8n-go-bridge"`

	// API Keys Configuration
	APIKeyHeader  string `yaml:"api_key_header" env:"API_KEY_HEADER" default:"X-API-Key"`
	APIKeyStorage string `yaml:"api_key_storage" env:"API_KEY_STORAGE" default:"memory"`

	// Security
	RequireHTTPS  bool `yaml:"require_https" env:"REQUIRE_HTTPS" default:"true"`
	AllowInsecure bool `yaml:"allow_insecure" env:"ALLOW_INSECURE" default:"false"`

	// Rate Limiting
	DefaultRateLimit *RateLimit `yaml:"default_rate_limit"`
	EnableRateLimit  bool       `yaml:"enable_rate_limit" env:"ENABLE_RATE_LIMIT" default:"true"`

	// Bypass options pour développement
	BypassForPaths []string `yaml:"bypass_for_paths"`
	BypassForIPs   []string `yaml:"bypass_for_ips"`
}

// AuthError types d'erreurs d'authentification
type AuthError struct {
	Code    string `json:"code"`
	Message string `json:"message"`
	Details string `json:"details,omitempty"`
}

func (e *AuthError) Error() string {
	return e.Message
}

// Codes d'erreur standard
const (
	ErrCodeInvalidToken      = "INVALID_TOKEN"
	ErrCodeExpiredToken      = "EXPIRED_TOKEN"
	ErrCodeInvalidAPIKey     = "INVALID_API_KEY"
	ErrCodeInsufficientPerms = "INSUFFICIENT_PERMISSIONS"
	ErrCodeRateLimitExceeded = "RATE_LIMIT_EXCEEDED"
	ErrCodeUnsupportedAuth   = "UNSUPPORTED_AUTH_METHOD"
	ErrCodeMissingAuth       = "MISSING_AUTHENTICATION"
)
