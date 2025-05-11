<#
.SYNOPSIS
    Script de test pour la création de sauvegarde.

.DESCRIPTION
    Ce script teste la fonctionnalité de création de sauvegarde du gestionnaire de restauration.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Importer les modules requis
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$conflictManagerPath = Join-Path -Path $scriptDir -ChildPath "ConflictManager.ps1"
$synchronizationManagerPath = Join-Path -Path $scriptDir -ChildPath "SynchronizationManager.ps1"
$restoreManagerPath = Join-Path -Path $scriptDir -ChildPath "RestoreManager.ps1"

if (Test-Path -Path $conflictManagerPath) {
    . $conflictManagerPath
}
else {
    throw "Le module ConflictManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $conflictManagerPath"
}

if (Test-Path -Path $synchronizationManagerPath) {
    . $synchronizationManagerPath
}
else {
    throw "Le module SynchronizationManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $synchronizationManagerPath"
}

if (Test-Path -Path $restoreManagerPath) {
    . $restoreManagerPath
}
else {
    throw "Le module RestoreManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $restoreManagerPath"
}

# Fonction pour afficher un message formaté
function Write-TestMessage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Level = "Info"
    )
    
    $colors = @{
        Info = "White"
        Success = "Green"
        Warning = "Yellow"
        Error = "Red"
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colors[$Level]
}

# Fonction pour créer un répertoire de test temporaire
function New-TestDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$BasePath = $env:TEMP,
        
        [Parameter(Mandatory = $false)]
        [string]$DirectoryName = "RestoreManagerTest_$(Get-Date -Format 'yyyyMMddHHmmss')"
    )
    
    $testDir = Join-Path -Path $BasePath -ChildPath $DirectoryName
    
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
    }
    
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
    
    return $testDir
}

# Fonction pour tester la création de sauvegarde
function Test-BackupCreation {
    [CmdletBinding()]
    param()
    
    Write-TestMessage "Démarrage du test de création de sauvegarde" -Level "Info"
    
    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"
    
    # Créer un gestionnaire de synchronisation
    $syncOptions = @{
        InstanceId = "instance_test"
        StoragePath = $testDir
        EnableLocks = $false
        Debug = $true
    }
    
    $syncManager = New-SynchronizationManager -Options $syncOptions
    
    Write-TestMessage "Gestionnaire de synchronisation créé" -Level "Info"
    
    # Créer un gestionnaire de restauration
    $restoreOptions = @{
        BackupPath = Join-Path -Path $testDir -ChildPath "Backups"
        EnableAutoBackup = $true
        Debug = $true
    }
    
    $restoreManager = New-RestoreManager -InstanceId "instance_test" -SyncManager $syncManager -BackupPath $restoreOptions.BackupPath -EnableAutoBackup -EnableDebug
    
    Write-TestMessage "Gestionnaire de restauration créé" -Level "Info"
    
    # Créer un état de test
    $resourceId = "resource1"
    $testState = @{
        Version = "1.0"
        Content = "Contenu initial"
        Timestamp = (Get-Date).ToString('o')
        Metadata = @{
            Author = "Utilisateur test"
            Tags = @("tag1", "tag2")
        }
    }
    
    # Enregistrer l'état initial
    $syncManager.UpdateResourceState($resourceId, $testState)
    
    Write-TestMessage "État initial enregistré pour $resourceId" -Level "Info"
    
    # Test 1: Créer une sauvegarde
    Write-TestMessage "Test 1: Création d'une sauvegarde" -Level "Info"
    
    $backupId = $restoreManager.CreateBackup($resourceId, "Sauvegarde de test")
    
    if ($null -ne $backupId -and $backupId -ne "") {
        Write-TestMessage "Sauvegarde créée avec succès: $backupId" -Level "Success"
    }
    else {
        Write-TestMessage "Échec de la création de sauvegarde" -Level "Error"
    }
    
    # Test 2: Vérifier que la sauvegarde existe
    Write-TestMessage "Test 2: Vérification de l'existence de la sauvegarde" -Level "Info"
    
    $backupFilePath = Join-Path -Path $restoreOptions.BackupPath -ChildPath "$backupId.json"
    
    if (Test-Path -Path $backupFilePath) {
        Write-TestMessage "Fichier de sauvegarde trouvé: $backupFilePath" -Level "Success"
    }
    else {
        Write-TestMessage "Fichier de sauvegarde non trouvé: $backupFilePath" -Level "Error"
    }
    
    # Test 3: Vérifier le contenu de la sauvegarde
    Write-TestMessage "Test 3: Vérification du contenu de la sauvegarde" -Level "Info"
    
    $backupContent = Get-Content -Path $backupFilePath -Raw | ConvertFrom-Json
    
    if ($backupContent.ResourceId -eq $resourceId) {
        Write-TestMessage "ResourceId correct dans la sauvegarde: $($backupContent.ResourceId)" -Level "Success"
    }
    else {
        Write-TestMessage "ResourceId incorrect dans la sauvegarde: $($backupContent.ResourceId), attendu: $resourceId" -Level "Error"
    }
    
    if ($backupContent.State.Version -eq $testState.Version) {
        Write-TestMessage "Version correcte dans la sauvegarde: $($backupContent.State.Version)" -Level "Success"
    }
    else {
        Write-TestMessage "Version incorrecte dans la sauvegarde: $($backupContent.State.Version), attendu: $($testState.Version)" -Level "Error"
    }
    
    Write-TestMessage "Tests de création de sauvegarde terminés" -Level "Info"
    
    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Exécuter les tests
Write-TestMessage "Démarrage des tests du gestionnaire de restauration" -Level "Info"
Test-BackupCreation
Write-TestMessage "Tous les tests du gestionnaire de restauration sont terminés" -Level "Info"
