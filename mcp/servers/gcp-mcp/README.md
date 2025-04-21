# Configuration du MCP GCP pour N8N

Ce dossier contient le MCP (Model Context Protocol) pour Google Cloud Platform, qui permet à N8N d'interagir avec les services GCP via des assistants IA.

## Prérequis

- Node.js (déjà installé)
- Identifiants OAuth2 pour Google Cloud Platform

## Utilisation dans N8N

Pour utiliser ce MCP dans N8N, vous devez configurer un nœud MCP avec les paramètres suivants :

1. Type de connexion : Command Line (STDIO)
2. Commande : `cmd.exe`
3. Arguments : `/c`, `D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1\mcp-servers\gcp-mcp\start-gcp-mcp.cmd`
4. Variables d'environnement : `N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true`

## Fonctionnalités disponibles

Le MCP GCP permet d'interagir avec les services suivants :

- Google Compute Engine
- Cloud Storage
- Cloud Functions
- Cloud Run
- BigQuery
- Cloud SQL
- Google Kubernetes Engine (GKE)
- Cloud Logging
- Cloud Billing
- Resource Manager
- Et plus encore...

## Exemples d'utilisation

- "Liste tous les projets GCP auxquels j'ai accès"
- "Montre-moi toutes les instances Cloud SQL dans le projet X"
- "Quel est mon statut de facturation actuel ?"
- "Montre-moi les logs de mes services Cloud Run"
- "Liste tous les clusters GKE dans us-central1"
- "Montre-moi tous les buckets Cloud Storage dans le projet X"
- "Quelles fonctions Cloud sont déployées dans us-central1 ?"
- "Liste tous les services Cloud Run"
- "Montre-moi les datasets et tables BigQuery"

## Configuration de l'authentification OAuth2

Pour configurer l'authentification OAuth2 :

1. Le fichier d'identifiants OAuth2 a été copié dans `credentials.json`
2. Exécutez le script `setup-auth.cmd` pour obtenir un jeton d'accès
3. Suivez les instructions à l'écran pour autoriser l'application
4. Une fois l'autorisation terminée, un fichier `token.json` sera créé

Ce processus n'est nécessaire qu'une seule fois, sauf si le jeton expire.

## Dépannage

Si vous rencontrez des problèmes :

1. Erreurs d'authentification : Vérifiez que votre fichier `token.json` existe et est valide. Si nécessaire, supprimez-le et exécutez `setup-auth.cmd` à nouveau.
2. Erreurs de permission : Vérifiez les rôles IAM pour votre compte et assurez-vous que les scopes OAuth2 appropriés sont activés.
3. Erreurs d'API : Vérifiez que les API requises sont activées dans votre projet GCP.
