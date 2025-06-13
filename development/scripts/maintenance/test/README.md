# Tests de la solution d'organisation des scripts

Ce dossier contient les tests unitaires et d'intégration pour la solution d'organisation des scripts de maintenance.

## Exécution des tests

Pour exécuter la suite complète de tests, utilisez la commande suivante depuis la racine du projet:

```powershell
.\development\scripts\maintenance\test\Run-TestSuite.ps1 -OutputPath ".\reports" -GenerateHTML
```plaintext
Ou depuis le dossier `development\scripts\maintenance`:

```powershell
.\test\Run-TestSuite.ps1 -OutputPath ".\reports" -GenerateHTML
```plaintext
## Types de tests

### Tests unitaires

Pour exécuter uniquement les tests unitaires:

```powershell
.\development\scripts\maintenance\test\Run-AllTests.ps1 -OutputPath ".\reports\tests" -GenerateHTML
```plaintext
### Couverture de code

Pour générer un rapport de couverture de code:

```powershell
.\development\scripts\maintenance\test\Get-CodeCoverage.ps1 -OutputPath ".\reports\coverage" -GenerateHTML
```plaintext
### Tests d'intégration

Pour exécuter les tests d'intégration:

```powershell
.\development\scripts\maintenance\test\Test-Integration.ps1 -OutputPath ".\reports\integration"
```plaintext
## Rapports

Les rapports sont générés dans le dossier spécifié par le paramètre `-OutputPath`. Par défaut, les rapports sont générés dans le dossier `.\reports`.

- `reports\tests`: Rapports des tests unitaires
- `reports\coverage`: Rapports de couverture de code
- `reports\integration`: Rapports des tests d'intégration
- `reports\TestSuiteReport.md`: Rapport global de la suite de tests

## Dépendances

Ces tests nécessitent:

- PowerShell 5.1 ou supérieur
- Module Pester (installé automatiquement si nécessaire)
- ReportUnit (téléchargé automatiquement si nécessaire pour les rapports HTML)
- ReportGenerator (installé automatiquement si nécessaire pour les rapports de couverture HTML)
