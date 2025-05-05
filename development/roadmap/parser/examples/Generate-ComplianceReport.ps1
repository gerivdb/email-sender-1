# Generate-ComplianceReport.ps1
# Exemple d'utilisation du script de gÃƒÂ©nÃƒÂ©ration de rapport de conformitÃƒÂ©

# Chemin du script de gÃƒÂ©nÃƒÂ©ration de rapport
$reportScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\development\scripts\Generate-SqlPermissionComplianceReport.ps1"

# ParamÃƒÂ¨tres du rapport
$params = @{
    ServerInstance = "localhost\SQLEXPRESS"  # Remplacer par votre instance SQL Server
    OutputPath = "C:\Temp\SqlPermissionComplianceReport.html"
    ExcludeDatabases = @("tempdb", "model", "msdb")
    IncludeObjectLevel = $true
    Verbose = $true
}

# GÃƒÂ©nÃƒÂ©rer le rapport
& $reportScriptPath @params

# Exemple avec envoi d'email (dÃƒÂ©commenter et modifier les paramÃƒÂ¨tres pour utiliser)
<#
$emailParams = @{
    ServerInstance = "localhost\SQLEXPRESS"
    OutputPath = "C:\Temp\SqlPermissionComplianceReport.html"
    ExcludeDatabases = @("tempdb", "model", "msdb")
    IncludeObjectLevel = $true
    SendEmail = $true
    SmtpServer = "smtp.example.com"
    FromAddress = "reports@example.com"
    ToAddress = @("admin@example.com", "security@example.com")
    Subject = "Rapport de conformitÃƒÂ© SQL Server - $(Get-Date -Format 'yyyy-MM-dd')"
    Verbose = $true
}

& $reportScriptPath @emailParams
#>
