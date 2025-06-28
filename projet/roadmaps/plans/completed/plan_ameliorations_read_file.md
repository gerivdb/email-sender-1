# Plan de Développement : Améliorations de la lecture de fichiers volumineux (`read_file`)
## 🚨 CONSIGNES CRITIQUES DE VÉRIFICATION

### Avant CHAQUE étape

- [ ] **VÉRIFIER la branche actuelle** : `git branch` et `git status`
- [ ] **VÉRIFIER les imports** : cohérence des chemins relatifs/absolus
- [ ] **VÉRIFIER la stack** : `go mod tidy` et `go build ./...`
- [ ] **VÉRIFIER les fichiers requis** : présence de tous les composants
- [ ] **VÉRIFIER la responsabilité** : éviter la duplication de code
- [ ] **TESTER avant commit** : `go test ./...` doit passer à 100%

### À CHAQUE section majeure

- [ ] **COMMITTER sur la bonne branche** : vérifier correspondance
- [ ] **PUSHER immédiatement** : `git push origin [branch-name]`
- [ ] **DOCUMENTER les changements** : mise à jour du README
- [ ] **VALIDER l'intégration** : tests end-to-end

### Responsabilités par branche

- **main** : Code de production stable uniquement
- **dev** : Intégration et tests de l'écosystème unifié  
- **managers** : Développement des managers individuels
- **vectorization-go** : Migration Python→Go des vecteurs
- **consolidation-v57** : Branche dédiée pour ce plan

## 🏗️ SPÉCIFICATIONS TECHNIQUES GÉNÉRIQUES

### 📋 Stack Technique Complète

**Runtime et Outils**

- **Go Version** : 1.21+ requis (vérifier avec `go version`)
- **Module System** : Go modules activés (`go mod init/tidy`)
- **Build Tool** : `go build ./...` pour validation complète
- **Dependency Management** : `go mod download` et `go mod verify`

**Dépendances Critiques**

```go
// go.mod - dépendances requises
require (
    github.com/qdrant/go-client v1.7.0        // Client Qdrant natif
    github.com/google/uuid v1.6.0             // Génération UUID
    github.com/stretchr/testify v1.8.4        // Framework de test
    go.uber.org/zap v1.26.0                   // Logging structuré
    golang.org/x/sync v0.5.0                  // Primitives de concurrence
    github.com/spf13/viper v1.17.0            // Configuration
    github.com/gin-gonic/gin v1.9.1           // Framework HTTP (si APIs)
)
```

**Outils de Développement**

- **Linting** : `golangci-lint run` (configuration dans `.golangci.yml`)
- **Formatting** : `gofmt -s -w .` et `goimports -w .`
- **Testing** : `go test -v -race -cover ./...`
- **Security** : `gosec ./...` pour l'analyse de sécurité

### 🗂️ Structure des Répertoires Normalisée

```
EMAIL_SENDER_1/
├── cmd/                          # Points d'entrée des applications
│   ├── migration-tool/          # Outil de migration Python->Go
│   └── manager-consolidator/    # Outil de consolidation
├── internal/                    # Code interne non exportable
│   ├── config/                 # Configuration centralisée
│   ├── models/                 # Structures de données
│   ├── repository/             # Couche d'accès données
│   └── service/                # Logique métier
├── pkg/                        # Packages exportables
│   ├── vectorization/          # Module vectorisation Go
│   ├── managers/               # Managers consolidés
│   └── common/                 # Utilitaires partagés
├── api/                        # Définitions API (OpenAPI/Swagger)
├── scripts/                    # Scripts d'automatisation
├── docs/                       # Documentation technique
├── tests/                      # Tests d'intégration
└── deployments/                # Configuration déploiement
```

### 🎯 Conventions de Nommage Strictes

**Fichiers et Répertoires**

- **Packages** : `snake_case` (ex: `vector_client`, `email_manager`)
- **Fichiers Go** : `snake_case.go` (ex: `vector_client.go`, `manager_consolidator.go`)
- **Tests** : `*_test.go` (ex: `vector_client_test.go`)
- **Scripts** : `kebab-case.sh/.ps1` (ex: `build-and-test.sh`)

**Code Go**

- **Variables/Fonctions** : `camelCase` (ex: `vectorClient`, `processEmails`)
- **Constantes** : `UPPER_SNAKE_CASE` ou `CamelCase` selon contexte
- **Types/Interfaces** : `PascalCase` (ex: `VectorClient`, `EmailManager`)
- **Méthodes** : `PascalCase` pour export, `camelCase` pour privé

**Git et Branches**

- **Branches** : `kebab-case` (ex: `feature/vector-migration`, `fix/manager-consolidation`)
- **Commits** : Format Conventional Commits

  ```
  feat(vectorization): add Go native Qdrant client
  fix(managers): resolve duplicate interface definitions
  docs(readme): update installation instructions
  ```

### 🔧 Standards de Code et Qualité

**Formatage et Style**

- **Indentation** : Tabs (format Go standard)
- **Longueur de ligne** : 100 caractères maximum
- **Imports** : Groupés (standard, third-party, internal) avec lignes vides
- **Commentaires** : GoDoc format pour exports, inline pour logique complexe

**Architecture et Patterns**

- **Principe** : Clean Architecture avec dépendances inversées
- **Error Handling** : Types d'erreur explicites avec wrapping
- **Logging** : Structured logging avec Zap (JSON en prod, console en dev)
- **Configuration** : Viper avec support YAML/ENV/flags
- **Concurrence** : Channels et goroutines, éviter les mutexes sauf nécessaire

**Exemple de Structure d'Erreur**

