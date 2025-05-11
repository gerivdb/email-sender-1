<#
.SYNOPSIS
    Système de transactions avancé pour la synchronisation distribuée.

.DESCRIPTION
    Ce module fournit un système de transactions avancé qui implémente les propriétés ACID
    (Atomicité, Cohérence, Isolation, Durabilité) pour les opérations distribuées.
    Il s'intègre avec le système de verrous distribués pour assurer la synchronisation
    entre différents processus PowerShell.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Importer les modules requis
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$synchronizationManagerPath = Join-Path -Path $scriptDir -ChildPath "SynchronizationManager.ps1"

if (Test-Path -Path $synchronizationManagerPath) {
    . $synchronizationManagerPath
} else {
    throw "Le module SynchronizationManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $synchronizationManagerPath"
}

#region Interfaces et classes de base

# Énumération pour les états de transaction
enum TransactionState {
    Inactive
    Active
    Preparing
    Prepared
    Committing
    Committed
    RollingBack
    RolledBack
    Failed
}

# Énumération pour les niveaux d'isolation
enum IsolationLevel {
    ReadUncommitted
    ReadCommitted
    RepeatableRead
    Serializable
}

# Énumération pour les types d'opérations
enum OperationType {
    Read
    Write
    Delete
    Custom
}

# Interface pour les ressources transactionnelles
class ITransactionalResource {
    # Propriétés
    [string]$ResourceId
    [string]$ResourceType
    [hashtable]$Metadata

    # Méthodes abstraites
    [object] GetState() { throw "Méthode abstraite non implémentée" }
    [bool] SetState([object]$state) { throw "Méthode abstraite non implémentée" }
    [bool] Lock([string]$transactionId, [string]$lockMode) { throw "Méthode abstraite non implémentée" }
    [bool] Unlock([string]$transactionId) { throw "Méthode abstraite non implémentée" }
    [bool] Validate() { throw "Méthode abstraite non implémentée" }
}

# Classe pour représenter une opération dans une transaction
class TransactionOperation {
    [string]$OperationId
    [OperationType]$Type
    [string]$ResourceId
    [object]$OriginalState
    [object]$NewState
    [datetime]$Timestamp
    [bool]$IsCompleted
    [string]$Status
    [hashtable]$Metadata

    # Constructeur
    TransactionOperation(
        [OperationType]$type,
        [string]$resourceId,
        [object]$originalState,
        [object]$newState = $null
    ) {
        $this.OperationId = "op_$(Get-Date -Format 'yyyyMMddHHmmss')_$(Get-Random -Minimum 10000 -Maximum 99999)"
        $this.Type = $type
        $this.ResourceId = $resourceId
        $this.OriginalState = $originalState
        $this.NewState = $newState
        $this.Timestamp = Get-Date
        $this.IsCompleted = $false
        $this.Status = "pending"
        $this.Metadata = @{}
    }

    # Méthode pour exécuter l'opération
    [bool] Execute([ITransactionalResource]$resource) {
        try {
            $result = $false

            switch ($this.Type) {
                ([OperationType]::Read) {
                    # Pour une opération de lecture, on ne modifie pas l'état
                    $this.IsCompleted = $true
                    $this.Status = "completed"
                    $result = $true
                }
                ([OperationType]::Write) {
                    # Pour une opération d'écriture, on applique les changements en attente
                    if ($resource -is [FileTransactionalResource]) {
                        $success = $resource.ApplyPendingChanges()
                    } else {
                        $success = $resource.SetState($this.NewState)
                    }

                    if ($success) {
                        $this.IsCompleted = $true
                        $this.Status = "completed"
                    } else {
                        $this.Status = "failed"
                    }
                    $result = $success
                }
                ([OperationType]::Delete) {
                    # Pour une opération de suppression, on applique les changements en attente
                    if ($resource -is [FileTransactionalResource]) {
                        $success = $resource.ApplyPendingChanges()
                    } else {
                        $success = $resource.SetState($null)
                    }

                    if ($success) {
                        $this.IsCompleted = $true
                        $this.Status = "completed"
                    } else {
                        $this.Status = "failed"
                    }
                    $result = $success
                }
                ([OperationType]::Custom) {
                    # Pour une opération personnalisée, on utilise la logique définie dans les métadonnées
                    if ($this.Metadata.ContainsKey("CustomExecute") -and $this.Metadata.CustomExecute -is [scriptblock]) {
                        $success = & $this.Metadata.CustomExecute $resource
                        if ($success) {
                            $this.IsCompleted = $true
                            $this.Status = "completed"
                        } else {
                            $this.Status = "failed"
                        }
                        $result = $success
                    } else {
                        $this.Status = "failed_no_custom_logic"
                        $result = $false
                    }
                }
                default {
                    $this.Status = "failed_unknown_operation"
                    $result = $false
                }
            }

            return $result
        } catch {
            $this.Status = "failed_exception: $_"
            return $false
        }
    }

