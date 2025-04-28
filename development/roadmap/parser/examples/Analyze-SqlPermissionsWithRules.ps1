# Analyze-SqlPermissionsWithRules.ps1
# Exemple d'utilisation du systÃ¨me de rÃ¨gles pour l'analyse des permissions SQL Server

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\module" -Resolve
Import-Module $modulePath -Force

# ParamÃ¨tres de connexion SQL Server
$params = @{
    ServerInstance = "localhost\SQLEXPRESS"  # Remplacer par votre instance SQL Server
    Database = "master"                      # Base de donnÃ©es initiale
    Credential = $null                       # Utiliser l'authentification Windows par dÃ©faut
}

# Exemple 1: Analyser toutes les permissions avec toutes les rÃ¨gles
Write-Host "Exemple 1: Analyser toutes les permissions avec toutes les rÃ¨gles" -ForegroundColor Cyan
$result1 = Analyze-SqlServerPermission @params -IncludeObjectLevel -OutputFormat "JSON"
Write-Host "Nombre total d'anomalies dÃ©tectÃ©es: $($result1.TotalAnomalies)" -ForegroundColor Yellow
Write-Host ""

# Exemple 2: Analyser uniquement avec les rÃ¨gles de sÃ©vÃ©ritÃ© Ã©levÃ©e
Write-Host "Exemple 2: Analyser uniquement avec les rÃ¨gles de sÃ©vÃ©ritÃ© Ã©levÃ©e" -ForegroundColor Cyan
$result2 = Analyze-SqlServerPermission @params -IncludeObjectLevel -OutputFormat "JSON" -Severity "Ã‰levÃ©e"
Write-Host "Nombre d'anomalies de sÃ©vÃ©ritÃ© Ã©levÃ©e: $($result2.TotalAnomalies)" -ForegroundColor Yellow
Write-Host ""

# Exemple 3: Analyser avec des rÃ¨gles spÃ©cifiques
Write-Host "Exemple 3: Analyser avec des rÃ¨gles spÃ©cifiques" -ForegroundColor Cyan
$specificRules = @("SVR-001", "DB-001", "OBJ-002")
$result3 = Analyze-SqlServerPermission @params -IncludeObjectLevel -OutputFormat "JSON" -RuleIds $specificRules
Write-Host "Nombre d'anomalies pour les rÃ¨gles spÃ©cifiques: $($result3.TotalAnomalies)" -ForegroundColor Yellow
Write-Host ""

# Exemple 4: GÃ©nÃ©rer un rapport HTML
Write-Host "Exemple 4: GÃ©nÃ©rer un rapport HTML" -ForegroundColor Cyan
$outputPath = Join-Path -Path $PSScriptRoot -ChildPath "SqlPermissionReport.html"
$result4 = Analyze-SqlServerPermission @params -IncludeObjectLevel -OutputFormat "HTML" -OutputPath $outputPath
Write-Host "Rapport HTML gÃ©nÃ©rÃ©: $outputPath" -ForegroundColor Green
Write-Host "Nombre total d'anomalies dans le rapport: $($result4.TotalAnomalies)" -ForegroundColor Yellow
Write-Host ""

# Exemple 5: Afficher les rÃ¨gles disponibles
Write-Host "Exemple 5: Afficher les rÃ¨gles disponibles" -ForegroundColor Cyan
Write-Host "RÃ¨gles au niveau serveur:" -ForegroundColor Green
$serverRules = Get-SqlPermissionRules -RuleType "Server"
$serverRules | Format-Table -Property RuleId, Name, Severity -AutoSize

Write-Host "RÃ¨gles au niveau base de donnÃ©es:" -ForegroundColor Green
$dbRules = Get-SqlPermissionRules -RuleType "Database"
$dbRules | Format-Table -Property RuleId, Name, Severity -AutoSize

Write-Host "RÃ¨gles au niveau objet:" -ForegroundColor Green
$objRules = Get-SqlPermissionRules -RuleType "Object"
$objRules | Format-Table -Property RuleId, Name, Severity -AutoSize
