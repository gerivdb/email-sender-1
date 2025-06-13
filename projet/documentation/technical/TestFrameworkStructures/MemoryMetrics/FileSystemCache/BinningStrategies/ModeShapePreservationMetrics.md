# Métriques de conservation de la forme des modes

## 1. Introduction

Ce document définit des métriques quantitatives pour évaluer la conservation de la forme des modes dans les histogrammes de latence. Au-delà de la simple position et largeur, la forme complète d'un mode (asymétrie, aplatissement, structure fine) contient des informations précieuses sur les caractéristiques du système sous-jacent. Une représentation fidèle de cette forme est essentielle pour l'analyse approfondie des distributions de latence de blocs de 2KB, permettant d'identifier les mécanismes spécifiques contribuant aux différents régimes de performance.

## 2. Caractéristiques de forme des modes

### 2.1 Paramètres de forme fondamentaux

| Paramètre | Définition | Signification |
|-----------|------------|---------------|
| **Asymétrie** (skewness) | Mesure de l'asymétrie de la distribution autour du mode | Indique la direction et l'ampleur de la queue de distribution |
| **Aplatissement** (kurtosis) | Mesure de la concentration des valeurs autour du mode | Indique si la distribution est plus pointue ou plus aplatie qu'une distribution normale |
| **Bimodalité locale** | Présence de sous-structures à deux pics dans un mode principal | Indique des mécanismes concurrents ou des transitions de phase |
| **Épaulement** | Déformation asymétrique sur un flanc du mode | Indique l'influence d'un mécanisme secondaire |

### 2.2 Formes typiques des modes de latence

| Niveau | Forme caractéristique | Interprétation |
|--------|------------------------|----------------|
| **L1/L2 Cache** | Légèrement asymétrique (queue droite), parfois bimodal | Différence entre L1 et L2, variabilité des temps d'accès |
| **L3/Mémoire** | Modérément asymétrique, souvent avec épaulement | Transition entre cache L3 et mémoire principale |
| **Cache Système** | Fortement asymétrique, queue droite prononcée | Variabilité due aux mécanismes de cache du système d'exploitation |
| **Stockage** | Très asymétrique, parfois multimodal | Différents types d'accès au stockage, effets de contention |

## 3. Métriques de conservation de forme

### 3.1 Métriques basées sur les moments statistiques

| Métrique | Formule | Interprétation |
|----------|---------|----------------|
| **Ratio de conservation d'asymétrie** (RCA) | asymétrie_hist / asymétrie_réelle | Mesure la préservation de l'asymétrie du mode |
| **Ratio de conservation d'aplatissement** (RCK) | (kurtosis_hist - 3) / (kurtosis_réel - 3) | Mesure la préservation de l'aplatissement du mode |
| **Indice de conservation des moments** (ICM) | 1 - (1/4)Σ\|moment_i_normalisé_hist - moment_i_normalisé_réel\| | Mesure globale basée sur les 4 premiers moments |

### 3.2 Seuils d'interprétation pour les métriques basées sur les moments

| Métrique | Excellent | Bon | Acceptable | Insuffisant |
|----------|-----------|-----|------------|-------------|
| **RCA** | 0.9-1.1 | 0.8-1.2 | 0.7-1.3 | < 0.7 ou > 1.3 |
| **RCK** | 0.9-1.1 | 0.8-1.2 | 0.6-1.4 | < 0.6 ou > 1.4 |
| **ICM** | > 0.95 | > 0.9 | > 0.85 | < 0.85 |

### 3.3 Métriques basées sur la distribution

| Métrique | Formule | Interprétation |
|----------|---------|----------------|
| **Distance de Wasserstein** (DW) | inf_γ∈Γ(P,Q) E(x,y)∼γ[\|x-y\|] | Mesure la distance minimale pour transformer une distribution en une autre |
| **Divergence de Kullback-Leibler** (DKL) | Σ P(x) log(P(x)/Q(x)) | Mesure l'information perdue en approximant P par Q |
| **Distance de Hellinger** (DH) | (1/√2)·\|\|√P - √Q\|\|₂ | Mesure la similarité entre distributions, bornée entre 0 et 1 |
| **Coefficient de Bhattacharyya** (BC) | Σ √(P(x)·Q(x)) | Mesure le chevauchement entre distributions |

### 3.4 Seuils d'interprétation pour les métriques basées sur la distribution

