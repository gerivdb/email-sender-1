# Guide d'utilisation du MCP Desktop Commander

## Introduction

Le MCP Desktop Commander est un serveur MCP (Model Context Protocol) qui permet à Claude et autres assistants IA de manipuler des fichiers, exécuter des commandes terminal et automatiser des tâches sur votre ordinateur. Ce guide vous explique comment configurer et utiliser le MCP Desktop Commander dans vos workflows.

## Prérequis

- Node.js 18.0.0 ou supérieur
- npm (généralement installé avec Node.js)
- Claude Desktop (ou autre client MCP compatible)
- Accès administrateur pour l'installation globale (recommandé)

## Installation

### Installation automatique

La méthode la plus simple pour installer Desktop Commander est d'utiliser notre script d'installation automatique :

```powershell
.\projet\mcp\scripts\setup-desktop-commander-mcp.ps1
```plaintext
Ce script va :
1. Vérifier que Node.js est installé
2. Installer le package npm `@wonderwhy-er/desktop-commander`
3. Configurer le MCP dans votre système
4. Créer les fichiers de configuration nécessaires

### Installation manuelle

Si vous préférez installer manuellement :

1. Installez le package npm globalement :
   ```
   npm install -g @wonderwhy-er/desktop-commander
   ```

2. Configurez Claude Desktop :
   ```
   npx @wonderwhy-er/desktop-commander setup
   ```

3. Redémarrez Claude Desktop pour appliquer les changements.

## Configuration

Le MCP Desktop Commander peut être configuré via le fichier `projet/mcp/config/servers/desktop-commander.json`. Les options principales sont :

| Option | Description | Valeur par défaut |
|--------|-------------|-------------------|
| `enabled` | Active ou désactive le serveur | `true` |
| `port` | Port sur lequel le serveur écoute | `8080` |
| `allowedDirectories` | Répertoires auxquels le serveur a accès | `[]` (tous) |
| `blockedCommands` | Commandes interdites | `["rm -rf /", "format", "deltree"]` |
| `defaultShell` | Shell par défaut | `"powershell"` sur Windows, `"bash"` sur macOS/Linux |
| `disableTelemetry` | Désactive la télémétrie | `true` |

⚠️ **Attention** : La restriction `allowedDirectories` ne s'applique qu'aux opérations sur les fichiers, pas aux commandes terminal qui peuvent toujours accéder à tout le système.

## Fonctionnalités principales

### Exécution de commandes terminal

Desktop Commander permet d'exécuter des commandes dans le terminal et de récupérer leur sortie :

```plaintext
execute_command({ "command": "dir", "timeout": 30000 })
```plaintext
Options disponibles :
- `command` : La commande à exécuter
- `timeout` : Délai d'attente en millisecondes (défaut : 30000)
- `shell` : Shell à utiliser (ex: "powershell", "cmd", "bash")

Pour les commandes longues, vous pouvez utiliser :
```plaintext
read_output({ "pid": 1234 })
```plaintext
### Gestion des processus

Lister les processus en cours :
```plaintext
list_processes({})
```plaintext
Terminer un processus :
```plaintext
kill_process({ "pid": 1234 })
```plaintext
### Opérations sur les fichiers

Lire un fichier :
```plaintext
read_file({ "path": "chemin/vers/fichier.txt" })
```plaintext
Écrire dans un fichier :
```plaintext
write_file({ "path": "chemin/vers/fichier.txt", "content": "Nouveau contenu" })
```plaintext
Lister un répertoire :
```plaintext
list_directory({ "path": "chemin/vers/dossier" })
```plaintext
### Recherche de fichiers et de code

Rechercher des fichiers par nom :
```plaintext
search_files({ "directory": "chemin/vers/dossier", "pattern": "*.txt" })
```plaintext
Rechercher du texte dans les fichiers :
```plaintext
search_code({ "directory": "chemin/vers/dossier", "pattern": "fonction()" })
```plaintext
### Édition de code

Desktop Commander offre une fonctionnalité puissante d'édition de code avec le format de bloc suivant :

```plaintext
edit_block({
  "content": "chemin/vers/fichier.js\n<<<<<<< SEARCH\nancien code\n=======\nnouveau code\n>>>>>>> REPLACE"
})
```plaintext
Ce format permet de faire des modifications chirurgicales dans les fichiers sans avoir à les réécrire entièrement.

## Intégration avec n8n

Pour utiliser le MCP Desktop Commander dans n8n :

1. Assurez-vous que le serveur MCP est en cours d'exécution
2. Dans n8n, utilisez le nœud "MCP" et sélectionnez "desktop-commander" comme serveur
3. Configurez les paramètres selon vos besoins

Exemple de workflow n8n :
- Trigger → MCP (desktop-commander) → Action (execute_command) → Traitement de la sortie

## Cas d'utilisation

Le MCP Desktop Commander est particulièrement utile pour :

1. **Exploration de code** : Parcourir et comprendre des bases de code complexes
2. **Automatisation de tâches** : Exécuter des séquences de commandes
3. **Édition de code assistée par IA** : Faire des modifications précises dans les fichiers
4. **Recherche avancée** : Trouver du code ou des fichiers avec des critères spécifiques
5. **Gestion de projet** : Organiser et manipuler des fichiers de projet

## Sécurité

⚠️ **Avertissement de sécurité** : Desktop Commander donne à Claude un accès significatif à votre système. Prenez les précautions suivantes :

1. Limitez les répertoires accessibles via `allowedDirectories`
2. Bloquez les commandes dangereuses via `blockedCommands`
3. N'exécutez pas de commandes dont vous ne comprenez pas les effets
4. Utilisez un compte utilisateur dédié avec des permissions limitées pour les opérations sensibles

## Dépannage

Si vous rencontrez des problèmes avec Desktop Commander :

1. **Le serveur ne démarre pas** :
   - Vérifiez que Node.js est correctement installé
   - Vérifiez qu'aucun autre service n'utilise le même port

2. **Claude ne peut pas se connecter au serveur** :
   - Vérifiez que le serveur est en cours d'exécution
   - Redémarrez Claude Desktop
   - Vérifiez la configuration dans `claude_desktop_config.json`

3. **Erreurs lors de l'exécution de commandes** :
   - Vérifiez que vous avez les permissions nécessaires
   - Vérifiez que la commande n'est pas bloquée dans la configuration

## Ressources supplémentaires

- [GitHub du projet Desktop Commander](https://github.com/wonderwhy-er/DesktopCommanderMCP)
- [Documentation du Model Context Protocol](https://modelcontextprotocol.ai/)
- [Guide d'utilisation des MCP dans n8n](GUIDE_FINAL_MCP.md)

## Support

Si vous avez besoin d'aide avec Desktop Commander, vous pouvez :
- Consulter les [issues GitHub](https://github.com/wonderwhy-er/DesktopCommanderMCP/issues)
- Rejoindre le [serveur Discord](https://discord.gg/kQ27sNnZr7)
- Consulter la [FAQ](https://github.com/wonderwhy-er/DesktopCommanderMCP/blob/main/FAQ.md)
