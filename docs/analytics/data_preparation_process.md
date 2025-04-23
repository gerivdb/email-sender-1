# Processus de préparation des données de performance

## Introduction

Ce document décrit le processus d'extraction, de nettoyage, de transformation et de préparation des données historiques de performance pour l'analyse exploratoire. Ce processus est une étape cruciale qui permet d'assurer la qualité et la cohérence des données utilisées pour l'analyse et le développement des modèles prédictifs.

## Sources de données

Le processus de préparation des données intègre les sources suivantes :

1. **Logs système** : Événements système Windows contenant des informations sur les erreurs, avertissements et autres événements système.
2. **Métriques de performance** : Données collectées via les compteurs de performance Windows, incluant l'utilisation CPU, mémoire, disque et réseau.
3. **Logs applicatifs** : Journaux générés par les applications, notamment n8n, les workflows et les scripts PowerShell.

## Étapes du processus

### 1. Extraction des données

Cette étape consiste à extraire les données brutes des différentes sources :

- **Logs système** : Extraction des événements système Windows via `Get-WinEvent`.
- **Métriques de performance** : Collecte des compteurs de performance via `Get-Counter`.
- **Logs applicatifs** : Analyse des fichiers de logs applicatifs.

### 2. Nettoyage des données

Cette étape vise à éliminer les données incorrectes, incomplètes ou non pertinentes :

- **Filtrage des valeurs nulles** : Élimination des entrées sans valeur.
- **Détection des valeurs aberrantes** : Identification et traitement des valeurs statistiquement improbables.
- **Gestion des doublons** : Élimination des entrées dupliquées.
- **Correction des erreurs** : Identification et correction des erreurs de format ou de contenu.

#### Méthode de détection des valeurs aberrantes

Pour les données de performance, nous utilisons la méthode de l'écart interquartile (IQR) :

1. Calcul du premier quartile (Q1) et du troisième quartile (Q3).
2. Calcul de l'écart interquartile : IQR = Q3 - Q1.
3. Définition des limites : 
   - Limite inférieure = Q1 - 1.5 * IQR
   - Limite supérieure = Q3 + 1.5 * IQR
4. Filtrage des valeurs en dehors de ces limites.

### 3. Normalisation des données

Cette étape vise à standardiser les données pour faciliter leur comparaison et leur analyse :

#### Méthodes de normalisation

1. **Min-Max (0-1)** : Transforme les données pour qu'elles soient comprises entre 0 et 1.
   ```
   X_norm = (X - X_min) / (X_max - X_min)
   ```

2. **Z-Score** : Normalise les données en fonction de leur écart à la moyenne.
   ```
   X_norm = (X - μ) / σ
   ```
   où μ est la moyenne et σ est l'écart-type.

3. **Normalisation logarithmique** : Applique une transformation logarithmique pour réduire l'impact des valeurs extrêmes.
   ```
   X_norm = log(X)
   ```

### 4. Structuration des données

Cette étape organise les données dans un format adapté à l'analyse :

- **Format temporel** : Conversion des horodatages en format standard.
- **Agrégation** : Regroupement des données selon différentes dimensions (temps, composant, etc.).
- **Jointure** : Combinaison des données provenant de différentes sources.

### 5. Exportation des données préparées

Les données préparées sont exportées dans des fichiers structurés :

- **Format CSV** : Format principal pour l'analyse avec Python et PowerShell.
- **Format JSON** : Utilisé pour certaines intégrations et visualisations.

## Résultats

Le processus de préparation génère les fichiers suivants dans le répertoire `data/performance` :

1. `prepared_performance_data.csv` : Métriques de performance nettoyées et normalisées.
2. `prepared_system_logs.csv` : Logs système nettoyés et structurés.
3. `prepared_application_logs.csv` : Logs applicatifs nettoyés et structurés.

## Métriques de qualité des données

Pour évaluer la qualité des données préparées, nous utilisons les métriques suivantes :

1. **Complétude** : Pourcentage de valeurs non manquantes.
2. **Exactitude** : Pourcentage de valeurs correctes selon les règles métier.
3. **Cohérence** : Degré de cohérence entre les différentes sources de données.
4. **Unicité** : Absence de doublons dans les données.

## Utilisation

Le script de préparation des données peut être exécuté avec la commande suivante :

```powershell
.\scripts\analytics\data_preparation.ps1 -SourcePath "logs" -OutputPath "data/performance" -StartDate "2025-01-01" -EndDate "2025-03-31" -LogLevel "Info"
```

### Paramètres

- `SourcePath` : Chemin vers les sources de données (logs, métriques, etc.).
- `OutputPath` : Chemin où les données préparées seront sauvegardées.
- `StartDate` : Date de début pour l'extraction des données (format: yyyy-MM-dd).
- `EndDate` : Date de fin pour l'extraction des données (format: yyyy-MM-dd).
- `LogLevel` : Niveau de journalisation (Verbose, Info, Warning, Error).

## Maintenance et mise à jour

Le processus de préparation des données doit être exécuté régulièrement pour maintenir à jour les données d'analyse. La fréquence recommandée est quotidienne, avec une exécution planifiée pendant les heures creuses.

## Dépendances

- PowerShell 5.1 ou supérieur
- Accès aux logs système et applicatifs
- Droits d'administrateur pour accéder aux compteurs de performance

## Limitations connues

1. Les données de performance historiques sont limitées par la rétention des compteurs de performance.
2. Certains logs applicatifs peuvent avoir des formats non standard nécessitant des adaptations spécifiques.
3. La détection des valeurs aberrantes peut nécessiter des ajustements selon le contexte spécifique de chaque métrique.

## Prochaines améliorations

1. Intégration de sources de données supplémentaires (base de données, services cloud).
2. Implémentation de méthodes de détection d'anomalies plus avancées.
3. Optimisation des performances pour le traitement de grands volumes de données.
4. Développement d'une interface utilisateur pour la configuration et le suivi du processus.
