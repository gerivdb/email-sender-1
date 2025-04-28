# Tests pour la structure de documentation Augment

Ce dossier contient les tests unitaires et d'intégration pour la structure de documentation Augment.

## Fichiers de test

- **Test-AugmentDocumentation.ps1** : Tests unitaires pour vérifier la structure des fichiers et dossiers
- **Test-AugmentIntegration.ps1** : Tests d'intégration pour vérifier l'accès aux fichiers par Augment
- **Run-AugmentTests.ps1** : Script pour exécuter tous les tests et générer un rapport

## Exécution des tests

Pour exécuter tous les tests et générer un rapport HTML :

```powershell
.\Run-AugmentTests.ps1
```

Par défaut, le rapport sera généré dans le dossier `development/testing/tests/augment/reports`. Vous pouvez spécifier un autre dossier avec le paramètre `-OutputPath` :

```powershell
.\Run-AugmentTests.ps1 -OutputPath "D:\Reports"
```

## Prérequis

- PowerShell 5.1 ou supérieur
- Module Pester (installé automatiquement si nécessaire)

## Structure des tests

### Tests unitaires

Les tests unitaires vérifient :
- L'existence des dossiers et fichiers
- La validité du format JSON pour le fichier de configuration
- La validité du format Markdown pour les fichiers de documentation
- L'intégration à la roadmap

### Tests d'intégration

Les tests d'intégration vérifient :
- La configuration VS Code pour Augment
- L'accès aux fichiers comme le ferait Augment
- La validité des patterns de fichiers dans la configuration

## Rapports

Les rapports générés incluent :
- Un fichier XML au format NUnit
- Un rapport HTML avec les résultats détaillés
- Des statistiques de couverture de code

## Intégration continue

Ces tests peuvent être intégrés dans un pipeline CI/CD pour vérifier automatiquement la structure de documentation Augment à chaque modification.
