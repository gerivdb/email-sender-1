# Makefile pour les tests de la Phase 5
# Usage: make test-phase5, make benchmark, make validate-all

.PHONY: help test-unit test-integration test-benchmark test-all validate-phase5 clean

# Variables
GO = go
TEST_FLAGS = -v -race
BENCHMARK_FLAGS = -bench=. -benchmem -benchtime=10s
PROJECT_ROOT = $(shell pwd)
REPORTS_DIR = $(PROJECT_ROOT)/development/tests/reports

# Help target
help:
	@echo "=== Tests Phase 5 - Commandes disponibles ==="
	@echo "make test-unit          - Exécute les tests unitaires"
	@echo "make test-integration   - Exécute les tests d'intégration"
	@echo "make test-benchmark     - Exécute les benchmarks"
	@echo "make test-all          - Exécute tous les tests"
	@echo "make validate-phase5   - Validation complète Phase 5"
	@echo "make test-short        - Tests rapides (mode court)"
	@echo "make clean             - Nettoie les rapports et fichiers temporaires"

# Préparation de l'environnement
setup:
	@echo "=== Préparation de l'environnement de test ==="
	@mkdir -p $(REPORTS_DIR)
	@mkdir -p $(PROJECT_ROOT)/tmp/test_data
	@$(GO) mod tidy
	@$(GO) mod download

# Tests unitaires
test-unit: setup
	@echo "=== Exécution des tests unitaires ==="
	@$(GO) test $(TEST_FLAGS) -timeout=5m ./development/tests/unit/...
	@echo "✅ Tests unitaires terminés"

# Tests d'intégration
test-integration: setup
	@echo "=== Exécution des tests d'intégration ==="
	@$(GO) test $(TEST_FLAGS) -timeout=10m ./development/tests/integration/...
	@echo "✅ Tests d'intégration terminés"

# Benchmarks
test-benchmark: setup
	@echo "=== Exécution des benchmarks ==="
	@$(GO) test $(BENCHMARK_FLAGS) -timeout=30m ./development/tests/benchmarks/...
	@echo "✅ Benchmarks terminés"

# Tests de performance Python vs Go
test-comparison: setup
	@echo "=== Comparaison Python vs Go ==="
	@$(GO) test -v -timeout=20m -run TestPythonVsGoVectorizationPerformance ./development/tests/benchmarks/...
	@echo "✅ Comparaison terminée"

# Tests de charge
test-load: setup
	@echo "=== Tests de charge ==="
	@$(GO) test -v -timeout=30m -run TestLoadWith100kTasks ./development/tests/benchmarks/...
	@$(GO) test -v -timeout=15m -run TestConcurrencyMultipleGoroutines ./development/tests/benchmarks/...
	@echo "✅ Tests de charge terminés"

# Tests courts (pour développement rapide)
test-short: setup
	@echo "=== Tests en mode court ==="
	@SHORT_MODE=true $(GO) test -short $(TEST_FLAGS) -timeout=2m ./development/tests/unit/...
	@SHORT_MODE=true $(GO) test -short $(TEST_FLAGS) -timeout=5m ./development/tests/integration/...
	@echo "✅ Tests courts terminés"

# Tous les tests
test-all: test-unit test-integration test-benchmark
	@echo "✅ Tous les tests terminés avec succès"

# Validation complète Phase 5
validate-phase5: setup
	@echo "=== Validation complète Phase 5 ==="
	@$(GO) run ./development/tests/validate_phase5.go
	@echo "✅ Validation Phase 5 terminée"

# Tests avec couverture
test-coverage: setup
	@echo "=== Tests avec couverture ==="
	@$(GO) test -coverprofile=coverage.out -coverpkg=./... ./development/tests/unit/...
	@$(GO) tool cover -html=coverage.out -o $(REPORTS_DIR)/coverage.html
	@$(GO) tool cover -func=coverage.out | grep total
	@echo "📊 Rapport de couverture généré: $(REPORTS_DIR)/coverage.html"

