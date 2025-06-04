package integratedmanager

import (
	"errors"
	"fmt"
	"sync"
	"time"
)

// Types are defined in error_integration.go

// MockErrorManager is defined in integration_demo.go

// Gestionnaire d'erreurs intégré simplifié
type SimpleIntegratedManager struct {
	errorManager ErrorManager
	hooks        map[string][]func(string, error, map[string]interface{})
	mu           sync.RWMutex
}

func NewSimpleIntegratedManager() *SimpleIntegratedManager {
	return &SimpleIntegratedManager{
		hooks: make(map[string][]func(string, error, map[string]interface{})),
	}
}

func (sim *SimpleIntegratedManager) SetErrorManager(em ErrorManager) {
	sim.errorManager = em
}

func (sim *SimpleIntegratedManager) AddHook(module string, hook func(string, error, map[string]interface{})) {
	sim.mu.Lock()
	defer sim.mu.Unlock()
	sim.hooks[module] = append(sim.hooks[module], hook)
}

func (sim *SimpleIntegratedManager) PropagateError(module string, err error, context map[string]interface{}) {
	if err == nil {
		return
	}

	// Exécuter les hooks
	sim.executeHooks(module, err, context)

	// Créer une entrée d'erreur
	entry := ErrorEntry{
		ID:             fmt.Sprintf("err-%d", time.Now().Unix()),
		Timestamp:      time.Now(),
		Message:        err.Error(),
		StackTrace:     "stack trace placeholder",
		Module:         module,
		ErrorCode:      sim.determineErrorCode(err),
		ManagerContext: context,
		Severity:       sim.determineSeverity(err),
	}

	// Valider et cataloguer
	if sim.errorManager != nil {
		if valErr := sim.errorManager.ValidateError(entry); valErr == nil {
			sim.errorManager.CatalogError(entry)
		}
	}
}

func (sim *SimpleIntegratedManager) CentralizeError(module string, err error, context map[string]interface{}) error {
	if err == nil {
		return nil
	}

	wrappedErr := fmt.Errorf("centralized error from %s: %w", module, err)
	sim.PropagateError(module, wrappedErr, context)
	return wrappedErr
}

func (sim *SimpleIntegratedManager) executeHooks(module string, err error, context map[string]interface{}) {
	sim.mu.RLock()
	hooks := sim.hooks[module]
	sim.mu.RUnlock()

	for _, hook := range hooks {
		hook(module, err, context)
	}
}

func (sim *SimpleIntegratedManager) determineErrorCode(err error) string {
	message := err.Error()
	switch {
	case contains(message, "timeout"):
		return "TIMEOUT_ERROR"
	case contains(message, "connection"):
		return "CONNECTION_ERROR"
	case contains(message, "permission"):
		return "PERMISSION_ERROR"
	default:
		return "GENERAL_ERROR"
	}
}

