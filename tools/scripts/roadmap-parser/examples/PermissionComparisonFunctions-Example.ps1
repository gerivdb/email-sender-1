# PermissionComparisonFunctions-Example.ps1
# Exemple d'utilisation des fonctions de comparaison ensembliste pour identifier les permissions absentes

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\RoadmapParser.psm1"
Import-Module $modulePath -Force

# Charger directement les fichiers nécessaires pour l'exemple
$missingPermissionModelPath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\Functions\Private\SqlPermissionModels\MissingPermissionModel.ps1"
. $missingPermissionModelPath

$permissionComparisonFunctionsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\Functions\Private\SqlPermissionModels\PermissionComparisonFunctions.ps1"
. $permissionComparisonFunctionsPath

# Définir le nom de l'instance SQL Server
$serverInstance = "SQLSERVER01"

# 1. Créer un modèle de référence
Write-Host "1. Création d'un modèle de référence pour les permissions SQL Server" -ForegroundColor Cyan

$referenceModel = [PSCustomObject]@{
    ModelName = "ProductionSecurityModel"
    
    # Permissions au niveau serveur
    ServerPermissions = @(
        [PSCustomObject]@{
            PermissionName = "CONNECT SQL"
            LoginName = "AppUser"
            PermissionState = "GRANT"
            Description = "Permet à l'application de se connecter au serveur SQL"
        },
        [PSCustomObject]@{
            PermissionName = "VIEW SERVER STATE"
            LoginName = "MonitoringUser"
            PermissionState = "GRANT"
            Description = "Permet aux outils de surveillance de collecter les métriques de performance"
        },
        [PSCustomObject]@{
            PermissionName = "ALTER ANY LOGIN"
            LoginName = "AdminUser"
            PermissionState = "GRANT"
            Description = "Permet à l'administrateur de gérer les logins"
        }
    )
    
    # Permissions au niveau base de données
    DatabasePermissions = @(
        [PSCustomObject]@{
            PermissionName = "CONNECT"
            UserName = "AppUser"
            PermissionState = "GRANT"
            SecurableType = "DATABASE"
            SecurableName = "AppDB"
            DatabaseName = "AppDB"
            Description = "Permet à l'application de se connecter à la base de données"
        },
        [PSCustomObject]@{
            PermissionName = "SELECT"
            UserName = "ReportUser"
            PermissionState = "GRANT"
            SecurableType = "DATABASE"
            SecurableName = "AppDB"
            DatabaseName = "AppDB"
            Description = "Permet à l'utilisateur de rapports de lire toutes les données"
        },
        [PSCustomObject]@{
            PermissionName = "CREATE TABLE"
            UserName = "DevUser"
            PermissionState = "GRANT"
            SecurableType = "SCHEMA"
            SecurableName = "dbo"
            DatabaseName = "DevDB"
            Description = "Permet aux développeurs de créer des tables dans le schéma dbo"
        }
    )
    
    # Permissions au niveau objet
    ObjectPermissions = @(
        [PSCustomObject]@{
            PermissionName = "SELECT"
            UserName = "ReportUser"
            PermissionState = "GRANT"
            ObjectType = "TABLE"
            SchemaName = "dbo"
            ObjectName = "Customers"
            ColumnName = ""
            DatabaseName = "AppDB"
            Description = "Permet à l'utilisateur de rapports de lire les données clients"
        },
        [PSCustomObject]@{
            PermissionName = "EXECUTE"
            UserName = "AppUser"
            PermissionState = "GRANT"
            ObjectType = "PROCEDURE"
            SchemaName = "dbo"
            ObjectName = "GetCustomerData"
            ColumnName = ""
            DatabaseName = "AppDB"
            Description = "Permet à l'application d'exécuter la procédure stockée"
        },
        [PSCustomObject]@{
            PermissionName = "SELECT"
            UserName = "LimitedUser"
            PermissionState = "GRANT"
            ObjectType = "TABLE"
            SchemaName = "dbo"
            ObjectName = "Customers"
            ColumnName = "Email"
            DatabaseName = "AppDB"
            Description = "Permet à l'utilisateur limité de lire les emails des clients"
        }
    )
}

Write-Host "Modèle de référence créé avec:"
Write-Host "- $($referenceModel.ServerPermissions.Count) permissions au niveau serveur"
Write-Host "- $($referenceModel.DatabasePermissions.Count) permissions au niveau base de données"
Write-Host "- $($referenceModel.ObjectPermissions.Count) permissions au niveau objet"

# 2. Simuler les permissions actuelles (avec certaines permissions manquantes)
Write-Host "`n2. Simulation des permissions actuelles (avec certaines permissions manquantes)" -ForegroundColor Cyan