```go
type VectorError struct {
    Operation string
    Cause     error
    Code      ErrorCode
}

func (e *VectorError) Error() string {
    return fmt.Sprintf("vector operation '%s' failed: %v", e.Operation, e.Cause)
}
```

### 🧪 Stratégie de Tests Complète

**Couverture et Types**

- **Couverture minimale** : 85% pour le code critique
- **Tests unitaires** : Tous les packages publics
- **Tests d'intégration** : Composants inter-dépendants
- **Tests de performance** : Benchmarks pour la vectorisation

**Conventions de Test**

```go
func TestVectorClient_CreateCollection(t *testing.T) {
    tests := []struct {
        name    string
        config  VectorConfig
        wantErr bool
    }{
        {
            name: "valid_collection_creation",
            config: VectorConfig{
                Host: "localhost",
                Port: 6333,
                CollectionName: "test_collection",
                VectorSize: 384,
            },
            wantErr: false,
        },
        // ... autres cas de test
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            // Test implementation
        })
    }
}
```

**Mocking et Test Data**

- **Interfaces** : Toujours définir des interfaces pour le mocking
- **Test fixtures** : Données de test dans `testdata/`
- **Setup/Teardown** : `TestMain` pour setup global

### 🔒 Sécurité et Configuration

**Gestion des Secrets**

- **Variables d'environnement** : Pas de secrets dans le code
- **Configuration** : Fichiers YAML pour le dev, ENV pour la prod
- **Qdrant** : Authentification via token si configuré

**Variables d'Environnement Requises**

```bash
# Configuration Qdrant
QDRANT_HOST=localhost
QDRANT_PORT=6333
QDRANT_API_KEY=optional_token

# Configuration Application
LOG_LEVEL=info
ENV=development
CONFIG_PATH=./config/config.yaml

# Migration
PYTHON_DATA_PATH=./data/vectors/
BATCH_SIZE=1000
```

### 📊 Performance et Monitoring

**Critères de Performance**

- **Vectorisation** : < 500ms pour 10k vecteurs
- **API Response** : < 100ms pour requêtes simples
- **Memory Usage** : < 500MB en utilisation normale
- **Concurrence** : Support 100 requêtes simultanées

**Métriques à Tracker**

```go
// Exemple de métriques avec Prometheus
var (
    vectorOperationDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name: "vector_operation_duration_seconds",
            Help: "Duration of vector operations",
        },
        []string{"operation", "status"},
    )
)
```

### 🔄 Workflow Git et CI/CD

**Workflow de Développement**

1. **Créer branche** : `git checkout -b feature/task-name`
2. **Développer** : Commits atomiques avec tests
3. **Valider** : `go test ./...` + `golangci-lint run`
4. **Push** : `git push origin feature/task-name`
5. **Merger** : Via PR après review

**Definition of Done**

- [ ] Code implémenté selon les spécifications
- [ ] Tests unitaires écrits et passants (>85% coverage)
- [ ] Linting sans erreurs (`golangci-lint run`)
- [ ] Documentation GoDoc mise à jour
- [ ] Tests d'intégration passants
- [ ] Performance validée (benchmarks si critique)
- [ ] Code review approuvé
- [ ] Branch mergée et nettoyée

## Objectif
Proposer et planifier des améliorations pour la manipulation, la lecture et la navigation dans des fichiers volumineux au sein de l’environnement Cline/Copilot, en réponse aux limitations constatées (troncature, absence de navigation par plage/bloc, etc.).

---

## 1. Roadmap exhaustive et automatisable : Améliorations de la lecture de fichiers volumineux (`read_file`)

### 1.1 Recensement & Analyse d’écart (Roadmap détaillée)

#### 1.1.1 Recensement des usages actuels de `read_file`
- [x] **Scan automatisé du code**
  - Livrable : `docs/read_file_usage_audit.md` (Markdown, inventaire des appels)
  - Script Go à créer : `cmd/audit_read_file.go`
    - Fonction : Scanner récursivement le dépôt, détecter tous les appels à `read_file`, générer un rapport détaillé (fichier, ligne, contexte, extrait de code)
    - Exemple minimal :
      ```go
      // cmd/audit_read_file.go
      package main
      import ("os"; "fmt"; "path/filepath"; "strings")
      func main() {
        filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
          if strings.HasSuffix(path, ".go") { /* ...scan... */ }
          return nil
        })
        fmt.Println("# Audit usages read_file\n...")
      }
      ```
  - Commande : `go run cmd/audit_read_file.go > docs/read_file_usage_audit.md`
  - Format attendu : Markdown (tableau usages, extraits, stats)
  - Critères de validation : Rapport généré, commit signé, badge de couverture, logs d’exécution
  - Rollback/versionning : Sauvegarde `.bak`, commit revert, logs
  - CI/CD : Ajout d’un job d’audit dans `.github/workflows/read_file.yml` (scan à chaque PR)
  - Documentation : Section dans `docs/read_file_README.md` (mode d’emploi, exemples)
  - Traçabilité : Logs d’exécution, historique des rapports, badge CI

#### 1.1.2 Analyse d’écart avec besoins utilisateurs
- [x] **Comparaison usages vs besoins**
  - Livrable : `docs/read_file_gap_analysis.md` (Markdown, tableau d’écart)
  - Script Go à créer : `cmd/gap_analysis.go`
    - Fonction : Charger le rapport d’usage, charger les besoins (`docs/read_file_user_needs.md`), générer un tableau d’écart (besoin couvert/non couvert, priorité, suggestion)
    - Exemple minimal :
      ```go
      // cmd/gap_analysis.go
      package main
      import ("fmt")
      func main() {
        fmt.Println("# Gap analysis read_file\n...")
      }
      ```
  - Commande : `go run cmd/gap_analysis.go > docs/read_file_gap_analysis.md`
  - Format attendu : Markdown (tableau, stats, priorités)
  - Critères de validation : Rapport généré, revue croisée, logs, badge CI
  - Rollback/versionning : Sauvegarde `.bak`, commit revert, logs
  - CI/CD : Ajout d’un job d’analyse d’écart dans `.github/workflows/read_file.yml` (dépend du rapport d’usage)
  - Documentation : Section dans `docs/read_file_README.md` (mode d’emploi, exemples)
  - Traçabilité : Logs d’exécution, historique des rapports, badge CI

