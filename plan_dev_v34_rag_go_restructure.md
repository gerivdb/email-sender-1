# Plan de Développement EMAIL SENDER 1 - RAG Go
*Version v34 - Intégration EMAIL_SENDER_1 - 27 Mai 2025 - Progression globale : 63%*

Ce plan de développement détaille l'architecture, l'état d'avancement et la feuille de route pour l'implémentation d'un système RAG (Retrieval Augmented Generation) performant en Go, intégré avec le projet EMAIL_SENDER_1 et une base de données vectorielle QDrant standalone. L'objectif est d'optimiser les performances et d'apporter une intelligence contextuelle avancée aux processus d'envoi d'emails.

## Table des matières
- [1] Phase 1: Setup & Architecture EMAIL_SENDER_1 + RAG
- [2] Phase 2: Core RAG Engine + EMAIL_SENDER Integration
- [3] Phase 3: API & Search + EMAIL_SENDER workflows
- [4] Phase 4: Performance + EMAIL_SENDER Optimization
- [5] Phase 5: Tests & Validation EMAIL_SENDER + RAG
- [6] Phase 6: Documentation & Déploiement EMAIL_SENDER + RAG
- [7] Méthodologies et Standards
- [8] Axes de Développement Futurs et Décisions Architecturales

## Phase 1: Setup & Architecture EMAIL_SENDER_1 + RAG
*Progression: 100%*

### 1.1 Architecture n8n workflows
*Progression: 100%*
- [x] Définition et mise en place de l'architecture des workflows n8n pour EMAIL_SENDER_1.
    *Détails : Identification des workflows principaux (Email Sender - Phase 1, 2, 3; Email Sender - Config). Pattern de workflow EMAIL_SENDER_1 + RAG défini.*
    *Sources : `/src/n8n/workflows/`, `/src/n8n/workflows/archive`*
    *Entrées : Besoins fonctionnels EMAIL_SENDER_1.*
    *Sorties : Diagramme d'architecture des workflows, spécifications des workflows.*

### 1.2 Intégration MCP servers
*Progression: 100%*
- [x] Intégration des serveurs MCP (Model Context Protocol).
    *Détails : Connexion des serveurs (filesystem, github, gcp) pour fournir du contexte aux modèles IA.*
    *Sources : `/src/mcp/servers/`*
    *Conditions préalables : Serveurs MCP disponibles et configurés.*

### 1.3 Setup RAG Go
*Progression: 100%*
- [x] Mise en place initiale du système RAG en Go.
    *Détails : Configuration de l'environnement Go (1.21+), initialisation du projet RAG, structure des dossiers `/src/rag-go/`.*
    *Sources : `/src/rag-go/`*
    *Conditions préalables : Environnement de développement Go 1.21+.*

## Phase 2: Core RAG Engine + EMAIL_SENDER Integration
*Progression: 85%*

### 2.1 Structures de données RAG
*Progression: 100%*
- [x] Définition et implémentation des structures de données pour le RAG.
    *Détails : Modèles de données pour les documents, embeddings, métadonnées.*

### 2.2 Service Vectorisation
*Progression: 100%*
- [x] Création et finalisation du service de vectorisation.
    *Détails : Choix du modèle d'embedding, implémentation de la logique de transformation de texte en vecteurs.*
    *Scripts illustratifs : `./tools/generators/Generate-Code.ps1 -Type "go-service" -Parameters @{ EntityName="EmailContact" Fields="Email string, Name string, Company string, Vectors []float32, LastInteraction time.Time" Integration="EmailSender" }` (pour la création de services liés).*

### 2.3 Intégration n8n webhooks
*Progression: 90%*
- [ ] Intégration des webhooks n8n avec le système RAG.
    *Détails : Assurer la communication bidirectionnelle sécurisée entre n8n et RAG pour l'enrichissement de contexte et le déclenchement d'actions.*
    *Méthodologie : Contract-First pour les APIs des webhooks.*

