# Décisions architecturales pour EMAIL SENDER 1

*Version 2025-05-15*

Ce document présente les principales décisions architecturales pour le projet EMAIL SENDER 1, leurs justifications et leurs implications.

## 1. Multi-Instance vs. Multi-Tenant

### 1.1 Contexte

Une décision architecturale majeure pour tout système qui sert plusieurs utilisateurs ou clients est de choisir entre une approche Multi-Instance ou Multi-Tenant.

### 1.2 Options

#### Multi-Instance

- **Description** : Chaque client a sa propre instance isolée de l'application (n8n, base de données, etc.)
- **Avantages** :
  - Sécurité accrue (isolation complète des données)
  - Plus facile à construire et à maintenir
  - Mises à jour indépendantes par client
  - Moins de complexité pour n8n (credentials en dur par instance)
  - Pas de bugs inter-clients
- **Inconvénients** :
  - Coûts d'infrastructure plus élevés
  - Onboarding plus complexe
  - Duplication des ressources

#### Multi-Tenant

- **Description** : Une seule instance de l'application sert tous les clients, avec séparation logique des données
- **Avantages** :
  - Moins cher à scaler
  - Déploiement unique
  - Idéal pour un SaaS de bout en bout
  - Utilisation plus efficace des ressources
- **Inconvénients** :
  - Plus complexe à développer
  - Webhooks n8n doivent être génériques (passer `client_id`, récupérer les credentials spécifiques)
  - Plus difficile à personnaliser par client
  - Risques de fuites de données entre clients

### 1.3 Décision

Pour EMAIL SENDER 1, nous avons opté pour une approche **hybride** :

- **Multi-Instance pour les workflows n8n** : Chaque client (artiste/agent) a ses propres workflows n8n
- **Multi-Tenant pour les données** : Une base de données Notion partagée avec Row Level Security

### 1.4 Justification

Cette approche hybride offre :
- Sécurité et personnalisation des workflows par client
- Économies d'échelle pour le stockage et la gestion des données
- Flexibilité pour migrer vers une approche entièrement Multi-Tenant à l'avenir

### 1.5 Implications

- Nécessité de développer un système de provisionnement pour créer de nouvelles instances n8n
- Besoin d'un mécanisme robuste de Row Level Security dans Notion
- Complexité accrue pour la synchronisation des données entre instances

## 2. Architecture des workflows n8n

### 2.1 Contexte

Les workflows n8n sont au cœur du système EMAIL SENDER 1. Leur conception impacte directement la maintenabilité, l'évolutivité et la robustesse du système.

### 2.2 Décision

Nous avons adopté une architecture modulaire avec les composants suivants :

1. **Workflows principaux** :
   - Email Sender - Phase 1 (Prospection)
   - Email Sender - Phase 2 (Suivi)
   - Email Sender - Phase 3 (Traitement des réponses)

2. **Workflow de configuration** :
   - Email Sender - Config

3. **Pattern de workflow standard** :
   ```
   Trigger -> Read -> Filter -> Act -> Update -> Wait -> Re-check -> Conditional Act -> Update
   ```

### 2.3 Justification

Cette architecture modulaire :
- Sépare les préoccupations (separation of concerns)
- Facilite la maintenance et les mises à jour
- Permet une évolution indépendante des différentes phases
- Centralise la configuration pour une cohérence globale

### 2.4 Implications

- Nécessité de maintenir la cohérence entre les workflows
- Besoin de mécanismes de partage de données entre workflows
- Importance de la documentation pour chaque workflow

## 3. Intégration MCP pour la personnalisation IA

### 3.1 Contexte

La personnalisation des emails est un aspect critique du projet. L'utilisation de l'IA via OpenRouter/DeepSeek nécessite une architecture d'intégration efficace.

### 3.2 Décision

Nous avons choisi d'implémenter le Model Context Protocol (MCP) comme couche d'abstraction entre n8n et les services IA :

```plaintext
+-----------------+      +--------------+      +-----------------+      +---------+
| Read Contact    | ---> | Prepare Data | ---> | Call MCP        | ---> | Send    |
| (Notion)        |      | (Context)    |      | (Get AI Text)   |      | Email   |
+-----------------+      +--------------+      +-----------------+      +---------+
                                 |                     |
                                 +---------------------+
                                       (Pass Data)
```plaintext
### 3.3 Justification

Cette architecture :
- Enrichit les prompts avec du contexte pertinent
- Abstrait la complexité des appels API aux services IA
- Permet de changer facilement de fournisseur IA
- Optimise l'utilisation des tokens

### 3.4 Implications

- Nécessité de développer et maintenir les serveurs MCP
- Besoin d'une gestion efficace du contexte
- Importance de la qualité des prompts

## 4. Gestion des états et sécurité

### 4.1 Contexte

La gestion des états et la sécurité sont fondamentales pour un système d'automatisation d'emails.

