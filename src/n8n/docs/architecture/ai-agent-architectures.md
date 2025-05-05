# Architectures d'agents IA pour n8n

## Vue d'ensemble

Ce document présente différentes architectures d'agents IA qui peuvent être implémentées dans n8n pour le projet Email Sender 1. Ces architectures permettent d'optimiser les workflows d'automatisation en tirant parti des capacités des modèles d'IA.

## Architectures applicables

### 1. Agent unique + Outils
Architecture de base où un seul agent IA (comme DeepSeek via OpenRouter) peut accéder à différents outils (Gmail, Google Calendar, Notion).

**Implémentation n8n:**
- Un nœud OpenRouter/DeepSeek central
- Connexions vers des nœuds d'outils (Gmail, Google Sheets, etc.)
- Utilisation de variables pour stocker le contexte

**Structure du workflow:**
- Webhook de déclenchement → Agent IA → Connexions multiples vers outils (OpenAI, Simple Memory, Gmail, etc.)
- Utilisation de variables n8n pour maintenir le contexte entre les appels

### 2. Agents séquentiels
Chaîne de workflows n8n où chaque étape utilise un agent IA spécialisé.

**Implémentation n8n:**
- Plusieurs workflows connectés
- Chaque workflow contient un agent IA spécialisé
- Transfert de données entre workflows via webhooks ou variables

**Structure du workflow:**
- Webhook → Agent IA #1 → Webhook → Agent IA #2 → Webhook → Agent IA #3
- Chaque agent a accès à ses propres outils spécifiques (OpenAI, Google Chat Model, etc.)
- Transfert de contexte enrichi à chaque étape

### 3. Agent + MCP Servers + Outils
Architecture intégrant les serveurs MCP pour fournir du contexte aux modèles IA.

**Implémentation n8n:**
- Nœud HTTP Request pour interroger les serveurs MCP
- Nœud Function pour formater le contexte
- Nœud OpenRouter pour l'agent IA avec contexte enrichi

**Structure du workflow:**
- Webhook → HTTP Request vers MCP → Function (formatage) → Agent IA → Outils
- Enrichissement du contexte avant l'appel à l'agent IA

### 4. Agent + Router
Système de routage intelligent des emails selon leur contenu.

**Implémentation n8n:**
- Agent IA pour analyser le contenu
- Nœuds Switch/IF pour le routage basé sur l'analyse
- Workflows distincts pour chaque type de réponse

**Structure du workflow:**
- Webhook → Agent IA → Nœud IF/Switch → Multiples chemins de traitement
- Utilisation de nœuds IF imbriqués pour une logique de routage complexe
- Redirection vers différents webhooks selon la classification

### 5. Agent + Human in the Loop
Architecture avec validation humaine dans le processus.

**Implémentation n8n:**
- Génération de contenu par IA
- Nœud Slack/Email pour notification et approbation
- Nœud Wait pour pause jusqu'à approbation
- Continuation conditionnelle basée sur l'approbation

**Structure du workflow:**
- Webhook → Agent IA → Slack Approval → Wait → IF (approuvé) → Action finale
- Boucle de feedback avec possibilité de modifications avant approbation

### 6. Agent unique + Appel dynamique d'autres agents
Architecture permettant à un agent principal d'appeler d'autres agents spécialisés selon les besoins.

**Implémentation n8n:**
- Agent principal avec logique de décision
- Sous-workflows pour chaque agent spécialisé
- Mécanisme d'appel dynamique via Execute Workflow

**Structure du workflow:**
- Webhook → Agent principal → IF/Switch → Execute Workflow (agents spécialisés)
- Intégration avec divers outils: OpenAI, Simple Memory, Airtable, Microsoft 365, HubSpot
- Agrégation des résultats des agents spécialisés

### 7. Hiérarchie d'agents + Agents parallèles + Outils partagés
Architecture complexe avec une hiérarchie d'agents travaillant en parallèle et partageant des outils.

**Implémentation n8n:**
- Agent superviseur au sommet de la hiérarchie
- Agents spécialisés exécutés en parallèle
- Outils partagés accessibles à tous les agents

**Structure du workflow:**
- Webhook → Agent superviseur → Split → Agents parallèles → Merge → Résultat final
- Nœud central pour la coordination des agents parallèles
- Accès partagé aux outils et ressources (OpenAI, Memory, Gmail, Telegram)

### 8. Hiérarchie d'agents + Boucle + Agents parallèles + RAG partagé
Architecture avancée combinant hiérarchie, boucles de feedback, traitement parallèle et système RAG partagé.

**Implémentation n8n:**
- Structure hiérarchique d'agents
- Mécanisme de boucle pour l'amélioration itérative
- Traitement parallèle pour les tâches indépendantes
- Système RAG (Retrieval Augmented Generation) partagé

**Structure du workflow:**
- Webhook → Agent superviseur → Split → Agents parallèles → RAG partagé → Merge → Boucle de feedback
- Intégration avec des bases de connaissances via le système RAG
- Mécanisme de boucle pour raffiner les résultats
- Utilisation d'Embeddings/Search pour la recherche contextuelle

