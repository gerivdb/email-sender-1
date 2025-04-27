<#
.SYNOPSIS
    Interface utilisateur pour les outils de gestion des rÃ©fÃ©rences.

.DESCRIPTION
    Ce script fournit une interface utilisateur simple pour exÃ©cuter les outils de gestion des rÃ©fÃ©rences.
    Il permet de dÃ©tecter et de mettre Ã  jour les rÃ©fÃ©rences brisÃ©es dans les fichiers du projet.

.PARAMETER ScanPath
    Chemin du rÃ©pertoire Ã  analyser. Par dÃ©faut, utilise le rÃ©pertoire racine du projet.

.EXAMPLE
    .\Start-ReferenceManager.ps1
    Lance l'interface utilisateur pour les outils de gestion des rÃ©fÃ©rences.

.EXAMPLE
    .\Start-ReferenceManager.ps1 -ScanPath "D:\Projets\EMAIL_SENDER_1"
    Lance l'interface utilisateur en spÃ©cifiant le rÃ©pertoire Ã  analyser.

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
    PrÃ©requis:      PowerShell 5.1 ou supÃ©rieur
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ScanPath = ""
)

# Fonction pour obtenir le rÃ©pertoire racine du projet
function Get-ProjectRoot {
    $currentDir = Get-Location
    
    # Remonter jusqu'Ã  trouver un rÃ©pertoire contenant un dossier .git ou atteindre la racine du disque
    while ($true) {
        if (Test-Path -Path (Join-Path -Path $currentDir -ChildPath ".git") -PathType Container) {
            return $currentDir
        }
        
        $parentDir = Split-Path -Path $currentDir -Parent
        if ($parentDir -eq $null -or $parentDir -eq $currentDir) {
            # Nous avons atteint la racine du disque ou un autre point oÃ¹ nous ne pouvons plus remonter
            return $currentDir
        }
        
        $currentDir = $parentDir
    }
}

# Fonction pour afficher le menu principal
function Show-MainMenu {
    Clear-Host
    Write-Host "=== Gestionnaire de rÃ©fÃ©rences ==="
    Write-Host
    Write-Host "RÃ©pertoire analysÃ©: $ScanPath"
    Write-Host
    Write-Host "1. DÃ©tecter les rÃ©fÃ©rences brisÃ©es"
    Write-Host "2. Mettre Ã  jour les rÃ©fÃ©rences brisÃ©es"
    Write-Host "3. ExÃ©cuter les tests"
    Write-Host "4. Changer le rÃ©pertoire Ã  analyser"
    Write-Host "5. Quitter"
    Write-Host
    
    $choice = Read-Host "Choisissez une option (1-5)"
    return $choice
}

# Fonction pour exÃ©cuter la dÃ©tection des rÃ©fÃ©rences brisÃ©es
function Invoke-DetectReferences {
    Clear-Host
    Write-Host "=== DÃ©tection des rÃ©fÃ©rences brisÃ©es ==="
    Write-Host
    Write-Host "RÃ©pertoire analysÃ©: $ScanPath"
    Write-Host
    
    $outputPath = Read-Host "Chemin de sortie pour les rapports (laisser vide pour utiliser le rÃ©pertoire courant)"
    if ([string]::IsNullOrWhiteSpace($outputPath)) {
        $outputPath = Get-Location
    }
    
    $useCustomMappings = Read-Host "Utiliser des mappages personnalisÃ©s? (O/N)"
    $customMappingsPath = ""
    
    if ($useCustomMappings -eq "O" -or $useCustomMappings -eq "o") {
        $customMappingsPath = Read-Host "Chemin du fichier de mappages personnalisÃ©s"
        if (-not (Test-Path -Path $customMappingsPath)) {
            Write-Host "Le fichier de mappages personnalisÃ©s n'existe pas: $customMappingsPath" -ForegroundColor Red
            Read-Host "Appuyez sur EntrÃ©e pour continuer"
            return
        }
    }
    
    Write-Host
    Write-Host "ExÃ©cution de la dÃ©tection des rÃ©fÃ©rences brisÃ©es..."
    Write-Host
    
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Detect-BrokenReferences.ps1"
    
    if ($customMappingsPath -ne "") {
        & $scriptPath -ScanPath $ScanPath -OutputPath $outputPath -CustomMappings $customMappingsPath
    }
    else {
        & $scriptPath -ScanPath $ScanPath -OutputPath $outputPath
    }
    
    Write-Host
    Read-Host "Appuyez sur EntrÃ©e pour continuer"
}

