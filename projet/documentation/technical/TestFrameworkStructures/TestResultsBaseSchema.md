# Schéma de base des résultats de test

## 1. Vue d'ensemble

Le schéma de base des résultats de test définit la structure fondamentale utilisée pour représenter les résultats des tests de performance exécutés par le moteur d'exécution. Cette structure est conçue pour être complète, cohérente et facilement exploitable par les composants d'analyse et de reporting.

## 2. Structure de base

Les résultats de test sont représentés sous forme de structure hiérarchique, qui peut être sérialisée en JSON, XML ou CSV pour le stockage et l'échange. La structure de base est la suivante :

```json
{
  "testId": "string",
  "testName": "string",
  "status": "string",
  "timestamp": {
    "start": "string (ISO 8601)",
    "end": "string (ISO 8601)"
  },
  "duration": "number (milliseconds)",
  "configuration": {
    // Configuration utilisée pour le test
  },
  "summary": {
    // Résumé des résultats
  },
  "metrics": {
    // Métriques collectées
  },
  "steps": [
    // Résultats par étape
  ],
  "errors": [
    // Erreurs rencontrées
  ],
  "metadata": {
    // Métadonnées supplémentaires
  }
}
```

## 3. Composants principaux

### 3.1 Identification et métadonnées de base

```json
{
  "testId": "perf-test-001",
  "testName": "Index Loading Performance Test",
  "description": "Test de performance pour le chargement des index",
  "version": "1.0",
  "tags": ["performance", "index", "loading"],
  "status": "completed",
  "timestamp": {
    "start": "2025-05-15T10:00:00.000Z",
    "end": "2025-05-15T10:05:30.500Z"
  },
  "duration": 330500,
  "executedBy": "John Doe",
  "environment": {
    "machine": "DESKTOP-ABC123",
    "os": "Windows 11 Pro",
    "processor": "Intel Core i7-12700K",
    "memory": "32GB",
    "powershell": "7.3.0"
  }
}
```

| Champ | Type | Description |
|-------|------|-------------|
| `testId` | string | Identifiant unique du test |
| `testName` | string | Nom du test |
| `description` | string | Description détaillée du test |
| `version` | string | Version du test |
| `tags` | array | Tags pour catégoriser le test |
| `status` | string | Statut final du test (completed, failed, aborted, etc.) |
| `timestamp.start` | string | Date et heure de début du test (ISO 8601) |
| `timestamp.end` | string | Date et heure de fin du test (ISO 8601) |
| `duration` | number | Durée totale du test en millisecondes |
| `executedBy` | string | Utilisateur ou système ayant exécuté le test |
| `environment` | object | Informations sur l'environnement d'exécution |

### 3.2 Configuration

```json
{
  "configuration": {
    "original": {
      // Configuration originale fournie pour le test
    },
    "effective": {
      // Configuration effective après résolution des valeurs par défaut et variables
    },
    "overrides": {
      // Paramètres qui ont été surchargés pendant l'exécution
    }
  }
}
```

| Champ | Type | Description |
|-------|------|-------------|
| `configuration.original` | object | Configuration originale fournie pour le test |
| `configuration.effective` | object | Configuration effective après résolution des valeurs par défaut et variables |
| `configuration.overrides` | object | Paramètres qui ont été surchargés pendant l'exécution |

### 3.3 Résumé

```json
{
  "summary": {
    "success": true,
    "iterations": {
      "planned": 5,
      "executed": 5,
      "successful": 5,
      "failed": 0
    },
    "performance": {
      "loadTime": {
        "min": 1200,
        "max": 1500,
        "avg": 1350,
        "median": 1320,
        "p90": 1450,
        "p95": 1480,
        "p99": 1495
      },
      "memoryUsage": {
        "min": 256000000,
        "max": 512000000,
        "avg": 384000000,
        "peak": 550000000
      },
      "cpuUsage": {
        "min": 15.5,
        "max": 85.2,
        "avg": 45.7
      }
    },
    "comparison": {
      "baseline": "perf-test-001-baseline",
      "changes": {
        "loadTime": {
          "absolute": -150,
          "percentage": -10.0,
          "significance": "improvement"
        },
        "memoryUsage": {
          "absolute": 50000000,
          "percentage": 15.0,
          "significance": "regression"
        }
      }
    },
    "thresholds": {
      "violated": false,
      "details": [
        {
          "metric": "loadTime",
          "threshold": 2000,
          "actual": 1350,
          "violated": false
        },
        {
          "metric": "memoryUsage",
          "threshold": 600000000,
          "actual": 384000000,
          "violated": false
        }
      ]
    }
  }
}
```

