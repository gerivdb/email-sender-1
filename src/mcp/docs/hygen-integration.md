# Intégration de Hygen dans la documentation globale MCP

Ce document explique comment Hygen s'intègre dans la documentation globale MCP.

## Introduction

Hygen est un générateur de code simple, rapide et évolutif qui vit dans votre projet. Il permet de créer des templates pour générer du code de manière cohérente et standardisée. Hygen a été intégré dans le projet MCP pour faciliter la création de composants standardisés.

## Documentation Hygen

La documentation Hygen est organisée de la manière suivante :

1. **[Guide d'utilisation](hygen-guide.md)** : Guide d'utilisation de Hygen pour MCP
2. **[Guide de formation](hygen-training-guide.md)** : Guide de formation pour les développeurs
3. **[Procédures d'utilisation](hygen-procedures.md)** : Procédures d'utilisation de Hygen
4. **[Rapport des bénéfices](hygen-benefits-report.md)** : Rapport sur les bénéfices de Hygen
5. **[Rapport des retours utilisateurs](hygen-user-feedback-report.md)** : Rapport sur les retours des utilisateurs
6. **[Analyse de la structure](hygen-analysis.md)** : Analyse de la structure MCP
7. **[Plan des templates](hygen-templates-plan.md)** : Plan des templates à développer
8. **[Plan d'intégration](hygen-integration-plan.md)** : Plan d'intégration de Hygen

## Intégration dans la documentation MCP

La documentation Hygen s'intègre dans la documentation MCP de la manière suivante :

### 1. Documentation des composants

Les composants générés par Hygen incluent une documentation intégrée qui respecte les standards de documentation MCP. Cette documentation est générée automatiquement à partir des templates Hygen et inclut les éléments suivants :

- Synopsis
- Description
- Paramètres
- Exemples
- Notes

### 2. Documentation des scripts

Les scripts générés par Hygen incluent une documentation intégrée qui respecte les standards de documentation MCP. Cette documentation est générée automatiquement à partir des templates Hygen et inclut les éléments suivants :

- Synopsis
- Description
- Paramètres
- Exemples
- Notes

### 3. Documentation des modules

Les modules générés par Hygen incluent une documentation intégrée qui respecte les standards de documentation MCP. Cette documentation est générée automatiquement à partir des templates Hygen et inclut les éléments suivants :

- Synopsis
- Description
- Fonctions exportées
- Exemples
- Notes

### 4. Documentation externe

La documentation externe générée par Hygen respecte les standards de documentation MCP. Cette documentation est générée automatiquement à partir des templates Hygen et inclut les éléments suivants :

- Introduction
- Installation
- Configuration
- Utilisation
- API
- Exemples
- Références

## Structure de la documentation

La documentation Hygen est structurée de la manière suivante :

```
mcp/docs/
  ├── hygen-guide.md                 # Guide d'utilisation
  ├── hygen-training-guide.md        # Guide de formation
  ├── hygen-procedures.md            # Procédures d'utilisation
  ├── hygen-benefits-report.md       # Rapport des bénéfices
  ├── hygen-user-feedback-report.md  # Rapport des retours utilisateurs
  ├── hygen-analysis.md              # Analyse de la structure
  ├── hygen-templates-plan.md        # Plan des templates
  ├── hygen-integration-plan.md      # Plan d'intégration
  ├── hygen-integration.md           # Intégration dans la documentation globale
  ├── api/
  │   └── MCPApiUtils.md             # Documentation de l'API MCPApiUtils
  ├── guides/
  │   └── api-gateway-guide.md       # Guide d'utilisation du serveur de passerelle API
  └── architecture/
      └── hygen-architecture.md      # Architecture de Hygen
```

## Navigation dans la documentation

La documentation Hygen est accessible depuis la documentation MCP de la manière suivante :

1. **Page d'accueil** : La page d'accueil de la documentation MCP inclut un lien vers la documentation Hygen
2. **Menu de navigation** : Le menu de navigation de la documentation MCP inclut une section "Hygen" avec des liens vers les différentes parties de la documentation Hygen
3. **Recherche** : La recherche dans la documentation MCP inclut les résultats de la documentation Hygen

## Maintenance de la documentation

La documentation Hygen est maintenue de la manière suivante :

1. **Mise à jour automatique** : La documentation intégrée est mise à jour automatiquement lorsque les templates Hygen sont modifiés
2. **Mise à jour manuelle** : La documentation externe est mise à jour manuellement lorsque les fonctionnalités Hygen sont modifiées
3. **Revue de la documentation** : La documentation Hygen est revue régulièrement pour s'assurer qu'elle est à jour et complète

## Références

- [Documentation MCP](README.md)
- [Documentation officielle de Hygen](https://www.hygen.io/)
- [GitHub de Hygen](https://github.com/jondot/hygen)

## Annexes

### A. Glossaire

- **Hygen** : Générateur de code simple, rapide et évolutif
- **Template** : Modèle utilisé pour générer du code
- **Générateur** : Ensemble de templates pour un type de composant
- **EJS** : Embedded JavaScript, langage de template utilisé par Hygen

### B. Index des templates

| Template               | Description                                  | Chemin                                      |
|------------------------|----------------------------------------------|---------------------------------------------|
| mcp-server             | Template pour les scripts serveur MCP        | `mcp/_templates/mcp-server/new/hello.ejs.t` |
| mcp-client             | Template pour les scripts client MCP         | `mcp/_templates/mcp-client/new/hello.ejs.t` |
| mcp-module             | Template pour les modules MCP                | `mcp/_templates/mcp-module/new/hello.ejs.t` |
| mcp-doc                | Template pour la documentation MCP           | `mcp/_templates/mcp-doc/new/hello.ejs.t`    |

### C. Index des scripts

| Script                           | Description                                  | Chemin                                      |
|----------------------------------|----------------------------------------------|---------------------------------------------|
| Generate-MCPComponent.ps1        | Script principal de génération               | `mcp/scripts/utils/Generate-MCPComponent.ps1` |
| generate-component.cmd           | Script de commande                           | `mcp/cmd/utils/generate-component.cmd`      |
| ensure-hygen-environment.ps1     | Script de configuration de l'environnement   | `mcp/scripts/setup/ensure-hygen-environment.ps1` |
| Integrate-HygenWorkflow.ps1      | Script d'intégration du workflow             | `mcp/scripts/utils/Integrate-HygenWorkflow.ps1` |