# Fonction pour exÃ©cuter la mise Ã  jour des rÃ©fÃ©rences brisÃ©es
function Invoke-UpdateReferences {
    Clear-Host
    Write-Host "=== Mise Ã  jour des rÃ©fÃ©rences brisÃ©es ==="
    Write-Host
    Write-Host "RÃ©pertoire analysÃ©: $ScanPath"
    Write-Host
    
    $outputPath = Read-Host "Chemin de sortie pour les rapports (laisser vide pour utiliser le rÃ©pertoire courant)"
    if ([string]::IsNullOrWhiteSpace($outputPath)) {
        $outputPath = Get-Location
    }
    
    $reportOnly = Read-Host "GÃ©nÃ©rer uniquement un rapport sans effectuer de modifications? (O/N)"
    $reportOnlySwitch = $reportOnly -eq "O" -or $reportOnly -eq "o"
    
    $backupFiles = Read-Host "CrÃ©er des sauvegardes des fichiers avant de les modifier? (O/N)"
    $backupFilesSwitch = $backupFiles -eq "O" -or $backupFiles -eq "o"
    
    Write-Host
    Write-Host "ExÃ©cution de la mise Ã  jour des rÃ©fÃ©rences brisÃ©es..."
    Write-Host
    
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Update-References.ps1"
    
    $params = @{
        ScanPath = $ScanPath
        OutputPath = $outputPath
    }
    
    if ($reportOnlySwitch) {
        $params.Add("ReportOnly", $true)
    }
    
    if ($backupFilesSwitch) {
        $params.Add("BackupFiles", $true)
    }
    
    & $scriptPath @params
    
    Write-Host
    Read-Host "Appuyez sur EntrÃ©e pour continuer"
}

# Fonction pour exÃ©cuter les tests
function Invoke-ReferenceTests {
    Clear-Host
    Write-Host "=== Tests des outils de gestion des rÃ©fÃ©rences ==="
    Write-Host
    
    $testDirectory = Read-Host "RÃ©pertoire de test (laisser vide pour utiliser le sous-rÃ©pertoire 'test' du rÃ©pertoire courant)"
    if ([string]::IsNullOrWhiteSpace($testDirectory)) {
        $testDirectory = Join-Path -Path (Get-Location) -ChildPath "test"
    }
    
    $cleanupAfterTest = Read-Host "Supprimer l'environnement de test aprÃ¨s l'exÃ©cution? (O/N)"
    $cleanupAfterTestSwitch = $cleanupAfterTest -eq "O" -or $cleanupAfterTest -eq "o"
    
    Write-Host
    Write-Host "ExÃ©cution des tests..."
    Write-Host
    
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Test-ReferenceUpdater.ps1"
    
    $params = @{
        TestDirectory = $testDirectory
    }
    
    if ($cleanupAfterTestSwitch) {
        $params.Add("CleanupAfterTest", $true)
    }
    
    & $scriptPath @params
    
    Write-Host
    Read-Host "Appuyez sur EntrÃ©e pour continuer"
}

# Fonction pour changer le rÃ©pertoire Ã  analyser
function Set-ScanPath {
    Clear-Host
    Write-Host "=== Changer le rÃ©pertoire Ã  analyser ==="
    Write-Host
    Write-Host "RÃ©pertoire actuel: $ScanPath"
    Write-Host
    
    $newPath = Read-Host "Nouveau rÃ©pertoire Ã  analyser (laisser vide pour utiliser le rÃ©pertoire racine du projet)"
    
    if ([string]::IsNullOrWhiteSpace($newPath)) {
        $newPath = Get-ProjectRoot
    }
    
    if (-not (Test-Path -Path $newPath -PathType Container)) {
        Write-Host "Le rÃ©pertoire spÃ©cifiÃ© n'existe pas: $newPath" -ForegroundColor Red
        Read-Host "Appuyez sur EntrÃ©e pour continuer"
        return $ScanPath
    }
    
    Write-Host "RÃ©pertoire Ã  analyser modifiÃ©: $newPath" -ForegroundColor Green
    Read-Host "Appuyez sur EntrÃ©e pour continuer"
    
    return $newPath
}

# Fonction principale
function Main {
    if ([string]::IsNullOrWhiteSpace($ScanPath)) {
        $ScanPath = Get-ProjectRoot
    }
    
    while ($true) {
        $choice = Show-MainMenu
        
        switch ($choice) {
            "1" { Invoke-DetectReferences }
            "2" { Invoke-UpdateReferences }
            "3" { Invoke-ReferenceTests }
            "4" { $ScanPath = Set-ScanPath }
            "5" { return }
            default { 
                Write-Host "Option invalide. Veuillez choisir une option entre 1 et 5." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    }
}

# ExÃ©cution du script
Main
