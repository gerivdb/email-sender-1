# Plan de développement v43a - Gestionnaire de Configuration (ConfigManager)
*Version 1.0 - 2025-06-04 - Progression globale : 0%*

## Introduction
Ce document détaille le plan de développement pour le `ConfigManager` du projet `EMAIL_SENDER_1`. Ce manager sera responsable de la centralisation et de la fourniture de toutes les configurations nécessaires à l'application et à ses différents modules. Il chargera les configurations depuis diverses sources (fichiers, variables d'environnement), permettra un accès typé et sécurisé, et gérera les priorités entre les sources.

Le `ConfigManager` respectera les principes DRY (en évitant la duplication de la logique de configuration), KISS (en offrant une API simple et claire), et SOLID (en ayant une responsabilité unique et bien définie, et en étant extensible pour de nouvelles sources de configuration).

Il sera situé dans `development/managers/config-manager/`.

## Table des matières
- [1] Phase 1 : Conception et Initialisation
- [2] Phase 2 : Implémentation des Fonctionnalités Clés
- [3] Phase 3 : Intégration et Tests Avancés
- [4] Phase 4 : Documentation et Finalisation

## Phase 1 : Conception et Initialisation
*Progression : 0%*

### 1.1 Définition détaillée des responsabilités et du périmètre
*Progression : 0%*
- [ ] Micro-étape 1.1.1 : Lister les fonctionnalités exactes :
    - [ ] Chargement depuis fichiers (JSON, YAML, TOML).
    - [ ] Chargement depuis variables d'environnement.
    - [ ] Chargement depuis des valeurs par défaut codées en dur.
    - [ ] Fusion des configurations avec gestion des priorités (ex: env > fichier > défauts).
    - [ ] Accès typé aux valeurs de configuration (string, int, bool, slices, maps, structs imbriquées).
    - [ ] Validation des configurations (champs requis, formats).
    - [ ] Possibilité de "watcher" les fichiers de configuration pour rechargement à chaud (optionnel, future amélioration).
    - [ ] Exposition de sous-sections de configuration pour des modules spécifiques.
- [ ] Micro-étape 1.1.2 : Définir les interfaces publiques du manager :
    - [ ] `type ConfigManager interface { ... }`
    - [ ] `func New() (ConfigManager, error)`
    - [ ] `func (cm *configManagerImpl) GetString(key string) (string, error)`
    - [ ] `func (cm *configManagerImpl) GetInt(key string) (int, error)`
    - [ ] `func (cm *configManagerImpl) GetBool(key string) (bool, error)`
    - [ ] `func (cm *configManagerImpl) UnmarshalKey(key string, targetStruct interface{}) error`
    - [ ] `func (cm *configManagerImpl) IsSet(key string) bool`
    - [ ] `func (cm *configManagerImpl) RegisterDefaults(defaults map[string]interface{})`
    - [ ] `func (cm *configManagerImpl) LoadConfigFile(filePath string, fileType string) error` // fileType could be "json", "yaml", "toml"
    - [ ] `func (cm *configManagerImpl) LoadFromEnv(prefix string)`
- [ ] Micro-étape 1.1.3 : Identifier les points d'intégration :
    - [ ] `IntegratedManager` : Pour l'initialisation et potentiellement pour notifier d'autres managers d'un changement de config (si rechargement à chaud).
    - [ ] Tous les autres managers : Utiliseront `ConfigManager` pour obtenir leurs configurations spécifiques.
    - [ ] `ErrorManager` : Pour logger les erreurs de chargement ou d'accès à la configuration.

### 1.2 Initialisation de la structure du module Go
*Progression : 0%*
- [ ] Micro-étape 1.2.1 : Créer le répertoire `development/managers/config-manager/`.
    - [ ] Entrées : Structure de projet existante.
    - [ ] Sorties : Nouveau répertoire créé.