### 2.4 Implémentation Mock
*Progression: 60%*
- [ ] Finalisation de l'implémentation des Mocks pour les services externes.
    *Détails : Mocks pour Qdrant client, n8n webhook endpoints, Notion API, Gmail API, OpenRouter/DeepSeek pour permettre un développement et des tests découplés.*
    *Méthodologie : Mock-First Strategy.*
    *Sorties potentielles : `mocks/qdrant_client.go`, `mocks/n8n_webhook.go`, `mocks/notion_api.go` (dans `/src/rag-go/mocks/` ou un chemin similaire).*
    *Scripts de génération : `./tools/generators/Generate-Code.ps1 -Type "mock-service" -Parameters @{ ServiceName="EmailSenderService" ... Integration="n8n,notion,gmail" }`, `./tools/n8n/Generate-Mocks.ps1 -Type "workflow" ...`.*
    *Conditions préalables : Interfaces de service clairement définies.*

### 2.5 Indexation
*Progression: 50% (Progression détaillée des sous-tâches ci-dessous)*

#### 2.5.1 BatchIndexer
*Progression: 100%*
- [x] Développement et finalisation du BatchIndexer pour l'ingestion massive de données.
    *Détails : Capacité à traiter de grands volumes de documents sources pour la vectorisation et l'indexation.*

#### 2.5.2 Intégration Qdrant
*Progression: 95%*
- [ ] Intégration avec la base de données vectorielle QDrant.
    *Détails : Configuration de la connexion, opérations CRUD sur les vecteurs, gestion des collections. "Analyse HTTP complète" effectuée, suggérant une validation approfondie de l'API Qdrant.*
    *Outils : `docker-compose.yml` pour l'environnement QDrant local.*
    *Conditions préalables : Instance QDrant accessible.*

#### 2.5.3 Indexation contacts Notion
*Progression: 80%*
- [ ] Finalisation de l'indexation des contacts depuis Notion.
    *Détails : Extraction des données de la base de données LOT1 (contacts programmateurs), transformation et indexation dans RAG/QDrant. Gestion de la synchronisation.*
    *Entrées : Accès API Notion, structure de la base LOT1.*
    *Sorties : Contacts Notion vectorisés et indexés.*

#### 2.5.4 Indexation historique Gmail
*Progression: 70%*
- [ ] Finalisation de l'indexation de l'historique des emails Gmail.
    *Détails : Extraction des emails pertinents, nettoyage, vectorisation et indexation pour analyse contextuelle et historique des interactions.*
    *Entrées : Accès API Gmail, critères de filtrage des emails.*
    *Sorties : Historique Gmail vectorisé et indexé.*

## Phase 3: API & Search + EMAIL_SENDER workflows
*Progression: 25%*

### 3.1 APIs RAG de base
*Progression: 0%*
- [ ] Développement des APIs RAG de base.
    *Détails : Conception et implémentation des endpoints REST pour la recherche sémantique, la récupération de contexte (ex: `/search/contacts`, `/email-context/{contactId}`). Intégration de la logique de validation comme `validateEmailSearchRequest`.*
    *Méthodologie : Contract-First Development. Utilisation de Code Generation Framework pour les handlers et structures à partir d'OpenAPI.*
    *Scripts : `go generate ./api/email-sender/...` (commande typique pour la génération de code à partir de directives `//go:generate`).*
    *Sorties : Spécification OpenAPI `./api/email-sender-openapi.yaml`. Code des handlers et des modèles de données généré dans `/src/rag-go/api/` ou similaire.*
    *Conditions préalables : Service de recherche RAG fonctionnel (Phase 2), contrat OpenAPI défini.*

### 3.2 Endpoints n8n intégration
*Progression: 60%*
- [ ] Finalisation du développement des endpoints pour l'intégration n8n.
    *Détails : Création et sécurisation des webhooks pour permettre aux workflows n8n d'interagir avec le système RAG (ex: `/webhooks/n8n/{workflowId}`). Implémentation de la logique de validation comme `validateN8nWebhook`.*
    *Sources : Workflows n8n dans `/src/n8n/workflows/` qui consommeront ces endpoints.*
    *Entrées : Spécifications des données échangées avec n8n.*
    *Sorties : Endpoints webhooks fonctionnels et documentés.*