| Champ | Type | Description |
|-------|------|-------------|
| `summary.success` | boolean | Indique si le test a réussi |
| `summary.iterations` | object | Informations sur les itérations du test |
| `summary.performance` | object | Résumé des métriques de performance clés |
| `summary.comparison` | object | Comparaison avec une référence (si disponible) |
| `summary.thresholds` | object | Vérification des seuils définis |

### 3.4 Métriques

La section `metrics` contient les métriques collectées pendant le test. La structure détaillée des métriques est définie dans un document séparé.

```json
{
  "metrics": {
    "time": {
      // Métriques de temps
    },
    "memory": {
      // Métriques de mémoire
    },
    "cpu": {
      // Métriques CPU
    },
    "io": {
      // Métriques d'entrées/sorties
    },
    "custom": {
      // Métriques personnalisées
    }
  }
}
```

### 3.5 Étapes

La section `steps` contient les résultats détaillés pour chaque étape du test. La structure détaillée des résultats par étape est définie dans un document séparé.

```json
{
  "steps": [
    {
      "name": "initialization",
      "status": "completed",
      "timestamp": {
        "start": "2025-05-15T10:00:00.000Z",
        "end": "2025-05-15T10:00:05.500Z"
      },
      "duration": 5500,
      "metrics": {
        // Métriques spécifiques à cette étape
      },
      "output": {
        "stdout": "...",
        "stderr": "..."
      },
      "result": {
        // Résultat spécifique à cette étape
      }
    },
    // Autres étapes...
  ]
}
```

### 3.6 Erreurs

La section `errors` contient les erreurs rencontrées pendant l'exécution du test. La structure détaillée des erreurs est définie dans un document séparé.

```json
{
  "errors": [
    {
      "timestamp": "2025-05-15T10:02:30.500Z",
      "step": "data_loading",
      "type": "TimeoutException",
      "message": "Operation timed out after 300 seconds",
      "stackTrace": "...",
      "data": {
        // Données supplémentaires sur l'erreur
      },
      "handled": true,
      "impact": "warning",
      "recovery": {
        "action": "retry",
        "successful": true
      }
    },
    // Autres erreurs...
  ]
}
```

### 3.7 Métadonnées

La section `metadata` contient des métadonnées supplémentaires sur le test, qui peuvent être utilisées pour l'analyse et le reporting.

```json
{
  "metadata": {
    "testSuite": "Performance Tests",
    "testGroup": "Index Operations",
    "priority": "high",
    "categories": ["benchmark", "regression"],
    "links": [
      {
        "type": "issue",
        "url": "https://github.com/org/repo/issues/123",
        "description": "Related issue"
      },
      {
        "type": "baseline",
        "url": "file:///results/baseline/perf-test-001.json",
        "description": "Baseline results"
      }
    ],
    "notes": "Test executed as part of weekly performance testing",
    "custom": {
      // Métadonnées personnalisées
    }
  }
}
```

## 4. Extensions et personnalisation

Le schéma de base des résultats est conçu pour être extensible. Des sections supplémentaires peuvent être ajoutées pour des besoins spécifiques.

### 4.1 Extension par ajout de sections

```json
{
  // Schéma de base...
  "customAnalysis": {
    // Analyse personnalisée
  },
  "securityMetrics": {
    // Métriques de sécurité
  }
}
```

### 4.2 Extension par ajout de champs

```json
{
  "testId": "perf-test-001",
  "testName": "Index Loading Performance Test",
  "customField1": "value1",
  "customField2": 42,
  // Autres champs standard...
}
```

## 5. Validation

La validation des résultats de test est effectuée en plusieurs étapes :

1. **Validation du schéma** : Vérification que la structure des résultats respecte le schéma défini.
2. **Validation de la cohérence** : Vérification que les différentes parties des résultats sont cohérentes entre elles (par exemple, la durée totale correspond à la somme des durées des étapes).
3. **Validation des références** : Vérification que les références (par exemple, à la configuration ou à la référence) sont valides.

## 6. Exemples

### 6.1 Exemple minimal

```json
{
  "testId": "simple-test-001",
  "testName": "Simple Performance Test",
  "status": "completed",
  "timestamp": {
    "start": "2025-05-15T10:00:00.000Z",
    "end": "2025-05-15T10:01:00.000Z"
  },
  "duration": 60000,
  "summary": {
    "success": true
  }
}
```

### 6.2 Exemple complet

