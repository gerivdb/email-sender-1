# Export-ToPowerBIExample.ps1
# Exemple d'utilisation du script d'exportation des donnÃ©es d'anomalies vers Power BI

# Chemin du script d'exportation
$exportScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\development\scripts\Export-SqlPermissionsToPowerBI.ps1"

# ParamÃ¨tres d'exportation
$params = @{
    ServerInstance = "localhost\SQLEXPRESS"  # Remplacer par votre instance SQL Server
    OutputFolder = "C:\Reports\SqlPermissionAnomalies\PowerBI"
    ExcludeDatabases = @("tempdb", "model", "msdb")
    IncludeObjectLevel = $true
    GenerateTemplate = $true
    Verbose = $true
}

# Exporter les donnÃ©es
$result = & $exportScriptPath @params

# Afficher les rÃ©sultats
Write-Host "Exportation terminÃ©e pour l'instance: $($result.ServerInstance)" -ForegroundColor Green
Write-Host "Date d'exportation: $($result.ExportDate)" -ForegroundColor Green
Write-Host "Dossier de sortie: $($result.OutputFolder)" -ForegroundColor Green
Write-Host "Nombre total d'anomalies: $($result.TotalAnomalies)" -ForegroundColor Yellow
Write-Host "Nombre de rÃ¨gles: $($result.RuleCount)" -ForegroundColor Yellow
Write-Host "Nombre de dÃ©tails d'anomalies: $($result.DetailsCount)" -ForegroundColor Yellow

# Ouvrir le dossier d'exportation
Start-Process $params.OutputFolder
