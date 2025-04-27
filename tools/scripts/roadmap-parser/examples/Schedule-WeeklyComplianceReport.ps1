# Schedule-WeeklyComplianceReport.ps1
# Exemple d'utilisation du script de planification du rapport de conformitÃ©

# Chemin du script de planification
$scheduleScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\Schedule-SqlPermissionComplianceReport.ps1"

# ParamÃ¨tres de planification
$params = @{
    ServerInstance = "localhost\SQLEXPRESS"  # Remplacer par votre instance SQL Server
    OutputFolder = "C:\Reports\SqlPermissionCompliance"
    Frequency = "Weekly"
    DayOfWeek = 1  # Lundi
    Time = "03:00"
    TaskName = "SqlPermissionComplianceReport_Weekly"
    TaskDescription = "GÃ©nÃ¨re un rapport hebdomadaire de conformitÃ© des permissions SQL Server"
    Verbose = $true
    WhatIf = $true  # Simuler l'exÃ©cution sans crÃ©er la tÃ¢che
}

# Planifier le rapport
& $scheduleScriptPath @params

# Exemple avec envoi d'email (dÃ©commenter et modifier les paramÃ¨tres pour utiliser)
<#
$emailParams = @{
    ServerInstance = "localhost\SQLEXPRESS"
    OutputFolder = "C:\Reports\SqlPermissionCompliance"
    Frequency = "Weekly"
    DayOfWeek = 1  # Lundi
    Time = "03:00"
    SendEmail = $true
    SmtpServer = "smtp.example.com"
    FromAddress = "reports@example.com"
    ToAddress = @("admin@example.com", "security@example.com")
    TaskName = "SqlPermissionComplianceReport_Weekly_Email"
    TaskDescription = "GÃ©nÃ¨re et envoie par email un rapport hebdomadaire de conformitÃ© des permissions SQL Server"
    Verbose = $true
    WhatIf = $true  # Simuler l'exÃ©cution sans crÃ©er la tÃ¢che
}

& $scheduleScriptPath @emailParams
#>

# Pour crÃ©er rÃ©ellement la tÃ¢che, supprimez le paramÃ¨tre WhatIf
