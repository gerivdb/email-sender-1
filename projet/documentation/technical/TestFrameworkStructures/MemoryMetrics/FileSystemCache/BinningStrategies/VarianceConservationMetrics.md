# Formules d'erreur absolue et relative pour la conservation de la variance

## 1. Introduction

Ce document établit les formules d'erreur absolue et relative pour évaluer la conservation de la variance dans les histogrammes de latence. La variance est une statistique fondamentale qui caractérise la dispersion d'une distribution. Pour les distributions de latence de blocs de 2KB, la conservation précise de la variance est essentielle pour garantir que l'histogramme représente fidèlement la variabilité des performances du système, permettant une évaluation correcte de la stabilité et la détection fiable des anomalies.

## 2. Définitions fondamentales

### 2.1 Variance d'une distribution continue

Pour une distribution continue avec fonction de densité de probabilité f(x), la variance est définie par :

```
σ² = ∫ (x - μ)²·f(x) dx
```

où μ est la moyenne de la distribution et l'intégration est effectuée sur l'ensemble du domaine.

### 2.2 Variance d'un échantillon

Pour un échantillon de n observations {x₁, x₂, ..., xₙ}, la variance empirique est :

```
s² = (1/(n-1)) · Σ (xᵢ - x̄)²
```

où x̄ est la moyenne de l'échantillon.

### 2.3 Variance d'un histogramme

Pour un histogramme avec k bins, où chaque bin i a une valeur centrale xᵢ et une fréquence relative fᵢ, la variance est :

```
σ²ₕ = Σ (xᵢ - μₕ)²·fᵢ
```

où μₕ est la moyenne de l'histogramme et la somme est effectuée sur tous les bins.

## 3. Formules d'erreur pour la conservation de la variance

### 3.1 Erreur absolue de la variance (EAV)

L'erreur absolue de la variance quantifie la différence absolue entre la variance de la distribution réelle et celle de l'histogramme :

```
EAV = |σ² - σ²ₕ|
```

où :
- σ² est la variance de la distribution réelle
- σ²ₕ est la variance de l'histogramme

#### 3.1.1 Unités et interprétation

- **Unités** : Microsecondes au carré (μs²) pour les latences
- **Interprétation** : Représente l'écart absolu entre les variances, dans les unités au carré des données originales
- **Avantages** : Directement lié à l'échelle des données, utile pour les comparaisons absolues
- **Limitations** : Difficile à interpréter intuitivement, sensible à l'échelle des données

### 3.2 Erreur relative de la variance (ERV)

L'erreur relative de la variance exprime l'erreur absolue en pourcentage de la variance réelle :

```
ERV = |σ² - σ²ₕ| / σ² × 100%
```

#### 3.2.1 Unités et interprétation

- **Unités** : Pourcentage (%)
- **Interprétation** : Représente l'écart relatif entre les variances
- **Avantages** : Indépendant de l'échelle, facilite la comparaison entre différentes distributions
- **Limitations** : Peut être instable pour les variances proches de zéro

### 3.3 Erreur sur l'écart-type (EET)

L'erreur sur l'écart-type est souvent plus intuitive que l'erreur sur la variance :

```
EET = |σ - σₕ|
```

où :
- σ est l'écart-type de la distribution réelle
- σₕ est l'écart-type de l'histogramme

#### 3.3.1 Unités et interprétation

- **Unités** : Microsecondes (μs) pour les latences
- **Interprétation** : Représente l'écart absolu entre les écarts-types, dans les mêmes unités que les données originales
- **Avantages** : Plus intuitive que l'erreur sur la variance, directement comparable aux valeurs de latence
- **Limitations** : Ne reflète pas directement l'erreur sur la variance (relation non linéaire)

### 3.4 Erreur relative sur l'écart-type (ERET)

L'erreur relative sur l'écart-type exprime l'erreur absolue sur l'écart-type en pourcentage de l'écart-type réel :

```
ERET = |σ - σₕ| / σ × 100%
```

#### 3.4.1 Unités et interprétation

