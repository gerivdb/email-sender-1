# Tests - Tests unitaires et d'intégration

Ce dossier contient les tests unitaires et d'intégration pour le système de roadmap.

## Structure

- **Unit/** - Tests unitaires
- **Integration/** - Tests d'intégration
- **Mocks/** - Mocks pour les tests

## Tests principaux

- **Search-Tasks.Tests.ps1** - Tests pour les fonctionnalités de recherche
- **Update-TaskStatus.Tests.ps1** - Tests pour la mise à jour du statut des tâches
- **Convert-TaskToVector.Tests.ps1** - Tests pour la conversion des tâches en vecteurs
- **Invoke-RoadmapRAG.Tests.ps1** - Tests pour le système RAG

## Exécution des tests

Pour exécuter tous les tests:

```powershell
Invoke-Pester -Path "development\scripts\roadmap\tests"
```plaintext
Pour exécuter un test spécifique:

```powershell
Invoke-Pester -Path "development\scripts\roadmap\tests\Search-Tasks.Tests.ps1"
```plaintext
## Couverture de code

Pour générer un rapport de couverture de code:

```powershell
Invoke-Pester -Path "development\scripts\roadmap\tests" -CodeCoverage "development\scripts\roadmap\**\*.ps1" -CodeCoverageOutputFile "coverage.xml" -CodeCoverageOutputFileFormat JaCoCo
```plaintext