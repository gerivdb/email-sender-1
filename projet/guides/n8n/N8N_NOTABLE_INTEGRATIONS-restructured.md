# Intégrations Notables dans n8n (Applications et Services)

## Table des matières

1. [Intégrations Notables dans n8n (Applications et Services)](#section-1)
    1.1. [Nœud Slack (Envoi de Message)](#section-2)
        1.1.1. [Exemple : Publier un message dans un canal](#section-3)
    1.2. [Nœud Google Sheets](#section-4)
        1.2.1. [Exemple : Ajouter une nouvelle ligne de données à une feuille](#section-5)
    1.3. [Nœud Notion](#section-6)
        1.3.1. [Exemple : Interroger une base de données Notion pour les pages correspondant à un filtre](#section-7)
    1.4. [Nœud GitHub](#section-8)
        1.4.1. [Exemple : Créer un nouveau problème dans un dépôt GitHub](#section-9)
    1.5. [Nœuds de Base de Données (MySQL, Postgres, etc.)](#section-10)
        1.5.1. [Exemple : Utilisation du nœud MySQL pour exécuter une requête](#section-11)
    1.6. [Autres Intégrations](#section-12)
        1.6.1. [Expressions](#section-13)
        1.6.2. [Identifiants](#section-14)
        1.6.3. [IDs et Position des Nœuds](#section-15)
        1.6.4. [Connexion des Nœuds](#section-16)
        1.6.5. [Test et Itération](#section-17)

## 1. Intégrations Notables dans n8n (Applications et Services) <a name='section-1'></a>

Ce document présente des exemples d'utilisation JSON pour les nœuds de services tiers populaires dans n8n. Chacun de ces nœuds nécessite des identifiants appropriés (configurés dans les Credentials de n8n et référencés par nom ou ID dans le JSON). Les champs exacts dépendent de l'API du service.

### 1.1. Nœud Slack (Envoi de Message) <a name='section-2'></a>

Le nœud Slack vous permet de publier des messages, d'obtenir des informations sur les canaux, de gérer des fichiers, etc., via l'API de Slack. Une opération courante est l'envoi d'un message à un canal.

#### 1.1.1. Exemple : Publier un message dans un canal <a name='section-3'></a>

```json
{
  "name": "Send Slack Message",
  "type": "n8n-nodes-base.slack",
  "typeVersion": 1,
  "parameters": {
    "resource": "message",
    "operation": "send",
    "channel": "C01234567",
    "text": "Hello from n8n :tada:"
  },
  "credentials": {
    "slackApi": {
      "name": "Slack OAuth2"
    }
```

**Explication :** Cela enverra le texte "Hello from n8n 🎉" au canal Slack spécifié. Nous avons choisi `resource: "message"` et `operation: "send"`. Les nœuds Slack ont souvent plusieurs ressources comme message, channel, etc. Le canal peut être l'ID du canal Slack ou son nom (si vous utilisez le nom, assurez-vous que l'identifiant a les autorisations appropriées pour le trouver).

Les credentials pointent vers un identifiant OAuth2 Slack (avec des autorisations comme chat:write, etc. selon les besoins). Si vous souhaitez utiliser des blocs ou des pièces jointes, le nœud Slack permet un mode JSON pour ces champs (`jsonParameters: true` et fournir un objet JSON pour attachments ou blocks).

La sortie de ce nœud inclura généralement l'ID du message Slack et l'horodatage en cas de succès. Vous pouvez également utiliser le nœud Slack Trigger pour écouter les événements Slack si vous configurez un webhook d'application Slack – utile pour les workflows réactifs (par exemple, répondre lorsqu'un message est publié).

### 1.2. Nœud Google Sheets <a name='section-4'></a>

Ce nœud s'intègre à Google Sheets pour lire ou écrire des données de feuille de calcul. Les opérations incluent : Lire des lignes, Ajouter une ligne, Mettre à jour une ligne, Supprimer une ligne, Rechercher, etc. Vous devez avoir configuré des identifiants Google Sheets (OAuth2).

#### 1.2.1. Exemple : Ajouter une nouvelle ligne de données à une feuille <a name='section-5'></a>

```json
{
  "name": "Append to Sheet",
  "type": "n8n-nodes-base.googleSheets",
  "typeVersion": 4,
  "parameters": {
    "operation": "append",
    "spreadsheetId": "1A2b3C4D5E6FgHiJkLMnoPQrstu",
    "sheetName": "Sheet1",
    "dataMode": "autoMap",
    "options": {
      "valueInputMode": "USER_ENTERED"
    }
  },
  "credentials": {
    "googleSheetsOAuth2Api": {
      "name": "Google Sheets OAuth2"
```

**Explication :** Cette configuration est configurée pour ajouter une nouvelle ligne à la feuille nommée "Sheet1" dans le document Google Sheets avec l'ID donné. Nous avons utilisé `dataMode: "autoMap"`, ce qui signifie que le nœud mappera automatiquement les champs entrants aux colonnes avec le même nom d'en-tête.

Par exemple, si les éléments entrants ont un JSON comme `{ "Name": "Alice", "Email": "alice@example.com" }`, et que la feuille Google a des colonnes "Name" et "Email", ces valeurs seront placées en conséquence.

`valueInputMode: "USER_ENTERED"` indique à Google Sheets de traiter l'entrée comme si un utilisateur l'avait tapée (donc les formules dans les cellules seront recalculées, etc.). Si vous vouliez mapper explicitement des champs, vous pourriez utiliser `dataMode: "define"` et fournir une liste de champs à envoyer.

Pour la lecture de données, le Get Many (ou `operation: "getAll"`) nécessiterait une plage (par exemple, "Sheet1!A:D") et renvoie un tableau de lignes. Le nœud Google Sheets est puissant à la fois pour exporter des données de n8n vers des feuilles de calcul et pour importer des données de feuilles de calcul dans n8n pour un traitement ultérieur.

### 1.3. Nœud Notion <a name='section-6'></a>

Le nœud Notion se connecte à l'API de Notion, vous permettant de créer ou de mettre à jour des pages dans une base de données, de récupérer des éléments de base de données ou d'ajouter du contenu aux pages.

#### 1.3.1. Exemple : Interroger une base de données Notion pour les pages correspondant à un filtre <a name='section-7'></a>

```json
{
  "name": "Query Notion DB",
  "type": "n8n-nodes-base.notion",
  "typeVersion": 2,
  "parameters": {
    "resource": "databasePage",
    "operation": "getAll",
    "databaseId": "YOUR_NOTION_DATABASE_ID",
    "options": {
      "filter": {
        "singleCondition": {
          "key": "Email|email",
          "condition": "equals",
          "emailValue": "={{ $json[\"email\"] }}"
        }
  },
  "credentials": {
    "notionApi": {
      "name": "Notion API"
```

**Explication :** Cela récupérera toutes les pages de la base de données Notion spécifiée où la propriété Email est égale à la valeur `$json["email"]` du nœud précédent. Dans l'API de Notion, les filtres peuvent être complexes ; ici, nous avons utilisé un filtre à condition unique sur une propriété Email.

La clé est formatée comme `PropertyName|propertyType` dans le nœud (le nœud Notion a besoin du type de propriété pour formater correctement le filtre, d'où "Email|email"). Le nœud Notion prend en charge la création de pages (vous spécifieriez les propriétés à définir), la mise à jour de pages, la recherche, etc.

Pour un exemple de création, vous utiliseriez `operation: "create"` avec un `pageId` (si vous ajoutez à une page) ou `databaseId` (si vous ajoutez à une base de données) et fourniriez l'objet properties. Par exemple, pour une base de données :
properties: { 
  "Name": {"title": [{"text": {"content": "New Item"}}]}, 
  "Status": {"select": {"name": "Done"}} 

La structure suit le JSON de l'API Notion. Le nœud simplifie une partie de cela, mais souvent vous utilisez l'approche No Code pour définir les champs via l'interface utilisateur. Lorsque vous travaillez par programmation, il est utile de se référer à la documentation de l'API Notion pour le JSON exact des propriétés.

La sortie d'un nœud Notion sera la représentation JSON de la page Notion ou des entrées de base de données récupérées. Utilisez cette intégration pour automatiser l'ajout de notes de réunion, la mise à jour des statuts de tâches ou la génération de tableaux de bord dans Notion.

### 1.4. Nœud GitHub <a name='section-8'></a>

Ce nœud permet des interactions avec GitHub, comme la création de problèmes, la récupération de commits, la gestion de dépôts, etc.

#### 1.4.1. Exemple : Créer un nouveau problème dans un dépôt GitHub <a name='section-9'></a>

```json
{
  "name": "Create GitHub Issue",
  "type": "n8n-nodes-base.github",
  "typeVersion": 1,
  "parameters": {
    "resource": "issue",
    "operation": "create",
    "owner": "octocat",
    "repository": "Hello-World",
    "title": "Automated Issue from n8n",
    "body": "This issue was created by an n8n workflow."
  },
  "credentials": {
    "githubApi": {
      "name": "GitHub personal access token"
    }
```

**Explication :** Ce nœud utilise le nœud GitHub pour créer un problème dans le dépôt octocat/Hello-World. L'identifiant githubApi doit être un Personal Access Token avec des autorisations repo (ou un jeton d'application OAuth). Le nœud pourrait également mettre à jour ou lire des problèmes (différentes opérations), lister les commits (`resource: "repository", operation: "getCommits"` par exemple), gérer les pull requests, etc.

La sortie pour les opérations de création contient généralement les données de l'objet créé (détails du problème, y compris son numéro, URL, etc.). C'est utile pour l'automatisation comme la journalisation des erreurs ou des TODOs en tant que problèmes GitHub, ou la publication de notes de déploiement dans un dépôt.

### 1.5. Nœuds de Base de Données (MySQL, Postgres, etc.) <a name='section-10'></a>

n8n inclut des nœuds pour les bases de données populaires comme MySQL, PostgreSQL, MSSQL, etc. Ces nœuds vous permettent d'exécuter des requêtes ou des opérations (select/insert/update).

#### 1.5.1. Exemple : Utilisation du nœud MySQL pour exécuter une requête <a name='section-11'></a>

```json
{
  "name": "MySQL Query",
  "type": "n8n-nodes-base.mySql",
  "typeVersion": 2,
  "parameters": {
    "operation": "executeQuery",
    "query": "SELECT * FROM users WHERE id = {{ $json[\"user_id\"] }}",
    "additionalFields": {}
  },
  "credentials": {
    "mySql": {
      "name": "My MySQL DB"
    }
```

**Explication :** Cela exécutera la requête SQL donnée sur la base de données MySQL connectée (en utilisant les identifiants nommés "My MySQL DB"). Nous avons utilisé une expression pour injecter un user_id entrant dans la requête. Le résultat sera retourné sous forme d'éléments (chaque ligne comme un élément avec des colonnes comme champs).

Vous pourriez également utiliser `operation: insert` et spécifier la table et les données de colonne de manière structurée, mais souvent le SQL brut (avec executeQuery ou execute) est le plus simple pour les opérations complexes. Assurez-vous que vos requêtes sont sécurisées (si vous utilisez des expressions, assurez-vous qu'elles sont assainies ou ne proviennent pas directement de l'entrée utilisateur pour éviter l'injection SQL).

Pour PostgreSQL, le nœud est similaire (le type est simplement postgres et le type d'identifiants est postgreSql). Ces nœuds vous permettent d'intégrer votre workflow avec des bases de données existantes pour lire ou écrire des données, faisant essentiellement de n8n une partie de votre pipeline de données.

### 1.6. Autres Intégrations <a name='section-12'></a>

n8n dispose de plus de 500 nœuds pour divers services. Voici quelques autres nœuds notables :

- **AWS S3** (et autres services AWS via des nœuds dédiés) : par exemple, le nœud S3 peut télécharger ou téléverser des fichiers.
- **Google Drive** : pour les opérations de fichiers (téléverser, télécharger, lister les fichiers).
- **Email Send (SMTP)** : pour envoyer des emails via SMTP ou des services comme SendGrid.
- **Twilio** : envoyer des SMS ou des messages WhatsApp via Twilio.
- **Stripe** : créer des clients, traiter des paiements ou réagir aux événements Stripe (Stripe Trigger).
- **Webhook (spécifique au service)** : De nombreux services ont des nœuds de déclenchement (par exemple, Stripe Trigger, GitHub Trigger, Slack Trigger) qui écoutent les webhooks entrants de ces services sans que vous ayez à configurer manuellement le nœud Webhook.
- **Jira, Trello, Asana** : nœuds de gestion de projet pour créer/mettre à jour des tâches.
- **HubSpot, Salesforce** : nœuds CRM pour gérer les contacts, les affaires, etc.
- **CSV & XML** : nœuds pour analyser ou écrire CSV/XML, utiles lors de la manipulation de données de fichiers.
- **HTTP Webhook (sortant)** : Si vous devez appeler un webhook externe, utilisez simplement le nœud HTTP (comme indiqué) ou l'intégration spécifique si disponible.

Pour tout nœud de service spécifique, le modèle est : resource (quelle entité vous traitez), operation (action à effectuer), puis les champs pour cette opération (correspondant souvent étroitement aux champs de l'API du service). La meilleure façon de les construire est souvent de configurer le nœud dans l'éditeur de n8n, puis de copier le JSON (via l'exportation du workflow) comme référence.

#### 1.6.1. Expressions <a name='section-13'></a>

Dans les exemples JSON ci-dessus, vous voyez beaucoup de `={{ $json["..."] }}`. Ce sont des expressions n8n qui extraient des données des nœuds précédents. Dans le code, assurez-vous qu'elles sont enveloppées dans des accolades doubles à l'intérieur de la chaîne JSON. À l'exécution, n8n les évalue. Vous pouvez également utiliser `$node["NodeName"].json["field"]` pour référencer la sortie d'un nœud spécifique, ou `$items()` pour référencer plusieurs éléments.

#### 1.6.2. Identifiants <a name='section-14'></a>

La section "credentials" dans le JSON de chaque nœud renvoie aux identifiants stockés. Dans les exportations, ils peuvent apparaître comme `{ "id": "some-id", "name": "Credential Name" }` ou simplement le nom. Lors de la création programmatique de workflows via l'API, vous pourriez n'avoir besoin que de définir le nom de l'identifiant (s'il est unique) ou l'ID. Assurez-vous toujours que l'identifiant existe dans n8n au préalable.

#### 1.6.3. IDs et Position des Nœuds <a name='section-15'></a>

Vous pourriez remarquer `id` et `position` dans les exemples d'exportations. Ceux-ci ne sont pas nécessaires lors de l'écriture d'une fiche de référence, mais dans le JSON de workflow réel, ils placent le nœud dans l'éditeur. Ils peuvent être omis si l'on se concentre uniquement sur la configuration fonctionnelle des nœuds.

#### 1.6.4. Connexion des Nœuds <a name='section-16'></a>

Dans le JSON du workflow, il y a un objet "connections" qui relie les sorties des nœuds aux entrées. Dans cette fiche, nous montrons des nœuds individuels. Lors de la construction d'un workflow par programmation, vous devrez construire cet objet connections. Par exemple, pour connecter Cron -> GraphQL -> Function -> Slack comme dans notre exemple de rappel Slack, le JSON avait :

```json
"connections": {
  "Cron": { "main": [ [ { "node": "GraphQL", "type": "main", "index": 0 } ] ] },
  "GraphQL": { "main": [ [ { "node": "Summarize", "type": "main", "index": 0 } ] ] },
  "Summarize": { "main": [ [ { "node": "Slack", "type": "main", "index": 0 } ] ] }
}
```

Cela indique que la sortie de Cron se connecte à l'entrée de GraphQL, etc. Si vous créez des workflows via l'API, vous formulerez une structure similaire.

#### 1.6.5. Test et Itération <a name='section-17'></a>

Commencez par des nœuds simples (Manual Trigger -> un nœud -> sortie) pour vous assurer que votre JSON est correct, puis développez. Vous pouvez importer du JSON dans n8n via Workflow -> Import from JSON pour le vérifier visuellement.