    # Méthode pour annuler l'opération
    [bool] Rollback([ITransactionalResource]$resource) {
        try {
            # Si l'opération n'a pas été exécutée, pas besoin de rollback
            if (-not $this.IsCompleted) {
                $this.Status = "rollback_not_needed"
                return $true
            }

            # Pour les opérations de lecture, pas besoin de rollback
            if ($this.Type -eq [OperationType]::Read) {
                $this.Status = "rollback_not_needed"
                return $true
            }

            # Pour les autres opérations, restaurer l'état original
            $success = $resource.SetState($this.OriginalState)
            if ($success) {
                $this.Status = "rolled_back"
            } else {
                $this.Status = "rollback_failed"
            }
            return $success
        } catch {
            $this.Status = "rollback_exception: $_"
            return $false
        }
    }
}

# Classe pour le journal des transactions
class TransactionLog {
    [string]$LogId
    [string]$TransactionId
    [System.Collections.Generic.List[hashtable]]$Entries
    [string]$LogFilePath
    [bool]$EnablePersistence
    [bool]$Debug

    # Constructeur
    TransactionLog([string]$transactionId, [string]$logDirectory, [bool]$enablePersistence, [bool]$debug) {
        $this.LogId = "log_$(Get-Date -Format 'yyyyMMddHHmmss')_$(Get-Random -Minimum 10000 -Maximum 99999)"
        $this.TransactionId = $transactionId
        $this.Entries = [System.Collections.Generic.List[hashtable]]::new()
        $this.LogFilePath = Join-Path -Path $logDirectory -ChildPath "$($transactionId)_journal.json"
        $this.EnablePersistence = $enablePersistence
        $this.Debug = $debug

        # Créer le répertoire de logs s'il n'existe pas
        $logDir = Split-Path -Path $this.LogFilePath -Parent
        if (-not (Test-Path -Path $logDir -PathType Container)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }

        # Initialiser le journal
        $this.AddEntry("transaction_start", @{
                Timestamp = (Get-Date).ToString('o')
            })
    }

    # Méthode pour ajouter une entrée au journal
    [void] AddEntry([string]$entryType, [hashtable]$data) {
        $entry = @{
            EntryId   = "entry_$(Get-Date -Format 'yyyyMMddHHmmssffff')_$(Get-Random -Minimum 10000 -Maximum 99999)"
            Type      = $entryType
            Timestamp = (Get-Date).ToString('o')
            Data      = $data
        }

        $this.Entries.Add($entry)
        $this.WriteDebug("Ajout d'une entrée de type '$entryType' au journal")

        # Persister le journal si nécessaire
        if ($this.EnablePersistence) {
            $this.Persist()
        }
    }

    # Méthode pour persister le journal sur disque
    [bool] Persist() {
        try {
            $journalData = @{
                LogId         = $this.LogId
                TransactionId = $this.TransactionId
                Entries       = $this.Entries.ToArray()
                LastUpdated   = (Get-Date).ToString('o')
            }

            $journalJson = ConvertTo-Json -InputObject $journalData -Depth 10
            $journalJson | Out-File -FilePath $this.LogFilePath -Encoding utf8 -Force

            $this.WriteDebug("Journal persisté dans le fichier: $($this.LogFilePath)")
            return $true
        } catch {
            $this.WriteDebug("Erreur lors de la persistance du journal: $_")
            return $false
        }
    }

    # Méthode pour charger le journal depuis le disque
    [bool] Load() {
        try {
            if (Test-Path -Path $this.LogFilePath) {
                $journalJson = Get-Content -Path $this.LogFilePath -Raw -Encoding utf8
                $journalData = ConvertFrom-Json -InputObject $journalJson -AsHashtable

                $this.LogId = $journalData.LogId
                $this.TransactionId = $journalData.TransactionId
                $this.Entries.Clear()

                foreach ($entry in $journalData.Entries) {
                    $this.Entries.Add($entry)
                }

                $this.WriteDebug("Journal chargé depuis le fichier: $($this.LogFilePath)")
                return $true
            } else {
                $this.WriteDebug("Fichier de journal non trouvé: $($this.LogFilePath)")
                return $false
            }
        } catch {
            $this.WriteDebug("Erreur lors du chargement du journal: $_")
            return $false
        }
    }

    # Méthode pour écrire des messages de débogage
    hidden [void] WriteDebug([string]$message) {
        if ($this.Debug) {
            Write-Host "[TransactionLog] $message" -ForegroundColor Cyan
        }
    }
}

#endregion

# Classe pour représenter un point de sauvegarde (savepoint)
class TransactionSavepoint {
    [string]$SavepointId
    [string]$TransactionId
    [int]$OperationIndex
    [datetime]$Timestamp
    [hashtable]$Metadata

    # Constructeur
    TransactionSavepoint([string]$transactionId, [int]$operationIndex) {
        $this.SavepointId = "sp_$(Get-Date -Format 'yyyyMMddHHmmss')_$(Get-Random -Minimum 10000 -Maximum 99999)"
        $this.TransactionId = $transactionId
        $this.OperationIndex = $operationIndex
        $this.Timestamp = Get-Date
        $this.Metadata = @{
            CreatedAt = (Get-Date).ToString('o')
        }
    }

