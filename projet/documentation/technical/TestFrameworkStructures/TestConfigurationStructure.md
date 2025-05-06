# Structure de configuration des tests

## 1. Vue d'ensemble

La structure de configuration des tests définit le format et le contenu des configurations utilisées pour paramétrer l'exécution des tests de performance. Cette structure est conçue pour être flexible, extensible et facile à utiliser, tout en fournissant toutes les informations nécessaires au moteur d'exécution pour configurer et exécuter correctement les tests.

## 2. Format de base

La configuration des tests est représentée sous forme de structure hiérarchique, qui peut être sérialisée en JSON ou YAML pour le stockage et l'échange. La structure de base est la suivante :

```json
{
  "testId": "string",
  "name": "string",
  "description": "string",
  "version": "string",
  "scenario": {
    // Configuration du scénario
  },
  "data": {
    // Configuration des données de test
  },
  "execution": {
    // Configuration de l'exécution
  },
  "metrics": {
    // Configuration des métriques à collecter
  },
  "environment": {
    // Configuration de l'environnement
  },
  "output": {
    // Configuration de la sortie
  },
  "analysis": {
    // Configuration de l'analyse
  },
  "extensions": {
    // Extensions personnalisées
  }
}
```

## 3. Sections de configuration

### 3.1 Métadonnées du test

```json
{
  "testId": "perf-test-001",
  "name": "Index Loading Performance Test",
  "description": "Test de performance pour le chargement des index",
  "version": "1.0",
  "tags": ["performance", "index", "loading"],
  "author": "John Doe",
  "createdAt": "2025-05-15T10:00:00Z",
  "updatedAt": "2025-05-15T10:00:00Z"
}
```

| Champ | Type | Obligatoire | Description |
|-------|------|-------------|-------------|
| `testId` | string | Oui | Identifiant unique du test |
| `name` | string | Oui | Nom du test |
| `description` | string | Non | Description détaillée du test |
| `version` | string | Non | Version de la configuration |
| `tags` | array | Non | Tags pour catégoriser le test |
| `author` | string | Non | Auteur de la configuration |
| `createdAt` | string (ISO 8601) | Non | Date de création |
| `updatedAt` | string (ISO 8601) | Non | Date de dernière mise à jour |

### 3.2 Configuration du scénario

```json
{
  "scenario": {
    "type": "script",
    "path": "scenarios/index_loading.ps1",
    "parameters": {
      "indexType": "hashtable",
      "cacheSize": 1024,
      "parallelism": 4
    },
    "steps": [
      {
        "name": "initialization",
        "description": "Initialisation de l'environnement",
        "enabled": true,
        "timeout": 60
      },
      {
        "name": "data_loading",
        "description": "Chargement des données",
        "enabled": true,
        "timeout": 300,
        "parameters": {
          "batchSize": 100
        }
      },
      {
        "name": "index_creation",
        "description": "Création des index",
        "enabled": true,
        "timeout": 600
      },
      {
        "name": "cleanup",
        "description": "Nettoyage",
        "enabled": true,
        "timeout": 60
      }
    ],
    "dependencies": {
      "modules": ["DataProcessing", "IndexManagement"],
      "scripts": ["utils/helpers.ps1"]
    }
  }
}
```

| Champ | Type | Obligatoire | Description |
|-------|------|-------------|-------------|
| `type` | string | Oui | Type de scénario (script, fonction, etc.) |
| `path` | string | Oui pour type=script | Chemin vers le script du scénario |
| `parameters` | object | Non | Paramètres globaux du scénario |
| `steps` | array | Non | Étapes du scénario |
| `steps[].name` | string | Oui | Nom de l'étape |
| `steps[].description` | string | Non | Description de l'étape |
| `steps[].enabled` | boolean | Non | Si l'étape est activée (défaut: true) |
| `steps[].timeout` | number | Non | Timeout en secondes (0 = pas de timeout) |
| `steps[].parameters` | object | Non | Paramètres spécifiques à l'étape |
| `dependencies` | object | Non | Dépendances du scénario |
| `dependencies.modules` | array | Non | Modules PowerShell requis |
| `dependencies.scripts` | array | Non | Scripts auxiliaires requis |

### 3.3 Configuration des données de test