## Applications pratiques pour Email Sender 1

### Phase 1: Prospection initiale
- **Architecture recommandée:** Agent + MCP Servers + Outils
- **Workflow:** Génération de messages personnalisés avec contexte riche
- **Template:** Webhook → MCP Context → OpenAI → Gmail

### Phase 2: Suivi des propositions
- **Architecture recommandée:** Agents séquentiels
- **Workflow:** Analyse des réponses → Génération de suivi → Planification
- **Template:** Gmail Trigger → Analyse Agent → Suivi Agent → Calendar Agent

### Phase 3: Traitement des réponses
- **Architecture recommandée:** Agent + Router
- **Workflow:** Classification des réponses → Routage vers workflows appropriés
- **Template:** Gmail Trigger → Classification Agent → Switch → Workflows spécifiques

### Phase 4: Confirmation et finalisation
- **Architecture recommandée:** Agent + Human in the Loop
- **Workflow:** Génération de contrats → Validation humaine → Envoi final
- **Template:** Trigger → Contract Agent → Slack Approval → Gmail

### Phase 5: Analyse et optimisation
- **Architecture recommandée:** Hiérarchie d'agents + RAG partagé
- **Workflow:** Analyse des performances → Optimisation des messages → Amélioration continue
- **Template:** Trigger périodique → Analyse Agent → RAG → Optimisation Agent

## Templates prêts à l'emploi

### Template 1: Prospection automatisée
```json
{
  "name": "Prospection IA automatisée",
  "nodes": [
    {"type": "n8n-nodes-base.webhook", "position": [100, 300]},
    {"type": "n8n-nodes-base.httpRequest", "position": [300, 300], "name": "MCP Context"},
    {"type": "n8n-nodes-base.function", "position": [500, 300], "name": "Format Context"},
    {"type": "n8n-nodes-base.openAi", "position": [700, 300]},
    {"type": "n8n-nodes-base.gmail", "position": [900, 300]}
  ],
  "connections": {/* Connexions entre les nœuds */}
}
```

### Template 2: Validation humaine des emails
```json
{
  "name": "Validation humaine des emails",
  "nodes": [
    {"type": "n8n-nodes-base.webhook", "position": [100, 300]},
    {"type": "n8n-nodes-base.openAi", "position": [300, 300]},
    {"type": "n8n-nodes-base.slack", "position": [500, 300], "name": "Approval Request"},
    {"type": "n8n-nodes-base.wait", "position": [700, 300]},
    {"type": "n8n-nodes-base.if", "position": [900, 300]},
    {"type": "n8n-nodes-base.gmail", "position": [1100, 200]}
  ],
  "connections": {/* Connexions entre les nœuds */}
}
```

### Template 3: Classification et routage des réponses
```json
{
  "name": "Classification et routage des réponses",
  "nodes": [
    {"type": "n8n-nodes-base.gmail", "position": [100, 300], "name": "Email Trigger"},
    {"type": "n8n-nodes-base.function", "position": [300, 300], "name": "Extract Content"},
    {"type": "n8n-nodes-base.openAi", "position": [500, 300], "name": "Classification Agent"},
    {"type": "n8n-nodes-base.switch", "position": [700, 300]},
    {"type": "n8n-nodes-base.webhook", "position": [900, 100], "name": "Positive Response"},
    {"type": "n8n-nodes-base.webhook", "position": [900, 300], "name": "Need More Info"},
    {"type": "n8n-nodes-base.webhook", "position": [900, 500], "name": "Negative Response"}
  ],
  "connections": {/* Connexions entre les nœuds */}
}
```

## Bonnes pratiques d'implémentation

1. **Isolation des responsabilités:** Chaque agent doit avoir un rôle clairement défini
2. **Gestion du contexte:** Utiliser les variables n8n pour maintenir le contexte entre les nœuds
3. **Logging détaillé:** Activer les logs pour suivre les décisions des agents
4. **Tests A/B:** Comparer différentes architectures pour optimiser les performances
5. **Mécanismes de fallback:** Prévoir des chemins alternatifs en cas d'échec d'un agent
6. **Modularité:** Concevoir des sous-workflows réutilisables pour les fonctionnalités communes
7. **Gestion des erreurs:** Implémenter des mécanismes de détection et de récupération d'erreurs
8. **Monitoring:** Mettre en place des alertes pour surveiller les performances des agents
9. **Versionnement:** Maintenir un historique des versions des workflows pour faciliter les rollbacks
10. **Documentation:** Documenter clairement le rôle et les interactions de chaque agent

## Ressources et exemples

Les exemples complets de workflows sont disponibles dans le dossier `src/n8n/workflows/templates/ai-agents/`.

Pour implémenter ces architectures, consultez également:
- [Documentation officielle n8n sur l'intégration OpenAI](https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.openai/)
- [Guide d'utilisation des variables n8n](https://docs.n8n.io/code-examples/expressions/variables/)
- [Tutoriel sur les workflows conditionnels](https://docs.n8n.io/workflows/workflows-conditional/)
