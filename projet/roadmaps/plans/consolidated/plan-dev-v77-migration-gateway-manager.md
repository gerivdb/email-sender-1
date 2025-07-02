# Plan de migration v77 – Gateway Manager (consolidé)

---

## PHASE 1 – Préparation et cadrage

- [ ] **1.1 Analyse des dépendances et des modules impactés**
    - Cartographier tous les modules et dépendances liés au Gateway Manager.
    - Identifier les points de couplage fort et les dépendances critiques.
- [ ] **1.2 Définition des objectifs de migration**
    - Définir les objectifs techniques et fonctionnels de la migration v77.
    - Valider les critères de succès avec les parties prenantes.
- [ ] **1.3 Planification détaillée**
    - Découper la migration en lots et jalons.
    - Établir le planning prévisionnel et les ressources nécessaires.

---

## PHASE 2 – Sécurisation de l’existant

- [ ] **2.1 Sauvegarde des configurations et données**
    - Mettre en place une sauvegarde complète des fichiers de configuration et des données critiques.
- [ ] **2.2 Congélation des évolutions hors migration**
    - Geler les évolutions fonctionnelles non liées à la migration sur la branche concernée.
- [ ] **2.3 Documentation de l’état initial**
    - Documenter l’architecture, les flux, les dépendances et les points de vigilance de l’existant.

---

## PHASE 3 – Préparation de l’environnement cible

- [ ] **3.1 Mise à jour des outils et dépendances**
    - Mettre à jour Go, les outils de build, et les dépendances critiques à la version cible.
- [ ] **3.2 Préparation des environnements de test et d’intégration**
    - Déployer des environnements de test représentatifs.
    - Automatiser les déploiements de test.
- [ ] **3.3 Validation des prérequis techniques**
    - Vérifier la compatibilité des outils, scripts et pipelines CI/CD.

---

## PHASE 4 – Migration du code et des modules

- [ ] **4.1 Migration incrémentale des modules**
    - Migrer les modules un par un, en priorisant les plus critiques.
    - Adapter les interfaces et points d’intégration.
- [ ] **4.2 Refactoring des points de couplage fort**
    - Découpler les modules fortement liés.
    - Introduire des interfaces ou adaptateurs si nécessaire.
- [ ] **4.3 Adaptation des scripts et outils internes**
    - Adapter les scripts de build, de test et de déploiement.
    - Mettre à jour la documentation technique.

---

## PHASE 5 – Tests et validation

- [ ] **5.1 Mise à jour et exécution des tests unitaires**
    - Adapter et compléter la couverture de tests unitaires.
- [ ] **5.2 Mise à jour et exécution des tests d’intégration**
    - Adapter et compléter la couverture de tests d’intégration.
- [ ] **5.3 Tests de non-régression**
    - Exécuter des campagnes de tests de non-régression sur l’ensemble du périmètre migré.
- [ ] **5.4 Validation croisée avec les équipes métiers**
    - Organiser des sessions de validation avec les utilisateurs clés.

---

## PHASE 6 – Documentation et formation

- [ ] **6.1 Mise à jour de la documentation technique**
    - Documenter les changements d’architecture, d’API et de configuration.
- [ ] **6.2 Formation des équipes**
    - Former les équipes techniques et métiers aux évolutions apportées par la migration.

---

## PHASE 7 – Déploiement et bascule

- [ ] **7.1 Préparation du plan de bascule**
    - Définir les étapes de bascule, les points de contrôle et les procédures de rollback.
- [ ] **7.2 Déploiement progressif**
    - Déployer la nouvelle version en environnement de préproduction puis production.
    - Surveiller les métriques et les logs.
- [ ] **7.3 Gestion des incidents post-migration**
    - Mettre en place une cellule de support renforcée pendant la période de stabilisation.

---

## PHASE 8 – Correction des erreurs Go critiques (lots 1 à 18)

### 8.1 à 8.14 (lots 1 à 14)
- [ ] **8.1 à 8.14**  
    - (Voir historique ou annexes pour le détail des lots 1 à 14, chaque lot correspondant à une série d’erreurs Go à corriger, avec la même structure que les lots suivants.)

---

### 8.15 Résolution des erreurs Go critiques (lot 15)

