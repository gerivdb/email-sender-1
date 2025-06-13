# Percentiles caractéristiques pour les lectures aléatoires de blocs de 2KB

## 1. Vue d'ensemble

Ce document définit les percentiles caractéristiques (p90, p95, p99) pour les métriques de latence des lectures aléatoires de blocs de 2 kilooctets (2KB) dans le cache de système de fichiers. Ces percentiles sont essentiels pour comprendre la distribution des latences, en particulier pour les valeurs extrêmes qui affectent l'expérience utilisateur et les performances des applications sensibles au temps. Contrairement aux métriques centrales (moyenne, médiane), les percentiles élevés capturent le comportement du système dans les cas les moins favorables.

## 2. Définition des percentiles

| Percentile | Définition |
|------------|------------|
| p90 (90e percentile) | Valeur en dessous de laquelle se trouvent 90% des observations. 10% des lectures sont plus lentes que cette valeur. |
| p95 (95e percentile) | Valeur en dessous de laquelle se trouvent 95% des observations. 5% des lectures sont plus lentes que cette valeur. |
| p99 (99e percentile) | Valeur en dessous de laquelle se trouvent 99% des observations. 1% des lectures sont plus lentes que cette valeur. |
| p99.9 (99.9e percentile) | Valeur en dessous de laquelle se trouvent 99.9% des observations. 0.1% des lectures sont plus lentes que cette valeur. |

## 3. Plages de valeurs pour les percentiles caractéristiques

### 3.1 Valeurs globales

| Percentile | Unité | Minimum observé | Maximum observé | Typique (bas) | Typique (moyen) | Typique (haut) |
|------------|-------|-----------------|-----------------|---------------|-----------------|----------------|
| p90 | µs | 400 | 1200 | 500 | 650 | 900 |
| p95 | µs | 600 | 2000 | 750 | 1000 | 1400 |
| p99 | µs | 1200 | 5000 | 1500 | 2200 | 3000 |
| p99.9 | µs | 2000 | 8000 | 2500 | 3500 | 5000 |

### 3.2 Structure JSON

```json
{
  "percentiles": {
    "unit": "microseconds",
    "p90": 650,
    "p95": 1000,
    "p99": 2200,
    "p99_9": 3500,
    "typicalRanges": {
      "p90": {
        "low": 500,
        "medium": 650,
        "high": 900
      },
      "p95": {
        "low": 750,
        "medium": 1000,
        "high": 1400
      },
      "p99": {
        "low": 1500,
        "medium": 2200,
        "high": 3000
      },
      "p99_9": {
        "low": 2500,
        "medium": 3500,
        "high": 5000
      }
    }
  }
}
```plaintext
## 4. Ratios entre percentiles et métriques centrales

### 4.1 Ratios typiques

| Ratio | Formule | Valeur typique | Plage normale |
|-------|---------|----------------|---------------|
| p90/median | p90/median | 3.0 | 2.5 - 3.5 |
| p95/median | p95/median | 4.5 | 3.5 - 5.5 |
| p99/median | p99/median | 10.0 | 8.0 - 12.0 |
| p99.9/median | p99.9/median | 16.0 | 12.0 - 20.0 |
| p95/p90 | p95/p90 | 1.5 | 1.4 - 1.7 |
| p99/p95 | p99/p95 | 2.2 | 2.0 - 2.5 |
| p99.9/p99 | p99.9/p99 | 1.6 | 1.4 - 1.8 |

### 4.2 Formules d'estimation

Ces formules permettent d'estimer approximativement les percentiles à partir des valeurs connues :

```plaintext
p90 ≈ median * 3.0
p95 ≈ p90 * 1.5
p99 ≈ p95 * 2.2
p99.9 ≈ p99 * 1.6
```plaintext
## 5. Facteurs influençant les percentiles

### 5.1 Facteurs à fort impact sur les percentiles élevés

| Facteur | Impact | Effet sur les percentiles |
|---------|--------|---------------------------|
| Contention des ressources | Critique | Augmentation disproportionnée des p95-p99.9 |
| Garbage collection | Majeur | Pics périodiques affectant principalement p99-p99.9 |
| Swapping mémoire | Sévère | Augmentation drastique de tous les percentiles |
| Interruptions système | Significatif | Affecte principalement p99-p99.9 |
| Fragmentation du stockage | Progressif | Augmentation graduelle de tous les percentiles |

