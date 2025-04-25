# MCP (Model Context Protocol) Framework

Ce dossier contient l'implémentation du framework MCP (Model Context Protocol) qui permet d'interagir avec différents serveurs MCP et d'exécuter des outils via le protocole MCP.

## Structure du dossier

```
mcp/
├── core/                  # Composants principaux du framework MCP
│   ├── client/            # Implémentation du client MCP (Python et PowerShell)
│   ├── server/            # Implémentation du serveur MCP
│   └── tests/             # Tests unitaires et d'intégration
├── docs/                  # Documentation
├── integrations/          # Intégrations avec d'autres systèmes
├── modules/               # Modules PowerShell pour MCP
├── scripts/               # Scripts Python pour MCP
├── servers/               # Implémentations de serveurs MCP spécifiques
│   ├── gdrive/            # Serveur MCP pour Google Drive
│   └── ...
└── utils/                 # Utilitaires
    ├── commands/          # Fichiers de commande (.cmd)
    └── scripts/           # Scripts PowerShell utilitaires
```

## Composants principaux

- **Client MCP** : Permet de se connecter à un serveur MCP, récupérer la liste des outils disponibles et exécuter des outils.
- **Serveur MCP** : Implémente le protocole MCP et expose des outils via une API REST.
- **Gestionnaire MCP** : Détecte, configure et gère les serveurs MCP.
- **Agent MCP** : Utilise un modèle de langage pour exécuter des requêtes en langage naturel via le protocole MCP.

## Types de serveurs supportés

- **n8n** : Serveur d'automatisation de flux de travail
- **Augment** : Serveur d'IA pour l'augmentation de code
- **Deepsite** : Serveur pour l'analyse de sites web
- **crewAI** : Serveur pour la gestion d'agents d'IA
- **Google Drive** : Serveur pour l'accès aux fichiers Google Drive
- **Serveurs locaux** : Serveurs MCP exécutés localement
- **Serveurs cloud** : Serveurs MCP hébergés sur GCP ou GitHub

## Utilisation

Pour démarrer le gestionnaire de serveurs MCP :

```powershell
Import-Module .\modules\MCPManager.psm1
Start-MCPManager
```

Pour démarrer un agent MCP :

```powershell
Import-Module .\modules\MCPManager.psm1
Start-MCPManager -Agent -Query "Trouve les meilleurs restaurants à Paris"
```

Pour plus d'informations, consultez la documentation dans le dossier `docs/`.
