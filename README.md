# Projet Email Sender pour n8n

Ce projet contient des workflows n8n et des outils pour automatiser l'envoi d'emails et la gestion des processus de booking pour le groupe Gribitch. Il inclut également un système complet d'intégration continue et de déploiement continu (CI/CD) avec notifications par email.

## Structure du projet

```
├── workflows/            # Workflows n8n finaux
│   ├── core/             # Workflows principaux
│   ├── config/           # Workflows de configuration
│   ├── phases/           # Workflows par phase
│   └── testing/          # Workflows de test
├── credentials/          # Informations d'identification
├── config/               # Fichiers de configuration
├── mcp/                  # Configurations MCP
├── src/                  # Code source principal
│   ├── workflows/        # Workflows n8n (développement)
│   └── mcp/              # Fichiers MCP (Model Context Protocol)
│       ├── batch/        # Fichiers batch pour MCP
│       └── config/       # Configurations MCP
├── scripts/              # Scripts utilitaires
│   ├── maintenance/      # Scripts de maintenance
│   │   ├── repo/         # Organisation et vérification du dépôt
│   │   ├── encoding/     # Correction des problèmes d'encodage
│   │   └── cleanup/      # Nettoyage des fichiers et dossiers
│   ├── setup/            # Scripts d'installation
│   │   ├── mcp/          # Configuration des MCP
│   │   └── env/          # Configuration de l'environnement
│   ├── workflow/         # Scripts liés aux workflows n8n
│   │   ├── validation/   # Validation des workflows
│   │   ├── testing/      # Test des workflows
│   │   └── monitoring/   # Surveillance des workflows
│   └── utils/            # Scripts utilitaires
│       ├── markdown/     # Traitement des fichiers Markdown
│       ├── json/         # Traitement des fichiers JSON
│       └── automation/   # Automatisation des tâches
├── logs/                 # Fichiers de logs
│   ├── daily/            # Logs quotidiens
│   ├── weekly/           # Logs hebdomadaires
│   ├── monthly/          # Logs mensuels
│   ├── scripts/          # Logs des scripts
│   └── workflows/        # Logs des workflows
├── docs/                 # Documentation
│   ├── guides/           # Guides d'utilisation
│   └── api/              # Documentation API
├── tests/                # Tests
├── tools/                # Outils divers
└── assets/               # Ressources statiques
```

## Organisation des fichiers finaux

Les fichiers finaux indispensables au projet sont organisés dans les répertoires suivants :

