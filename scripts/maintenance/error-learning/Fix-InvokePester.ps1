<#
.SYNOPSIS
    Script pour corriger les appels à Invoke-Pester dans les fichiers de test.
.DESCRIPTION
    Ce script commente les appels à Invoke-Pester dans les fichiers de test pour éviter les problèmes de récursion infinie.
.EXAMPLE
    .\Fix-InvokePester.ps1
    Corrige tous les fichiers de test.
#>

[CmdletBinding()]
param ()

# Définir le chemin des tests
$testRoot = Join-Path -Path $PSScriptRoot -ChildPath "Tests"
$testFiles = Get-ChildItem -Path $testRoot -Filter "*.Tests.ps1" -Recurse

# Afficher les tests trouvés
Write-Host "Fichiers de test trouvés :" -ForegroundColor Cyan
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
            $newLines += "# $line # Commenté pour éviter la récursion infinie"
            $modified = $true
            Write-Host "  Appel à Invoke-Pester commenté" -ForegroundColor Green
        }
        else {
            $newLines += $line
        }
    }
    
    # Écrire le nouveau contenu dans le fichier si des modifications ont été apportées
    if ($modified) {
        Set-Content -Path $testFile.FullName -Value $newLines
    }
    else {
        Write-Host "  Aucun appel à Invoke-Pester trouvé" -ForegroundColor Yellow
    }
}

Write-Host "`nTous les fichiers de test ont été corrigés" -ForegroundColor Green
