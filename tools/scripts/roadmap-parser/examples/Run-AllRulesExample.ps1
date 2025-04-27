# Run-AllRulesExample.ps1
# Exemple d'utilisation du script pour exécuter toutes les règles de détection d'anomalies SQL Server

# Chemin du script d'exécution de toutes les règles
$runAllRulesScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\Run-AllSqlPermissionRules.ps1"

# Paramètres d'exécution
$params = @{
    ServerInstance = "localhost\SQLEXPRESS"  # Remplacer par votre instance SQL Server
    OutputPath = "C:\Temp\SqlPermissionAnomaliesReport.html"
    ExcludeDatabases = @("tempdb", "model", "msdb")
    IncludeObjectLevel = $true
    Verbose = $true
}

# Exécuter toutes les règles
& $runAllRulesScriptPath @params

# Exemple avec envoi d'email (décommenter et modifier les paramètres pour utiliser)
<#
$emailParams = @{
    ServerInstance = "localhost\SQLEXPRESS"
    OutputPath = "C:\Temp\SqlPermissionAnomaliesReport.html"
    ExcludeDatabases = @("tempdb", "model", "msdb")
    IncludeObjectLevel = $true
    SendEmail = $true
    SmtpServer = "smtp.example.com"
    FromAddress = "reports@example.com"
    ToAddress = @("admin@example.com", "security@example.com")
    Subject = "Rapport d'anomalies SQL Server - $(Get-Date -Format 'yyyy-MM-dd')"
    Verbose = $true
}

& $runAllRulesScriptPath @emailParams
#>
