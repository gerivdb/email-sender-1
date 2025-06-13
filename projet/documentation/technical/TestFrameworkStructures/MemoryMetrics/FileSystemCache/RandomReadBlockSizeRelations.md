# Relations entre métriques pour les lectures aléatoires par taille de bloc

## 1. Vue d'ensemble

Ce document définit les relations entre les différentes métriques de latence par taille de bloc pour les lectures aléatoires dans le cache de système de fichiers. Ces relations sont essentielles pour garantir la cohérence des données, permettre des analyses comparatives fiables et faciliter la dérivation de métriques avancées à partir de métriques fondamentales. La compréhension de ces relations permet également d'optimiser la collecte des données en identifiant les métriques qui peuvent être calculées plutôt que mesurées directement.

## 2. Types de relations

### 2.1 Relations hiérarchiques

Les relations hiérarchiques définissent la structure d'imbrication des métriques dans le schéma JSON.

```plaintext
byBlockSize
  ├── blockSizes[]
  │     ├── metrics
  │     │     ├── basic
  │     │     ├── distribution
  │     │     ├── stability
  │     │     ├── cacheEfficiency
  │     │     ├── throughput
  │     │     └── comparisonToSequential
  ├── summary
  ├── scaling
  └── optimal
```plaintext
### 2.2 Relations mathématiques

Les relations mathématiques définissent comment certaines métriques peuvent être calculées à partir d'autres.

| Métrique dérivée | Formule | Métriques sources |
|------------------|---------|-------------------|
| `metrics.basic.stdDev` | √(variance) | `metrics.basic.variance` |
| `metrics.basic.variance` | Σ(x - avg)² / n | Données brutes, `metrics.basic.avg` |
| `metrics.distribution.histogram[].percentage` | count / samples * 100 | `metrics.distribution.histogram[].count`, `metrics.basic.samples` |
| `metrics.cacheEfficiency.missRate` | 1 - hitRate | `metrics.cacheEfficiency.hitRate` |
| `metrics.cacheEfficiency.hitLatencyToMissLatency` | hitLatency / missLatency | `metrics.cacheEfficiency.hitLatency`, `metrics.cacheEfficiency.missLatency` |
| `metrics.comparisonToSequential.latencyRatio.avg` | randomLatency.avg / sequentialLatency.avg | `metrics.basic.avg`, Métriques séquentielles correspondantes |
| `scaling.equation` | Régression sur les données | `blockSizes[].sizeBytes`, `blockSizes[].metrics.basic.avg` |
| `scaling.r2` | Coefficient de détermination | `blockSizes[].sizeBytes`, `blockSizes[].metrics.basic.avg`, `scaling.equation` |

### 2.3 Relations de cohérence

Les relations de cohérence définissent les contraintes que les métriques doivent respecter pour être valides.

| Contrainte | Description | Métriques concernées |
|------------|-------------|---------------------|
| Ordre statistique | min ≤ p10 ≤ p25 ≤ median ≤ p75 ≤ p90 ≤ p95 ≤ p99 ≤ max | Tous les percentiles dans `metrics.basic` |
| Moyenne vs médiane | Dans une distribution asymétrique positive (typique pour la latence), avg > median | `metrics.basic.avg`, `metrics.basic.median` |
| Somme des pourcentages | Σ histogram[].percentage = 100% | `metrics.distribution.histogram[].percentage` |
| Cohérence des outliers | outliers.min > un seuil basé sur les percentiles (ex: p99) | `metrics.distribution.outliers.min`, `metrics.basic.p99` |
| Ratio de latence | comparisonToSequential.latencyRatio.avg > 1 (lectures aléatoires généralement plus lentes) | `metrics.comparisonToSequential.latencyRatio.avg` |
| Ratio de débit | comparisonToSequential.throughputRatio < 1 (lectures aléatoires généralement moins performantes) | `metrics.comparisonToSequential.throughputRatio` |

### 2.4 Relations inter-tailles de bloc

