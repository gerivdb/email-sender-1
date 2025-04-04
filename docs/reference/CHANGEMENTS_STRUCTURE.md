# Changements de structure du projet

Ce document explique les changements de structure qui ont été apportés au projet Email Sender pour n8n.

## Ancienne structure

Auparavant, tous les fichiers étaient stockés à la racine du projet ou dans quelques dossiers épars, ce qui rendait difficile la navigation et la maintenance.

## Nouvelle structure

Le projet a été réorganisé selon les bonnes pratiques GitHub avec une structure de dossiers claire et logique :

```
├── src/                  # Code source principal
│   ├── workflows/        # Workflows n8n
│   └── mcp/              # Fichiers MCP (Model Context Protocol)
│       ├── batch/        # Fichiers batch pour MCP
│       └── config/       # Configurations MCP
├── scripts/              # Scripts utilitaires
│   ├── setup/            # Scripts d'installation
│   └── maintenance/      # Scripts de maintenance
├── config/               # Fichiers de configuration
├── logs/                 # Fichiers de logs
├── docs/                 # Documentation
│   ├── guides/           # Guides d'utilisation
│   └── api/              # Documentation API
├── tests/                # Tests
├── tools/                # Outils divers
└── assets/               # Ressources statiques
```

## Changements spécifiques

### Workflows n8n
- Tous les fichiers JSON des workflows ont été déplacés dans `src/workflows/`
- Exemples : `EMAIL_SENDER_PHASE1.json`, `test-mcp-git-ingest-workflow.json`

### Fichiers MCP
- Les fichiers batch MCP ont été déplacés dans `src/mcp/batch/`
  - Exemples : `mcp-standard.cmd`, `mcp-notion.cmd`, `gateway.exe.cmd`, `mcp-git-ingest.cmd`
- Les fichiers de configuration MCP ont été déplacés dans `src/mcp/config/`
  - Exemples : `mcp-config.json`, `gateway.yaml`

### Scripts
- Les scripts PowerShell ont été organisés dans `scripts/` et ses sous-dossiers
  - Scripts d'installation et de configuration : `scripts/setup/`
  - Scripts de maintenance : `scripts/maintenance/`

### Documentation
- Tous les fichiers de documentation ont été déplacés dans `docs/`
- Les guides d'utilisation sont dans `docs/guides/`
  - Exemples : `GUIDE_FINAL_MCP.md`, `GUIDE_MCP_GATEWAY.md`

### Outils
- Les scripts de démarrage ont été déplacés dans `tools/`
  - Exemples : `start-n8n.cmd`, `start-n8n-mcp.cmd`

## Comment utiliser la nouvelle structure

### Démarrer n8n
```
.\tools\start-n8n-mcp.cmd
```

### Configurer les MCP
```
.\scripts\setup\configure-n8n-mcp.ps1
.\scripts\setup\configure-mcp-git-ingest.ps1
```

### Créer de nouveaux fichiers
Utilisez le script `new-file.ps1` pour créer de nouveaux fichiers dans les bons dossiers :
```
.\scripts\maintenance\new-file.ps1 -Type workflow -Name mon-workflow
```

Types disponibles :
- `workflow` : Crée un nouveau workflow n8n
- `script` : Crée un nouveau script PowerShell
- `doc` : Crée un nouveau document Markdown
- `config` : Crée un nouveau fichier de configuration
- `mcp` : Crée un nouveau fichier batch MCP
- `test` : Crée un nouveau script de test

### Organisation automatique
Le script `auto-organize.ps1` peut être exécuté périodiquement pour organiser automatiquement les fichiers :
```
.\scripts\maintenance\auto-organize.ps1
```

## Avantages de la nouvelle structure
1. **Organisation claire** : Chaque fichier a sa place logique
2. **Facilité de maintenance** : Les scripts sont regroupés par fonction
3. **Évolutivité** : La structure peut facilement accueillir de nouveaux composants
4. **Conformité aux bonnes pratiques** : Structure standard pour les projets GitHub
5. **Auto-organisation** : Les nouveaux fichiers sont automatiquement placés au bon endroit