```json
{
  "testId": "perf-test-001",
  "testName": "Index Loading Performance Test",
  "description": "Test de performance pour le chargement des index",
  "version": "1.0",
  "tags": ["performance", "index", "loading"],
  "status": "completed",
  "timestamp": {
    "start": "2025-05-15T10:00:00.000Z",
    "end": "2025-05-15T10:05:30.500Z"
  },
  "duration": 330500,
  "executedBy": "John Doe",
  "environment": {
    "machine": "DESKTOP-ABC123",
    "os": "Windows 11 Pro",
    "processor": "Intel Core i7-12700K",
    "memory": "32GB",
    "powershell": "7.3.0"
  },
  
  "configuration": {
    "original": {
      "scenario": {
        "type": "script",
        "path": "scenarios/index_loading.ps1",
        "parameters": {
          "indexType": "hashtable",
          "cacheSize": 1024,
          "parallelism": 4
        }
      },
      "execution": {
        "iterations": 5
      }
    },
    "effective": {
      "scenario": {
        "type": "script",
        "path": "scenarios/index_loading.ps1",
        "parameters": {
          "indexType": "hashtable",
          "cacheSize": 1024,
          "parallelism": 4
        }
      },
      "execution": {
        "iterations": 5,
        "timeout": {
          "total": 3600,
          "perIteration": 600
        }
      }
    },
    "overrides": {}
  },
  
  "summary": {
    "success": true,
    "iterations": {
      "planned": 5,
      "executed": 5,
      "successful": 5,
      "failed": 0
    },
    "performance": {
      "loadTime": {
        "min": 1200,
        "max": 1500,
        "avg": 1350,
        "median": 1320,
        "p90": 1450,
        "p95": 1480,
        "p99": 1495
      },
      "memoryUsage": {
        "min": 256000000,
        "max": 512000000,
        "avg": 384000000,
        "peak": 550000000
      },
      "cpuUsage": {
        "min": 15.5,
        "max": 85.2,
        "avg": 45.7
      }
    },
    "comparison": {
      "baseline": "perf-test-001-baseline",
      "changes": {
        "loadTime": {
          "absolute": -150,
          "percentage": -10.0,
          "significance": "improvement"
        },
        "memoryUsage": {
          "absolute": 50000000,
          "percentage": 15.0,
          "significance": "regression"
        }
      }
    },
    "thresholds": {
      "violated": false,
      "details": [
        {
          "metric": "loadTime",
          "threshold": 2000,
          "actual": 1350,
          "violated": false
        },
        {
          "metric": "memoryUsage",
          "threshold": 600000000,
          "actual": 384000000,
          "violated": false
        }
      ]
    }
  },
  
  "metrics": {
    "time": {
      "wallClock": {
        "total": 330500,
        "byPhase": {
          "initialization": 5500,
          "dataLoading": 120000,
          "indexCreation": 200000,
          "cleanup": 5000
        }
      },
      "cpu": {
        "total": 280000,
        "user": 250000,
        "system": 30000
      }
    },
    "memory": {
      "physical": {
        "min": 256000000,
        "max": 512000000,
        "avg": 384000000,
        "samples": [
          {
            "timestamp": "2025-05-15T10:00:10.000Z",
            "value": 260000000
          },
          {
            "timestamp": "2025-05-15T10:01:10.000Z",
            "value": 350000000
          },
          {
            "timestamp": "2025-05-15T10:02:10.000Z",
            "value": 450000000
          },
          {
            "timestamp": "2025-05-15T10:03:10.000Z",
            "value": 500000000
          },
          {
            "timestamp": "2025-05-15T10:04:10.000Z",
            "value": 350000000
          }
        ]
      },
      "virtual": {
        "min": 1000000000,
        "max": 1500000000,
        "avg": 1250000000
      },
      "managed": {
        "allocated": 200000000,
        "gcCollections": {
          "gen0": 10,
          "gen1": 5,
          "gen2": 2
        }
      }
    },
    "cpu": {
      "usage": {
        "min": 15.5,
        "max": 85.2,
        "avg": 45.7,
        "samples": [
          {
            "timestamp": "2025-05-15T10:00:10.000Z",
            "value": 20.5
          },
          {
            "timestamp": "2025-05-15T10:01:10.000Z",
            "value": 45.8
          },
          {
            "timestamp": "2025-05-15T10:02:10.000Z",
            "value": 85.2
          },
          {
            "timestamp": "2025-05-15T10:03:10.000Z",
            "value": 60.3
          },
          {
            "timestamp": "2025-05-15T10:04:10.000Z",
            "value": 15.5
          }
        ]
      },
      "cores": {
        "total": 16,
        "used": 8
      }
    },
    "io": {
      "disk": {
        "read": {
          "operations": 1250,
          "bytes": 256000000
        },
        "write": {
          "operations": 850,
          "bytes": 128000000
        }
      },
      "network": {
        "sent": {
          "packets": 0,
          "bytes": 0
        },
        "received": {
          "packets": 0,
          "bytes": 0
        }
      }
    },
    "custom": {
      "indexOperations": {
        "lookups": 10000,
        "inserts": 5000,
        "updates": 2000,
        "deletes": 1000,
        "performance": {
          "lookupAvg": 0.5,
          "insertAvg": 1.2,
          "updateAvg": 1.5,
          "deleteAvg": 0.8
        }
      }
    }
  },
  
  "steps": [
    {
      "name": "initialization",
      "description": "Initialisation de l'environnement",
      "status": "completed",
      "timestamp": {
        "start": "2025-05-15T10:00:00.000Z",
        "end": "2025-05-15T10:00:05.500Z"
      },
      "duration": 5500,
      "metrics": {
        "time": {
          "wallClock": 5500,
          "cpu": 3000
        },
        "memory": {
          "physical": {
            "start": 256000000,
            "end": 260000000,
            "delta": 4000000
          }
        }
      },
      "output": {
        "stdout": "Initializing environment...\nEnvironment initialized successfully.",
        "stderr": ""
      },
      "result": {
        "success": true,
        "data": {
          "environmentId": "env-001"
        }
      }
    },
    {
      "name": "data_loading",
      "description": "Chargement des données",
      "status": "completed",
      "timestamp": {
        "start": "2025-05-15T10:00:05.500Z",
        "end": "2025-05-15T10:02:05.500Z"
      },
      "duration": 120000,
      "metrics": {
        "time": {
          "wallClock": 120000,
          "cpu": 100000
        },
        "memory": {
          "physical": {
            "start": 260000000,
            "end": 450000000,
            "delta": 190000000
          }
        },
        "io": {
          "disk": {
            "read": {
              "operations": 1000,
              "bytes": 200000000
            }
          }
        }
      },
      "output": {
        "stdout": "Loading data...\nLoaded 1000000 records.",
        "stderr": ""
      },
      "result": {
        "success": true,
        "data": {
          "recordsLoaded": 1000000,
          "dataSize": 200000000
        }
      }
    },
    {
      "name": "index_creation",
      "description": "Création des index",
      "status": "completed",
      "timestamp": {
        "start": "2025-05-15T10:02:05.500Z",
        "end": "2025-05-15T10:05:25.500Z"
      },
      "duration": 200000,
      "metrics": {
        "time": {
          "wallClock": 200000,
          "cpu": 170000
        },
        "memory": {
          "physical": {
            "start": 450000000,
            "end": 350000000,
            "delta": -100000000
          }
        },
        "custom": {
          "indexOperations": {
            "inserts": 5000
          }
        }
      },
      "output": {
        "stdout": "Creating indexes...\nCreated 5 indexes.",
        "stderr": ""
      },
      "result": {
        "success": true,
        "data": {
          "indexesCreated": 5,
          "indexSize": 150000000
        }
      }
    },
    {
      "name": "cleanup",
      "description": "Nettoyage",
      "status": "completed",
      "timestamp": {
        "start": "2025-05-15T10:05:25.500Z",
        "end": "2025-05-15T10:05:30.500Z"
      },
      "duration": 5000,
      "metrics": {
        "time": {
          "wallClock": 5000,
          "cpu": 2000
        },
        "memory": {
          "physical": {
            "start": 350000000,
            "end": 260000000,
            "delta": -90000000
          }
        }
      },
      "output": {
        "stdout": "Cleaning up...\nCleanup completed.",
        "stderr": ""
      },
      "result": {
        "success": true
      }
    }
  ],
  
  "errors": [],
  
  "metadata": {
    "testSuite": "Performance Tests",
    "testGroup": "Index Operations",
    "priority": "high",
    "categories": ["benchmark", "regression"],
    "links": [
      {
        "type": "issue",
        "url": "https://github.com/org/repo/issues/123",
        "description": "Related issue"
      },
      {
        "type": "baseline",
        "url": "file:///results/baseline/perf-test-001.json",
        "description": "Baseline results"
      }
    ],
    "notes": "Test executed as part of weekly performance testing"
  }
}
```

## 7. Bonnes pratiques

### 7.1 Structure

- Utiliser une structure hiérarchique claire et cohérente
- Regrouper les informations connexes dans des sections dédiées
- Éviter les structures trop profondes (plus de 5 niveaux)
- Utiliser des noms de champs explicites et cohérents

### 7.2 Types de données

- Utiliser les types de données appropriés (string, number, boolean, array, object)
- Utiliser des formats standards pour les dates (ISO 8601)
- Utiliser des unités cohérentes pour les mesures (millisecondes, octets, etc.)
- Documenter les unités utilisées

### 7.3 Extensibilité

- Concevoir le schéma pour être extensible
- Prévoir des sections pour les données personnalisées
- Documenter les extensions et personnalisations
- Maintenir la compatibilité avec les versions antérieures

### 7.4 Validation

- Valider les résultats contre le schéma défini
- Vérifier la cohérence des données
- Documenter les contraintes et règles de validation
- Fournir des messages d'erreur clairs en cas de validation échouée
