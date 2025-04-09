<#
.SYNOPSIS
    Interface utilisateur pour les outils de gestion des références.

.DESCRIPTION
    Ce script fournit une interface utilisateur simple pour exécuter les outils de gestion des références.
    Il permet de détecter et de mettre à jour les références brisées dans les fichiers du projet.

.PARAMETER ScanPath
    Chemin du répertoire à analyser. Par défaut, utilise le répertoire racine du projet.

.EXAMPLE
    .\Start-ReferenceManager.ps1
    Lance l'interface utilisateur pour les outils de gestion des références.

.EXAMPLE
    .\Start-ReferenceManager.ps1 -ScanPath "D:\Projets\EMAIL_SENDER_1"
    Lance l'interface utilisateur en spécifiant le répertoire à analyser.

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date création:  09/04/2025
    Prérequis:      PowerShell 5.1 ou supérieur
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ScanPath = ""
)

# Fonction pour obtenir le répertoire racine du projet
function Get-ProjectRoot {
    $currentDir = Get-Location
    
    # Remonter jusqu'à trouver un répertoire contenant un dossier .git ou atteindre la racine du disque
    while ($true) {
        if (Test-Path -Path (Join-Path -Path $currentDir -ChildPath ".git") -PathType Container) {
            return $currentDir
        }
        
        $parentDir = Split-Path -Path $currentDir -Parent
        if ($parentDir -eq $null -or $parentDir -eq $currentDir) {
            # Nous avons atteint la racine du disque ou un autre point où nous ne pouvons plus remonter
            return $currentDir
        }
        
        $currentDir = $parentDir
    }
}

# Fonction pour afficher le menu principal
function Show-MainMenu {
    Clear-Host
    Write-Host "=== Gestionnaire de références ==="
    Write-Host
    Write-Host "Répertoire analysé: $ScanPath"
    Write-Host
    Write-Host "1. Détecter les références brisées"
    Write-Host "2. Mettre à jour les références brisées"
    Write-Host "3. Exécuter les tests"
    Write-Host "4. Changer le répertoire à analyser"
    Write-Host "5. Quitter"
    Write-Host
    
    $choice = Read-Host "Choisissez une option (1-5)"
    return $choice
}

# Fonction pour exécuter la détection des références brisées
function Invoke-DetectReferences {
    Clear-Host
    Write-Host "=== Détection des références brisées ==="
    Write-Host
    Write-Host "Répertoire analysé: $ScanPath"
    Write-Host
    
    $outputPath = Read-Host "Chemin de sortie pour les rapports (laisser vide pour utiliser le répertoire courant)"
    if ([string]::IsNullOrWhiteSpace($outputPath)) {
        $outputPath = Get-Location
    }
    
    $useCustomMappings = Read-Host "Utiliser des mappages personnalisés? (O/N)"
    $customMappingsPath = ""
    
    if ($useCustomMappings -eq "O" -or $useCustomMappings -eq "o") {
        $customMappingsPath = Read-Host "Chemin du fichier de mappages personnalisés"
        if (-not (Test-Path -Path $customMappingsPath)) {
            Write-Host "Le fichier de mappages personnalisés n'existe pas: $customMappingsPath" -ForegroundColor Red
            Read-Host "Appuyez sur Entrée pour continuer"
            return
        }
    }
    
    Write-Host
    Write-Host "Exécution de la détection des références brisées..."
    Write-Host
    
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Detect-BrokenReferences.ps1"
    
    if ($customMappingsPath -ne "") {
        & $scriptPath -ScanPath $ScanPath -OutputPath $outputPath -CustomMappings $customMappingsPath
    }
    else {
        & $scriptPath -ScanPath $ScanPath -OutputPath $outputPath
    }
    
    Write-Host
    Read-Host "Appuyez sur Entrée pour continuer"
}

# Fonction pour exécuter la mise à jour des références brisées
function Invoke-UpdateReferences {
    Clear-Host
    Write-Host "=== Mise à jour des références brisées ==="
    Write-Host
    Write-Host "Répertoire analysé: $ScanPath"
    Write-Host
    
    $outputPath = Read-Host "Chemin de sortie pour les rapports (laisser vide pour utiliser le répertoire courant)"
    if ([string]::IsNullOrWhiteSpace($outputPath)) {
        $outputPath = Get-Location
    }
    
    $reportOnly = Read-Host "Générer uniquement un rapport sans effectuer de modifications? (O/N)"
    $reportOnlySwitch = $reportOnly -eq "O" -or $reportOnly -eq "o"
    
    $backupFiles = Read-Host "Créer des sauvegardes des fichiers avant de les modifier? (O/N)"
    $backupFilesSwitch = $backupFiles -eq "O" -or $backupFiles -eq "o"
    
    Write-Host
    Write-Host "Exécution de la mise à jour des références brisées..."
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
    Read-Host "Appuyez sur Entrée pour continuer"
}

# Fonction pour exécuter les tests
function Invoke-ReferenceTests {
    Clear-Host
    Write-Host "=== Tests des outils de gestion des références ==="
    Write-Host
    
    $testDirectory = Read-Host "Répertoire de test (laisser vide pour utiliser le sous-répertoire 'test' du répertoire courant)"
    if ([string]::IsNullOrWhiteSpace($testDirectory)) {
        $testDirectory = Join-Path -Path (Get-Location) -ChildPath "test"
    }
    
    $cleanupAfterTest = Read-Host "Supprimer l'environnement de test après l'exécution? (O/N)"
    $cleanupAfterTestSwitch = $cleanupAfterTest -eq "O" -or $cleanupAfterTest -eq "o"
    
    Write-Host
    Write-Host "Exécution des tests..."
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
    Read-Host "Appuyez sur Entrée pour continuer"
}

# Fonction pour changer le répertoire à analyser
function Set-ScanPath {
    Clear-Host
    Write-Host "=== Changer le répertoire à analyser ==="
    Write-Host
    Write-Host "Répertoire actuel: $ScanPath"
    Write-Host
    
    $newPath = Read-Host "Nouveau répertoire à analyser (laisser vide pour utiliser le répertoire racine du projet)"
    
    if ([string]::IsNullOrWhiteSpace($newPath)) {
        $newPath = Get-ProjectRoot
    }
    
    if (-not (Test-Path -Path $newPath -PathType Container)) {
        Write-Host "Le répertoire spécifié n'existe pas: $newPath" -ForegroundColor Red
        Read-Host "Appuyez sur Entrée pour continuer"
        return $ScanPath
    }
    
    Write-Host "Répertoire à analyser modifié: $newPath" -ForegroundColor Green
    Read-Host "Appuyez sur Entrée pour continuer"
    
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

# Exécution du script
Main