---

> Chaque étape est atomique, automatisable, testée, traçable, avec rollback/versionning, documentation, intégration CI/CD, et alignée sur la stack Go native et la structure du dépôt. Si une étape échoue, logs et rapport d’erreur sont générés, et une alternative manuelle est proposée dans le README.

## 1.2 Recueil des besoins (Roadmap détaillée)

#### 1.2.1 Génération et diffusion du template de recueil
- [x] **Création du template Markdown**
  - Livrable : `docs/read_file_user_needs.md` (template structuré)
  - Script Bash à créer : `scripts/gen_user_needs_template.sh`
    - Fonction : Générer un template interactif ou statique pour recueil des besoins (questions, tableaux à remplir)
    - Exemple minimal :
      ```bash
      #!/bin/bash
      cat <<EOF > docs/read_file_user_needs.md
      # Recueil des besoins utilisateurs pour read_file
      - Utilisateur :
      - Cas d'usage :
      - Limitations rencontrées :
      - Fonctionnalités attendues :
      - Priorité :
      EOF
      ```
  - Commande : `bash scripts/gen_user_needs_template.sh`
  - Format attendu : Markdown
  - Critères de validation : Fichier généré, commit, logs
  - Rollback/versionning : .bak, commit revert
  - CI/CD : Job de génération de template (optionnel)
  - Documentation : README usage script
  - Traçabilité : logs, historique des templates

#### 1.2.2 Collecte interactive des besoins
- [x] **Collecte automatisée ou semi-automatisée**
  - Livrable : `docs/read_file_user_needs.md` (rempli)
  - Script Bash à créer/adapter : `scripts/collect_user_needs.sh`
    - Fonction : Poser les questions du template à l’utilisateur (en CLI), remplir le Markdown, ou ouvrir le fichier pour édition manuelle
    - Exemple minimal :
      ```bash
      #!/bin/bash
      echo "# Recueil des besoins utilisateurs pour read_file" > docs/read_file_user_needs.md
      read -p "Utilisateur : " user
      read -p "Cas d'usage : " usecase
      read -p "Limitations rencontrées : " limits
      read -p "Fonctionnalités attendues : " features
      read -p "Priorité : " priority
      echo "- Utilisateur : $user" >> docs/read_file_user_needs.md
      echo "- Cas d'usage : $usecase" >> docs/read_file_user_needs.md
      echo "- Limitations rencontrées : $limits" >> docs/read_file_user_needs.md
      echo "- Fonctionnalités attendues : $features" >> docs/read_file_user_needs.md
      echo "- Priorité : $priority" >> docs/read_file_user_needs.md
      ```
  - Commande : `bash scripts/collect_user_needs.sh > docs/read_file_user_needs.md`
  - Format attendu : Markdown rempli
  - Critères de validation : Rapport rempli, feedback utilisateur, logs
  - Rollback/versionning : .bak, commit revert
  - CI/CD : Job de vérification de complétion (optionnel)
  - Documentation : README usage script, guide de recueil
  - Traçabilité : logs, historique des retours, feedback automatisé

#### 1.2.3 Validation et archivage des besoins
- [x] **Validation croisée et archivage**
  - Livrable : `docs/read_file_user_needs.md` (validé), backup `.bak`
  - Script Bash/Go à créer : `scripts/validate_and_archive_user_needs.sh`
    - Fonction : Vérifier la complétion du fichier, archiver la version validée dans `archive/`, générer un log
    - Exemple minimal :
      ```bash
      #!/bin/bash
      cp docs/read_file_user_needs.md archive/read_file_user_needs_$(date +%F).bak
      echo "Validation et archivage terminés."
      ```
  - Commande : `bash scripts/validate_and_archive_user_needs.sh`
  - Format attendu : Markdown, .bak
  - Critères de validation : Archive présente, logs, feedback
  - Rollback/versionning : restauration .bak, commit revert
  - CI/CD : Job d’archivage automatique (optionnel)
  - Documentation : README, logs d’archivage
  - Traçabilité : logs, historique des archives, feedback automatisé

---

> Chaque sous-étape est atomique, automatisable, testée, traçable, avec rollback/versionning, documentation, intégration CI/CD, et alignée sur la stack Go native et la structure du dépôt. Si une étape échoue, logs et rapport d’erreur sont générés, et une alternative manuelle est proposée dans le README.

## 1.3 Spécification détaillée (Roadmap détaillée)

#### 1.3.1 Génération du template de spécification
- [x] **Création du template Markdown pour les specs**
  - Livrable : `specs/read_file_spec.md` (template structuré)
  - Script Go à créer : `cmd/gen_read_file_spec.go`
    - Fonction : Générer un template de spécification à partir des besoins collectés (`docs/read_file_user_needs.md`), pré-rempli avec les sections attendues (fonctionnalités, API, cas d’usage, critères d’acceptation)
    - Exemple minimal :
      ```go
      // cmd/gen_read_file_spec.go
      package main
      import ("fmt")
      func main() {
        fmt.Println("# Spécification fonctionnelle et technique read_file\n...")
      }
      ```
  - Commande : `go run cmd/gen_read_file_spec.go > specs/read_file_spec.md`
  - Format attendu : Markdown (sections, tableaux, exemples)
  - Critères de validation : Fichier généré, commit, logs
  - Rollback/versionning : .bak, commit revert
  - CI/CD : Job de génération de spec (optionnel)
  - Documentation : README usage script
  - Traçabilité : logs, historique des specs

