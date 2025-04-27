# Test-ContradictoryPermissionModel.ps1
# Script de test simple pour vérifier que les classes de permissions contradictoires fonctionnent correctement

# Charger le fichier de modèle de permissions contradictoires
$contradictoryPermissionModelPath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\Functions\Private\SqlPermissionModels\ContradictoryPermissionModel.ps1"
. $contradictoryPermissionModelPath

Write-Host "=== Tests de la classe SqlServerContradictoryPermission ==="
Write-Host "========================================================"

# Créer une instance de SqlServerContradictoryPermission
Write-Host "Création d'une instance de SqlServerContradictoryPermission..."
$serverPermission = [SqlServerContradictoryPermission]::new("CONNECT SQL", "TestLogin")

# Vérifier que l'instance a été créée correctement
Write-Host "Vérification des propriétés de l'instance..."
Write-Host "PermissionName: $($serverPermission.PermissionName)"
Write-Host "LoginName: $($serverPermission.LoginName)"
Write-Host "SecurableType: $($serverPermission.SecurableType)"
Write-Host "ContradictionType: $($serverPermission.ContradictionType)"
Write-Host "RiskLevel: $($serverPermission.RiskLevel)"

# Tester la méthode ToString
Write-Host "`nTest de la méthode ToString()..."
$toString = $serverPermission.ToString()
Write-Host "ToString(): $toString"

# Tester la méthode GenerateFixScript
Write-Host "`nTest de la méthode GenerateFixScript()..."
$script = $serverPermission.GenerateFixScript()
Write-Host "Script de résolution généré:"
Write-Host $script

# Tester la méthode GetDetailedDescription
Write-Host "`nTest de la méthode GetDetailedDescription()..."
$description = $serverPermission.GetDetailedDescription()
Write-Host "Description détaillée:"
Write-Host $description

# Tester la fonction New-SqlServerContradictoryPermission
Write-Host "`nTest de la fonction New-SqlServerContradictoryPermission..."
$newServerPermission = New-SqlServerContradictoryPermission `
    -PermissionName "ALTER ANY LOGIN" `
    -LoginName "AdminLogin" `
    -SecurableName "TestServer" `
    -ContradictionType "Héritage" `
    -RiskLevel "Critique" `
    -Impact "Risque de sécurité élevé" `
    -RecommendedAction "Vérifier les rôles du login"

# Vérifier que l'instance a été créée correctement
Write-Host "Vérification des propriétés de l'instance créée avec New-SqlServerContradictoryPermission..."
Write-Host "PermissionName: $($newServerPermission.PermissionName)"
Write-Host "LoginName: $($newServerPermission.LoginName)"
Write-Host "SecurableName: $($newServerPermission.SecurableName)"
Write-Host "ContradictionType: $($newServerPermission.ContradictionType)"
Write-Host "RiskLevel: $($newServerPermission.RiskLevel)"
Write-Host "Impact: $($newServerPermission.Impact)"
Write-Host "RecommendedAction: $($newServerPermission.RecommendedAction)"

Write-Host "`n=== Tests de la classe SqlDatabaseContradictoryPermission ==="
Write-Host "=========================================================="

# Créer une instance de SqlDatabaseContradictoryPermission
Write-Host "Création d'une instance de SqlDatabaseContradictoryPermission..."
$dbPermission = [SqlDatabaseContradictoryPermission]::new("SELECT", "TestUser", "TestDB")

# Vérifier que l'instance a été créée correctement
Write-Host "Vérification des propriétés de l'instance..."
Write-Host "PermissionName: $($dbPermission.PermissionName)"
Write-Host "UserName: $($dbPermission.UserName)"
Write-Host "DatabaseName: $($dbPermission.DatabaseName)"
Write-Host "SecurableType: $($dbPermission.SecurableType)"
Write-Host "SecurableName: $($dbPermission.SecurableName)"
Write-Host "ContradictionType: $($dbPermission.ContradictionType)"
Write-Host "RiskLevel: $($dbPermission.RiskLevel)"

# Tester la méthode ToString
Write-Host "`nTest de la méthode ToString()..."
$toString = $dbPermission.ToString()
Write-Host "ToString(): $toString"

