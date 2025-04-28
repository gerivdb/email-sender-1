# MissingPermissionModel-Example.ps1
# Exemple d'utilisation de la structure de donnÃ©es pour les permissions manquantes

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\RoadmapParser.psm1"
Import-Module $modulePath -Force

# Charger directement le fichier de modÃ¨le de permissions manquantes pour l'exemple
$missingPermissionModelPath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\Functions\Private\SqlPermissionModels\MissingPermissionModel.ps1"
. $missingPermissionModelPath

# CrÃ©er un ensemble de permissions manquantes
$missingPermissions = New-SqlMissingPermissionsSet -ServerInstance "SQLSERVER01" -ModelName "ProductionSecurityModel"

# Ajouter des permissions manquantes au niveau serveur
$serverPerm1 = New-SqlServerMissingPermission -PermissionName "CONNECT SQL" -LoginName "AppUser" -Severity "Moyenne"
$serverPerm1.Impact = "L'application ne peut pas se connecter au serveur SQL"
$serverPerm1.RecommendedAction = "Accorder la permission CONNECT SQL Ã  l'utilisateur AppUser"
$missingPermissions.AddServerPermission($serverPerm1)

$serverPerm2 = New-SqlServerMissingPermission -PermissionName "VIEW SERVER STATE" -LoginName "MonitoringUser" -Severity "Ã‰levÃ©e"
$serverPerm2.Impact = "Les outils de surveillance ne peuvent pas collecter les mÃ©triques de performance"
$serverPerm2.RecommendedAction = "Accorder la permission VIEW SERVER STATE Ã  l'utilisateur MonitoringUser"
$missingPermissions.AddServerPermission($serverPerm2)

# Ajouter des permissions manquantes au niveau base de donnÃ©es
$dbPerm1 = New-SqlDatabaseMissingPermission -PermissionName "CONNECT" -DatabaseName "AppDB" -UserName "AppUser" -Severity "Critique"
$dbPerm1.Impact = "L'application ne peut pas accÃ©der Ã  la base de donnÃ©es AppDB"
$dbPerm1.RecommendedAction = "Accorder la permission CONNECT sur la base de donnÃ©es AppDB Ã  l'utilisateur AppUser"
$missingPermissions.AddDatabasePermission($dbPerm1)

$dbPerm2 = New-SqlDatabaseMissingPermission -PermissionName "CREATE TABLE" -DatabaseName "DevDB" -UserName "Developer" -SecurableType "SCHEMA" -SecurableName "dbo" -Severity "Faible"
$dbPerm2.Impact = "Les dÃ©veloppeurs ne peuvent pas crÃ©er de tables dans le schÃ©ma dbo"
$dbPerm2.RecommendedAction = "Accorder la permission CREATE TABLE sur le schÃ©ma dbo Ã  l'utilisateur Developer"
$missingPermissions.AddDatabasePermission($dbPerm2)

# Ajouter des permissions manquantes au niveau objet
$objPerm1 = New-SqlObjectMissingPermission -PermissionName "SELECT" -DatabaseName "AppDB" -UserName "ReportUser" -ObjectType "TABLE" -SchemaName "dbo" -ObjectName "Customers" -Severity "Ã‰levÃ©e"
$objPerm1.Impact = "Les rapports clients ne peuvent pas Ãªtre gÃ©nÃ©rÃ©s"
$objPerm1.RecommendedAction = "Accorder la permission SELECT sur la table Customers Ã  l'utilisateur ReportUser"
$missingPermissions.AddObjectPermission($objPerm1)

$objPerm2 = New-SqlObjectMissingPermission -PermissionName "EXECUTE" -DatabaseName "AppDB" -UserName "AppUser" -ObjectType "PROCEDURE" -SchemaName "dbo" -ObjectName "GetCustomerData" -Severity "Critique"
$objPerm2.Impact = "L'application ne peut pas exÃ©cuter la procÃ©dure stockÃ©e GetCustomerData"
$objPerm2.RecommendedAction = "Accorder la permission EXECUTE sur la procÃ©dure GetCustomerData Ã  l'utilisateur AppUser"
$missingPermissions.AddObjectPermission($objPerm2)