Les relations inter-tailles de bloc définissent comment les métriques évoluent en fonction de la taille des blocs.

| Relation | Description | Métriques concernées |
|----------|-------------|---------------------|
| Scaling de latence | La latence augmente généralement avec la taille du bloc | `blockSizes[].metrics.basic.avg` |
| Scaling de débit | Le débit augmente généralement avec la taille du bloc jusqu'à un certain point | `blockSizes[].metrics.throughput.avg` |
| Scaling d'IOPS | Les IOPS diminuent généralement quand la taille du bloc augmente | `blockSizes[].metrics.throughput.iops.avg` |
| Efficacité du cache | Le taux de succès du cache diminue généralement quand la taille du bloc augmente | `blockSizes[].metrics.cacheEfficiency.hitRate` |
| Variabilité | La variabilité relative (coefficient de variation) diminue généralement quand la taille du bloc augmente | `blockSizes[].metrics.stability.variationCoefficient` |

## 3. Graphe de dépendances des métriques

Le graphe de dépendances ci-dessous illustre comment les métriques sont dérivées les unes des autres. Les nœuds représentent les métriques et les arêtes indiquent les dépendances.

```plaintext
                                 ┌─────────────┐
                                 │ Données brutes │
                                 └───────┬─────┘
                                         │
                 ┌───────────────┬───────┼───────┬───────────────┐
                 │               │       │       │               │
         ┌───────▼───────┐      │       │       │      ┌────────▼────────┐
         │     min       │      │       │       │      │       max       │
         └───────────────┘      │       │       │      └─────────────────┘
                                │       │       │
                         ┌──────▼──┐    │    ┌──▼─────┐
                         │ median  │    │    │  avg   │
                         └─────────┘    │    └────┬───┘
                                        │         │
                                  ┌─────▼─────┐   │
                                  │ percentiles│   │
                                  └─────┬─────┘   │
                                        │         │
                                        │    ┌────▼────┐
                                        │    │ variance │
                                        │    └────┬────┘
                                        │         │
                                        │    ┌────▼────┐
                                        │    │  stdDev  │
                                        │    └─────────┘
                                        │
                               ┌────────▼────────┐
                               │    histogram    │
                               └────────┬────────┘
                                        │
                                        │
                               ┌────────▼────────┐
                               │     outliers    │
                               └────────┬────────┘
                                        │
                                        │
                               ┌────────▼────────┐
                               │ variationCoeff  │
                               └────────┬────────┘
                                        │
                                        │
                               ┌────────▼────────┐
                               │  stabilityScore  │
                               └─────────────────┘
```plaintext
## 4. Relations entre métriques et tailles de bloc

### 4.1 Modèles de scaling typiques

Les relations entre la taille des blocs et les différentes métriques suivent généralement des modèles prévisibles. Voici les modèles les plus courants :

#### 4.1.1 Latence moyenne

La latence moyenne en fonction de la taille du bloc suit généralement l'un de ces modèles :

1. **Linéaire** : `latency = a + b * blockSize`
   - Typique pour les petites tailles de bloc où le temps de transfert domine
   - Exemple : `latency = 100 + 0.25 * blockSize` (µs, blockSize en KB)

2. **Sous-linéaire** : `latency = a + b * blockSize^c` (où c < 1)
   - Typique quand les optimisations matérielles compensent partiellement l'augmentation de taille
   - Exemple : `latency = 100 + 2 * blockSize^0.7` (µs, blockSize en KB)

3. **Par paliers** : Augmentation par paliers correspondant aux limites des caches matériels
   - Exemple : Augmentation significative après 64KB (taille de ligne de cache L2)

#### 4.1.2 Débit

Le débit en fonction de la taille du bloc suit généralement une courbe en cloche :

1. **Phase ascendante** : `throughput = a * blockSize^b` (où b < 1)
   - Pour les petites tailles de bloc, où l'overhead par opération domine
   - Exemple : `throughput = 5 * blockSize^0.8` (MB/s, blockSize en KB)

