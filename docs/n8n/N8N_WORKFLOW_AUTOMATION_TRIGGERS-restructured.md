# Automatisation de Workflow et Déclencheurs dans n8n

## Table des matières

1. [Automatisation de Workflow et Déclencheurs dans n8n](#section-1)
    1.1. [Déclencheur Cron (Planification)](#section-2)
        1.1.1. [Exemple : Exécution quotidienne à 9h00 et 17h00](#section-3)
    1.2. [Déclencheur Email (IMAP)](#section-4)
        1.2.1. [Exemple (avec des valeurs génériques)](#section-5)
    1.3. [Déclencheur Manuel](#section-6)
        1.3.1. [Exemple](#section-7)
    1.4. [Déclencheur de Workflow (Execute Workflow)](#section-8)
        1.4.1. [Exemple : Nœud Execute Workflow qui appelle un sous-workflow par ID et attend le résultat](#section-9)
    1.5. [Hooks Externes (n8n Trigger)](#section-10)
    1.6. [Autres Déclencheurs Spécialisés](#section-11)
        1.6.1. [Déclencheurs de Webhook](#section-12)
        1.6.2. [Déclencheurs de Base de Données](#section-13)
        1.6.3. [Déclencheurs de Services Cloud](#section-14)
        1.6.4. [Déclencheurs de Médias Sociaux](#section-15)
    1.7. [Bonnes Pratiques pour les Déclencheurs](#section-16)

## 1. Automatisation de Workflow et Déclencheurs dans n8n <a name='section-1'></a>

Ce document détaille les différents types de déclencheurs disponibles dans n8n pour démarrer vos workflows automatisés.

### 1.1. Déclencheur Cron (Planification) <a name='section-2'></a>

Le nœud Cron (également appelé Schedule Trigger) démarre les workflows selon des planifications temporelles. Vous pouvez le configurer pour s'exécuter à des heures fixes (tous les jours à X, toutes les semaines à Y, etc.) ou à intervalles réguliers.

#### 1.1.1. Exemple : Exécution quotidienne à 9h00 et 17h00 <a name='section-3'></a>

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
```

**Explication :** Cette configuration définit deux heures de déclenchement (Cron gère les deux). Le premier objet est 9h00, le second est 17h00 (5 PM). Par défaut, si vous spécifiez uniquement l'heure/minute, il s'exécute tous les jours à cette heure.

Vous pouvez ajouter `"weekday": ["Monday","Tuesday",...]` ou `"dayOfMonth": [...]` pour affiner la planification.

Alternativement, Cron peut être configuré en modes simples :
- `"mode": "everyMinute"` 
- `"mode": "everyX"` avec une valeur et une unité

Par exemple, pour déclencher toutes les 15 minutes :
{"item": [ { "mode": "everyX", "value": 15, "unit": "minutes" } ] }

Les déclencheurs Cron sont parfaits pour les rapports quotidiens, les synchronisations de données de routine, etc. Ce nœud n'a pas d'entrée ; il se déclenche simplement selon la planification et transmet un élément vide pour démarrer le workflow.

### 1.2. Déclencheur Email (IMAP) <a name='section-4'></a>

Le nœud Email Trigger surveille une boîte de réception IMAP pour les nouveaux emails. La configuration inclut le serveur, les identifiants email, les critères de recherche, etc.

#### 1.2.1. Exemple (avec des valeurs génériques) <a name='section-5'></a>

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
```

**Explication :** Ce nœud vérifie la boîte de réception (INBOX) du compte email configuré pour les messages non lus et les marque comme lus (`postProcessAction: "read"`). Pour chaque nouvel email, il déclenche le workflow avec le contenu de l'email.

Utilisez ce déclencheur pour des automatisations comme l'analyse des emails de support entrants ou les notifications de prospects. Vous pouvez le combiner avec un nœud IF pour filtrer les emails par sujet, etc., puis les acheminer (par exemple, créer des tickets, envoyer des alertes, etc.).

### 1.3. Déclencheur Manuel <a name='section-6'></a>

Le déclencheur Manuel est simplement un nœud pour démarrer le workflow en cliquant sur "Execute Workflow" dans l'éditeur. Il n'a pas de paramètres dans le JSON au-delà des valeurs par défaut.

#### 1.3.1. Exemple <a name='section-7'></a>

```json
{
  "name": "Manual Trigger",
  "type": "n8n-nodes-base.manualTrigger",
  "typeVersion": 1,
  "parameters": {}
}
```

**Explication :** Vous n'incluriez généralement pas ce nœud dans un JSON de workflow exporté si vous prévoyez de l'exécuter automatiquement, mais il est utile pendant le développement. Il produit un élément vide pour démarrer le flux.

### 1.4. Déclencheur de Workflow (Execute Workflow) <a name='section-8'></a>

n8n permet à un workflow d'en appeler un autre. Il existe deux nœuds pour cela :
- **Execute Workflow** (dans le workflow appelant)
- **Workflow Trigger** (dans le workflow appelé)

Dans le sous-workflow qui est appelé, vous utilisez un nœud Workflow Trigger pour recevoir l'appel (agit essentiellement comme un Webhook mais en interne). Dans le workflow parent, vous utilisez Execute Workflow pour invoquer.

#### 1.4.1. Exemple : Nœud Execute Workflow qui appelle un sous-workflow par ID et attend le résultat <a name='section-9'></a>

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
```

**Explication :** Ce nœud exécutera le workflow avec l'ID 123 (vous pouvez trouver l'ID d'un workflow dans son URL ou sa liste). Il transmet un champ d'entrée `inputData` au sous-workflow (le nœud Workflow Trigger du sous-workflow doit être configuré pour accepter ce champ).

Si `waitForCompletion` est `true`, le workflow parent se met en pause jusqu'à ce que le sous-workflow se termine, puis reprend avec la sortie que le sous-workflow a retournée. Si `false`, il déclenche l'autre workflow et continue immédiatement (mode fire-and-forget).

Utilisez cette fonctionnalité pour réutiliser des routines communes entre les workflows ou pour diviser des processus complexes. Par exemple, vous pourriez avoir un sous-workflow qui prend des données et les écrit dans Google Sheets, que vous pouvez appeler depuis plusieurs autres workflows au lieu de dupliquer ces nœuds.

**Note :** Assurez-vous que le sous-workflow a un nœud Workflow Trigger (qui dans le JSON serait simplement `"type": "n8n-nodes-base.workflowTrigger"` avec tout schéma d'entrée défini). Les sorties du sous-workflow deviennent la sortie du nœud Execute Workflow.

### 1.5. Hooks Externes (n8n Trigger) <a name='section-10'></a>

Il existe également un nœud n8n Trigger qui peut se déclencher lorsque certains événements se produisent dans n8n (comme lorsqu'un workflow est activé, ou qu'un utilisateur le déclenche via API).

Pour la plupart des utilisateurs, ce nœud est moins couramment utilisé, mais il est bon de savoir qu'il existe pour l'orchestration avancée.

### 1.6. Autres Déclencheurs Spécialisés <a name='section-11'></a>

n8n propose de nombreux autres déclencheurs spécialisés pour différents services :

#### 1.6.1. Déclencheurs de Webhook <a name='section-12'></a>

- **Webhook** : Crée un point de terminaison HTTP qui déclenche le workflow lorsqu'il reçoit une requête
- **Webhook Personnalisé** : Version plus avancée avec des options de routage et d'authentification

#### 1.6.2. Déclencheurs de Base de Données <a name='section-13'></a>

- **PostgreSQL Trigger** : Surveille les changements dans une base de données PostgreSQL
- **MongoDB Trigger** : Réagit aux changements dans une collection MongoDB

#### 1.6.3. Déclencheurs de Services Cloud <a name='section-14'></a>

- **AWS S3** : Déclenche sur les événements de bucket S3 (nouveaux fichiers, suppressions, etc.)
- **Google Drive** : Surveille les changements dans les dossiers ou fichiers
- **Dropbox** : Réagit aux modifications de fichiers

#### 1.6.4. Déclencheurs de Médias Sociaux <a name='section-15'></a>

- **Twitter** : Déclenche sur les nouveaux tweets correspondant à certains critères
- **Telegram** : Réagit aux nouveaux messages dans un bot Telegram
- **Slack** : Déclenche sur les événements Slack (messages, réactions, etc.)

### 1.7. Bonnes Pratiques pour les Déclencheurs <a name='section-16'></a>

1. **Fréquence appropriée** : Pour les déclencheurs Cron, choisissez une fréquence qui équilibre la fraîcheur des données avec la charge sur le système
2. **Gestion des erreurs** : Configurez des notifications en cas d'échec des workflows déclenchés automatiquement
3. **Déduplication** : Pour les déclencheurs qui peuvent recevoir des événements en double (comme les webhooks), implémentez une logique de déduplication
4. **Sécurité** : Pour les déclencheurs exposés publiquement (webhooks), utilisez l'authentification ou des jetons secrets
5. **Tests** : Testez vos déclencheurs avec des données réalistes avant de les mettre en production

