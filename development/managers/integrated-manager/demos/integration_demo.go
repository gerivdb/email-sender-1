package demos

import (
	"context"
	"errors"
	"fmt"
	"log"
	"strings"
	"sync"
	"time"
)

// MockErrorManager implements ErrorManager for demo purposes
type MockErrorManager struct {
	loggedErrors		[]LoggedError
	catalogedErrors		[]ErrorEntry
	validationErrors	[]ErrorEntry
	mu			sync.Mutex
}

type LoggedError struct {
	Err	error
	Module	string
	Code	string
}

// NewMockErrorManager creates a new mock error manager
func NewMockErrorManager() *MockErrorManager {
	return &MockErrorManager{
		loggedErrors:		make([]LoggedError, 0),
		catalogedErrors:	make([]ErrorEntry, 0),
	}
}

func (m *MockErrorManager) LogError(err error, module string, code string) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.loggedErrors = append(m.loggedErrors, LoggedError{
		Err:	err,
		Module:	module,
		Code:	code,
	})
	log.Printf("📝 Logged error from %s: %s", module, err.Error())
}

func (m *MockErrorManager) CatalogError(entry ErrorEntry) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.catalogedErrors = append(m.catalogedErrors, entry)
	log.Printf("📚 Cataloged error: %s from %s (Severity: %s)", entry.Message, entry.Module, entry.Severity)
	return nil
}

func (m *MockErrorManager) ValidateError(entry ErrorEntry) error {
	if entry.Message == "" || entry.Module == "" {
		return errors.New("invalid error entry")
	}
	return nil
}

func (m *MockErrorManager) GetLoggedErrors() []LoggedError {
	m.mu.Lock()
	defer m.mu.Unlock()
	return append([]LoggedError{}, m.loggedErrors...)
}

func (m *MockErrorManager) GetCatalogedErrors() []ErrorEntry {
	m.mu.Lock()
	defer m.mu.Unlock()
	return append([]ErrorEntry{}, m.catalogedErrors...)
}

// DemoIntegration démontre l'utilisation du gestionnaire d'erreurs intégré
func DemoIntegration() {
	fmt.Println("🚀 Démonstration de l'intégration du gestionnaire d'erreurs")
	fmt.Println(strings.Repeat("=", 60))

	// Obtenir l'instance du gestionnaire intégré
	iem := GetIntegratedErrorManager()
	defer iem.Shutdown()

	// Configurer un mock error manager pour la démonstration
	mockEM := NewMockErrorManager()
	iem.SetErrorManager(mockEM)

	// Démonstration 1: Propagation d'erreur simple
	fmt.Println("\n📤 Démonstration 1: Propagation d'erreur simple")
	testError := errors.New("Erreur de connexion à la base de données")
	PropagateError("database-manager", testError)

	// Démonstration 2: Centralisation d'erreur avec contexte
	fmt.Println("\n🎯 Démonstration 2: Centralisation avec contexte")
	emailError := errors.New("Échec d'envoi d'email")
	emailContext := map[string]interface{}{
		"recipient":	"user@example.com",
		"template":	"welcome",
		"attempt":	3,
	}
	CentralizeErrorWithContext("email-manager", emailError, emailContext)

	// Démonstration 3: Hooks d'erreur
	fmt.Println("\n🎣 Démonstration 3: Hooks d'erreur personnalisés")

	// Ajouter un hook pour les erreurs critiques
	AddErrorHook("security-manager", func(module string, err error, context map[string]interface{}) {
		if determineSeverity(err) == "CRITICAL" {
			fmt.Printf("🚨 ALERTE SÉCURITÉ: %s - %s\n", module, err.Error())
		}
	})

	// Déclencher une erreur critique
	criticalError := errors.New("critical: unauthorized access attempt detected")
	PropagateErrorWithContext("security-manager", criticalError, map[string]interface{}{
		"ip":		"192.168.1.100",
		"user":		"unknown",
		"action":	"admin_access",
	})

	// Démonstration 4: Gestion des timeouts
	fmt.Println("\n⏰ Démonstration 4: Gestion des timeouts")
	timeoutCtx, cancel := context.WithTimeout(context.Background(), 1*time.Millisecond)
	defer cancel()

	// Simuler un timeout
	<-timeoutCtx.Done()
	timeoutError := timeoutCtx.Err()
	PropagateError("operation-manager", timeoutError)

	// Laisser le temps au traitement asynchrone
	time.Sleep(100 * time.Millisecond)

	// Afficher les statistiques
	printErrorStatistics(mockEM)
}

