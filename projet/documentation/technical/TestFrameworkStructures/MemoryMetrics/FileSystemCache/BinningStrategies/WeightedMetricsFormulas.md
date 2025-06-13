# Formules de métriques pondérées pour chaque moment statistique

## 1. Introduction

Ce document présente les formules mathématiques et l'implémentation des métriques pondérées pour chaque moment statistique (moyenne, variance, asymétrie, aplatissement) dans le cadre de l'évaluation de la qualité des histogrammes. Ces métriques permettent d'attribuer une importance relative à chaque moment selon le contexte d'analyse, le type de distribution ou les objectifs spécifiques.

## 2. Principe des métriques pondérées

### 2.1 Formulation générale

Pour chaque moment statistique, l'erreur pondérée est définie par :

```plaintext
Erreur_pondérée(M) = w_M × Erreur_relative(M)
```plaintext
où :
- M est le moment statistique (moyenne, variance, asymétrie ou aplatissement)
- w_M est le poids attribué au moment M
- Erreur_relative(M) est l'erreur relative (en pourcentage) entre la valeur réelle du moment et celle calculée à partir de l'histogramme

### 2.2 Erreur totale pondérée

L'erreur totale pondérée combine les erreurs de tous les moments :

```plaintext
Erreur_totale = Σ w_M × Erreur_relative(M)
```plaintext
où la somme est effectuée sur tous les moments statistiques.

## 3. Formules spécifiques pour chaque moment

### 3.1 Erreur pondérée pour la moyenne (1er moment)

```plaintext
Erreur_moyenne = w₁ × |μ - μₕ| / |μ| × 100%
```plaintext
où :
- w₁ est le poids attribué à la moyenne
- μ est la moyenne réelle
- μₕ est la moyenne calculée à partir de l'histogramme

### 3.2 Erreur pondérée pour la variance (2ème moment)

```plaintext
Erreur_variance = w₂ × |σ² - σ²ₕ| / |σ²| × 100%
```plaintext
où :
- w₂ est le poids attribué à la variance
- σ² est la variance réelle
- σ²ₕ est la variance calculée à partir de l'histogramme, avec correction de Sheppard si applicable

La correction de Sheppard pour la variance est :

```plaintext
σ²ₕ_corrigée = σ²ₕ_non_corrigée + h²/12
```plaintext
où h est la largeur du bin (ou la largeur moyenne pondérée pour les bins à largeur variable).

### 3.3 Erreur pondérée pour l'asymétrie (3ème moment)

```plaintext
Erreur_asymétrie = w₃ × |γ₁ - γ₁ₕ| / |γ₁| × 100%
```plaintext
où :
- w₃ est le poids attribué à l'asymétrie
- γ₁ est l'asymétrie réelle
- γ₁ₕ est l'asymétrie calculée à partir de l'histogramme

L'asymétrie de l'histogramme est calculée par :

```plaintext
γ₁ₕ = m₃ / (m₂)^(3/2)
```plaintext
où :
- m₂ = Σ fᵢ·(xᵢ - μₕ)²
- m₃ = Σ fᵢ·(xᵢ - μₕ)³
- fᵢ est la fréquence relative du bin i
- xᵢ est la valeur centrale du bin i
- μₕ est la moyenne de l'histogramme

### 3.4 Erreur pondérée pour l'aplatissement (4ème moment)

```plaintext
Erreur_aplatissement = w₄ × |β₂ - β₂ₕ| / |β₂| × 100%
```plaintext
où :
- w₄ est le poids attribué à l'aplatissement
- β₂ est l'aplatissement réel
- β₂ₕ est l'aplatissement calculé à partir de l'histogramme

L'aplatissement de l'histogramme est calculé par :

```plaintext
β₂ₕ = m₄ / (m₂)²
```plaintext
où :
- m₂ = Σ fᵢ·(xᵢ - μₕ)²
- m₄ = Σ fᵢ·(xᵢ - μₕ)⁴
- fᵢ est la fréquence relative du bin i
- xᵢ est la valeur centrale du bin i
- μₕ est la moyenne de l'histogramme

## 4. Stratégies de pondération

### 4.1 Pondération par défaut

La pondération par défaut reflète l'importance relative typique des moments pour l'analyse des distributions de latence :

| Moment | Poids par défaut | Justification |
|--------|------------------|---------------|
| Moyenne | w₁ = 0.40 | Métrique primaire pour la performance |
| Variance | w₂ = 0.30 | Indicateur clé de stabilité |
| Asymétrie | w₃ = 0.20 | Important pour caractériser les valeurs aberrantes |
| Aplatissement | w₄ = 0.10 | Utile mais plus sensible au bruit |

### 4.2 Pondération adaptative selon le contexte

Pour certains contextes d'analyse, des pondérations spécifiques sont recommandées :

| Contexte | Moyenne | Variance | Asymétrie | Aplatissement | Justification |
|----------|---------|----------|-----------|---------------|---------------|
| Monitoring opérationnel | 0.50 | 0.30 | 0.15 | 0.05 | Focus sur performance moyenne et stabilité |
| Analyse de stabilité | 0.20 | 0.50 | 0.20 | 0.10 | Priorité à la variance |
| Détection d'anomalies | 0.20 | 0.25 | 0.35 | 0.20 | Importance des moments d'ordre supérieur |
| Caractérisation complète | 0.25 | 0.25 | 0.25 | 0.25 | Équilibre entre tous les moments |

## 5. Implémentation

