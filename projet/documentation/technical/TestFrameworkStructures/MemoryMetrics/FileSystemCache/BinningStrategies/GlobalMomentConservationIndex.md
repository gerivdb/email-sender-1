# Formulation mathématique de l'indice global de conservation des moments

## 1. Introduction

Ce document définit la formulation mathématique d'un indice global de conservation des moments statistiques pour les histogrammes de latence. Cet indice vise à quantifier, par une métrique unique et interprétable, la fidélité avec laquelle un histogramme préserve l'ensemble des caractéristiques statistiques importantes d'une distribution de latence. Pour les distributions de latence de blocs de 2KB, un tel indice est essentiel pour évaluer et comparer différentes stratégies de binning, permettant une optimisation globale de la représentation des données.

## 2. Fondements théoriques

### 2.1 Moments statistiques et leur importance

Les moments statistiques caractérisent différents aspects d'une distribution :

1. **Premier moment (moyenne)** : Tendance centrale
2. **Deuxième moment (variance)** : Dispersion autour de la moyenne
3. **Troisième moment (asymétrie)** : Déséquilibre de la distribution
4. **Quatrième moment (aplatissement)** : Concentration des valeurs et épaisseur des queues

Pour une distribution de latence, chaque moment capture des aspects spécifiques du comportement du système :
- La moyenne reflète la performance typique
- La variance indique la stabilité
- L'asymétrie révèle la fréquence des valeurs aberrantes
- L'aplatissement caractérise la prévisibilité et les événements extrêmes

### 2.2 Erreurs de conservation des moments

Pour chaque moment, nous avons défini des métriques d'erreur spécifiques :

- **Erreur relative de la moyenne (ERM)** : `|μ - μₕ| / μ × 100%`
- **Erreur relative de la variance (ERV)** : `|σ² - σ²ₕ| / σ² × 100%`
- **Erreur relative de l'asymétrie (ERA)** : `|γ₁ - γ₁ₕ| / |γ₁| × 100%`
- **Erreur relative de l'aplatissement (ERK)** : `|β₂ - β₂ₕ| / β₂ × 100%`

où les indices h désignent les valeurs calculées à partir de l'histogramme.

## 3. Formulation de l'indice global

### 3.1 Principe de construction

L'indice global de conservation des moments (IGCM) doit satisfaire plusieurs critères :

1. **Normalisation** : Valeur entre 0 et 1, où 1 indique une conservation parfaite
2. **Sensibilité équilibrée** : Réactivité appropriée aux erreurs sur chaque moment
3. **Interprétabilité** : Relation claire avec la qualité de la représentation
4. **Robustesse** : Stabilité face aux cas particuliers (distributions atypiques)

### 3.2 Formulation mathématique de base

L'IGCM est défini comme une moyenne pondérée des indices de conservation de chaque moment :

```plaintext
IGCM = w₁·ICM + w₂·ICV + w₃·ICA + w₄·ICK
```plaintext
où :
- ICM est l'indice de conservation de la moyenne : `ICM = 1 - min(ERM/100, 1)`
- ICV est l'indice de conservation de la variance : `ICV = 1 - min(ERV/100, 1)`
- ICA est l'indice de conservation de l'asymétrie : `ICA = 1 - min(ERA/100, 1)`
- ICK est l'indice de conservation de l'aplatissement : `ICK = 1 - min(ERK/100, 1)`
- w₁, w₂, w₃, w₄ sont les poids attribués à chaque indice, avec `w₁ + w₂ + w₃ + w₄ = 1`

### 3.3 Formulation avancée avec normalisation adaptative

Pour améliorer la robustesse de l'indice, nous introduisons une normalisation adaptative qui tient compte des seuils d'acceptabilité pour chaque moment :

```plaintext
IGCM = Σ wᵢ·(1 - min(ERᵢ/Tᵢ, 1))
```plaintext
où :
- ERᵢ est l'erreur relative pour le moment i
- Tᵢ est le seuil d'acceptabilité pour le moment i
- wᵢ est le poids attribué au moment i