### 3.3 Webhooks EMAIL_SENDER
*Progression: 80%*
- [ ] Finalisation de la mise en place et de la configuration des webhooks spécifiques à EMAIL_SENDER.
    *Détails : Webhooks pour des événements clés dans le processus EMAIL_SENDER, potentiellement pour la mise à jour de statuts ou le déclenchement d'actions contextuelles.*
    *Conditions préalables : Logique métier EMAIL_SENDER définie pour les événements concernés.*

## Phase 4: Performance + EMAIL_SENDER Optimization
*Progression: 0%*

- [ ] **4.1 Analyse et optimisation des performances globales**
    *Détails : Identifier les goulots d'étranglement dans le système RAG et les workflows EMAIL_SENDER. Optimiser l'utilisation des ressources (CPU, mémoire, I/O).*
    *Méthodologie : Metrics-Driven Development. Utilisation de `validateEmailSenderConfig` pour s'assurer de configurations optimales.*
    *Outils : Prometheus pour la collecte de métriques, Grafana pour les dashboards.*
    *Scripts : `./metrics/collectors/Collect-PerformanceMetrics.ps1`, `./metrics/dashboards/Start-EmailSenderDashboard.ps1` (ou `./metrics/dashboards/Start-Dashboard.ps1`).*
    *Sorties : Rapports de performance, configurations optimisées, fichier d'alertes `./monitoring/email-sender-alerts.yml`.*
- [ ] **4.2 Optimisation de la parallélisation des workflows EMAIL_SENDER**
    *Détails : Permettre le traitement simultané de plusieurs tâches ou emails pour améliorer le débit.*
- [ ] **4.3 Optimisation des requêtes RAG**
    *Détails : Affiner les stratégies de recherche, optimiser les requêtes vectorielles, améliorer la pertinence des résultats.*
- [ ] **4.4 Mise en cache prédictive des contextes EMAIL_SENDER**
    *Détails : Anticiper les besoins en contexte et les précharger en cache pour réduire la latence.*
- [ ] **4.5 Pipeline de vectorisation en temps réel pour nouveaux contacts/données**
    *Détails : Assurer une indexation rapide des nouvelles informations pour qu'elles soient immédiatement disponibles pour le RAG.*

## Phase 5: Tests & Validation EMAIL_SENDER + RAG
*Progression: 85%*

### 5.1 Tests unitaires RAG
*Progression: 100%*
- [x] Écriture et exécution des tests unitaires pour les composants RAG.
    *Détails : Couverture des fonctions critiques, validation des logiques métier isolées. Exemples de tests : `TestEmailSenderProviders`.*
    *Méthodologie : Inverted TDD, Go testing framework. Utilisation des standards de complexité cyclomatique < 10.*
    *Outils : `go test ./...`*

### 5.2 Tests BatchIndexer
*Progression: 100%*
- [x] Écriture et exécution des tests pour le BatchIndexer.
    *Détails : Validation du traitement correct des lots de données, gestion des erreurs, performance.*

### 5.3 Tests d'intégration QDrant
*Progression: 100%*
- [x] Écriture et exécution des tests d'intégration avec QDrant.
    *Détails : "90+ tests analysés". Validation de la connectivité, des opérations CRUD sur les vecteurs, recherche, filtrage.*
    *Conditions préalables : Instance QDrant accessible (peut être mockée ou réelle selon la portée du test).*

### 5.4 Tests workflows n8n
*Progression: 100%*
- [x] Écriture et exécution des tests pour les workflows n8n.
    *Détails : Validation de la logique de chaque workflow, des intégrations avec les services externes (via mocks ou instances réelles contrôlées). Exemple de test généré : `TestN8nWorkflowIntegration_EmailSenderPhase1`.*
    *Scripts : `./scripts/test-n8n-workflows.sh`, `./scripts/validate-email-sender-workflows.sh`.*
    *Conditions préalables : Workflows n8n déployés dans un environnement de test.*

