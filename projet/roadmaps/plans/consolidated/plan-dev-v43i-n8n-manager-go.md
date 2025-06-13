# Plan de développement v43i - Gestionnaire N8N (Go)

*Version 1.0 - 2025-06-04 - Progression globale : 0%*

Ce plan de développement détaille la création d'un nouveau **Gestionnaire N8N (N8NManager)** en Go pour le projet EMAIL SENDER 1. Ce manager sera responsable de toutes les interactions avec une instance N8N, y compris le déclenchement de workflows, la récupération de résultats, la gestion des erreurs d'exécution des workflows, et la configuration des connexions à l'API N8N. L'objectif est d'encapsuler la logique d'intégration N8N, de la rendre réutilisable et testable. Ce manager s'inscrira dans la nouvelle architecture v43+ visant à harmoniser les composants clés en Go.

## Table des matières

- [1] Phase 1 : Conception et Initialisation du Projet
- [2] Phase 2 : Client API N8N
- [3] Phase 3 : Déclenchement et Suivi des Workflows
- [4] Phase 4 : Gestion des Données et Résultats des Workflows
- [5] Phase 5 : Gestion des Erreurs et Configuration
- [6] Phase 6 : Intégration avec les Autres Gestionnaires (v43+)
- [7] Phase 7 : Tests et Validation
- [8] Phase 8 : Documentation et Finalisation

## Phase 1 : Conception et Initialisation du Projet

*Progression : 0%*

### 1.1 Analyse des Besoins d'Intégration N8N

*Progression : 0%*
- [ ] Identifier les workflows N8N spécifiques à intégrer
- [ ] Définir les données d'entrée requises par ces workflows
- [ ] Spécifier les données de sortie attendues et leur format
- [ ] Déterminer les mécanismes d'authentification pour l'API N8N (API Key, OAuth)
- [ ] Lister les cas d'erreur à gérer (ex: workflow non trouvé, échec d'exécution, timeout)

### 1.2 Initialisation du Module Go

*Progression : 0%*
- [ ] Créer le répertoire `development/managers/n8n-manager/`
- [ ] Initialiser le module Go : `go mod init github.com/EMAIL_SENDER_1/n8n-manager`
- [ ] Définir la structure de base (ex: `cmd/`, `pkg/`, `internal/`, `pkg/client`, `pkg/workflows`)
- [ ] Mettre en place les outils de linting et de formatage

### 1.3 Définition des Structures de Données Principales

