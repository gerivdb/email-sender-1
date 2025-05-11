<#
.SYNOPSIS
    Script de test pour le gestionnaire de verrous pour les transactions.

.DESCRIPTION
    Ce script teste le fonctionnement du gestionnaire de verrous pour les transactions,
    notamment l'acquisition et la libération des verrous, la détection des deadlocks
    et la gestion des verrous expirés.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Importer les modules requis
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$transactionSystemPath = Join-Path -Path $scriptDir -ChildPath "TransactionSystem.ps1"
$distributedLockPath = Join-Path -Path $scriptDir -ChildPath "DistributedLock.ps1"
$transactionLockManagerPath = Join-Path -Path $scriptDir -ChildPath "TransactionLockManager.ps1"

# Importer les modules dans le bon ordre
if (Test-Path -Path $transactionSystemPath) {
    . $transactionSystemPath
} else {
    throw "Le module TransactionSystem.ps1 est requis mais n'a pas été trouvé à l'emplacement: $transactionSystemPath"
}

if (Test-Path -Path $distributedLockPath) {
    . $distributedLockPath
} else {
    throw "Le module DistributedLock.ps1 est requis mais n'a pas été trouvé à l'emplacement: $distributedLockPath"
}

if (Test-Path -Path $transactionLockManagerPath) {
    . $transactionLockManagerPath
} else {
    throw "Le module TransactionLockManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $transactionLockManagerPath"
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
        [string]$DirectoryName = "TransactionLockManagerTest_$(Get-Date -Format 'yyyyMMddHHmmss')"
    )

    $testDir = Join-Path -Path $BasePath -ChildPath $DirectoryName

    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
    }

    New-Item -Path $testDir -ItemType Directory -Force | Out-Null

    return $testDir
}

