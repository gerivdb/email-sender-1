# Métriques de dispersion pour les lectures aléatoires de blocs de 2KB

## 1. Vue d'ensemble

Ce document définit les métriques de dispersion (écart-type, variance) pour les latences des lectures aléatoires de blocs de 2 kilooctets (2KB) dans le cache de système de fichiers. Ces métriques quantifient la variabilité et la stabilité des performances, fournissant des informations essentielles sur la prévisibilité du système. Contrairement aux métriques centrales et aux percentiles qui décrivent la tendance centrale et les valeurs extrêmes, les métriques de dispersion caractérisent la distribution dans son ensemble.

## 2. Définition des métriques de dispersion

### 2.1 Définitions mathématiques

| Métrique | Symbole | Formule | Description |
|----------|---------|---------|-------------|
| Variance | σ² | Σ(x - μ)² / n | Moyenne des carrés des écarts à la moyenne |
| Écart-type | σ | √σ² | Racine carrée de la variance |
| Coefficient de variation | CV | σ / μ | Écart-type divisé par la moyenne |
| Étendue | R | max - min | Différence entre la valeur maximale et minimale |
| Écart interquartile | IQR | Q3 - Q1 | Différence entre le 3e et le 1er quartile |
| Écart moyen absolu | MAD | Σ\|x - μ\| / n | Moyenne des écarts absolus à la moyenne |

### 2.2 Interprétation des métriques

| Métrique | Unité | Interprétation |
|----------|-------|----------------|
| Variance | µs² | Mesure la dispersion quadratique, sensible aux valeurs extrêmes |
| Écart-type | µs | Mesure la dispersion dans la même unité que les données originales |
| Coefficient de variation | sans unité | Permet de comparer la variabilité relative indépendamment de l'échelle |
| Étendue | µs | Mesure simple mais très sensible aux valeurs aberrantes |
| Écart interquartile | µs | Mesure robuste de la dispersion, insensible aux valeurs extrêmes |
| Écart moyen absolu | µs | Alternative à l'écart-type, moins sensible aux valeurs extrêmes |

## 3. Plages de valeurs pour les métriques de dispersion

### 3.1 Valeurs globales

| Métrique | Unité | Minimum observé | Maximum observé | Typique (bas) | Typique (moyen) | Typique (haut) |
|----------|-------|-----------------|-----------------|---------------|-----------------|----------------|
| Écart-type (stdDev) | µs | 150 | 800 | 200 | 350 | 500 |
| Variance | µs² | 22500 | 640000 | 40000 | 122500 | 250000 |
| Coefficient de variation | ratio | 0.5 | 2.0 | 0.7 | 1.2 | 1.6 |
| Étendue | µs | 2000 | 8000 | 3000 | 4000 | 6000 |
| Écart interquartile | µs | 100 | 600 | 150 | 250 | 400 |
| Écart moyen absolu | µs | 120 | 650 | 160 | 280 | 400 |

### 3.2 Structure JSON

```json
{
  "dispersion": {
    "stdDev": {
      "unit": "microseconds",
      "value": 350,
      "typicalRanges": {
        "low": 200,
        "medium": 350,
        "high": 500
      }
    },
    "variance": {
      "unit": "microseconds_squared",
      "value": 122500,
      "typicalRanges": {
        "low": 40000,
        "medium": 122500,
        "high": 250000
      }
    },
    "coefficientOfVariation": {
      "unit": "ratio",
      "value": 1.2,
      "typicalRanges": {
        "low": 0.7,
        "medium": 1.2,
        "high": 1.6
      }
    },
    "range": {
      "unit": "microseconds",
      "value": 4000,
      "typicalRanges": {
        "low": 3000,
        "medium": 4000,
        "high": 6000
      }
    },
    "interquartileRange": {
      "unit": "microseconds",
      "value": 250,
      "typicalRanges": {
        "low": 150,
        "medium": 250,
        "high": 400
      }
    },
    "meanAbsoluteDeviation": {
      "unit": "microseconds",
      "value": 280,
      "typicalRanges": {
        "low": 160,
        "medium": 280,
        "high": 400
      }
    }
  }
}
```plaintext
## 4. Ratios et relations entre métriques de dispersion

### 4.1 Ratios typiques

