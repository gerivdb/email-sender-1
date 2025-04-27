# ContradictoryPermissionModel-Example.ps1
# Exemple d'utilisation de la structure de donnÃ©es pour les permissions contradictoires

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\RoadmapParser.psm1"
Import-Module $modulePath -Force

# Charger directement le fichier de modÃ¨le de permissions contradictoires pour l'exemple
$contradictoryPermissionModelPath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\Functions\Private\SqlPermissionModels\ContradictoryPermissionModel.ps1"
. $contradictoryPermissionModelPath

# CrÃ©er une permission contradictoire au niveau serveur
$serverContradiction = New-SqlServerContradictoryPermission `
    -PermissionName "CONNECT SQL" `
    -LoginName "AppUser" `
    -SecurableName "SQLSERVER01" `
    -ContradictionType "GRANT/DENY" `
    -ModelName "ProductionSecurityModel" `
    -RiskLevel "Ã‰levÃ©" `
    -Impact "L'utilisateur peut avoir des problÃ¨mes de connexion intermittents" `
    -RecommendedAction "Supprimer la permission DENY et conserver GRANT"

# Afficher les informations de la permission contradictoire au niveau serveur
Write-Host "Permission contradictoire au niveau serveur:"
Write-Host "----------------------------------------"
Write-Host $serverContradiction.ToString()
Write-Host ""
Write-Host "Description dÃ©taillÃ©e:"
Write-Host $serverContradiction.GetDetailedDescription()
Write-Host ""
Write-Host "Script de rÃ©solution:"
Write-Host "--------------------"
Write-Host $serverContradiction.GenerateFixScript()

# CrÃ©er une permission contradictoire au niveau base de donnÃ©es
$databaseContradiction = New-SqlDatabaseContradictoryPermission `
    -PermissionName "SELECT" `
    -UserName "AppUser" `
    -DatabaseName "AppDB" `
    -ContradictionType "GRANT/DENY" `
    -ModelName "ProductionSecurityModel" `
    -RiskLevel "Moyen" `
    -LoginName "AppLogin" `
    -Impact "L'utilisateur peut avoir des problÃ¨mes d'accÃ¨s aux donnÃ©es" `
    -RecommendedAction "Supprimer la permission DENY et conserver GRANT"

# Afficher les informations de la permission contradictoire au niveau base de donnÃ©es
Write-Host "`nPermission contradictoire au niveau base de donnÃ©es:"
Write-Host "------------------------------------------------"
Write-Host $databaseContradiction.ToString()
Write-Host ""
Write-Host "Description dÃ©taillÃ©e:"
Write-Host $databaseContradiction.GetDetailedDescription()
Write-Host ""
Write-Host "Script de rÃ©solution:"
Write-Host "--------------------"
Write-Host $databaseContradiction.GenerateFixScript()

# CrÃ©er une permission contradictoire au niveau objet
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
    -Impact "L'utilisateur peut avoir des problÃ¨mes de mise Ã  jour des donnÃ©es clients" `
    -RecommendedAction "Supprimer la permission DENY et conserver GRANT"

# Afficher les informations de la permission contradictoire au niveau objet
Write-Host "`nPermission contradictoire au niveau objet:"
Write-Host "----------------------------------------"
Write-Host $objectContradiction.ToString()
Write-Host ""
Write-Host "Description dÃ©taillÃ©e:"
Write-Host $objectContradiction.GetDetailedDescription()
Write-Host ""
Write-Host "Script de rÃ©solution:"
Write-Host "--------------------"
Write-Host $objectContradiction.GenerateFixScript()

# CrÃ©er un ensemble de permissions contradictoires
$permissionsSet = New-SqlContradictoryPermissionsSet `
    -ServerName "SQLSERVER01" `
    -ModelName "ProductionSecurityModel" `
    -Description "Analyse des permissions contradictoires sur le serveur de production" `
    -ReportTitle "Rapport de permissions contradictoires - Serveur de production"

# Ajouter les contradictions Ã  l'ensemble
$permissionsSet.AddServerContradiction($serverContradiction)
$permissionsSet.AddDatabaseContradiction($databaseContradiction)
$permissionsSet.AddObjectContradiction($objectContradiction)

