# Métriques pour la conservation de l'aplatissement (kurtosis)

## 1. Introduction

Ce document définit des métriques pour évaluer la conservation de l'aplatissement (kurtosis) dans les histogrammes de latence. L'aplatissement est une statistique qui caractérise la concentration des valeurs autour de la moyenne et l'épaisseur des queues d'une distribution. Pour les distributions de latence de blocs de 2KB, la conservation fidèle de l'aplatissement est essentielle pour représenter correctement la fréquence des valeurs extrêmes et la stabilité des performances.

## 2. Définitions fondamentales

### 2.1 Aplatissement d'une distribution continue

Pour une distribution continue avec fonction de densité de probabilité f(x), l'aplatissement est défini par :

```
β₂ = μ₄/σ⁴
```

où :
- μ₄ est le quatrième moment centré : μ₄ = ∫ (x - μ)⁴·f(x) dx
- σ est l'écart-type de la distribution
- μ est la moyenne de la distribution

L'excès d'aplatissement (kurtosis excess) est souvent utilisé pour comparer avec la distribution normale :

```
γ₂ = β₂ - 3
```

Une distribution normale a un aplatissement β₂ = 3, donc un excès d'aplatissement γ₂ = 0.

### 2.2 Aplatissement d'un échantillon

Pour un échantillon de n observations {x₁, x₂, ..., xₙ}, l'aplatissement empirique est :

```
g₂ = (m₄/m₂²) · [(n+1)n/((n-1)(n-2)(n-3))] - 3(n-1)²/((n-2)(n-3))
```

où :
- m₄ = (1/n) · Σ (xᵢ - x̄)⁴
- m₂ = (1/n) · Σ (xᵢ - x̄)²
- x̄ est la moyenne de l'échantillon

### 2.3 Aplatissement d'un histogramme

Pour un histogramme avec k bins, où chaque bin i a une valeur centrale xᵢ et une fréquence relative fᵢ, l'aplatissement est :

```
β₂ₕ = Σ fᵢ·(xᵢ - μₕ)⁴ / (Σ fᵢ·(xᵢ - μₕ)²)²
```

où μₕ est la moyenne de l'histogramme.

## 3. Métriques pour la conservation de l'aplatissement

### 3.1 Erreur absolue de l'aplatissement (EAK)

```
EAK = |β₂ - β₂ₕ|
```

où :
- β₂ est l'aplatissement de la distribution réelle
- β₂ₕ est l'aplatissement de l'histogramme

**Unités** : Sans unité (adimensionnel)

### 3.2 Erreur relative de l'aplatissement (ERK)

```
ERK = |β₂ - β₂ₕ| / β₂ × 100%
```

**Unités** : Pourcentage (%)

### 3.3 Erreur absolue de l'excès d'aplatissement (EAEK)

```
EAEK = |γ₂ - γ₂ₕ|
```

où :
- γ₂ est l'excès d'aplatissement de la distribution réelle
- γ₂ₕ est l'excès d'aplatissement de l'histogramme

**Unités** : Sans unité (adimensionnel)

### 3.4 Erreur de caractérisation des queues (ECQ)

```
ECQ = |P₉₅/P₅₀ - P₉₅ₕ/P₅₀ₕ| / (P₉₅/P₅₀)
```

où :
- P₉₅ et P₅₀ sont les 95ème et 50ème percentiles de la distribution réelle
- P₉₅ₕ et P₅₀ₕ sont les 95ème et 50ème percentiles de l'histogramme

**Unités** : Sans unité, exprimé généralement en pourcentage

### 3.5 Indice de conservation de l'aplatissement (ICK)

```
ICK = 1 - min(|β₂ - β₂ₕ| / max(β₂, 3), 1)
```

**Unités** : Sans unité, normalisé entre 0 et 1

## 4. Métriques spécifiques pour les distributions de latence

### 4.1 Ratio de conservation des valeurs extrêmes (RCVE)

```
RCVE = (N₉₅ₕ/N) / (N₉₅/N)
```

où :
- N₉₅ est le nombre d'observations au-dessus du 95ème percentile dans les données réelles
- N₉₅ₕ est le nombre d'observations estimé au-dessus du 95ème percentile dans l'histogramme
- N est le nombre total d'observations

**Unités** : Ratio, idéalement proche de 1.0

### 4.2 Indice de conservation de forme des queues (ICFQ)

```
ICFQ = (1 - |γ₂ - γ₂ₕ| / max(|γ₂|, 1)) · (1 - ECQ)
```

**Unités** : Sans unité, normalisé entre 0 et 1

## 5. Implémentation et calcul

### 5.1 Calcul de l'aplatissement réel

```python
def calculate_real_kurtosis(data):
    """
    Calcule l'aplatissement réel d'un ensemble de données.
    
    Args:
        data: Array des mesures de latence
        
    Returns:
        kurtosis: Aplatissement des données
        excess_kurtosis: Excès d'aplatissement des données
    """
    kurtosis = scipy.stats.kurtosis(data, fisher=False, bias=False)
    excess_kurtosis = scipy.stats.kurtosis(data, fisher=True, bias=False)
    return kurtosis, excess_kurtosis
```

