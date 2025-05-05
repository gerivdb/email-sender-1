# Generate-DashboardExample.ps1
# Exemple d'utilisation du script de gÃƒÂ©nÃƒÂ©ration du tableau de bord des anomalies SQL Server

# Chemin du script de gÃƒÂ©nÃƒÂ©ration du tableau de bord
$dashboardScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\development\scripts\Generate-SqlPermissionDashboard.ps1"

# ParamÃƒÂ¨tres de gÃƒÂ©nÃƒÂ©ration du tableau de bord
$params = @{
    ServerInstance = "localhost\SQLEXPRESS"  # Remplacer par votre instance SQL Server
    ReportsFolder = "C:\Reports\SqlPermissionAnomalies"
    DashboardPath = "C:\Reports\SqlPermissionDashboard.html"
    HistoryDays = 30
    Verbose = $true
}

# GÃƒÂ©nÃƒÂ©rer le tableau de bord
& $dashboardScriptPath @params

# Ouvrir le tableau de bord dans le navigateur par dÃƒÂ©faut
Start-Process $params.DashboardPath
