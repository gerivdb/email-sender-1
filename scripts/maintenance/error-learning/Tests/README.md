# Tests du système d'apprentissage des erreurs PowerShell

Ce répertoire contient les tests unitaires et d'intégration pour le système d'apprentissage des erreurs PowerShell.

## Structure des tests

- **Tests unitaires** : Testent les fonctionnalités individuelles du système.
  - `ErrorLearningSystem.Tests.ps1` : Tests pour le module principal.
  - `Analyze-ScriptForErrors.Tests.ps1` : Tests pour le script d'analyse des erreurs dans les scripts.
  - `Auto-CorrectErrors.Tests.ps1` : Tests pour le script de correction automatique des erreurs.
  - `Adaptive-ErrorCorrection.Tests.ps1` : Tests pour le script d'apprentissage adaptatif.
  - `Validate-ErrorCorrections.Tests.ps1` : Tests pour le script de validation des corrections.
  - `Basic.Tests.ps1` : Tests basiques pour vérifier le fonctionnement de Pester.
  - `Simple.Tests.ps1` : Tests simples pour vérifier le fonctionnement de Pester.

- **Tests d'intégration** : Testent l'interaction entre les différentes parties du système.
  - `ErrorLearningSystem.Integration.Tests.ps1` : Tests d'intégration pour le système d'apprentissage des erreurs.

## Exécution des tests

### Exécuter tous les tests

Pour exécuter tous les tests (unitaires et d'intégration), utilisez la commande suivante :

```powershell
.\Run-AllTests.ps1
```

### Exécuter uniquement les tests unitaires

Pour exécuter uniquement les tests unitaires, utilisez la commande suivante :

```powershell
.\Run-AllTests.ps1 -TestType Unit
```

### Exécuter uniquement les tests d'intégration

Pour exécuter uniquement les tests d'intégration, utilisez la commande suivante :

```powershell
.\Run-AllTests.ps1 -TestType Integration
```

### Générer un rapport HTML des résultats

Pour générer un rapport HTML des résultats des tests, utilisez l'option `-GenerateReport` :

```powershell
.\Run-AllTests.ps1 -GenerateReport
```

## Exécution des tests dans un pipeline CI/CD

Pour exécuter les tests dans un pipeline CI/CD, utilisez le script `Run-TestsInPipeline.ps1` situé dans le répertoire `CI-CD` :

```powershell
.\CI-CD\Run-TestsInPipeline.ps1
```

Ce script génère des rapports XML des résultats des tests et de la couverture de code, qui peuvent être utilisés par des outils d'intégration continue comme GitHub Actions.

## Ajout de nouveaux tests

Pour ajouter de nouveaux tests, créez un fichier `.Tests.ps1` dans ce répertoire. Assurez-vous de suivre les conventions suivantes :

- Utilisez le framework Pester pour écrire les tests.
- Utilisez des blocs `Describe`, `Context` et `It` pour organiser les tests.
- Utilisez des assertions `Should` pour vérifier les résultats.
- N'appelez pas `Invoke-Pester` à la fin du fichier pour éviter la récursion infinie.
- Pour les tests d'intégration, utilisez le suffixe `.Integration.Tests.ps1` dans le nom du fichier.

## Bonnes pratiques

- Écrivez des tests pour chaque nouvelle fonctionnalité.
- Exécutez les tests avant de soumettre des modifications.
- Assurez-vous que tous les tests passent avant de soumettre des modifications.
- Utilisez des assertions spécifiques pour vérifier les résultats.
- Utilisez des mocks pour simuler des dépendances externes.
- Utilisez des paramètres pour rendre les tests plus flexibles.
- Utilisez des blocs `BeforeAll` et `AfterAll` pour initialiser et nettoyer l'environnement de test.