### 5.2 Calcul de l'aplatissement d'un histogramme

```python
def calculate_histogram_kurtosis(bin_edges, bin_counts):
    """
    Calcule l'aplatissement d'un histogramme.
    
    Args:
        bin_edges: Limites des bins
        bin_counts: Comptage par bin
        
    Returns:
        kurtosis: Aplatissement de l'histogramme
        excess_kurtosis: Excès d'aplatissement de l'histogramme
    """
    # Calculer les centres des bins
    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2
    
    # Calculer les fréquences relatives
    total_count = np.sum(bin_counts)
    if total_count == 0:
        return 3.0, 0.0
    
    frequencies = bin_counts / total_count
    
    # Calculer la moyenne
    mean = np.sum(bin_centers * frequencies)
    
    # Calculer les moments centrés
    m2 = np.sum(frequencies * (bin_centers - mean)**2)
    m4 = np.sum(frequencies * (bin_centers - mean)**4)
    
    # Calculer l'aplatissement
    if m2 > 0:
        kurtosis = m4 / (m2**2)
        excess_kurtosis = kurtosis - 3
    else:
        kurtosis = 3.0
        excess_kurtosis = 0.0
    
    return kurtosis, excess_kurtosis
```

### 5.3 Calcul des métriques de conservation de l'aplatissement

```python
def calculate_kurtosis_conservation_metrics(real_data, bin_edges, bin_counts):
    """
    Calcule les métriques de conservation de l'aplatissement.
    
    Args:
        real_data: Données réelles
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme
        
    Returns:
        metrics: Dictionnaire des métriques calculées
    """
    # Calculer les aplatissements
    real_kurtosis, real_excess = calculate_real_kurtosis(real_data)
    hist_kurtosis, hist_excess = calculate_histogram_kurtosis(bin_edges, bin_counts)
    
    # Calculer les erreurs
    absolute_error = abs(real_kurtosis - hist_kurtosis)
    
    if real_kurtosis > 0:
        relative_error = absolute_error / real_kurtosis * 100
    else:
        relative_error = float('inf') if absolute_error > 0 else 0
    
    excess_absolute_error = abs(real_excess - hist_excess)
    
    # Indice de conservation
    ick = 1 - min(absolute_error / max(real_kurtosis, 3), 1)
    
    # Calcul des percentiles pour ECQ
    real_p50 = np.percentile(real_data, 50)
    real_p95 = np.percentile(real_data, 95)
    
    # Calculer les percentiles de l'histogramme
    cum_freq = np.cumsum(bin_counts) / np.sum(bin_counts)
    p50_idx = np.searchsorted(cum_freq, 0.5)
    p95_idx = np.searchsorted(cum_freq, 0.95)
    
    if p50_idx >= len(bin_centers) or p95_idx >= len(bin_centers):
        ecq = float('inf')
    else:
        hist_p50 = bin_centers[p50_idx]
        hist_p95 = bin_centers[p95_idx]
        
        real_ratio = real_p95 / real_p50 if real_p50 > 0 else float('inf')
        hist_ratio = hist_p95 / hist_p50 if hist_p50 > 0 else float('inf')
        
        if real_ratio != float('inf') and hist_ratio != float('inf'):
            ecq = abs(hist_ratio - real_ratio) / real_ratio
        else:
            ecq = float('inf')
    
    # Calcul de l'ICFQ
    icfq = (1 - min(excess_absolute_error / max(abs(real_excess), 1), 1)) * (1 - min(ecq, 1))
    
    # Résultats
    metrics = {
        "real_kurtosis": real_kurtosis,
        "histogram_kurtosis": hist_kurtosis,
        "real_excess_kurtosis": real_excess,
        "histogram_excess_kurtosis": hist_excess,
        "absolute_error": absolute_error,
        "relative_error": relative_error,
        "excess_absolute_error": excess_absolute_error,
        "ick": ick,
        "ecq": ecq,
        "icfq": icfq
    }
    
    return metrics
```

## 6. Seuils recommandés

| Métrique | Excellent | Bon | Acceptable | Insuffisant |
|----------|-----------|-----|------------|-------------|
| **EAK** | < 0.5 | < 1.0 | < 2.0 | > 2.0 |
| **ERK** | < 15% | < 25% | < 40% | > 40% |
| **EAEK** | < 0.3 | < 0.7 | < 1.5 | > 1.5 |
| **ICK** | > 0.85 | > 0.75 | > 0.6 | < 0.6 |
| **ECQ** | < 10% | < 20% | < 30% | > 30% |
| **ICFQ** | > 0.8 | > 0.7 | > 0.5 | < 0.5 |

### 6.1 Seuils par niveau d'aplatissement

| Niveau d'aplatissement | ERK | ICK | ICFQ |
|------------------------|-----|-----|------|
| **Mésokurtique** (β₂ ≈ 3) | < 20% | > 0.8 | > 0.75 |
| **Leptokurtique modéré** (3 < β₂ < 5) | < 25% | > 0.75 | > 0.7 |
| **Leptokurtique élevé** (5 ≤ β₂ < 10) | < 30% | > 0.7 | > 0.65 |
| **Leptokurtique très élevé** (β₂ ≥ 10) | < 35% | > 0.65 | > 0.6 |

