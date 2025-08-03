// error_manager.go — Implémentation Roo de ErrorManager avec intégration MonitoringManager
//
// Cette implémentation transmet automatiquement les événements critiques
// (ProcessError, CatalogError, ValidateErrorEntry) au MonitoringManager Roo
// selon les conventions AGENTS.md et la spécification Roo.
// Aucune logique métier avancée, uniquement intégration et documentation Go.

package automatisation_doc

import (
	"context"
)

// ErrorManagerImpl implémente ErrorManager et intègre MonitoringManager Roo.
type ErrorManagerImpl struct {
	monitoring *MonitoringManager
}

// NewErrorManagerImpl crée un ErrorManager avec intégration MonitoringManager.
func NewErrorManagerImpl(monitoring *MonitoringManager) *ErrorManagerImpl {
	return &ErrorManagerImpl{
		monitoring: monitoring,
	}
}

// ProcessError centralise le traitement d’erreur et transmet l’événement au MonitoringManager.
//
// À chaque appel, un événement de type "ProcessError" est transmis au MonitoringManager
// pour collecte automatique des métriques/documentation Roo.
func (e *ErrorManagerImpl) ProcessError(ctx context.Context, err error, component, operation string, hooks *ErrorHooks) error {
	if e.monitoring != nil {
		// Transmission d’un événement d’opération critique au MonitoringManager.
		_, _ = e.monitoring.StartOperationMonitoring(ctx, "ProcessError")
		// Optionnel : enrichir avec des métadonnées si besoin.
	}
	// Logique métier à compléter.
	return nil
}

// CatalogError journalise une erreur et transmet l’événement au MonitoringManager.
//
// À chaque appel, un événement de type "CatalogError" est transmis au MonitoringManager.
func (e *ErrorManagerImpl) CatalogError(entry ErrorEntry) error {
	if e.monitoring != nil {
		_, _ = e.monitoring.StartOperationMonitoring(context.Background(), "CatalogError")
	}
	// Logique métier à compléter.
	return nil
}

// ValidateErrorEntry valide une entrée d’erreur et transmet l’événement au MonitoringManager.
//
// À chaque appel, un événement de type "ValidateErrorEntry" est transmis au MonitoringManager.
func (e *ErrorManagerImpl) ValidateErrorEntry(entry ErrorEntry) error {
	if e.monitoring != nil {
		_, _ = e.monitoring.StartOperationMonitoring(context.Background(), "ValidateErrorEntry")
	}
	// Logique métier à compléter.
	return nil
}
