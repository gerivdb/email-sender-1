# TestOmnibus

TestOmnibus est un système centralisé pour exécuter et gérer tous les tests unitaires du projet. Il permet d'exécuter les tests de différents modules, de collecter les résultats et de générer des rapports.

## Fonctionnalités

- **Exécution centralisée** des tests unitaires de différents modules
- **Parallélisation** des tests pour une exécution plus rapide
- **Génération de rapports** HTML détaillés
- **Collecte de métriques** de performance
- **Filtrage des tests** par module, tag, priorité, etc.
- **Intégration avec différents frameworks** de test (Pester, etc.)

## Structure

- `Invoke-TestOmnibus.ps1` : Script principal pour exécuter les tests
- `Run-AllTests.ps1` : Script pour exécuter tous les tests configurés
- `Run-MaintenanceTests.ps1` : Script pour exécuter spécifiquement les tests de maintenance
- `Config/` : Répertoire contenant les fichiers de configuration
  - `testomnibus_config.json` : Configuration principale
- `Adapters/` : Répertoire contenant les adaptateurs pour différents modules de test
  - `ProactiveOptimization-Adapter.ps1` : Adaptateur pour les tests d'optimisation proactive
  - `MaintenanceStandards-Adapter.ps1` : Adaptateur pour les tests de standards de maintenance
  - `MaintenanceCleanup-Adapter.ps1` : Adaptateur pour les tests de nettoyage de maintenance
- `Results/` : Répertoire où sont stockés les résultats des tests

## Modules de test intégrés

### ProactiveOptimization

Tests pour le module d'optimisation proactive, qui inclut :
- Tests pour l'optimisation dynamique de la parallélisation
- Tests pour la mise en cache prédictive
- Tests pour le monitoring d'usage

### MaintenanceStandards

Tests pour le module de standards de maintenance, qui inclut :
- Tests pour l'inspection préventive des scripts
- Tests pour la vérification des bonnes pratiques de codage
- Tests pour la validation des standards de nommage

### MaintenanceCleanup

Tests pour le module de nettoyage de maintenance, qui inclut :
- Tests pour la correction automatique des problèmes PSScriptAnalyzer
- Tests pour le nettoyage des fichiers temporaires
- Tests pour la gestion des sauvegardes

## Utilisation

### Exécuter tous les tests

```powershell
.\Run-AllTests.ps1 -GenerateHtmlReport
```

### Exécuter les tests d'un module spécifique

```powershell
.\Invoke-TestOmnibus.ps1 -Path "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/scripts/utils/ProactiveOptimization/tests"
```

### Exécuter les tests de maintenance

```powershell
.\Run-MaintenanceTests.ps1 -GenerateHtmlReport
```

## Configuration

Le fichier `testomnibus_config.json` contient la configuration principale de TestOmnibus :

```json
{
    "MaxThreads": 4,
    "OutputPath": "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/scripts/utils/TestOmnibus/Results",
    "GenerateHtmlReport": true,
    "CollectPerformanceData": true,
    "TestModules": [
        {
            "Name": "ProactiveOptimization",
            "Path": "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/scripts/utils/ProactiveOptimization/tests",
            "Adapter": "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/scripts/utils/TestOmnibus/Adapters/ProactiveOptimization-Adapter.ps1",
            "Priority": 1,
            "Tags": ["PowerShell", "Optimization", "Monitoring"]
        },
        {
            "Name": "MaintenanceStandards",
            "Path": "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/scripts/maintenance/standards/tests",
            "Adapter": "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/scripts/utils/TestOmnibus/Adapters/MaintenanceStandards-Adapter.ps1",
            "Priority": 2,
            "Tags": ["PowerShell", "Maintenance", "Standards"]
        },
        {
            "Name": "MaintenanceCleanup",
            "Path": "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/scripts/maintenance/cleanup/tests",
            "Adapter": "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/scripts/utils/TestOmnibus/Adapters/MaintenanceCleanup-Adapter.ps1",
            "Priority": 3,
            "Tags": ["PowerShell", "Maintenance", "Cleanup"]
        }
    ]
}
```

## Ajouter un nouveau module de test

Pour ajouter un nouveau module de test à TestOmnibus :

1. Créer un adaptateur pour le module dans le répertoire `Adapters/`
2. Ajouter une entrée pour le module dans le fichier `testomnibus_config.json`
3. Créer les tests unitaires pour le module

## Rapports

Les rapports HTML générés par TestOmnibus contiennent :

- Un résumé global des tests exécutés
- Des résultats détaillés par module
- Des métriques de performance
- Des graphiques et visualisations (si activés)

## Intégration continue

TestOmnibus peut être intégré dans un pipeline CI/CD pour exécuter automatiquement les tests à chaque commit ou pull request.