- **Unités** : Pourcentage (%)
- **Interprétation** : Représente l'écart relatif entre les écarts-types
- **Avantages** : Intuitive, indépendante de l'échelle, facilite la comparaison entre différentes distributions
- **Limitations** : Ne reflète pas directement l'erreur sur la variance (relation non linéaire)

### 3.5 Relation entre les erreurs sur la variance et l'écart-type

Pour de petites erreurs relatives, la relation approximative est :

```
ERV ≈ 2 × ERET
```

Cette relation découle du développement au premier ordre de la fonction racine carrée.

## 4. Propriétés théoriques

### 4.1 Biais de la variance dans les histogrammes

Pour un histogramme à largeur de bin fixe, la variance est théoriquement biaisée en raison de :

1. **Erreur de discrétisation** : La représentation des valeurs continues par des valeurs discrètes introduit un biais systématique
2. **Effet de groupement** : Le regroupement des observations dans des bins réduit la variance apparente

Le biais théorique pour un histogramme à k bins de largeur h est approximativement :

```
Biais(σ²ₕ) ≈ -h²/12
```

Ce biais est négatif, indiquant que l'histogramme tend à sous-estimer la variance réelle.

### 4.2 Erreur théorique due à la discrétisation

Pour une distribution continue f(x) discrétisée en k bins de largeur h, l'erreur théorique sur la variance est de l'ordre de O(h²).

### 4.3 Impact du nombre de bins

L'erreur sur la variance diminue généralement avec l'augmentation du nombre de bins, suivant approximativement une relation :

```
EAV ∝ 1/k²
```

où k est le nombre de bins.

## 5. Formules spécifiques pour les distributions de latence de blocs de 2KB

### 5.1 Erreur de variance normalisée (EVN)

Pour les distributions de latence, il est utile de normaliser l'erreur de variance par le carré de la moyenne :

```
EVN = |σ² - σ²ₕ| / μ²
```

Cette métrique est particulièrement pertinente pour comparer la conservation de la variance entre différentes distributions de latence.

### 5.2 Erreur sur le coefficient de variation (ECV)

Le coefficient de variation (CV = σ/μ) est une mesure importante de la variabilité relative pour les distributions de latence :

```
ECV = |CV - CVₕ| = |(σ/μ) - (σₕ/μₕ)|
```

où :
- CV est le coefficient de variation réel
- CVₕ est le coefficient de variation de l'histogramme

### 5.3 Erreur relative sur le coefficient de variation (ERCV)

```
ERCV = |CV - CVₕ| / CV × 100%
```

Cette métrique est particulièrement utile pour évaluer la conservation de la variabilité relative, indépendamment de l'échelle absolue des latences.

## 6. Implémentation et calcul

### 6.1 Calcul de la variance réelle

```python
def calculate_real_variance(data):
    """
    Calcule la variance réelle d'un ensemble de données.
    
    Args:
        data: Array des mesures de latence
        
    Returns:
        variance: Variance des données
    """
    return np.var(data, ddof=1)  # ddof=1 pour variance non biaisée
```

### 6.2 Calcul de la variance d'un histogramme

```python
def calculate_histogram_variance(bin_edges, bin_counts):
    """
    Calcule la variance d'un histogramme.
    
    Args:
        bin_edges: Limites des bins
        bin_counts: Comptage par bin
        
    Returns:
        variance: Variance de l'histogramme
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
    
    # Calculer la variance
    variance = np.sum(frequencies * (bin_centers - mean)**2)
    
    # Correction du biais de groupement (Sheppard's correction)
    bin_width = bin_edges[1] - bin_edges[0]  # Supposant des bins de largeur fixe
    variance_correction = bin_width**2 / 12
    
    # Appliquer la correction
    corrected_variance = variance + variance_correction
    
    return corrected_variance
```

### 6.3 Calcul des erreurs de conservation de la variance