### 5.2 Sensibilité relative des percentiles

| Percentile | Sensibilité aux anomalies | Stabilité | Utilité principale |
|------------|---------------------------|-----------|-------------------|
| p90 | Modérée | Élevée | Détection des problèmes courants |
| p95 | Élevée | Moyenne | Équilibre entre stabilité et sensibilité |
| p99 | Très élevée | Faible | Détection des problèmes rares mais significatifs |
| p99.9 | Extrême | Très faible | Détection des problèmes critiques rares |

## 6. Percentiles par environnement spécifique

### 6.1 Systèmes à hautes performances

Environnements optimisés pour les E/S (serveurs dédiés, workstations haut de gamme)

```json
{
  "percentiles": {
    "unit": "microseconds",
    "p90": 500,
    "p95": 750,
    "p99": 1500,
    "p99_9": 2500
  }
}
```plaintext
### 6.2 Systèmes standards

Environnements génériques (ordinateurs de bureau, serveurs polyvalents)

```json
{
  "percentiles": {
    "unit": "microseconds",
    "p90": 650,
    "p95": 1000,
    "p99": 2200,
    "p99_9": 3500
  }
}
```plaintext
### 6.3 Systèmes contraints

Environnements limités en ressources (systèmes embarqués, machines virtuelles partagées)

```json
{
  "percentiles": {
    "unit": "microseconds",
    "p90": 900,
    "p95": 1400,
    "p99": 3000,
    "p99_9": 5000
  }
}
```plaintext
## 7. Percentiles par système de fichiers

### 7.1 NTFS (Windows)

```json
{
  "percentiles": {
    "unit": "microseconds",
    "p90": 700,
    "p95": 1100,
    "p99": 2400,
    "p99_9": 3800
  }
}
```plaintext
### 7.2 ext4 (Linux)

```json
{
  "percentiles": {
    "unit": "microseconds",
    "p90": 600,
    "p95": 950,
    "p99": 2000,
    "p99_9": 3200
  }
}
```plaintext
### 7.3 APFS (macOS)

```json
{
  "percentiles": {
    "unit": "microseconds",
    "p90": 650,
    "p95": 1000,
    "p99": 2200,
    "p99_9": 3500
  }
}
```plaintext
### 7.4 ZFS

```json
{
  "percentiles": {
    "unit": "microseconds",
    "p90": 750,
    "p95": 1200,
    "p99": 2600,
    "p99_9": 4000
  }
}
```plaintext
## 8. Percentiles par type de stockage

### 8.1 SSD NVMe

```json
{
  "percentiles": {
    "unit": "microseconds",
    "p90": 500,
    "p95": 800,
    "p99": 1600,
    "p99_9": 2800
  }
}
```plaintext
### 8.2 SSD SATA

```json
{
  "percentiles": {
    "unit": "microseconds",
    "p90": 600,
    "p95": 950,
    "p99": 2000,
    "p99_9": 3200
  }
}
```plaintext
### 8.3 HDD (7200 RPM)

```json
{
  "percentiles": {
    "unit": "microseconds",
    "p90": 1200,
    "p95": 2000,
    "p99": 4500,
    "p99_9": 7000
  }
}
```plaintext
### 8.4 Stockage réseau (NAS/SAN)

```json
{
  "percentiles": {
    "unit": "microseconds",
    "p90": 1000,
    "p95": 1800,
    "p99": 4000,
    "p99_9": 6500
  }
}
```plaintext
## 9. Évolution des percentiles dans le temps

### 9.1 Tendances à court terme

Sur une période de minutes à heures, les percentiles peuvent fluctuer en fonction de :
- La charge système (p99/p99.9: ±40%, p90/p95: ±25%)
- L'état du cache (p99/p99.9: ±35%, p90/p95: ±20%)
- Les processus concurrents (p99/p99.9: ±50%, p90/p95: ±30%)

### 9.2 Tendances à moyen terme