# Afficher les informations de l'ensemble de permissions contradictoires
Write-Host "`nEnsemble de permissions contradictoires:"
Write-Host "--------------------------------------"
Write-Host $permissionsSet.ToString()
Write-Host ""
Write-Host "Nombre total de contradictions: $($permissionsSet.TotalContradictions)"
Write-Host "Contradictions au niveau serveur: $($permissionsSet.ServerContradictions.Count)"
Write-Host "Contradictions au niveau base de donnÃ©es: $($permissionsSet.DatabaseContradictions.Count)"
Write-Host "Contradictions au niveau objet: $($permissionsSet.ObjectContradictions.Count)"

# GÃ©nÃ©rer un rapport de synthÃ¨se
Write-Host "`nRapport de synthÃ¨se:"
Write-Host "-----------------"
Write-Host $permissionsSet.GenerateSummaryReport()

# GÃ©nÃ©rer un script de rÃ©solution pour toutes les contradictions
Write-Host "`nScript de rÃ©solution pour toutes les contradictions:"
Write-Host "----------------------------------------------"
Write-Host $permissionsSet.GenerateFixScript()

# Filtrer les contradictions par niveau de risque
$highRiskContradictions = $permissionsSet.FilterByRiskLevel("Ã‰levÃ©")
Write-Host "`nContradictions de niveau de risque Ã©levÃ©: $($highRiskContradictions.Count)"
foreach ($contradiction in $highRiskContradictions) {
    Write-Host "- $($contradiction.ToString())"
}

# Filtrer les contradictions par type
$grantDenyContradictions = $permissionsSet.FilterByType("GRANT/DENY")
Write-Host "`nContradictions de type GRANT/DENY: $($grantDenyContradictions.Count)"
foreach ($contradiction in $grantDenyContradictions) {
    Write-Host "- $($contradiction.ToString())"
}

# Filtrer les contradictions par utilisateur
$appUserContradictions = $permissionsSet.FilterByUser("AppUser")
Write-Host "`nContradictions pour l'utilisateur AppUser: $($appUserContradictions.Count)"
foreach ($contradiction in $appUserContradictions) {
    Write-Host "- $($contradiction.ToString())"
}

# Exemple d'utilisation dans un scÃ©nario de dÃ©tection
Write-Host "`nExemple de scÃ©nario de dÃ©tection de contradictions:"
Write-Host "------------------------------------------------"
Write-Host "1. RÃ©cupÃ©rer les permissions actuelles du serveur SQL, des bases de donnÃ©es et des objets"
Write-Host "2. Analyser les permissions pour dÃ©tecter les contradictions GRANT/DENY"
Write-Host "3. CrÃ©er des objets SqlServerContradictoryPermission, SqlDatabaseContradictoryPermission et SqlObjectContradictoryPermission pour chaque contradiction"
Write-Host "4. Ajouter les contradictions Ã  un objet SqlContradictoryPermissionsSet"
Write-Host "5. GÃ©nÃ©rer des rapports et des scripts de rÃ©solution"
Write-Host ""

# Exemple de code pour dÃ©tecter les contradictions au niveau serveur (pseudo-code)
Write-Host "Pseudo-code pour la dÃ©tection des contradictions au niveau serveur:"
Write-Host "```powershell"
Write-Host "# RÃ©cupÃ©rer les permissions du serveur"
Write-Host '$serverPermissions = Get-SqlServerPermission -ServerInstance "SQLSERVER01"'
Write-Host ""
Write-Host "# DÃ©tecter les contradictions GRANT/DENY"
Write-Host 'foreach ($login in $serverPermissions.Logins) {'
Write-Host '    $permissionNames = $login.Permissions | Select-Object -ExpandProperty PermissionName -Unique'
Write-Host '    foreach ($permName in $permissionNames) {'
Write-Host '        $grantedPerm = $login.Permissions | Where-Object { $_.PermissionName -eq $permName -and $_.PermissionState -eq "GRANT" }'
Write-Host '        $deniedPerm = $login.Permissions | Where-Object { $_.PermissionName -eq $permName -and $_.PermissionState -eq "DENY" }'
Write-Host '        if ($grantedPerm -and $deniedPerm) {'
Write-Host '            # CrÃ©er un objet SqlServerContradictoryPermission'
Write-Host '            $contradiction = New-SqlServerContradictoryPermission -PermissionName $permName -LoginName $login.Name'
Write-Host '            # Ajouter Ã  la liste des contradictions'
Write-Host '            $contradictions.Add($contradiction)'
Write-Host '        }'
Write-Host '    }'
Write-Host '}'
Write-Host "```"