| Ratio | Formule | Valeur typique | Plage normale |
|-------|---------|----------------|---------------|
| stdDev/avg | σ/μ | 1.2 | 0.7 - 1.6 |
| stdDev/median | σ/median | 1.6 | 1.0 - 2.2 |
| variance/avg² | σ²/μ² | 1.4 | 0.5 - 2.5 |
| IQR/stdDev | IQR/σ | 0.7 | 0.5 - 0.9 |
| MAD/stdDev | MAD/σ | 0.8 | 0.7 - 0.9 |
| range/stdDev | R/σ | 11.4 | 8.0 - 15.0 |

### 4.2 Formules d'estimation

Ces formules permettent d'estimer approximativement les métriques de dispersion à partir d'autres métriques connues :

```plaintext
stdDev ≈ avg * 1.2
variance ≈ stdDev²
coefficientOfVariation ≈ stdDev / avg
range ≈ stdDev * 11.4
interquartileRange ≈ stdDev * 0.7
meanAbsoluteDeviation ≈ stdDev * 0.8
```plaintext
### 4.3 Relations avec les percentiles

| Relation | Formule approximative | Valeur typique |
|----------|------------------------|----------------|
| stdDev à partir des percentiles | (p95 - p5) / 3.29 | ≈ 350 µs |
| stdDev à partir de l'IQR | IQR / 1.35 | ≈ 350 µs |
| Estimation de p95 | avg + 1.96 * stdDev | ≈ 1000 µs |
| Estimation de p99 | avg + 2.58 * stdDev | ≈ 2200 µs |

## 5. Facteurs influençant les métriques de dispersion

### 5.1 Facteurs augmentant la dispersion

| Facteur | Impact sur stdDev | Impact sur CV | Mécanisme |
|---------|-------------------|---------------|-----------|
| Contention des ressources | +30-100% | +20-80% | Création de files d'attente et délais variables |
| Fragmentation du stockage | +20-60% | +15-40% | Accès non contigus et temps de recherche variables |
| Charge système variable | +40-120% | +30-100% | Disponibilité fluctuante des ressources système |
| Swapping mémoire | +80-200% | +60-150% | Latences extrêmes lors des accès à la mémoire virtuelle |
| Interférences d'autres processus | +25-70% | +20-50% | Partage des ressources et interruptions |

### 5.2 Facteurs réduisant la dispersion

| Facteur | Impact sur stdDev | Impact sur CV | Mécanisme |
|---------|-------------------|---------------|-----------|
| Cache efficace | -20-50% | -15-40% | Réduction des accès au stockage physique |
| Préchargement intelligent | -15-35% | -10-30% | Anticipation des besoins et réduction des échecs de cache |
| Isolation des ressources | -25-60% | -20-50% | Réduction des interférences externes |
| Défragmentation | -10-30% | -8-25% | Amélioration de la localité des données |
| Priorité d'E/S élevée | -15-40% | -10-35% | Réduction des délais d'attente pour les ressources |

## 6. Métriques de dispersion par environnement spécifique

### 6.1 Systèmes à hautes performances

Environnements optimisés pour les E/S (serveurs dédiés, workstations haut de gamme)

```json
{
  "dispersion": {
    "stdDev": {
      "unit": "microseconds",
      "value": 200
    },
    "variance": {
      "unit": "microseconds_squared",
      "value": 40000
    },
    "coefficientOfVariation": {
      "unit": "ratio",
      "value": 0.9
    }
  }
}
```plaintext
### 6.2 Systèmes standards

Environnements génériques (ordinateurs de bureau, serveurs polyvalents)

```json
{
  "dispersion": {
    "stdDev": {
      "unit": "microseconds",
      "value": 350
    },
    "variance": {
      "unit": "microseconds_squared",
      "value": 122500
    },
    "coefficientOfVariation": {
      "unit": "ratio",
      "value": 1.2
    }
  }
}
```plaintext
### 6.3 Systèmes contraints

Environnements limités en ressources (systèmes embarqués, machines virtuelles partagées)

```json
{
  "dispersion": {
    "stdDev": {
      "unit": "microseconds",
      "value": 500
    },
    "variance": {
      "unit": "microseconds_squared",
      "value": 250000
    },
    "coefficientOfVariation": {
      "unit": "ratio",
      "value": 1.5
    }
  }
}
```plaintext
## 7. Métriques de dispersion par système de fichiers

### 7.1 NTFS (Windows)

```json
{
  "dispersion": {
    "stdDev": {
      "unit": "microseconds",
      "value": 380
    },
    "variance": {
      "unit": "microseconds_squared",
      "value": 144400
    },
    "coefficientOfVariation": {
      "unit": "ratio",
      "value": 1.3
    }
  }
}
```plaintext
### 7.2 ext4 (Linux)

