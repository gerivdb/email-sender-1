# ContradictoryPermissionDetection-Example.ps1
# Exemple d'utilisation des fonctions de dÃ©tection des permissions contradictoires

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\RoadmapParser.psm1"
if (Test-Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Warning "Le module RoadmapParser.psm1 n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement: $modulePath"
}

# Charger le modÃ¨le de permissions contradictoires
$contradictoryPermissionModelPath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\Functions\Private\SqlPermissionModels\ContradictoryPermissionModel.ps1"
if (Test-Path $contradictoryPermissionModelPath) {
    . $contradictoryPermissionModelPath
} else {
    Write-Warning "Le fichier ContradictoryPermissionModel.ps1 n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement: $contradictoryPermissionModelPath"
}

# Charger directement le fichier de dÃ©tection des permissions contradictoires pour l'exemple
$contradictoryPermissionDetectionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\Functions\Private\SqlPermissionModels\ContradictoryPermissionDetection.ps1"
if (Test-Path $contradictoryPermissionDetectionPath) {
    . $contradictoryPermissionDetectionPath
} else {
    Write-Warning "Le fichier ContradictoryPermissionDetection.ps1 n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement: $contradictoryPermissionDetectionPath"
}

# DÃ©finir les paramÃ¨tres de connexion Ã  SQL Server
$serverInstance = "localhost"  # Remplacer par le nom de votre instance SQL Server
$databaseName = "AdventureWorks"  # Remplacer par le nom de votre base de donnÃ©es

# Exemple 1: DÃ©tecter les permissions contradictoires au niveau serveur
Write-Host "Exemple 1: DÃ©tection des permissions contradictoires au niveau serveur"
Write-Host "---------------------------------------------------------------"
Write-Host "Note: Cet exemple nÃ©cessite une connexion Ã  SQL Server. Si vous n'avez pas de serveur SQL disponible,"
Write-Host "      vous pouvez utiliser les exemples avec des donnÃ©es simulÃ©es plus bas."
Write-Host ""
Write-Host "Pour exÃ©cuter cet exemple avec une connexion SQL Server rÃ©elle, dÃ©commentez les lignes suivantes:"
Write-Host ""
Write-Host "# `$serverContradictions = Find-SqlServerContradictoryPermission -ServerInstance `"$serverInstance`""
Write-Host "# Write-Host `"Nombre de contradictions dÃ©tectÃ©es au niveau serveur: `$(`$serverContradictions.Count)`""
Write-Host "# foreach (`$contradiction in `$serverContradictions) {"
Write-Host "#     Write-Host `"- `$(`$contradiction.ToString())`""
Write-Host "# }"
Write-Host ""

# Exemple 2: DÃ©tecter les permissions contradictoires au niveau base de donnÃ©es
Write-Host "Exemple 2: DÃ©tection des permissions contradictoires au niveau base de donnÃ©es"
Write-Host "-----------------------------------------------------------------"
Write-Host "Pour exÃ©cuter cet exemple avec une connexion SQL Server rÃ©elle, dÃ©commentez les lignes suivantes:"
Write-Host ""
Write-Host "# `$dbContradictions = Find-SqlDatabaseContradictoryPermission -ServerInstance `"$serverInstance`" -Database `"$databaseName`""
Write-Host "# Write-Host `"Nombre de contradictions dÃ©tectÃ©es au niveau base de donnÃ©es: `$(`$dbContradictions.Count)`""
Write-Host "# foreach (`$contradiction in `$dbContradictions) {"
Write-Host "#     Write-Host `"- `$(`$contradiction.ToString())`""
Write-Host "# }"
Write-Host ""

# Exemple 3: DÃ©tecter les permissions contradictoires au niveau objet
Write-Host "Exemple 3: DÃ©tection des permissions contradictoires au niveau objet"
Write-Host "------------------------------------------------------------"
Write-Host "Pour exÃ©cuter cet exemple avec une connexion SQL Server rÃ©elle, dÃ©commentez les lignes suivantes:"
Write-Host ""
Write-Host "# `$objContradictions = Find-SqlObjectContradictoryPermission -ServerInstance `"$serverInstance`" -Database `"$databaseName`""
Write-Host "# Write-Host `"Nombre de contradictions dÃ©tectÃ©es au niveau objet: `$(`$objContradictions.Count)`""
Write-Host "# foreach (`$contradiction in `$objContradictions) {"
Write-Host "#     Write-Host `"- `$(`$contradiction.ToString())`""
Write-Host "# }"
Write-Host ""

# Exemple 4: DÃ©tecter toutes les permissions contradictoires
Write-Host "Exemple 4: DÃ©tection de toutes les permissions contradictoires"
Write-Host "--------------------------------------------------------"
Write-Host "Pour exÃ©cuter cet exemple avec une connexion SQL Server rÃ©elle, dÃ©commentez les lignes suivantes:"
Write-Host ""
Write-Host "# `$contradictionsSet = Find-SqlContradictoryPermission -ServerInstance `"$serverInstance`" -Database `"$databaseName`""
Write-Host "# Write-Host `"Nombre total de contradictions dÃ©tectÃ©es: `$(`$contradictionsSet.TotalContradictions)`""
Write-Host "# Write-Host `"Contradictions au niveau serveur: `$(`$contradictionsSet.ServerContradictions.Count)`""
Write-Host "# Write-Host `"Contradictions au niveau base de donnÃ©es: `$(`$contradictionsSet.DatabaseContradictions.Count)`""
Write-Host "# Write-Host `"Contradictions au niveau objet: `$(`$contradictionsSet.ObjectContradictions.Count)`""
Write-Host "# "
Write-Host "# Write-Host `"`nRapport de synthÃ¨se:`""
Write-Host "# Write-Host `$contradictionsSet.GenerateSummaryReport()"
Write-Host "# "
Write-Host "# Write-Host `"`nScript de rÃ©solution:`""
Write-Host "# Write-Host `$contradictionsSet.GenerateFixScript()"
Write-Host ""

