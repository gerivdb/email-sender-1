# Métriques pour la conservation de l'asymétrie (skewness)

## 1. Introduction

Ce document définit des métriques pour évaluer la conservation de l'asymétrie (skewness) dans les histogrammes de latence. L'asymétrie est une statistique fondamentale qui caractérise la forme d'une distribution, indiquant si elle est symétrique ou déséquilibrée vers les valeurs élevées ou faibles. Pour les distributions de latence de blocs de 2KB, qui présentent typiquement une asymétrie positive prononcée, la conservation fidèle de cette asymétrie est essentielle pour garantir que l'histogramme représente correctement la structure de la distribution, permettant une caractérisation précise des performances et une détection fiable des anomalies.

## 2. Définitions fondamentales

### 2.1 Asymétrie d'une distribution continue

Pour une distribution continue avec fonction de densité de probabilité f(x), l'asymétrie est définie par :

```plaintext
γ₁ = μ₃/σ³
```plaintext
où :
- μ₃ est le troisième moment centré : μ₃ = ∫ (x - μ)³·f(x) dx
- σ est l'écart-type de la distribution
- μ est la moyenne de la distribution

### 2.2 Asymétrie d'un échantillon

Pour un échantillon de n observations {x₁, x₂, ..., xₙ}, l'asymétrie empirique est :

```plaintext
g₁ = (m₃/m₂^(3/2)) · √(n(n-1))/(n-2)
```plaintext
où :
- m₃ = (1/n) · Σ (xᵢ - x̄)³
- m₂ = (1/n) · Σ (xᵢ - x̄)²
- x̄ est la moyenne de l'échantillon
- Le facteur √(n(n-1))/(n-2) est une correction pour le biais

### 2.3 Asymétrie d'un histogramme

Pour un histogramme avec k bins, où chaque bin i a une valeur centrale xᵢ et une fréquence relative fᵢ, l'asymétrie est :

```plaintext
γ₁ₕ = Σ fᵢ·(xᵢ - μₕ)³ / (Σ fᵢ·(xᵢ - μₕ)²)^(3/2)
```plaintext
où μₕ est la moyenne de l'histogramme.

## 3. Métriques pour la conservation de l'asymétrie

### 3.1 Erreur absolue de l'asymétrie (EAA)

L'erreur absolue de l'asymétrie quantifie la différence absolue entre l'asymétrie de la distribution réelle et celle de l'histogramme :

```plaintext
EAA = |γ₁ - γ₁ₕ|
```plaintext
où :
- γ₁ est l'asymétrie de la distribution réelle
- γ₁ₕ est l'asymétrie de l'histogramme

#### 3.1.1 Unités et interprétation

- **Unités** : Sans unité (adimensionnel)
- **Interprétation** : Représente l'écart absolu entre les asymétries
- **Avantages** : Directe et intuitive, facile à interpréter
- **Limitations** : Ne tient pas compte de l'échelle de l'asymétrie, difficile à comparer entre distributions très différentes

### 3.2 Erreur relative de l'asymétrie (ERA)

L'erreur relative de l'asymétrie exprime l'erreur absolue en pourcentage de l'asymétrie réelle :

```plaintext
ERA = |γ₁ - γ₁ₕ| / |γ₁| × 100%
```plaintext
#### 3.2.1 Unités et interprétation

- **Unités** : Pourcentage (%)
- **Interprétation** : Représente l'écart relatif entre les asymétries
- **Avantages** : Indépendante de l'échelle, facilite la comparaison entre différentes distributions
- **Limitations** : Instable pour les asymétries proches de zéro, peut être trompeuse pour les distributions quasi-symétriques

### 3.3 Erreur de signe de l'asymétrie (ESA)

L'erreur de signe de l'asymétrie est une métrique binaire qui indique si l'histogramme préserve correctement le signe de l'asymétrie :

```plaintext
ESA = {
    0 si sign(γ₁) = sign(γ₁ₕ)
    1 si sign(γ₁) ≠ sign(γ₁ₕ)
}
```plaintext
#### 3.3.1 Unités et interprétation

