# Plan de développement v44 - Optimisation des Goroutines et Tâches PowerShell pour EMAIL_SENDER_1
*Version 1.0 - 2025-06-05 - Progression globale : 0%*

Ce plan de développement détaille l'implémentation de l'optimisation des **goroutines** et des **tâches PowerShell** dans l'écosystème de managers du projet **EMAIL_SENDER_1**. L'objectif est d'identifier et d'implémenter des opérations asynchrones pour améliorer les performances, la scalabilité et la modularité, tout en respectant les principes **DRY**, **KISS**, et **SOLID**. Le plan couvre l'analyse des managers, la parallélisation des opérations, l'intégration avec les systèmes existants, et la validation via des tests unitaires et dry-runs.

## Table des matières
- [1] Phase 1 : Analyse des Opportunités de Parallélisation
- [2] Phase 2 : Implémentation des Goroutines
- [3] Phase 3 : Implémentation des Tâches PowerShell
- [4] Phase 4 : Optimisation des Performances
- [5] Phase 5 : Tests et Validation
- [6] Phase 6 : Documentation et CI/CD
- [7] Phase 7 : Mise à jour et Validation Finale

---

## Phase 1 : Analyse des Opportunités de Parallélisation
*Progression : 0%*

### 1.1 Identification des Opérations Candidates
*Progression : 0%*

#### 1.1.1 Analyse des Managers
- [ ] Identifier les opérations I/O-bound et CPU-bound dans chaque manager (ErrorManager, IntegratedManager, ConfigManager, etc.).
  - [ ] Micro-étape : Vérifier les appels API (ex. : N8NManager.StartWorkflow).
  - [ ] Micro-étape : Analyser les accès aux bases de données (ex. : StorageManager.GetPostgreSQLConnection).
  - [ ] Micro-étape : Identifier les tâches de surveillance (ex. : MonitoringManager.CollectMetrics).
- [ ] Classifier les opérations selon leur potentiel de parallélisation.
  - [ ] Micro-étape : Lister les tâches indépendantes (ex. : démarrage de conteneurs dans ContainerManager).
  - [ ] Micro-étape : Identifier les tâches séquentielles nécessitant une synchronisation (ex. : IntegratedManager.RegisterManager).

#### 1.1.2 Évaluation des Tâches PowerShell
- [ ] Identifier les opérations nécessitant une interaction avec des systèmes Windows.
  - [ ] Micro-étape : Vérifier l'utilisation du PowerShellBridge pour exécuter des scripts existants.
  - [ ] Micro-étape : Analyser les tâches de gestion de certificats ou de services Windows (ex. : SecurityManager, ProcessManager).
- [ ] Vérifier la compatibilité des scripts PowerShell avec une exécution asynchrone via `Start-Job`.

**Tests unitaires** :
- Simuler l'exécution des opérations candidates pour confirmer leur indépendance.
- Vérifier la faisabilité des tâches PowerShell via un dry-run dans un environnement Windows.

**Mise à jour** :
- [ ] Mettre à jour le plan avec les résultats de l’analyse (cases cochées, progression ajustée).

---

## Phase 2 : Implémentation des Goroutines
*Progression : 0%*

### 2.1 Intégration des Goroutines dans les Managers
*Progression : 0%*

#### 2.1.1 ErrorManager
- [ ] Implémenter une goroutine pour `CatalogError`.
  - [ ] Micro-étape : Créer un channel pour envoyer les erreurs au storage.
  - [ ] Micro-étape : Ajouter une gestion des erreurs via ErrorManager.
    ```go
    func (em *errorManagerImpl) CatalogError(ctx context.Context, err error, module string) {
        go func() {
            if err := em.storage.SaveError(ctx, err, module); err != nil {
                em.logger.Error("Failed to catalog error", zap.Error(err))
            }
        }()
    }
    ```
- [ ] Implémenter des goroutines pour `TriggerHooks`.
  - [ ] Micro-étape : Lancer chaque hook dans une goroutine séparée.
  - [ ] Micro-étape : Utiliser une WaitGroup pour synchroniser les hooks critiques.

#### 2.1.2 StorageManager
- [ ] Implémenter une goroutine pour `GetPostgreSQLConnection` et `GetQdrantConnection`.
  - [ ] Micro-étape : Utiliser des channels pour retourner les connexions.
  - [ ] Micro-étape : Intégrer un contexte pour annuler les goroutines en cas d’erreur.
    ```go
    func (sm *storageManagerImpl) GetConnections(ctx context.Context) (pgConn, qdrantConn interface{}, err error) {
        var wg sync.WaitGroup
        pgResult := make(chan interface{})
        errChan := make(chan error, 2)
        wg.Add(1)
        go func() {
            defer wg.Done()
            conn, err := sm.pgPool.Acquire(ctx)
            if err != nil {
                errChan <- err
                return
            }
            pgResult <- conn
        }()
        // Similaire pour Qdrant
        ...
    }
    ```

