# Intervalles de confiance statistique pour les lectures aléatoires de blocs de 2KB

## 1. Vue d'ensemble

Ce document définit les intervalles de confiance statistique pour les métriques de latence des lectures aléatoires de blocs de 2 kilooctets (2KB) dans le cache de système de fichiers. Les intervalles de confiance quantifient l'incertitude associée aux estimations statistiques et permettent d'évaluer la fiabilité des mesures de performance. Ils sont particulièrement importants pour les tests de régression, les comparaisons de performance et l'établissement de seuils d'alerte fiables.

## 2. Définition des intervalles de confiance

### 2.1 Concepts fondamentaux

| Concept | Définition |
|---------|------------|
| Intervalle de confiance | Plage de valeurs qui contient la vraie valeur du paramètre avec une probabilité spécifiée |
| Niveau de confiance | Probabilité que l'intervalle contienne la vraie valeur (généralement 90%, 95% ou 99%) |
| Marge d'erreur | Demi-largeur de l'intervalle de confiance |
| Erreur standard | Estimation de l'écart-type de la distribution d'échantillonnage d'une statistique |
| Taille d'échantillon | Nombre d'observations utilisées pour calculer l'intervalle |

### 2.2 Formules de calcul

| Type d'intervalle | Formule | Application |
|-------------------|---------|-------------|
| IC pour la moyenne | μ ± t(α/2, n-1) × (σ/√n) | Estimation de la vraie latence moyenne |
| IC pour l'écart-type | [√((n-1)s²/χ²(α/2, n-1)), √((n-1)s²/χ²(1-α/2, n-1))] | Estimation de la vraie variabilité |
| IC pour les percentiles | Basé sur la distribution binomiale ou l'approximation normale | Estimation des vraies valeurs de percentiles |
| IC pour le taux de succès | p ± z(α/2) × √(p(1-p)/n) | Estimation du vrai taux de succès du cache |

### 2.3 Interprétation des intervalles de confiance

| Niveau de confiance | Interprétation |
|---------------------|----------------|
| 90% | L'intervalle contient la vraie valeur dans 90% des cas (équilibre entre précision et largeur) |
| 95% | L'intervalle contient la vraie valeur dans 95% des cas (standard courant) |
| 99% | L'intervalle contient la vraie valeur dans 99% des cas (haute fiabilité, intervalle plus large) |

## 3. Intervalles de confiance pour les métriques clés

### 3.1 Intervalles de confiance pour la latence moyenne

| Métrique | Valeur estimée | Niveau de confiance | Borne inférieure | Borne supérieure | Marge d'erreur | Taille d'échantillon |
|----------|----------------|---------------------|------------------|------------------|----------------|----------------------|
| Latence moyenne | 300 µs | 95% | 290 µs | 310 µs | ±10 µs | 1000 |
| Latence moyenne | 300 µs | 99% | 285 µs | 315 µs | ±15 µs | 1000 |
| Latence moyenne | 300 µs | 95% | 285 µs | 315 µs | ±15 µs | 500 |
| Latence moyenne | 300 µs | 95% | 295 µs | 305 µs | ±5 µs | 4000 |

### 3.2 Structure JSON pour les intervalles de confiance

```json
{
  "confidenceIntervals": {
    "mean": {
      "value": 300,
      "unit": "microseconds",
      "confidenceLevel": 0.95,
      "lowerBound": 290,
      "upperBound": 310,
      "marginOfError": 10,
      "sampleSize": 1000
    },
    "stdDev": {
      "value": 350,
      "unit": "microseconds",
      "confidenceLevel": 0.95,
      "lowerBound": 330,
      "upperBound": 372,
      "marginOfError": 21,
      "sampleSize": 1000
    },
    "p95": {
      "value": 1000,
      "unit": "microseconds",
      "confidenceLevel": 0.95,
      "lowerBound": 950,
      "upperBound": 1060,
      "marginOfError": 55,
      "sampleSize": 1000
    },
    "p99": {
      "value": 2200,
      "unit": "microseconds",
      "confidenceLevel": 0.95,
      "lowerBound": 2050,
      "upperBound": 2380,
      "marginOfError": 165,
      "sampleSize": 1000
    },
    "hitRate": {
      "value": 0.80,
      "unit": "ratio",
      "confidenceLevel": 0.95,
      "lowerBound": 0.775,
      "upperBound": 0.825,
      "marginOfError": 0.025,
      "sampleSize": 1000
    }
  }
}
```

## 4. Facteurs influençant la largeur des intervalles de confiance

### 4.1 Taille d'échantillon

