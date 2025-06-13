# Flux applicatif détaillé

Ce document décrit les flux principaux de l'application, les interactions entre les composants et le cycle de vie des données.

## Architecture générale

L'application suit une architecture en couches avec les composants suivants :

```plaintext
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Interface  │────▶│ Contrôleurs │────▶│  Services   │────▶│ Repositories │
│ Utilisateur │◀────│    API      │◀────│             │◀────│             │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                                                                   │
                                                                   ▼
                                                            ┌─────────────┐
                                                            │  Base de    │
                                                            │  données    │
                                                            └─────────────┘
```plaintext
## Flux principal : Traitement des emails

### 1. Déclenchement

- L'utilisateur configure un workflow dans n8n
- Le workflow est déclenché par un événement (webhook, timer, etc.)

### 2. Récupération des données

- n8n récupère les données nécessaires (contacts, templates, etc.)
- Les données sont validées et préparées pour le traitement

### 3. Génération des emails

- Le service de templating génère le contenu des emails
- Les pièces jointes sont préparées si nécessaire

### 4. Envoi des emails

- Les emails sont envoyés via l'API Gmail
- Les statuts d'envoi sont enregistrés

### 5. Suivi et reporting

- Les statistiques d'envoi sont mises à jour
- Les rapports sont générés pour l'utilisateur

## Flux secondaire : Gestion des contacts

### 1. Import des contacts

- L'utilisateur importe un fichier CSV/Excel
- Le système valide le format et la structure

### 2. Traitement des données

- Les données sont nettoyées et normalisées
- Les doublons sont détectés et gérés

### 3. Stockage

- Les contacts sont enregistrés dans la base de données
- Les métadonnées sont mises à jour

### 4. Segmentation

- Les contacts sont classés par catégories
- Des tags sont appliqués selon les critères définis

## Flux d'authentification

### 1. Connexion utilisateur

- L'utilisateur fournit ses identifiants
- Le système vérifie les identifiants

### 2. Génération de token

- Un token JWT est généré
- Les informations de session sont enregistrées

### 3. Autorisation

- Les requêtes sont authentifiées via le token
- Les permissions sont vérifiées pour chaque action

### 4. Déconnexion

- Le token est invalidé
- Les ressources de session sont libérées

## Intégrations externes

### Gmail API

- Authentification via OAuth2
- Envoi d'emails via l'API
- Récupération des statuts et des réponses

### n8n

- Exécution de workflows
- Gestion des erreurs et des retries
- Logging des exécutions

### Notion (planifié)

- Synchronisation des données
- Gestion des documents
- Suivi des projets

### ERPNext (futur)

- Gestion des clients
- Facturation
- Reporting financier

## Cycle de vie des données

### Création

- Validation des entrées
- Normalisation
- Attribution d'identifiants uniques

### Stockage

- Persistance dans la base de données
- Mise en cache pour les accès fréquents
- Gestion des versions si nécessaire

### Accès

- Contrôle d'accès basé sur les rôles
- Logging des accès sensibles
- Pagination pour les grandes collections

### Mise à jour

- Validation des modifications
- Gestion des conflits
- Journalisation des changements

### Suppression

- Soft delete vs hard delete
- Archivage des données historiques
- Respect des politiques de rétention
