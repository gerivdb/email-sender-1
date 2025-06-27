// Stubs pour lever les erreurs de compilation liées à l'intégration d'erreurs
package integratedmanager

import (
	"context"
)

// ErrorEntry : structure d'exemple pour la gestion d'erreurs
type ErrorEntry struct {
	Code     string
	Message  string
	Severity string
	Context  map[string]interface{}
}

// GetIntegratedErrorManager : stub de récupération du gestionnaire d'erreurs intégré
func GetIntegratedErrorManager() *IntegratedErrorManager {
	return &IntegratedErrorManager{}
}

// IntegratedErrorManager : stub du gestionnaire d'erreurs intégré
type IntegratedErrorManager struct{}

// PropagateError : stub de propagation d'une erreur
func PropagateError(err error) {}

// PropagateErrorWithContext : stub de propagation d'une erreur avec contexte
func PropagateErrorWithContext(ctx context.Context, err error) {}

// CentralizeErrorWithContext : stub de centralisation d'une erreur avec contexte
func CentralizeErrorWithContext(ctx context.Context, entry ErrorEntry) {}

// AddErrorHook : stub d'ajout de hook d'erreur
func AddErrorHook(hook func(ErrorEntry)) {}

// determineSeverity : stub de détermination de la sévérité d'une erreur
func determineSeverity(err error) string {
	return "unknown"
}
