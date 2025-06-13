# Indicateurs Clés de Performance (KPIs) Système

## Introduction

Ce document définit les indicateurs clés de performance (KPIs) au niveau système qui sont utilisés pour surveiller, analyser et prédire les performances de l'infrastructure. Ces KPIs fournissent une vision complète de l'état du système et permettent d'identifier rapidement les problèmes potentiels.

## Objectifs

Les KPIs système ont été définis pour répondre aux objectifs suivants :

1. **Surveillance proactive** : Détecter les problèmes avant qu'ils n'impactent les utilisateurs
2. **Analyse des tendances** : Comprendre l'évolution des performances dans le temps
3. **Planification des capacités** : Anticiper les besoins en ressources
4. **Optimisation des performances** : Identifier les goulots d'étranglement et les opportunités d'amélioration
5. **Prédiction des incidents** : Alimenter les modèles prédictifs pour anticiper les problèmes

## Catégories de KPIs

Les KPIs système sont organisés en plusieurs catégories :

1. **Processeur (CPU)** : Utilisation et performance du processeur
2. **Mémoire** : Utilisation et disponibilité de la mémoire physique
3. **Stockage** : Utilisation de l'espace disque et performance des opérations d'E/S
4. **Réseau** : Débit, latence et erreurs de communication réseau
5. **Système global** : Métriques composites et indicateurs de santé générale

## Définition des KPIs

### Processeur (CPU)

#### CPU_UTILIZATION

- **Nom** : Utilisation CPU
- **Description** : Pourcentage moyen d'utilisation du CPU
- **Formule** : Moyenne du pourcentage d'utilisation CPU sur la période d'analyse
- **Unité** : %
- **Seuils** :
  - Normal : < 70%
  - Avertissement : 70% - 90%
  - Critique : > 90%
- **Interprétation** : Une utilisation CPU élevée peut indiquer un manque de ressources de calcul, des processus inefficaces ou des pics d'activité. Une utilisation constamment élevée nécessite généralement une augmentation des ressources ou une optimisation des applications.

#### CPU_PEAK

- **Nom** : Pic d'utilisation CPU
- **Description** : Valeur maximale d'utilisation du CPU
- **Formule** : Maximum du pourcentage d'utilisation CPU sur la période d'analyse
- **Unité** : %
- **Seuils** :
  - Normal : < 85%
  - Avertissement : 85% - 95%
  - Critique : > 95%
- **Interprétation** : Des pics d'utilisation CPU fréquents peuvent indiquer des processus intensifs périodiques ou des problèmes de dimensionnement. Ils peuvent causer des ralentissements temporaires mais significatifs.

### Mémoire

#### MEMORY_UTILIZATION

- **Nom** : Utilisation mémoire
- **Description** : Pourcentage d'utilisation de la mémoire physique
- **Formule** : Moyenne du pourcentage d'utilisation de la mémoire sur la période d'analyse
- **Unité** : %
- **Seuils** :
  - Normal : < 80%
  - Avertissement : 80% - 95%
  - Critique : > 95%
- **Interprétation** : Une utilisation mémoire élevée peut entraîner du swapping et dégrader significativement les performances. Elle peut indiquer des fuites mémoire, un dimensionnement insuffisant ou des applications gourmandes en ressources.

#### MEMORY_AVAILABLE

- **Nom** : Mémoire disponible
- **Description** : Quantité de mémoire physique disponible
- **Formule** : Moyenne de la mémoire disponible sur la période d'analyse
- **Unité** : MB
- **Seuils** :
  - Normal : > 1024 MB
  - Avertissement : 512 MB - 1024 MB
  - Critique : < 512 MB
- **Interprétation** : Une faible quantité de mémoire disponible peut entraîner des problèmes de performance, notamment du swapping et des temps de réponse dégradés. Ce KPI est particulièrement important pour les applications à forte intensité mémoire.

### Stockage

