# Pilotage du serveur MCP Filesystem via MCP Manager et Proxy-MCP

## Utilisation

- Le serveur MCP Filesystem peut être démarré automatiquement ou manuellement via le script `start-filesystem-mcp.cmd`.
- Il est compatible avec MCP Manager et Proxy-MCP : configurez simplement le port et le chemin dans le manager ou le proxy.
- Le fichier `config.json` permet de restreindre les accès et de définir le port utilisé.

## Exemple de configuration pour Proxy-MCP

```json
{
  "servers": [
    {
      "name": "filesystem",
      "type": "filesystem",
      "port": 3000,
      "path": "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/projet/mcp/servers/filesystem"
    }
  ]
}
```plaintext
## Documentation API

Voir le README du package dans `node_modules/@modelcontextprotocol/server-filesystem/README.md`.