| Métrique | Excellent | Bon | Acceptable | Insuffisant |
|----------|-----------|-----|------------|-------------|
| **DW** (normalisée) | < 0.05 | < 0.1 | < 0.2 | > 0.2 |
| **DKL** (bits) | < 0.1 | < 0.3 | < 0.5 | > 0.5 |
| **DH** | < 0.1 | < 0.2 | < 0.3 | > 0.3 |
| **BC** | > 0.95 | > 0.9 | > 0.8 | < 0.8 |

## 4. Métriques de conservation des caractéristiques spécifiques

### 4.1 Conservation de la bimodalité locale

| Métrique | Formule | Interprétation |
|----------|---------|----------------|
| **Indice de conservation de bimodalité** (ICB) | min(1, nb_modes_locaux_hist / nb_modes_locaux_réel) | Mesure la préservation du nombre de sous-modes |
| **Ratio de séparation des sous-modes** (RSS) | (séparation_sous_modes_hist / séparation_sous_modes_réelle) | Mesure la préservation de la distance entre sous-modes |
| **Ratio d'amplitude relative** (RAR) | (amplitude_relative_sous_modes_hist / amplitude_relative_sous_modes_réelle) | Mesure la préservation des proportions entre sous-modes |

### 4.2 Conservation des épaulements

| Métrique | Formule | Interprétation |
|----------|---------|----------------|
| **Indice de détection d'épaulement** (IDE) | épaulement_détecté_hist / épaulement_détecté_réel | Mesure binaire de la préservation des épaulements |
| **Ratio de position d'épaulement** (RPE) | position_relative_épaulement_hist / position_relative_épaulement_réelle | Mesure la préservation de la position des épaulements |
| **Ratio d'amplitude d'épaulement** (RAE) | amplitude_relative_épaulement_hist / amplitude_relative_épaulement_réelle | Mesure la préservation de l'amplitude des épaulements |

## 5. Métriques spécifiques aux distributions de latence de blocs de 2KB

### 5.1 Indice de conservation de forme hiérarchique (ICFH)

Métrique pondérée qui évalue la conservation de forme pour tous les modes, avec une importance accrue pour les modes de latence faible:

```plaintext
ICFH = Σ(wi × similarité_forme_i) / Σwi
```plaintext
Où:
- wi = (max_latence / latence_mode_i)^α, avec α = 0.5 typiquement
- similarité_forme_i = coefficient de Bhattacharyya entre les distributions normalisées du mode i

| Plage | Interprétation |
|-------|----------------|
| > 0.95 | Excellente conservation hiérarchique |
| 0.9-0.95 | Bonne conservation hiérarchique |
| 0.85-0.9 | Conservation acceptable |
| < 0.85 | Conservation insuffisante |

### 5.2 Indice de conservation des transitions (ICT)

Évalue la préservation des formes dans les régions de transition entre modes:

```plaintext
ICT = moyenne(coefficient_Bhattacharyya(transition_i_réelle, transition_i_hist))
```plaintext
Où les transitions sont définies comme les régions entre les points d'inflexion des modes adjacents.

| Plage | Interprétation |
|-------|----------------|
| > 0.9 | Excellente conservation des transitions |
| 0.85-0.9 | Bonne conservation des transitions |
| 0.8-0.85 | Conservation acceptable |
| < 0.8 | Conservation insuffisante |

## 6. Implémentation et calcul

### 6.1 Normalisation des distributions pour comparaison de forme

```python
def normalize_mode_shape(x_values, y_values, mode_position, window_width):
    """
    Normalise la forme d'un mode pour comparaison.
    
    Args:
        x_values: Valeurs x (latences)
        y_values: Valeurs y (densités/fréquences)
        mode_position: Position du mode
        window_width: Largeur de la fenêtre autour du mode
        
    Returns:
        x_norm: Valeurs x normalisées (centrées et mises à l'échelle)
        y_norm: Valeurs y normalisées (somme = 1)
    """
    # Sélectionner les points dans la fenêtre autour du mode

    mask = np.abs(x_values - mode_position) <= window_width
    x_window = x_values[mask]
    y_window = y_values[mask]
    
    if len(x_window) == 0:
        return np.array([]), np.array([])
    
    # Normaliser les positions x (centrer et mettre à l'échelle)

    x_norm = (x_window - mode_position) / window_width
    
    # Normaliser les valeurs y (somme = 1)

    y_sum = np.sum(y_window)
    if y_sum > 0:
        y_norm = y_window / y_sum
    else:
        y_norm = y_window
    
    return x_norm, y_norm
```plaintext
### 6.2 Calcul du coefficient de Bhattacharyya

