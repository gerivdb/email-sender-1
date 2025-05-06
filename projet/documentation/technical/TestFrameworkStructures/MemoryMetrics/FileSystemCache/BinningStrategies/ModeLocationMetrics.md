# Métriques de précision de localisation des modes

## 1. Introduction

Ce document définit des métriques quantitatives pour évaluer la précision de localisation des modes dans les histogrammes de latence. La localisation précise des modes est essentielle pour identifier correctement les différents régimes de performance et les transitions entre niveaux de cache dans les distributions de latence de blocs de 2KB.

## 2. Métriques fondamentales

### 2.1 Erreur absolue de localisation (EAL)

```
EAL = |position_mode_réel - position_mode_histogramme|
```

| Plage | Interprétation |
|-------|----------------|
| 0-0.1×W | Excellente précision |
| 0.1×W-0.25×W | Bonne précision |
| 0.25×W-0.5×W | Précision acceptable |
| >0.5×W | Précision insuffisante |

Où W est la largeur du mode (FWHM).

### 2.2 Erreur relative de localisation (ERL)

```
ERL = |position_mode_réel - position_mode_histogramme| / position_mode_réel
```

| Plage | Interprétation |
|-------|----------------|
| 0-1% | Excellente précision |
| 1-5% | Bonne précision |
| 5-10% | Précision acceptable |
| >10% | Précision insuffisante |

### 2.3 Erreur normalisée par la largeur de bin (ENB)

```
ENB = |position_mode_réel - position_mode_histogramme| / largeur_bin
```

| Plage | Interprétation |
|-------|----------------|
| 0-0.25 | Excellente précision |
| 0.25-0.5 | Bonne précision |
| 0.5-1.0 | Précision acceptable |
| >1.0 | Précision insuffisante |

## 3. Métriques avancées

### 3.1 Indice de précision multimodale (IPM)

```
IPM = 1 - (Σ|position_mode_i_réel - position_mode_i_histogramme| / Σ|position_mode_i_réel|)
```

| Plage | Interprétation |
|-------|----------------|
| 0.95-1.0 | Excellente précision |
| 0.9-0.95 | Bonne précision |
| 0.8-0.9 | Précision acceptable |
| <0.8 | Précision insuffisante |

### 3.2 Ratio de conservation des distances inter-modes (RCDIM)

```
RCDIM = (distance_inter_modes_histogramme / distance_inter_modes_réelle)
```

| Plage | Interprétation |
|-------|----------------|
| 0.95-1.05 | Excellente conservation |
| 0.9-1.1 | Bonne conservation |
| 0.8-1.2 | Conservation acceptable |
| <0.8 ou >1.2 | Conservation insuffisante |

### 3.3 Coefficient de corrélation des positions (CCP)

```
CCP = corr(positions_modes_réels, positions_modes_histogramme)
```

| Plage | Interprétation |
|-------|----------------|
| 0.98-1.0 | Excellente corrélation |
| 0.95-0.98 | Bonne corrélation |
| 0.9-0.95 | Corrélation acceptable |
| <0.9 | Corrélation insuffisante |

## 4. Métriques spécifiques aux latences de blocs de 2KB

### 4.1 Précision de localisation hiérarchique (PLH)

Métrique pondérée qui accorde plus d'importance aux modes de latence faible:

```
PLH = Σ(wi × (1 - |position_mode_i_réel - position_mode_i_histogramme| / position_mode_i_réel))
```

Où wi = (max_position / position_mode_i_réel)^α, avec α = 0.5 typiquement.

| Plage | Interprétation |
|-------|----------------|
| 0.95-1.0 | Excellente précision hiérarchique |
| 0.9-0.95 | Bonne précision hiérarchique |
| 0.8-0.9 | Précision hiérarchique acceptable |
| <0.8 | Précision hiérarchique insuffisante |

### 4.2 Indice de conservation des transitions (ICT)

Évalue la préservation des points de transition entre niveaux de cache:

```
ICT = 1 - Σ|transition_i_réelle - transition_i_histogramme| / Σ|transition_i_réelle|
```

