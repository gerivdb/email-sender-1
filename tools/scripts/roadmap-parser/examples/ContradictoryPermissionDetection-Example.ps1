# ContradictoryPermissionDetection-Example.ps1
# Exemple d'utilisation des fonctions de détection des permissions contradictoires

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\RoadmapParser.psm1"
if (Test-Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Warning "Le module RoadmapParser.psm1 n'a pas été trouvé à l'emplacement: $modulePath"
}

# Charger le modèle de permissions contradictoires
$contradictoryPermissionModelPath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\Functions\Private\SqlPermissionModels\ContradictoryPermissionModel.ps1"
if (Test-Path $contradictoryPermissionModelPath) {
    . $contradictoryPermissionModelPath
} else {
    Write-Warning "Le fichier ContradictoryPermissionModel.ps1 n'a pas été trouvé à l'emplacement: $contradictoryPermissionModelPath"
}

# Charger directement le fichier de détection des permissions contradictoires pour l'exemple
$contradictoryPermissionDetectionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\Functions\Private\SqlPermissionModels\ContradictoryPermissionDetection.ps1"
if (Test-Path $contradictoryPermissionDetectionPath) {
    . $contradictoryPermissionDetectionPath
} else {
    Write-Warning "Le fichier ContradictoryPermissionDetection.ps1 n'a pas été trouvé à l'emplacement: $contradictoryPermissionDetectionPath"
}

# Définir les paramètres de connexion à SQL Server
$serverInstance = "localhost"  # Remplacer par le nom de votre instance SQL Server
$databaseName = "AdventureWorks"  # Remplacer par le nom de votre base de données

# Exemple 1: Détecter les permissions contradictoires au niveau serveur
Write-Host "Exemple 1: Détection des permissions contradictoires au niveau serveur"
Write-Host "---------------------------------------------------------------"
Write-Host "Note: Cet exemple nécessite une connexion à SQL Server. Si vous n'avez pas de serveur SQL disponible,"
Write-Host "      vous pouvez utiliser les exemples avec des données simulées plus bas."
Write-Host ""
Write-Host "Pour exécuter cet exemple avec une connexion SQL Server réelle, décommentez les lignes suivantes:"
Write-Host ""
Write-Host "# `$serverContradictions = Find-SqlServerContradictoryPermission -ServerInstance `"$serverInstance`""
Write-Host "# Write-Host `"Nombre de contradictions détectées au niveau serveur: `$(`$serverContradictions.Count)`""
Write-Host "# foreach (`$contradiction in `$serverContradictions) {"
Write-Host "#     Write-Host `"- `$(`$contradiction.ToString())`""
Write-Host "# }"
Write-Host ""

# Exemple 2: Détecter les permissions contradictoires au niveau base de données
Write-Host "Exemple 2: Détection des permissions contradictoires au niveau base de données"
Write-Host "-----------------------------------------------------------------"
Write-Host "Pour exécuter cet exemple avec une connexion SQL Server réelle, décommentez les lignes suivantes:"
Write-Host ""
Write-Host "# `$dbContradictions = Find-SqlDatabaseContradictoryPermission -ServerInstance `"$serverInstance`" -Database `"$databaseName`""
Write-Host "# Write-Host `"Nombre de contradictions détectées au niveau base de données: `$(`$dbContradictions.Count)`""
Write-Host "# foreach (`$contradiction in `$dbContradictions) {"
Write-Host "#     Write-Host `"- `$(`$contradiction.ToString())`""
Write-Host "# }"
Write-Host ""

# Exemple 3: Détecter les permissions contradictoires au niveau objet
Write-Host "Exemple 3: Détection des permissions contradictoires au niveau objet"
Write-Host "------------------------------------------------------------"
Write-Host "Pour exécuter cet exemple avec une connexion SQL Server réelle, décommentez les lignes suivantes:"
Write-Host ""
Write-Host "# `$objContradictions = Find-SqlObjectContradictoryPermission -ServerInstance `"$serverInstance`" -Database `"$databaseName`""
Write-Host "# Write-Host `"Nombre de contradictions détectées au niveau objet: `$(`$objContradictions.Count)`""
Write-Host "# foreach (`$contradiction in `$objContradictions) {"
Write-Host "#     Write-Host `"- `$(`$contradiction.ToString())`""
Write-Host "# }"
Write-Host ""

# Exemple 4: Détecter toutes les permissions contradictoires
Write-Host "Exemple 4: Détection de toutes les permissions contradictoires"
Write-Host "--------------------------------------------------------"
Write-Host "Pour exécuter cet exemple avec une connexion SQL Server réelle, décommentez les lignes suivantes:"
Write-Host ""
Write-Host "# `$contradictionsSet = Find-SqlContradictoryPermission -ServerInstance `"$serverInstance`" -Database `"$databaseName`""
Write-Host "# Write-Host `"Nombre total de contradictions détectées: `$(`$contradictionsSet.TotalContradictions)`""
Write-Host "# Write-Host `"Contradictions au niveau serveur: `$(`$contradictionsSet.ServerContradictions.Count)`""
Write-Host "# Write-Host `"Contradictions au niveau base de données: `$(`$contradictionsSet.DatabaseContradictions.Count)`""
Write-Host "# Write-Host `"Contradictions au niveau objet: `$(`$contradictionsSet.ObjectContradictions.Count)`""
Write-Host "# "
Write-Host "# Write-Host `"`nRapport de synthèse:`""
Write-Host "# Write-Host `$contradictionsSet.GenerateSummaryReport()"
Write-Host "# "
Write-Host "# Write-Host `"`nScript de résolution:`""
Write-Host "# Write-Host `$contradictionsSet.GenerateFixScript()"
Write-Host ""