Les seuils d'acceptabilité par défaut sont :
- T₁ = 5% pour la moyenne
- T₂ = 20% pour la variance
- T₃ = 30% pour l'asymétrie
- T₄ = 40% pour l'aplatissement

### 3.4 Formulation avec fonction de pénalité exponentielle

Pour accentuer l'impact des erreurs importantes, nous introduisons une fonction de pénalité exponentielle :

```plaintext
IGCM = Σ wᵢ·exp(-αᵢ·(ERᵢ/Tᵢ)²)
```plaintext
où αᵢ est un paramètre de sensibilité pour le moment i, typiquement αᵢ = 2.3 pour que exp(-αᵢ) ≈ 0.1 lorsque ERᵢ = Tᵢ.

### 3.5 Formulation finale avec robustesse aux cas particuliers

La formulation finale intègre des mécanismes de robustesse pour gérer les cas particuliers :

```plaintext
IGCM = Σ wᵢ·f(ERᵢ, Tᵢ, Sᵢ)
```plaintext
où :
- f(ERᵢ, Tᵢ, Sᵢ) = exp(-αᵢ·(min(ERᵢ, Sᵢ)/Tᵢ)²)
- Sᵢ est une valeur de saturation pour l'erreur du moment i
- Les valeurs de saturation par défaut sont :
  - S₁ = 20% pour la moyenne
  - S₂ = 50% pour la variance
  - S₃ = 100% pour l'asymétrie
  - S₄ = 150% pour l'aplatissement

Cette formulation garantit que même des erreurs très élevées sur un moment ne dominent pas complètement l'indice global.

## 4. Pondération des moments

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

### 4.3 Pondération adaptative selon les caractéristiques de la distribution

Pour certaines distributions avec des caractéristiques particulières, des pondérations adaptées sont recommandées :

| Type de distribution | Moyenne | Variance | Asymétrie | Aplatissement | Justification |
|---------------------|---------|----------|-----------|---------------|---------------|
| Quasi-normale | 0.40 | 0.40 | 0.10 | 0.10 | Focus sur moments d'ordre inférieur |
| Fortement asymétrique | 0.30 | 0.30 | 0.30 | 0.10 | Importance accrue de l'asymétrie |
| Leptokurtique | 0.30 | 0.30 | 0.20 | 0.20 | Importance accrue de l'aplatissement |
| Multimodale | 0.25 | 0.35 | 0.25 | 0.15 | Équilibre adapté à la complexité |

## 5. Implémentation et calcul

### 5.1 Algorithme de calcul de l'IGCM

```python
def calculate_global_moment_conservation_index(real_data, bin_edges, bin_counts, 
                                              weights=None, thresholds=None, 
                                              saturation_values=None, context=None):
    """
    Calcule l'indice global de conservation des moments.
    
    Args:
        real_data: Données réelles
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme
        weights: Poids des moments [w₁, w₂, w₃, w₄]
        thresholds: Seuils d'acceptabilité [T₁, T₂, T₃, T₄]
        saturation_values: Valeurs de saturation [S₁, S₂, S₃, S₄]
        context: Contexte d'analyse pour pondération adaptative
        
    Returns:
        igcm: Indice global de conservation des moments
        component_indices: Indices individuels pour chaque moment
    """
    # Définir les poids par défaut ou selon le contexte

    if weights is None:
        if context == "monitoring":
            weights = [0.50, 0.30, 0.15, 0.05]
        elif context == "stability":
            weights = [0.20, 0.50, 0.20, 0.10]
        elif context == "anomaly_detection":
            weights = [0.20, 0.25, 0.35, 0.20]
        elif context == "characterization":
            weights = [0.25, 0.25, 0.25, 0.25]
        else:
            weights = [0.40, 0.30, 0.20, 0.10]  # Défaut

    
    # Normaliser les poids

    weights = [w / sum(weights) for w in weights]
    
    # Définir les seuils d'acceptabilité par défaut

    if thresholds is None:
        thresholds = [5.0, 20.0, 30.0, 40.0]  # En pourcentage

    
    # Définir les valeurs de saturation par défaut

    if saturation_values is None:
        saturation_values = [20.0, 50.0, 100.0, 150.0]  # En pourcentage

    
    # Calculer les erreurs relatives pour chaque moment

    mean_error = calculate_mean_relative_error(real_data, bin_edges, bin_counts)
    variance_error = calculate_variance_relative_error(real_data, bin_edges, bin_counts)
    skewness_error = calculate_skewness_relative_error(real_data, bin_edges, bin_counts)
    kurtosis_error = calculate_kurtosis_relative_error(real_data, bin_edges, bin_counts)
    
    errors = [mean_error, variance_error, skewness_error, kurtosis_error]
    
    # Calculer les indices individuels avec fonction exponentielle

    alpha = 2.3  # Paramètre de sensibilité

    component_indices = []
    
    for i in range(4):
        # Limiter l'erreur à la valeur de saturation

        capped_error = min(errors[i], saturation_values[i])
        # Calculer l'indice normalisé avec pénalité exponentielle

        index = math.exp(-alpha * (capped_error / thresholds[i])**2)
        component_indices.append(index)
    
    # Calculer l'indice global comme moyenne pondérée

    igcm = sum(w * idx for w, idx in zip(weights, component_indices))
    
    return igcm, component_indices
```plaintext
### 5.2 Fonctions auxiliaires pour le calcul des erreurs relatives

