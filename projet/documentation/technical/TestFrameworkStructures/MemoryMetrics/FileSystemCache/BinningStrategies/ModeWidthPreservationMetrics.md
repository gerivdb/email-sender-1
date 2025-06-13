# Métriques de préservation de la largeur des modes

## 1. Introduction

Ce document définit des métriques quantitatives pour évaluer la préservation de la largeur des modes dans les histogrammes de latence. La largeur d'un mode est une caractéristique fondamentale qui reflète la variabilité des performances au sein d'un régime spécifique. Une représentation fidèle de cette largeur est essentielle pour l'analyse de la stabilité des performances et la détection des anomalies dans les distributions de latence de blocs de 2KB.

## 2. Définitions fondamentales

### 2.1 Mesures de largeur

| Mesure | Définition | Application |
|--------|------------|-------------|
| **FWHM** (Full Width at Half Maximum) | Largeur à mi-hauteur du mode | Mesure standard de la largeur d'un pic |
| **FWTM** (Full Width at Tenth Maximum) | Largeur à 10% du maximum | Caractérisation des queues du mode |
| **Écart-type local** (σ_local) | Écart-type des observations dans la région du mode | Mesure statistique de la dispersion |
| **Largeur interquartile locale** (IQR_local) | Différence entre Q3 et Q1 dans la région du mode | Mesure robuste de la dispersion |

### 2.2 Calcul des largeurs dans les histogrammes

Pour un histogramme avec des bins de largeur fixe, la largeur FWHM peut être estimée par:

```plaintext
FWHM_hist = largeur_bin × (nombre de bins avec hauteur ≥ 0.5 × hauteur_max + 
           fraction du bin à gauche + fraction du bin à droite)
```plaintext
Où les fractions sont calculées par interpolation linéaire aux seuils de mi-hauteur.

## 3. Métriques de préservation de largeur

### 3.1 Métriques de base

| Métrique | Formule | Interprétation |
|----------|---------|----------------|
| **Erreur absolue de largeur** (EAL) | \|FWHM_réel - FWHM_hist\| | Différence absolue entre largeurs |
| **Erreur relative de largeur** (ERL) | \|FWHM_réel - FWHM_hist\| / FWHM_réel | Différence relative entre largeurs |
| **Ratio de préservation de largeur** (RPL) | FWHM_hist / FWHM_réel | Rapport direct des largeurs |

### 3.2 Seuils d'interprétation

| Métrique | Excellent | Bon | Acceptable | Insuffisant |
|----------|-----------|-----|------------|-------------|
| **EAL** | < 0.1 × FWHM_réel | < 0.2 × FWHM_réel | < 0.3 × FWHM_réel | > 0.3 × FWHM_réel |
| **ERL** | < 10% | < 20% | < 30% | > 30% |
| **RPL** | 0.9-1.1 | 0.8-1.2 | 0.7-1.3 | < 0.7 ou > 1.3 |

## 4. Métriques avancées

### 4.1 Indice de préservation de forme (IPF)

Évalue la préservation du profil complet du mode, pas seulement sa largeur:

```plaintext
IPF = 1 - (1/n) × Σ|densité_normalisée_réelle(i) - densité_normalisée_hist(i)|
```plaintext
Où les densités sont normalisées par leur maximum et échantillonnées en n points équidistants.

| Plage | Interprétation |
|-------|----------------|
| 0.95-1.0 | Excellente préservation de forme |
| 0.9-0.95 | Bonne préservation de forme |
| 0.8-0.9 | Préservation acceptable |
| < 0.8 | Préservation insuffisante |

### 4.2 Ratio de conservation d'asymétrie (RCA)

Compare l'asymétrie du mode dans la distribution réelle et l'histogramme:

```plaintext
RCA = asymétrie_hist / asymétrie_réelle
```plaintext
Où l'asymétrie peut être mesurée par le rapport entre les demi-largeurs droite et gauche à mi-hauteur.

| Plage | Interprétation |
|-------|----------------|
| 0.9-1.1 | Excellente conservation d'asymétrie |
| 0.8-1.2 | Bonne conservation d'asymétrie |
| 0.7-1.3 | Conservation acceptable |
| < 0.7 ou > 1.3 | Conservation insuffisante |

### 4.3 Indice de résolution relative (IRR)

Évalue si la résolution de l'histogramme est suffisante par rapport à la largeur du mode:

