# TestOmnibus

TestOmnibus est un systÃ¨me centralisÃ© pour exÃ©cuter et gÃ©rer tous les tests unitaires du projet. Il permet d'exÃ©cuter les tests de diffÃ©rents modules, de collecter les rÃ©sultats et de gÃ©nÃ©rer des rapports.

## FonctionnalitÃ©s

- **ExÃ©cution centralisÃ©e** des tests unitaires de diffÃ©rents modules
- **ParallÃ©lisation** des tests pour une exÃ©cution plus rapide
- **GÃ©nÃ©ration de rapports** HTML dÃ©taillÃ©s
- **Collecte de mÃ©triques** de performance
- **Filtrage des tests** par module, tag, prioritÃ©, etc.
- **IntÃ©gration avec diffÃ©rents frameworks** de test (Pester, etc.)

## Structure

- `Invoke-TestOmnibus.ps1` : Script principal pour exÃ©cuter les tests
- `Run-AllTests.ps1` : Script pour exÃ©cuter tous les tests configurÃ©s
- `Run-MaintenanceTests.ps1` : Script pour exÃ©cuter spÃ©cifiquement les tests de maintenance
- `projet/config/` : RÃ©pertoire contenant les fichiers de configuration
  - `testomnibus_config.json` : Configuration principale
- `Adapters/` : RÃ©pertoire contenant les adaptateurs pour diffÃ©rents modules de test
  - `ProactiveOptimization-Adapter.ps1` : Adaptateur pour les tests d'optimisation proactive
  - `MaintenanceStandards-Adapter.ps1` : Adaptateur pour les tests de standards de maintenance
  - `MaintenanceCleanup-Adapter.ps1` : Adaptateur pour les tests de nettoyage de maintenance
- `Results/` : RÃ©pertoire oÃ¹ sont stockÃ©s les rÃ©sultats des tests

## Modules de test intÃ©grÃ©s

### ProactiveOptimization

Tests pour le module d'optimisation proactive, qui inclut :
- Tests pour l'optimisation dynamique de la parallÃ©lisation
- Tests pour la mise en cache prÃ©dictive
- Tests pour le monitoring d'usage

### MaintenanceStandards

Tests pour le module de standards de maintenance, qui inclut :
- Tests pour l'inspection prÃ©ventive des scripts
- Tests pour la vÃ©rification des bonnes pratiques de codage
- Tests pour la validation des standards de nommage

### MaintenanceCleanup

Tests pour le module de nettoyage de maintenance, qui inclut :
- Tests pour la correction automatique des problÃ¨mes PSScriptAnalyzer
- Tests pour le nettoyage des fichiers temporaires
- Tests pour la gestion des sauvegardes

## Utilisation

### ExÃ©cuter tous les tests

```powershell
.\Run-AllTests.ps1 -GenerateHtmlReport
```plaintext
### ExÃ©cuter les tests d'un module spÃ©cifique

```powershell
.\Invoke-TestOmnibus.ps1 -Path "D:/DO/WEB/N8N_development/testing/tests/PROJETS/EMAIL_SENDER_1/development/scripts/utils/ProactiveOptimization/tests"
```plaintext
### ExÃ©cuter les tests de maintenance

```powershell
.\Run-MaintenanceTests.ps1 -GenerateHtmlReport
```plaintext
## Configuration

Le fichier `testomnibus_config.json` contient la configuration principale de TestOmnibus :

```json
{
    "MaxThreads": 4,
    "OutputPath": "D:/DO/WEB/N8N_development/testing/tests/PROJETS/EMAIL_SENDER_1/development/scripts/utils/TestOmnibus/Results",
    "GenerateHtmlReport": true,
    "CollectPerformanceData": true,
    "TestModules": [
        {
            "Name": "ProactiveOptimization",
            "Path": "D:/DO/WEB/N8N_development/testing/tests/PROJETS/EMAIL_SENDER_1/development/scripts/utils/ProactiveOptimization/tests",
            "Adapter": "D:/DO/WEB/N8N_development/testing/tests/PROJETS/EMAIL_SENDER_1/development/scripts/utils/TestOmnibus/Adapters/ProactiveOptimization-Adapter.ps1",
            "Priority": 1,
            "Tags": ["PowerShell", "Optimization", "Monitoring"]
        },
        {
            "Name": "MaintenanceStandards",
            "Path": "D:/DO/WEB/N8N_development/testing/tests/PROJETS/EMAIL_SENDER_1/development/scripts/maintenance/standards/tests",
            "Adapter": "D:/DO/WEB/N8N_development/testing/tests/PROJETS/EMAIL_SENDER_1/development/scripts/utils/TestOmnibus/Adapters/MaintenanceStandards-Adapter.ps1",
            "Priority": 2,
            "Tags": ["PowerShell", "Maintenance", "Standards"]
        },
        {
            "Name": "MaintenanceCleanup",
            "Path": "D:/DO/WEB/N8N_development/testing/tests/PROJETS/EMAIL_SENDER_1/development/scripts/maintenance/cleanup/tests",
            "Adapter": "D:/DO/WEB/N8N_development/testing/tests/PROJETS/EMAIL_SENDER_1/development/scripts/utils/TestOmnibus/Adapters/MaintenanceCleanup-Adapter.ps1",
            "Priority": 3,
            "Tags": ["PowerShell", "Maintenance", "Cleanup"]
        }
    ]
}
```plaintext
## Ajouter un nouveau module de test

Pour ajouter un nouveau module de test Ã  TestOmnibus :

1. CrÃ©er un adaptateur pour le module dans le rÃ©pertoire `Adapters/`
2. Ajouter une entrÃ©e pour le module dans le fichier `testomnibus_config.json`
3. CrÃ©er les tests unitaires pour le module

## Rapports

Les rapports HTML gÃ©nÃ©rÃ©s par TestOmnibus contiennent :

- Un rÃ©sumÃ© global des tests exÃ©cutÃ©s
- Des rÃ©sultats dÃ©taillÃ©s par module
- Des mÃ©triques de performance
- Des graphiques et visualisations (si activÃ©s)

## IntÃ©gration continue

TestOmnibus peut Ãªtre intÃ©grÃ© dans un pipeline CI/CD pour exÃ©cuter automatiquement les tests Ã  chaque commit ou pull request.
