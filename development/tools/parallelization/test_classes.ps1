# Script de test pour les classes du module UnifiedParallel

# Définir la classe ParallelResult pour les tests
class ParallelResult {
    [string]$Id
    [object]$Value
    [bool]$Success
    [System.Management.Automation.ErrorRecord]$Error
    [datetime]$StartTime
    [datetime]$EndTime
    [timespan]$Duration
    [int]$ThreadId
    [int]$RunspaceId
    [hashtable]$Metadata
    [object]$SyncRoot
    [int]$Priority
    [string]$Status
    [string]$TaskType
    [string]$CorrelationId
    [System.Collections.Generic.Dictionary[string, object]]$Tags

    ParallelResult() {
        $this.Id = [guid]::NewGuid().ToString()
        $this.Success = $true
        $this.StartTime = [datetime]::Now
        $this.SyncRoot = [System.Object]::new()
        $this.Status = "Pending"
        $this.Priority = 1
        $this.TaskType = "Default"
        $this.Tags = [System.Collections.Generic.Dictionary[string, object]]::new()
    }

    [void] Complete([object]$value) {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            $this.Value = $value
            $this.EndTime = [datetime]::Now
            $this.Duration = $this.EndTime - $this.StartTime
            $this.Status = "Completed"
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [void] MarkFailed([System.Management.Automation.ErrorRecord]$errorRecord) {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            $this.Success = $false
            $this.Error = $errorRecord
            $this.EndTime = [datetime]::Now
            $this.Duration = $this.EndTime - $this.StartTime
            $this.Status = "Failed"
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [string] ToString() {
        return "[$($this.Status)] ID: $($this.Id), Success: $($this.Success), Duration: $($this.Duration.TotalMilliseconds) ms"
    }
}

# Créer une instance de ParallelResult
$result = [ParallelResult]::new()
Write-Host "Nouvelle instance de ParallelResult créée avec ID: $($result.Id)"
Write-Host "Status initial: $($result.Status)"
Write-Host "Success initial: $($result.Success)"

# Tester la méthode Complete
$result.Complete("Test réussi")
Write-Host "Après Complete() - Status: $($result.Status)"
Write-Host "Après Complete() - Value: $($result.Value)"
Write-Host "Après Complete() - Success: $($result.Success)"
Write-Host "Après Complete() - Duration: $($result.Duration.TotalMilliseconds) ms"

# Créer une autre instance pour tester MarkFailed
$failedResult = [ParallelResult]::new()
try {
    throw "Erreur de test"
} catch {
    $failedResult.MarkFailed($_)
}
Write-Host "Après MarkFailed() - Status: $($failedResult.Status)"
Write-Host "Après MarkFailed() - Success: $($failedResult.Success)"
Write-Host "Après MarkFailed() - Error: $($failedResult.Error.Exception.Message)"
Write-Host "Après MarkFailed() - Duration: $($failedResult.Duration.TotalMilliseconds) ms"

Write-Host "Test des classes terminé avec succès."
