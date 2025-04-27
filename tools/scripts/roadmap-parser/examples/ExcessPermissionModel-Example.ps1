# ExcessPermissionModel-Example.ps1
# Exemple d'utilisation de la structure de données pour les permissions excédentaires

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\RoadmapParser.psm1"
Import-Module $modulePath -Force

# Charger directement le fichier de modèle de permissions excédentaires pour l'exemple
$excessPermissionModelPath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\Functions\Private\SqlPermissionModels\ExcessPermissionModel.ps1"
. $excessPermissionModelPath

# Créer un ensemble de permissions excédentaires
$excessPermissions = New-SqlExcessPermissionsSet -ServerInstance "SQLSERVER01" -ModelName "ProductionSecurityModel"

# Ajouter des permissions excédentaires au niveau serveur
$serverPerm1 = New-SqlServerExcessPermission -PermissionName "CONTROL SERVER" -LoginName "AppUser" -RiskLevel "Critique"
$serverPerm1.Impact = "L'application dispose d'un contrôle complet sur le serveur SQL, ce qui représente un risque de sécurité majeur"
$serverPerm1.RecommendedAction = "Révoquer la permission CONTROL SERVER pour l'utilisateur AppUser et accorder uniquement les permissions nécessaires"
$excessPermissions.AddServerPermission($serverPerm1)

$serverPerm2 = New-SqlServerExcessPermission -PermissionName "ALTER ANY LOGIN" -LoginName "MonitoringUser" -RiskLevel "Élevé"
$serverPerm2.Impact = "L'utilisateur de surveillance peut modifier les logins, ce qui dépasse ses besoins fonctionnels"
$serverPerm2.RecommendedAction = "Révoquer la permission ALTER ANY LOGIN pour l'utilisateur MonitoringUser"
$excessPermissions.AddServerPermission($serverPerm2)

# Ajouter des permissions excédentaires au niveau base de données
$dbPerm1 = New-SqlDatabaseExcessPermission -PermissionName "CONTROL" -DatabaseName "AppDB" -UserName "AppUser" -RiskLevel "Élevé"
$dbPerm1.Impact = "L'application dispose d'un contrôle complet sur la base de données, ce qui dépasse ses besoins fonctionnels"
$dbPerm1.RecommendedAction = "Révoquer la permission CONTROL sur la base de données AppDB pour l'utilisateur AppUser et accorder uniquement les permissions nécessaires"
$excessPermissions.AddDatabasePermission($dbPerm1)

$dbPerm2 = New-SqlDatabaseExcessPermission -PermissionName "ALTER" -DatabaseName "DevDB" -UserName "ReportUser" -RiskLevel "Moyen"
$dbPerm2.Impact = "L'utilisateur de rapports peut modifier la structure de la base de données, ce qui dépasse ses besoins fonctionnels"
$dbPerm2.RecommendedAction = "Révoquer la permission ALTER sur la base de données DevDB pour l'utilisateur ReportUser"
$excessPermissions.AddDatabasePermission($dbPerm2)

# Ajouter des permissions excédentaires au niveau objet
$objPerm1 = New-SqlObjectExcessPermission -PermissionName "DELETE" -DatabaseName "AppDB" -UserName "ReportUser" -ObjectType "TABLE" -SchemaName "dbo" -ObjectName "Customers" -RiskLevel "Élevé"
$objPerm1.Impact = "L'utilisateur de rapports peut supprimer des données clients, ce qui dépasse ses besoins fonctionnels"
$objPerm1.RecommendedAction = "Révoquer la permission DELETE sur la table Customers pour l'utilisateur ReportUser"
$excessPermissions.AddObjectPermission($objPerm1)

$objPerm2 = New-SqlObjectExcessPermission -PermissionName "UPDATE" -DatabaseName "AppDB" -UserName "ReadOnlyUser" -ObjectType "TABLE" -SchemaName "dbo" -ObjectName "Orders" -RiskLevel "Critique"
$objPerm2.Impact = "L'utilisateur en lecture seule peut modifier les commandes, ce qui est contraire à son rôle"
$objPerm2.RecommendedAction = "Révoquer la permission UPDATE sur la table Orders pour l'utilisateur ReadOnlyUser"
$excessPermissions.AddObjectPermission($objPerm2)

