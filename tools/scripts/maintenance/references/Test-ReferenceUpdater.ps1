<#
.SYNOPSIS
    Teste les fonctionnalitÃ©s de dÃ©tection et de mise Ã  jour des rÃ©fÃ©rences.

.DESCRIPTION
    Ce script crÃ©e un environnement de test pour vÃ©rifier le bon fonctionnement des scripts
    Detect-BrokenReferences.ps1 et Update-References.ps1. Il gÃ©nÃ¨re des fichiers de test
    contenant des rÃ©fÃ©rences brisÃ©es, exÃ©cute les scripts et vÃ©rifie les rÃ©sultats.

.PARAMETER TestDirectory
    RÃ©pertoire oÃ¹ crÃ©er l'environnement de test. Par dÃ©faut, utilise un sous-rÃ©pertoire "test" du rÃ©pertoire courant.

.PARAMETER CleanupAfterTest
    Si spÃ©cifiÃ©, supprime l'environnement de test aprÃ¨s l'exÃ©cution.

.EXAMPLE
    .\Test-ReferenceUpdater.ps1
    CrÃ©e un environnement de test, exÃ©cute les tests et conserve l'environnement pour inspection.

.EXAMPLE
    .\Test-ReferenceUpdater.ps1 -CleanupAfterTest
    CrÃ©e un environnement de test, exÃ©cute les tests et supprime l'environnement aprÃ¨s l'exÃ©cution.

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
    PrÃ©requis:      PowerShell 5.1 ou supÃ©rieur
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$TestDirectory = (Join-Path -Path (Get-Location).Path -ChildPath "test"),

    [Parameter(Mandatory = $false)]
    [switch]$CleanupAfterTest
)

# Fonction pour crÃ©er l'environnement de test
function Initialize-TestEnvironment {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestDir
    )

    if (Test-Path -Path $TestDir) {
        Write-Host "Suppression de l'environnement de test existant..."
        Remove-Item -Path $TestDir -Recurse -Force
    }

    Write-Host "CrÃ©ation de l'environnement de test..."
    New-Item -Path $TestDir -ItemType Directory -Force | Out-Null
    New-Item -Path (Join-Path -Path $TestDir -ChildPath "scripts") -ItemType Directory -Force | Out-Null
    New-Item -Path (Join-Path -Path $TestDir -ChildPath "docs") -ItemType Directory -Force | Out-Null
    New-Item -Path (Join-Path -Path $TestDir -ChildPath "md") -ItemType Directory -Force | Out-Null
    New-Item -Path (Join-Path -Path $TestDir -ChildPath "Roadmap") -ItemType Directory -Force | Out-Null

    # CrÃ©er des fichiers de test avec des rÃ©fÃ©rences brisÃ©es
    $testFiles = @{
        "scripts\test1.ps1" = @"
# Script de test 1
# RÃ©fÃ©rence Ã  un fichier roadmap
`$roadmapPath = "md\roadmap_perso.md"
Get-Content -Path `$roadmapPath
"@

        "scripts\test2.ps1" = @"
# Script de test 2
# RÃ©fÃ©rence Ã  un fichier roadmap avec sÃ©parateur /
`$roadmapPath = "md/roadmap_perso.md"
Get-Content -Path `$roadmapPath
"@

        "docs\documentation.md" = @"
# Documentation du projet

Voir la roadmap du projet pour plus d'informations: [Roadmap](../md/roadmap_perso.md)

Voir Ã©galement la nouvelle roadmap: [Nouvelle Roadmap](../Roadmap/roadmap_perso_new.md)
"@

        "Roadmap\README.md" = @"
# Roadmap du projet

Ce rÃ©pertoire contient les fichiers de roadmap du projet.

- [Roadmap principale](roadmap_perso.md)
- [Ancienne roadmap](../md/roadmap_perso.md)
- [Nouvelle roadmap](roadmap_perso_new.md)
"@
    }

    foreach ($file in $testFiles.Keys) {
        $filePath = Join-Path -Path $TestDir -ChildPath $file
        $content = $testFiles[$file]

        $fileDir = Split-Path -Path $filePath -Parent
        if (-not (Test-Path -Path $fileDir)) {
            New-Item -Path $fileDir -ItemType Directory -Force | Out-Null
        }

        Set-Content -Path $filePath -Value $content -Force -Encoding UTF8
    }

    # CrÃ©er les fichiers roadmap
    $roadmapContent = "# Roadmap du projet`n`nCe document contient la roadmap du projet."
    Set-Content -Path (Join-Path -Path $TestDir -ChildPath "md\roadmap_perso.md") -Value $roadmapContent -Force -Encoding UTF8
    Set-Content -Path (Join-Path -Path $TestDir -ChildPath "Roadmap\roadmap_perso_new.md") -Value $roadmapContent -Force -Encoding UTF8
    Set-Content -Path (Join-Path -Path $TestDir -ChildPath "Roadmap\roadmap_perso.md") -Value $roadmapContent -Force -Encoding UTF8

    Write-Host "Environnement de test crÃ©Ã© avec succÃ¨s: $TestDir"
}