    # Méthode pour obtenir une représentation textuelle du savepoint
    [string] ToString() {
        return "Savepoint $($this.SavepointId) at operation $($this.OperationIndex) ($(Get-Date $this.Timestamp -Format 'yyyy-MM-dd HH:mm:ss'))"
    }
}

# Classe pour la transaction avancée
class AdvancedTransaction {
    # Propriétés
    [string]$TransactionId
    [string]$InstanceId
    [TransactionState]$State
    [IsolationLevel]$IsolationLevel
    [System.Collections.Generic.List[TransactionOperation]]$Operations
    [hashtable]$Resources
    [TransactionLog]$Journal
    [datetime]$StartTime
    [datetime]$ExpiryTime
    [int]$Timeout
    [hashtable]$Options
    [bool]$Debug
    [System.Collections.Generic.Dictionary[string, TransactionSavepoint]]$Savepoints

    # Constructeur
    AdvancedTransaction(
        [string]$instanceId,
        [int]$timeout,
        [hashtable]$options,
        [bool]$debug
    ) {
        $this.TransactionId = "tx_$(Get-Date -Format 'yyyyMMddHHmmss')_$(Get-Random -Minimum 10000 -Maximum 99999)"
        $this.InstanceId = $instanceId
        $this.State = [TransactionState]::Inactive
        $this.IsolationLevel = [IsolationLevel]::ReadCommitted  # Niveau par défaut
        $this.Operations = [System.Collections.Generic.List[TransactionOperation]]::new()
        $this.Resources = @{}
        $this.StartTime = Get-Date
        $this.Timeout = $timeout
        $this.ExpiryTime = $this.StartTime.AddMilliseconds($timeout)
        $this.Options = $options
        $this.Debug = $debug
        $this.Savepoints = [System.Collections.Generic.Dictionary[string, TransactionSavepoint]]::new()

        # Initialiser le journal des transactions
        $logDirectory = if ($options.ContainsKey('LogDirectory')) {
            $options.LogDirectory
        } else {
            Join-Path -Path $env:TEMP -ChildPath "TransactionLogs"
        }

        $enablePersistence = if ($options.ContainsKey('EnablePersistence')) {
            $options.EnablePersistence
        } else {
            $true
        }

        $this.Journal = [TransactionLog]::new($this.TransactionId, $logDirectory, $enablePersistence, $debug)

        # Activer la transaction
        $this.State = [TransactionState]::Active
        $this.WriteDebug("Transaction $($this.TransactionId) créée et activée")
    }

    # Méthode pour ajouter une ressource à la transaction
    [void] AddResource([string]$resourceId, [ITransactionalResource]$resource) {
        if ($this.State -ne [TransactionState]::Active) {
            $this.WriteDebug("Impossible d'ajouter une ressource à une transaction non active")
            throw "La transaction n'est pas dans l'état actif"
        }

        $this.Resources[$resourceId] = $resource
        $this.Journal.AddEntry("resource_added", @{
                ResourceId   = $resourceId
                ResourceType = $resource.ResourceType
                Timestamp    = (Get-Date).ToString('o')
            })

        $this.WriteDebug("Ressource $resourceId ajoutée à la transaction $($this.TransactionId)")
    }

    # Méthode pour enregistrer une opération de lecture
    [object] Read([string]$resourceId) {
        if ($this.State -ne [TransactionState]::Active) {
            $this.WriteDebug("Impossible de lire une ressource dans une transaction non active")
            throw "La transaction n'est pas dans l'état actif"
        }

        # Vérifier si la ressource existe
        if (-not $this.Resources.ContainsKey($resourceId)) {
            $this.WriteDebug("Ressource $resourceId non trouvée dans la transaction")
            throw "Ressource non trouvée: $resourceId"
        }

        $resource = $this.Resources[$resourceId]

        # Acquérir un verrou de lecture selon le niveau d'isolation
        $lockMode = switch ($this.IsolationLevel) {
            ([IsolationLevel]::ReadUncommitted) { "none" }
            ([IsolationLevel]::ReadCommitted) { "shared" }
            ([IsolationLevel]::RepeatableRead) { "shared" }
            ([IsolationLevel]::Serializable) { "exclusive" }
            default { "shared" }
        }

        if ($lockMode -ne "none") {
            $locked = $resource.Lock($this.TransactionId, $lockMode)
            if (-not $locked) {
                $this.WriteDebug("Impossible d'acquérir un verrou de lecture sur la ressource $resourceId")
                throw "Échec de l'acquisition du verrou de lecture"
            }
        }

        # Lire l'état de la ressource
        $resourceState = $resource.GetState()

        # Enregistrer l'opération de lecture
        $operation = [TransactionOperation]::new([OperationType]::Read, $resourceId, $resourceState, $null)
        $this.Operations.Add($operation)

        $this.Journal.AddEntry("read_operation", @{
                OperationId = $operation.OperationId
                ResourceId  = $resourceId
                Timestamp   = (Get-Date).ToString('o')
            })

        $this.WriteDebug("Lecture effectuée sur la ressource $resourceId")
        return $resourceState
    }