```json
{
  "data": {
    "source": {
      "type": "generator",
      "name": "RandomDataGenerator",
      "parameters": {
        "size": "medium",
        "complexity": "medium",
        "seed": 12345
      }
    },
    "preload": true,
    "cache": {
      "enabled": true,
      "location": "memory",
      "expiration": 3600
    },
    "validation": {
      "enabled": true,
      "rules": ["schema", "consistency"]
    },
    "cleanup": {
      "enabled": true,
      "when": "afterTest"
    }
  }
}
```

| Champ | Type | Obligatoire | Description |
|-------|------|-------------|-------------|
| `source` | object | Oui | Source des données de test |
| `source.type` | string | Oui | Type de source (generator, file, api, etc.) |
| `source.name` | string | Oui | Nom du générateur ou chemin du fichier |
| `source.parameters` | object | Non | Paramètres pour la génération/chargement |
| `preload` | boolean | Non | Si les données doivent être préchargées |
| `cache` | object | Non | Configuration du cache de données |
| `validation` | object | Non | Configuration de la validation des données |
| `cleanup` | object | Non | Configuration du nettoyage des données |

### 3.4 Configuration de l'exécution

```json
{
  "execution": {
    "mode": "standard",
    "iterations": 5,
    "warmup": {
      "enabled": true,
      "iterations": 1
    },
    "concurrency": {
      "enabled": false,
      "level": 1
    },
    "timeout": {
      "total": 3600,
      "perIteration": 600
    },
    "errorHandling": {
      "continueOnError": false,
      "retryCount": 0,
      "retryDelay": 5
    },
    "scheduling": {
      "startAt": null,
      "priority": "normal"
    }
  }
}
```

| Champ | Type | Obligatoire | Description |
|-------|------|-------------|-------------|
| `mode` | string | Non | Mode d'exécution (standard, stress, endurance) |
| `iterations` | number | Non | Nombre d'itérations à exécuter |
| `warmup` | object | Non | Configuration de l'échauffement |
| `concurrency` | object | Non | Configuration de la concurrence |
| `timeout` | object | Non | Configuration des timeouts |
| `errorHandling` | object | Non | Configuration de la gestion des erreurs |
| `scheduling` | object | Non | Configuration de la planification |

### 3.5 Configuration des métriques

```json
{
  "metrics": {
    "collectors": [
      {
        "type": "time",
        "enabled": true,
        "parameters": {
          "precision": "millisecond",
          "includeWallClock": true,
          "includeCpuTime": true
        }
      },
      {
        "type": "memory",
        "enabled": true,
        "parameters": {
          "samplingInterval": 100,
          "trackAllocations": true,
          "trackGC": true
        }
      },
      {
        "type": "cpu",
        "enabled": true,
        "parameters": {
          "samplingInterval": 100,
          "trackPerCore": true
        }
      },
      {
        "type": "custom",
        "name": "IndexOperations",
        "enabled": true,
        "parameters": {
          "trackLookups": true,
          "trackInserts": true,
          "trackUpdates": true,
          "trackDeletes": true
        }
      }
    ],
    "markers": [
      "start",
      "dataLoaded",
      "indexCreated",
      "operationsCompleted",
      "end"
    ],
    "sampling": {
      "interval": 100,
      "aggregation": "average"
    },
    "storage": {
      "format": "json",
      "compression": false,
      "retention": "7d"
    }
  }
}
```

| Champ | Type | Obligatoire | Description |
|-------|------|-------------|-------------|
| `collectors` | array | Oui | Collecteurs de métriques à utiliser |
| `collectors[].type` | string | Oui | Type de collecteur |
| `collectors[].enabled` | boolean | Non | Si le collecteur est activé |
| `collectors[].parameters` | object | Non | Paramètres du collecteur |
| `markers` | array | Non | Marqueurs pour les points de mesure |
| `sampling` | object | Non | Configuration de l'échantillonnage |
| `storage` | object | Non | Configuration du stockage des métriques |

### 3.6 Configuration de l'environnement

```json
{
  "environment": {
    "setup": {
      "script": "setup/prepare_environment.ps1",
      "parameters": {
        "cleanDatabase": true
      }
    },
    "variables": {
      "DB_CONNECTION": "Server=localhost;Database=TestDB;",
      "API_ENDPOINT": "https://api.example.com/v1"
    },
    "requirements": {
      "memory": {
        "minimum": "4GB",
        "recommended": "8GB"
      },
      "disk": {
        "minimum": "10GB",
        "recommended": "20GB"
      },
      "cpu": {
        "minimum": 2,
        "recommended": 4
      }
    },
    "cleanup": {
      "script": "cleanup/cleanup_environment.ps1",
      "parameters": {},
      "runAlways": true
    }
  }
}
```

