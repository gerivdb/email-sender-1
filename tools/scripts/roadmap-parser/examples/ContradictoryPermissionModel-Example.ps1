# ContradictoryPermissionModel-Example.ps1
# Exemple d'utilisation de la structure de données pour les permissions contradictoires

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\RoadmapParser.psm1"
Import-Module $modulePath -Force

# Charger directement le fichier de modèle de permissions contradictoires pour l'exemple
$contradictoryPermissionModelPath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\Functions\Private\SqlPermissionModels\ContradictoryPermissionModel.ps1"
. $contradictoryPermissionModelPath

# Créer une permission contradictoire au niveau serveur
$serverContradiction = New-SqlServerContradictoryPermission `
    -PermissionName "CONNECT SQL" `
    -LoginName "AppUser" `
    -SecurableName "SQLSERVER01" `
    -ContradictionType "GRANT/DENY" `
    -ModelName "ProductionSecurityModel" `
    -RiskLevel "Élevé" `
    -Impact "L'utilisateur peut avoir des problèmes de connexion intermittents" `
    -RecommendedAction "Supprimer la permission DENY et conserver GRANT"

# Afficher les informations de la permission contradictoire au niveau serveur
Write-Host "Permission contradictoire au niveau serveur:"
Write-Host "----------------------------------------"
Write-Host $serverContradiction.ToString()
Write-Host ""
Write-Host "Description détaillée:"
Write-Host $serverContradiction.GetDetailedDescription()
Write-Host ""
Write-Host "Script de résolution:"
Write-Host "--------------------"
Write-Host $serverContradiction.GenerateFixScript()

# Créer une permission contradictoire au niveau base de données
$databaseContradiction = New-SqlDatabaseContradictoryPermission `
    -PermissionName "SELECT" `
    -UserName "AppUser" `
    -DatabaseName "AppDB" `
    -ContradictionType "GRANT/DENY" `
    -ModelName "ProductionSecurityModel" `
    -RiskLevel "Moyen" `
    -LoginName "AppLogin" `
    -Impact "L'utilisateur peut avoir des problèmes d'accès aux données" `
    -RecommendedAction "Supprimer la permission DENY et conserver GRANT"

# Afficher les informations de la permission contradictoire au niveau base de données
Write-Host "`nPermission contradictoire au niveau base de données:"
Write-Host "------------------------------------------------"
Write-Host $databaseContradiction.ToString()
Write-Host ""
Write-Host "Description détaillée:"
Write-Host $databaseContradiction.GetDetailedDescription()
Write-Host ""
Write-Host "Script de résolution:"
Write-Host "--------------------"
Write-Host $databaseContradiction.GenerateFixScript()

# Créer une permission contradictoire au niveau objet
$objectContradiction = New-SqlObjectContradictoryPermission `
    -PermissionName "UPDATE" `
    -UserName "AppUser" `
    -DatabaseName "AppDB" `
    -SchemaName "dbo" `
    -ObjectName "Customers" `
    -ObjectType "TABLE" `
    -ColumnName "CustomerID" `
    -ContradictionType "GRANT/DENY" `
    -ModelName "ProductionSecurityModel" `
    -RiskLevel "Critique" `
    -LoginName "AppLogin" `
    -Impact "L'utilisateur peut avoir des problèmes de mise à jour des données clients" `
    -RecommendedAction "Supprimer la permission DENY et conserver GRANT"

# Afficher les informations de la permission contradictoire au niveau objet
Write-Host "`nPermission contradictoire au niveau objet:"
Write-Host "----------------------------------------"
Write-Host $objectContradiction.ToString()
Write-Host ""
Write-Host "Description détaillée:"
Write-Host $objectContradiction.GetDetailedDescription()
Write-Host ""
Write-Host "Script de résolution:"
Write-Host "--------------------"
Write-Host $objectContradiction.GenerateFixScript()

# Exemple d'utilisation dans un scénario de détection
Write-Host "`nExemple de scénario de détection de contradictions:"
Write-Host "------------------------------------------------"
Write-Host "1. Récupérer les permissions actuelles du serveur SQL, des bases de données et des objets"
Write-Host "2. Analyser les permissions pour détecter les contradictions GRANT/DENY"
Write-Host "3. Créer des objets SqlServerContradictoryPermission, SqlDatabaseContradictoryPermission et SqlObjectContradictoryPermission pour chaque contradiction"
Write-Host "4. Générer des rapports et des scripts de résolution"
Write-Host ""

