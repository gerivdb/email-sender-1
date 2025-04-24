# Guide sur le dossier .n8n

## Qu'est-ce que le dossier .n8n ?

Le dossier `.n8n` est un dossier spécial utilisé par n8n pour stocker sa configuration locale et ses données. Il s'agit d'un élément essentiel de l'infrastructure n8n qui contient toutes les informations nécessaires au fonctionnement de l'application.

## Fonctions principales du dossier .n8n

### 1. Configuration locale

Le dossier `.n8n` contient les fichiers de configuration spécifiques à votre installation n8n, notamment :
- Les paramètres de connexion à la base de données
- Les ports utilisés par l'application
- Les options de configuration personnalisées
- Les paramètres d'environnement

### 2. Base de données

Par défaut, n8n utilise une base de données SQLite stockée dans ce dossier (généralement un fichier `database.sqlite`) qui contient :
- Tous vos workflows
- Les informations d'exécution des workflows
- Les variables d'environnement
- Les configurations des nœuds

### 3. Credentials chiffrées

Les informations d'identification sensibles sont stockées de manière chiffrée dans ce dossier :
- API keys
- Mots de passe
- Tokens d'authentification
- Autres informations sensibles

### 4. Cache et données temporaires

n8n stocke également des données de cache et des fichiers temporaires dans ce dossier pour améliorer les performances :
- Cache des exécutions
- Données temporaires des workflows
- Fichiers intermédiaires

### 5. Logs

Selon votre configuration, certains fichiers de logs peuvent être stockés dans ce dossier :
- Logs d'erreurs
- Logs d'exécution
- Logs de débogage

## Emplacement du dossier .n8n

L'emplacement par défaut du dossier `.n8n` dépend de votre système d'exploitation :
- **Linux/Mac** : `~/.n8n`
- **Windows** : `%USERPROFILE%\.n8n`

Dans votre projet, le dossier `.n8n` semble être présent directement dans le répertoire du projet, ce qui permet de maintenir une configuration spécifique au projet.

## Importance pour la sauvegarde

Lors de la sauvegarde de votre projet n8n, il est crucial d'inclure le dossier `.n8n` car il contient :
- Tous vos workflows
- Toutes vos credentials (chiffrées)
- Toute la configuration de votre instance n8n

Sans ce dossier, vous perdriez l'ensemble de votre travail et de votre configuration.

## Précautions importantes

1. **Ne pas modifier manuellement** : Ne modifiez jamais manuellement les fichiers dans ce dossier, car cela pourrait corrompre votre installation n8n.

2. **Ne pas partager les credentials** : Bien que les credentials soient chiffrées, évitez de partager directement le dossier `.n8n` avec d'autres personnes. Utilisez plutôt les fonctionnalités d'export/import de n8n.

3. **Sauvegarde régulière** : Effectuez des sauvegardes régulières de ce dossier pour éviter la perte de données.

4. **Gestion des versions** : Si vous utilisez Git, vous pouvez inclure ce dossier dans votre `.gitignore` et gérer les sauvegardes séparément pour éviter de stocker des informations sensibles dans votre dépôt.

## Utilisation avec les MCP

Lorsque vous utilisez des Model Context Protocols (MCP) avec n8n, le dossier `.n8n` stocke également :
- Les configurations des MCP
- Les données d'état des MCP
- Les logs d'exécution des MCP

C'est pourquoi il est particulièrement important de préserver ce dossier dans votre projet Email Sender qui utilise intensivement les MCP.

## Conclusion

Le dossier `.n8n` est le cœur de votre installation n8n, contenant toutes les données et configurations nécessaires au fonctionnement de l'application. Il doit être traité avec soin et inclus dans vos stratégies de sauvegarde pour assurer la pérennité de votre projet.
