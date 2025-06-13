# MCP Filesystem Server

Ce dossier contient une installation locale du serveur MCP Filesystem.

## Lancement manuel

Depuis ce dossier, lancez :

```powershell
npx @modelcontextprotocol/server-filesystem
```plaintext
ou

```powershell
node ./node_modules/@modelcontextprotocol/server-filesystem/dist/index.js
```plaintext
## Intégration avec MCP Manager et Proxy-MCP

- Ce serveur peut être piloté par MCP Manager ou Proxy-MCP via la configuration des chemins et des ports.
- Assurez-vous que le port et les droits d’accès sont bien configurés dans `config.json` si besoin.

## Documentation

Voir le fichier `node_modules/@modelcontextprotocol/server-filesystem/README.md` pour l’API et les fonctionnalités.