    # Méthode pour enregistrer une opération d'écriture
    [bool] Write([string]$resourceId, [object]$newState) {
        if ($this.State -ne [TransactionState]::Active) {
            $this.WriteDebug("Impossible d'écrire sur une ressource dans une transaction non active")
            throw "La transaction n'est pas dans l'état actif"
        }

        # Vérifier si la ressource existe
        if (-not $this.Resources.ContainsKey($resourceId)) {
            $this.WriteDebug("Ressource $resourceId non trouvée dans la transaction")
            throw "Ressource non trouvée: $resourceId"
        }

        $resource = $this.Resources[$resourceId]

        # Acquérir un verrou d'écriture (toujours exclusif)
        $locked = $resource.Lock($this.TransactionId, "exclusive")
        if (-not $locked) {
            $this.WriteDebug("Impossible d'acquérir un verrou d'écriture sur la ressource $resourceId")
            throw "Échec de l'acquisition du verrou d'écriture"
        }

        # Lire l'état actuel de la ressource
        $currentState = $resource.GetState()

        # Enregistrer l'opération d'écriture
        $operation = [TransactionOperation]::new([OperationType]::Write, $resourceId, $currentState, $newState)
        $this.Operations.Add($operation)

        # Stocker l'état en attente dans la ressource
        if ($resource -is [FileTransactionalResource]) {
            $resource.PendingState = $newState
            $resource.HasPendingChanges = $true
        }

        $this.Journal.AddEntry("write_operation", @{
                OperationId = $operation.OperationId
                ResourceId  = $resourceId
                Timestamp   = (Get-Date).ToString('o')
            })

        $this.WriteDebug("Opération d'écriture enregistrée pour la ressource $resourceId")
        return $true
    }

    # Méthode pour enregistrer une opération de suppression
    [bool] Delete([string]$resourceId) {
        if ($this.State -ne [TransactionState]::Active) {
            $this.WriteDebug("Impossible de supprimer une ressource dans une transaction non active")
            throw "La transaction n'est pas dans l'état actif"
        }

        # Vérifier si la ressource existe
        if (-not $this.Resources.ContainsKey($resourceId)) {
            $this.WriteDebug("Ressource $resourceId non trouvée dans la transaction")
            throw "Ressource non trouvée: $resourceId"
        }

        $resource = $this.Resources[$resourceId]

        # Acquérir un verrou d'écriture (toujours exclusif)
        $locked = $resource.Lock($this.TransactionId, "exclusive")
        if (-not $locked) {
            $this.WriteDebug("Impossible d'acquérir un verrou d'écriture sur la ressource $resourceId")
            throw "Échec de l'acquisition du verrou d'écriture"
        }

        # Lire l'état actuel de la ressource
        $currentState = $resource.GetState()

        # Enregistrer l'opération de suppression
        $operation = [TransactionOperation]::new([OperationType]::Delete, $resourceId, $currentState, $null)
        $this.Operations.Add($operation)

        # Stocker l'état en attente dans la ressource (null pour suppression)
        if ($resource -is [FileTransactionalResource]) {
            $resource.PendingState = $null
            $resource.HasPendingChanges = $true
        }

        $this.Journal.AddEntry("delete_operation", @{
                OperationId = $operation.OperationId
                ResourceId  = $resourceId
                Timestamp   = (Get-Date).ToString('o')
            })

        $this.WriteDebug("Opération de suppression enregistrée pour la ressource $resourceId")
        return $true
    }

    # Méthode pour préparer la transaction (phase 1 du commit en deux phases)
    [bool] Prepare() {
        if ($this.State -ne [TransactionState]::Active) {
            $this.WriteDebug("Impossible de préparer une transaction non active")
            return $false
        }

        $this.State = [TransactionState]::Preparing
        $this.WriteDebug("Préparation de la transaction $($this.TransactionId)")

        $this.Journal.AddEntry("prepare_start", @{
                Timestamp = (Get-Date).ToString('o')
            })

        # Vérifier que toutes les ressources sont valides
        $allValid = $true
        foreach ($resourceId in $this.Resources.Keys) {
            $resource = $this.Resources[$resourceId]
            $valid = $resource.Validate()

            if (-not $valid) {
                $this.WriteDebug("Validation échouée pour la ressource $resourceId")
                $allValid = $false
                break
            }
        }

        if (-not $allValid) {
            $this.State = [TransactionState]::Failed
            $this.Journal.AddEntry("prepare_failed", @{
                    Reason    = "resource_validation_failed"
                    Timestamp = (Get-Date).ToString('o')
                })
            $this.WriteDebug("Préparation échouée: validation des ressources")
            return $false
        }

        # Si tout est valide, passer à l'état préparé
        $this.State = [TransactionState]::Prepared
        $this.Journal.AddEntry("prepare_success", @{
                Timestamp = (Get-Date).ToString('o')
            })
        $this.WriteDebug("Transaction $($this.TransactionId) préparée avec succès")
        return $true
    }