- [ ] **8.15.1 Corriger les erreurs d’imports de dépendances et modules manquants**
    - Ajouter les dépendances manquantes dans le `go.mod` racine ou du module concerné :
        - `github.com/email-sender-manager/storage-manager`
        - `github.com/email-sender-manager/dependency-manager`
        - `github.com/email-sender-manager/security-manager`
        - `github.com/google/uuid`
        - `github.com/sirupsen/logrus`
        - `github.com/spf13/cobra`
        - `github.com/spf13/viper`
        - `go.uber.org/zap`
        - `gopkg.in/yaml.v3`
        - `github.com/stretchr/testify/assert`
        - `github.com/stretchr/testify/require`
        - `github.com/stretchr/testify/suite`
    - Vérifier et corriger les imports internes :
        - `maintenance-manager/src/core`
        - `maintenance-manager/src/vector`
        - `maintenance-manager/src/ai`
        - `maintenance-manager/src/cleanup`
        - `maintenance-manager/src/integration`
        - `maintenance-manager/src/templates`
        - `maintenance-manager/src/vector/qdrant`
        - `maintenance-manager/tests`
        - `integrated-manager`
        - `integration-manager`
        - `interfaces`
        - `integration`
        - `integration_tests`

- [ ] **8.15.2 Corriger les erreurs de types ou symboles non déclarés**
    - Exemple : `undefined: interfaces`, `undefined: contains`, `undefined: NewMockErrorManager`, `undefined: VectorRegistry`, `undefined: IntegrationHub`, `undefined: AIAnalyzer`, `undefined: PatternRecognizer`, `undefined: NewVectorRegistry`, `undefined: NewIntegrationHub`, `undefined: NewAIAnalyzer`, `undefined: NewPatternRecognizer`, `undefined: CleanupResult`, etc.
        - Vérifier la déclaration et l’import des fonctions/types/symboles utilisés dans le code.

- [ ] **8.15.3 Corriger les erreurs de structure et de déclaration**
    - Exemple : `main redeclared in this block`, `ErrorEntry redeclared in this block`, `IntegratedErrorManager redeclared in this block`, `GetIntegratedErrorManager redeclared in this block`, `PropagateError redeclared in this block`, `PropagateErrorWithContext redeclared in this block`, `CentralizeErrorWithContext redeclared in this block`, `AddErrorHook redeclared in this block`, `BaseManager redeclared in this block`, `ManagerStatus redeclared in this block`, `StatusStarting redeclared in this block`, `StatusError redeclared in this block`, `StatusRunning redeclared in this block`, `StatusStopping redeclared in this block`, `StatusStopped redeclared in this block`, `DependencyConflict redeclared in this block`, `AIAnalyzer redeclared in this block`, `LearningData redeclared in this block`, `PatternSuccess redeclared in this block`, `AnalysisPattern redeclared in this block`, `AIRequest redeclared in this block`, `AIMessage redeclared in this block`, `AIResponse redeclared in this block`, `AIChoice redeclared in this block`, `AIUsage redeclared in this block`, `NewAIAnalyzer redeclared in this block`, `method ... already declared`, `invalid constant type ManagerStatus`, `invalid import path (invalid character U+003A ':')`, `missing ',' in composite literal`, `imported and not used: ...`, `declared and not used: ...`, `undefined: ...`, etc.
        - Harmoniser les noms de package dans chaque dossier.
        - Corriger l’ordre des imports et des déclarations.
        - Corriger les erreurs de typage, de déclaration et d’utilisation des variables.

---

### 8.16 Résolution des erreurs Go critiques (lot 16)

