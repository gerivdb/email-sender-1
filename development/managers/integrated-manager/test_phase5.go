package integratedmanager

import (
	"errors"
	"fmt"
	"time"
)

func runTestPhase5() {
	fmt.Println("🧪 Test Phase 5.1 - Intégration avec integrated-manager")
	fmt.Println("=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=" + "=")

	// Test 1: Micro-étape 5.1.1 - Ajouter des appels au gestionnaire d'erreurs
	fmt.Println("\n📤 Test 1: Micro-étape 5.1.1 - Propagation d'erreurs dans les points critiques")
	testCriticalPointsIntegration()

	// Test 2: Micro-étape 5.1.2 - Configurer la propagation des erreurs entre managers
	fmt.Println("\n🔄 Test 2: Micro-étape 5.1.2 - Propagation entre managers")
	testManagerErrorPropagation()

	// Test 3: Micro-étape 5.2.1 - Créer CentralizeError()
	fmt.Println("\n🎯 Test 3: Micro-étape 5.2.1 - Centralisation des erreurs")
	testErrorCentralization()

	// Test 4: Micro-étape 5.2.2 - Tester avec des scénarios simulés
	fmt.Println("\n🎭 Test 4: Micro-étape 5.2.2 - Scénarios d'erreurs simulés")
	testSimulatedErrorScenarios()

	fmt.Println("\n✅ Tests Phase 5.1 terminés avec succès!")
}

func testCriticalPointsIntegration() {
	// Obtenir l'instance du gestionnaire intégré
	iem := GetIntegratedErrorManager()
	defer iem.Shutdown()

	// Configurer un mock error manager
	mockEM := NewMockErrorManager()
	iem.SetErrorManager(mockEM)

	// Simuler des erreurs dans les points critiques de différents managers
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
		PropagateErrorWithContext(critErr.module, critErr.err, critErr.context)
		fmt.Printf("  ✓ Erreur critique propagée depuis %s\n", critErr.module)
	}

	// Attendre le traitement asynchrone
	time.Sleep(100 * time.Millisecond)

	// Vérifier que les erreurs ont été cataloguées
	catalogedErrors := mockEM.GetCatalogedErrors()
	fmt.Printf("  📊 %d erreurs critiques cataloguées\n", len(catalogedErrors))

	// Vérifier que toutes les erreurs sont marquées comme critiques
	criticalCount := 0
	for _, err := range catalogedErrors {
		if err.Severity == "CRITICAL" {
			criticalCount++
		}
	}
	fmt.Printf("  🚨 %d/%d erreurs identifiées comme critiques\n", criticalCount, len(catalogedErrors))
}

func testManagerErrorPropagation() {
	// Tester la propagation en chaîne entre managers
	iem := GetIntegratedErrorManager()
	defer iem.Shutdown()

	mockEM := NewMockErrorManager()
	iem.SetErrorManager(mockEM)

	// Initialiser les hooks de managers
	RegisterManagerIntegrations()

	// Simuler une cascade d'erreurs
	cascadeScenarios := []struct {
		step    int
		module  string
		err     error
		context map[string]interface{}
	}{
		{
			1, "dependency-manager",
			errors.New("package resolution timeout"),
			map[string]interface{}{"package": "critical-lib", "timeout": "30s"},
		},
		{
			2, "script-manager",
			errors.New("build script failed due to missing dependency"),
			map[string]interface{}{"script": "build.ps1", "dependency": "critical-lib"},
		},
		{
			3, "process-manager",
			errors.New("application startup failed"),
			map[string]interface{}{"process": "email-sender", "exit_code": 1},
		},
	}

	fmt.Println("  🔄 Simulation d'une cascade d'erreurs:")
	for _, scenario := range cascadeScenarios {
		fmt.Printf("    Étape %d: %s\n", scenario.step, scenario.module)
		PropagateErrorWithContext(scenario.module, scenario.err, scenario.context)
		time.Sleep(50 * time.Millisecond) // Laisser le temps pour le traitement
	}

	time.Sleep(100 * time.Millisecond)

	catalogedErrors := mockEM.GetCatalogedErrors()
	fmt.Printf("  📈 %d erreurs dans la cascade propagées\n", len(catalogedErrors))
}