    # Méthode pour valider la transaction (phase 2 du commit en deux phases)
    [bool] Commit() {
        # Si la transaction n'est pas préparée, essayer de la préparer
        if ($this.State -eq [TransactionState]::Active) {
            $prepared = $this.Prepare()
            if (-not $prepared) {
                $this.WriteDebug("Impossible de valider la transaction: échec de la préparation")
                return $false
            }
        }

        if ($this.State -ne [TransactionState]::Prepared) {
            $this.WriteDebug("Impossible de valider une transaction non préparée")
            return $false
        }

        $this.State = [TransactionState]::Committing
        $this.WriteDebug("Validation de la transaction $($this.TransactionId)")

        $this.Journal.AddEntry("commit_start", @{
                Timestamp = (Get-Date).ToString('o')
            })

        # Appliquer les changements en attente pour les ressources de type fichier
        foreach ($resourceId in $this.Resources.Keys) {
            $resource = $this.Resources[$resourceId]
            if ($resource -is [FileTransactionalResource]) {
                # Même si HasPendingChanges est false, on applique quand même les changements
                # car le rollback peut avoir réinitialisé l'état en attente
                $success = $resource.ApplyPendingChanges()
                if (-not $success) {
                    $this.WriteDebug("Échec de l'application des changements en attente pour la ressource $resourceId")
                    $this.State = [TransactionState]::Failed
                    $this.Journal.AddEntry("commit_failed", @{
                            Reason    = "pending_changes_application_failed"
                            Timestamp = (Get-Date).ToString('o')
                        })

                    # Tenter un rollback automatique
                    $this.Rollback()
                    return $false
                }
            }
        }

        # Exécuter toutes les opérations
        $allSuccess = $true
        foreach ($operation in $this.Operations) {
            $resource = $this.Resources[$operation.ResourceId]

            # Pour les opérations de lecture, pas besoin d'exécuter
            if ($operation.Type -eq [OperationType]::Read) {
                $operation.IsCompleted = $true
                $operation.Status = "completed"
                continue
            }

            $success = $operation.Execute($resource)

            if (-not $success) {
                $this.WriteDebug("Échec de l'exécution de l'opération $($operation.OperationId) sur la ressource $($operation.ResourceId)")
                $allSuccess = $false
                break
            }
        }

        if (-not $allSuccess) {
            $this.State = [TransactionState]::Failed
            $this.Journal.AddEntry("commit_failed", @{
                    Reason    = "operation_execution_failed"
                    Timestamp = (Get-Date).ToString('o')
                })
            $this.WriteDebug("Validation échouée: exécution des opérations")

            # Tenter un rollback automatique
            $this.Rollback()
            return $false
        }

        # Libérer tous les verrous
        foreach ($resourceId in $this.Resources.Keys) {
            $resource = $this.Resources[$resourceId]
            $resource.Unlock($this.TransactionId)
        }

        # Si tout est validé, passer à l'état validé
        $this.State = [TransactionState]::Committed
        $this.Journal.AddEntry("commit_success", @{
                Timestamp = (Get-Date).ToString('o')
            })
        $this.WriteDebug("Transaction $($this.TransactionId) validée avec succès")
        return $true
    }

    # Méthode pour annuler la transaction
    [bool] Rollback() {
        if ($this.State -eq [TransactionState]::Committed) {
            $this.WriteDebug("Impossible d'annuler une transaction déjà validée")
            return $false
        }

        $this.State = [TransactionState]::RollingBack
        $this.WriteDebug("Annulation de la transaction $($this.TransactionId)")

        $this.Journal.AddEntry("rollback_start", @{
                Timestamp = (Get-Date).ToString('o')
            })

        # Annuler toutes les opérations dans l'ordre inverse
        $reversedOperations = $this.Operations.ToArray()
        [array]::Reverse($reversedOperations)

        $allSuccess = $true
        foreach ($operation in $reversedOperations) {
            $resource = $this.Resources[$operation.ResourceId]
            $success = $operation.Rollback($resource)

            if (-not $success) {
                $this.WriteDebug("Échec de l'annulation de l'opération $($operation.OperationId) sur la ressource $($operation.ResourceId)")
                $allSuccess = $false
                # Continuer malgré l'échec pour tenter de restaurer autant que possible
            }
        }

        # Libérer tous les verrous
        foreach ($resourceId in $this.Resources.Keys) {
            $resource = $this.Resources[$resourceId]
            $resource.Unlock($this.TransactionId)
        }

        if (-not $allSuccess) {
            $this.State = [TransactionState]::Failed
            $this.Journal.AddEntry("rollback_partial", @{
                    Reason    = "operation_rollback_failed"
                    Timestamp = (Get-Date).ToString('o')
                })
            $this.WriteDebug("Annulation partiellement échouée")
            return $false
        }

        # Si tout est annulé, passer à l'état annulé
        $this.State = [TransactionState]::RolledBack
        $this.Journal.AddEntry("rollback_success", @{
                Timestamp = (Get-Date).ToString('o')
            })
        $this.WriteDebug("Transaction $($this.TransactionId) annulée avec succès")
        return $true
    }

