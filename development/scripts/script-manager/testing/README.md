# Tests unitaires du script manager

Ce dossier contient les tests unitaires pour le script manager. Les tests sont écrits en utilisant le framework Pester et sont organisés en plusieurs catégories.

## Structure des tests

Les tests sont organisés en plusieurs catégories :

- **Tests de structure** : Vérifient que la structure du dossier manager est correcte.
- **Tests des fonctions d'organisation** : Vérifient que les fonctions d'organisation des scripts fonctionnent correctement.
- **Tests des fonctions d'analyse** : Vérifient que les fonctions d'analyse des scripts fonctionnent correctement.
- **Tests des fonctions d'inventaire** : Vérifient que les fonctions d'inventaire des scripts fonctionnent correctement.
- **Tests d'intégration** : Vérifient que les différentes parties du script manager fonctionnent correctement ensemble.

## Types de tests

Il existe plusieurs types de tests :

- **Tests originaux** : Les tests originaux qui ont été créés pour le script manager.
- **Tests simplifiés** : Des versions simplifiées des tests qui ne nécessitent pas de modifications de l'environnement.
- **Tests corrigés** : Des versions corrigées des tests qui utilisent des mocks pour éviter de modifier l'environnement.

## Scripts d'exécution des tests

Plusieurs scripts sont disponibles pour exécuter les tests :

- **Run-AllManagerTests.ps1** : Exécute tous les tests (originaux, simplifiés et corrigés) et génère des rapports détaillés.
- **Run-SimplifiedTests.ps1** : Exécute uniquement les tests simplifiés.
- **Run-FixedTests.ps1** : Exécute uniquement les tests corrigés.

### Exemples d'utilisation

```powershell
# Exécuter tous les tests et générer des rapports HTML

.\Run-AllManagerTests.ps1 -OutputPath ".\reports\tests" -GenerateHTML

# Exécuter uniquement les tests corrigés liés à l'organisation

.\Run-FixedTests.ps1 -TestName "Organization" -OutputPath ".\reports\tests" -GenerateHTML

# Exécuter uniquement les tests simplifiés

.\Run-SimplifiedTests.ps1 -OutputPath ".\reports\tests" -GenerateHTML
```plaintext
## Rapports de tests

Les rapports de tests sont générés au format XML et HTML. Les rapports XML sont compatibles avec les outils d'intégration continue comme Jenkins, TeamCity, etc. Les rapports HTML sont plus faciles à lire et à interpréter.

### Structure des rapports

Les rapports HTML contiennent les informations suivantes :

- **Résumé global** : Nombre total de tests exécutés, réussis, échoués et ignorés.
- **Détails des tests** : Détails de chaque test exécuté, y compris les messages d'erreur en cas d'échec.
- **Recommandations** : Recommandations pour améliorer les tests unitaires.

## Problèmes connus et solutions

### Problème 1 : Les fonctions testées ne sont pas correctement importées dans les tests

**Solution** : Utiliser les tests corrigés qui importent correctement les fonctions à tester.

### Problème 2 : Le script d'organisation déplace les fichiers avant que les tests ne puissent les vérifier

**Solution** : Utiliser les tests corrigés qui utilisent des mocks pour simuler les opérations de fichier.

### Problème 3 : Le téléchargement de ReportUnit échoue

**Solution** : Utiliser le paramètre `-SkipDownload` pour ignorer le téléchargement de ReportUnit.

## Recommandations pour améliorer les tests

1. **Utiliser des mocks** : Pour éviter que les tests ne modifient réellement les fichiers, il est recommandé d'utiliser des mocks pour simuler les opérations de fichier.
2. **Isoler les tests** : Chaque test devrait être indépendant des autres tests, ce qui signifie qu'il ne devrait pas dépendre de l'état laissé par un test précédent.
3. **Utiliser des fixtures** : Pour préparer l'environnement de test, il est recommandé d'utiliser des fixtures qui créent un environnement de test propre avant chaque test et le nettoient après.
4. **Intégrer les tests dans le processus de CI/CD** : Les tests devraient être exécutés automatiquement lors des commits et des pull requests pour s'assurer que les modifications ne cassent pas le code existant.

## Ressources supplémentaires

- [Documentation Pester](https://pester.dev/docs/quick-start)
- [Guide des mocks Pester](https://pester.dev/docs/usage/mocking)
- [Guide des assertions Pester](https://pester.dev/docs/usage/assertions)