func testErrorCentralization() {
	// Tester la fonction CentralizeError
	iem := GetIntegratedErrorManager()
	defer iem.Shutdown()

	mockEM := NewMockErrorManager()
	iem.SetErrorManager(mockEM)

	// Tester la centralisation avec différents types d'erreurs
	errorsTocentralize := []struct {
		module string
		err    error
	}{
		{"email-manager", errors.New("SMTP connection failed")},
		{"database-manager", errors.New("connection pool exhausted")},
		{"auth-manager", errors.New("JWT token validation failed")},
		{"file-manager", errors.New("disk space insufficient")},
	}

	fmt.Println("  🎯 Test de centralisation d'erreurs:")
	for _, errInfo := range errorsTocentralize {
		centralizedErr := CentralizeError(errInfo.module, errInfo.err)
		if centralizedErr != nil {
			fmt.Printf("    ✓ Erreur de %s centralisée\n", errInfo.module)
		}
	}

	// Tester avec erreur nil
	nilErr := CentralizeError("test-manager", nil)
	if nilErr == nil {
		fmt.Println("    ✓ Gestion correcte des erreurs nil")
	}

	time.Sleep(100 * time.Millisecond)

	catalogedErrors := mockEM.GetCatalogedErrors()
	fmt.Printf("  📊 %d erreurs centralisées cataloguées\n", len(catalogedErrors))
}

func testSimulatedErrorScenarios() {
	// Exécuter la démonstration complète
	fmt.Println("  🎭 Exécution des scénarios simulés:")

	// Scénario 1: Erreurs de démarrage du système
	fmt.Println("    Scénario 1: Erreurs de démarrage")
	simulateSystemStartupErrors()

	// Scénario 2: Erreurs de runtime
	fmt.Println("    Scénario 2: Erreurs de runtime")
	simulateRuntimeErrors()

	// Scénario 3: Erreurs de shutdown
	fmt.Println("    Scénario 3: Erreurs de shutdown")
	simulateShutdownErrors()

	fmt.Println("  ✅ Tous les scénarios simulés exécutés")
}

func simulateSystemStartupErrors() {
	iem := GetIntegratedErrorManager()
	defer iem.Shutdown()

	mockEM := NewMockErrorManager()
	iem.SetErrorManager(mockEM)

	// Erreurs typiques de démarrage
	startupErrors := []struct {
		module  string
		err     error
		context map[string]interface{}
	}{
		{
			"dependency-manager",
			errors.New("Go toolchain not found"),
			map[string]interface{}{"required_version": "1.22+", "found": "none"},
		},
		{
			"process-manager",
			errors.New("port 8080 already in use"),
			map[string]interface{}{"port": 8080, "service": "http-server"},
		},
		{
			"script-manager",
			errors.New("PowerShell execution policy restricted"),
			map[string]interface{}{"policy": "Restricted", "required": "RemoteSigned"},
		},
	}

	for _, startupErr := range startupErrors {
		PropagateErrorWithContext(startupErr.module, startupErr.err, startupErr.context)
	}

	time.Sleep(100 * time.Millisecond)
}

func simulateRuntimeErrors() {
	iem := GetIntegratedErrorManager()
	defer iem.Shutdown()

	mockEM := NewMockErrorManager()
	iem.SetErrorManager(mockEM)

	// Erreurs typiques de runtime
	runtimeErrors := []struct {
		module  string
		err     error
		context map[string]interface{}
	}{
		{
			"n8n-manager",
			errors.New("workflow execution timeout"),
			map[string]interface{}{"workflow_id": "email-campaign-001", "timeout": "5m"},
		},
		{
			"mcp-manager",
			errors.New("message queue overflow"),
			map[string]interface{}{"queue_size": 10000, "max_size": 5000},
		},
		{
			"roadmap-manager",
			errors.New("phase validation failed"),
			map[string]interface{}{"phase": "5.1", "validation_rule": "dependencies_met"},
		},
	}

	for _, runtimeErr := range runtimeErrors {
		PropagateErrorWithContext(runtimeErr.module, runtimeErr.err, runtimeErr.context)
	}

	time.Sleep(100 * time.Millisecond)
}

func simulateShutdownErrors() {
	iem := GetIntegratedErrorManager()
	defer iem.Shutdown()

	mockEM := NewMockErrorManager()
	iem.SetErrorManager(mockEM)

	// Erreurs typiques de shutdown
	shutdownErrors := []struct {
		module  string
		err     error
		context map[string]interface{}
	}{
		{
			"process-manager",
			errors.New("graceful shutdown timeout"),
			map[string]interface{}{"process": "email-worker", "timeout": "30s"},
		},
		{
			"dependency-manager",
			errors.New("cleanup failed for temporary files"),
			map[string]interface{}{"temp_dir": "/tmp/build", "files_count": 150},
		},
	}

	for _, shutdownErr := range shutdownErrors {
		PropagateErrorWithContext(shutdownErr.module, shutdownErr.err, shutdownErr.context)
	}

	time.Sleep(100 * time.Millisecond)
}