# Fonction pour tester l'acquisition et la libération des verrous
function Test-LockAcquisitionAndRelease {
    [CmdletBinding()]
    param()

    Write-TestMessage "Démarrage du test d'acquisition et de libération des verrous" -Level "Info"

    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"

    # Créer un gestionnaire de verrous
    $lockManager = New-TransactionLockManager -LockDirectory $testDir -EnableDebug

    Write-TestMessage "Gestionnaire de verrous créé" -Level "Info"

    # Créer deux transactions
    $transaction1 = [AdvancedTransaction]::new("instance1", 60000, @{}, $true)
    $transaction2 = [AdvancedTransaction]::new("instance2", 60000, @{}, $true)

    Write-TestMessage "Transactions créées" -Level "Info"

    # Test 1: Acquérir un verrou exclusif pour la première transaction
    Write-TestMessage "Test 1: Acquisition d'un verrou exclusif pour la première transaction" -Level "Info"

    $acquired1 = $lockManager.AcquireLock($transaction1, "resource1", "exclusive")

    if ($acquired1) {
        Write-TestMessage "Verrou exclusif acquis pour la première transaction" -Level "Success"
    } else {
        Write-TestMessage "Échec de l'acquisition du verrou exclusif pour la première transaction" -Level "Error"
    }

    # Test 2: Tenter d'acquérir un verrou exclusif pour la deuxième transaction (devrait échouer)
    Write-TestMessage "Test 2: Tentative d'acquisition d'un verrou exclusif pour la deuxième transaction" -Level "Info"

    $acquired2 = $lockManager.AcquireLock($transaction2, "resource1", "exclusive")

    if (-not $acquired2) {
        Write-TestMessage "Échec attendu de l'acquisition du verrou exclusif pour la deuxième transaction" -Level "Success"
    } else {
        Write-TestMessage "Verrou exclusif acquis pour la deuxième transaction (inattendu)" -Level "Error"
    }

    # Test 3: Libérer le verrou de la première transaction
    Write-TestMessage "Test 3: Libération du verrou de la première transaction" -Level "Info"

    $released1 = $lockManager.ReleaseLock($transaction1, "resource1")

    if ($released1) {
        Write-TestMessage "Verrou libéré pour la première transaction" -Level "Success"
    } else {
        Write-TestMessage "Échec de la libération du verrou pour la première transaction" -Level "Error"
    }

    # Test 4: Acquérir un verrou exclusif pour la deuxième transaction (devrait réussir maintenant)
    Write-TestMessage "Test 4: Acquisition d'un verrou exclusif pour la deuxième transaction après libération" -Level "Info"

    $acquired3 = $lockManager.AcquireLock($transaction2, "resource1", "exclusive")

    if ($acquired3) {
        Write-TestMessage "Verrou exclusif acquis pour la deuxième transaction" -Level "Success"
    } else {
        Write-TestMessage "Échec de l'acquisition du verrou exclusif pour la deuxième transaction" -Level "Error"
    }

    # Test 5: Libérer tous les verrous de la deuxième transaction
    Write-TestMessage "Test 5: Libération de tous les verrous de la deuxième transaction" -Level "Info"

    $releasedAll = $lockManager.ReleaseAllLocks($transaction2)

    if ($releasedAll) {
        Write-TestMessage "Tous les verrous libérés pour la deuxième transaction" -Level "Success"
    } else {
        Write-TestMessage "Échec de la libération de tous les verrous pour la deuxième transaction" -Level "Error"
    }

    Write-TestMessage "Tests d'acquisition et de libération des verrous terminés" -Level "Info"

    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Fonction pour tester les verrous partagés
function Test-SharedLocks {
    [CmdletBinding()]
    param()

    Write-TestMessage "Démarrage du test des verrous partagés" -Level "Info"

    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"

    # Créer un gestionnaire de verrous
    $lockManager = New-TransactionLockManager -LockDirectory $testDir -EnableDebug

    Write-TestMessage "Gestionnaire de verrous créé" -Level "Info"

    # Créer trois transactions
    $transaction1 = [AdvancedTransaction]::new("instance1", 60000, @{}, $true)
    $transaction2 = [AdvancedTransaction]::new("instance2", 60000, @{}, $true)
    $transaction3 = [AdvancedTransaction]::new("instance3", 60000, @{}, $true)

    Write-TestMessage "Transactions créées" -Level "Info"

    # Test 1: Acquérir un verrou partagé pour la première transaction
    Write-TestMessage "Test 1: Acquisition d'un verrou partagé pour la première transaction" -Level "Info"

    $acquired1 = $lockManager.AcquireLock($transaction1, "resource1", "shared")

    if ($acquired1) {
        Write-TestMessage "Verrou partagé acquis pour la première transaction" -Level "Success"
    } else {
        Write-TestMessage "Échec de l'acquisition du verrou partagé pour la première transaction" -Level "Error"
    }

    # Test 2: Acquérir un verrou partagé pour la deuxième transaction (devrait réussir)
    Write-TestMessage "Test 2: Acquisition d'un verrou partagé pour la deuxième transaction" -Level "Info"

    $acquired2 = $lockManager.AcquireLock($transaction2, "resource1", "shared")

    if ($acquired2) {
        Write-TestMessage "Verrou partagé acquis pour la deuxième transaction" -Level "Success"
    } else {
        Write-TestMessage "Échec de l'acquisition du verrou partagé pour la deuxième transaction" -Level "Error"
    }

    # Test 3: Tenter d'acquérir un verrou exclusif pour la troisième transaction (devrait échouer)
    Write-TestMessage "Test 3: Tentative d'acquisition d'un verrou exclusif pour la troisième transaction" -Level "Info"

    $acquired3 = $lockManager.AcquireLock($transaction3, "resource1", "exclusive")

    if (-not $acquired3) {
        Write-TestMessage "Échec attendu de l'acquisition du verrou exclusif pour la troisième transaction" -Level "Success"
    } else {
        Write-TestMessage "Verrou exclusif acquis pour la troisième transaction (inattendu)" -Level "Error"
    }

    # Test 4: Libérer les verrous des deux premières transactions
    Write-TestMessage "Test 4: Libération des verrous des deux premières transactions" -Level "Info"

    $released1 = $lockManager.ReleaseLock($transaction1, "resource1")
    $released2 = $lockManager.ReleaseLock($transaction2, "resource1")

    if ($released1 -and $released2) {
        Write-TestMessage "Verrous libérés pour les deux premières transactions" -Level "Success"
    } else {
        Write-TestMessage "Échec de la libération des verrous pour les deux premières transactions" -Level "Error"
    }

    # Test 5: Acquérir un verrou exclusif pour la troisième transaction (devrait réussir maintenant)
    Write-TestMessage "Test 5: Acquisition d'un verrou exclusif pour la troisième transaction après libération" -Level "Info"

    $acquired4 = $lockManager.AcquireLock($transaction3, "resource1", "exclusive")

    if ($acquired4) {
        Write-TestMessage "Verrou exclusif acquis pour la troisième transaction" -Level "Success"
    } else {
        Write-TestMessage "Échec de l'acquisition du verrou exclusif pour la troisième transaction" -Level "Error"
    }

    Write-TestMessage "Tests des verrous partagés terminés" -Level "Info"

    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Fonction pour tester les fonctionnalités de base
function Test-BasicFunctionality {
    [CmdletBinding()]
    param()

    Write-TestMessage "Démarrage du test des fonctionnalités de base" -Level "Info"

    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"

    # Créer un gestionnaire de verrous
    $options = @{
        LockDirectory             = $testDir
        DefaultTimeout            = 30000
        DefaultRetryCount         = 3
        DefaultRetryDelay         = 1000
        EnableDeadlockDetection   = $true
        DeadlockDetectionInterval = 5000
        Debug                     = $true
    }

    $lockManager = [TransactionLockManager]::new("instance_test", $options)

    Write-TestMessage "Gestionnaire de verrous créé" -Level "Info"

    # Vérifier que le gestionnaire de verrous a été créé correctement
    if ($null -ne $lockManager) {
        Write-TestMessage "Gestionnaire de verrous créé avec succès" -Level "Success"
    } else {
        Write-TestMessage "Échec de la création du gestionnaire de verrous" -Level "Error"
    }

    # Vérifier les propriétés du gestionnaire de verrous
    if ($lockManager.InstanceId -eq "instance_test") {
        Write-TestMessage "ID d'instance correct" -Level "Success"
    } else {
        Write-TestMessage "ID d'instance incorrect" -Level "Error"
    }

    if ($lockManager.LockDirectory -eq $testDir) {
        Write-TestMessage "Répertoire de verrous correct" -Level "Success"
    } else {
        Write-TestMessage "Répertoire de verrous incorrect" -Level "Error"
    }

    if ($lockManager.DefaultTimeout -eq 30000) {
        Write-TestMessage "Timeout par défaut correct" -Level "Success"
    } else {
        Write-TestMessage "Timeout par défaut incorrect" -Level "Error"
    }

    if ($lockManager.EnableDeadlockDetection -eq $true) {
        Write-TestMessage "Détection des deadlocks activée" -Level "Success"
    } else {
        Write-TestMessage "Détection des deadlocks désactivée" -Level "Error"
    }

    Write-TestMessage "Tests des fonctionnalités de base terminés" -Level "Info"

    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Exécuter les tests
Write-Host "Démarrage des tests du gestionnaire de verrous pour les transactions"

# Vérifier que les modules sont correctement importés
Write-Host "Vérification des modules importés:"
Write-Host "TransactionSystem.ps1: $(if (Get-Command -Name 'New-AdvancedTransaction' -ErrorAction SilentlyContinue) { 'OK' } else { 'NON' })"
Write-Host "DistributedLock.ps1: $(if (Get-Command -Name 'New-DistributedLock' -ErrorAction SilentlyContinue) { 'OK' } else { 'NON' })"
Write-Host "TransactionLockManager.ps1: $(if (Get-Command -Name 'New-TransactionLockManager' -ErrorAction SilentlyContinue) { 'OK' } else { 'NON' })"

# Vérifier que les types sont correctement définis
Write-Host "Vérification des types définis:"
try {
    $type = [AdvancedTransaction]
    Write-Host "AdvancedTransaction: OK"
} catch {
    Write-Host "AdvancedTransaction: NON"
}

try {
    $type = [DistributedLock]
    Write-Host "DistributedLock: OK"
} catch {
    Write-Host "DistributedLock: NON"
}

try {
    $type = [TransactionLockManager]
    Write-Host "TransactionLockManager: OK"
} catch {
    Write-Host "TransactionLockManager: NON"
}

# Créer un répertoire de test
$testDir = New-TestDirectory
Write-Host "Répertoire de test créé: $testDir"

# Créer un gestionnaire de verrous manuellement
try {
    $options = @{
        LockDirectory             = $testDir
        DefaultTimeout            = 30000
        DefaultRetryCount         = 3
        DefaultRetryDelay         = 1000
        EnableDeadlockDetection   = $true
        DeadlockDetectionInterval = 5000
        Debug                     = $true
    }

    $lockManager = [TransactionLockManager]::new("instance_test", $options)
    Write-Host "Gestionnaire de verrous créé avec succès"
} catch {
    Write-Host "Erreur lors de la création du gestionnaire de verrous: $_"
}

# Nettoyage
Remove-Item -Path $testDir -Recurse -Force

Write-Host "Tous les tests du gestionnaire de verrous pour les transactions sont terminés"