| Champ | Type | Obligatoire | Description |
|-------|------|-------------|-------------|
| `setup` | object | Non | Configuration de la préparation de l'environnement |
| `variables` | object | Non | Variables d'environnement |
| `requirements` | object | Non | Exigences matérielles et logicielles |
| `cleanup` | object | Non | Configuration du nettoyage de l'environnement |

### 3.7 Configuration de la sortie

```json
{
  "output": {
    "path": "results/",
    "format": "json",
    "includeRawData": true,
    "generateReport": true,
    "reportTemplate": "templates/performance_report.html",
    "notifications": {
      "onCompletion": {
        "enabled": true,
        "channels": ["email"],
        "recipients": ["team@example.com"]
      },
      "onError": {
        "enabled": true,
        "channels": ["email", "slack"],
        "recipients": ["team@example.com", "#alerts"]
      }
    },
    "archiving": {
      "enabled": true,
      "retention": "30d",
      "compress": true
    }
  }
}
```

| Champ | Type | Obligatoire | Description |
|-------|------|-------------|-------------|
| `path` | string | Non | Chemin de sortie des résultats |
| `format` | string | Non | Format de sortie (json, csv, xml) |
| `includeRawData` | boolean | Non | Inclure les données brutes |
| `generateReport` | boolean | Non | Générer un rapport |
| `reportTemplate` | string | Non | Template du rapport |
| `notifications` | object | Non | Configuration des notifications |
| `archiving` | object | Non | Configuration de l'archivage |

### 3.8 Configuration de l'analyse

```json
{
  "analysis": {
    "enabled": true,
    "baseline": {
      "source": "previous",
      "path": null
    },
    "thresholds": {
      "loadTime": {
        "warning": 10,
        "critical": 20
      },
      "memoryUsage": {
        "warning": 15,
        "critical": 30
      }
    },
    "statistics": {
      "percentiles": [50, 90, 95, 99],
      "outlierDetection": {
        "enabled": true,
        "method": "iqr",
        "threshold": 1.5
      }
    },
    "regression": {
      "enabled": true,
      "sensitivity": "medium",
      "alertThreshold": 15
    },
    "recommendations": {
      "enabled": true,
      "includeInReport": true
    }
  }
}
```

| Champ | Type | Obligatoire | Description |
|-------|------|-------------|-------------|
| `enabled` | boolean | Non | Si l'analyse est activée |
| `baseline` | object | Non | Configuration de la référence |
| `thresholds` | object | Non | Seuils d'alerte |
| `statistics` | object | Non | Configuration des statistiques |
| `regression` | object | Non | Configuration de la détection de régression |
| `recommendations` | object | Non | Configuration des recommandations |

### 3.9 Extensions personnalisées

```json
{
  "extensions": {
    "customPlugin1": {
      "enabled": true,
      "parameters": {
        "option1": "value1",
        "option2": 42
      }
    },
    "customPlugin2": {
      "enabled": false,
      "parameters": {}
    }
  }
}
```

| Champ | Type | Obligatoire | Description |
|-------|------|-------------|-------------|
| `extensions` | object | Non | Extensions personnalisées |
| `extensions.<name>` | object | Non | Configuration d'une extension |
| `extensions.<name>.enabled` | boolean | Non | Si l'extension est activée |
| `extensions.<name>.parameters` | object | Non | Paramètres de l'extension |

## 4. Validation de la configuration

La validation de la configuration est effectuée en plusieurs étapes :

1. **Validation du schéma** : Vérification que la structure de la configuration respecte le schéma défini.
2. **Validation des références** : Vérification que les références (chemins de fichiers, noms de collecteurs, etc.) sont valides.
3. **Validation de la cohérence** : Vérification que les différentes parties de la configuration sont cohérentes entre elles.
4. **Validation des dépendances** : Vérification que les dépendances requises sont disponibles.

## 5. Héritage et surcharge

La configuration des tests supporte l'héritage et la surcharge pour faciliter la réutilisation et la personnalisation :

