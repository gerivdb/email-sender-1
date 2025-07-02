# Intégration MCP avec Augment Code

Ce guide explique comment intégrer les serveurs MCP (Model Context Protocol) d'Augment Code avec le MCP Manager existant.

## Introduction

Le MCP (Model Context Protocol) est un protocole qui permet aux modèles d'IA d'accéder à des ressources externes, comme des fichiers, des bases de données, ou des API. Dans notre projet, nous utilisons plusieurs serveurs MCP pour différentes fonctionnalités, et nous avons ajouté deux nouveaux serveurs MCP spécifiques à Augment Code :

1. **Serveur MCP pour les Memories** : Permet à Augment Code d'accéder et de gérer les Memories.
2. **Adaptateur MCP pour le gestionnaire de modes** : Permet à Augment Code d'interagir avec le gestionnaire de modes.

Pour une gestion centralisée de tous les serveurs MCP, nous avons intégré ces nouveaux serveurs avec le MCP Manager existant.

## Serveurs MCP d'Augment Code

### Serveur MCP pour les Memories

Le serveur MCP pour les Memories (`mcp-memories-server.ps1`) expose les fonctionnalités suivantes via le protocole MCP :

- `getMemories` : Récupère les Memories actuelles
- `updateMemories` : Met à jour les Memories avec un nouveau contenu
- `splitInput` : Divise un input en segments pour respecter la limite de taille
- `exportToVSCode` : Exporte les Memories vers VS Code

Ce serveur écoute par défaut sur le port 7891.

### Adaptateur MCP pour le gestionnaire de modes

L'adaptateur MCP pour le gestionnaire de modes (`mcp-mode-manager-adapter.ps1`) expose les fonctionnalités suivantes via le protocole MCP :

- `listModes` : Récupère la liste des modes disponibles
- `executeMode` : Exécute un mode spécifique
- `getModeConfig` : Récupère la configuration d'un mode
- `executeChain` : Exécute une chaîne de modes séquentiellement

Cet adaptateur écoute par défaut sur le port 7892.

## Intégration avec le MCP Manager

Pour intégrer les serveurs MCP d'Augment Code avec le Gateway Manager existant, nous avons créé un script d'intégration (`integrate-with-gateway-manager.ps1`) qui effectue les actions suivantes :

1. Met à jour le module MCPManager pour inclure les serveurs MCP d'Augment Code
2. Met à jour la configuration MCP globale
3. Met à jour le script de démarrage de tous les serveurs MCP

### Exécution du script d'intégration

Pour exécuter le script d'intégration, utilisez la commande suivante :

```powershell
.\development\scripts\maintenance\augment\integrate-with-gateway-manager.ps1
```plaintext
Si les serveurs MCP d'Augment Code sont déjà intégrés, le script affichera un message et s'arrêtera. Pour forcer la mise à jour, utilisez le paramètre `-Force` :

```powershell
.\development\scripts\maintenance\augment\integrate-with-gateway-manager.ps1 -Force
```plaintext
### Vérification de l'intégration

Pour vérifier que l'intégration a réussi, vous pouvez exécuter les tests unitaires :

```powershell
.\development\scripts\maintenance\augment\tests\Run-AllTests.ps1
```plaintext
Ou exécuter spécifiquement le test d'intégration avec le MCP Manager :

```powershell
Invoke-Pester -Path "development\scripts\maintenance\augment\tests\Test-IntegrateWithMCPManager.ps1"
```plaintext
## Démarrage des serveurs MCP

Après l'intégration, vous pouvez démarrer tous les serveurs MCP, y compris les serveurs MCP d'Augment Code, en utilisant le script de démarrage global :

```powershell
.\src\mcp\utils\scripts\start-all-mcp-servers.ps1
```plaintext
Ou vous pouvez démarrer uniquement les serveurs MCP d'Augment Code en utilisant le script de démarrage spécifique :

```powershell
.\development\scripts\maintenance\augment\start-mcp-servers.ps1
```plaintext
## Configuration

### Configuration du serveur MCP pour les Memories

Le serveur MCP pour les Memories utilise la configuration suivante :

- **Port** : 7891 (par défaut)
- **ConfigPath** : "development\config\unified-config.json" (par défaut)

Vous pouvez modifier ces paramètres en éditant le fichier de configuration ou en spécifiant des paramètres lors du démarrage du serveur :

```powershell
.\development\scripts\maintenance\augment\mcp-memories-server.ps1 -Port 7893 -ConfigPath "config\custom-config.json"
```plaintext
### Configuration de l'adaptateur MCP pour le gestionnaire de modes

L'adaptateur MCP pour le gestionnaire de modes utilise la configuration suivante :

- **Port** : 7892 (par défaut)
- **ConfigPath** : "development\config\unified-config.json" (par défaut)

Vous pouvez modifier ces paramètres en éditant le fichier de configuration ou en spécifiant des paramètres lors du démarrage de l'adaptateur :

```powershell
.\development\scripts\maintenance\augment\mcp-mode-manager-adapter.ps1 -Port 7894 -ConfigPath "config\custom-config.json"
```plaintext
## Utilisation avec Augment Code

Augment Code peut maintenant accéder aux fonctionnalités du gestionnaire de modes et des Memories via le protocole MCP. Par exemple, pour exécuter un mode spécifique, Augment Code peut envoyer une requête MCP à l'adaptateur MCP pour le gestionnaire de modes :

```json
{
  "method": "executeMode",
  "params": {
    "mode": "GRAN",
    "filePath": "docs/plans/plan-modes-stepup.md",
    "taskIdentifier": "1.2.3"
  }
}
```plaintext
Et pour récupérer les Memories, Augment Code peut envoyer une requête MCP au serveur MCP pour les Memories :

```json
{
  "method": "getMemories",
  "params": {}
}
```plaintext
## Dépannage

### Les serveurs MCP ne démarrent pas

Si les serveurs MCP ne démarrent pas, vérifiez les points suivants :

- Les ports 7891 et 7892 sont disponibles
- Les scripts sont exécutés avec les droits d'administrateur si nécessaire
- Les chemins vers les scripts sont corrects

### Erreurs de communication avec les serveurs MCP

Si Augment Code ne peut pas communiquer avec les serveurs MCP, vérifiez les points suivants :

- Les serveurs MCP sont démarrés
- Les ports sont correctement configurés
- Les pare-feu ne bloquent pas les connexions

### Réinitialisation de la configuration

Si vous rencontrez des problèmes avec la configuration, vous pouvez réinitialiser l'intégration en exécutant le script d'intégration avec le paramètre `-Force` :

```powershell
.\development\scripts\maintenance\augment\integrate-with-gateway-manager.ps1 -Force
```plaintext
## Ressources supplémentaires

- [Guide d'intégration avec Augment Code](./integration_guide.md)
- [Optimisation des Memories](./memories_optimization.md)
- [Limitations d'Augment Code](./limitations.md)
- [Documentation officielle du MCP](https://modelcontextprotocol.github.io/)
