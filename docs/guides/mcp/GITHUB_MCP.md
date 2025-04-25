# Guide d'utilisation du MCP GitHub

Ce document explique comment configurer et utiliser le serveur MCP GitHub pour accéder aux dépôts GitHub depuis n8n et les modèles d'IA comme Claude.

## Qu'est-ce que le MCP GitHub ?

Le MCP GitHub est une implémentation du Model Context Protocol (MCP) qui permet aux modèles d'IA d'interagir avec les dépôts GitHub. Il offre les fonctionnalités suivantes :

- Exploration des dépôts GitHub
- Lecture des fichiers dans les dépôts
- Recherche de code dans les dépôts
- Accès aux issues et pull requests
- Et plus encore

## Installation

Le serveur MCP GitHub peut être installé globalement via npm :

```bash
npm install -g @modelcontextprotocol/server-github
```

## Configuration

### Token GitHub

Pour un accès optimal, il est recommandé de configurer un token GitHub. Vous pouvez le faire de plusieurs façons :

1. **Utiliser le script de configuration** : Exécutez le script suivant qui vous guidera pas à pas :
   ```powershell
   .\scripts\setup\configure-github-token.ps1
   ```

2. **Variable d'environnement** : Définissez la variable d'environnement `GITHUB_TOKEN`

3. **Fichier .env** : Créez manuellement un fichier `.env` à la racine du projet avec le contenu suivant :
   ```
   GITHUB_TOKEN=votre_token_github
   ```

4. **Lors de l'exécution** : Le script vous demandera un token s'il n'en trouve pas

#### Création d'un token GitHub

Pour créer un token GitHub, suivez ces étapes :

1. Connectez-vous à votre compte GitHub
2. Accédez aux paramètres de votre compte (cliquez sur votre photo de profil en haut à droite, puis sur "Settings")
3. Dans le menu de gauche, cliquez sur "Developer settings"
4. Cliquez sur "Personal access tokens" puis "Tokens (classic)"
5. Cliquez sur "Generate new token" puis "Generate new token (classic)"
6. Donnez un nom à votre token (par exemple "MCP GitHub Access")
7. Sélectionnez les autorisations nécessaires :
   - `repo` (accès complet aux dépôts)
   - `read:org` (lecture des informations sur l'organisation)
   - `read:user` (lecture des informations sur l'utilisateur)
   - `read:project` (lecture des projets)
8. Cliquez sur "Generate token"
9. **Important** : Copiez le token généré, car vous ne pourrez plus le voir après avoir quitté cette page

### Intégration avec n8n

Pour utiliser le MCP GitHub dans n8n, exécutez le script de configuration :

```powershell
.\scripts\setup\mcp\configure-mcp-github.ps1
```

Ce script va :
- Créer les fichiers batch nécessaires
- Configurer les identifiants dans n8n
- Mettre à jour la base de données des identifiants

## Utilisation

### Démarrage manuel

Pour démarrer manuellement le serveur MCP GitHub, utilisez l'une des commandes suivantes :

- **PowerShell** : `.\scripts\mcp\Start-McpGithub.ps1`
- **Batch** : `.\scripts\mcp\start-mcp-github.cmd`

### Utilisation avec Augment

Pour utiliser le MCP GitHub avec Augment, ajoutez la configuration suivante à votre fichier de configuration Augment :

```json
{
  "augment.mcpServers": [
    {
      "name": "MCP GitHub",
      "type": "command",
      "command": "D:\\chemin\\vers\\votre\\projet\\scripts\\cmd\\augment\\augment-mcp-github.cmd"
    }
  ]
}
```

### Utilisation avec n8n

Dans n8n, vous pouvez utiliser le MCP GitHub via le nœud "MCP Client" :

1. Ajoutez un nœud "MCP Client"
2. Sélectionnez l'identifiant "MCP GitHub"
3. Configurez les paramètres selon vos besoins

## Exemples d'utilisation

### Exploration d'un dépôt

```json
{
  "tool": "github_list_files",
  "params": {
    "repo_url": "https://github.com/utilisateur/depot"
  }
}
```

### Lecture d'un fichier

```json
{
  "tool": "github_read_file",
  "params": {
    "repo_url": "https://github.com/utilisateur/depot",
    "file_path": "chemin/vers/fichier.txt"
  }
}
```

### Recherche de code

```json
{
  "tool": "github_search_code",
  "params": {
    "repo_url": "https://github.com/utilisateur/depot",
    "query": "fonction recherchée"
  }
}
```

## Dépannage

### Problèmes d'authentification

Si vous rencontrez des problèmes d'authentification :

1. Vérifiez que votre token GitHub est valide
2. Assurez-vous que le token a les permissions nécessaires
3. Vérifiez que la variable d'environnement `GITHUB_TOKEN` est correctement définie

### Limites de taux

Sans authentification, GitHub impose des limites de taux strictes. Si vous rencontrez des erreurs de limite de taux :

1. Configurez un token GitHub
2. Réduisez la fréquence de vos requêtes
3. Mettez en place une logique de retry avec backoff exponentiel

## Ressources supplémentaires

- [Documentation officielle du MCP](https://github.com/anthropics/anthropic-cookbook/tree/main/mcp)
- [API GitHub](https://docs.github.com/en/rest)
- [Création de tokens GitHub](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
