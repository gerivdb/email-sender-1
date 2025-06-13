# Métriques de latence pour les caches matériels

## 1. Vue d'ensemble

Les métriques de latence pour les caches matériels mesurent le temps nécessaire pour accéder aux données dans les différents niveaux de cache du processeur. Ces métriques sont cruciales pour comprendre les performances du système de mémoire et identifier les goulots d'étranglement potentiels. Ce document définit les métriques de latence pour les caches matériels (L1, L2, L3, etc.) et leur structure dans le cadre des résultats de test.

## 2. Définitions fondamentales

### 2.1 Terminologie de base

- **Latence d'accès** : Temps écoulé entre le moment où une requête d'accès au cache est émise et le moment où les données sont disponibles.
- **Latence en cas de succès (Hit Latency)** : Temps d'accès lorsque les données sont trouvées dans le cache.
- **Latence en cas d'échec (Miss Latency)** : Temps d'accès lorsque les données ne sont pas trouvées dans le cache et doivent être récupérées depuis un niveau de mémoire plus lent.
- **Pénalité d'échec (Miss Penalty)** : Temps supplémentaire nécessaire pour récupérer les données en cas d'échec de cache, par rapport à un succès.
- **Cycle d'horloge** : Unité de temps fondamentale du processeur, souvent utilisée pour mesurer la latence.

### 2.2 Unités de mesure

- **Cycles d'horloge** : Nombre de cycles du processeur nécessaires pour accéder aux données.
- **Nanosecondes (ns)** : Mesure absolue du temps, indépendante de la fréquence du processeur.
- **Ratio de latence** : Rapport entre les latences de différents niveaux de cache.

## 3. Structure des métriques de latence pour les caches matériels

### 3.1 Structure générale

```json
{
  "latency": {
    "unit": "cycles",
    "hit": {
      // Latence en cas de succès
    },
    "miss": {
      // Latence en cas d'échec
    },
    "penalty": {
      // Pénalité d'échec
    },
    "distribution": {
      // Distribution statistique
    },
    "timeSeries": {
      // Évolution temporelle
    }
  }
}
```plaintext
### 3.2 Métriques de latence en cas de succès

```json
{
  "latency": {
    "hit": {
      "min": 3,
      "max": 8,
      "avg": 4.2,
      "median": 4,
      "p90": 6,
      "p99": 7,
      "byAccessType": {
        "read": 4.0,
        "write": 4.5,
        "instruction": 3.8,
        "data": 4.5
      },
      "byDataSize": {
        "32bit": 3.5,
        "64bit": 4.0,
        "128bit": 4.8,
        "256bit": 5.5
      }
    }
  }
}
```plaintext
| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `min` | number | cycles/ns | Latence minimale en cas de succès |
| `max` | number | cycles/ns | Latence maximale en cas de succès |
| `avg` | number | cycles/ns | Latence moyenne en cas de succès |
| `median` | number | cycles/ns | Latence médiane en cas de succès |
| `p90` | number | cycles/ns | 90e percentile de la latence en cas de succès |
| `p99` | number | cycles/ns | 99e percentile de la latence en cas de succès |
| `byAccessType` | object | - | Latence par type d'accès |
| `byAccessType.read` | number | cycles/ns | Latence moyenne pour les lectures |
| `byAccessType.write` | number | cycles/ns | Latence moyenne pour les écritures |
| `byAccessType.instruction` | number | cycles/ns | Latence moyenne pour les instructions |
| `byAccessType.data` | number | cycles/ns | Latence moyenne pour les données |
| `byDataSize` | object | - | Latence par taille de données |
| `byDataSize.<size>` | number | cycles/ns | Latence moyenne pour une taille de données spécifique |

### 3.3 Métriques de latence en cas d'échec

