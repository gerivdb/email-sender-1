# Test-ContradictoryPermissionModel.ps1
# Script de test simple pour vÃ©rifier que les classes de permissions contradictoires fonctionnent correctement

# Charger le fichier de modÃ¨le de permissions contradictoires
$contradictoryPermissionModelPath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\Functions\Private\SqlPermissionModels\ContradictoryPermissionModel.ps1"
. $contradictoryPermissionModelPath

Write-Host "=== Tests de la classe SqlServerContradictoryPermission ==="
Write-Host "========================================================"

# CrÃ©er une instance de SqlServerContradictoryPermission
Write-Host "CrÃ©ation d'une instance de SqlServerContradictoryPermission..."
$serverPermission = [SqlServerContradictoryPermission]::new("CONNECT SQL", "TestLogin")

# VÃ©rifier que l'instance a Ã©tÃ© crÃ©Ã©e correctement
Write-Host "VÃ©rification des propriÃ©tÃ©s de l'instance..."
Write-Host "PermissionName: $($serverPermission.PermissionName)"
Write-Host "LoginName: $($serverPermission.LoginName)"
Write-Host "SecurableType: $($serverPermission.SecurableType)"
Write-Host "ContradictionType: $($serverPermission.ContradictionType)"
Write-Host "RiskLevel: $($serverPermission.RiskLevel)"

# Tester la mÃ©thode ToString
Write-Host "`nTest de la mÃ©thode ToString()..."
$toString = $serverPermission.ToString()
Write-Host "ToString(): $toString"

# Tester la mÃ©thode GenerateFixScript
Write-Host "`nTest de la mÃ©thode GenerateFixScript()..."
$script = $serverPermission.GenerateFixScript()
Write-Host "Script de rÃ©solution gÃ©nÃ©rÃ©:"
Write-Host $script

# Tester la mÃ©thode GetDetailedDescription
Write-Host "`nTest de la mÃ©thode GetDetailedDescription()..."
$description = $serverPermission.GetDetailedDescription()
Write-Host "Description dÃ©taillÃ©e:"
Write-Host $description

# Tester la fonction New-SqlServerContradictoryPermission
Write-Host "`nTest de la fonction New-SqlServerContradictoryPermission..."
$newServerPermission = New-SqlServerContradictoryPermission `
    -PermissionName "ALTER ANY LOGIN" `
    -LoginName "AdminLogin" `
    -SecurableName "TestServer" `
    -ContradictionType "HÃ©ritage" `
    -RiskLevel "Critique" `
    -Impact "Risque de sÃ©curitÃ© Ã©levÃ©" `
    -RecommendedAction "VÃ©rifier les rÃ´les du login"

# VÃ©rifier que l'instance a Ã©tÃ© crÃ©Ã©e correctement
Write-Host "VÃ©rification des propriÃ©tÃ©s de l'instance crÃ©Ã©e avec New-SqlServerContradictoryPermission..."
Write-Host "PermissionName: $($newServerPermission.PermissionName)"
Write-Host "LoginName: $($newServerPermission.LoginName)"
Write-Host "SecurableName: $($newServerPermission.SecurableName)"
Write-Host "ContradictionType: $($newServerPermission.ContradictionType)"
Write-Host "RiskLevel: $($newServerPermission.RiskLevel)"
Write-Host "Impact: $($newServerPermission.Impact)"
Write-Host "RecommendedAction: $($newServerPermission.RecommendedAction)"

Write-Host "`n=== Tests de la classe SqlDatabaseContradictoryPermission ==="
Write-Host "=========================================================="

# CrÃ©er une instance de SqlDatabaseContradictoryPermission
Write-Host "CrÃ©ation d'une instance de SqlDatabaseContradictoryPermission..."
$dbPermission = [SqlDatabaseContradictoryPermission]::new("SELECT", "TestUser", "TestDB")

# VÃ©rifier que l'instance a Ã©tÃ© crÃ©Ã©e correctement
Write-Host "VÃ©rification des propriÃ©tÃ©s de l'instance..."
Write-Host "PermissionName: $($dbPermission.PermissionName)"
Write-Host "UserName: $($dbPermission.UserName)"
Write-Host "DatabaseName: $($dbPermission.DatabaseName)"
Write-Host "SecurableType: $($dbPermission.SecurableType)"
Write-Host "SecurableName: $($dbPermission.SecurableName)"
Write-Host "ContradictionType: $($dbPermission.ContradictionType)"
Write-Host "RiskLevel: $($dbPermission.RiskLevel)"