#### DISK_UTILIZATION

- **Nom** : Utilisation disque
- **Description** : Pourcentage d'utilisation de l'espace disque
- **Formule** : Moyenne du pourcentage d'utilisation de l'espace disque sur la période d'analyse
- **Unité** : %
- **Seuils** :
  - Normal : < 85%
  - Avertissement : 85% - 95%
  - Critique : > 95%
- **Interprétation** : Une utilisation élevée de l'espace disque peut entraîner des problèmes de performance et des erreurs d'écriture. Il est recommandé de maintenir au moins 15% d'espace libre pour les opérations système et la défragmentation.

#### DISK_READ_RATE

- **Nom** : Taux de lecture disque
- **Description** : Nombre d'opérations de lecture par seconde
- **Formule** : Moyenne du nombre d'opérations de lecture par seconde sur la période d'analyse
- **Unité** : IOPS
- **Seuils** :
  - Normal : < 5000 IOPS
  - Avertissement : 5000 - 10000 IOPS
  - Critique : > 10000 IOPS
- **Interprétation** : Un taux de lecture élevé peut indiquer des applications intensives en I/O ou des problèmes de cache. Il peut être nécessaire d'optimiser les requêtes ou d'améliorer le sous-système de stockage.

#### DISK_WRITE_RATE

- **Nom** : Taux d'écriture disque
- **Description** : Nombre d'opérations d'écriture par seconde
- **Formule** : Moyenne du nombre d'opérations d'écriture par seconde sur la période d'analyse
- **Unité** : IOPS
- **Seuils** :
  - Normal : < 3000 IOPS
  - Avertissement : 3000 - 7000 IOPS
  - Critique : > 7000 IOPS
- **Interprétation** : Un taux d'écriture élevé peut indiquer des opérations intensives de journalisation, des sauvegardes ou des problèmes d'application. Les écritures sont généralement plus coûteuses en ressources que les lectures.

#### DISK_QUEUE_LENGTH

- **Nom** : Longueur de la file d'attente disque
- **Description** : Nombre moyen de requêtes en attente
- **Formule** : Moyenne de la longueur de la file d'attente disque sur la période d'analyse
- **Unité** : Requêtes
- **Seuils** :
  - Normal : < 2 requêtes
  - Avertissement : 2 - 5 requêtes
  - Critique : > 5 requêtes
- **Interprétation** : Une file d'attente longue indique que le sous-système de stockage est saturé et ne peut pas traiter les requêtes assez rapidement. Cela entraîne des latences élevées et des temps de réponse dégradés.

### Réseau

#### NETWORK_THROUGHPUT_IN

- **Nom** : Débit réseau entrant
- **Description** : Débit réseau entrant
- **Formule** : Moyenne du débit réseau entrant sur la période d'analyse
- **Unité** : MB/s
- **Seuils** :
  - Normal : < 50 MB/s
  - Avertissement : 50 - 80 MB/s
  - Critique : > 80 MB/s
- **Interprétation** : Un débit entrant élevé peut indiquer un trafic intense ou des attaques potentielles. Il est important de corréler ce KPI avec les patterns d'utilisation normaux.

#### NETWORK_THROUGHPUT_OUT

- **Nom** : Débit réseau sortant
- **Description** : Débit réseau sortant
- **Formule** : Moyenne du débit réseau sortant sur la période d'analyse
- **Unité** : MB/s
- **Seuils** :
  - Normal : < 50 MB/s
  - Avertissement : 50 - 80 MB/s
  - Critique : > 80 MB/s
- **Interprétation** : Un débit sortant élevé peut indiquer des transferts de données massifs, des sauvegardes ou des fuites de données potentielles. Il est important de comprendre les patterns normaux de trafic sortant.

#### NETWORK_ERRORS