func (sim *SimpleIntegratedManager) determineSeverity(err error) string {
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

// contains function is defined in error_integration.go

func mainSimpleTest() {
	fmt.Println("🧪 Test Phase 5.1 - Intégration avec integrated-manager")
	fmt.Println(fmt.Sprintf("%s", "================================================================"))

	// Initialiser le gestionnaire intégré
	integratedManager := NewSimpleIntegratedManager()
	mockEM := NewMockErrorManager()
	integratedManager.SetErrorManager(mockEM)

	// Test 1: Micro-étape 5.1.1 - Propagation d'erreurs dans les points critiques
	fmt.Println("\n📤 Test 1: Micro-étape 5.1.1 - Propagation d'erreurs dans les points critiques")
	testCriticalPointsIntegrationSimple(integratedManager, mockEM)

	// Test 2: Micro-étape 5.1.2 - Propagation entre managers
	fmt.Println("\n🔄 Test 2: Micro-étape 5.1.2 - Propagation entre managers")
	testManagerErrorPropagationSimple(integratedManager, mockEM)

	// Test 3: Micro-étape 5.2.1 - Centralisation des erreurs
	fmt.Println("\n🎯 Test 3: Micro-étape 5.2.1 - Centralisation des erreurs")
	testErrorCentralizationSimple(integratedManager, mockEM)

	// Test 4: Micro-étape 5.2.2 - Scénarios simulés
	fmt.Println("\n🎭 Test 4: Micro-étape 5.2.2 - Scénarios d'erreurs simulés")
	testSimulatedErrorScenariosSimple(integratedManager, mockEM)

	fmt.Println("\n✅ Tests Phase 5.1 terminés avec succès!")

	// Afficher les statistiques finales
	catalogedErrors := mockEM.GetCatalogedErrors()
	fmt.Printf("\n📊 Statistiques finales: %d erreurs cataloguées\n", len(catalogedErrors))

	// Grouper par module et sévérité
	moduleStats := make(map[string]int)
	severityStats := make(map[string]int)

	for _, err := range catalogedErrors {
		moduleStats[err.Module]++
		severityStats[err.Severity]++
	}

	fmt.Println("\n📋 Répartition par module:")
	for module, count := range moduleStats {
		fmt.Printf("  - %s: %d erreurs\n", module, count)
	}

	fmt.Println("\n🎯 Répartition par sévérité:")
	for severity, count := range severityStats {
		fmt.Printf("  - %s: %d erreurs\n", severity, count)
	}
}

func testCriticalPointsIntegrationSimple(manager *SimpleIntegratedManager, mockEM *MockErrorManager) {
	criticalErrors := []struct {
		module  string
		err     error
		context map[string]interface{}
	}{
		{
			"dependency-manager",
			errors.New("critical: failed to resolve core dependencies"),
			map[string]interface{}{"stage": "initialization", "critical": true},
		},
		{
			"mcp-manager",
			errors.New("critical: MCP server unreachable"),
			map[string]interface{}{"server": "main-mcp", "retries": 3},
		},
		{
			"n8n-manager",
			errors.New("critical: workflow engine crashed"),
			map[string]interface{}{"workflow_count": 15, "active_executions": 42},
		},
	}

	for _, critErr := range criticalErrors {
		manager.PropagateError(critErr.module, critErr.err, critErr.context)
		fmt.Printf("  ✓ Erreur critique propagée depuis %s\n", critErr.module)
	}

	time.Sleep(100 * time.Millisecond)
	catalogedErrors := mockEM.GetCatalogedErrors()
	fmt.Printf("  📊 %d erreurs critiques cataloguées\n", len(catalogedErrors))
}

func testManagerErrorPropagationSimple(manager *SimpleIntegratedManager, mockEM *MockErrorManager) {
	// Ajouter des hooks pour simuler la propagation
	manager.AddHook("dependency-manager", func(module string, err error, context map[string]interface{}) {
		fmt.Printf("  🎣 Hook exécuté pour %s: %s\n", module, err.Error())
	})

	cascadeErrors := []struct {
		module  string
		err     error
		context map[string]interface{}
	}{
		{
			"dependency-manager",
			errors.New("package resolution timeout"),
			map[string]interface{}{"package": "critical-lib", "timeout": "30s"},
		},
		{
			"script-manager",
			errors.New("build script failed due to missing dependency"),
			map[string]interface{}{"script": "build.ps1", "dependency": "critical-lib"},
		},
	}

	for _, cascadeErr := range cascadeErrors {
		manager.PropagateError(cascadeErr.module, cascadeErr.err, cascadeErr.context)
		fmt.Printf("  ✓ Erreur en cascade depuis %s\n", cascadeErr.module)
	}
}

func testErrorCentralizationSimple(manager *SimpleIntegratedManager, mockEM *MockErrorManager) {
	errorsToCentralize := []struct {
		module string
		err    error
	}{
		{"email-manager", errors.New("SMTP connection failed")},
		{"database-manager", errors.New("connection pool exhausted")},
		{"auth-manager", errors.New("JWT token validation failed")},
	}

	for _, errInfo := range errorsToCentralize {
		centralizedErr := manager.CentralizeError(errInfo.module, errInfo.err, nil)
		if centralizedErr != nil {
			fmt.Printf("  ✓ Erreur de %s centralisée\n", errInfo.module)
		}
	}

	// Test avec erreur nil
	nilErr := manager.CentralizeError("test-manager", nil, nil)
	if nilErr == nil {
		fmt.Println("  ✓ Gestion correcte des erreurs nil")
	}
}

func testSimulatedErrorScenariosSimple(manager *SimpleIntegratedManager, mockEM *MockErrorManager) {
	scenarios := []struct {
		name    string
		module  string
		err     error
		context map[string]interface{}
	}{
		{
			"Erreur de démarrage",
			"process-manager",
			errors.New("port 8080 already in use"),
			map[string]interface{}{"port": 8080, "service": "http-server"},
		},
		{
			"Erreur de runtime",
			"n8n-manager",
			errors.New("workflow execution timeout"),
			map[string]interface{}{"workflow_id": "email-campaign-001", "timeout": "5m"},
		},
		{
			"Erreur de shutdown",
			"process-manager",
			errors.New("graceful shutdown timeout"),
			map[string]interface{}{"process": "email-worker", "timeout": "30s"},
		},
	}

	for _, scenario := range scenarios {
		fmt.Printf("  🎭 Scénario: %s\n", scenario.name)
		manager.PropagateError(scenario.module, scenario.err, scenario.context)
	}
}
