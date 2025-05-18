# Script de test pour la classe ParallelErrorInfo

# Définir la classe ParallelErrorInfo pour les tests
class ParallelErrorInfo {
    [string]$Id
    [System.Management.Automation.ErrorRecord]$Error
    [string]$Category
    [int]$Severity
    [bool]$IsRetryable
    [int]$RetryCount
    [string]$Source
    [hashtable]$Context
    [object]$SyncRoot
    [datetime]$Timestamp
    [string]$CorrelationId
    [string]$ErrorCode
    [System.Collections.Generic.Dictionary[string, object]]$Tags

    ParallelErrorInfo([System.Management.Automation.ErrorRecord]$errorRecord) {
        $this.Id = [guid]::NewGuid().ToString()
        $this.Error = $errorRecord
        $this.Category = "Unknown"
        $this.Severity = 1
        $this.IsRetryable = $false
        $this.RetryCount = 0
        $this.SyncRoot = [System.Object]::new()
        $this.Timestamp = [datetime]::Now
        $this.Tags = [System.Collections.Generic.Dictionary[string, object]]::new()
        
        # Essayer d'extraire un code d'erreur
        if ($errorRecord.Exception -is [System.Management.Automation.RuntimeException]) {
            $this.ErrorCode = "Runtime"
        } elseif ($errorRecord.Exception -is [System.IO.IOException]) {
            $this.ErrorCode = "IO"
        } elseif ($errorRecord.Exception -is [System.Net.WebException]) {
            $this.ErrorCode = "Network"
        } elseif ($errorRecord.Exception -is [System.ArgumentException]) {
            $this.ErrorCode = "Argument"
        } else {
            $this.ErrorCode = "General"
        }
    }

    [void] IncrementRetryCount() {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            $this.RetryCount++
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [void] SetRetryable([bool]$isRetryable) {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            $this.IsRetryable = $isRetryable
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [string] ToString() {
        return "[$($this.Category)] [$($this.ErrorCode)] $($this.Error.Exception.Message) | Retries: $($this.RetryCount)"
    }
}

# Créer une erreur pour tester
try {
    throw "Erreur de test pour ParallelErrorInfo"
} catch {
    $errorRecord = $_
    $errorInfo = [ParallelErrorInfo]::new($errorRecord)
    
    Write-Host "Nouvelle instance de ParallelErrorInfo créée avec ID: $($errorInfo.Id)"
    Write-Host "Message d'erreur: $($errorInfo.Error.Exception.Message)"
    Write-Host "Catégorie initiale: $($errorInfo.Category)"
    Write-Host "Code d'erreur: $($errorInfo.ErrorCode)"
    Write-Host "Nombre de tentatives initial: $($errorInfo.RetryCount)"
    Write-Host "Est réessayable: $($errorInfo.IsRetryable)"
    
    # Tester les méthodes
    $errorInfo.IncrementRetryCount()
    $errorInfo.IncrementRetryCount()
    Write-Host "Après IncrementRetryCount() x2 - RetryCount: $($errorInfo.RetryCount)"
    
    $errorInfo.SetRetryable($true)
    Write-Host "Après SetRetryable(true) - IsRetryable: $($errorInfo.IsRetryable)"
    
    # Tester ToString()
    Write-Host "ToString(): $($errorInfo.ToString())"
}

Write-Host "Test de ParallelErrorInfo terminé avec succès."
