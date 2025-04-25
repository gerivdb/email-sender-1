# Base de connaissances des erreurs

Ce document centralise les erreurs rencontrées et leurs solutions pour faciliter le dépannage futur.

## Erreurs PowerShell

### PSUseApprovedVerbs

**Description** : Utilisation d'un verbe non approuvé dans le nom d'une fonction ou cmdlet PowerShell.

**Exemple d'erreur** :
```
The cmdlet 'Fix-NullComparisons' uses an unapproved verb.
```

**Solution** :
- Remplacer le verbe non approuvé par un verbe approuvé de la liste `Get-Verb`
- Correspondances courantes :
  - `Fix-` → `Repair-` ou `Update-`
  - `Extract-` → `Get-` ou `Export-`
  - `Create-` → `New-`

**Code corrigé** :
```powershell
# Avant
function Fix-NullComparisons { ... }

# Après
function Repair-NullComparisons { ... }
```

### PSAvoidAssignmentToAutomaticVariable

**Description** : Assignation à une variable automatique de PowerShell, ce qui peut avoir des effets secondaires indésirables.

**Exemple d'erreur** :
```
The Variable 'Matches' is an automatic variable that is built into PowerShell, assigning to it might have undesired side effects.
```

**Solution** :
- Utiliser un nom de variable différent
- Pour les expressions régulières, utiliser `$RegexMatches` au lieu de `$Matches`

**Code corrigé** :
```powershell
# Avant
$Matches = [regex]::Matches($Content, $Pattern)

# Après
$RegexMatches = [regex]::Matches($Content, $Pattern)
```

### Missing closing '}' in statement block

**Description** : Accolade fermante manquante dans un bloc de code.

**Cause** : Souvent causé par des problèmes d'échappement dans les expressions régulières ou les chaînes de caractères.

**Solution** :
- Vérifier l'équilibre des accolades dans le code
- Utiliser des guillemets simples pour les expressions régulières
- Échapper correctement les caractères spéciaux

**Code corrigé** :
```powershell
# Avant (problématique)
if (-not ($Content -match "if\s+__name__\s*==\s*['""]__main__['""]")) {
    # Code
}

# Après (corrigé)
if (-not ($Content -match 'if\s+__name__\s*==\s*[''"]__main__[''"]')) {
    # Code
}
```

### Unexpected token in expression or statement

**Description** : Token inattendu dans une expression ou une instruction.

**Cause** : Souvent causé par des problèmes d'échappement ou de syntaxe dans les expressions régulières.

**Solution** :
- Vérifier la syntaxe des expressions régulières
- Utiliser des guillemets simples pour les expressions régulières complexes
- Tester les expressions régulières séparément

## Erreurs d'encodage de fichiers

### Problèmes d'encodage UTF-8 avec/sans BOM

**Description** : Problèmes de compatibilité liés à l'encodage des fichiers.

**Symptômes** :
- Caractères spéciaux mal affichés
- Erreurs d'exécution dans les scripts
- Problèmes de compatibilité entre systèmes

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

### Accès refusé ou fichier introuvable

**Description** : Erreurs lors de la lecture, écriture ou modification de fichiers.

**Symptômes** :
- Exception "Access denied"
- Exception "File not found"
- Exception "Path too long"

**Solution** :
- Vérifier l'existence des chemins avant d'y accéder
  ```powershell
  if (Test-Path -Path $FilePath -ErrorAction SilentlyContinue) {
      # Opérations sur le fichier
  }
  ```
- Utiliser des blocs try/catch pour gérer les erreurs
  ```powershell
  try {
      $Content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
  } catch {
      Write-Log "Erreur lors de la lecture du fichier: $_" -Level "ERROR"
  }
  ```
- Vérifier les chaînes nulles ou vides
  ```powershell
  if (-not [string]::IsNullOrWhiteSpace($FilePath)) {
      # Opérations sur le fichier
  }
  ```

## Bonnes pratiques pour éviter les erreurs

### Système de journalisation unifié

Implémenter un système de journalisation cohérent pour faciliter le débogage :

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
    
    # Écrire dans un fichier de log
    $LogFile = "scripts\manager\data\log_file.log"
    Add-Content -Path $LogFile -Value $FormattedMessage -ErrorAction SilentlyContinue
}
```

### Mode simulation avant application

Implémenter un mode simulation pour tester les modifications avant de les appliquer :

```powershell
function Update-Files {
    param (
        [string]$Path,
        [switch]$Apply
    )
    
    # Logique de mise à jour
    
    if ($Apply) {
        # Appliquer les modifications
        Set-Content -Path $FilePath -Value $NewContent
        Write-Log "Modifications appliquées" -Level "SUCCESS"
    } else {
        # Simuler les modifications
        Write-Log "Modifications simulées (non appliquées)" -Level "WARNING"
    }
}
```

### Tests unitaires pour les fonctions critiques

Créer des tests unitaires pour les fonctions critiques :

```powershell
# Fonction à tester
function Repair-NullComparisons {
    param ([string]$Content)
    return $Content -replace "(\$[A-Za-z0-9_]+)\s+-eq\s+\$null", "`$null -eq `$1"
}

# Test unitaire
$TestContent = '$variable -eq $null'
$ExpectedResult = '$null -eq $variable'
$ActualResult = Repair-NullComparisons -Content $TestContent

if ($ActualResult -eq $ExpectedResult) {
    Write-Host "Test réussi" -ForegroundColor Green
} else {
    Write-Host "Test échoué" -ForegroundColor Red
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

*Dernière mise à jour: 08/04/2025 19:45*
