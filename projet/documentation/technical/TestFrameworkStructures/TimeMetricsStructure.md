# Structure des métriques temporelles

## 1. Vue d'ensemble

La structure des métriques temporelles définit le format et l'organisation des données de mesure du temps collectées pendant l'exécution des tests de performance. Ces métriques sont essentielles pour évaluer les performances temporelles des composants testés et pour identifier les goulots d'étranglement.

## 2. Structure de base

Les métriques temporelles sont organisées dans une structure hiérarchique qui permet de capturer différents aspects des mesures de temps. La structure de base est la suivante :

```json
{
  "time": {
    "wallClock": {
      // Mesures de temps réel (temps écoulé)
    },
    "cpu": {
      // Mesures de temps CPU
    },
    "operations": {
      // Mesures de temps par opération
    },
    "markers": {
      // Mesures de temps entre marqueurs
    },
    "distributions": {
      // Distributions statistiques des temps
    }
  }
}
```plaintext
## 3. Composants détaillés

### 3.1 Temps réel (wallClock)

Le temps réel, ou "wall clock time", représente le temps écoulé tel que mesuré par une horloge murale. C'est le temps perçu par l'utilisateur.

```json
{
  "wallClock": {
    "total": 330500,
    "byPhase": {
      "initialization": 5500,
      "dataLoading": 120000,
      "indexCreation": 200000,
      "cleanup": 5000
    },
    "byIteration": [
      {
        "iteration": 1,
        "duration": 65000
      },
      {
        "iteration": 2,
        "duration": 63500
      },
      {
        "iteration": 3,
        "duration": 67000
      },
      {
        "iteration": 4,
        "duration": 65500
      },
      {
        "iteration": 5,
        "duration": 64500
      }
    ],
    "overhead": {
      "total": 5000,
      "setup": 2000,
      "teardown": 3000
    }
  }
}
```plaintext
| Champ | Type | Description |
|-------|------|-------------|
| `total` | number | Durée totale du test en millisecondes |
| `byPhase` | object | Répartition du temps par phase du test |
| `byPhase.<phase>` | number | Durée d'une phase spécifique en millisecondes |
| `byIteration` | array | Répartition du temps par itération |
| `byIteration[].iteration` | number | Numéro de l'itération |
| `byIteration[].duration` | number | Durée de l'itération en millisecondes |
| `overhead` | object | Temps de surcharge non lié à l'exécution du test lui-même |
| `overhead.total` | number | Temps de surcharge total en millisecondes |
| `overhead.setup` | number | Temps de préparation en millisecondes |
| `overhead.teardown` | number | Temps de nettoyage en millisecondes |

### 3.2 Temps CPU

Le temps CPU représente le temps de traitement utilisé par le processeur pour exécuter le test. Il peut être divisé en temps utilisateur et temps système.

```json
{
  "cpu": {
    "total": 280000,
    "user": 250000,
    "system": 30000,
    "byPhase": {
      "initialization": 3000,
      "dataLoading": 100000,
      "indexCreation": 170000,
      "cleanup": 2000
    },
    "byProcess": {
      "main": 260000,
      "child": 20000
    },
    "byThread": [
      {
        "threadId": 1,
        "duration": 150000
      },
      {
        "threadId": 2,
        "duration": 130000
      }
    ],
    "utilization": 0.85
  }
}
```plaintext
| Champ | Type | Description |
|-------|------|-------------|
| `total` | number | Temps CPU total en millisecondes |
| `user` | number | Temps CPU en mode utilisateur en millisecondes |
| `system` | number | Temps CPU en mode système en millisecondes |
| `byPhase` | object | Répartition du temps CPU par phase |
| `byPhase.<phase>` | number | Temps CPU d'une phase spécifique en millisecondes |
| `byProcess` | object | Répartition du temps CPU par processus |
| `byProcess.<process>` | number | Temps CPU d'un processus spécifique en millisecondes |
| `byThread` | array | Répartition du temps CPU par thread |
| `byThread[].threadId` | number | Identifiant du thread |
| `byThread[].duration` | number | Temps CPU du thread en millisecondes |
| `utilization` | number | Ratio d'utilisation CPU (temps CPU / temps réel) |

### 3.3 Temps par opération

Le temps par opération représente le temps passé à exécuter des opérations spécifiques pendant le test.

