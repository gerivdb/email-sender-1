# Guide d'organisation automatique des fichiers

Ce guide explique comment fonctionne l'organisation automatique des fichiers dans le projet Email Sender.

## Principes d'organisation

L'organisation des fichiers suit plusieurs principes :

1. **Organisation par nature** : Les fichiers sont organisés selon leur nature (configuration, script, documentation, etc.)
2. **Organisation par type** : Les fichiers sont organisés selon leur type (JSON, CMD, PS1, etc.)
3. **Organisation par usage** : Les fichiers sont organisés selon leur usage (MCP, Augment, n8n, etc.)
4. **Organisation par temporalité** : Les logs sont organisés par unité de temps (quotidien, hebdomadaire, mensuel)

## Structure des dossiers

La structure des dossiers suit les conventions GitHub tout en organisant les fichiers de manière logique :

```
├── .github/               # Configuration GitHub
├── config/                # Fichiers de configuration
│   ├── app/               # Configuration de l'application
│   ├── env/               # Variables d'environnement
│   ├── n8n/               # Configuration n8n
│   └── vscode/            # Configuration VS Code
├── docs/                  # Documentation
│   ├── api/               # Documentation API
│   ├── guides/            # Guides d'utilisation
│   ├── mcp/               # Documentation MCP
│   ├── n8n/               # Documentation n8n
│   ├── plans/             # Plans et stratégies
│   ├── reference/         # Documents de référence
│   └── workflows/         # Documentation des workflows
├── logs/                  # Fichiers de logs
│   ├── daily/             # Logs quotidiens
│   ├── monthly/           # Logs mensuels
│   ├── scripts/           # Logs des scripts
│   ├── weekly/            # Logs hebdomadaires
│   └── workflows/         # Logs des workflows
├── mcp/                   # Fichiers MCP
│   ├── config/            # Configuration MCP
│   ├── gdrive/            # MCP Google Drive
│   └── servers/           # Serveurs MCP
├── scripts/               # Scripts divers
│   ├── cmd/               # Scripts CMD
│   │   ├── augment/       # Scripts CMD pour Augment
│   │   ├── batch/         # Scripts batch
│   │   └── mcp/           # Scripts CMD pour MCP
│   ├── maintenance/       # Scripts de maintenance
│   │   ├── cleanup/       # Scripts de nettoyage
│   │   ├── encoding/      # Scripts de correction d'encodage
│   │   ├── mcp/           # Scripts de maintenance MCP
│   │   └── repo/          # Scripts d'organisation du dépôt
│   ├── setup/             # Scripts d'installation
│   │   ├── env/           # Scripts de configuration de l'environnement
│   │   └── mcp/           # Scripts de configuration MCP
│   ├── utils/             # Scripts utilitaires
│   │   ├── automation/    # Scripts d'automatisation
│   │   ├── json/          # Scripts de traitement JSON
│   │   └── markdown/      # Scripts de traitement Markdown
│   └── workflow/          # Scripts liés aux workflows
│       ├── monitoring/    # Scripts de surveillance
│       ├── testing/       # Scripts de test
│       └── validation/    # Scripts de validation
├── src/                   # Code source
├── tests/                 # Tests
├── tools/                 # Outils divers
└── workflows/             # Workflows n8n
    ├── core/              # Workflows principaux
    ├── config/            # Workflows de configuration
    ├── phases/            # Workflows par phase
    └── testing/           # Workflows de test
```

## Mécanismes d'automatisation

Plusieurs mécanismes sont mis en place pour automatiser l'organisation des fichiers :

### 1. Scripts d'organisation

- **organize-repo-structure.ps1** : Organise la structure globale du dépôt
- **auto-organize-folders.ps1** : Organise les dossiers contenant trop de fichiers
- **organize-docs-fixed.ps1** : Organise les documents
- **manage-logs.ps1** : Gère les logs par unité de temps

### 2. Surveillance en temps réel

Le script **auto-organize-watcher.ps1** surveille en temps réel la création de nouveaux fichiers et les organise automatiquement selon les règles définies.

### 3. Hooks Git

Le hook pre-commit exécute automatiquement le script d'organisation avant chaque commit, garantissant que les fichiers sont toujours correctement organisés dans le dépôt.

### 4. Tâches planifiées

Des tâches planifiées sont configurées pour exécuter régulièrement les scripts d'organisation :

- **OrganizeRepoStructure** : Exécution quotidienne (3h00)
- **OrganizeFolders** : Exécution quotidienne (3h00)
- **OrganizeDocs** : Exécution hebdomadaire (dimanche à 3h00)
- **ManageLogs** : Exécution quotidienne (3h00)
- **AutoOrganizeWatcher** : Service ou tâche au démarrage

## Configuration de l'automatisation

Pour configurer l'automatisation, exécutez le script suivant en tant qu'administrateur :

```powershell
powershell -File .\scripts\setup\setup-auto-organization.ps1
```

Ce script configure les hooks Git, les tâches planifiées et le service de surveillance.

## Règles d'organisation

Les règles d'organisation sont définies dans les scripts et peuvent être personnalisées selon les besoins du projet. Voici quelques exemples de règles :

- Les fichiers `.settings.json` sont placés dans `config\vscode`
- Les fichiers `.cmd` sont placés dans `scripts\cmd\batch`
- Les fichiers `augment-*.cmd` sont placés dans `scripts\cmd\augment`
- Les fichiers `mcp-*.cmd` sont placés dans `scripts\cmd\mcp`
- Les fichiers `.log` sont placés dans `logs\daily`
- Les fichiers `GUIDE_*.md` sont placés dans `docs\guides`

## Ajout de nouvelles règles

Pour ajouter de nouvelles règles d'organisation, modifiez les scripts suivants :

1. **scripts\maintenance\repo\organize-repo-structure.ps1** : Pour les règles globales
2. **scripts\utils\automation\auto-organize-watcher.ps1** : Pour les règles de surveillance en temps réel

## Résolution des problèmes

Si vous rencontrez des problèmes avec l'organisation automatique, vérifiez les points suivants :

1. **Logs** : Consultez les logs dans le dossier `logs` pour identifier les erreurs
2. **Permissions** : Assurez-vous que les scripts ont les permissions nécessaires
3. **Tâches planifiées** : Vérifiez que les tâches planifiées sont correctement configurées
4. **Service de surveillance** : Vérifiez que le service de surveillance est en cours d'exécution

## Conclusion

L'organisation automatique des fichiers garantit que le dépôt reste propre et structuré, facilitant la navigation et la maintenance pour l'équipe de développement. Elle respecte à la fois les conventions GitHub et les principes d'organisation par nature, type, usage et temporalité.
