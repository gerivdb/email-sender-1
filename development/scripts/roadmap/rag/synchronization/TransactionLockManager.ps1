<#
.SYNOPSIS
    Gestionnaire de verrous pour les transactions distribuées.

.DESCRIPTION
    Ce module fournit un gestionnaire de verrous qui intègre le système de verrous distribués
    avec le système de transactions. Il permet de synchroniser l'acquisition des verrous
    avec les transactions, de gérer la libération automatique des verrous et de détecter
    les deadlocks.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Importer les modules requis
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$distributedLockPath = Join-Path -Path $scriptDir -ChildPath "DistributedLock.ps1"
$transactionSystemPath = Join-Path -Path $scriptDir -ChildPath "TransactionSystem.ps1"

if (Test-Path -Path $distributedLockPath) {
    . $distributedLockPath
} else {
    throw "Le module DistributedLock.ps1 est requis mais n'a pas été trouvé à l'emplacement: $distributedLockPath"
}

if (Test-Path -Path $transactionSystemPath) {
    . $transactionSystemPath
} else {
    throw "Le module TransactionSystem.ps1 est requis mais n'a pas été trouvé à l'emplacement: $transactionSystemPath"
}

# Classe pour représenter un gestionnaire de verrous pour les transactions
class TransactionLockManager {
    # Propriétés
    [string]$InstanceId
    [hashtable]$ActiveLocks
    [hashtable]$TransactionLocks
    [string]$LockDirectory
    [int]$DefaultTimeout
    [int]$DefaultRetryCount
    [int]$DefaultRetryDelay
    [bool]$EnableDeadlockDetection
    [int]$DeadlockDetectionInterval
    [System.Collections.Generic.List[string]]$WaitForGraph
    [bool]$Debug

    # Constructeur
    TransactionLockManager(
        [string]$instanceId,
        [hashtable]$options
    ) {
        $this.InstanceId = $instanceId
        $this.ActiveLocks = @{}
        $this.TransactionLocks = @{}
        $this.LockDirectory = if ($options.ContainsKey('LockDirectory')) {
            $options.LockDirectory
        } else {
            Join-Path -Path $env:TEMP -ChildPath "TransactionLocks"
        }
        $this.DefaultTimeout = if ($options.ContainsKey('DefaultTimeout')) {
            $options.DefaultTimeout
        } else {
            30000
        }
        $this.DefaultRetryCount = if ($options.ContainsKey('DefaultRetryCount')) {
            $options.DefaultRetryCount
        } else {
            3
        }
        $this.DefaultRetryDelay = if ($options.ContainsKey('DefaultRetryDelay')) {
            $options.DefaultRetryDelay
        } else {
            1000
        }
        $this.EnableDeadlockDetection = if ($options.ContainsKey('EnableDeadlockDetection')) {
            $options.EnableDeadlockDetection
        } else {
            $true
        }
        $this.DeadlockDetectionInterval = if ($options.ContainsKey('DeadlockDetectionInterval')) {
            $options.DeadlockDetectionInterval
        } else {
            5000
        }
        $this.WaitForGraph = [System.Collections.Generic.List[string]]::new()
        $this.Debug = if ($options.ContainsKey('Debug')) {
            $options.Debug
        } else {
            $false
        }

        # Créer le répertoire de verrous s'il n'existe pas
        if (-not (Test-Path -Path $this.LockDirectory -PathType Container)) {
            New-Item -Path $this.LockDirectory -ItemType Directory -Force | Out-Null
        }

        $this.WriteDebug("Gestionnaire de verrous pour les transactions créé avec l'ID d'instance: $instanceId")
    }