    # Méthode pour créer un point de sauvegarde
    [TransactionSavepoint] CreateSavepoint([string]$savepointName = "") {
        if ($this.State -ne [TransactionState]::Active) {
            $this.WriteDebug("Impossible de créer un point de sauvegarde dans une transaction non active")
            throw "La transaction n'est pas dans l'état actif"
        }

        # Créer un nouveau point de sauvegarde à l'index actuel des opérations
        $operationIndex = $this.Operations.Count
        $savepoint = [TransactionSavepoint]::new($this.TransactionId, $operationIndex)

        # Si un nom est fourni, l'utiliser comme clé, sinon utiliser l'ID du savepoint
        $savepointKey = if ([string]::IsNullOrEmpty($savepointName)) {
            $savepoint.SavepointId
        } else {
            $savepointName
        }

        # Enregistrer le point de sauvegarde
        $this.Savepoints[$savepointKey] = $savepoint

        $this.Journal.AddEntry("savepoint_created", @{
                SavepointId    = $savepoint.SavepointId
                SavepointName  = $savepointName
                OperationIndex = $operationIndex
                Timestamp      = (Get-Date).ToString('o')
            })

        $this.WriteDebug("Point de sauvegarde créé: $($savepoint.SavepointId) à l'index $operationIndex")
        return $savepoint
    }

    # Méthode pour revenir à un point de sauvegarde
    [bool] RollbackToSavepoint([string]$savepointNameOrId) {
        if ($this.State -ne [TransactionState]::Active) {
            $this.WriteDebug("Impossible de revenir à un point de sauvegarde dans une transaction non active")
            throw "La transaction n'est pas dans l'état actif"
        }

        # Vérifier si le point de sauvegarde existe
        if (-not $this.Savepoints.ContainsKey($savepointNameOrId)) {
            # Essayer de trouver le savepoint par ID
            $savepoint = $this.Savepoints.Values | Where-Object { $_.SavepointId -eq $savepointNameOrId } | Select-Object -First 1

            if ($null -eq $savepoint) {
                $this.WriteDebug("Point de sauvegarde non trouvé: $savepointNameOrId")
                return $false
            }
        } else {
            $savepoint = $this.Savepoints[$savepointNameOrId]
        }

        $this.Journal.AddEntry("rollback_to_savepoint_start", @{
                SavepointId    = $savepoint.SavepointId
                OperationIndex = $savepoint.OperationIndex
                Timestamp      = (Get-Date).ToString('o')
            })

        # Annuler toutes les opérations après le point de sauvegarde (dans l'ordre inverse)
        if ($this.Operations.Count > $savepoint.OperationIndex) {
            $operationsToRollback = $this.Operations.GetRange($savepoint.OperationIndex, $this.Operations.Count - $savepoint.OperationIndex)
            [array]::Reverse($operationsToRollback)

            $allSuccess = $true
            foreach ($operation in $operationsToRollback) {
                $resource = $this.Resources[$operation.ResourceId]

                # Réinitialiser l'état en attente pour les ressources de type fichier
                if ($resource -is [FileTransactionalResource]) {
                    if ($operation.Type -eq [OperationType]::Write -or $operation.Type -eq [OperationType]::Delete) {
                        $resource.PendingState = $operation.OriginalState
                        $resource.HasPendingChanges = ($null -ne $operation.OriginalState)
                    }
                } else {
                    # Pour les autres types de ressources, utiliser le rollback standard
                    $success = $operation.Rollback($resource)

                    if (-not $success) {
                        $this.WriteDebug("Échec de l'annulation de l'opération $($operation.OperationId) sur la ressource $($operation.ResourceId)")
                        $allSuccess = $false
                        # Continuer malgré l'échec pour tenter de restaurer autant que possible
                    }
                }
            }

            # Supprimer les opérations annulées
            $this.Operations.RemoveRange($savepoint.OperationIndex, $this.Operations.Count - $savepoint.OperationIndex)

            if (-not $allSuccess) {
                $this.Journal.AddEntry("rollback_to_savepoint_partial", @{
                        SavepointId = $savepoint.SavepointId
                        Reason      = "operation_rollback_failed"
                        Timestamp   = (Get-Date).ToString('o')
                    })
                $this.WriteDebug("Retour partiel au point de sauvegarde $($savepoint.SavepointId)")
                return $false
            }
        }

        # Supprimer les points de sauvegarde qui sont après celui-ci
        $savepointsToRemove = @()
        foreach ($key in $this.Savepoints.Keys) {
            if ($this.Savepoints[$key].OperationIndex -gt $savepoint.OperationIndex) {
                $savepointsToRemove += $key
            }
        }

        foreach ($key in $savepointsToRemove) {
            $this.Savepoints.Remove($key)
        }

        $this.Journal.AddEntry("rollback_to_savepoint_success", @{
                SavepointId = $savepoint.SavepointId
                Timestamp   = (Get-Date).ToString('o')
            })
        $this.WriteDebug("Retour au point de sauvegarde $($savepoint.SavepointId) réussi")
        return $true
    }

