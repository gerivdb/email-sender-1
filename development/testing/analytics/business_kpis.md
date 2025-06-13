# Indicateurs Clés de Performance (KPIs) Métier

## Introduction

Ce document définit les indicateurs clés de performance (KPIs) métier qui sont utilisés pour mesurer, analyser et optimiser les performances des campagnes d'emailing et des processus associés. Ces KPIs fournissent une vision complète de l'efficacité, de l'engagement et de la valeur générée par les activités d'emailing.

## Objectifs

Les KPIs métier ont été définis pour répondre aux objectifs suivants :

1. **Mesure de l'efficacité** : Évaluer la performance technique des campagnes d'emailing
2. **Analyse de l'engagement** : Comprendre comment les destinataires interagissent avec les emails
3. **Évaluation de la qualité** : Surveiller la qualité des listes d'emails et des contenus
4. **Mesure de la valeur** : Quantifier le retour sur investissement des campagnes
5. **Optimisation continue** : Identifier les opportunités d'amélioration des processus

## Catégories de KPIs

Les KPIs métier sont organisés en plusieurs catégories :

1. **Efficacité** : Mesure de la performance technique des campagnes
2. **Engagement** : Mesure de l'interaction des destinataires avec les emails
3. **Qualité** : Mesure de la qualité des listes et des contenus
4. **Performance** : Mesure de la rapidité et de l'efficacité des processus
5. **Croissance** : Mesure de l'évolution de la base d'abonnés
6. **Coût** : Mesure des aspects financiers des campagnes
7. **Valeur** : Mesure du retour sur investissement et de la valeur générée
8. **Global** : Métriques composites et indicateurs de santé générale

## Définition des KPIs

### Efficacité

#### EMAIL_DELIVERY_RATE

- **Nom** : Taux de livraison des emails
- **Description** : Pourcentage d'emails correctement livrés
- **Formule** : (Nombre d'emails livrés / Nombre total d'emails envoyés) * 100
- **Unité** : %
- **Seuils** :
  - Normal : > 95%
  - Avertissement : 90% - 95%
  - Critique : < 90%
- **Interprétation** : Un taux de livraison élevé indique une bonne qualité de la liste d'emails et une bonne réputation d'expéditeur. Un taux faible peut signaler des problèmes de qualité de la liste, de configuration technique ou de réputation.

#### CAMPAIGN_COMPLETION_RATE

- **Nom** : Taux de complétion des campagnes
- **Description** : Pourcentage de campagnes terminées avec succès
- **Formule** : (Nombre de campagnes terminées avec succès / Nombre total de campagnes) * 100
- **Unité** : %
- **Seuils** :
  - Normal : > 95%
  - Avertissement : 90% - 95%
  - Critique : < 90%
- **Interprétation** : Un taux de complétion élevé indique que les campagnes s'exécutent correctement sans erreurs techniques. Un taux faible peut signaler des problèmes dans les processus d'exécution des campagnes.

#### WORKFLOW_COMPLETION_RATE

- **Nom** : Taux de complétion des workflows
- **Description** : Pourcentage de workflows terminés avec succès
- **Formule** : (Nombre de workflows terminés avec succès / Nombre total de workflows) * 100
- **Unité** : %
- **Seuils** :
  - Normal : > 95%
  - Avertissement : 90% - 95%
  - Critique : < 90%
- **Interprétation** : Un taux de complétion élevé indique que les workflows s'exécutent correctement. Un taux faible peut signaler des problèmes dans la configuration ou l'exécution des workflows.

### Engagement

#### EMAIL_OPEN_RATE

- **Nom** : Taux d'ouverture des emails
- **Description** : Pourcentage d'emails ouverts par les destinataires
- **Formule** : (Nombre d'emails ouverts / Nombre d'emails livrés) * 100
- **Unité** : %
- **Seuils** :
  - Normal : > 15%
  - Avertissement : 10% - 15%
  - Critique : < 10%