- **Unités** : Binaire (0 ou 1)
- **Interprétation** : 0 indique une conservation correcte du signe, 1 indique une inversion du signe
- **Avantages** : Capture l'erreur qualitative la plus grave (inversion de l'asymétrie)
- **Limitations** : Ne fournit pas d'information sur la magnitude de l'erreur

### 3.4 Indice de conservation de l'asymétrie (ICA)

L'indice de conservation de l'asymétrie est une métrique normalisée qui évalue la fidélité globale de la représentation de l'asymétrie :

```plaintext
ICA = 1 - min(|γ₁ - γ₁ₕ| / (|γ₁| + |γ₁ₕ| + ε), 1)
```plaintext
où ε est une petite constante (typiquement 0.1) pour éviter la division par zéro dans le cas de distributions symétriques.

#### 3.4.1 Unités et interprétation

- **Unités** : Sans unité, normalisé entre 0 et 1
- **Interprétation** : 1 indique une conservation parfaite, 0 indique une distorsion maximale
- **Avantages** : Robuste aux différentes échelles d'asymétrie, intuitive
- **Limitations** : Moins sensible aux petites variations que l'ERA

## 4. Métriques spécifiques pour les distributions de latence

### 4.1 Erreur de caractérisation de queue (ECQ)

Pour les distributions de latence, qui présentent typiquement une queue droite étendue, l'erreur de caractérisation de queue évalue spécifiquement la conservation de cette caractéristique :

```plaintext
ECQ = |P₉₀ₕ/P₅₀ₕ - P₉₀/P₅₀| / (P₉₀/P₅₀)
```plaintext
où :
- P₉₀ et P₅₀ sont les 90ème et 50ème percentiles de la distribution réelle
- P₉₀ₕ et P₅₀ₕ sont les 90ème et 50ème percentiles de l'histogramme

#### 4.1.1 Unités et interprétation

- **Unités** : Sans unité, exprimé généralement en pourcentage
- **Interprétation** : Mesure l'erreur dans la représentation de l'étendue relative de la queue
- **Avantages** : Directement liée à une caractéristique critique des distributions de latence
- **Limitations** : Ne capture pas toutes les nuances de l'asymétrie

### 4.2 Indice de conservation de forme asymétrique (ICFA)

L'indice de conservation de forme asymétrique évalue la préservation de la forme globale de la distribution asymétrique :

```plaintext
ICFA = (1 - |γ₁ - γ₁ₕ| / max(|γ₁|, 1)) · (1 - |CV - CVₕ| / max(CV, 0.1))
```plaintext
où :
- CV est le coefficient de variation de la distribution réelle
- CVₕ est le coefficient de variation de l'histogramme

#### 4.2.1 Unités et interprétation

- **Unités** : Sans unité, normalisé entre 0 et 1
- **Interprétation** : 1 indique une conservation parfaite de la forme asymétrique, 0 indique une distorsion maximale
- **Avantages** : Combine la conservation de l'asymétrie et de la dispersion relative
- **Limitations** : Métrique composite, peut masquer des compensations entre différents aspects

## 5. Propriétés théoriques

### 5.1 Biais de l'asymétrie dans les histogrammes

Pour un histogramme à largeur de bin fixe, l'asymétrie est théoriquement biaisée en raison de :

1. **Effet de discrétisation** : La représentation des valeurs continues par des valeurs discrètes introduit un biais
2. **Effet de groupement** : Le regroupement des observations dans des bins peut atténuer l'asymétrie
3. **Effet de troncature** : La limitation de la plage représentée peut tronquer la queue, réduisant l'asymétrie apparente

Le biais théorique dépend de la forme de la distribution et de la configuration du binning, mais tend généralement à sous-estimer l'asymétrie pour les distributions à asymétrie positive.

### 5.2 Impact du nombre de bins

L'erreur sur l'asymétrie diminue généralement avec l'augmentation du nombre de bins, mais pas aussi rapidement que pour la moyenne ou la variance. La relation approximative est :

```plaintext
EAA ∝ 1/k
```plaintext
où k est le nombre de bins.

### 5.3 Sensibilité aux valeurs extrêmes

L'asymétrie est particulièrement sensible aux valeurs extrêmes, ce qui la rend vulnérable aux effets de troncature et de regroupement dans les queues de distribution. Pour les distributions de latence, qui présentent souvent des valeurs aberrantes dans la queue droite, cette sensibilité est particulièrement importante.