    # Méthode pour libérer un point de sauvegarde
    [bool] ReleaseSavepoint([string]$savepointNameOrId) {
        if ($this.State -ne [TransactionState]::Active) {
            $this.WriteDebug("Impossible de libérer un point de sauvegarde dans une transaction non active")
            throw "La transaction n'est pas dans l'état actif"
        }

        # Vérifier si le point de sauvegarde existe
        if (-not $this.Savepoints.ContainsKey($savepointNameOrId)) {
            # Essayer de trouver le savepoint par ID
            $savepoint = $this.Savepoints.Values | Where-Object { $_.SavepointId -eq $savepointNameOrId } | Select-Object -First 1

            if ($null -eq $savepoint) {
                $this.WriteDebug("Point de sauvegarde non trouvé: $savepointNameOrId")
                return $false
            }

            # Trouver la clé associée à ce savepoint
            $savepointKey = $this.Savepoints.Keys | Where-Object { $this.Savepoints[$_].SavepointId -eq $savepointNameOrId } | Select-Object -First 1
        } else {
            $savepointKey = $savepointNameOrId
            $savepoint = $this.Savepoints[$savepointNameOrId]
        }

        # Supprimer le point de sauvegarde
        $this.Savepoints.Remove($savepointKey)

        $this.Journal.AddEntry("savepoint_released", @{
                SavepointId   = $savepoint.SavepointId
                SavepointName = $savepointKey
                Timestamp     = (Get-Date).ToString('o')
            })

        $this.WriteDebug("Point de sauvegarde libéré: $($savepoint.SavepointId)")
        return $true
    }

    # Méthode pour obtenir la liste des points de sauvegarde
    [System.Collections.Generic.List[TransactionSavepoint]] GetSavepoints() {
        return [System.Collections.Generic.List[TransactionSavepoint]]::new($this.Savepoints.Values)
    }

    # Méthode pour vérifier si la transaction est expirée
    [bool] IsExpired() {
        return (Get-Date) -gt $this.ExpiryTime
    }

    # Méthode pour écrire des messages de débogage
    hidden [void] WriteDebug([string]$message) {
        if ($this.Debug) {
            Write-Host "[AdvancedTransaction] $message" -ForegroundColor Magenta
        }
    }
}

# Classe pour une ressource transactionnelle basée sur un fichier
class FileTransactionalResource : ITransactionalResource {
    # Propriétés
    [string]$FilePath
    [hashtable]$ActiveLocks
    [bool]$Debug
    [object]$PendingState
    [bool]$HasPendingChanges

    # Constructeur
    FileTransactionalResource([string]$filePath, [bool]$debug) {
        $this.ResourceId = "file_$(Split-Path -Path $filePath -Leaf)"
        $this.ResourceType = "file"
        $this.FilePath = $filePath
        $this.Metadata = @{
            CreatedAt    = (Get-Date).ToString('o')
            LastAccessed = (Get-Date).ToString('o')
        }
        $this.ActiveLocks = @{}
        $this.Debug = $debug
        $this.PendingState = $null
        $this.HasPendingChanges = $false

        $this.WriteDebug("Ressource transactionnelle créée pour le fichier: $filePath")
    }

    # Méthode pour obtenir l'état de la ressource
    [object] GetState() {
        try {
            if (Test-Path -Path $this.FilePath) {
                $content = Get-Content -Path $this.FilePath -Raw -Encoding utf8
                $this.Metadata.LastAccessed = (Get-Date).ToString('o')
                $this.WriteDebug("État récupéré pour le fichier: $($this.FilePath)")
                return $content
            } else {
                $this.WriteDebug("Fichier non trouvé: $($this.FilePath)")
                return $null
            }
        } catch {
            $this.WriteDebug("Erreur lors de la récupération de l'état: $_")
            throw "Erreur lors de la récupération de l'état: $_"
        }
    }

    # Méthode pour définir l'état de la ressource (stocke l'état en mémoire jusqu'au commit)
    [bool] SetState([object]$state) {
        try {
            # Stocker l'état en mémoire pour application ultérieure lors du commit
            $this.PendingState = $state
            $this.HasPendingChanges = $true
            $this.Metadata.LastAccessed = (Get-Date).ToString('o')

            $this.WriteDebug("État en attente défini pour le fichier: $($this.FilePath)")
            return $true
        } catch {
            $this.WriteDebug("Erreur lors de la définition de l'état en attente: $_")
            return $false
        }
    }

    # Méthode pour appliquer réellement les changements au fichier (appelée lors du commit)
    [bool] ApplyPendingChanges() {
        try {
            if (-not $this.HasPendingChanges) {
                $this.WriteDebug("Aucun changement en attente à appliquer pour le fichier: $($this.FilePath)")
                return $true
            }

            if ($null -eq $this.PendingState) {
                # Si l'état est null, supprimer le fichier
                if (Test-Path -Path $this.FilePath) {
                    Remove-Item -Path $this.FilePath -Force
                    $this.WriteDebug("Fichier supprimé: $($this.FilePath)")
                }
            } else {
                # Sinon, écrire le contenu dans le fichier
                $this.PendingState | Out-File -FilePath $this.FilePath -Encoding utf8 -Force
                $this.WriteDebug("État appliqué au fichier: $($this.FilePath)")
            }

            $this.HasPendingChanges = $false
            $this.PendingState = $null
            return $true
        } catch {
            $this.WriteDebug("Erreur lors de l'application des changements: $_")
            return $false
        }
    }