| Plage | Interprétation |
|-------|----------------|
| 0.95-1.0 | Excellente conservation des transitions |
| 0.9-0.95 | Bonne conservation des transitions |
| 0.8-0.9 | Conservation acceptable des transitions |
| <0.8 | Conservation insuffisante des transitions |

## 5. Implémentation et calcul

### 5.1 Détection des modes dans les histogrammes

```python
def detect_modes_in_histogram(bin_edges, bin_counts):
    """
    Détecte les modes dans un histogramme.
    
    Args:
        bin_edges: Limites des bins
        bin_counts: Comptage par bin
        
    Returns:
        mode_positions: Positions estimées des modes
    """
    # Calculer les centres des bins
    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2
    
    # Identifier les maxima locaux
    is_peak = np.r_[True, bin_counts[1:] < bin_counts[:-1]] & np.r_[bin_counts[:-1] < bin_counts[1:], True]
    peak_indices = np.where(is_peak)[0]
    
    # Filtrer les pics insignifiants (< 10% du pic maximal)
    significant_peaks = peak_indices[bin_counts[peak_indices] > 0.1 * np.max(bin_counts)]
    
    # Affiner la position des pics par interpolation parabolique
    refined_positions = []
    for idx in significant_peaks:
        if idx > 0 and idx < len(bin_counts) - 1:
            x = bin_centers[idx-1:idx+2]
            y = bin_counts[idx-1:idx+2]
            
            # Ajustement parabolique
            a, b, c = np.polyfit(x, y, 2)
            
            # Position du maximum: -b/(2*a)
            refined_position = -b / (2 * a) if a != 0 else bin_centers[idx]
            refined_positions.append(refined_position)
        else:
            refined_positions.append(bin_centers[idx])
    
    return np.array(refined_positions)
```

### 5.2 Calcul des métriques de localisation

```python
def calculate_location_metrics(real_modes, histogram_modes, bin_width, mode_widths=None):
    """
    Calcule les métriques de précision de localisation.
    
    Args:
        real_modes: Positions réelles des modes
        histogram_modes: Positions des modes dans l'histogramme
        bin_width: Largeur des bins
        mode_widths: Largeurs des modes (FWHM)
        
    Returns:
        metrics: Dictionnaire des métriques calculées
    """
    # Associer chaque mode réel au mode histogramme le plus proche
    mode_pairs = []
    for real_mode in real_modes:
        closest_idx = np.argmin(np.abs(histogram_modes - real_mode))
        mode_pairs.append((real_mode, histogram_modes[closest_idx]))
    
    # Calculer les métriques de base
    abs_errors = [abs(real - hist) for real, hist in mode_pairs]
    rel_errors = [abs(real - hist) / real for real, hist in mode_pairs]
    bin_norm_errors = [abs(real - hist) / bin_width for real, hist in mode_pairs]
    
    # Métriques avancées
    ipm = 1 - sum(abs_errors) / sum([real for real, _ in mode_pairs])
    
    # Distances inter-modes
    real_distances = [real_modes[i+1] - real_modes[i] for i in range(len(real_modes)-1)]
    hist_distances = [histogram_modes[i+1] - histogram_modes[i] for i in range(len(histogram_modes)-1)]
    
    # Ajuster les listes à la même longueur
    min_len = min(len(real_distances), len(hist_distances))
    real_distances = real_distances[:min_len]
    hist_distances = hist_distances[:min_len]
    
    rcdim_values = [hist / real for hist, real in zip(hist_distances, real_distances)]
    
    # Coefficient de corrélation
    if len(mode_pairs) > 1:
        real_positions = [real for real, _ in mode_pairs]
        hist_positions = [hist for _, hist in mode_pairs]
        ccp = np.corrcoef(real_positions, hist_positions)[0, 1]
    else:
        ccp = 1.0  # Par défaut pour un seul mode
    
    # Métriques spécifiques aux latences 2KB
    max_position = max([real for real, _ in mode_pairs])
    weights = [(max_position / real)**0.5 for real, _ in mode_pairs]
    weight_sum = sum(weights)
    plh = sum([w * (1 - abs(real - hist) / real) for w, (real, hist) in zip(weights, mode_pairs)]) / weight_sum
    
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
        "ENB": {
            "values": bin_norm_errors,
            "mean": np.mean(bin_norm_errors),
            "max": max(bin_norm_errors)
        },
        "IPM": ipm,
        "RCDIM": {
            "values": rcdim_values,
            "mean": np.mean(rcdim_values) if rcdim_values else 1.0
        },
        "CCP": ccp,
        "PLH": plh
    }
    
    # Ajouter les métriques basées sur la largeur si disponible
    if mode_widths is not None:
        width_norm_errors = [abs(real - hist) / width for (real, hist), width 
                            in zip(mode_pairs, mode_widths)]
        metrics["EAL_width_normalized"] = {
            "values": width_norm_errors,
            "mean": np.mean(width_norm_errors),
            "max": max(width_norm_errors)
        }
    
    return metrics
```

