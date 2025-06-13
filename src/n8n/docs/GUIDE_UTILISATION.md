# Guide d'utilisation de la nouvelle structure n8n

Ce guide explique comment utiliser la nouvelle structure n8n mise en place dans le projet.

## Table des matières

1. [Vue d'ensemble](#vue-densemble)

2. [Démarrage](#démarrage)

3. [Gestion des workflows](#gestion-des-workflows)

4. [Configuration](#configuration)

5. [Intégrations](#intégrations)

6. [Automatisation](#automatisation)

7. [Dépannage](#dépannage)

## Vue d'ensemble

La nouvelle structure n8n est organisée de manière à séparer clairement les différents composants et à faciliter la maintenance et l'intégration avec d'autres systèmes.

```plaintext
n8n/
├── core/                  # Composants principaux

│   ├── workflows/        # Workflows n8n

│   ├── credentials/      # Gestion des credentials

│   └── triggers/        # Déclencheurs automatisés

├── integrations/         # Intégrations externes

│   ├── mcp/            # Integration MCP

│   ├── ide/            # Integration IDE

│   └── api/            # APIs externes

├── automation/           # Scripts d'automatisation

│   ├── deployment/      # Scripts de déploiement

│   ├── maintenance/     # Scripts de maintenance

│   └── monitoring/      # Scripts de surveillance

├── data/                 # Données n8n (base de données, credentials, etc.)

└── docs/                # Documentation

    ├── architecture/    # Documentation technique

    ├── workflows/       # Documentation des workflows

    └── api/            # Documentation API

```plaintext
## Démarrage

### Installation

Pour installer n8n avec la nouvelle structure, exécutez le script d'installation :

```powershell
.\n8n\automation\deployment\install-n8n-complete.ps1
```plaintext
Ce script installe n8n, crée la nouvelle structure de dossiers, migre les fichiers existants et configure l'environnement.

### Démarrage de n8n

Pour démarrer n8n, exécutez le script de démarrage :

```plaintext
.\start-n8n-new.cmd
```plaintext
Ou directement :

```powershell
.\n8n\automation\deployment\start-n8n.ps1
```plaintext
### Arrêt de n8n

Pour arrêter n8n, appuyez sur Ctrl+C dans la fenêtre de terminal où n8n est en cours d'exécution.

## Gestion des workflows

### Structure des workflows

Les workflows sont organisés en deux catégories :

1. **Workflows locaux** (`n8n\core\workflows\local`) : Workflows utilisés par l'instance n8n locale
2. **Workflows IDE** (`n8n\core\workflows\ide`) : Workflows utilisés par l'IDE

### Lister les workflows

Pour lister tous les workflows présents dans la nouvelle structure, exécutez :

```powershell
.\n8n\automation\monitoring\list-workflows.ps1
```plaintext
### Synchronisation des workflows

Pour synchroniser les workflows entre n8n et les fichiers locaux, exécutez :

```powershell
.\n8n\automation\maintenance\sync-workflows-simple.ps1
```plaintext
Options disponibles :
- `-Direction` : Direction de la synchronisation (`to-n8n`, `from-n8n`, `both`)
- `-Environment` : Environnement cible (`local`, `ide`, `all`)

Exemple :

```powershell
.\n8n\automation\maintenance\sync-workflows-simple.ps1 -Direction "both" -Environment "all"
```plaintext
## Configuration

### Fichier de configuration

Le fichier de configuration principal de n8n se trouve dans `n8n\core\n8n-config.json`. Ce fichier contient les paramètres de base de n8n, tels que le port, le protocole, l'hôte, etc.

### Variables d'environnement

Les variables d'environnement sont définies dans le fichier `n8n\.env`. Ce fichier est utilisé par le script de démarrage pour configurer l'environnement n8n.

Pour mettre à jour la configuration, exécutez :

```powershell
.\n8n\automation\deployment\update-n8n-config.ps1
```plaintext
## Intégrations

### Intégration MCP

L'intégration avec MCP se trouve dans le dossier `n8n\integrations\mcp`. Cette intégration permet d'utiliser les fonctionnalités de MCP dans les workflows n8n.

### Intégration IDE

L'intégration avec l'IDE se trouve dans le dossier `n8n\integrations\ide`. Cette intégration permet d'utiliser les workflows n8n directement depuis l'IDE.

## Automatisation

### Scripts de déploiement

Les scripts de déploiement se trouvent dans le dossier `n8n\automation\deployment`. Ces scripts permettent d'installer, de configurer et de démarrer n8n.

### Scripts de maintenance

Les scripts de maintenance se trouvent dans le dossier `n8n\automation\maintenance`. Ces scripts permettent de maintenir et de synchroniser les workflows n8n.

### Scripts de surveillance

Les scripts de surveillance se trouvent dans le dossier `n8n\automation\monitoring`. Ces scripts permettent de surveiller l'état de n8n et des workflows.

## Dépannage

### Vérification de la structure

Pour vérifier que la structure n8n est correcte, exécutez :

```powershell
.\n8n\automation\monitoring\test-n8n-structure-simple.ps1
```plaintext
### Problèmes courants

#### n8n ne démarre pas

Si n8n ne démarre pas, vérifiez les points suivants :

1. Vérifiez que n8n est installé : `npx n8n --version`
2. Vérifiez que le fichier `.env` existe : `Test-Path -Path ".\n8n\.env"`
3. Vérifiez que le dossier des données existe : `Test-Path -Path ".\n8n\data"`
4. Vérifiez les logs pour plus d'informations

#### Les workflows ne sont pas visibles

Si les workflows ne sont pas visibles dans n8n, vérifiez les points suivants :

1. Vérifiez que les workflows existent dans le dossier `n8n\core\workflows`
2. Vérifiez que la variable d'environnement `N8N_WORKFLOW_IMPORT_PATH` est correctement définie
3. Essayez de synchroniser les workflows : `.\n8n\automation\maintenance\sync-workflows-simple.ps1`

#### Erreurs d'authentification

Si vous rencontrez des erreurs d'authentification, vérifiez les points suivants :

1. Vérifiez que les variables d'environnement `N8N_BASIC_AUTH_ACTIVE` et `N8N_USER_MANAGEMENT_DISABLED` sont correctement définies
2. Vérifiez que le fichier `n8n\core\api-key.json` existe si vous utilisez une clé API