#### 2.1.3 ContainerManager
- [ ] Implémenter des goroutines pour `StartContainers` et `StopContainers`.
  - [ ] Micro-étape : Paralléliser le démarrage des conteneurs avec une WaitGroup.
  - [ ] Micro-étape : Ajouter des métriques via MonitoringManager pour surveiller les goroutines.

**Tests unitaires** :
- Simuler l’exécution parallèle des goroutines avec des mocks pour les bases de données et conteneurs.
- Tester la gestion des erreurs dans les goroutines via ErrorManager.

**Mise à jour** :
- [ ] Mettre à jour le plan avec les extraits de code implémentés et les résultats des tests.

---

## Phase 3 : Implémentation des Tâches PowerShell
*Progression : 0%*

### 3.1 Intégration avec PowerShellBridge
*Progression : 0%*

#### 3.1.1 Exécution Asynchrone des Scripts
- [ ] Implémenter l’exécution asynchrone des scripts PowerShell via `Start-Job`.
  - [ ] Micro-étape : Créer un script PowerShell pour collecter des métriques Windows.
    ```powershell
    $job = Start-Job -ScriptBlock {
        $cpu = Get-WmiObject Win32_Processor | Measure-Object -Property LoadPercentage -Average
        $cpu.Average | Out-File "cpu_metrics.txt"
    }
    Wait-Job -Job $job
    ```
- [ ] Intégrer le script dans PowerShellBridge.
  - [ ] Micro-étape : Ajouter une méthode `ExecuteAsync` dans PowerShellBridge.
    ```go
    func (pb *powerShellBridgeImpl) ExecuteAsync(ctx context.Context, script string) error {
        go func() {
            if err := pb.runPowerShellScript(script); err != nil {
                pb.errorManager.ProcessError(ctx, err, "PowerShellBridge", "execute_async", nil)
            }
        }()
        return nil
    }
    ```

#### 3.1.2 Gestion des Certificats Windows
- [ ] Implémenter un script PowerShell pour exporter des certificats.
  - [ ] Micro-étape : Vérifier l’accès au magasin de certificats Windows.
    ```powershell
    $cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Subject -eq "CN=EMAIL_SENDER_1" }
    Export-Certificate -Cert $cert -FilePath "cert.pfx"
    ```
- [ ] Intégrer le script dans SecurityManager via PowerShellBridge.

**Tests unitaires** :
- Simuler l’exécution des scripts PowerShell dans un environnement Windows.
- Tester la gestion des erreurs via ErrorManager pour les scripts échoués.

**Mise à jour** :
- [ ] Mettre à jour le plan avec les scripts PowerShell implémentés et les résultats des tests.

---

## Phase 4 : Optimisation des Performances
*Progression : 0%*

### 4.1 Limitation des Goroutines
*Progression : 0%*

#### 4.1.1 Utilisation d’un Pool de Goroutines
- [ ] Implémenter un pool de goroutines avec `golang.org/x/sync/errgroup`.
  - [ ] Micro-étape : Limiter le nombre de goroutines actives pour éviter l’épuisement des ressources.
    ```go
    import "golang.org/x/sync/errgroup"
    func (cm *containerManagerImpl) StartContainers(ctx context.Context, services []string) error {
        g, ctx := errgroup.WithContext(ctx)
        for _, service := range services {
            g.Go(func() error {
                return cm.dockerClient.StartContainer(ctx, service)
            })
        }
        return g.Wait()
    }
    ```

#### 4.1.2 Surveillance des Performances
- [ ] Intégrer MonitoringManager pour collecter les métriques des goroutines.
  - [ ] Micro-étape : Ajouter des métriques pour le nombre de goroutines actives et la consommation CPU/mémoire.

**Tests unitaires** :
- Simuler une charge élevée avec 100 conteneurs pour valider la scalabilité.
- Mesurer la latence des appels API dans des conditions stressées (ex. : < 500ms pour 100 utilisateurs).

**Mise à jour** :
- [ ] Mettre à jour le plan avec les résultats des tests de performance.

---

## Phase 5 : Tests et Validation
*Progression : 0%*

### 5.1 Tests Unitaires et d’Intégration
*Progression : 0%*

#### 5.1.1 Tests des Goroutines
- [ ] Créer des tests unitaires pour chaque goroutine implémentée.
  - [ ] Micro-étape : Simuler des erreurs dans les appels API pour tester ErrorManager.
  - [ ] Micro-étape : Vérifier la synchronisation avec WaitGroup.
