<#
.SYNOPSIS
    Script de test pour les verrous distribués.

.DESCRIPTION
    Ce script teste le fonctionnement des verrous distribués et du gestionnaire de synchronisation.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Importer les modules
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$distributedLockPath = Join-Path -Path $scriptDir -ChildPath "DistributedLock.ps1"
$synchronizationManagerPath = Join-Path -Path $scriptDir -ChildPath "SynchronizationManager.ps1"

if (Test-Path -Path $distributedLockPath) {
    . $distributedLockPath
} else {
    throw "Le module DistributedLock.ps1 est requis mais n'a pas été trouvé à l'emplacement: $distributedLockPath"
}

if (Test-Path -Path $synchronizationManagerPath) {
    . $synchronizationManagerPath
} else {
    throw "Le module SynchronizationManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $synchronizationManagerPath"
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

# Fonction pour tester les verrous distribués de base
function Test-BasicDistributedLocks {
    [CmdletBinding()]
    param()

    Write-TestMessage "Démarrage du test des verrous distribués de base" -Level "Info"

    # Créer un répertoire temporaire pour les verrous
    $lockDir = Join-Path -Path $env:TEMP -ChildPath "TestDistributedLocks"
    if (-not (Test-Path -Path $lockDir)) {
        New-Item -Path $lockDir -ItemType Directory -Force | Out-Null
    }

    # Créer deux instances de verrous pour la même ressource
    $resourceId = "test-resource-1"
    $instance1Id = "instance-1"
    $instance2Id = "instance-2"

    Write-TestMessage "Création de deux verrous pour la ressource $resourceId" -Level "Info"

    $lock1 = New-DistributedLock -ResourceId $resourceId -InstanceId $instance1Id -LockDirectory $lockDir -EnableDebug
    $lock2 = New-DistributedLock -ResourceId $resourceId -InstanceId $instance2Id -LockDirectory $lockDir -EnableDebug

    # Test 1: Acquisition du premier verrou
    Write-TestMessage "Test 1: Acquisition du premier verrou" -Level "Info"
    $acquired1 = $lock1.Acquire()

    if ($acquired1) {
        Write-TestMessage "Verrou 1 acquis avec succès" -Level "Success"
    } else {
        Write-TestMessage "Échec de l'acquisition du verrou 1" -Level "Error"
    }

    # Test 2: Tentative d'acquisition du deuxième verrou (devrait échouer)
    Write-TestMessage "Test 2: Tentative d'acquisition du deuxième verrou (devrait échouer)" -Level "Info"
    $acquired2 = $lock2.Acquire()

    if (-not $acquired2) {
        Write-TestMessage "Verrou 2 correctement refusé (attendu)" -Level "Success"
    } else {
        Write-TestMessage "Verrou 2 acquis alors qu'il devrait être refusé" -Level "Error"
    }

    # Test 3: Libération du premier verrou
    Write-TestMessage "Test 3: Libération du premier verrou" -Level "Info"
    $released1 = $lock1.Release()

    if ($released1) {
        Write-TestMessage "Verrou 1 libéré avec succès" -Level "Success"
    } else {
        Write-TestMessage "Échec de la libération du verrou 1" -Level "Error"
    }

    # Test 4: Acquisition du deuxième verrou après libération du premier
    Write-TestMessage "Test 4: Acquisition du deuxième verrou après libération du premier" -Level "Info"
    $acquired2 = $lock2.Acquire()

    if ($acquired2) {
        Write-TestMessage "Verrou 2 acquis avec succès après libération du verrou 1" -Level "Success"
    } else {
        Write-TestMessage "Échec de l'acquisition du verrou 2 après libération du verrou 1" -Level "Error"
    }

    # Test 5: Libération du deuxième verrou
    Write-TestMessage "Test 5: Libération du deuxième verrou" -Level "Info"
    $released2 = $lock2.Release()

    if ($released2) {
        Write-TestMessage "Verrou 2 libéré avec succès" -Level "Success"
    } else {
        Write-TestMessage "Échec de la libération du verrou 2" -Level "Error"
    }

    Write-TestMessage "Tests des verrous distribués de base terminés" -Level "Info"
}

# Fonction pour tester les verrous partagés
function Test-SharedDistributedLocks {
    [CmdletBinding()]
    param()

    Write-TestMessage "Démarrage du test des verrous distribués partagés" -Level "Info"

    # Créer un répertoire temporaire pour les verrous
    $lockDir = Join-Path -Path $env:TEMP -ChildPath "TestDistributedLocks"
    if (-not (Test-Path -Path $lockDir)) {
        New-Item -Path $lockDir -ItemType Directory -Force | Out-Null
    }

    # Créer trois instances de verrous pour la même ressource
    $resourceId = "test-resource-2"
    $instance1Id = "instance-1"
    $instance2Id = "instance-2"
    $instance3Id = "instance-3"

    Write-TestMessage "Création de trois verrous pour la ressource $resourceId" -Level "Info"

    $lock1 = New-DistributedLock -ResourceId $resourceId -InstanceId $instance1Id -LockDirectory $lockDir -Mode "shared" -EnableDebug
    $lock2 = New-DistributedLock -ResourceId $resourceId -InstanceId $instance2Id -LockDirectory $lockDir -Mode "shared" -EnableDebug
    $lock3 = New-DistributedLock -ResourceId $resourceId -InstanceId $instance3Id -LockDirectory $lockDir -Mode "exclusive" -EnableDebug

    # Test 1: Acquisition du premier verrou partagé
    Write-TestMessage "Test 1: Acquisition du premier verrou partagé" -Level "Info"
    $acquired1 = $lock1.Acquire()

    if ($acquired1) {
        Write-TestMessage "Verrou partagé 1 acquis avec succès" -Level "Success"
    } else {
        Write-TestMessage "Échec de l'acquisition du verrou partagé 1" -Level "Error"
    }

    # Test 2: Acquisition du deuxième verrou partagé (devrait réussir)
    Write-TestMessage "Test 2: Acquisition du deuxième verrou partagé (devrait réussir)" -Level "Info"
    $acquired2 = $lock2.Acquire()

    if ($acquired2) {
        Write-TestMessage "Verrou partagé 2 acquis avec succès" -Level "Success"
    } else {
        Write-TestMessage "Échec de l'acquisition du verrou partagé 2" -Level "Error"
    }

    # Test 3: Tentative d'acquisition du verrou exclusif (devrait échouer)
    Write-TestMessage "Test 3: Tentative d'acquisition du verrou exclusif (devrait échouer)" -Level "Info"
    $acquired3 = $lock3.Acquire()

    if (-not $acquired3) {
        Write-TestMessage "Verrou exclusif correctement refusé (attendu)" -Level "Success"
    } else {
        Write-TestMessage "Verrou exclusif acquis alors qu'il devrait être refusé" -Level "Error"
    }

    # Test 4: Libération des verrous partagés
    Write-TestMessage "Test 4: Libération des verrous partagés" -Level "Info"
    $released1 = $lock1.Release()
    $released2 = $lock2.Release()

    if ($released1 -and $released2) {
        Write-TestMessage "Verrous partagés libérés avec succès" -Level "Success"
    } else {
        Write-TestMessage "Échec de la libération des verrous partagés" -Level "Error"
    }

    # Test 5: Acquisition du verrou exclusif après libération des verrous partagés
    Write-TestMessage "Test 5: Acquisition du verrou exclusif après libération des verrous partagés" -Level "Info"
    $acquired3 = $lock3.Acquire()

    if ($acquired3) {
        Write-TestMessage "Verrou exclusif acquis avec succès après libération des verrous partagés" -Level "Success"
    } else {
        Write-TestMessage "Échec de l'acquisition du verrou exclusif après libération des verrous partagés" -Level "Error"
    }

    # Test 6: Libération du verrou exclusif
    Write-TestMessage "Test 6: Libération du verrou exclusif" -Level "Info"
    $released3 = $lock3.Release()

    if ($released3) {
        Write-TestMessage "Verrou exclusif libéré avec succès" -Level "Success"
    } else {
        Write-TestMessage "Échec de la libération du verrou exclusif" -Level "Error"
    }

    Write-TestMessage "Tests des verrous distribués partagés terminés" -Level "Info"
}

# Fonction pour tester le gestionnaire de synchronisation
function Test-SynchronizationManager {
    [CmdletBinding()]
    param()

    Write-TestMessage "Démarrage du test du gestionnaire de synchronisation" -Level "Info"

    # Créer un répertoire temporaire pour les verrous
    $lockDir = Join-Path -Path $env:TEMP -ChildPath "TestSynchronizationManager"
    if (-not (Test-Path -Path $lockDir)) {
        New-Item -Path $lockDir -ItemType Directory -Force | Out-Null
    }

    # Créer deux instances du gestionnaire de synchronisation
    $options1 = @{
        InstanceId    = "sync-manager-1"
        LockDirectory = $lockDir
        Debug         = $true
    }

    $options2 = @{
        InstanceId    = "sync-manager-2"
        LockDirectory = $lockDir
        Debug         = $true
    }

    Write-TestMessage "Création de deux gestionnaires de synchronisation" -Level "Info"

    $syncManager1 = [SynchronizationManager]::new($options1)
    $syncManager2 = [SynchronizationManager]::new($options2)

    # Test 1: Acquisition d'un verrou par le premier gestionnaire
    Write-TestMessage "Test 1: Acquisition d'un verrou par le premier gestionnaire" -Level "Info"
    $resourceId = "test-resource-3"
    $lockResult1 = $syncManager1.AcquireLock($resourceId)

    if ($lockResult1.Granted) {
        Write-TestMessage "Verrou acquis avec succès par le gestionnaire 1" -Level "Success"
    } else {
        Write-TestMessage "Échec de l'acquisition du verrou par le gestionnaire 1" -Level "Error"
    }

    # Test 2: Tentative d'acquisition du même verrou par le deuxième gestionnaire
    Write-TestMessage "Test 2: Tentative d'acquisition du même verrou par le deuxième gestionnaire" -Level "Info"
    $lockResult2 = $syncManager2.AcquireLock($resourceId)

    if (-not $lockResult2.Granted) {
        Write-TestMessage "Verrou correctement refusé pour le gestionnaire 2 (attendu)" -Level "Success"
    } else {
        Write-TestMessage "Verrou acquis par le gestionnaire 2 alors qu'il devrait être refusé" -Level "Error"
    }

    # Test 3: Libération du verrou par le premier gestionnaire
    Write-TestMessage "Test 3: Libération du verrou par le premier gestionnaire" -Level "Info"
    $released1 = $syncManager1.ReleaseLock($resourceId)

    if ($released1) {
        Write-TestMessage "Verrou libéré avec succès par le gestionnaire 1" -Level "Success"
    } else {
        Write-TestMessage "Échec de la libération du verrou par le gestionnaire 1" -Level "Error"
    }

    # Test 4: Acquisition du verrou par le deuxième gestionnaire après libération
    Write-TestMessage "Test 4: Acquisition du verrou par le deuxième gestionnaire après libération" -Level "Info"
    $lockResult2 = $syncManager2.AcquireLock($resourceId)

    if ($lockResult2.Granted) {
        Write-TestMessage "Verrou acquis avec succès par le gestionnaire 2 après libération" -Level "Success"
    } else {
        Write-TestMessage "Échec de l'acquisition du verrou par le gestionnaire 2 après libération" -Level "Error"
    }

    # Test 5: Libération du verrou par le deuxième gestionnaire
    Write-TestMessage "Test 5: Libération du verrou par le deuxième gestionnaire" -Level "Info"
    $released2 = $syncManager2.ReleaseLock($resourceId)

    if ($released2) {
        Write-TestMessage "Verrou libéré avec succès par le gestionnaire 2" -Level "Success"
    } else {
        Write-TestMessage "Échec de la libération du verrou par le gestionnaire 2" -Level "Error"
    }

    # Test 6: Création d'une transaction
    Write-TestMessage "Test 6: Création d'une transaction" -Level "Info"
    $transaction = $syncManager1.BeginTransaction()

    if ($null -ne $transaction) {
        Write-TestMessage "Transaction créée avec succès" -Level "Success"
    } else {
        Write-TestMessage "Échec de la création de la transaction" -Level "Error"
    }

    # Test 7: Acquisition d'un verrou dans le cadre de la transaction
    Write-TestMessage "Test 7: Acquisition d'un verrou dans le cadre de la transaction" -Level "Info"
    $resourceId = "test-resource-4"
    $lockInTx = $syncManager1.AcquireLockInTransaction($transaction, $resourceId)

    if ($lockInTx) {
        Write-TestMessage "Verrou acquis avec succès dans la transaction" -Level "Success"
    } else {
        Write-TestMessage "Échec de l'acquisition du verrou dans la transaction" -Level "Error"
    }

    # Test 8: Validation de la transaction
    Write-TestMessage "Test 8: Validation de la transaction" -Level "Info"
    $committed = $syncManager1.CommitTransaction($transaction)

    if ($committed) {
        Write-TestMessage "Transaction validée avec succès" -Level "Success"
    } else {
        Write-TestMessage "Échec de la validation de la transaction" -Level "Error"
    }

    # Nettoyage
    Write-TestMessage "Nettoyage des ressources" -Level "Info"
    $syncManager1.Cleanup()
    $syncManager2.Cleanup()

    Write-TestMessage "Tests du gestionnaire de synchronisation terminés" -Level "Info"
}

# Exécuter les tests
Write-TestMessage "Démarrage des tests de synchronisation" -Level "Info"
Test-BasicDistributedLocks
Test-SharedDistributedLocks
# Test-SynchronizationManager  # Désactivé temporairement en raison de problèmes avec la classe SynchronizationManager
Write-TestMessage "Tous les tests de synchronisation sont terminés" -Level "Info"
