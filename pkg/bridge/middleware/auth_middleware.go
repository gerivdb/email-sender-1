package middleware

import (
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

// AuthMiddleware interface pour le middleware d'authentification
type AuthMiddleware interface {
	Authenticate() gin.HandlerFunc
	RequireRole(role string) gin.HandlerFunc
	RequirePermission(permission string) gin.HandlerFunc
	ExtractAuthContext(c *gin.Context) (*AuthContext, error)
}

// authMiddleware implémentation concrète
type authMiddleware struct {
	config      *AuthConfig
	apiKeyStore APIKeyStore
	rateLimiter RateLimiter
}

// NewAuthMiddleware crée une nouvelle instance du middleware
func NewAuthMiddleware(config *AuthConfig, apiKeyStore APIKeyStore, rateLimiter RateLimiter) AuthMiddleware {
	return &authMiddleware{
		config:      config,
		apiKeyStore: apiKeyStore,
		rateLimiter: rateLimiter,
	}
}

// Authenticate middleware principal d'authentification
func (am *authMiddleware) Authenticate() gin.HandlerFunc {
	return gin.HandlerFunc(func(c *gin.Context) {
		// Vérifier si le chemin est dans la liste bypass
		if am.shouldBypass(c.Request.URL.Path, c.ClientIP()) {
			c.Next()
			return
		}

		// Générer un ID de requête pour le tracing
		requestID := uuid.New().String()
		c.Set("request_id", requestID)

		// Vérifier HTTPS si requis
		if am.config.RequireHTTPS && !am.config.AllowInsecure && c.Request.TLS == nil {
			am.respondWithError(c, http.StatusBadRequest, &AuthError{
				Code:    "HTTPS_REQUIRED",
				Message: "HTTPS is required for authentication",
			})
			return
		}

		// Tenter l'authentification JWT d'abord
		authContext, err := am.tryJWTAuth(c)
		if err == nil {
			am.setAuthContext(c, authContext, requestID)
			c.Next()
			return
		}

		// Tenter l'authentification API Key
		authContext, err = am.tryAPIKeyAuth(c)
		if err == nil {
			am.setAuthContext(c, authContext, requestID)
			c.Next()
			return
		}

		// Aucune authentification valide trouvée
		am.respondWithError(c, http.StatusUnauthorized, &AuthError{
			Code:    ErrCodeMissingAuth,
			Message: "Valid authentication required",
			Details: "Provide either JWT token or API key",
		})
	})
}

// RequireRole middleware pour vérifier les rôles
func (am *authMiddleware) RequireRole(role string) gin.HandlerFunc {
	return func(c *gin.Context) {
		authContext, exists := c.Get("auth_context")
		if !exists {
			am.respondWithError(c, http.StatusUnauthorized, &AuthError{
				Code:    ErrCodeMissingAuth,
				Message: "Authentication context not found",
			})
			return
		}

		auth, ok := authContext.(*AuthContext)
		if !ok {
			am.respondWithError(c, http.StatusInternalServerError, &AuthError{
				Code:    "INVALID_AUTH_CONTEXT",
				Message: "Invalid authentication context",
			})
			return
		}

		if !am.hasRole(auth.Roles, role) {
			am.respondWithError(c, http.StatusForbidden, &AuthError{
				Code:    ErrCodeInsufficientPerms,
				Message: fmt.Sprintf("Role '%s' required", role),
			})
			return
		}

		c.Next()
	}
}

// RequirePermission middleware pour vérifier les permissions
func (am *authMiddleware) RequirePermission(permission string) gin.HandlerFunc {
	return func(c *gin.Context) {
		authContext, exists := c.Get("auth_context")
		if !exists {
			am.respondWithError(c, http.StatusUnauthorized, &AuthError{
				Code:    ErrCodeMissingAuth,
				Message: "Authentication context not found",
			})
			return
		}

		auth, ok := authContext.(*AuthContext)
		if !ok {
			am.respondWithError(c, http.StatusInternalServerError, &AuthError{
				Code:    "INVALID_AUTH_CONTEXT",
				Message: "Invalid authentication context",
			})
			return
		}

		if !am.hasPermission(auth.Permissions, permission) {
			am.respondWithError(c, http.StatusForbidden, &AuthError{
				Code:    ErrCodeInsufficientPerms,
				Message: fmt.Sprintf("Permission '%s' required", permission),
			})
			return
		}

		c.Next()
	}
}

// ExtractAuthContext extrait le contexte d'authentification
func (am *authMiddleware) ExtractAuthContext(c *gin.Context) (*AuthContext, error) {
	authContext, exists := c.Get("auth_context")
	if !exists {
		return nil, &AuthError{
			Code:    ErrCodeMissingAuth,
			Message: "Authentication context not found",
		}
	}

	auth, ok := authContext.(*AuthContext)
	if !ok {
		return nil, &AuthError{
			Code:    "INVALID_AUTH_CONTEXT",
			Message: "Invalid authentication context",
		}
	}

	return auth, nil
}

// tryJWTAuth tente l'authentification JWT
func (am *authMiddleware) tryJWTAuth(c *gin.Context) (*AuthContext, error) {
	authHeader := c.GetHeader("Authorization")
	if authHeader == "" {
		return nil, &AuthError{Code: ErrCodeMissingAuth, Message: "Missing Authorization header"}
	}

	if !strings.HasPrefix(authHeader, "Bearer ") {
		return nil, &AuthError{Code: ErrCodeInvalidToken, Message: "Invalid token format"}
	}

	tokenString := authHeader[7:] // Remove "Bearer " prefix

	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(am.config.JWTSecret), nil
	})
	if err != nil {
		return nil, &AuthError{Code: ErrCodeInvalidToken, Message: err.Error()}
	}

	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, &AuthError{Code: ErrCodeInvalidToken, Message: "Invalid token claims"}
	}

	// Vérifier l'expiration
	if time.Unix(claims.ExpiresAt, 0).Before(time.Now()) {
		return nil, &AuthError{Code: ErrCodeExpiredToken, Message: "Token has expired"}
	}

	return &AuthContext{
		Method:      AuthMethodJWT,
		UserID:      claims.UserID,
		Username:    claims.Username,
		Roles:       claims.Roles,
		Permissions: claims.Permissions,
		IssuedAt:    time.Unix(claims.IssuedAt, 0),
		ExpiresAt:   time.Unix(claims.ExpiresAt, 0),
	}, nil
}