#### 1.3.2 Rédaction collaborative et validation croisée
- [ ] **Complétion et validation de la spec**
  - Livrable : `specs/read_file_spec.md` (rempli et validé)
  - Action : Compléter le template, intégrer les retours des parties prenantes
  - Commande : Edition manuelle ou via script Go interactif
  - Format attendu : Markdown structuré, checklist, exemples d’API, diagrammes (optionnel)
  - Critères de validation : Revue croisée, badge CI, logs
  - Rollback/versionning : .bak, commit revert
  - CI/CD : Job de vérification de complétion (optionnel)
  - Documentation : README, guide de validation
  - Traçabilité : logs, historique des versions, feedback automatisé

#### 1.3.3 Archivage et traçabilité
- [x] **Archivage automatique des versions de spec**
  - Livrable : `archive/read_file_spec_YYYY-MM-DD.bak`
  - Script Bash/Go à créer : `scripts/archive_spec.sh`
    - Fonction : Sauvegarder la spec validée dans `archive/` avec datestamp, générer un log
    - Exemple minimal :
      ```bash
      #!/bin/bash
      cp specs/read_file_spec.md archive/read_file_spec_$(date +%F).bak
      echo "Spec archivée."
      ```
  - Commande : `bash scripts/archive_spec.sh`
  - Format attendu : Markdown, .bak
  - Critères de validation : Archive présente, logs
  - Rollback/versionning : restauration .bak, commit revert
  - CI/CD : Job d’archivage automatique (optionnel)
  - Documentation : README, logs d’archivage
  - Traçabilité : logs, historique des archives, feedback automatisé

---

> Chaque sous-étape est atomique, automatisable, testée, traçable, avec rollback/versionning, documentation, intégration CI/CD, et alignée sur la stack Go native et la structure du dépôt. Si une étape échoue, logs et rapport d’erreur sont générés, et une alternative manuelle est proposée dans le README.

## 1.4 Développement modulaire (Roadmap détaillée)

#### 1.4.1 Refactorisation de l’API `read_file`
- [x] **Développement et tests de l’API**
  - Livrables :
    - `pkg/common/read_file.go` (API refactorisée : lecture par plage, navigation, détection binaire)
    - `pkg/common/read_file_test.go` (tests unitaires)
  - Scripts Go à créer :
    - `pkg/common/read_file.go` (fonction `ReadFileRange`, gestion navigation, preview hex)
    - `pkg/common/read_file_test.go` (tests de couverture, cas limites, fichiers volumineux/binaires)
    - Exemple minimal :
      ```go
      // pkg/common/read_file.go
      package common
      import ("os"; "bufio")
      func ReadFileRange(path string, start, end int) ([]string, error) {
        // ... lecture par plage ...
        return nil, nil
      }
      ```
  - Commandes :
    - `go build ./pkg/common/...`
    - `go test -v -cover ./pkg/common/read_file_test.go`
  - Formats attendus : Go, Markdown (rapport de couverture)
  - Critères de validation : Couverture >90%, badge CI, logs, tests passants
  - Rollback/versionning : git revert, backup .bak
  - CI/CD : Job build/test/lint dans `.github/workflows/read_file.yml`
  - Documentation : GoDoc, README usage API
  - Traçabilité : logs, historique des builds/tests, badge CI

#### 1.4.2 Ajout navigation interactive
- [x] **Développement CLI de navigation**
  - Livrables :
    - `cmd/read_file_navigator.go` (CLI navigation, tests associés)
  - Script Go à créer :
    - `cmd/read_file_navigator.go` (navigation next/prev block, goto start/end, intégration avec API)
    - Exemple minimal :
      ```go
      // cmd/read_file_navigator.go
      package main
      import ("fmt")
      func main() {
        fmt.Println("# Navigation interactive read_file\n...")
      }
      ```
  - Commande : `go run cmd/read_file_navigator.go --file=... --block=100`
  - Formats attendus : Go, Markdown (rapport CLI)
  - Critères de validation : Tests CLI, logs, feedback utilisateur
  - Rollback/versionning : git revert, backup .bak
  - CI/CD : Job CLI/test dans `.github/workflows/read_file.yml`
  - Documentation : README CLI, exemples d’usage
  - Traçabilité : logs, historique des runs, feedback automatisé

#### 1.4.3 Intégration sélection active éditeur
- [x] **Extension VSCode pour sélection active**
  - Livrables :
    - `scripts/vscode_read_file_selection.js` (extension, tests)
  - Script JS à créer :
    - Récupération de la sélection active, appel API Go (via CLI ou HTTP)
    - Exemple minimal :
      ```js
      // scripts/vscode_read_file_selection.js
      const vscode = require('vscode');
      // ... récupération sélection, appel API ...
      ```
  - Commande : `node scripts/vscode_read_file_selection.js`
  - Formats attendus : JS, Markdown (rapport d’intégration)
  - Critères de validation : Test VSCode, logs, feedback utilisateur
  - Rollback/versionning : désactivation extension, backup
  - CI/CD : Job test intégration (optionnel)
  - Documentation : README extension, guide d’usage
  - Traçabilité : logs, historique des sélections, feedback automatisé