$objPerm3 = New-SqlObjectExcessPermission -PermissionName "UPDATE" -DatabaseName "AppDB" -UserName "LimitedUser" -ObjectType "TABLE" -SchemaName "dbo" -ObjectName "Customers" -ColumnName "CreditCardNumber" -RiskLevel "Critique"
$objPerm3.Impact = "L'utilisateur limité peut modifier les numéros de carte de crédit des clients, ce qui représente un risque de sécurité majeur"
$objPerm3.RecommendedAction = "Révoquer la permission UPDATE sur la colonne CreditCardNumber de la table Customers pour l'utilisateur LimitedUser"
$excessPermissions.AddObjectPermission($objPerm3)

# Afficher le résumé des permissions excédentaires
Write-Host "Résumé des permissions excédentaires:" -ForegroundColor Cyan
Write-Host $excessPermissions.GetSummary() -ForegroundColor White

# Filtrer les permissions par niveau de risque
$criticalPermissions = $excessPermissions.FilterByRiskLevel("Critique")
Write-Host "`nPermissions excédentaires critiques:" -ForegroundColor Red
foreach ($perm in $criticalPermissions.ServerPermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor Red
}
foreach ($perm in $criticalPermissions.DatabasePermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor Red
}
foreach ($perm in $criticalPermissions.ObjectPermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor Red
}

# Générer un script SQL pour corriger les permissions excédentaires
$fixScript = $excessPermissions.GenerateFixScript()
Write-Host "`nScript de correction des permissions excédentaires:" -ForegroundColor Green
Write-Host $fixScript -ForegroundColor White

# Exporter le script de correction dans un fichier
$scriptPath = Join-Path -Path $env:TEMP -ChildPath "FixExcessPermissions.sql"
$fixScript | Out-File -FilePath $scriptPath -Encoding UTF8
Write-Host "`nLe script de correction a été exporté dans: $scriptPath" -ForegroundColor Yellow

# Exemple d'utilisation dans un scénario de comparaison
Write-Host "`nExemple de scénario de comparaison:" -ForegroundColor Cyan
Write-Host "1. Capturer les permissions actuelles de l'instance SQL Server"
Write-Host "2. Comparer avec le modèle de référence 'ProductionSecurityModel'"
Write-Host "3. Identifier les permissions excédentaires (comme illustré ci-dessus)"
Write-Host "4. Générer un rapport de conformité"
Write-Host "5. Appliquer les corrections si nécessaire"

# Exemple de rapport de conformité basé sur les permissions excédentaires
$totalPermissions = 100  # Nombre total de permissions dans le modèle (exemple)
$excessCount = $excessPermissions.TotalCount
$complianceScore = [math]::Round(100 - ($excessCount / $totalPermissions * 100), 2)

Write-Host "`nRapport de conformité:" -ForegroundColor Cyan
Write-Host "Score de conformité: $complianceScore%" -ForegroundColor $(if ($complianceScore -ge 90) { "Green" } elseif ($complianceScore -ge 70) { "Yellow" } else { "Red" })
Write-Host "Permissions conformes: $($totalPermissions - $excessCount)/$totalPermissions" -ForegroundColor White
Write-Host "Permissions excédentaires: $excessCount/$totalPermissions" -ForegroundColor White
Write-Host "Répartition par niveau de risque:"
Write-Host "- Critique: $($excessPermissions.RiskLevelCounts['Critique'])" -ForegroundColor Red
Write-Host "- Élevé: $($excessPermissions.RiskLevelCounts['Élevé'])" -ForegroundColor DarkRed
Write-Host "- Moyen: $($excessPermissions.RiskLevelCounts['Moyen'])" -ForegroundColor Yellow
Write-Host "- Faible: $($excessPermissions.RiskLevelCounts['Faible'])" -ForegroundColor Green
