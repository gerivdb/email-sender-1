# Export-ToPowerBIExample.ps1
# Exemple d'utilisation du script d'exportation des donnÃƒÂ©es d'anomalies vers Power BI

# Chemin du script d'exportation
$exportScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\development\scripts\Export-SqlPermissionsToPowerBI.ps1"

# ParamÃƒÂ¨tres d'exportation
$params = @{
    ServerInstance = "localhost\SQLEXPRESS"  # Remplacer par votre instance SQL Server
    OutputFolder = "C:\Reports\SqlPermissionAnomalies\PowerBI"
    ExcludeDatabases = @("tempdb", "model", "msdb")
    IncludeObjectLevel = $true
    GenerateTemplate = $true
    Verbose = $true
}

# Exporter les donnÃƒÂ©es
$result = & $exportScriptPath @params

# Afficher les rÃƒÂ©sultats
Write-Host "Exportation terminÃƒÂ©e pour l'instance: $($result.ServerInstance)" -ForegroundColor Green
Write-Host "Date d'exportation: $($result.ExportDate)" -ForegroundColor Green
Write-Host "Dossier de sortie: $($result.OutputFolder)" -ForegroundColor Green
Write-Host "Nombre total d'anomalies: $($result.TotalAnomalies)" -ForegroundColor Yellow
Write-Host "Nombre de rÃƒÂ¨gles: $($result.RuleCount)" -ForegroundColor Yellow
Write-Host "Nombre de dÃƒÂ©tails d'anomalies: $($result.DetailsCount)" -ForegroundColor Yellow

# Ouvrir le dossier d'exportation
Start-Process $params.OutputFolder
