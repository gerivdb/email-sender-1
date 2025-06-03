package integratedmanager

import (
	"context"
	"errors"
	"fmt"
	"log"
	"strings"
	"sync"
	"time"
)

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
		"recipient": "user@example.com",
		"template":  "welcome",
		"attempt":   3,
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
	criticalError := errors.New("fatal: unauthorized access detected")
	PropagateErrorWithContext("security-manager", criticalError, map[string]interface{}{
		"ip_address": "192.168.1.100",
		"user_agent": "malicious-bot",
	})

	// Démonstration 4: Gestion d'erreurs de timeout
	fmt.Println("\n⏰ Démonstration 4: Gestion des timeouts")
	ctx, cancel := context.WithTimeout(context.Background(), 1*time.Millisecond)
	defer cancel()
	
	time.Sleep(2 * time.Millisecond) // Simuler une opération qui prend du temps
	
	if ctx.Err() != nil {
		PropagateErrorWithContext("api-manager", ctx.Err(), map[string]interface{}{
			"endpoint": "/api/v1/users",
			"timeout":  "1ms",
		})
	}

	// Démonstration 5: Erreurs multiples en parallèle
	fmt.Println("\n🔄 Démonstration 5: Erreurs multiples en parallèle")
	simulateMultipleErrors()

	// Attendre que tous les traitements asynchrones se terminent
	time.Sleep(200 * time.Millisecond)

	// Afficher les statistiques
	fmt.Println("\n📊 Statistiques finales:")
	printErrorStatistics(mockEM)
}

// simulateMultipleErrors simule plusieurs erreurs provenant de différents managers
func simulateMultipleErrors() {
	managers := []string{
		"dependency-manager",
		"mcp-manager",
		"n8n-manager",
		"process-manager",
		"roadmap-manager",
		"script-manager",
	}

	errors := []error{
		errors.New("dependency resolution failed"),
		errors.New("MCP connection timeout"),
		errors.New("n8n workflow execution error"),
		errors.New("process startup failure"),
		errors.New("roadmap validation error"),
		errors.New("script execution permission denied"),
	}

	for i, manager := range managers {
		go func(m string, e error) {
			context := map[string]interface{}{
				"timestamp": time.Now().Unix(),
				"manager":   m,
				"thread_id": fmt.Sprintf("thread-%d", i),
			}
			PropagateErrorWithContext(m, e, context)
		}(manager, errors[i])
	}
}

// printErrorStatistics affiche les statistiques des erreurs traitées
func printErrorStatistics(mockEM *MockErrorManager) {
	catalogedErrors := mockEM.GetCatalogedErrors()
	
	fmt.Printf("  📈 Total des erreurs cataloguées: %d\n", len(catalogedErrors))
	
	// Grouper par module
	moduleStats := make(map[string]int)
	severityStats := make(map[string]int)
	
	for _, err := range catalogedErrors {
		moduleStats[err.Module]++
		severityStats[err.Severity]++
	}
	
	fmt.Println("  📋 Répartition par module:")
	for module, count := range moduleStats {
		fmt.Printf("    - %s: %d erreurs\n", module, count)
	}
	
	fmt.Println("  🎯 Répartition par sévérité:")
	for severity, count := range severityStats {
		fmt.Printf("    - %s: %d erreurs\n", severity, count)
	}
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
		err     error
		context map[string]interface{}
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
		err     error
		context map[string]interface{}
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
		err     error
		context map[string]interface{}
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

// RunIntegrationTests exécute une suite complète de tests d'intégration
func RunIntegrationTests() error {
	fmt.Println("🧪 Exécution des tests d'intégration")
	
	// Test 1: Vérification du singleton
	iem1 := GetIntegratedErrorManager()
	iem2 := GetIntegratedErrorManager()
	
	if iem1 != iem2 {
		return errors.New("échec du test singleton: instances différentes")
	}
	fmt.Println("✅ Test singleton: RÉUSSI")

	// Test 2: Gestion des erreurs nil
	PropagateError("test", nil)
	centralizedErr := CentralizeError("test", nil)
	if centralizedErr != nil {
		return errors.New("échec du test erreur nil: erreur non-nil retournée")
	}
	fmt.Println("✅ Test erreur nil: RÉUSSI")

	// Test 3: Propagation avec contexte
	mockEM := NewMockErrorManager()
	iem1.SetErrorManager(mockEM)
	
	testErr := errors.New("test error")
	testContext := map[string]interface{}{"test": "value"}
	PropagateErrorWithContext("test-module", testErr, testContext)
	
	time.Sleep(50 * time.Millisecond)
	
	catalogedErrors := mockEM.GetCatalogedErrors()
	if len(catalogedErrors) != 1 {
		return fmt.Errorf("échec du test propagation: attendu 1 erreur, reçu %d", len(catalogedErrors))
	}
	
	if catalogedErrors[0].ManagerContext["test"] != "value" {
		return errors.New("échec du test contexte: contexte incorrect")
	}
	fmt.Println("✅ Test propagation avec contexte: RÉUSSI")

	iem1.Shutdown()
	
	// Reset pour les prochains tests
	integratedManager = nil
	once = sync.Once{}
	
	fmt.Println("🎉 Tous les tests d'intégration ont réussi!")
	return nil
}
