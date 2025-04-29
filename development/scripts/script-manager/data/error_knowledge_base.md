# Base de connaissances des erreurs

Ce document centralise les erreurs rencontrÃ©es et leurs solutions pour faciliter le dÃ©pannage futur.

## Erreurs PowerShell

### PSUseApprovedVerbs

**Description** : Utilisation d'un verbe non approuvÃ© dans le nom d'une fonction ou cmdlet PowerShell.

**Exemple d'erreur** :
```
The cmdlet 'Fix-NullComparisons' uses an unapproved verb.
```

**Solution** :
- Remplacer le verbe non approuvÃ© par un verbe approuvÃ© de la liste `Get-Verb`
- Correspondances courantes :
  - `Fix-` â†’ `Repair-` ou `Update-`
  - `Extract-` â†’ `Get-` ou `Export-`
  - `Create-` â†’ `New-`

**Code corrigÃ©** :
```powershell
# Avant
function Fix-NullComparisons { ... }

# AprÃ¨s
function Repair-NullComparisons { ... }
```

### PSAvoidAssignmentToAutomaticVariable

**Description** : Assignation Ã  une variable automatique de PowerShell, ce qui peut avoir des effets secondaires indÃ©sirables.

**Exemple d'erreur** :
```
The Variable 'Matches' is an automatic variable that is built into PowerShell, assigning to it might have undesired side effects.
```

**Solution** :
- Utiliser un nom de variable diffÃ©rent
- Pour les expressions rÃ©guliÃ¨res, utiliser `$RegexMatches` au lieu de `$Matches`

**Code corrigÃ©** :
```powershell
# Avant
$Matches = [regex]::Matches($Content, $Pattern)

# AprÃ¨s
$RegexMatches = [regex]::Matches($Content, $Pattern)
```

### Missing closing '}' in statement block

**Description** : Accolade fermante manquante dans un bloc de code.

**Cause** : Souvent causÃ© par des problÃ¨mes d'Ã©chappement dans les expressions rÃ©guliÃ¨res ou les chaÃ®nes de caractÃ¨res.

**Solution** :
- VÃ©rifier l'Ã©quilibre des accolades dans le code
- Utiliser des guillemets simples pour les expressions rÃ©guliÃ¨res
- Ã‰chapper correctement les caractÃ¨res spÃ©ciaux

**Code corrigÃ©** :
```powershell
# Avant (problÃ©matique)
if (-not ($Content -match "if\s+__name__\s*==\s*['""]__main__['""]")) {
    # Code
}

# AprÃ¨s (corrigÃ©)
if (-not ($Content -match 'if\s+__name__\s*==\s*[''"]__main__[''"]')) {
    # Code
}
```

### Unexpected token in expression or statement

**Description** : Token inattendu dans une expression ou une instruction.

**Cause** : Souvent causÃ© par des problÃ¨mes d'Ã©chappement ou de syntaxe dans les expressions rÃ©guliÃ¨res.

**Solution** :
- VÃ©rifier la syntaxe des expressions rÃ©guliÃ¨res
- Utiliser des guillemets simples pour les expressions rÃ©guliÃ¨res complexes
- Tester les expressions rÃ©guliÃ¨res sÃ©parÃ©ment

## Erreurs d'encodage de fichiers

### ProblÃ¨mes d'encodage UTF-8 avec/sans BOM

**Description** : ProblÃ¨mes de compatibilitÃ© liÃ©s Ã  l'encodage des fichiers.

**SymptÃ´mes** :
- CaractÃ¨res spÃ©ciaux mal affichÃ©s
- Erreurs d'exÃ©cution dans les scripts
- ProblÃ¨mes de compatibilitÃ© entre systÃ¨mes

**Solution** :
- Pour PowerShell : Utiliser UTF-8 avec BOM
  ```powershell
  [System.IO.File]::WriteAllText($FilePath, $Content, [System.Text.Encoding]::UTF8)
  ```
