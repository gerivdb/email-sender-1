# PermissionComparisonFunctions-Example.ps1
# Exemple d'utilisation des fonctions de comparaison ensembliste pour identifier les permissions absentes

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\RoadmapParser.psm1"
Import-Module $modulePath -Force

# Charger directement les fichiers nÃ©cessaires pour l'exemple
$missingPermissionModelPath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\Functions\Private\SqlPermissionModels\MissingPermissionModel.ps1"
. $missingPermissionModelPath

$permissionComparisonFunctionsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\Functions\Private\SqlPermissionModels\PermissionComparisonFunctions.ps1"
. $permissionComparisonFunctionsPath

# DÃ©finir le nom de l'instance SQL Server
$serverInstance = "SQLSERVER01"

# 1. CrÃ©er un modÃ¨le de rÃ©fÃ©rence
Write-Host "1. CrÃ©ation d'un modÃ¨le de rÃ©fÃ©rence pour les permissions SQL Server" -ForegroundColor Cyan

$referenceModel = [PSCustomObject]@{
    ModelName = "ProductionSecurityModel"
    
    # Permissions au niveau serveur
    ServerPermissions = @(
        [PSCustomObject]@{
            PermissionName = "CONNECT SQL"
            LoginName = "AppUser"
            PermissionState = "GRANT"
            Description = "Permet Ã  l'application de se connecter au serveur SQL"
        },
        [PSCustomObject]@{
            PermissionName = "VIEW SERVER STATE"
            LoginName = "MonitoringUser"
            PermissionState = "GRANT"
            Description = "Permet aux outils de surveillance de collecter les mÃ©triques de performance"
        },
        [PSCustomObject]@{
            PermissionName = "ALTER ANY LOGIN"
            LoginName = "AdminUser"
            PermissionState = "GRANT"
            Description = "Permet Ã  l'administrateur de gÃ©rer les logins"
        }
    )
    
    # Permissions au niveau base de donnÃ©es
    DatabasePermissions = @(
        [PSCustomObject]@{
            PermissionName = "CONNECT"
            UserName = "AppUser"
            PermissionState = "GRANT"
            SecurableType = "DATABASE"
            SecurableName = "AppDB"
            DatabaseName = "AppDB"
            Description = "Permet Ã  l'application de se connecter Ã  la base de donnÃ©es"
        },
        [PSCustomObject]@{
            PermissionName = "SELECT"
            UserName = "ReportUser"
            PermissionState = "GRANT"
            SecurableType = "DATABASE"
            SecurableName = "AppDB"
            DatabaseName = "AppDB"
            Description = "Permet Ã  l'utilisateur de rapports de lire toutes les donnÃ©es"
        },
        [PSCustomObject]@{
            PermissionName = "CREATE TABLE"
            UserName = "DevUser"
            PermissionState = "GRANT"
            SecurableType = "SCHEMA"
            SecurableName = "dbo"
            DatabaseName = "DevDB"
            Description = "Permet aux dÃ©veloppeurs de crÃ©er des tables dans le schÃ©ma dbo"
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
            Description = "Permet Ã  l'utilisateur de rapports de lire les donnÃ©es clients"
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
            Description = "Permet Ã  l'application d'exÃ©cuter la procÃ©dure stockÃ©e"
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
            Description = "Permet Ã  l'utilisateur limitÃ© de lire les emails des clients"
        }
    )
}

Write-Host "ModÃ¨le de rÃ©fÃ©rence crÃ©Ã© avec:"
Write-Host "- $($referenceModel.ServerPermissions.Count) permissions au niveau serveur"
Write-Host "- $($referenceModel.DatabasePermissions.Count) permissions au niveau base de donnÃ©es"
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
    
    # Permissions au niveau base de donnÃ©es (SELECT pour ReportUser manquant)
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

Write-Host "Permissions actuelles simulÃ©es avec:"
Write-Host "- $($currentPermissions.ServerPermissions.Count) permissions au niveau serveur"
Write-Host "- $($currentPermissions.DatabasePermissions.Count) permissions au niveau base de donnÃ©es"
Write-Host "- $($currentPermissions.ObjectPermissions.Count) permissions au niveau objet"

# 3. Comparer les permissions actuelles avec le modÃ¨le de rÃ©fÃ©rence
Write-Host "`n3. Comparaison des permissions actuelles avec le modÃ¨le de rÃ©fÃ©rence" -ForegroundColor Cyan