```python
def calculate_variance_conservation_errors(real_data, bin_edges, bin_counts):
    """
    Calcule les erreurs de conservation de la variance.
    
    Args:
        real_data: Données réelles
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme
        
    Returns:
        errors: Dictionnaire des erreurs calculées
    """
    # Calculer les statistiques réelles
    real_mean = np.mean(real_data)
    real_variance = np.var(real_data, ddof=1)
    real_std = np.sqrt(real_variance)
    real_cv = real_std / real_mean if real_mean != 0 else float('inf')
    
    # Calculer les statistiques de l'histogramme
    hist_variance = calculate_histogram_variance(bin_edges, bin_counts)
    hist_std = np.sqrt(hist_variance)
    
    # Calculer la moyenne de l'histogramme
    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2
    total_count = np.sum(bin_counts)
    frequencies = bin_counts / total_count if total_count > 0 else np.zeros_like(bin_counts)
    hist_mean = np.sum(bin_centers * frequencies)
    
    hist_cv = hist_std / hist_mean if hist_mean != 0 else float('inf')
    
    # Calculer les erreurs
    absolute_error_variance = abs(real_variance - hist_variance)
    relative_error_variance = absolute_error_variance / real_variance * 100 if real_variance != 0 else float('inf')
    
    absolute_error_std = abs(real_std - hist_std)
    relative_error_std = absolute_error_std / real_std * 100 if real_std != 0 else float('inf')
    
    normalized_error_variance = absolute_error_variance / (real_mean**2) if real_mean != 0 else float('inf')
    
    error_cv = abs(real_cv - hist_cv)
    relative_error_cv = error_cv / real_cv * 100 if real_cv != 0 else float('inf')
    
    # Résultats
    errors = {
        "real_variance": real_variance,
        "histogram_variance": hist_variance,
        "absolute_error_variance": absolute_error_variance,
        "relative_error_variance": relative_error_variance,
        "real_std": real_std,
        "histogram_std": hist_std,
        "absolute_error_std": absolute_error_std,
        "relative_error_std": relative_error_std,
        "normalized_error_variance": normalized_error_variance,
        "real_cv": real_cv,
        "histogram_cv": hist_cv,
        "error_cv": error_cv,
        "relative_error_cv": relative_error_cv
    }
    
    return errors
```

## 7. Seuils recommandés pour les latences de blocs de 2KB

| Métrique | Excellent | Bon | Acceptable | Insuffisant |
|----------|-----------|-----|------------|-------------|
| **ERV** | < 5% | < 10% | < 20% | > 20% |
| **ERET** | < 2.5% | < 5% | < 10% | > 10% |
| **EVN** | < 0.01 | < 0.02 | < 0.05 | > 0.05 |
| **ERCV** | < 5% | < 10% | < 15% | > 15% |

Ces seuils peuvent varier selon le contexte d'utilisation :

| Contexte | ERV | ERET | ERCV |
|----------|-----|------|------|
| **Monitoring opérationnel** | < 20% | < 10% | < 15% |
| **Analyse comparative** | < 10% | < 5% | < 10% |
| **Optimisation système** | < 5% | < 2.5% | < 5% |
| **Recherche et développement** | < 3% | < 1.5% | < 3% |

## 8. Représentation JSON

