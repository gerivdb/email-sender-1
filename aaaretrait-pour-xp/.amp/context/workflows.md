# Workflows n8n du projet EMAIL_SENDER_1

Ce document détaille les workflows n8n utilisés dans le projet EMAIL_SENDER_1, leur structure, fonctionnement et interactions.

## 1. Vue d'ensemble des workflows

Le projet EMAIL_SENDER_1 s'articule autour de quatre workflows n8n principaux, chacun responsable d'une phase spécifique du processus de booking :

```plaintext
┌─────────────────────┐     ┌─────────────────────┐     ┌─────────────────────┐
│  Email Sender -     │────▶│  Email Sender -     │────▶│  Email Sender -     │
│     Phase 1         │     │     Phase 2         │     │     Phase 3         │
│  (Prospection)      │     │     (Suivi)         │     │   (Traitement)      │
└─────────────────────┘     └─────────────────────┘     └─────────────────────┘
           ▲                           ▲                           ▲
           │                           │                           │
           └───────────────┬───────────┴───────────────┬───────────┘
                           │                           │
                           ▼                           ▼
                  ┌─────────────────────┐    ┌─────────────────────┐
                  │  Email Sender -     │    │  Services IA        │
                  │     Config          │    │  (OpenRouter/       │
                  │                     │    │   DeepSeek)         │
                  └─────────────────────┘    └─────────────────────┘
```plaintext
## 2. Email Sender - Phase 1 (Prospection initiale)

### 2.1 Objectif

Automatiser l'envoi d'emails de prospection initiale aux programmateurs de salles de concert.

### 2.2 Structure du workflow

- **Déclencheur** : Planification temporelle ou déclenchement manuel
- **Récupération des données** : Extraction des contacts depuis Notion
- **Filtrage** : Sélection des contacts pertinents selon critères
- **Personnalisation** : Génération de contenu personnalisé via IA
- **Envoi** : Transmission des emails via Gmail API
- **Suivi** : Enregistrement des actions dans Notion

### 2.3 Nœuds principaux

- Schedule Trigger / Manual Trigger
- Notion (Get Database Items)
- Function (Filtering)
- HTTP Request (OpenRouter API)
- Gmail (Send Email)
- Notion (Update Database Item)

### 2.4 Variables et paramètres

- `contactList` : Liste des contacts à prospecter
- `emailTemplate` : Template de base pour les emails
- `aiPrompt` : Instructions pour la personnalisation IA
- `batchSize` : Nombre d'emails par lot

## 3. Email Sender - Phase 2 (Suivi des propositions)

### 3.1 Objectif

Assurer le suivi des propositions envoyées et relancer les contacts n'ayant pas répondu.

### 3.2 Structure du workflow

- **Déclencheur** : Planification temporelle (hebdomadaire)
- **Récupération** : Extraction des contacts en attente de réponse
- **Analyse** : Vérification du délai depuis le dernier contact
- **Personnalisation** : Génération de relance personnalisée
- **Envoi** : Transmission des emails de relance
- **Mise à jour** : Actualisation du statut dans Notion

### 3.3 Nœuds principaux

- Schedule Trigger
- Notion (Get Database Items with Filter)
- Function (Date Calculation)
- HTTP Request (OpenRouter API)
- Gmail (Send Email)
- Notion (Update Database Item)

### 3.4 Variables et paramètres

- `followUpDelay` : Délai avant relance (jours)
- `maxFollowUps` : Nombre maximum de relances
- `followUpTemplate` : Template pour les emails de relance

## 4. Email Sender - Phase 3 (Traitement des réponses)

### 4.1 Objectif

Traiter automatiquement les réponses reçues et préparer les actions de suivi appropriées.

### 4.2 Structure du workflow

- **Déclencheur** : Webhook Gmail (réception d'email)
- **Analyse** : Classification de la réponse via IA
- **Traitement** : Actions spécifiques selon le type de réponse
- **Notification** : Alerte pour intervention humaine si nécessaire
- **Mise à jour** : Actualisation du statut dans Notion

### 4.3 Nœuds principaux

- Webhook Trigger
- Gmail (Get Emails)
- HTTP Request (OpenRouter API for Classification)
- Switch (Based on Response Type)
- Slack / Email (Notification)
- Notion (Update Database Item)

### 4.4 Variables et paramètres

- `responseCategories` : Catégories de réponses (positif, négatif, question, etc.)
- `humanInterventionThreshold` : Seuil de confiance pour intervention humaine
- `notificationChannels` : Canaux de notification configurés

## 5. Email Sender - Config (Configuration centralisée)

### 5.1 Objectif

Centraliser la configuration des workflows et gérer les templates d'emails.

### 5.2 Structure du workflow

- **Interface** : Formulaire de configuration
- **Stockage** : Sauvegarde des paramètres dans n8n
- **Validation** : Vérification de la cohérence des paramètres
- **Distribution** : Mise à disposition des configurations pour les autres workflows

### 5.3 Nœuds principaux

- Webhook Trigger (Configuration Interface)
- Function (Validation)
- n8n (Set Variables)
- Respond to Webhook

### 5.4 Variables et paramètres

- `globalConfig` : Configuration globale du système
- `emailTemplates` : Collection de templates d'emails
- `aiSettings` : Paramètres pour les services IA
- `notificationSettings` : Configuration des notifications

## 6. Intégration avec les services IA

### 6.1 Architectures d'agents IA

Plusieurs architectures sont implémentées dans les workflows :

- **Agent unique + Outils** : Un seul agent IA accède à différents outils
- **Agents séquentiels** : Plusieurs agents spécialisés travaillent en séquence
- **Agent + MCP + Outils** : Agent enrichi par contexte des serveurs MCP
- **Agent + Router** : Système de routage intelligent des emails
- **Agent + Human in the Loop** : Collaboration IA-humain pour les cas complexes

### 6.2 Templates disponibles

Des templates prêts à l'emploi sont disponibles dans `/src/n8n/workflows/templates/ai-agents/` :
- `agent-single-tools.json`
- `agents-sequential.json`
- `agent-mcp-tools.json`
- `agent-router.json`
- `agent-human-loop.json`

## 7. Bonnes pratiques d'implémentation

1. **Isolation des responsabilités** : Chaque workflow a un rôle clairement défini
2. **Gestion du contexte** : Utilisation des variables n8n pour maintenir le contexte
3. **Logging détaillé** : Activation des logs pour suivre les décisions
4. **Tests A/B** : Comparaison des performances de différentes configurations
5. **Mécanismes de fallback** : Chemins alternatifs en cas d'échec
6. **Modularité** : Sous-workflows réutilisables pour les fonctionnalités communes
7. **Gestion des erreurs** : Mécanismes de détection et récupération
8. **Monitoring** : Alertes pour surveiller les performances
