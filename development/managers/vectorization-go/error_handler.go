package vectorization

import (
	"context"
	"fmt"
	"time"

	"go.uber.org/zap"
)

// ErrorType représente le type d'erreur vectorielle
type ErrorType string

const (
	ErrorTypeConnection ErrorType = "connection"
	ErrorTypeValidation ErrorType = "validation"
	ErrorTypeTimeout    ErrorType = "timeout"
	ErrorTypeCapacity   ErrorType = "capacity"
	ErrorTypeNotFound   ErrorType = "not_found"
	ErrorTypeConflict   ErrorType = "conflict"
	ErrorTypeInternal   ErrorType = "internal"
)

// VectorError représente une erreur dans les opérations vectorielles
type VectorError struct {
	Type      ErrorType
	Message   string
	Operation string
	Cause     error
	Timestamp time.Time
	Retryable bool
}

func (ve *VectorError) Error() string {
	return fmt.Sprintf("[%s] %s: %s", ve.Type, ve.Operation, ve.Message)
}

func (ve *VectorError) Unwrap() error {
	return ve.Cause
}

// NewVectorError crée une nouvelle erreur vectorielle
func NewVectorError(errType ErrorType, operation, message string, cause error) *VectorError {
	return &VectorError{
		Type:      errType,
		Message:   message,
		Operation: operation,
		Cause:     cause,
		Timestamp: time.Now(),
		Retryable: isRetryable(errType),
	}
}

// isRetryable détermine si une erreur peut être réessayée
func isRetryable(errType ErrorType) bool {
	switch errType {
	case ErrorTypeConnection, ErrorTypeTimeout, ErrorTypeCapacity:
		return true
	case ErrorTypeValidation, ErrorTypeNotFound, ErrorTypeConflict:
		return false
	default:
		return false
	}
}

// RetryConfig configure la stratégie de retry
type RetryConfig struct {
	MaxAttempts   int           `yaml:"max_attempts"`
	InitialDelay  time.Duration `yaml:"initial_delay"`
	MaxDelay      time.Duration `yaml:"max_delay"`
	BackoffFactor float64       `yaml:"backoff_factor"`
	EnableJitter  bool          `yaml:"enable_jitter"`
}

// DefaultRetryConfig retourne une configuration de retry par défaut
func DefaultRetryConfig() RetryConfig {
	return RetryConfig{
		MaxAttempts:   3,
		InitialDelay:  1 * time.Second,
		MaxDelay:      30 * time.Second,
		BackoffFactor: 2.0,
		EnableJitter:  true,
	}
}

// ErrorHandler gère les erreurs et les retry
type ErrorHandler struct {
	config RetryConfig
	logger *zap.Logger
}

// NewErrorHandler crée un nouveau gestionnaire d'erreurs
func NewErrorHandler(config RetryConfig, logger *zap.Logger) *ErrorHandler {
	return &ErrorHandler{
		config: config,
		logger: logger,
	}
}

// ExecuteWithRetry exécute une opération avec retry automatique
func (eh *ErrorHandler) ExecuteWithRetry(ctx context.Context, operation string, fn func() error) error {
	var lastErr error

	for attempt := 0; attempt < eh.config.MaxAttempts; attempt++ {
		// Calculer le délai pour cette tentative
		if attempt > 0 {
			delay := eh.calculateDelay(attempt)
			eh.logger.Info("Nouvelle tentative",
				zap.String("operation", operation),
				zap.Int("attempt", attempt+1),
				zap.Int("max_attempts", eh.config.MaxAttempts),
				zap.Duration("delay", delay))

			select {
			case <-time.After(delay):
			case <-ctx.Done():
				return fmt.Errorf("opération annulée: %w", ctx.Err())
			}
		}

		// Exécuter l'opération
		err := fn()
		if err == nil {
			if attempt > 0 {
				eh.logger.Info("Opération réussie après retry",
					zap.String("operation", operation),
					zap.Int("attempts", attempt+1))
			}
			return nil
		}

		lastErr = err

		// Vérifier si l'erreur est retryable
		if vectorErr, ok := err.(*VectorError); ok {
			if !vectorErr.Retryable {
				eh.logger.Error("Erreur non-retryable détectée",
					zap.String("operation", operation),
					zap.String("error_type", string(vectorErr.Type)),
					zap.Error(err))
				return err
			}
		}

		eh.logger.Warn("Tentative échouée",
			zap.String("operation", operation),
			zap.Int("attempt", attempt+1),
			zap.Error(err))
	}

	eh.logger.Error("Toutes les tentatives ont échoué",
		zap.String("operation", operation),
		zap.Int("max_attempts", eh.config.MaxAttempts),
		zap.Error(lastErr))

	return fmt.Errorf("échec après %d tentatives: %w", eh.config.MaxAttempts, lastErr)
}

