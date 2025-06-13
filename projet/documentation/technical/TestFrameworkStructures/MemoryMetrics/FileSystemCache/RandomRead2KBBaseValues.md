# Plages de valeurs typiques pour les lectures aléatoires de blocs de 2KB

## 1. Vue d'ensemble

Ce document définit les plages de valeurs typiques (minimum, maximum, moyenne, médiane) pour les métriques de latence des lectures aléatoires de blocs de 2 kilooctets (2KB) dans le cache de système de fichiers. Ces valeurs de référence sont essentielles pour établir des bases de comparaison, identifier les anomalies de performance et calibrer les systèmes de surveillance. Les blocs de 2KB représentent une taille intermédiaire entre les petits blocs (512B, 1KB) et la taille de page standard (4KB), ce qui leur confère un profil de performance particulier.

## 2. Méthodologie d'établissement des plages

Les plages de valeurs présentées dans ce document ont été établies selon la méthodologie suivante :

1. **Collecte de données empiriques** : Mesures effectuées sur différentes configurations matérielles et logicielles
2. **Analyse statistique** : Traitement des données pour identifier les tendances centrales et la dispersion
3. **Segmentation par environnement** : Classification des valeurs selon le type de matériel et de système de fichiers
4. **Validation croisée** : Comparaison avec les données publiées dans la littérature scientifique et technique
5. **Ajustement contextuel** : Adaptation des plages en fonction des spécificités des blocs de 2KB

## 3. Plages de valeurs statistiques de base

### 3.1 Valeurs globales

| Métrique | Unité | Minimum | Maximum | Typique (bas) | Typique (moyen) | Typique (haut) |
|----------|-------|---------|---------|---------------|-----------------|----------------|
| Minimum (min) | µs | 45 | 80 | 50 | 60 | 70 |
| Maximum (max) | µs | 2000 | 8000 | 3000 | 4000 | 6000 |
| Moyenne (avg) | µs | 200 | 600 | 250 | 300 | 400 |
| Médiane (median) | µs | 150 | 450 | 180 | 220 | 300 |

### 3.2 Structure JSON

```json
{
  "basic": {
    "unit": "microseconds",
    "min": 60,
    "max": 4000,
    "avg": 300,
    "median": 220,
    "typicalRanges": {
      "min": {
        "low": 50,
        "medium": 60,
        "high": 70
      },
      "max": {
        "low": 3000,
        "medium": 4000,
        "high": 6000
      },
      "avg": {
        "low": 250,
        "medium": 300,
        "high": 400
      },
      "median": {
        "low": 180,
        "medium": 220,
        "high": 300
      }
    }
  }
}
```plaintext
## 4. Facteurs influençant les valeurs

### 4.1 Facteurs matériels

| Facteur | Impact sur les valeurs | Variation typique |
|---------|------------------------|-------------------|
| Vitesse du processeur | Affecte principalement l'overhead | ±15% sur avg/median |
| Architecture du cache | Influence critique sur min/median | ±25% sur min/median |
| Type de stockage | Impact majeur sur max/avg | ±40% sur max, ±20% sur avg |
| Mémoire RAM | Influence modérée sur toutes les métriques | ±10% sur toutes les métriques |
| Bus système | Impact sur les transferts de données | ±15% sur avg/median |

### 4.2 Facteurs logiciels

| Facteur | Impact sur les valeurs | Variation typique |
|---------|------------------------|-------------------|
| Système d'exploitation | Influence sur l'overhead système | ±20% sur avg/median |
| Système de fichiers | Impact critique sur toutes les métriques | ±30% sur toutes les métriques |
| Stratégie de cache | Influence majeure sur min/avg/median | ±25% sur min/avg/median |
| Charge système | Impact variable selon le niveau de contention | ±35% sur avg/max |
| Fragmentation | Influence croissante avec l'âge du système | +5-50% sur avg/max |

## 5. Plages par environnement spécifique

### 5.1 Systèmes à hautes performances

Environnements optimisés pour les E/S (serveurs dédiés, workstations haut de gamme)

```json
{
  "basic": {
    "unit": "microseconds",
    "min": 45,
    "max": 2500,
    "avg": 220,
    "median": 170
  }
}
```plaintext
### 5.2 Systèmes standards

Environnements génériques (ordinateurs de bureau, serveurs polyvalents)

```json
{
  "basic": {
    "unit": "microseconds",
    "min": 60,
    "max": 4000,
    "avg": 300,
    "median": 220
  }
}
```plaintext
### 5.3 Systèmes contraints

Environnements limités en ressources (systèmes embarqués, machines virtuelles partagées)

```json
{
  "basic": {
    "unit": "microseconds",
    "min": 75,
    "max": 6000,
    "avg": 400,
    "median": 300
  }
}
```plaintext
## 6. Plages par système de fichiers

### 6.1 NTFS (Windows)

```json
{
  "basic": {
    "unit": "microseconds",
    "min": 65,
    "max": 4500,
    "avg": 320,
    "median": 240,
    "byClusterSize": {
      "4KB": {
        "avg": 310,
        "median": 230
      },
      "8KB": {
        "avg": 330,
        "median": 250
      }
    }
  }
}
```plaintext
### 6.2 ext4 (Linux)

```json
{
  "basic": {
    "unit": "microseconds",
    "min": 55,
    "max": 3800,
    "avg": 280,
    "median": 210,
    "byBlockSize": {
      "4KB": {
        "avg": 270,
        "median": 200
      },
      "8KB": {
        "avg": 290,
        "median": 220
      }
    }
  }
}
```plaintext
### 6.3 APFS (macOS)