# Fonction pour exÃ©cuter les tests
function Invoke-ReferenceTests {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestDir
    )

    Write-Host "`n=== Test de dÃ©tection des rÃ©fÃ©rences brisÃ©es ===`n"

    $detectScript = Join-Path -Path (Get-Location).Path -ChildPath "Detect-BrokenReferences.ps1"
    if (-not (Test-Path -Path $detectScript)) {
        Write-Error "Script de dÃ©tection non trouvÃ©: $detectScript"
        return $false
    }

    & $detectScript -ScanPath $TestDir -OutputPath $TestDir

    $detailedReport = Join-Path -Path $TestDir -ChildPath "broken_references_detailed.md"
    if (-not (Test-Path -Path $detailedReport)) {
        Write-Error "Rapport dÃ©taillÃ© non gÃ©nÃ©rÃ©: $detailedReport"
        return $false
    }

    Write-Host "`n=== Test de mise Ã  jour des rÃ©fÃ©rences brisÃ©es ===`n"

    $updateScript = Join-Path -Path (Get-Location).Path -ChildPath "Update-References.ps1"
    if (-not (Test-Path -Path $updateScript)) {
        Write-Error "Script de mise Ã  jour non trouvÃ©: $updateScript"
        return $false
    }

    & $updateScript -ScanPath $TestDir -OutputPath $TestDir -BackupFiles -ReportOnly

    $summaryReport = Join-Path -Path $TestDir -ChildPath "broken_references_summary.md"
    if (-not (Test-Path -Path $summaryReport)) {
        Write-Error "Rapport de synthÃ¨se non gÃ©nÃ©rÃ©: $summaryReport"
        return $false
    }

    Write-Host "`n=== VÃ©rification des sauvegardes et des mises Ã  jour ===`n"

    # Simuler une confirmation utilisateur
    Write-Host "Simulation de la confirmation utilisateur pour la mise Ã  jour..."
    & $updateScript -ScanPath $TestDir -OutputPath $TestDir -BackupFiles

    # VÃ©rifier que les fichiers ont Ã©tÃ© mis Ã  jour
    $updatedFiles = @(
        "scripts\test1.ps1",
        "scripts\test2.ps1",
        "docs\documentation.md"
    )

    $allUpdated = $true
    foreach ($file in $updatedFiles) {
        $filePath = Join-Path -Path $TestDir -ChildPath $file
        $content = Get-Content -Path $filePath -Raw

        if ($content -match "md[/\\]roadmap_perso\.md" -or $content -match "roadmap_perso_new\.md") {
            Write-Error "Le fichier n'a pas Ã©tÃ© correctement mis Ã  jour: $filePath"
            $allUpdated = $false
        }

        $backupPath = "$filePath.bak"
        if (-not (Test-Path -Path $backupPath)) {
            Write-Error "Sauvegarde non crÃ©Ã©e pour: $filePath"
            $allUpdated = $false
        }
    }

    if ($allUpdated) {
        Write-Host "Tous les fichiers ont Ã©tÃ© correctement mis Ã  jour et sauvegardÃ©s."
        return $true
    }
    else {
        Write-Error "Certains fichiers n'ont pas Ã©tÃ© correctement mis Ã  jour ou sauvegardÃ©s."
        return $false
    }
}

# Fonction pour nettoyer l'environnement de test
function Remove-TestEnvironment {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestDir
    )

    if (Test-Path -Path $TestDir) {
        Write-Host "Suppression de l'environnement de test..."
        Remove-Item -Path $TestDir -Recurse -Force
        Write-Host "Environnement de test supprimÃ©: $TestDir"
    }
}

# Fonction principale
function Main {
    Write-Host "=== Test des scripts de gestion des rÃ©fÃ©rences ==="
    Write-Host "RÃ©pertoire de test: $TestDirectory"

    Initialize-TestEnvironment -TestDir $TestDirectory

    $testResult = Invoke-ReferenceTests -TestDir $TestDirectory

    if ($CleanupAfterTest) {
        Remove-TestEnvironment -TestDir $TestDirectory
    }
    else {
        Write-Host "`nL'environnement de test a Ã©tÃ© conservÃ© pour inspection: $TestDirectory"
        Write-Host "Pour le supprimer manuellement, exÃ©cutez: Remove-Item -Path `"$TestDirectory`" -Recurse -Force"
    }

    if ($testResult) {
        Write-Host "`n=== Tests rÃ©ussis ! ==="
    }
    else {
        Write-Host "`n=== Tests Ã©chouÃ©s ! ===" -ForegroundColor Red
    }
}

# ExÃ©cution du script
Main
