# Guide d'intégration MCP avec n8n

## Vue d'ensemble

Ce guide détaille l'intégration du Model Context Protocol (MCP) avec n8n, permettant d'utiliser les capacités de MCP dans les workflows d'automatisation n8n. Cette intégration permet notamment de gérer les mémoires MCP et d'utiliser le contexte pour générer des emails personnalisés.

## Composants de l'intégration

L'intégration MCP-n8n comprend les éléments suivants :

1. **Nodes n8n personnalisés** :
   - MCP Client : Node générique pour interagir avec les serveurs MCP
   - MCP Memory : Node spécifique pour la gestion des mémoires

2. **Workflows d'exemple** :
   - Gestion des mémoires MCP
   - Génération d'emails contextuels

3. **Configuration des credentials** :
   - Configuration HTTP pour les serveurs MCP REST
   - Configuration Command Line pour les serveurs MCP STDIO

## Installation des nodes MCP

### Prérequis

- n8n installé et fonctionnel (version 0.214.0 ou supérieure)
- Serveur MCP accessible (HTTP ou Command Line)

### Installation manuelle

1. Copiez les dossiers `mcp-client` et `mcp-memory` dans le répertoire des nodes personnalisés de n8n :
   ```bash
   cp -r src/n8n/nodes/mcp-client ~/.n8n/custom/
   cp -r src/n8n/nodes/mcp-memory ~/.n8n/custom/
   ```

2. Redémarrez n8n pour charger les nouveaux nodes :
   ```bash
   n8n restart
   ```

### Installation via npm

1. Installez le package n8n-nodes-mcp :
   ```bash
   npm install n8n-nodes-mcp
   ```

2. Ajoutez le package à la configuration n8n :
   ```bash
   n8n config:set N8N_CUSTOM_EXTENSIONS=n8n-nodes-mcp
   ```

3. Redémarrez n8n :
   ```bash
   n8n restart
   ```

## Configuration des credentials

### Configuration HTTP

1. Dans n8n, allez dans **Paramètres** > **Credentials**
2. Cliquez sur **Créer**
3. Sélectionnez **MCP Client API**
4. Configurez les paramètres suivants :
   - **Nom** : Un nom descriptif (ex: "MCP API Production")
   - **Type de connexion** : HTTP
   - **URL de base** : L'URL de votre serveur MCP (ex: "http://localhost:3000")
   - **Clé API** : Votre clé API MCP

### Configuration Command Line

1. Dans n8n, allez dans **Paramètres** > **Credentials**
2. Cliquez sur **Créer**
3. Sélectionnez **MCP Client API**
4. Configurez les paramètres suivants :
   - **Nom** : Un nom descriptif (ex: "MCP CLI Local")
   - **Type de connexion** : Command Line
   - **Commande** : Chemin vers votre exécutable MCP (ex: "python" ou "node")
   - **Arguments** : Arguments à passer à la commande (ex: "mcp_server.py" ou "mcp-server.js")
   - **Variables d'environnement** : Variables d'environnement à définir (format: "CLE1=valeur1,CLE2=valeur2")

## Utilisation des nodes MCP

### MCP Client

Le node MCP Client permet d'interagir avec un serveur MCP pour obtenir du contexte ou exécuter des outils.

#### Opérations disponibles

- **Get Context** : Récupère du contexte à partir d'un prompt et de sources spécifiées
- **List Tools** : Liste les outils disponibles sur le serveur MCP
- **Execute Tool** : Exécute un outil spécifique avec des paramètres personnalisés

#### Exemple d'utilisation

1. Ajoutez un node MCP Client à votre workflow
2. Sélectionnez l'opération "Get Context"
3. Configurez les paramètres :
   - **Prompt** : "Générer un email pour {{$json.contact.name}}"
   - **Sources** : ["notion", "calendar", "memory"]
4. Connectez le node à un node Function pour traiter le contexte

### MCP Memory

Le node MCP Memory permet de gérer les mémoires dans MCP.

#### Opérations disponibles

- **Add Memory** : Ajoute une nouvelle mémoire
- **Get Memory** : Récupère une mémoire par son ID
- **Search Memories** : Recherche des mémoires par contenu ou métadonnées
- **Update Memory** : Met à jour une mémoire existante
- **Delete Memory** : Supprime une mémoire

#### Exemple d'utilisation

1. Ajoutez un node MCP Memory à votre workflow
2. Sélectionnez l'opération "Add Memory"
3. Configurez les paramètres :
   - **Content** : "{{$json.emailContent}}"
   - **Metadata** : `{"type": "email", "recipient": "{{$json.contact.email}}", "timestamp": "{{$now}}"}`
4. Connectez le node à un node HTTP Request ou Email pour envoyer l'email

## Workflows d'exemple

### Gestion des mémoires MCP

Ce workflow démontre les opérations CRUD de base sur les mémoires MCP :

1. Ajouter une nouvelle mémoire
2. Récupérer la mémoire par son ID
3. Mettre à jour la mémoire
4. Rechercher des mémoires similaires
5. Supprimer la mémoire

Le workflow est disponible dans `src/n8n/workflows/examples/mcp-memory-management.json`.

### Génération d'emails contextuels

Ce workflow utilise MCP pour générer des emails personnalisés basés sur le contexte :

1. Récupérer les données de contact depuis Notion
2. Obtenir du contexte depuis MCP
3. Formater l'email
4. Sauvegarder l'email dans les mémoires MCP
5. Envoyer l'email via Gmail

Le workflow est disponible dans `src/n8n/workflows/examples/mcp-email-generation.json`.

## Bonnes pratiques

- **Gestion des erreurs** : Ajoutez des nodes Error pour gérer les erreurs potentielles des nodes MCP
- **Mise en cache** : Pour les opérations fréquentes, utilisez un node Function pour mettre en cache les résultats
- **Sécurité** : Stockez les clés API dans les credentials n8n, jamais en dur dans les workflows
- **Performances** : Limitez la taille des données envoyées à MCP pour éviter les timeouts

## Dépannage

### Problèmes courants

1. **Erreur de connexion** : Vérifiez que votre serveur MCP est accessible et que les credentials sont corrects
2. **Timeout** : Augmentez le timeout dans les paramètres du node ou réduisez la taille des données
3. **Erreurs de format** : Assurez-vous que les données JSON sont valides

### Logs

Pour diagnostiquer les problèmes, consultez les logs n8n :

```bash
tail -f ~/.n8n/logs/n8n.log
```

## Ressources supplémentaires

- [Documentation MCP](../../mcp/docs/README.md)
- [Documentation n8n](https://docs.n8n.io/)
- [Exemples de workflows](../workflows/examples/)
