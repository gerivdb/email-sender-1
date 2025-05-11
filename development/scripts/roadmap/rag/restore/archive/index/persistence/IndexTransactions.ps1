# IndexTransactions.ps1
# Script implémentant la gestion des transactions et verrouillage pour les index
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$segmentationPath = Join-Path -Path $scriptPath -ChildPath "IndexSegmentation.ps1"

if (Test-Path -Path $segmentationPath) {
    . $segmentationPath
} else {
    Write-Error "Le fichier IndexSegmentation.ps1 est introuvable."
    exit 1
}

# Classe pour représenter une opération de transaction
class IndexOperation {
    # Type d'opération (Add, Update, Remove)
    [string]$Type
    
    # Document concerné par l'opération
    [IndexDocument]$Document
    
    # ID du document (pour les suppressions)
    [string]$DocumentId
    
    # Constructeur par défaut
    IndexOperation() {
        $this.Type = "Add"
        $this.Document = $null
        $this.DocumentId = ""
    }
    
    # Constructeur pour ajout/mise à jour
    IndexOperation([string]$type, [IndexDocument]$document) {
        $this.Type = $type
        $this.Document = $document
        $this.DocumentId = $document.Id
    }
    
    # Constructeur pour suppression
    IndexOperation([string]$type, [string]$documentId) {
        $this.Type = $type
        $this.Document = $null
        $this.DocumentId = $documentId
    }
    
    # Méthode pour convertir en chaîne
    [string] ToString() {
        return "$($this.Type): $($this.DocumentId)"
    }
}

# Classe pour représenter une transaction
class IndexTransaction {
    # ID de la transaction
    [string]$Id
    
    # Liste des opérations
    [System.Collections.Generic.List[IndexOperation]]$Operations
    
    # État de la transaction (Pending, Committed, RolledBack)
    [string]$State
    
    # Horodatage de création
    [DateTime]$CreatedAt
    
    # Horodatage de validation ou annulation
    [DateTime]$CompletedAt
    
    # Constructeur par défaut
    IndexTransaction() {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.Operations = [System.Collections.Generic.List[IndexOperation]]::new()
        $this.State = "Pending"
        $this.CreatedAt = Get-Date
        $this.CompletedAt = [DateTime]::MinValue
    }
    
    # Méthode pour ajouter une opération
    [void] AddOperation([IndexOperation]$operation) {
        if ($this.State -ne "Pending") {
            throw "Impossible d'ajouter une opération à une transaction $($this.State)"
        }
        
        $this.Operations.Add($operation)
    }
    
    # Méthode pour ajouter un document
    [void] AddDocument([IndexDocument]$document) {
        $operation = [IndexOperation]::new("Add", $document)
        $this.AddOperation($operation)
    }
    
    # Méthode pour mettre à jour un document
    [void] UpdateDocument([IndexDocument]$document) {
        $operation = [IndexOperation]::new("Update", $document)
        $this.AddOperation($operation)
    }
    
    # Méthode pour supprimer un document
    [void] RemoveDocument([string]$documentId) {
        $operation = [IndexOperation]::new("Remove", $documentId)
        $this.AddOperation($operation)
    }
    
    # Méthode pour valider la transaction
    [void] Commit() {
        if ($this.State -ne "Pending") {
            throw "Impossible de valider une transaction $($this.State)"
        }
        
        $this.State = "Committed"
        $this.CompletedAt = Get-Date
    }
    
    # Méthode pour annuler la transaction
    [void] Rollback() {
        if ($this.State -ne "Pending") {
            throw "Impossible d'annuler une transaction $($this.State)"
        }
        
        $this.State = "RolledBack"
        $this.CompletedAt = Get-Date
    }
    
    # Méthode pour convertir en chaîne
    [string] ToString() {
        return "Transaction $($this.Id) ($($this.State)): $($this.Operations.Count) opérations"
    }
}

# Classe pour gérer les transactions d'index
class IndexTransactionManager {
    # Gestionnaire de segments
    [IndexSegmentManager]$SegmentManager
    
    # Journal des transactions
    [System.Collections.Generic.List[IndexTransaction]]$TransactionLog
    
    # Transaction active
    [IndexTransaction]$ActiveTransaction
    
    # Verrou global
    [object]$GlobalLock
    
    # Verrous par document
    [System.Collections.Generic.Dictionary[string, object]]$DocumentLocks
    
    # Constructeur par défaut
    IndexTransactionManager() {
        $this.SegmentManager = $null
        $this.TransactionLog = [System.Collections.Generic.List[IndexTransaction]]::new()
        $this.ActiveTransaction = $null
        $this.GlobalLock = New-Object object
        $this.DocumentLocks = [System.Collections.Generic.Dictionary[string, object]]::new()
    }
    
    # Constructeur avec gestionnaire de segments
    IndexTransactionManager([IndexSegmentManager]$segmentManager) {
        $this.SegmentManager = $segmentManager
        $this.TransactionLog = [System.Collections.Generic.List[IndexTransaction]]::new()
        $this.ActiveTransaction = $null
        $this.GlobalLock = New-Object object
        $this.DocumentLocks = [System.Collections.Generic.Dictionary[string, object]]::new()
    }
    
