# ExcessPermissionModel-Example.ps1
# Exemple d'utilisation de la structure de donnÃ©es pour les permissions excÃ©dentaires

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\RoadmapParser.psm1"
Import-Module $modulePath -Force

# Charger directement le fichier de modÃ¨le de permissions excÃ©dentaires pour l'exemple
$excessPermissionModelPath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\Functions\Private\SqlPermissionModels\ExcessPermissionModel.ps1"
. $excessPermissionModelPath

# CrÃ©er un ensemble de permissions excÃ©dentaires
$excessPermissions = New-SqlExcessPermissionsSet -ServerInstance "SQLSERVER01" -ModelName "ProductionSecurityModel"

# Ajouter des permissions excÃ©dentaires au niveau serveur
$serverPerm1 = New-SqlServerExcessPermission -PermissionName "CONTROL SERVER" -LoginName "AppUser" -RiskLevel "Critique"
$serverPerm1.Impact = "L'application dispose d'un contrÃ´le complet sur le serveur SQL, ce qui reprÃ©sente un risque de sÃ©curitÃ© majeur"
$serverPerm1.RecommendedAction = "RÃ©voquer la permission CONTROL SERVER pour l'utilisateur AppUser et accorder uniquement les permissions nÃ©cessaires"
$excessPermissions.AddServerPermission($serverPerm1)

$serverPerm2 = New-SqlServerExcessPermission -PermissionName "ALTER ANY LOGIN" -LoginName "MonitoringUser" -RiskLevel "Ã‰levÃ©"
$serverPerm2.Impact = "L'utilisateur de surveillance peut modifier les logins, ce qui dÃ©passe ses besoins fonctionnels"
$serverPerm2.RecommendedAction = "RÃ©voquer la permission ALTER ANY LOGIN pour l'utilisateur MonitoringUser"
$excessPermissions.AddServerPermission($serverPerm2)

# Ajouter des permissions excÃ©dentaires au niveau base de donnÃ©es
$dbPerm1 = New-SqlDatabaseExcessPermission -PermissionName "CONTROL" -DatabaseName "AppDB" -UserName "AppUser" -RiskLevel "Ã‰levÃ©"
$dbPerm1.Impact = "L'application dispose d'un contrÃ´le complet sur la base de donnÃ©es, ce qui dÃ©passe ses besoins fonctionnels"
$dbPerm1.RecommendedAction = "RÃ©voquer la permission CONTROL sur la base de donnÃ©es AppDB pour l'utilisateur AppUser et accorder uniquement les permissions nÃ©cessaires"
$excessPermissions.AddDatabasePermission($dbPerm1)

$dbPerm2 = New-SqlDatabaseExcessPermission -PermissionName "ALTER" -DatabaseName "DevDB" -UserName "ReportUser" -RiskLevel "Moyen"
$dbPerm2.Impact = "L'utilisateur de rapports peut modifier la structure de la base de donnÃ©es, ce qui dÃ©passe ses besoins fonctionnels"
$dbPerm2.RecommendedAction = "RÃ©voquer la permission ALTER sur la base de donnÃ©es DevDB pour l'utilisateur ReportUser"
$excessPermissions.AddDatabasePermission($dbPerm2)

# Ajouter des permissions excÃ©dentaires au niveau objet
$objPerm1 = New-SqlObjectExcessPermission -PermissionName "DELETE" -DatabaseName "AppDB" -UserName "ReportUser" -ObjectType "TABLE" -SchemaName "dbo" -ObjectName "Customers" -RiskLevel "Ã‰levÃ©"
$objPerm1.Impact = "L'utilisateur de rapports peut supprimer des donnÃ©es clients, ce qui dÃ©passe ses besoins fonctionnels"
$objPerm1.RecommendedAction = "RÃ©voquer la permission DELETE sur la table Customers pour l'utilisateur ReportUser"
$excessPermissions.AddObjectPermission($objPerm1)

$objPerm2 = New-SqlObjectExcessPermission -PermissionName "UPDATE" -DatabaseName "AppDB" -UserName "ReadOnlyUser" -ObjectType "TABLE" -SchemaName "dbo" -ObjectName "Orders" -RiskLevel "Critique"
$objPerm2.Impact = "L'utilisateur en lecture seule peut modifier les commandes, ce qui est contraire Ã  son rÃ´le"
$objPerm2.RecommendedAction = "RÃ©voquer la permission UPDATE sur la table Orders pour l'utilisateur ReadOnlyUser"
$excessPermissions.AddObjectPermission($objPerm2)