#### 1.4.4 Gestion fichiers binaires/mixtes
- [x] **Détection et preview hex**
  - Livrables :
    - `pkg/common/read_file.go` (détection binaire, preview hex)
    - `pkg/common/read_file_test.go` (tests binaires/mixtes)
  - Script Go à créer :
    - Ajout détection binaire, preview hex dans API
    - Exemple minimal :
      ```go
      // pkg/common/read_file.go (extrait)
      func IsBinaryFile(path string) bool { /* ... */ }
      func PreviewHex(path string, start, end int) ([]byte, error) { /* ... */ }
      ```
  - Commande : `go test -v pkg/common/read_file_test.go`
  - Formats attendus : Go, Markdown (rapport de tests)
  - Critères de validation : Tests passants, logs, badge CI
  - Rollback/versionning : git revert
  - CI/CD : Job test binaire dans `.github/workflows/read_file.yml`
  - Documentation : GoDoc, README API
  - Traçabilité : logs, historique des tests, badge CI

---

> Chaque sous-étape est atomique, automatisable, testée, traçable, avec rollback/versionning, documentation, intégration CI/CD, et alignée sur la stack Go native et la structure du dépôt. Si une étape échoue, logs et rapport d’erreur sont générés, et une alternative manuelle est proposée dans le README.

## 1.5 Tests unitaires & intégration (Roadmap détaillée)

#### 1.5.1 Tests unitaires Go
- [x] **Développement et exécution des tests unitaires**
  - Livrables :
    - `*_test.go` (tests unitaires pour chaque module Go modifié)
    - Badge de couverture (généré par CI)
  - Scripts Go à créer/adapter :
    - Tests pour toutes les fonctions critiques de `pkg/common/read_file.go`, navigation, détection binaire, preview hex
    - Exemple minimal :
      ```go
      // pkg/common/read_file_test.go
      package common
      import ("testing")
      func TestReadFileRange(t *testing.T) {
        // ... cas de test ...
      }
      ```
  - Commandes :
    - `go test -v -cover ./...`
    - `go tool cover -func=coverage.out`
  - Formats attendus : Go, HTML (rapport de couverture), Markdown (résumé)
  - Critères de validation : Couverture >90%, badge CI, logs, tests passants
  - Rollback/versionning : suppression des tests, git revert
  - CI/CD : Job test/coverage dans `.github/workflows/read_file.yml`
  - Documentation : README section tests, GoDoc
  - Traçabilité : logs, historique des tests, badge CI

#### 1.5.2 Tests d’intégration CLI/éditeur
- [x] **Développement et exécution des tests d’intégration**
  - Livrables :
    - `integration/read_file_integration_test.go` (tests d’intégration CLI/API/éditeur)
    - Logs d'exécution
  - Scripts Go à créer/adapter :
    - Tests d’intégration pour la CLI (`cmd/read_file_navigator.go`), API, extension VSCode
    - Exemple minimal :
      ```go
      // integration/read_file_integration_test.go
      package integration
      import ("testing")
      func TestReadFileIntegration(t *testing.T) {
        // ... test CLI/API/éditeur ...
      }
      ```
  - Commandes :
    - `go test -v integration/read_file_integration_test.go`
  - Formats attendus : Go, Markdown (rapport d’intégration)
  - Critères de validation : Logs, badge CI, feedback utilisateur
  - Rollback/versionning : git revert
  - CI/CD : Job test intégration dans `.github/workflows/read_file.yml`
  - Documentation : README section intégration, GoDoc
  - Traçabilité : logs, historique des tests, badge CI

---

> Chaque sous-étape est atomique, automatisable, testée, traçable, avec rollback/versionning, documentation, intégration CI/CD, et alignée sur la stack Go native et la structure du dépôt. Si une étape échoue, logs et rapport d’erreur sont générés, et une alternative manuelle est proposée dans le README.

## 1.6 Reporting & documentation (Roadmap détaillée)

#### 1.6.1 Génération de rapports automatisés
- [x] **Rapports de couverture et reporting automatisé**
  - Livrables :
    - `reports/read_file_report.md` (rapport synthétique Markdown)
    - `reports/read_file_coverage.html` (rapport de couverture HTML)
    - Badge de couverture (généré par CI)
  - Scripts Go à créer/adapter :
    - Génération automatique du rapport Markdown à partir des résultats de test/coverage
    - Exemple minimal :
      ```go
      // scripts/gen_read_file_report.go
      package main
      import ("fmt")
      func main() {
        fmt.Println("# Rapport automatisé read_file\n...")
      }
      ```
  - Commandes :
    - `go test -coverprofile=coverage.out`
    - `go tool cover -html=coverage.out -o reports/read_file_coverage.html`
    - `go run scripts/gen_read_file_report.go > reports/read_file_report.md`
  - Formats attendus : Markdown, HTML, badge CI
  - Critères de validation : Rapport généré, badge CI, logs
  - Rollback/versionning : suppression rapport, git revert
  - CI/CD : Job reporting dans `.github/workflows/read_file.yml`
  - Documentation : README section reporting, GoDoc
  - Traçabilité : logs, historique des rapports, badge CI

#### 1.6.2 Documentation technique et guides
- [x] **Documentation technique, guides d’usage et GoDoc**
  - Livrables :
    - `docs/read_file_README.md` (guide d’usage, conventions, exemples)
    - GoDoc générée automatiquement
  - Scripts à créer/adapter :
    - Génération GoDoc, extraction d’exemples d’usage, vérification de la complétude
    - Exemple minimal :
      ```bash
      godoc -http=:6060
      # Vérification manuelle ou scriptée de la documentation
      ```
  - Commandes :
    - `godoc -http=:6060` (consultation locale)
    - `go doc pkg/common/read_file.go` (extraction CLI)
  - Formats attendus : Markdown, HTML (GoDoc)
  - Critères de validation : Documentation à jour, logs, feedback utilisateur
  - Rollback/versionning : backup, git revert
  - CI/CD : Job doc dans `.github/workflows/read_file.yml`
  - Documentation : README, GoDoc, guides d’usage
  - Traçabilité : logs, historique des docs, feedback automatisé

