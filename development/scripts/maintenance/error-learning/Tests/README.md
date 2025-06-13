# Tests du systÃ¨me d'apprentissage des erreurs PowerShell

Ce rÃ©pertoire contient les tests unitaires et d'intÃ©gration pour le systÃ¨me d'apprentissage des erreurs PowerShell.

## Structure des tests

### Tests basiques

- **VeryBasic.Tests.ps1** : Tests trÃ¨s basiques pour les opÃ©rations mathÃ©matiques de base
- **Basic.Tests.ps1** : Tests basiques pour les opÃ©rations d'addition et de soustraction
- **Simple.Tests.ps1** : Tests simples pour vÃ©rifier le fonctionnement de Pester

### Tests unitaires

- **ErrorLearningSystem.Tests.ps1** : Tests pour le module principal
- **Analyze-ScriptForErrors.Tests.ps1** : Tests pour le script d'analyse des erreurs dans les scripts
- **Auto-CorrectErrors.Tests.ps1** : Tests pour le script de correction automatique des erreurs
- **Adaptive-ErrorCorrection.Tests.ps1** : Tests pour le script d'apprentissage adaptatif
- **Validate-ErrorCorrections.Tests.ps1** : Tests pour le script de validation des corrections
- **ErrorFunctions.Tests.ps1** : Tests unitaires pour les fonctions du systÃ¨me d'apprentissage des erreurs
- **ErrorHandling.Tests.ps1** : Tests unitaires pour la gestion des erreurs PowerShell
- **AdaptiveLearning.Tests.ps1** : Tests unitaires pour la fonctionnalitÃ© d'apprentissage adaptatif
- **ValidationCorrections.Tests.ps1** : Tests unitaires pour la fonctionnalitÃ© de validation des corrections
- **HelperFunctions.Tests.ps1** : Tests unitaires pour les fonctions auxiliaires
- **AdvancedErrorHandling.Simple.ps1** : Tests unitaires simplifiÃ©s pour la fonctionnalitÃ© de gestion des erreurs avancÃ©e

### Tests d'intÃ©gration

- **SimpleIntegration.Tests.ps1** : Tests d'intÃ©gration simples pour les opÃ©rations de fichier
- **ErrorLearningSystem.Integration.Tests.ps1** : Tests d'intÃ©gration pour le systÃ¨me d'apprentissage des erreurs
- **ErrorLearningSystem.Integration.Fixed.ps1** : Tests d'intÃ©gration corrigÃ©s pour le systÃ¨me d'apprentissage des erreurs
- **ErrorLearningSystem.Integration.Simple.ps1** : Tests d'intÃ©gration simplifiÃ©s pour le systÃ¨me d'apprentissage des erreurs

## Scripts d'exÃ©cution des tests

Plusieurs scripts sont disponibles pour exÃ©cuter les tests :