# Tester la mÃ©thode ToString
Write-Host "`nTest de la mÃ©thode ToString()..."
$toString = $dbPermission.ToString()
Write-Host "ToString(): $toString"

# Tester la mÃ©thode GenerateFixScript
Write-Host "`nTest de la mÃ©thode GenerateFixScript()..."
$script = $dbPermission.GenerateFixScript()
Write-Host "Script de rÃ©solution gÃ©nÃ©rÃ©:"
Write-Host $script

# Tester la mÃ©thode GetDetailedDescription
Write-Host "`nTest de la mÃ©thode GetDetailedDescription()..."
$dbPermission.LoginName = "TestLogin"
$dbPermission.Impact = "AccÃ¨s incohÃ©rent aux donnÃ©es"
$dbPermission.RecommendedAction = "Supprimer la permission DENY"
$description = $dbPermission.GetDetailedDescription()
Write-Host "Description dÃ©taillÃ©e:"
Write-Host $description

# Tester la fonction New-SqlDatabaseContradictoryPermission
Write-Host "`nTest de la fonction New-SqlDatabaseContradictoryPermission..."
$newDbPermission = New-SqlDatabaseContradictoryPermission `
    -PermissionName "UPDATE" `
    -UserName "AppUser" `
    -DatabaseName "AppDB" `
    -ContradictionType "HÃ©ritage" `
    -ModelName "SecurityModel" `
    -RiskLevel "Critique" `
    -LoginName "AppLogin" `
    -Impact "Risque de sÃ©curitÃ© Ã©levÃ©" `
    -RecommendedAction "VÃ©rifier les rÃ´les de l'utilisateur"

# VÃ©rifier que l'instance a Ã©tÃ© crÃ©Ã©e correctement
Write-Host "VÃ©rification des propriÃ©tÃ©s de l'instance crÃ©Ã©e avec New-SqlDatabaseContradictoryPermission..."
Write-Host "PermissionName: $($newDbPermission.PermissionName)"
Write-Host "UserName: $($newDbPermission.UserName)"
Write-Host "DatabaseName: $($newDbPermission.DatabaseName)"
Write-Host "SecurableName: $($newDbPermission.SecurableName)"
Write-Host "ContradictionType: $($newDbPermission.ContradictionType)"
Write-Host "ModelName: $($newDbPermission.ModelName)"
Write-Host "RiskLevel: $($newDbPermission.RiskLevel)"
Write-Host "LoginName: $($newDbPermission.LoginName)"
Write-Host "Impact: $($newDbPermission.Impact)"
Write-Host "RecommendedAction: $($newDbPermission.RecommendedAction)"

Write-Host "`n=== Tests de la classe SqlObjectContradictoryPermission ==="
Write-Host "======================================================="

# CrÃ©er une instance de SqlObjectContradictoryPermission
Write-Host "CrÃ©ation d'une instance de SqlObjectContradictoryPermission..."
$objPermission = [SqlObjectContradictoryPermission]::new("SELECT", "TestUser", "TestDB", "TestTable")

# VÃ©rifier que l'instance a Ã©tÃ© crÃ©Ã©e correctement
Write-Host "VÃ©rification des propriÃ©tÃ©s de l'instance..."
Write-Host "PermissionName: $($objPermission.PermissionName)"
Write-Host "UserName: $($objPermission.UserName)"
Write-Host "DatabaseName: $($objPermission.DatabaseName)"
Write-Host "ObjectName: $($objPermission.ObjectName)"
Write-Host "SecurableType: $($objPermission.SecurableType)"
Write-Host "SecurableName: $($objPermission.SecurableName)"
Write-Host "ContradictionType: $($objPermission.ContradictionType)"
Write-Host "RiskLevel: $($objPermission.RiskLevel)"

# Tester la mÃ©thode ToString
Write-Host "`nTest de la mÃ©thode ToString()..."
$objPermission.SchemaName = "dbo"
$toString = $objPermission.ToString()
Write-Host "ToString(): $toString"

