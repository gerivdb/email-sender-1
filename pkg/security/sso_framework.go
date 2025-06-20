// SPDX-License-Identifier: MIT
// Package security : gestion du SSO unifié (v65)
package security

import (
	"context"
	"errors"
	"time"
)

// SSOProvider interface pour les providers SSO (OIDC, SAML, OAuth2)
type SSOProvider interface {
	Authenticate(ctx context.Context, req AuthRequest) (*User, error)
	RefreshToken(ctx context.Context, token string) (*Token, error)
	Logout(ctx context.Context, sessionID string) error
}

// SSOManager gestionnaire principal SSO
type SSOManager struct {
	Providers    map[string]SSOProvider
	JWTManager   *JWTManager
	SessionStore SessionStore
}

// AuthRequest structure de requête d’authentification
type AuthRequest struct {
	Provider string
	Username string
	Password string
	Scopes   []string
}

// User structure utilisateur
type User struct {
	ID    string
	Email string
	Name  string
	Roles []string
}

// Token structure de jeton JWT
type Token struct {
	AccessToken  string
	RefreshToken string
	ExpiresAt    time.Time
}

// JWTManager gestion des JWT (RS256, refresh, révocation)
type JWTManager struct {
	SecretKey string
	Issuer    string
}

// SessionStore interface pour la gestion des sessions
type SessionStore interface {
	Set(sessionID string, user *User, expires time.Duration) error
	Get(sessionID string) (*User, error)
	Delete(sessionID string) error
}

// Exemple d’implémentation Authenticate (simplifiée)
func (m *SSOManager) Authenticate(ctx context.Context, req AuthRequest) (*User, error) {
	// TODO: Sélectionner le provider, authentifier, créer session, générer JWT
	return nil, errors.New("not implemented")
}