$objPerm3 = New-SqlObjectMissingPermission -PermissionName "SELECT" -DatabaseName "AppDB" -UserName "LimitedUser" -ObjectType "TABLE" -SchemaName "dbo" -ObjectName "Customers" -ColumnName "Email" -Severity "Moyenne"
$objPerm3.Impact = "L'utilisateur LimitedUser ne peut pas accÃ©der aux emails des clients"
$objPerm3.RecommendedAction = "Accorder la permission SELECT sur la colonne Email de la table Customers Ã  l'utilisateur LimitedUser"
$missingPermissions.AddObjectPermission($objPerm3)

# Afficher le rÃ©sumÃ© des permissions manquantes
Write-Host "RÃ©sumÃ© des permissions manquantes:" -ForegroundColor Cyan
Write-Host $missingPermissions.GetSummary() -ForegroundColor White

# Filtrer les permissions par sÃ©vÃ©ritÃ©
$criticalPermissions = $missingPermissions.FilterBySeverity("Critique")
Write-Host "`nPermissions manquantes critiques:" -ForegroundColor Red
foreach ($perm in $criticalPermissions.ServerPermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor Red
}
foreach ($perm in $criticalPermissions.DatabasePermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor Red
}
foreach ($perm in $criticalPermissions.ObjectPermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor Red
}

# GÃ©nÃ©rer un script SQL pour corriger les permissions manquantes
$fixScript = $missingPermissions.GenerateFixScript()
Write-Host "`nScript de correction des permissions manquantes:" -ForegroundColor Green
Write-Host $fixScript -ForegroundColor White

# Exporter le script de correction dans un fichier
$scriptPath = Join-Path -Path $env:TEMP -ChildPath "FixMissingPermissions.sql"
$fixScript | Out-File -FilePath $scriptPath -Encoding UTF8
Write-Host "`nLe script de correction a Ã©tÃ© exportÃ© dans: $scriptPath" -ForegroundColor Yellow

# Exemple d'utilisation dans un scÃ©nario de comparaison
Write-Host "`nExemple de scÃ©nario de comparaison:" -ForegroundColor Cyan
Write-Host "1. Capturer les permissions actuelles de l'instance SQL Server"
Write-Host "2. Comparer avec le modÃ¨le de rÃ©fÃ©rence 'ProductionSecurityModel'"
Write-Host "3. Identifier les permissions manquantes (comme illustrÃ© ci-dessus)"
Write-Host "4. GÃ©nÃ©rer un rapport de conformitÃ©"
Write-Host "5. Appliquer les corrections si nÃ©cessaire"

# Exemple de rapport de conformitÃ© basÃ© sur les permissions manquantes
$totalPermissions = 100  # Nombre total de permissions dans le modÃ¨le (exemple)
$missingCount = $missingPermissions.TotalCount
$complianceScore = [math]::Round(100 - ($missingCount / $totalPermissions * 100), 2)

Write-Host "`nRapport de conformitÃ©:" -ForegroundColor Cyan
Write-Host "Score de conformitÃ©: $complianceScore%" -ForegroundColor $(if ($complianceScore -ge 90) { "Green" } elseif ($complianceScore -ge 70) { "Yellow" } else { "Red" })
Write-Host "Permissions conformes: $($totalPermissions - $missingCount)/$totalPermissions" -ForegroundColor White
Write-Host "Permissions manquantes: $missingCount/$totalPermissions" -ForegroundColor White
Write-Host "RÃ©partition par sÃ©vÃ©ritÃ©:"
Write-Host "- Critique: $($missingPermissions.SeverityCounts['Critique'])" -ForegroundColor Red
Write-Host "- Ã‰levÃ©e: $($missingPermissions.SeverityCounts['Ã‰levÃ©e'])" -ForegroundColor DarkRed
Write-Host "- Moyenne: $($missingPermissions.SeverityCounts['Moyenne'])" -ForegroundColor Yellow
Write-Host "- Faible: $($missingPermissions.SeverityCounts['Faible'])" -ForegroundColor Green