### 4.2 Décision

Nous avons adopté les principes suivants :

1. **Gestion des états** :
   - Notion comme source de vérité pour le suivi des statuts
   - Mise à jour systématique après chaque action
   - Vérification de l'état avant toute action critique

2. **Sécurité** :
   - Stockage sécurisé des secrets (clés API, webhooks)
   - Couche intermédiaire pour masquer les webhooks n8n
   - Authentification pour tous les points d'entrée

### 4.3 Justification

Ces principes :
- Assurent la cohérence des données
- Évitent les actions en double
- Protègent les informations sensibles
- Réduisent les risques de sécurité

### 4.4 Implications

- Nécessité d'un modèle de données robuste dans Notion
- Besoin d'un système de gestion des secrets
- Importance des tests de sécurité

## 5. Structure du projet et organisation du code

### 5.1 Contexte

L'organisation du code et la structure du projet impactent directement la productivité, la maintenabilité et la qualité.

### 5.2 Décision

Nous avons adopté la structure suivante :

```plaintext
/src/n8n/workflows/       → Workflows n8n actifs (*.json)
/src/n8n/workflows/archive → Versions archivées
/src/mcp/servers/         → Serveurs MCP (filesystem, github, gcp)
/projet/guides/           → Documentation méthodologique
/projet/roadmaps/         → Roadmap et planification
/projet/config/           → Fichiers de configuration
/development/scripts/     → Scripts d'automatisation et modes
/docs/guides/augment/     → Guides spécifiques à Augment
```plaintext
### 5.3 Justification

Cette structure :
- Sépare clairement le code source, la documentation et les outils de développement
- Facilite la navigation et la recherche
- Suit les bonnes pratiques de l'industrie
- Supporte le versionnement et l'archivage

### 5.4 Implications

- Nécessité de respecter cette structure dans tous les développements
- Besoin de scripts d'organisation pour maintenir la cohérence
- Importance de la documentation pour expliquer la structure

## 6. Intégration avec les services externes

### 6.1 Contexte

EMAIL SENDER 1 s'intègre avec plusieurs services externes (Notion, Google Calendar, Gmail, OpenRouter/DeepSeek).

### 6.2 Décision

Nous avons adopté les principes d'intégration suivants :

1. **Abstraction des API** :
   - Utilisation des nœuds n8n natifs quand disponibles
   - Création de nœuds personnalisés pour les intégrations spécifiques

2. **Gestion des credentials** :
   - Stockage sécurisé dans n8n
   - Rotation régulière des clés

3. **Résilience** :
   - Mécanismes de retry pour les appels API
   - Gestion des erreurs et fallbacks

### 6.3 Justification

Ces principes :
- Simplifient les intégrations
- Améliorent la sécurité
- Augmentent la robustesse du système
- Facilitent les mises à jour des services externes

### 6.4 Implications

- Nécessité de surveiller les changements d'API des services externes
- Besoin de tests d'intégration réguliers
- Importance de la documentation des intégrations

## 7. Évolutivité et maintenance

### 7.1 Contexte

EMAIL SENDER 1 doit être conçu pour évoluer et être maintenu facilement sur le long terme.

### 7.2 Décision

Nous avons adopté les principes suivants :

1. **Modularité** :
   - Composants indépendants et réutilisables
   - Interfaces clairement définies

2. **Documentation** :
   - Minimum 20% du code
   - Guides d'utilisation et de développement

3. **Tests** :
   - Tests unitaires avec Pester (PS) et pytest (Python)
   - Tests d'intégration pour les workflows n8n

### 7.3 Justification

Ces principes :
- Facilitent l'ajout de nouvelles fonctionnalités
- Réduisent le coût de maintenance
- Améliorent la qualité du code
- Préservent la connaissance du projet

### 7.4 Implications

- Nécessité d'un effort initial plus important
- Besoin de discipline dans le développement
- Importance de la revue de code

## 8. Conclusion et prochaines étapes

Les décisions architecturales présentées dans ce document forment la base du projet EMAIL SENDER 1. Elles seront révisées et affinées au fur et à mesure de l'avancement du projet.

### 8.1 Prochaines étapes

1. **Prototypage** :
   - Implémenter un workflow n8n de base suivant le pattern standard
   - Tester l'intégration avec MCP

2. **Validation** :
   - Valider l'approche hybride Multi-Instance/Multi-Tenant
   - Tester la gestion des états avec Notion

3. **Documentation** :
   - Détailler chaque composant de l'architecture
   - Créer des guides d'implémentation

### 8.2 Points de décision futurs

- Choix d'une solution de monitoring pour les workflows n8n
- Stratégie de déploiement et d'hébergement
- Approche pour les tests automatisés des workflows n8n

---

> **Note** : Ce document est évolutif et sera mis à jour au fur et à mesure des avancées du projet et des nouvelles décisions architecturales.