- **Interprétation** : Un taux d'ouverture élevé indique un bon niveau d'engagement et d'intérêt des destinataires. Il est influencé par la pertinence de l'objet de l'email, la réputation de l'expéditeur et le moment d'envoi.

#### EMAIL_CLICK_RATE

- **Nom** : Taux de clic des emails
- **Description** : Pourcentage d'emails ayant généré au moins un clic
- **Formule** : (Nombre d'emails cliqués / Nombre d'emails livrés) * 100
- **Unité** : %
- **Seuils** :
  - Normal : > 5%
  - Avertissement : 2% - 5%
  - Critique : < 2%
- **Interprétation** : Un taux de clic élevé indique que le contenu de l'email est pertinent et incite à l'action. Il est influencé par la qualité du contenu, la clarté des appels à l'action et la pertinence de l'offre.

#### UNSUBSCRIBE_RATE

- **Nom** : Taux de désabonnement
- **Description** : Pourcentage d'abonnés qui se désabonnent
- **Formule** : (Nombre de désabonnements / Nombre total d'abonnés) * 100
- **Unité** : %
- **Seuils** :
  - Normal : < 0.5%
  - Avertissement : 0.5% - 1%
  - Critique : > 1%
- **Interprétation** : Un taux de désabonnement faible indique que les destinataires trouvent de la valeur dans les emails reçus. Un taux élevé peut signaler des problèmes de fréquence d'envoi, de pertinence du contenu ou de ciblage.

### Qualité

#### EMAIL_BOUNCE_RATE

- **Nom** : Taux de rebond des emails
- **Description** : Pourcentage d'emails ayant généré un rebond
- **Formule** : (Nombre d'emails ayant rebondi / Nombre total d'emails envoyés) * 100
- **Unité** : %
- **Seuils** :
  - Normal : < 3%
  - Avertissement : 3% - 5%
  - Critique : > 5%
- **Interprétation** : Un taux de rebond faible indique une bonne qualité de la liste d'emails. Un taux élevé peut signaler des problèmes de qualité de la liste, d'adresses obsolètes ou de problèmes techniques.

#### EMAIL_COMPLAINT_RATE

- **Nom** : Taux de plainte
- **Description** : Pourcentage d'emails ayant généré une plainte (spam)
- **Formule** : (Nombre de plaintes / Nombre d'emails livrés) * 100
- **Unité** : %
- **Seuils** :
  - Normal : < 0.1%
  - Avertissement : 0.1% - 0.5%
  - Critique : > 0.5%
- **Interprétation** : Un taux de plainte faible indique que les destinataires s'attendent à recevoir vos emails et les trouvent pertinents. Un taux élevé peut signaler des problèmes de consentement, de fréquence d'envoi ou de pertinence du contenu.

### Performance

#### EMAIL_PROCESSING_TIME

- **Nom** : Temps de traitement des emails
- **Description** : Temps moyen de traitement d'un email (de la demande à l'envoi)
- **Formule** : Moyenne des temps de traitement sur la période d'analyse
- **Unité** : s
- **Seuils** :
  - Normal : < 5 s
  - Avertissement : 5 - 10 s
  - Critique : > 10 s
- **Interprétation** : Un temps de traitement faible indique un processus d'envoi efficace. Un temps élevé peut signaler des problèmes de performance du système, de configuration ou de surcharge.

#### CAMPAIGN_EXECUTION_TIME

- **Nom** : Temps d'exécution des campagnes
- **Description** : Temps moyen d'exécution d'une campagne
- **Formule** : Moyenne des temps d'exécution sur la période d'analyse
- **Unité** : min
- **Seuils** :
  - Normal : < 30 min
  - Avertissement : 30 - 60 min
  - Critique : > 60 min
- **Interprétation** : Un temps d'exécution faible indique un processus de campagne efficace. Un temps élevé peut signaler des problèmes de performance, de configuration ou de complexité excessive.

### Croissance

#### SUBSCRIBER_GROWTH_RATE

- **Nom** : Taux de croissance des abonnés
- **Description** : Pourcentage de croissance du nombre d'abonnés
- **Formule** : ((Nombre actuel d'abonnés - Nombre précédent d'abonnés) / Nombre précédent d'abonnés) * 100
- **Unité** : %
- **Seuils** :
  - Normal : > 1%
  - Avertissement : 0% - 1%
  - Critique : < 0%
- **Interprétation** : Un taux de croissance positif indique une acquisition efficace de nouveaux abonnés. Un taux négatif peut signaler des problèmes d'acquisition ou de rétention.

### Coût

#### COST_PER_EMAIL

- **Nom** : Coût par email
- **Description** : Coût moyen d'envoi d'un email
- **Formule** : Coût total / Nombre total d'emails envoyés
- **Unité** : €
- **Seuils** :
  - Normal : < 0.01 €
  - Avertissement : 0.01 € - 0.02 €
  - Critique : > 0.02 €
- **Interprétation** : Un coût par email faible indique une bonne efficacité économique. Un coût élevé peut signaler des inefficacités dans le processus d'envoi ou des tarifs élevés des fournisseurs.

### Valeur

#### ROI

- **Nom** : Retour sur investissement
- **Description** : Retour sur investissement des campagnes email
- **Formule** : ((Revenu - Coût total) / Coût total) * 100
- **Unité** : %
- **Seuils** :
  - Normal : > 200%
  - Avertissement : 100% - 200%
  - Critique : < 100%
- **Interprétation** : Un ROI élevé indique que les campagnes génèrent un bon retour sur investissement. Un ROI faible peut signaler des problèmes d'efficacité des campagnes ou des coûts trop élevés.

#### REVENUE_PER_EMAIL

- **Nom** : Revenu par email
- **Description** : Revenu moyen généré par email envoyé
- **Formule** : Revenu total / Nombre total d'emails envoyés
- **Unité** : €
- **Seuils** :
  - Normal : > 0.05 €
  - Avertissement : 0.02 € - 0.05 €
  - Critique : < 0.02 €
- **Interprétation** : Un revenu par email élevé indique une bonne efficacité commerciale des campagnes. Un revenu faible peut signaler des problèmes de conversion ou de valeur des offres.

#### CONVERSION_RATE

- **Nom** : Taux de conversion
- **Description** : Pourcentage d'emails ayant généré une conversion
- **Formule** : (Nombre de conversions / Nombre d'emails livrés) * 100
- **Unité** : %
- **Seuils** :
  - Normal : > 1%
  - Avertissement : 0.5% - 1%
  - Critique : < 0.5%
- **Interprétation** : Un taux de conversion élevé indique que les emails sont efficaces pour générer des actions. Un taux faible peut signaler des problèmes dans le parcours de conversion ou la pertinence des offres.

### KPIs composites

#### EMAIL_DELIVERABILITY_INDEX

- **Nom** : Indice de délivrabilité
- **Description** : Indice composite de la délivrabilité des emails
- **Formule** : 0.5 * (EMAIL_DELIVERY_RATE normalisé) + 0.3 * (EMAIL_BOUNCE_RATE normalisé) + 0.2 * (EMAIL_COMPLAINT_RATE normalisé)
- **Unité** : Score (0-1)
- **Seuils** :
  - Normal : < 0.7
  - Avertissement : 0.7 - 0.9
  - Critique : > 0.9
- **Interprétation** : Cet indice fournit une vue d'ensemble de la délivrabilité des emails. Un score élevé indique des problèmes potentiels qui nécessitent une attention immédiate.

#### EMAIL_ENGAGEMENT_INDEX

- **Nom** : Indice d'engagement
- **Description** : Indice composite de l'engagement des destinataires
- **Formule** : 0.4 * (EMAIL_OPEN_RATE normalisé) + 0.4 * (EMAIL_CLICK_RATE normalisé) + 0.2 * (UNSUBSCRIBE_RATE normalisé)
- **Unité** : Score (0-1)
- **Seuils** :
  - Normal : < 0.7
  - Avertissement : 0.7 - 0.9
  - Critique : > 0.9
- **Interprétation** : Cet indice fournit une vue d'ensemble de l'engagement des destinataires. Un score élevé indique des problèmes potentiels d'engagement qui nécessitent une attention.

#### EMAIL_BUSINESS_VALUE_INDEX

- **Nom** : Indice de valeur métier
- **Description** : Indice composite de la valeur métier des campagnes email
- **Formule** : 0.3 * (CONVERSION_RATE normalisé) + 0.4 * (ROI normalisé) + 0.3 * (REVENUE_PER_EMAIL normalisé)
- **Unité** : Score (0-1)
- **Seuils** :
  - Normal : < 0.7
  - Avertissement : 0.7 - 0.9
  - Critique : > 0.9
- **Interprétation** : Cet indice fournit une vue d'ensemble de la valeur métier générée par les campagnes email. Un score élevé indique des problèmes potentiels de rentabilité qui nécessitent une attention.

## Collecte et calcul

Les KPIs métier sont calculés à partir des données collectées par différentes sources :

1. **Plateforme d'emailing** : Statistiques d'envoi, d'ouverture, de clic, etc.
2. **Système de suivi des conversions** : Données de conversion et de revenu
3. **Système de gestion des abonnés** : Données sur les abonnés et les désabonnements
4. **Système de facturation** : Données sur les coûts des campagnes

Le script `business_kpi_calculator.ps1` est responsable du calcul régulier de ces KPIs.

### Fréquence de calcul

- **Quotidien** : La plupart des KPIs sont calculés quotidiennement pour le suivi régulier
- **Hebdomadaire** : Des agrégations hebdomadaires sont calculées pour l'analyse des tendances
- **Mensuel** : Des agrégations mensuelles sont calculées pour l'analyse stratégique

### Sources de données

- Logs de la plateforme d'emailing
- Base de données des abonnés
- Système de suivi des conversions
- Système de facturation

## Visualisation et reporting

Les KPIs métier sont visualisés dans plusieurs tableaux de bord et rapports :

1. **Tableau de bord quotidien** : Affiche les KPIs clés pour le suivi quotidien
2. **Tableau de bord des campagnes** : Montre les KPIs par campagne
3. **Tableau de bord de l'engagement** : Présente les KPIs liés à l'engagement des destinataires
4. **Tableau de bord de la valeur** : Affiche les KPIs liés à la valeur générée
5. **Rapport mensuel** : Résume les performances du mois écoulé avec analyse des tendances

## Intégration avec le système d'alerte

Les KPIs métier sont intégrés au système d'alerte pour permettre la détection proactive des problèmes :

1. **Alertes basées sur les seuils** : Déclenchées lorsqu'un KPI dépasse ses seuils définis
2. **Alertes basées sur les tendances** : Déclenchées lorsqu'un KPI montre une tendance anormale
3. **Alertes composites** : Déclenchées lorsque plusieurs KPIs indiquent un problème potentiel

## Maintenance et évolution

Les définitions des KPIs métier sont régulièrement revues et mises à jour pour s'adapter aux évolutions des besoins métier et des meilleures pratiques. Ce processus comprend :

1. **Revue trimestrielle** : Évaluation de la pertinence et de l'efficacité des KPIs
2. **Ajustement des seuils** : Calibration des seuils en fonction des données historiques et des objectifs métier
3. **Ajout de nouveaux KPIs** : Intégration de nouveaux indicateurs pour couvrir de nouveaux aspects métier
4. **Retrait des KPIs obsolètes** : Suppression des indicateurs qui ne sont plus pertinents

## Annexes

### A. Formules détaillées

Cette section contient les formules détaillées pour le calcul de chaque KPI, y compris les transformations et normalisations appliquées.

### B. Benchmarks par secteur

Cette section présente des benchmarks par secteur d'activité pour les principaux KPIs, permettant de comparer les performances avec les standards de l'industrie.

### C. Historique des modifications

Cette section trace l'historique des modifications apportées aux définitions des KPIs, y compris les ajustements de seuils et les changements de formules.
