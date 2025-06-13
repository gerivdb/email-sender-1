# Métriques de mémoire virtuelle

## 1. Vue d'ensemble

Les métriques de mémoire virtuelle représentent les mesures liées à l'utilisation de l'espace d'adressage virtuel par le système et les processus testés. La mémoire virtuelle est une abstraction qui permet aux processus de disposer d'un espace d'adressage plus grand que la mémoire physique disponible, en utilisant le stockage secondaire (généralement le disque) comme extension de la mémoire RAM.

## 2. Structure de base

Les métriques de mémoire virtuelle sont organisées dans une structure hiérarchique qui permet de capturer différents aspects de l'utilisation de la mémoire virtuelle. La structure de base est la suivante :

```json
{
  "memory": {
    "virtual": {
      // Métriques de mémoire virtuelle
    }
  }
}
```plaintext
## 3. Métriques principales

### 3.1 Utilisation globale

```json
{
  "virtual": {
    "total": 140737488355328,
    "available": 140736439615488,
    "used": 1048739840,
    "usedByProcess": 734003200,
    "percentUsed": 0.0007,
    "percentUsedByProcess": 0.0005,
    "committed": 8589934592,
    "reserved": 17179869184
  }
}
```plaintext
| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `total` | number | octets | Taille totale de l'espace d'adressage virtuel disponible |
| `available` | number | octets | Espace d'adressage virtuel disponible pour allocation |
| `used` | number | octets | Espace d'adressage virtuel utilisé par le système |
| `usedByProcess` | number | octets | Espace d'adressage virtuel utilisé par le processus testé |
| `percentUsed` | number | pourcentage | Pourcentage d'espace d'adressage virtuel utilisé par le système |
| `percentUsedByProcess` | number | pourcentage | Pourcentage d'espace d'adressage virtuel utilisé par le processus testé |
| `committed` | number | octets | Mémoire virtuelle engagée (garantie d'être disponible) |
| `reserved` | number | octets | Mémoire virtuelle réservée mais non engagée |

### 3.2 Mesures statistiques

```json
{
  "virtual": {
    "statistics": {
      "min": 500000000,
      "max": 1500000000,
      "avg": 1000000000,
      "median": 950000000,
      "stdDev": 250000000,
      "p90": 1300000000,
      "p95": 1400000000,
      "p99": 1480000000
    }
  }
}
```plaintext
| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `min` | number | octets | Utilisation minimale de mémoire virtuelle pendant le test |
| `max` | number | octets | Utilisation maximale de mémoire virtuelle pendant le test |
| `avg` | number | octets | Utilisation moyenne de mémoire virtuelle pendant le test |
| `median` | number | octets | Médiane de l'utilisation de mémoire virtuelle pendant le test |
| `stdDev` | number | octets | Écart-type de l'utilisation de mémoire virtuelle |
| `p90` | number | octets | 90e percentile de l'utilisation de mémoire virtuelle |
| `p95` | number | octets | 95e percentile de l'utilisation de mémoire virtuelle |
| `p99` | number | octets | 99e percentile de l'utilisation de mémoire virtuelle |

### 3.3 Série temporelle

```json
{
  "virtual": {
    "timeSeries": {
      "interval": 1000,
      "unit": "ms",
      "samples": [
        {
          "timestamp": "2025-05-15T10:00:10.000Z",
          "value": 600000000
        },
        {
          "timestamp": "2025-05-15T10:00:11.000Z",
          "value": 750000000
        },
        {
          "timestamp": "2025-05-15T10:00:12.000Z",
          "value": 900000000
        },
        // ... autres échantillons
      ]
    }
  }
}
```plaintext
| Champ | Type | Description |
|-------|------|-------------|
| `interval` | number | Intervalle d'échantillonnage en millisecondes |
| `unit` | string | Unité de l'intervalle d'échantillonnage (ms, s, etc.) |
| `samples` | array | Liste des échantillons de mémoire virtuelle |
| `samples[].timestamp` | string | Horodatage de l'échantillon (ISO 8601) |
| `samples[].value` | number | Valeur de l'utilisation de mémoire virtuelle en octets |

### 3.4 Allocation et mappage

```json
{
  "virtual": {
    "allocation": {
      "total": 2000000000,
      "count": 2500,
      "avgSize": 800000,
      "maxSize": 100000000,
      "rate": {
        "avg": 250,
        "peak": 1000
      }
    },
    "deallocation": {
      "total": 1500000000,
      "count": 2000,
      "avgSize": 750000,
      "rate": {
        "avg": 200,
        "peak": 800
      }
    },
    "mapping": {
      "filesMapped": 25,
      "totalMappedSize": 500000000,
      "largestMapping": 100000000,
      "avgMappingSize": 20000000
    }
  }
}
```plaintext
| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `allocation.total` | number | octets | Quantité totale de mémoire virtuelle allouée pendant le test |
| `allocation.count` | number | - | Nombre total d'allocations de mémoire virtuelle |
| `allocation.avgSize` | number | octets | Taille moyenne des allocations de mémoire virtuelle |
| `allocation.maxSize` | number | octets | Taille maximale d'une allocation de mémoire virtuelle |
| `allocation.rate.avg` | number | allocations/s | Taux moyen d'allocations par seconde |
| `allocation.rate.peak` | number | allocations/s | Taux maximal d'allocations par seconde |
| `deallocation.total` | number | octets | Quantité totale de mémoire virtuelle libérée pendant le test |
| `deallocation.count` | number | - | Nombre total de libérations de mémoire virtuelle |
| `deallocation.avgSize` | number | octets | Taille moyenne des libérations de mémoire virtuelle |
| `deallocation.rate.avg` | number | libérations/s | Taux moyen de libérations par seconde |
| `deallocation.rate.peak` | number | libérations/s | Taux maximal de libérations par seconde |
| `mapping.filesMapped` | number | - | Nombre de fichiers mappés en mémoire |
| `mapping.totalMappedSize` | number | octets | Taille totale des fichiers mappés en mémoire |
| `mapping.largestMapping` | number | octets | Taille du plus grand fichier mappé en mémoire |
| `mapping.avgMappingSize` | number | octets | Taille moyenne des fichiers mappés en mémoire |

### 3.5 Utilisation par région

```json
{
  "virtual": {
    "byRegion": {
      "code": {
        "size": 50000000,
        "percentOfTotal": 5.0
      },
      "stack": {
        "size": 20000000,
        "percentOfTotal": 2.0
      },
      "heap": {
        "size": 500000000,
        "percentOfTotal": 50.0
      },
      "mappedFiles": {
        "size": 400000000,
        "percentOfTotal": 40.0
      },
      "other": {
        "size": 30000000,
        "percentOfTotal": 3.0
      }
    }
  }
}
```plaintext
| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `byRegion.<region>.size` | number | octets | Taille de la région de mémoire virtuelle |
| `byRegion.<region>.percentOfTotal` | number | pourcentage | Pourcentage de l'utilisation totale de mémoire virtuelle par la région |

### 3.6 Métriques de pagination

```json
{
  "virtual": {
    "paging": {
      "pageSize": 4096,
      "totalPages": 256000,
      "residentPages": 128000,
      "nonresidentPages": 128000,
      "pageIns": 50000,
      "pageOuts": 30000,
      "pageFaults": {
        "minor": 100000,
        "major": 5000,
        "rate": {
          "avg": 1050,
          "peak": 5000
        }
      },
      "pageReplacement": {
        "algorithm": "LRU",
        "efficiency": 0.85
      }
    }
  }
}
```plaintext
| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `paging.pageSize` | number | octets | Taille d'une page mémoire |
| `paging.totalPages` | number | - | Nombre total de pages mémoire utilisées |
| `paging.residentPages` | number | - | Nombre de pages mémoire résidentes en RAM |
| `paging.nonresidentPages` | number | - | Nombre de pages mémoire non résidentes (sur disque) |
| `paging.pageIns` | number | - | Nombre de pages chargées depuis le disque |
| `paging.pageOuts` | number | - | Nombre de pages déchargées vers le disque |
| `paging.pageFaults.minor` | number | - | Nombre de défauts de page mineurs (page en mémoire) |
| `paging.pageFaults.major` | number | - | Nombre de défauts de page majeurs (page sur disque) |
| `paging.pageFaults.rate.avg` | number | défauts/s | Taux moyen de défauts de page |
| `paging.pageFaults.rate.peak` | number | défauts/s | Taux maximal de défauts de page |
| `paging.pageReplacement.algorithm` | string | - | Algorithme de remplacement de page utilisé |
| `paging.pageReplacement.efficiency` | number | - | Efficacité de l'algorithme de remplacement de page (0-1) |

## 4. Métriques avancées

### 4.1 Fragmentation de l'espace d'adressage

```json
{
  "virtual": {
    "addressSpaceFragmentation": {
      "index": 0.35,
      "largestFreeRegion": 1073741824,
      "freeRegionsCount": 250,
      "avgFreeRegionSize": 50000000,
      "allocFailuresDueToFragmentation": 10
    }
  }
}
```plaintext
| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `addressSpaceFragmentation.index` | number | - | Indice de fragmentation de l'espace d'adressage (0-1, où 1 est très fragmenté) |
| `addressSpaceFragmentation.largestFreeRegion` | number | octets | Taille de la plus grande région libre dans l'espace d'adressage |
| `addressSpaceFragmentation.freeRegionsCount` | number | - | Nombre de régions libres dans l'espace d'adressage |
| `addressSpaceFragmentation.avgFreeRegionSize` | number | octets | Taille moyenne des régions libres dans l'espace d'adressage |
| `addressSpaceFragmentation.allocFailuresDueToFragmentation` | number | - | Nombre d'échecs d'allocation dus à la fragmentation de l'espace d'adressage |

### 4.2 Protection mémoire

```json
{
  "virtual": {
    "protection": {
      "byPermission": {
        "readOnly": {
          "size": 200000000,
          "percentOfTotal": 20.0
        },
        "readWrite": {
          "size": 700000000,
          "percentOfTotal": 70.0
        },
        "execute": {
          "size": 50000000,
          "percentOfTotal": 5.0
        },
        "executeRead": {
          "size": 30000000,
          "percentOfTotal": 3.0
        },
        "executeReadWrite": {
          "size": 20000000,
          "percentOfTotal": 2.0
        }
      },
      "accessViolations": {
        "total": 15,
        "byType": {
          "readViolation": 5,
          "writeViolation": 8,
          "executeViolation": 2
        }
      }
    }
  }
}
```plaintext
| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `protection.byPermission.<permission>.size` | number | octets | Taille de la mémoire avec les permissions spécifiées |
| `protection.byPermission.<permission>.percentOfTotal` | number | pourcentage | Pourcentage de la mémoire avec les permissions spécifiées |
| `protection.accessViolations.total` | number | - | Nombre total de violations d'accès mémoire |
| `protection.accessViolations.byType.<type>` | number | - | Nombre de violations d'accès mémoire par type |

### 4.3 Métriques de performance de la mémoire virtuelle

```json
{
  "virtual": {
    "performance": {
      "commitLatency": {
        "avg": 0.5,
        "max": 5.0
      },
      "decommitLatency": {
        "avg": 0.3,
        "max": 3.0
      },
      "allocationLatency": {
        "avg": 0.2,
        "max": 2.0
      },
      "mappingLatency": {
        "avg": 1.5,
        "max": 10.0
      },
      "pageFaultLatency": {
        "minor": {
          "avg": 0.01,
          "max": 0.1
        },
        "major": {
          "avg": 15.0,
          "max": 100.0
        }
      }
    }
  }
}
```plaintext
| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `performance.commitLatency.avg` | number | ms | Latence moyenne pour engager de la mémoire virtuelle |
| `performance.commitLatency.max` | number | ms | Latence maximale pour engager de la mémoire virtuelle |
| `performance.decommitLatency.avg` | number | ms | Latence moyenne pour désengager de la mémoire virtuelle |
| `performance.decommitLatency.max` | number | ms | Latence maximale pour désengager de la mémoire virtuelle |
| `performance.allocationLatency.avg` | number | ms | Latence moyenne pour allouer de la mémoire virtuelle |
| `performance.allocationLatency.max` | number | ms | Latence maximale pour allouer de la mémoire virtuelle |
| `performance.mappingLatency.avg` | number | ms | Latence moyenne pour mapper un fichier en mémoire |
| `performance.mappingLatency.max` | number | ms | Latence maximale pour mapper un fichier en mémoire |
| `performance.pageFaultLatency.minor.avg` | number | ms | Latence moyenne pour un défaut de page mineur |
| `performance.pageFaultLatency.minor.max` | number | ms | Latence maximale pour un défaut de page mineur |
| `performance.pageFaultLatency.major.avg` | number | ms | Latence moyenne pour un défaut de page majeur |
| `performance.pageFaultLatency.major.max` | number | ms | Latence maximale pour un défaut de page majeur |

## 5. Exemples

### 5.1 Exemple minimal

```json
{
  "memory": {
    "virtual": {
      "total": 140737488355328,
      "available": 140736439615488,
      "used": 1048739840,
      "usedByProcess": 734003200,
      "percentUsed": 0.0007,
      "percentUsedByProcess": 0.0005,
      "statistics": {
        "min": 500000000,
        "max": 1500000000,
        "avg": 1000000000
      }
    }
  }
}
```plaintext
### 5.2 Exemple complet

```json
{
  "memory": {
    "virtual": {
      "total": 140737488355328,
      "available": 140736439615488,
      "used": 1048739840,
      "usedByProcess": 734003200,
      "percentUsed": 0.0007,
      "percentUsedByProcess": 0.0005,
      "committed": 8589934592,
      "reserved": 17179869184,
      
      "statistics": {
        "min": 500000000,
        "max": 1500000000,
        "avg": 1000000000,
        "median": 950000000,
        "stdDev": 250000000,
        "p90": 1300000000,
        "p95": 1400000000,
        "p99": 1480000000
      },
      
      "timeSeries": {
        "interval": 1000,
        "unit": "ms",
        "samples": [
          {
            "timestamp": "2025-05-15T10:00:10.000Z",
            "value": 600000000
          },
          {
            "timestamp": "2025-05-15T10:00:11.000Z",
            "value": 750000000
          },
          {
            "timestamp": "2025-05-15T10:00:12.000Z",
            "value": 900000000
          },
          {
            "timestamp": "2025-05-15T10:00:13.000Z",
            "value": 1100000000
          },
          {
            "timestamp": "2025-05-15T10:00:14.000Z",
            "value": 1300000000
          }
        ]
      },
      
      "allocation": {
        "total": 2000000000,
        "count": 2500,
        "avgSize": 800000,
        "maxSize": 100000000,
        "rate": {
          "avg": 250,
          "peak": 1000
        }
      },
      
      "deallocation": {
        "total": 1500000000,
        "count": 2000,
        "avgSize": 750000,
        "rate": {
          "avg": 200,
          "peak": 800
        }
      },
      
      "mapping": {
        "filesMapped": 25,
        "totalMappedSize": 500000000,
        "largestMapping": 100000000,
        "avgMappingSize": 20000000
      },
      
      "byRegion": {
        "code": {
          "size": 50000000,
          "percentOfTotal": 5.0
        },
        "stack": {
          "size": 20000000,
          "percentOfTotal": 2.0
        },
        "heap": {
          "size": 500000000,
          "percentOfTotal": 50.0
        },
        "mappedFiles": {
          "size": 400000000,
          "percentOfTotal": 40.0
        },
        "other": {
          "size": 30000000,
          "percentOfTotal": 3.0
        }
      },
      
      "paging": {
        "pageSize": 4096,
        "totalPages": 256000,
        "residentPages": 128000,
        "nonresidentPages": 128000,
        "pageIns": 50000,
        "pageOuts": 30000,
        "pageFaults": {
          "minor": 100000,
          "major": 5000,
          "rate": {
            "avg": 1050,
            "peak": 5000
          }
        },
        "pageReplacement": {
          "algorithm": "LRU",
          "efficiency": 0.85
        }
      },
      
      "addressSpaceFragmentation": {
        "index": 0.35,
        "largestFreeRegion": 1073741824,
        "freeRegionsCount": 250,
        "avgFreeRegionSize": 50000000,
        "allocFailuresDueToFragmentation": 10
      },
      
      "protection": {
        "byPermission": {
          "readOnly": {
            "size": 200000000,
            "percentOfTotal": 20.0
          },
          "readWrite": {
            "size": 700000000,
            "percentOfTotal": 70.0
          },
          "execute": {
            "size": 50000000,
            "percentOfTotal": 5.0
          },
          "executeRead": {
            "size": 30000000,
            "percentOfTotal": 3.0
          },
          "executeReadWrite": {
            "size": 20000000,
            "percentOfTotal": 2.0
          }
        },
        "accessViolations": {
          "total": 15,
          "byType": {
            "readViolation": 5,
            "writeViolation": 8,
            "executeViolation": 2
          }
        }
      },
      
      "performance": {
        "commitLatency": {
          "avg": 0.5,
          "max": 5.0
        },
        "decommitLatency": {
          "avg": 0.3,
          "max": 3.0
        },
        "allocationLatency": {
          "avg": 0.2,
          "max": 2.0
        },
        "mappingLatency": {
          "avg": 1.5,
          "max": 10.0
        },
        "pageFaultLatency": {
          "minor": {
            "avg": 0.01,
            "max": 0.1
          },
          "major": {
            "avg": 15.0,
            "max": 100.0
          }
        }
      }
    }
  }
}
```plaintext
## 6. Bonnes pratiques

### 6.1 Collecte des métriques

- Collecter les métriques de mémoire virtuelle à intervalles réguliers
- Adapter la fréquence d'échantillonnage à la durée du test
- Utiliser des outils de profilage mémoire pour les mesures détaillées
- Surveiller particulièrement les défauts de page et les accès au fichier d'échange
- Mesurer l'utilisation de mémoire virtuelle avant et après chaque phase importante du test

### 6.2 Analyse des métriques

- Comparer l'utilisation de mémoire virtuelle avec les références établies
- Analyser les tendances d'utilisation de mémoire virtuelle au fil du temps
- Identifier les fuites potentielles en surveillant la croissance de l'espace d'adressage
- Corréler les défauts de page avec les activités spécifiques du test
- Examiner la fragmentation de l'espace d'adressage pour les tests de longue durée

### 6.3 Optimisation

- Optimiser les allocations pour réduire la fragmentation de l'espace d'adressage
- Utiliser des mappages de fichiers pour les données partagées ou volumineuses
- Ajuster les permissions de mémoire en fonction des besoins réels
- Optimiser l'utilisation des pages pour réduire les défauts de page
- Précharger les données fréquemment utilisées pour éviter les défauts de page majeurs

### 6.4 Reporting

- Inclure des graphiques d'utilisation de mémoire virtuelle dans les rapports
- Mettre en évidence les anomalies et les tendances importantes
- Comparer les métriques de mémoire virtuelle avec les métriques de mémoire physique
- Fournir des recommandations basées sur l'analyse des métriques
- Documenter les configurations optimales pour différents scénarios de test