```json
{
  "varianceConservationMetrics": {
    "absoluteVarianceError": {
      "definition": "Absolute difference between real and histogram variances",
      "formula": "|σ² - σ²ₕ|",
      "unit": "microseconds_squared",
      "thresholds": {
        "excellent": "context-dependent",
        "good": "context-dependent",
        "acceptable": "context-dependent",
        "insufficient": "context-dependent"
      }
    },
    "relativeVarianceError": {
      "definition": "Relative difference between real and histogram variances",
      "formula": "|σ² - σ²ₕ| / σ² × 100%",
      "unit": "percentage",
      "thresholds": {
        "excellent": "< 5%",
        "good": "< 10%",
        "acceptable": "< 20%",
        "insufficient": "> 20%"
      }
    },
    "absoluteStdDevError": {
      "definition": "Absolute difference between real and histogram standard deviations",
      "formula": "|σ - σₕ|",
      "unit": "microseconds",
      "thresholds": {
        "excellent": "context-dependent",
        "good": "context-dependent",
        "acceptable": "context-dependent",
        "insufficient": "context-dependent"
      }
    },
    "relativeStdDevError": {
      "definition": "Relative difference between real and histogram standard deviations",
      "formula": "|σ - σₕ| / σ × 100%",
      "unit": "percentage",
      "thresholds": {
        "excellent": "< 2.5%",
        "good": "< 5%",
        "acceptable": "< 10%",
        "insufficient": "> 10%"
      }
    },
    "normalizedVarianceError": {
      "definition": "Variance error normalized by squared mean",
      "formula": "|σ² - σ²ₕ| / μ²",
      "unit": "dimensionless",
      "thresholds": {
        "excellent": "< 0.01",
        "good": "< 0.02",
        "acceptable": "< 0.05",
        "insufficient": "> 0.05"
      }
    },
    "coefficientOfVariationError": {
      "definition": "Absolute difference between real and histogram coefficients of variation",
      "formula": "|(σ/μ) - (σₕ/μₕ)|",
      "unit": "dimensionless",
      "thresholds": {
        "excellent": "context-dependent",
        "good": "context-dependent",
        "acceptable": "context-dependent",
        "insufficient": "context-dependent"
      }
    },
    "relativeCoeffOfVarError": {
      "definition": "Relative difference between real and histogram coefficients of variation",
      "formula": "|(σ/μ) - (σₕ/μₕ)| / (σ/μ) × 100%",
      "unit": "percentage",
      "thresholds": {
        "excellent": "< 5%",
        "good": "< 10%",
        "acceptable": "< 15%",
        "insufficient": "> 15%"
      }
    }
  }
}
```

## 9. Exemples d'application

### 9.1 Cas d'étude: Histogramme à 20 bins uniformes

Pour une distribution de latence de blocs de 2KB typique :

| Statistique | Valeur |
|-------------|--------|
| Variance réelle | 40000 μs² |
| Variance histogramme | 35000 μs² |
| ERV | 12.5% |
| Écart-type réel | 200 μs |
| Écart-type histogramme | 187 μs |
| ERET | 6.5% |
| CV réel | 0.5 |
| CV histogramme | 0.46 |
| ERCV | 8% |

Évaluation : Bon pour ERV, Acceptable pour ERET et ERCV

### 9.2 Cas d'étude: Histogramme à largeur variable optimisée

| Statistique | Valeur |
|-------------|--------|
| Variance réelle | 40000 μs² |
| Variance histogramme | 38500 μs² |
| ERV | 3.75% |
| Écart-type réel | 200 μs |
| Écart-type histogramme | 196 μs |
| ERET | 2% |
| CV réel | 0.5 |
| CV histogramme | 0.49 |
| ERCV | 2% |

Évaluation : Excellent pour toutes les métriques

## 10. Conclusion

Les formules d'erreur absolue et relative pour la conservation de la variance fournissent un cadre quantitatif pour évaluer la fidélité avec laquelle un histogramme représente la dispersion d'une distribution de latence. Pour les distributions de latence de blocs de 2KB, ces métriques sont particulièrement importantes car:

1. **Évaluation de la stabilité**: La variance est un indicateur clé de la stabilité des performances, et sa conservation fidèle est essentielle pour détecter les changements de comportement.

2. **Détection des anomalies**: Une représentation précise de la variance permet de définir des seuils d'alerte appropriés et de détecter les anomalies avec fiabilité.

3. **Caractérisation des performances**: Le coefficient de variation (CV) est particulièrement important pour comparer la variabilité relative entre différents systèmes ou configurations.

Les métriques présentées dans ce document permettent d'évaluer:
- L'écart absolu et relatif entre les variances (EAV, ERV)
- L'écart absolu et relatif entre les écarts-types (EET, ERET)
- L'erreur sur la variabilité relative (ECV, ERCV)

Ces métriques constituent un outil essentiel pour optimiser les stratégies de binning et garantir que les histogrammes de latence représentent fidèlement la dispersion des distributions sous-jacentes.