| Taille d'échantillon | Marge d'erreur typique (95% IC) | Réduction relative |
|----------------------|----------------------------------|-------------------|
| 100 | ±35 µs | Référence |
| 400 | ±17.5 µs | 50% |
| 1000 | ±11 µs | 69% |
| 4000 | ±5.5 µs | 84% |
| 10000 | ±3.5 µs | 90% |

### 4.2 Variabilité des données

| Écart-type | Marge d'erreur typique (95% IC, n=1000) | Augmentation relative |
|------------|------------------------------------------|----------------------|
| 200 µs | ±6 µs | Référence |
| 350 µs | ±11 µs | 83% |
| 500 µs | ±16 µs | 167% |
| 700 µs | ±22 µs | 267% |

### 4.3 Niveau de confiance

| Niveau de confiance | Marge d'erreur typique (n=1000, stdDev=350) | Augmentation relative |
|---------------------|---------------------------------------------|----------------------|
| 90% | ±9 µs | Référence |
| 95% | ±11 µs | 22% |
| 99% | ±14 µs | 56% |
| 99.9% | ±18 µs | 100% |

### 4.4 Distribution des données

| Type de distribution | Impact sur la largeur de l'IC | Ajustement recommandé |
|----------------------|-------------------------------|------------------------|
| Normale | Référence | Aucun |
| Asymétrique positive | Élargissement de 10-30% | Transformation logarithmique ou bootstrap |
| Bimodale | Élargissement de 20-50% | Analyse par composantes ou bootstrap |
| Avec valeurs aberrantes | Élargissement de 30-100% | Méthodes robustes ou bootstrap |

## 5. Intervalles de confiance par environnement spécifique

### 5.1 Systèmes à hautes performances

Environnements optimisés pour les E/S (serveurs dédiés, workstations haut de gamme)

```json
{
  "confidenceIntervals": {
    "mean": {
      "value": 220,
      "confidenceLevel": 0.95,
      "lowerBound": 214,
      "upperBound": 226,
      "marginOfError": 6,
      "sampleSize": 1000
    },
    "p95": {
      "value": 750,
      "confidenceLevel": 0.95,
      "lowerBound": 720,
      "upperBound": 785,
      "marginOfError": 32.5,
      "sampleSize": 1000
    }
  }
}
```

### 5.2 Systèmes standards

Environnements génériques (ordinateurs de bureau, serveurs polyvalents)

```json
{
  "confidenceIntervals": {
    "mean": {
      "value": 300,
      "confidenceLevel": 0.95,
      "lowerBound": 290,
      "upperBound": 310,
      "marginOfError": 10,
      "sampleSize": 1000
    },
    "p95": {
      "value": 1000,
      "confidenceLevel": 0.95,
      "lowerBound": 950,
      "upperBound": 1060,
      "marginOfError": 55,
      "sampleSize": 1000
    }
  }
}
```

### 5.3 Systèmes contraints

Environnements limités en ressources (systèmes embarqués, machines virtuelles partagées)

```json
{
  "confidenceIntervals": {
    "mean": {
      "value": 400,
      "confidenceLevel": 0.95,
      "lowerBound": 385,
      "upperBound": 415,
      "marginOfError": 15,
      "sampleSize": 1000
    },
    "p95": {
      "value": 1400,
      "confidenceLevel": 0.95,
      "lowerBound": 1320,
      "upperBound": 1490,
      "marginOfError": 85,
      "sampleSize": 1000
    }
  }
}
```

## 6. Intervalles de confiance par système de fichiers

### 6.1 NTFS (Windows)

```json
{
  "confidenceIntervals": {
    "mean": {
      "value": 320,
      "confidenceLevel": 0.95,
      "lowerBound": 308,
      "upperBound": 332,
      "marginOfError": 12,
      "sampleSize": 1000
    }
  }
}
```

### 6.2 ext4 (Linux)

```json
{
  "confidenceIntervals": {
    "mean": {
      "value": 280,
      "confidenceLevel": 0.95,
      "lowerBound": 270,
      "upperBound": 290,
      "marginOfError": 10,
      "sampleSize": 1000
    }
  }
}
```

### 6.3 APFS (macOS)

```json
{
  "confidenceIntervals": {
    "mean": {
      "value": 290,
      "confidenceLevel": 0.95,
      "lowerBound": 280,
      "upperBound": 300,
      "marginOfError": 10,
      "sampleSize": 1000
    }
  }
}
```

### 6.4 ZFS

```json
{
  "confidenceIntervals": {
    "mean": {
      "value": 350,
      "confidenceLevel": 0.95,
      "lowerBound": 337,
      "upperBound": 363,
      "marginOfError": 13,
      "sampleSize": 1000
    }
  }
}
```

## 7. Intervalles de confiance par type de stockage

### 7.1 SSD NVMe