## 6. Implémentation et calcul

### 6.1 Calcul de l'asymétrie réelle

```python
def calculate_real_skewness(data):
    """
    Calcule l'asymétrie réelle d'un ensemble de données.
    
    Args:
        data: Array des mesures de latence
        
    Returns:
        skewness: Asymétrie des données
    """
    return scipy.stats.skew(data, bias=False)
```plaintext
### 6.2 Calcul de l'asymétrie d'un histogramme

```python
def calculate_histogram_skewness(bin_edges, bin_counts):
    """
    Calcule l'asymétrie d'un histogramme.
    
    Args:
        bin_edges: Limites des bins
        bin_counts: Comptage par bin
        
    Returns:
        skewness: Asymétrie de l'histogramme
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
    
    # Calculer les moments centrés

    m2 = np.sum(frequencies * (bin_centers - mean)**2)
    m3 = np.sum(frequencies * (bin_centers - mean)**3)
    
    # Calculer l'asymétrie

    if m2 > 0:
        skewness = m3 / (m2**(3/2))
    else:
        skewness = 0
    
    return skewness
```plaintext
### 6.3 Calcul des métriques de conservation de l'asymétrie

```python
def calculate_skewness_conservation_metrics(real_data, bin_edges, bin_counts):
    """
    Calcule les métriques de conservation de l'asymétrie.
    
    Args:
        real_data: Données réelles
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme
        
    Returns:
        metrics: Dictionnaire des métriques calculées
    """
    # Calculer les asymétries

    real_skewness = calculate_real_skewness(real_data)
    hist_skewness = calculate_histogram_skewness(bin_edges, bin_counts)
    
    # Calculer les erreurs

    absolute_error = abs(real_skewness - hist_skewness)
    
    if abs(real_skewness) > 1e-10:
        relative_error = absolute_error / abs(real_skewness) * 100
    else:
        relative_error = float('inf') if absolute_error > 1e-10 else 0
    
    # Erreur de signe

    sign_error = 0 if (real_skewness * hist_skewness > 0 or 
                       (abs(real_skewness) < 1e-10 and abs(hist_skewness) < 1e-10)) else 1
    
    # Indice de conservation

    epsilon = 0.1
    ica = 1 - min(absolute_error / (abs(real_skewness) + abs(hist_skewness) + epsilon), 1)
    
    # Calcul des percentiles pour ECQ

    real_p50 = np.percentile(real_data, 50)
    real_p90 = np.percentile(real_data, 90)
    
    # Calculer les percentiles de l'histogramme

    cum_freq = np.cumsum(bin_counts) / np.sum(bin_counts)
    p50_idx = np.searchsorted(cum_freq, 0.5)
    p90_idx = np.searchsorted(cum_freq, 0.9)
    
    if p50_idx >= len(bin_centers) or p90_idx >= len(bin_centers):
        ecq = float('inf')
    else:
        hist_p50 = bin_centers[p50_idx]
        hist_p90 = bin_centers[p90_idx]
        
        real_ratio = real_p90 / real_p50 if real_p50 > 0 else float('inf')
        hist_ratio = hist_p90 / hist_p50 if hist_p50 > 0 else float('inf')
        
        if real_ratio != float('inf') and hist_ratio != float('inf'):
            ecq = abs(hist_ratio - real_ratio) / real_ratio
        else:
            ecq = float('inf')
    
    # Calcul de l'ICFA

    real_mean = np.mean(real_data)
    real_std = np.std(real_data)
    real_cv = real_std / real_mean if real_mean > 0 else float('inf')
    
    hist_mean = np.sum(bin_centers * frequencies)
    hist_var = np.sum(frequencies * (bin_centers - hist_mean)**2)
    hist_std = np.sqrt(hist_var)
    hist_cv = hist_std / hist_mean if hist_mean > 0 else float('inf')
    
    if real_cv != float('inf') and hist_cv != float('inf'):
        cv_error = abs(real_cv - hist_cv) / max(real_cv, 0.1)
        icfa = (1 - absolute_error / max(abs(real_skewness), 1)) * (1 - cv_error)
    else:
        icfa = 0
    
    # Résultats

    metrics = {
        "real_skewness": real_skewness,
        "histogram_skewness": hist_skewness,
        "absolute_error": absolute_error,
        "relative_error": relative_error,
        "sign_error": sign_error,
        "ica": ica,
        "ecq": ecq,
        "icfa": icfa
    }
    
    return metrics
```plaintext
## 7. Seuils recommandés pour les latences de blocs de 2KB