2. **Plateau** : `throughput ≈ constant`
   - Pour les tailles de bloc moyennes, où le débit atteint la limite du sous-système
   - Exemple : `throughput ≈ 120 MB/s` pour 32KB-128KB

3. **Phase descendante** : `throughput = c / blockSize^d`
   - Pour les grandes tailles de bloc, où les limitations de mémoire ou de cache deviennent significatives
   - Exemple : `throughput = 10000 / blockSize^0.3` (MB/s, blockSize en KB)

#### 4.1.3 Taux de succès du cache

Le taux de succès du cache en fonction de la taille du bloc suit généralement une courbe décroissante :

1. **Décroissance exponentielle** : `hitRate = a * e^(-b * blockSize)`
   - Typique quand la capacité du cache est le facteur limitant
   - Exemple : `hitRate = 0.95 * e^(-0.01 * blockSize)` (blockSize en KB)

2. **Décroissance sigmoïde** : `hitRate = a / (1 + e^(b * (blockSize - c)))`
   - Typique quand il y a un seuil critique de taille de bloc
   - Exemple : `hitRate = 0.95 / (1 + e^(0.1 * (blockSize - 64)))` (blockSize en KB)

### 4.2 Points d'inflexion typiques

Les points d'inflexion dans les courbes de performance correspondent souvent à des caractéristiques matérielles ou logicielles spécifiques :

| Taille de bloc | Point d'inflexion typique | Explication |
|----------------|---------------------------|-------------|
| 4KB | Taille de page du système d'exploitation | Alignement avec la pagination mémoire |
| 8-16KB | Taille du cache L1 par cœur | Limite du cache de premier niveau |
| 32-64KB | Taille de ligne du cache L2 | Limite d'une ligne de cache L2 |
| 128-256KB | Taille du cache L2 par cœur | Limite du cache de deuxième niveau |
| 1-4MB | Taille du cache L3 partagé | Limite du cache de troisième niveau |
| 64-128KB | Taille de bloc du système de fichiers | Alignement avec les blocs du système de fichiers |
| 1-4MB | Taille de préchargement maximale | Limite des mécanismes de préchargement |

## 5. Relations entre métriques de différentes catégories

### 5.1 Relations entre latence et débit

La relation entre la latence et le débit pour une taille de bloc donnée est généralement inversement proportionnelle :

```plaintext
throughput ≈ blockSize / latency * concurrencyFactor
```plaintext
Où :
- `throughput` est le débit en octets par seconde
- `blockSize` est la taille du bloc en octets
- `latency` est la latence moyenne en secondes
- `concurrencyFactor` est un facteur qui dépend du niveau de parallélisme (≥ 1)

### 5.2 Relations entre latence et efficacité du cache

La latence moyenne est une combinaison pondérée des latences en cas de succès et d'échec du cache :

```plaintext
avg = hitRate * hitLatency + missRate * missLatency
```plaintext
Cette relation permet de dériver l'une des métriques si les autres sont connues.

### 5.3 Relations entre stabilité et distribution

Les métriques de stabilité sont dérivées des caractéristiques de la distribution :

```plaintext
variationCoefficient = stdDev / avg
```plaintext
```plaintext
stabilityScore = 1 / (1 + variationCoefficient)
```plaintext
### 5.4 Relations entre métriques comparatives

Les métriques comparatives entre lectures aléatoires et séquentielles sont directement liées aux métriques absolues :

```plaintext
latencyRatio.avg = randomLatency.avg / sequentialLatency.avg
```plaintext
```plaintext
throughputRatio = randomThroughput.avg / sequentialThroughput.avg
```plaintext
## 6. Utilisation des relations pour la validation et la dérivation

### 6.1 Validation des données

Les relations définies peuvent être utilisées pour valider la cohérence des données collectées :

