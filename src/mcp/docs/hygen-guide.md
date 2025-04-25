# Guide d'utilisation de Hygen pour MCP

Ce guide explique comment utiliser Hygen pour générer des composants standardisés pour le projet MCP.

## Qu'est-ce que Hygen ?

Hygen est un générateur de code simple, rapide et évolutif qui vit dans votre projet. Il permet de créer des templates pour générer du code de manière cohérente et standardisée.

## Installation

### Prérequis

- Node.js et npm installés
- Projet MCP initialisé

### Installation automatique

La méthode la plus simple pour installer Hygen est d'utiliser le script d'installation :

```batch
.\mcp\cmd\utils\install-hygen.cmd
```

Ce script installera Hygen et créera la structure de dossiers nécessaire.

### Installation manuelle

Si vous préférez installer Hygen manuellement, suivez ces étapes :

1. Installez Hygen en tant que dépendance de développement :

```bash
npm install --save-dev hygen
```

2. Créez la structure de dossiers nécessaire :

```powershell
.\mcp\scripts\setup\ensure-hygen-structure.ps1
```

### Vérification de l'installation

Pour vérifier que Hygen est correctement installé, exécutez :

```powershell
.\mcp\scripts\setup\verify-hygen-installation.ps1
```

## Utilisation

### Génération de composants

#### Utilisation du script de commande

La méthode la plus simple pour générer des composants est d'utiliser le script de commande :

```batch
.\mcp\cmd\utils\generate-component.cmd
```

Ce script vous présentera un menu avec les options suivantes :

1. Générer un script serveur MCP
2. Générer un script client MCP
3. Générer un module MCP
4. Générer une documentation MCP
Q. Quitter

#### Utilisation du script PowerShell

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
```

### Exemples

#### Création d'un script serveur MCP

```bash
npx hygen mcp-server new
# Nom: api-server
# Description: Serveur API MCP
# Auteur: John Doe
```

Ou avec le script PowerShell :

```powershell
.\mcp\scripts\utils\Generate-MCPComponent.ps1 -Type server -Name "api-server" -Description "Serveur API MCP" -Author "John Doe"
```

#### Création d'un script client MCP

```bash
npx hygen mcp-client new
# Nom: admin-client
# Description: Client d'administration MCP
# Auteur: Jane Smith
```

Ou avec le script PowerShell :

```powershell
.\mcp\scripts\utils\Generate-MCPComponent.ps1 -Type client -Name "admin-client" -Description "Client d'administration MCP" -Author "Jane Smith"
```

#### Création d'un module MCP

```bash
npx hygen mcp-module new
# Nom: MCPUtils
# Description: Utilitaires MCP
# Auteur: Dev Team
```

Ou avec le script PowerShell :

```powershell
.\mcp\scripts\utils\Generate-MCPComponent.ps1 -Type module -Name "MCPUtils" -Description "Utilitaires MCP" -Author "Dev Team"
```

#### Création d'une documentation MCP

```bash
npx hygen mcp-doc new
# Nom: installation-guide
# Description: Guide d'installation MCP
# Catégorie: guides
# Auteur: Doc Team
```

Ou avec le script PowerShell :

```powershell
.\mcp\scripts\utils\Generate-MCPComponent.ps1 -Type doc -Name "installation-guide" -Category "guides" -Description "Guide d'installation MCP" -Author "Doc Team"
```

## Structure des templates

Les templates sont stockés dans le dossier `mcp/_templates`. Chaque générateur a son propre dossier avec des templates spécifiques.

```
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
```

Les composants générés sont placés dans les dossiers suivants :

```
mcp/
  ├── core/
  │   ├── client/       # Scripts client
  │   └── server/       # Scripts serveur
  ├── docs/             # Documentation
  │   ├── architecture/
  │   ├── api/
  │   └── guides/
  └── modules/          # Modules PowerShell
```

## Personnalisation des templates

Si vous souhaitez personnaliser les templates existants ou en créer de nouveaux, vous pouvez modifier les fichiers dans le dossier `mcp/_templates`.

Pour créer un nouveau générateur :

```bash
npx hygen generator new mon-generateur
```

## Bonnes pratiques

1. Utilisez toujours les générateurs pour créer de nouveaux composants afin de maintenir une structure cohérente.
2. Respectez les conventions de nommage définies dans les templates.
3. Mettez à jour les templates si nécessaire pour refléter les évolutions des standards du projet.
4. Documentez les nouveaux générateurs que vous créez.
5. Exécutez régulièrement les tests pour vérifier que tout fonctionne correctement.
6. Utilisez les scripts d'utilitaires pour faciliter l'utilisation de Hygen.

## Résolution des problèmes

### Hygen n'est pas installé

Si Hygen n'est pas installé, exécutez :

```powershell
npm install --save-dev hygen
```

### Structure de dossiers incomplète

Si la structure de dossiers est incomplète, exécutez :

```powershell
.\mcp\scripts\setup\ensure-hygen-structure.ps1
```

### Erreurs lors de la génération de composants

Si vous rencontrez des erreurs lors de la génération de composants, vérifiez :

- Que Hygen est correctement installé
- Que les templates sont présents dans le dossier `mcp/_templates`
- Que les dossiers de destination existent

## Références

- [Documentation officielle de Hygen](https://www.hygen.io/)
- [GitHub de Hygen](https://github.com/jondot/hygen)
- [Analyse de la structure MCP](hygen-analysis.md)
- [Plan des templates](hygen-templates-plan.md)
- [Plan d'intégration](hygen-integration-plan.md)