L'implémentation des métriques pondérées est réalisée dans le module `weighted_moment_metrics.py`. Voici les principales fonctions :

### 5.1 Calcul de l'erreur pondérée pour la moyenne

```python
def weighted_mean_error(real_data, bin_edges, bin_counts, weight=1.0):
    """
    Calcule l'erreur pondérée pour la moyenne.
    
    Args:
        real_data: Données réelles
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme
        weight: Poids attribué à cette métrique
        
    Returns:
        weighted_error: Erreur pondérée
        raw_error: Erreur brute (non pondérée)
    """
    # Calculer la moyenne réelle

    real_mean = np.mean(real_data)
    
    # Calculer les centres des bins

    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2
    
    # Calculer les fréquences relatives

    total_count = np.sum(bin_counts)
    if total_count == 0:
        return weight * 100.0, 100.0
    
    frequencies = bin_counts / total_count
    
    # Calculer la moyenne de l'histogramme

    hist_mean = np.sum(bin_centers * frequencies)
    
    # Calculer l'erreur relative en pourcentage

    if abs(real_mean) > 1e-10:
        relative_error = abs(real_mean - hist_mean) / abs(real_mean) * 100
    else:
        relative_error = 100.0 if abs(hist_mean) > 1e-10 else 0.0
    
    # Appliquer la pondération

    weighted_error = weight * relative_error
    
    return weighted_error, relative_error
```plaintext
### 5.2 Calcul de l'erreur totale pondérée

```python
def calculate_total_weighted_error(real_data, bin_edges, bin_counts, weights=None):
    """
    Calcule l'erreur totale pondérée pour tous les moments.
    
    Args:
        real_data: Données réelles
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme
        weights: Liste des poids [w₁, w₂, w₃, w₄] pour chaque moment
        
    Returns:
        total_weighted_error: Erreur totale pondérée
        component_errors: Dictionnaire des erreurs par composante
    """
    # Définir les poids par défaut si non spécifiés

    if weights is None:
        weights = [0.40, 0.30, 0.20, 0.10]  # [moyenne, variance, asymétrie, aplatissement]

    
    # Normaliser les poids

    sum_weights = sum(weights)
    if sum_weights > 0:
        weights = [w / sum_weights for w in weights]
    else:
        weights = [0.25, 0.25, 0.25, 0.25]  # Poids égaux par défaut

    
    # Calculer les erreurs pondérées pour chaque moment

    mean_error, mean_raw = weighted_mean_error(real_data, bin_edges, bin_counts, weights[0])
    variance_error, variance_raw = weighted_variance_error(real_data, bin_edges, bin_counts, weights[1])
    skewness_error, skewness_raw = weighted_skewness_error(real_data, bin_edges, bin_counts, weights[2])
    kurtosis_error, kurtosis_raw = weighted_kurtosis_error(real_data, bin_edges, bin_counts, weights[3])
    
    # Calculer l'erreur totale pondérée

    total_weighted_error = mean_error + variance_error + skewness_error + kurtosis_error
    
    # Préparer le dictionnaire des erreurs par composante

    component_errors = {
        "mean": {
            "raw_error": mean_raw,
            "weight": weights[0],
            "weighted_error": mean_error
        },
        "variance": {
            "raw_error": variance_raw,
            "weight": weights[1],
            "weighted_error": variance_error
        },
        "skewness": {
            "raw_error": skewness_raw,
            "weight": weights[2],
            "weighted_error": skewness_error
        },
        "kurtosis": {
            "raw_error": kurtosis_raw,
            "weight": weights[3],
            "weighted_error": kurtosis_error
        }
    }
    
    return total_weighted_error, component_errors
```plaintext
## 6. Exemples d'application

### 6.1 Comparaison des différentes stratégies de pondération

Pour une distribution de latence typique (asymétrique positive), voici l'impact des différentes stratégies de pondération sur l'erreur totale :

| Stratégie | Erreur totale | Contribution moyenne | Contribution variance | Contribution asymétrie | Contribution aplatissement |
|-----------|---------------|----------------------|------------------------|--------------------------|----------------------------|
| Poids égaux | 25.0 | 6.25 | 6.25 | 6.25 | 6.25 |
| Poids par défaut | 22.0 | 8.8 | 6.6 | 4.4 | 2.2 |
| Monitoring | 24.5 | 12.25 | 7.35 | 3.675 | 1.225 |
| Stabilité | 21.0 | 4.4 | 11.0 | 4.4 | 2.2 |

### 6.2 Optimisation de la stratégie de binning

L'utilisation de métriques pondérées permet d'optimiser la stratégie de binning en fonction du contexte :

| Contexte | Stratégie optimale | Justification |
|----------|-------------------|---------------|
| Monitoring | 20 bins logarithmiques | Bonne conservation de la moyenne et variance |
| Stabilité | 30 bins à largeur variable | Conservation optimale de la variance |
| Détection d'anomalies | 40 bins logarithmiques | Bonne conservation de l'asymétrie |
| Caractérisation | 50 bins stratifiés | Conservation équilibrée de tous les moments |

## 7. Conclusion

Les formules de métriques pondérées pour chaque moment statistique fournissent un cadre flexible pour évaluer la qualité des histogrammes en fonction du contexte d'analyse. En attribuant des poids différents à chaque moment, ces métriques permettent de cibler les aspects les plus importants de la distribution pour chaque cas d'utilisation, conduisant à des stratégies de binning optimisées et à une représentation plus fidèle des caractéristiques pertinentes des distributions de latence.