1. **Vérification des contraintes d'ordre** : S'assurer que min ≤ median ≤ avg ≤ max
2. **Vérification des relations dérivées** : S'assurer que stdDev = √variance
3. **Vérification des relations inter-tailles** : S'assurer que les tendances de scaling sont respectées
4. **Vérification des relations catégorielles** : S'assurer que avg = hitRate * hitLatency + missRate * missLatency

### 6.2 Dérivation de métriques manquantes

Les relations définies peuvent être utilisées pour dériver des métriques non mesurées directement :

1. **Dérivation de percentiles** : Estimer les percentiles à partir de la distribution
2. **Dérivation de métriques de stabilité** : Calculer variationCoefficient et stabilityScore à partir de avg et stdDev
3. **Dérivation de métriques d'efficacité** : Calculer missRate à partir de hitRate
4. **Dérivation de métriques comparatives** : Calculer les ratios à partir des métriques absolues

### 6.3 Détection d'anomalies

Les relations définies peuvent être utilisées pour détecter des anomalies dans les données :

1. **Anomalies de scaling** : Déviations significatives par rapport au modèle de scaling attendu
2. **Anomalies de cohérence** : Violations des contraintes de cohérence
3. **Anomalies de distribution** : Distributions multimodales ou fortement asymétriques
4. **Anomalies de performance** : Performances anormalement basses ou élevées pour certaines tailles de bloc

## 7. Exemples de relations dans différents contextes

### 7.1 Système de fichiers avec cache efficace

Dans un système avec un cache de système de fichiers efficace, les relations typiques sont :

- Latence : Augmentation quasi-linéaire avec la taille du bloc
- Taux de succès : Diminution lente avec la taille du bloc
- Débit : Augmentation rapide puis plateau
- Variabilité : Faible et stable

```json
{
  "byBlockSize": {
    "blockSizes": [
      {
        "size": "4KB",
        "metrics": {
          "basic": { "avg": 100 },
          "cacheEfficiency": { "hitRate": 0.95 },
          "throughput": { "avg": 40 }
        }
      },
      {
        "size": "64KB",
        "metrics": {
          "basic": { "avg": 400 },
          "cacheEfficiency": { "hitRate": 0.85 },
          "throughput": { "avg": 160 }
        }
      }
    ],
    "scaling": {
      "model": "linear",
      "equation": "latency = 80 + 5 * blockSize"
    }
  }
}
```plaintext
### 7.2 Système de fichiers avec cache inefficace

Dans un système avec un cache de système de fichiers inefficace, les relations typiques sont :

- Latence : Augmentation rapide avec la taille du bloc
- Taux de succès : Diminution rapide avec la taille du bloc
- Débit : Augmentation limitée puis diminution
- Variabilité : Élevée et croissante

```json
{
  "byBlockSize": {
    "blockSizes": [
      {
        "size": "4KB",
        "metrics": {
          "basic": { "avg": 500 },
          "cacheEfficiency": { "hitRate": 0.60 },
          "throughput": { "avg": 8 }
        }
      },
      {
        "size": "64KB",
        "metrics": {
          "basic": { "avg": 3000 },
          "cacheEfficiency": { "hitRate": 0.20 },
          "throughput": { "avg": 21 }
        }
      }
    ],
    "scaling": {
      "model": "exponential",
      "equation": "latency = 400 * e^(0.03 * blockSize)"
    }
  }
}
```plaintext
## 8. Conclusion

Les relations entre les métriques de latence par taille de bloc pour les lectures aléatoires sont complexes mais prévisibles. La compréhension de ces relations permet :

1. **Une collecte de données optimisée** : En mesurant directement les métriques fondamentales et en dérivant les autres
2. **Une validation robuste** : En vérifiant la cohérence des données collectées
3. **Une analyse approfondie** : En identifiant les tendances et les anomalies
4. **Des recommandations précises** : En déterminant les tailles de bloc optimales pour différents cas d'utilisation

Ces relations constituent la base d'un modèle de performance complet pour les lectures aléatoires dans le cache de système de fichiers, permettant des prédictions fiables et des optimisations efficaces.
