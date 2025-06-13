# Tests unitaires pour Hygen

Ce dossier contient les tests unitaires pour l'implémentation de Hygen dans le projet n8n.

## Structure des tests

- `Hygen.Tests.ps1` : Tests généraux pour l'implémentation de Hygen
- `HygenGenerators.Tests.ps1` : Tests pour les générateurs Hygen
- `HygenUtilities.Tests.ps1` : Tests pour les scripts d'utilitaires
- `HygenInstallation.Tests.ps1` : Tests pour les scripts d'installation
- `Run-HygenTests.ps1` : Script pour exécuter tous les tests

## Exécution des tests

### Via PowerShell

```powershell
# Exécuter tous les tests

.\Run-HygenTests.ps1

# Exécuter tous les tests avec un chemin de sortie personnalisé

.\Run-HygenTests.ps1 -OutputPath "C:\Reports"

# Exécuter un fichier de tests spécifique

Invoke-Pester -Path .\Hygen.Tests.ps1 -Output Detailed
```plaintext
### Via la ligne de commande

```batch
# Exécuter tous les tests

n8n\cmd\utils\run-hygen-tests.cmd
```plaintext
## Rapports de tests

Les rapports de tests sont générés dans le dossier `TestResults` par défaut. Deux types de rapports sont générés :

- `HygenTests.xml` : Rapport des résultats des tests au format NUnit
- `HygenCoverage.xml` : Rapport de couverture de code au format JaCoCo

## Couverture de code

Les tests couvrent les fichiers suivants :

- `n8n/scripts/setup/ensure-hygen-structure.ps1`
- `n8n/scripts/setup/install-hygen.ps1`
- `n8n/scripts/utils/Generate-N8nComponent.ps1`

## Ajout de nouveaux tests

Pour ajouter de nouveaux tests :

1. Créez un nouveau fichier de tests avec le suffixe `.Tests.ps1`
2. Utilisez le framework Pester pour écrire vos tests
3. Ajoutez le fichier à tester dans la liste `$scriptsToTest` dans `Run-HygenTests.ps1`

## Bonnes pratiques

- Utilisez des dossiers temporaires pour les tests qui créent des fichiers
- Nettoyez les fichiers temporaires après les tests
- Utilisez des mocks pour simuler les appels externes
- Testez les cas d'erreur en plus des cas de succès
- Assurez-vous que les tests sont indépendants les uns des autres