$currentPermissions = [PSCustomObject]@{
    # Permissions au niveau serveur (VIEW SERVER STATE manquant)
    ServerPermissions = @(
        [PSCustomObject]@{
            PermissionName = "CONNECT SQL"
            LoginName = "AppUser"
            PermissionState = "GRANT"
        },
        [PSCustomObject]@{
            PermissionName = "ALTER ANY LOGIN"
            LoginName = "AdminUser"
            PermissionState = "GRANT"
        }
    )
    
    # Permissions au niveau base de données (SELECT pour ReportUser manquant)
    DatabasePermissions = @(
        [PSCustomObject]@{
            PermissionName = "CONNECT"
            UserName = "AppUser"
            PermissionState = "GRANT"
            SecurableType = "DATABASE"
            SecurableName = "AppDB"
            DatabaseName = "AppDB"
        },
        [PSCustomObject]@{
            PermissionName = "CREATE TABLE"
            UserName = "DevUser"
            PermissionState = "GRANT"
            SecurableType = "SCHEMA"
            SecurableName = "dbo"
            DatabaseName = "DevDB"
        }
    )
    
    # Permissions au niveau objet (EXECUTE pour AppUser et SELECT sur Email pour LimitedUser manquants)
    ObjectPermissions = @(
        [PSCustomObject]@{
            PermissionName = "SELECT"
            UserName = "ReportUser"
            PermissionState = "GRANT"
            ObjectType = "TABLE"
            SchemaName = "dbo"
            ObjectName = "Customers"
            ColumnName = ""
            DatabaseName = "AppDB"
        }
    )
}

Write-Host "Permissions actuelles simulées avec:"
Write-Host "- $($currentPermissions.ServerPermissions.Count) permissions au niveau serveur"
Write-Host "- $($currentPermissions.DatabasePermissions.Count) permissions au niveau base de données"
Write-Host "- $($currentPermissions.ObjectPermissions.Count) permissions au niveau objet"

# 3. Comparer les permissions actuelles avec le modèle de référence
Write-Host "`n3. Comparaison des permissions actuelles avec le modèle de référence" -ForegroundColor Cyan

# Définir des cartes de sévérité personnalisées
$serverSeverityMap = @{
    "CONNECT SQL" = "Critique"
    "VIEW SERVER STATE" = "Élevée"
    "ALTER ANY LOGIN" = "Élevée"
    "DEFAULT" = "Moyenne"
}

$databaseSeverityMap = @{
    "CONNECT" = "Critique"
    "SELECT" = "Moyenne"
    "CREATE TABLE" = "Faible"
    "DEFAULT" = "Moyenne"
}

$objectSeverityMap = @{
    "EXECUTE" = "Critique"
    "SELECT" = "Moyenne"
    "DEFAULT" = "Moyenne"
}

$objectTypeSeverityMap = @{
    "PROCEDURE" = @{
        "EXECUTE" = "Critique"
    }
    "TABLE" = @{
        "SELECT" = "Moyenne"
    }
}

# Effectuer la comparaison
$missingPermissions = Compare-SqlPermissionsWithModel `
    -ReferenceModel $referenceModel `
    -CurrentPermissions $currentPermissions `
    -ServerInstance $serverInstance `
    -ServerSeverityMap $serverSeverityMap `
    -DatabaseSeverityMap $databaseSeverityMap `
    -ObjectSeverityMap $objectSeverityMap `
    -ObjectTypeSeverityMap $objectTypeSeverityMap

# 4. Afficher les résultats de la comparaison
Write-Host "`n4. Résultats de la comparaison" -ForegroundColor Cyan
Write-Host $missingPermissions.GetSummary()

# 5. Afficher les permissions manquantes par niveau
Write-Host "`n5. Permissions manquantes par niveau" -ForegroundColor Cyan

Write-Host "`nPermissions manquantes au niveau serveur:" -ForegroundColor Yellow
foreach ($perm in $missingPermissions.ServerPermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor $(
        switch ($perm.Severity) {
            "Critique" { "Red" }
            "Élevée" { "DarkRed" }
            "Moyenne" { "Yellow" }
            "Faible" { "Green" }
            default { "White" }
        }
    )
    Write-Host "  Impact: $($perm.Impact)" -ForegroundColor Gray
    Write-Host "  Action recommandée: $($perm.RecommendedAction)" -ForegroundColor Gray
}

Write-Host "`nPermissions manquantes au niveau base de données:" -ForegroundColor Yellow
foreach ($perm in $missingPermissions.DatabasePermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor $(
        switch ($perm.Severity) {
            "Critique" { "Red" }
            "Élevée" { "DarkRed" }
            "Moyenne" { "Yellow" }
            "Faible" { "Green" }
            default { "White" }
        }
    )
    Write-Host "  Impact: $($perm.Impact)" -ForegroundColor Gray
    Write-Host "  Action recommandée: $($perm.RecommendedAction)" -ForegroundColor Gray
}