### 5.5 Tests EMAIL_SENDER end-to-end
*Progression: 0%*
- [ ] Écriture et exécution des tests end-to-end pour EMAIL_SENDER.
    *Détails : Simuler des scénarios utilisateurs complets, de la création/récupération de contact à l'envoi d'email personnalisé avec contexte RAG et au suivi des réponses.*
    *Méthodologie : Inverted TDD, Code Generation Framework pour les squelettes de tests. Exemples de tests auto-générés : `TestSendProspectionEmail_Success`, `TestVectorSearchContacts_WithEmailSenderContext`.*
    *Scripts de génération : `./tools/generators/Generate-Code.ps1 -Type "test-suite" -Parameters @{ Package="email-sender" ... Integration="n8n,notion,gmail,rag" }`.*
    *Scripts d'exécution (depuis CI) : `./scripts/e2e-test-prospection-workflow.sh`, `./scripts/smoke-tests-email-sender.sh`.*

### 5.6 Tests de performance
*Progression: 0%*
- [ ] Réalisation des tests de performance.
    *Détails : Mesurer la latence des APIs, le throughput du système RAG et des workflows n8n sous charge. Identifier les limites du système.*
    *Exemples de benchmarks auto-générés : `BenchmarkEmailSenderWorkflow_EndToEnd`.*
    *Scripts : `go test -bench=. -benchmem ./... > benchmark-email-sender.txt`, `./scripts/analyze-email-sender-performance.sh`.*
    *Outils : Outils de test de charge (k6, jmeter, etc.), profiling Go.*

## Phase 6: Documentation & Déploiement EMAIL_SENDER + RAG
*Progression: 85%*

### 6.1 Documentation RAG de base
*Progression: 100%*
- [x] Rédaction de la documentation de base pour le système RAG.
    *Détails : Architecture du RAG, composants principaux, flux de données, APIs.*
    *Sorties : Documents dans `/docs/guides/architecture/` ou `/src/rag-go/docs/`.*

### 6.2 Documentation QDrant
*Progression: 100%*
- [x] Rédaction de la documentation pour l'intégration et l'utilisation de QDrant.
    *Détails : "Analyse détaillée" effectuée. Configuration, gestion des collections, bonnes pratiques pour QDrant dans le contexte EMAIL_SENDER.*
    *Sorties : Documents dans `/docs/guides/architecture/` ou spécifique à QDrant.*

### 6.3 Documentation EMAIL_SENDER workflows
*Progression: 100%*
- [x] Documentation des workflows EMAIL_SENDER.
    *Détails : Description détaillée de chaque workflow n8n (Phase 1, 2, 3, Config), leurs étapes, triggers, variables, interactions avec RAG et autres services.*
    *Scripts de génération des workflows documentés : `./tools/n8n/Generate-Workflow.ps1 -Type "email-sender-complete" ...`.*
    *Exemple de workflow généré qui nécessite documentation : `EMAIL_SENDER_1 - Prospection avec RAG` (JSON).*
    *Sorties : Documents dans `/docs/guides/n8n/` ou `/projet/guides/n8n/`.*

### 6.4 Documentation n8n intégration
*Progression: 100%*
- [x] Documentation de l'intégration avec n8n.
    *Détails : Comment RAG communique avec n8n, comment configurer les webhooks, gestion des erreurs, format des données échangées.*
    *Sorties : Documents dans `/docs/guides/n8n/` ou `/projet/guides/architecture/`.*

### 6.5 Documentation Time-Saving Methods
*Progression: 100%*
- [x] Création d'un guide complet sur les Time-Saving Methods appliquées au projet.
    *Détails : "Guide complet créé". Description de chaque méthode (Fail-Fast, Mock-First, etc.), exemples d'application concrets dans EMAIL_SENDER, ROI attendu.*
    *Sorties : Document dans `/projet/guides/methodologies/`.*

