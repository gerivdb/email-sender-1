# Guide des nouvelles fonctionnalités et de l'organisation du dépôt

## Introduction

Ce guide présente les nouvelles fonctionnalités et l'organisation du dépôt qui ont été mises en place pour améliorer l'efficacité et la maintenabilité du projet Email Sender 1.

## Nouvelles fonctionnalités

### 1. MCP Git Ingest amélioré

Le MCP Git Ingest a été amélioré pour utiliser Python directement au lieu de npm, ce qui résout les problèmes de dépendances et améliore la stabilité.

#### Utilisation

Pour utiliser le MCP Git Ingest dans Augment :

1. Assurez-vous que la configuration est présente dans les paramètres VS Code
2. Utilisez des prompts comme :
   ```
   Utilise le MCP Git Ingest pour explorer la structure du dépôt GitHub "adhikasp/mcp-git-ingest".
   ```

Pour tester le serveur HTTP :

1. Exécutez `.\scripts\cmd\start-mcp-git-ingest-server.cmd`
2. Accédez à `http://localhost:8001/health` pour vérifier que le serveur fonctionne

### 2. MCP GDrive

Un nouveau MCP pour interagir avec Google Drive a été ajouté.

#### Utilisation

Pour utiliser le MCP GDrive :

1. Configurez les identifiants OAuth2 pour Google Drive
2. Utilisez le MCP dans n8n ou Augment pour interagir avec vos fichiers Google Drive

### 3. Organisation automatique du dépôt

Des scripts d'automatisation ont été ajoutés pour organiser automatiquement le dépôt selon une structure cohérente.

#### Utilisation

Pour configurer l'organisation automatique :

1. Exécutez `.\scripts\setup\setup-auto-organization.ps1`
2. Les fichiers seront automatiquement organisés selon leur type et leur usage

## Nouvelle organisation du dépôt

Le dépôt a été réorganisé selon la structure suivante :

```
email-sender-1/
├── .github/                  # Configuration GitHub
│   └── hooks/                # Hooks Git pour l'automatisation
├── .n8n/                     # Configuration n8n
├── docs/                     # Documentation
│   └── guides/               # Guides d'utilisation
├── mcp/                      # Serveurs MCP
│   ├── batch/                # Scripts batch pour les MCP
│   └── gdrive/               # MCP Google Drive
├── scripts/                  # Scripts utilitaires
│   ├── cmd/                  # Scripts CMD
│   │   ├── augment/          # Scripts pour Augment
│   │   └── batch/            # Scripts batch généraux
│   ├── maintenance/          # Scripts de maintenance
│   │   └── repo/             # Scripts d'organisation du dépôt
│   ├── python/               # Scripts Python
│   ├── setup/                # Scripts d'installation et de configuration
│   └── utils/                # Utilitaires divers
│       └── automation/       # Scripts d'automatisation
└── src/                      # Code source principal
    └── mcp/                  # Implémentation des MCP
        └── batch/            # Scripts batch pour les MCP
```

## Configuration VS Code

La configuration VS Code a été mise à jour pour inclure le MCP Git Ingest. Pour mettre à jour votre configuration :

1. Exécutez `.\scripts\setup\update-vscode-settings.ps1`
2. Redémarrez VS Code

## Prochaines étapes

1. Tester les nouvelles fonctionnalités dans vos workflows
2. Contribuer à l'amélioration des MCP
3. Suggérer des améliorations pour l'organisation du dépôt

## Ressources supplémentaires

- [Guide MCP Git Ingest](GUIDE_MCP_GIT_INGEST.md)
- [Guide d'organisation automatique](GUIDE_ORGANISATION_AUTOMATIQUE.md)
