# Schedule-WeeklyComplianceReport.ps1
# Exemple d'utilisation du script de planification du rapport de conformité

# Chemin du script de planification
$scheduleScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\Schedule-SqlPermissionComplianceReport.ps1"

# Paramètres de planification
$params = @{
    ServerInstance = "localhost\SQLEXPRESS"  # Remplacer par votre instance SQL Server
    OutputFolder = "C:\Reports\SqlPermissionCompliance"
    Frequency = "Weekly"
    DayOfWeek = 1  # Lundi
    Time = "03:00"
    TaskName = "SqlPermissionComplianceReport_Weekly"
    TaskDescription = "Génère un rapport hebdomadaire de conformité des permissions SQL Server"
    Verbose = $true
    WhatIf = $true  # Simuler l'exécution sans créer la tâche
}

# Planifier le rapport
& $scheduleScriptPath @params

# Exemple avec envoi d'email (décommenter et modifier les paramètres pour utiliser)
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
    TaskDescription = "Génère et envoie par email un rapport hebdomadaire de conformité des permissions SQL Server"
    Verbose = $true
    WhatIf = $true  # Simuler l'exécution sans créer la tâche
}

& $scheduleScriptPath @emailParams
#>

# Pour créer réellement la tâche, supprimez le paramètre WhatIf
