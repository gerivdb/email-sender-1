# Tests unitaires pour le système de gestion de roadmap

Ce dossier contient les tests unitaires pour le système de gestion de roadmap du projet EMAIL_SENDER_1.

## Structure des fichiers

- `Split-Roadmap.Tests.ps1` : Tests pour le script de séparation de la roadmap
- `Update-RoadmapStatus.Tests.ps1` : Tests pour le script de mise à jour des statuts
- `Navigate-Roadmap.Tests.ps1` : Tests pour le script de navigation dans la roadmap
- `Manage-Roadmap.Tests.ps1` : Tests pour le script principal de gestion
- `Run-AllTests.ps1` : Script pour exécuter tous les tests
- `testdata/` : Données de test utilisées par les tests unitaires

## Exécution des tests

Pour exécuter tous les tests, utilisez le script `Run-AllTests.ps1` :

```powershell
.\development\tests\maintenance\Run-AllTests.ps1
```plaintext
Pour générer un rapport de test et de couverture de code :

```powershell
.\development\tests\maintenance\Run-AllTests.ps1 -GenerateReport
```plaintext
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

## Bonnes pratiques

- Chaque test est isolé et ne dépend pas des autres tests
- Les données de test sont créées et nettoyées pour chaque test
- Les dépendances externes sont mockées pour éviter les effets de bord
- Les tests sont organisés en contextes et descriptions claires
- Chaque fonction est testée individuellement
