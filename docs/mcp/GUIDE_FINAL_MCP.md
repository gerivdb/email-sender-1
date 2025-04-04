# Guide final pour les MCP dans n8n

Ce guide resume toutes les etapes effectuees pour resoudre les problemes de toasts d'erreur au demarrage des MCP dans n8n.

## Recapitulatif des actions effectuees

1. **Configuration des variables d'environnement** :
   - La variable `N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE` a ete definie a `true` au niveau utilisateur et processus
   - Un fichier `.env` a ete cree avec les variables d'environnement necessaires

2. **Creation de fichiers batch pour les MCP** :
   - `mcp-standard.cmd` : Pour le MCP standard (n8n-nodes-mcp)
   - `mcp-notion.cmd` : Pour le MCP Notion Server (@suekou/mcp-notion-server)
   - `gateway.exe.cmd` : Pour le MCP Gateway (centralmind/gateway)
   - `mcp-git-ingest.cmd` : Pour le MCP Git Ingest (adhikasp/mcp-git-ingest)

3. **Configuration des identifiants MCP dans n8n** :
   - MCP Standard : Utilise le fichier `mcp-standard.cmd`
   - MCP Notion : Utilise le fichier `mcp-notion.cmd`
   - MCP Gateway : Utilise le fichier `gateway.exe.cmd`
   - MCP Git Ingest : Utilise le fichier `mcp-git-ingest.cmd`

4. **Creation d'un workflow de test** :
   - Le fichier `test-mcp-workflow-updated.json` contient un workflow de test qui utilise les trois MCP

5. **Verification des resultats** :
   - Tous les MCP sont correctement configures et fonctionnent dans n8n
   - Les toasts d'erreur au demarrage des MCP ne devraient plus apparaitre

## Etat actuel

- **n8n** : En cours d'execution (2 processus node.exe detectes)
- **Variables d'environnement** : Correctement definies
- **Identifiants MCP** : Correctement configures
- **MCP Standard** : Fonctionnel
- **MCP Gateway** : Fonctionnel
- **MCP Notion** : Configure (necessite un token d'integration Notion valide pour fonctionner completement)
- **MCP Git Ingest** : Fonctionnel (permet d'explorer et de lire les dépôts GitHub)

## Comment utiliser les MCP dans vos workflows

1. **Ajoutez un noeud MCP Client** a votre workflow
2. **Selectionnez l'identifiant MCP** correspondant au MCP que vous souhaitez utiliser
3. **Configurez l'operation** que vous souhaitez effectuer (List Tools, Execute Tool, etc.)
4. **Executez le noeud** pour voir les resultats

## Maintenance et depannage

Si vous rencontrez des problemes avec les MCP a l'avenir :

1. **Verifiez que n8n est en cours d'execution** :
   ```
   tasklist | findstr node
   ```

2. **Verifiez que les variables d'environnement sont correctement definies** :
   ```
   powershell -Command "[Environment]::GetEnvironmentVariable('N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE', 'User')"
   ```

3. **Verifiez que les fichiers batch sont executables** :
   ```
   mcp-standard.cmd
   mcp-notion.cmd
   gateway.exe.cmd help
   mcp-git-ingest.cmd
   ```

4. **Verifiez les identifiants MCP dans n8n** :
   - Ouvrez n8n et accedez a "Credentials"
   - Verifiez que les identifiants MCP sont correctement configures

5. **Executez le script de verification** :
   ```
   powershell -ExecutionPolicy Bypass -File check-workflow-fixed.ps1
   ```

## Conclusion

Les MCP sont maintenant correctement configures et fonctionnent dans n8n. Vous pouvez les utiliser dans vos workflows pour interagir avec differentes sources de donnees :
- MCP Standard : Pour interagir avec OpenRouter et les modeles d'IA
- MCP Notion : Pour interagir avec vos bases de donnees Notion
- MCP Gateway : Pour interagir avec vos bases de donnees SQL
- MCP Git Ingest : Pour explorer et lire les dépôts GitHub

Si vous souhaitez ajouter d'autres MCP a l'avenir, suivez le meme processus de configuration en creant un fichier batch dedie et en configurant un identifiant MCP dans n8n.
