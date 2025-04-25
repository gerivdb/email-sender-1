# Guide complet d'utilisation de Hygen pour le projet n8n

Ce guide explique comment utiliser Hygen dans le projet n8n pour générer des composants standardisés.

## Qu'est-ce que Hygen ?

Hygen est un générateur de code simple, rapide et évolutif qui vit dans votre projet. Il permet de créer des templates pour générer du code de manière cohérente et standardisée.

## Installation

### Prérequis

- Node.js et npm installés
- Projet n8n initialisé

### Installation automatique

La méthode la plus simple pour installer Hygen est d'utiliser le script d'installation :

```batch
.\n8n\cmd\utils\install-hygen.cmd
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
.\n8n\scripts\setup\ensure-hygen-structure.ps1
```

### Vérification de l'installation

Pour vérifier que Hygen est correctement installé, exécutez :

```powershell
.\n8n\scripts\setup\verify-hygen-installation.ps1
```

### Finalisation de l'installation

Pour finaliser l'installation, exécutez :

```powershell
.\n8n\scripts\setup\finalize-hygen-installation.ps1
```

## Générateurs disponibles

### 1. Script d'automatisation n8n

Génère un script PowerShell d'automatisation n8n avec une structure standardisée.

```bash
npx hygen n8n-script new
```

Vous serez invité à fournir :
- Le nom du script (sans extension)
- La catégorie du script (deployment, monitoring, diagnostics, etc.)
- Une description du script
- L'auteur du script

### 2. Workflow n8n

Génère un fichier JSON de workflow n8n avec une structure de base.

```bash
npx hygen n8n-workflow new
```

Vous serez invité à fournir :
- Le nom du workflow
- L'environnement du workflow (local, ide, archive)
- Les tags associés au workflow

### 3. Documentation n8n

Génère un fichier Markdown de documentation avec une structure standardisée.

```bash
npx hygen n8n-doc new
```

Vous serez invité à fournir :
- Le nom du document (sans extension)
- La catégorie du document (architecture, workflows, api, etc.)
- Une description du document
- L'auteur du document

### 4. Intégration n8n

Génère un script PowerShell d'intégration avec une structure standardisée.

```bash
npx hygen n8n-integration new
```

Vous serez invité à fournir :
- Le nom du script d'intégration (sans extension)
- Le système avec lequel s'intègre ce script (mcp, ide, api, augment)
- Une description de l'intégration
- L'auteur du script

## Structure des dossiers

Hygen utilise la structure de dossiers suivante :

```
n8n/_templates/
  n8n-script/
    new/
      hello.ejs.t
      prompt.js
  n8n-workflow/
    new/
      hello.ejs.t
      prompt.js
  n8n-doc/
    new/
      hello.ejs.t
      prompt.js
  n8n-integration/
    new/
      hello.ejs.t
      prompt.js
```

Les composants générés sont placés dans les dossiers suivants :

```
n8n/
  automation/
    deployment/
    monitoring/
    diagnostics/
    notification/
    maintenance/
    dashboard/
    tests/
  core/
    workflows/
      local/
      ide/
      archive/
  integrations/
    mcp/
    ide/
    api/
    augment/
  docs/
    architecture/
    workflows/
    api/
    guides/
    installation/
```

## Utilisation

### Génération de composants

#### Utilisation du script de commande

La méthode la plus simple pour générer des composants est d'utiliser le script de commande :

```batch
.\n8n\cmd\utils\generate-component.cmd
```

Ce script vous présentera un menu avec les options suivantes :

1. Générer un script PowerShell
2. Générer un workflow n8n
3. Générer un document
4. Générer une intégration
Q. Quitter

#### Utilisation du script PowerShell

Vous pouvez également utiliser directement le script PowerShell :

```powershell
# Générer un composant en mode interactif
.\n8n\scripts\utils\Generate-N8nComponent.ps1

# Générer un script PowerShell
.\n8n\scripts\utils\Generate-N8nComponent.ps1 -Type script -Name "My-Script" -Category "deployment" -Description "Mon script de déploiement"

# Générer un workflow n8n
.\n8n\scripts\utils\Generate-N8nComponent.ps1 -Type workflow -Name "my-workflow" -Category "local" -Description "Mon workflow"

# Générer un document
.\n8n\scripts\utils\Generate-N8nComponent.ps1 -Type doc -Name "my-doc" -Category "guides" -Description "Mon document"

# Générer une intégration
.\n8n\scripts\utils\Generate-N8nComponent.ps1 -Type integration -Name "My-Integration" -Category "mcp" -Description "Mon intégration"
```

## Structure des templates

Les templates sont stockés dans le dossier `n8n/_templates`. Chaque générateur a son propre dossier avec des templates spécifiques.

## Personnalisation des templates