# Exemple 5: Utilisation avec des donnÃ©es simulÃ©es
Write-Host "Exemple 5: Utilisation avec des donnÃ©es simulÃ©es"
Write-Host "-------------------------------------------"

# CrÃ©er des donnÃ©es de test pour les permissions au niveau serveur
$serverPermissionsData = @(
    # Permissions sans contradiction
    [PSCustomObject]@{
        LoginName      = "Login1"
        ClassDesc      = "SERVER"
        PermissionName = "CONNECT SQL"
        StateDesc      = "GRANT"
        SecurableType  = "SERVER"
        SecurableName  = "TestServer"
    },
    # Permissions avec contradiction
    [PSCustomObject]@{
        LoginName      = "Login3"
        ClassDesc      = "SERVER"
        PermissionName = "VIEW SERVER STATE"
        StateDesc      = "GRANT"
        SecurableType  = "SERVER"
        SecurableName  = "TestServer"
    },
    [PSCustomObject]@{
        LoginName      = "Login3"
        ClassDesc      = "SERVER"
        PermissionName = "VIEW SERVER STATE"
        StateDesc      = "DENY"
        SecurableType  = "SERVER"
        SecurableName  = "TestServer"
    }
)

# DÃ©tecter les contradictions avec les donnÃ©es simulÃ©es
$serverContradictions = Find-SqlServerContradictoryPermission -PermissionsData $serverPermissionsData -ModelName "TestModel"
Write-Host "Nombre de contradictions dÃ©tectÃ©es au niveau serveur (donnÃ©es simulÃ©es): $($serverContradictions.Count)"
foreach ($contradiction in $serverContradictions) {
    Write-Host "- $($contradiction.ToString())"
}