- Pour Python et Shell : Utiliser UTF-8 sans BOM
  ```powershell
  $Utf8NoBom = New-Object System.Text.UTF8Encoding $false
  [System.IO.File]::WriteAllText($FilePath, $Content, $Utf8NoBom)
  ```

## Erreurs de manipulation de fichiers

### AccÃ¨s refusÃ© ou fichier introuvable

**Description** : Erreurs lors de la lecture, Ã©criture ou modification de fichiers.

**SymptÃ´mes** :
- Exception "Access denied"
- Exception "File not found"
- Exception "Path too long"

**Solution** :
- VÃ©rifier l'existence des chemins avant d'y accÃ©der
  ```powershell
  if (Test-Path -Path $FilePath -ErrorAction SilentlyContinue) {
      # OpÃ©rations sur le fichier
  }
  ```
- Utiliser des blocs try/catch pour gÃ©rer les erreurs
  ```powershell
  try {
      $Content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
  } catch {
      Write-Log "Erreur lors de la lecture du fichier: $_" -Level "ERROR"
  }
  ```
- VÃ©rifier les chaÃ®nes nulles ou vides
  ```powershell
  if (-not [string]::IsNullOrWhiteSpace($FilePath)) {
      # OpÃ©rations sur le fichier
  }
  ```

## Bonnes pratiques pour Ã©viter les erreurs

### SystÃ¨me de journalisation unifiÃ©

ImplÃ©menter un systÃ¨me de journalisation cohÃ©rent pour faciliter le dÃ©bogage :

```powershell
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "TITLE")]
        [string]$Level = "INFO"
    )
    
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR" = "Red"
        "TITLE" = "Cyan"
    }
    
    $Color = $ColorMap[$Level]
    $FormattedMessage = "[$TimeStamp] [$Level] $Message"
    
    Write-Host $FormattedMessage -ForegroundColor $Color
    
    # Ã‰crire dans un fichier de log
    $LogFile = "scripts\\mode-manager\data\log_file.log"
    Add-Content -Path $LogFile -Value $FormattedMessage -ErrorAction SilentlyContinue
}
```

### Mode simulation avant application

ImplÃ©menter un mode simulation pour tester les modifications avant de les appliquer :

```powershell
function Update-Files {
    param (
        [string]$Path,
        [switch]$Apply
    )
    
    # Logique de mise Ã  jour
    
    if ($Apply) {
        # Appliquer les modifications
        Set-Content -Path $FilePath -Value $NewContent
        Write-Log "Modifications appliquÃ©es" -Level "SUCCESS"
    } else {
        # Simuler les modifications
        Write-Log "Modifications simulÃ©es (non appliquÃ©es)" -Level "WARNING"
    }
}
```

### Tests unitaires pour les fonctions critiques

CrÃ©er des tests unitaires pour les fonctions critiques :

```powershell
# Fonction Ã  tester
function Repair-NullComparisons {
    param ([string]$Content)
    return $Content -replace "(\$[A-Za-z0-9_]+)\s+-eq\s+\$null", "`$null -eq `$1"
}

# Test unitaire
$TestContent = '$variable -eq $null'
$ExpectedResult = '$null -eq $variable'
$ActualResult = Repair-NullComparisons -Content $TestContent

if ($ActualResult -eq $ExpectedResult) {
    Write-Host "Test rÃ©ussi" -ForegroundColor Green
} else {
    Write-Host "Test Ã©chouÃ©" -ForegroundColor Red
    Write-Host "Attendu: $ExpectedResult" -ForegroundColor Yellow
    Write-Host "Obtenu: $ActualResult" -ForegroundColor Yellow
}
```

## Ressources

- [PowerShell Approved Verbs](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands)
- [PowerShell Best Practices](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/cmdlet-development-guidelines)
- [Regular Expressions in PowerShell](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_regular_expressions)
- [Error Handling in PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-exceptions)

---

*DerniÃ¨re mise Ã  jour: 08/04/2025 19:45*