- [ ] **8.16.1 Corriger les erreurs d’imports de dépendances et modules manquants**
    - Ajouter les dépendances manquantes dans le `go.mod` racine ou du module concerné :
        - `github.com/stretchr/testify/assert`
        - `github.com/stretchr/testify/mock`
        - `github.com/Masterminds/semver/v3`
        - `github.com/google/uuid`
        - `github.com/robfig/cron/v3`
        - `github.com/gin-gonic/gin`
        - `github.com/go-git/go-git/v5`
        - `github.com/go-git/go-git/v5/plumbing`
        - `github.com/go-git/go-git/v5/plumbing/object`
        - `github.com/google/go-github/v58/github`
        - `golang.org/x/oauth2`
        - `gopkg.in/yaml.v3`
        - `go.uber.org/zap`
        - `go.uber.org/zap/zaptest`
        - `gopkg.in/gomail.v2`
    - Vérifier et corriger les imports internes :
        - `email_sender/development/managers/gateway-manager`
        - `email_sender/internal/core`
        - `github.com/gerivdb/email-sender-1/managers/interfaces`
        - `github.com/gerivdb/email-sender-1/git-workflow-manager/internal/branch`
        - `github.com/gerivdb/email-sender-1/git-workflow-manager/internal/commit`
        - `github.com/gerivdb/email-sender-1/git-workflow-manager/internal/pr`
        - `github.com/gerivdb/email-sender-1/git-workflow-manager/internal/webhook`
        - `github.com/gerivdb/email-sender-1/git-workflow-manager/workflows`
        - `github.com/gerivdb/email-sender-1/managers/integrated-manager`
        - `github.com/gerivdb/email-sender-1/development/managers/storage-manager`
        - `github.com/gerivdb/email-sender-1/development/managers/dependency-manager`
        - `github.com/gerivdb/email-sender-1/development/managers/security-manager`
        - `github.com/gerivdb/email-sender-1/git-workflow-manager`
        - `github.com/gerivdb/email-sender-1/git-workflow-manager/workflows`
        - `github.com/gerivdb/email-sender-1/managers/interfaces`
        - `github.com/gerivdb/email-sender-1/managers/integrated-manager`
        - `github.com/gerivdb/email-sender-1/managers/integrated-manager/demos`
        - `github.com/gerivdb/email-sender-1/managers/integrated-manager/tests`
        - `github.com/gerivdb/email-sender-1/managers/integrated-manager/api_test.go`
        - `github.com/gerivdb/email-sender-1/managers/integrated-manager/error_integration_test.go`
        - `github.com/gerivdb/email-sender-1/managers/integrated-manager/conformity_manager_test.go`
        - `github.com/gerivdb/email-sender-1/managers/integrated-manager/demos/demo_api.go`
        - `github.com/gerivdb/email-sender-1/managers/integrated-manager/demos/phase_2_2_3_test.go`
        - `github.com/gerivdb/email-sender-1/managers/integrated-manager/demos/integration_demo.go`
        - `github.com/gerivdb/email-sender-1/managers/integrated-manager/error_manager_stub.go`
        - `github.com/gerivdb/email-sender-1/managers/integrated-manager/error_integration.go`
        - `github.com/gerivdb/email-sender-1/managers/integrated-manager/conformity_api.go`
        - `github.com/gerivdb/email-sender-1/managers/integrated-manager/conformity_manager.go`
        - `github.com/gerivdb/email-sender-1/managers/integrated-manager/conformity_manager_test.go`
        - `github.com/gerivdb/email-sender-1/managers/integrated-manager/tests`
        - `github.com/gerivdb/email-sender-1/managers/integrated-manager/tests/integration_manager_test.go`
        - `github.com/gerivdb/email-sender-1/managers/integrated-manager/tests/integration_test.go`
        - `github.com/gerivdb/email-sender-1/managers/integrated-manager/tests/conformity_manager_test.go`
        - `github.com/gerivdb/email-sender-1/managers/integrated-manager/tests/error_integration_test.go`
        - `github.com/gerivdb/email-sender-1/managers/integrated-manager/tests/error_manager_stub.go`
        - `github.com/gerivdb/email-sender-1/managers/integrated-manager/tests/demo_api.go`
        - `github.com/gerivdb/email-sender-1/managers/integrated-manager/tests/phase_2_2_3_test.go`
        - `github.com/gerivdb/email-sender-1/managers/integrated-manager/tests/integration_demo.go`

- [ ] **8.16.2 Corriger les erreurs de types ou symboles non déclarés**
    - Exemple : `undefined: semver`, `undefined: git`, `undefined: cron`, `undefined: yaml`, `undefined: gomail`, `undefined: io`, `undefined: contains`, `undefined: NewMockErrorManager`, `undefined: ErrorEntry`, `undefined: GetIntegratedErrorManager`, `undefined: PropagateError`, `undefined: CentralizeErrorWithContext`, `undefined: AddErrorHook`, `undefined: determineSeverity`, `undefined: determineErrorCode`, `undefined: NewIntegratedErrorManager`, `undefined: NewConformityManager`, etc.
        - Vérifier la déclaration et l’import des fonctions/types/symboles utilisés dans le code.

- [ ] **8.16.3 Corriger les erreurs de structure et de déclaration**
    - Exemple : `main redeclared in this block`, `ErrorEntry redeclared in this block`, `IntegratedErrorManager redeclared in this block`, `GetIntegratedErrorManager redeclared in this block`, `PropagateError redeclared in this block`, `PropagateErrorWithContext redeclared in this block`, `CentralizeErrorWithContext redeclared in this block`, `AddErrorHook redeclared in this block`, `BaseManager redeclared in this block`, `ManagerStatus redeclared in this block`, `StatusStarting redeclared in this block`, `StatusError redeclared in this block`, `StatusRunning redeclared in this block`, `StatusStopping redeclared in this block`, `StatusStopped redeclared in this block`, `DependencyConflict redeclared in this block`, `AIAnalyzer redeclared in this block`, `LearningData redeclared in this block`, `PatternSuccess redeclared in this block`, `AnalysisPattern redeclared in this block`, `AIRequest redeclared in this block`, `AIMessage redeclared in this block`, `AIResponse redeclared in this block`, `AIChoice redeclared in this block`, `AIUsage redeclared in this block`, `NewAIAnalyzer redeclared in this block`, `method ... already declared`, `invalid constant type ManagerStatus`, `invalid import path (invalid character U+003A ':')`, `missing ',' in composite literal`, `imported and not used: ...`, `declared and not used: ...`, `undefined: ...`, etc.
        - Harmoniser les noms de package dans chaque dossier.
        - Corriger l’ordre des imports et des déclarations.
        - Corriger les erreurs de typage, de déclaration et d’utilisation des variables.