### 6.6 Guide d'utilisation EMAIL_SENDER + RAG
*Progression: 100%*
- [x] Rédaction du guide d'utilisation pour EMAIL_SENDER avec RAG.
    *Détails : Comment utiliser le système complet, configurer les campagnes, interpréter les résultats, dépanner les problèmes courants.*
    *Sorties : Documents dans `/docs/guides/email-sender/`.*

### 6.7 Scripts de déploiement et CI/CD
*Progression: 100%*
- [x] Création, configuration et documentation des scripts et pipelines de déploiement automatisé.
    *Détails : "CI/CD automatisé". Pipeline GitHub Actions défini dans `.github/workflows/email-sender-ci-cd.yml` (ou `ci-cd.yml`). Infrastructure as Code avec Terraform. Scripts pour diverses opérations de déploiement et maintenance.*
    *Méthodologie : Pipeline-as-Code.*
    *Sources - CI/CD : `.github/workflows/email-sender-ci-cd.yml`.*
    *Sources - Scripts : `/development/scripts/deploy/`, `/scripts/` (ex: `./scripts/package-n8n-workflows.sh`).*
    *Sources - IaC : `/devops/terraform/deploy-email-sender.sh`.*
    *Sources - Monitoring setup : `/devops/monitoring/setup-email-sender.sh`.*
    *Outils : Docker (`docker-compose.yml`, `Dockerfile.email-sender`), Kubernetes (`k8s/email-sender/`).*

## 7. Méthodologies et Standards
*Progression: N/A (Informationnel)*

### 7.1 Méthodes Time-Saving (Intégrées)
- [x] **Fail-Fast Validation**
    *Application : Validation workflows n8n + connexions RAG.*
    *Exemples de code : `validateEmailSearchRequest`, `validateN8nWebhook` (dans `/src/rag-go/`).*
- [x] **Mock-First Strategy**
    *Application : Mocks pour n8n webhooks + services RAG.*
    *Exemples de code : `MockN8nWebhookClient`, `MockNotionAPI` (dans `/src/rag-go/mocks/`).*
    *Scripts de génération : `./tools/generators/Generate-Code.ps1 -Type "mock-service" ...`.*
    *Sorties : `mocks/qdrant_client.go`, `mocks/n8n_webhook.go`.*
- [x] **Contract-First Development**
    *Application : APIs n8n + contrats RAG OpenAPI.*
    *Sorties : `./api/email-sender-openapi.yaml`.*
- [x] **Inverted TDD**
    *Application : Tests d'intégration n8n-RAG avant unitaires.*
    *Scripts de génération : `./tools/generators/Generate-Code.ps1 -Type "test-suite" ...`.*
- [x] **Code Generation Framework**
    *Application : Génération workflows n8n + services RAG Go.*
    *Scripts : `./tools/generators/Generate-Code.ps1`, `./tools/n8n/Generate-Workflow.ps1`.*
- [x] **Metrics-Driven Development**
    *Application : Monitoring workflows + performance RAG.*
    *Exemples : Métriques Prometheus, dashboard Grafana.*
    *Scripts : `./metrics/collectors/Collect-PerformanceMetrics.ps1`, `./metrics/dashboards/Start-Dashboard.ps1`.*
- [x] **Pipeline-as-Code**
    *Application : CI/CD pour n8n + déploiement RAG automatisé.*
    *Sorties : `.github/workflows/ci-cd.yml` (ou `email-sender-ci-cd.yml`).*
    *Outils : `docker-compose.yml`.*

### 7.2 Standards Techniques EMAIL_SENDER_1 (Actifs)
- [x] Golang 1.21+ comme environnement principal pour RAG.
- [x] PowerShell 7 + Python 3.11 pour scripts d'intégration et compatibilité legacy.
- [x] TypeScript pour les composants n8n personnalisés et webhooks.
- [x] UTF-8 pour tous les fichiers (avec BOM pour PowerShell).
- [x] Tests unitaires avec Go testing framework, Pester (PS) et pytest (Python).
- [x] Documentation : minimum 20% du code (objectif).
- [x] Complexité cyclomatique < 10 (objectif).

