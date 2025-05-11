<#
.SYNOPSIS
    Script de test pour le gestionnaire de restauration.

.DESCRIPTION
    Ce script teste les fonctionnalités du gestionnaire de restauration,
    notamment la création de sauvegardes, la restauration sélective et complète,
    ainsi que la prévisualisation des restaurations.

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
} else {
    throw "Le module ConflictManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $conflictManagerPath"
}

if (Test-Path -Path $synchronizationManagerPath) {
    . $synchronizationManagerPath
} else {
    throw "Le module SynchronizationManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $synchronizationManagerPath"
}

if (Test-Path -Path $restoreManagerPath) {
    . $restoreManagerPath
} else {
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
        Info    = "White"
        Success = "Green"
        Warning = "Yellow"
        Error   = "Red"
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

# Fonction pour simuler les entrées utilisateur
function Set-MockUserInput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Inputs
    )

    # Créer un script temporaire qui simule les entrées utilisateur
    $tempScript = @"
`$inputs = @(
$(($Inputs | ForEach-Object { "'$_'" }) -join ",`n")
)

`$inputIndex = 0

function Read-Host {
    param([string]`$prompt)

    Write-Host "`$prompt" -NoNewline
    `$input = `$inputs[`$script:inputIndex]
    `$script:inputIndex++
    Write-Host " `$input"
    return `$input
}
"@

    $tempScriptPath = Join-Path -Path $env:TEMP -ChildPath "MockUserInput_$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
    $tempScript | Out-File -FilePath $tempScriptPath -Encoding utf8

    # Charger le script temporaire
    . $tempScriptPath

    # Supprimer le script temporaire
    Remove-Item -Path $tempScriptPath -Force
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
        InstanceId  = "instance_test"
        StoragePath = $testDir
        EnableLocks = $false
        Debug       = $true
    }
    $syncManager = New-SynchronizationManager -Options $syncOptions

    Write-TestMessage "Gestionnaire de synchronisation créé" -Level "Info"

    # Créer un gestionnaire de restauration
    $restoreOptions = @{
        BackupPath       = Join-Path -Path $testDir -ChildPath "Backups"
        EnableAutoBackup = $true
        Debug            = $true
    }

    $restoreManager = New-RestoreManager -InstanceId "instance_test" -SyncManager $syncManager -BackupPath $restoreOptions.BackupPath -EnableAutoBackup -EnableDebug

    Write-TestMessage "Gestionnaire de restauration créé" -Level "Info"

    # Créer un état de test
    $resourceId = "resource1"
    $testState = @{
        Version   = "1.0"
        Content   = "Contenu initial"
        Timestamp = (Get-Date).ToString('o')
        Metadata  = @{
            Author = "Utilisateur test"
            Tags   = @("tag1", "tag2")
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
    } else {
        Write-TestMessage "Échec de la création de sauvegarde" -Level "Error"
    }

    # Test 2: Vérifier que la sauvegarde existe
    Write-TestMessage "Test 2: Vérification de l'existence de la sauvegarde" -Level "Info"

    $backupFilePath = Join-Path -Path $restoreOptions.BackupPath -ChildPath "$backupId.json"

    if (Test-Path -Path $backupFilePath) {
        Write-TestMessage "Fichier de sauvegarde trouvé: $backupFilePath" -Level "Success"
    } else {
        Write-TestMessage "Fichier de sauvegarde non trouvé: $backupFilePath" -Level "Error"
    }

    # Test 3: Vérifier le contenu de la sauvegarde
    Write-TestMessage "Test 3: Vérification du contenu de la sauvegarde" -Level "Info"

    $backupContent = Get-Content -Path $backupFilePath -Raw | ConvertFrom-Json

    if ($backupContent.ResourceId -eq $resourceId) {
        Write-TestMessage "ResourceId correct dans la sauvegarde: $($backupContent.ResourceId)" -Level "Success"
    } else {
        Write-TestMessage "ResourceId incorrect dans la sauvegarde: $($backupContent.ResourceId), attendu: $resourceId" -Level "Error"
    }

    if ($backupContent.State.Version -eq $testState.Version) {
        Write-TestMessage "Version correcte dans la sauvegarde: $($backupContent.State.Version)" -Level "Success"
    } else {
        Write-TestMessage "Version incorrecte dans la sauvegarde: $($backupContent.State.Version), attendu: $($testState.Version)" -Level "Error"
    }

    Write-TestMessage "Tests de création de sauvegarde terminés" -Level "Info"

    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Fonction pour tester la restauration sélective
function Test-SelectiveRestore {
    [CmdletBinding()]
    param()

    Write-TestMessage "Démarrage du test de restauration sélective" -Level "Info"

    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"

    # Créer un gestionnaire de synchronisation
    $syncOptions = @{
        InstanceId  = "instance_test"
        StoragePath = $testDir
        EnableLocks = $false
        Debug       = $true
    }
    $syncManager = New-SynchronizationManager -Options $syncOptions

    Write-TestMessage "Gestionnaire de synchronisation créé" -Level "Info"

    # Créer un gestionnaire de restauration
    $restoreOptions = @{
        BackupPath       = Join-Path -Path $testDir -ChildPath "Backups"
        EnableAutoBackup = $true
        Debug            = $true
    }

    $restoreManager = New-RestoreManager -InstanceId "instance_test" -SyncManager $syncManager -BackupPath $restoreOptions.BackupPath -EnableAutoBackup -EnableDebug

    Write-TestMessage "Gestionnaire de restauration créé" -Level "Info"

    # Créer un état de test
    $resourceId = "resource1"
    $initialState = @{
        Version   = "1.0"
        Content   = "Contenu initial"
        Timestamp = (Get-Date).AddDays(-1).ToString('o')
        Metadata  = @{
            Author = "Utilisateur initial"
            Tags   = @("tag1", "tag2")
        }
    }

    # Enregistrer l'état initial
    $syncManager.UpdateResourceState($resourceId, $initialState)

    Write-TestMessage "État initial enregistré pour $resourceId" -Level "Info"

    # Créer une sauvegarde de l'état initial
    $backupId = $restoreManager.CreateBackup($resourceId, "Sauvegarde de l'état initial")

    Write-TestMessage "Sauvegarde de l'état initial créée: $backupId" -Level "Info"

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

    $syncManager.UpdateResourceState($resourceId, $updatedState)

    Write-TestMessage "État modifié enregistré pour $resourceId" -Level "Info"

    # Test 1: Restaurer sélectivement la version
    Write-TestMessage "Test 1: Restauration sélective de la version" -Level "Info"

    $result = $restoreManager.RestoreSelective($resourceId, $backupId, @("Version"), @{})

    if ($result) {
        Write-TestMessage "Restauration sélective de la version réussie" -Level "Success"
    } else {
        Write-TestMessage "Échec de la restauration sélective de la version" -Level "Error"
    }

    # Vérifier l'état après restauration
    $currentState = $syncManager.GetResourceState($resourceId)

    if ($currentState.Version -eq $initialState.Version) {
        Write-TestMessage "Version correctement restaurée: $($currentState.Version)" -Level "Success"
    } else {
        Write-TestMessage "Version incorrectement restaurée: $($currentState.Version), attendu: $($initialState.Version)" -Level "Error"
    }

    if ($currentState.Content -eq $updatedState.Content) {
        Write-TestMessage "Contenu non modifié comme prévu: $($currentState.Content)" -Level "Success"
    } else {
        Write-TestMessage "Contenu modifié de façon inattendue: $($currentState.Content), attendu: $($updatedState.Content)" -Level "Error"
    }

    # Test 2: Restaurer sélectivement les métadonnées
    Write-TestMessage "Test 2: Restauration sélective des métadonnées" -Level "Info"

    $result = $restoreManager.RestoreSelective($resourceId, $backupId, @("Metadata.Author", "Metadata.Tags"), @{})

    if ($result) {
        Write-TestMessage "Restauration sélective des métadonnées réussie" -Level "Success"
    } else {
        Write-TestMessage "Échec de la restauration sélective des métadonnées" -Level "Error"
    }

    # Vérifier l'état après restauration
    $currentState = $syncManager.GetResourceState($resourceId)

    if ($currentState.Metadata.Author -eq $initialState.Metadata.Author) {
        Write-TestMessage "Auteur correctement restauré: $($currentState.Metadata.Author)" -Level "Success"
    } else {
        Write-TestMessage "Auteur incorrectement restauré: $($currentState.Metadata.Author), attendu: $($initialState.Metadata.Author)" -Level "Error"
    }

    if ($currentState.Metadata.Tags.Count -eq $initialState.Metadata.Tags.Count) {
        Write-TestMessage "Tags correctement restaurés: $($currentState.Metadata.Tags -join ', ')" -Level "Success"
    } else {
        Write-TestMessage "Tags incorrectement restaurés: $($currentState.Metadata.Tags -join ', '), attendu: $($initialState.Metadata.Tags -join ', ')" -Level "Error"
    }

    if ($currentState.Metadata.ContainsKey('ExtraInfo')) {
        Write-TestMessage "ExtraInfo préservé comme prévu: $($currentState.Metadata.ExtraInfo)" -Level "Success"
    } else {
        Write-TestMessage "ExtraInfo supprimé de façon inattendue" -Level "Error"
    }

    Write-TestMessage "Tests de restauration sélective terminés" -Level "Info"

    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Fonction pour tester la restauration complète
function Test-FullRestore {
    [CmdletBinding()]
    param()

    Write-TestMessage "Démarrage du test de restauration complète" -Level "Info"

    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"

    # Créer un gestionnaire de synchronisation
    $syncOptions = @{
        InstanceId  = "instance_test"
        StoragePath = $testDir
        EnableLocks = $false
        Debug       = $true
    }
    $syncManager = New-SynchronizationManager -Options $syncOptions

    Write-TestMessage "Gestionnaire de synchronisation créé" -Level "Info"

    # Créer un gestionnaire de restauration
    $restoreOptions = @{
        BackupPath       = Join-Path -Path $testDir -ChildPath "Backups"
        EnableAutoBackup = $true
        Debug            = $true
    }

    $restoreManager = New-RestoreManager -InstanceId "instance_test" -SyncManager $syncManager -BackupPath $restoreOptions.BackupPath -EnableAutoBackup -EnableDebug

    Write-TestMessage "Gestionnaire de restauration créé" -Level "Info"

    # Créer un état de test
    $resourceId = "resource1"
    $initialState = @{
        Version   = "1.0"
        Content   = "Contenu initial"
        Timestamp = (Get-Date).AddDays(-1).ToString('o')
        Metadata  = @{
            Author = "Utilisateur initial"
            Tags   = @("tag1", "tag2")
        }
    }

    # Enregistrer l'état initial
    $syncManager.UpdateResourceState($resourceId, $initialState)

    Write-TestMessage "État initial enregistré pour $resourceId" -Level "Info"

    # Créer une sauvegarde de l'état initial
    $backupId = $restoreManager.CreateBackup($resourceId, "Sauvegarde de l'état initial")

    Write-TestMessage "Sauvegarde de l'état initial créée: $backupId" -Level "Info"

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

    $syncManager.UpdateResourceState($resourceId, $updatedState)

    Write-TestMessage "État modifié enregistré pour $resourceId" -Level "Info"

    # Test 1: Restaurer complètement l'état initial
    Write-TestMessage "Test 1: Restauration complète de l'état initial" -Level "Info"

    # Vérifier que le fichier de sauvegarde existe
    $backupFilePath = Join-Path -Path $restoreOptions.BackupPath -ChildPath "$backupId.json"

    if (Test-Path -Path $backupFilePath) {
        # Lire le contenu de la sauvegarde pour vérification
        $backupContent = Get-Content -Path $backupFilePath -Raw | ConvertFrom-Json

        # Effectuer la restauration
        $result = $restoreManager.RestoreFull($resourceId, $backupId, @{})

        if ($result) {
            Write-TestMessage "Restauration complète réussie" -Level "Success"
        } else {
            Write-TestMessage "Échec de la restauration complète" -Level "Error"
        }
    } else {
        Write-TestMessage "Fichier de sauvegarde non trouvé: $backupFilePath" -Level "Error"
    }

    # Vérifier l'état après restauration
    $currentState = $syncManager.GetResourceState($resourceId)

    if ($currentState.Version -eq $initialState.Version) {
        Write-TestMessage "Version correctement restaurée: $($currentState.Version)" -Level "Success"
    } else {
        Write-TestMessage "Version incorrectement restaurée: $($currentState.Version), attendu: $($initialState.Version)" -Level "Error"
    }

    if ($currentState.Content -eq $initialState.Content) {
        Write-TestMessage "Contenu correctement restauré: $($currentState.Content)" -Level "Success"
    } else {
        Write-TestMessage "Contenu incorrectement restauré: $($currentState.Content), attendu: $($initialState.Content)" -Level "Error"
    }

    if (-not $currentState.Metadata.ContainsKey('ExtraInfo')) {
        Write-TestMessage "ExtraInfo correctement supprimé" -Level "Success"
    } else {
        Write-TestMessage "ExtraInfo toujours présent de façon inattendue: $($currentState.Metadata.ExtraInfo)" -Level "Error"
    }

    # Test 2: Vérifier la sauvegarde automatique avant restauration
    Write-TestMessage "Test 2: Vérification de la sauvegarde automatique" -Level "Info"

    $restoreHistory = $restoreManager.GetRestoreHistory($resourceId)

    $autoBackups = $restoreHistory | Where-Object { $_.Description -like "Sauvegarde automatique avant restauration*" }

    if ($autoBackups.Count -gt 0) {
        Write-TestMessage "Sauvegarde automatique trouvée: $($autoBackups[0].BackupId)" -Level "Success"
    } else {
        Write-TestMessage "Aucune sauvegarde automatique trouvée" -Level "Error"
    }

    # Test 3: Annuler la restauration
    Write-TestMessage "Test 3: Annulation de la restauration" -Level "Info"

    $result = $restoreManager.UndoRestore($resourceId)

    if ($result) {
        Write-TestMessage "Annulation de la restauration réussie" -Level "Success"
    } else {
        Write-TestMessage "Échec de l'annulation de la restauration" -Level "Error"
    }

    # Vérifier l'état après annulation
    $currentState = $syncManager.GetResourceState($resourceId)

    if ($currentState.Version -eq $updatedState.Version) {
        Write-TestMessage "Version correctement restaurée après annulation: $($currentState.Version)" -Level "Success"
    } else {
        Write-TestMessage "Version incorrectement restaurée après annulation: $($currentState.Version), attendu: $($updatedState.Version)" -Level "Error"
    }

    if ($currentState.Metadata.ContainsKey('ExtraInfo')) {
        Write-TestMessage "ExtraInfo correctement restauré après annulation: $($currentState.Metadata.ExtraInfo)" -Level "Success"
    } else {
        Write-TestMessage "ExtraInfo non restauré après annulation" -Level "Error"
    }

    Write-TestMessage "Tests de restauration complète terminés" -Level "Info"

    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Exécuter les tests
Write-TestMessage "Démarrage des tests du gestionnaire de restauration" -Level "Info"
Test-BackupCreation
Test-SelectiveRestore
Test-FullRestore
Write-TestMessage "Tous les tests du gestionnaire de restauration sont terminés" -Level "Info"