---

### 8.17 Résolution des erreurs Go critiques (lot 17)

- [ ] **8.17.1 Corriger les erreurs d’imports de dépendances et modules manquants**
    - Ajouter les dépendances manquantes dans le `go.mod` racine ou du module concerné :
        - `github.com/stretchr/testify/assert`
        - `github.com/stretchr/testify/require`
        - `github.com/stretchr/testify/suite`
        - `go.uber.org/zap`
        - `go.uber.org/zap/zaptest`
        - `golang.org/x/mod/modfile`
    - Vérifier et corriger les imports internes :
        - `email_sender/development/managers/contextual-memory-manager/pkg/manager`
        - `email_sender/development/managers/interfaces`
        - `github.com/contextual-memory-manager/internal/monitoring`
        - `github.com/gerivdb/email-sender-1/development/managers/contextual-memory-manager/development`
        - `github.com/gerivdb/email-sender-1/development/managers/contextual-memory-manager/interfaces`
        - `github.com/gerivdb/email-sender-1/development/managers/dependencymanager`
        - `github.com/gerivdb/email-sender-1/development/managers/interfaces`

- [ ] **8.17.2 Corriger les erreurs de types ou symboles non déclarés**
    - Exemple : `undefined: retrieval`, `undefined: baseInterfaces`, `undefined: DependencyManagerImpl`, `undefined: Config`, `undefined: NewDependencyManager`, `undefined: DependencyConfig`, `undefined: PackageManagerConfig`, `undefined: RegistryConfig`, `undefined: AuthConfig`, `undefined: SecurityConfig`, `undefined: ResolutionConfig`, `undefined: CacheConfig`, etc.
        - Vérifier la déclaration et l’import des fonctions/types/symboles utilisés dans le code.

- [ ] **8.17.3 Corriger les erreurs de structure et de déclaration**
    - Exemple : `found packages ... and ... in ...`, `package ...; expected package ...`, `invalid import path (invalid character U+003A ':')`, `declared and not used: ...`, etc.
        - Harmoniser les noms de package dans chaque dossier et fichier.
        - Corriger l’ordre des imports et des déclarations.
        - Corriger les erreurs de typage, de déclaration et d’utilisation des variables.

---

### 8.18 Résolution des erreurs critiques Go/YAML/CI/CD (lot 18)

- [ ] **8.18.1 Corriger les erreurs de directives et de syntaxe Go**
    - Corriger :  
        - `unknown directive: m` dans `go.mod`
        - `local replacement are not allowed` dans les fichiers `go.mod` des sous-modules
        - `cannot load module . listed in go.work file: errors parsing go.mod`
    - Vérifier la conformité des fichiers `go.mod` et `go.work` à la syntaxe Go officielle.

- [ ] **8.18.2 Corriger les erreurs de syntaxe YAML (Helm, GitHub Actions, etc.)**
    - Corriger :  
        - `Unexpected scalar at node end`
        - `Block collections are not allowed within flow collections`
        - `Missing , or : between flow map items`
        - `A block sequence may not be used as an implicit map key`
        - `Implicit keys need to be on a single line`
        - `Implicit map keys need to be followed by map values`
        - `All mapping items must start at the same column`
        - `Incorrect type. Expected "string | array".`
    - Vérifier la conformité des fichiers YAML (Helm charts, GitHub Actions, etc.) aux schémas attendus.

- [ ] **8.18.3 Corriger les erreurs de linting et de style Go**
    - Corriger :  
        - `use of fmt.Printf/Println forbidden by pattern`
        - `missing whitespace above this line`
        - `avoid inline error handling using if err := ...; err != nil`
        - `Context access might be invalid: ...` (GitHub Actions)
    - Appliquer les règles de linting et de style Go et YAML sur l’ensemble du projet.

---

[FIN DU PLAN v77 – VERSION CONSOLIDÉE ET AUGMENTÉE DES 18 LOTS]
