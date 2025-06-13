# Guide de formation Hygen pour MCP

Ce guide de formation est destiné aux développeurs qui souhaitent utiliser Hygen pour générer des composants MCP.

## Objectifs de la formation

À la fin de cette formation, vous serez capable de :

1. Comprendre ce qu'est Hygen et pourquoi nous l'utilisons
2. Configurer votre environnement de développement pour Hygen
3. Générer différents types de composants MCP avec Hygen
4. Personnaliser les templates Hygen pour vos besoins spécifiques
5. Intégrer Hygen dans votre workflow de développement

## Prérequis

- Connaissance de base de PowerShell
- Connaissance de base de Node.js et npm
- Accès au dépôt Git du projet MCP

## 1. Introduction à Hygen

### Qu'est-ce que Hygen ?

Hygen est un générateur de code simple, rapide et évolutif qui vit dans votre projet. Il permet de créer des templates pour générer du code de manière cohérente et standardisée.

### Pourquoi utiliser Hygen ?

- **Standardisation** : Assure une structure cohérente pour tous les composants MCP
- **Accélération** : Réduit le temps nécessaire pour créer de nouveaux composants
- **Documentation** : Améliore la documentation des composants
- **Intégration** : Facilite l'intégration des nouveaux composants dans le système existant

## 2. Installation et configuration

### Installation de Hygen

Hygen est déjà installé dans le projet MCP. Si vous avez besoin de le réinstaller, vous pouvez utiliser le script d'installation :

```batch
.\mcp\cmd\utils\setup-hygen-environment.cmd
```plaintext
Ce script vérifie et configure l'environnement de développement pour Hygen.

### Vérification de l'installation

Pour vérifier que Hygen est correctement installé, exécutez :

```powershell
npx hygen --version
```plaintext
Vous devriez voir la version de Hygen s'afficher.

## 3. Génération de composants MCP

### Types de composants

Hygen peut générer les types de composants MCP suivants :

- **Scripts serveur** : Scripts PowerShell pour les serveurs MCP
- **Scripts client** : Scripts PowerShell pour les clients MCP
- **Modules** : Modules PowerShell réutilisables
- **Documentation** : Documentation Markdown

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

## 4. Personnalisation des templates

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
### Modification des templates

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

## 5. Intégration dans le workflow de développement

### Intégration avec Git

Si vous avez exécuté le script d'intégration du workflow, un hook Git post-commit a été créé pour vérifier si des fichiers générés par Hygen ont été modifiés.

### Intégration avec VS Code

Si vous avez exécuté le script d'intégration du workflow, des tâches VS Code ont été créées pour faciliter l'utilisation de Hygen.

### Intégration avec PowerShell

Si vous avez exécuté le script d'intégration du workflow, des alias PowerShell ont été créés pour faciliter l'utilisation de Hygen.

## 6. Bonnes pratiques

1. Utilisez toujours les générateurs pour créer de nouveaux composants afin de maintenir une structure cohérente.
2. Respectez les conventions de nommage définies dans les templates.
3. Mettez à jour les templates si nécessaire pour refléter les évolutions des standards du projet.
4. Documentez les nouveaux générateurs que vous créez.
5. Exécutez régulièrement les tests pour vérifier que tout fonctionne correctement.
6. Utilisez les scripts d'utilitaires pour faciliter l'utilisation de Hygen.

## 7. Exercices pratiques

### Exercice 1 : Générer un script serveur

1. Ouvrez une invite de commande PowerShell
2. Exécutez la commande suivante :
   ```powershell
   .\mcp\scripts\utils\Generate-MCPComponent.ps1 -Type server -Name "exercice-server" -Description "Serveur d'exercice MCP" -Author "Votre nom"
   ```
3. Vérifiez que le fichier a été créé dans `mcp/core/server/exercice-server.ps1`
4. Ouvrez le fichier et examinez son contenu

### Exercice 2 : Générer un script client

1. Ouvrez une invite de commande PowerShell
2. Exécutez la commande suivante :
   ```powershell
   .\mcp\scripts\utils\Generate-MCPComponent.ps1 -Type client -Name "exercice-client" -Description "Client d'exercice MCP" -Author "Votre nom"
   ```
3. Vérifiez que le fichier a été créé dans `mcp/core/client/exercice-client.ps1`
4. Ouvrez le fichier et examinez son contenu

### Exercice 3 : Générer un module

1. Ouvrez une invite de commande PowerShell
2. Exécutez la commande suivante :
   ```powershell
   .\mcp\scripts\utils\Generate-MCPComponent.ps1 -Type module -Name "ExerciceModule" -Description "Module d'exercice MCP" -Author "Votre nom"
   ```
3. Vérifiez que le fichier a été créé dans `mcp/modules/ExerciceModule.psm1`
4. Ouvrez le fichier et examinez son contenu

### Exercice 4 : Générer une documentation

1. Ouvrez une invite de commande PowerShell
2. Exécutez la commande suivante :
   ```powershell
   .\mcp\scripts\utils\Generate-MCPComponent.ps1 -Type doc -Name "exercice-guide" -Category "guides" -Description "Guide d'exercice MCP" -Author "Votre nom"
   ```
3. Vérifiez que le fichier a été créé dans `mcp/docs/guides/exercice-guide.md`
4. Ouvrez le fichier et examinez son contenu

## 8. Ressources supplémentaires

- [Documentation officielle de Hygen](https://www.hygen.io/)
- [GitHub de Hygen](https://github.com/jondot/hygen)
- [Guide d'utilisation de Hygen pour MCP](hygen-guide.md)
- [Analyse de la structure MCP](hygen-analysis.md)
- [Plan des templates](hygen-templates-plan.md)
- [Plan d'intégration](hygen-integration-plan.md)

## 9. Support

Si vous rencontrez des problèmes avec Hygen, vous pouvez contacter l'équipe MCP ou consulter les ressources suivantes :

- [Guide de résolution des problèmes](hygen-guide.md#résolution-des-problèmes)

- [Forum de discussion MCP](https://example.com/mcp-forum)
- [Canal Slack MCP](https://example.com/mcp-slack)
