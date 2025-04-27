# Analyze-SqlPermissionsWithRules.ps1
# Exemple d'utilisation du système de règles pour l'analyse des permissions SQL Server

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\module" -Resolve
Import-Module $modulePath -Force

# Paramètres de connexion SQL Server
$params = @{
    ServerInstance = "localhost\SQLEXPRESS"  # Remplacer par votre instance SQL Server
    Database = "master"                      # Base de données initiale
    Credential = $null                       # Utiliser l'authentification Windows par défaut
}

# Exemple 1: Analyser toutes les permissions avec toutes les règles
Write-Host "Exemple 1: Analyser toutes les permissions avec toutes les règles" -ForegroundColor Cyan
$result1 = Analyze-SqlServerPermission @params -IncludeObjectLevel -OutputFormat "JSON"
Write-Host "Nombre total d'anomalies détectées: $($result1.TotalAnomalies)" -ForegroundColor Yellow
Write-Host ""

# Exemple 2: Analyser uniquement avec les règles de sévérité élevée
Write-Host "Exemple 2: Analyser uniquement avec les règles de sévérité élevée" -ForegroundColor Cyan
$result2 = Analyze-SqlServerPermission @params -IncludeObjectLevel -OutputFormat "JSON" -Severity "Élevée"
Write-Host "Nombre d'anomalies de sévérité élevée: $($result2.TotalAnomalies)" -ForegroundColor Yellow
Write-Host ""

# Exemple 3: Analyser avec des règles spécifiques
Write-Host "Exemple 3: Analyser avec des règles spécifiques" -ForegroundColor Cyan
$specificRules = @("SVR-001", "DB-001", "OBJ-002")
$result3 = Analyze-SqlServerPermission @params -IncludeObjectLevel -OutputFormat "JSON" -RuleIds $specificRules
Write-Host "Nombre d'anomalies pour les règles spécifiques: $($result3.TotalAnomalies)" -ForegroundColor Yellow
Write-Host ""

# Exemple 4: Générer un rapport HTML
Write-Host "Exemple 4: Générer un rapport HTML" -ForegroundColor Cyan
$outputPath = Join-Path -Path $PSScriptRoot -ChildPath "SqlPermissionReport.html"
$result4 = Analyze-SqlServerPermission @params -IncludeObjectLevel -OutputFormat "HTML" -OutputPath $outputPath
Write-Host "Rapport HTML généré: $outputPath" -ForegroundColor Green
Write-Host "Nombre total d'anomalies dans le rapport: $($result4.TotalAnomalies)" -ForegroundColor Yellow
Write-Host ""

# Exemple 5: Afficher les règles disponibles
Write-Host "Exemple 5: Afficher les règles disponibles" -ForegroundColor Cyan
Write-Host "Règles au niveau serveur:" -ForegroundColor Green
$serverRules = Get-SqlPermissionRules -RuleType "Server"
$serverRules | Format-Table -Property RuleId, Name, Severity -AutoSize

Write-Host "Règles au niveau base de données:" -ForegroundColor Green
$dbRules = Get-SqlPermissionRules -RuleType "Database"
$dbRules | Format-Table -Property RuleId, Name, Severity -AutoSize

Write-Host "Règles au niveau objet:" -ForegroundColor Green
$objRules = Get-SqlPermissionRules -RuleType "Object"
$objRules | Format-Table -Property RuleId, Name, Severity -AutoSize
