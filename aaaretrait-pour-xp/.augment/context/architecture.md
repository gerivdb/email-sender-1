# Architecture du projet EMAIL_SENDER_1

Ce document présente l'architecture globale du projet EMAIL_SENDER_1, ses composants principaux et leurs interactions.

## 1. Vue d'ensemble

EMAIL_SENDER_1 est un système d'automatisation d'envoi d'emails pour la gestion de booking de concerts, basé sur une architecture modulaire intégrant plusieurs technologies :

```plaintext
┌─────────────────────────────────────────────────────────────────┐
│                       EMAIL_SENDER_1                            │
├─────────────┬─────────────┬────────────────┬──────────────────┐
│   n8n       │    MCP      │  Scripts       │  Notion +        │
│  Workflows  │  Servers    │  PowerShell/   │  Google Calendar │
│             │             │  Python        │                  │
└─────────────┴─────────────┴────────────────┴──────────────────┘
```plaintext
## 2. Composants principaux

### 2.1 n8n Workflows

Les workflows n8n constituent le cœur du système, organisés en phases :

- **Email Sender - Phase 1** : Prospection initiale
- **Email Sender - Phase 2** : Suivi des propositions
- **Email Sender - Phase 3** : Traitement des réponses
- **Email Sender - Config** : Configuration centralisée

Architecture interne des workflows :
```plaintext
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Déclencheur │────▶│ Récupération│────▶│ Traitement  │────▶│   Action    │
│  (Trigger)  │     │  de données │     │  des données│     │  (Envoi)    │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```plaintext
### 2.2 MCP (Model Context Protocol)

Les serveurs MCP fournissent du contexte aux modèles IA :

- **server-filesystem** : Accès au système de fichiers local
- **server-github** : Accès aux repositories GitHub
- **server-gcp** : Accès aux services Google Cloud Platform

### 2.3 Scripts PowerShell/Python

Utilitaires et intégrations pour :
- Automatisation des tâches
- Synchronisation des données
- Tests et validation
- Maintenance du système

### 2.4 Sources de données

- **Notion** : Base de données de contacts et suivi
- **Google Calendar** : Gestion des disponibilités

### 2.5 Services IA

- **OpenRouter** : Routage vers différents modèles IA
- **DeepSeek** : Service IA pour personnalisation des messages

## 3. Flux de données

```plaintext
┌───────────┐    ┌───────────┐    ┌───────────┐    ┌───────────┐
│  Sources  │───▶│    n8n    │───▶│  Services │───▶│ Destinat. │
│de données │    │ Workflows │    │    IA     │    │  (Email)  │
└───────────┘    └───────────┘    └───────────┘    └───────────┘
      ▲                ▲                               │
      │                │                               │
      └────────────────┴───────────────────────────────┘
                      Feedback Loop
```plaintext
## 4. Architecture des dossiers

```plaintext
/src/n8n/workflows/       → Workflows n8n actifs (*.json)
/src/n8n/workflows/archive → Versions archivées
/src/mcp/servers/         → Serveurs MCP
/projet/guides/           → Documentation méthodologique
/projet/roadmaps/         → Roadmap et planification
/projet/config/           → Fichiers de configuration
/development/scripts/     → Scripts d'automatisation
/docs/guides/augment/     → Guides spécifiques à Augment
```plaintext
## 5. Intégrations externes

### 5.1 Notion

- API Notion pour la gestion des bases de données
- Webhooks pour les notifications en temps réel

### 5.2 Google Calendar

- API Google Calendar pour la gestion des disponibilités
- Synchronisation bidirectionnelle avec Notion

### 5.3 Gmail

- API Gmail pour l'envoi et la réception d'emails
- Gestion des templates et des pièces jointes

### 5.4 OpenRouter/DeepSeek

- API OpenRouter pour l'accès aux modèles IA
- Personnalisation des messages et analyse des réponses

## 6. Sécurité et confidentialité

- Gestion des secrets via des variables d'environnement
- Chiffrement des données sensibles
- Journalisation des accès et des actions
- Conformité RGPD pour le traitement des données personnelles

## 7. Évolutivité

L'architecture est conçue pour évoluer selon les axes suivants :
- Ajout de nouvelles phases de workflow
- Intégration de nouveaux services IA
- Extension à d'autres plateformes de gestion de contenu
- Automatisation accrue des processus de suivi
