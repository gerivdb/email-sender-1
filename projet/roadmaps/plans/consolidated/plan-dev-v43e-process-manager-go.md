# Plan de développement v43e - Création d'un Gestionnaire de Processus en Go
*Version 1.0 - 2025-06-04 - Progression globale : 0%*

Ce plan de développement détaille la conception et l'implémentation d'un nouveau `ProcessManager` en Go natif pour le projet EMAIL SENDER 1. Ce gestionnaire remplacera la version PowerShell existante et s'alignera sur les nouveaux standards v43+ du projet, en privilégiant Go pour la performance, la robustesse et l'harmonisation avec les autres gestionnaires Go (ConfigManager, ErrorManager, DependencyManager). L'objectif est de fournir un orchestrateur centralisé capable de découvrir, exécuter et gérer les processus et les tâches des différents managers du projet.

## Table des matières
- [1] Phase 1 : Conception et Architecture du ProcessManager en Go
- [2] Phase 2 : Implémentation du Noyau du ProcessManager
- [3] Phase 3 : Intégration avec les Gestionnaires Standards (ErrorManager, ConfigManager)
- [4] Phase 4 : Découverte et Exécution des Managers
- [5] Phase 5 : Gestion des Tâches et des Workflows (Basique)
- [6] Phase 6 : Interface CLI et API (Optionnel)
- [7] Phase 7 : Tests Approfondis et Validation
- [8] Phase 8 : Documentation et Déploiement

## Phase 1 : Conception et Architecture du ProcessManager en Go
*Progression : 0%*

### 1.1 Définition des Responsabilités et du Périmètre
*Progression : 0%*
- [ ] Objectif : Clarifier les fonctionnalités clés du `ProcessManager` Go.
  - [ ] Étape 1.1 : Définir les capacités principales.
    - [ ] Micro-étape 1.1.1 : Gestion du cycle de vie des processus des autres managers (démarrage, arrêt, statut).
    - [ ] Micro-étape 1.1.2 : Exécution de commandes/tâches spécifiques exposées par les managers.
    - [ ] Micro-étape 1.1.3 : Découverte des managers enregistrés (via manifestes ou configuration).
    - [ ] Micro-étape 1.1.4 : Orchestration simple de séquences de tâches impliquant plusieurs managers.
    - [ ] Micro-étape 1.1.5 : Collecte et transmission standardisée des logs et erreurs (via `ErrorManager`).
  - [ ] Étape 1.2 : Définir les interactions avec les autres managers.
    - [ ] Micro-étape 1.2.1 : Comment le `ProcessManager` invoquera-t-il les managers Go (exécution de binaire, appel gRPC, etc.) ?
    - [ ] Micro-étape 1.2.2 : Comment le `ProcessManager` interagira-t-il avec les managers PowerShell existants pendant la transition (exécution de scripts .ps1) ?
  - [ ] Entrées : Analyse des fonctionnalités du `ProcessManager` PowerShell existant, besoins d'orchestration du projet.
  - [ ] Sorties : Document de spécifications fonctionnelles pour le `ProcessManager` Go.