- [ ] Effectuer des tests d’intégration dans un environnement Docker.
  - [ ] Micro-étape : Simuler l’exécution de tous les managers avec des goroutines actives.

#### 5.1.2 Tests des Tâches PowerShell
- [ ] Tester les scripts PowerShell dans un environnement Windows.
  - [ ] Micro-étape : Simuler une exécution asynchrone via `Start-Job`.
  - [ ] Micro-étape : Valider les sorties des scripts (ex. : fichiers générés).

**Tests unitaires** :
- Exécuter un dry-run pour chaque goroutine et tâche PowerShell.
- Simuler des erreurs (ex. : base de données hors ligne, script PowerShell invalide).

**Mise à jour** :
- [ ] Mettre à jour le plan avec les résultats des tests.

---

## Phase 6 : Documentation et CI/CD
*Progression : 0%*

### 6.1 Documentation
*Progression : 0%*

#### 6.1.1 Documentation des Goroutines
- [ ] Ajouter des commentaires GoDoc pour chaque méthode utilisant des goroutines.
  - [ ] Micro-étape : Générer la documentation avec `godoc -http=:6060`.
  - [ ] Micro-étape : Créer un guide utilisateur pour les développeurs (ex. : `goroutines-guide.md`).

#### 6.1.2 Documentation des Tâches PowerShell
- [ ] Documenter les scripts PowerShell dans un fichier Markdown.
  - [ ] Micro-étape : Inclure des exemples d’utilisation et des cas d’erreur.

### 6.2 Intégration CI/CD
*Progression : 0%*

#### 6.2.1 Automatisation des Tests
- [ ] Configurer GitHub Actions pour exécuter les tests unitaires et d’intégration.
  - [ ] Micro-étape : Ajouter un workflow YAML pour tester les goroutines et scripts PowerShell.
    ```yaml
    name: CI
    on: [push]
    jobs:
      test:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v3
          - name: Run Go Tests
            run: go test ./...
          - name: Run PowerShell Tests
            run: pwsh -File ./test.ps1
    ```

#### 6.2.2 Stratégie de Rollback
- [ ] Implémenter une stratégie de rollback pour les déploiements échoués.
  - [ ] Micro-étape : Ajouter un script PowerShell pour restaurer les configurations précédentes.

**Tests unitaires** :
- Vérifier que la documentation est accessible via GoDoc.
- Simuler un déploiement CI/CD avec rollback pour valider la robustesse.

**Mise à jour** :
- [ ] Mettre à jour le plan avec les fichiers de documentation et de CI/CD.

---

## Phase 7 : Mise à jour et Validation Finale
*Progression : 0%*

### 7.1 Revue Globale
*Progression : 0%*

#### 7.1.1 Vérification des Lacunes
- [ ] Vérifier que toutes les opérations candidates sont couvertes par des goroutines ou des tâches PowerShell.
- [ ] Confirmer l’alignement avec les principes DRY, KISS, et SOLID.

#### 7.1.2 Validation Intégrale
- [ ] Exécuter un dry-run de l’ensemble du plan dans un environnement Docker.
- [ ] Simuler une implémentation partielle pour confirmer l’actionnabilité.

**Tests unitaires** :
- Simuler l’exécution complète des managers avec des goroutines et tâches PowerShell.
- Vérifier la cohérence des métriques collectées par MonitoringManager.

**Mise à jour** :
- [ ] Mettre à jour la version du plan (v44.1).
- [ ] Ajuster les pourcentages de progression et cocher les tâches terminées.

---

## Recommandations
- **DRY** : Réutiliser les patterns de goroutines (ex. : channels, WaitGroups) via des utilitaires Go.
- **KISS** : Limiter les goroutines aux opérations I/O-bound ou longues, et simplifier les scripts PowerShell.
- **SOLID** : S’assurer que chaque goroutine a une responsabilité unique et que les dépendances sont abstraites via des interfaces.
- **Performances** : Utiliser un pool de goroutines et surveiller les métriques pour éviter l’épuisement des ressources.
- **Sécurité** : Valider les scripts PowerShell avant exécution et stocker les secrets dans SecurityManager.
- **Documentation** : Générer des guides clairs pour les développeurs et utilisateurs finaux.

**Sorties attendues** :
- Fichier Markdown : `plan-dev-v44-goroutines-powershell.md`.
- Scripts Go : `goroutine_utils.go`, `powershell_bridge.go`.
- Scripts PowerShell : `async_metrics.ps1`, `cert_export.ps1`.
- Documentation : `goroutines-guide.md`, `powershell-guide.md`.
- Configuration CI/CD : `.github/workflows/ci.yml`.