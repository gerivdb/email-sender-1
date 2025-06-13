# Indicateurs Clés de Performance (KPIs) Applicatifs

## Introduction

Ce document définit les indicateurs clés de performance (KPIs) au niveau applicatif qui sont utilisés pour surveiller, analyser et prédire les performances des applications, notamment n8n, les workflows, les API et les scripts PowerShell. Ces KPIs fournissent une vision complète de l'état des applications et permettent d'identifier rapidement les problèmes potentiels.

## Objectifs

Les KPIs applicatifs ont été définis pour répondre aux objectifs suivants :

1. **Surveillance proactive** : Détecter les problèmes avant qu'ils n'impactent les utilisateurs
2. **Analyse des performances** : Comprendre le comportement des applications sous différentes charges
3. **Optimisation des ressources** : Identifier les opportunités d'amélioration des performances
4. **Fiabilité des services** : Assurer un niveau de service conforme aux attentes
5. **Expérience utilisateur** : Garantir une expérience utilisateur optimale

## Catégories de KPIs

Les KPIs applicatifs sont organisés en plusieurs catégories :

1. **Performance** : Mesure de la rapidité et de l'efficacité des applications
2. **Fiabilité** : Mesure de la stabilité et de la disponibilité des applications
3. **Ressources** : Utilisation des ressources système par les applications
4. **Utilisation** : Niveau d'utilisation des applications et services
5. **Global** : Métriques composites et indicateurs de santé générale

## Définition des KPIs

### Performance

#### APP_RESPONSE_TIME

- **Nom** : Temps de réponse
- **Description** : Temps de réponse moyen des requêtes applicatives
- **Formule** : Moyenne des temps de réponse sur la période d'analyse
- **Unité** : ms
- **Seuils** :
  - Normal : < 500 ms
  - Avertissement : 500 - 1000 ms
  - Critique : > 1000 ms
- **Interprétation** : Un temps de réponse élevé peut indiquer des problèmes de performance, des goulots d'étranglement ou une charge excessive. Il impacte directement l'expérience utilisateur et peut entraîner une baisse de satisfaction.

#### APP_THROUGHPUT

- **Nom** : Débit de requêtes
- **Description** : Nombre de requêtes traitées par seconde
- **Formule** : Moyenne du nombre de requêtes par seconde sur la période d'analyse
- **Unité** : req/s
- **Seuils** :
  - Normal : < 100 req/s
  - Avertissement : 100 - 200 req/s
  - Critique : > 200 req/s
- **Interprétation** : Un débit élevé peut indiquer une forte charge sur l'application. Si le débit augmente sans dégradation des performances, cela indique une bonne capacité de mise à l'échelle. Une baisse soudaine peut indiquer des problèmes de disponibilité.

#### N8N_WORKFLOW_EXECUTION_TIME

- **Nom** : Temps d'exécution des workflows n8n
- **Description** : Temps moyen d'exécution des workflows n8n
- **Formule** : Moyenne des temps d'exécution sur la période d'analyse
- **Unité** : s
- **Seuils** :
  - Normal : < 10 s
  - Avertissement : 10 - 30 s
  - Critique : > 30 s
- **Interprétation** : Un temps d'exécution élevé peut indiquer des workflows inefficaces, des problèmes de connexion avec des services externes ou des opérations trop complexes. L'optimisation des workflows peut réduire ce temps.

#### API_RESPONSE_TIME

- **Nom** : Temps de réponse API
- **Description** : Temps de réponse moyen des appels API
- **Formule** : Moyenne des temps de réponse API sur la période d'analyse
- **Unité** : ms
- **Seuils** :
  - Normal : < 200 ms
  - Avertissement : 200 - 500 ms
  - Critique : > 500 ms
- **Interprétation** : Un temps de réponse API élevé peut indiquer des problèmes de performance des services backend, des requêtes inefficaces ou une surcharge des services. Il peut impacter toutes les applications qui dépendent de ces API.

#### SCRIPT_EXECUTION_TIME