Write-Host "`nPermissions manquantes au niveau objet:" -ForegroundColor Yellow
foreach ($perm in $missingPermissions.ObjectPermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor $(
        switch ($perm.Severity) {
            "Critique" { "Red" }
            "Élevée" { "DarkRed" }
            "Moyenne" { "Yellow" }
            "Faible" { "Green" }
            default { "White" }
        }
    )
    Write-Host "  Impact: $($perm.Impact)" -ForegroundColor Gray
    Write-Host "  Action recommandée: $($perm.RecommendedAction)" -ForegroundColor Gray
}

# 6. Générer un script SQL pour corriger les permissions manquantes
Write-Host "`n6. Script SQL pour corriger les permissions manquantes" -ForegroundColor Cyan
$fixScript = $missingPermissions.GenerateFixScript()
Write-Host $fixScript -ForegroundColor White

# 7. Exporter le script de correction dans un fichier
$scriptPath = Join-Path -Path $env:TEMP -ChildPath "FixMissingPermissions.sql"
$fixScript | Out-File -FilePath $scriptPath -Encoding UTF8
Write-Host "`nLe script de correction a été exporté dans: $scriptPath" -ForegroundColor Yellow

# 8. Filtrer les permissions par sévérité
Write-Host "`n8. Filtrer les permissions par sévérité" -ForegroundColor Cyan

$criticalPermissions = $missingPermissions.FilterBySeverity("Critique")
Write-Host "`nPermissions manquantes critiques: $($criticalPermissions.TotalCount)" -ForegroundColor Red
foreach ($perm in $criticalPermissions.ServerPermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor Red
}
foreach ($perm in $criticalPermissions.DatabasePermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor Red
}
foreach ($perm in $criticalPermissions.ObjectPermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor Red
}

$highPermissions = $missingPermissions.FilterBySeverity("Élevée")
Write-Host "`nPermissions manquantes élevées: $($highPermissions.TotalCount)" -ForegroundColor DarkRed
foreach ($perm in $highPermissions.ServerPermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor DarkRed
}
foreach ($perm in $highPermissions.DatabasePermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor DarkRed
}
foreach ($perm in $highPermissions.ObjectPermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor DarkRed
}

# 9. Exemple de scénario d'utilisation réel
Write-Host "`n9. Exemple de scénario d'utilisation réel" -ForegroundColor Cyan
Write-Host "1. Capturer le modèle de référence à partir d'une instance SQL Server de référence"
Write-Host "2. Capturer les permissions actuelles de l'instance SQL Server à auditer"
Write-Host "3. Comparer les permissions actuelles avec le modèle de référence"
Write-Host "4. Générer un rapport des permissions manquantes"
Write-Host "5. Générer un script SQL pour corriger les permissions manquantes"
Write-Host "6. Exécuter le script SQL pour corriger les permissions manquantes"
Write-Host "7. Vérifier que toutes les permissions sont correctement appliquées"

# 10. Calcul du score de conformité
Write-Host "`n10. Calcul du score de conformité" -ForegroundColor Cyan

# Nombre total de permissions dans le modèle de référence
$totalPermissions = $referenceModel.ServerPermissions.Count + 
                   $referenceModel.DatabasePermissions.Count + 
                   $referenceModel.ObjectPermissions.Count

# Nombre de permissions manquantes
$missingCount = $missingPermissions.TotalCount

# Calcul du score de conformité
$complianceScore = [math]::Round(100 - ($missingCount / $totalPermissions * 100), 2)

Write-Host "Score de conformité: $complianceScore%" -ForegroundColor $(
    if ($complianceScore -ge 90) { "Green" } 
    elseif ($complianceScore -ge 70) { "Yellow" } 
    else { "Red" }
)
Write-Host "Permissions conformes: $($totalPermissions - $missingCount)/$totalPermissions" -ForegroundColor White
Write-Host "Permissions manquantes: $missingCount/$totalPermissions" -ForegroundColor White
Write-Host "Répartition par sévérité:"
Write-Host "- Critique: $($missingPermissions.SeverityCounts['Critique'])" -ForegroundColor Red
Write-Host "- Élevée: $($missingPermissions.SeverityCounts['Élevée'])" -ForegroundColor DarkRed
Write-Host "- Moyenne: $($missingPermissions.SeverityCounts['Moyenne'])" -ForegroundColor Yellow
Write-Host "- Faible: $($missingPermissions.SeverityCounts['Faible'])" -ForegroundColor Green