```python
def bhattacharyya_coefficient(p, q):
    """
    Calcule le coefficient de Bhattacharyya entre deux distributions discrètes.
    
    Args:
        p: Première distribution (normalisée)
        q: Deuxième distribution (normalisée)
        
    Returns:
        bc: Coefficient de Bhattacharyya
    """
    # Vérifier que les distributions sont normalisées

    if abs(np.sum(p) - 1.0) > 1e-10 or abs(np.sum(q) - 1.0) > 1e-10:
        raise ValueError("Les distributions doivent être normalisées")
    
    # Calculer le coefficient

    bc = np.sum(np.sqrt(p * q))
    
    return bc
```plaintext
### 6.3 Calcul des métriques de conservation de forme

```python
def calculate_shape_preservation_metrics(real_modes, histogram_modes, 
                                        real_distribution, hist_distribution):
    """
    Calcule les métriques de conservation de forme des modes.
    
    Args:
        real_modes: Positions réelles des modes
        histogram_modes: Positions des modes dans l'histogramme
        real_distribution: Tuple (x_real, y_real) de la distribution réelle
        hist_distribution: Tuple (x_hist, y_hist) de l'histogramme
        
    Returns:
        metrics: Dictionnaire des métriques calculées
    """
    x_real, y_real = real_distribution
    x_hist, y_hist = hist_distribution
    
    # Associer chaque mode réel au mode histogramme le plus proche

    mode_pairs = []
    for real_mode in real_modes:
        closest_idx = np.argmin(np.abs(histogram_modes - real_mode))
        mode_pairs.append((real_mode, histogram_modes[closest_idx]))
    
    # Calculer les métriques pour chaque mode

    bc_values = []
    skewness_ratios = []
    kurtosis_ratios = []
    
    for real_mode, hist_mode in mode_pairs:
        # Estimer la largeur de la fenêtre comme 3 fois l'écart-type local

        # ou utiliser une heuristique basée sur la distance au mode voisin

        window_width = min(
            estimate_local_std(x_real, y_real, real_mode) * 3,
            min_distance_to_neighbor(real_modes, real_mode) * 0.8
        )
        
        # Normaliser les formes pour comparaison

        x_real_norm, y_real_norm = normalize_mode_shape(
            x_real, y_real, real_mode, window_width)
        x_hist_norm, y_hist_norm = normalize_mode_shape(
            x_hist, y_hist, hist_mode, window_width)
        
        if len(x_real_norm) == 0 or len(x_hist_norm) == 0:
            continue
        
        # Interpoler pour avoir les mêmes points x

        x_common = np.linspace(-1, 1, 100)
        y_real_interp = np.interp(x_common, x_real_norm, y_real_norm)
        y_hist_interp = np.interp(x_common, x_hist_norm, y_hist_norm)
        
        # Normaliser à nouveau après interpolation

        y_real_interp = y_real_interp / np.sum(y_real_interp)
        y_hist_interp = y_hist_interp / np.sum(y_hist_interp)
        
        # Calculer le coefficient de Bhattacharyya

        bc = bhattacharyya_coefficient(y_real_interp, y_hist_interp)
        bc_values.append(bc)
        
        # Calculer les moments centraux

        real_skewness = calculate_skewness(x_common, y_real_interp)
        hist_skewness = calculate_skewness(x_common, y_hist_interp)
        
        real_kurtosis = calculate_kurtosis(x_common, y_real_interp)
        hist_kurtosis = calculate_kurtosis(x_common, y_hist_interp)
        
        # Calculer les ratios (avec gestion des cas spéciaux)

        if abs(real_skewness) > 1e-10:
            skewness_ratio = hist_skewness / real_skewness
        else:
            skewness_ratio = 1.0 if abs(hist_skewness) < 1e-10 else float('inf')
        
        if abs(real_kurtosis - 3) > 1e-10:
            kurtosis_ratio = (hist_kurtosis - 3) / (real_kurtosis - 3)
        else:
            kurtosis_ratio = 1.0 if abs(hist_kurtosis - 3) < 1e-10 else float('inf')
        
        skewness_ratios.append(skewness_ratio)
        kurtosis_ratios.append(kurtosis_ratio)
    
    # Calculer l'indice de conservation de forme hiérarchique

    if bc_values:
        max_latency = max(real_modes)
        weights = [(max_latency / real_mode)**0.5 for real_mode, _ in mode_pairs]
        weight_sum = sum(weights)
        icfh = sum([w * bc for w, bc in zip(weights, bc_values)]) / weight_sum
    else:
        icfh = 0.0
    
    # Filtrer les valeurs infinies ou NaN

    skewness_ratios = [r for r in skewness_ratios if np.isfinite(r)]
    kurtosis_ratios = [r for r in kurtosis_ratios if np.isfinite(r)]
    
    # Résultats

    metrics = {
        "BC": {
            "values": bc_values,
            "mean": np.mean(bc_values) if bc_values else 0.0
        },
        "RCA": {
            "values": skewness_ratios,
            "mean": np.mean(skewness_ratios) if skewness_ratios else 0.0
        },
        "RCK": {
            "values": kurtosis_ratios,
            "mean": np.mean(kurtosis_ratios) if kurtosis_ratios else 0.0
        },
        "ICFH": icfh
    }
    
    return metrics
```plaintext
### 6.4 Fonctions auxiliaires