Si vous souhaitez personnaliser les templates existants ou en créer de nouveaux, vous pouvez modifier les fichiers dans le dossier `n8n/_templates`.

Pour créer un nouveau générateur :

```bash
npx hygen generator new mon-generateur
```

## Validation et tests

### Validation des templates

Pour valider les templates Hygen, exécutez :

```powershell
.\n8n\scripts\setup\validate-hygen-templates.ps1
```

Ou utilisez le script de commande :

```batch
.\n8n\cmd\utils\validate-templates.cmd
```

### Validation des scripts d'utilitaires

Pour valider les scripts d'utilitaires Hygen, exécutez :

```powershell
.\n8n\scripts\setup\validate-hygen-utilities.ps1
```

Ou utilisez le script de commande :

```batch
.\n8n\cmd\utils\validate-utilities.cmd
```

### Exécution de tous les tests

Pour exécuter tous les tests Hygen, exécutez :

```powershell
.\n8n\scripts\setup\run-all-hygen-tests.ps1
```

Ou utilisez le script de commande :

```batch
.\n8n\cmd\utils\run-all-tests.cmd
```

## Bonnes pratiques

1. Utilisez toujours les générateurs pour créer de nouveaux composants afin de maintenir une structure cohérente.
2. Respectez les conventions de nommage définies dans les templates.
3. Mettez à jour les templates si nécessaire pour refléter les évolutions des standards du projet.
4. Documentez les nouveaux générateurs que vous créez.
5. Exécutez régulièrement les tests pour vérifier que tout fonctionne correctement.
6. Utilisez les scripts d'utilitaires pour faciliter l'utilisation de Hygen.

## Exemples d'utilisation

### Création d'un script de déploiement

```bash
npx hygen n8n-script new
# Nom: deploy-n8n
# Catégorie: deployment
# Description: Script de déploiement de n8n
# Auteur: Équipe DevOps
```

### Création d'un workflow d'envoi d'email

```bash
npx hygen n8n-workflow new
# Nom: email-sender
# Environnement: local
# Tags: email, notification
```

### Création d'une documentation d'architecture

```bash
npx hygen n8n-doc new
# Nom: system-architecture
# Catégorie: architecture
# Description: Documentation de l'architecture du système n8n
# Auteur: Équipe Architecture
```

### Création d'un script d'intégration MCP

```bash
npx hygen n8n-integration new
# Nom: sync-workflows
# Système: mcp
# Description: Script de synchronisation des workflows avec MCP
# Auteur: Équipe Intégration
```

## Bénéfices

L'utilisation de Hygen dans ce projet apporte plusieurs bénéfices :

### Standardisation de la structure du code

- Uniformité des scripts PowerShell
- Cohérence des workflows n8n
- Documentation homogène
- Facilité de maintenance

### Accélération du développement

- Automatisation de la création de boilerplate
- Réduction des erreurs
- Accélération de l'intégration des nouveaux développeurs

### Organisation cohérente des fichiers

- Placement automatique des fichiers au bon endroit
- Maintien d'une structure de dossiers cohérente
- Évitement des fichiers éparpillés

### Facilitation de l'intégration avec MCP

- Templates spécifiques pour les intégrations
- Structure adaptée aux besoins d'intégration

### Amélioration de la documentation

- Génération automatique de documents bien structurés
- Documentation systématique de chaque composant
- Standardisation du format de la documentation

### Facilitation de la mise en œuvre de la roadmap

- Création rapide des scripts nécessaires
- Cohérence entre les différents composants
- Facilitation de l'implémentation des nouvelles fonctionnalités

## Résolution des problèmes

### Hygen n'est pas installé

Si Hygen n'est pas installé, exécutez :

```powershell
npm install --save-dev hygen
```

### Structure de dossiers incomplète

Si la structure de dossiers est incomplète, exécutez :

```powershell
.\n8n\scripts\setup\ensure-hygen-structure.ps1
```

### Erreurs lors de la génération de composants

Si vous rencontrez des erreurs lors de la génération de composants, vérifiez :

- Que Hygen est correctement installé
- Que les templates sont présents dans le dossier `n8n/_templates`
- Que les dossiers de destination existent

### Erreurs lors de l'exécution des tests

Si vous rencontrez des erreurs lors de l'exécution des tests, vérifiez :

- Que PowerShell est configuré pour exécuter des scripts
- Que Node.js et npm sont installés et accessibles
- Que Hygen est correctement installé

## Références

- [Documentation officielle de Hygen](https://www.hygen.io/)
- [GitHub de Hygen](https://github.com/jondot/hygen)
- [Guide de finalisation de l'installation](hygen-installation-finalization.md)
- [Guide de validation des templates](hygen-templates-validation.md)
- [Guide de validation des scripts d'utilitaires](hygen-utilities-validation.md)