// calculateDelay calcule le délai avant la prochaine tentative
func (eh *ErrorHandler) calculateDelay(attempt int) time.Duration {
	// Calcul du backoff exponentiel
	delay := float64(eh.config.InitialDelay) *
		pow(eh.config.BackoffFactor, float64(attempt-1))

	// Limiter au délai maximum
	if delay > float64(eh.config.MaxDelay) {
		delay = float64(eh.config.MaxDelay)
	}

	duration := time.Duration(delay)
	// Ajouter du jitter si activé
	if eh.config.EnableJitter {
		jitterFactor := float64(time.Now().UnixNano()%2)*2 - 1 // -1 ou +1
		jitter := time.Duration(float64(duration) * 0.1 * jitterFactor)
		duration += jitter
	}

	return duration
}

// pow calcule x^y (version simple pour éviter la dépendance math)
func pow(x, y float64) float64 {
	if y == 0 {
		return 1
	}
	result := x
	for i := 1; i < int(y); i++ {
		result *= x
	}
	return result
}

// ValidateVector valide un vecteur avant traitement
func ValidateVector(vector Vector, expectedSize int) error {
	if vector.ID == "" {
		return NewVectorError(ErrorTypeValidation, "validate_vector",
			"ID de vecteur requis", nil)
	}

	if len(vector.Values) == 0 {
		return NewVectorError(ErrorTypeValidation, "validate_vector",
			"vecteur vide", nil)
	}

	if len(vector.Values) != expectedSize {
		return NewVectorError(ErrorTypeValidation, "validate_vector",
			fmt.Sprintf("taille incorrecte: %d, attendue %d",
				len(vector.Values), expectedSize), nil)
	}

	// Vérifier les valeurs NaN ou infinies
	for i, val := range vector.Values {
		if isNaN(val) || isInf(val) {
			return NewVectorError(ErrorTypeValidation, "validate_vector",
				fmt.Sprintf("valeur invalide à l'index %d: %f", i, val), nil)
		}
	}

	return nil
}

// ValidateVectors valide un lot de vecteurs
func ValidateVectors(vectors []Vector, expectedSize int) error {
	if len(vectors) == 0 {
		return NewVectorError(ErrorTypeValidation, "validate_vectors",
			"aucun vecteur à valider", nil)
	}

	for i, vector := range vectors {
		if err := ValidateVector(vector, expectedSize); err != nil {
			return fmt.Errorf("vecteur %d: %w", i, err)
		}
	}

	return nil
}

// isNaN vérifie si un float32 est NaN
func isNaN(f float32) bool {
	return f != f
}

// isInf vérifie si un float32 est infini
func isInf(f float32) bool {
	return f > 3.4028235e+38 || f < -3.4028235e+38
}

// CircuitBreaker implémente un circuit breaker pour les opérations vectorielles
type CircuitBreaker struct {
	maxFailures int
	resetTime   time.Duration
	failures    int
	lastFailure time.Time
	state       string
	logger      *zap.Logger
}

// NewCircuitBreaker crée un nouveau circuit breaker
func NewCircuitBreaker(maxFailures int, resetTime time.Duration, logger *zap.Logger) *CircuitBreaker {
	return &CircuitBreaker{
		maxFailures: maxFailures,
		resetTime:   resetTime,
		state:       "closed",
		logger:      logger,
	}
}

// Execute exécute une opération via le circuit breaker
func (cb *CircuitBreaker) Execute(operation string, fn func() error) error {
	// Vérifier l'état du circuit
	if cb.state == "open" {
		if time.Since(cb.lastFailure) > cb.resetTime {
			cb.state = "half-open"
			cb.logger.Info("Circuit breaker passe en half-open",
				zap.String("operation", operation))
		} else {
			return NewVectorError(ErrorTypeCapacity, operation,
				"circuit breaker ouvert", nil)
		}
	}

	// Exécuter l'opération
	err := fn()
	if err != nil {
		cb.failures++
		cb.lastFailure = time.Now()

		if cb.failures >= cb.maxFailures {
			cb.state = "open"
			cb.logger.Error("Circuit breaker ouvert",
				zap.String("operation", operation),
				zap.Int("failures", cb.failures))
		}

		return err
	}

	// Réinitialiser en cas de succès
	if cb.state == "half-open" {
		cb.state = "closed"
		cb.failures = 0
		cb.logger.Info("Circuit breaker fermé après succès",
			zap.String("operation", operation))
	}

	return nil
}

// GetState retourne l'état actuel du circuit breaker
func (cb *CircuitBreaker) GetState() string {
	return cb.state
}
