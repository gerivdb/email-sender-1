# Plan de développement v43c - Gestionnaire de Conteneurs (ContainerManager)
*Version 1.0 - 2025-06-04 - Progression globale : 0%*

## Introduction
Ce document détaille le plan de développement pour le `ContainerManager` du projet `EMAIL_SENDER_1`. Ce manager sera responsable de la gestion du cycle de vie des conteneurs Docker nécessaires au projet, tels que PostgreSQL et Qdrant pour l'environnement de développement et de test, et potentiellement pour l'application elle-même dans des déploiements conteneurisés.

Il fournira une abstraction pour démarrer, arrêter, vérifier l'état et consulter les logs des conteneurs, en s'appuyant sur des fichiers `docker-compose.yml` ou en interagissant directement avec l'API Docker (ou le CLI Docker).

Le `ContainerManager` respectera les principes DRY (en centralisant la logique de gestion Docker), KISS (en offrant une API simple pour les opérations courantes sur les conteneurs), et SOLID (en ayant une responsabilité unique et en étant potentiellement extensible pour d'autres runtimes de conteneurs à l'avenir).

Il sera situé dans `development/managers/container-manager/`.

## Table des matières
- [1] Phase 1 : Conception et Initialisation
- [2] Phase 2 : Implémentation de la gestion via Docker Compose
- [3] Phase 3 : Implémentation de la gestion via API Docker (Optionnel)
- [4] Phase 4 : Intégration, Tests et Documentation

## Phase 1 : Conception et Initialisation
*Progression : 0%*

### 1.1 Définition détaillée des responsabilités et du périmètre
*Progression : 0%*
- [ ] Micro-étape 1.1.1 : Lister les fonctionnalités exactes :
    - [ ] Démarrer un ensemble de services définis dans un `docker-compose.yml`.
    - [ ] Arrêter les services.
    - [ ] Vérifier le statut des services/conteneurs (running, stopped, health).
    - [ ] Récupérer les logs d'un service/conteneur spécifique.
    - [ ] Lister les conteneurs gérés.
    - [ ] S'assurer que les volumes et réseaux nécessaires sont configurés (via Docker Compose).
    - [ ] Optionnel : Tirer les images Docker si elles ne sont pas présentes localement.
    - [ ] Optionnel : Supprimer les conteneurs et volumes associés (cleanup).
- [ ] Micro-étape 1.1.2 : Définir les interfaces publiques du manager :
    - [ ] `type ContainerManager interface { ... }`
    - [ ] `func New(cfg ConfigManager) (ContainerManager, error)`
    - [ ] `func (cm *containerManagerImpl) StartServices(composeFilePath string, services []string) error` // services optionnel, démarre tout si vide
    - [ ] `func (cm *containerManagerImpl) StopServices(composeFilePath string, services []string) error`
    - [ ] `func (cm *containerManagerImpl) GetServiceStatus(composeFilePath string, serviceName string) (string, error)` // ex: "running", "stopped", "unhealthy"
    - [ ] `func (cm *containerManagerImpl) GetServiceLogs(composeFilePath string, serviceName string, tailLines int) (string, error)`
    - [ ] `func (cm *containerManagerImpl) IsServiceRunning(composeFilePath string, serviceName string) (bool, error)`
- [ ] Micro-étape 1.1.3 : Identifier les points d'intégration :
    - [ ] `IntegratedManager` : Pour l'initialisation et potentiellement pour démarrer/arrêter les conteneurs au démarrage/arrêt de l'application (surtout en dev/test).
    - [ ] `ConfigManager` : Pour obtenir les chemins vers les fichiers `docker-compose.yml`, noms des services par défaut.
    - [ ] `StorageManager` : Pourrait dépendre du `ContainerManager` pour s'assurer que les DBs sont prêtes avant de tenter une connexion (en environnement de test/dev).
    - [ ] `ErrorManager` : Pour logger les erreurs de gestion des conteneurs.