$objPerm3 = New-SqlObjectExcessPermission -PermissionName "UPDATE" -DatabaseName "AppDB" -UserName "LimitedUser" -ObjectType "TABLE" -SchemaName "dbo" -ObjectName "Customers" -ColumnName "CreditCardNumber" -RiskLevel "Critique"
$objPerm3.Impact = "L'utilisateur limitÃ© peut modifier les numÃ©ros de carte de crÃ©dit des clients, ce qui reprÃ©sente un risque de sÃ©curitÃ© majeur"
$objPerm3.RecommendedAction = "RÃ©voquer la permission UPDATE sur la colonne CreditCardNumber de la table Customers pour l'utilisateur LimitedUser"
$excessPermissions.AddObjectPermission($objPerm3)

# Afficher le rÃ©sumÃ© des permissions excÃ©dentaires
Write-Host "RÃ©sumÃ© des permissions excÃ©dentaires:" -ForegroundColor Cyan
Write-Host $excessPermissions.GetSummary() -ForegroundColor White

# Filtrer les permissions par niveau de risque
$criticalPermissions = $excessPermissions.FilterByRiskLevel("Critique")
Write-Host "`nPermissions excÃ©dentaires critiques:" -ForegroundColor Red
foreach ($perm in $criticalPermissions.ServerPermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor Red
}
foreach ($perm in $criticalPermissions.DatabasePermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor Red
}
foreach ($perm in $criticalPermissions.ObjectPermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor Red
}

# GÃ©nÃ©rer un script SQL pour corriger les permissions excÃ©dentaires
$fixScript = $excessPermissions.GenerateFixScript()
Write-Host "`nScript de correction des permissions excÃ©dentaires:" -ForegroundColor Green
Write-Host $fixScript -ForegroundColor White

# Exporter le script de correction dans un fichier
$scriptPath = Join-Path -Path $env:TEMP -ChildPath "FixExcessPermissions.sql"
$fixScript | Out-File -FilePath $scriptPath -Encoding UTF8
Write-Host "`nLe script de correction a Ã©tÃ© exportÃ© dans: $scriptPath" -ForegroundColor Yellow

# Exemple d'utilisation dans un scÃ©nario de comparaison
Write-Host "`nExemple de scÃ©nario de comparaison:" -ForegroundColor Cyan
Write-Host "1. Capturer les permissions actuelles de l'instance SQL Server"
Write-Host "2. Comparer avec le modÃ¨le de rÃ©fÃ©rence 'ProductionSecurityModel'"
Write-Host "3. Identifier les permissions excÃ©dentaires (comme illustrÃ© ci-dessus)"
Write-Host "4. GÃ©nÃ©rer un rapport de conformitÃ©"
Write-Host "5. Appliquer les corrections si nÃ©cessaire"

# Exemple de rapport de conformitÃ© basÃ© sur les permissions excÃ©dentaires
$totalPermissions = 100  # Nombre total de permissions dans le modÃ¨le (exemple)
$excessCount = $excessPermissions.TotalCount
$complianceScore = [math]::Round(100 - ($excessCount / $totalPermissions * 100), 2)

Write-Host "`nRapport de conformitÃ©:" -ForegroundColor Cyan
Write-Host "Score de conformitÃ©: $complianceScore%" -ForegroundColor $(if ($complianceScore -ge 90) { "Green" } elseif ($complianceScore -ge 70) { "Yellow" } else { "Red" })
Write-Host "Permissions conformes: $($totalPermissions - $excessCount)/$totalPermissions" -ForegroundColor White
Write-Host "Permissions excÃ©dentaires: $excessCount/$totalPermissions" -ForegroundColor White
Write-Host "RÃ©partition par niveau de risque:"
Write-Host "- Critique: $($excessPermissions.RiskLevelCounts['Critique'])" -ForegroundColor Red
Write-Host "- Ã‰levÃ©: $($excessPermissions.RiskLevelCounts['Ã‰levÃ©'])" -ForegroundColor DarkRed
Write-Host "- Moyen: $($excessPermissions.RiskLevelCounts['Moyen'])" -ForegroundColor Yellow
Write-Host "- Faible: $($excessPermissions.RiskLevelCounts['Faible'])" -ForegroundColor Green