- **Run-AllTests.ps1** : ExÃ©cute tous les tests (unitaires et d'intÃ©gration)
- **Run-VeryBasicTests.ps1** : ExÃ©cute uniquement les tests trÃ¨s basiques
- **Run-BasicTests.ps1** : ExÃ©cute uniquement les tests basiques
- **Run-SimpleIntegrationTests.ps1** : ExÃ©cute uniquement les tests d'intÃ©gration simples
- **Run-SimpleIntegrationTests2.ps1** : ExÃ©cute uniquement les tests d'intÃ©gration simplifiÃ©s
- **Run-FixedIntegrationTests.ps1** : ExÃ©cute uniquement les tests d'intÃ©gration corrigÃ©s
- **Run-FunctionTests.ps1** : ExÃ©cute uniquement les tests des fonctions
- **Run-ErrorHandlingTests.ps1** : ExÃ©cute uniquement les tests de gestion des erreurs
- **Run-AdaptiveLearningTests.ps1** : ExÃ©cute uniquement les tests d'apprentissage adaptatif
- **Run-ValidationCorrectionsTests.ps1** : ExÃ©cute uniquement les tests de validation des corrections
- **Run-HelperFunctionsTests.ps1** : ExÃ©cute uniquement les tests des fonctions auxiliaires
- **Run-AdvancedErrorHandlingSimpleTests.ps1** : ExÃ©cute uniquement les tests de gestion des erreurs avancÃ©e simplifiÃ©s
- **Run-WorkingTests.ps1** : ExÃ©cute tous les tests qui fonctionnent correctement
- **Run-AllWorkingTests.ps1** : ExÃ©cute tous les tests qui fonctionnent correctement (version amÃ©liorÃ©e)

### ExÃ©cuter tous les tests

Pour exÃ©cuter tous les tests (unitaires et d'intÃ©gration), utilisez la commande suivante :

```powershell
.\Run-AllTests.ps1
```plaintext
### ExÃ©cuter uniquement les tests unitaires

Pour exÃ©cuter uniquement les tests unitaires, utilisez la commande suivante :

```powershell
.\Run-AllTests.ps1 -TestType Unit
```plaintext
### ExÃ©cuter uniquement les tests d'intÃ©gration

Pour exÃ©cuter uniquement les tests d'intÃ©gration, utilisez la commande suivante :

```powershell
.\Run-AllTests.ps1 -TestType Integration
```plaintext
### ExÃ©cuter tous les tests qui fonctionnent correctement

Pour exÃ©cuter tous les tests qui fonctionnent correctement, utilisez la commande suivante :

```powershell
.\Run-AllWorkingTests.ps1
```plaintext
## Automatisation des tests

Des scripts sont disponibles pour automatiser l'exÃ©cution des tests dans un pipeline CI/CD :

- **CI-CD/Run-TestsInCI.ps1** : Script pour exÃ©cuter les tests dans un pipeline CI/CD
- **CI-CD/github-workflow-tests.yml** : Fichier de configuration pour GitHub Actions

Pour exÃ©cuter les tests dans un pipeline CI/CD, utilisez la commande suivante :

```powershell
.\CI-CD\Run-TestsInCI.ps1
```plaintext
Ce script gÃ©nÃ¨re des rapports XML des rÃ©sultats des tests et de la couverture de code, qui peuvent Ãªtre utilisÃ©s par des outils d'intÃ©gration continue comme GitHub Actions.

## RÃ©sultats des tests

Les tests actuellement fonctionnels sont les suivants :

- Tests basiques : 6 tests rÃ©ussis
- Tests trÃ¨s basiques : 4 tests rÃ©ussis
- Tests d'intÃ©gration simples : 4 tests rÃ©ussis
- Tests des fonctions : 3 tests rÃ©ussis
- Tests de gestion des erreurs : 4 tests rÃ©ussis
- Tests d'apprentissage adaptatif : 5 tests rÃ©ussis
- Tests de validation des corrections : 5 tests rÃ©ussis
- Tests des fonctions auxiliaires : 12 tests rÃ©ussis
- Tests de gestion des erreurs avancÃ©e simplifiÃ©s : 4 tests rÃ©ussis

Total : 43 tests rÃ©ussis

## Ajout de nouveaux tests

Pour ajouter de nouveaux tests, crÃ©ez un fichier `.Tests.ps1` dans ce rÃ©pertoire. Assurez-vous de suivre les conventions suivantes :

- Utilisez le framework Pester pour Ã©crire les tests.
- Utilisez des blocs `Describe`, `Context` et `It` pour organiser les tests.
- Utilisez des assertions `Should` pour vÃ©rifier les rÃ©sultats.
- N'appelez pas `Invoke-Pester` Ã  la fin du fichier pour Ã©viter la rÃ©cursion infinie.
- Pour les tests d'intÃ©gration, utilisez le suffixe `.Integration.Tests.ps1` dans le nom du fichier.

## Bonnes pratiques

- Ã‰crivez des tests pour chaque nouvelle fonctionnalitÃ©.
- ExÃ©cutez les tests avant de soumettre des modifications.
- Assurez-vous que tous les tests passent avant de soumettre des modifications.
- Utilisez des assertions spÃ©cifiques pour vÃ©rifier les rÃ©sultats.
- Utilisez des mocks pour simuler des dÃ©pendances externes.
- Utilisez des paramÃ¨tres pour rendre les tests plus flexibles.
- Utilisez des blocs `BeforeAll` et `AfterAll` pour initialiser et nettoyer l'environnement de test.