```plaintext
IRR = FWHM_réel / largeur_bin
```plaintext
| Plage | Interprétation |
|-------|----------------|
| > 8 | Excellente résolution relative |
| 5-8 | Bonne résolution relative |
| 3-5 | Résolution acceptable |
| < 3 | Résolution insuffisante |

## 5. Métriques spécifiques aux distributions de latence de blocs de 2KB

### 5.1 Indice de préservation de variabilité hiérarchique (IPVH)

Métrique pondérée qui évalue la préservation des largeurs de tous les modes, avec une importance accrue pour les modes de latence faible:

```plaintext
IPVH = Σ(wi × (1 - |FWHM_réel_i - FWHM_hist_i| / FWHM_réel_i)) / Σwi
```plaintext
Où wi = (max_latence / latence_mode_i)^α, avec α = 0.5 typiquement.

| Plage | Interprétation |
|-------|----------------|
| 0.95-1.0 | Excellente préservation hiérarchique |
| 0.9-0.95 | Bonne préservation hiérarchique |
| 0.8-0.9 | Préservation acceptable |
| < 0.8 | Préservation insuffisante |

### 5.2 Ratio de conservation de stabilité (RCS)

Compare le coefficient de variation (CV = σ/μ) dans la région de chaque mode:

```plaintext
RCS = CV_hist / CV_réel
```plaintext
| Plage | Interprétation |
|-------|----------------|
| 0.9-1.1 | Excellente conservation de stabilité |
| 0.8-1.2 | Bonne conservation de stabilité |
| 0.7-1.3 | Conservation acceptable |
| < 0.7 ou > 1.3 | Conservation insuffisante |

## 6. Implémentation et calcul

### 6.1 Estimation de la largeur FWHM dans les histogrammes

```python
def estimate_fwhm_in_histogram(bin_edges, bin_counts, mode_position):
    """
    Estime la largeur à mi-hauteur (FWHM) d'un mode dans un histogramme.
    
    Args:
        bin_edges: Limites des bins
        bin_counts: Comptage par bin
        mode_position: Position estimée du mode
        
    Returns:
        fwhm: Largeur à mi-hauteur estimée
    """
    # Calculer les centres des bins

    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2
    bin_width = bin_edges[1] - bin_edges[0]  # Supposant des bins de largeur fixe

    
    # Trouver le bin contenant le mode

    mode_bin_idx = np.argmin(np.abs(bin_centers - mode_position))
    max_height = bin_counts[mode_bin_idx]
    half_max = max_height / 2
    
    # Trouver les intersections avec la mi-hauteur

    left_idx = mode_bin_idx
    while left_idx > 0 and bin_counts[left_idx] > half_max:
        left_idx -= 1
    
    right_idx = mode_bin_idx
    while right_idx < len(bin_counts) - 1 and bin_counts[right_idx] > half_max:
        right_idx += 1
    
    # Interpolation linéaire pour les positions exactes des intersections

    if left_idx < len(bin_counts) - 1:
        if bin_counts[left_idx] != bin_counts[left_idx + 1]:
            left_frac = (half_max - bin_counts[left_idx]) / (bin_counts[left_idx + 1] - bin_counts[left_idx])
        else:
            left_frac = 0
    else:
        left_frac = 0
    
    if right_idx > 0:
        if bin_counts[right_idx] != bin_counts[right_idx - 1]:
            right_frac = (half_max - bin_counts[right_idx]) / (bin_counts[right_idx - 1] - bin_counts[right_idx])
        else:
            right_frac = 0
    else:
        right_frac = 0
    
    # Calculer la largeur FWHM

    left_pos = bin_centers[left_idx] + left_frac * bin_width
    right_pos = bin_centers[right_idx] - right_frac * bin_width
    
    fwhm = right_pos - left_pos
    
    return max(fwhm, bin_width)  # Garantir une largeur minimale d'un bin

```plaintext
### 6.2 Calcul des métriques de préservation de largeur

