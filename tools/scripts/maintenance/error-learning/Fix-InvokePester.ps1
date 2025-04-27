<#
.SYNOPSIS
    Script pour corriger les appels Ã  Invoke-Pester dans les fichiers de test.
.DESCRIPTION
    Ce script commente les appels Ã  Invoke-Pester dans les fichiers de test pour Ã©viter les problÃ¨mes de rÃ©cursion infinie.
.EXAMPLE
    .\Fix-InvokePester.ps1
    Corrige tous les fichiers de test.
#>

[CmdletBinding()]
param ()

# DÃ©finir le chemin des tests
$testRoot = Join-Path -Path $PSScriptRoot -ChildPath "Tests"
$testFiles = Get-ChildItem -Path $testRoot -Filter "*.Tests.ps1" -Recurse

# Afficher les tests trouvÃ©s
Write-Host "Fichiers de test trouvÃ©s :" -ForegroundColor Cyan
foreach ($testFile in $testFiles) {
    Write-Host "  $($testFile.Name)" -ForegroundColor Yellow
}

# Corriger chaque fichier de test
foreach ($testFile in $testFiles) {
    Write-Host "`nAnalyse de $($testFile.Name)..." -ForegroundColor Yellow
    
    # Lire le contenu du fichier ligne par ligne
    $lines = Get-Content -Path $testFile.FullName
    $newLines = @()
    $modified = $false
    
    foreach ($line in $lines) {
        if ($line -match "Invoke-Pester") {
            $newLines += "# $line # CommentÃ© pour Ã©viter la rÃ©cursion infinie"
            $modified = $true
            Write-Host "  Appel Ã  Invoke-Pester commentÃ©" -ForegroundColor Green
        }
        else {
            $newLines += $line
        }
    }
    
    # Ã‰crire le nouveau contenu dans le fichier si des modifications ont Ã©tÃ© apportÃ©es
    if ($modified) {
        Set-Content -Path $testFile.FullName -Value $newLines
    }
    else {
        Write-Host "  Aucun appel Ã  Invoke-Pester trouvÃ©" -ForegroundColor Yellow
    }
}

Write-Host "`nTous les fichiers de test ont Ã©tÃ© corrigÃ©s" -ForegroundColor Green
