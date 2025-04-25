# Formation Hygen pour MCP

## Introduction

- **Qu'est-ce que Hygen ?**
  - Générateur de code simple, rapide et évolutif
  - Vit dans votre projet
  - Utilise des templates pour générer du code

- **Pourquoi utiliser Hygen ?**
  - Standardisation du code
  - Accélération du développement
  - Amélioration de la documentation
  - Facilitation de l'intégration

## Installation et configuration

- **Installation automatique**
  ```batch
  .\mcp\cmd\utils\setup-hygen-environment.cmd
  ```

- **Vérification de l'installation**
  ```powershell
  npx hygen --version
  ```

## Types de composants MCP

- **Scripts serveur**
  - Scripts PowerShell pour les serveurs MCP
  - Générés dans `mcp/core/server/`

- **Scripts client**
  - Scripts PowerShell pour les clients MCP
  - Générés dans `mcp/core/client/`

- **Modules**
  - Modules PowerShell réutilisables
  - Générés dans `mcp/modules/`

- **Documentation**
  - Documentation Markdown
  - Générée dans `mcp/docs/`

## Génération de composants

- **Utilisation du script de commande**
  ```batch
  .\mcp\cmd\utils\generate-component.cmd
  ```

- **Utilisation du script PowerShell**
  ```powershell
  .\mcp\scripts\utils\Generate-MCPComponent.ps1 -Type server -Name "api-server" -Description "Serveur API MCP" -Author "John Doe"
  ```

- **Utilisation des alias PowerShell**
  ```powershell
  gmcps -Name "api-server" -Description "Serveur API MCP" -Author "John Doe"
  ```

- **Utilisation des tâches VS Code**
  - Ctrl+Shift+P
  - "Tasks: Run Task"
  - "Hygen: Generate MCP Server"

## Structure des templates

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

## Personnalisation des templates

- **Modification des templates existants**
  - Ouvrir le fichier `hello.ejs.t`
  - Modifier le contenu selon les besoins

- **Création de nouveaux templates**
  ```bash
  npx hygen generator new mon-generateur
  ```

## Intégration dans le workflow

- **Intégration avec Git**
  - Hook post-commit pour vérifier les fichiers générés

- **Intégration avec VS Code**
  - Tâches pour générer des composants

- **Intégration avec PowerShell**
  - Alias pour générer des composants

## Bonnes pratiques

1. Utiliser les générateurs pour tous les nouveaux composants
2. Respecter les conventions de nommage
3. Mettre à jour les templates si nécessaire
4. Documenter les nouveaux générateurs
5. Exécuter régulièrement les tests
6. Utiliser les scripts d'utilitaires

## Démonstration

- **Génération d'un script serveur**
  ```powershell
  .\mcp\scripts\utils\Generate-MCPComponent.ps1 -Type server -Name "demo-server" -Description "Serveur de démonstration MCP" -Author "Formateur"
  ```

- **Génération d'un script client**
  ```powershell
  .\mcp\scripts\utils\Generate-MCPComponent.ps1 -Type client -Name "demo-client" -Description "Client de démonstration MCP" -Author "Formateur"
  ```

- **Génération d'un module**
  ```powershell
  .\mcp\scripts\utils\Generate-MCPComponent.ps1 -Type module -Name "DemoModule" -Description "Module de démonstration MCP" -Author "Formateur"
  ```

- **Génération d'une documentation**
  ```powershell
  .\mcp\scripts\utils\Generate-MCPComponent.ps1 -Type doc -Name "demo-guide" -Category "guides" -Description "Guide de démonstration MCP" -Author "Formateur"
  ```

## Exercices pratiques

- **Exercice 1 : Générer un script serveur**
- **Exercice 2 : Générer un script client**
- **Exercice 3 : Générer un module**
- **Exercice 4 : Générer une documentation**

## Questions et réponses

- Temps pour les questions et réponses
- Discussion sur les cas d'utilisation spécifiques
- Feedback sur les templates existants

## Ressources supplémentaires

- [Documentation officielle de Hygen](https://www.hygen.io/)
- [Guide d'utilisation de Hygen pour MCP](hygen-guide.md)
- [Guide de formation Hygen pour MCP](hygen-training-guide.md)
- [Analyse de la structure MCP](hygen-analysis.md)
- [Plan des templates](hygen-templates-plan.md)
- [Plan d'intégration](hygen-integration-plan.md)
