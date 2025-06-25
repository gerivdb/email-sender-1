# Guide de Dépannage MCP pour Cline

## ✅ Problème Résolu : Format JSON Invalide

### Le Problème
L'erreur "Invalid MCP settings format. Please ensure your settings follow the correct JSON format. Source Cline" était causée par un fichier JSON mal formaté dans `misc/cline_mcp_settings.json`.

### La Solution
1. **Fichier problématique supprimé** : `misc/cline_mcp_settings.json` (contenait des accolades surnuméraires)
2. **Nouveau fichier créé** : `.cline_mcp_settings.json` avec un format JSON valide

### Configuration MCP Correcte

Le fichier `.cline_mcp_settings.json` contient maintenant :

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "@modelcontextprotocol/server-filesystem",
        "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1"
      ],
      "disabled": false
    },
    "git": {
      "command": "npx", 
      "args": [
        "@modelcontextprotocol/server-git",
        "--repository",
        "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1"
      ],
      "disabled": false
    }
  }
}
```

## 🔧 Vérification de la Configuration MCP

### Valider le JSON
```powershell
# Valider que le JSON est correct
Get-Content ".cline_mcp_settings.json" | ConvertFrom-Json | ConvertTo-Json
```

### Localiser les Configurations MCP
```powershell
# Trouver tous les fichiers de configuration MCP
Get-ChildItem -Recurse -Name "*mcp*config*", "*cline*", "claude*"
```

## 🚨 Erreurs Communes et Solutions

### 1. Accolades Surnuméraires
**Erreur** : `}` fermante en trop
**Solution** : Vérifier que chaque `{` a sa `}` correspondante

### 2. Virgules Manquantes
**Erreur** : Éléments de tableau non séparés
**Solution** : Ajouter des virgules entre les éléments

### 3. Chemins Windows
**Erreur** : Backslashes non échappés
**Solution** : Utiliser `\\` au lieu de `\` dans les chemins

## 📁 Emplacements des Configurations MCP

- **Configuration Cline** : `.cline_mcp_settings.json` (racine du projet)
- **Configuration Claude Desktop** : `src/mcp/servers/claude_desktop_config.json`
- **Configuration MCP Serveurs** : `src/mcp/servers/mcp-config.json`
- **Templates MCP** : `projet/mcp/config/templates/`

## ✅ Validation Finale

Le problème MCP a été résolu avec succès :
- ✅ Fichier JSON invalide supprimé
- ✅ Nouvelle configuration MCP valide créée
- ✅ Format JSON validé
- ✅ Configuration compatible avec Cline

## 🔄 Si le Problème Persiste

1. Redémarrer VS Code
2. Vérifier les extensions Cline
3. Consulter les logs de Cline dans VS Code
4. Valider tous les fichiers JSON MCP du projet

---

**Note** : Ce guide documente la résolution du problème rencontré le 25/06/2025. La configuration MCP est maintenant opérationnelle.