### 7.3 Cycle par tâche avec Framework Golang + EMAIL_SENDER (Adopté)
- [x] Analyze : Décomposition et estimation avec métriques automatisées.
- [x] Learn : Recherche de patterns existants.
- [x] Explore : Prototypage avec code generation (ToT).
- [x] Reason : Boucle ReAct avec validation fail-fast.
- [x] Code : Implémentation Golang haute performance (≤ 5KB par composant RAG).
- [x] Progress : Avancement séquentiel avec pipeline automatisé.
- [x] Adapt : Ajustement de la granularité selon complexité.
- [x] Segment : Division des tâches complexes avec codegen.

### 7.4 Gestion des inputs volumineux EMAIL_SENDER_1 (En place)
- [x] Segmentation automatique si > 5KB avec streaming Go (emails + contacts).
- [x] Compression haute performance (suppression commentaires/espaces) pour workflows n8n.
- [x] Implémentation incrémentale fonction par fonction avec génération de templates.

### 7.5 Modes opérationnels EMAIL_SENDER_1 (Définis)
- [x] **GRAN** : Décomposition des tâches complexes.
- [x] **DEV-R** : Implémentation des tâches roadmap.
- [x] **ARCHI** : Conception et modélisation.
- [x] **DEBUG** : Résolution de bugs.
- [x] **TEST** : Tests automatisés.
- [x] **OPTI** : Optimisation des performances.
- [x] **REVIEW** : Vérification de qualité.
- [x] **PREDIC** : Analyse prédictive.
- [x] **C-BREAK** : Résolution de dépendances circulaires.

## 8. Axes de Développement Futurs et Décisions Architecturales
*Progression: N/A (Informationnel)*

### 8.1 Axes de Développement Prioritaires (À entreprendre)
- [ ] Automatisation complète du workflow de booking avec RAG (Prospection → Suivi → Confirmation → Post-concert).
- [ ] Intégration MCP avancée avec EMAIL_SENDER (Serveurs contextuels, déploiement GitHub Actions).
- [ ] Optimisation continue des performances EMAIL_SENDER + RAG (Parallélisation, cache prédictif, vectorisation temps réel).
- [ ] Amélioration de l'UX EMAIL_SENDER (Interface configuration, dashboards, analytics).

### 8.2 Décisions Architecturales (Actées)
- [x] **Stratégie d'instanciation :** Multi-Instance recommandée pour EMAIL_SENDER (isolation, sécurité).
- [x] **Sécurisation des secrets EMAIL_SENDER_1 :** Principes définis (stockage sécurisé via Vault ou équivalent, couche intermédiaire pour webhooks n8n, configuration centralisée chiffrée).

### 8.3 Prochaines Étapes Clés (Issues du document original)
*Immédiat (Semaine 1 - Rappel des tâches en cours/à démarrer)*
- [ ] **Finaliser Phase 2** : Compléter l'indexation contacts Notion (voir 2.5.3) + historique Gmail (voir 2.5.4).
- [ ] **Démarrer Phase 3** : Développer les endpoints RAG spécialisés EMAIL_SENDER (voir 3.1).
- [ ] **Tests d'intégration initiaux** : Valider la communication n8n ↔ RAG ↔ EMAIL_SENDER (partie de Phase 5).
*Court terme (Semaines 2-3)*
- [ ] **Phase 3 complète** : Finaliser APIs RAG + workflows n8n optimisés.
- [ ] **Phase 4 démarrage** : Mettre en place les métriques de performance EMAIL_SENDER en temps réel.
- [ ] **Documentation utilisateur (finalisation)** : S'assurer que les guides complets EMAIL_SENDER + RAG sont publiés (voir 6.6).
*Moyen terme (Semaines 4-6)*
- [ ] **Phase 5 (finalisation)** : Compléter les tests end-to-end EMAIL_SENDER (voir 5.5) et les tests de performance (voir 5.6).
- [ ] **Phase 6 (déploiement production)** : Déployer en production EMAIL_SENDER + RAG et activer le monitoring complet.
- [ ] **Optimisations continues** : Basées sur les métriques réelles post-déploiement (boucle vers Phase 4).