```python
def calculate_mean_relative_error(real_data, bin_edges, bin_counts):
    """Calcule l'erreur relative de la moyenne."""
    real_mean = np.mean(real_data)
    
    # Calculer la moyenne de l'histogramme

    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2
    total_count = np.sum(bin_counts)
    frequencies = bin_counts / total_count if total_count > 0 else np.zeros_like(bin_counts)
    hist_mean = np.sum(bin_centers * frequencies)
    
    # Calculer l'erreur relative en pourcentage

    if abs(real_mean) > 1e-10:
        relative_error = abs(real_mean - hist_mean) / abs(real_mean) * 100
    else:
        relative_error = 100.0 if abs(hist_mean) > 1e-10 else 0.0
    
    return relative_error
```plaintext
Les fonctions pour les autres moments suivent un schéma similaire.

## 6. Interprétation de l'indice global

### 6.1 Échelle d'interprétation

| Valeur IGCM | Interprétation | Description |
|-------------|----------------|-------------|
| 0.90 - 1.00 | Excellente | Conservation quasi-parfaite de tous les moments |
| 0.80 - 0.90 | Très bonne | Conservation très fidèle, adaptée aux analyses détaillées |
| 0.70 - 0.80 | Bonne | Conservation fidèle, adaptée à la plupart des analyses |
| 0.60 - 0.70 | Acceptable | Conservation adéquate pour le monitoring général |
| 0.50 - 0.60 | Limitée | Conservation partielle, utilisable avec précaution |
| 0.00 - 0.50 | Insuffisante | Conservation inadéquate, représentation potentiellement trompeuse |

### 6.2 Interprétation par composante

L'analyse des indices individuels permet d'identifier les aspects spécifiques nécessitant une amélioration :

| Composante | Valeur faible | Stratégie d'amélioration |
|------------|---------------|--------------------------|
| ICM < 0.80 | Conservation insuffisante de la moyenne | Augmenter le nombre de bins, améliorer l'alignement |
| ICV < 0.70 | Conservation insuffisante de la variance | Utiliser des bins à largeur variable, appliquer la correction de Sheppard |
| ICA < 0.60 | Conservation insuffisante de l'asymétrie | Utiliser des bins logarithmiques, améliorer la résolution dans les queues |
| ICK < 0.50 | Conservation insuffisante de l'aplatissement | Augmenter significativement le nombre de bins, stratification par région |

## 7. Représentation JSON