# DÃ©finir des cartes de sÃ©vÃ©ritÃ© personnalisÃ©es
$serverSeverityMap = @{
    "CONNECT SQL" = "Critique"
    "VIEW SERVER STATE" = "Ã‰levÃ©e"
    "ALTER ANY LOGIN" = "Ã‰levÃ©e"
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

# 4. Afficher les rÃ©sultats de la comparaison
Write-Host "`n4. RÃ©sultats de la comparaison" -ForegroundColor Cyan
Write-Host $missingPermissions.GetSummary()

# 5. Afficher les permissions manquantes par niveau
Write-Host "`n5. Permissions manquantes par niveau" -ForegroundColor Cyan

Write-Host "`nPermissions manquantes au niveau serveur:" -ForegroundColor Yellow
foreach ($perm in $missingPermissions.ServerPermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor $(
        switch ($perm.Severity) {
            "Critique" { "Red" }
            "Ã‰levÃ©e" { "DarkRed" }
            "Moyenne" { "Yellow" }
            "Faible" { "Green" }
            default { "White" }
        }
    )
    Write-Host "  Impact: $($perm.Impact)" -ForegroundColor Gray
    Write-Host "  Action recommandÃ©e: $($perm.RecommendedAction)" -ForegroundColor Gray
}

Write-Host "`nPermissions manquantes au niveau base de donnÃ©es:" -ForegroundColor Yellow
foreach ($perm in $missingPermissions.DatabasePermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor $(
        switch ($perm.Severity) {
            "Critique" { "Red" }
            "Ã‰levÃ©e" { "DarkRed" }
            "Moyenne" { "Yellow" }
            "Faible" { "Green" }
            default { "White" }
        }
    )
    Write-Host "  Impact: $($perm.Impact)" -ForegroundColor Gray
    Write-Host "  Action recommandÃ©e: $($perm.RecommendedAction)" -ForegroundColor Gray
}

Write-Host "`nPermissions manquantes au niveau objet:" -ForegroundColor Yellow
foreach ($perm in $missingPermissions.ObjectPermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor $(
        switch ($perm.Severity) {
            "Critique" { "Red" }
            "Ã‰levÃ©e" { "DarkRed" }
            "Moyenne" { "Yellow" }
            "Faible" { "Green" }
            default { "White" }
        }
    )
    Write-Host "  Impact: $($perm.Impact)" -ForegroundColor Gray
    Write-Host "  Action recommandÃ©e: $($perm.RecommendedAction)" -ForegroundColor Gray
}

# 6. GÃ©nÃ©rer un script SQL pour corriger les permissions manquantes
Write-Host "`n6. Script SQL pour corriger les permissions manquantes" -ForegroundColor Cyan
$fixScript = $missingPermissions.GenerateFixScript()
Write-Host $fixScript -ForegroundColor White

# 7. Exporter le script de correction dans un fichier
$scriptPath = Join-Path -Path $env:TEMP -ChildPath "FixMissingPermissions.sql"
$fixScript | Out-File -FilePath $scriptPath -Encoding UTF8
Write-Host "`nLe script de correction a Ã©tÃ© exportÃ© dans: $scriptPath" -ForegroundColor Yellow

# 8. Filtrer les permissions par sÃ©vÃ©ritÃ©
Write-Host "`n8. Filtrer les permissions par sÃ©vÃ©ritÃ©" -ForegroundColor Cyan

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

$highPermissions = $missingPermissions.FilterBySeverity("Ã‰levÃ©e")
Write-Host "`nPermissions manquantes Ã©levÃ©es: $($highPermissions.TotalCount)" -ForegroundColor DarkRed
foreach ($perm in $highPermissions.ServerPermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor DarkRed
}
foreach ($perm in $highPermissions.DatabasePermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor DarkRed
}
foreach ($perm in $highPermissions.ObjectPermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor DarkRed
}

# 9. Exemple de scÃ©nario d'utilisation rÃ©el
Write-Host "`n9. Exemple de scÃ©nario d'utilisation rÃ©el" -ForegroundColor Cyan
Write-Host "1. Capturer le modÃ¨le de rÃ©fÃ©rence Ã  partir d'une instance SQL Server de rÃ©fÃ©rence"
Write-Host "2. Capturer les permissions actuelles de l'instance SQL Server Ã  auditer"
Write-Host "3. Comparer les permissions actuelles avec le modÃ¨le de rÃ©fÃ©rence"
Write-Host "4. GÃ©nÃ©rer un rapport des permissions manquantes"
Write-Host "5. GÃ©nÃ©rer un script SQL pour corriger les permissions manquantes"
Write-Host "6. ExÃ©cuter le script SQL pour corriger les permissions manquantes"
Write-Host "7. VÃ©rifier que toutes les permissions sont correctement appliquÃ©es"

# 10. Calcul du score de conformitÃ©
Write-Host "`n10. Calcul du score de conformitÃ©" -ForegroundColor Cyan

# Nombre total de permissions dans le modÃ¨le de rÃ©fÃ©rence
$totalPermissions = $referenceModel.ServerPermissions.Count + 
                   $referenceModel.DatabasePermissions.Count + 
                   $referenceModel.ObjectPermissions.Count

# Nombre de permissions manquantes
$missingCount = $missingPermissions.TotalCount

# Calcul du score de conformitÃ©
$complianceScore = [math]::Round(100 - ($missingCount / $totalPermissions * 100), 2)

Write-Host "Score de conformitÃ©: $complianceScore%" -ForegroundColor $(
    if ($complianceScore -ge 90) { "Green" } 
    elseif ($complianceScore -ge 70) { "Yellow" } 
    else { "Red" }
)
Write-Host "Permissions conformes: $($totalPermissions - $missingCount)/$totalPermissions" -ForegroundColor White
Write-Host "Permissions manquantes: $missingCount/$totalPermissions" -ForegroundColor White
Write-Host "RÃ©partition par sÃ©vÃ©ritÃ©:"
Write-Host "- Critique: $($missingPermissions.SeverityCounts['Critique'])" -ForegroundColor Red
Write-Host "- Ã‰levÃ©e: $($missingPermissions.SeverityCounts['Ã‰levÃ©e'])" -ForegroundColor DarkRed
Write-Host "- Moyenne: $($missingPermissions.SeverityCounts['Moyenne'])" -ForegroundColor Yellow
Write-Host "- Faible: $($missingPermissions.SeverityCounts['Faible'])" -ForegroundColor Green