- **Nom** : Temps d'exécution des scripts
- **Description** : Temps moyen d'exécution des scripts PowerShell
- **Formule** : Moyenne des temps d'exécution sur la période d'analyse
- **Unité** : s
- **Seuils** :
  - Normal : < 5 s
  - Avertissement : 5 - 15 s
  - Critique : > 15 s
- **Interprétation** : Un temps d'exécution élevé peut indiquer des scripts inefficaces, des opérations bloquantes ou des problèmes de ressources. L'optimisation des scripts et l'utilisation de techniques asynchrones peuvent améliorer les performances.

### Fiabilité

#### APP_ERROR_RATE

- **Nom** : Taux d'erreur
- **Description** : Pourcentage de requêtes ayant généré une erreur
- **Formule** : (Nombre d'erreurs / Nombre total de requêtes) * 100
- **Unité** : %
- **Seuils** :
  - Normal : < 1%
  - Avertissement : 1% - 5%
  - Critique : > 5%
- **Interprétation** : Un taux d'erreur élevé indique des problèmes de fiabilité qui peuvent affecter l'expérience utilisateur. Les erreurs peuvent être dues à des bugs, des problèmes de configuration ou des défaillances de services externes.

#### N8N_WORKFLOW_SUCCESS_RATE

- **Nom** : Taux de succès des workflows n8n
- **Description** : Pourcentage de workflows n8n exécutés avec succès
- **Formule** : (Nombre de workflows réussis / Nombre total de workflows) * 100
- **Unité** : %
- **Seuils** :
  - Normal : > 95%
  - Avertissement : 90% - 95%
  - Critique : < 90%
- **Interprétation** : Un faible taux de succès peut indiquer des problèmes dans la conception des workflows, des erreurs de configuration ou des problèmes avec les services externes. Il est important d'analyser les causes des échecs pour améliorer la fiabilité.

#### API_SUCCESS_RATE

- **Nom** : Taux de succès des appels API
- **Description** : Pourcentage d'appels API réussis (code 2xx/3xx)
- **Formule** : (Nombre d'appels API réussis / Nombre total d'appels API) * 100
- **Unité** : %
- **Seuils** :
  - Normal : > 98%
  - Avertissement : 95% - 98%
  - Critique : < 95%
- **Interprétation** : Un faible taux de succès des API peut indiquer des problèmes de disponibilité, des erreurs de validation ou des problèmes d'authentification. Il est crucial de maintenir un taux élevé pour assurer la fiabilité des services.

#### SCRIPT_ERROR_RATE

- **Nom** : Taux d'erreur des scripts
- **Description** : Pourcentage de scripts ayant généré une erreur
- **Formule** : (Nombre d'erreurs de script / Nombre total d'exécutions de script) * 100
- **Unité** : %
- **Seuils** :
  - Normal : < 2%
  - Avertissement : 2% - 5%
  - Critique : > 5%
- **Interprétation** : Un taux d'erreur élevé dans les scripts peut indiquer des problèmes de robustesse, des erreurs de syntaxe ou des problèmes avec les ressources manipulées. L'amélioration de la gestion des erreurs et des tests peut réduire ce taux.

### Ressources

#### APP_CPU_USAGE

- **Nom** : Utilisation CPU par l'application
- **Description** : Pourcentage d'utilisation CPU par les processus de l'application
- **Formule** : Moyenne du pourcentage d'utilisation CPU sur la période d'analyse
- **Unité** : %
- **Seuils** :
  - Normal : < 60%
  - Avertissement : 60% - 80%
  - Critique : > 80%
- **Interprétation** : Une utilisation CPU élevée peut indiquer des processus inefficaces, des boucles infinies ou une charge excessive. Elle peut entraîner des ralentissements et affecter d'autres applications sur le même système.

#### APP_MEMORY_USAGE

- **Nom** : Utilisation mémoire par l'application
- **Description** : Quantité de mémoire utilisée par les processus de l'application
- **Formule** : Moyenne de la mémoire utilisée sur la période d'analyse
- **Unité** : MB
- **Seuils** :
  - Normal : < 1024 MB
  - Avertissement : 1024 - 2048 MB
  - Critique : > 2048 MB
- **Interprétation** : Une utilisation mémoire élevée peut indiquer des fuites mémoire, une mauvaise gestion des ressources ou une configuration inadéquate. Elle peut entraîner des problèmes de performance et des crashs.

#### SCRIPT_CPU_USAGE

- **Nom** : Utilisation CPU par les scripts
- **Description** : Pourcentage d'utilisation CPU par les scripts PowerShell
- **Formule** : Moyenne du pourcentage d'utilisation CPU sur la période d'analyse
- **Unité** : %
- **Seuils** :
  - Normal : < 50%
  - Avertissement : 50% - 70%
  - Critique : > 70%
- **Interprétation** : Une utilisation CPU élevée par les scripts peut indiquer des opérations intensives, des algorithmes inefficaces ou des boucles mal optimisées. L'optimisation des scripts peut réduire cette utilisation.

### Utilisation

#### APP_CONCURRENT_USERS

- **Nom** : Utilisateurs concurrents
- **Description** : Nombre d'utilisateurs actifs simultanément
- **Formule** : Moyenne du nombre d'utilisateurs actifs sur la période d'analyse
- **Unité** : utilisateurs
- **Seuils** :
  - Normal : < 50 utilisateurs
  - Avertissement : 50 - 100 utilisateurs
  - Critique : > 100 utilisateurs
- **Interprétation** : Un nombre élevé d'utilisateurs concurrents peut indiquer une forte adoption de l'application, mais aussi potentiellement une charge excessive. Il est important de dimensionner les ressources en fonction de ce nombre.

#### N8N_ACTIVE_WORKFLOWS

- **Nom** : Workflows n8n actifs
- **Description** : Nombre de workflows n8n actifs
- **Formule** : Nombre de workflows actifs à un moment donné
- **Unité** : workflows
- **Seuils** :
  - Normal : < 20 workflows
  - Avertissement : 20 - 30 workflows
  - Critique : > 30 workflows
- **Interprétation** : Un nombre élevé de workflows actifs peut indiquer une forte utilisation de n8n, mais aussi potentiellement une charge excessive sur le système. Il est important de surveiller l'impact sur les ressources.

#### API_RATE_LIMIT

- **Nom** : Utilisation des limites d'API
- **Description** : Pourcentage d'utilisation des limites de taux d'API
- **Formule** : (Nombre d'appels API / Limite de taux) * 100
- **Unité** : %
- **Seuils** :
  - Normal : < 80%
  - Avertissement : 80% - 95%
  - Critique : > 95%
- **Interprétation** : Une utilisation élevée des limites de taux peut indiquer un risque de throttling ou de blocage par les fournisseurs d'API. Il est important de gérer cette utilisation pour éviter les interruptions de service.

### KPIs composites

#### APP_HEALTH_INDEX

- **Nom** : Indice de santé applicative
- **Description** : Indice composite de santé des applications
- **Formule** : 0.4 * (APP_RESPONSE_TIME normalisé) + 0.4 * (APP_ERROR_RATE normalisé) + 0.2 * (APP_THROUGHPUT normalisé)
- **Unité** : Score (0-1)
- **Seuils** :
  - Normal : < 0.7
  - Avertissement : 0.7 - 0.9
  - Critique : > 0.9
- **Interprétation** : Cet indice fournit une vue d'ensemble de la santé des applications. Un score élevé indique des problèmes potentiels qui nécessitent une attention immédiate.

#### N8N_HEALTH_INDEX

- **Nom** : Indice de santé n8n
- **Description** : Indice composite de santé de n8n
- **Formule** : 0.5 * (N8N_WORKFLOW_SUCCESS_RATE normalisé) + 0.3 * (N8N_WORKFLOW_EXECUTION_TIME normalisé) + 0.2 * (N8N_ACTIVE_WORKFLOWS normalisé)
- **Unité** : Score (0-1)
- **Seuils** :
  - Normal : < 0.7
  - Avertissement : 0.7 - 0.9
  - Critique : > 0.9
- **Interprétation** : Cet indice fournit une vue d'ensemble de la santé de n8n. Un score élevé indique des problèmes potentiels avec les workflows ou la plateforme n8n.

#### API_HEALTH_INDEX

- **Nom** : Indice de santé API
- **Description** : Indice composite de santé des API
- **Formule** : 0.5 * (API_SUCCESS_RATE normalisé) + 0.3 * (API_RESPONSE_TIME normalisé) + 0.2 * (API_RATE_LIMIT normalisé)
- **Unité** : Score (0-1)
- **Seuils** :
  - Normal : < 0.7
  - Avertissement : 0.7 - 0.9
  - Critique : > 0.9
- **Interprétation** : Cet indice fournit une vue d'ensemble de la santé des API. Un score élevé indique des problèmes potentiels avec les services API qui nécessitent une attention.

## Collecte et calcul

Les KPIs applicatifs sont calculés à partir des données de performance collectées par différentes sources :

1. **Logs applicatifs** : Analyse des logs pour extraire les temps de réponse, les erreurs, etc.
2. **Métriques n8n** : Collecte des métriques de performance des workflows n8n
3. **Métriques API** : Collecte des statistiques d'appels API et des temps de réponse
4. **Métriques de scripts** : Instrumentation des scripts PowerShell pour collecter des métriques de performance

Le script `application_kpi_calculator.ps1` est responsable du calcul régulier de ces KPIs.

### Fréquence de calcul

- **Temps réel** : Certains KPIs critiques sont calculés en temps réel pour la détection immédiate des problèmes
- **Horaire** : La plupart des KPIs sont calculés toutes les heures pour le suivi régulier
- **Quotidien** : Des agrégations quotidiennes sont calculées pour l'analyse des tendances
- **Hebdomadaire/Mensuel** : Des agrégations à plus long terme sont calculées pour l'analyse des patterns

### Sources de données

- Logs applicatifs (IIS, nginx, application custom)
- API n8n pour les métriques de workflows
- Instrumentation des scripts PowerShell
- Compteurs de performance Windows pour les métriques de ressources

## Visualisation et reporting

Les KPIs applicatifs sont visualisés dans plusieurs tableaux de bord et rapports :

1. **Tableau de bord en temps réel** : Affiche l'état actuel des KPIs critiques
2. **Tableau de bord des performances** : Montre l'évolution des KPIs de performance sur différentes périodes
3. **Tableau de bord de fiabilité** : Présente les KPIs liés à la stabilité et aux erreurs
4. **Rapports quotidiens** : Résume les performances applicatives sur les dernières 24 heures
5. **Rapports hebdomadaires** : Analyse les tendances sur la semaine écoulée

## Intégration avec le système d'alerte

Les KPIs applicatifs sont intégrés au système d'alerte pour permettre la détection proactive des problèmes :

1. **Alertes basées sur les seuils** : Déclenchées lorsqu'un KPI dépasse ses seuils définis
2. **Alertes basées sur les tendances** : Déclenchées lorsqu'un KPI montre une tendance anormale
3. **Alertes composites** : Déclenchées lorsque plusieurs KPIs indiquent un problème potentiel
4. **Alertes prédictives** : Déclenchées lorsque les modèles prédisent qu'un KPI dépassera ses seuils

## Maintenance et évolution

Les définitions des KPIs applicatifs sont régulièrement revues et mises à jour pour s'adapter aux évolutions des applications et des besoins métier. Ce processus comprend :

1. **Revue périodique** : Évaluation trimestrielle de la pertinence et de l'efficacité des KPIs
2. **Ajustement des seuils** : Calibration des seuils en fonction des données historiques et des objectifs de performance
3. **Ajout de nouveaux KPIs** : Intégration de nouveaux indicateurs pour couvrir de nouvelles fonctionnalités ou applications
4. **Retrait des KPIs obsolètes** : Suppression des indicateurs qui ne sont plus pertinents

## Annexes

### A. Formules détaillées

Cette section contient les formules détaillées pour le calcul de chaque KPI, y compris les transformations et normalisations appliquées.

### B. Mapping des sources de données

Cette section détaille les sources de données spécifiques utilisées pour calculer chaque KPI.

### C. Historique des modifications

Cette section trace l'historique des modifications apportées aux définitions des KPIs, y compris les ajustements de seuils et les changements de formules.
