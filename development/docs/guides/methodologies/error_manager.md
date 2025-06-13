# Guide du Gestionnaire d'Erreurs

## Introduction

Le gestionnaire d'erreurs est un composant essentiel du système qui centralise la gestion, le traitement et la journalisation des erreurs. Ce document détaille son fonctionnement, ses paramètres, et fournit des exemples d'utilisation pour vous aider à l'utiliser efficacement.

## Objectif

L'objectif principal du gestionnaire d'erreurs est de fournir une approche unifiée pour gérer les erreurs dans l'ensemble du système. Il permet notamment de :

- Centraliser la gestion des erreurs
- Standardiser le format des messages d'erreur
- Journaliser les erreurs de manière cohérente
- Faciliter le diagnostic et la résolution des problèmes

## Architecture

### Structure des répertoires

Le gestionnaire d'erreurs est organisé selon la structure de répertoires suivante :

```plaintext
development/managers/error-manager/
├── scripts/
│   ├── error-manager.ps1           # Script principal

│   ├── install-error-manager.ps1   # Script d'installation

│   └── ...                         # Autres scripts

├── modules/
│   └── ...                         # Modules PowerShell

├── tests/
│   ├── Test-ErrorManager.ps1       # Tests unitaires

│   └── ...                         # Autres tests

└── config/
    └── ...                         # Fichiers de configuration locaux

```plaintext
### Fichiers de configuration

Les fichiers de configuration du gestionnaire sont stockés dans :

```plaintext
projet/config/managers/error-manager/
└── error-manager.config.json       # Configuration principale

```plaintext
## Prérequis

Avant d'utiliser le gestionnaire d'erreurs, assurez-vous que :

1. PowerShell 5.1 ou supérieur est installé sur votre système
2. Le gestionnaire intégré est installé
3. Les droits d'accès appropriés sont configurés

## Installation

### Installation automatique

Pour installer le gestionnaire d'erreurs, utilisez le script d'installation :

```powershell
.\development\managers\error-manager\scripts\install-error-manager.ps1
```plaintext
### Installation manuelle

Si vous préférez une installation manuelle, suivez ces étapes :

1. Copiez les fichiers du gestionnaire dans le répertoire approprié
2. Créez le fichier de configuration dans le répertoire approprié
3. Vérifiez que le gestionnaire fonctionne correctement

## Configuration

### Fichier de configuration principal

Le fichier de configuration principal du gestionnaire est situé à :

```plaintext
projet/config/managers/error-manager/error-manager.config.json
```plaintext
Voici un exemple de configuration :

```json
{
  "Enabled": true,
  "LogLevel": "Info",
  "ErrorLogPath": "logs/errors",
  "MaxLogSize": 10485760,
  "MaxLogCount": 10,
  "ErrorCategories": {
    "Critical": {
      "Color": "Red",
      "NotifyAdmin": true,
      "StopExecution": true
    },
    "Warning": {
      "Color": "Yellow",
      "NotifyAdmin": false,
      "StopExecution": false
    },
    "Info": {
      "Color": "Cyan",
      "NotifyAdmin": false,
      "StopExecution": false
    }
  },
  "NotificationSettings": {
    "EmailEnabled": false,
    "EmailRecipients": [],
    "SlackEnabled": false,
    "SlackWebhook": ""
  }
}
```plaintext
### Options de configuration

| Option | Type | Description | Valeur par défaut |
|--------|------|-------------|-------------------|
| Enabled | boolean | Active ou désactive le gestionnaire | true |
| LogLevel | string | Niveau de journalisation (Debug, Info, Warning, Error) | "Info" |
| ErrorLogPath | string | Chemin vers le répertoire des journaux d'erreurs | "logs/errors" |
| MaxLogSize | number | Taille maximale d'un fichier journal en octets | 10485760 (10 Mo) |
| MaxLogCount | number | Nombre maximal de fichiers journaux à conserver | 10 |
| ErrorCategories | object | Configuration des catégories d'erreurs | {} |
| NotificationSettings | object | Configuration des notifications d'erreurs | {} |

## Utilisation

### Commandes principales

Le gestionnaire d'erreurs expose les commandes suivantes :

#### Commande 1 : LogError

```powershell
.\development\managers\error-manager\scripts\error-manager.ps1 -Command LogError -Message "Une erreur est survenue" -Category "Warning" -Source "MonScript.ps1"
```plaintext
**Description :** Journalise une erreur

**Paramètres :**
- `-Message` : Message d'erreur
- `-Category` : Catégorie d'erreur (Critical, Warning, Info)
- `-Source` : Source de l'erreur
- `-Exception` : Objet exception (optionnel)

**Exemple :**
```powershell
.\development\managers\error-manager\scripts\error-manager.ps1 -Command LogError -Message "Fichier non trouvé" -Category "Critical" -Source "find-managers.ps1" -Exception $_.Exception
```plaintext
#### Commande 2 : GetErrors

