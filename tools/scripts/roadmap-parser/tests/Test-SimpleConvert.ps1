﻿# Test pour la fonction simplifiÃ©e ConvertFrom-MarkdownToObject

# Importer la fonction
$functionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\Simple-ConvertFromMarkdown.ps1"
. $functionPath

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier markdown de test simple
$simpleMarkdownPath = Join-Path -Path $testDir -ChildPath "simple.md"
@"
# Roadmap Simple

Ceci est une roadmap simple pour les tests.

## Section 1

- [ ] TÃ¢che 1

## Section 2

- [ ] TÃ¢che 2
"@ | Out-File -FilePath $simpleMarkdownPath -Encoding UTF8

Write-Host "Fichier markdown de test crÃ©Ã©: $simpleMarkdownPath" -ForegroundColor Green

# Tester la fonction
try {
    Write-Host "Test: Conversion simple" -ForegroundColor Cyan
    $result = ConvertFrom-MarkdownToObject -FilePath $simpleMarkdownPath
    
    Write-Host "Titre: $($result.Title)" -ForegroundColor Yellow
    Write-Host "Description: $($result.Description)" -ForegroundColor Yellow
    Write-Host "Nombre de sections: $($result.Items.Count)" -ForegroundColor Yellow
    
    foreach ($section in $result.Items) {
        Write-Host "Section: $($section.Title)" -ForegroundColor Magenta
    }
    
    Write-Host "Test rÃ©ussi!" -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors du test: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}
finally {
    # Nettoyer les fichiers de test
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
        Write-Host "RÃ©pertoire de test nettoyÃ©: $testDir" -ForegroundColor Gray
    }
}
