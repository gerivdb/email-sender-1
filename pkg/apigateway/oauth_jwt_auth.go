package apigateway

import (
	"context"
	"errors"
	"net/http"
	"strings"

	"github.com/golang-jwt/jwt/v5"
)

// JWTAuthConfig configuration de l’authentification JWT
type JWTAuthConfig struct {
	SecretKey     string
	Issuer        string
	Audience      string
	RequiredScope string
}

// JWTClaims structure des claims JWT
type JWTClaims struct {
	Scope string `json:"scope"`
	jwt.RegisteredClaims
}

// JWTAuthenticator gère la validation JWT
type JWTAuthenticator struct {
	config JWTAuthConfig
}

// NewJWTAuthenticator crée un validateur JWT
func NewJWTAuthenticator(config JWTAuthConfig) *JWTAuthenticator {
	return &JWTAuthenticator{config: config}
}

// Middleware HTTP pour protéger une route avec JWT
func (a *JWTAuthenticator) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if !strings.HasPrefix(authHeader, "Bearer ") {
			http.Error(w, "Missing Bearer token", http.StatusUnauthorized)
			return
		}
		tokenStr := strings.TrimPrefix(authHeader, "Bearer ")
		claims := &JWTClaims{}
		token, err := jwt.ParseWithClaims(tokenStr, claims, func(token *jwt.Token) (interface{}, error) {
			return []byte(a.config.SecretKey), nil
		})
		if err != nil || !token.Valid {
			http.Error(w, "Invalid token", http.StatusUnauthorized)
			return
		}
		if a.config.Issuer != "" && claims.Issuer != a.config.Issuer {
			http.Error(w, "Invalid issuer", http.StatusUnauthorized)
			return
		}
		// Manual audience check
		if a.config.Audience != "" {
			validAudience := false
			for _, aud := range claims.Audience {
				if aud == a.config.Audience {
					validAudience = true
					break
				}
			}
			if !validAudience {
				http.Error(w, "Invalid audience", http.StatusUnauthorized)
				return
			}
		}
		if a.config.RequiredScope != "" && !strings.Contains(claims.Scope, a.config.RequiredScope) {
			http.Error(w, "Insufficient scope", http.StatusForbidden)
			return
		}
		next.ServeHTTP(w, r)
	})
}

// ValidateToken permet de valider un JWT manuellement
func (a *JWTAuthenticator) ValidateToken(ctx context.Context, tokenStr string) (*JWTClaims, error) {
	claims := &JWTClaims{}
	token, err := jwt.ParseWithClaims(tokenStr, claims, func(token *jwt.Token) (interface{}, error) {
		return []byte(a.config.SecretKey), nil
	})
	if err != nil || !token.Valid {
		return nil, errors.New("invalid token")
	}
	if a.config.Issuer != "" && claims.Issuer != a.config.Issuer {
		return nil, errors.New("invalid issuer")
	}
	// Manual audience check
	if a.config.Audience != "" {
		validAudience := false
		for _, aud := range claims.Audience {
			if aud == a.config.Audience {
				validAudience = true
				break
			}
		}
		if !validAudience {
			return nil, errors.New("invalid audience")
		}
	}
	if a.config.RequiredScope != "" && !strings.Contains(claims.Scope, a.config.RequiredScope) {
		return nil, errors.New("insufficient scope")
	}
	return claims, nil
}

// Example usage:
/*
func main() {
auth := apigateway.NewJWTAuthenticator(apigateway.JWTAuthConfig{
SecretKey: "my-secret",
Issuer: "my-app",
Audience: "my-users",
RequiredScope: "api:read",
})
http.Handle("/api/v1/secure", auth.Middleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
w.Write([]byte("JWT OK"))
})))
http.ListenAndServe(":8080", nil)
}
*/
