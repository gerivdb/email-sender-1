# Run-AllRulesExample.ps1
# Exemple d'utilisation du script pour exÃƒÂ©cuter toutes les rÃƒÂ¨gles de dÃƒÂ©tection d'anomalies SQL Server

# Chemin du script d'exÃƒÂ©cution de toutes les rÃƒÂ¨gles
$runAllRulesScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\development\scripts\Run-AllSqlPermissionRules.ps1"

# ParamÃƒÂ¨tres d'exÃƒÂ©cution
$params = @{
    ServerInstance = "localhost\SQLEXPRESS"  # Remplacer par votre instance SQL Server
    OutputPath = "C:\Temp\SqlPermissionAnomaliesReport.html"
    ExcludeDatabases = @("tempdb", "model", "msdb")
    IncludeObjectLevel = $true
    Verbose = $true
}

# ExÃƒÂ©cuter toutes les rÃƒÂ¨gles
& $runAllRulesScriptPath @params

# Exemple avec envoi d'email (dÃƒÂ©commenter et modifier les paramÃƒÂ¨tres pour utiliser)
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
