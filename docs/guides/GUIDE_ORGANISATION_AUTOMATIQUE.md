# Guide d'organisation automatique des fichiers

Ce guide explique comment fonctionne l'organisation automatique des fichiers dans le projet Email Sender.

## Principes d'organisation

L'organisation des fichiers suit plusieurs principes :

1. **Organisation par nature** : Les fichiers sont organisés selon leur nature (configuration, script, documentation, etc.)
2. **Organisation par type** : Les fichiers sont organisés selon leur type (JSON, CMD, PS1, etc.)
3. **Organisation par usage** : Les fichiers sont organisés selon leur usage (MCP, Augment, n8n, etc.)
4. **Organisation par temporalité** : Les logs sont organisés par unité de temps (quotidien, hebdomadaire, mensuel)
5. **Organisation automatique** : Les fichiers sont automatiquement placés dans les dossiers appropriés dès leur création

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

- **auto-organize.ps1** : Organise interactivement les fichiers à la racine
- **auto-organize-silent.ps1** : Version silencieuse pour les tâches planifiées
- **clean-root.ps1** : Nettoie interactivement les fichiers à la racine
- **organize-repo.ps1** : Réorganise complètement la structure du dépôt

### 2. Surveillance en temps réel

Le script **watch-and-organize.ps1** surveille en temps réel la création de nouveaux fichiers et les organise automatiquement selon les règles définies. Il utilise la classe `FileSystemWatcher` de PowerShell pour détecter les nouveaux fichiers dès leur création.

### 3. Hooks Git

Le hook pre-commit exécute automatiquement le script d'organisation avant chaque commit, garantissant que les fichiers sont toujours correctement organisés dans le dépôt. Ce hook est configuré automatiquement par le script `setup-all-auto-organize.ps1`.

### 4. Tâches planifiées

Deux tâches planifiées sont configurées pour assurer l'organisation automatique :

- **N8N_AutoOrganize_Daily** : Exécution quotidienne (9h00) du script `auto-organize-silent.ps1`
- **N8N_AutoWatch_Startup** : Exécution au démarrage de Windows du script `watch-and-organize.ps1`

## Configuration de l'automatisation

Pour configurer toutes les méthodes d'organisation automatique en une seule fois, exécutez le script suivant en tant qu'administrateur :

```powershell
powershell -File .\scripts\maintenance\setup-all-auto-organize.ps1
```

Ce script configure :
1. La tâche planifiée quotidienne (9h00)
2. La surveillance en temps réel au démarrage de Windows
3. Le hook Git pre-commit
4. Un raccourci sur le bureau pour démarrer manuellement la surveillance

Vous pouvez également démarrer manuellement la surveillance en temps réel avec :

```powershell
.\start-file-watcher.cmd
```

## Règles d'organisation

Les règles d'organisation sont définies dans les scripts et peuvent être personnalisées selon les besoins du projet. Voici les principales règles :

| Type de fichier | Pattern | Destination |
|-----------------|---------|-------------|
| Workflows n8n | `*.json`, `*.workflow.json` | `src/workflows` |
| Fichiers batch MCP | `mcp-*.cmd`, `gateway.exe.cmd` | `src/mcp/batch` |
| Fichiers config YAML | `*.yaml` | `src/mcp/config` |
| Fichiers config MCP | `mcp-config*.json` | `src/mcp/config` |
| Scripts PowerShell | `*.ps1` | `scripts` |
| Scripts de configuration | `configure-*.ps1` | `scripts/setup` |
| Scripts d'installation | `setup-*.ps1` | `scripts/setup` |
| Scripts de mise à jour | `update-*.ps1` | `scripts/maintenance` |
| Scripts de nettoyage | `cleanup-*.ps1` | `scripts/maintenance` |
| Scripts de vérification | `check-*.ps1` | `scripts/maintenance` |
| Scripts d'organisation | `organize-*.ps1` | `scripts/maintenance` |
| Guides d'utilisation | `GUIDE_*.md` | `docs/guides` |
| Fichiers de logs | `*.log` | `logs` |
| Fichiers d'environnement | `*.env` | `config` |
| Fichiers de configuration | `*.config` | `config` |
| Scripts de démarrage | `start-*.cmd` | `tools` |
| Scripts Python | `*.py` | `src` |

### Fichiers conservés à la racine

Les fichiers suivants sont toujours conservés à la racine du dépôt :
- `README.md`
- `.gitignore`
- `package.json`
- `package-lock.json`
- `CHANGELOG.md`
- `LICENSE`
- `CONTRIBUTING.md`
- `CODE_OF_CONDUCT.md`
- `JOURNAL_DE_BORD.md`

## Ajout de nouvelles règles

Pour ajouter de nouvelles règles d'organisation, modifiez les scripts suivants :

1. **scripts\maintenance\auto-organize.ps1** : Pour les règles interactives
2. **scripts\maintenance\auto-organize-silent.ps1** : Pour les règles silencieuses
3. **scripts\maintenance\watch-and-organize.ps1** : Pour les règles de surveillance en temps réel

## Résolution des problèmes

Si vous rencontrez des problèmes avec l'organisation automatique, vérifiez les points suivants :

### La surveillance en temps réel ne fonctionne pas

1. Vérifiez que le script `watch-and-organize.ps1` est bien exécuté
2. Vérifiez que vous avez les droits d'administrateur
3. Redémarrez la surveillance manuellement avec `start-file-watcher.cmd`

### Les fichiers ne sont pas déplacés automatiquement

1. Vérifiez que le fichier correspond à l'une des règles d'organisation
2. Vérifiez que le fichier n'est pas dans la liste des fichiers à conserver à la racine
3. Exécutez manuellement `clean-root.ps1` pour voir les messages d'erreur éventuels

### La tâche planifiée ne s'exécute pas

1. Ouvrez le Planificateur de tâches Windows
2. Vérifiez l'état de la tâche `N8N_AutoOrganize_Daily`
3. Consultez l'historique d'exécution pour voir les erreurs éventuelles
4. Recréez la tâche avec `setup-all-auto-organize.ps1`

### Le hook Git pre-commit ne fonctionne pas

1. Vérifiez que le fichier `.git\hooks\pre-commit` existe
2. Vérifiez que le fichier a les droits d'exécution (sous Linux/macOS)
3. Recréez le hook avec `setup-all-auto-organize.ps1`

## Conclusion

L'organisation automatique des fichiers garantit que le dépôt reste propre et structuré, facilitant la navigation et la maintenance pour l'équipe de développement. Grâce à la surveillance en temps réel, aux tâches planifiées et aux hooks Git, les fichiers sont toujours placés dans les dossiers appropriés, même lorsque plusieurs personnes travaillent sur le projet.

Cette automatisation permet de :
- Maintenir une structure cohérente et conforme aux standards GitHub
- Éviter l'accumulation de fichiers à la racine du dépôt
- Faciliter la recherche et la navigation dans le projet
- Assurer que tous les membres de l'équipe suivent les mêmes conventions