| Métrique | Excellent | Bon | Acceptable | Insuffisant |
|----------|-----------|-----|------------|-------------|
| **EAA** | < 0.2 | < 0.5 | < 1.0 | > 1.0 |
| **ERA** | < 10% | < 20% | < 30% | > 30% |
| **ESA** | 0 | 0 | 0 | 1 |
| **ICA** | > 0.9 | > 0.8 | > 0.7 | < 0.7 |
| **ECQ** | < 5% | < 10% | < 20% | > 20% |
| **ICFA** | > 0.85 | > 0.75 | > 0.65 | < 0.65 |

Ces seuils peuvent varier selon le contexte d'utilisation :

| Contexte | ERA | ICA | ICFA |
|----------|-----|-----|------|
| **Monitoring opérationnel** | < 30% | > 0.7 | > 0.65 |
| **Analyse comparative** | < 20% | > 0.8 | > 0.75 |
| **Caractérisation de performance** | < 15% | > 0.85 | > 0.8 |
| **Recherche et développement** | < 10% | > 0.9 | > 0.85 |

## 8. Seuils spécifiques pour les distributions de latence de blocs de 2KB

### 8.1 Seuils recommandés par niveau d'asymétrie

| Niveau d'asymétrie | ERA | ICA | ICFA |
|--------------------|-----|-----|------|
| **Faible** (γ₁ < 0.5) | < 25% | > 0.75 | > 0.7 |
| **Modéré** (0.5 ≤ γ₁ < 1.5) | < 20% | > 0.8 | > 0.75 |
| **Élevé** (1.5 ≤ γ₁ < 3.0) | < 15% | > 0.85 | > 0.8 |
| **Très élevé** (γ₁ ≥ 3.0) | < 10% | > 0.9 | > 0.85 |

### 8.2 Seuils recommandés par région de latence

| Région | ERA | ICA | ICFA |
|--------|-----|-----|------|
| **L1/L2 Cache** (50-100 μs) | < 25% | > 0.75 | > 0.7 |
| **L3/Mémoire** (150-250 μs) | < 20% | > 0.8 | > 0.75 |
| **Cache Système** (400-700 μs) | < 15% | > 0.85 | > 0.8 |
| **Stockage** (1500-3000 μs) | < 10% | > 0.9 | > 0.85 |

## 9. Représentation JSON

```json
{
  "skewnessConservationMetrics": {
    "absoluteSkewnessError": {
      "definition": "Absolute difference between real and histogram skewness",
      "formula": "|γ₁ - γ₁ₕ|",
      "unit": "dimensionless",
      "thresholds": {
        "excellent": "< 0.2",
        "good": "< 0.5",
        "acceptable": "< 1.0",
        "insufficient": "> 1.0"
      }
    },
    "relativeSkewnessError": {
      "definition": "Relative difference between real and histogram skewness",
      "formula": "|γ₁ - γ₁ₕ| / |γ₁| × 100%",
      "unit": "percentage",
      "thresholds": {
        "excellent": "< 10%",
        "good": "< 20%",
        "acceptable": "< 30%",
        "insufficient": "> 30%"
      }
    },
    "skewnessSignError": {
      "definition": "Binary metric indicating whether skewness sign is preserved",
      "formula": "0 if sign(γ₁) = sign(γ₁ₕ), 1 otherwise",
      "unit": "binary",
      "thresholds": {
        "acceptable": "0",
        "insufficient": "1"
      }
    },
    "skewnessConservationIndex": {
      "definition": "Normalized metric of skewness conservation",
      "formula": "1 - min(|γ₁ - γ₁ₕ| / (|γ₁| + |γ₁ₕ| + ε), 1)",
      "unit": "dimensionless",
      "thresholds": {
        "excellent": "> 0.9",
        "good": "> 0.8",
        "acceptable": "> 0.7",
        "insufficient": "< 0.7"
      }
    },
    "tailCharacterizationError": {
      "definition": "Error in representing the relative extent of the tail",
      "formula": "|P₉₀ₕ/P₅₀ₕ - P₉₀/P₅₀| / (P₉₀/P₅₀)",
      "unit": "dimensionless",
      "thresholds": {
        "excellent": "< 5%",
        "good": "< 10%",
        "acceptable": "< 20%",
        "insufficient": "> 20%"
      }
    },
    "asymmetricShapeConservationIndex": {
      "definition": "Combined metric of skewness and CV conservation",
      "formula": "(1 - |γ₁ - γ₁ₕ| / max(|γ₁|, 1)) · (1 - |CV - CVₕ| / max(CV, 0.1))",
      "unit": "dimensionless",
      "thresholds": {
        "excellent": "> 0.85",
        "good": "> 0.75",
        "acceptable": "> 0.65",
        "insufficient": "< 0.65"
      }
    }
  }
}
```plaintext
## 10. Exemples d'application

