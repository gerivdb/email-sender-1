package integratedmanager

import (
	"context"
	"fmt"
	"log"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/pkg/errors"
)

// ErrorManager interface pour découpler la dépendance
type ErrorManager interface {
	LogError(err error, module string, code string)
	CatalogError(entry ErrorEntry) error
	ValidateError(entry ErrorEntry) error
}

// ErrorEntry représente une erreur cataloguée
type ErrorEntry struct {
	ID             string                 `json:"id"`
	Timestamp      time.Time              `json:"timestamp"`
	Message        string                 `json:"message"`
	StackTrace     string                 `json:"stack_trace"`
	Module         string                 `json:"module"`
	ErrorCode      string                 `json:"error_code"`
	ManagerContext map[string]interface{} `json:"manager_context"`
	Severity       string                 `json:"severity"`
}

// IntegratedErrorManager gère la centralisation des erreurs
type IntegratedErrorManager struct {
	errorManager ErrorManager
	errorQueue   chan ErrorEntry
	wg          sync.WaitGroup
	ctx         context.Context
	cancel      context.CancelFunc
	hooks       map[string][]ErrorHook
	mu          sync.RWMutex
}

// ErrorHook définit un hook d'erreur pour un manager spécifique
type ErrorHook func(module string, err error, context map[string]interface{})

var (
	integratedManager *IntegratedErrorManager
	once             sync.Once
)

// GetIntegratedErrorManager retourne l'instance singleton
func GetIntegratedErrorManager() *IntegratedErrorManager {
	once.Do(func() {
		ctx, cancel := context.WithCancel(context.Background())
		integratedManager = &IntegratedErrorManager{
			errorQueue: make(chan ErrorEntry, 100),
			ctx:        ctx,
			cancel:     cancel,
			hooks:      make(map[string][]ErrorHook),
		}
		integratedManager.startErrorProcessor()
	})
	return integratedManager
}

// SetErrorManager configure le gestionnaire d'erreurs
func (iem *IntegratedErrorManager) SetErrorManager(em ErrorManager) {
	iem.errorManager = em
}

// AddHook ajoute un hook d'erreur pour un module spécifique
func (iem *IntegratedErrorManager) AddHook(module string, hook ErrorHook) {
	iem.mu.Lock()
	defer iem.mu.Unlock()
	iem.hooks[module] = append(iem.hooks[module], hook)
}

// PropagateError propage une erreur vers le gestionnaire d'erreurs
func (iem *IntegratedErrorManager) PropagateError(module string, err error, context map[string]interface{}) {
	if err == nil {
		return
	}

	// Exécuter les hooks spécifiques au module
	iem.executeHooks(module, err, context)

	// Créer une entrée d'erreur standardisée
	entry := ErrorEntry{
		ID:             uuid.New().String(),
		Timestamp:      time.Now(),
		Message:        err.Error(),
		StackTrace:     fmt.Sprintf("%+v", errors.WithStack(err)),
		Module:         module,
		ErrorCode:      determineErrorCode(err),
		ManagerContext: context,
		Severity:       determineSeverity(err),
	}

	// Envoyer l'erreur dans la queue pour traitement asynchrone
	select {
	case iem.errorQueue <- entry:
		// Erreur ajoutée à la queue
	default:
		// Queue pleine, traitement synchrone
		iem.processError(entry)
	}
}

// CentralizeError collecte et centralise toutes les erreurs
func (iem *IntegratedErrorManager) CentralizeError(module string, err error, context map[string]interface{}) error {
	if err == nil {
		return nil
	}

	// Wrapper l'erreur avec plus de contexte
	wrappedErr := errors.Wrapf(err, "Centralized error from module %s", module)
	
	// Propager l'erreur
	iem.PropagateError(module, wrappedErr, context)
	
	return wrappedErr
}

// executeHooks exécute tous les hooks pour un module donné
func (iem *IntegratedErrorManager) executeHooks(module string, err error, context map[string]interface{}) {
	iem.mu.RLock()
	hooks := iem.hooks[module]
	iem.mu.RUnlock()

	for _, hook := range hooks {
		go func(h ErrorHook) {
			defer func() {
				if r := recover(); r != nil {
					log.Printf("Error hook panic for module %s: %v", module, r)
				}
			}()
			h(module, err, context)
		}(hook)
	}
}

// startErrorProcessor démarre le processeur d'erreurs asynchrone
func (iem *IntegratedErrorManager) startErrorProcessor() {
	iem.wg.Add(1)
	go func() {
		defer iem.wg.Done()
		for {
			select {
			case entry := <-iem.errorQueue:
				iem.processError(entry)
			case <-iem.ctx.Done():
				return
			}
		}
	}()
}

// processError traite une erreur individuellement
func (iem *IntegratedErrorManager) processError(entry ErrorEntry) {
	if iem.errorManager == nil {
		log.Printf("Error manager not configured, logging error: %s", entry.Message)
		return
	}

	// Valider l'erreur
	if err := iem.errorManager.ValidateError(entry); err != nil {
		log.Printf("Error validation failed: %v", err)
		return
	}

	// Cataloguer l'erreur
	if err := iem.errorManager.CatalogError(entry); err != nil {
		log.Printf("Error cataloging failed: %v", err)
	}
}

// determineErrorCode détermine le code d'erreur basé sur le type d'erreur
func determineErrorCode(err error) string {
	switch {
	case errors.Is(err, context.DeadlineExceeded):
		return "TIMEOUT_ERROR"
	case errors.Is(err, context.Canceled):
		return "CANCELED_ERROR"
	default:
		return "GENERAL_ERROR"
	}
}

// determineSeverity détermine la sévérité basée sur le message d'erreur
func determineSeverity(err error) string {
	message := err.Error()
	switch {
	case contains(message, "critical", "fatal", "panic"):
		return "CRITICAL"
	case contains(message, "error", "failed", "failure"):
		return "ERROR"
	case contains(message, "warning", "warn"):
		return "WARNING"
	default:
		return "INFO"
	}
}

// contains vérifie si une chaîne contient l'un des mots-clés
func contains(text string, keywords ...string) bool {
	for _, keyword := range keywords {
		if len(text) >= len(keyword) {
			for i := 0; i <= len(text)-len(keyword); i++ {
				if text[i:i+len(keyword)] == keyword {
					return true
				}
			}
		}
	}
	return false
}

// Shutdown arrête proprement le gestionnaire intégré
func (iem *IntegratedErrorManager) Shutdown() {
	iem.cancel()
	iem.wg.Wait()
	close(iem.errorQueue)
}

// Fonctions utilitaires pour l'intégration avec les autres managers

// PropagateError fonction globale pour la compatibilité
func PropagateError(module string, err error) {
	GetIntegratedErrorManager().PropagateError(module, err, nil)
}

// CentralizeError fonction globale pour la compatibilité
func CentralizeError(module string, err error) error {
	return GetIntegratedErrorManager().CentralizeError(module, err, nil)
}

// PropagateErrorWithContext propage une erreur avec contexte
func PropagateErrorWithContext(module string, err error, context map[string]interface{}) {
	GetIntegratedErrorManager().PropagateError(module, err, context)
}

// CentralizeErrorWithContext centralise une erreur avec contexte
func CentralizeErrorWithContext(module string, err error, context map[string]interface{}) error {
	return GetIntegratedErrorManager().CentralizeError(module, err, context)
}

// AddErrorHook ajoute un hook d'erreur global
func AddErrorHook(module string, hook ErrorHook) {
	GetIntegratedErrorManager().AddHook(module, hook)
}
