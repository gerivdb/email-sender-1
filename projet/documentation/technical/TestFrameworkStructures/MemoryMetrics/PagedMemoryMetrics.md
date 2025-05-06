# Métriques de mémoire paginée

## 1. Vue d'ensemble

Les métriques de mémoire paginée représentent les mesures liées au système de pagination de la mémoire, qui est un mécanisme fondamental des systèmes d'exploitation modernes permettant de gérer la mémoire virtuelle. La pagination divise la mémoire en blocs de taille fixe (pages) qui peuvent être transférés entre la mémoire physique (RAM) et le stockage secondaire (disque) selon les besoins.

## 2. Structure de base

Les métriques de mémoire paginée sont organisées dans une structure hiérarchique qui permet de capturer différents aspects du système de pagination. La structure de base est la suivante :

```json
{
  "memory": {
    "paging": {
      // Métriques de mémoire paginée
    }
  }
}
```

## 3. Métriques principales

### 3.1 Configuration du système de pagination

```json
{
  "paging": {
    "system": {
      "pageSize": 4096,
      "largePageSize": 2097152,
      "totalPages": 4194304,
      "swapFileSize": 17179869184,
      "swapFileUsed": 2147483648,
      "swapFileAvailable": 15032385536,
      "swapFileLocation": "C:\\pagefile.sys",
      "minWorkingSetSize": 204800,
      "maxWorkingSetSize": 1073741824
    }
  }
}
```

| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `system.pageSize` | number | octets | Taille standard d'une page mémoire |
| `system.largePageSize` | number | octets | Taille d'une grande page mémoire (si supportée) |
| `system.totalPages` | number | - | Nombre total de pages mémoire disponibles |
| `system.swapFileSize` | number | octets | Taille totale du fichier d'échange |
| `system.swapFileUsed` | number | octets | Espace utilisé dans le fichier d'échange |
| `system.swapFileAvailable` | number | octets | Espace disponible dans le fichier d'échange |
| `system.swapFileLocation` | string | - | Emplacement du fichier d'échange |
| `system.minWorkingSetSize` | number | octets | Taille minimale du working set du processus |
| `system.maxWorkingSetSize` | number | octets | Taille maximale du working set du processus |

### 3.2 Statistiques de pages

```json
{
  "paging": {
    "pages": {
      "total": 256000,
      "resident": 128000,
      "nonresident": 128000,
      "shared": 50000,
      "private": 206000,
      "readOnly": 80000,
      "readWrite": 176000,
      "executable": 30000,
      "largePages": {
        "count": 50,
        "totalSize": 104857600
      }
    }
  }
}
```

| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `pages.total` | number | - | Nombre total de pages utilisées par le processus |
| `pages.resident` | number | - | Nombre de pages résidentes en mémoire physique |
| `pages.nonresident` | number | - | Nombre de pages non résidentes (sur disque) |
| `pages.shared` | number | - | Nombre de pages partagées avec d'autres processus |
| `pages.private` | number | - | Nombre de pages privées au processus |
| `pages.readOnly` | number | - | Nombre de pages en lecture seule |
| `pages.readWrite` | number | - | Nombre de pages en lecture/écriture |
| `pages.executable` | number | - | Nombre de pages exécutables |
| `pages.largePages.count` | number | - | Nombre de grandes pages utilisées |
| `pages.largePages.totalSize` | number | octets | Taille totale des grandes pages utilisées |

### 3.3 Défauts de page

```json
{
  "paging": {
    "pageFaults": {
      "total": 105000,
      "minor": 100000,
      "major": 5000,
      "copyOnWrite": 20000,
      "rate": {
        "avg": 1050,
        "peak": 5000,
        "byPhase": {
          "initialization": 2000,
          "dataLoading": 3000,
          "processing": 500,
          "cleanup": 100
        }
      },
      "timeSeries": {
        "interval": 1000,
        "unit": "ms",
        "samples": [
          {
            "timestamp": "2025-05-15T10:00:10.000Z",
            "minor": 1000,
            "major": 50
          },
          {
            "timestamp": "2025-05-15T10:00:11.000Z",
            "minor": 1500,
            "major": 75
          },
          // ... autres échantillons
        ]
      }
    }
  }
}
```

| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `pageFaults.total` | number | - | Nombre total de défauts de page |
| `pageFaults.minor` | number | - | Nombre de défauts de page mineurs (page en mémoire) |
| `pageFaults.major` | number | - | Nombre de défauts de page majeurs (page sur disque) |
| `pageFaults.copyOnWrite` | number | - | Nombre de défauts de page copy-on-write |
| `pageFaults.rate.avg` | number | défauts/s | Taux moyen de défauts de page |
| `pageFaults.rate.peak` | number | défauts/s | Taux maximal de défauts de page |
| `pageFaults.rate.byPhase.<phase>` | number | défauts/s | Taux de défauts de page par phase |
| `pageFaults.timeSeries.interval` | number | - | Intervalle d'échantillonnage |
| `pageFaults.timeSeries.unit` | string | - | Unité de l'intervalle d'échantillonnage |
| `pageFaults.timeSeries.samples` | array | - | Échantillons de défauts de page au fil du temps |

### 3.4 Opérations de pagination

```json
{
  "paging": {
    "operations": {
      "pageIns": {
        "total": 5000,
        "size": 20480000,
        "rate": {
          "avg": 50,
          "peak": 200
        }
      },
      "pageOuts": {
        "total": 3000,
        "size": 12288000,
        "rate": {
          "avg": 30,
          "peak": 150
        }
      },
      "pageReplacements": {
        "total": 2500,
        "algorithm": "LRU",
        "efficiency": 0.85
      },
      "pageReclaims": {
        "total": 1500,
        "rate": {
          "avg": 15,
          "peak": 100
        }
      }
    }
  }
}
```

| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `operations.pageIns.total` | number | - | Nombre total de pages chargées depuis le disque |
| `operations.pageIns.size` | number | octets | Taille totale des pages chargées depuis le disque |
| `operations.pageIns.rate.avg` | number | pages/s | Taux moyen de chargement de pages |
| `operations.pageIns.rate.peak` | number | pages/s | Taux maximal de chargement de pages |
| `operations.pageOuts.total` | number | - | Nombre total de pages déchargées vers le disque |
| `operations.pageOuts.size` | number | octets | Taille totale des pages déchargées vers le disque |
| `operations.pageOuts.rate.avg` | number | pages/s | Taux moyen de déchargement de pages |
| `operations.pageOuts.rate.peak` | number | pages/s | Taux maximal de déchargement de pages |
| `operations.pageReplacements.total` | number | - | Nombre total de remplacements de pages |
| `operations.pageReplacements.algorithm` | string | - | Algorithme de remplacement de pages utilisé |
| `operations.pageReplacements.efficiency` | number | - | Efficacité de l'algorithme de remplacement (0-1) |
| `operations.pageReclaims.total` | number | - | Nombre total de récupérations de pages |
| `operations.pageReclaims.rate.avg` | number | pages/s | Taux moyen de récupération de pages |
| `operations.pageReclaims.rate.peak` | number | pages/s | Taux maximal de récupération de pages |

### 3.5 Performance de la pagination

```json
{
  "paging": {
    "performance": {
      "latency": {
        "minorFault": {
          "avg": 0.01,
          "min": 0.005,
          "max": 0.1,
          "p90": 0.02,
          "p99": 0.05
        },
        "majorFault": {
          "avg": 15.0,
          "min": 5.0,
          "max": 100.0,
          "p90": 30.0,
          "p99": 50.0
        },
        "pageIn": {
          "avg": 10.0,
          "min": 3.0,
          "max": 80.0,
          "p90": 20.0,
          "p99": 40.0
        },
        "pageOut": {
          "avg": 8.0,
          "min": 2.0,
          "max": 60.0,
          "p90": 15.0,
          "p99": 30.0
        }
      },
      "throughput": {
        "pageIn": {
          "avg": 20.0,
          "peak": 100.0
        },
        "pageOut": {
          "avg": 15.0,
          "peak": 80.0
        }
      },
      "impact": {
        "cpuUtilization": 5.0,
        "ioUtilization": 15.0,
        "responseTimeIncrease": 8.0
      }
    }
  }
}
```

| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `performance.latency.minorFault.avg` | number | ms | Latence moyenne d'un défaut de page mineur |
| `performance.latency.minorFault.min` | number | ms | Latence minimale d'un défaut de page mineur |
| `performance.latency.minorFault.max` | number | ms | Latence maximale d'un défaut de page mineur |
| `performance.latency.minorFault.p90` | number | ms | 90e percentile de la latence d'un défaut de page mineur |
| `performance.latency.minorFault.p99` | number | ms | 99e percentile de la latence d'un défaut de page mineur |
| `performance.latency.majorFault.avg` | number | ms | Latence moyenne d'un défaut de page majeur |
| `performance.latency.majorFault.min` | number | ms | Latence minimale d'un défaut de page majeur |
| `performance.latency.majorFault.max` | number | ms | Latence maximale d'un défaut de page majeur |
| `performance.latency.majorFault.p90` | number | ms | 90e percentile de la latence d'un défaut de page majeur |
| `performance.latency.majorFault.p99` | number | ms | 99e percentile de la latence d'un défaut de page majeur |
| `performance.latency.pageIn.avg` | number | ms | Latence moyenne d'un chargement de page |
| `performance.latency.pageIn.min` | number | ms | Latence minimale d'un chargement de page |
| `performance.latency.pageIn.max` | number | ms | Latence maximale d'un chargement de page |
| `performance.latency.pageIn.p90` | number | ms | 90e percentile de la latence d'un chargement de page |
| `performance.latency.pageIn.p99` | number | ms | 99e percentile de la latence d'un chargement de page |
| `performance.latency.pageOut.avg` | number | ms | Latence moyenne d'un déchargement de page |
| `performance.latency.pageOut.min` | number | ms | Latence minimale d'un déchargement de page |
| `performance.latency.pageOut.max` | number | ms | Latence maximale d'un déchargement de page |
| `performance.latency.pageOut.p90` | number | ms | 90e percentile de la latence d'un déchargement de page |
| `performance.latency.pageOut.p99` | number | ms | 99e percentile de la latence d'un déchargement de page |
| `performance.throughput.pageIn.avg` | number | MB/s | Débit moyen de chargement de pages |
| `performance.throughput.pageIn.peak` | number | MB/s | Débit maximal de chargement de pages |
| `performance.throughput.pageOut.avg` | number | MB/s | Débit moyen de déchargement de pages |
| `performance.throughput.pageOut.peak` | number | MB/s | Débit maximal de déchargement de pages |
| `performance.impact.cpuUtilization` | number | % | Impact de la pagination sur l'utilisation CPU |
| `performance.impact.ioUtilization` | number | % | Impact de la pagination sur l'utilisation I/O |
| `performance.impact.responseTimeIncrease` | number | % | Augmentation du temps de réponse due à la pagination |

## 4. Métriques avancées

### 4.1 Localité des pages

```json
{
  "paging": {
    "locality": {
      "spatialLocality": {
        "score": 0.75,
        "consecutiveAccesses": 80.0
      },
      "temporalLocality": {
        "score": 0.85,
        "reuseDistance": {
          "avg": 1000,
          "median": 500,
          "p90": 5000
        }
      },
      "workingSetSize": {
        "current": 524288000,
        "min": 262144000,
        "max": 786432000,
        "optimal": 524288000
      },
      "accessPattern": {
        "sequential": 70.0,
        "random": 20.0,
        "mixed": 10.0
      }
    }
  }
}
```

| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `locality.spatialLocality.score` | number | - | Score de localité spatiale (0-1, où 1 est optimal) |
| `locality.spatialLocality.consecutiveAccesses` | number | % | Pourcentage d'accès à des pages consécutives |
| `locality.temporalLocality.score` | number | - | Score de localité temporelle (0-1, où 1 est optimal) |
| `locality.temporalLocality.reuseDistance.avg` | number | - | Distance moyenne de réutilisation des pages |
| `locality.temporalLocality.reuseDistance.median` | number | - | Distance médiane de réutilisation des pages |
| `locality.temporalLocality.reuseDistance.p90` | number | - | 90e percentile de la distance de réutilisation des pages |
| `locality.workingSetSize.current` | number | octets | Taille actuelle du working set |
| `locality.workingSetSize.min` | number | octets | Taille minimale du working set observée |
| `locality.workingSetSize.max` | number | octets | Taille maximale du working set observée |
| `locality.workingSetSize.optimal` | number | octets | Taille optimale estimée du working set |
| `locality.accessPattern.sequential` | number | % | Pourcentage d'accès séquentiels |
| `locality.accessPattern.random` | number | % | Pourcentage d'accès aléatoires |
| `locality.accessPattern.mixed` | number | % | Pourcentage d'accès mixtes |

### 4.2 Thrashing

```json
{
  "paging": {
    "thrashing": {
      "detected": true,
      "severity": 0.65,
      "duration": 120000,
      "startTime": "2025-05-15T10:02:30.000Z",
      "endTime": "2025-05-15T10:04:30.000Z",
      "pageFaultRate": 5000,
      "cpuUtilization": 15.0,
      "memoryPressure": 0.95,
      "impactScore": 0.8
    }
  }
}
```

| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `thrashing.detected` | boolean | - | Indique si un thrashing a été détecté |
| `thrashing.severity` | number | - | Sévérité du thrashing (0-1, où 1 est le plus sévère) |
| `thrashing.duration` | number | ms | Durée du thrashing |
| `thrashing.startTime` | string | - | Heure de début du thrashing (ISO 8601) |
| `thrashing.endTime` | string | - | Heure de fin du thrashing (ISO 8601) |
| `thrashing.pageFaultRate` | number | défauts/s | Taux de défauts de page pendant le thrashing |
| `thrashing.cpuUtilization` | number | % | Utilisation CPU pendant le thrashing |
| `thrashing.memoryPressure` | number | - | Pression mémoire pendant le thrashing (0-1) |
| `thrashing.impactScore` | number | - | Score d'impact du thrashing sur les performances (0-1) |

### 4.3 Optimisations de pagination

```json
{
  "paging": {
    "optimizations": {
      "prefetching": {
        "enabled": true,
        "algorithm": "adaptive",
        "pagesPerFetch": 4,
        "hitRate": 0.75,
        "accuracy": 0.8
      },
      "compression": {
        "enabled": true,
        "algorithm": "lz4",
        "ratio": 2.5,
        "pagesCompressed": 50000,
        "memoryGained": 153600000
      },
      "prioritization": {
        "enabled": true,
        "algorithm": "lru-k",
        "efficiency": 0.85
      },
      "largePages": {
        "enabled": true,
        "coverage": 0.4,
        "tlbHitRateImprovement": 0.25
      }
    }
  }
}
```

| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `optimizations.prefetching.enabled` | boolean | - | Indique si le préchargement de pages est activé |
| `optimizations.prefetching.algorithm` | string | - | Algorithme de préchargement utilisé |
| `optimizations.prefetching.pagesPerFetch` | number | - | Nombre de pages préchargées par défaut de page |
| `optimizations.prefetching.hitRate` | number | - | Taux de succès du préchargement (0-1) |
| `optimizations.prefetching.accuracy` | number | - | Précision du préchargement (0-1) |
| `optimizations.compression.enabled` | boolean | - | Indique si la compression de pages est activée |
| `optimizations.compression.algorithm` | string | - | Algorithme de compression utilisé |
| `optimizations.compression.ratio` | number | - | Ratio de compression moyen |
| `optimizations.compression.pagesCompressed` | number | - | Nombre de pages compressées |
| `optimizations.compression.memoryGained` | number | octets | Mémoire économisée grâce à la compression |
| `optimizations.prioritization.enabled` | boolean | - | Indique si la priorisation de pages est activée |
| `optimizations.prioritization.algorithm` | string | - | Algorithme de priorisation utilisé |
| `optimizations.prioritization.efficiency` | number | - | Efficacité de la priorisation (0-1) |
| `optimizations.largePages.enabled` | boolean | - | Indique si l'utilisation de grandes pages est activée |
| `optimizations.largePages.coverage` | number | - | Proportion de la mémoire utilisant de grandes pages (0-1) |
| `optimizations.largePages.tlbHitRateImprovement` | number | - | Amélioration du taux de succès du TLB grâce aux grandes pages |

## 5. Exemples

### 5.1 Exemple minimal

```json
{
  "memory": {
    "paging": {
      "system": {
        "pageSize": 4096,
        "totalPages": 4194304,
        "swapFileSize": 17179869184
      },
      "pages": {
        "total": 256000,
        "resident": 128000,
        "nonresident": 128000
      },
      "pageFaults": {
        "total": 105000,
        "minor": 100000,
        "major": 5000
      }
    }
  }
}
```

### 5.2 Exemple complet

