<#
.SYNOPSIS
    Teste les fonctionnalités de détection et de mise à jour des références.

.DESCRIPTION
    Ce script crée un environnement de test pour vérifier le bon fonctionnement des scripts
    Detect-BrokenReferences.ps1 et Update-References.ps1. Il génère des fichiers de test
    contenant des références brisées, exécute les scripts et vérifie les résultats.

.PARAMETER TestDirectory
    Répertoire où créer l'environnement de test. Par défaut, utilise un sous-répertoire "test" du répertoire courant.

.PARAMETER CleanupAfterTest
    Si spécifié, supprime l'environnement de test après l'exécution.

.EXAMPLE
    .\Test-ReferenceUpdater.ps1
    Crée un environnement de test, exécute les tests et conserve l'environnement pour inspection.

.EXAMPLE
    .\Test-ReferenceUpdater.ps1 -CleanupAfterTest
    Crée un environnement de test, exécute les tests et supprime l'environnement après l'exécution.

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date création:  09/04/2025
    Prérequis:      PowerShell 5.1 ou supérieur
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$TestDirectory = (Join-Path -Path (Get-Location).Path -ChildPath "test"),

    [Parameter(Mandatory = $false)]
    [switch]$CleanupAfterTest
)

# Fonction pour créer l'environnement de test
function Initialize-TestEnvironment {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestDir
    )

    if (Test-Path -Path $TestDir) {
        Write-Host "Suppression de l'environnement de test existant..."
        Remove-Item -Path $TestDir -Recurse -Force
    }

    Write-Host "Création de l'environnement de test..."
    New-Item -Path $TestDir -ItemType Directory -Force | Out-Null
    New-Item -Path (Join-Path -Path $TestDir -ChildPath "scripts") -ItemType Directory -Force | Out-Null
    New-Item -Path (Join-Path -Path $TestDir -ChildPath "docs") -ItemType Directory -Force | Out-Null
    New-Item -Path (Join-Path -Path $TestDir -ChildPath "md") -ItemType Directory -Force | Out-Null
    New-Item -Path (Join-Path -Path $TestDir -ChildPath "Roadmap") -ItemType Directory -Force | Out-Null

    # Créer des fichiers de test avec des références brisées
    $testFiles = @{
        "scripts\test1.ps1" = @"
# Script de test 1
# Référence à un fichier roadmap
`$roadmapPath = "md\roadmap_perso.md"
Get-Content -Path `$roadmapPath
"@

        "scripts\test2.ps1" = @"
# Script de test 2
# Référence à un fichier roadmap avec séparateur /
`$roadmapPath = "md/roadmap_perso.md"
Get-Content -Path `$roadmapPath
"@

        "docs\documentation.md" = @"
# Documentation du projet

Voir la roadmap du projet pour plus d'informations: [Roadmap](../md/roadmap_perso.md)

Voir également la nouvelle roadmap: [Nouvelle Roadmap](../Roadmap/roadmap_perso_new.md)
"@

        "Roadmap\README.md" = @"
# Roadmap du projet

Ce répertoire contient les fichiers de roadmap du projet.

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

    # Créer les fichiers roadmap
    $roadmapContent = "# Roadmap du projet`n`nCe document contient la roadmap du projet."
    Set-Content -Path (Join-Path -Path $TestDir -ChildPath "md\roadmap_perso.md") -Value $roadmapContent -Force -Encoding UTF8
    Set-Content -Path (Join-Path -Path $TestDir -ChildPath "Roadmap\roadmap_perso_new.md") -Value $roadmapContent -Force -Encoding UTF8
    Set-Content -Path (Join-Path -Path $TestDir -ChildPath "Roadmap\roadmap_perso.md") -Value $roadmapContent -Force -Encoding UTF8

    Write-Host "Environnement de test créé avec succès: $TestDir"
}

# Fonction pour exécuter les tests
function Invoke-ReferenceTests {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestDir
    )

    Write-Host "`n=== Test de détection des références brisées ===`n"

    $detectScript = Join-Path -Path (Get-Location).Path -ChildPath "Detect-BrokenReferences.ps1"
    if (-not (Test-Path -Path $detectScript)) {
        Write-Error "Script de détection non trouvé: $detectScript"
        return $false
    }

    & $detectScript -ScanPath $TestDir -OutputPath $TestDir

    $detailedReport = Join-Path -Path $TestDir -ChildPath "broken_references_detailed.md"
    if (-not (Test-Path -Path $detailedReport)) {
        Write-Error "Rapport détaillé non généré: $detailedReport"
        return $false
    }

    Write-Host "`n=== Test de mise à jour des références brisées ===`n"

    $updateScript = Join-Path -Path (Get-Location).Path -ChildPath "Update-References.ps1"
    if (-not (Test-Path -Path $updateScript)) {
        Write-Error "Script de mise à jour non trouvé: $updateScript"
        return $false
    }

    & $updateScript -ScanPath $TestDir -OutputPath $TestDir -BackupFiles -ReportOnly

    $summaryReport = Join-Path -Path $TestDir -ChildPath "broken_references_summary.md"
    if (-not (Test-Path -Path $summaryReport)) {
        Write-Error "Rapport de synthèse non généré: $summaryReport"
        return $false
    }

    Write-Host "`n=== Vérification des sauvegardes et des mises à jour ===`n"

    # Simuler une confirmation utilisateur
    Write-Host "Simulation de la confirmation utilisateur pour la mise à jour..."
    & $updateScript -ScanPath $TestDir -OutputPath $TestDir -BackupFiles

    # Vérifier que les fichiers ont été mis à jour
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
            Write-Error "Le fichier n'a pas été correctement mis à jour: $filePath"
            $allUpdated = $false
        }

        $backupPath = "$filePath.bak"
        if (-not (Test-Path -Path $backupPath)) {
            Write-Error "Sauvegarde non créée pour: $filePath"
            $allUpdated = $false
        }
    }

    if ($allUpdated) {
        Write-Host "Tous les fichiers ont été correctement mis à jour et sauvegardés."
        return $true
    }
    else {
        Write-Error "Certains fichiers n'ont pas été correctement mis à jour ou sauvegardés."
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
        Write-Host "Environnement de test supprimé: $TestDir"
    }
}

# Fonction principale
function Main {
    Write-Host "=== Test des scripts de gestion des références ==="
    Write-Host "Répertoire de test: $TestDirectory"

    Initialize-TestEnvironment -TestDir $TestDirectory

    $testResult = Invoke-ReferenceTests -TestDir $TestDirectory

    if ($CleanupAfterTest) {
        Remove-TestEnvironment -TestDir $TestDirectory
    }
    else {
        Write-Host "`nL'environnement de test a été conservé pour inspection: $TestDirectory"
        Write-Host "Pour le supprimer manuellement, exécutez: Remove-Item -Path `"$TestDirectory`" -Recurse -Force"
    }

    if ($testResult) {
        Write-Host "`n=== Tests réussis ! ==="
    }
    else {
        Write-Host "`n=== Tests échoués ! ===" -ForegroundColor Red
    }
}

# Exécution du script
Main
