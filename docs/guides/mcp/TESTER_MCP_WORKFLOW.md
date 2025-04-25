# Guide pour tester les MCP dans n8n

Ce guide vous explique comment importer et tester le workflow de test pour vérifier que les MCP fonctionnent correctement.

## Étape 1 : Importer le workflow de test

1. Ouvrez l'interface web de n8n (http://localhost:5678)
2. Cliquez sur "Workflows" dans le menu de gauche
3. Cliquez sur le bouton "Import from File" (icône d'importation)
4. Sélectionnez le fichier `test-mcp-workflow-updated.json`
5. Cliquez sur "Import"

## Étape 2 : Configurer les identifiants MCP

Le workflow de test utilise trois identifiants MCP :
- MCP Standard
- MCP Notion
- MCP Gateway

Si ces identifiants n'existent pas encore ou ont des noms différents, vous devrez mettre à jour le workflow :

1. Cliquez sur chaque nœud MCP Client
2. Dans la section "Credentials", sélectionnez l'identifiant MCP correspondant
3. Cliquez sur "Save" pour enregistrer les modifications

## Étape 3 : Exécuter le workflow

1. Cliquez sur le bouton "Execute Workflow" (icône de lecture)
2. Observez les résultats de l'exécution

Si les MCP fonctionnent correctement, vous devriez voir les résultats suivants :
- Le nœud MCP Client (Standard) devrait afficher la liste des outils disponibles dans le MCP standard
- Le nœud MCP Client (Notion) devrait afficher la liste des outils disponibles dans le MCP Notion Server
- Le nœud MCP Client (Gateway) devrait afficher la liste des outils disponibles dans le MCP Gateway

## Étape 4 : Vérifier les toasts d'erreur

Si vous ne voyez plus de toasts d'erreur indiquant que les MCP n'ont pas démarré, cela signifie que le problème est résolu.

## Dépannage

Si vous rencontrez toujours des problèmes :

1. Vérifiez les logs de n8n pour voir les erreurs éventuelles
2. Assurez-vous que les chemins dans la configuration des identifiants MCP sont corrects et utilisent des chemins absolus
3. Vérifiez que les fichiers batch sont exécutables et accessibles
4. Assurez-vous que n8n a les permissions nécessaires pour exécuter les scripts et accéder aux fichiers

## Conclusion

Si le workflow de test s'exécute correctement et que vous ne voyez plus de toasts d'erreur, cela signifie que les MCP sont correctement configurés et fonctionnent dans n8n.
