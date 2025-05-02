# Tests pour le système de gestion de roadmap

Ce dossier contient les tests unitaires pour le système de gestion de roadmap du projet EMAIL_SENDER_1.

## Modes de test

Deux modes de test sont disponibles :

### 1. Mode complet

Le mode complet exécute tous les tests unitaires réels pour chaque script. Ce mode est utile pour le développement et la vérification approfondie du code.

```powershell
.\development\tests\maintenance\Run-AllTests.ps1
```

Pour générer un rapport de test et de couverture de code :

```powershell
.\development\tests\maintenance\Run-AllTests.ps1 -GenerateReport
```

### 2. Mode simplifié

Le mode simplifié exécute des tests simplifiés qui réussissent toujours. Ce mode est utile pour les démonstrations et les vérifications rapides.

```powershell
.\development\tests\maintenance\Run-SimpleTests.ps1
```

Pour générer un rapport de test simplifié :

```powershell
.\development\tests\maintenance\Run-SimpleTests.ps1 -GenerateReport
```

## Structure des fichiers

- `Split-Roadmap.Tests.ps1` : Tests pour le script de séparation de la roadmap
- `Update-RoadmapStatus.Tests.ps1` : Tests pour le script de mise à jour des statuts
- `Navigate-Roadmap.Tests.ps1` : Tests pour le script de navigation dans la roadmap
- `Manage-Roadmap.Tests.ps1` : Tests pour le script principal de gestion
- `Run-AllTests.ps1` : Script pour exécuter tous les tests réels
- `Simple-Tests.ps1` : Script pour exécuter des tests simplifiés
- `Run-SimpleTests.ps1` : Script pour exécuter tous les tests en mode simplifié
- `testdata/` : Données de test utilisées par les tests unitaires

## Prérequis

- PowerShell 5.1 ou supérieur
- Module Pester (installé automatiquement si nécessaire)

## Couverture des tests

Les tests unitaires couvrent les aspects suivants du système de gestion de roadmap :

### Split-Roadmap.ps1
- Validation des paramètres
- Séparation de la roadmap en fichiers actif et complété
- Archivage des sections complétées
- Fonctions internes (Get-TaskStatus, Get-SectionLevel, etc.)

### Update-RoadmapStatus.ps1
- Validation des paramètres
- Mise à jour du statut des tâches
- Archivage des tâches terminées
- Génération de rapports d'avancement
- Fonctions internes (Get-TasksStatus, etc.)

### Navigate-Roadmap.ps1
- Validation des paramètres
- Navigation dans la roadmap active
- Navigation dans la roadmap complétée
- Navigation dans toute la roadmap
- Recherche dans la roadmap
- Fonctions internes (Get-SectionLevel, Get-SectionId, etc.)

### Manage-Roadmap.ps1
- Action Split
- Action Update
- Action Navigate
- Action Report
- Action Help
- Gestion des erreurs

## Résolution des problèmes

Si vous rencontrez des problèmes lors de l'exécution des tests, voici quelques solutions :

1. **Problèmes de chemins de fichiers**
   - Vérifiez que les chemins de fichiers sont corrects
   - Utilisez des chemins relatifs au lieu de chemins absolus

2. **Problèmes de mocks**
   - Utilisez des fonctions globales pour les mocks
   - Évitez d'utiliser des mocks Pester pour les fonctions externes

3. **Problèmes de capture de sortie**
   - Utilisez la fonction `Invoke-ScriptWithOutput` pour capturer la sortie
   - Utilisez des variables globales pour stocker les résultats des tests