### 1.2 Initialisation de la structure du module Go
*Progression : 0%*
- [ ] Micro-étape 1.2.1 : Créer le répertoire `development/managers/container-manager/`.
- [ ] Micro-étape 1.2.2 : Créer les fichiers initiaux.
    - [ ] `container_manager.go` (implémentation principale et interface)
    - [ ] `compose_driver.go` (logique pour interagir avec `docker-compose` CLI)
    - [ ] `docker_api_driver.go` (logique pour interagir avec l'API Docker - optionnel)
    - [ ] `types.go` (structs pour statuts, etc.)
    - [ ] `container_manager_test.go`
    - [ ] `README.md`
- [ ] Micro-étape 1.2.3 : Identifier les dépendances (ex: `github.com/docker/docker` client si API Docker est utilisée).

### 1.3 Conception de la gestion des erreurs internes
*Progression : 0%*
- [ ] Micro-étape 1.3.1 : Définir des erreurs spécifiques (ex: `ErrComposeFileNotFound`, `ErrServiceNotRunning`, `ErrDockerCommandFailed`).
- [ ] Micro-étape 1.3.2 : Planifier l'utilisation du `ErrorManager` centralisé.

### 1.4 Planification des tests initiaux
*Progression : 0%*
- [ ] Micro-étape 1.4.1 : Préparer un `docker-compose.test.yml` simple (ex: avec un service `alpine` qui fait un `ping`).
- [ ] Micro-étape 1.4.2 : Tester le démarrage et l'arrêt de ce service via le CLI `docker-compose` manuellement pour comprendre les commandes.

## Phase 2 : Implémentation de la gestion via Docker Compose CLI
*Progression : 0%*

### 2.1 Implémentation des fonctions de base (Start, Stop)
*Progression : 0%*
- [ ] Micro-étape 2.1.1 : Implémenter `StartServices` en utilisant `exec.Command("docker-compose", "-f", composeFilePath, "up", "-d", services...)`.
    - [ ] Gérer la construction de la commande et l'exécution.
    - [ ] Capturer stdout/stderr pour le logging.
    - [ ] Scripts : `compose_driver.go`
- [ ] Micro-étape 2.1.2 : Implémenter `StopServices` en utilisant `exec.Command("docker-compose", "-f", composeFilePath, "down", services...)` ou `stop`.
    - [ ] Scripts : `compose_driver.go`
- [ ] Micro-étape 2.1.3 : Tests unitaires (nécessitent Docker et `docker-compose` installés).
    - [ ] Utiliser le `docker-compose.test.yml`.
    - [ ] Scripts : `container_manager_test.go`

### 2.2 Implémentation des fonctions de statut et de logs
*Progression : 0%*
- [ ] Micro-étape 2.2.1 : Implémenter `GetServiceStatus`.
    - [ ] Utiliser `docker-compose -f <file> ps <service>` et parser la sortie, ou `docker inspect`.
    - [ ] Scripts : `compose_driver.go`
- [ ] Micro-étape 2.2.2 : Implémenter `IsServiceRunning` (basé sur `GetServiceStatus`).
    - [ ] Scripts : `compose_driver.go`
- [ ] Micro-étape 2.2.3 : Implémenter `GetServiceLogs`.
    - [ ] Utiliser `docker-compose -f <file> logs --no-color <service>`.
    - [ ] Scripts : `compose_driver.go`
- [ ] Micro-étape 2.2.4 : Tests unitaires pour le statut et les logs.
    - [ ] Scripts : `container_manager_test.go`

### 2.3 Gestion de la configuration des chemins et services
*Progression : 0%*
- [ ] Micro-étape 2.3.1 : Le `ContainerManager` doit pouvoir accepter le chemin du `docker-compose.yml` lors de l'appel des méthodes, ou utiliser un chemin par défaut configurable via `ConfigManager`.
- [ ] Micro-étape 2.3.2 : Permettre de spécifier les services cibles ou d'opérer sur tous les services du fichier compose.

## Phase 3 : Implémentation de la gestion via API Docker (Optionnel / Amélioration Future)
*Cette phase est optionnelle et peut être considérée comme une amélioration pour éviter la dépendance au CLI `docker-compose` et avoir un contrôle plus fin.*
*Progression : 0%*

### 3.1 Intégration du client Docker Go
*Progression : 0%*
- [ ] Micro-étape 3.1.1 : Ajouter la dépendance `github.com/docker/docker`.
- [ ] Micro-étape 3.1.2 : Implémenter la connexion au daemon Docker.
    - [ ] Scripts : `docker_api_driver.go`

### 3.2 Ré-implémentation des fonctions de base avec l'API
*Progression : 0%*
- [ ] Micro-étape 3.2.1 : Implémenter le démarrage de conteneurs (plus complexe car il faut gérer réseaux, volumes, etc., qui sont décrits dans le compose).
    - [ ] Nécessite de parser le `docker-compose.yml` (ex: avec `github.com/compose-spec/compose-go`) puis de traduire en appels API Docker.
- [ ] Micro-étape 3.2.2 : Implémenter l'arrêt, le statut, les logs via l'API.
- [ ] Micro-étape 3.2.3 : Tests unitaires pour le driver API.

## Phase 4 : Intégration, Tests et Documentation
*Progression : 0%*

### 4.1 Intégration avec `IntegratedManager` et `ConfigManager`
*Progression : 0%*
- [ ] Micro-étape 4.1.1 : `IntegratedManager` initialise `ContainerManager`.
- [ ] Micro-étape 4.1.2 : `ContainerManager` utilise `ConfigManager` pour les chemins par défaut des fichiers compose.

### 4.2 Scénarios d'utilisation (ex: tests d'intégration)
*Progression : 0%*
- [ ] Micro-étape 4.2.1 : Avant de lancer des tests d'intégration qui dépendent de PostgreSQL/Qdrant, `IntegratedManager` (ou un hook de test) utilise `ContainerManager` pour démarrer ces services.
- [ ] Micro-étape 4.2.2 : Après les tests, les services sont arrêtés.

### 4.3 Tests d'intégration du `ContainerManager` lui-même
*Progression : 0%*
- [ ] Micro-étape 4.3.1 : Tester le cycle de vie complet : start -> status -> logs -> stop.
- [ ] Micro-étape 4.3.2 : Tester avec plusieurs services dans un fichier compose.
- [ ] Micro-étape 4.3.3 : Tester les cas d'erreur (fichier compose non trouvé, service inexistant, commande docker échoue).

### 4.4 Documentation (GoDoc, README)
*Progression : 0%*
- [ ] Micro-étape 4.4.1 : Documenter les interfaces et fonctions publiques.
- [ ] Micro-étape 4.4.2 : Mettre à jour le `README.md` de `ContainerManager`.
    - [ ] Expliquer comment l'utiliser (avec Docker Compose CLI).
    - [ ] Prérequis (Docker, Docker Compose installés).
    - [ ] Exemples de fichiers `docker-compose.yml` attendus.

### 4.5 Validation finale et couverture de tests
*Progression : 0%*
- [ ] Micro-étape 4.5.1 : Viser une couverture de tests adéquate (les tests d'intégration seront prédominants ici).
- [ ] Micro-étape 4.5.2 : Revue de code et linting.

### 4.6 Scripts et Conditions
*Progression : 0%*
- [ ] Scripts principaux :
    - `development/managers/container-manager/container_manager.go`
    - `development/managers/container-manager/compose_driver.go`
- [ ] Fichiers de test Docker Compose :
    - `development/managers/container-manager/testdata/docker-compose.simple.yml`
    - `development/managers/container-manager/testdata/docker-compose.multiservice.yml`
- [ ] Conditions préalables générales : Go 1.22+, Docker et Docker Compose installés sur la machine de développement/test, `ConfigManager` et `ErrorManager` (interfaces de base disponibles).
