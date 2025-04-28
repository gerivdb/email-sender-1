# Inspection PrÃ©ventive des Scripts PowerShell

Ce module fournit des outils pour inspecter prÃ©ventivement les scripts PowerShell et dÃ©tecter les problÃ¨mes potentiels avant qu'ils ne deviennent des problÃ¨mes rÃ©els.

## FonctionnalitÃ©s

- **Analyse statique** des scripts PowerShell pour dÃ©tecter les problÃ¨mes courants
- **Correction automatique** de certains problÃ¨mes (comparaisons avec `$null`, variables non utilisÃ©es, etc.)
- **Filtrage flexible** par sÃ©vÃ©ritÃ©, rÃ¨gle incluse/exclue, etc.
- **Analyse rÃ©cursive** des scripts dans un dossier
- **Tests unitaires** pour vÃ©rifier le bon fonctionnement des outils

## Structure du module

- `Inspect-ScriptPreventively.ps1` : Script principal pour l'inspection prÃ©ventive des scripts PowerShell
- `Repair-PSScriptAnalyzerIssues.ps1` : Script pour corriger automatiquement les problÃ¨mes dÃ©tectÃ©s par PSScriptAnalyzer
- `Demo-PreventiveInspection.ps1` : Script de dÃ©monstration montrant l'utilisation des outils
- `development/testing/tests/` : Tests unitaires pour les scripts

## Utilisation

### Inspection prÃ©ventive des scripts

```powershell
# Analyser un script spÃ©cifique
.\Inspect-ScriptPreventively.ps1 -Path .\MonScript.ps1

# Analyser et corriger automatiquement un script
.\Inspect-ScriptPreventively.ps1 -Path .\MonScript.ps1 -Fix

# Analyser tous les scripts dans un dossier
.\Inspect-ScriptPreventively.ps1 -Path .\development\scripts\*.ps1 -Recurse

# Analyser et corriger tous les scripts dans un dossier
.\Inspect-ScriptPreventively.ps1 -Path .\development\scripts\*.ps1 -Recurse -Fix

# Filtrer par sÃ©vÃ©ritÃ©
.\Inspect-ScriptPreventively.ps1 -Path .\MonScript.ps1 -Severity Warning

# Filtrer par rÃ¨gle incluse
.\Inspect-ScriptPreventively.ps1 -Path .\MonScript.ps1 -IncludeRule PSPossibleIncorrectComparisonWithNull

# Filtrer par rÃ¨gle exclue
.\Inspect-ScriptPreventively.ps1 -Path .\MonScript.ps1 -ExcludeRule PSAvoidUsingWriteHost
```

### Correction automatique des problÃ¨mes PSScriptAnalyzer

```powershell
# Analyser un script spÃ©cifique
.\Repair-PSScriptAnalyzerIssues.ps1 -ScriptPath .\MonScript.ps1

# Analyser et corriger automatiquement un script
.\Repair-PSScriptAnalyzerIssues.ps1 -ScriptPath .\MonScript.ps1 -Fix

# Analyser et corriger tous les scripts dans un dossier, avec sauvegarde
.\Repair-PSScriptAnalyzerIssues.ps1 -ScriptPath .\development\scripts\*.ps1 -Fix -CreateBackup
```

### ExÃ©cution des tests unitaires

```powershell
# ExÃ©cuter tous les tests
.\development\testing\tests\Run-Tests.ps1

# ExÃ©cuter un test spÃ©cifique
Invoke-Pester -Path .\development\testing\tests\Inspect-ScriptPreventively.Tests.ps1
```

### DÃ©monstration

Pour voir les outils en action :

```powershell
# ExÃ©cuter la dÃ©monstration
.\Demo-PreventiveInspection.ps1
```

## ProblÃ¨mes dÃ©tectÃ©s et corrigÃ©s

Les outils peuvent dÃ©tecter et corriger automatiquement plusieurs types de problÃ¨mes :

- **Comparaisons incorrectes avec `$null`** : `$variable -eq $null` â†’ `$null -eq $variable`
- **Variables non utilisÃ©es** : `$unused = "valeur"` â†’ `"valeur" | Out-Null`
- **Verbes non approuvÃ©s** dans les noms de fonctions : `Fix-Problem` â†’ `Repair-Problem`
- **Valeurs par dÃ©faut pour les paramÃ¨tres de type switch** : `[switch]$Force = $true` â†’ `[switch]$Force`
- **Assignations aux variables automatiques** comme `$matches`
- **Utilisation de `Write-Host`** au lieu de `Write-Output`, `Write-Verbose`, etc.
- **Noms pluriels** pour les fonctions et cmdlets

## IntÃ©gration dans le flux de travail

Ces outils peuvent Ãªtre intÃ©grÃ©s dans votre flux de travail de dÃ©veloppement de plusieurs faÃ§ons :

1. **Analyse manuelle** : ExÃ©cutez les scripts manuellement pour vÃ©rifier vos scripts
2. **IntÃ©gration dans l'IDE** : Configurez votre IDE pour exÃ©cuter les scripts automatiquement
3. **Hooks Git** : Configurez un hook pre-commit pour vÃ©rifier les scripts avant de les commiter
4. **IntÃ©gration continue** : IntÃ©grez les scripts dans votre pipeline CI/CD

## Bonnes pratiques

- ExÃ©cutez rÃ©guliÃ¨rement l'inspection prÃ©ventive pour dÃ©tecter les problÃ¨mes tÃ´t
- Corrigez les problÃ¨mes dÃ¨s qu'ils sont dÃ©tectÃ©s
- Utilisez les filtres pour vous concentrer sur les problÃ¨mes les plus importants
- IntÃ©grez l'inspection prÃ©ventive dans votre flux de travail de dÃ©veloppement
- ExÃ©cutez les tests unitaires aprÃ¨s avoir modifiÃ© les scripts d'inspection