```powershell
.\development\managers\error-manager\scripts\error-manager.ps1 -Command GetErrors -StartDate "2025-04-01" -EndDate "2025-04-29"
```plaintext
**Description :** Récupère les erreurs journalisées

**Paramètres :**
- `-StartDate` : Date de début (optionnel)
- `-EndDate` : Date de fin (optionnel)
- `-Category` : Catégorie d'erreur (optionnel)
- `-Source` : Source de l'erreur (optionnel)

**Exemple :**
```powershell
.\development\managers\error-manager\scripts\error-manager.ps1 -Command GetErrors -Category "Critical" -Source "find-managers.ps1"
```plaintext
### Exemples d'utilisation

#### Exemple 1 : Journalisation d'une erreur critique

```powershell
# Journaliser une erreur critique

try {
    # Code qui peut générer une erreur

    $result = 1 / 0
} catch {
    .\development\managers\error-manager\scripts\error-manager.ps1 -Command LogError -Message "Division par zéro" -Category "Critical" -Source "mon-script.ps1" -Exception $_.Exception
}
```plaintext
#### Exemple 2 : Récupération des erreurs récentes

```powershell
# Récupérer les erreurs des dernières 24 heures

$yesterday = (Get-Date).AddDays(-1)
$today = Get-Date
.\development\managers\error-manager\scripts\error-manager.ps1 -Command GetErrors -StartDate $yesterday -EndDate $today
```plaintext
## Intégration avec d'autres gestionnaires

Le gestionnaire d'erreurs s'intègre avec les autres gestionnaires du système :

### Intégration avec le gestionnaire intégré

```powershell
# Utiliser le gestionnaire d'erreurs via le gestionnaire intégré

.\development\managers\integrated-manager\scripts\integrated-manager.ps1 -Manager ErrorManager -Command LogError -Message "Une erreur est survenue" -Category "Warning" -Source "MonScript.ps1"
```plaintext
### Intégration avec le gestionnaire de scripts

```powershell
# Utiliser le gestionnaire d'erreurs avec le gestionnaire de scripts

try {
    .\development\managers\script-manager\scripts\script-manager.ps1 -Command RunScript -ScriptPath "development/scripts/maintenance/find-managers.ps1"
} catch {
    .\development\managers\error-manager\scripts\error-manager.ps1 -Command LogError -Message "Erreur lors de l'exécution du script" -Category "Critical" -Source "script-manager" -Exception $_.Exception
}
```plaintext
## Dépannage

### Problèmes courants et solutions

#### Problème 1 : Erreurs non journalisées

**Symptômes :**
- Les erreurs ne sont pas enregistrées dans les journaux
- Aucun message d'erreur n'est affiché

**Causes possibles :**
- Le gestionnaire d'erreurs est désactivé
- Le niveau de journalisation est trop élevé
- Problèmes de permissions sur les fichiers journaux

**Solutions :**
1. Vérifiez que le gestionnaire d'erreurs est activé dans la configuration
2. Assurez-vous que le niveau de journalisation est approprié
3. Vérifiez les permissions sur le répertoire des journaux

#### Problème 2 : Notifications d'erreur non reçues

**Symptômes :**
- Les notifications d'erreur ne sont pas envoyées
- Les administrateurs ne sont pas informés des erreurs critiques

**Causes possibles :**
- Les notifications sont désactivées
- Configuration incorrecte des paramètres de notification
- Problèmes de connectivité réseau

**Solutions :**
1. Vérifiez que les notifications sont activées dans la configuration
2. Assurez-vous que les paramètres de notification sont corrects
3. Vérifiez la connectivité réseau

### Journalisation

Le gestionnaire d'erreurs génère des journaux dans le répertoire suivant :

```plaintext
logs/error-manager/
```plaintext
Les niveaux de journalisation peuvent être configurés dans le fichier de configuration principal.

## Tests

### Exécution des tests

Pour exécuter les tests du gestionnaire d'erreurs, utilisez la commande suivante :

```powershell
.\development\managers\error-manager\tests\Test-ErrorManager.ps1
```plaintext
### Types de tests disponibles

- **Tests unitaires :** Testent les fonctions individuelles du gestionnaire
- **Tests d'intégration :** Testent l'intégration avec d'autres composants
- **Tests de performance :** Évaluent les performances du gestionnaire

## Bonnes pratiques

### Recommandations d'utilisation

1. Utilisez le gestionnaire d'erreurs pour toutes les erreurs du système
2. Catégorisez correctement les erreurs selon leur gravité
3. Incluez des informations contextuelles dans les messages d'erreur

### Sécurité

1. Ne journalisez pas d'informations sensibles dans les messages d'erreur
2. Protégez l'accès aux fichiers journaux
3. Limitez les notifications aux administrateurs autorisés

## Références

- [Documentation du gestionnaire intégré](integrated_manager.md)
- [Documentation du gestionnaire de scripts](script_manager.md)
- [Guide des bonnes pratiques PowerShell](../best-practices/powershell_best_practices.md)

## Historique des versions

| Version | Date | Description |
|---------|------|-------------|
| 1.0.0 | 2025-04-29 | Version initiale |
