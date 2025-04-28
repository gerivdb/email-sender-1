# ContradictoryPermissionDetection.ps1
# Fonctions pour dÃ©tecter les permissions contradictoires dans SQL Server

# Importer le modÃ¨le de permissions contradictoires
$contradictoryPermissionModelPath = Join-Path -Path $PSScriptRoot -ChildPath "ContradictoryPermissionModel.ps1"
if (Test-Path $contradictoryPermissionModelPath) {
    . $contradictoryPermissionModelPath
} else {
    Write-Warning "Le fichier ContradictoryPermissionModel.ps1 n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement: $contradictoryPermissionModelPath"
}

#region Fonctions de dÃ©tection au niveau serveur

<#
.SYNOPSIS
    DÃ©tecte les permissions contradictoires au niveau serveur SQL.
.DESCRIPTION
    Cette fonction analyse les permissions au niveau serveur pour dÃ©tecter les contradictions
    de type GRANT/DENY sur la mÃªme permission pour le mÃªme login.
.PARAMETER ServerInstance
    Nom de l'instance SQL Server Ã  analyser.
.PARAMETER Credential
    Informations d'identification pour la connexion Ã  SQL Server.
.PARAMETER PermissionsData
    DonnÃ©es de permissions prÃ©alablement rÃ©cupÃ©rÃ©es (facultatif).
.PARAMETER ModelName
    Nom du modÃ¨le de rÃ©fÃ©rence utilisÃ© pour l'analyse.
.EXAMPLE
    $contradictions = Find-SqlServerContradictoryPermission -ServerInstance "SQLSERVER01"
.OUTPUTS
    System.Collections.Generic.List[SqlServerContradictoryPermission]
#>
function Find-SqlServerContradictoryPermission {
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[SqlServerContradictoryPermission]])]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "Server")]
        [string]$ServerInstance,

        [Parameter(Mandatory = $false, ParameterSetName = "Server")]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(Mandatory = $true, ParameterSetName = "Data")]
        [object]$PermissionsData,

        [Parameter(Mandatory = $false)]
        [string]$ModelName = "DefaultModel"
    )

    $contradictions = New-Object System.Collections.Generic.List[SqlServerContradictoryPermission]

    try {
        # Si les donnÃ©es de permissions ne sont pas fournies, les rÃ©cupÃ©rer
        if ($PSCmdlet.ParameterSetName -eq "Server") {
            Write-Verbose "RÃ©cupÃ©ration des permissions au niveau serveur pour l'instance $ServerInstance"

            # Construire les paramÃ¨tres pour la connexion
            $sqlParams = @{
                ServerInstance = $ServerInstance
                Database       = "master"
                Query          = @"
                SELECT
                    l.name AS LoginName,
                    p.class_desc AS ClassDesc,
                    p.permission_name AS PermissionName,
                    p.state_desc AS StateDesc,
                    CASE
                        WHEN p.class = 100 THEN 'SERVER'
                        WHEN p.class = 101 THEN 'DATABASE'
                        WHEN p.class = 102 THEN 'SCHEMA'
                        WHEN p.class = 105 THEN 'ROLE'
                        WHEN p.class = 108 THEN 'ASSEMBLY'
                        ELSE CAST(p.class AS VARCHAR(10))
                    END AS SecurableType,
                    CASE
                        WHEN p.class = 100 THEN @@SERVERNAME
                        ELSE ISNULL(OBJECT_NAME(p.major_id), CAST(p.major_id AS VARCHAR(10)))
                    END AS SecurableName
                FROM sys.server_permissions p
                JOIN sys.server_principals l ON p.grantee_principal_id = l.principal_id
                WHERE l.type IN ('S', 'U', 'G')
                ORDER BY l.name, p.permission_name, p.state_desc
"@
            }

            # Ajouter les informations d'identification si fournies
            if ($Credential) {
                $sqlParams.Add("Credential", $Credential)
            }

            # ExÃ©cuter la requÃªte
            try {
                $permissionsData = Invoke-Sqlcmd @sqlParams
            } catch {
                Write-Error "Erreur lors de la rÃ©cupÃ©ration des permissions au niveau serveur: $_"
                return $contradictions
            }
        }

        # Analyser les donnÃ©es de permissions pour dÃ©tecter les contradictions
        Write-Verbose "Analyse des permissions au niveau serveur pour dÃ©tecter les contradictions"

        # Regrouper les permissions par login et nom de permission
        $permissionGroups = $permissionsData | Group-Object -Property LoginName, PermissionName

        foreach ($group in $permissionGroups) {
            # VÃ©rifier s'il y a Ã  la fois GRANT et DENY pour la mÃªme permission
            $grantPermission = $group.Group | Where-Object { $_.StateDesc -eq "GRANT" }
            $denyPermission = $group.Group | Where-Object { $_.StateDesc -eq "DENY" }

            if ($grantPermission -and $denyPermission) {
                # Extraire les informations du groupe
                $loginName = $group.Group[0].LoginName
                $permissionName = $group.Group[0].PermissionName
                $securableType = $group.Group[0].SecurableType
                $securableName = $group.Group[0].SecurableName

                # CrÃ©er un objet de permission contradictoire
                $contradiction = New-SqlServerContradictoryPermission `
                    -PermissionName $permissionName `
                    -LoginName $loginName `
                    -SecurableName $securableName `
                    -ContradictionType "GRANT/DENY" `
                    -ModelName $ModelName `
                    -RiskLevel "Ã‰levÃ©" `
                    -Impact "L'utilisateur peut avoir des problÃ¨mes d'accÃ¨s intermittents" `
                    -RecommendedAction "RÃ©soudre la contradiction en supprimant soit GRANT soit DENY"

                $contradictions.Add($contradiction)

                Write-Verbose "Contradiction dÃ©tectÃ©e: Permission $permissionName pour le login $loginName"
            }
        }

        Write-Verbose "$($contradictions.Count) contradictions dÃ©tectÃ©es au niveau serveur"
    } catch {
        Write-Error "Erreur lors de la dÃ©tection des permissions contradictoires au niveau serveur: $_"
    }

    return $contradictions
}