```json
{
  "confidenceIntervals": {
    "mean": {
      "value": 220,
      "confidenceLevel": 0.95,
      "lowerBound": 213,
      "upperBound": 227,
      "marginOfError": 7,
      "sampleSize": 1000
    }
  }
}
```

### 7.2 SSD SATA

```json
{
  "confidenceIntervals": {
    "mean": {
      "value": 280,
      "confidenceLevel": 0.95,
      "lowerBound": 270,
      "upperBound": 290,
      "marginOfError": 10,
      "sampleSize": 1000
    }
  }
}
```

### 7.3 HDD (7200 RPM)

```json
{
  "confidenceIntervals": {
    "mean": {
      "value": 600,
      "confidenceLevel": 0.95,
      "lowerBound": 575,
      "upperBound": 625,
      "marginOfError": 25,
      "sampleSize": 1000
    }
  }
}
```

### 7.4 Stockage réseau (NAS/SAN)

```json
{
  "confidenceIntervals": {
    "mean": {
      "value": 500,
      "confidenceLevel": 0.95,
      "lowerBound": 480,
      "upperBound": 520,
      "marginOfError": 20,
      "sampleSize": 1000
    }
  }
}
```

## 8. Utilisation des intervalles de confiance

### 8.1 Tests de régression

| Utilisation | Méthodologie | Seuil typique |
|-------------|--------------|---------------|
| Détection de régression | Comparer si la nouvelle moyenne est en dehors de l'IC de l'ancienne | 95% IC |
| Confirmation d'amélioration | Vérifier si les IC de l'ancienne et de la nouvelle moyenne ne se chevauchent pas | 95% IC |
| Test de non-infériorité | Vérifier si la borne supérieure de l'IC de la différence est inférieure au seuil | 90% IC |
| Test d'équivalence | Vérifier si l'IC de la différence est entièrement contenu dans les limites d'équivalence | 90% IC |

### 8.2 Établissement de seuils d'alerte

| Type de seuil | Méthodologie | Niveau de confiance recommandé |
|---------------|--------------|--------------------------------|
| Seuil d'avertissement | Borne supérieure de l'IC + 1 écart-type | 95% |
| Seuil critique | Borne supérieure de l'IC + 2 écarts-types | 99% |
| Seuil de capacité | Borne supérieure de l'IC + 3 écarts-types | 99.9% |

### 8.3 Dimensionnement des tests

| Objectif | Formule de taille d'échantillon | Exemple pour détecter 5% de différence |
|----------|----------------------------------|---------------------------------------|
| Détecter une différence de d% | n = 16 × (σ/d)² | n = 16 × (350/15)² = 8711 |
| Obtenir une marge d'erreur de e | n = (1.96 × σ/e)² | n = (1.96 × 350/10)² = 4706 |
| Comparer deux moyennes | n = 2 × (1.96 × σ/d)² | n = 2 × (1.96 × 350/15)² = 10824 par groupe |

## 9. Méthodes avancées pour les intervalles de confiance

### 9.1 Bootstrap

```json
{
  "confidenceIntervals": {
    "bootstrap": {
      "mean": {
        "value": 300,
        "confidenceLevel": 0.95,
        "lowerBound": 288,
        "upperBound": 312,
        "marginOfError": 12,
        "resamples": 10000,
        "method": "percentile"
      },
      "p95": {
        "value": 1000,
        "confidenceLevel": 0.95,
        "lowerBound": 940,
        "upperBound": 1070,
        "marginOfError": 65,
        "resamples": 10000,
        "method": "percentile"
      }
    }
  }
}
```

### 9.2 Intervalles de confiance bayésiens

```json
{
  "confidenceIntervals": {
    "bayesian": {
      "mean": {
        "value": 300,
        "credibleLevel": 0.95,
        "lowerBound": 292,
        "upperBound": 308,
        "marginOfError": 8,
        "prior": "informative",
        "posteriorSamples": 10000
      },
      "stdDev": {
        "value": 350,
        "credibleLevel": 0.95,
        "lowerBound": 335,
        "upperBound": 368,
        "marginOfError": 16.5,
        "prior": "informative",
        "posteriorSamples": 10000
      }
    }
  }
}
```

### 9.3 Intervalles de prédiction

```json
{
  "confidenceIntervals": {
    "prediction": {
      "individualLatency": {
        "confidenceLevel": 0.95,
        "lowerBound": 0,
        "upperBound": 1000,
        "coverage": 0.95
      },
      "meanOfNextNSamples": {
        "n": 100,
        "confidenceLevel": 0.95,
        "lowerBound": 280,
        "upperBound": 320,
        "marginOfError": 20
      }
    }
  }
}
```

## 10. Intervalles de confiance de référence pour les tests

### 10.1 Intervalles de confiance pour les tests unitaires

