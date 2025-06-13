# Formules d'erreur absolue et relative pour la conservation de la moyenne

## 1. Introduction

Ce document établit les formules d'erreur absolue et relative pour évaluer la conservation de la moyenne dans les histogrammes de latence. La moyenne est une statistique fondamentale qui caractérise la tendance centrale d'une distribution. Pour les distributions de latence de blocs de 2KB, la conservation précise de la moyenne est essentielle pour garantir que l'histogramme représente fidèlement le comportement moyen du système, permettant des comparaisons valides entre différentes configurations et l'identification correcte des dégradations de performance.

## 2. Définitions fondamentales

### 2.1 Moyenne d'une distribution continue

Pour une distribution continue avec fonction de densité de probabilité f(x), la moyenne est définie par :

```plaintext
μ = ∫ x·f(x) dx
```plaintext
où l'intégration est effectuée sur l'ensemble du domaine de la distribution.

### 2.2 Moyenne d'un échantillon

Pour un échantillon de n observations {x₁, x₂, ..., xₙ}, la moyenne empirique est :

```plaintext
x̄ = (1/n) · Σ xᵢ
```plaintext
### 2.3 Moyenne d'un histogramme

Pour un histogramme avec k bins, où chaque bin i a une valeur centrale xᵢ et une fréquence relative fᵢ, la moyenne est :

```plaintext
μₕ = Σ xᵢ·fᵢ
```plaintext
où la somme est effectuée sur tous les bins de l'histogramme.

## 3. Formules d'erreur pour la conservation de la moyenne

### 3.1 Erreur absolue de la moyenne (EAM)

L'erreur absolue de la moyenne quantifie la différence absolue entre la moyenne de la distribution réelle et celle de l'histogramme :

```plaintext
EAM = |μ - μₕ|
```plaintext
où :
- μ est la moyenne de la distribution réelle
- μₕ est la moyenne de l'histogramme

#### 3.1.1 Unités et interprétation

- **Unités** : Microsecondes (μs) pour les latences
- **Interprétation** : Représente l'écart absolu entre les moyennes, dans les mêmes unités que les données originales
- **Avantages** : Facilement interprétable, directement comparable aux valeurs de latence
- **Limitations** : Ne tient pas compte de l'échelle des données, difficile à comparer entre différentes distributions

### 3.2 Erreur relative de la moyenne (ERM)

L'erreur relative de la moyenne exprime l'erreur absolue en pourcentage de la moyenne réelle :

```plaintext
ERM = |μ - μₕ| / μ × 100%
```plaintext
#### 3.2.1 Unités et interprétation

- **Unités** : Pourcentage (%)
- **Interprétation** : Représente l'écart relatif entre les moyennes
- **Avantages** : Indépendant de l'échelle, facilite la comparaison entre différentes distributions
- **Limitations** : Peut être instable pour les moyennes proches de zéro

### 3.3 Erreur normalisée de la moyenne (ENM)

L'erreur normalisée de la moyenne exprime l'erreur absolue en unités d'écart-type de la distribution :

```plaintext
ENM = |μ - μₕ| / σ
```plaintext
où σ est l'écart-type de la distribution réelle.

#### 3.3.1 Unités et interprétation