```python
def calculate_skewness(x, p):
    """Calcule l'asymétrie d'une distribution discrète."""
    mean = np.sum(x * p)
    variance = np.sum(p * (x - mean)**2)
    if variance > 0:
        std = np.sqrt(variance)
        skewness = np.sum(p * ((x - mean) / std)**3)
        return skewness
    return 0.0

def calculate_kurtosis(x, p):
    """Calcule l'aplatissement d'une distribution discrète."""
    mean = np.sum(x * p)
    variance = np.sum(p * (x - mean)**2)
    if variance > 0:
        std = np.sqrt(variance)
        kurtosis = np.sum(p * ((x - mean) / std)**4)
        return kurtosis
    return 3.0

def estimate_local_std(x, y, mode_position):
    """Estime l'écart-type local autour d'un mode."""
    # Trouver l'index le plus proche du mode

    idx = np.argmin(np.abs(x - mode_position))
    
    # Trouver la hauteur du mode

    mode_height = y[idx]
    
    # Trouver les points à mi-hauteur

    half_height = mode_height / 2
    
    # Chercher à gauche

    left_idx = idx
    while left_idx > 0 and y[left_idx] > half_height:
        left_idx -= 1
    
    # Chercher à droite

    right_idx = idx
    while right_idx < len(y) - 1 and y[right_idx] > half_height:
        right_idx += 1
    
    # Calculer la largeur à mi-hauteur

    fwhm = x[right_idx] - x[left_idx]
    
    # Convertir FWHM en écart-type (pour une distribution normale)

    # FWHM = 2.355 * sigma

    std = fwhm / 2.355
    
    return max(std, (x[1] - x[0]) * 2)  # Garantir une valeur minimale

def min_distance_to_neighbor(modes, current_mode):
    """Calcule la distance minimale à un mode voisin."""
    if len(modes) <= 1:
        return float('inf')
    
    distances = [abs(m - current_mode) for m in modes if m != current_mode]
    return min(distances) if distances else float('inf')
```plaintext
## 7. Seuils recommandés pour les latences de blocs de 2KB

| Métrique | Mode | Monitoring | Analyse standard | Analyse détaillée |
|----------|------|------------|------------------|-------------------|
| **BC** | L1/L2 | > 0.8 | > 0.85 | > 0.9 |
| **BC** | L3/Mém | > 0.8 | > 0.85 | > 0.9 |
| **BC** | Cache Sys | > 0.75 | > 0.8 | > 0.85 |
| **BC** | Stockage | > 0.7 | > 0.75 | > 0.8 |
| **RCA** | L1/L2 | 0.7-1.3 | 0.8-1.2 | 0.9-1.1 |
| **RCA** | L3/Mém | 0.7-1.3 | 0.8-1.2 | 0.9-1.1 |
| **RCA** | Cache Sys | 0.6-1.4 | 0.7-1.3 | 0.8-1.2 |
| **RCA** | Stockage | 0.5-1.5 | 0.6-1.4 | 0.7-1.3 |
| **ICFH** | Global | > 0.75 | > 0.8 | > 0.85 |

## 8. Représentation JSON

