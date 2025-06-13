# Guide de démarrage rapide MCP

Ce guide vous aidera à démarrer rapidement avec la nouvelle structure MCP (Model Context Protocol) dans le projet EMAIL_SENDER_1.

## Prérequis

- PowerShell 5.1 ou ultérieur
- Node.js 16 ou ultérieur
- Python 3.8 ou ultérieur (pour certains serveurs)
- n8n (pour l'intégration avec les workflows)

## Installation

1. Clonez le dépôt :
   ```
   git clone https://github.com/gerivonderbitsh/EMAIL_SENDER_1.git
   cd EMAIL_SENDER_1
   ```

2. Exécutez le script d'installation :
   ```powershell
   .\projet\mcp\scripts\setup\setup-mcp.ps1
   ```

   Ce script va :
   - Créer la structure de dossiers
   - Installer les dépendances
   - Configurer les serveurs MCP

## Démarrage des serveurs

Pour démarrer tous les serveurs MCP :

```powershell
Import-Module .\projet\mcp\modules\MCPManager
Start-MCPServer
```plaintext
Pour démarrer un serveur spécifique :

```powershell
Start-MCPServer -ServerName filesystem
```plaintext
## Vérification de l'état des serveurs

Pour vérifier l'état des serveurs MCP :

```powershell
Get-MCPServerStatus
```plaintext
## Arrêt des serveurs

Pour arrêter tous les serveurs MCP :

```powershell
Stop-MCPServer
```plaintext
Pour arrêter un serveur spécifique :

```powershell
Stop-MCPServer -ServerName filesystem
```plaintext
## Intégration avec n8n

Pour configurer n8n avec les serveurs MCP :

```powershell
.\projet\mcp\integrations\n8n\scripts\configure-n8n-mcp.ps1
```plaintext
Ensuite, importez les workflows n8n depuis le dossier `projet/mcp/integrations/n8n/workflows/`.

## Surveillance des serveurs

Pour vérifier l'état de santé des serveurs MCP :

```powershell
.\projet\mcp\monitoring\scripts\check-mcp-health.ps1
```plaintext
Pour générer un rapport de santé complet :

```powershell
.\projet\mcp\monitoring\scripts\generate-health-report.ps1 -OutputFormat HTML -IncludeTests
```plaintext
## Sauvegarde et restauration

Pour sauvegarder la configuration MCP :

```powershell
.\projet\mcp\scripts\maintenance\backup-mcp-config.ps1 -CreateZip
```plaintext
Pour planifier des sauvegardes automatiques :

```powershell
.\projet\mcp\scripts\maintenance\schedule-mcp-backups.ps1 -Frequency Daily -Time 02:00 -CreateZip
```plaintext
Pour nettoyer les anciennes sauvegardes :

```powershell
.\projet\mcp\scripts\maintenance\cleanup-mcp-backups.ps1 -MaxAge 30 -MaxCount 10
```plaintext
## Mise à jour des composants

Pour mettre à jour les composants MCP :

```powershell
.\projet\mcp\versioning\scripts\update-mcp-components.ps1
```plaintext
Pour planifier des mises à jour automatiques :

```powershell
.\projet\mcp\scripts\maintenance\schedule-mcp-updates.ps1 -Frequency Weekly -DayOfWeek Sunday -Time 03:00
```plaintext
## Démarrage automatique

Pour configurer le démarrage automatique des serveurs MCP :

```powershell
.\projet\mcp\scripts\utils\register-mcp-startup.ps1 -StartupType User
```plaintext
## Tests

Pour exécuter tous les tests :

```powershell
.\projet\mcp\tests\Run-AllTests.ps1
```plaintext
Pour exécuter uniquement les tests unitaires :

```powershell
.\projet\mcp\tests\Run-AllTests.ps1 -SkipIntegrationTests -SkipPerformanceTests
```plaintext
## Désinstallation

Pour désinstaller les serveurs MCP :

```powershell
.\projet\mcp\scripts\maintenance\uninstall-mcp.ps1
```plaintext
## Structure des dossiers

La nouvelle structure MCP est organisée comme suit :

```plaintext
projet/mcp/
├── core/                  # Composants principaux

├── servers/               # Serveurs spécifiques

├── scripts/               # Scripts d'utilisation

│   ├── setup/             # Scripts d'installation

│   ├── maintenance/       # Scripts de maintenance

│   └── utils/             # Scripts utilitaires

├── modules/               # Modules PowerShell

├── tests/                 # Tests

│   ├── unit/              # Tests unitaires

│   ├── integration/       # Tests d'intégration

│   └── performance/       # Tests de performance

├── config/                # Configuration

│   ├── templates/         # Modèles de configuration

│   ├── environments/      # Configurations par environnement

│   └── servers/           # Configurations des serveurs

├── docs/                  # Documentation

├── integrations/          # Intégrations

│   └── n8n/               # Intégration avec n8n

├── monitoring/            # Monitoring

│   ├── scripts/           # Scripts de monitoring

│   ├── dashboards/        # Dashboards

│   └── alerts/            # Alertes

├── versioning/            # Versioning

│   ├── scripts/           # Scripts de versioning

│   ├── backups/           # Sauvegardes

│   └── changelog/         # Changelog

└── dependencies/          # Dépendances

    ├── npm/               # Dépendances npm

    ├── pip/               # Dépendances pip

    └── binary/            # Dépendances binaires

```plaintext
## Ressources supplémentaires

- [Guide d'installation complet](installation.md)
- [Guide de configuration](configuration.md)
- [Documentation des serveurs](../servers/)
- [Guide de développement](../development/)
