<#
.SYNOPSIS
    Script pour corriger les fichiers de test du système d'apprentissage des erreurs.
.DESCRIPTION
    Ce script analyse et corrige les fichiers de test pour éviter les problèmes de récursion infinie.
.EXAMPLE
    .\Fix-TestFiles.ps1
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

# Fonction pour corriger un fichier de test
function Repair-TestFile {
    param (
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File
    )

    Write-Host "`nAnalyse de $($File.Name)..." -ForegroundColor Yellow

    # Lire le contenu du fichier
    $content = Get-Content -Path $File.FullName -Raw

    # Vérifier si le fichier contient un appel à Invoke-Pester
    if ($content -match "Invoke-Pester") {
        Write-Host "  Le fichier contient un appel à Invoke-Pester" -ForegroundColor Red

        # Remplacer l'appel à Invoke-Pester par un commentaire
        $newContent = $content -replace "(?m)^(.*Invoke-Pester.*$)", "# `$1 # Commenté pour éviter la récursion infinie"

        # Écrire le nouveau contenu dans le fichier
        Set-Content -Path $File.FullName -Value $newContent

        Write-Host "  Appel à Invoke-Pester commenté" -ForegroundColor Green
    }
    else {
        Write-Host "  Le fichier ne contient pas d'appel à Invoke-Pester" -ForegroundColor Green
    }

    # Vérifier si le fichier contient une référence à $PSCommandPath
    if ($content -match "\$PSCommandPath") {
        Write-Host "  Le fichier contient une référence à \$PSCommandPath" -ForegroundColor Red

        # Lire le contenu ligne par ligne
        $lines = Get-Content -Path $File.FullName
        $newLines = @()

        foreach ($line in $lines) {
            if ($line -match "\$PSCommandPath") {
                $newLines += "# $line # Commenté pour éviter la récursion infinie"
            }
            else {
                $newLines += $line
            }
        }

        # Écrire le nouveau contenu dans le fichier
        Set-Content -Path $File.FullName -Value $newLines

        Write-Host "  Références à \$PSCommandPath commentées" -ForegroundColor Green
    }
    else {
        Write-Host "  Le fichier ne contient pas de référence à \$PSCommandPath" -ForegroundColor Green
    }
}

# Corriger chaque fichier de test
foreach ($testFile in $testFiles) {
    Repair-TestFile -File $testFile
}

Write-Host "`nTous les fichiers de test ont été corrigés" -ForegroundColor Green
