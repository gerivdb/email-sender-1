# Tests du Mode Manager

Ce répertoire contient les tests pour le mode manager. Les tests sont organisés par type et peuvent être exécutés individuellement ou tous ensemble.

## Structure des tests

Les tests sont organisés en plusieurs catégories :

- **Tests de base** : Vérifient les fonctionnalités de base du mode manager.
- **Tests d'intégration** : Vérifient que le mode manager s'intègre correctement avec d'autres composants.
- **Tests de performance** : Vérifient que le mode manager est efficace.
- **Tests de workflow** : Vérifient que le mode manager peut exécuter des séquences de modes.
- **Tests d'erreur** : Vérifient que le mode manager gère correctement les erreurs.
- **Tests de configuration** : Vérifient que le mode manager gère correctement les configurations.
- **Tests de sécurité** : Vérifient que le mode manager est résistant aux tentatives d'injection de commandes.
- **Tests de documentation** : Vérifient que le mode manager fournit une aide intégrée correcte et complète.
- **Tests d'installation** : Vérifient que le mode manager peut être installé, mis à jour et désinstallé correctement.
- **Tests de régression** : Vérifient que les corrections de bugs ne réintroduisent pas des problèmes précédemment résolus.
- **Tests de compatibilité** : Vérifient que le mode manager fonctionne correctement sur différentes versions de PowerShell.
- **Tests de localisation** : Vérifient que le mode manager gère correctement les différentes langues et cultures.

## Exécution des tests

### Exécuter tous les tests

Pour exécuter tous les tests, utilisez le script `Run-AllTests.ps1` :

```powershell
.\Run-AllTests.ps1
```plaintext
### Exécuter un type de test spécifique

Pour exécuter un type de test spécifique, utilisez le paramètre `-TestType` :

```powershell
.\Run-AllTests.ps1 -TestType Unit
```plaintext
Les types de tests disponibles sont :

- `All` : Tous les tests
- `Unit` : Tests unitaires
- `Integration` : Tests d'intégration
- `Performance` : Tests de performance
- `Workflow` : Tests de workflow
- `Error` : Tests d'erreur
- `Config` : Tests de configuration
- `Simple` : Tests simples
- `PerformanceAdvanced` : Tests de performance avancés
- `WorkflowAdvanced` : Tests de workflow avancés
- `UI` : Tests d'interface utilisateur
- `Security` : Tests de sécurité
- `Documentation` : Tests de documentation
- `Installation` : Tests d'installation
- `Regression` : Tests de régression
- `Load` : Tests de charge
- `IntegrationRoadmapParser` : Tests d'intégration avec le roadmap parser
- `Compatibility` : Tests de compatibilité
- `Localization` : Tests de localisation
- `LongTermPerformance` : Tests de performance à long terme
- `IntegrationReporting` : Tests d'intégration avec le générateur de rapports

### Exécuter les tests avec couverture de code

Pour exécuter les tests avec couverture de code, utilisez le script `Run-TestsWithCoverage.ps1` :

```powershell
.\Run-TestsWithCoverage.ps1
```plaintext
Ce script exécute les tests et génère un rapport de couverture de code. Le rapport est généré au format HTML et peut être ouvert automatiquement.

### Exécuter les tests dans un environnement CI/CD

Pour exécuter les tests dans un environnement CI/CD, utilisez le script `Run-AllTestsCI.ps1` :

```powershell
.\Run-AllTestsCI.ps1
```plaintext
Ce script exécute les tests en parallèle et génère des rapports au format XML et HTML. Les rapports peuvent être publiés dans un pipeline CI/CD.

## Génération de rapports

### Générer un rapport de couverture de code

Pour générer un rapport de couverture de code, utilisez le script `Generate-CoverageReport.ps1` :

```powershell
.\Generate-CoverageReport.ps1
```plaintext
Ce script génère un rapport de couverture de code au format HTML et un fichier de synthèse au format Markdown.

### Générer un badge de couverture de code

Pour générer un badge de couverture de code, utilisez le script `Generate-CoverageBadge.ps1` :

```powershell
.\Generate-CoverageBadge.ps1
```plaintext
Ce script génère un badge de couverture de code au format SVG et met à jour le fichier README.md avec le badge.

## Intégration CI/CD

Les tests peuvent être intégrés dans un pipeline CI/CD. Des fichiers de configuration sont disponibles pour GitHub Actions et Azure DevOps Pipelines :

- `.github/workflows/mode-manager-tests.yml` : Configuration pour GitHub Actions
- `azure-pipelines/mode-manager-tests.yml` : Configuration pour Azure DevOps Pipelines

Ces fichiers de configuration exécutent les tests sur différentes plateformes (Windows, Linux) et versions de PowerShell (5.1, 7+), et publient les résultats des tests et la couverture de code.