*Progression : 0%*
- [ ] Concevoir la structure `N8NWorkflowExecution` (ID, statut, inputs, outputs, erreurs)
- [ ] Concevoir la structure `N8NConnectionConfig` (URL de l'instance N8N, credentials)
- [ ] Définir des structures pour les inputs/outputs spécifiques des workflows clés si nécessaire
- [ ] Sauvegarder les structures dans `development/managers/n8n-manager/pkg/types/types.go`

## Phase 2 : Client API N8N

*Progression : 0%*

### 2.1 Implémentation du Client HTTP

*Progression : 0%*
- [ ] Utiliser le package `net/http` de Go pour créer un client HTTP configurable
- [ ] Gérer les headers (ex: `Content-Type: application/json`, `Authorization`)
- [ ] Implémenter la gestion des timeouts et des nouvelles tentatives (retry) de base
- [ ] Module : `development/managers/n8n-manager/internal/client/http_client.go`

### 2.2 Fonctions d'Interaction avec l'API N8N

*Progression : 0%*
- [ ] Fonction pour lister les workflows (si API N8N le permet et si c'est utile)
- [ ] Fonction pour récupérer la définition/statut d'un workflow spécifique
- [ ] Fonction pour déclencher un workflow (via webhook ou API d'exécution directe)
  - [ ] Gérer les paramètres d'entrée du workflow
- [ ] Fonction pour récupérer les résultats/statut d'une exécution de workflow
- [ ] Gérer la pagination si applicable pour les listes ou les résultats d'exécution
- [ ] Module : `development/managers/n8n-manager/pkg/client/api_wrapper.go`

## Phase 3 : Déclenchement et Suivi des Workflows

*Progression : 0%*

### 3.1 Déclenchement Synchrone de Workflows

*Progression : 0%*
- [ ] Implémenter `TriggerWorkflowSync(workflowId string, inputs map[string]interface{}) (N8NWorkflowExecution, error)`
  - [ ] Attend la fin de l'exécution du workflow pour retourner les résultats
  - [ ] Gérer les timeouts pour les exécutions longues

### 3.2 Déclenchement Asynchrone de Workflows

*Progression : 0%*
- [ ] Implémenter `TriggerWorkflowAsync(workflowId string, inputs map[string]interface{}) (string, error)`
  - [ ] Retourne immédiatement un ID d'exécution pour suivi ultérieur
- [ ] Implémenter `GetWorkflowExecutionStatus(executionId string) (N8NWorkflowExecution, error)`

### 3.3 Abstraction des Workflows

*Progression : 0%*
- [ ] Créer des fonctions spécifiques pour les workflows N8N fréquemment utilisés
  - [ ] Ex: `ExecuteEmailSendingWorkflow(params EmailParams) (EmailResult, error)`
  - [ ] Ces fonctions encapsulent l'ID du workflow et la transformation des inputs/outputs
- [ ] Module : `development/managers/n8n-manager/pkg/workflows/facade.go`

## Phase 4 : Gestion des Données et Résultats des Workflows

*Progression : 0%*

### 4.1 Parsing et Validation des Données d'Entrée

*Progression : 0%*
- [ ] Avant de déclencher un workflow, valider que les données d'entrée sont correctes (types, champs requis)
- [ ] Transformer les données Go en format JSON attendu par N8N

### 4.2 Parsing et Transformation des Résultats

*Progression : 0%*
- [ ] Parser la réponse JSON de N8N
- [ ] Transformer les résultats en structures Go utilisables par l'application
- [ ] Gérer les différents formats de sortie que N8N peut produire

## Phase 5 : Gestion des Erreurs et Configuration

*Progression : 0%*

### 5.1 Gestion des Erreurs de l'API N8N

*Progression : 0%*
- [ ] Interpréter les codes de statut HTTP de l'API N8N (4xx, 5xx)
- [ ] Parser les messages d'erreur retournés par N8N
- [ ] Mapper ces erreurs à des types d'erreurs Go spécifiques (ex: `ErrWorkflowNotFound`, `ErrExecutionFailed`)
- [ ] Intégrer avec `ErrorManager` (v42) pour la journalisation

### 5.2 Configuration de la Connexion N8N

*Progression : 0%*
- [ ] Permettre la configuration de l'URL de l'instance N8N et des credentials via `ConfigManager` (v43a)
- [ ] Gérer la mise à jour dynamique de la configuration si nécessaire

## Phase 6 : Intégration avec les Autres Gestionnaires (v43+)

*Progression : 0%*

### 6.1 Intégration avec `ConfigManager` (v43a)

*Progression : 0%*
- [ ] Lire la configuration de connexion N8N (URL, API Key)
- [ ] Potentiellement stocker les ID des workflows ou d'autres configurations liées à N8N

### 6.2 Intégration avec `ErrorManager` (v42) / `LoggingManager`

*Progression : 0%*
- [ ] Journaliser toutes les interactions avec N8N (déclenchements, résultats, erreurs)
- [ ] Utiliser le catalogage d'erreurs pour les problèmes d'intégration N8N

### 6.3 Exposition des Services aux Autres Managers/Services Applicatifs

*Progression : 0%*
- [ ] Fournir une API Go claire et simple pour interagir avec N8N depuis d'autres parties de l'application

## Phase 7 : Tests et Validation

*Progression : 0%*

### 7.1 Tests Unitaires

*Progression : 0%*
- [ ] Tester le client API N8N avec un serveur HTTP mocké
  - [ ] Simuler des réponses N8N réussies et des erreurs
- [ ] Valider la logique de déclenchement synchrone et asynchrone
- [ ] Tester le parsing et la transformation des données
- [ ] Objectif : >90% de couverture de code

### 7.2 Tests d'Intégration

*Progression : 0%*
- [ ] (Optionnel, si une instance N8N de test est disponible) Tester l'intégration avec une instance N8N réelle
  - [ ] Déclencher un workflow de test simple
  - [ ] Vérifier la récupération des résultats
- [ ] Valider l'intégration avec `ConfigManager` pour la configuration de la connexion

## Phase 8 : Documentation et Finalisation

*Progression : 0%*

### 8.1 Documentation Technique

*Progression : 0%*
- [ ] Documenter l'API publique du `N8NManager` (godoc)
- [ ] Décrire l'architecture du client API et les flux d'interaction avec N8N
- [ ] Lister les workflows N8N supportés et leurs signatures (inputs/outputs attendus)

### 8.2 Guide Utilisateur pour les Développeurs

*Progression : 0%*
- [ ] Expliquer comment utiliser le `N8NManager` pour déclencher des workflows et gérer les résultats
- [ ] Fournir des exemples de code pour les cas d'utilisation courants

### 8.3 Préparation pour le Déploiement Interne

*Progression : 0%*
- [ ] Scripts de build et configuration pour les différents environnements
- [ ] Ajouter le manager à `development/managers/integrated-manager`

### 8.4 Revue de Code et Améliorations

*Progression : 0%*
- [ ] Revue de code complète
- [ ] Optimiser les appels API et la gestion des données
- [ ] S'assurer de la robustesse face aux erreurs N8N

## Livrables Attendus

- Module Go fonctionnel pour le `N8NManager` dans `development/managers/n8n-manager/`
- Client API N8N testable et réutilisable
- Tests unitaires (et d'intégration si possible)
- Documentation technique et guide pour les développeurs
- Intégration avec `ConfigManager` et `ErrorManager`/`LoggingManager`

Ce plan sera mis à jour au fur et à mesure de l'avancement du développement.
Les dates et les pourcentages de progression seront actualisés régulièrement.