```json
{
  "basic": {
    "unit": "microseconds",
    "min": 60,
    "max": 4200,
    "avg": 290,
    "median": 220
  }
}
```plaintext
### 6.4 ZFS

```json
{
  "basic": {
    "unit": "microseconds",
    "min": 70,
    "max": 4800,
    "avg": 350,
    "median": 260,
    "byRecordSize": {
      "4KB": {
        "avg": 340,
        "median": 250
      },
      "8KB": {
        "avg": 360,
        "median": 270
      }
    }
  }
}
```plaintext
## 7. Plages par type de stockage

### 7.1 SSD NVMe

```json
{
  "basic": {
    "unit": "microseconds",
    "min": 50,
    "max": 2000,
    "avg": 220,
    "median": 180
  }
}
```plaintext
### 7.2 SSD SATA

```json
{
  "basic": {
    "unit": "microseconds",
    "min": 60,
    "max": 3000,
    "avg": 280,
    "median": 220
  }
}
```plaintext
### 7.3 HDD (7200 RPM)

```json
{
  "basic": {
    "unit": "microseconds",
    "min": 70,
    "max": 8000,
    "avg": 600,
    "median": 450
  }
}
```plaintext
### 7.4 Stockage réseau (NAS/SAN)

```json
{
  "basic": {
    "unit": "microseconds",
    "min": 80,
    "max": 7000,
    "avg": 500,
    "median": 380
  }
}
```plaintext
## 8. Relation entre les métriques de base

### 8.1 Ratios typiques

| Ratio | Formule | Valeur typique | Plage normale |
|-------|---------|----------------|---------------|
| Moyenne/Médiane | avg/median | 1.35 | 1.2 - 1.5 |
| Maximum/Moyenne | max/avg | 13.3 | 10 - 20 |
| Médiane/Minimum | median/min | 3.7 | 3 - 5 |
| Maximum/Minimum | max/min | 66.7 | 50 - 100 |

### 8.2 Formules d'estimation

Ces formules permettent d'estimer approximativement les valeurs manquantes à partir des valeurs connues :

```plaintext
median ≈ avg / 1.35
min ≈ median / 3.7
max ≈ avg * 13.3
avg ≈ median * 1.35
```plaintext
## 9. Évolution des valeurs dans le temps

### 9.1 Tendances à court terme

Sur une période de minutes à heures, les valeurs peuvent fluctuer en fonction de :
- La charge système (±20%)
- L'état du cache (±30%)
- Les processus concurrents (±25%)

### 9.2 Tendances à moyen terme

Sur une période de jours à semaines, les valeurs peuvent évoluer en fonction de :
- La fragmentation progressive (+5-15%)
- L'accumulation de métadonnées (+3-10%)
- Les mises à jour système (±15%)

### 9.3 Tendances à long terme

Sur une période de mois à années, les valeurs peuvent changer en fonction de :
- La dégradation des performances du stockage (+10-30%)
- L'évolution des logiciels système (±20%)
- L'accumulation de données et métadonnées (+5-20%)

## 10. Valeurs de référence pour les tests

### 10.1 Valeurs de référence pour les tests unitaires

```json
{
  "basic": {
    "unit": "microseconds",
    "min": 60,
    "max": 4000,
    "avg": 300,
    "median": 220,
    "tolerance": {
      "min": 10,
      "max": 1000,
      "avg": 50,
      "median": 40
    }
  }
}
```plaintext
### 10.2 Valeurs de référence pour les tests d'intégration

```json
{
  "basic": {
    "unit": "microseconds",
    "min": 60,
    "max": 4500,
    "avg": 320,
    "median": 240,
    "tolerance": {
      "min": 15,
      "max": 1500,
      "avg": 80,
      "median": 60
    }
  }
}
```plaintext
### 10.3 Valeurs de référence pour les tests de performance

```json
{
  "basic": {
    "unit": "microseconds",
    "min": 55,
    "max": 3500,
    "avg": 280,
    "median": 210,
    "targets": {
      "min": {
        "good": 50,
        "acceptable": 65,
        "problematic": 80
      },
      "max": {
        "good": 3000,
        "acceptable": 5000,
        "problematic": 7000
      },
      "avg": {
        "good": 250,
        "acceptable": 350,
        "problematic": 450
      },
      "median": {
        "good": 190,
        "acceptable": 260,
        "problematic": 330
      }
    }
  }
}
```plaintext
## 11. Conclusion

Les plages de valeurs typiques pour les lectures aléatoires de blocs de 2KB présentent les caractéristiques suivantes :

1. **Valeurs centrales modérées** : Avec une moyenne typique de 250-400 µs et une médiane de 180-300 µs, les blocs de 2KB offrent des performances intermédiaires entre les très petits blocs (512B, 1KB) et les blocs standard (4KB).

2. **Asymétrie positive** : La distribution est généralement asymétrique (moyenne > médiane), reflétant l'impact des valeurs extrêmes sur la moyenne.

3. **Sensibilité au contexte** : Les valeurs varient significativement selon l'environnement matériel, logiciel et la charge du système.

4. **Position stratégique** : Les blocs de 2KB se situent à un point d'inflexion intéressant dans la courbe de performance, offrant un bon équilibre entre overhead par opération et volume de données transféré.

Ces plages de valeurs servent de référence pour l'analyse des performances, la détection d'anomalies et l'optimisation des systèmes utilisant des lectures aléatoires de blocs de 2KB.
