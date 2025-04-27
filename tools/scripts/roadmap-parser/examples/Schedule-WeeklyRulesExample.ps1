# Schedule-WeeklyRulesExample.ps1
# Exemple d'utilisation du script de planification de l'exécution des règles de détection d'anomalies SQL Server

# Chemin du script de planification
$scheduleScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\Schedule-SqlPermissionRules.ps1"

# Paramètres de planification
$params = @{
    ServerInstance = "localhost\SQLEXPRESS"  # Remplacer par votre instance SQL Server
    OutputFolder = "C:\Reports\SqlPermissionAnomalies"
    Frequency = "Weekly"
    DayOfWeek = 1  # Lundi
    Time = "03:00"
    TaskName = "SqlPermissionRules_Weekly"
    TaskDescription = "Exécute toutes les règles de détection d'anomalies SQL Server chaque semaine"
    Verbose = $true
    WhatIf = $true  # Simuler l'exécution sans créer la tâche
}

# Planifier l'exécution des règles
& $scheduleScriptPath @params

# Exemple avec envoi d'email (décommenter et modifier les paramètres pour utiliser)
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
    TaskDescription = "Exécute toutes les règles de détection d'anomalies SQL Server chaque semaine et envoie un rapport par email"
    Verbose = $true
    WhatIf = $true  # Simuler l'exécution sans créer la tâche
}

& $scheduleScriptPath @emailParams
#>

# Pour créer réellement la tâche, supprimez le paramètre WhatIf