# Exemple de code pour détecter les contradictions au niveau serveur (pseudo-code)
Write-Host "Pseudo-code pour la détection des contradictions au niveau serveur:"
Write-Host "```powershell"
Write-Host "# Récupérer les permissions du serveur"
Write-Host '$serverPermissions = Get-SqlServerPermission -ServerInstance "SQLSERVER01"'
Write-Host ""
Write-Host "# Détecter les contradictions GRANT/DENY"
Write-Host 'foreach ($login in $serverPermissions.Logins) {'
Write-Host '    $permissionNames = $login.Permissions | Select-Object -ExpandProperty PermissionName -Unique'
Write-Host '    foreach ($permName in $permissionNames) {'
Write-Host '        $grantedPerm = $login.Permissions | Where-Object { $_.PermissionName -eq $permName -and $_.PermissionState -eq "GRANT" }'
Write-Host '        $deniedPerm = $login.Permissions | Where-Object { $_.PermissionName -eq $permName -and $_.PermissionState -eq "DENY" }'
Write-Host '        if ($grantedPerm -and $deniedPerm) {'
Write-Host '            # Créer un objet SqlServerContradictoryPermission'
Write-Host '            $contradiction = New-SqlServerContradictoryPermission -PermissionName $permName -LoginName $login.Name'
Write-Host '            # Ajouter à la liste des contradictions'
Write-Host '            $contradictions.Add($contradiction)'
Write-Host '        }'
Write-Host '    }'
Write-Host '}'
Write-Host "```"

# Exemple de code pour détecter les contradictions au niveau base de données (pseudo-code)
Write-Host "`nPseudo-code pour la détection des contradictions au niveau base de données:"
Write-Host "```powershell"
Write-Host "# Récupérer les permissions des bases de données"
Write-Host 'foreach ($database in Get-SqlDatabase -ServerInstance "SQLSERVER01") {'
Write-Host '    $databasePermissions = Get-SqlDatabasePermission -ServerInstance "SQLSERVER01" -Database $database.Name'
Write-Host ''
Write-Host '    # Détecter les contradictions GRANT/DENY'
Write-Host '    foreach ($user in $databasePermissions.Users) {'
Write-Host '        $permissionNames = $user.Permissions | Select-Object -ExpandProperty PermissionName -Unique'
Write-Host '        foreach ($permName in $permissionNames) {'
Write-Host '            $grantedPerm = $user.Permissions | Where-Object { $_.PermissionName -eq $permName -and $_.PermissionState -eq "GRANT" }'
Write-Host '            $deniedPerm = $user.Permissions | Where-Object { $_.PermissionName -eq $permName -and $_.PermissionState -eq "DENY" }'
Write-Host '            if ($grantedPerm -and $deniedPerm) {'
Write-Host '                # Créer un objet SqlDatabaseContradictoryPermission'
Write-Host '                $contradiction = New-SqlDatabaseContradictoryPermission -PermissionName $permName -UserName $user.Name -DatabaseName $database.Name'
Write-Host '                # Ajouter à la liste des contradictions'
Write-Host '                $contradictions.Add($contradiction)'
Write-Host '            }'
Write-Host '        }'
Write-Host '    }'
Write-Host '}'
Write-Host "```"

# Exemple de code pour détecter les contradictions au niveau objet (pseudo-code)
Write-Host "`nPseudo-code pour la détection des contradictions au niveau objet:"
Write-Host "```powershell"
Write-Host "# Récupérer les permissions des objets dans chaque base de données"
Write-Host 'foreach ($database in Get-SqlDatabase -ServerInstance "SQLSERVER01") {'
Write-Host '    $objectPermissions = Get-SqlObjectPermission -ServerInstance "SQLSERVER01" -Database $database.Name'
Write-Host ''
Write-Host '    # Détecter les contradictions GRANT/DENY'
Write-Host '    foreach ($user in $objectPermissions.Users) {'
Write-Host '        foreach ($object in $objectPermissions.Objects) {'
Write-Host '            $permissionNames = $object.Permissions | Where-Object { $_.UserName -eq $user.Name } | Select-Object -ExpandProperty PermissionName -Unique'
Write-Host '            foreach ($permName in $permissionNames) {'
Write-Host '                $grantedPerm = $object.Permissions | Where-Object { $_.UserName -eq $user.Name -and $_.PermissionName -eq $permName -and $_.PermissionState -eq "GRANT" }'
Write-Host '                $deniedPerm = $object.Permissions | Where-Object { $_.UserName -eq $user.Name -and $_.PermissionName -eq $permName -and $_.PermissionState -eq "DENY" }'
Write-Host '                if ($grantedPerm -and $deniedPerm) {'
Write-Host '                    # Créer un objet SqlObjectContradictoryPermission'
Write-Host '                    $contradiction = New-SqlObjectContradictoryPermission -PermissionName $permName -UserName $user.Name -DatabaseName $database.Name -SchemaName $object.SchemaName -ObjectName $object.Name -ObjectType $object.Type'
Write-Host '                    # Ajouter à la liste des contradictions'
Write-Host '                    $contradictions.Add($contradiction)'
Write-Host '                }'
Write-Host '            }'
Write-Host '        }'
Write-Host '    }'
Write-Host '}'
Write-Host "```"