---

> Chaque sous-étape est atomique, automatisable, testée, traçable, avec rollback/versionning, documentation, intégration CI/CD, et alignée sur la stack Go native et la structure du dépôt. Si une étape échoue, logs et rapport d’erreur sont générés, et une alternative manuelle est proposée dans le README.

## 1.7 Validation croisée & feedback (Roadmap détaillée)

#### 1.7.1 Revue croisée code/spec/tests
- [ ] **Processus de revue croisée et validation CI**
  - Livrables :
    - Logs de review (PR, commentaires, validation)
    - Badge CI (statut de la PR)
  - Actions à automatiser :
    - Création de PR sur la branche dédiée
    - Assignation automatique de reviewers (script GitHub Actions ou bot)
    - Génération automatique de checklist de validation (Markdown)
    - Exemple minimal :
      ```bash
      # Commande manuelle ou scriptée
      gh pr create --base main --head feature/read-file --title "Review read_file" --body "Checklist..."
      ```
  - Commandes :
    - `gh pr create ...` (ou via interface GitHub)
    - Validation CI automatique sur PR
  - Formats attendus : Markdown (checklist), logs PR, badge CI
  - Critères de validation : Feedback reviewers, logs, badge CI vert
  - Rollback/versionning : PR close, revert, logs
  - CI/CD : Job de validation sur PR dans `.github/workflows/read_file.yml`
  - Documentation : README section review, guide de validation croisée
  - Traçabilité : logs PR, historique des reviews, badge CI

#### 1.7.2 Feedback utilisateur final
- [x] **Collecte et intégration du feedback utilisateur**
  - Livrables :
    - `docs/read_file_user_feedback.md` (rapport feedback)
    - Logs de collecte et d’intégration
  - Scripts à créer/adapter :
    - Script Bash/Go pour collecte interactive ou formulaire (CLI ou web)
    - Exemple minimal :
      ```bash
      #!/bin/bash
      echo "# Feedback utilisateur read_file" > docs/read_file_user_feedback.md
      read -p "Nom utilisateur : " user
      read -p "Feedback : " feedback
      echo "- Utilisateur : $user" >> docs/read_file_user_feedback.md
      echo "- Feedback : $feedback" >> docs/read_file_user_feedback.md
      ```
  - Commande : `bash scripts/collect_user_feedback.sh > docs/read_file_user_feedback.md`
  - Format attendu : Markdown, logs
  - Critères de validation : Feedback intégré, logs, badge CI
  - Rollback/versionning : backup, git revert
  - CI/CD : Job feedback dans `.github/workflows/read_file.yml` (optionnel)
  - Documentation : README section feedback, guide d’intégration
  - Traçabilité : logs, historique des feedbacks, badge CI

---

> Chaque sous-étape est atomique, automatisable, testée, traçable, avec rollback/versionning, documentation, intégration CI/CD, et alignée sur la stack Go native et la structure du dépôt. Si une étape échoue, logs et rapport d’erreur sont générés, et une alternative manuelle est proposée dans le README.

## 1.8 Rollback & versionning (Roadmap détaillée)

### 1.8.1 Recensement des besoins et points critiques
- [x] **Audit des points de rollback/versionning nécessaires**
  - Livrable : `docs/rollback_points_audit.md` (tableau des points critiques à sauvegarder/restaurer)
  - Script Go à créer : `cmd/audit_rollback_points.go`
    - Fonction : Scanner le dépôt pour identifier les fichiers critiques (config, data, code, rapports), générer un rapport Markdown.
    - Exemple minimal :
      ```go
      // cmd/audit_rollback_points.go
      package main
      import ("fmt")
      func main() {
        fmt.Println("# Audit rollback points\n- config.yaml\n- pkg/common/read_file.go\n...")
      }
      ```
  - Commande : `go run cmd/audit_rollback_points.go > docs/rollback_points_audit.md`
  - Format attendu : Markdown (liste, tableau)
  - Critères de validation : Rapport généré, logs, commit
  - Rollback : .bak, commit revert
  - CI/CD : Job d’audit dans `.github/workflows/read_file.yml`
  - Documentation : README section rollback
  - Traçabilité : logs, historique des audits

### 1.8.2 Spécification des procédures de sauvegarde/restauration
- [x] **Rédaction des specs de backup/restore**
  - Livrable : `specs/rollback_spec.md` (procédures, cas d’usage, critères)
  - Script Go à créer : `cmd/gen_rollback_spec.go`
    - Fonction : Générer un template de spec à partir de l’audit, sections pour chaque type de fichier/dossier à sauvegarder/restaurer.
    - Exemple minimal :
      ```go
      // cmd/gen_rollback_spec.go
      package main
      import ("fmt")
      func main() {
        fmt.Println("# Spécification rollback\n- Sauvegarde config\n- Restauration code\n...")
      }
      ```
  - Commande : `go run cmd/gen_rollback_spec.go > specs/rollback_spec.md`
  - Format attendu : Markdown
  - Critères de validation : Spec générée, logs, commit
  - Rollback : .bak, commit revert
  - CI/CD : Job spec rollback (optionnel)
  - Documentation : README, guide rollback
  - Traçabilité : logs, historique des specs

