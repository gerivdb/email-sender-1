# Mode MANAGER

Ce répertoire contient les scripts et la documentation du mode MANAGER, qui permet de gérer et d'orchestrer les différents modes opérationnels du projet.

## Structure du répertoire

- `mode-manager.ps1` : Script principal du mode MANAGER
- `install-mode-manager.ps1` : Script d'installation du mode MANAGER
- `update-mode-references.ps1` : Script pour mettre à jour les références aux modes dans les fichiers de documentation
- `tests/` : Répertoire contenant les tests du mode MANAGER
  - `Test-ModeManager.ps1` : Tests unitaires pour le script mode-manager.ps1
  - `Test-ModeManagerIntegration.ps1` : Tests d'intégration pour vérifier l'interaction avec les autres modes
  - `Test-ModeManagerPerformance.ps1` : Tests de performance pour mesurer les performances du mode MANAGER
  - `Test-ModeManagerInstallation.ps1` : Tests pour vérifier l'installation du mode MANAGER
  - `Run-AllTests.ps1` : Script pour exécuter tous les tests du mode MANAGER

## Installation

Pour installer le mode MANAGER, exécutez le script `install-mode-manager.ps1` :

```powershell
# Mode simulation (n'applique pas les modifications)
.\install-mode-manager.ps1

# Mode installation (applique les modifications)
.\install-mode-manager.ps1 -Force
```

## Utilisation

### Commande de base

```powershell
.\mode-manager.ps1 -Mode <MODE> -FilePath <FILEPATH> -TaskIdentifier <TASKID> [-Force]
```

### Paramètres

| Paramètre | Description | Obligatoire | Valeur par défaut |
|-----------|-------------|-------------|-------------------|
| Mode | Le mode à exécuter (ARCHI, CHECK, C-BREAK, DEBUG, DEV-R, GRAN, OPTI, PREDIC, REVIEW, TEST) | Oui (sauf avec -ListModes, -ShowConfig ou -Chain) | - |
| FilePath | Chemin vers le fichier de roadmap ou le document actif | Non | Valeur de configuration |
| TaskIdentifier | Identifiant de la tâche à traiter (ex: "1.2.3") | Non | - |
| ConfigPath | Chemin vers le fichier de configuration | Non | Chemin par défaut |
| Force | Indique si les modifications doivent être appliquées sans confirmation | Non | $false |
| ListModes | Affiche la liste des modes disponibles et leurs descriptions | Non | $false |
| ShowConfig | Affiche la configuration actuelle du mode spécifié | Non | $false |
| Chain | Chaîne de modes à exécuter séquentiellement (ex: "GRAN,DEV-R,CHECK") | Non | - |

### Exemples

#### Exécuter un mode spécifique

```powershell
# Exécuter le mode CHECK
.\mode-manager.ps1 -Mode CHECK -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3" -Force

# Exécuter le mode GRAN
.\mode-manager.ps1 -Mode GRAN -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3"
```

#### Afficher la liste des modes disponibles

```powershell
.\mode-manager.ps1 -ListModes
```

#### Afficher la configuration d'un mode

```powershell
.\mode-manager.ps1 -ShowConfig -Mode CHECK
```

#### Exécuter une chaîne de modes

```powershell
# Exécuter GRAN, puis DEV-R, puis CHECK
.\mode-manager.ps1 -Chain "GRAN,DEV-R,CHECK" -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3"
```

## Tests

Pour exécuter les tests du mode MANAGER, utilisez le script `tests/Run-AllTests.ps1` :

```powershell
# Exécuter tous les tests
.\tests\Run-AllTests.ps1 -OutputPath "reports" -GenerateHTML

# Exécuter uniquement les tests unitaires
.\tests\Run-AllTests.ps1 -TestType Unit -OutputPath "reports" -GenerateHTML

# Exécuter uniquement les tests d'intégration
.\tests\Run-AllTests.ps1 -TestType Integration -OutputPath "reports" -GenerateHTML

# Exécuter uniquement les tests de performance
.\tests\Run-AllTests.ps1 -TestType Performance -OutputPath "reports" -GenerateHTML

# Exécuter tous les tests sauf les tests de performance
.\tests\Run-AllTests.ps1 -SkipPerformanceTests -OutputPath "reports" -GenerateHTML
```

### Types de tests

Le mode MANAGER dispose de plusieurs types de tests :

1. **Tests unitaires** : Vérifient le bon fonctionnement des fonctions individuelles du mode MANAGER.
2. **Tests d'intégration** : Vérifient l'interaction du mode MANAGER avec les autres modes.
3. **Tests de performance** : Mesurent les performances du mode MANAGER (temps d'exécution, consommation de mémoire).
4. **Tests d'installation** : Vérifient que le mode MANAGER est correctement installé et configuré.

## Documentation

La documentation complète du mode MANAGER se trouve dans le fichier `development\docs\guides\methodologies\mode_manager.md`.

## Configuration

La configuration du mode MANAGER se trouve dans le fichier `development\roadmap\parser\config\modes-config.json`.

## Mise à jour des références

Pour mettre à jour les références aux modes dans les fichiers de documentation, utilisez le script `update-mode-references.ps1` :

```powershell
# Mode simulation (n'applique pas les modifications)
.\update-mode-references.ps1

# Mode mise à jour (applique les modifications)
.\update-mode-references.ps1 -Force
```