## 6. Seuils recommandés pour les latences de blocs de 2KB

| Métrique | Monitoring | Analyse standard | Analyse détaillée |
|----------|------------|------------------|-------------------|
| EAL (L1/L2) | <10 µs | <5 µs | <2 µs |
| EAL (L3/Mém) | <20 µs | <10 µs | <5 µs |
| EAL (Cache Sys) | <50 µs | <25 µs | <10 µs |
| EAL (Stockage) | <200 µs | <100 µs | <50 µs |
| ERL (tous modes) | <8% | <5% | <2% |
| ENB (tous modes) | <0.8 | <0.5 | <0.3 |
| IPM | >0.85 | >0.9 | >0.95 |
| RCDIM | 0.8-1.2 | 0.9-1.1 | 0.95-1.05 |
| CCP | >0.9 | >0.95 | >0.98 |
| PLH | >0.85 | >0.9 | >0.95 |

## 7. Représentation JSON

```json
{
  "modeLocationMetrics": {
    "basic": {
      "absoluteLocationError": {
        "definition": "Absolute difference between real and histogram mode positions",
        "formula": "|position_mode_real - position_mode_histogram|",
        "unit": "microseconds",
        "thresholds": {
          "excellent": "< 0.1 × mode_width",
          "good": "< 0.25 × mode_width",
          "acceptable": "< 0.5 × mode_width",
          "insufficient": "> 0.5 × mode_width"
        }
      },
      "relativeLocationError": {
        "definition": "Relative difference between real and histogram mode positions",
        "formula": "|position_mode_real - position_mode_histogram| / position_mode_real",
        "unit": "ratio",
        "thresholds": {
          "excellent": "< 0.01",
          "good": "< 0.05",
          "acceptable": "< 0.1",
          "insufficient": "> 0.1"
        }
      }
    },
    "advanced": {
      "multimodalPrecisionIndex": {
        "definition": "Overall precision across all modes",
        "formula": "1 - (Σ|position_mode_i_real - position_mode_i_histogram| / Σ|position_mode_i_real|)",
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
      "hierarchicalLocationPrecision": {
        "definition": "Weighted precision metric giving more importance to low-latency modes",
        "formula": "Σ(wi × (1 - |position_mode_i_real - position_mode_i_histogram| / position_mode_i_real))",
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
```

## 8. Conclusion

Les métriques de précision de localisation des modes fournissent un cadre quantitatif pour évaluer la fidélité avec laquelle un histogramme représente les positions des modes dans une distribution de latence. Pour les distributions de latence de blocs de 2KB, ces métriques sont particulièrement importantes car les positions des modes correspondent directement aux différents niveaux de la hiérarchie de stockage.

Les métriques présentées dans ce document permettent d'évaluer:
- La précision absolue et relative de localisation de chaque mode
- La préservation des distances entre modes
- La fidélité globale de la structure multimodale
- La précision adaptée à l'importance hiérarchique des modes

Ces métriques constituent un outil essentiel pour optimiser les stratégies de binning et garantir que les histogrammes de latence capturent fidèlement les caractéristiques fondamentales des distributions sous-jacentes.