- **Unités** : Sans unité (nombre d'écarts-types)
- **Interprétation** : Représente l'écart entre les moyennes en termes de variabilité naturelle des données
- **Avantages** : Tient compte de la dispersion des données, plus robuste aux valeurs aberrantes
- **Limitations** : Nécessite une estimation fiable de l'écart-type

## 4. Propriétés théoriques

### 4.1 Biais de la moyenne dans les histogrammes

Pour un histogramme à largeur de bin fixe, la moyenne est théoriquement non biaisée si :
1. Les observations sont uniformément réparties au sein de chaque bin
2. Les valeurs centrales des bins sont correctement définies

Dans la pratique, des biais peuvent apparaître en raison de :
- La discrétisation des données continues
- L'asymétrie de la distribution au sein des bins
- Le traitement des valeurs extrêmes

### 4.2 Erreur théorique due à la discrétisation

Pour une distribution continue f(x) discrétisée en k bins de largeur h, l'erreur théorique sur la moyenne est de l'ordre de O(h²) si les centres des bins sont correctement définis.

### 4.3 Impact du nombre de bins

L'erreur sur la moyenne diminue généralement avec l'augmentation du nombre de bins, suivant approximativement une relation :

```plaintext
EAM ∝ 1/k²
```plaintext
où k est le nombre de bins.

## 5. Formules spécifiques pour les distributions de latence de blocs de 2KB

### 5.1 Erreur pondérée par région (EPR)

Pour les distributions de latence multimodales, une erreur pondérée par région peut être plus informative :

```plaintext
EPR = Σ wᵣ · |μᵣ - μₕᵣ| / μᵣ
```plaintext
où :
- r indexe les différentes régions (L1/L2, L3/Mémoire, Cache Système, Stockage)
- wᵣ est le poids attribué à chaque région (typiquement proportionnel à l'importance opérationnelle)
- μᵣ est la moyenne réelle dans la région r
- μₕᵣ est la moyenne de l'histogramme dans la région r

### 5.2 Erreur de conservation de la hiérarchie (ECH)

Cette métrique évalue si l'histogramme préserve correctement les relations d'ordre entre les moyennes des différentes régions :

```plaintext
ECH = 1 - (nombre de paires de régions dont l'ordre est inversé) / (nombre total de paires de régions)
```plaintext
Une valeur de 1.0 indique une préservation parfaite de la hiérarchie des moyennes.

## 6. Implémentation et calcul

### 6.1 Calcul de la moyenne réelle

```python
def calculate_real_mean(data):
    """
    Calcule la moyenne réelle d'un ensemble de données.
    
    Args:
        data: Array des mesures de latence
        
    Returns:
        mean: Moyenne des données
    """
    return np.mean(data)
```plaintext
### 6.2 Calcul de la moyenne d'un histogramme

```python
def calculate_histogram_mean(bin_edges, bin_counts):
    """
    Calcule la moyenne d'un histogramme.
    
    Args:
        bin_edges: Limites des bins
        bin_counts: Comptage par bin
        
    Returns:
        mean: Moyenne de l'histogramme
    """
    # Calculer les centres des bins

    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2
    
    # Calculer les fréquences relatives

    total_count = np.sum(bin_counts)
    if total_count == 0:
        return 0
    
    frequencies = bin_counts / total_count
    
    # Calculer la moyenne

    mean = np.sum(bin_centers * frequencies)
    
    return mean
```plaintext
### 6.3 Calcul des erreurs de conservation de la moyenne

```python
def calculate_mean_conservation_errors(real_data, bin_edges, bin_counts):
    """
    Calcule les erreurs de conservation de la moyenne.
    
    Args:
        real_data: Données réelles
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme
        
    Returns:
        errors: Dictionnaire des erreurs calculées
    """
    # Calculer les moyennes

    real_mean = calculate_real_mean(real_data)
    hist_mean = calculate_histogram_mean(bin_edges, bin_counts)
    
    # Calculer l'écart-type réel

    real_std = np.std(real_data)
    
    # Calculer les erreurs

    absolute_error = abs(real_mean - hist_mean)
    relative_error = absolute_error / real_mean * 100 if real_mean != 0 else float('inf')
    normalized_error = absolute_error / real_std if real_std != 0 else float('inf')
    
    # Résultats

    errors = {
        "real_mean": real_mean,
        "histogram_mean": hist_mean,
        "absolute_error": absolute_error,
        "relative_error": relative_error,
        "normalized_error": normalized_error
    }
    
    return errors
```plaintext
## 7. Seuils recommandés pour les latences de blocs de 2KB

| Métrique | Excellent | Bon | Acceptable | Insuffisant |
|----------|-----------|-----|------------|-------------|
| **EAM** | < 5 μs | < 15 μs | < 30 μs | > 30 μs |
| **ERM** | < 1% | < 3% | < 5% | > 5% |
| **ENM** | < 0.05 | < 0.1 | < 0.2 | > 0.2 |

Ces seuils peuvent varier selon le contexte d'utilisation :

| Contexte | EAM | ERM | ENM |
|----------|-----|-----|-----|
| **Monitoring opérationnel** | < 30 μs | < 5% | < 0.2 |
| **Analyse comparative** | < 15 μs | < 3% | < 0.1 |
| **Optimisation système** | < 10 μs | < 2% | < 0.1 |
| **Recherche et développement** | < 5 μs | < 1% | < 0.05 |

## 8. Représentation JSON

```json
{
  "meanConservationMetrics": {
    "absoluteMeanError": {
      "definition": "Absolute difference between real and histogram means",
      "formula": "|μ - μₕ|",
      "unit": "microseconds",
      "thresholds": {
        "excellent": "< 5",
        "good": "< 15",
        "acceptable": "< 30",
        "insufficient": "> 30"
      }
    },
    "relativeMeanError": {
      "definition": "Relative difference between real and histogram means",
      "formula": "|μ - μₕ| / μ × 100%",
      "unit": "percentage",
      "thresholds": {
        "excellent": "< 1%",
        "good": "< 3%",
        "acceptable": "< 5%",
        "insufficient": "> 5%"
      }
    },
    "normalizedMeanError": {
      "definition": "Mean error normalized by standard deviation",
      "formula": "|μ - μₕ| / σ",
      "unit": "dimensionless",
      "thresholds": {
        "excellent": "< 0.05",
        "good": "< 0.1",
        "acceptable": "< 0.2",
        "insufficient": "> 0.2"
      }
    }
  }
}
```plaintext
## 9. Exemples d'application

### 9.1 Cas d'étude: Histogramme à 20 bins uniformes

Pour une distribution de latence de blocs de 2KB typique :

| Statistique | Valeur |
|-------------|--------|
| Moyenne réelle | 350 μs |
| Moyenne histogramme | 365 μs |
| EAM | 15 μs |
| ERM | 4.3% |
| ENM | 0.12 |

Évaluation : Bon pour EAM, Acceptable pour ERM et ENM

### 9.2 Cas d'étude: Histogramme à largeur variable optimisée

| Statistique | Valeur |
|-------------|--------|
| Moyenne réelle | 350 μs |
| Moyenne histogramme | 353 μs |
| EAM | 3 μs |
| ERM | 0.9% |
| ENM | 0.02 |

Évaluation : Excellent pour toutes les métriques

## 10. Conclusion

Les formules d'erreur absolue et relative pour la conservation de la moyenne fournissent un cadre quantitatif pour évaluer la fidélité avec laquelle un histogramme représente la tendance centrale d'une distribution de latence. Pour les distributions de latence de blocs de 2KB, ces métriques sont particulièrement importantes car:

1. **Comparaison des performances**: La moyenne est souvent utilisée comme métrique primaire pour comparer les performances entre différentes configurations.

2. **Détection des dégradations**: Une représentation fidèle de la moyenne est essentielle pour détecter les dégradations subtiles de performance.

3. **Calibration des seuils d'alerte**: Les seuils d'alerte sont souvent définis en fonction de la moyenne, nécessitant une estimation précise.

Les métriques présentées dans ce document permettent d'évaluer:
- L'écart absolu entre les moyennes (EAM), directement interprétable en unités de latence
- L'écart relatif (ERM), facilitant la comparaison entre différentes distributions
- L'écart normalisé (ENM), tenant compte de la variabilité naturelle des données

Ces métriques constituent un outil essentiel pour optimiser les stratégies de binning et garantir que les histogrammes de latence représentent fidèlement la tendance centrale des distributions sous-jacentes.