```json
{
  "latency": {
    "miss": {
      "min": 12,
      "max": 45,
      "avg": 25.3,
      "median": 22,
      "p90": 35,
      "p99": 42,
      "byMissType": {
        "capacity": 28.5,
        "conflict": 26.2,
        "compulsory": 22.8
      },
      "byNextLevelHit": {
        "l2Hit": 12.5,
        "l3Hit": 28.7,
        "memoryAccess": 120.3
      }
    }
  }
}
```plaintext
| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `min` | number | cycles/ns | Latence minimale en cas d'échec |
| `max` | number | cycles/ns | Latence maximale en cas d'échec |
| `avg` | number | cycles/ns | Latence moyenne en cas d'échec |
| `median` | number | cycles/ns | Latence médiane en cas d'échec |
| `p90` | number | cycles/ns | 90e percentile de la latence en cas d'échec |
| `p99` | number | cycles/ns | 99e percentile de la latence en cas d'échec |
| `byMissType` | object | - | Latence par type d'échec |
| `byMissType.capacity` | number | cycles/ns | Latence moyenne pour les échecs de capacité |
| `byMissType.conflict` | number | cycles/ns | Latence moyenne pour les échecs de conflit |
| `byMissType.compulsory` | number | cycles/ns | Latence moyenne pour les échecs obligatoires |
| `byNextLevelHit` | object | - | Latence par niveau de cache où les données sont trouvées |
| `byNextLevelHit.<level>` | number | cycles/ns | Latence moyenne lorsque les données sont trouvées au niveau spécifié |

### 3.4 Métriques de pénalité d'échec

```json
{
  "latency": {
    "penalty": {
      "avg": 21.1,
      "byMissType": {
        "capacity": 24.5,
        "conflict": 22.2,
        "compulsory": 18.8
      },
      "byNextLevelHit": {
        "l2Hit": 8.5,
        "l3Hit": 24.7,
        "memoryAccess": 116.3
      },
      "relativeToClock": 10.55,
      "relativeToHitLatency": 5.02
    }
  }
}
```plaintext
| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `avg` | number | cycles/ns | Pénalité d'échec moyenne |
| `byMissType` | object | - | Pénalité par type d'échec |
| `byMissType.<type>` | number | cycles/ns | Pénalité moyenne pour un type d'échec spécifique |
| `byNextLevelHit` | object | - | Pénalité par niveau de cache où les données sont trouvées |
| `byNextLevelHit.<level>` | number | cycles/ns | Pénalité moyenne lorsque les données sont trouvées au niveau spécifié |
| `relativeToClock` | number | - | Pénalité relative à la période d'horloge |
| `relativeToHitLatency` | number | - | Pénalité relative à la latence en cas de succès |

### 3.5 Distribution statistique

```json
{
  "latency": {
    "distribution": {
      "histogram": [
        {
          "bin": "0-5",
          "count": 15000,
          "percentage": 75.0
        },
        {
          "bin": "6-10",
          "count": 3000,
          "percentage": 15.0
        },
        {
          "bin": "11-20",
          "count": 1500,
          "percentage": 7.5
        },
        {
          "bin": "21-50",
          "count": 400,
          "percentage": 2.0
        },
        {
          "bin": "51+",
          "count": 100,
          "percentage": 0.5
        }
      ],
      "cdf": [
        {
          "value": 5,
          "percentile": 75.0
        },
        {
          "value": 10,
          "percentile": 90.0
        },
        {
          "value": 20,
          "percentile": 97.5
        },
        {
          "value": 50,
          "percentile": 99.5
        },
        {
          "value": 100,
          "percentile": 100.0
        }
      ]
    }
  }
}
```plaintext
| Champ | Type | Description |
|-------|------|-------------|
| `histogram` | array | Histogramme de distribution des latences |
| `histogram[].bin` | string | Plage de valeurs du bin |
| `histogram[].count` | number | Nombre d'échantillons dans ce bin |
| `histogram[].percentage` | number | Pourcentage d'échantillons dans ce bin |
| `cdf` | array | Fonction de distribution cumulative |
| `cdf[].value` | number | Valeur de latence |
| `cdf[].percentile` | number | Pourcentage d'échantillons avec une latence inférieure ou égale à cette valeur |

### 3.6 Série temporelle