```json
{
  "memory": {
    "paging": {
      "system": {
        "pageSize": 4096,
        "largePageSize": 2097152,
        "totalPages": 4194304,
        "swapFileSize": 17179869184,
        "swapFileUsed": 2147483648,
        "swapFileAvailable": 15032385536,
        "swapFileLocation": "C:\\pagefile.sys",
        "minWorkingSetSize": 204800,
        "maxWorkingSetSize": 1073741824
      },
      
      "pages": {
        "total": 256000,
        "resident": 128000,
        "nonresident": 128000,
        "shared": 50000,
        "private": 206000,
        "readOnly": 80000,
        "readWrite": 176000,
        "executable": 30000,
        "largePages": {
          "count": 50,
          "totalSize": 104857600
        }
      },
      
      "pageFaults": {
        "total": 105000,
        "minor": 100000,
        "major": 5000,
        "copyOnWrite": 20000,
        "rate": {
          "avg": 1050,
          "peak": 5000,
          "byPhase": {
            "initialization": 2000,
            "dataLoading": 3000,
            "processing": 500,
            "cleanup": 100
          }
        },
        "timeSeries": {
          "interval": 1000,
          "unit": "ms",
          "samples": [
            {
              "timestamp": "2025-05-15T10:00:10.000Z",
              "minor": 1000,
              "major": 50
            },
            {
              "timestamp": "2025-05-15T10:00:11.000Z",
              "minor": 1500,
              "major": 75
            },
            {
              "timestamp": "2025-05-15T10:00:12.000Z",
              "minor": 1200,
              "major": 60
            }
          ]
        }
      },
      
      "operations": {
        "pageIns": {
          "total": 5000,
          "size": 20480000,
          "rate": {
            "avg": 50,
            "peak": 200
          }
        },
        "pageOuts": {
          "total": 3000,
          "size": 12288000,
          "rate": {
            "avg": 30,
            "peak": 150
          }
        },
        "pageReplacements": {
          "total": 2500,
          "algorithm": "LRU",
          "efficiency": 0.85
        },
        "pageReclaims": {
          "total": 1500,
          "rate": {
            "avg": 15,
            "peak": 100
          }
        }
      },
      
      "performance": {
        "latency": {
          "minorFault": {
            "avg": 0.01,
            "min": 0.005,
            "max": 0.1,
            "p90": 0.02,
            "p99": 0.05
          },
          "majorFault": {
            "avg": 15.0,
            "min": 5.0,
            "max": 100.0,
            "p90": 30.0,
            "p99": 50.0
          },
          "pageIn": {
            "avg": 10.0,
            "min": 3.0,
            "max": 80.0,
            "p90": 20.0,
            "p99": 40.0
          },
          "pageOut": {
            "avg": 8.0,
            "min": 2.0,
            "max": 60.0,
            "p90": 15.0,
            "p99": 30.0
          }
        },
        "throughput": {
          "pageIn": {
            "avg": 20.0,
            "peak": 100.0
          },
          "pageOut": {
            "avg": 15.0,
            "peak": 80.0
          }
        },
        "impact": {
          "cpuUtilization": 5.0,
          "ioUtilization": 15.0,
          "responseTimeIncrease": 8.0
        }
      },
      
      "locality": {
        "spatialLocality": {
          "score": 0.75,
          "consecutiveAccesses": 80.0
        },
        "temporalLocality": {
          "score": 0.85,
          "reuseDistance": {
            "avg": 1000,
            "median": 500,
            "p90": 5000
          }
        },
        "workingSetSize": {
          "current": 524288000,
          "min": 262144000,
          "max": 786432000,
          "optimal": 524288000
        },
        "accessPattern": {
          "sequential": 70.0,
          "random": 20.0,
          "mixed": 10.0
        }
      },
      
      "thrashing": {
        "detected": true,
        "severity": 0.65,
        "duration": 120000,
        "startTime": "2025-05-15T10:02:30.000Z",
        "endTime": "2025-05-15T10:04:30.000Z",
        "pageFaultRate": 5000,
        "cpuUtilization": 15.0,
        "memoryPressure": 0.95,
        "impactScore": 0.8
      },
      
      "optimizations": {
        "prefetching": {
          "enabled": true,
          "algorithm": "adaptive",
          "pagesPerFetch": 4,
          "hitRate": 0.75,
          "accuracy": 0.8
        },
        "compression": {
          "enabled": true,
          "algorithm": "lz4",
          "ratio": 2.5,
          "pagesCompressed": 50000,
          "memoryGained": 153600000
        },
        "prioritization": {
          "enabled": true,
          "algorithm": "lru-k",
          "efficiency": 0.85
        },
        "largePages": {
          "enabled": true,
          "coverage": 0.4,
          "tlbHitRateImprovement": 0.25
        }
      }
    }
  }
}
```

## 6. Bonnes pratiques

### 6.1 Collecte des métriques

- Collecter les métriques de pagination à intervalles réguliers
- Adapter la fréquence d'échantillonnage à la durée du test
- Utiliser des outils de profilage système pour les mesures détaillées
- Surveiller particulièrement les défauts de page majeurs et le thrashing
- Mesurer l'impact de la pagination sur les performances globales

### 6.2 Analyse des métriques

- Comparer les métriques de pagination avec les références établies
- Analyser les tendances de défauts de page au fil du temps
- Identifier les périodes de thrashing et leurs causes
- Corréler les défauts de page avec les opérations spécifiques du test
- Examiner la localité des pages pour optimiser les accès mémoire

### 6.3 Optimisation

- Ajuster la taille du working set pour réduire les défauts de page
- Utiliser des grandes pages pour les allocations importantes et stables
- Optimiser la localité spatiale et temporelle des accès mémoire
- Précharger les données fréquemment utilisées pour éviter les défauts de page
- Ajuster les paramètres du système de pagination en fonction des résultats

### 6.4 Reporting

- Inclure des graphiques de défauts de page dans les rapports
- Mettre en évidence les périodes de thrashing et leur impact
- Comparer les métriques de pagination avec d'autres métriques système
- Fournir des recommandations basées sur l'analyse des métriques
- Documenter les configurations optimales pour différents scénarios de test