    # Méthode pour acquérir un verrou pour une transaction
    [bool] AcquireLock(
        [AdvancedTransaction]$transaction,
        [string]$resourceId,
        [string]$lockMode,
        [hashtable]$options = @{}
    ) {
        $this.WriteDebug("Tentative d'acquisition d'un verrou $lockMode pour la ressource $resourceId dans la transaction $($transaction.TransactionId)")

        # Vérifier si la transaction est active
        if ($transaction.State -ne [TransactionState]::Active) {
            $this.WriteDebug("La transaction n'est pas active, impossible d'acquérir un verrou")
            return $false
        }

        # Créer un ID unique pour le verrou
        $lockId = "$($transaction.TransactionId)_$resourceId"

        # Vérifier si le verrou est déjà acquis pour cette transaction
        if ($this.TransactionLocks.ContainsKey($lockId)) {
            $existingLock = $this.TransactionLocks[$lockId]

            # Si le mode de verrou est le même, renouveler le verrou
            if ($existingLock.LockMode -eq $lockMode) {
                $this.WriteDebug("Verrou déjà acquis pour cette transaction, renouvellement...")
                $renewed = $existingLock.Renew()
                return $renewed
            }

            # Si le mode de verrou est différent, libérer l'ancien verrou et en acquérir un nouveau
            $this.WriteDebug("Verrou déjà acquis avec un mode différent, libération et réacquisition...")
            $released = $existingLock.Release()
            if (-not $released) {
                $this.WriteDebug("Impossible de libérer l'ancien verrou")
                return $false
            }

            $this.TransactionLocks.Remove($lockId)
            $this.ActiveLocks.Remove($lockId)
        }

        # Configurer les options du verrou
        $lockOptions = @{
            Mode       = $lockMode
            Timeout    = if ($options.ContainsKey('Timeout')) { $options.Timeout } else { $this.DefaultTimeout }
            RetryCount = if ($options.ContainsKey('RetryCount')) { $options.RetryCount } else { $this.DefaultRetryCount }
            RetryDelay = if ($options.ContainsKey('RetryDelay')) { $options.RetryDelay } else { $this.DefaultRetryDelay }
            Debug      = $this.Debug
        }

        # Créer un nouveau verrou distribué
        $lock = [DistributedLock]::new($resourceId, $this.InstanceId, $this.LockDirectory, $lockOptions)

        # Mettre à jour le graphe d'attente pour la détection des deadlocks
        if ($this.EnableDeadlockDetection) {
            $this._UpdateWaitForGraph($transaction.TransactionId, $resourceId)
        }

        # Acquérir le verrou
        $acquired = $lock.Acquire()

        if ($acquired) {
            # Enregistrer le verrou dans les collections
            $this.TransactionLocks[$lockId] = $lock
            $this.ActiveLocks[$lockId] = @{
                Lock          = $lock
                TransactionId = $transaction.TransactionId
                ResourceId    = $resourceId
                AcquiredTime  = Get-Date
            }

            $this.WriteDebug("Verrou acquis pour la ressource $resourceId dans la transaction $($transaction.TransactionId)")

            # Nettoyer le graphe d'attente
            if ($this.EnableDeadlockDetection) {
                $this._CleanupWaitForGraph($transaction.TransactionId, $resourceId)
            }
        } else {
            $this.WriteDebug("Échec de l'acquisition du verrou pour la ressource $resourceId dans la transaction $($transaction.TransactionId)")

            # Vérifier s'il y a un deadlock
            if ($this.EnableDeadlockDetection) {
                $deadlock = $this._DetectDeadlock($transaction.TransactionId, $resourceId)
                if ($deadlock) {
                    $this.WriteDebug("Deadlock détecté pour la transaction $($transaction.TransactionId)")
                    throw "Deadlock détecté lors de l'acquisition du verrou pour la ressource $resourceId"
                }
            }
        }

        return $acquired
    }

    # Méthode pour libérer un verrou pour une transaction
    [bool] ReleaseLock(
        [AdvancedTransaction]$transaction,
        [string]$resourceId
    ) {
        $this.WriteDebug("Tentative de libération du verrou pour la ressource $resourceId dans la transaction $($transaction.TransactionId)")

        # Créer un ID unique pour le verrou
        $lockId = "$($transaction.TransactionId)_$resourceId"

        # Vérifier si le verrou existe
        if (-not $this.TransactionLocks.ContainsKey($lockId)) {
            $this.WriteDebug("Aucun verrou trouvé pour la ressource $resourceId dans la transaction $($transaction.TransactionId)")
            return $true
        }

        # Récupérer le verrou
        $lock = $this.TransactionLocks[$lockId]

        # Libérer le verrou
        $released = $lock.Release()

        if ($released) {
            # Supprimer le verrou des collections
            $this.TransactionLocks.Remove($lockId)
            $this.ActiveLocks.Remove($lockId)

            $this.WriteDebug("Verrou libéré pour la ressource $resourceId dans la transaction $($transaction.TransactionId)")

            # Nettoyer le graphe d'attente
            if ($this.EnableDeadlockDetection) {
                $this._CleanupWaitForGraph($transaction.TransactionId, $resourceId)
            }
        } else {
            $this.WriteDebug("Échec de la libération du verrou pour la ressource $resourceId dans la transaction $($transaction.TransactionId)")
        }

        return $released
    }

