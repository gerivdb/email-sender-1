# Generate-ComplianceReport.ps1
# Exemple d'utilisation du script de gÃ©nÃ©ration de rapport de conformitÃ©

# Chemin du script de gÃ©nÃ©ration de rapport
$reportScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\Generate-SqlPermissionComplianceReport.ps1"

# ParamÃ¨tres du rapport
$params = @{
    ServerInstance = "localhost\SQLEXPRESS"  # Remplacer par votre instance SQL Server
    OutputPath = "C:\Temp\SqlPermissionComplianceReport.html"
    ExcludeDatabases = @("tempdb", "model", "msdb")
    IncludeObjectLevel = $true
    Verbose = $true
}

# GÃ©nÃ©rer le rapport
& $reportScriptPath @params

# Exemple avec envoi d'email (dÃ©commenter et modifier les paramÃ¨tres pour utiliser)
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
    Subject = "Rapport de conformitÃ© SQL Server - $(Get-Date -Format 'yyyy-MM-dd')"
    Verbose = $true
}

& $reportScriptPath @emailParams
#>
