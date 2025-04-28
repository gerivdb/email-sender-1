# Schedule-WeeklyRulesExample.ps1
# Exemple d'utilisation du script de planification de l'exÃ©cution des rÃ¨gles de dÃ©tection d'anomalies SQL Server

# Chemin du script de planification
$scheduleScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\development\scripts\Schedule-SqlPermissionRules.ps1"

# ParamÃ¨tres de planification
$params = @{
    ServerInstance = "localhost\SQLEXPRESS"  # Remplacer par votre instance SQL Server
    OutputFolder = "C:\Reports\SqlPermissionAnomalies"
    Frequency = "Weekly"
    DayOfWeek = 1  # Lundi
    Time = "03:00"
    TaskName = "SqlPermissionRules_Weekly"
    TaskDescription = "ExÃ©cute toutes les rÃ¨gles de dÃ©tection d'anomalies SQL Server chaque semaine"
    Verbose = $true
    WhatIf = $true  # Simuler l'exÃ©cution sans crÃ©er la tÃ¢che
}

# Planifier l'exÃ©cution des rÃ¨gles
& $scheduleScriptPath @params

# Exemple avec envoi d'email (dÃ©commenter et modifier les paramÃ¨tres pour utiliser)
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
    TaskDescription = "ExÃ©cute toutes les rÃ¨gles de dÃ©tection d'anomalies SQL Server chaque semaine et envoie un rapport par email"
    Verbose = $true
    WhatIf = $true  # Simuler l'exÃ©cution sans crÃ©er la tÃ¢che
}

& $scheduleScriptPath @emailParams
#>

# Pour crÃ©er rÃ©ellement la tÃ¢che, supprimez le paramÃ¨tre WhatIf
