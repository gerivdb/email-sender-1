# Test-MarkdownFormatValidation.ps1
# Script pour tester la fonction Test-MarkdownFormat

# Importer la fonction Ã  tester
$functionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\Test-MarkdownFormat.ps1"
. $functionPath

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier markdown valide
$validMarkdownPath = Join-Path -Path $testDir -ChildPath "valid.md"
$validMarkdown = @"
# Roadmap Valide

Ceci est une roadmap valide pour tester la fonction Test-MarkdownFormat.

## Section 1

- [ ] **1** TÃ¢che 1
  - [x] **1.1** TÃ¢che 1.1
  - [ ] **1.2** TÃ¢che 1.2

## Section 2

- [ ] **2** TÃ¢che 2
  - [ ] **2.1** TÃ¢che 2.1
"@

$validMarkdown | Out-File -FilePath $validMarkdownPath -Encoding UTF8

# CrÃ©er un fichier markdown invalide
$invalidMarkdownPath = Join-Path -Path $testDir -ChildPath "invalid.md"
$invalidMarkdown = @"
Roadmap Invalide

Cette roadmap est invalide car elle n'a pas de titre avec #.

Section 1

- TÃ¢che sans case Ã  cocher
- [ ] TÃ¢che sans identifiant
- [x] **1** TÃ¢che valide

Section 2

* Autre tÃ¢che sans case Ã  cocher
"@

$invalidMarkdown | Out-File -FilePath $invalidMarkdownPath -Encoding UTF8

# CrÃ©er un fichier markdown partiellement valide
$partiallyValidMarkdownPath = Join-Path -Path $testDir -ChildPath "partially-valid.md"
$partiallyValidMarkdown = @"
# Roadmap Partiellement Valide

Cette roadmap est partiellement valide.

## Section 1

- [ ] **1** TÃ¢che valide
- TÃ¢che sans case Ã  cocher
- [ ] TÃ¢che sans identifiant

## Section 2

- [ ] **2** TÃ¢che valide
"@

$partiallyValidMarkdown | Out-File -FilePath $partiallyValidMarkdownPath -Encoding UTF8

Write-Host "Fichiers de test crÃ©Ã©s." -ForegroundColor Green

try {
    # Test 1: Validation d'un fichier valide
    Write-Host "`nTest 1: Validation d'un fichier valide" -ForegroundColor Cyan
    $result = Test-MarkdownFormat -FilePath $validMarkdownPath

    if ($result.IsValid) {
        Write-Host "âœ“ Le fichier valide est correctement validÃ©" -ForegroundColor Green
    } else {
        Write-Host "âœ— Le fichier valide n'est pas correctement validÃ©" -ForegroundColor Red
        Write-Host "Erreurs: $($result.Errors -join ', ')" -ForegroundColor Red
        Write-Host "Avertissements: $($result.Warnings -join ', ')" -ForegroundColor Yellow
    }

    # VÃ©rifier les statistiques
    Write-Host "Statistiques:" -ForegroundColor Yellow
    Write-Host "  - Nombre de lignes: $($result.Statistics.TotalLines)" -ForegroundColor Yellow
    Write-Host "  - Nombre de titres: $($result.Statistics.TitleCount)" -ForegroundColor Yellow
    Write-Host "  - Nombre de sections: $($result.Statistics.SectionCount)" -ForegroundColor Yellow
    Write-Host "  - Nombre de tÃ¢ches: $($result.Statistics.TaskCount)" -ForegroundColor Yellow
    Write-Host "  - TÃ¢ches avec ID: $($result.Statistics.TaskWithIdCount)" -ForegroundColor Yellow
    Write-Host "  - TÃ¢ches sans ID: $($result.Statistics.TaskWithoutIdCount)" -ForegroundColor Yellow
    Write-Host "  - TÃ¢ches avec case Ã  cocher: $($result.Statistics.TaskWithCheckboxCount)" -ForegroundColor Yellow
    Write-Host "  - TÃ¢ches sans case Ã  cocher: $($result.Statistics.TaskWithoutCheckboxCount)" -ForegroundColor Yellow

    # Test 2: Validation d'un fichier invalide
    Write-Host "`nTest 2: Validation d'un fichier invalide" -ForegroundColor Cyan
    $result = Test-MarkdownFormat -FilePath $invalidMarkdownPath

    if (-not $result.IsValid) {
        Write-Host "âœ“ Le fichier invalide est correctement dÃ©tectÃ© comme invalide" -ForegroundColor Green
    } else {
        Write-Host "âœ— Le fichier invalide est incorrectement validÃ©" -ForegroundColor Red
    }

    Write-Host "Avertissements: $($result.Warnings.Count)" -ForegroundColor Yellow
    if ($result.Warnings.Count -gt 0) {
        foreach ($warning in $result.Warnings) {
            Write-Host "  - $warning" -ForegroundColor Yellow
        }
    }

    # Test 3: Validation stricte d'un fichier partiellement valide
    Write-Host "`nTest 3: Validation stricte d'un fichier partiellement valide" -ForegroundColor Cyan
    $result = Test-MarkdownFormat -FilePath $partiallyValidMarkdownPath -Strict

    if (-not $result.IsValid) {
        Write-Host "âœ“ Le fichier partiellement valide est correctement dÃ©tectÃ© comme invalide en mode strict" -ForegroundColor Green
    } else {
        Write-Host "âœ— Le fichier partiellement valide est incorrectement validÃ© en mode strict" -ForegroundColor Red
    }

    Write-Host "Erreurs: $($result.Errors.Count)" -ForegroundColor Yellow
    if ($result.Errors.Count -gt 0) {
        foreach ($error in $result.Errors) {
            Write-Host "  - $error" -ForegroundColor Yellow
        }
    }

    # Test 4: Validation non stricte d'un fichier partiellement valide
    Write-Host "`nTest 4: Validation non stricte d'un fichier partiellement valide" -ForegroundColor Cyan
    $result = Test-MarkdownFormat -FilePath $partiallyValidMarkdownPath

    if (-not $result.IsValid) {
        Write-Host "âœ“ Le fichier partiellement valide est correctement dÃ©tectÃ© comme invalide en mode non strict" -ForegroundColor Green
    } else {
        Write-Host "âœ— Le fichier partiellement valide est incorrectement validÃ© en mode non strict" -ForegroundColor Red
    }

    Write-Host "Avertissements: $($result.Warnings.Count)" -ForegroundColor Yellow
    if ($result.Warnings.Count -gt 0) {
        foreach ($warning in $result.Warnings) {
            Write-Host "  - $warning" -ForegroundColor Yellow
        }
    }

    Write-Host "`nTous les tests sont terminÃ©s." -ForegroundColor Green
} catch {
    Write-Host "Erreur lors des tests: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
} finally {
    # Nettoyer les fichiers de test
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
        Write-Host "`nRÃ©pertoire de test nettoyÃ©: $testDir" -ForegroundColor Gray
    }
}
