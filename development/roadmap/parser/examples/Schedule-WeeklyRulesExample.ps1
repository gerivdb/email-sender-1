# Schedule-WeeklyRulesExample.ps1
# Exemple d'utilisation du script de planification de l'exÃƒÂ©cution des rÃƒÂ¨gles de dÃƒÂ©tection d'anomalies SQL Server

# Chemin du script de planification
$scheduleScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\development\scripts\Schedule-SqlPermissionRules.ps1"

# ParamÃƒÂ¨tres de planification
$params = @{
    ServerInstance = "localhost\SQLEXPRESS"  # Remplacer par votre instance SQL Server
    OutputFolder = "C:\Reports\SqlPermissionAnomalies"
    Frequency = "Weekly"
    DayOfWeek = 1  # Lundi
    Time = "03:00"
    TaskName = "SqlPermissionRules_Weekly"
    TaskDescription = "ExÃƒÂ©cute toutes les rÃƒÂ¨gles de dÃƒÂ©tection d'anomalies SQL Server chaque semaine"
    Verbose = $true
    WhatIf = $true  # Simuler l'exÃƒÂ©cution sans crÃƒÂ©er la tÃƒÂ¢che
}

# Planifier l'exÃƒÂ©cution des rÃƒÂ¨gles
& $scheduleScriptPath @params

# Exemple avec envoi d'email (dÃƒÂ©commenter et modifier les paramÃƒÂ¨tres pour utiliser)
<#
$emailParams = @{
    ServerInstance = "localhost\SQLEXPRESS"
    OutputFolder = "C:\Reports\SqlPermissionAnomalies"
    Frequency = "Weekly"
    DayOfWeek = 1  # Lundi
    Time = "03:00"
    SendEmail = $true
    SmtpServer = "smtp.example.com"
    FromAddress = "reports@example.com"
    ToAddress = @("admin@example.com", "security@example.com")
    TaskName = "SqlPermissionRules_Weekly_Email"
    TaskDescription = "ExÃƒÂ©cute toutes les rÃƒÂ¨gles de dÃƒÂ©tection d'anomalies SQL Server chaque semaine et envoie un rapport par email"
    Verbose = $true
    WhatIf = $true  # Simuler l'exÃƒÂ©cution sans crÃƒÂ©er la tÃƒÂ¢che
}

& $scheduleScriptPath @emailParams
#>

# Pour crÃƒÂ©er rÃƒÂ©ellement la tÃƒÂ¢che, supprimez le paramÃƒÂ¨tre WhatIf