### 1.8.3 Développement des scripts de sauvegarde automatique
- [x] **Création du script de backup Go**
  - Livrable : `scripts/backup.go`, dossiers `.bak/`, `backup/`
  - Script Go à créer : `scripts/backup.go`
    - Fonction : Sauvegarder les fichiers/dossiers critiques listés dans l’audit, logs détaillés, gestion des erreurs.
    - Exemple minimal :
      ```go
      // scripts/backup.go
      package main
      import ("os"; "fmt")
      func main() {
        // Copier fichiers critiques vers backup/
        fmt.Println("Backup terminé.")
      }
      ```
  - Commande : `go run scripts/backup.go`
  - Format attendu : Fichiers/dossiers `.bak/`, logs texte
  - Critères de validation : Backup présent, logs, test automatisé
  - Rollback : restauration backup, logs
  - CI/CD : Job backup dans `.github/workflows/read_file.yml`
  - Documentation : README usage backup
  - Traçabilité : logs, historique des backups

### 1.8.4 Tests automatisés des procédures de backup/restore
- [x] **Développement des tests unitaires/integration**
  - Livrable : `scripts/backup_test.go`, badge de couverture
  - Script Go à créer : `scripts/backup_test.go`
    - Fonction : Tester la création/restauration de backup, cas d’erreur, logs.
    - Exemple minimal :
      ```go
      // scripts/backup_test.go
      package main
      import ("testing")
      func TestBackup(t *testing.T) {
        // ... test backup/restore ...
      }
      ```
  - Commande : `go test -v scripts/backup_test.go`
  - Format attendu : Go, Markdown (rapport de test)
  - Critères de validation : Tests passants, logs, badge CI
  - Rollback : suppression tests, git revert
  - CI/CD : Job test backup dans `.github/workflows/read_file.yml`
  - Documentation : README section tests backup
  - Traçabilité : logs, historique des tests

### 1.8.5 Gestion avancée du versionning git
- [x] **Automatisation des opérations git critiques**
  - Livrable : commits atomiques, tags, branches, logs
  - Script Bash/Go à créer : `scripts/git_versioning.sh` ou `scripts/git_versioning.go`
    - Fonction : Automatiser la création de tags, branches, revert, logs d’opérations.
    - Exemple minimal (Bash) :
      ```bash
      #!/bin/bash
      git add .
      git commit -m "backup: commit avant modification critique"
      git tag backup-$(date +%F-%H%M)
      ```
  - Commande : `bash scripts/git_versioning.sh`
  - Format attendu : logs git, tags, branches
  - Critères de validation : Historique git, logs, badge CI
  - Rollback : `git revert`, suppression tag/branche
  - CI/CD : Job git versionning dans `.github/workflows/read_file.yml`
  - Documentation : README usage script git
  - Traçabilité : logs, historique git, badge CI

### 1.8.6 Reporting & documentation des opérations de rollback/versionning
- [x] **Génération de rapports automatisés**
  - Livrable : `reports/rollback_report.md` (synthèse des backups, restores, git)
  - Script Go à créer : `scripts/gen_rollback_report.go`
    - Fonction : Générer un rapport Markdown à partir des logs de backup/git.
    - Exemple minimal :
      ```go
      // scripts/gen_rollback_report.go
      package main
      import ("fmt")
      func main() {
        fmt.Println("# Rapport rollback/versionning\n- Backups : ...\n- Git : ...")
      }
      ```
  - Commande : `go run scripts/gen_rollback_report.go > reports/rollback_report.md`
  - Format attendu : Markdown
  - Critères de validation : Rapport généré, logs, badge CI
  - Rollback : suppression rapport, git revert
  - CI/CD : Job reporting rollback dans `.github/workflows/read_file.yml`
  - Documentation : README section reporting rollback
  - Traçabilité : logs, historique des rapports

### 1.8.7 Validation croisée & feedback
- [x] **Revue croisée des procédures et feedback utilisateur**
  - Livrable : logs de review, feedback intégré dans `docs/rollback_feedback.md`
  - Script Bash/Go à créer : `scripts/collect_rollback_feedback.sh`
    - Fonction : Collecte interactive du feedback sur la robustesse des procédures.
    - Exemple minimal :
      ```bash
      #!/bin/bash
      echo "# Feedback rollback" > docs/rollback_feedback.md
      read -p "Nom utilisateur : " user
      read -p "Feedback : " feedback
      echo "- Utilisateur : $user" >> docs/rollback_feedback.md
      echo "- Feedback : $feedback" >> docs/rollback_feedback.md
      ```
  - Commande : `bash scripts/collect_rollback_feedback.sh > docs/rollback_feedback.md`
  - Format attendu : Markdown, logs
  - Critères de validation : Feedback intégré, logs, badge CI
  - Rollback : backup, git revert
  - CI/CD : Job feedback rollback (optionnel)
  - Documentation : README section feedback rollback
  - Traçabilité : logs, historique des feedbacks

---

### Orchestration & CI/CD (Roadmap détaillée)