```json
{
  "operations": {
    "summary": {
      "total": 18000,
      "count": 18000,
      "avgPerOperation": 1.0
    },
    "details": {
      "lookup": {
        "total": 5000,
        "count": 10000,
        "avgPerOperation": 0.5,
        "min": 0.1,
        "max": 2.5,
        "p50": 0.4,
        "p90": 0.8,
        "p95": 1.0,
        "p99": 1.5
      },
      "insert": {
        "total": 6000,
        "count": 5000,
        "avgPerOperation": 1.2,
        "min": 0.5,
        "max": 5.0,
        "p50": 1.0,
        "p90": 2.0,
        "p95": 2.5,
        "p99": 4.0
      },
      "update": {
        "total": 3000,
        "count": 2000,
        "avgPerOperation": 1.5,
        "min": 0.8,
        "max": 6.0,
        "p50": 1.2,
        "p90": 2.5,
        "p95": 3.0,
        "p99": 5.0
      },
      "delete": {
        "total": 800,
        "count": 1000,
        "avgPerOperation": 0.8,
        "min": 0.3,
        "max": 3.0,
        "p50": 0.7,
        "p90": 1.5,
        "p95": 2.0,
        "p99": 2.5
      }
    },
    "bySize": [
      {
        "size": "small",
        "avgTime": 0.5
      },
      {
        "size": "medium",
        "avgTime": 1.0
      },
      {
        "size": "large",
        "avgTime": 2.0
      }
    ],
    "byComplexity": [
      {
        "complexity": "simple",
        "avgTime": 0.5
      },
      {
        "complexity": "moderate",
        "avgTime": 1.0
      },
      {
        "complexity": "complex",
        "avgTime": 2.0
      }
    ]
  }
}
```plaintext
| Champ | Type | Description |
|-------|------|-------------|
| `summary.total` | number | Temps total pour toutes les opérations en millisecondes |
| `summary.count` | number | Nombre total d'opérations |
| `summary.avgPerOperation` | number | Temps moyen par opération en millisecondes |
| `details` | object | Détails par type d'opération |
| `details.<operation>` | object | Métriques pour un type d'opération spécifique |
| `details.<operation>.total` | number | Temps total pour ce type d'opération en millisecondes |
| `details.<operation>.count` | number | Nombre d'opérations de ce type |
| `details.<operation>.avgPerOperation` | number | Temps moyen par opération en millisecondes |
| `details.<operation>.min` | number | Temps minimum pour une opération en millisecondes |
| `details.<operation>.max` | number | Temps maximum pour une opération en millisecondes |
| `details.<operation>.p50/p90/p95/p99` | number | Percentiles des temps d'opération en millisecondes |
| `bySize` | array | Répartition des temps par taille d'opération |
| `byComplexity` | array | Répartition des temps par complexité d'opération |

### 3.4 Marqueurs temporels

Les marqueurs temporels permettent de mesurer le temps entre des points spécifiques du test.

```json
{
  "markers": {
    "points": {
      "start": "2025-05-15T10:00:00.000Z",
      "dataLoaded": "2025-05-15T10:02:05.500Z",
      "indexCreated": "2025-05-15T10:05:25.500Z",
      "end": "2025-05-15T10:05:30.500Z"
    },
    "intervals": {
      "initialization": {
        "start": "start",
        "end": "dataLoaded",
        "duration": 125500
      },
      "processing": {
        "start": "dataLoaded",
        "end": "indexCreated",
        "duration": 200000
      },
      "finalization": {
        "start": "indexCreated",
        "end": "end",
        "duration": 5000
      }
    },
    "custom": [
      {
        "name": "firstBatchProcessed",
        "timestamp": "2025-05-15T10:01:05.500Z",
        "elapsedFromStart": 65500
      },
      {
        "name": "halfwayPoint",
        "timestamp": "2025-05-15T10:02:45.250Z",
        "elapsedFromStart": 165250
      }
    ]
  }
}
```plaintext
| Champ | Type | Description |
|-------|------|-------------|
| `points` | object | Points de marquage temporel |
| `points.<marker>` | string | Horodatage d'un marqueur spécifique (ISO 8601) |
| `intervals` | object | Intervalles entre marqueurs |
| `intervals.<interval>` | object | Définition d'un intervalle |
| `intervals.<interval>.start` | string | Marqueur de début de l'intervalle |
| `intervals.<interval>.end` | string | Marqueur de fin de l'intervalle |
| `intervals.<interval>.duration` | number | Durée de l'intervalle en millisecondes |
| `custom` | array | Marqueurs personnalisés |
| `custom[].name` | string | Nom du marqueur personnalisé |
| `custom[].timestamp` | string | Horodatage du marqueur (ISO 8601) |
| `custom[].elapsedFromStart` | number | Temps écoulé depuis le début du test en millisecondes |

### 3.5 Distributions temporelles

Les distributions temporelles fournissent des informations statistiques sur la répartition des temps mesurés.