### 1.2 Conception de l'Architecture Interne
*Progression : 0%*
- [ ] Objectif : Définir les modules internes du `ProcessManager` Go.
  - [ ] Étape 2.1 : Définir les composants principaux.
    - [ ] Micro-étape 2.1.1 : Module de Découverte (`DiscoveryService`): Responsable de trouver et charger les informations des managers (ex: lire les `manifest.json`).
    - [ ] Micro-étape 2.1.2 : Module d'Exécution (`ExecutionEngine`): Responsable de lancer et de superviser les processus/commandes des managers.
    - [ ] Micro-étape 2.1.3 : Module d'Interface Manager (`ManagerInterface`): Abstraction pour communiquer avec différents types de managers (Go, PowerShell).
    - [ ] Micro-étape 2.1.4 : Module de Configuration (`ConfigService`): Interface avec `ConfigManager` pour charger sa propre configuration.
    - [ ] Micro-étape 2.1.5 : Module de Journalisation/Erreur (`LoggingService`): Interface avec `ErrorManager`.
  - [ ] Étape 2.2 : Définir les structures de données clés.
    - [ ] Micro-étape 2.2.1 : Structure `ManagedProcess` (infos sur un processus managé).
    - [ ] Micro-étape 2.2.2 : Structure `TaskDefinition` (description d'une tâche à exécuter).
    - [ ] Micro-étape 2.2.3 : Structure `ManagerManifest` (informations d'un manager découvert).
  - [ ] Entrées : Spécifications fonctionnelles (1.1).
  - [ ] Sorties : Diagramme d'architecture, description des modules et des structures de données (`development/managers/process-manager-go/architecture.md`).

### 1.3 Conception des Interfaces et des Contrats
*Progression : 0%*
- [ ] Objectif : Définir comment le `ProcessManager` sera invoqué et comment il interagira.
  - [ ] Étape 3.1 : Définir l'interface CLI du `ProcessManager` Go.
    - [ ] Micro-étape 3.1.1 : Commandes principales (ex: `process-manager list-managers`, `process-manager run-task <manager> <task> [params]`, `process-manager status <process_id>`).
  - [ ] Étape 3.2 : (Optionnel) Définir une interface API (gRPC/REST) si une interaction programmatique directe est nécessaire.
  - [ ] Étape 3.3 : Définir le format des manifestes des managers que le `ProcessManager` utilisera pour la découverte.
    - [ ] Micro-étape 3.3.1 : S'inspirer du `manifest.json` existant mais l'adapter pour Go (ex: chemin du binaire, commandes exposées).
  - [ ] Entrées : Spécifications fonctionnelles (1.1), Architecture (1.2).
  - [ ] Sorties : Spécifications de l'interface CLI, format du manifeste (`development/managers/process-manager-go/api_spec.md`).

## Phase 2 : Implémentation du Noyau du ProcessManager
*Progression : 0%*

### 2.1 Initialisation du Projet Go
*Progression : 0%*
- [ ] Objectif : Mettre en place la structure du projet Go pour le `ProcessManager`.
  - [ ] Étape 1.1 : Créer le répertoire `development/managers/process-manager-go`.
  - [ ] Étape 1.2 : Initialiser le module Go (`go mod init github.com/EMAIL_SENDER_1/process-manager-go` ou chemin interne).
  - [ ] Étape 1.3 : Définir la structure des répertoires internes (ex: `cmd/process-manager/`, `internal/discovery/`, `internal/execution/`, `pkg/api/`).
  - [ ] Entrées : Décisions d'architecture (Phase 1).
  - [ ] Sorties : Structure de projet Go initialisée.

### 2.2 Implémentation des Structures de Données de Base
*Progression : 0%*
- [ ] Objectif : Coder les structures de données définies en Phase 1.
  - [ ] Étape 2.1 : Implémenter `ManagedProcess`, `TaskDefinition`, `ManagerManifest` dans des fichiers Go appropriés (ex: `internal/core/types.go`).
  - [ ] Entrées : Description des structures de données (1.2.2).
  - [ ] Sorties : Fichiers Go avec les types de base.

### 2.3 Implémentation du Moteur d'Exécution (Basique)
*Progression : 0%*
- [ ] Objectif : Capacité à lancer et superviser un processus externe simple.
  - [ ] Étape 3.1 : Implémenter les fonctions de base dans `internal/execution/engine.go`.
    - [ ] Micro-étape 3.1.1 : Fonction pour démarrer un processus externe (ex: un binaire Go ou un script PowerShell).
    - [ ] Micro-étape 3.1.2 : Fonction pour récupérer le statut d'un processus (en cours, terminé, erreur).
    - [ ] Micro-étape 3.1.3 : Gestion basique du `stdout` et `stderr` des processus enfants.
  - [ ] Entrées : Architecture (1.2).
  - [ ] Sorties : Module d'exécution capable de lancer des commandes simples.

## Phase 3 : Intégration avec les Gestionnaires Standards (ErrorManager, ConfigManager)
*Progression : 0%*

### 3.1 Intégration avec ErrorManager
*Progression : 0%*
- [ ] Objectif : Standardiser la journalisation et la gestion des erreurs.
  - [ ] Étape 1.1 : Intégrer le client `ErrorManager` (ou son logger Zap configuré).
    - [ ] Micro-étape 1.1.1 : Utiliser le logger Zap pour toute la journalisation interne du `ProcessManager`.
    - [ ] Micro-étape 1.1.2 : Envelopper les erreurs avec `pkg/errors` et les cataloguer via `ErrorManager.CatalogError` pour les erreurs significatives.
  - [ ] Entrées : `plan-dev-v42-error-manager.md`, code de l'ErrorManager.
  - [ ] Sorties : `ProcessManager` utilisant la journalisation et la gestion d'erreurs standardisées.

### 3.2 Intégration avec ConfigManager
*Progression : 0%*
- [ ] Objectif : Gérer la configuration du `ProcessManager` de manière centralisée.
  - [ ] Étape 2.1 : Définir le schéma de configuration du `ProcessManager` (ex: chemin des manifestes, timeouts par défaut).
  - [ ] Étape 2.2 : Implémenter la récupération de sa configuration via `ConfigManager`.
    - [ ] Micro-étape 2.2.1 : Le `ProcessManager` doit appeler `ConfigManager` au démarrage pour charger ses paramètres.
  - [ ] Entrées : `plan-dev-v43a-config-manager.md`, code du ConfigManager.
  - [ ] Sorties : `ProcessManager` chargeant sa configuration depuis `ConfigManager`.

## Phase 4 : Découverte et Exécution des Managers
*Progression : 0%*

### 4.1 Implémentation du Service de Découverte
*Progression : 0%*
- [ ] Objectif : Permettre au `ProcessManager` de trouver les managers disponibles.
  - [ ] Étape 1.1 : Implémenter le parsing des fichiers manifestes (`ManagerManifest`).
    - [ ] Micro-étape 1.1.1 : Fonction pour lire un répertoire et parser tous les `*.manifest.json` trouvés.
  - [ ] Étape 1.2 : Stocker les informations des managers découverts.
  - [ ] Entrées : Format du manifeste (1.3.3), `internal/discovery/discovery.go`.
  - [ ] Sorties : Service de découverte fonctionnel.

### 4.2 Implémentation de l'Interface Manager
*Progression : 0%*
- [ ] Objectif : Abstraire l'interaction avec différents types de managers.
  - [ ] Étape 2.1 : Définir une interface Go `ManagerAdapter` (ex: `ExecuteTask(task TaskDefinition) (output string, err error)`).
  - [ ] Étape 2.2 : Implémenter un adaptateur pour les managers Go (exécution de binaire).
  - [ ] Étape 2.3 : Implémenter un adaptateur pour les managers PowerShell (exécution de script .ps1).
  - [ ] Entrées : Architecture (1.2), `internal/execution/adapters.go`.
  - [ ] Sorties : Adaptateurs pour les types de managers cibles.

### 4.3 Exécution de Tâches Spécifiques aux Managers
*Progression : 0%*
- [ ] Objectif : Permettre d'exécuter des commandes définies dans les manifestes des managers.
  - [ ] Étape 3.1 : Modifier `ExecutionEngine` pour utiliser les `ManagerAdapter`.
  - [ ] Étape 3.2 : Permettre de passer des paramètres aux tâches des managers.
  - [ ] Entrées : Service de découverte (4.1), Adaptateurs (4.2).
  - [ ] Sorties : Capacité à exécuter des tâches ciblées sur des managers spécifiques.

## Phase 5 : Gestion des Tâches et des Workflows (Basique)
*Progression : 0%*

### 5.1 Suivi de l'État des Tâches
*Progression : 0%*
- [ ] Objectif : Garder une trace des tâches en cours, terminées, ou en erreur.
  - [ ] Étape 1.1 : Implémenter un gestionnaire d'état des tâches en mémoire.
    - [ ] Micro-étape 1.1.1 : Assigner des IDs uniques aux tâches.
    - [ ] Micro-étape 1.1.2 : Stocker le statut, l'heure de début/fin, la sortie, les erreurs.
  - [ ] Entrées : `internal/core/types.go`.
  - [ ] Sorties : Système de suivi d'état des tâches.

### 5.2 Orchestration Séquentielle Simple
*Progression : 0%*
- [ ] Objectif : Exécuter une série de tâches dans un ordre défini.
  - [ ] Étape 2.1 : Définir un format simple pour décrire une séquence de tâches (ex: un fichier JSON ou YAML).
  - [ ] Étape 2.2 : Implémenter la capacité d'exécuter une telle séquence.
  - [ ] Entrées : Suivi d'état (5.1).
  - [ ] Sorties : Fonctionnalité basique d'orchestration.

## Phase 6 : Interface CLI et API (Optionnel)
*Progression : 0%*

### 6.1 Implémentation de l'Interface CLI
*Progression : 0%*
- [ ] Objectif : Fournir une interface en ligne de commande pour interagir avec le `ProcessManager`.
  - [ ] Étape 1.1 : Utiliser une bibliothèque Go pour la CLI (ex: `cobra`, `urfave/cli`).
  - [ ] Étape 1.2 : Implémenter les commandes définies en 1.3.1 (lister managers, exécuter tâche, voir statut).
  - [ ] Entrées : Spécifications CLI (1.3.1), `cmd/process-manager/main.go`.
  - [ ] Sorties : Binaire `process-manager.exe` fonctionnel.

### 6.2 (Optionnel) Implémentation d'une API gRPC/REST
*Progression : 0%*
- [ ] Objectif : Exposer les fonctionnalités du `ProcessManager` via une API programmatique.
  - [ ] Étape 2.1 : Définir les services et messages Protobuf (pour gRPC) ou les endpoints OpenAPI (pour REST).
  - [ ] Étape 2.2 : Implémenter le serveur API.
  - [ ] Entrées : Spécifications API (1.3.2).
  - [ ] Sorties : Serveur API fonctionnel.

## Phase 7 : Tests Approfondis et Validation
*Progression : 0%*

### 7.1 Tests Unitaires
*Progression : 0%*
- [ ] Objectif : Assurer la qualité et la robustesse de chaque module.
  - [ ] Étape 1.1 : Écrire des tests unitaires pour le service de découverte, le moteur d'exécution, les adaptateurs, etc.
  - [ ] Étape 1.2 : Viser une couverture de test élevée (>80%).
  - [ ] Entrées : Code des modules.
  - [ ] Sorties : Suite de tests unitaires complète.

### 7.2 Tests d'Intégration
*Progression : 0%*
- [ ] Objectif : Valider l'interaction entre les modules du `ProcessManager` et avec les managers externes.
  - [ ] Étape 2.1 : Tester la découverte et l'exécution de managers Go mockés.
  - [ ] Étape 2.2 : Tester la découverte et l'exécution de scripts PowerShell mockés.
  - [ ] Étape 2.3 : Tester l'intégration avec `ConfigManager` et `ErrorManager` réels (ou leurs mocks).
  - [ ] Entrées : `ProcessManager` complet.
  - [ ] Sorties : Scénarios de tests d'intégration validés.

## Phase 8 : Documentation et Déploiement
*Progression : 0%*

### 8.1 Documentation Technique et Utilisateur
*Progression : 0%*
- [ ] Objectif : Documenter le fonctionnement, l'API et l'utilisation du `ProcessManager`.
  - [ ] Étape 1.1 : Rédiger un `README.md` pour `development/managers/process-manager-go/`.
  - [ ] Étape 1.2 : Documenter l'architecture (`architecture.md`).
  - [ ] Étape 1.3 : Documenter l'interface CLI et le format des manifestes (`api_spec.md` ou guide utilisateur).
  - [ ] Étape 1.4 : Générer la documentation GoDoc.
  - [ ] Entrées : Code finalisé, spécifications.
  - [ ] Sorties : Documentation complète.

### 8.2 Préparation au Déploiement
*Progression : 0%*
- [ ] Objectif : Rendre le `ProcessManager` Go déployable.
  - [ ] Étape 2.1 : Créer un `Makefile` ou des scripts de build pour compiler le binaire.
  - [ ] Étape 2.2 : Définir comment le `ProcessManager` sera lancé (ex: service système, manuellement).
  - [ ] Étape 2.3 : Mettre à jour le `manifest.json` du `ProcessManager` lui-même.
  - [ ] Entrées : Binaire testé, documentation.
  - [ ] Sorties : `ProcessManager` Go prêt à être déployé et intégré dans l'écosystème.
