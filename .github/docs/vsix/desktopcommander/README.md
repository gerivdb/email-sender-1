# DesktopCommanderMCP

Extension MCP pour automatiser le bureau Windows et les applications.

## Dépôt officiel
https://github.com/wonderwhy-er/DesktopCommanderMCP

## Installation

1. Cloner le dépôt ou installer via npx :
   ```
   npx wonderwhy-er/DesktopCommanderMCP
   ```
2. Ajouter le serveur MCP dans la configuration :
   ```json
   {
     "command": "npx",
     "args": ["wonderwhy-er/DesktopCommanderMCP"],
     "disabled": false,
     "autoApprove": []
   }
   ```

## Fonctionnalités

- Lancement d’applications
- Gestion de fenêtres et processus
- Automatisation clavier/souris
- Capture d’écran et monitoring
- Accès aux fichiers et dossiers

## Usage avec Roo Code

Déclarez DesktopCommanderMCP comme serveur MCP pour piloter le bureau et automatiser des workflows avancés.