    # Méthode pour libérer tous les verrous d'une transaction
    [bool] ReleaseAllLocks([AdvancedTransaction]$transaction) {
        $this.WriteDebug("Libération de tous les verrous pour la transaction $($transaction.TransactionId)")

        $allReleased = $true
        $locksToRelease = @()

        # Identifier tous les verrous de cette transaction
        foreach ($lockId in $this.TransactionLocks.Keys) {
            if ($lockId.StartsWith("$($transaction.TransactionId)_")) {
                $locksToRelease += $lockId
            }
        }

        # Libérer chaque verrou
        foreach ($lockId in $locksToRelease) {
            $lock = $this.TransactionLocks[$lockId]
            $released = $lock.Release()

            if ($released) {
                $this.TransactionLocks.Remove($lockId)
                $this.ActiveLocks.Remove($lockId)
                $this.WriteDebug("Verrou $lockId libéré")
            } else {
                $this.WriteDebug("Échec de la libération du verrou $lockId")
                $allReleased = $false
            }
        }

        # Nettoyer le graphe d'attente
        if ($this.EnableDeadlockDetection) {
            $this._CleanupAllWaitForGraph($transaction.TransactionId)
        }

        return $allReleased
    }

    # Méthode pour vérifier si un verrou est détenu par une transaction
    [bool] HasLock(
        [AdvancedTransaction]$transaction,
        [string]$resourceId
    ) {
        $lockId = "$($transaction.TransactionId)_$resourceId"
        return $this.TransactionLocks.ContainsKey($lockId)
    }

    # Méthode pour obtenir tous les verrous d'une transaction
    [hashtable] GetTransactionLocks([AdvancedTransaction]$transaction) {
        $locks = @{}

        foreach ($lockId in $this.TransactionLocks.Keys) {
            if ($lockId.StartsWith("$($transaction.TransactionId)_")) {
                $resourceId = $lockId.Substring($transaction.TransactionId.Length + 1)
                $locks[$resourceId] = $this.TransactionLocks[$lockId]
            }
        }

        return $locks
    }

    # Méthode pour nettoyer les verrous expirés
    [int] CleanupExpiredLocks() {
        $this.WriteDebug("Nettoyage des verrous expirés")

        $count = 0
        $locksToRemove = @()

        # Identifier les verrous expirés
        foreach ($lockInfo in $this.ActiveLocks.Values) {
            $lock = $lockInfo.Lock

            if ((Get-Date) -gt $lock.ExpiryTime) {
                $locksToRemove += $lockInfo
                $count++
            }
        }

        # Supprimer les verrous expirés
        foreach ($lockInfo in $locksToRemove) {
            $lockId = "$($lockInfo.TransactionId)_$($lockInfo.ResourceId)"
            $lock = $lockInfo.Lock

            $this.WriteDebug("Suppression du verrou expiré: $lockId")
            $lock.Release()

            $this.TransactionLocks.Remove($lockId)
            $this.ActiveLocks.Remove($lockId)
        }

        return $count
    }

    # Méthode privée pour mettre à jour le graphe d'attente
    hidden [void] _UpdateWaitForGraph([string]$transactionId, [string]$resourceId) {
        # Trouver toutes les transactions qui détiennent un verrou sur cette ressource
        $holdingTransactions = @()

        foreach ($lockInfo in $this.ActiveLocks.Values) {
            if ($lockInfo.ResourceId -eq $resourceId -and $lockInfo.TransactionId -ne $transactionId) {
                $holdingTransactions += $lockInfo.TransactionId
            }
        }

        # Ajouter des arêtes au graphe d'attente
        foreach ($holdingTransaction in $holdingTransactions) {
            $edge = "$transactionId->$holdingTransaction"
            if ($this.WaitForGraph -notcontains $edge) {
                $this.WaitForGraph.Add($edge)
                $this.WriteDebug("Ajout de l'arête au graphe d'attente: $edge")
            }
        }
    }

    # Méthode privée pour nettoyer le graphe d'attente
    hidden [void] _CleanupWaitForGraph([string]$transactionId, [string]$resourceId) {
        # Supprimer toutes les arêtes où cette transaction attend pour cette ressource
        $edgesToRemove = @()

        foreach ($edge in $this.WaitForGraph) {
            if ($edge.StartsWith("$transactionId->")) {
                $edgesToRemove += $edge
            }
        }

        foreach ($edge in $edgesToRemove) {
            $this.WaitForGraph.Remove($edge)
            $this.WriteDebug("Suppression de l'arête du graphe d'attente: $edge")
        }
    }

