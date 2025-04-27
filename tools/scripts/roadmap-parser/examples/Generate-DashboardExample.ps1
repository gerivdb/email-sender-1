# Generate-DashboardExample.ps1
# Exemple d'utilisation du script de gÃ©nÃ©ration du tableau de bord des anomalies SQL Server

# Chemin du script de gÃ©nÃ©ration du tableau de bord
$dashboardScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\Generate-SqlPermissionDashboard.ps1"

# ParamÃ¨tres de gÃ©nÃ©ration du tableau de bord
$params = @{
    ServerInstance = "localhost\SQLEXPRESS"  # Remplacer par votre instance SQL Server
    ReportsFolder = "C:\Reports\SqlPermissionAnomalies"
    DashboardPath = "C:\Reports\SqlPermissionDashboard.html"
    HistoryDays = 30
    Verbose = $true
}

# GÃ©nÃ©rer le tableau de bord
& $dashboardScriptPath @params

# Ouvrir le tableau de bord dans le navigateur par dÃ©faut
Start-Process $params.DashboardPath