```json
{
  "latency": {
    "timeSeries": {
      "interval": 1000,
      "unit": "ms",
      "samples": [
        {
          "timestamp": "2025-05-15T10:00:10.000Z",
          "hit": 4.1,
          "miss": 24.8
        },
        {
          "timestamp": "2025-05-15T10:00:11.000Z",
          "hit": 4.2,
          "miss": 25.3
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
| `samples` | array | Liste des échantillons de latence |
| `samples[].timestamp` | string | Horodatage de l'échantillon (ISO 8601) |
| `samples[].hit` | number | Latence moyenne en cas de succès à cet instant |
| `samples[].miss` | number | Latence moyenne en cas d'échec à cet instant |

## 4. Métriques spécifiques par niveau de cache

### 4.1 Cache L1

```json
{
  "cache": {
    "hardware": {
      "l1": {
        "latency": {
          "unit": "cycles",
          "hit": {
            "avg": 4,
            "byCore": [
              {
                "coreId": 0,
                "avg": 3.9
              },
              {
                "coreId": 1,
                "avg": 4.1
              }
            ],
            "instruction": 3.5,
            "data": 4.5
          },
          "miss": {
            "avg": 12,
            "byNextLevelHit": {
              "l2Hit": 12
            }
          },
          "penalty": {
            "avg": 8
          }
        }
      }
    }
  }
}
```plaintext
| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `unit` | string | - | Unité de mesure de la latence (cycles, ns) |
| `hit.avg` | number | cycles/ns | Latence moyenne en cas de succès |
| `hit.byCore` | array | - | Latence par cœur de processeur |
| `hit.byCore[].coreId` | number | - | Identifiant du cœur |
| `hit.byCore[].avg` | number | cycles/ns | Latence moyenne pour ce cœur |
| `hit.instruction` | number | cycles/ns | Latence moyenne pour le cache d'instructions |
| `hit.data` | number | cycles/ns | Latence moyenne pour le cache de données |
| `miss.avg` | number | cycles/ns | Latence moyenne en cas d'échec |
| `miss.byNextLevelHit` | object | - | Latence par niveau de cache où les données sont trouvées |
| `penalty.avg` | number | cycles/ns | Pénalité d'échec moyenne |

### 4.2 Cache L2

```json
{
  "cache": {
    "hardware": {
      "l2": {
        "latency": {
          "unit": "cycles",
          "hit": {
            "avg": 12,
            "byCore": [
              {
                "coreId": 0,
                "avg": 11.8
              },
              {
                "coreId": 1,
                "avg": 12.2
              }
            ],
            "byAccessType": {
              "read": 11.5,
              "write": 12.5
            }
          },
          "miss": {
            "avg": 28,
            "byNextLevelHit": {
              "l3Hit": 28
            }
          },
          "penalty": {
            "avg": 16
          }
        }
      }
    }
  }
}
```plaintext
### 4.3 Cache L3

```json
{
  "cache": {
    "hardware": {
      "l3": {
        "latency": {
          "unit": "cycles",
          "hit": {
            "avg": 28,
            "byCore": [
              {
                "coreId": 0,
                "avg": 27.5
              },
              {
                "coreId": 1,
                "avg": 28.5
              }
            ],
            "byAccessType": {
              "read": 27.0,
              "write": 29.0
            },
            "bySharing": {
              "exclusive": 26.0,
              "shared": 30.0
            }
          },
          "miss": {
            "avg": 120,
            "byNextLevelHit": {
              "memoryAccess": 120
            }
          },
          "penalty": {
            "avg": 92
          }
        }
      }
    }
  }
}
```plaintext
| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `hit.bySharing.exclusive` | number | cycles/ns | Latence pour les données exclusives à un cœur |
| `hit.bySharing.shared` | number | cycles/ns | Latence pour les données partagées entre cœurs |

### 4.4 TLB (Translation Lookaside Buffer)

```json
{
  "cache": {
    "hardware": {
      "tlb": {
        "latency": {
          "unit": "cycles",
          "hit": {
            "avg": 1,
            "instruction": 0.9,
            "data": 1.1
          },
          "miss": {
            "avg": 30,
            "byPageSize": {
              "4KB": 35,
              "2MB": 25,
              "1GB": 20
            },
            "byPageTableLevel": {
              "level1": 15,
              "level2": 25,
              "level3": 35,
              "level4": 45
            }
          },
          "penalty": {
            "avg": 29
          }
        }
      }
    }
  }
}
```plaintext
| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `miss.byPageSize` | object | - | Latence par taille de page |
| `miss.byPageSize.<size>` | number | cycles/ns | Latence pour une taille de page spécifique |
| `miss.byPageTableLevel` | object | - | Latence par niveau de table de pages |
| `miss.byPageTableLevel.<level>` | number | cycles/ns | Latence pour un niveau de table de pages spécifique |

## 5. Métriques dérivées

### 5.1 Ratios de latence entre niveaux de cache

```json
{
  "cache": {
    "hardware": {
      "latencyRatios": {
        "l2ToL1": 3.0,
        "l3ToL2": 2.33,
        "memoryToL3": 4.29,
        "memoryToL1": 30.0
      }
    }
  }
}
```plaintext
| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `l2ToL1` | number | ratio | Rapport entre la latence L2 et L1 |
| `l3ToL2` | number | ratio | Rapport entre la latence L3 et L2 |
| `memoryToL3` | number | ratio | Rapport entre la latence mémoire et L3 |
| `memoryToL1` | number | ratio | Rapport entre la latence mémoire et L1 |

### 5.2 Impact de la latence sur les performances

```json
{
  "cache": {
    "hardware": {
      "latencyImpact": {
        "averageCyclesPerInstruction": 0.85,
        "cyclesPenaltyDueToMisses": 0.35,
        "percentageOfTimeStalledOnCache": 28.5,
        "estimatedPerformanceLoss": 22.0
      }
    }
  }
}
```plaintext
| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `averageCyclesPerInstruction` | number | cycles | Nombre moyen de cycles par instruction |
| `cyclesPenaltyDueToMisses` | number | cycles | Pénalité moyenne en cycles due aux échecs de cache |
| `percentageOfTimeStalledOnCache` | number | pourcentage | Pourcentage du temps où le processeur est bloqué en attente du cache |
| `estimatedPerformanceLoss` | number | pourcentage | Perte de performance estimée due à la latence du cache |

### 5.3 Métriques de variation de latence

```json
{
  "cache": {
    "hardware": {
      "latencyVariation": {
        "jitter": 1.5,
        "coefficient": 0.25,
        "maxDeviation": 3.5,
        "stabilityScore": 0.85
      }
    }
  }
}
```plaintext
| Champ | Type | Unité | Description |
|-------|------|-------|-------------|
| `jitter` | number | cycles/ns | Variation moyenne de la latence |
| `coefficient` | number | - | Coefficient de variation (écart-type / moyenne) |
| `maxDeviation` | number | cycles/ns | Écart maximal par rapport à la moyenne |
| `stabilityScore` | number | ratio (0-1) | Score de stabilité de la latence (1 = parfaitement stable) |

## 6. Exemples complets

### 6.1 Exemple minimal

```json
{
  "memory": {
    "cache": {
      "hardware": {
        "l1": {
          "latency": {
            "unit": "cycles",
            "hit": {
              "avg": 4
            },
            "miss": {
              "avg": 12
            }
          }
        },
        "l2": {
          "latency": {
            "unit": "cycles",
            "hit": {
              "avg": 12
            },
            "miss": {
              "avg": 28
            }
          }
        },
        "l3": {
          "latency": {
            "unit": "cycles",
            "hit": {
              "avg": 28
            },
            "miss": {
              "avg": 120
            }
          }
        }
      }
    }
  }
}
```plaintext
### 6.2 Exemple complet

```json
{
  "memory": {
    "cache": {
      "hardware": {
        "l1": {
          "latency": {
            "unit": "cycles",
            "hit": {
              "min": 3,
              "max": 5,
              "avg": 4,
              "median": 4,
              "p90": 5,
              "p99": 5,
              "byCore": [
                {
                  "coreId": 0,
                  "avg": 3.9
                },
                {
                  "coreId": 1,
                  "avg": 4.1
                }
              ],
              "byAccessType": {
                "read": 3.8,
                "write": 4.2,
                "instruction": 3.5,
                "data": 4.5
              },
              "byDataSize": {
                "32bit": 3.5,
                "64bit": 4.0,
                "128bit": 4.5
              }
            },
            "miss": {
              "min": 10,
              "max": 15,
              "avg": 12,
              "median": 12,
              "p90": 14,
              "p99": 15,
              "byMissType": {
                "capacity": 13,
                "conflict": 12,
                "compulsory": 11
              },
              "byNextLevelHit": {
                "l2Hit": 12
              }
            },
            "penalty": {
              "avg": 8,
              "byMissType": {
                "capacity": 9,
                "conflict": 8,
                "compulsory": 7
              },
              "relativeToClock": 4.0,
              "relativeToHitLatency": 2.0
            },
            "distribution": {
              "histogram": [
                {
                  "bin": "3-4",
                  "count": 8000,
                  "percentage": 80.0
                },
                {
                  "bin": "5-10",
                  "count": 1000,
                  "percentage": 10.0
                },
                {
                  "bin": "11-15",
                  "count": 1000,
                  "percentage": 10.0
                }
              ]
            },
            "timeSeries": {
              "interval": 1000,
              "unit": "ms",
              "samples": [
                {
                  "timestamp": "2025-05-15T10:00:10.000Z",
                  "hit": 3.9,
                  "miss": 11.8
                },
                {
                  "timestamp": "2025-05-15T10:00:11.000Z",
                  "hit": 4.0,
                  "miss": 12.0
                },
                {
                  "timestamp": "2025-05-15T10:00:12.000Z",
                  "hit": 4.1,
                  "miss": 12.2
                }
              ]
            }
          }
        },
        "l2": {
          "latency": {
            "unit": "cycles",
            "hit": {
              "min": 10,
              "max": 14,
              "avg": 12,
              "median": 12,
              "p90": 13,
              "p99": 14,
              "byCore": [
                {
                  "coreId": 0,
                  "avg": 11.8
                },
                {
                  "coreId": 1,
                  "avg": 12.2
                }
              ],
              "byAccessType": {
                "read": 11.5,
                "write": 12.5
              }
            },
            "miss": {
              "min": 25,
              "max": 32,
              "avg": 28,
              "median": 28,
              "p90": 30,
              "p99": 32,
              "byNextLevelHit": {
                "l3Hit": 28
              }
            },
            "penalty": {
              "avg": 16
            }
          }
        },
        "l3": {
          "latency": {
            "unit": "cycles",
            "hit": {
              "min": 25,
              "max": 32,
              "avg": 28,
              "median": 28,
              "p90": 30,
              "p99": 32,
              "byCore": [
                {
                  "coreId": 0,
                  "avg": 27.5
                },
                {
                  "coreId": 1,
                  "avg": 28.5
                }
              ],
              "byAccessType": {
                "read": 27.0,
                "write": 29.0
              },
              "bySharing": {
                "exclusive": 26.0,
                "shared": 30.0
              }
            },
            "miss": {
              "min": 100,
              "max": 150,
              "avg": 120,
              "median": 115,
              "p90": 140,
              "p99": 148,
              "byNextLevelHit": {
                "memoryAccess": 120
              }
            },
            "penalty": {
              "avg": 92
            }
          }
        },
        "tlb": {
          "latency": {
            "unit": "cycles",
            "hit": {
              "avg": 1,
              "instruction": 0.9,
              "data": 1.1
            },
            "miss": {
              "avg": 30,
              "byPageSize": {
                "4KB": 35,
                "2MB": 25,
                "1GB": 20
              },
              "byPageTableLevel": {
                "level1": 15,
                "level2": 25,
                "level3": 35,
                "level4": 45
              }
            },
            "penalty": {
              "avg": 29
            }
          }
        },
        "latencyRatios": {
          "l2ToL1": 3.0,
          "l3ToL2": 2.33,
          "memoryToL3": 4.29,
          "memoryToL1": 30.0
        },
        "latencyImpact": {
          "averageCyclesPerInstruction": 0.85,
          "cyclesPenaltyDueToMisses": 0.35,
          "percentageOfTimeStalledOnCache": 28.5,
          "estimatedPerformanceLoss": 22.0
        },
        "latencyVariation": {
          "jitter": 1.5,
          "coefficient": 0.25,
          "maxDeviation": 3.5,
          "stabilityScore": 0.85
        }
      }
    }
  }
}
```plaintext
## 7. Bonnes pratiques

### 7.1 Collecte des métriques

- Utiliser des compteurs de performance matériels (PMC) pour mesurer précisément les latences
- Collecter les latences à différents niveaux de cache simultanément
- Mesurer les latences dans différentes conditions de charge
- Isoler les mesures de latence des autres facteurs de performance
- Effectuer plusieurs mesures et calculer des statistiques robustes

### 7.2 Analyse des métriques

- Comparer les latences mesurées avec les spécifications du fabricant
- Analyser les variations de latence au fil du temps
- Identifier les patterns d'accès qui causent des latences élevées
- Corréler les latences avec d'autres métriques de performance
- Examiner l'impact des latences sur les performances globales

### 7.3 Optimisation

- Optimiser les structures de données pour minimiser les latences d'accès
- Adapter les algorithmes aux caractéristiques de latence du cache
- Utiliser des techniques de préchargement pour masquer les latences
- Optimiser la localité spatiale et temporelle des accès
- Éviter les patterns d'accès qui causent des latences élevées

### 7.4 Reporting

- Inclure des graphiques de latence dans les rapports
- Mettre en évidence les anomalies et les tendances importantes
- Comparer les latences avec d'autres métriques de performance
- Fournir des recommandations basées sur l'analyse des latences
- Documenter les configurations optimales pour différents scénarios