### 10.1 Cas d'étude: Distribution à asymétrie modérée

Pour une distribution de latence typique avec asymétrie modérée (γ₁ ≈ 1.2) :

| Stratégie | EAA | ERA | ESA | ICA | ECQ | ICFA |
|-----------|-----|-----|-----|-----|-----|------|
| 10 bins uniformes | 0.65 | 54% | 0 | 0.65 | 22% | 0.58 |
| 20 bins uniformes | 0.42 | 35% | 0 | 0.74 | 15% | 0.68 |
| 50 bins uniformes | 0.22 | 18% | 0 | 0.85 | 8% | 0.81 |
| 20 bins logarithmiques | 0.18 | 15% | 0 | 0.88 | 6% | 0.84 |

Évaluation : Insuffisant pour 10 bins, Acceptable pour 20 bins, Bon pour 50 bins et 20 bins logarithmiques

### 10.2 Cas d'étude: Distribution à forte asymétrie

Pour une distribution de latence avec forte asymétrie (γ₁ ≈ 2.8) :

| Stratégie | EAA | ERA | ESA | ICA | ECQ | ICFA |
|-----------|-----|-----|-----|-----|-----|------|
| 20 bins uniformes | 0.95 | 34% | 0 | 0.68 | 28% | 0.62 |
| 50 bins uniformes | 0.56 | 20% | 0 | 0.82 | 15% | 0.78 |
| 20 bins logarithmiques | 0.34 | 12% | 0 | 0.89 | 7% | 0.86 |
| 50 bins logarithmiques | 0.17 | 6% | 0 | 0.94 | 3% | 0.92 |

Évaluation : Insuffisant pour 20 bins uniformes, Acceptable pour 50 bins uniformes, Bon pour 20 bins logarithmiques, Excellent pour 50 bins logarithmiques

## 11. Conclusion

Les métriques pour la conservation de l'asymétrie fournissent un cadre quantitatif pour évaluer la fidélité avec laquelle un histogramme représente la forme asymétrique d'une distribution de latence. Pour les distributions de latence de blocs de 2KB, qui présentent typiquement une asymétrie positive prononcée, ces métriques sont particulièrement importantes car:

1. **Caractérisation de la forme** : L'asymétrie est un indicateur clé de la forme de la distribution, reflétant la présence et l'étendue de la queue droite caractéristique des distributions de latence.

2. **Détection des anomalies** : Une représentation précise de l'asymétrie permet de détecter les changements dans la structure de la distribution, qui peuvent indiquer des problèmes de performance.

3. **Optimisation ciblée** : La connaissance précise de l'asymétrie aide à identifier les sources de variabilité et à cibler les efforts d'optimisation.

Les métriques présentées dans ce document permettent d'évaluer:
- L'écart absolu et relatif entre les asymétries (EAA, ERA)
- La préservation du signe de l'asymétrie (ESA)
- La conservation globale de la forme asymétrique (ICA, ICFA)
- La représentation spécifique de la queue caractéristique des distributions de latence (ECQ)

Ces métriques constituent un outil essentiel pour optimiser les stratégies de binning et garantir que les histogrammes de latence représentent fidèlement la forme asymétrique des distributions sous-jacentes, permettant une caractérisation précise des performances et une détection fiable des anomalies.
