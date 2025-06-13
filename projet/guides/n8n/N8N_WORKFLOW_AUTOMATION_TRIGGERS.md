# Automatisation de Workflow et Déclencheurs dans n8n

Ce document détaille les différents types de déclencheurs disponibles dans n8n pour démarrer vos workflows automatisés.

## Déclencheur Cron (Planification)

Le nœud Cron (également appelé Schedule Trigger) démarre les workflows selon des planifications temporelles. Vous pouvez le configurer pour s'exécuter à des heures fixes (tous les jours à X, toutes les semaines à Y, etc.) ou à intervalles réguliers.

### Exemple : Exécution quotidienne à 9h00 et 17h00

```json
{
  "name": "Daily Schedule",
  "type": "n8n-nodes-base.cron",
  "typeVersion": 1,
  "parameters": {
    "triggerTimes": {
      "item": [
        { "hour": 9, "minute": 0 },
        { "hour": 17, "minute": 0 }
      ]
    }
  }
}
```plaintext
**Explication :** Cette configuration définit deux heures de déclenchement (Cron gère les deux). Le premier objet est 9h00, le second est 17h00 (5 PM). Par défaut, si vous spécifiez uniquement l'heure/minute, il s'exécute tous les jours à cette heure.

Vous pouvez ajouter `"weekday": ["Monday","Tuesday",...]` ou `"dayOfMonth": [...]` pour affiner la planification.

Alternativement, Cron peut être configuré en modes simples :
- `"mode": "everyMinute"` 
- `"mode": "everyX"` avec une valeur et une unité

Par exemple, pour déclencher toutes les 15 minutes :
```json
{"item": [ { "mode": "everyX", "value": 15, "unit": "minutes" } ] }
```plaintext
Les déclencheurs Cron sont parfaits pour les rapports quotidiens, les synchronisations de données de routine, etc. Ce nœud n'a pas d'entrée ; il se déclenche simplement selon la planification et transmet un élément vide pour démarrer le workflow.

## Déclencheur Email (IMAP)

Le nœud Email Trigger surveille une boîte de réception IMAP pour les nouveaux emails. La configuration inclut le serveur, les identifiants email, les critères de recherche, etc.

### Exemple (avec des valeurs génériques)

```json
{
  "name": "Email Trigger",
  "type": "n8n-nodes-base.emailReadImap",
  "typeVersion": 1,
  "parameters": {
    "mailbox": "INBOX",
    "postProcessAction": "read",
    "options": {
      "criteria": "UNSEEN"
    }
  },
  "credentials": {
    "imap": {
      "name": "My Email Account"
    }
  }
}
```plaintext
**Explication :** Ce nœud vérifie la boîte de réception (INBOX) du compte email configuré pour les messages non lus et les marque comme lus (`postProcessAction: "read"`). Pour chaque nouvel email, il déclenche le workflow avec le contenu de l'email.

Utilisez ce déclencheur pour des automatisations comme l'analyse des emails de support entrants ou les notifications de prospects. Vous pouvez le combiner avec un nœud IF pour filtrer les emails par sujet, etc., puis les acheminer (par exemple, créer des tickets, envoyer des alertes, etc.).

## Déclencheur Manuel

Le déclencheur Manuel est simplement un nœud pour démarrer le workflow en cliquant sur "Execute Workflow" dans l'éditeur. Il n'a pas de paramètres dans le JSON au-delà des valeurs par défaut.

### Exemple

```json
{
  "name": "Manual Trigger",
  "type": "n8n-nodes-base.manualTrigger",
  "typeVersion": 1,
  "parameters": {}
}
```plaintext
**Explication :** Vous n'incluriez généralement pas ce nœud dans un JSON de workflow exporté si vous prévoyez de l'exécuter automatiquement, mais il est utile pendant le développement. Il produit un élément vide pour démarrer le flux.

## Déclencheur de Workflow (Execute Workflow)

n8n permet à un workflow d'en appeler un autre. Il existe deux nœuds pour cela :
- **Execute Workflow** (dans le workflow appelant)
- **Workflow Trigger** (dans le workflow appelé)

