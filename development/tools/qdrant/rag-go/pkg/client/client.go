// Package client fournit un client HTTP pour interagir avec QDrant
package client

import (
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"sync"
	"time"
)

// QdrantClient est le client principal pour interagir avec QDrant via HTTP
type QdrantClient struct {
	// BaseURL est l'URL de base du serveur QDrant
	BaseURL string
	// HTTPClient est le client HTTP utilisé pour les requêtes
	HTTPClient *http.Client
	// DefaultHeaders contient les en-têtes HTTP à inclure dans chaque requête
	DefaultHeaders map[string]string
	// TLSConfig contient la configuration TLS si nécessaire
	TLSConfig *TLSConfig
	// statusCache est utilisé pour mettre en cache temporairement le statut du serveur
	statusCache struct {
		alive     bool
		timestamp time.Time
		mutex     sync.RWMutex
	}
}

// TLSConfig contient la configuration TLS pour le client
type TLSConfig struct {
	CertFile   string
	KeyFile    string
	CACertFile string
	SkipVerify bool
}

// Option est une fonction qui configure le client QDrant
type Option func(*QdrantClient)

// WithTimeout définit le timeout du client HTTP
func WithTimeout(timeout time.Duration) Option {
	return func(client *QdrantClient) {
		client.HTTPClient.Timeout = timeout
	}
}

// WithHeader ajoute un en-tête HTTP par défaut
func WithHeader(key, value string) Option {
	return func(client *QdrantClient) {
		client.DefaultHeaders[key] = value
	}
}

// WithTLSConfig configure les options TLS du client
func WithTLSConfig(tlsConfig *TLSConfig) Option {
	return func(client *QdrantClient) {
		client.TLSConfig = tlsConfig
	}
}

// NewQdrantClient crée un nouveau client QDrant avec les options spécifiées
func NewQdrantClient(baseURL string, options ...Option) (*QdrantClient, error) {
	// Valider l'URL de base
	_, err := url.Parse(baseURL)
	if err != nil {
		return nil, fmt.Errorf("URL de base invalide: %w", err)
	}

	// Créer le client avec les valeurs par défaut
	client := &QdrantClient{
		BaseURL:    baseURL,
		HTTPClient: &http.Client{Timeout: 30 * time.Second},
		DefaultHeaders: map[string]string{
			"Content-Type": "application/json",
			"Accept":       "application/json",
		},
	}

	// Appliquer les options personnalisées
	for _, option := range options {
		option(client)
	}

	return client, nil
}

// HealthCheck vérifie si le serveur QDrant est disponible et fonctionne correctement
func (c *QdrantClient) HealthCheck() error {
	resp, err := c.HTTPClient.Get(fmt.Sprintf("%s/healthz", c.BaseURL))
	if err != nil {
		return NewQdrantConnectionError("erreur de connexion", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return NewQdrantAPIError(resp.StatusCode, "le serveur n'est pas en bonne santé")
	}

	return nil
}

// IsAlive vérifie rapidement si le serveur QDrant est accessible
// Cette méthode utilise un cache pour éviter des requêtes trop fréquentes
func (c *QdrantClient) IsAlive() bool {
	c.statusCache.mutex.RLock()
	if !c.statusCache.timestamp.IsZero() && time.Since(c.statusCache.timestamp) < 5*time.Second {
		alive := c.statusCache.alive
		c.statusCache.mutex.RUnlock()
		return alive
	}
	c.statusCache.mutex.RUnlock()

	// Configurer un client avec un timeout court pour ce check
	shortClient := &http.Client{Timeout: 5 * time.Second}
	resp, err := shortClient.Get(fmt.Sprintf("%s/", c.BaseURL))

	c.statusCache.mutex.Lock()
	defer c.statusCache.mutex.Unlock()

	c.statusCache.timestamp = time.Now()
	c.statusCache.alive = err == nil && resp != nil && resp.StatusCode == http.StatusOK

	if resp != nil && resp.Body != nil {
		resp.Body.Close()
	}

	return c.statusCache.alive
}

// QdrantError est l'interface commune pour toutes les erreurs QDrant
type QdrantError interface {
	error
	IsQdrantError() bool
}

// QdrantConnectionError représente une erreur de connexion au serveur QDrant
type QdrantConnectionError struct {
	Message string
	Cause   error
}

func NewQdrantConnectionError(message string, cause error) *QdrantConnectionError {
	return &QdrantConnectionError{
		Message: message,
		Cause:   cause,
	}
}

func (e *QdrantConnectionError) Error() string {
	if e.Cause != nil {
		return fmt.Sprintf("QDrant connection error: %s - %v", e.Message, e.Cause)
	}
	return fmt.Sprintf("QDrant connection error: %s", e.Message)
}

func (e *QdrantConnectionError) IsQdrantError() bool {
	return true
}

// QdrantTimeoutError représente une erreur de timeout lors d'une requête à QDrant
type QdrantTimeoutError struct {
	Duration time.Duration
}

func NewQdrantTimeoutError(duration time.Duration) *QdrantTimeoutError {
	return &QdrantTimeoutError{
		Duration: duration,
	}
}

func (e *QdrantTimeoutError) Error() string {
	return fmt.Sprintf("QDrant timeout error: la requête a dépassé %v", e.Duration)
}

func (e *QdrantTimeoutError) IsQdrantError() bool {
	return true
}

// QdrantAPIError représente une erreur retournée par l'API QDrant
type QdrantAPIError struct {
	StatusCode int
	Message    string
}

func NewQdrantAPIError(statusCode int, message string) *QdrantAPIError {
	return &QdrantAPIError{
		StatusCode: statusCode,
		Message:    message,
	}
}

func (e *QdrantAPIError) Error() string {
	return fmt.Sprintf("QDrant API error (%d): %s", e.StatusCode, e.Message)
}

func (e *QdrantAPIError) IsQdrantError() bool {
	return true
}

// ShouldRetry détermine si une requête devrait être réessayée en fonction de l'erreur
func ShouldRetry(err error) bool {
	if err == nil {
		return false
	}

	// Vérifier si c'est une erreur de timeout
	var timeoutErr *QdrantTimeoutError
	if errors.As(err, &timeoutErr) {
		return true
	}

	// Vérifier si c'est une erreur de connexion
	var connErr *QdrantConnectionError
	if errors.As(err, &connErr) {
		return true
	}

	// Vérifier si c'est une erreur API avec un code 5xx
	var apiErr *QdrantAPIError
	if errors.As(err, &apiErr) && apiErr.StatusCode >= 500 && apiErr.StatusCode < 600 {
		return true
	}

	return false
}

// WithRetry exécute une fonction avec une stratégie de retry
func WithRetry(maxRetries int, fn func() error) error {
	var err error

	for attempt := 0; attempt <= maxRetries; attempt++ {
		err = fn()
		if err == nil {
			return nil
		}

		if !ShouldRetry(err) || attempt >= maxRetries {
			return err
		}

		// Délai exponentiel: 100ms, 200ms, 400ms, ...
		backoff := time.Duration(100*(1<<attempt)) * time.Millisecond
		time.Sleep(backoff)
	}

	return err
}