- [ ] Micro-étape 1.2.2 : Créer les fichiers initiaux.
    - [ ] `config_manager.go` (implémentation principale et interface)
    - [ ] `loader.go` (logique de chargement depuis fichiers/env)
    - [ ] `types.go` (structures de données internes si nécessaire)
    - [ ] `config_manager_test.go` (tests unitaires)
    - [ ] `README.md` (documentation initiale du module)
    - [ ] Entrées : Décisions de conception de l'étape 1.1.
    - [ ] Sorties : Squelettes de fichiers Go.
- [ ] Micro-étape 1.2.3 : S'assurer de l'intégration dans le `go.mod` principal du projet.
    - [ ] Entrées : Fichier `go.mod` existant.
    - [ ] Sorties : `go.mod` mis à jour si nécessaire (généralement pas pour un package interne).

### 1.3 Conception de la gestion des erreurs internes
*Progression : 0%*
- [ ] Micro-étape 1.3.1 : Définir des erreurs spécifiques (ex: `ErrKeyNotFound`, `ErrConfigParse`, `ErrInvalidType`).
    - [ ] Utiliser `fmt.Errorf` avec wrapping (`%w`) ou des types d'erreurs custom.
- [ ] Micro-étape 1.3.2 : Planifier l'utilisation du `ErrorManager` centralisé.
    - [ ] Toutes les erreurs générées par `ConfigManager` qui ne sont pas gérées localement (ex: une clé non trouvée retournée à l'appelant) mais qui indiquent un problème de configuration (ex: fichier de config illisible) seront loggées via `ErrorManager`.
    - [ ] Entrées : Interface de `ErrorManager`.
    - [ ] Sorties : Stratégie de logging d'erreur.

### 1.4 Planification des tests unitaires initiaux
*Progression : 0%*
- [ ] Micro-étape 1.4.1 : Identifier les premiers composants à tester :
    - [ ] Chargement d'un fichier JSON simple.
    - [ ] Lecture d'une variable d'environnement simple.
    - [ ] Application des valeurs par défaut.
    - [ ] Récupération d'une valeur typée (string, int).

## Phase 2 : Implémentation des Fonctionnalités Clés
*Progression : 0%*

### 2.1 Implémentation du chargement des valeurs par défaut
*Progression : 0%*
- [ ] Micro-étape 2.1.1 : Implémenter `RegisterDefaults(defaults map[string]interface{})`.
    - [ ] Stocker les valeurs par défaut en interne.
- [ ] Micro-étape 2.1.2 : S'assurer que les valeurs par défaut sont utilisées si aucune autre source ne fournit la clé.
- [ ] Micro-étape 2.1.3 : Tests unitaires pour les valeurs par défaut.
    - [ ] Scripts : `config_manager_test.go`
    - [ ] Conditions préalables : Structure de base du manager.

### 2.2 Implémentation du chargement depuis fichiers (JSON, YAML, TOML)
*Progression : 0%*
- [ ] Micro-étape 2.2.1 : Implémenter le chargement pour JSON.
    - [ ] Utiliser `encoding/json`.
    - [ ] Gérer les erreurs de lecture de fichier et de parsing.
    - [ ] Scripts : `loader.go`
- [ ] Micro-étape 2.2.2 : Implémenter le chargement pour YAML.
    - [ ] Ajouter une dépendance (ex: `gopkg.in/yaml.v3`).
    - [ ] Mettre à jour `go.mod` et `go.sum`.
    - [ ] Scripts : `loader.go`
- [ ] Micro-étape 2.2.3 : Implémenter le chargement pour TOML.
    - [ ] Ajouter une dépendance (ex: `github.com/BurntSushi/toml`).
    - [ ] Mettre à jour `go.mod` et `go.sum`.
    - [ ] Scripts : `loader.go`
- [ ] Micro-étape 2.2.4 : Implémenter `LoadConfigFile(filePath string, fileType string) error`.
    - [ ] Détecter le type si non fourni (basé sur l'extension) ou utiliser le paramètre `fileType`.
- [ ] Micro-étape 2.2.5 : Tests unitaires pour chaque format de fichier et pour les erreurs.
    - [ ] Créer des fichiers de configuration d'exemple (valides et invalides).
    - [ ] Scripts : `config_manager_test.go`
    - [ ] Conditions préalables : Fonctionnalité 2.1.

### 2.3 Implémentation du chargement depuis variables d'environnement
*Progression : 0%*
- [ ] Micro-étape 2.3.1 : Implémenter `LoadFromEnv(prefix string)`.
    - [ ] Lire toutes les variables d'environnement.
    - [ ] Filtrer celles avec le préfixe spécifié (ex: `APP_CONFIG_`).
    - [ ] Convertir les noms de variables (ex: `APP_CONFIG_DATABASE_HOST` -> `database.host`).
    - [ ] Gérer les types de base (string, int, bool via parsing).
    - [ ] Scripts : `loader.go`
- [ ] Micro-étape 2.3.2 : Tests unitaires pour le chargement depuis l'environnement.
    - [ ] Simuler des variables d'environnement pour les tests.
    - [ ] Scripts : `config_manager_test.go`

### 2.4 Implémentation de la fusion et de la priorité des sources
*Progression : 0%*
- [ ] Micro-étape 2.4.1 : Définir l'ordre de priorité (ex: Env > Fichier spécifique > Fichier général > Défauts).
- [ ] Micro-étape 2.4.2 : Implémenter la logique de fusion qui écrase les valeurs selon la priorité.
    - [ ] Les clés de configuration doivent être normalisées (ex: sensible à la casse ou non).
- [ ] Micro-étape 2.4.3 : Tests unitaires pour divers scénarios de fusion et de priorité.
    - [ ] Scripts : `config_manager_test.go`
    - [ ] Conditions préalables : Fonctionnalités 2.1, 2.2, 2.3.

### 2.5 Implémentation des méthodes d'accès typées
*Progression : 0%*
- [ ] Micro-étape 2.5.1 : Implémenter `GetString`, `GetInt`, `GetBool`.
    - [ ] Gérer la conversion de type si la valeur stockée est d'un type différent mais compatible.
    - [ ] Retourner une erreur si la clé n'est pas trouvée ou si la conversion est impossible.
- [ ] Micro-étape 2.5.2 : Implémenter `IsSet(key string) bool`.
- [ ] Micro-étape 2.5.3 : Implémenter `UnmarshalKey(key string, targetStruct interface{}) error`.
    - [ ] Permettre de déverser une section de la configuration dans une struct Go.
    - [ ] Utiliser une librairie comme `mapstructure` si nécessaire.
- [ ] Micro-étape 2.5.4 : Tests unitaires pour toutes les méthodes d'accès, y compris les cas d'erreur.
    - [ ] Scripts : `config_manager_test.go`

### 2.6 Implémentation de la validation de base des configurations
*Progression : 0%*
- [ ] Micro-étape 2.6.1 : Ajouter une méthode pour valider la configuration chargée (ex: `Validate() error`).
    - [ ] Vérifier la présence de clés requises.
    - [ ] Potentiellement intégrer une librairie de validation de struct (ex: `go-playground/validator`).
- [ ] Micro-étape 2.6.2 : Tests unitaires pour la validation.
    - [ ] Scripts : `config_manager_test.go`

## Phase 3 : Intégration et Tests Avancés
*Progression : 0%*

### 3.1 Intégration avec `IntegratedManager`
*Progression : 0%*
- [ ] Micro-étape 3.1.1 : `IntegratedManager` initialise `ConfigManager` au démarrage.
    - [ ] `IntegratedManager` appelle les méthodes de chargement de `ConfigManager` dans l'ordre approprié.
- [ ] Micro-étape 3.1.2 : Fournir une instance de `ConfigManager` aux autres managers via `IntegratedManager`.
    - [ ] Entrées : Code de `IntegratedManager`.
    - [ ] Sorties : `IntegratedManager` modifié.
    - [ ] Scripts : `development/managers/integrated-manager/manager.go`

### 3.2 Utilisation par d'autres managers (Exemple : `StorageManager`)
*Progression : 0%*
- [ ] Micro-étape 3.2.1 : `StorageManager` récupère ses configurations (ex: DSN de base de données) depuis `ConfigManager`.
    - [ ] `dbHost := cfgManager.GetString("database.host")`
- [ ] Micro-étape 3.2.2 : Adapter les managers existants ou futurs pour utiliser `ConfigManager`.
    - [ ] Entrées : Code des autres managers.
    - [ ] Sorties : Managers modifiés.

### 3.3 Développement des tests d'intégration
*Progression : 0%*
- [ ] Micro-étape 3.3.1 : Créer des scénarios de test où `IntegratedManager` initialise `ConfigManager`, et un autre manager (mock ou réel simple) lit une configuration.
- [ ] Micro-étape 3.3.2 : Tester le cycle de vie complet du chargement et de l'accès.
    - [ ] Scripts : `development/managers/integrated-manager/integration_test.go` (ou un fichier de test dédié)

### 3.4 Tests de robustesse et de gestion des cas limites
*Progression : 0%*
- [ ] Micro-étape 3.4.1 : Tester avec des fichiers de configuration manquants, corrompus, ou avec des permissions incorrectes.
- [ ] Micro-étape 3.4.2 : Tester avec des variables d'environnement non définies ou mal formatées.
- [ ] Micro-étape 3.4.3 : Vérifier le comportement pour des clés de configuration très imbriquées ou avec des noms complexes.

### 3.5 Raffinement de la gestion des erreurs et logging via `ErrorManager`
*Progression : 0%*
- [ ] Micro-étape 3.5.1 : S'assurer que toutes les erreurs critiques de configuration (ex: fichier principal introuvable) sont loggées avec une sévérité appropriée via `ErrorManager`.
- [ ] Micro-étape 3.5.2 : Vérifier que les messages d'erreur sont clairs et informatifs.

## Phase 4 : Documentation et Finalisation
*Progression : 0%*

### 4.1 Documentation du code (GoDoc)
*Progression : 0%*
- [ ] Micro-étape 4.1.1 : Commenter toutes les fonctions publiques, structs, et interfaces dans `config_manager.go`, `loader.go`, etc.
- [ ] Micro-étape 4.1.2 : Générer la documentation GoDoc et la vérifier.

### 4.2 Rédaction de la documentation d'architecture
*Progression : 0%*
- [ ] Micro-étape 4.2.1 : Créer un diagramme simple dans le `README.md` du module expliquant le flux de chargement et de priorité.
- [ ] Micro-étape 4.2.2 : Expliquer les choix de conception majeurs (ex: pourquoi telle librairie de parsing a été choisie, comment la priorité est gérée).

### 4.3 Rédaction d'un guide d'utilisation (`README.md` dans `development/managers/config-manager/`)
*Progression : 0%*
- [ ] Micro-étape 4.3.1 : Expliquer comment initialiser et utiliser le `ConfigManager`.
    - [ ] Ordre d'appel des méthodes de chargement.
    - [ ] Comment définir les fichiers de configuration.
    - [ ] Comment nommer les variables d'environnement.
- [ ] Micro-étape 4.3.2 : Fournir des exemples de code pour récupérer différents types de valeurs.
- [ ] Micro-étape 4.3.3 : Expliquer comment définir des valeurs par défaut.
- [ ] Micro-étape 4.3.4 : Documenter les formats de fichiers supportés.

### 4.4 Validation finale et couverture de tests
*Progression : 0%*
- [ ] Micro-étape 4.4.1 : Exécuter tous les tests et viser une couverture de code d'au moins 90%.
    - [ ] Utiliser `go test -coverprofile=coverage.out && go tool cover -html=coverage.out`.
- [ ] Micro-étape 4.4.2 : Effectuer une revue de code complète du `ConfigManager`.
- [ ] Micro-étape 4.4.3 : S'assurer de l'absence d'erreurs de linting (`golangci-lint run`).

### 4.5 Scripts et Conditions
*Progression : 0%*
- [ ] Scripts principaux :
    - `development/managers/config-manager/config_manager.go`
    - `development/managers/config-manager/loader.go`
    - `development/managers/config-manager/config_manager_test.go`
- [ ] Conditions préalables générales : Go 1.22+, `ErrorManager` et `IntegratedManager` (interfaces de base disponibles).