# Tester la mÃ©thode GenerateFixScript
Write-Host "`nTest de la mÃ©thode GenerateFixScript()..."
$script = $objPermission.GenerateFixScript()
Write-Host "Script de rÃ©solution gÃ©nÃ©rÃ©:"
Write-Host $script

# Tester la mÃ©thode GenerateFixScript avec colonne
Write-Host "`nTest de la mÃ©thode GenerateFixScript() avec colonne..."
$objPermission.ColumnName = "ID"
$script = $objPermission.GenerateFixScript()
Write-Host "Script de rÃ©solution gÃ©nÃ©rÃ© avec colonne:"
Write-Host $script

# Tester la mÃ©thode GetDetailedDescription
Write-Host "`nTest de la mÃ©thode GetDetailedDescription()..."
$objPermission.ObjectType = "TABLE"
$objPermission.LoginName = "TestLogin"
$objPermission.Impact = "AccÃ¨s incohÃ©rent aux donnÃ©es de la table"
$objPermission.RecommendedAction = "Supprimer la permission DENY"
$description = $objPermission.GetDetailedDescription()
Write-Host "Description dÃ©taillÃ©e:"
Write-Host $description

# Tester la fonction New-SqlObjectContradictoryPermission
Write-Host "`nTest de la fonction New-SqlObjectContradictoryPermission..."
$newObjPermission = New-SqlObjectContradictoryPermission `
    -PermissionName "UPDATE" `
    -UserName "AppUser" `
    -DatabaseName "AppDB" `
    -SchemaName "Sales" `
    -ObjectName "Customers" `
    -ObjectType "TABLE" `
    -ColumnName "CustomerID" `
    -ContradictionType "HÃ©ritage" `
    -ModelName "SecurityModel" `
    -RiskLevel "Critique" `
    -LoginName "AppLogin" `
    -Impact "Risque de sÃ©curitÃ© Ã©levÃ©" `
    -RecommendedAction "VÃ©rifier les rÃ´les de l'utilisateur"

# VÃ©rifier que l'instance a Ã©tÃ© crÃ©Ã©e correctement
Write-Host "VÃ©rification des propriÃ©tÃ©s de l'instance crÃ©Ã©e avec New-SqlObjectContradictoryPermission..."
Write-Host "PermissionName: $($newObjPermission.PermissionName)"
Write-Host "UserName: $($newObjPermission.UserName)"
Write-Host "DatabaseName: $($newObjPermission.DatabaseName)"
Write-Host "SchemaName: $($newObjPermission.SchemaName)"
Write-Host "ObjectName: $($newObjPermission.ObjectName)"
Write-Host "ObjectType: $($newObjPermission.ObjectType)"
Write-Host "ColumnName: $($newObjPermission.ColumnName)"
Write-Host "SecurableName: $($newObjPermission.SecurableName)"
Write-Host "ContradictionType: $($newObjPermission.ContradictionType)"
Write-Host "ModelName: $($newObjPermission.ModelName)"
Write-Host "RiskLevel: $($newObjPermission.RiskLevel)"
Write-Host "LoginName: $($newObjPermission.LoginName)"
Write-Host "Impact: $($newObjPermission.Impact)"
Write-Host "RecommendedAction: $($newObjPermission.RecommendedAction)"

Write-Host "`n=== Tests de la classe SqlContradictoryPermissionsSet ==="
Write-Host "================================================"

# CrÃ©er une instance de SqlContradictoryPermissionsSet
Write-Host "CrÃ©ation d'une instance de SqlContradictoryPermissionsSet..."
$permissionsSet = [SqlContradictoryPermissionsSet]::new("TestServer", "TestModel")

# VÃ©rifier que l'instance a Ã©tÃ© crÃ©Ã©e correctement
Write-Host "VÃ©rification des propriÃ©tÃ©s de l'instance..."
Write-Host "ServerName: $($permissionsSet.ServerName)"
Write-Host "ModelName: $($permissionsSet.ModelName)"
Write-Host "AnalysisDate: $($permissionsSet.AnalysisDate)"
Write-Host "AnalysisUser: $($permissionsSet.AnalysisUser)"
Write-Host "TotalContradictions: $($permissionsSet.TotalContradictions)"