```json
{
  "distributions": {
    "histogram": {
      "buckets": [
        {
          "min": 0,
          "max": 1,
          "count": 5000
        },
        {
          "min": 1,
          "max": 2,
          "count": 8000
        },
        {
          "min": 2,
          "max": 5,
          "count": 4000
        },
        {
          "min": 5,
          "max": 10,
          "count": 1000
        }
      ],
      "outliers": 50
    },
    "percentiles": {
      "p1": 0.2,
      "p5": 0.3,
      "p10": 0.4,
      "p25": 0.6,
      "p50": 1.2,
      "p75": 2.0,
      "p90": 3.5,
      "p95": 4.8,
      "p99": 8.0,
      "p99.9": 15.0
    },
    "statistics": {
      "mean": 1.8,
      "median": 1.2,
      "stdDev": 1.5,
      "variance": 2.25,
      "skewness": 2.1,
      "kurtosis": 7.5
    },
    "timeSeries": {
      "interval": 10000,
      "points": [
        {
          "timestamp": "2025-05-15T10:00:10.000Z",
          "value": 1.5
        },
        {
          "timestamp": "2025-05-15T10:00:20.000Z",
          "value": 1.7
        },
        {
          "timestamp": "2025-05-15T10:00:30.000Z",
          "value": 1.9
        },
        // ... autres points
      ]
    }
  }
}
```plaintext
| Champ | Type | Description |
|-------|------|-------------|
| `histogram.buckets` | array | Buckets de l'histogramme des temps |
| `histogram.buckets[].min` | number | Limite inférieure du bucket en millisecondes |
| `histogram.buckets[].max` | number | Limite supérieure du bucket en millisecondes |
| `histogram.buckets[].count` | number | Nombre de mesures dans ce bucket |
| `histogram.outliers` | number | Nombre de valeurs aberrantes |
| `percentiles` | object | Valeurs des percentiles en millisecondes |
| `statistics` | object | Statistiques descriptives |
| `statistics.mean` | number | Moyenne des temps en millisecondes |
| `statistics.median` | number | Médiane des temps en millisecondes |
| `statistics.stdDev` | number | Écart-type des temps en millisecondes |
| `statistics.variance` | number | Variance des temps |
| `statistics.skewness` | number | Asymétrie de la distribution |
| `statistics.kurtosis` | number | Aplatissement de la distribution |
| `timeSeries` | object | Série temporelle des mesures |
| `timeSeries.interval` | number | Intervalle d'échantillonnage en millisecondes |
| `timeSeries.points` | array | Points de la série temporelle |

## 4. Formats spécialisés

### 4.1 Latence et débit

```json
{
  "latency": {
    "min": 0.5,
    "max": 15.0,
    "avg": 1.8,
    "p50": 1.2,
    "p90": 3.5,
    "p95": 4.8,
    "p99": 8.0,
    "jitter": 0.8
  },
  "throughput": {
    "total": 18000,
    "perSecond": 54.5,
    "peak": 120.0,
    "byPhase": {
      "initialization": 0.0,
      "dataLoading": 83.3,
      "indexCreation": 25.0,
      "cleanup": 0.0
    }
  }
}
```plaintext
| Champ | Type | Description |
|-------|------|-------------|
| `latency` | object | Métriques de latence en millisecondes |
| `latency.jitter` | number | Variation de la latence en millisecondes |
| `throughput` | object | Métriques de débit |
| `throughput.total` | number | Nombre total d'opérations |
| `throughput.perSecond` | number | Nombre d'opérations par seconde |
| `throughput.peak` | number | Débit maximal atteint en opérations par seconde |
| `throughput.byPhase` | object | Débit par phase en opérations par seconde |

### 4.2 Temps de réponse

```json
{
  "responseTime": {
    "firstByte": {
      "min": 0.2,
      "max": 5.0,
      "avg": 0.8
    },
    "lastByte": {
      "min": 0.5,
      "max": 15.0,
      "avg": 1.8
    },
    "processing": {
      "min": 0.3,
      "max": 10.0,
      "avg": 1.0
    },
    "byStatus": {
      "success": {
        "avg": 1.5
      },
      "error": {
        "avg": 3.0
      }
    }
  }
}
```plaintext
| Champ | Type | Description |
|-------|------|-------------|
| `responseTime.firstByte` | object | Temps jusqu'au premier octet en millisecondes |
| `responseTime.lastByte` | object | Temps jusqu'au dernier octet en millisecondes |
| `responseTime.processing` | object | Temps de traitement en millisecondes |
| `responseTime.byStatus` | object | Temps de réponse par statut en millisecondes |

