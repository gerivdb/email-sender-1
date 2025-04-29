# MCP (Model Context Protocol) Framework

Ce dossier contient l'implÃ©mentation du framework MCP (Model Context Protocol) qui permet d'interagir avec diffÃ©rents serveurs MCP et d'exÃ©cuter des outils via le protocole MCP.

## Structure du dossier

```
mcp/
â”œâ”€â”€ core/                  # Composants principaux du framework MCP
â”‚   â”œâ”€â”€ client/            # ImplÃ©mentation du client MCP (Python et PowerShell)
â”‚   â”œâ”€â”€ server/            # ImplÃ©mentation du serveur MCP
â”‚   â””â”€â”€ tests/             # Tests unitaires et d'intÃ©gration
â”œâ”€â”€ docs/                  # Documentation
â”œâ”€â”€ integrations/          # IntÃ©grations avec d'autres systÃ¨mes
â”œâ”€â”€ modules/               # Modules PowerShell pour MCP
â”œâ”€â”€ scripts/               # Scripts Python pour MCP
â”œâ”€â”€ servers/               # ImplÃ©mentations de serveurs MCP spÃ©cifiques
â”‚   â”œâ”€â”€ gdrive/            # Serveur MCP pour Google Drive
â”‚   â””â”€â”€ ...
â””â”€â”€ utils/                 # Utilitaires
    â”œâ”€â”€ commands/          # Fichiers de commande (.cmd)
    â””â”€â”€ scripts/           # Scripts PowerShell utilitaires
```

## Composants principaux

- **Client MCP** : Permet de se connecter Ã  un serveur MCP, rÃ©cupÃ©rer la liste des outils disponibles et exÃ©cuter des outils.
- **Serveur MCP** : ImplÃ©mente le protocole MCP et expose des outils via une API REST.
- **Gestionnaire MCP** : DÃ©tecte, configure et gÃ¨re les serveurs MCP.
- **Agent MCP** : Utilise un modÃ¨le de langage pour exÃ©cuter des requÃªtes en langage naturel via le protocole MCP.

## Types de serveurs supportÃ©s

- **n8n** : Serveur d'automatisation de flux de travail
- **Augment** : Serveur d'IA pour l'augmentation de code
- **Deepsite** : Serveur pour l'analyse de sites web
- **crewAI** : Serveur pour la gestion d'agents d'IA
- **Google Drive** : Serveur pour l'accÃ¨s aux fichiers Google Drive
- **Serveurs locaux** : Serveurs MCP exÃ©cutÃ©s localement
- **Serveurs cloud** : Serveurs MCP hÃ©bergÃ©s sur GCP ou GitHub

## Utilisation

Pour dÃ©marrer le gestionnaire de serveurs MCP :

```powershell
Import-Module .\modules\MCPManager.psm1
mcp-manager
```

Pour dÃ©marrer un agent MCP :

```powershell
Import-Module .\modules\MCPManager.psm1
mcp-manager -Agent -Query "Trouve les meilleurs restaurants Ã  Paris"
```

Pour plus d'informations, consultez la documentation dans le dossier `docs/`.