### 5.1 Héritage de base

```json
{
  "inherits": "base_configurations/standard_performance_test.json",
  "name": "Custom Index Loading Test",
  "scenario": {
    "parameters": {
      "indexType": "dictionary"
    }
  }
}
```

### 5.2 Héritage multiple

```json
{
  "inherits": [
    "base_configurations/standard_performance_test.json",
    "base_configurations/memory_metrics.json"
  ],
  "name": "Custom Index Loading Test"
}
```

### 5.3 Règles de surcharge

- Les champs simples (chaînes, nombres, booléens) sont remplacés.
- Les tableaux sont remplacés, sauf si la propriété `mergeArrays` est définie à `true`.
- Les objets sont fusionnés récursivement.
- La propriété spéciale `null` peut être utilisée pour supprimer un champ hérité.

## 6. Variables et substitution

La configuration supporte l'utilisation de variables et de substitutions pour rendre les configurations plus flexibles et réutilisables :

### 6.1 Variables intégrées

```json
{
  "output": {
    "path": "results/${testId}/${timestamp}"
  }
}
```

Variables intégrées disponibles :
- `${testId}` : Identifiant du test
- `${timestamp}` : Horodatage au format ISO 8601
- `${date}` : Date au format YYYY-MM-DD
- `${time}` : Heure au format HH-MM-SS
- `${env:VARIABLE}` : Variable d'environnement
- `${random:n}` : Nombre aléatoire à n chiffres

### 6.2 Variables personnalisées

```json
{
  "variables": {
    "dataSize": "medium",
    "iterations": 5
  },
  "scenario": {
    "parameters": {
      "size": "${dataSize}",
      "repeat": "${iterations}"
    }
  }
}
```

### 6.3 Expressions conditionnelles

```json
{
  "execution": {
    "iterations": "${dataSize == 'small' ? 10 : 5}"
  }
}
```

## 7. Exemples complets

### 7.1 Configuration minimale

```json
{
  "testId": "simple-test",
  "name": "Simple Performance Test",
  "scenario": {
    "type": "script",
    "path": "scenarios/simple_test.ps1"
  }
}
```

### 7.2 Configuration complète