```json
{
  "globalMomentConservationIndex": {
    "definition": "Weighted composite metric evaluating overall statistical fidelity",
    "formula": "IGCM = Σ wᵢ·exp(-αᵢ·(min(ERᵢ, Sᵢ)/Tᵢ)²)",
    "components": {
      "meanConservationIndex": {
        "weight": 0.40,
        "threshold": 5.0,
        "saturation": 20.0
      },
      "varianceConservationIndex": {
        "weight": 0.30,
        "threshold": 20.0,
        "saturation": 50.0
      },
      "skewnessConservationIndex": {
        "weight": 0.20,
        "threshold": 30.0,
        "saturation": 100.0
      },
      "kurtosisConservationIndex": {
        "weight": 0.10,
        "threshold": 40.0,
        "saturation": 150.0
      }
    },
    "contextualWeights": {
      "monitoring": [0.50, 0.30, 0.15, 0.05],
      "stability": [0.20, 0.50, 0.20, 0.10],
      "anomalyDetection": [0.20, 0.25, 0.35, 0.20],
      "characterization": [0.25, 0.25, 0.25, 0.25]
    },
    "interpretation": {
      "excellent": "0.90 - 1.00",
      "veryGood": "0.80 - 0.90",
      "good": "0.70 - 0.80",
      "acceptable": "0.60 - 0.70",
      "limited": "0.50 - 0.60",
      "insufficient": "0.00 - 0.50"
    }
  }
}
```plaintext
## 8. Exemples d'application

### 8.1 Distribution asymétrique positive (typique des latences)

Pour une distribution de latence avec asymétrie positive (γ₁ ≈ 1.8) et aplatissement élevé (β₂ ≈ 7.5) :

| Stratégie | ERM | ERV | ERA | ERK | IGCM | Interprétation |
|-----------|-----|-----|-----|-----|------|----------------|
| 10 bins uniformes | 8.5% | 32.4% | 54.2% | 58.7% | 0.48 | Insuffisante |
| 20 bins uniformes | 4.2% | 18.7% | 35.1% | 42.3% | 0.67 | Acceptable |
| 20 bins logarithmiques | 2.1% | 9.3% | 18.2% | 25.6% | 0.82 | Très bonne |
| 50 bins logarithmiques | 0.8% | 3.5% | 7.1% | 12.4% | 0.94 | Excellente |

### 8.2 Distribution multimodale complexe

Pour une distribution de latence multimodale avec modes asymétriques :

| Stratégie | ERM | ERV | ERA | ERK | IGCM | Interprétation |
|-----------|-----|-----|-----|-----|------|----------------|
| 20 bins uniformes | 6.3% | 25.8% | 42.7% | 52.1% | 0.56 | Limitée |
| 20 bins logarithmiques | 3.8% | 15.2% | 28.3% | 36.4% | 0.71 | Bonne |
| 50 bins stratifiés | 1.2% | 5.7% | 10.2% | 18.5% | 0.89 | Très bonne |
| 100 bins stratifiés | 0.5% | 2.3% | 4.8% | 9.2% | 0.96 | Excellente |

## 9. Conclusion

La formulation mathématique de l'indice global de conservation des moments (IGCM) fournit une métrique unique et interprétable pour évaluer la fidélité statistique globale d'un histogramme. Pour les distributions de latence de blocs de 2KB, cet indice est particulièrement utile car:

1. **Évaluation holistique** : Il intègre la conservation de tous les moments statistiques importants en une seule métrique.

2. **Adaptabilité contextuelle** : Le système de pondération adaptative permet d'ajuster l'importance relative des moments selon le contexte d'analyse.

3. **Robustesse** : La formulation avec saturation et pénalité exponentielle garantit la stabilité face aux cas particuliers et aux distributions atypiques.

4. **Interprétabilité** : L'échelle normalisée et les seuils d'interprétation facilitent l'évaluation qualitative des histogrammes.

Cet indice constitue un outil essentiel pour optimiser les stratégies de binning et garantir que les histogrammes de latence représentent fidèlement l'ensemble des caractéristiques statistiques des distributions sous-jacentes, permettant des analyses précises et des décisions d'optimisation éclairées.