#### 1. Orchestrateur global
- [x] **Recensement des scripts et dépendances**
  - Livrable : `docs/orchestration_audit.md` (liste des scripts, dépendances, points d'entrée)
  - Script Go à créer : `cmd/audit_orchestration.go`
    - Fonction : Scanner le dépôt pour lister tous les scripts d'automatisation, générer un rapport Markdown.
    - Exemple minimal :
      ```go
      // cmd/audit_orchestration.go
      package main
      import ("fmt")
      func main() {
        fmt.Println("# Audit orchestration\n- scripts/backup.go\n- scripts/backup_test.go\n...")
      }
      ```
  - Commande : `go run cmd/audit_orchestration.go > docs/orchestration_audit.md`
  - Format attendu : Markdown
  - Critères de validation : Rapport généré, logs, commit
  - Rollback : .bak, commit revert
  - CI/CD : Job d’audit orchestration dans `.github/workflows/read_file.yml`
  - Documentation : README section orchestration
  - Traçabilité : logs, historique des audits

- [x] **Spécification de l'orchestrateur**
  - Livrable : `specs/orchestrator_spec.md` (scénarios, séquences, critères)
  - Script Go à créer : `cmd/gen_orchestrator_spec.go`
    - Fonction : Générer un template de spec pour l'orchestrateur global.
    - Exemple minimal :
      ```go
      // cmd/gen_orchestrator_spec.go
      package main
      import ("fmt")
      func main() {
        fmt.Println("# Spécification orchestrateur\n- Séquence : backup -> test -> report\n...")
      }
      ```
  - Commande : `go run cmd/gen_orchestrator_spec.go > specs/orchestrator_spec.md`
  - Format attendu : Markdown
  - Critères de validation : Spec générée, logs, commit
  - Rollback : .bak, commit revert
  - CI/CD : Job spec orchestrateur (optionnel)
  - Documentation : README orchestrateur
  - Traçabilité : logs, historique des specs

- [x] **Développement de l'orchestrateur global**
  - Livrable : `cmd/auto-roadmap-runner.go`
  - Script Go à créer : `cmd/auto-roadmap-runner.go`
    - Fonction : Exécuter séquentiellement tous les scripts d'automatisation (backup, restore, git, reporting, feedback), logs, gestion erreurs, notifications.
    - Exemple minimal :
      ```go
      // cmd/auto-roadmap-runner.go
      package main
      import ("fmt"; "os/exec")
      func main() {
        fmt.Println("# Orchestration globale : démarrage")
        exec.Command("go", "run", "scripts/backup.go").Run()
        // ... autres scripts ...
        fmt.Println("# Orchestration globale : terminée")
      }
      ```
  - Commande : `go run cmd/auto-roadmap-runner.go`
  - Format attendu : logs texte, artefacts générés
  - Critères de validation : Exécution complète, logs, artefacts, badge CI
  - Rollback : logs, backup, git revert
  - CI/CD : Job orchestrateur dans `.github/workflows/read_file.yml`
  - Documentation : README orchestrateur, logs d’exécution
  - Traçabilité : logs, historique des runs

- [x] **Tests automatisés de l'orchestrateur**
  - Livrable : `cmd/auto-roadmap-runner_test.go`, badge de couverture
  - Script Go à créer : `cmd/auto-roadmap-runner_test.go`
    - Fonction : Tester l’exécution séquentielle, gestion erreurs, logs.
    - Exemple minimal :
      ```go
      // cmd/auto-roadmap-runner_test.go
      package main
      import ("testing")
      func TestOrchestrator(t *testing.T) {
        // ... test orchestration ...
      }
      ```
  - Commande : `go test -v cmd/auto-roadmap-runner_test.go`
  - Format attendu : Go, Markdown (rapport de test)
  - Critères de validation : Tests passants, logs, badge CI
  - Rollback : suppression tests, git revert
  - CI/CD : Job test orchestrateur dans `.github/workflows/read_file.yml`
  - Documentation : README section tests orchestrateur
  - Traçabilité : logs, historique des tests

- [x] **Reporting & feedback de l'orchestration**
  - Livrable : `reports/orchestration_report.md` (synthèse des runs, logs, erreurs, feedback)
  - Script Go à créer : `scripts/gen_orchestration_report.go`
    - Fonction : Générer un rapport Markdown à partir des logs d’exécution de l’orchestrateur.
    - Exemple minimal :
      ```go
      // scripts/gen_orchestration_report.go
      package main
      import ("fmt")
      func main() {
        fmt.Println("# Rapport orchestration\n- Runs : ...\n- Erreurs : ...")
      }
      ```
  - Commande : `go run scripts/gen_orchestration_report.go > reports/orchestration_report.md`
  - Format attendu : Markdown
  - Critères de validation : Rapport généré, logs, badge CI
  - Rollback : suppression rapport, git revert
  - CI/CD : Job reporting orchestration dans `.github/workflows/read_file.yml`
  - Documentation : README section reporting orchestration
  - Traçabilité : logs, historique des rapports

#### 2. Intégration CI/CD
- [x] **Définition et génération du pipeline CI/CD**
  - Livrable : `.github/workflows/read_file.yml` (jobs backup, restore, git, reporting, feedback, orchestration)
  - Script YAML à créer/adapter : `.github/workflows/read_file.yml`
    - Fonction : Définir les jobs, triggers, artefacts, notifications, rollback.
    - Exemple minimal :
      ```yaml
      name: read_file_pipeline
      on: [push, pull_request]
      jobs:
        build:
          runs-on: ubuntu-latest
          steps:
            - uses: actions/checkout@v3
            - name: Build
              run: go build ./...
        test:
          runs-on: ubuntu-latest
          steps:
            - uses: actions/checkout@v3
            - name: Test
              run: go test -v -cover ./...
      ```
  - Commande : push, trigger pipeline
  - Format attendu : YAML, logs, artefacts
  - Critères de validation : Pipeline vert, logs, artefacts archivés, badge CI
  - Rollback : désactivation job, revert
  - CI/CD : Pipeline activé sur push/PR
  - Documentation : README section CI/CD
  - Traçabilité : logs, historique des runs, badge CI

---

> Toutes les sous-étapes sont atomiques, automatisables, testées, traçables, avec rollback/versionning, documentation, intégration CI/CD, et alignées sur la stack Go native et la structure du dépôt. Si une étape échoue, logs et rapport d’erreur sont générés, et une alternative manuelle est proposée dans le README.