### 6.2 Seuils par région de latence

| Région | ERK | ICK | ICFQ |
|--------|-----|-----|------|
| **L1/L2 Cache** (50-100 μs) | < 30% | > 0.7 | > 0.65 |
| **L3/Mémoire** (150-250 μs) | < 25% | > 0.75 | > 0.7 |
| **Cache Système** (400-700 μs) | < 20% | > 0.8 | > 0.75 |
| **Stockage** (1500-3000 μs) | < 15% | > 0.85 | > 0.8 |

## 7. Représentation JSON

```json
{
  "kurtosisConservationMetrics": {
    "absoluteKurtosisError": {
      "definition": "Absolute difference between real and histogram kurtosis",
      "formula": "|β₂ - β₂ₕ|",
      "unit": "dimensionless",
      "thresholds": {
        "excellent": "< 0.5",
        "good": "< 1.0",
        "acceptable": "< 2.0",
        "insufficient": "> 2.0"
      }
    },
    "relativeKurtosisError": {
      "definition": "Relative difference between real and histogram kurtosis",
      "formula": "|β₂ - β₂ₕ| / β₂ × 100%",
      "unit": "percentage",
      "thresholds": {
        "excellent": "< 15%",
        "good": "< 25%",
        "acceptable": "< 40%",
        "insufficient": "> 40%"
      }
    },
    "excessKurtosisAbsoluteError": {
      "definition": "Absolute difference between real and histogram excess kurtosis",
      "formula": "|γ₂ - γ₂ₕ|",
      "unit": "dimensionless",
      "thresholds": {
        "excellent": "< 0.3",
        "good": "< 0.7",
        "acceptable": "< 1.5",
        "insufficient": "> 1.5"
      }
    },
    "kurtosisConservationIndex": {
      "definition": "Normalized metric of kurtosis conservation",
      "formula": "1 - min(|β₂ - β₂ₕ| / max(β₂, 3), 1)",
      "unit": "dimensionless",
      "thresholds": {
        "excellent": "> 0.85",
        "good": "> 0.75",
        "acceptable": "> 0.6",
        "insufficient": "< 0.6"
      }
    },
    "tailShapeConservationIndex": {
      "definition": "Combined metric of excess kurtosis and tail ratio conservation",
      "formula": "(1 - min(|γ₂ - γ₂ₕ| / max(|γ₂|, 1), 1)) · (1 - ECQ)",
      "unit": "dimensionless",
      "thresholds": {
        "excellent": "> 0.8",
        "good": "> 0.7",
        "acceptable": "> 0.5",
        "insufficient": "< 0.5"
      }
    }
  }
}
```

## 8. Exemples d'application

### 8.1 Distribution leptokurtique modérée

Pour une distribution de latence avec aplatissement modéré (β₂ ≈ 4.2) :

| Stratégie | EAK | ERK | EAEK | ICK | ICFQ |
|-----------|-----|-----|------|-----|------|
| 20 bins uniformes | 1.8 | 43% | 1.8 | 0.57 | 0.48 |
| 50 bins uniformes | 0.9 | 21% | 0.9 | 0.79 | 0.72 |
| 20 bins logarithmiques | 0.7 | 17% | 0.7 | 0.83 | 0.76 |
| 50 bins logarithmiques | 0.4 | 10% | 0.4 | 0.91 | 0.85 |

### 8.2 Distribution fortement leptokurtique

Pour une distribution de latence avec aplatissement élevé (β₂ ≈ 8.5) :

| Stratégie | EAK | ERK | EAEK | ICK | ICFQ |
|-----------|-----|-----|------|-----|------|
| 20 bins uniformes | 3.6 | 42% | 3.6 | 0.58 | 0.45 |
| 50 bins uniformes | 2.1 | 25% | 2.1 | 0.75 | 0.65 |
| 20 bins logarithmiques | 1.5 | 18% | 1.5 | 0.82 | 0.74 |
| 50 bins logarithmiques | 0.8 | 9% | 0.8 | 0.91 | 0.86 |

## 9. Conclusion

Les métriques pour la conservation de l'aplatissement fournissent un cadre quantitatif pour évaluer la fidélité avec laquelle un histogramme représente la concentration des valeurs et l'épaisseur des queues d'une distribution de latence. Pour les distributions de latence de blocs de 2KB, qui présentent souvent un aplatissement élevé (leptokurtiques), ces métriques sont essentielles pour garantir que les histogrammes capturent correctement la fréquence des valeurs extrêmes et la stabilité des performances.

Les métriques présentées permettent d'évaluer:
- L'écart absolu et relatif entre les aplatissements (EAK, ERK)
- La conservation de l'excès d'aplatissement (EAEK)
- La représentation globale de la forme des queues (ICK, ICFQ)

Ces métriques constituent un outil essentiel pour optimiser les stratégies de binning et garantir que les histogrammes de latence représentent fidèlement la distribution des valeurs extrêmes, permettant une caractérisation précise de la stabilité des performances et une détection fiable des anomalies.