// SimulateManagerErrors simule des erreurs spécifiques à chaque manager
func SimulateManagerErrors() {
	fmt.Println("🔧 Simulation d'erreurs spécifiques aux managers")

	iem := GetIntegratedErrorManager()
	defer iem.Shutdown()

	mockEM := NewMockErrorManager()
	iem.SetErrorManager(mockEM)

	// Erreurs du dependency-manager
	fmt.Println("\n🔗 Erreurs du dependency-manager:")
	depErrors := []struct {
		err	error
		context	map[string]interface{}
	}{
		{
			errors.New("circular dependency detected"),
			map[string]interface{}{"package": "github.com/example/pkg", "version": "v1.2.3"},
		},
		{
			errors.New("package not found"),
			map[string]interface{}{"package": "missing-pkg", "registry": "npm"},
		},
	}

	for _, depErr := range depErrors {
		PropagateErrorWithContext("dependency-manager", depErr.err, depErr.context)
	}

	// Erreurs du mcp-manager
	fmt.Println("\n💬 Erreurs du mcp-manager:")
	mcpErrors := []struct {
		err	error
		context	map[string]interface{}
	}{
		{
			errors.New("MCP server connection refused"),
			map[string]interface{}{"server": "localhost:8080", "protocol": "websocket"},
		},
		{
			errors.New("invalid MCP message format"),
			map[string]interface{}{"message_id": "msg-123", "expected": "json", "received": "xml"},
		},
	}

	for _, mcpErr := range mcpErrors {
		PropagateErrorWithContext("mcp-manager", mcpErr.err, mcpErr.context)
	}

	// Erreurs du n8n-manager
	fmt.Println("\n🔄 Erreurs du n8n-manager:")
	n8nErrors := []struct {
		err	error
		context	map[string]interface{}
	}{
		{
			errors.New("workflow execution timeout"),
			map[string]interface{}{"workflow_id": "wf-456", "timeout": "30s", "step": "send-email"},
		},
		{
			errors.New("node configuration invalid"),
			map[string]interface{}{"node_type": "EmailNode", "field": "credentials", "validation": "required"},
		},
	}

	for _, n8nErr := range n8nErrors {
		PropagateErrorWithContext("n8n-manager", n8nErr.err, n8nErr.context)
	}

	time.Sleep(100 * time.Millisecond)
	printErrorStatistics(mockEM)
}

// printErrorStatistics affiche les statistiques des erreurs
func printErrorStatistics(mockEM *MockErrorManager) {
	fmt.Println("\n📊 Statistiques des erreurs:")
	fmt.Println(strings.Repeat("-", 40))

	catalogedErrors := mockEM.GetCatalogedErrors()
	loggedErrors := mockEM.GetLoggedErrors()

	fmt.Printf("📚 Erreurs cataloguées: %d\n", len(catalogedErrors))
	fmt.Printf("📝 Erreurs loggées: %d\n", len(loggedErrors))

	if len(catalogedErrors) > 0 {
		fmt.Println("\n📋 Détails des erreurs cataloguées:")
		for i, err := range catalogedErrors {
			if i >= 5 {	// Limiter l'affichage aux 5 premières
				fmt.Printf("... et %d autres erreurs\n", len(catalogedErrors)-5)
				break
			}
			fmt.Printf("  %d. [%s] %s - %s (Sévérité: %s)\n",
				i+1, err.Module, err.ErrorCode, err.Message, err.Severity)
		}
	}
}

// DemoIntegrationWithConcurrency démontre la gestion d'erreurs concurrent
func DemoIntegrationWithConcurrency() {
	fmt.Println("🚀 Démonstration de l'intégration avec concurrence")
	fmt.Println(strings.Repeat("=", 60))

	iem := GetIntegratedErrorManager()
	defer iem.Shutdown()

	mockEM := NewMockErrorManager()
	iem.SetErrorManager(mockEM)

	// Simuler des erreurs concurrentes de plusieurs managers
	var wg sync.WaitGroup
	managers := []string{"config-manager", "roadmap-manager", "script-manager", "process-manager"}

	for i, manager := range managers {
		wg.Add(1)
		go func(mgr string, id int) {
			defer wg.Done()

			for j := 0; j < 3; j++ {
				err := errors.New(fmt.Sprintf("concurrent error %d from %s", j+1, mgr))
				context := map[string]interface{}{
					"goroutine":	id,
					"iteration":	j,
					"timestamp":	time.Now(),
				}
				PropagateErrorWithContext(mgr, err, context)
				time.Sleep(10 * time.Millisecond)
			}
		}(manager, i)
	}

	wg.Wait()
	time.Sleep(200 * time.Millisecond)

	fmt.Println("\n🏁 Résultats de la concurrence:")
	printErrorStatistics(mockEM)
}