# CrÃ©er des donnÃ©es de test pour les permissions au niveau base de donnÃ©es
$dbPermissionsData = @(
    # Permissions sans contradiction
    [PSCustomObject]@{
        UserName       = "User1"
        ClassDesc      = "DATABASE"
        PermissionName = "SELECT"
        StateDesc      = "GRANT"
        SecurableType  = "DATABASE"
        SecurableName  = "TestDB"
        LoginName      = "Login1"
    },
    # Permissions avec contradiction
    [PSCustomObject]@{
        UserName       = "User3"
        ClassDesc      = "DATABASE"
        PermissionName = "CREATE TABLE"
        StateDesc      = "GRANT"
        SecurableType  = "DATABASE"
        SecurableName  = "TestDB"
        LoginName      = "Login3"
    },
    [PSCustomObject]@{
        UserName       = "User3"
        ClassDesc      = "DATABASE"
        PermissionName = "CREATE TABLE"
        StateDesc      = "DENY"
        SecurableType  = "DATABASE"
        SecurableName  = "TestDB"
        LoginName      = "Login3"
    }
)

# DÃ©tecter les contradictions avec les donnÃ©es simulÃ©es
$dbContradictions = Find-SqlDatabaseContradictoryPermission -PermissionsData $dbPermissionsData -ModelName "TestModel"
Write-Host "`nNombre de contradictions dÃ©tectÃ©es au niveau base de donnÃ©es (donnÃ©es simulÃ©es): $($dbContradictions.Count)"
foreach ($contradiction in $dbContradictions) {
    Write-Host "- $($contradiction.ToString())"
}

# CrÃ©er des donnÃ©es de test pour les permissions au niveau objet
$objPermissionsData = @(
    # Permissions sans contradiction
    [PSCustomObject]@{
        UserName       = "User1"
        ClassDesc      = "OBJECT_OR_COLUMN"
        PermissionName = "SELECT"
        StateDesc      = "GRANT"
        SecurableType  = "OBJECT"
        SchemaName     = "dbo"
        ObjectName     = "Table1"
        ObjectType     = "TABLE"
        ColumnName     = $null
        LoginName      = "Login1"
        DatabaseName   = "TestDB"
    },
    # Permissions avec contradiction
    [PSCustomObject]@{
        UserName       = "User3"
        ClassDesc      = "OBJECT_OR_COLUMN"
        PermissionName = "SELECT"
        StateDesc      = "GRANT"
        SecurableType  = "OBJECT"
        SchemaName     = "dbo"
        ObjectName     = "Table3"
        ObjectType     = "TABLE"
        ColumnName     = $null
        LoginName      = "Login3"
        DatabaseName   = "TestDB"
    },
    [PSCustomObject]@{
        UserName       = "User3"
        ClassDesc      = "OBJECT_OR_COLUMN"
        PermissionName = "SELECT"
        StateDesc      = "DENY"
        SecurableType  = "OBJECT"
        SchemaName     = "dbo"
        ObjectName     = "Table3"
        ObjectType     = "TABLE"
        ColumnName     = $null
        LoginName      = "Login3"
        DatabaseName   = "TestDB"
    }
)

# DÃ©tecter les contradictions avec les donnÃ©es simulÃ©es
$objContradictions = Find-SqlObjectContradictoryPermission -PermissionsData $objPermissionsData -ModelName "TestModel"
Write-Host "`nNombre de contradictions dÃ©tectÃ©es au niveau objet (donnÃ©es simulÃ©es): $($objContradictions.Count)"
foreach ($contradiction in $objContradictions) {
    Write-Host "- $($contradiction.ToString())"
}

# CrÃ©er un ensemble de permissions contradictoires
$contradictionsSet = New-SqlContradictoryPermissionsSet -ServerName "TestServer" -ModelName "TestModel"

# Ajouter les contradictions Ã  l'ensemble
foreach ($contradiction in $serverContradictions) {
    $contradictionsSet.AddServerContradiction($contradiction)
}

foreach ($contradiction in $dbContradictions) {
    $contradictionsSet.AddDatabaseContradiction($contradiction)
}

foreach ($contradiction in $objContradictions) {
    $contradictionsSet.AddObjectContradiction($contradiction)
}