```python
def calculate_width_preservation_metrics(real_modes, real_fwhms, 
                                        histogram_modes, bin_edges, bin_counts):
    """
    Calcule les métriques de préservation de largeur des modes.
    
    Args:
        real_modes: Positions réelles des modes
        real_fwhms: Largeurs FWHM réelles des modes
        histogram_modes: Positions des modes dans l'histogramme
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme
        
    Returns:
        metrics: Dictionnaire des métriques calculées
    """
    # Associer chaque mode réel au mode histogramme le plus proche

    mode_pairs = []
    for i, real_mode in enumerate(real_modes):
        closest_idx = np.argmin(np.abs(histogram_modes - real_mode))
        mode_pairs.append((i, closest_idx))
    
    # Calculer les largeurs FWHM dans l'histogramme

    hist_fwhms = [estimate_fwhm_in_histogram(bin_edges, bin_counts, histogram_modes[idx]) 
                 for _, idx in mode_pairs]
    
    # Calculer les métriques de base

    abs_errors = [abs(real_fwhms[i] - hist_fwhm) 
                 for (i, _), hist_fwhm in zip(mode_pairs, hist_fwhms)]
    
    rel_errors = [abs(real_fwhms[i] - hist_fwhm) / real_fwhms[i] 
                 for (i, _), hist_fwhm in zip(mode_pairs, hist_fwhms)]
    
    ratios = [hist_fwhm / real_fwhms[i] 
             for (i, _), hist_fwhm in zip(mode_pairs, hist_fwhms)]
    
    # Calculer l'indice de résolution relative

    bin_width = bin_edges[1] - bin_edges[0]  # Supposant des bins de largeur fixe

    irr_values = [real_fwhms[i] / bin_width for i, _ in mode_pairs]
    
    # Calculer l'indice de préservation de variabilité hiérarchique

    max_latency = max(real_modes)
    weights = [(max_latency / real_modes[i])**0.5 for i, _ in mode_pairs]
    weight_sum = sum(weights)
    
    ipvh = sum([w * (1 - abs(real_fwhms[i] - hist_fwhm) / real_fwhms[i]) 
               for w, ((i, _), hist_fwhm) in zip(weights, zip(mode_pairs, hist_fwhms))]) / weight_sum
    
    # Résultats

    metrics = {
        "EAL": {
            "values": abs_errors,
            "mean": np.mean(abs_errors),
            "max": max(abs_errors)
        },
        "ERL": {
            "values": rel_errors,
            "mean": np.mean(rel_errors),
            "max": max(rel_errors)
        },
        "RPL": {
            "values": ratios,
            "mean": np.mean(ratios),
            "min": min(ratios),
            "max": max(ratios)
        },
        "IRR": {
            "values": irr_values,
            "mean": np.mean(irr_values),
            "min": min(irr_values)
        },
        "IPVH": ipvh
    }
    
    return metrics
```plaintext
## 7. Seuils recommandés pour les latences de blocs de 2KB

| Métrique | Mode | Monitoring | Analyse standard | Analyse détaillée |
|----------|------|------------|------------------|-------------------|
| **ERL** | L1/L2 | <30% | <20% | <10% |
| **ERL** | L3/Mém | <30% | <20% | <10% |
| **ERL** | Cache Sys | <35% | <25% | <15% |
| **ERL** | Stockage | <40% | <30% | <20% |
| **RPL** | L1/L2 | 0.7-1.3 | 0.8-1.2 | 0.9-1.1 |
| **RPL** | L3/Mém | 0.7-1.3 | 0.8-1.2 | 0.9-1.1 |
| **RPL** | Cache Sys | 0.65-1.35 | 0.75-1.25 | 0.85-1.15 |
| **RPL** | Stockage | 0.6-1.4 | 0.7-1.3 | 0.8-1.2 |
| **IRR** | L1/L2 | >3 | >5 | >8 |
| **IRR** | L3/Mém | >3 | >5 | >8 |
| **IRR** | Cache Sys | >3 | >4 | >6 |
| **IRR** | Stockage | >2 | >3 | >5 |
| **IPVH** | Global | >0.75 | >0.85 | >0.9 |

## 8. Représentation JSON

