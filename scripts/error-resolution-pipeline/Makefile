# Makefile pour Error Resolution Pipeline Go Native
# Version 1.0.0

.PHONY: help build test clean install run metrics docker docs

# Variables
BINARY_NAME=pipeline
VERSION=1.0.0
BUILD_DIR=./build
CONFIG_FILE=src/config/pipeline_config.json
TARGET_PATH=../../.github/docs/algorithms

# Couleurs pour l'affichage
CYAN=\033[36m
GREEN=\033[32m
YELLOW=\033[33m
RED=\033[31m
NC=\033[0m # No Color

help: ## Affiche l'aide
	@echo "$(CYAN)Error Resolution Pipeline Go Native v$(VERSION)$(NC)"
	@echo "$(YELLOW)Commandes disponibles:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'

build: ## Compile le pipeline
	@echo "$(CYAN)🔨 Compilation du pipeline...$(NC)"
	@go mod download
	@mkdir -p $(BUILD_DIR)
	@go build -ldflags="-X main.Version=$(VERSION)" -o $(BUILD_DIR)/$(BINARY_NAME) ./cmd/pipeline
	@echo "$(GREEN)✓ Pipeline compilé avec succès dans $(BUILD_DIR)/$(BINARY_NAME)$(NC)"

build-windows: ## Compile pour Windows
	@echo "$(CYAN)🔨 Compilation pour Windows...$(NC)"
	@mkdir -p $(BUILD_DIR)
	@GOOS=windows GOARCH=amd64 go build -ldflags="-X main.Version=$(VERSION)" -o $(BUILD_DIR)/$(BINARY_NAME).exe ./cmd/pipeline
	@echo "$(GREEN)✓ Binary Windows créé: $(BUILD_DIR)/$(BINARY_NAME).exe$(NC)"

test: ## Lance les tests unitaires
	@echo "$(CYAN)🧪 Lancement des tests...$(NC)"
	@go test -v ./pkg/...
	@echo "$(GREEN)✓ Tests terminés$(NC)"

test-coverage: ## Lance les tests avec couverture
	@echo "$(CYAN)📊 Tests avec couverture...$(NC)"
	@go test -coverprofile=coverage.out ./pkg/...
	@go tool cover -html=coverage.out -o coverage.html
	@echo "$(GREEN)✓ Rapport de couverture généré: coverage.html$(NC)"

clean: ## Nettoie les fichiers de build
	@echo "$(CYAN)🧹 Nettoyage...$(NC)"
	@rm -rf $(BUILD_DIR)
	@rm -f coverage.out coverage.html
	@rm -f *.exe
	@echo "$(GREEN)✓ Nettoyage terminé$(NC)"

install: build ## Installe le binary dans $GOPATH/bin
	@echo "$(CYAN)📦 Installation...$(NC)"
	@cp $(BUILD_DIR)/$(BINARY_NAME) $(GOPATH)/bin/
	@echo "$(GREEN)✓ Pipeline installé dans $(GOPATH)/bin/$(NC)"

run: build ## Lance le pipeline avec la config par défaut
	@echo "$(CYAN)🚀 Lancement du pipeline...$(NC)"
	@$(BUILD_DIR)/$(BINARY_NAME) -config $(CONFIG_FILE) -target $(TARGET_PATH)

run-dry: build ## Lance le pipeline en mode dry-run
	@echo "$(CYAN)🧪 Lancement en mode dry-run...$(NC)"
	@$(BUILD_DIR)/$(BINARY_NAME) -config $(CONFIG_FILE) -target $(TARGET_PATH) -dry-run

run-verbose: build ## Lance le pipeline en mode verbose
	@echo "$(CYAN)🔍 Lancement en mode verbose...$(NC)"
	@$(BUILD_DIR)/$(BINARY_NAME) -config $(CONFIG_FILE) -target $(TARGET_PATH) -verbose

run-test: ## Lance le script de test PowerShell
	@echo "$(CYAN)🧪 Lancement du script de test...$(NC)"
	@powershell -ExecutionPolicy Bypass -File scripts/test-pipeline.ps1

metrics: ## Démarre uniquement le serveur de métriques
	@echo "$(CYAN)📊 Démarrage du serveur de métriques...$(NC)"
	@$(BUILD_DIR)/$(BINARY_NAME) -metrics-only -port 9090

fmt: ## Formate le code Go
	@echo "$(CYAN)✨ Formatage du code...$(NC)"
	@go fmt ./...
	@echo "$(GREEN)✓ Code formaté$(NC)"

lint: ## Lance le linter Go
	@echo "$(CYAN)🔍 Linting...$(NC)"
	@golint ./...
	@go vet ./...
	@echo "$(GREEN)✓ Linting terminé$(NC)"

vet: ## Lance go vet
	@echo "$(CYAN)🔍 Go vet...$(NC)"
	@go vet ./...
	@echo "$(GREEN)✓ Go vet terminé$(NC)"

deps: ## Met à jour les dépendances
	@echo "$(CYAN)📦 Mise à jour des dépendances...$(NC)"
	@go mod tidy
	@go mod download
	@echo "$(GREEN)✓ Dépendances mises à jour$(NC)"

init-workspace: ## Initialise un nouveau workspace
	@echo "$(CYAN)🏗️ Initialisation du workspace...$(NC)"
	@mkdir -p src/config src/modules reports patches metrics
	@mkdir -p pkg/detector pkg/resolver pkg/monitor
	@mkdir -p cmd/pipeline cmd/analyzer
	@mkdir -p tests/unit tests/integration
	@mkdir -p docs/api docs/architecture
	@echo "$(GREEN)✓ Workspace initialisé$(NC)"

docker-build: ## Construit l'image Docker
	@echo "$(CYAN)🐳 Construction de l'image Docker...$(NC)"
	@docker build -t error-resolution-pipeline:$(VERSION) .
	@echo "$(GREEN)✓ Image Docker créée$(NC)"

docker-run: docker-build ## Lance le pipeline dans Docker
	@echo "$(CYAN)🐳 Lancement du pipeline dans Docker...$(NC)"
	@docker run --rm -v $(PWD)/$(TARGET_PATH):/data error-resolution-pipeline:$(VERSION)

benchmark: ## Lance les benchmarks
	@echo "$(CYAN)⚡ Lancement des benchmarks...$(NC)"
	@go test -bench=. -benchmem ./pkg/...
	@echo "$(GREEN)✓ Benchmarks terminés$(NC)"

profile: build ## Profile le pipeline
	@echo "$(CYAN)📊 Profiling du pipeline...$(NC)"
	@$(BUILD_DIR)/$(BINARY_NAME) -config $(CONFIG_FILE) -target $(TARGET_PATH) -cpuprofile=cpu.prof -memprofile=mem.prof
	@echo "$(GREEN)✓ Profils générés: cpu.prof, mem.prof$(NC)"

docs-gen: ## Génère la documentation
	@echo "$(CYAN)📚 Génération de la documentation...$(NC)"
	@godoc -http=:6060 &
	@echo "$(GREEN)✓ Documentation disponible sur http://localhost:6060$(NC)"

validate-config: ## Valide la configuration
	@echo "$(CYAN)✅ Validation de la configuration...$(NC)"
	@$(BUILD_DIR)/$(BINARY_NAME) -config $(CONFIG_FILE) -validate-config-only
	@echo "$(GREEN)✓ Configuration valide$(NC)"

analyze-algorithms: build ## Analyse spécifiquement les algorithmes existants
	@echo "$(CYAN)🔍 Analyse des algorithmes existants...$(NC)"
	@$(BUILD_DIR)/$(BINARY_NAME) -config $(CONFIG_FILE) -target ../../.github/docs/algorithms -mode algorithms-only

fix-errors: build ## Applique les fixes automatiques
	@echo "$(CYAN)🔧 Application des fixes automatiques...$(NC)"
	@$(BUILD_DIR)/$(BINARY_NAME) -config $(CONFIG_FILE) -target $(TARGET_PATH) -auto-fix
	@echo "$(YELLOW)⚠️ Vérifiez les modifications et les backups créés$(NC)"

status: ## Affiche le statut du pipeline
	@echo "$(CYAN)📊 Statut du Error Resolution Pipeline$(NC)"
	@echo "Version: $(VERSION)"
	@echo "Configuration: $(CONFIG_FILE)"
	@echo "Cible par défaut: $(TARGET_PATH)"
	@if [ -f $(BUILD_DIR)/$(BINARY_NAME) ]; then echo "$(GREEN)✓ Binary compilé$(NC)"; else echo "$(RED)✗ Binary non compilé$(NC)"; fi
	@if [ -f $(CONFIG_FILE) ]; then echo "$(GREEN)✓ Configuration trouvée$(NC)"; else echo "$(RED)✗ Configuration manquante$(NC)"; fi

all: clean deps fmt vet test build ## Lance toutes les étapes (clean, deps, fmt, vet, test, build)
	@echo "$(GREEN)🎉 Build complet terminé avec succès!$(NC)"

# Cibles pour l'intégration continue
ci-test: deps fmt vet test ## Tests pour CI
ci-build: ci-test build ## Build pour CI

# Version information
version: ## Affiche la version
	@echo "Error Resolution Pipeline v$(VERSION)"

# Aide par défaut
.DEFAULT_GOAL := help
