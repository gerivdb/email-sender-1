# Guide pour tester les MCP dans n8n

Ce guide vous explique comment importer et tester le workflow de test pour verifier que les MCP fonctionnent correctement.

## Etape 1 : Importer le workflow de test

1. Ouvrez l'interface web de n8n (http://localhost:5678)
2. Cliquez sur "Workflows" dans le menu de gauche
3. Cliquez sur le bouton "Import from File" (icone d'importation)
4. Selectionnez le fichier `test-mcp-workflow-updated.json`
5. Cliquez sur "Import"

## Etape 2 : Configurer les identifiants MCP

Le workflow de test utilise trois identifiants MCP :
- MCP Standard
- MCP Notion
- MCP Gateway

Si ces identifiants n'existent pas encore ou ont des noms differents, vous devrez mettre a jour le workflow :

1. Cliquez sur chaque noeud MCP Client
2. Dans la section "Credentials", selectionnez l'identifiant MCP correspondant
3. Cliquez sur "Save" pour enregistrer les modifications

## Etape 3 : Executer le workflow

1. Cliquez sur le bouton "Execute Workflow" (icone de lecture)
2. Observez les resultats de l'execution

Si les MCP fonctionnent correctement, vous devriez voir les resultats suivants :
- Le noeud MCP Client (Standard) devrait afficher la liste des outils disponibles dans le MCP standard
- Le noeud MCP Client (Notion) devrait afficher la liste des outils disponibles dans le MCP Notion Server
- Le noeud MCP Client (Gateway) devrait afficher la liste des outils disponibles dans le MCP Gateway

## Etape 4 : Verifier les toasts d'erreur

Si vous ne voyez plus de toasts d'erreur indiquant que les MCP n'ont pas demarre, cela signifie que le probleme est resolu.

## Depannage

Si vous rencontrez toujours des problemes :

1. Verifiez les logs de n8n pour voir les erreurs eventuelles
2. Assurez-vous que les chemins dans la configuration des identifiants MCP sont corrects et utilisent des chemins absolus
3. Verifiez que les fichiers batch sont executables et accessibles
4. Assurez-vous que n8n a les permissions necessaires pour executer les scripts et acceder aux fichiers

## Conclusion

Si le workflow de test s'execute correctement et que vous ne voyez plus de toasts d'erreur, cela signifie que les MCP sont correctement configures et fonctionnent dans n8n.