    # Méthode pour démarrer une transaction
    [IndexTransaction] BeginTransaction() {
        # Acquérir le verrou global
        [System.Threading.Monitor]::Enter($this.GlobalLock)
        
        try {
            # Vérifier s'il y a déjà une transaction active
            if ($null -ne $this.ActiveTransaction) {
                throw "Une transaction est déjà active"
            }
            
            # Créer une nouvelle transaction
            $this.ActiveTransaction = [IndexTransaction]::new()
            
            return $this.ActiveTransaction
        } catch {
            # Libérer le verrou global en cas d'erreur
            [System.Threading.Monitor]::Exit($this.GlobalLock)
            throw
        }
    }
    
    # Méthode pour valider une transaction
    [bool] CommitTransaction() {
        try {
            # Vérifier s'il y a une transaction active
            if ($null -eq $this.ActiveTransaction) {
                throw "Aucune transaction active"
            }
            
            # Acquérir les verrous pour tous les documents concernés
            $docIds = [System.Collections.Generic.HashSet[string]]::new()
            
            foreach ($operation in $this.ActiveTransaction.Operations) {
                $docIds.Add($operation.DocumentId)
            }
            
            $acquiredLocks = [System.Collections.Generic.List[object]]::new()
            
            foreach ($docId in $docIds) {
                $lockObj = $this.AcquireDocumentLock($docId)
                $acquiredLocks.Add($lockObj)
            }
            
            try {
                # Appliquer les opérations
                foreach ($operation in $this.ActiveTransaction.Operations) {
                    switch ($operation.Type) {
                        "Add" {
                            $this.SegmentManager.AddDocument($operation.Document)
                        }
                        "Update" {
                            $this.SegmentManager.AddDocument($operation.Document)
                        }
                        "Remove" {
                            $this.SegmentManager.RemoveDocument($operation.DocumentId)
                        }
                    }
                }
                
                # Valider la transaction
                $this.ActiveTransaction.Commit()
                
                # Ajouter la transaction au journal
                $this.TransactionLog.Add($this.ActiveTransaction)
                
                # Effacer la transaction active
                $this.ActiveTransaction = $null
                
                return $true
            } finally {
                # Libérer les verrous des documents
                foreach ($docId in $docIds) {
                    $this.ReleaseDocumentLock($docId)
                }
            }
        } finally {
            # Libérer le verrou global
            [System.Threading.Monitor]::Exit($this.GlobalLock)
        }
    }
    
    # Méthode pour annuler une transaction
    [bool] RollbackTransaction() {
        try {
            # Vérifier s'il y a une transaction active
            if ($null -eq $this.ActiveTransaction) {
                throw "Aucune transaction active"
            }
            
            # Annuler la transaction
            $this.ActiveTransaction.Rollback()
            
            # Ajouter la transaction au journal
            $this.TransactionLog.Add($this.ActiveTransaction)
            
            # Effacer la transaction active
            $this.ActiveTransaction = $null
            
            return $true
        } finally {
            # Libérer le verrou global
            [System.Threading.Monitor]::Exit($this.GlobalLock)
        }
    }
    
    # Méthode pour ajouter un document dans la transaction active
    [bool] AddDocument([IndexDocument]$document) {
        # Vérifier s'il y a une transaction active
        if ($null -eq $this.ActiveTransaction) {
            throw "Aucune transaction active"
        }
        
        # Ajouter l'opération à la transaction
        $this.ActiveTransaction.AddDocument($document)
        
        return $true
    }
    
    # Méthode pour mettre à jour un document dans la transaction active
    [bool] UpdateDocument([IndexDocument]$document) {
        # Vérifier s'il y a une transaction active
        if ($null -eq $this.ActiveTransaction) {
            throw "Aucune transaction active"
        }
        
        # Ajouter l'opération à la transaction
        $this.ActiveTransaction.UpdateDocument($document)
        
        return $true
    }
    
    # Méthode pour supprimer un document dans la transaction active
    [bool] RemoveDocument([string]$documentId) {
        # Vérifier s'il y a une transaction active
        if ($null -eq $this.ActiveTransaction) {
            throw "Aucune transaction active"
        }
        
        # Ajouter l'opération à la transaction
        $this.ActiveTransaction.RemoveDocument($documentId)
        
        return $true
    }
    
    # Méthode pour acquérir un verrou de document
    [object] AcquireDocumentLock([string]$documentId) {
        if (-not $this.DocumentLocks.ContainsKey($documentId)) {
            $this.DocumentLocks[$documentId] = New-Object object
        }
        
        $lockObj = $this.DocumentLocks[$documentId]
        
        # Acquérir le verrou
        [System.Threading.Monitor]::Enter($lockObj)
        
        return $lockObj
    }
    
    # Méthode pour libérer un verrou de document
    [void] ReleaseDocumentLock([string]$documentId) {
        if ($this.DocumentLocks.ContainsKey($documentId)) {
            $lockObj = $this.DocumentLocks[$documentId]
            
            # Libérer le verrou
            [System.Threading.Monitor]::Exit($lockObj)
        }
    }
    
    # Méthode pour obtenir le journal des transactions
    [IndexTransaction[]] GetTransactionLog() {
        return $this.TransactionLog.ToArray()
    }
    
    # Méthode pour purger le journal des transactions
    [void] PurgeTransactionLog() {
        $this.TransactionLog.Clear()
    }
}

# Fonction pour créer un gestionnaire de transactions d'index
function New-IndexTransactionManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [IndexSegmentManager]$SegmentManager
    )
    
    return [IndexTransactionManager]::new($SegmentManager)
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-IndexTransactionManager