# Tests CI/CD (pour intégration continue)
test-ci: setup
	@echo "=== Tests pour CI/CD ==="
	@CI=true $(GO) test -timeout=30m -json ./development/tests/... > $(REPORTS_DIR)/test_results.json
	@echo "✅ Tests CI/CD terminés"

# Nettoyage
clean:
	@echo "=== Nettoyage ==="
	@rm -rf $(REPORTS_DIR)/*
	@rm -rf $(PROJECT_ROOT)/tmp/test_data/*
	@rm -f coverage.out
	@rm -f *.json
	@rm -f phase5_validation_report_*.txt
	@rm -f python_vs_go_comparison_report.json
	@echo "🧹 Nettoyage terminé"

# Tests avec options personnalisées
test-custom:
	@echo "=== Tests personnalisés ==="
	@echo "Usage: make test-custom ARGS='<arguments>'"
	@$(GO) test $(ARGS)

# Vérification de la qualité du code
lint:
	@echo "=== Vérification de la qualité du code ==="
	@which golangci-lint > /dev/null || (echo "golangci-lint non installé. Installation..." && go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest)
	@golangci-lint run ./development/tests/...
	@echo "✅ Vérification qualité terminée"

# Tests de régression
test-regression: setup
	@echo "=== Tests de régression ==="
	@$(GO) test -count=5 $(TEST_FLAGS) ./development/tests/unit/...
	@$(GO) test -count=3 $(TEST_FLAGS) ./development/tests/integration/...
	@echo "✅ Tests de régression terminés"

# Profiling des performances
profile-cpu:
	@echo "=== Profiling CPU ==="
	@$(GO) test -cpuprofile=$(REPORTS_DIR)/cpu.prof -bench=. ./development/tests/benchmarks/...
	@$(GO) tool pprof -http=:6060 $(REPORTS_DIR)/cpu.prof &
	@echo "🔍 Profiler CPU disponible sur http://localhost:6060"

profile-mem:
	@echo "=== Profiling Mémoire ==="
	@$(GO) test -memprofile=$(REPORTS_DIR)/mem.prof -bench=. ./development/tests/benchmarks/...
	@$(GO) tool pprof -http=:6061 $(REPORTS_DIR)/mem.prof &
	@echo "🔍 Profiler Mémoire disponible sur http://localhost:6061"

# Documentation des tests
doc-tests:
	@echo "=== Documentation des tests ==="
	@$(GO) doc ./development/tests/unit
	@$(GO) doc ./development/tests/integration
	@$(GO) doc ./development/tests/benchmarks

# Statistiques des tests
stats:
	@echo "=== Statistiques des tests ==="
	@echo "Nombre de fichiers de test:"
	@find ./development/tests -name "*_test.go" | wc -l
	@echo "Nombre de fonctions de test:"
	@grep -r "func Test" ./development/tests --include="*_test.go" | wc -l
	@echo "Nombre de benchmarks:"
	@grep -r "func Benchmark" ./development/tests --include="*_test.go" | wc -l
	@echo "Lignes de code de test:"
	@find ./development/tests -name "*.go" -exec wc -l {} + | tail -n 1

# Aide spécifique pour les développeurs
dev-help:
	@echo "=== Guide développeur - Tests Phase 5 ==="
	@echo ""
	@echo "🧪 WORKFLOW TYPIQUE:"
	@echo "1. make test-short          # Tests rapides pendant développement"
	@echo "2. make test-unit           # Tests unitaires complets"
	@echo "3. make test-integration    # Tests d'intégration"
	@echo "4. make validate-phase5     # Validation finale"
	@echo ""
	@echo "🔍 DEBUGGING:"
	@echo "- make test-custom ARGS='-v -run TestSpecificFunction'"
	@echo "- make profile-cpu          # Pour analyser les performances"
	@echo "- make test-coverage        # Pour voir la couverture"
	@echo ""
	@echo "📊 MÉTRIQUES:"
	@echo "- make stats                # Statistiques des tests"
	@echo "- make lint                 # Qualité du code"
	@echo ""
	@echo "🚀 CI/CD:"
	@echo "- make test-ci              # Tests pour intégration continue"
