# Hooks Git pour l'analyse des erreurs

Ce répertoire contient des hooks Git pour l'analyse des erreurs dans les scripts PowerShell.

## Hooks disponibles

### pre-commit

Le hook `pre-commit` analyse les fichiers PowerShell modifiés (staged) pour détecter les erreurs potentielles avant de les committer. Il utilise le module `ErrorPatternAnalyzer` pour l'analyse.

### post-commit

Le hook `post-commit` analyse les fichiers PowerShell modifiés dans le dernier commit et enrichit le journal de développement avec les résultats d'analyse. Il génère également un rapport d'analyse au format Markdown.

## Installation

Pour installer les hooks Git, exécutez le script `Install-GitHooks.ps1` :

```powershell
.\git-hooks\Install-GitHooks.ps1
```

Pour forcer la réinstallation des hooks existants, utilisez le paramètre `-Force` :

```powershell
.\git-hooks\Install-GitHooks.ps1 -Force
```

## Configuration

La configuration des hooks se trouve dans le répertoire `config`. Vous pouvez modifier les fichiers de configuration pour personnaliser le comportement des hooks.

### pre-commit-config.json

Ce fichier contient la configuration du hook `pre-commit` :

```json
{
    "IgnorePatterns": [
        "PSAvoidUsingWriteHost",
        "PSAvoidUsingPositionalParameters"
    ],
    "SeverityLevel": "Warning",
    "MaxErrors": 10,
    "ExcludePaths": [
        "node_modules",
        "vendor",
        "dist",
        "out",
        "tests",
        "examples"
    ]
}
```

- `IgnorePatterns` : Liste des patterns d'erreurs à ignorer
- `SeverityLevel` : Niveau de sévérité minimum pour bloquer le commit (Error, Warning, Information)
- `MaxErrors` : Nombre maximum d'erreurs autorisées avant de bloquer le commit
- `ExcludePaths` : Liste des chemins à exclure de l'analyse

## Rapports

Les rapports générés par les hooks se trouvent dans le répertoire `reports`. Chaque exécution d'un hook génère un rapport au format Markdown.

## Tests

Des tests unitaires sont disponibles dans le répertoire `tests`. Pour exécuter les tests, utilisez le script `Run-Tests.ps1` :

```powershell
.\git-hooks\Run-Tests.ps1
```

Pour afficher les résultats détaillés des tests, utilisez le paramètre `-ShowTestResults` :

```powershell
.\git-hooks\Run-Tests.ps1 -ShowTestResults
```

Pour générer un rapport de test au format HTML, utilisez le paramètre `-GenerateReport` :

```powershell
.\git-hooks\Run-Tests.ps1 -GenerateReport
```

Pour des tests plus simples, vous pouvez utiliser le script `Simple-Tests.ps1` :

```powershell
.\git-hooks\tests\Simple-Tests.ps1
```

## Désactivation temporaire

Pour désactiver temporairement un hook, vous pouvez utiliser l'option `--no-verify` lors de la commande Git :

```bash
git commit --no-verify -m "Message de commit"
```

## Dépendances

Les hooks dépendent du module `ErrorPatternAnalyzer` qui doit être présent dans le répertoire `development/scripts/maintenance/error-learning` du dépôt.
