# Procédures d'utilisation de Hygen pour MCP

Ce document présente les procédures d'utilisation de Hygen pour la génération de composants MCP.

## Table des matières

1. [Installation](#installation)

2. [Configuration](#configuration)

3. [Génération de composants](#génération-de-composants)

4. [Personnalisation des templates](#personnalisation-des-templates)

5. [Intégration dans le workflow](#intégration-dans-le-workflow)

6. [Résolution des problèmes](#résolution-des-problèmes)

## Installation

### Installation automatique

La méthode la plus simple pour installer Hygen est d'utiliser le script d'installation :

```batch
.\mcp\cmd\utils\setup-hygen-environment.cmd
```plaintext
Ce script vérifie et configure l'environnement de développement pour Hygen.

### Installation manuelle

Si vous préférez installer Hygen manuellement, suivez ces étapes :

1. Installez Hygen en tant que dépendance de développement :

```bash
npm install --save-dev hygen
```plaintext
2. Vérifiez que Hygen est correctement installé :

```bash
npx hygen --version
```plaintext
3. Créez la structure de dossiers nécessaire :

```powershell
.\mcp\scripts\setup\ensure-hygen-environment.ps1
```plaintext
## Configuration

### Configuration de l'environnement

Pour configurer l'environnement de développement pour Hygen, exécutez le script suivant :

```powershell
.\mcp\scripts\setup\ensure-hygen-environment.ps1
```plaintext
Ce script vérifie et configure les éléments suivants :

- Installation de Hygen
- Structure de dossiers
- Templates
- Dossiers de destination

### Configuration de l'intégration

Pour configurer l'intégration de Hygen dans le workflow de développement, exécutez le script suivant :

```powershell
.\mcp\scripts\utils\Integrate-HygenWorkflow.ps1
```plaintext
Ce script configure les éléments suivants :

- Alias PowerShell
- Tâches VS Code
- Intégration Git

## Génération de composants

### Utilisation du script de commande

La méthode la plus simple pour générer des composants est d'utiliser le script de commande :

```batch
.\mcp\cmd\utils\generate-component.cmd
```plaintext
Ce script vous présentera un menu avec les options suivantes :

1. Générer un script serveur MCP
2. Générer un script client MCP
3. Générer un module MCP
4. Générer une documentation MCP
Q. Quitter

### Utilisation du script PowerShell

Vous pouvez également utiliser directement le script PowerShell :

```powershell
# Générer un composant en mode interactif

.\mcp\scripts\utils\Generate-MCPComponent.ps1

# Générer un script serveur

.\mcp\scripts\utils\Generate-MCPComponent.ps1 -Type server -Name "api-server" -Description "Serveur API MCP" -Author "John Doe"

# Générer un script client

.\mcp\scripts\utils\Generate-MCPComponent.ps1 -Type client -Name "admin-client" -Description "Client d'administration MCP" -Author "Jane Smith"

# Générer un module

.\mcp\scripts\utils\Generate-MCPComponent.ps1 -Type module -Name "MCPUtils" -Description "Utilitaires MCP" -Author "Dev Team"

# Générer une documentation

.\mcp\scripts\utils\Generate-MCPComponent.ps1 -Type doc -Name "installation-guide" -Category "guides" -Description "Guide d'installation MCP" -Author "Doc Team"
```plaintext
### Utilisation des alias PowerShell

Si vous avez exécuté le script d'intégration du workflow, vous pouvez utiliser les alias PowerShell suivants :

```powershell
# Générer un script serveur

gmcps -Name "api-server" -Description "Serveur API MCP" -Author "John Doe"

# Générer un script client

gmcpc -Name "admin-client" -Description "Client d'administration MCP" -Author "Jane Smith"

# Générer un module

gmcpm -Name "MCPUtils" -Description "Utilitaires MCP" -Author "Dev Team"

# Générer une documentation

gmcpd -Name "installation-guide" -Category "guides" -Description "Guide d'installation MCP" -Author "Doc Team"
```plaintext
### Utilisation des tâches VS Code

Si vous avez exécuté le script d'intégration du workflow, vous pouvez utiliser les tâches VS Code suivantes :

1. Ouvrez la palette de commandes (Ctrl+Shift+P)
2. Tapez "Tasks: Run Task"
3. Sélectionnez une des tâches Hygen :
   - Hygen: Generate MCP Server
   - Hygen: Generate MCP Client
   - Hygen: Generate MCP Module
   - Hygen: Generate MCP Doc

## Personnalisation des templates

### Structure des templates

Les templates sont stockés dans le dossier `mcp/_templates`. Chaque générateur a son propre dossier avec des templates spécifiques.

```plaintext
mcp/_templates/
  mcp-server/
    new/
      hello.ejs.t
      prompt.js
  mcp-client/
    new/
      hello.ejs.t
      prompt.js
  mcp-module/
    new/
      hello.ejs.t
      prompt.js
  mcp-doc/
    new/
      hello.ejs.t
      prompt.js
```plaintext
### Modification des templates existants

Pour modifier un template existant, ouvrez le fichier `hello.ejs.t` correspondant dans votre éditeur de texte.

Les templates utilisent la syntaxe EJS (Embedded JavaScript) pour générer du code dynamique. Voici un exemple de template pour un script serveur :

```ejs
---
to: mcp/core/server/<%= name %>.ps1
---
#!/usr/bin/env pwsh

<#

.SYNOPSIS
    <%= description %>

.DESCRIPTION
    <%= description %>
    
.PARAMETER Port
    Port sur lequel le serveur MCP écoute.
    
.PARAMETER LogLevel
    Niveau de journalisation (DEBUG, INFO, WARNING, ERROR).
    
.EXAMPLE
    .\<%= name %>.ps1 -Port 8000
    Démarre le serveur sur le port 8000.
    
.NOTES
    Version: 1.0.0
    Auteur: <%= author || 'MCP Team' %>
    Date de création: <%= new Date().toISOString().split('T')[0] %>
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$false)]
    [int]$Port = 8000,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR")]
    [string]$LogLevel = "INFO"
)

# Reste du code...

```plaintext
### Création de nouveaux templates

Pour créer un nouveau générateur :

```bash
npx hygen generator new mon-generateur
```plaintext
Cela créera un nouveau dossier `mcp/_templates/mon-generateur` avec les fichiers nécessaires.

## Intégration dans le workflow

### Intégration avec Git

Si vous avez exécuté le script d'intégration du workflow, un hook Git post-commit a été créé pour vérifier si des fichiers générés par Hygen ont été modifiés.

### Intégration avec VS Code

Si vous avez exécuté le script d'intégration du workflow, des tâches VS Code ont été créées pour faciliter l'utilisation de Hygen.

### Intégration avec PowerShell

Si vous avez exécuté le script d'intégration du workflow, des alias PowerShell ont été créés pour faciliter l'utilisation de Hygen.

## Résolution des problèmes

### Hygen n'est pas installé

Si Hygen n'est pas installé, exécutez :

```powershell
npm install --save-dev hygen
```plaintext
### Structure de dossiers incomplète

Si la structure de dossiers est incomplète, exécutez :

```powershell
.\mcp\scripts\setup\ensure-hygen-environment.ps1
```plaintext
### Erreurs lors de la génération de composants

Si vous rencontrez des erreurs lors de la génération de composants, vérifiez :

- Que Hygen est correctement installé
- Que les templates sont présents dans le dossier `mcp/_templates`
- Que les dossiers de destination existent

### Erreurs lors de l'intégration

Si vous rencontrez des erreurs lors de l'intégration, vérifiez :

- Que le script d'intégration a été exécuté
- Que les fichiers de configuration sont présents
- Que les outils d'intégration sont installés

## Procédures spécifiques

### Procédure 1 : Génération d'un script serveur

1. Ouvrez une invite de commande PowerShell
2. Exécutez la commande suivante :
   ```powershell
   .\mcp\scripts\utils\Generate-MCPComponent.ps1 -Type server -Name "mon-serveur" -Description "Mon serveur MCP" -Author "Votre nom"
   ```
3. Vérifiez que le fichier a été créé dans `mcp/core/server/mon-serveur.ps1`
4. Ouvrez le fichier et examinez son contenu
5. Modifiez le fichier selon vos besoins

### Procédure 2 : Génération d'un script client

1. Ouvrez une invite de commande PowerShell
2. Exécutez la commande suivante :
   ```powershell
   .\mcp\scripts\utils\Generate-MCPComponent.ps1 -Type client -Name "mon-client" -Description "Mon client MCP" -Author "Votre nom"
   ```
3. Vérifiez que le fichier a été créé dans `mcp/core/client/mon-client.ps1`
4. Ouvrez le fichier et examinez son contenu
5. Modifiez le fichier selon vos besoins

### Procédure 3 : Génération d'un module

1. Ouvrez une invite de commande PowerShell
2. Exécutez la commande suivante :
   ```powershell
   .\mcp\scripts\utils\Generate-MCPComponent.ps1 -Type module -Name "MonModule" -Description "Mon module MCP" -Author "Votre nom"
   ```
3. Vérifiez que le fichier a été créé dans `mcp/modules/MonModule.psm1`
4. Ouvrez le fichier et examinez son contenu
5. Modifiez le fichier selon vos besoins

### Procédure 4 : Génération d'une documentation

1. Ouvrez une invite de commande PowerShell
2. Exécutez la commande suivante :
   ```powershell
   .\mcp\scripts\utils\Generate-MCPComponent.ps1 -Type doc -Name "mon-guide" -Category "guides" -Description "Mon guide MCP" -Author "Votre nom"
   ```
3. Vérifiez que le fichier a été créé dans `mcp/docs/guides/mon-guide.md`
4. Ouvrez le fichier et examinez son contenu
5. Modifiez le fichier selon vos besoins

### Procédure 5 : Personnalisation d'un template

1. Ouvrez le fichier `mcp/_templates/mcp-server/new/hello.ejs.t` dans votre éditeur de texte
2. Modifiez le contenu selon vos besoins
3. Enregistrez le fichier
4. Testez le template en générant un nouveau composant

### Procédure 6 : Création d'un nouveau générateur

1. Ouvrez une invite de commande PowerShell
2. Exécutez la commande suivante :
   ```bash
   npx hygen generator new mon-generateur
   ```
3. Vérifiez que le dossier `mcp/_templates/mon-generateur` a été créé
4. Ouvrez le fichier `mcp/_templates/mon-generateur/new/hello.ejs.t` dans votre éditeur de texte
5. Modifiez le contenu selon vos besoins
6. Enregistrez le fichier
7. Testez le générateur en exécutant la commande suivante :
   ```bash
   npx hygen mon-generateur new
   ```

## Références

- [Documentation officielle de Hygen](https://www.hygen.io/)
- [GitHub de Hygen](https://github.com/jondot/hygen)
- [Guide d'utilisation de Hygen pour MCP](hygen-guide.md)
- [Guide de formation Hygen pour MCP](hygen-training-guide.md)
- [Analyse de la structure MCP](hygen-analysis.md)
- [Plan des templates](hygen-templates-plan.md)
- [Plan d'intégration](hygen-integration-plan.md)