```json
{
  "confidenceIntervals": {
    "unitTests": {
      "mean": {
        "value": 300,
        "confidenceLevel": 0.95,
        "lowerBound": 290,
        "upperBound": 310,
        "marginOfError": 10,
        "sampleSize": 1000,
        "maxAllowedWidth": 30
      },
      "p95": {
        "value": 1000,
        "confidenceLevel": 0.95,
        "lowerBound": 950,
        "upperBound": 1060,
        "marginOfError": 55,
        "sampleSize": 1000,
        "maxAllowedWidth": 150
      }
    }
  }
}
```

### 10.2 Intervalles de confiance pour les tests d'intégration

```json
{
  "confidenceIntervals": {
    "integrationTests": {
      "mean": {
        "value": 320,
        "confidenceLevel": 0.95,
        "lowerBound": 305,
        "upperBound": 335,
        "marginOfError": 15,
        "sampleSize": 500,
        "maxAllowedWidth": 40
      },
      "p95": {
        "value": 1100,
        "confidenceLevel": 0.95,
        "lowerBound": 1030,
        "upperBound": 1180,
        "marginOfError": 75,
        "sampleSize": 500,
        "maxAllowedWidth": 200
      }
    }
  }
}
```

### 10.3 Intervalles de confiance pour les tests de performance

```json
{
  "confidenceIntervals": {
    "performanceTests": {
      "mean": {
        "value": 300,
        "confidenceLevel": 0.99,
        "lowerBound": 285,
        "upperBound": 315,
        "marginOfError": 15,
        "sampleSize": 5000,
        "maxAllowedWidth": 35,
        "requiredPower": 0.9
      },
      "p95": {
        "value": 1000,
        "confidenceLevel": 0.99,
        "lowerBound": 940,
        "upperBound": 1065,
        "marginOfError": 62.5,
        "sampleSize": 5000,
        "maxAllowedWidth": 150,
        "requiredPower": 0.9
      }
    }
  }
}
```

## 11. Interprétation et bonnes pratiques

### 11.1 Interprétation correcte des intervalles de confiance

| Interprétation correcte | Interprétation incorrecte |
|-------------------------|---------------------------|
| "Il y a 95% de chances que cet intervalle contienne la vraie moyenne de latence" | "Il y a 95% de chances que la vraie moyenne soit dans cet intervalle" |
| "Si nous répétions l'échantillonnage de nombreuses fois, 95% des intervalles calculés contiendraient la vraie moyenne" | "La probabilité que la vraie moyenne soit dans cet intervalle est de 95%" |
| "Nous sommes confiants à 95% que la vraie moyenne est entre 290 et 310 µs" | "95% des latences sont entre 290 et 310 µs" |

### 11.2 Bonnes pratiques pour l'utilisation des intervalles de confiance

1. **Taille d'échantillon adéquate** : Utiliser au moins 30 échantillons, idéalement 100+ pour les distributions normales et 1000+ pour les distributions asymétriques

2. **Vérification des hypothèses** : Vérifier la normalité pour les petits échantillons ou utiliser des méthodes non paramétriques/bootstrap

3. **Niveau de confiance approprié** : Utiliser 95% pour les cas généraux, 99% pour les décisions critiques

4. **Interprétation contextuelle** : Considérer la signification pratique, pas seulement la signification statistique

5. **Correction pour tests multiples** : Ajuster le niveau de confiance lors de la réalisation de multiples comparaisons

6. **Rapporter la taille d'échantillon** : Toujours inclure n avec les intervalles de confiance

7. **Visualisation** : Représenter graphiquement les intervalles de confiance pour faciliter l'interprétation

## 12. Conclusion

Les intervalles de confiance statistique pour les lectures aléatoires de blocs de 2KB présentent les caractéristiques suivantes :

1. **Précision modérée** : Avec une marge d'erreur typique de ±10 µs (95% IC) pour la moyenne avec 1000 échantillons, les blocs de 2KB permettent une estimation relativement précise des performances.

2. **Sensibilité à la taille d'échantillon** : La précision des estimations s'améliore significativement avec l'augmentation de la taille d'échantillon, suivant une relation en √n.

3. **Variabilité des percentiles élevés** : Les intervalles de confiance pour les percentiles élevés (p95, p99) sont considérablement plus larges que pour la moyenne, reflétant leur plus grande variabilité d'échantillonnage.

4. **Dépendance contextuelle** : La largeur des intervalles varie selon l'environnement matériel, logiciel et la charge du système, nécessitant des ajustements spécifiques au contexte.

Ces intervalles de confiance servent de référence pour l'évaluation de la fiabilité des mesures de performance, la détection de régressions et l'établissement de seuils d'alerte pour les systèmes utilisant des lectures aléatoires de blocs de 2KB.