Sur une période de jours à semaines, les percentiles peuvent évoluer en fonction de :
- La fragmentation progressive (p99/p99.9: +10-25%, p90/p95: +5-15%)
- L'accumulation de métadonnées (p99/p99.9: +8-20%, p90/p95: +5-12%)
- Les mises à jour système (p99/p99.9: ±30%, p90/p95: ±20%)

### 9.3 Tendances à long terme

Sur une période de mois à années, les percentiles peuvent changer en fonction de :
- La dégradation des performances du stockage (p99/p99.9: +20-50%, p90/p95: +15-30%)
- L'évolution des logiciels système (p99/p99.9: ±35%, p90/p95: ±25%)
- L'accumulation de données et métadonnées (p99/p99.9: +15-40%, p90/p95: +10-25%)

## 10. Percentiles de référence pour les tests

### 10.1 Percentiles de référence pour les tests unitaires

```json
{
  "percentiles": {
    "unit": "microseconds",
    "p90": 650,
    "p95": 1000,
    "p99": 2200,
    "tolerance": {
      "p90": 100,
      "p95": 200,
      "p99": 500
    }
  }
}
```plaintext
### 10.2 Percentiles de référence pour les tests d'intégration

```json
{
  "percentiles": {
    "unit": "microseconds",
    "p90": 700,
    "p95": 1100,
    "p99": 2400,
    "tolerance": {
      "p90": 150,
      "p95": 300,
      "p99": 700
    }
  }
}
```plaintext
### 10.3 Percentiles de référence pour les tests de performance

```json
{
  "percentiles": {
    "unit": "microseconds",
    "p90": 650,
    "p95": 1000,
    "p99": 2200,
    "targets": {
      "p90": {
        "good": 550,
        "acceptable": 750,
        "problematic": 950
      },
      "p95": {
        "good": 850,
        "acceptable": 1200,
        "problematic": 1600
      },
      "p99": {
        "good": 1800,
        "acceptable": 2500,
        "problematic": 3500
      }
    }
  }
}
```plaintext
## 11. Interprétation des percentiles

### 11.1 Signification opérationnelle

| Percentile | Interprétation opérationnelle |
|------------|-------------------------------|
| p90 | Représente l'expérience de la majorité des utilisateurs dans des conditions normales |
| p95 | Seuil critique pour les applications interactives et les services en temps réel |
| p99 | Indicateur des problèmes systémiques affectant une minorité significative d'opérations |
| p99.9 | Révélateur des problèmes graves mais rares, critiques pour les systèmes à haute disponibilité |

### 11.2 Analyse des écarts entre percentiles

| Écart | Interprétation |
|-------|----------------|
| p95-p90 faible | Distribution homogène, comportement prévisible |
| p95-p90 élevé | Queue de distribution épaisse, variabilité significative |
| p99-p95 faible | Peu d'anomalies extrêmes |
| p99-p95 élevé | Présence d'anomalies significatives |
| p99.9-p99 très élevé | Problèmes graves mais très rares (interruptions système, swapping, etc.) |

## 12. Conclusion

Les percentiles caractéristiques pour les lectures aléatoires de blocs de 2KB présentent les particularités suivantes :

1. **Distribution à queue épaisse** : Les percentiles élevés (p99, p99.9) sont significativement plus grands que les métriques centrales, indiquant une distribution asymétrique avec une queue épaisse.

2. **Sensibilité contextuelle** : Les percentiles varient considérablement selon l'environnement matériel, logiciel et la charge du système, avec une sensibilité croissante à mesure que le percentile augmente.

3. **Indicateurs de qualité de service** : Les percentiles p95 et p99 sont particulièrement utiles pour évaluer la qualité de service et détecter les problèmes systémiques.

4. **Équilibre performance/fiabilité** : Pour les blocs de 2KB, les percentiles reflètent un équilibre entre les performances brutes et la fiabilité, avec des valeurs intermédiaires entre les petits blocs (plus variables) et les grands blocs (plus stables mais plus lents).

Ces percentiles caractéristiques servent de référence pour l'établissement de SLA (Service Level Agreements), la détection d'anomalies et l'optimisation des systèmes utilisant des lectures aléatoires de blocs de 2KB.