- **Nom** : Erreurs réseau
- **Description** : Nombre d'erreurs réseau par minute
- **Formule** : Somme des erreurs réseau sur la période d'analyse, normalisée par minute
- **Unité** : Erreurs/min
- **Seuils** :
  - Normal : < 10 erreurs/min
  - Avertissement : 10 - 50 erreurs/min
  - Critique : > 50 erreurs/min
- **Interprétation** : Un nombre élevé d'erreurs réseau peut indiquer des problèmes de connectivité, de configuration ou de matériel. Les erreurs réseau peuvent entraîner des retransmissions et dégrader les performances des applications.

### Système global

#### SYSTEM_UPTIME

- **Nom** : Temps de fonctionnement
- **Description** : Durée depuis le dernier redémarrage
- **Formule** : Maximum du temps de fonctionnement sur la période d'analyse
- **Unité** : Heures
- **Seuils** :
  - Normal : < 720 heures (30 jours)
  - Avertissement : 720 - 1440 heures (30 - 60 jours)
  - Critique : > 1440 heures (60 jours)
- **Interprétation** : Un temps de fonctionnement très long peut indiquer l'absence de maintenance régulière ou de mises à jour de sécurité. Des redémarrages périodiques sont souvent nécessaires pour appliquer les mises à jour et nettoyer les ressources.

#### PROCESS_COUNT

- **Nom** : Nombre de processus
- **Description** : Nombre total de processus en cours d'exécution
- **Formule** : Moyenne du nombre de processus sur la période d'analyse
- **Unité** : Processus
- **Seuils** :
  - Normal : < 200 processus
  - Avertissement : 200 - 300 processus
  - Critique : > 300 processus
- **Interprétation** : Un nombre élevé de processus peut indiquer des applications mal configurées, des fuites de processus ou des attaques. Il peut entraîner une surcharge du système et des problèmes de performance.

#### THREAD_COUNT

- **Nom** : Nombre de threads
- **Description** : Nombre total de threads en cours d'exécution
- **Formule** : Moyenne du nombre de threads sur la période d'analyse
- **Unité** : Threads
- **Seuils** :
  - Normal : < 2000 threads
  - Avertissement : 2000 - 3000 threads
  - Critique : > 3000 threads
- **Interprétation** : Un nombre élevé de threads peut indiquer des applications inefficaces, des problèmes de concurrence ou des fuites de threads. Il peut entraîner une surcharge du système et des problèmes de performance.

#### HANDLE_COUNT

- **Nom** : Nombre de handles
- **Description** : Nombre total de handles ouverts
- **Formule** : Moyenne du nombre de handles sur la période d'analyse
- **Unité** : Handles
- **Seuils** :
  - Normal : < 50000 handles
  - Avertissement : 50000 - 100000 handles
  - Critique : > 100000 handles
- **Interprétation** : Un nombre élevé de handles peut indiquer des fuites de ressources ou des applications mal conçues. Il peut entraîner une dégradation des performances et des erreurs d'allocation de ressources.

### KPIs composites

#### SYSTEM_LOAD

- **Nom** : Charge système
- **Description** : Indice de charge système composite (CPU, mémoire, disque)
- **Formule** : 0.4 * (CPU_UTILIZATION / 100) + 0.3 * (MEMORY_UTILIZATION / 100) + 0.3 * (DISK_UTILIZATION / 100)
- **Unité** : Score (0-1)
- **Seuils** :
  - Normal : < 0.7
  - Avertissement : 0.7 - 0.9
  - Critique : > 0.9
- **Interprétation** : Ce KPI composite fournit une vue d'ensemble de la charge du système. Un score élevé indique que le système est globalement sous pression et peut nécessiter une attention immédiate.

#### IO_PERFORMANCE

- **Nom** : Performance E/S
- **Description** : Indice de performance des opérations d'entrée/sortie
- **Formule** : Combinaison pondérée des KPIs liés aux opérations d'E/S
- **Unité** : Score (0-1)
- **Seuils** :
  - Normal : < 0.7
  - Avertissement : 0.7 - 0.9
  - Critique : > 0.9