```json
{
  "dispersion": {
    "stdDev": {
      "unit": "microseconds",
      "value": 320
    },
    "variance": {
      "unit": "microseconds_squared",
      "value": 102400
    },
    "coefficientOfVariation": {
      "unit": "ratio",
      "value": 1.1
    }
  }
}
```plaintext
### 7.3 APFS (macOS)

```json
{
  "dispersion": {
    "stdDev": {
      "unit": "microseconds",
      "value": 340
    },
    "variance": {
      "unit": "microseconds_squared",
      "value": 115600
    },
    "coefficientOfVariation": {
      "unit": "ratio",
      "value": 1.2
    }
  }
}
```plaintext
### 7.4 ZFS

```json
{
  "dispersion": {
    "stdDev": {
      "unit": "microseconds",
      "value": 400
    },
    "variance": {
      "unit": "microseconds_squared",
      "value": 160000
    },
    "coefficientOfVariation": {
      "unit": "ratio",
      "value": 1.3
    }
  }
}
```plaintext
## 8. Métriques de dispersion par type de stockage

### 8.1 SSD NVMe

```json
{
  "dispersion": {
    "stdDev": {
      "unit": "microseconds",
      "value": 250
    },
    "variance": {
      "unit": "microseconds_squared",
      "value": 62500
    },
    "coefficientOfVariation": {
      "unit": "ratio",
      "value": 1.1
    }
  }
}
```plaintext
### 8.2 SSD SATA

```json
{
  "dispersion": {
    "stdDev": {
      "unit": "microseconds",
      "value": 320
    },
    "variance": {
      "unit": "microseconds_squared",
      "value": 102400
    },
    "coefficientOfVariation": {
      "unit": "ratio",
      "value": 1.2
    }
  }
}
```plaintext
### 8.3 HDD (7200 RPM)

```json
{
  "dispersion": {
    "stdDev": {
      "unit": "microseconds",
      "value": 700
    },
    "variance": {
      "unit": "microseconds_squared",
      "value": 490000
    },
    "coefficientOfVariation": {
      "unit": "ratio",
      "value": 1.6
    }
  }
}
```plaintext
### 8.4 Stockage réseau (NAS/SAN)

```json
{
  "dispersion": {
    "stdDev": {
      "unit": "microseconds",
      "value": 600
    },
    "variance": {
      "unit": "microseconds_squared",
      "value": 360000
    },
    "coefficientOfVariation": {
      "unit": "ratio",
      "value": 1.5
    }
  }
}
```plaintext
## 9. Évolution des métriques de dispersion dans le temps

### 9.1 Tendances à court terme

Sur une période de minutes à heures, les métriques de dispersion peuvent fluctuer en fonction de :
- La charge système (stdDev: ±30%, CV: ±20%)
- L'état du cache (stdDev: ±25%, CV: ±15%)
- Les processus concurrents (stdDev: ±40%, CV: ±30%)

### 9.2 Tendances à moyen terme

Sur une période de jours à semaines, les métriques de dispersion peuvent évoluer en fonction de :
- La fragmentation progressive (stdDev: +10-30%, CV: +5-20%)
- L'accumulation de métadonnées (stdDev: +5-15%, CV: +3-10%)
- Les mises à jour système (stdDev: ±20%, CV: ±15%)

### 9.3 Tendances à long terme

Sur une période de mois à années, les métriques de dispersion peuvent changer en fonction de :
- La dégradation des performances du stockage (stdDev: +15-40%, CV: +10-30%)
- L'évolution des logiciels système (stdDev: ±25%, CV: ±20%)
- L'accumulation de données et métadonnées (stdDev: +10-30%, CV: +5-25%)

## 10. Métriques de dispersion de référence pour les tests

### 10.1 Métriques de dispersion pour les tests unitaires

```json
{
  "dispersion": {
    "stdDev": {
      "unit": "microseconds",
      "value": 350,
      "tolerance": 70
    },
    "coefficientOfVariation": {
      "unit": "ratio",
      "value": 1.2,
      "tolerance": 0.2
    }
  }
}
```plaintext
### 10.2 Métriques de dispersion pour les tests d'intégration

```json
{
  "dispersion": {
    "stdDev": {
      "unit": "microseconds",
      "value": 380,
      "tolerance": 100
    },
    "coefficientOfVariation": {
      "unit": "ratio",
      "value": 1.3,
      "tolerance": 0.3
    }
  }
}
```plaintext
### 10.3 Métriques de dispersion pour les tests de performance