# Exemple 5: Utilisation avec des données simulées
Write-Host "Exemple 5: Utilisation avec des données simulées"
Write-Host "-------------------------------------------"

# Créer des données de test pour les permissions au niveau serveur
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

# Détecter les contradictions avec les données simulées
$serverContradictions = Find-SqlServerContradictoryPermission -PermissionsData $serverPermissionsData -ModelName "TestModel"
Write-Host "Nombre de contradictions détectées au niveau serveur (données simulées): $($serverContradictions.Count)"
foreach ($contradiction in $serverContradictions) {
    Write-Host "- $($contradiction.ToString())"
}

# Créer des données de test pour les permissions au niveau base de données
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

# Détecter les contradictions avec les données simulées
$dbContradictions = Find-SqlDatabaseContradictoryPermission -PermissionsData $dbPermissionsData -ModelName "TestModel"
Write-Host "`nNombre de contradictions détectées au niveau base de données (données simulées): $($dbContradictions.Count)"
foreach ($contradiction in $dbContradictions) {
    Write-Host "- $($contradiction.ToString())"
}

# Créer des données de test pour les permissions au niveau objet
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

# Détecter les contradictions avec les données simulées
$objContradictions = Find-SqlObjectContradictoryPermission -PermissionsData $objPermissionsData -ModelName "TestModel"
Write-Host "`nNombre de contradictions détectées au niveau objet (données simulées): $($objContradictions.Count)"
foreach ($contradiction in $objContradictions) {
    Write-Host "- $($contradiction.ToString())"
}

# Créer un ensemble de permissions contradictoires
$contradictionsSet = New-SqlContradictoryPermissionsSet -ServerName "TestServer" -ModelName "TestModel"

# Ajouter les contradictions à l'ensemble
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
Write-Host "`nEnsemble de permissions contradictoires (données simulées):"
Write-Host "Nombre total de contradictions: $($contradictionsSet.TotalContradictions)"
Write-Host "Contradictions au niveau serveur: $($contradictionsSet.ServerContradictions.Count)"
Write-Host "Contradictions au niveau base de données: $($contradictionsSet.DatabaseContradictions.Count)"
Write-Host "Contradictions au niveau objet: $($contradictionsSet.ObjectContradictions.Count)"

# Générer un rapport de synthèse
Write-Host "`nRapport de synthèse:"
Write-Host $contradictionsSet.GenerateSummaryReport()

# Générer un script de résolution
Write-Host "`nScript de résolution:"
Write-Host $contradictionsSet.GenerateFixScript()
