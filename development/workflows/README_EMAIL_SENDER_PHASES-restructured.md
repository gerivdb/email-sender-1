# Email Sender - Structure Modulaire

## Table des matières

1. [Email Sender - Structure Modulaire](#section-1)

        1.0.1. [Phase 1: Gestion des Disponibilités](#section-2)

        1.0.2. [Phase 2: Génération & Envoi des Emails](#section-3)

        1.0.3. [Phase 3: Traitement des Réponses](#section-4)

        1.0.4. [Phase 4: Gestion des Concerts Confirmés](#section-5)

        1.0.5. [Phase 5: Suivi Post-Concert](#section-6)

        1.0.6. [Phase 6: Évaluation et Planification Future](#section-7)

    1.1. [Communication entre les phases](#section-8)

    1.2. [Flux de données](#section-9)

    1.3. [Installation et configuration](#section-10)

    1.4. [Maintenance](#section-11)

    1.5. [Avantages de cette structure modulaire](#section-12)

## 1. Email Sender - Structure Modulaire <a name='section-1'></a>

Ce projet est structuré en 6 phases distinctes, chacune implémentée dans un fichier JSON séparé. Cette approche modulaire facilite la maintenance, le débogage et l'évolution du système.

#### 1.0.1. Phase 1: Gestion des Disponibilités <a name='section-2'></a>

- **Fichier**: `EMAIL_SENDER_PHASE1.json`
- **Déclencheur**: Cron hebdomadaire
- **Objectif**: Consolider les indisponibilités Notion & Google Calendar
- **Sortie**: Liste des créneaux disponibles pour les concerts

#### 1.0.2. Phase 2: Génération & Envoi des Emails <a name='section-3'></a>

- **Fichier**: `EMAIL_SENDER_PHASE2.json`
- **Déclencheur**: Exécution de la Phase 1
- **Objectif**: Générer des emails personnalisés avec l'IA et les envoyer
- **Sortie**: Emails envoyés et statuts mis à jour dans Notion

#### 1.0.3. Phase 3: Traitement des Réponses <a name='section-4'></a>

- **Fichier**: `EMAIL_SENDER_PHASE3.json`
- **Déclencheur**: Réception d'emails de réponse
- **Objectif**: Analyser les réponses et mettre à jour Notion
- **Sortie**: Statuts des contacts mis à jour dans Notion

#### 1.0.4. Phase 4: Gestion des Concerts Confirmés <a name='section-5'></a>

- **Fichier**: `EMAIL_SENDER_PHASE4.json`
- **Déclencheur**: Cron toutes les 30 minutes (vérifie les confirmations)
- **Objectif**: Créer des événements dans Google Calendar
- **Sortie**: Événements créés et statuts mis à jour dans Notion

#### 1.0.5. Phase 5: Suivi Post-Concert <a name='section-6'></a>

- **Fichier**: `EMAIL_SENDER_PHASE5.json`
- **Déclencheur**: Cron quotidien (vérifie les concerts passés)
- **Objectif**: Envoyer des emails de remerciement
- **Sortie**: Emails envoyés et statuts mis à jour dans Notion

#### 1.0.6. Phase 6: Évaluation et Planification Future <a name='section-7'></a>

- **Fichier**: `EMAIL_SENDER_PHASE6.json`
- **Déclencheur**: Cron hebdomadaire
- **Objectif**: Analyser les données et générer des rapports
- **Sortie**: Rapports envoyés par email

### 1.1. Communication entre les phases <a name='section-8'></a>

Les phases communiquent entre elles de deux manières principales:

1. **Via la base de données Notion**:
   - Chaque phase met à jour les statuts dans Notion
   - Les phases suivantes lisent ces statuts pour déterminer les actions à prendre
   - Notion sert de "source de vérité" centrale

2. **Via des déclencheurs directs**:
   - La Phase 2 est déclenchée directement par la Phase 1
   - Les autres phases utilisent des déclencheurs temporels (Cron) ou événementiels (réception d'emails)

### 1.2. Flux de données <a name='section-9'></a>

```plaintext
Phase 1 (Disponibilités) → Phase 2 (Emails) → Phase 3 (Réponses) → Phase 4 (Confirmations) → Phase 5 (Post-Concert) → Phase 6 (Évaluation)

```plaintext
### 1.3. Installation et configuration <a name='section-10'></a>

1. Importez chaque fichier JSON dans n8n
2. Configurez les credentials pour:
   - Notion
   - Gmail
   - Google Calendar
   - OpenRouter (pour l'IA)
3. Activez les workflows dans l'ordre des phases

### 1.4. Maintenance <a name='section-11'></a>

Pour modifier une phase spécifique:
1. Ouvrez le fichier JSON correspondant
2. Effectuez vos modifications
3. Testez la phase individuellement
4. Vérifiez l'intégration avec les phases adjacentes

### 1.5. Avantages de cette structure modulaire <a name='section-12'></a>

- **Isolation**: Les problèmes dans une phase n'affectent pas les autres
- **Testabilité**: Chaque phase peut être testée indépendamment
- **Évolutivité**: Nouvelles fonctionnalités peuvent être ajoutées à des phases spécifiques
- **Clarté**: Chaque phase a un objectif clair et bien défini
- **Performance**: Les workflows plus petits sont plus efficaces