#endregion

#region Fonctions de dÃ©tection au niveau base de donnÃ©es

<#
.SYNOPSIS
    DÃ©tecte les permissions contradictoires au niveau base de donnÃ©es SQL.
.DESCRIPTION
    Cette fonction analyse les permissions au niveau base de donnÃ©es pour dÃ©tecter les contradictions
    de type GRANT/DENY sur la mÃªme permission pour le mÃªme utilisateur.
.PARAMETER ServerInstance
    Nom de l'instance SQL Server Ã  analyser.
.PARAMETER Database
    Nom de la base de donnÃ©es Ã  analyser.
.PARAMETER Credential
    Informations d'identification pour la connexion Ã  SQL Server.
.PARAMETER PermissionsData
    DonnÃ©es de permissions prÃ©alablement rÃ©cupÃ©rÃ©es (facultatif).
.PARAMETER ModelName
    Nom du modÃ¨le de rÃ©fÃ©rence utilisÃ© pour l'analyse.
.EXAMPLE
    $contradictions = Find-SqlDatabaseContradictoryPermission -ServerInstance "SQLSERVER01" -Database "AdventureWorks"
.OUTPUTS
    System.Collections.Generic.List[SqlDatabaseContradictoryPermission]
#>
function Find-SqlDatabaseContradictoryPermission {
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[SqlDatabaseContradictoryPermission]])]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "Server")]
        [string]$ServerInstance,

        [Parameter(Mandatory = $true, ParameterSetName = "Server")]
        [string]$Database,

        [Parameter(Mandatory = $false, ParameterSetName = "Server")]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(Mandatory = $true, ParameterSetName = "Data")]
        [object]$PermissionsData,

        [Parameter(Mandatory = $false)]
        [string]$ModelName = "DefaultModel"
    )

    $contradictions = New-Object System.Collections.Generic.List[SqlDatabaseContradictoryPermission]

    try {
        # Si les donnÃ©es de permissions ne sont pas fournies, les rÃ©cupÃ©rer
        if ($PSCmdlet.ParameterSetName -eq "Server") {
            Write-Verbose "RÃ©cupÃ©ration des permissions au niveau base de donnÃ©es pour $Database sur $ServerInstance"

            # Construire les paramÃ¨tres pour la connexion
            $sqlParams = @{
                ServerInstance = $ServerInstance
                Database       = $Database
                Query          = @"
                SELECT
                    dp.name AS UserName,
                    p.class_desc AS ClassDesc,
                    p.permission_name AS PermissionName,
                    p.state_desc AS StateDesc,
                    CASE
                        WHEN p.class = 0 THEN 'DATABASE'
                        WHEN p.class = 1 THEN 'OBJECT'
                        WHEN p.class = 3 THEN 'SCHEMA'
                        WHEN p.class = 4 THEN 'USER'
                        WHEN p.class = 5 THEN 'ROLE'
                        WHEN p.class = 6 THEN 'ASSEMBLY'
                        ELSE CAST(p.class AS VARCHAR(10))
                    END AS SecurableType,
                    CASE
                        WHEN p.class = 0 THEN DB_NAME()
                        WHEN p.class = 1 THEN OBJECT_NAME(p.major_id)
                        WHEN p.class = 3 THEN SCHEMA_NAME(p.major_id)
                        WHEN p.class = 4 THEN USER_NAME(p.major_id)
                        WHEN p.class = 5 THEN (SELECT name FROM sys.database_principals WHERE principal_id = p.major_id)
                        WHEN p.class = 6 THEN (SELECT name FROM sys.assemblies WHERE assembly_id = p.major_id)
                        ELSE CAST(p.major_id AS VARCHAR(10))
                    END AS SecurableName,
                    sp.name AS LoginName
                FROM sys.database_permissions p
                JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
                LEFT JOIN sys.server_principals sp ON dp.sid = sp.sid
                WHERE dp.type IN ('S', 'U', 'G')
                AND p.class = 0 -- Permissions au niveau base de donnÃ©es uniquement
                ORDER BY dp.name, p.permission_name, p.state_desc
"@
            }

            # Ajouter les informations d'identification si fournies
            if ($Credential) {
                $sqlParams.Add("Credential", $Credential)
            }

            # ExÃ©cuter la requÃªte
            try {
                $permissionsData = Invoke-Sqlcmd @sqlParams
            } catch {
                Write-Error "Erreur lors de la rÃ©cupÃ©ration des permissions au niveau base de donnÃ©es: $_"
                return $contradictions
            }
        }

        # Analyser les donnÃ©es de permissions pour dÃ©tecter les contradictions
        Write-Verbose "Analyse des permissions au niveau base de donnÃ©es pour dÃ©tecter les contradictions"

        # Regrouper les permissions par utilisateur et nom de permission
        $permissionGroups = $permissionsData | Group-Object -Property UserName, PermissionName

        foreach ($group in $permissionGroups) {
            # VÃ©rifier s'il y a Ã  la fois GRANT et DENY pour la mÃªme permission
            $grantPermission = $group.Group | Where-Object { $_.StateDesc -eq "GRANT" }
            $denyPermission = $group.Group | Where-Object { $_.StateDesc -eq "DENY" }

            if ($grantPermission -and $denyPermission) {
                # Extraire les informations du groupe
                $userName = $group.Group[0].UserName
                $permissionName = $group.Group[0].PermissionName
                $databaseName = if ($PSCmdlet.ParameterSetName -eq "Server") { $Database } else { $group.Group[0].SecurableName }
                $loginName = $group.Group[0].LoginName

                # CrÃ©er un objet de permission contradictoire
                $contradiction = New-SqlDatabaseContradictoryPermission `
                    -PermissionName $permissionName `
                    -UserName $userName `
                    -DatabaseName $databaseName `
                    -ContradictionType "GRANT/DENY" `
                    -ModelName $ModelName `
                    -RiskLevel "Ã‰levÃ©" `
                    -LoginName $loginName `
                    -Impact "L'utilisateur peut avoir des problÃ¨mes d'accÃ¨s intermittents Ã  la base de donnÃ©es" `
                    -RecommendedAction "RÃ©soudre la contradiction en supprimant soit GRANT soit DENY"

                $contradictions.Add($contradiction)

                Write-Verbose "Contradiction dÃ©tectÃ©e: Permission $permissionName pour l'utilisateur $userName dans la base de donnÃ©es $databaseName"
            }
        }

        Write-Verbose "$($contradictions.Count) contradictions dÃ©tectÃ©es au niveau base de donnÃ©es"
    } catch {
        Write-Error "Erreur lors de la dÃ©tection des permissions contradictoires au niveau base de donnÃ©es: $_"
    }

    return $contradictions
}

#endregion

#region Fonctions de dÃ©tection au niveau objet

<#
.SYNOPSIS
    DÃ©tecte les permissions contradictoires au niveau objet SQL.
.DESCRIPTION
    Cette fonction analyse les permissions au niveau objet pour dÃ©tecter les contradictions
    de type GRANT/DENY sur la mÃªme permission pour le mÃªme utilisateur.
.PARAMETER ServerInstance
    Nom de l'instance SQL Server Ã  analyser.
.PARAMETER Database
    Nom de la base de donnÃ©es Ã  analyser.
.PARAMETER Credential
    Informations d'identification pour la connexion Ã  SQL Server.
.PARAMETER PermissionsData
    DonnÃ©es de permissions prÃ©alablement rÃ©cupÃ©rÃ©es (facultatif).
.PARAMETER ModelName
    Nom du modÃ¨le de rÃ©fÃ©rence utilisÃ© pour l'analyse.
.EXAMPLE
    $contradictions = Find-SqlObjectContradictoryPermission -ServerInstance "SQLSERVER01" -Database "AdventureWorks"
.OUTPUTS
    System.Collections.Generic.List[SqlObjectContradictoryPermission]
#>
function Find-SqlObjectContradictoryPermission {
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[SqlObjectContradictoryPermission]])]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "Server")]
        [string]$ServerInstance,

        [Parameter(Mandatory = $true, ParameterSetName = "Server")]
        [string]$Database,

        [Parameter(Mandatory = $false, ParameterSetName = "Server")]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(Mandatory = $true, ParameterSetName = "Data")]
        [object]$PermissionsData,

        [Parameter(Mandatory = $false)]
        [string]$ModelName = "DefaultModel"
    )

    $contradictions = New-Object System.Collections.Generic.List[SqlObjectContradictoryPermission]

    try {
        # Si les donnÃ©es de permissions ne sont pas fournies, les rÃ©cupÃ©rer
        if ($PSCmdlet.ParameterSetName -eq "Server") {
            Write-Verbose "RÃ©cupÃ©ration des permissions au niveau objet pour $Database sur $ServerInstance"

            # Construire les paramÃ¨tres pour la connexion
            $sqlParams = @{
                ServerInstance = $ServerInstance
                Database       = $Database
                Query          = @"
                SELECT
                    dp.name AS UserName,
                    p.class_desc AS ClassDesc,
                    p.permission_name AS PermissionName,
                    p.state_desc AS StateDesc,
                    CASE
                        WHEN p.class = 1 THEN 'OBJECT'
                        ELSE CAST(p.class AS VARCHAR(10))
                    END AS SecurableType,
                    OBJECT_NAME(p.major_id) AS ObjectName,
                    SCHEMA_NAME(o.schema_id) AS SchemaName,
                    o.type_desc AS ObjectType,
                    CASE
                        WHEN p.minor_id > 0 THEN COL_NAME(p.major_id, p.minor_id)
                        ELSE NULL
                    END AS ColumnName,
                    sp.name AS LoginName
                FROM sys.database_permissions p
                JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
                JOIN sys.objects o ON p.major_id = o.object_id
                LEFT JOIN sys.server_principals sp ON dp.sid = sp.sid
                WHERE dp.type IN ('S', 'U', 'G')
                AND p.class = 1 -- Permissions au niveau objet uniquement
                ORDER BY dp.name, OBJECT_NAME(p.major_id), p.permission_name, p.state_desc
"@
            }

            # Ajouter les informations d'identification si fournies
            if ($Credential) {
                $sqlParams.Add("Credential", $Credential)
            }

            # ExÃ©cuter la requÃªte
            try {
                $permissionsData = Invoke-Sqlcmd @sqlParams
            } catch {
                Write-Error "Erreur lors de la rÃ©cupÃ©ration des permissions au niveau objet: $_"
                return $contradictions
            }
        }

        # Analyser les donnÃ©es de permissions pour dÃ©tecter les contradictions
        Write-Verbose "Analyse des permissions au niveau objet pour dÃ©tecter les contradictions"

        # Regrouper les permissions par utilisateur, objet, colonne et nom de permission
        $permissionGroups = $permissionsData | Group-Object -Property UserName, SchemaName, ObjectName, ColumnName, PermissionName

        foreach ($group in $permissionGroups) {
            # VÃ©rifier s'il y a Ã  la fois GRANT et DENY pour la mÃªme permission
            $grantPermission = $group.Group | Where-Object { $_.StateDesc -eq "GRANT" }
            $denyPermission = $group.Group | Where-Object { $_.StateDesc -eq "DENY" }

            if ($grantPermission -and $denyPermission) {
                # Extraire les informations du groupe
                $userName = $group.Group[0].UserName
                $permissionName = $group.Group[0].PermissionName
                $databaseName = if ($PSCmdlet.ParameterSetName -eq "Server") { $Database } else { $group.Group[0].DatabaseName }
                $schemaName = $group.Group[0].SchemaName
                $objectName = $group.Group[0].ObjectName
                $objectType = $group.Group[0].ObjectType
                $columnName = $group.Group[0].ColumnName
                $loginName = $group.Group[0].LoginName

                # CrÃ©er un objet de permission contradictoire
                # VÃ©rifier que les valeurs requises ne sont pas vides
                if ([string]::IsNullOrEmpty($databaseName)) {
                    $databaseName = "UnknownDB"
                }

                if ([string]::IsNullOrEmpty($objectName)) {
                    $objectName = "UnknownObject"
                }

                $contradiction = New-SqlObjectContradictoryPermission `
                    -PermissionName $permissionName `
                    -UserName $userName `
                    -DatabaseName $databaseName `
                    -SchemaName $schemaName `
                    -ObjectName $objectName `
                    -ObjectType $objectType `
                    -ColumnName $columnName `
                    -ContradictionType "GRANT/DENY" `
                    -ModelName $ModelName `
                    -RiskLevel "Ã‰levÃ©" `
                    -LoginName $loginName `
                    -Impact "L'utilisateur peut avoir des problÃ¨mes d'accÃ¨s intermittents Ã  l'objet" `
                    -RecommendedAction "RÃ©soudre la contradiction en supprimant soit GRANT soit DENY"

                $contradictions.Add($contradiction)

                $columnInfo = if ($columnName) { " (colonne: $columnName)" } else { "" }
                Write-Verbose "Contradiction dÃ©tectÃ©e: Permission $permissionName pour l'utilisateur $userName sur l'objet $schemaName.$objectName$columnInfo"
            }
        }

        Write-Verbose "$($contradictions.Count) contradictions dÃ©tectÃ©es au niveau objet"
    } catch {
        Write-Error "Erreur lors de la dÃ©tection des permissions contradictoires au niveau objet: $_"
    }

    return $contradictions
}