- **workflows/** - Contient tous les fichiers de workflow n8n finaux
  - **core/** - Workflows principaux
    - EMAIL_SENDER_1 (5).json - Workflow principal
  - **config/** - Workflows de configuration
    - EMAIL_SENDER_CONFIG.json - Configuration du workflow
  - **phases/** - Workflows par phase
    - EMAIL_SENDER_PHASE1.json à EMAIL_SENDER_PHASE6.json - Phases du workflow
  - **testing/** - Workflows de test

- **credentials/** - Contient les informations d'identification nécessaires pour les connexions
  - Fichiers de credentials pour les différentes connexions (OpenRouter, Notion, etc.)

- **config/** - Contient les fichiers de configuration
  - n8n-config.txt - Configuration de base de n8n

- **mcp/** - Contient les configurations pour les Model Context Protocol (MCP)
  - mcp-config.json - Configuration de base MCP
  - mcp-config-fixed.json - Configuration MCP corrigée

## MCP disponibles

- **MCP Standard** : Pour interagir avec OpenRouter et les modèles d'IA
- **MCP Notion** : Pour interagir avec vos bases de données Notion
- **MCP Gateway** : Pour interagir avec vos bases de données SQL
- **MCP Git Ingest** : Pour explorer et lire les dépôts GitHub (amélioré avec support Python direct)
- **MCP GDrive** : Pour interagir avec Google Drive

## Installation et configuration

1. **Configuration des MCP Standard, Notion et Gateway** :
   ```powershell
   .\scripts\setup\configure-n8n-mcp.ps1
   ```

2. **Configuration du MCP Git Ingest** :
   ```powershell
   .\scripts\setup\configure-mcp-git-ingest.ps1
   ```

3. **Configuration du MCP GDrive** :
   ```powershell
   .\scripts\setup\configure-gdrive-mcp.ps1
   ```

4. **Configuration de VS Code pour Augment** :
   ```powershell
   .\scripts\setup\update-vscode-settings.ps1
   ```

5. **Configuration de l'organisation automatique** :
   ```powershell
   .\scripts\setup\setup-auto-organization.ps1
   ```

6. **Démarrage de n8n avec vérification des MCP** :
   ```
   .\tools\start-n8n-mcp.cmd
   ```

## Mise à jour et maintenance

- **Mise à jour des MCP** :
  ```powershell
  .\scripts\maintenance\update-mcp.ps1
  ```

- **Organisation des fichiers** :
  ```powershell
  .\scripts\maintenance\create-folders.ps1
  .\scripts\maintenance\move-mcp-files.ps1
  ```

- **Nettoyage des fichiers obsolètes** :
  ```powershell
  .\scripts\maintenance\cleanup-mcp-files.ps1
  ```

## Intégration CI/CD et Déploiement

Le projet dispose d'un système complet d'intégration continue et de déploiement continu (CI/CD) avec notifications par email :

### Notifications par email

Le système envoie automatiquement des notifications par email dans les cas suivants :

- **Succès du pipeline CI/CD** : Notification envoyée lorsque le pipeline réussit
- **Échec du pipeline CI/CD** : Notification envoyée lorsque le pipeline échoue
- **Déploiement réussi** : Notification envoyée lorsqu'un déploiement est effectué avec succès
- **Échec du déploiement** : Notification envoyée lorsqu'un déploiement échoue

### Workflows GitHub Actions

- **Lint** : Vérification du style de code PowerShell et Python
- **Test** : Exécution des tests unitaires
- **Security** : Vérification de sécurité pour détecter les informations sensibles
- **Build** : Construction et déploiement du projet
- **Notify** : Envoi de notifications par email sur le statut du pipeline

### Scripts de déploiement

```powershell
# Déploiement de base (simulation)
.\scripts\ci\deploy.ps1 -Environment Development

# Déploiement réel avec SSH et notifications
.\scripts\ci\deploy-real.ps1 -Environment Production -SendNotification
```

### Tests unitaires

```powershell
# Exécuter les tests PowerShell
Invoke-Pester -Path .\tests\powershell

# Exécuter les tests Python
python -m unittest discover -s tests/python
```

### Vérifications locales

```powershell
# Exécuter toutes les vérifications CI/CD localement
.\scripts\ci\run-ci-checks.ps1

# Tester les hooks Git dans un environnement sans espaces
.\scripts\setup\test-hooks-clean-env.ps1
```

Pour plus d'informations, consultez le [Guide d'intégration CI/CD](docs/guides/GUIDE_INTEGRATION_CI_CD.md).

## Documentation

### Guides d'utilisation

- [Guide final MCP](docs/guides/GUIDE_FINAL_MCP.md) : Guide complet sur les MCP dans n8n
- [Guide MCP Gateway](docs/guides/GUIDE_MCP_GATEWAY.md) : Guide spécifique pour le MCP Gateway
- [Guide MCP Git Ingest](docs/guides/GUIDE_MCP_GIT_INGEST.md) : Guide spécifique pour le MCP Git Ingest
- [Guide des nouvelles fonctionnalités](docs/guides/GUIDE_NOUVELLES_FONCTIONNALITES.md) : Présentation des nouvelles fonctionnalités et de l'organisation du dépôt
- [Guide d'organisation automatique](docs/guides/GUIDE_ORGANISATION_AUTOMATIQUE.md) : Guide pour l'organisation automatique du dépôt
- [Guide de gestion des caractères accentués](docs/guides/GUIDE_GESTION_CARACTERES_ACCENTES.md) : Guide pour résoudre les problèmes d'encodage des caractères accentués français dans n8n
- [Guide d'intégration CI/CD](docs/guides/GUIDE_INTEGRATION_CI_CD.md) : Guide pour l'intégration continue et le déploiement continu

### Documentation de l'API n8n

- [Documentation de l'API n8n](docs/api/N8N_API_DOCUMENTATION.md) : Documentation complète de l'API n8n avec les endpoints testés et leur statut
- [Exemples d'utilisation de l'API n8n](docs/api/N8N_API_EXAMPLES.md) : Exemples concrets d'utilisation des endpoints fonctionnels

### Journal de bord

- [Journal de bord](JOURNAL_DE_BORD.md) : Journal documentant la progression, les problèmes rencontrés et les solutions mises en œuvre

## Organisation automatique des fichiers

Le projet dispose de scripts d'automatisation pour maintenir une structure de répertoire claire et organisée :

### Nouvelle organisation automatique

Un système complet d'organisation automatique des fichiers a été mis en place pour maintenir le dépôt propre et conforme aux standards GitHub :

- **Surveillance en temps réel** : Détecte et organise automatiquement les nouveaux fichiers dès leur création
- **Tâche planifiée quotidienne** : Nettoie et organise le dépôt chaque jour
- **Hook Git pre-commit** : Organise les fichiers avant chaque commit

Pour configurer toutes ces méthodes d'organisation automatique, exécutez :

```powershell
.\scripts\maintenance\setup-all-auto-organize.ps1
```

Pour démarrer manuellement la surveillance en temps réel :

```powershell
.\start-file-watcher.cmd
```

### Scripts d'organisation disponibles

- **scripts/maintenance/auto-organize.ps1** - Organisation interactive des fichiers
- **scripts/maintenance/auto-organize-silent.ps1** - Organisation silencieuse (pour les tâches planifiées)
- **scripts/maintenance/watch-and-organize.ps1** - Surveillance en temps réel des nouveaux fichiers
- **scripts/maintenance/clean-root.ps1** - Nettoyage interactif des fichiers à la racine
- **scripts/maintenance/organize-repo.ps1** - Réorganisation complète du dépôt

### Principes d'organisation

- **Organisation automatique** : Les fichiers sont automatiquement placés dans les dossiers appropriés
- **Règles de classement** : Basées sur les extensions et les préfixes des fichiers
- **Fichiers essentiels préservés** : Les fichiers comme README.md et .gitignore restent à la racine
- **Journalisation** : Toutes les actions d'organisation sont enregistrées dans des fichiers de log

## Utilisation des MCP

Pour utiliser les MCP, vous pouvez exécuter directement les fichiers batch dans le dossier `src/mcp/batch` :

```powershell
.\src\mcp\batch\mcp-standard.cmd
.\src\mcp\batch\mcp-notion.cmd
.\src\mcp\batch\gateway.exe.cmd
.\src\mcp\batch\mcp-git-ingest.cmd
```

## Workflows de test

Des workflows de test sont disponibles dans le dossier `workflows/testing` :
- `test-mcp-workflow-updated.json` : Workflow de test pour les MCP Standard, Notion et Gateway
- `test-mcp-git-ingest-workflow.json` : Workflow de test pour le MCP Git Ingest

## Dépannage

Si vous rencontrez des problèmes avec les MCP, consultez la section "Maintenance et dépannage" du [Guide final MCP](docs/guides/GUIDE_FINAL_MCP.md).