# Tester la méthode GenerateFixScript
Write-Host "`nTest de la méthode GenerateFixScript()..."
$script = $dbPermission.GenerateFixScript()
Write-Host "Script de résolution généré:"
Write-Host $script

# Tester la méthode GetDetailedDescription
Write-Host "`nTest de la méthode GetDetailedDescription()..."
$dbPermission.LoginName = "TestLogin"
$dbPermission.Impact = "Accès incohérent aux données"
$dbPermission.RecommendedAction = "Supprimer la permission DENY"
$description = $dbPermission.GetDetailedDescription()
Write-Host "Description détaillée:"
Write-Host $description

# Tester la fonction New-SqlDatabaseContradictoryPermission
Write-Host "`nTest de la fonction New-SqlDatabaseContradictoryPermission..."
$newDbPermission = New-SqlDatabaseContradictoryPermission `
    -PermissionName "UPDATE" `
    -UserName "AppUser" `
    -DatabaseName "AppDB" `
    -ContradictionType "Héritage" `
    -ModelName "SecurityModel" `
    -RiskLevel "Critique" `
    -LoginName "AppLogin" `
    -Impact "Risque de sécurité élevé" `
    -RecommendedAction "Vérifier les rôles de l'utilisateur"

# Vérifier que l'instance a été créée correctement
Write-Host "Vérification des propriétés de l'instance créée avec New-SqlDatabaseContradictoryPermission..."
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

# Créer une instance de SqlObjectContradictoryPermission
Write-Host "Création d'une instance de SqlObjectContradictoryPermission..."
$objPermission = [SqlObjectContradictoryPermission]::new("SELECT", "TestUser", "TestDB", "TestTable")

# Vérifier que l'instance a été créée correctement
Write-Host "Vérification des propriétés de l'instance..."
Write-Host "PermissionName: $($objPermission.PermissionName)"
Write-Host "UserName: $($objPermission.UserName)"
Write-Host "DatabaseName: $($objPermission.DatabaseName)"
Write-Host "ObjectName: $($objPermission.ObjectName)"
Write-Host "SecurableType: $($objPermission.SecurableType)"
Write-Host "SecurableName: $($objPermission.SecurableName)"
Write-Host "ContradictionType: $($objPermission.ContradictionType)"
Write-Host "RiskLevel: $($objPermission.RiskLevel)"

# Tester la méthode ToString
Write-Host "`nTest de la méthode ToString()..."
$objPermission.SchemaName = "dbo"
$toString = $objPermission.ToString()
Write-Host "ToString(): $toString"

# Tester la méthode GenerateFixScript
Write-Host "`nTest de la méthode GenerateFixScript()..."
$script = $objPermission.GenerateFixScript()
Write-Host "Script de résolution généré:"
Write-Host $script

# Tester la méthode GenerateFixScript avec colonne
Write-Host "`nTest de la méthode GenerateFixScript() avec colonne..."
$objPermission.ColumnName = "ID"
$script = $objPermission.GenerateFixScript()
Write-Host "Script de résolution généré avec colonne:"
Write-Host $script

# Tester la méthode GetDetailedDescription
Write-Host "`nTest de la méthode GetDetailedDescription()..."
$objPermission.ObjectType = "TABLE"
$objPermission.LoginName = "TestLogin"
$objPermission.Impact = "Accès incohérent aux données de la table"
$objPermission.RecommendedAction = "Supprimer la permission DENY"
$description = $objPermission.GetDetailedDescription()
Write-Host "Description détaillée:"
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
    -ContradictionType "Héritage" `
    -ModelName "SecurityModel" `
    -RiskLevel "Critique" `
    -LoginName "AppLogin" `
    -Impact "Risque de sécurité élevé" `
    -RecommendedAction "Vérifier les rôles de l'utilisateur"

# Vérifier que l'instance a été créée correctement
Write-Host "Vérification des propriétés de l'instance créée avec New-SqlObjectContradictoryPermission..."
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

# Créer une instance de SqlContradictoryPermissionsSet
Write-Host "Création d'une instance de SqlContradictoryPermissionsSet..."
$permissionsSet = [SqlContradictoryPermissionsSet]::new("TestServer", "TestModel")

# Vérifier que l'instance a été créée correctement
Write-Host "Vérification des propriétés de l'instance..."
Write-Host "ServerName: $($permissionsSet.ServerName)"
Write-Host "ModelName: $($permissionsSet.ModelName)"
Write-Host "AnalysisDate: $($permissionsSet.AnalysisDate)"
Write-Host "AnalysisUser: $($permissionsSet.AnalysisUser)"
Write-Host "TotalContradictions: $($permissionsSet.TotalContradictions)"

# Ajouter des contradictions
Write-Host "`nAjout de contradictions à l'ensemble..."
$permissionsSet.AddServerContradiction($serverPermission)
$permissionsSet.AddDatabaseContradiction($dbPermission)
$permissionsSet.AddObjectContradiction($objPermission)