Dans le sous-workflow qui est appelé, vous utilisez un nœud Workflow Trigger pour recevoir l'appel (agit essentiellement comme un Webhook mais en interne). Dans le workflow parent, vous utilisez Execute Workflow pour invoquer.

### Exemple : Nœud Execute Workflow qui appelle un sous-workflow par ID et attend le résultat

```json
{
  "name": "Run Sub-workflow",
  "type": "n8n-nodes-base.executeWorkflow",
  "typeVersion": 1,
  "parameters": {
    "workflowId": "123",
    "waitForCompletion": true,
    "inputs": {
      "inputData": "={{ $json[\"data\"] }}"
    }
  }
}
```plaintext
**Explication :** Ce nœud exécutera le workflow avec l'ID 123 (vous pouvez trouver l'ID d'un workflow dans son URL ou sa liste). Il transmet un champ d'entrée `inputData` au sous-workflow (le nœud Workflow Trigger du sous-workflow doit être configuré pour accepter ce champ).

Si `waitForCompletion` est `true`, le workflow parent se met en pause jusqu'à ce que le sous-workflow se termine, puis reprend avec la sortie que le sous-workflow a retournée. Si `false`, il déclenche l'autre workflow et continue immédiatement (mode fire-and-forget).

Utilisez cette fonctionnalité pour réutiliser des routines communes entre les workflows ou pour diviser des processus complexes. Par exemple, vous pourriez avoir un sous-workflow qui prend des données et les écrit dans Google Sheets, que vous pouvez appeler depuis plusieurs autres workflows au lieu de dupliquer ces nœuds.

**Note :** Assurez-vous que le sous-workflow a un nœud Workflow Trigger (qui dans le JSON serait simplement `"type": "n8n-nodes-base.workflowTrigger"` avec tout schéma d'entrée défini). Les sorties du sous-workflow deviennent la sortie du nœud Execute Workflow.

## Hooks Externes (n8n Trigger)

Il existe également un nœud n8n Trigger qui peut se déclencher lorsque certains événements se produisent dans n8n (comme lorsqu'un workflow est activé, ou qu'un utilisateur le déclenche via API).

Pour la plupart des utilisateurs, ce nœud est moins couramment utilisé, mais il est bon de savoir qu'il existe pour l'orchestration avancée.

## Autres Déclencheurs Spécialisés

n8n propose de nombreux autres déclencheurs spécialisés pour différents services :

### Déclencheurs de Webhook

- **Webhook** : Crée un point de terminaison HTTP qui déclenche le workflow lorsqu'il reçoit une requête
- **Webhook Personnalisé** : Version plus avancée avec des options de routage et d'authentification

### Déclencheurs de Base de Données

- **PostgreSQL Trigger** : Surveille les changements dans une base de données PostgreSQL
- **MongoDB Trigger** : Réagit aux changements dans une collection MongoDB

### Déclencheurs de Services Cloud

- **AWS S3** : Déclenche sur les événements de bucket S3 (nouveaux fichiers, suppressions, etc.)
- **Google Drive** : Surveille les changements dans les dossiers ou fichiers
- **Dropbox** : Réagit aux modifications de fichiers

### Déclencheurs de Médias Sociaux

- **Twitter** : Déclenche sur les nouveaux tweets correspondant à certains critères
- **Telegram** : Réagit aux nouveaux messages dans un bot Telegram
- **Slack** : Déclenche sur les événements Slack (messages, réactions, etc.)

## Bonnes Pratiques pour les Déclencheurs

1. **Fréquence appropriée** : Pour les déclencheurs Cron, choisissez une fréquence qui équilibre la fraîcheur des données avec la charge sur le système
2. **Gestion des erreurs** : Configurez des notifications en cas d'échec des workflows déclenchés automatiquement
3. **Déduplication** : Pour les déclencheurs qui peuvent recevoir des événements en double (comme les webhooks), implémentez une logique de déduplication
4. **Sécurité** : Pour les déclencheurs exposés publiquement (webhooks), utilisez l'authentification ou des jetons secrets
5. **Tests** : Testez vos déclencheurs avec des données réalistes avant de les mettre en production
