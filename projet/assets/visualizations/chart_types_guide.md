# Guide des types de graphiques

Ce document décrit les différents types de graphiques disponibles pour visualiser les données de performance, leurs cas d'utilisation et leurs configurations.

## Types de graphiques

### 1. Graphique linéaire (Line Chart)

**ID**: `time_series_line`

**Description**: Graphique linéaire pour visualiser l'évolution d'une métrique dans le temps.

**Cas d'utilisation**:
- Visualisation de l'évolution d'une métrique sur une période
- Identification des tendances et patterns temporels
- Comparaison de l'évolution de plusieurs métriques

**Exemple**:
```
CPU Usage (%) au fil du temps
```

### 2. Graphique multi-séries (Multi-Series Line Chart)

**ID**: `multi_series_line`

**Description**: Graphique linéaire pour comparer plusieurs métriques dans le temps.

**Cas d'utilisation**:
- Comparaison de plusieurs métriques corrélées
- Analyse des relations entre différentes métriques
- Visualisation des impacts d'une métrique sur une autre

**Exemple**:
```
CPU, Mémoire et Disque au fil du temps
```

### 3. Graphique de zone (Area Chart)

**ID**: `area_chart`

**Description**: Graphique de zone pour visualiser l'évolution et la magnitude d'une métrique.

**Cas d'utilisation**:
- Mise en évidence de la magnitude d'une métrique
- Visualisation des pics et creux
- Représentation des volumes

**Exemple**:
```
Volume de requêtes au fil du temps
```

### 4. Graphique à barres (Bar Chart)

**ID**: `bar_chart`

**Description**: Graphique à barres pour comparer des valeurs discrètes.

**Cas d'utilisation**:
- Comparaison de valeurs entre différentes catégories
- Visualisation de distributions
- Représentation de données agrégées

**Exemple**:
```
Temps de réponse moyen par service
```

### 5. Nuage de points (Scatter Plot)

**ID**: `scatter_plot`

**Description**: Nuage de points pour visualiser la relation entre deux variables.

**Cas d'utilisation**:
- Analyse de corrélation entre deux métriques
- Détection de clusters et d'anomalies
- Identification de patterns dans les données

**Exemple**:
```
Temps de réponse vs Nombre de requêtes
```

## Bonnes pratiques

### Choix du type de graphique

1. **Graphique linéaire**: Utilisez-le pour visualiser l'évolution d'une métrique continue dans le temps.
2. **Graphique de zone**: Utilisez-le lorsque la magnitude est aussi importante que la tendance.
3. **Graphique à barres**: Utilisez-le pour comparer des valeurs entre différentes catégories.
4. **Nuage de points**: Utilisez-le pour analyser la relation entre deux variables.

### Conception visuelle

1. **Échelles**: Choisissez des échelles appropriées pour éviter de déformer la perception des données.
2. **Couleurs**: Utilisez des couleurs contrastées pour distinguer les séries de données.
3. **Légendes**: Incluez des légendes claires pour identifier les séries de données.
4. **Titres et étiquettes**: Utilisez des titres et étiquettes descriptifs pour faciliter la compréhension.

### Interactivité

1. **Tooltips**: Affichez des informations détaillées au survol des points de données.
2. **Zoom**: Permettez aux utilisateurs de zoomer sur des périodes spécifiques.
3. **Filtrage**: Offrez la possibilité de filtrer les données affichées.

## Utilisation du script de génération de graphiques

Le script `trend_charts.ps1` permet de générer des graphiques de tendances à partir des données de performance.

### Exemples d'utilisation

1. Générer tous les types de graphiques pour toutes les métriques:
```powershell
.\scripts\visualization\trend_charts.ps1 -ChartType all -MetricType all
```

2. Générer des graphiques linéaires pour les métriques système:
```powershell
.\scripts\visualization\trend_charts.ps1 -ChartType line -MetricType system
```

3. Générer des graphiques pour une période spécifique:
```powershell
.\scripts\visualization\trend_charts.ps1 -StartDate (Get-Date).AddDays(-30) -EndDate (Get-Date)
```

### Personnalisation

Le script utilise des templates de graphiques définis dans le fichier `templates/charts/chart_templates.json`. Vous pouvez personnaliser ces templates pour adapter les graphiques à vos besoins spécifiques.
