# Schedule-WeeklyComplianceReport.ps1
# Exemple d'utilisation du script de planification du rapport de conformitÃƒÂ©

# Chemin du script de planification
$scheduleScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\development\scripts\Schedule-SqlPermissionComplianceReport.ps1"

# ParamÃƒÂ¨tres de planification
$params = @{
    ServerInstance = "localhost\SQLEXPRESS"  # Remplacer par votre instance SQL Server
    OutputFolder = "C:\Reports\SqlPermissionCompliance"
    Frequency = "Weekly"
    DayOfWeek = 1  # Lundi
    Time = "03:00"
    TaskName = "SqlPermissionComplianceReport_Weekly"
    TaskDescription = "GÃƒÂ©nÃƒÂ¨re un rapport hebdomadaire de conformitÃƒÂ© des permissions SQL Server"
    Verbose = $true
    WhatIf = $true  # Simuler l'exÃƒÂ©cution sans crÃƒÂ©er la tÃƒÂ¢che
}

# Planifier le rapport
& $scheduleScriptPath @params

# Exemple avec envoi d'email (dÃƒÂ©commenter et modifier les paramÃƒÂ¨tres pour utiliser)
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
    TaskDescription = "GÃƒÂ©nÃƒÂ¨re et envoie par email un rapport hebdomadaire de conformitÃƒÂ© des permissions SQL Server"
    Verbose = $true
    WhatIf = $true  # Simuler l'exÃƒÂ©cution sans crÃƒÂ©er la tÃƒÂ¢che
}

& $scheduleScriptPath @emailParams
#>

# Pour crÃƒÂ©er rÃƒÂ©ellement la tÃƒÂ¢che, supprimez le paramÃƒÂ¨tre WhatIf