// tryAPIKeyAuth tente l'authentification par clé API
func (am *authMiddleware) tryAPIKeyAuth(c *gin.Context) (*AuthContext, error) {
	apiKey := c.GetHeader(am.config.APIKeyHeader)
	if apiKey == "" {
		return nil, &AuthError{Code: ErrCodeMissingAuth, Message: "Missing API key"}
	}

	key, err := am.apiKeyStore.GetAPIKey(apiKey)
	if err != nil {
		return nil, &AuthError{Code: ErrCodeInvalidAPIKey, Message: "Invalid API key"}
	}

	if !key.IsActive {
		return nil, &AuthError{Code: ErrCodeInvalidAPIKey, Message: "API key is inactive"}
	}

	// Vérifier l'expiration
	if key.ExpiresAt != nil && key.ExpiresAt.Before(time.Now()) {
		return nil, &AuthError{Code: ErrCodeInvalidAPIKey, Message: "API key has expired"}
	}

	// Vérifier le rate limiting
	if am.config.EnableRateLimit && am.rateLimiter != nil {
		if !am.rateLimiter.Allow(key.ID) {
			return nil, &AuthError{Code: ErrCodeRateLimitExceeded, Message: "Rate limit exceeded"}
		}
	}

	// Mettre à jour last_used_at
	go func() {
		now := time.Now()
		key.LastUsedAt = &now
		am.apiKeyStore.UpdateAPIKey(key)
	}()

	return &AuthContext{
		Method:      AuthMethodAPIKey,
		UserID:      key.UserID,
		APIKeyID:    key.ID,
		Permissions: key.Permissions,
		IssuedAt:    key.CreatedAt,
		ExpiresAt: func() time.Time {
			if key.ExpiresAt != nil {
				return *key.ExpiresAt
			}
			return time.Now().Add(365 * 24 * time.Hour) // 1 year default
		}(),
	}, nil
}

// Méthodes utilitaires
func (am *authMiddleware) shouldBypass(path, clientIP string) bool {
	for _, bypassPath := range am.config.BypassForPaths {
		if strings.HasPrefix(path, bypassPath) {
			return true
		}
	}

	for _, bypassIP := range am.config.BypassForIPs {
		if clientIP == bypassIP {
			return true
		}
	}

	return false
}

func (am *authMiddleware) setAuthContext(c *gin.Context, auth *AuthContext, requestID string) {
	auth.RequestID = requestID
	c.Set("auth_context", auth)
	c.Set("user_id", auth.UserID)
	c.Set("auth_method", string(auth.Method))
}

func (am *authMiddleware) hasRole(roles []string, requiredRole string) bool {
	for _, role := range roles {
		if role == requiredRole || role == "admin" { // admin a tous les rôles
			return true
		}
	}
	return false
}

func (am *authMiddleware) hasPermission(permissions []string, requiredPermission string) bool {
	for _, perm := range permissions {
		if perm == requiredPermission || perm == "*" { // * = toutes permissions
			return true
		}
	}
	return false
}

func (am *authMiddleware) respondWithError(c *gin.Context, status int, authErr *AuthError) {
	c.Header("WWW-Authenticate", "Bearer")
	c.JSON(status, gin.H{
		"error":     authErr,
		"timestamp": time.Now().Unix(),
		"path":      c.Request.URL.Path,
	})
	c.Abort()
}
