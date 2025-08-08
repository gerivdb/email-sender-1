#region Configuration rollback (DRY)
$Global:RollbackConfig = @{
   BackupPath    = ".\backups\latest"
   LogPath       = ".\logs\rollback-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
   RestoreScopes = @("scripts", "docs", ".github")
}
#endregion

#region Fonctions rollback (SOLID)
function Write-RollbackLog {
   param([string]$Message, [string]$Level = "INFO")
   $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
   Write-Host $logEntry -ForegroundColor $(switch ($Level) { "ERROR" { "Red" }; "WARN" { "Yellow" }; "SUCCESS" { "Green" }; default { "Cyan" } })
   Add-Content -Path $Global:RollbackConfig.LogPath -Value $logEntry
}

function Test-BackupAvailability {
   if (-not (Test-Path $Global:RollbackConfig.BackupPath)) {
      Write-RollbackLog "❌ Backup non disponible: $($Global:RollbackConfig.BackupPath)" "ERROR"
      return $false
   }
   Write-RollbackLog "✅ Backup disponible: $($Global:RollbackConfig.BackupPath)" "SUCCESS"
   return $true
}

function Restore-FromBackup {
   param([string]$Scope)
    
   $sourcePath = Join-Path $Global:RollbackConfig.BackupPath $Scope
   $targetPath = ".\$Scope"
    
   if (Test-Path $sourcePath) {
      try {
         robocopy $sourcePath $targetPath /MIR /NFL /NDL /NJH /NJS | Out-Null
         Write-RollbackLog "✅ Restauration réussie: $Scope" "SUCCESS"
         return $true
      }
      catch {
         Write-RollbackLog "❌ Échec restauration $Scope : $($_.Exception.Message)" "ERROR"
         return $false
      }
   }
   else {
      Write-RollbackLog "⚠️ Backup manquant pour scope: $Scope" "WARN"
      return $false
   }
}
#endregion

#region Workflow rollback principal
Write-RollbackLog "🔄 Démarrage procédure rollback SOTA" "INFO"

if (-not (Test-BackupAvailability)) {
   Write-RollbackLog "🚨 ROLLBACK IMPOSSIBLE - Backup manquant" "ERROR"
   exit 1
}

$failedScopes = @()
foreach ($scope in $Global:RollbackConfig.RestoreScopes) {
   if (-not (Restore-FromBackup -Scope $scope)) {
      $failedScopes += $scope
   }
}

if ($failedScopes.Count -eq 0) {
   Write-RollbackLog "🎉 Rollback terminé avec succès" "SUCCESS"
   exit 0
}
else {
   Write-RollbackLog "🚨 Rollback partiel - Échecs: $($failedScopes -join ', ')" "ERROR"
   exit 2
}
#endregion