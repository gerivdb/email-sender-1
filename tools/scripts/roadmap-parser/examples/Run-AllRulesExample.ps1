# Run-AllRulesExample.ps1
# Exemple d'utilisation du script pour exÃ©cuter toutes les rÃ¨gles de dÃ©tection d'anomalies SQL Server

# Chemin du script d'exÃ©cution de toutes les rÃ¨gles
$runAllRulesScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\Run-AllSqlPermissionRules.ps1"

# ParamÃ¨tres d'exÃ©cution
$params = @{
    ServerInstance = "localhost\SQLEXPRESS"  # Remplacer par votre instance SQL Server
    OutputPath = "C:\Temp\SqlPermissionAnomaliesReport.html"
    ExcludeDatabases = @("tempdb", "model", "msdb")
    IncludeObjectLevel = $true
    Verbose = $true
}

# ExÃ©cuter toutes les rÃ¨gles
& $runAllRulesScriptPath @params

# Exemple avec envoi d'email (dÃ©commenter et modifier les paramÃ¨tres pour utiliser)
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
