<#
.SYNOPSIS
    Test simple pour vérifier le fonctionnement du gestionnaire de restauration.

.DESCRIPTION
    Ce script effectue un test simple pour vérifier que le gestionnaire de restauration
    fonctionne correctement.

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

Write-Host "Chargement des modules..." -ForegroundColor Cyan

if (Test-Path -Path $conflictManagerPath) {
    . $conflictManagerPath
    Write-Host "Module ConflictManager chargé" -ForegroundColor Green
} else {
    Write-Host "Module ConflictManager non trouvé à l'emplacement: $conflictManagerPath" -ForegroundColor Red
    exit 1
}

if (Test-Path -Path $synchronizationManagerPath) {
    . $synchronizationManagerPath
    Write-Host "Module SynchronizationManager chargé" -ForegroundColor Green
} else {
    Write-Host "Module SynchronizationManager non trouvé à l'emplacement: $synchronizationManagerPath" -ForegroundColor Red
    exit 1
}

if (Test-Path -Path $restoreManagerPath) {
    . $restoreManagerPath
    Write-Host "Module RestoreManager chargé" -ForegroundColor Green
} else {
    Write-Host "Module RestoreManager non trouvé à l'emplacement: $restoreManagerPath" -ForegroundColor Red
    exit 1
}

# Créer un répertoire de test
$testDir = Join-Path -Path $env:TEMP -ChildPath "SimpleTest_$(Get-Date -Format 'yyyyMMddHHmmss')"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null
Write-Host "Répertoire de test créé: $testDir" -ForegroundColor Cyan

# Créer un gestionnaire de synchronisation
$syncOptions = @{
    InstanceId  = "instance_test"
    StoragePath = $testDir
    EnableLocks = $false
    Debug       = $true
}

$syncManager = New-SynchronizationManager -Options $syncOptions
Write-Host "Gestionnaire de synchronisation créé" -ForegroundColor Green

# Créer un gestionnaire de restauration
$backupPath = Join-Path -Path $testDir -ChildPath "Backups"
$restoreManager = New-RestoreManager -InstanceId "instance_test" -SyncManager $syncManager -BackupPath $backupPath -EnableAutoBackup -EnableDebug
Write-Host "Gestionnaire de restauration créé" -ForegroundColor Green

# Créer un état de test
$resourceId = "resource1"
$initialState = @{
    Version   = "1.0"
    Content   = "Contenu initial"
    Timestamp = (Get-Date).ToString('o')
    Metadata  = @{
        Author = "Utilisateur test"
        Tags   = @("tag1", "tag2")
    }
}

# Enregistrer l'état initial
$result = $syncManager.UpdateResourceState($resourceId, $initialState)
Write-Host "État initial enregistré pour $resourceId - Résultat: $result" -ForegroundColor Green

# Créer une sauvegarde
$backupId = $restoreManager.CreateBackup($resourceId, "Sauvegarde de test")
Write-Host "Sauvegarde créée: $backupId" -ForegroundColor Green

# Vérifier que la sauvegarde existe
$backupFilePath = Join-Path -Path $backupPath -ChildPath "$backupId.json"
if (Test-Path -Path $backupFilePath) {
    Write-Host "Fichier de sauvegarde trouvé: $backupFilePath" -ForegroundColor Green

    # Afficher le contenu de la sauvegarde
    $backupContent = Get-Content -Path $backupFilePath -Raw | ConvertFrom-Json
    Write-Host "Contenu de la sauvegarde:" -ForegroundColor Cyan
    Write-Host "ResourceId: $($backupContent.ResourceId)" -ForegroundColor Cyan
    Write-Host "Version: $($backupContent.State.Version)" -ForegroundColor Cyan
    Write-Host "Content: $($backupContent.State.Content)" -ForegroundColor Cyan
} else {
    Write-Host "Fichier de sauvegarde non trouvé: $backupFilePath" -ForegroundColor Red
}

# Modifier l'état
$updatedState = @{
    Version   = "2.0"
    Content   = "Contenu modifié"
    Timestamp = (Get-Date).ToString('o')
    Metadata  = @{
        Author    = "Utilisateur modifié"
        Tags      = @("tag1", "tag3", "tag4")
        ExtraInfo = "Information supplémentaire"
    }
}

$result = $syncManager.UpdateResourceState($resourceId, $updatedState)
Write-Host "État modifié enregistré pour $resourceId - Résultat: $result" -ForegroundColor Green

# Restaurer sélectivement la version
$result = $restoreManager.RestoreSelective($resourceId, $backupId, @("Version"), @{})
Write-Host "Restauration sélective de la version: $result" -ForegroundColor Green

# Vérifier l'état après restauration
$currentState = $syncManager.GetResourceState($resourceId)
if ($currentState.Version -eq $initialState.Version) {
    Write-Host "Version correctement restaurée: $($currentState.Version)" -ForegroundColor Green
} else {
    Write-Host "Version incorrectement restaurée: $($currentState.Version), attendu: $($initialState.Version)" -ForegroundColor Red
}

# Restaurer complètement l'état initial
$result = $restoreManager.RestoreFull($resourceId, $backupId, @{})
Write-Host "Restauration complète: $result" -ForegroundColor Green

# Vérifier l'état après restauration
$currentState = $syncManager.GetResourceState($resourceId)
if ($currentState.Version -eq $initialState.Version) {
    Write-Host "Version correctement restaurée: $($currentState.Version)" -ForegroundColor Green
} else {
    Write-Host "Version incorrectement restaurée: $($currentState.Version), attendu: $($initialState.Version)" -ForegroundColor Red
}

if ($currentState.Content -eq $initialState.Content) {
    Write-Host "Contenu correctement restauré: $($currentState.Content)" -ForegroundColor Green
} else {
    Write-Host "Contenu incorrectement restauré: $($currentState.Content), attendu: $($initialState.Content)" -ForegroundColor Red
}

if (-not $currentState.Metadata.ContainsKey('ExtraInfo')) {
    Write-Host "ExtraInfo correctement supprimé" -ForegroundColor Green
} else {
    Write-Host "ExtraInfo toujours présent de façon inattendue: $($currentState.Metadata.ExtraInfo)" -ForegroundColor Red
}

# Nettoyage
Remove-Item -Path $testDir -Recurse -Force
Write-Host "Test terminé" -ForegroundColor Cyan