```json
{
  "modeShapePreservationMetrics": {
    "momentBased": {
      "skewnessConservationRatio": {
        "definition": "Ratio of histogram mode skewness to real mode skewness",
        "formula": "skewness_histogram / skewness_real",
        "unit": "ratio",
        "thresholds": {
          "excellent": "0.9-1.1",
          "good": "0.8-1.2",
          "acceptable": "0.7-1.3",
          "insufficient": "< 0.7 or > 1.3"
        }
      },
      "kurtosisConservationRatio": {
        "definition": "Ratio of histogram mode excess kurtosis to real mode excess kurtosis",
        "formula": "(kurtosis_histogram - 3) / (kurtosis_real - 3)",
        "unit": "ratio",
        "thresholds": {
          "excellent": "0.9-1.1",
          "good": "0.8-1.2",
          "acceptable": "0.6-1.4",
          "insufficient": "< 0.6 or > 1.4"
        }
      }
    },
    "distributionBased": {
      "bhattacharyyaCoefficient": {
        "definition": "Measure of overlap between normalized mode shapes",
        "formula": "sum(sqrt(p_real * p_histogram))",
        "unit": "ratio",
        "thresholds": {
          "excellent": "> 0.95",
          "good": "> 0.9",
          "acceptable": "> 0.8",
          "insufficient": "< 0.8"
        }
      }
    },
    "specific2KBLatency": {
      "hierarchicalShapeConservationIndex": {
        "definition": "Weighted shape preservation metric giving more importance to low-latency modes",
        "formula": "sum(wi * bhattacharyya_coefficient_i) / sum(wi)",
        "unit": "ratio",
        "thresholds": {
          "excellent": "> 0.95",
          "good": "> 0.9",
          "acceptable": "> 0.85",
          "insufficient": "< 0.85"
        }
      }
    }
  }
}
```plaintext
## 9. Exemples d'application

### 9.1 Cas d'étude: Histogramme à 20 bins uniformes

Pour une distribution de latence de blocs de 2KB typique avec 4 modes:

| Mode | Position | BC | RCA | RCK |
|------|----------|----|----|-----|
| L1/L2 | 80 µs | 0.72 | 0.65 | 0.55 |
| L3/Mém | 200 µs | 0.78 | 0.82 | 0.75 |
| Cache Sys | 550 µs | 0.81 | 0.88 | 0.92 |
| Stockage | 2200 µs | 0.76 | 0.95 | 1.10 |

ICFH = 0.76 (acceptable pour monitoring, insuffisant pour analyse standard)

### 9.2 Cas d'étude: Histogramme à largeur variable optimisée

| Mode | Position | BC | RCA | RCK |
|------|----------|----|----|-----|
| L1/L2 | 80 µs | 0.91 | 0.94 | 0.88 |
| L3/Mém | 200 µs | 0.93 | 0.95 | 0.92 |
| Cache Sys | 550 µs | 0.89 | 0.91 | 0.95 |
| Stockage | 2200 µs | 0.85 | 0.88 | 1.05 |

ICFH = 0.91 (excellent pour monitoring, bon pour analyse standard)

## 10. Conclusion

Les métriques de conservation de la forme des modes fournissent un cadre quantitatif pour évaluer la fidélité avec laquelle un histogramme représente les caractéristiques détaillées des distributions de latence. Pour les distributions de latence de blocs de 2KB, ces métriques sont particulièrement importantes car:

1. **Identification des mécanismes sous-jacents**: La forme précise des modes révèle des informations sur les mécanismes spécifiques de la hiérarchie de stockage.

2. **Détection des anomalies subtiles**: Des changements dans la forme des modes peuvent indiquer des problèmes système avant qu'ils n'affectent significativement les métriques globales.

3. **Optimisation ciblée**: Une représentation fidèle de la forme permet d'identifier précisément les composants nécessitant une optimisation.

Les métriques présentées dans ce document permettent d'évaluer:
- La préservation des caractéristiques d'asymétrie et d'aplatissement
- La fidélité globale de la forme via des mesures de similarité entre distributions
- La conservation des caractéristiques hiérarchiques à travers les différents niveaux de latence

Ces métriques constituent un outil essentiel pour optimiser les stratégies de binning et garantir que les histogrammes de latence capturent fidèlement les nuances importantes des distributions sous-jacentes, permettant une analyse plus précise et des décisions d'optimisation mieux ciblées.
