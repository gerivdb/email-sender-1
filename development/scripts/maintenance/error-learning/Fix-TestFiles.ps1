<#
.SYNOPSIS
    Script pour corriger les fichiers de test du systÃ¨me d'apprentissage des erreurs.
.DESCRIPTION
    Ce script analyse et corrige les fichiers de test pour Ã©viter les problÃ¨mes de rÃ©cursion infinie.
.EXAMPLE
    .\Fix-TestFiles.ps1
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

# Fonction pour corriger un fichier de test
function Repair-TestFile {
    param (
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File
    )

    Write-Host "`nAnalyse de $($File.Name)..." -ForegroundColor Yellow

    # Lire le contenu du fichier
    $content = Get-Content -Path $File.FullName -Raw

    # VÃ©rifier si le fichier contient un appel Ã  Invoke-Pester
    if ($content -match "Invoke-Pester") {
        Write-Host "  Le fichier contient un appel Ã  Invoke-Pester" -ForegroundColor Red

        # Remplacer l'appel Ã  Invoke-Pester par un commentaire
        $newContent = $content -replace "(?m)^(.*Invoke-Pester.*$)", "# `$1 # CommentÃ© pour Ã©viter la rÃ©cursion infinie"

        # Ã‰crire le nouveau contenu dans le fichier
        Set-Content -Path $File.FullName -Value $newContent

        Write-Host "  Appel Ã  Invoke-Pester commentÃ©" -ForegroundColor Green
    }
    else {
        Write-Host "  Le fichier ne contient pas d'appel Ã  Invoke-Pester" -ForegroundColor Green
    }

    # VÃ©rifier si le fichier contient une rÃ©fÃ©rence Ã  $PSCommandPath
    if ($content -match "\$PSCommandPath") {
        Write-Host "  Le fichier contient une rÃ©fÃ©rence Ã  \$PSCommandPath" -ForegroundColor Red

        # Lire le contenu ligne par ligne
        $lines = Get-Content -Path $File.FullName
        $newLines = @()

        foreach ($line in $lines) {
            if ($line -match "\$PSCommandPath") {
                $newLines += "# $line # CommentÃ© pour Ã©viter la rÃ©cursion infinie"
            }
            else {
                $newLines += $line
            }
        }

        # Ã‰crire le nouveau contenu dans le fichier
        Set-Content -Path $File.FullName -Value $newLines

        Write-Host "  RÃ©fÃ©rences Ã  \$PSCommandPath commentÃ©es" -ForegroundColor Green
    }
    else {
        Write-Host "  Le fichier ne contient pas de rÃ©fÃ©rence Ã  \$PSCommandPath" -ForegroundColor Green
    }
}

# Corriger chaque fichier de test
foreach ($testFile in $testFiles) {
    Repair-TestFile -File $testFile
}

Write-Host "`nTous les fichiers de test ont Ã©tÃ© corrigÃ©s" -ForegroundColor Green