```json
{
  "testId": "index-loading-test",
  "name": "Index Loading Performance Test",
  "description": "Test de performance pour le chargement des index",
  "version": "1.0",
  "tags": ["performance", "index", "loading"],
  "author": "John Doe",
  "createdAt": "2025-05-15T10:00:00Z",
  "updatedAt": "2025-05-15T10:00:00Z",
  
  "scenario": {
    "type": "script",
    "path": "scenarios/index_loading.ps1",
    "parameters": {
      "indexType": "hashtable",
      "cacheSize": 1024,
      "parallelism": 4
    },
    "steps": [
      {
        "name": "initialization",
        "description": "Initialisation de l'environnement",
        "enabled": true,
        "timeout": 60
      },
      {
        "name": "data_loading",
        "description": "Chargement des données",
        "enabled": true,
        "timeout": 300,
        "parameters": {
          "batchSize": 100
        }
      },
      {
        "name": "index_creation",
        "description": "Création des index",
        "enabled": true,
        "timeout": 600
      },
      {
        "name": "cleanup",
        "description": "Nettoyage",
        "enabled": true,
        "timeout": 60
      }
    ],
    "dependencies": {
      "modules": ["DataProcessing", "IndexManagement"],
      "scripts": ["utils/helpers.ps1"]
    }
  },
  
  "data": {
    "source": {
      "type": "generator",
      "name": "RandomDataGenerator",
      "parameters": {
        "size": "medium",
        "complexity": "medium",
        "seed": 12345
      }
    },
    "preload": true,
    "cache": {
      "enabled": true,
      "location": "memory",
      "expiration": 3600
    },
    "validation": {
      "enabled": true,
      "rules": ["schema", "consistency"]
    },
    "cleanup": {
      "enabled": true,
      "when": "afterTest"
    }
  },
  
  "execution": {
    "mode": "standard",
    "iterations": 5,
    "warmup": {
      "enabled": true,
      "iterations": 1
    },
    "concurrency": {
      "enabled": false,
      "level": 1
    },
    "timeout": {
      "total": 3600,
      "perIteration": 600
    },
    "errorHandling": {
      "continueOnError": false,
      "retryCount": 0,
      "retryDelay": 5
    },
    "scheduling": {
      "startAt": null,
      "priority": "normal"
    }
  },
  
  "metrics": {
    "collectors": [
      {
        "type": "time",
        "enabled": true,
        "parameters": {
          "precision": "millisecond",
          "includeWallClock": true,
          "includeCpuTime": true
        }
      },
      {
        "type": "memory",
        "enabled": true,
        "parameters": {
          "samplingInterval": 100,
          "trackAllocations": true,
          "trackGC": true
        }
      },
      {
        "type": "cpu",
        "enabled": true,
        "parameters": {
          "samplingInterval": 100,
          "trackPerCore": true
        }
      },
      {
        "type": "custom",
        "name": "IndexOperations",
        "enabled": true,
        "parameters": {
          "trackLookups": true,
          "trackInserts": true,
          "trackUpdates": true,
          "trackDeletes": true
        }
      }
    ],
    "markers": [
      "start",
      "dataLoaded",
      "indexCreated",
      "operationsCompleted",
      "end"
    ],
    "sampling": {
      "interval": 100,
      "aggregation": "average"
    },
    "storage": {
      "format": "json",
      "compression": false,
      "retention": "7d"
    }
  },
  
  "environment": {
    "setup": {
      "script": "setup/prepare_environment.ps1",
      "parameters": {
        "cleanDatabase": true
      }
    },
    "variables": {
      "DB_CONNECTION": "Server=localhost;Database=TestDB;",
      "API_ENDPOINT": "https://api.example.com/v1"
    },
    "requirements": {
      "memory": {
        "minimum": "4GB",
        "recommended": "8GB"
      },
      "disk": {
        "minimum": "10GB",
        "recommended": "20GB"
      },
      "cpu": {
        "minimum": 2,
        "recommended": 4
      }
    },
    "cleanup": {
      "script": "cleanup/cleanup_environment.ps1",
      "parameters": {},
      "runAlways": true
    }
  },
  
  "output": {
    "path": "results/",
    "format": "json",
    "includeRawData": true,
    "generateReport": true,
    "reportTemplate": "templates/performance_report.html",
    "notifications": {
      "onCompletion": {
        "enabled": true,
        "channels": ["email"],
        "recipients": ["team@example.com"]
      },
      "onError": {
        "enabled": true,
        "channels": ["email", "slack"],
        "recipients": ["team@example.com", "#alerts"]
      }
    },
    "archiving": {
      "enabled": true,
      "retention": "30d",
      "compress": true
    }
  },
  
  "analysis": {
    "enabled": true,
    "baseline": {
      "source": "previous",
      "path": null
    },
    "thresholds": {
      "loadTime": {
        "warning": 10,
        "critical": 20
      },
      "memoryUsage": {
        "warning": 15,
        "critical": 30
      }
    },
    "statistics": {
      "percentiles": [50, 90, 95, 99],
      "outlierDetection": {
        "enabled": true,
        "method": "iqr",
        "threshold": 1.5
      }
    },
    "regression": {
      "enabled": true,
      "sensitivity": "medium",
      "alertThreshold": 15
    },
    "recommendations": {
      "enabled": true,
      "includeInReport": true
    }
  },
  
  "extensions": {
    "customPlugin1": {
      "enabled": true,
      "parameters": {
        "option1": "value1",
        "option2": 42
      }
    }
  }
}
```

## 8. Bonnes pratiques

### 8.1 Organisation des configurations

- Utiliser des configurations de base pour les paramètres communs
- Créer des configurations spécifiques pour chaque type de test
- Stocker les configurations dans un répertoire dédié avec une structure claire

### 8.2 Nommage

- Utiliser des noms descriptifs pour les tests
- Suivre une convention de nommage cohérente
- Inclure des informations sur le type de test dans le nom

### 8.3 Documentation

- Inclure une description détaillée pour chaque test
- Documenter les paramètres spécifiques
- Utiliser des tags pour faciliter la recherche et le filtrage

### 8.4 Versionnement

- Versionner les configurations de test
- Documenter les changements entre les versions
- Conserver les anciennes versions pour référence

### 8.5 Paramétrage

- Paramétrer les configurations pour les rendre réutilisables
- Utiliser des variables pour les valeurs qui changent fréquemment
- Éviter les valeurs codées en dur