- **Interprétation** : Ce KPI composite évalue la performance globale du sous-système de stockage. Un score élevé indique des problèmes potentiels de performance d'E/S qui peuvent affecter de nombreuses applications.

#### NETWORK_PERFORMANCE

- **Nom** : Performance réseau
- **Description** : Indice de performance réseau
- **Formule** : Combinaison pondérée des KPIs liés au réseau
- **Unité** : Score (0-1)
- **Seuils** :
  - Normal : < 0.7
  - Avertissement : 0.7 - 0.9
  - Critique : > 0.9
- **Interprétation** : Ce KPI composite évalue la performance globale du réseau. Un score élevé indique des problèmes potentiels de connectivité ou de bande passante qui peuvent affecter les communications.

## Collecte et calcul

Les KPIs système sont calculés à partir des données de performance collectées par les compteurs de performance Windows, les logs système et d'autres sources de télémétrie. Le script `system_kpi_calculator.ps1` est responsable du calcul régulier de ces KPIs.

### Fréquence de calcul

- **Temps réel** : Certains KPIs critiques sont calculés en temps réel pour la détection immédiate des problèmes
- **Horaire** : La plupart des KPIs sont calculés toutes les heures pour le suivi régulier
- **Quotidien** : Des agrégations quotidiennes sont calculées pour l'analyse des tendances
- **Hebdomadaire/Mensuel** : Des agrégations à plus long terme sont calculées pour la planification des capacités

### Sources de données

- Compteurs de performance Windows
- Logs d'événements système
- WMI (Windows Management Instrumentation)
- Outils de monitoring tiers

## Visualisation et reporting

Les KPIs système sont visualisés dans plusieurs tableaux de bord et rapports :

1. **Tableau de bord en temps réel** : Affiche l'état actuel des KPIs critiques
2. **Tableau de bord des tendances** : Montre l'évolution des KPIs sur différentes périodes
3. **Rapports quotidiens** : Résume les performances du système sur les dernières 24 heures
4. **Rapports hebdomadaires** : Analyse les tendances sur la semaine écoulée
5. **Rapports mensuels** : Fournit une vue d'ensemble pour la planification des capacités

## Intégration avec le système d'alerte

Les KPIs système sont intégrés au système d'alerte pour permettre la détection proactive des problèmes :

1. **Alertes basées sur les seuils** : Déclenchées lorsqu'un KPI dépasse ses seuils définis
2. **Alertes basées sur les tendances** : Déclenchées lorsqu'un KPI montre une tendance anormale
3. **Alertes composites** : Déclenchées lorsque plusieurs KPIs indiquent un problème potentiel
4. **Alertes prédictives** : Déclenchées lorsque les modèles prédisent qu'un KPI dépassera ses seuils

## Maintenance et évolution

Les définitions des KPIs système sont régulièrement revues et mises à jour pour s'adapter aux évolutions de l'infrastructure et des besoins métier. Ce processus comprend :

1. **Revue périodique** : Évaluation trimestrielle de la pertinence et de l'efficacité des KPIs
2. **Ajustement des seuils** : Calibration des seuils en fonction des données historiques et des objectifs de performance
3. **Ajout de nouveaux KPIs** : Intégration de nouveaux indicateurs pour couvrir de nouveaux aspects ou technologies
4. **Retrait des KPIs obsolètes** : Suppression des indicateurs qui ne sont plus pertinents

## Annexes

### A. Formules détaillées

Cette section contient les formules détaillées pour le calcul de chaque KPI, y compris les transformations et normalisations appliquées.

### B. Mapping des compteurs de performance

Cette section détaille les compteurs de performance Windows spécifiques utilisés pour calculer chaque KPI.

### C. Historique des modifications

Cette section trace l'historique des modifications apportées aux définitions des KPIs, y compris les ajustements de seuils et les changements de formules.