# Exemple de code pour dÃ©tecter les contradictions au niveau base de donnÃ©es (pseudo-code)
Write-Host "`nPseudo-code pour la dÃ©tection des contradictions au niveau base de donnÃ©es:"
Write-Host "```powershell"
Write-Host "# RÃ©cupÃ©rer les permissions des bases de donnÃ©es"
Write-Host 'foreach ($database in Get-SqlDatabase -ServerInstance "SQLSERVER01") {'
Write-Host '    $databasePermissions = Get-SqlDatabasePermission -ServerInstance "SQLSERVER01" -Database $database.Name'
Write-Host ''
Write-Host '    # DÃ©tecter les contradictions GRANT/DENY'
Write-Host '    foreach ($user in $databasePermissions.Users) {'
Write-Host '        $permissionNames = $user.Permissions | Select-Object -ExpandProperty PermissionName -Unique'
Write-Host '        foreach ($permName in $permissionNames) {'
Write-Host '            $grantedPerm = $user.Permissions | Where-Object { $_.PermissionName -eq $permName -and $_.PermissionState -eq "GRANT" }'
Write-Host '            $deniedPerm = $user.Permissions | Where-Object { $_.PermissionName -eq $permName -and $_.PermissionState -eq "DENY" }'
Write-Host '            if ($grantedPerm -and $deniedPerm) {'
Write-Host '                # CrÃ©er un objet SqlDatabaseContradictoryPermission'
Write-Host '                $contradiction = New-SqlDatabaseContradictoryPermission -PermissionName $permName -UserName $user.Name -DatabaseName $database.Name'
Write-Host '                # Ajouter Ã  la liste des contradictions'
Write-Host '                $contradictions.Add($contradiction)'
Write-Host '            }'
Write-Host '        }'
Write-Host '    }'
Write-Host '}'
Write-Host "```"

# Exemple de code pour dÃ©tecter les contradictions au niveau objet (pseudo-code)
Write-Host "`nPseudo-code pour la dÃ©tection des contradictions au niveau objet:"
Write-Host "```powershell"
Write-Host "# RÃ©cupÃ©rer les permissions des objets dans chaque base de donnÃ©es"
Write-Host 'foreach ($database in Get-SqlDatabase -ServerInstance "SQLSERVER01") {'
Write-Host '    $objectPermissions = Get-SqlObjectPermission -ServerInstance "SQLSERVER01" -Database $database.Name'
Write-Host ''
Write-Host '    # DÃ©tecter les contradictions GRANT/DENY'
Write-Host '    foreach ($user in $objectPermissions.Users) {'
Write-Host '        foreach ($object in $objectPermissions.Objects) {'
Write-Host '            $permissionNames = $object.Permissions | Where-Object { $_.UserName -eq $user.Name } | Select-Object -ExpandProperty PermissionName -Unique'
Write-Host '            foreach ($permName in $permissionNames) {'
Write-Host '                $grantedPerm = $object.Permissions | Where-Object { $_.UserName -eq $user.Name -and $_.PermissionName -eq $permName -and $_.PermissionState -eq "GRANT" }'
Write-Host '                $deniedPerm = $object.Permissions | Where-Object { $_.UserName -eq $user.Name -and $_.PermissionName -eq $permName -and $_.PermissionState -eq "DENY" }'
Write-Host '                if ($grantedPerm -and $deniedPerm) {'
Write-Host '                    # CrÃ©er un objet SqlObjectContradictoryPermission'
Write-Host '                    $contradiction = New-SqlObjectContradictoryPermission -PermissionName $permName -UserName $user.Name -DatabaseName $database.Name -SchemaName $object.SchemaName -ObjectName $object.Name -ObjectType $object.Type'
Write-Host '                    # Ajouter Ã  la liste des contradictions'
Write-Host '                    $contradictions.Add($contradiction)'
Write-Host '                }'
Write-Host '            }'
Write-Host '        }'
Write-Host '    }'
Write-Host '}'
Write-Host "```"