```json
{
  "dispersion": {
    "stdDev": {
      "unit": "microseconds",
      "value": 350,
      "targets": {
        "good": 250,
        "acceptable": 400,
        "problematic": 550
      }
    },
    "coefficientOfVariation": {
      "unit": "ratio",
      "value": 1.2,
      "targets": {
        "good": 0.9,
        "acceptable": 1.3,
        "problematic": 1.7
      }
    }
  }
}
```plaintext
## 11. Interprétation des métriques de dispersion

### 11.1 Signification opérationnelle

| Métrique | Interprétation opérationnelle |
|----------|-------------------------------|
| Écart-type élevé | Instabilité des performances, expérience utilisateur imprévisible |
| Écart-type faible | Stabilité des performances, expérience utilisateur cohérente |
| CV élevé | Forte variabilité relative, problèmes potentiels de qualité de service |
| CV faible | Faible variabilité relative, bonne prévisibilité des performances |
| Variance élevée | Grande dispersion des valeurs, présence probable de valeurs extrêmes |
| IQR élevé | Large dispersion des valeurs centrales, indépendamment des extrêmes |

### 11.2 Analyse des tendances

| Tendance | Interprétation |
|----------|----------------|
| Augmentation progressive de stdDev | Dégradation de la stabilité du système |
| Augmentation soudaine de stdDev | Problème systémique récent (contention, fragmentation) |
| Augmentation de CV sans changement de moyenne | Détérioration de la prévisibilité sans impact sur la performance moyenne |
| Diminution de stdDev avec moyenne constante | Amélioration de la stabilité du système |
| Augmentation de stdDev avec diminution de moyenne | Amélioration générale mais avec instabilité accrue |

## 12. Métriques de dispersion avancées

### 12.1 Dispersion conditionnelle

```json
{
  "dispersion": {
    "conditional": {
      "byLoadLevel": {
        "low": {
          "stdDev": 200,
          "coefficientOfVariation": 0.9
        },
        "medium": {
          "stdDev": 350,
          "coefficientOfVariation": 1.2
        },
        "high": {
          "stdDev": 550,
          "coefficientOfVariation": 1.7
        }
      },
      "byCacheState": {
        "cold": {
          "stdDev": 500,
          "coefficientOfVariation": 1.5
        },
        "warm": {
          "stdDev": 350,
          "coefficientOfVariation": 1.2
        },
        "hot": {
          "stdDev": 250,
          "coefficientOfVariation": 1.0
        }
      },
      "byTimeOfDay": {
        "businessHours": {
          "stdDev": 400,
          "coefficientOfVariation": 1.3
        },
        "offHours": {
          "stdDev": 280,
          "coefficientOfVariation": 1.1
        }
      }
    }
  }
}
```plaintext
### 12.2 Métriques de stabilité temporelle

```json
{
  "dispersion": {
    "temporalStability": {
      "variationOfVariation": 0.25,
      "stdDevTrend": "+5% per week",
      "dispersionPredictability": 0.75,
      "autocorrelation": {
        "lag1": 0.65,
        "lag10": 0.40,
        "lag100": 0.15
      }
    }
  }
}
```plaintext
## 13. Conclusion

Les métriques de dispersion pour les lectures aléatoires de blocs de 2KB présentent les caractéristiques suivantes :

1. **Variabilité modérée** : Avec un écart-type typique de 200-500 µs et un coefficient de variation de 0.7-1.6, les blocs de 2KB montrent une variabilité modérée, intermédiaire entre les petits blocs (plus variables) et les grands blocs (plus stables).

2. **Sensibilité contextuelle** : Les métriques de dispersion sont fortement influencées par l'environnement matériel, logiciel et la charge du système, avec des variations pouvant atteindre ±50% selon le contexte.

3. **Indicateurs de stabilité** : L'écart-type et le coefficient de variation sont particulièrement utiles pour évaluer la stabilité et la prévisibilité des performances, aspects critiques pour les applications sensibles à la latence.

4. **Équilibre dispersion/performance** : Pour les blocs de 2KB, les métriques de dispersion reflètent un compromis entre la variabilité inhérente aux petits blocs et la stabilité des grands blocs, avec une tendance vers une dispersion modérée.

Ces métriques de dispersion servent de référence pour l'évaluation de la stabilité des performances, la détection d'anomalies et l'optimisation des systèmes utilisant des lectures aléatoires de blocs de 2KB.
