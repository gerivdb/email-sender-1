# Inspection Préventive des Scripts PowerShell

Ce module fournit des outils pour inspecter préventivement les scripts PowerShell et détecter les problèmes potentiels avant qu'ils ne deviennent des problèmes réels.

## Fonctionnalités

- **Analyse statique** des scripts PowerShell pour détecter les problèmes courants
- **Correction automatique** de certains problèmes (comparaisons avec `$null`, variables non utilisées, etc.)
- **Filtrage flexible** par sévérité, règle incluse/exclue, etc.
- **Analyse récursive** des scripts dans un dossier
- **Tests unitaires** pour vérifier le bon fonctionnement des outils

## Structure du module

- `Inspect-ScriptPreventively.ps1` : Script principal pour l'inspection préventive des scripts PowerShell
- `Repair-PSScriptAnalyzerIssues.ps1` : Script pour corriger automatiquement les problèmes détectés par PSScriptAnalyzer
- `Demo-PreventiveInspection.ps1` : Script de démonstration montrant l'utilisation des outils
- `tests/` : Tests unitaires pour les scripts

## Utilisation

### Inspection préventive des scripts

```powershell
# Analyser un script spécifique
.\Inspect-ScriptPreventively.ps1 -Path .\MonScript.ps1

# Analyser et corriger automatiquement un script
.\Inspect-ScriptPreventively.ps1 -Path .\MonScript.ps1 -Fix

# Analyser tous les scripts dans un dossier
.\Inspect-ScriptPreventively.ps1 -Path .\scripts\*.ps1 -Recurse

# Analyser et corriger tous les scripts dans un dossier
.\Inspect-ScriptPreventively.ps1 -Path .\scripts\*.ps1 -Recurse -Fix

# Filtrer par sévérité
.\Inspect-ScriptPreventively.ps1 -Path .\MonScript.ps1 -Severity Warning

# Filtrer par règle incluse
.\Inspect-ScriptPreventively.ps1 -Path .\MonScript.ps1 -IncludeRule PSPossibleIncorrectComparisonWithNull

# Filtrer par règle exclue
.\Inspect-ScriptPreventively.ps1 -Path .\MonScript.ps1 -ExcludeRule PSAvoidUsingWriteHost
```

### Correction automatique des problèmes PSScriptAnalyzer

```powershell
# Analyser un script spécifique
.\Repair-PSScriptAnalyzerIssues.ps1 -ScriptPath .\MonScript.ps1

# Analyser et corriger automatiquement un script
.\Repair-PSScriptAnalyzerIssues.ps1 -ScriptPath .\MonScript.ps1 -Fix

# Analyser et corriger tous les scripts dans un dossier, avec sauvegarde
.\Repair-PSScriptAnalyzerIssues.ps1 -ScriptPath .\scripts\*.ps1 -Fix -CreateBackup
```

### Exécution des tests unitaires

```powershell
# Exécuter tous les tests
.\tests\Run-Tests.ps1

# Exécuter un test spécifique
Invoke-Pester -Path .\tests\Inspect-ScriptPreventively.Tests.ps1
```

### Démonstration

Pour voir les outils en action :

```powershell
# Exécuter la démonstration
.\Demo-PreventiveInspection.ps1
```

## Problèmes détectés et corrigés

Les outils peuvent détecter et corriger automatiquement plusieurs types de problèmes :

- **Comparaisons incorrectes avec `$null`** : `$variable -eq $null` → `$null -eq $variable`
- **Variables non utilisées** : `$unused = "valeur"` → `"valeur" | Out-Null`
- **Verbes non approuvés** dans les noms de fonctions : `Fix-Problem` → `Repair-Problem`
- **Valeurs par défaut pour les paramètres de type switch** : `[switch]$Force = $true` → `[switch]$Force`
- **Assignations aux variables automatiques** comme `$matches`
- **Utilisation de `Write-Host`** au lieu de `Write-Output`, `Write-Verbose`, etc.
- **Noms pluriels** pour les fonctions et cmdlets

## Intégration dans le flux de travail

Ces outils peuvent être intégrés dans votre flux de travail de développement de plusieurs façons :

1. **Analyse manuelle** : Exécutez les scripts manuellement pour vérifier vos scripts
2. **Intégration dans l'IDE** : Configurez votre IDE pour exécuter les scripts automatiquement
3. **Hooks Git** : Configurez un hook pre-commit pour vérifier les scripts avant de les commiter
4. **Intégration continue** : Intégrez les scripts dans votre pipeline CI/CD

## Bonnes pratiques

- Exécutez régulièrement l'inspection préventive pour détecter les problèmes tôt
- Corrigez les problèmes dès qu'ils sont détectés
- Utilisez les filtres pour vous concentrer sur les problèmes les plus importants
- Intégrez l'inspection préventive dans votre flux de travail de développement
- Exécutez les tests unitaires après avoir modifié les scripts d'inspection