#endregion

#region Fonction principale de dÃ©tection

<#
.SYNOPSIS
    DÃ©tecte toutes les permissions contradictoires dans une instance SQL Server.
.DESCRIPTION
    Cette fonction analyse les permissions Ã  tous les niveaux (serveur, base de donnÃ©es, objet)
    pour dÃ©tecter les contradictions de type GRANT/DENY.
.PARAMETER ServerInstance
    Nom de l'instance SQL Server Ã  analyser.
.PARAMETER Database
    Nom de la base de donnÃ©es Ã  analyser. Si non spÃ©cifiÃ©, toutes les bases de donnÃ©es seront analysÃ©es.
.PARAMETER Credential
    Informations d'identification pour la connexion Ã  SQL Server.
.PARAMETER ModelName
    Nom du modÃ¨le de rÃ©fÃ©rence utilisÃ© pour l'analyse.
.EXAMPLE
    $contradictionsSet = Find-SqlContradictoryPermission -ServerInstance "SQLSERVER01"
.OUTPUTS
    SqlContradictoryPermissionsSet
#>
function Find-SqlContradictoryPermission {
    [CmdletBinding()]
    [OutputType([SqlContradictoryPermissionsSet])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ServerInstance,

        [Parameter(Mandatory = $false)]
        [string[]]$Database,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(Mandatory = $false)]
        [string]$ModelName = "DefaultModel"
    )

    # CrÃ©er un ensemble de permissions contradictoires
    $contradictionsSet = New-SqlContradictoryPermissionsSet -ServerName $ServerInstance -ModelName $ModelName

    try {
        # DÃ©tecter les contradictions au niveau serveur
        Write-Verbose "DÃ©tection des contradictions au niveau serveur pour $ServerInstance"
        $serverContradictions = Find-SqlServerContradictoryPermission -ServerInstance $ServerInstance -Credential $Credential -ModelName $ModelName

        foreach ($contradiction in $serverContradictions) {
            $contradictionsSet.AddServerContradiction($contradiction)
        }

        # Si aucune base de donnÃ©es n'est spÃ©cifiÃ©e, rÃ©cupÃ©rer toutes les bases de donnÃ©es
        if (-not $Database) {
            Write-Verbose "RÃ©cupÃ©ration de la liste des bases de donnÃ©es"

            # Construire les paramÃ¨tres pour la connexion
            $sqlParams = @{
                ServerInstance = $ServerInstance
                Database       = "master"
                Query          = "SELECT name FROM sys.databases WHERE state = 0 AND name NOT IN ('master', 'tempdb', 'model', 'msdb')"
            }

            # Ajouter les informations d'identification si fournies
            if ($Credential) {
                $sqlParams.Add("Credential", $Credential)
            }

            # ExÃ©cuter la requÃªte
            try {
                $databaseList = Invoke-Sqlcmd @sqlParams
                $Database = $databaseList | Select-Object -ExpandProperty name
            } catch {
                Write-Error "Erreur lors de la rÃ©cupÃ©ration de la liste des bases de donnÃ©es: $_"
                return $contradictionsSet
            }
        }

        # DÃ©tecter les contradictions pour chaque base de donnÃ©es
        foreach ($db in $Database) {
            Write-Verbose "DÃ©tection des contradictions pour la base de donnÃ©es $db"

            # DÃ©tecter les contradictions au niveau base de donnÃ©es
            $dbContradictions = Find-SqlDatabaseContradictoryPermission -ServerInstance $ServerInstance -Database $db -Credential $Credential -ModelName $ModelName

            foreach ($contradiction in $dbContradictions) {
                $contradictionsSet.AddDatabaseContradiction($contradiction)
            }

            # DÃ©tecter les contradictions au niveau objet
            $objContradictions = Find-SqlObjectContradictoryPermission -ServerInstance $ServerInstance -Database $db -Credential $Credential -ModelName $ModelName

            foreach ($contradiction in $objContradictions) {
                $contradictionsSet.AddObjectContradiction($contradiction)
            }
        }

        Write-Verbose "DÃ©tection des contradictions terminÃ©e. Total: $($contradictionsSet.TotalContradictions)"
    } catch {
        Write-Error "Erreur lors de la dÃ©tection des permissions contradictoires: $_"
    }

    return $contradictionsSet
}

#endregion

# Exporter les fonctions
Export-ModuleMember -Function Find-SqlServerContradictoryPermission, Find-SqlDatabaseContradictoryPermission, Find-SqlObjectContradictoryPermission, Find-SqlContradictoryPermission