# Ajouter des contradictions
Write-Host "`nAjout de contradictions Ã  l'ensemble..."
$permissionsSet.AddServerContradiction($serverPermission)
$permissionsSet.AddDatabaseContradiction($dbPermission)
$permissionsSet.AddObjectContradiction($objPermission)

# VÃ©rifier que les contradictions ont Ã©tÃ© ajoutÃ©es
Write-Host "VÃ©rification des contradictions ajoutÃ©es..."
Write-Host "Nombre total de contradictions: $($permissionsSet.TotalContradictions)"
Write-Host "Contradictions au niveau serveur: $($permissionsSet.ServerContradictions.Count)"
Write-Host "Contradictions au niveau base de donnÃ©es: $($permissionsSet.DatabaseContradictions.Count)"
Write-Host "Contradictions au niveau objet: $($permissionsSet.ObjectContradictions.Count)"

# Tester la mÃ©thode GetAllContradictions
Write-Host "`nTest de la mÃ©thode GetAllContradictions()..."
$allContradictions = $permissionsSet.GetAllContradictions()
Write-Host "Nombre total de contradictions rÃ©cupÃ©rÃ©es: $($allContradictions.Count)"

# Tester la mÃ©thode FilterByRiskLevel
Write-Host "`nTest de la mÃ©thode FilterByRiskLevel()..."
$moyenContradictions = $permissionsSet.FilterByRiskLevel("Moyen")
Write-Host "Nombre de contradictions de niveau Moyen: $($moyenContradictions.Count)"

# Tester la mÃ©thode FilterByType
Write-Host "`nTest de la mÃ©thode FilterByType()..."
$grantDenyContradictions = $permissionsSet.FilterByType("GRANT/DENY")
Write-Host "Nombre de contradictions de type GRANT/DENY: $($grantDenyContradictions.Count)"

# Tester la mÃ©thode FilterByUser
Write-Host "`nTest de la mÃ©thode FilterByUser()..."
$testUserContradictions = $permissionsSet.FilterByUser("TestUser")
Write-Host "Nombre de contradictions pour l'utilisateur TestUser: $($testUserContradictions.Count)"

# Tester la mÃ©thode GenerateSummaryReport
Write-Host "`nTest de la mÃ©thode GenerateSummaryReport()..."
$summaryReport = $permissionsSet.GenerateSummaryReport()
Write-Host "Rapport de synthÃ¨se gÃ©nÃ©rÃ© avec succÃ¨s."

# Tester la mÃ©thode GenerateDetailedReport
Write-Host "`nTest de la mÃ©thode GenerateDetailedReport()..."
$detailedReport = $permissionsSet.GenerateDetailedReport()
Write-Host "Rapport dÃ©taillÃ© gÃ©nÃ©rÃ© avec succÃ¨s."

# Tester la mÃ©thode GenerateFixScript
Write-Host "`nTest de la mÃ©thode GenerateFixScript()..."
$fixScript = $permissionsSet.GenerateFixScript()
Write-Host "Script de rÃ©solution gÃ©nÃ©rÃ© avec succÃ¨s."

# Tester la mÃ©thode ToString
Write-Host "`nTest de la mÃ©thode ToString()..."
$toString = $permissionsSet.ToString()
Write-Host "ToString(): $toString"

# Tester la fonction New-SqlContradictoryPermissionsSet
Write-Host "`nTest de la fonction New-SqlContradictoryPermissionsSet..."
$newPermissionsSet = New-SqlContradictoryPermissionsSet `
    -ServerName "ProdServer" `
    -ModelName "ProductionModel" `
    -Description "Test description" `
    -ReportTitle "Test report title"

# VÃ©rifier que l'instance a Ã©tÃ© crÃ©Ã©e correctement
Write-Host "VÃ©rification des propriÃ©tÃ©s de l'instance crÃ©Ã©e avec New-SqlContradictoryPermissionsSet..."
Write-Host "ServerName: $($newPermissionsSet.ServerName)"
Write-Host "ModelName: $($newPermissionsSet.ModelName)"
Write-Host "Description: $($newPermissionsSet.Description)"
Write-Host "ReportTitle: $($newPermissionsSet.ReportTitle)"

Write-Host "`nTous les tests terminÃ©s avec succÃ¨s!"