### 4.3 Temps d'attente et de blocage

```json
{
  "waiting": {
    "total": 50000,
    "byResource": {
      "database": 30000,
      "network": 15000,
      "disk": 5000
    },
    "byOperation": {
      "read": 20000,
      "write": 30000
    }
  },
  "blocking": {
    "total": 25000,
    "byLock": {
      "readLock": 10000,
      "writeLock": 15000
    },
    "byThread": {
      "thread1": 15000,
      "thread2": 10000
    }
  }
}
```plaintext
| Champ | Type | Description |
|-------|------|-------------|
| `waiting.total` | number | Temps d'attente total en millisecondes |
| `waiting.byResource` | object | Temps d'attente par ressource en millisecondes |
| `waiting.byOperation` | object | Temps d'attente par opération en millisecondes |
| `blocking.total` | number | Temps de blocage total en millisecondes |
| `blocking.byLock` | object | Temps de blocage par type de verrou en millisecondes |
| `blocking.byThread` | object | Temps de blocage par thread en millisecondes |

## 5. Exemples complets

### 5.1 Exemple minimal

```json
{
  "time": {
    "wallClock": {
      "total": 330500
    },
    "cpu": {
      "total": 280000
    }
  }
}
```plaintext
### 5.2 Exemple complet

```json
{
  "time": {
    "wallClock": {
      "total": 330500,
      "byPhase": {
        "initialization": 5500,
        "dataLoading": 120000,
        "indexCreation": 200000,
        "cleanup": 5000
      },
      "byIteration": [
        {
          "iteration": 1,
          "duration": 65000
        },
        {
          "iteration": 2,
          "duration": 63500
        },
        {
          "iteration": 3,
          "duration": 67000
        },
        {
          "iteration": 4,
          "duration": 65500
        },
        {
          "iteration": 5,
          "duration": 64500
        }
      ],
      "overhead": {
        "total": 5000,
        "setup": 2000,
        "teardown": 3000
      }
    },
    "cpu": {
      "total": 280000,
      "user": 250000,
      "system": 30000,
      "byPhase": {
        "initialization": 3000,
        "dataLoading": 100000,
        "indexCreation": 170000,
        "cleanup": 2000
      },
      "byProcess": {
        "main": 260000,
        "child": 20000
      },
      "byThread": [
        {
          "threadId": 1,
          "duration": 150000
        },
        {
          "threadId": 2,
          "duration": 130000
        }
      ],
      "utilization": 0.85
    },
    "operations": {
      "summary": {
        "total": 18000,
        "count": 18000,
        "avgPerOperation": 1.0
      },
      "details": {
        "lookup": {
          "total": 5000,
          "count": 10000,
          "avgPerOperation": 0.5,
          "min": 0.1,
          "max": 2.5,
          "p50": 0.4,
          "p90": 0.8,
          "p95": 1.0,
          "p99": 1.5
        },
        "insert": {
          "total": 6000,
          "count": 5000,
          "avgPerOperation": 1.2,
          "min": 0.5,
          "max": 5.0,
          "p50": 1.0,
          "p90": 2.0,
          "p95": 2.5,
          "p99": 4.0
        },
        "update": {
          "total": 3000,
          "count": 2000,
          "avgPerOperation": 1.5,
          "min": 0.8,
          "max": 6.0,
          "p50": 1.2,
          "p90": 2.5,
          "p95": 3.0,
          "p99": 5.0
        },
        "delete": {
          "total": 800,
          "count": 1000,
          "avgPerOperation": 0.8,
          "min": 0.3,
          "max": 3.0,
          "p50": 0.7,
          "p90": 1.5,
          "p95": 2.0,
          "p99": 2.5
        }
      },
      "bySize": [
        {
          "size": "small",
          "avgTime": 0.5
        },
        {
          "size": "medium",
          "avgTime": 1.0
        },
        {
          "size": "large",
          "avgTime": 2.0
        }
      ],
      "byComplexity": [
        {
          "complexity": "simple",
          "avgTime": 0.5
        },
        {
          "complexity": "moderate",
          "avgTime": 1.0
        },
        {
          "complexity": "complex",
          "avgTime": 2.0
        }
      ]
    },
    "markers": {
      "points": {
        "start": "2025-05-15T10:00:00.000Z",
        "dataLoaded": "2025-05-15T10:02:05.500Z",
        "indexCreated": "2025-05-15T10:05:25.500Z",
        "end": "2025-05-15T10:05:30.500Z"
      },
      "intervals": {
        "initialization": {
          "start": "start",
          "end": "dataLoaded",
          "duration": 125500
        },
        "processing": {
          "start": "dataLoaded",
          "end": "indexCreated",
          "duration": 200000
        },
        "finalization": {
          "start": "indexCreated",
          "end": "end",
          "duration": 5000
        }
      },
      "custom": [
        {
          "name": "firstBatchProcessed",
          "timestamp": "2025-05-15T10:01:05.500Z",
          "elapsedFromStart": 65500
        },
        {
          "name": "halfwayPoint",
          "timestamp": "2025-05-15T10:02:45.250Z",
          "elapsedFromStart": 165250
        }
      ]
    },
    "distributions": {
      "histogram": {
        "buckets": [
          {
            "min": 0,
            "max": 1,
            "count": 5000
          },
          {
            "min": 1,
            "max": 2,
            "count": 8000
          },
          {
            "min": 2,
            "max": 5,
            "count": 4000
          },
          {
            "min": 5,
            "max": 10,
            "count": 1000
          }
        ],
        "outliers": 50
      },
      "percentiles": {
        "p1": 0.2,
        "p5": 0.3,
        "p10": 0.4,
        "p25": 0.6,
        "p50": 1.2,
        "p75": 2.0,
        "p90": 3.5,
        "p95": 4.8,
        "p99": 8.0,
        "p99.9": 15.0
      },
      "statistics": {
        "mean": 1.8,
        "median": 1.2,
        "stdDev": 1.5,
        "variance": 2.25,
        "skewness": 2.1,
        "kurtosis": 7.5
      },
      "timeSeries": {
        "interval": 10000,
        "points": [
          {
            "timestamp": "2025-05-15T10:00:10.000Z",
            "value": 1.5
          },
          {
            "timestamp": "2025-05-15T10:00:20.000Z",
            "value": 1.7
          },
          {
            "timestamp": "2025-05-15T10:00:30.000Z",
            "value": 1.9
          }
        ]
      }
    },
    "latency": {
      "min": 0.5,
      "max": 15.0,
      "avg": 1.8,
      "p50": 1.2,
      "p90": 3.5,
      "p95": 4.8,
      "p99": 8.0,
      "jitter": 0.8
    },
    "throughput": {
      "total": 18000,
      "perSecond": 54.5,
      "peak": 120.0,
      "byPhase": {
        "initialization": 0.0,
        "dataLoading": 83.3,
        "indexCreation": 25.0,
        "cleanup": 0.0
      }
    },
    "responseTime": {
      "firstByte": {
        "min": 0.2,
        "max": 5.0,
        "avg": 0.8
      },
      "lastByte": {
        "min": 0.5,
        "max": 15.0,
        "avg": 1.8
      },
      "processing": {
        "min": 0.3,
        "max": 10.0,
        "avg": 1.0
      },
      "byStatus": {
        "success": {
          "avg": 1.5
        },
        "error": {
          "avg": 3.0
        }
      }
    },
    "waiting": {
      "total": 50000,
      "byResource": {
        "database": 30000,
        "network": 15000,
        "disk": 5000
      },
      "byOperation": {
        "read": 20000,
        "write": 30000
      }
    },
    "blocking": {
      "total": 25000,
      "byLock": {
        "readLock": 10000,
        "writeLock": 15000
      },
      "byThread": {
        "thread1": 15000,
        "thread2": 10000
      }
    }
  }
}
```plaintext
## 6. Bonnes pratiques

