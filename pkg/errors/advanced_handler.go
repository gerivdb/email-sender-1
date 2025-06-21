// SPDX-License-Identifier: MIT
// Package errors : gestion avancée des erreurs (v65)
package errors

import (
	"time"
)

// ErrorHandler gère les stratégies avancées d’erreur
type ErrorHandler struct {
	RetryManager    *RetryManager
	DeadLetterQueue *DeadLetterQueue
	CircuitBreaker  *CircuitBreaker
	Classifier      *ErrorClassifier
	Healer          *AutoHealer
}

// RetryPolicy définit la stratégie de retry
type RetryPolicy struct {
	MaxRetries      int
	BaseDelay       time.Duration
	MaxDelay        time.Duration
	Multiplier      float64
	Jitter          bool
	RetriableErrors []string
}

// DeadLetterJob représente un job échoué
type DeadLetterJob struct {
	ID           string
	OriginalJob  interface{}
	ErrorHistory []ErrorAttempt
	FirstFailed  time.Time
	LastAttempt  time.Time
	Metadata     map[string]interface{}
}

// ErrorAttempt détail d’une tentative d’exécution
type ErrorAttempt struct {
	Timestamp time.Time
	Error     string
}

// RetryManager, DeadLetterQueue, CircuitBreaker, ErrorClassifier, AutoHealer à implémenter selon besoins

// RetryManager gère les tentatives de réessai.
type RetryManager struct{}

// DeadLetterQueue gère les messages qui ne peuvent pas être traités.
type DeadLetterQueue struct{}

// CircuitBreaker surveille les échecs et peut interrompre les opérations.
type CircuitBreaker struct{}

// ErrorClassifier classifie les erreurs pour un traitement différencié.
type ErrorClassifier struct{}

// AutoHealer tente de résoudre automatiquement certains types d'erreurs.
type AutoHealer struct{}