    # Méthode pour verrouiller la ressource
    [bool] Lock([string]$transactionId, [string]$lockMode) {
        try {
            # Vérifier si la ressource est déjà verrouillée
            if ($this.ActiveLocks.Count -gt 0) {
                # Si c'est le même ID de transaction, renouveler le verrou
                if ($this.ActiveLocks.ContainsKey($transactionId)) {
                    $this.ActiveLocks[$transactionId].Timestamp = (Get-Date).ToString('o')
                    $this.WriteDebug("Verrou renouvelé pour la transaction: $transactionId")
                    return $true
                }

                # Si c'est un verrou exclusif, refuser tout autre verrou
                foreach ($lock in $this.ActiveLocks.Values) {
                    if ($lock.Mode -eq "exclusive") {
                        $this.WriteDebug("Verrou exclusif déjà détenu par une autre transaction")
                        return $false
                    }
                }

                # Si on demande un verrou exclusif mais qu'il y a déjà des verrous partagés, refuser
                if ($lockMode -eq "exclusive" -and $this.ActiveLocks.Count -gt 0) {
                    $this.WriteDebug("Impossible d'acquérir un verrou exclusif, des verrous partagés existent")
                    return $false
                }
            }

            # Ajouter le verrou
            $this.ActiveLocks[$transactionId] = @{
                TransactionId = $transactionId
                Mode          = $lockMode
                Timestamp     = (Get-Date).ToString('o')
            }

            $this.WriteDebug("Verrou $lockMode acquis pour la transaction: $transactionId")
            return $true
        } catch {
            $this.WriteDebug("Erreur lors de l'acquisition du verrou: $_")
            return $false
        }
    }

    # Méthode pour déverrouiller la ressource
    [bool] Unlock([string]$transactionId) {
        try {
            if ($this.ActiveLocks.ContainsKey($transactionId)) {
                $this.ActiveLocks.Remove($transactionId)
                $this.WriteDebug("Verrou libéré pour la transaction: $transactionId")
                return $true
            } else {
                $this.WriteDebug("Aucun verrou trouvé pour la transaction: $transactionId")
                return $false
            }
        } catch {
            $this.WriteDebug("Erreur lors de la libération du verrou: $_")
            return $false
        }
    }

    # Méthode pour valider la ressource
    [bool] Validate() {
        try {
            # Vérifier si le répertoire parent existe
            $parentDir = Split-Path -Path $this.FilePath -Parent
            if (-not (Test-Path -Path $parentDir -PathType Container)) {
                $this.WriteDebug("Le répertoire parent n'existe pas: $parentDir")
                return $false
            }

            # Si le fichier existe, vérifier qu'il est accessible en lecture/écriture
            if (Test-Path -Path $this.FilePath) {
                try {
                    $testContent = Get-Content -Path $this.FilePath -Raw -ErrorAction Stop
                    $testContent | Out-File -FilePath "$($this.FilePath).test" -Encoding utf8 -Force -ErrorAction Stop
                    Remove-Item -Path "$($this.FilePath).test" -Force -ErrorAction Stop
                } catch {
                    $this.WriteDebug("Le fichier n'est pas accessible en lecture/écriture: $($this.FilePath)")
                    return $false
                }
            } else {
                # Si le fichier n'existe pas, vérifier si on peut le créer
                try {
                    "" | Out-File -FilePath $this.FilePath -Encoding utf8 -Force -ErrorAction Stop
                    Remove-Item -Path $this.FilePath -Force -ErrorAction Stop
                } catch {
                    $this.WriteDebug("Impossible de créer le fichier: $($this.FilePath)")
                    return $false
                }
            }

            $this.WriteDebug("Ressource validée: $($this.FilePath)")
            return $true
        } catch {
            $this.WriteDebug("Erreur lors de la validation de la ressource: $_")
            return $false
        }
    }

    # Méthode pour écrire des messages de débogage
    hidden [void] WriteDebug([string]$message) {
        if ($this.Debug) {
            Write-Host "[FileResource] $message" -ForegroundColor Blue
        }
    }
}

# Fonction pour créer une nouvelle transaction avancée
function New-AdvancedTransaction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$InstanceId = "instance_$(Get-Date -Format 'yyyyMMddHHmmss')_$(Get-Random -Minimum 10000 -Maximum 99999)",

        [Parameter(Mandatory = $false)]
        [int]$Timeout = 60000,

        [Parameter(Mandatory = $false)]
        [hashtable]$Options = @{},

        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    return [AdvancedTransaction]::new($InstanceId, $Timeout, $Options, $EnableDebug.IsPresent)
}

# Fonction pour créer une nouvelle ressource transactionnelle basée sur un fichier
function New-FileTransactionalResource {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    return [FileTransactionalResource]::new($FilePath, $EnableDebug.IsPresent)
}

# Pas besoin d'exporter les fonctions car ce n'est pas un module
# Export-ModuleMember -Function New-AdvancedTransaction, New-FileTransactionalResource
