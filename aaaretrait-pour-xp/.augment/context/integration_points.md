# Points d'intégration du projet EMAIL_SENDER_1

Ce document détaille les différents points d'intégration du projet EMAIL_SENDER_1 avec des services externes, APIs et systèmes tiers.

## 1. Vue d'ensemble des intégrations

Le projet EMAIL_SENDER_1 s'intègre avec plusieurs services externes pour assurer ses fonctionnalités :

```plaintext
┌─────────────────────────────────────────────────────────────────┐
│                       EMAIL_SENDER_1                            │
└───────────┬─────────────┬────────────────┬──────────────────────┘
            │             │                │
            ▼             ▼                ▼
    ┌───────────────┐ ┌─────────┐  ┌────────────────┐
    │    Notion     │ │  Google │  │  OpenRouter/   │
    │  (Contacts)   │ │ Services│  │    DeepSeek    │
    └───────────────┘ └─────────┘  └────────────────┘
                         │  │
                         │  │
                         ▼  ▼
                    ┌──────────────┐
                    │   Gmail &    │
                    │   Calendar   │
                    └──────────────┘
```plaintext
## 2. Intégration avec Notion

### 2.1 Objectifs de l'intégration

- Gestion centralisée des contacts (programmateurs)
- Suivi des disponibilités des membres
- Gestion des lieux et salles de concert
- Tracking des interactions et statuts

### 2.2 Points d'intégration techniques

- **API Notion** : Accès programmatique aux bases de données
  - Endpoint : `https://api.notion.com/v1/`
  - Authentification : Token d'intégration Notion
  - Méthodes principales : `databases.query`, `pages.create`, `pages.update`

### 2.3 Structures de données

- **Base LOT1** : Contacts programmateurs
  - Propriétés : Nom, Email, Téléphone, Salle, Ville, Statut, Historique
- **Base Disponibilités** : Planning des membres
  - Propriétés : Membre, Date, Disponibilité, Notes
- **Base Lieux** : Salles de concert
  - Propriétés : Nom, Adresse, Capacité, Contact, Notes

### 2.4 Workflows d'intégration

- Synchronisation bidirectionnelle avec n8n
- Mise à jour automatique des statuts
- Notifications sur changements importants

### 2.5 Exemples d'utilisation

```javascript
// Exemple de requête pour récupérer les contacts depuis Notion
const response = await notion.databases.query({
  database_id: process.env.NOTION_DATABASE_ID,
  filter: {
    property: "Statut",
    select: {
      equals: "À contacter"
    }
  },
  sorts: [
    {
      property: "Priorité",
      direction: "ascending"
    }
  ]
});
```plaintext
## 3. Intégration avec Google Services

### 3.1 Google Calendar

#### 3.1.1 Objectifs de l'intégration

- Gestion des disponibilités des membres
- Planification des concerts et événements
- Synchronisation avec Notion

#### 3.1.2 Points d'intégration techniques

- **API Google Calendar** : Accès programmatique aux calendriers
  - Endpoint : `https://www.googleapis.com/calendar/v3/`
  - Authentification : OAuth 2.0 ou Service Account
  - Méthodes principales : `events.list`, `events.insert`, `events.update`

#### 3.1.3 Calendriers utilisés

- **BOOKING1** : Calendrier principal pour la gestion des disponibilités
- **Concerts** : Calendrier des événements confirmés
- **Répétitions** : Calendrier des sessions de répétition

### 3.2 Gmail

#### 3.2.1 Objectifs de l'intégration

- Envoi automatisé d'emails de prospection
- Réception et traitement des réponses
- Gestion des templates personnalisés

#### 3.2.2 Points d'intégration techniques

- **API Gmail** : Accès programmatique aux emails
  - Endpoint : `https://www.googleapis.com/gmail/v1/`
  - Authentification : OAuth 2.0
  - Méthodes principales : `messages.send`, `messages.list`, `messages.get`

#### 3.2.3 Templates et formats

- Templates HTML personnalisables
- Pièces jointes (dossier de presse, riders techniques)
- Signatures personnalisées par membre

## 4. Intégration avec les services IA

### 4.1 OpenRouter

#### 4.1.1 Objectifs de l'intégration

- Routage vers différents modèles IA
- Optimisation coût/performance
- Fallback en cas d'indisponibilité d'un modèle

#### 4.1.2 Points d'intégration techniques

- **API OpenRouter** : Accès aux modèles IA
  - Endpoint : `https://openrouter.ai/api/v1/`
  - Authentification : Clé API
  - Méthode principale : `chat/completions`

### 4.2 DeepSeek

#### 4.2.1 Objectifs de l'intégration

- Personnalisation avancée des messages
- Analyse des réponses reçues
- Classification des intentions

#### 4.2.2 Points d'intégration techniques

- **API DeepSeek** : Accès direct ou via OpenRouter
  - Modèles utilisés : DeepSeek-Coder, DeepSeek-Chat
  - Paramètres optimisés : température, top_p, max_tokens

### 4.3 Exemples d'utilisation

```javascript
// Exemple de requête pour personnaliser un email via OpenRouter
const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "Authorization": `Bearer ${process.env.OPENROUTER_API_KEY}`
  },
  body: JSON.stringify({
    model: "deepseek/deepseek-chat",
    messages: [
      {
        role: "system",
        content: "Tu es un assistant spécialisé dans la rédaction d'emails professionnels pour le booking de concerts."
      },
      {
        role: "user",
        content: `Personnalise ce template d'email pour ${contactName} de la salle ${venueName} : ${emailTemplate}`
      }
    ],
    temperature: 0.7,
    max_tokens: 1000
  })
});
```plaintext
## 5. Intégration avec MCP (Model Context Protocol)

### 5.1 Objectifs de l'intégration

- Fournir du contexte aux modèles IA
- Accéder aux données du projet de manière structurée
- Améliorer la pertinence des réponses IA

### 5.2 Serveurs MCP configurés

#### 5.2.1 server-filesystem

- Accès au système de fichiers local
- Configuration : chemin racine = répertoire du projet
- Utilisation : accès aux templates, configurations, logs

#### 5.2.2 server-github

- Accès aux repositories GitHub
- Configuration : token d'accès personnel pour l'authentification
- Utilisation : accès au code source, documentation, issues

#### 5.2.3 server-gcp

- Accès aux services Google Cloud Platform
- Configuration : credentials GCP
- Utilisation : accès aux données stockées dans GCP

### 5.3 Exemples d'utilisation

```javascript
// Exemple de requête MCP pour obtenir du contexte
const response = await fetch("http://localhost:8080/query", {
  method: "POST",
  headers: {
    "Content-Type": "application/json"
  },
  body: JSON.stringify({
    query: "Comment personnaliser un email pour un programmateur de salle de concert?",
    context_providers: ["filesystem", "github"],
    max_results: 5
  })
});
```plaintext
## 6. Futures intégrations planifiées

### 6.1 ERPNext

- Gestion des clients et facturation
- Suivi financier des événements
- Intégration prévue via API REST

### 6.2 Zapier/Make

- Intégration avec d'autres services sans API native
- Automatisation de tâches complémentaires
- Extension de l'écosystème d'intégration

### 6.3 Slack/Discord

- Notifications en temps réel
- Collaboration d'équipe
- Commandes et interactions via chatbots
