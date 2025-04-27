# MissingPermissionModel-Example.ps1
# Exemple d'utilisation de la structure de données pour les permissions manquantes

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\RoadmapParser.psm1"
Import-Module $modulePath -Force

# Charger directement le fichier de modèle de permissions manquantes pour l'exemple
$missingPermissionModelPath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\Functions\Private\SqlPermissionModels\MissingPermissionModel.ps1"
. $missingPermissionModelPath

# Créer un ensemble de permissions manquantes
$missingPermissions = New-SqlMissingPermissionsSet -ServerInstance "SQLSERVER01" -ModelName "ProductionSecurityModel"

# Ajouter des permissions manquantes au niveau serveur
$serverPerm1 = New-SqlServerMissingPermission -PermissionName "CONNECT SQL" -LoginName "AppUser" -Severity "Moyenne"
$serverPerm1.Impact = "L'application ne peut pas se connecter au serveur SQL"
$serverPerm1.RecommendedAction = "Accorder la permission CONNECT SQL à l'utilisateur AppUser"
$missingPermissions.AddServerPermission($serverPerm1)

$serverPerm2 = New-SqlServerMissingPermission -PermissionName "VIEW SERVER STATE" -LoginName "MonitoringUser" -Severity "Élevée"
$serverPerm2.Impact = "Les outils de surveillance ne peuvent pas collecter les métriques de performance"
$serverPerm2.RecommendedAction = "Accorder la permission VIEW SERVER STATE à l'utilisateur MonitoringUser"
$missingPermissions.AddServerPermission($serverPerm2)

# Ajouter des permissions manquantes au niveau base de données
$dbPerm1 = New-SqlDatabaseMissingPermission -PermissionName "CONNECT" -DatabaseName "AppDB" -UserName "AppUser" -Severity "Critique"
$dbPerm1.Impact = "L'application ne peut pas accéder à la base de données AppDB"
$dbPerm1.RecommendedAction = "Accorder la permission CONNECT sur la base de données AppDB à l'utilisateur AppUser"
$missingPermissions.AddDatabasePermission($dbPerm1)

$dbPerm2 = New-SqlDatabaseMissingPermission -PermissionName "CREATE TABLE" -DatabaseName "DevDB" -UserName "Developer" -SecurableType "SCHEMA" -SecurableName "dbo" -Severity "Faible"
$dbPerm2.Impact = "Les développeurs ne peuvent pas créer de tables dans le schéma dbo"
$dbPerm2.RecommendedAction = "Accorder la permission CREATE TABLE sur le schéma dbo à l'utilisateur Developer"
$missingPermissions.AddDatabasePermission($dbPerm2)

# Ajouter des permissions manquantes au niveau objet
$objPerm1 = New-SqlObjectMissingPermission -PermissionName "SELECT" -DatabaseName "AppDB" -UserName "ReportUser" -ObjectType "TABLE" -SchemaName "dbo" -ObjectName "Customers" -Severity "Élevée"
$objPerm1.Impact = "Les rapports clients ne peuvent pas être générés"
$objPerm1.RecommendedAction = "Accorder la permission SELECT sur la table Customers à l'utilisateur ReportUser"
$missingPermissions.AddObjectPermission($objPerm1)

$objPerm2 = New-SqlObjectMissingPermission -PermissionName "EXECUTE" -DatabaseName "AppDB" -UserName "AppUser" -ObjectType "PROCEDURE" -SchemaName "dbo" -ObjectName "GetCustomerData" -Severity "Critique"
$objPerm2.Impact = "L'application ne peut pas exécuter la procédure stockée GetCustomerData"
$objPerm2.RecommendedAction = "Accorder la permission EXECUTE sur la procédure GetCustomerData à l'utilisateur AppUser"
$missingPermissions.AddObjectPermission($objPerm2)

$objPerm3 = New-SqlObjectMissingPermission -PermissionName "SELECT" -DatabaseName "AppDB" -UserName "LimitedUser" -ObjectType "TABLE" -SchemaName "dbo" -ObjectName "Customers" -ColumnName "Email" -Severity "Moyenne"
$objPerm3.Impact = "L'utilisateur LimitedUser ne peut pas accéder aux emails des clients"
$objPerm3.RecommendedAction = "Accorder la permission SELECT sur la colonne Email de la table Customers à l'utilisateur LimitedUser"
$missingPermissions.AddObjectPermission($objPerm3)

# Afficher le résumé des permissions manquantes
Write-Host "Résumé des permissions manquantes:" -ForegroundColor Cyan
Write-Host $missingPermissions.GetSummary() -ForegroundColor White

# Filtrer les permissions par sévérité
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

# Générer un script SQL pour corriger les permissions manquantes
$fixScript = $missingPermissions.GenerateFixScript()
Write-Host "`nScript de correction des permissions manquantes:" -ForegroundColor Green
Write-Host $fixScript -ForegroundColor White

# Exporter le script de correction dans un fichier
$scriptPath = Join-Path -Path $env:TEMP -ChildPath "FixMissingPermissions.sql"
$fixScript | Out-File -FilePath $scriptPath -Encoding UTF8
Write-Host "`nLe script de correction a été exporté dans: $scriptPath" -ForegroundColor Yellow

# Exemple d'utilisation dans un scénario de comparaison
Write-Host "`nExemple de scénario de comparaison:" -ForegroundColor Cyan
Write-Host "1. Capturer les permissions actuelles de l'instance SQL Server"
Write-Host "2. Comparer avec le modèle de référence 'ProductionSecurityModel'"
Write-Host "3. Identifier les permissions manquantes (comme illustré ci-dessus)"
Write-Host "4. Générer un rapport de conformité"
Write-Host "5. Appliquer les corrections si nécessaire"

# Exemple de rapport de conformité basé sur les permissions manquantes
$totalPermissions = 100  # Nombre total de permissions dans le modèle (exemple)
$missingCount = $missingPermissions.TotalCount
$complianceScore = [math]::Round(100 - ($missingCount / $totalPermissions * 100), 2)

Write-Host "`nRapport de conformité:" -ForegroundColor Cyan
Write-Host "Score de conformité: $complianceScore%" -ForegroundColor $(if ($complianceScore -ge 90) { "Green" } elseif ($complianceScore -ge 70) { "Yellow" } else { "Red" })
Write-Host "Permissions conformes: $($totalPermissions - $missingCount)/$totalPermissions" -ForegroundColor White
Write-Host "Permissions manquantes: $missingCount/$totalPermissions" -ForegroundColor White
Write-Host "Répartition par sévérité:"
Write-Host "- Critique: $($missingPermissions.SeverityCounts['Critique'])" -ForegroundColor Red
Write-Host "- Élevée: $($missingPermissions.SeverityCounts['Élevée'])" -ForegroundColor DarkRed
Write-Host "- Moyenne: $($missingPermissions.SeverityCounts['Moyenne'])" -ForegroundColor Yellow
Write-Host "- Faible: $($missingPermissions.SeverityCounts['Faible'])" -ForegroundColor Green