# Vérifier que les contradictions ont été ajoutées
Write-Host "Vérification des contradictions ajoutées..."
Write-Host "Nombre total de contradictions: $($permissionsSet.TotalContradictions)"
Write-Host "Contradictions au niveau serveur: $($permissionsSet.ServerContradictions.Count)"
Write-Host "Contradictions au niveau base de données: $($permissionsSet.DatabaseContradictions.Count)"
Write-Host "Contradictions au niveau objet: $($permissionsSet.ObjectContradictions.Count)"

# Tester la méthode GetAllContradictions
Write-Host "`nTest de la méthode GetAllContradictions()..."
$allContradictions = $permissionsSet.GetAllContradictions()
Write-Host "Nombre total de contradictions récupérées: $($allContradictions.Count)"

# Tester la méthode FilterByRiskLevel
Write-Host "`nTest de la méthode FilterByRiskLevel()..."
$moyenContradictions = $permissionsSet.FilterByRiskLevel("Moyen")
Write-Host "Nombre de contradictions de niveau Moyen: $($moyenContradictions.Count)"

# Tester la méthode FilterByType
Write-Host "`nTest de la méthode FilterByType()..."
$grantDenyContradictions = $permissionsSet.FilterByType("GRANT/DENY")
Write-Host "Nombre de contradictions de type GRANT/DENY: $($grantDenyContradictions.Count)"

# Tester la méthode FilterByUser
Write-Host "`nTest de la méthode FilterByUser()..."
$testUserContradictions = $permissionsSet.FilterByUser("TestUser")
Write-Host "Nombre de contradictions pour l'utilisateur TestUser: $($testUserContradictions.Count)"

# Tester la méthode GenerateSummaryReport
Write-Host "`nTest de la méthode GenerateSummaryReport()..."
$summaryReport = $permissionsSet.GenerateSummaryReport()
Write-Host "Rapport de synthèse généré avec succès."

# Tester la méthode GenerateDetailedReport
Write-Host "`nTest de la méthode GenerateDetailedReport()..."
$detailedReport = $permissionsSet.GenerateDetailedReport()
Write-Host "Rapport détaillé généré avec succès."

# Tester la méthode GenerateFixScript
Write-Host "`nTest de la méthode GenerateFixScript()..."
$fixScript = $permissionsSet.GenerateFixScript()
Write-Host "Script de résolution généré avec succès."

# Tester la méthode ToString
Write-Host "`nTest de la méthode ToString()..."
$toString = $permissionsSet.ToString()
Write-Host "ToString(): $toString"

# Tester la fonction New-SqlContradictoryPermissionsSet
Write-Host "`nTest de la fonction New-SqlContradictoryPermissionsSet..."
$newPermissionsSet = New-SqlContradictoryPermissionsSet `
    -ServerName "ProdServer" `
    -ModelName "ProductionModel" `
    -Description "Test description" `
    -ReportTitle "Test report title"

# Vérifier que l'instance a été créée correctement
Write-Host "Vérification des propriétés de l'instance créée avec New-SqlContradictoryPermissionsSet..."
Write-Host "ServerName: $($newPermissionsSet.ServerName)"
Write-Host "ModelName: $($newPermissionsSet.ModelName)"
Write-Host "Description: $($newPermissionsSet.Description)"
Write-Host "ReportTitle: $($newPermissionsSet.ReportTitle)"

Write-Host "`nTous les tests terminés avec succès!"
