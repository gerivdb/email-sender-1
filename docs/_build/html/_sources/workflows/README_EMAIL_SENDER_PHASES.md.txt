# Email Sender - Structure Modulaire

Ce projet est structuré en 6 phases distinctes, chacune implémentée dans un fichier JSON séparé. Cette approche modulaire facilite la maintenance, le débogage et l'évolution du système.

## Vue d'ensemble des phases

### Phase 1: Gestion des Disponibilités
- **Fichier**: `EMAIL_SENDER_PHASE1.json`
- **Déclencheur**: Cron hebdomadaire
- **Objectif**: Consolider les indisponibilités Notion & Google Calendar
- **Sortie**: Liste des créneaux disponibles pour les concerts

### Phase 2: Génération & Envoi des Emails
- **Fichier**: `EMAIL_SENDER_PHASE2.json`
- **Déclencheur**: Exécution de la Phase 1
- **Objectif**: Générer des emails personnalisés avec l'IA et les envoyer
- **Sortie**: Emails envoyés et statuts mis à jour dans Notion

### Phase 3: Traitement des Réponses
- **Fichier**: `EMAIL_SENDER_PHASE3.json`
- **Déclencheur**: Réception d'emails de réponse
- **Objectif**: Analyser les réponses et mettre à jour Notion
- **Sortie**: Statuts des contacts mis à jour dans Notion

### Phase 4: Gestion des Concerts Confirmés
- **Fichier**: `EMAIL_SENDER_PHASE4.json`
- **Déclencheur**: Cron toutes les 30 minutes (vérifie les confirmations)
- **Objectif**: Créer des événements dans Google Calendar
- **Sortie**: Événements créés et statuts mis à jour dans Notion

### Phase 5: Suivi Post-Concert
- **Fichier**: `EMAIL_SENDER_PHASE5.json`
- **Déclencheur**: Cron quotidien (vérifie les concerts passés)
- **Objectif**: Envoyer des emails de remerciement
- **Sortie**: Emails envoyés et statuts mis à jour dans Notion

### Phase 6: Évaluation et Planification Future
- **Fichier**: `EMAIL_SENDER_PHASE6.json`
- **Déclencheur**: Cron hebdomadaire
- **Objectif**: Analyser les données et générer des rapports
- **Sortie**: Rapports envoyés par email

## Communication entre les phases

Les phases communiquent entre elles de deux manières principales:

1. **Via la base de données Notion**:
   - Chaque phase met à jour les statuts dans Notion
   - Les phases suivantes lisent ces statuts pour déterminer les actions à prendre
   - Notion sert de "source de vérité" centrale

2. **Via des déclencheurs directs**:
   - La Phase 2 est déclenchée directement par la Phase 1
   - Les autres phases utilisent des déclencheurs temporels (Cron) ou événementiels (réception d'emails)

## Flux de données

```
Phase 1 (Disponibilités) → Phase 2 (Emails) → Phase 3 (Réponses) → Phase 4 (Confirmations) → Phase 5 (Post-Concert) → Phase 6 (Évaluation)
```

## Installation et configuration

1. Importez chaque fichier JSON dans n8n
2. Configurez les credentials pour:
   - Notion
   - Gmail
   - Google Calendar
   - OpenRouter (pour l'IA)
3. Activez les workflows dans l'ordre des phases

## Maintenance

Pour modifier une phase spécifique:
1. Ouvrez le fichier JSON correspondant
2. Effectuez vos modifications
3. Testez la phase individuellement
4. Vérifiez l'intégration avec les phases adjacentes

## Avantages de cette structure modulaire

- **Isolation**: Les problèmes dans une phase n'affectent pas les autres
- **Testabilité**: Chaque phase peut être testée indépendamment
- **Évolutivité**: Nouvelles fonctionnalités peuvent être ajoutées à des phases spécifiques
- **Clarté**: Chaque phase a un objectif clair et bien défini
- **Performance**: Les workflows plus petits sont plus efficaces
