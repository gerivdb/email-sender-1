# Configuration du MCP Gateway dans n8n

Ce guide vous explique comment configurer le MCP Gateway dans n8n pour pouvoir l'utiliser dans vos workflows.

## Prérequis

- n8n installé et fonctionnel
- Les fichiers gateway.exe.cmd et gateway.yaml dans votre projet

## Étapes de configuration

### 1. Ouvrir n8n

Assurez-vous que n8n est démarré et ouvrez l'interface web.

### 2. Accéder aux identifiants

1. Cliquez sur l'icône d'engrenage (⚙️) dans le coin supérieur droit
2. Sélectionnez "Credentials" dans le menu déroulant

### 3. Créer un nouvel identifiant

1. Cliquez sur le bouton "New" ou "Create New Credential"
2. Dans la barre de recherche, tapez "MCP Client (STDIO) API"
3. Sélectionnez "MCP Client (STDIO) API" dans les résultats

### 4. Configurer l'identifiant

Remplissez les champs comme suit :

- **Credential Name**: MCP Gateway
- **Command**: Chemin complet vers gateway.exe.cmd
  - Exemple: `D:\\DO\\WEB\\N8N_tests\\scripts_ json_a_ tester\\EMAIL_SENDER_1\gateway.exe.cmd`
- **Arguments**: `start --config "D:\\DO\\WEB\\N8N_tests\\scripts_ json_a_ tester\\EMAIL_SENDER_1\gateway.yaml" mcp-stdio`
  - Remplacez le chemin par le chemin complet vers votre fichier gateway.yaml
- **Environments**: `N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true`

### 5. Enregistrer l'identifiant

Cliquez sur le bouton "Save" ou "Create" pour enregistrer l'identifiant.

## Utilisation dans un workflow

### 1. Créer un nouveau workflow

1. Cliquez sur "Workflows" dans le menu de gauche
2. Cliquez sur le bouton "+" pour créer un nouveau workflow

### 2. Ajouter un nœud MCP Client

1. Cliquez sur le bouton "+" pour ajouter un nouveau nœud
2. Recherchez "MCP Client" et sélectionnez-le

### 3. Configurer le nœud MCP Client

1. Dans la section "Credentials", sélectionnez l'identifiant "MCP Gateway" que vous avez créé
2. Dans la section "Operation", sélectionnez "List Tools" pour voir les outils disponibles
3. Cliquez sur "Execute Node" pour tester la connexion

### 4. Utiliser les outils Gateway

1. Changez l'opération en "Execute Tool"
2. Dans le champ "Tool Name", entrez l'un des outils disponibles (par exemple, "get_customers")
3. Dans le champ "Parameters", entrez les paramètres au format JSON (par exemple, `{"limit": 10, "offset": 0}`)
4. Cliquez sur "Execute Node" pour tester l'outil

## Dépannage

Si vous rencontrez des problèmes :

1. Vérifiez que les chemins vers gateway.exe.cmd et gateway.yaml sont corrects et utilisent des chemins absolus
2. Assurez-vous que la variable d'environnement `N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE` est définie sur "true"
3. Redémarrez n8n après avoir effectué des modifications
4. Vérifiez les logs de n8n pour voir les erreurs éventuelles

## Exemple de workflow

Voici un exemple de workflow simple qui utilise le MCP Gateway :

1. **Déclencheur manuel** : Démarrer le workflow manuellement
2. **MCP Client (List Tools)** : Lister les outils disponibles
3. **MCP Client (Execute Tool)** : Exécuter l'outil "get_customers"
4. **Set** : Formater les résultats
5. **Respond to Webhook** : Afficher les résultats

Ce workflow récupère la liste des clients et affiche les résultats.