```json
{
  "modeWidthPreservationMetrics": {
    "basic": {
      "absoluteWidthError": {
        "definition": "Absolute difference between real and histogram mode widths",
        "formula": "|FWHM_real - FWHM_histogram|",
        "unit": "microseconds",
        "thresholds": {
          "excellent": "< 0.1 × FWHM_real",
          "good": "< 0.2 × FWHM_real",
          "acceptable": "< 0.3 × FWHM_real",
          "insufficient": "> 0.3 × FWHM_real"
        }
      },
      "relativeWidthError": {
        "definition": "Relative difference between real and histogram mode widths",
        "formula": "|FWHM_real - FWHM_histogram| / FWHM_real",
        "unit": "ratio",
        "thresholds": {
          "excellent": "< 0.1",
          "good": "< 0.2",
          "acceptable": "< 0.3",
          "insufficient": "> 0.3"
        }
      },
      "widthPreservationRatio": {
        "definition": "Ratio of histogram mode width to real mode width",
        "formula": "FWHM_histogram / FWHM_real",
        "unit": "ratio",
        "thresholds": {
          "excellent": "0.9-1.1",
          "good": "0.8-1.2",
          "acceptable": "0.7-1.3",
          "insufficient": "< 0.7 or > 1.3"
        }
      }
    },
    "advanced": {
      "relativeResolutionIndex": {
        "definition": "Ratio of real mode width to bin width",
        "formula": "FWHM_real / bin_width",
        "unit": "ratio",
        "thresholds": {
          "excellent": "> 8",
          "good": "5-8",
          "acceptable": "3-5",
          "insufficient": "< 3"
        }
      }
    },
    "specific2KBLatency": {
      "hierarchicalVariabilityPreservationIndex": {
        "definition": "Weighted width preservation metric giving more importance to low-latency modes",
        "formula": "Σ(wi × (1 - |FWHM_real_i - FWHM_hist_i| / FWHM_real_i)) / Σwi",
        "unit": "ratio",
        "thresholds": {
          "excellent": "> 0.95",
          "good": "> 0.9",
          "acceptable": "> 0.8",
          "insufficient": "< 0.8"
        }
      }
    }
  }
}
```plaintext
## 9. Exemples d'application

### 9.1 Cas d'étude: Histogramme à 20 bins uniformes

Pour une distribution de latence de blocs de 2KB typique avec 4 modes:

| Mode | Position réelle | FWHM réel | Position histogramme | FWHM histogramme | ERL | RPL | IRR |
|------|----------------|-----------|---------------------|------------------|-----|-----|-----|
| L1/L2 | 80 µs | 25 µs | 75 µs | 50 µs | 100% | 2.0 | 1.0 |
| L3/Mém | 200 µs | 50 µs | 195 µs | 75 µs | 50% | 1.5 | 2.0 |
| Cache Sys | 550 µs | 120 µs | 525 µs | 150 µs | 25% | 1.25 | 4.8 |
| Stockage | 2200 µs | 750 µs | 2250 µs | 900 µs | 20% | 1.2 | 3.0 |

IPVH = 0.65 (insuffisant)

### 9.2 Cas d'étude: Histogramme à largeur variable optimisée

| Mode | Position réelle | FWHM réel | Position histogramme | FWHM histogramme | ERL | RPL | IRR |
|------|----------------|-----------|---------------------|------------------|-----|-----|-----|
| L1/L2 | 80 µs | 25 µs | 82 µs | 28 µs | 12% | 1.12 | 8.3 |
| L3/Mém | 200 µs | 50 µs | 198 µs | 54 µs | 8% | 1.08 | 10.0 |
| Cache Sys | 550 µs | 120 µs | 545 µs | 130 µs | 8% | 1.08 | 6.0 |
| Stockage | 2200 µs | 750 µs | 2180 µs | 820 µs | 9% | 1.09 | 3.75 |

IPVH = 0.91 (bon)

## 10. Conclusion

Les métriques de préservation de la largeur des modes fournissent un cadre quantitatif pour évaluer la fidélité avec laquelle un histogramme représente la variabilité des performances au sein de chaque régime de latence. Pour les distributions de latence de blocs de 2KB, ces métriques sont particulièrement importantes car:

1. **Caractérisation de la stabilité**: La largeur des modes reflète directement la stabilité des performances dans chaque niveau de la hiérarchie de stockage.

2. **Détection des anomalies**: Une représentation fidèle de la largeur est essentielle pour distinguer les variations normales des anomalies.

3. **Optimisation ciblée**: La connaissance précise de la variabilité par niveau permet de cibler les efforts d'optimisation.

Les métriques présentées dans ce document permettent d'évaluer:
- La précision absolue et relative de la représentation des largeurs
- L'adéquation de la résolution de l'histogramme par rapport aux caractéristiques des modes
- La préservation de la variabilité à travers les différents niveaux de la hiérarchie

Ces métriques constituent un outil essentiel pour optimiser les stratégies de binning et garantir que les histogrammes de latence capturent fidèlement la variabilité des performances dans les différents régimes.
