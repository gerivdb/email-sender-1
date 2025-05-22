# Structure de la section GCP dans `mcp-config.json`

Ce document décrit la structure attendue pour la section GCP dans le fichier de configuration du proxy MCP (`projet/mcp/config/mcp-config.json`).

## Exemple de section GCP

```json
"gcp": {
    "command": "npx",
    "args": [
        "gcp-mcp"
    ],
    "env": {
        "GOOGLE_APPLICATION_CREDENTIALS": "config/credentials/gcp-token.json"
    },
    "enabled": true,
    "configPath": "config/servers/gcp.json"
}
```

## Détail des champs
- **command** : Commande à exécuter pour lancer le serveur GCP MCP (ici `npx`).
- **args** : Arguments passés à la commande (ici le script ou package à lancer).
- **env** : Variables d’environnement nécessaires (ici le chemin du service account Google).
- **enabled** : Active ou non le serveur GCP MCP dans l’orchestration MCP.
- **configPath** : Chemin relatif vers le fichier de configuration spécifique GCP (`gcp.json`).

## Fichier de configuration GCP (`gcp.json`)
Exemple :
```json
{
  "projectId": "...",
  "region": "...",
  "serviceAccount": "config/credentials/gcp-token.json",
  "features": { ... }
}
```

## Bonnes pratiques
- Vérifier que le chemin du service account est correct et accessible.
- S’assurer que le champ `enabled` est à `true` pour activer le serveur.
- Adapter les arguments selon le script ou le package utilisé pour le serveur GCP MCP.

---
Dernière mise à jour : 2025-05-22
