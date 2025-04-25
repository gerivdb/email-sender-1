# Tests du système d'apprentissage des erreurs PowerShell

Ce répertoire contient les tests unitaires et d'intégration pour le système d'apprentissage des erreurs PowerShell.

## Structure des tests

### Tests basiques

- **VeryBasic.Tests.ps1** : Tests très basiques pour les opérations mathématiques de base
- **Basic.Tests.ps1** : Tests basiques pour les opérations d'addition et de soustraction
- **Simple.Tests.ps1** : Tests simples pour vérifier le fonctionnement de Pester

### Tests unitaires

- **ErrorLearningSystem.Tests.ps1** : Tests pour le module principal
- **Analyze-ScriptForErrors.Tests.ps1** : Tests pour le script d'analyse des erreurs dans les scripts
- **Auto-CorrectErrors.Tests.ps1** : Tests pour le script de correction automatique des erreurs
- **Adaptive-ErrorCorrection.Tests.ps1** : Tests pour le script d'apprentissage adaptatif
- **Validate-ErrorCorrections.Tests.ps1** : Tests pour le script de validation des corrections
- **ErrorFunctions.Tests.ps1** : Tests unitaires pour les fonctions du système d'apprentissage des erreurs
- **ErrorHandling.Tests.ps1** : Tests unitaires pour la gestion des erreurs PowerShell
- **AdaptiveLearning.Tests.ps1** : Tests unitaires pour la fonctionnalité d'apprentissage adaptatif
- **ValidationCorrections.Tests.ps1** : Tests unitaires pour la fonctionnalité de validation des corrections
- **HelperFunctions.Tests.ps1** : Tests unitaires pour les fonctions auxiliaires
- **AdvancedErrorHandling.Simple.ps1** : Tests unitaires simplifiés pour la fonctionnalité de gestion des erreurs avancée

### Tests d'intégration

- **SimpleIntegration.Tests.ps1** : Tests d'intégration simples pour les opérations de fichier
- **ErrorLearningSystem.Integration.Tests.ps1** : Tests d'intégration pour le système d'apprentissage des erreurs
- **ErrorLearningSystem.Integration.Fixed.ps1** : Tests d'intégration corrigés pour le système d'apprentissage des erreurs
- **ErrorLearningSystem.Integration.Simple.ps1** : Tests d'intégration simplifiés pour le système d'apprentissage des erreurs

## Scripts d'exécution des tests

Plusieurs scripts sont disponibles pour exécuter les tests :

- **Run-AllTests.ps1** : Exécute tous les tests (unitaires et d'intégration)
- **Run-VeryBasicTests.ps1** : Exécute uniquement les tests très basiques
- **Run-BasicTests.ps1** : Exécute uniquement les tests basiques
- **Run-SimpleIntegrationTests.ps1** : Exécute uniquement les tests d'intégration simples
- **Run-SimpleIntegrationTests2.ps1** : Exécute uniquement les tests d'intégration simplifiés
- **Run-FixedIntegrationTests.ps1** : Exécute uniquement les tests d'intégration corrigés
- **Run-FunctionTests.ps1** : Exécute uniquement les tests des fonctions
- **Run-ErrorHandlingTests.ps1** : Exécute uniquement les tests de gestion des erreurs
- **Run-AdaptiveLearningTests.ps1** : Exécute uniquement les tests d'apprentissage adaptatif
- **Run-ValidationCorrectionsTests.ps1** : Exécute uniquement les tests de validation des corrections
- **Run-HelperFunctionsTests.ps1** : Exécute uniquement les tests des fonctions auxiliaires
- **Run-AdvancedErrorHandlingSimpleTests.ps1** : Exécute uniquement les tests de gestion des erreurs avancée simplifiés
- **Run-WorkingTests.ps1** : Exécute tous les tests qui fonctionnent correctement
- **Run-AllWorkingTests.ps1** : Exécute tous les tests qui fonctionnent correctement (version améliorée)

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

### Exécuter tous les tests qui fonctionnent correctement

Pour exécuter tous les tests qui fonctionnent correctement, utilisez la commande suivante :

```powershell
.\Run-AllWorkingTests.ps1
```

## Automatisation des tests

Des scripts sont disponibles pour automatiser l'exécution des tests dans un pipeline CI/CD :

- **CI-CD/Run-TestsInCI.ps1** : Script pour exécuter les tests dans un pipeline CI/CD
- **CI-CD/github-workflow-tests.yml** : Fichier de configuration pour GitHub Actions

Pour exécuter les tests dans un pipeline CI/CD, utilisez la commande suivante :

```powershell
.\CI-CD\Run-TestsInCI.ps1
```

Ce script génère des rapports XML des résultats des tests et de la couverture de code, qui peuvent être utilisés par des outils d'intégration continue comme GitHub Actions.

## Résultats des tests

Les tests actuellement fonctionnels sont les suivants :

- Tests basiques : 6 tests réussis
- Tests très basiques : 4 tests réussis
- Tests d'intégration simples : 4 tests réussis
- Tests des fonctions : 3 tests réussis
- Tests de gestion des erreurs : 4 tests réussis
- Tests d'apprentissage adaptatif : 5 tests réussis
- Tests de validation des corrections : 5 tests réussis
- Tests des fonctions auxiliaires : 12 tests réussis
- Tests de gestion des erreurs avancée simplifiés : 4 tests réussis

Total : 43 tests réussis

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