# Afficher les informations sur l'ensemble de contradictions
Write-Host "`nEnsemble de permissions contradictoires (donnÃ©es simulÃ©es):"
Write-Host "Nombre total de contradictions: $($contradictionsSet.TotalContradictions)"
Write-Host "Contradictions au niveau serveur: $($contradictionsSet.ServerContradictions.Count)"
Write-Host "Contradictions au niveau base de donnÃ©es: $($contradictionsSet.DatabaseContradictions.Count)"
Write-Host "Contradictions au niveau objet: $($contradictionsSet.ObjectContradictions.Count)"

# GÃ©nÃ©rer un rapport de synthÃ¨se
Write-Host "`nRapport de synthÃ¨se:"
Write-Host $contradictionsSet.GenerateSummaryReport()

# GÃ©nÃ©rer un script de rÃ©solution
Write-Host "`nScript de rÃ©solution:"
Write-Host $contradictionsSet.GenerateFixScript()

# Exemple de gÃ©nÃ©ration de scripts de rÃ©solution pour diffÃ©rents types de contradictions
Write-Host "`n`nExemples de scripts de rÃ©solution pour diffÃ©rents types de contradictions:" -ForegroundColor Green

# Contradiction de type GRANT/DENY au niveau serveur
Write-Host "`nScript de rÃ©solution pour une contradiction GRANT/DENY au niveau serveur:" -ForegroundColor Cyan
if ($serverContradictions.Count -gt 0) {
    $serverContradiction = $serverContradictions[0]
    $serverContradiction.RiskLevel = "Ã‰levÃ©"
    $serverContradiction.Impact = "L'utilisateur peut avoir des problÃ¨mes d'accÃ¨s intermittents au serveur"
    $serverContradiction.RecommendedAction = "RÃ©soudre la contradiction en supprimant soit GRANT soit DENY"
    Write-Host $serverContradiction.GenerateFixScript()
} else {
    $serverContradiction = [SqlServerContradictoryPermission]::new("VIEW SERVER STATE", "TestLogin")
    $serverContradiction.ContradictionType = "GRANT/DENY"
    $serverContradiction.RiskLevel = "Ã‰levÃ©"
    $serverContradiction.Impact = "L'utilisateur peut avoir des problÃ¨mes d'accÃ¨s intermittents au serveur"
    $serverContradiction.RecommendedAction = "RÃ©soudre la contradiction en supprimant soit GRANT soit DENY"
    Write-Host $serverContradiction.GenerateFixScript()
}

# Contradiction de type HÃ©ritage
Write-Host "`nScript de rÃ©solution pour une contradiction de type HÃ©ritage:" -ForegroundColor Cyan
$inheritanceContradiction = [SqlServerContradictoryPermission]::new("CONNECT SQL", "TestLogin")
$inheritanceContradiction.ContradictionType = "HÃ©ritage"
$inheritanceContradiction.RiskLevel = "Moyen"
$inheritanceContradiction.Impact = "L'utilisateur peut avoir des permissions contradictoires via l'hÃ©ritage de rÃ´les"
$inheritanceContradiction.RecommendedAction = "VÃ©rifier les rÃ´les du login et ajuster les permissions"
Write-Host $inheritanceContradiction.GenerateFixScript()

# Contradiction de type RÃ´le/Utilisateur
Write-Host "`nScript de rÃ©solution pour une contradiction de type RÃ´le/Utilisateur:" -ForegroundColor Cyan
$roleUserContradiction = [SqlDatabaseContradictoryPermission]::new("SELECT", "TestUser", "TestDB")
$roleUserContradiction.ContradictionType = "RÃ´le/Utilisateur"
$roleUserContradiction.RiskLevel = "Ã‰levÃ©"
$roleUserContradiction.Impact = "L'utilisateur a des permissions directes qui contredisent celles hÃ©ritÃ©es des rÃ´les"
$roleUserContradiction.RecommendedAction = "RÃ©soudre la contradiction en ajustant les permissions directes ou l'appartenance aux rÃ´les"
Write-Host $roleUserContradiction.GenerateFixScript()