### 6.1 Unités de mesure

- Utiliser les millisecondes comme unité de base pour toutes les mesures de temps
- Pour les opérations très rapides, envisager d'utiliser les microsecondes
- Documenter clairement les unités utilisées
- Être cohérent dans l'utilisation des unités

### 6.2 Précision et exactitude

- Utiliser des méthodes de mesure de haute précision (par exemple, Stopwatch en .NET)
- Tenir compte de la résolution de l'horloge système
- Effectuer plusieurs mesures pour les opérations très rapides
- Documenter la précision des mesures

### 6.3 Contexte

- Inclure des informations sur l'environnement d'exécution
- Capturer les conditions initiales et finales
- Enregistrer les événements externes qui pourraient affecter les mesures
- Documenter les facteurs pouvant influencer les résultats

### 6.4 Agrégation

- Fournir des statistiques agrégées pour les mesures répétées
- Inclure des percentiles pour caractériser la distribution
- Identifier et traiter les valeurs aberrantes
- Utiliser des méthodes d'agrégation appropriées selon le type de données

### 6.5 Visualisation

- Concevoir la structure pour faciliter la visualisation des données
- Inclure des séries temporelles pour l'analyse des tendances
- Fournir des histogrammes pour comprendre la distribution
- Permettre la comparaison facile entre différentes exécutions