    # Méthode privée pour nettoyer toutes les arêtes d'une transaction
    hidden [void] _CleanupAllWaitForGraph([string]$transactionId) {
        # Supprimer toutes les arêtes impliquant cette transaction
        $edgesToRemove = @()

        foreach ($edge in $this.WaitForGraph) {
            if ($edge.StartsWith("$transactionId->") -or $edge.EndsWith("->$transactionId")) {
                $edgesToRemove += $edge
            }
        }

        foreach ($edge in $edgesToRemove) {
            $this.WaitForGraph.Remove($edge)
            $this.WriteDebug("Suppression de l'arête du graphe d'attente: $edge")
        }
    }

    # Méthode privée pour détecter les deadlocks
    hidden [bool] _DetectDeadlock([string]$transactionId, [string]$resourceId) {
        # Construire un graphe dirigé à partir des arêtes
        $graph = @{}

        foreach ($edge in $this.WaitForGraph) {
            $nodes = $edge -split '->'
            $from = $nodes[0]
            $to = $nodes[1]

            if (-not $graph.ContainsKey($from)) {
                $graph[$from] = @()
            }

            $graph[$from] += $to
        }

        # Fonction récursive pour détecter les cycles
        function Find-Cycle {
            param (
                [hashtable]$graph,
                [string]$current,
                [string]$start,
                [System.Collections.Generic.HashSet[string]]$visited
            )

            # Marquer le nœud comme visité
            $visited.Add($current)

            # Parcourir les voisins
            if ($graph.ContainsKey($current)) {
                foreach ($neighbor in $graph[$current]) {
                    # Si on revient au nœud de départ, on a trouvé un cycle
                    if ($neighbor -eq $start) {
                        return $true
                    }

                    # Si le voisin n'a pas été visité, continuer la recherche
                    if (-not $visited.Contains($neighbor)) {
                        $cycleFound = Find-Cycle -graph $graph -current $neighbor -start $start -visited $visited
                        if ($cycleFound) {
                            return $true
                        }
                    }
                }
            }

            return $false
        }

        # Vérifier s'il y a un cycle à partir de la transaction courante
        $visited = [System.Collections.Generic.HashSet[string]]::new()
        $deadlockDetected = Find-Cycle -graph $graph -current $transactionId -start $transactionId -visited $visited

        if ($deadlockDetected) {
            $this.WriteDebug("Deadlock détecté pour la transaction $transactionId")
        }

        return $deadlockDetected
    }

    # Méthode pour écrire des messages de débogage
    hidden [void] WriteDebug([string]$message) {
        if ($this.Debug) {
            Write-Host "[TransactionLockManager] $message" -ForegroundColor Yellow
        }
    }
}

# Fonction pour créer un nouveau gestionnaire de verrous pour les transactions
function New-TransactionLockManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$InstanceId = "instance_$(Get-Date -Format 'yyyyMMddHHmmss')_$(Get-Random -Minimum 10000 -Maximum 99999)",

        [Parameter(Mandatory = $false)]
        [string]$LockDirectory = (Join-Path -Path $env:TEMP -ChildPath "TransactionLocks"),

        [Parameter(Mandatory = $false)]
        [int]$DefaultTimeout = 30000,

        [Parameter(Mandatory = $false)]
        [int]$DefaultRetryCount = 3,

        [Parameter(Mandatory = $false)]
        [int]$DefaultRetryDelay = 1000,

        [Parameter(Mandatory = $false)]
        [switch]$DisableDeadlockDetection,

        [Parameter(Mandatory = $false)]
        [int]$DeadlockDetectionInterval = 5000,

        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    $options = @{
        LockDirectory             = $LockDirectory
        DefaultTimeout            = $DefaultTimeout
        DefaultRetryCount         = $DefaultRetryCount
        DefaultRetryDelay         = $DefaultRetryDelay
        EnableDeadlockDetection   = -not $DisableDeadlockDetection.IsPresent
        DeadlockDetectionInterval = $DeadlockDetectionInterval
        Debug                     = $EnableDebug.IsPresent
    }

    return [TransactionLockManager]::new($InstanceId, $options)
}

# Pas besoin d'exporter les fonctions car ce n'est pas un module
# Export-ModuleMember -Function New-TransactionLockManager
