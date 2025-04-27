# Generate-ComplianceReport.ps1
# Exemple d'utilisation du script de génération de rapport de conformité

# Chemin du script de génération de rapport
$reportScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\Generate-SqlPermissionComplianceReport.ps1"

# Paramètres du rapport
$params = @{
    ServerInstance = "localhost\SQLEXPRESS"  # Remplacer par votre instance SQL Server
    OutputPath = "C:\Temp\SqlPermissionComplianceReport.html"
    ExcludeDatabases = @("tempdb", "model", "msdb")
    IncludeObjectLevel = $true
    Verbose = $true
}

# Générer le rapport
& $reportScriptPath @params

# Exemple avec envoi d'email (décommenter et modifier les paramètres pour utiliser)
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
    Subject = "Rapport de conformité SQL Server - $(Get-Date -Format 'yyyy-MM-dd')"
    Verbose = $true
}

& $reportScriptPath @emailParams
#>
