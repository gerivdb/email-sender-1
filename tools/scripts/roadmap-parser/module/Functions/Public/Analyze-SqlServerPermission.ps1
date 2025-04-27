<#
.SYNOPSIS
    Analyse les permissions SQL Server au niveau serveur et base de donnÃ©es.

.DESCRIPTION
    Cette fonction analyse en dÃ©tail les permissions SQL Server au niveau serveur et base de donnÃ©es,
    y compris les rÃ´les serveur, les rÃ´les de base de donnÃ©es, les permissions explicites, et les identitÃ©s associÃ©es.

.PARAMETER ServerInstance
    Le nom de l'instance SQL Server (serveur\instance ou serveur).

.PARAMETER Database
    Le nom de la base de donnÃ©es Ã  analyser. Si non spÃ©cifiÃ©, toutes les bases de donnÃ©es sont analysÃ©es.

.PARAMETER Credential
    Les informations d'identification Ã  utiliser pour l'accÃ¨s Ã  la base de donnÃ©es.
    Si non spÃ©cifiÃ©, l'authentification Windows est utilisÃ©e.

.PARAMETER IncludeDatabaseLevel
    Indique si l'analyse doit inclure les permissions au niveau base de donnÃ©es.
    Par dÃ©faut: $true.

.PARAMETER OutputPath
    Le chemin oÃ¹ exporter le rapport de permissions. Si non spÃ©cifiÃ©, aucun rapport n'est gÃ©nÃ©rÃ©.

.PARAMETER OutputFormat
    Le format du rapport de permissions (HTML, CSV, JSON, XML). Par dÃ©faut: HTML.

.EXAMPLE
    Analyze-SqlServerPermission -ServerInstance "localhost\SQLEXPRESS"

.EXAMPLE
    Analyze-SqlServerPermission -ServerInstance "localhost\SQLEXPRESS" -Database "AdventureWorks"

.EXAMPLE
    Analyze-SqlServerPermission -ServerInstance "localhost\SQLEXPRESS" -IncludeDatabaseLevel $false

.EXAMPLE
    Analyze-SqlServerPermission -ServerInstance "localhost\SQLEXPRESS" -OutputPath "C:\Reports\SqlPermissions.html"

.EXAMPLE
    $cred = Get-Credential
    Analyze-SqlServerPermission -ServerInstance "SqlServer01" -Credential $cred -OutputFormat "JSON" -OutputPath "C:\Reports\SqlPermissions.json"

.OUTPUTS
    [PSCustomObject] avec des dÃ©tails sur les permissions au niveau serveur et base de donnÃ©es
#>
function Analyze-SqlServerPermission {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$ServerInstance,

        [Parameter(Mandatory = $false)]
        [string]$Database,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(Mandatory = $false)]
        [bool]$IncludeDatabaseLevel = $true,

        [Parameter(Mandatory = $false)]
        [bool]$IncludeObjectLevel = $false,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("HTML", "CSV", "JSON", "XML")]
        [string]$OutputFormat = "HTML",

        [Parameter(Mandatory = $false)]
        [string[]]$RuleIds = @(),

        [Parameter(Mandatory = $false)]
        [ValidateSet("All", "Ã‰levÃ©e", "Moyenne", "Faible")]
        [string]$Severity = "All"
    )

    begin {
        Write-Verbose "DÃ©marrage de l'analyse des permissions SQL Server pour l'instance: $ServerInstance"

        # VÃ©rifier si le module SqlServer est installÃ©
        if (-not (Get-Module -Name SqlServer -ListAvailable)) {
            Write-Warning "Le module SqlServer n'est pas installÃ©. Installation en cours..."
            try {
                if ($PSCmdlet.ShouldProcess("Module SqlServer", "Installation")) {
                    # Dans un environnement de test, nous ne voulons pas rÃ©ellement installer le module
                    if (-not $env:PESTER_TEST_RUN) {
                        Install-Module -Name SqlServer -Force -AllowClobber -Scope CurrentUser
                    }
                }
            } catch {
                Write-Error "Impossible d'installer le module SqlServer: $($_.Exception.Message)"
                return
            }
        }

        # Importer le module SqlServer
        try {
            # Dans un environnement de test, nous ne voulons pas rÃ©ellement importer le module
            if (-not $env:PESTER_TEST_RUN) {
                Import-Module -Name SqlServer -ErrorAction Stop
            }
        } catch {
            Write-Error "Impossible d'importer le module SqlServer: $($_.Exception.Message)"
            return
        }
    }

    process {
        try {
            # CrÃ©er les paramÃ¨tres de connexion
            $sqlParams = @{
                ServerInstance = $ServerInstance
            }

            if ($Credential) {
                $sqlParams.Add("Credential", $Credential)
            }

            # Analyser les permissions au niveau serveur
            Write-Verbose "Analyse des rÃ´les serveur et des permissions..."

            # 1. Obtenir les rÃ´les serveur et leurs membres
            $serverRoles = Get-ServerRoles @sqlParams

            # 2. Obtenir les permissions explicites au niveau serveur
            $serverPermissions = Get-ServerPermissions @sqlParams

            # 3. Obtenir les logins et leurs propriÃ©tÃ©s
            $serverLogins = Get-ServerLogins @sqlParams

            # 4. DÃ©tecter les anomalies de permissions au niveau serveur
            $serverPermissionAnomalies = Find-PermissionAnomalies -ServerRoles $serverRoles -ServerPermissions $serverPermissions -ServerLogins $serverLogins -RuleIds $RuleIds -Severity $Severity

            # Variables pour les permissions au niveau base de donnÃ©es
            $databaseRoles = @()
            $databasePermissions = @()
            $databaseUsers = @()
            $databasePermissionAnomalies = @()

            # Variables pour les permissions au niveau objet
            $databaseObjects = @()
            $objectPermissions = @()
            $objectPermissionAnomalies = @()

            # Analyser les permissions au niveau base de donnÃ©es si demandÃ©
            if ($IncludeDatabaseLevel) {
                Write-Verbose "Analyse des permissions au niveau base de donnÃ©es..."

                # Obtenir la liste des bases de donnÃ©es Ã  analyser
                $databases = @()
                if ($Database) {
                    # Analyser une base de donnÃ©es spÃ©cifique
                    $databases += $Database
                } else {
                    # Analyser toutes les bases de donnÃ©es
                    $dbQuery = "SELECT name FROM sys.databases WHERE state = 0 AND name NOT IN ('master', 'tempdb', 'model', 'msdb')"
                    $databases = (Invoke-Sqlcmd @sqlParams -Query $dbQuery).name
                }

                foreach ($db in $databases) {
                    Write-Verbose "Analyse de la base de donnÃ©es: $db"

                    # CrÃ©er les paramÃ¨tres SQL avec la base de donnÃ©es
                    $dbSqlParams = $sqlParams.Clone()
                    $dbSqlParams.Add("Database", $db)

                    # 1. Obtenir les rÃ´les de base de donnÃ©es et leurs membres
                    $dbRoles = Get-DatabaseRoles @dbSqlParams
                    foreach ($role in $dbRoles) {
                        $role | Add-Member -MemberType NoteProperty -Name "DatabaseName" -Value $db
                    }
                    $databaseRoles += $dbRoles

                    # 2. Obtenir les permissions explicites au niveau base de donnÃ©es
                    $dbPermissions = Get-DatabasePermissions @dbSqlParams
                    foreach ($perm in $dbPermissions) {
                        $perm | Add-Member -MemberType NoteProperty -Name "DatabaseName" -Value $db
                    }
                    $databasePermissions += $dbPermissions

                    # 3. Obtenir les utilisateurs de base de donnÃ©es
                    $dbUsers = Get-DatabaseUsers @dbSqlParams
                    foreach ($user in $dbUsers) {
                        $user | Add-Member -MemberType NoteProperty -Name "DatabaseName" -Value $db
                    }
                    $databaseUsers += $dbUsers
                }

                # 4. DÃ©tecter les anomalies de permissions au niveau base de donnÃ©es
                if ($databaseRoles.Count -gt 0 -or $databasePermissions.Count -gt 0 -or $databaseUsers.Count -gt 0) {
                    $databasePermissionAnomalies = Find-DatabasePermissionAnomalies -DatabaseRoles $databaseRoles -DatabasePermissions $databasePermissions -DatabaseUsers $databaseUsers -ServerLogins $serverLogins -RuleIds $RuleIds -Severity $Severity
                }

                # 5. Analyser les permissions au niveau objet si demandÃ©
                if ($IncludeObjectLevel) {
                    Write-Verbose "Analyse des permissions au niveau objet..."

                    foreach ($db in $databases) {
                        Write-Verbose "Analyse des objets et permissions dans la base de donnÃ©es: $db"

                        # CrÃ©er les paramÃ¨tres SQL avec la base de donnÃ©es
                        $dbSqlParams = $sqlParams.Clone()
                        $dbSqlParams.Add("Database", $db)

                        # 1. Obtenir les objets de base de donnÃ©es
                        $dbObjects = Get-DatabaseObjects @dbSqlParams
                        foreach ($objType in $dbObjects) {
                            $objType | Add-Member -MemberType NoteProperty -Name "DatabaseName" -Value $db
                        }
                        $databaseObjects += $dbObjects

                        # 2. Obtenir les permissions au niveau objet
                        $dbObjectPermissions = Get-ObjectPermissions @dbSqlParams
                        foreach ($perm in $dbObjectPermissions) {
                            $perm | Add-Member -MemberType NoteProperty -Name "DatabaseName" -Value $db
                        }
                        $objectPermissions += $dbObjectPermissions

                        # 3. DÃ©tecter les anomalies de permissions au niveau objet
                        if ($dbObjectPermissions.Count -gt 0) {
                            $dbObjectAnomalies = Find-ObjectPermissionAnomalies -ObjectPermissions $dbObjectPermissions -DatabaseUsers $dbUsers -DatabaseName $db -RuleIds $RuleIds -Severity $Severity
                            $objectPermissionAnomalies += $dbObjectAnomalies
                        }
                    }
                }
            }

            # CrÃ©er l'objet de rÃ©sultat
            $result = [PSCustomObject]@{
                ServerInstance              = $ServerInstance
                ServerRoles                 = $serverRoles
                ServerPermissions           = $serverPermissions
                ServerLogins                = $serverLogins
                ServerPermissionAnomalies   = $serverPermissionAnomalies
                IncludeDatabaseLevel        = $IncludeDatabaseLevel
                DatabaseRoles               = $databaseRoles
                DatabasePermissions         = $databasePermissions
                DatabaseUsers               = $databaseUsers
                DatabasePermissionAnomalies = $databasePermissionAnomalies
                IncludeObjectLevel          = $IncludeObjectLevel
                DatabaseObjects             = $databaseObjects
                ObjectPermissions           = $objectPermissions
                ObjectPermissionAnomalies   = $objectPermissionAnomalies
                AnalysisDate                = Get-Date
            }

            # GÃ©nÃ©rer un rapport si demandÃ©
            if ($OutputPath) {
                if ($PSCmdlet.ShouldProcess("Rapport de permissions", "GÃ©nÃ©ration")) {
                    Export-PermissionReport -PermissionData $result -OutputPath $OutputPath -OutputFormat $OutputFormat
                }
            }

            # Retourner les rÃ©sultats
            return $result
        } catch {
            Write-Error "Erreur lors de l'analyse des permissions SQL Server: $($_.Exception.Message)"
        }
    }

    end {
        Write-Verbose "Analyse des permissions SQL Server terminÃ©e pour l'instance: $ServerInstance"
    }
}

function Get-ServerRoles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$sqlParams
    )

    try {
        # RequÃªte pour obtenir les rÃ´les serveur et leurs membres
        $query = @"
SELECT
    SR.name AS RoleName,
    SP.name AS MemberName,
    SP.type_desc AS MemberType,
    SP.create_date AS MemberCreateDate,
    SP.is_disabled AS IsDisabled
FROM sys.server_principals SR
JOIN sys.server_role_members SRM ON SR.principal_id = SRM.role_principal_id
JOIN sys.server_principals SP ON SRM.member_principal_id = SP.principal_id
WHERE SR.type = 'R'
ORDER BY SR.name, SP.name
"@

        # ExÃ©cuter la requÃªte
        $roleMembers = Invoke-Sqlcmd @sqlParams -Query $query -ErrorAction Stop

        # Organiser les rÃ©sultats par rÃ´le
        $roles = @{}
        foreach ($roleMember in $roleMembers) {
            $roleName = $roleMember.RoleName

            if (-not $roles.ContainsKey($roleName)) {
                $roles[$roleName] = @{
                    RoleName = $roleName
                    Members  = @()
                }
            }

            $roles[$roleName].Members += [PSCustomObject]@{
                MemberName = $roleMember.MemberName
                MemberType = $roleMember.MemberType
                CreateDate = $roleMember.MemberCreateDate
                IsDisabled = $roleMember.IsDisabled
            }
        }

        # Convertir en tableau d'objets
        $result = @()
        foreach ($role in $roles.Keys) {
            $result += [PSCustomObject]@{
                RoleName    = $roles[$role].RoleName
                Members     = $roles[$role].Members
                MemberCount = $roles[$role].Members.Count
            }
        }

        return $result
    } catch {
        Write-Error "Erreur lors de l'obtention des rÃ´les serveur: $($_.Exception.Message)"
        return @()
    }
}

function Get-ServerPermissions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$sqlParams
    )

    try {
        # RequÃªte pour obtenir les permissions explicites au niveau serveur
        $query = @"
SELECT
    SP.name AS GranteeName,
    SP.type_desc AS GranteeType,
    CASE
        WHEN SP2.name IS NOT NULL THEN SP2.name
        ELSE COALESCE(OBJECT_NAME(SPerm.major_id), 'SERVER')
    END AS SecurableName,
    CASE
        WHEN SP2.name IS NOT NULL THEN 'SERVER_PRINCIPAL'
        WHEN SPerm.class = 100 THEN 'SERVER'
        WHEN SPerm.class = 105 THEN 'ENDPOINT'
        ELSE 'OTHER'
    END AS SecurableType,
    SPerm.permission_name AS PermissionName,
    SPerm.state_desc AS PermissionState
FROM sys.server_permissions SPerm
JOIN sys.server_principals SP ON SPerm.grantee_principal_id = SP.principal_id
LEFT JOIN sys.server_principals SP2 ON SPerm.major_id = SP2.principal_id AND SPerm.class = 101
ORDER BY SP.name, SPerm.permission_name
"@

        # ExÃ©cuter la requÃªte
        $permissions = Invoke-Sqlcmd @sqlParams -Query $query -ErrorAction Stop

        # Organiser les rÃ©sultats par utilisateur/login
        $userPermissions = @{}
        foreach ($permission in $permissions) {
            $granteeName = $permission.GranteeName

            if (-not $userPermissions.ContainsKey($granteeName)) {
                $userPermissions[$granteeName] = @{
                    GranteeName = $granteeName
                    GranteeType = $permission.GranteeType
                    Permissions = @()
                }
            }

            $userPermissions[$granteeName].Permissions += [PSCustomObject]@{
                SecurableName   = $permission.SecurableName
                SecurableType   = $permission.SecurableType
                PermissionName  = $permission.PermissionName
                PermissionState = $permission.PermissionState
            }
        }

        # Convertir en tableau d'objets
        $result = @()
        foreach ($user in $userPermissions.Keys) {
            $result += [PSCustomObject]@{
                GranteeName     = $userPermissions[$user].GranteeName
                GranteeType     = $userPermissions[$user].GranteeType
                Permissions     = $userPermissions[$user].Permissions
                PermissionCount = $userPermissions[$user].Permissions.Count
            }
        }

        return $result
    } catch {
        Write-Error "Erreur lors de l'obtention des permissions serveur: $($_.Exception.Message)"
        return @()
    }
}

function Get-ServerLogins {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$sqlParams
    )

    try {
        # RequÃªte pour obtenir les logins et leurs propriÃ©tÃ©s
        $query = @"
SELECT
    SP.name AS LoginName,
    SP.type_desc AS LoginType,
    SP.create_date AS CreateDate,
    SP.modify_date AS ModifyDate,
    SP.is_disabled AS IsDisabled,
    LOGINPROPERTY(SP.name, 'PasswordLastSetTime') AS PasswordLastSetTime,
    LOGINPROPERTY(SP.name, 'DaysUntilExpiration') AS DaysUntilExpiration,
    LOGINPROPERTY(SP.name, 'IsExpired') AS IsExpired,
    LOGINPROPERTY(SP.name, 'IsMustChange') AS IsMustChange,
    LOGINPROPERTY(SP.name, 'LockoutTime') AS LockoutTime,
    LOGINPROPERTY(SP.name, 'BadPasswordCount') AS BadPasswordCount,
    LOGINPROPERTY(SP.name, 'IsLocked') AS IsLocked
FROM sys.server_principals SP
WHERE SP.type IN ('S', 'U', 'G')
ORDER BY SP.name
"@

        # ExÃ©cuter la requÃªte
        $logins = Invoke-Sqlcmd @sqlParams -Query $query -ErrorAction Stop

        # Convertir en tableau d'objets
        $result = @()
        foreach ($login in $logins) {
            $result += [PSCustomObject]@{
                LoginName           = $login.LoginName
                LoginType           = $login.LoginType
                CreateDate          = $login.CreateDate
                ModifyDate          = $login.ModifyDate
                IsDisabled          = $login.IsDisabled
                PasswordLastSetTime = $login.PasswordLastSetTime
                DaysUntilExpiration = $login.DaysUntilExpiration
                IsExpired           = $login.IsExpired
                IsMustChange        = $login.IsMustChange
                LockoutTime         = $login.LockoutTime
                BadPasswordCount    = $login.BadPasswordCount
                IsLocked            = $login.IsLocked
            }
        }

        return $result
    } catch {
        Write-Error "Erreur lors de l'obtention des logins serveur: $($_.Exception.Message)"
        return @()
    }
}

function Get-DatabaseRoles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$sqlParams
    )

    try {
        # RequÃªte pour obtenir les rÃ´les de base de donnÃ©es et leurs membres
        $query = @"
SELECT
    DP.name AS RoleName,
    DPM.name AS MemberName,
    DPM.type_desc AS MemberType,
    DPM.create_date AS MemberCreateDate,
    CASE WHEN SP.is_disabled IS NULL THEN 0 ELSE SP.is_disabled END AS IsDisabled
FROM sys.database_principals DP
JOIN sys.database_role_members DRM ON DP.principal_id = DRM.role_principal_id
JOIN sys.database_principals DPM ON DRM.member_principal_id = DPM.principal_id
LEFT JOIN sys.server_principals SP ON DPM.sid = SP.sid
WHERE DP.type = 'R'
ORDER BY DP.name, DPM.name
"@

        # ExÃ©cuter la requÃªte
        $roleMembers = Invoke-Sqlcmd @sqlParams -Query $query -ErrorAction Stop

        # Organiser les rÃ©sultats par rÃ´le
        $roles = @{}
        foreach ($roleMember in $roleMembers) {
            $roleName = $roleMember.RoleName

            if (-not $roles.ContainsKey($roleName)) {
                $roles[$roleName] = @{
                    RoleName = $roleName
                    Members  = @()
                }
            }

            $roles[$roleName].Members += [PSCustomObject]@{
                MemberName = $roleMember.MemberName
                MemberType = $roleMember.MemberType
                CreateDate = $roleMember.MemberCreateDate
                IsDisabled = $roleMember.IsDisabled
            }
        }

        # Convertir en tableau d'objets
        $result = @()
        foreach ($role in $roles.Keys) {
            $result += [PSCustomObject]@{
                RoleName    = $roles[$role].RoleName
                Members     = $roles[$role].Members
                MemberCount = $roles[$role].Members.Count
            }
        }

        return $result
    } catch {
        Write-Error "Erreur lors de l'obtention des rÃ´les de base de donnÃ©es: $($_.Exception.Message)"
        return @()
    }
}

function Get-DatabasePermissions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$sqlParams
    )

    try {
        # RequÃªte pour obtenir les permissions explicites au niveau base de donnÃ©es
        $query = @"
SELECT
    DP.name AS GranteeName,
    DP.type_desc AS GranteeType,
    CASE
        WHEN DP2.name IS NOT NULL THEN DP2.name
        WHEN O.name IS NOT NULL THEN O.name
        WHEN S.name IS NOT NULL THEN S.name
        ELSE COALESCE(OBJECT_SCHEMA_NAME(DPerm.major_id), 'DATABASE')
    END AS SecurableName,
    CASE
        WHEN DP2.name IS NOT NULL THEN 'DATABASE_PRINCIPAL'
        WHEN DPerm.class = 0 THEN 'DATABASE'
        WHEN DPerm.class = 1 THEN 'OBJECT'
        WHEN DPerm.class = 3 THEN 'SCHEMA'
        ELSE 'OTHER'
    END AS SecurableType,
    DPerm.permission_name AS PermissionName,
    DPerm.state_desc AS PermissionState
FROM sys.database_permissions DPerm
JOIN sys.database_principals DP ON DPerm.grantee_principal_id = DP.principal_id
LEFT JOIN sys.database_principals DP2 ON DPerm.major_id = DP2.principal_id AND DPerm.class = 4
LEFT JOIN sys.objects O ON DPerm.major_id = O.object_id AND DPerm.class = 1
LEFT JOIN sys.schemas S ON DPerm.major_id = S.schema_id AND DPerm.class = 3
ORDER BY DP.name, DPerm.permission_name
"@

        # ExÃ©cuter la requÃªte
        $permissions = Invoke-Sqlcmd @sqlParams -Query $query -ErrorAction Stop

        # Organiser les rÃ©sultats par utilisateur
        $userPermissions = @{}
        foreach ($permission in $permissions) {
            $granteeName = $permission.GranteeName

            if (-not $userPermissions.ContainsKey($granteeName)) {
                $userPermissions[$granteeName] = @{
                    GranteeName = $granteeName
                    GranteeType = $permission.GranteeType
                    Permissions = @()
                }
            }

            $userPermissions[$granteeName].Permissions += [PSCustomObject]@{
                SecurableName   = $permission.SecurableName
                SecurableType   = $permission.SecurableType
                PermissionName  = $permission.PermissionName
                PermissionState = $permission.PermissionState
            }
        }

        # Convertir en tableau d'objets
        $result = @()
        foreach ($user in $userPermissions.Keys) {
            $result += [PSCustomObject]@{
                GranteeName     = $userPermissions[$user].GranteeName
                GranteeType     = $userPermissions[$user].GranteeType
                Permissions     = $userPermissions[$user].Permissions
                PermissionCount = $userPermissions[$user].Permissions.Count
            }
        }

        return $result
    } catch {
        Write-Error "Erreur lors de l'obtention des permissions de base de donnÃ©es: $($_.Exception.Message)"
        return @()
    }
}

function Get-DatabaseUsers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$sqlParams
    )

    try {
        # RequÃªte pour obtenir les utilisateurs de base de donnÃ©es et leurs propriÃ©tÃ©s
        $query = @"
SELECT
    DP.name AS UserName,
    DP.type_desc AS UserType,
    DP.create_date AS CreateDate,
    DP.modify_date AS ModifyDate,
    DP.default_schema_name AS DefaultSchema,
    SP.name AS LoginName,
    CASE WHEN SP.is_disabled IS NULL THEN 0 ELSE SP.is_disabled END AS IsDisabled
FROM sys.database_principals DP
LEFT JOIN sys.server_principals SP ON DP.sid = SP.sid
WHERE DP.type IN ('S', 'U', 'G') AND DP.is_fixed_role = 0 AND DP.name NOT IN ('dbo', 'guest', 'INFORMATION_SCHEMA', 'sys')
ORDER BY DP.name
"@

        # ExÃ©cuter la requÃªte
        $users = Invoke-Sqlcmd @sqlParams -Query $query -ErrorAction Stop

        # Convertir en tableau d'objets
        $result = @()
        foreach ($user in $users) {
            $result += [PSCustomObject]@{
                UserName      = $user.UserName
                UserType      = $user.UserType
                CreateDate    = $user.CreateDate
                ModifyDate    = $user.ModifyDate
                DefaultSchema = $user.DefaultSchema
                LoginName     = $user.LoginName
                IsDisabled    = $user.IsDisabled
            }
        }

        return $result
    } catch {
        Write-Error "Erreur lors de l'obtention des utilisateurs de base de donnÃ©es: $($_.Exception.Message)"
        return @()
    }
}

function Find-DatabasePermissionAnomalies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$DatabaseRoles,

        [Parameter(Mandatory = $true)]
        [array]$DatabasePermissions,

        [Parameter(Mandatory = $true)]
        [array]$DatabaseUsers,

        [Parameter(Mandatory = $true)]
        [array]$ServerLogins,

        [Parameter(Mandatory = $false)]
        [string[]]$RuleIds = @(),

        [Parameter(Mandatory = $false)]
        [string]$Severity = "All"
    )

    $anomalies = @()

    # Obtenir les rÃ¨gles de dÃ©tection d'anomalies au niveau base de donnÃ©es
    $rules = Get-SqlPermissionRules -RuleType "Database" -Severity $Severity

    # Filtrer par ID de rÃ¨gle si spÃ©cifiÃ©
    if ($RuleIds.Count -gt 0) {
        $rules = $rules | Where-Object { $RuleIds -contains $_.RuleId }
    }

    # Appliquer chaque rÃ¨gle
    foreach ($rule in $rules) {
        Write-Verbose "Application de la rÃ¨gle $($rule.RuleId): $($rule.Name)"

        # ExÃ©cuter la fonction de vÃ©rification de la rÃ¨gle
        $ruleResults = & $rule.CheckFunction $DatabaseUsers $DatabaseRoles $DatabasePermissions $ServerLogins

        # Ajouter les rÃ©sultats Ã  la liste des anomalies
        foreach ($result in $ruleResults) {
            $anomalies += [PSCustomObject]@{
                AnomalyType       = $rule.Name
                RuleId            = $rule.RuleId
                DatabaseName      = $result.DatabaseName
                UserName          = $result.UserName
                Description       = $result.Description
                Severity          = $rule.Severity
                RecommendedAction = $result.RecommendedAction
            }
        }
    }

    return $anomalies
}

function Get-SqlPermissionRules {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$RuleType = "All",

        [Parameter(Mandatory = $false)]
        [string]$Severity = "All"
    )

    # DÃ©finir les rÃ¨gles de dÃ©tection d'anomalies
    $rules = @(
        # RÃ¨gles au niveau serveur
        [PSCustomObject]@{
            RuleId        = "SVR001"
            RuleType      = "Server"
            Name          = "DisabledLoginWithPermissions"
            Description   = "DÃ©tecte les logins dÃ©sactivÃ©s qui possÃ¨dent encore des permissions"
            Severity      = "Moyenne"
            CheckFunction = {
                param($ServerLogins, $ServerRoles, $ServerPermissions)
                $disabledLoginsWithPermissions = $ServerLogins | Where-Object { $_.IsDisabled -eq $true }
                $results = @()
                foreach ($login in $disabledLoginsWithPermissions) {
                    $hasPermissions = $ServerPermissions | Where-Object { $_.GranteeName -eq $login.LoginName }
                    $isRoleMember = $ServerRoles | ForEach-Object { $_.Members } | Where-Object { $_.MemberName -eq $login.LoginName }
                    if ($hasPermissions -or $isRoleMember) {
                        $results += [PSCustomObject]@{
                            LoginName         = $login.LoginName
                            Description       = "Le login dÃ©sactivÃ© possÃ¨de des permissions ou est membre de rÃ´les serveur"
                            RecommendedAction = "RÃ©voquer les permissions ou retirer des rÃ´les serveur"
                        }
                    }
                }
                return $results
            }
        },
        [PSCustomObject]@{
            RuleId        = "SVR002"
            RuleType      = "Server"
            Name          = "HighPrivilegeAccount"
            Description   = "DÃ©tecte les comptes avec des permissions Ã©levÃ©es (sysadmin, securityadmin, serveradmin)"
            Severity      = "Ã‰levÃ©e"
            CheckFunction = {
                param($ServerLogins, $ServerRoles, $ServerPermissions)
                $highPrivilegeRoles = @("sysadmin", "securityadmin", "serveradmin")
                $results = @()
                foreach ($role in $ServerRoles | Where-Object { $highPrivilegeRoles -contains $_.RoleName }) {
                    foreach ($member in $role.Members) {
                        # Exclure les comptes systÃ¨me
                        if (-not $member.MemberName.StartsWith("##")) {
                            $results += [PSCustomObject]@{
                                LoginName         = $member.MemberName
                                Description       = "Le login est membre du rÃ´le serveur Ã  privilÃ¨ges Ã©levÃ©s: $($role.RoleName)"
                                RecommendedAction = "VÃ©rifier si ce niveau de privilÃ¨ge est nÃ©cessaire"
                            }
                        }
                    }
                }
                return $results
            }
        },
        [PSCustomObject]@{
            RuleId        = "SVR003"
            RuleType      = "Server"
            Name          = "PasswordPolicyExempt"
            Description   = "DÃ©tecte les comptes SQL exemptÃ©s de la politique de mot de passe"
            Severity      = "Moyenne"
            CheckFunction = {
                param($ServerLogins, $ServerRoles, $ServerPermissions)
                $results = @()
                $sqlLoginsWithoutPolicy = $ServerLogins | Where-Object {
                    $_.LoginType -eq "SQL_LOGIN" -and
                    ($_.IsPolicyChecked -eq 0 -or $_.IsExpirationChecked -eq 0)
                }
                foreach ($login in $sqlLoginsWithoutPolicy) {
                    $results += [PSCustomObject]@{
                        LoginName         = $login.LoginName
                        Description       = "Le login SQL n'est pas soumis Ã  la politique de mot de passe complÃ¨te"
                        RecommendedAction = "Activer la vÃ©rification de politique et d'expiration de mot de passe"
                    }
                }
                return $results
            }
        },
        [PSCustomObject]@{
            RuleId        = "SVR004"
            RuleType      = "Server"
            Name          = "LockedAccount"
            Description   = "DÃ©tecte les comptes verrouillÃ©s"
            Severity      = "Moyenne"
            CheckFunction = {
                param($ServerLogins, $ServerRoles, $ServerPermissions)
                $results = @()
                $lockedAccounts = $ServerLogins | Where-Object { $_.IsLocked -eq 1 }
                foreach ($login in $lockedAccounts) {
                    $results += [PSCustomObject]@{
                        LoginName         = $login.LoginName
                        Description       = "Le compte est verrouillÃ©"
                        RecommendedAction = "DÃ©verrouiller le compte et investiguer la cause"
                    }
                }
                return $results
            }
        },
        [PSCustomObject]@{
            RuleId        = "SVR005"
            RuleType      = "Server"
            Name          = "ControlServerPermission"
            Description   = "DÃ©tecte les comptes avec la permission CONTROL SERVER (Ã©quivalent Ã  sysadmin)"
            Severity      = "Ã‰levÃ©e"
            CheckFunction = {
                param($ServerLogins, $ServerRoles, $ServerPermissions)
                $results = @()
                $controlServerPermissions = $ServerPermissions | Where-Object {
                    $_.Permissions | Where-Object {
                        $_.PermissionName -eq "CONTROL SERVER" -and $_.PermissionState -eq "GRANT"
                    }
                }
                foreach ($permission in $controlServerPermissions) {
                    # Exclure les comptes systÃ¨me
                    if (-not $permission.GranteeName.StartsWith("##")) {
                        $results += [PSCustomObject]@{
                            LoginName         = $permission.GranteeName
                            Description       = "Le login possÃ¨de la permission CONTROL SERVER (Ã©quivalent Ã  sysadmin)"
                            RecommendedAction = "VÃ©rifier si ce niveau de privilÃ¨ge est nÃ©cessaire"
                        }
                    }
                }
                return $results
            }
        },
        [PSCustomObject]@{
            RuleId        = "SVR006"
            RuleType      = "Server"
            Name          = "DefaultSaAccount"
            Description   = "DÃ©tecte si le compte SA est activÃ© et/ou a Ã©tÃ© renommÃ©"
            Severity      = "Ã‰levÃ©e"
            CheckFunction = {
                param($ServerLogins, $ServerRoles, $ServerPermissions)
                $results = @()
                $saAccount = $ServerLogins | Where-Object { $_.LoginName -eq "sa" }
                if ($saAccount -and $saAccount.IsDisabled -eq 0) {
                    $results += [PSCustomObject]@{
                        LoginName         = "sa"
                        Description       = "Le compte SA est activÃ©"
                        RecommendedAction = "DÃ©sactiver le compte SA ou le renommer pour des raisons de sÃ©curitÃ©"
                    }
                }
                return $results
            }
        },

        # RÃ¨gles au niveau base de donnÃ©es
        [PSCustomObject]@{
            RuleId        = "DB001"
            RuleType      = "Database"
            Name          = "OrphanedUser"
            Description   = "DÃ©tecte les utilisateurs sans login associÃ© (utilisateurs orphelins)"
            Severity      = "Moyenne"
            CheckFunction = {
                param($DatabaseUsers, $DatabaseRoles, $DatabasePermissions, $ServerLogins)
                $results = @()
                $orphanedUsers = $DatabaseUsers | Where-Object {
                    $null -eq $_.LoginName -and
                    $_.UserType -ne "CERTIFICATE_MAPPED_USER" -and
                    $_.UserType -ne "ASYMMETRIC_KEY_MAPPED_USER"
                }
                foreach ($user in $orphanedUsers) {
                    $results += [PSCustomObject]@{
                        DatabaseName      = $user.DatabaseName
                        UserName          = $user.UserName
                        Description       = "L'utilisateur de base de donnÃ©es n'a pas de login associÃ©"
                        RecommendedAction = "Supprimer l'utilisateur ou le rÃ©associer Ã  un login"
                    }
                }
                return $results
            }
        },
        [PSCustomObject]@{
            RuleId        = "DB002"
            RuleType      = "Database"
            Name          = "DisabledLoginWithDatabaseUser"
            Description   = "DÃ©tecte les utilisateurs de base de donnÃ©es associÃ©s Ã  des logins dÃ©sactivÃ©s"
            Severity      = "Moyenne"
            CheckFunction = {
                param($DatabaseUsers, $DatabaseRoles, $DatabasePermissions, $ServerLogins)
                $results = @()
                $disabledLogins = $ServerLogins | Where-Object { $_.IsDisabled -eq 1 } | Select-Object -ExpandProperty LoginName
                $usersWithDisabledLogins = $DatabaseUsers | Where-Object { $disabledLogins -contains $_.LoginName }
                foreach ($user in $usersWithDisabledLogins) {
                    $results += [PSCustomObject]@{
                        DatabaseName      = $user.DatabaseName
                        UserName          = $user.UserName
                        Description       = "L'utilisateur est associÃ© Ã  un login dÃ©sactivÃ©: $($user.LoginName)"
                        RecommendedAction = "DÃ©sactiver l'utilisateur de base de donnÃ©es ou rÃ©activer le login"
                    }
                }
                return $results
            }
        },
        [PSCustomObject]@{
            RuleId        = "DB003"
            RuleType      = "Database"
            Name          = "HighPrivilegeDatabaseAccount"
            Description   = "DÃ©tecte les utilisateurs avec des permissions Ã©levÃ©es (db_owner, db_securityadmin)"
            Severity      = "Ã‰levÃ©e"
            CheckFunction = {
                param($DatabaseUsers, $DatabaseRoles, $DatabasePermissions, $ServerLogins)
                $results = @()
                $highPrivilegeRoles = @("db_owner", "db_securityadmin", "db_accessadmin")
                foreach ($role in $DatabaseRoles | Where-Object { $highPrivilegeRoles -contains $_.RoleName }) {
                    foreach ($member in $role.Members) {
                        # Exclure les comptes systÃ¨me
                        if (-not $member.MemberName.StartsWith("##") -and $member.MemberName -ne "dbo") {
                            $results += [PSCustomObject]@{
                                DatabaseName      = $role.DatabaseName
                                UserName          = $member.MemberName
                                Description       = "L'utilisateur est membre du rÃ´le de base de donnÃ©es Ã  privilÃ¨ges Ã©levÃ©s: $($role.RoleName)"
                                RecommendedAction = "VÃ©rifier si ce niveau de privilÃ¨ge est nÃ©cessaire"
                            }
                        }
                    }
                }
                return $results
            }
        },
        [PSCustomObject]@{
            RuleId        = "DB004"
            RuleType      = "Database"
            Name          = "ControlDatabasePermission"
            Description   = "DÃ©tecte les utilisateurs avec la permission CONTROL sur la base de donnÃ©es"
            Severity      = "Ã‰levÃ©e"
            CheckFunction = {
                param($DatabaseUsers, $DatabaseRoles, $DatabasePermissions, $ServerLogins)
                $results = @()
                $controlDatabasePermissions = $DatabasePermissions | Where-Object {
                    $_.SecurableType -eq "DATABASE" -and
                    $_.Permissions | Where-Object {
                        $_.PermissionName -eq "CONTROL" -and $_.PermissionState -eq "GRANT"
                    }
                }
                foreach ($permission in $controlDatabasePermissions) {
                    # Exclure les comptes systÃ¨me et dbo
                    if (-not $permission.GranteeName.StartsWith("##") -and $permission.GranteeName -ne "dbo") {
                        $results += [PSCustomObject]@{
                            DatabaseName      = $permission.DatabaseName
                            UserName          = $permission.GranteeName
                            Description       = "L'utilisateur possÃ¨de la permission CONTROL sur la base de donnÃ©es (Ã©quivalent Ã  db_owner)"
                            RecommendedAction = "VÃ©rifier si ce niveau de privilÃ¨ge est nÃ©cessaire"
                        }
                    }
                }
                return $results
            }
        },
        [PSCustomObject]@{
            RuleId        = "DB005"
            RuleType      = "Database"
            Name          = "GuestUserPermissions"
            Description   = "DÃ©tecte si l'utilisateur guest a des permissions explicites"
            Severity      = "Ã‰levÃ©e"
            CheckFunction = {
                param($DatabaseUsers, $DatabaseRoles, $DatabasePermissions, $ServerLogins)
                $results = @()
                $guestUsers = $DatabasePermissions | Where-Object { $_.GranteeName -eq "guest" }
                foreach ($permission in $guestUsers) {
                    $results += [PSCustomObject]@{
                        DatabaseName      = $permission.DatabaseName
                        UserName          = "guest"
                        Description       = "L'utilisateur guest possÃ¨de des permissions explicites"
                        RecommendedAction = "RÃ©voquer les permissions de l'utilisateur guest"
                    }
                }
                return $results
            }
        },
        [PSCustomObject]@{
            RuleId        = "DB006"
            RuleType      = "Database"
            Name          = "PublicRoleExcessivePermissions"
            Description   = "DÃ©tecte si le rÃ´le public a des permissions excessives"
            Severity      = "Ã‰levÃ©e"
            CheckFunction = {
                param($DatabaseUsers, $DatabaseRoles, $DatabasePermissions, $ServerLogins)
                $results = @()
                $publicRolePermissions = $DatabasePermissions | Where-Object {
                    $_.GranteeName -eq "public" -and
                    $_.Permissions | Where-Object {
                        $_.PermissionName -in @("ALTER", "CONTROL", "TAKE OWNERSHIP", "ALTER ANY", "CREATE", "DELETE") -and
                        $_.PermissionState -eq "GRANT"
                    }
                }
                foreach ($permission in $publicRolePermissions) {
                    $permNames = ($permission.Permissions | Where-Object {
                            $_.PermissionName -in @("ALTER", "CONTROL", "TAKE OWNERSHIP", "ALTER ANY", "CREATE", "DELETE") -and
                            $_.PermissionState -eq "GRANT"
                        } | Select-Object -ExpandProperty PermissionName) -join ", "

                    $results += [PSCustomObject]@{
                        DatabaseName      = $permission.DatabaseName
                        UserName          = "public"
                        Description       = "Le rÃ´le public possÃ¨de des permissions potentiellement excessives: $permNames"
                        RecommendedAction = "RÃ©voquer les permissions excessives du rÃ´le public"
                    }
                }
                return $results
            }
        },

        # RÃ¨gles au niveau objet
        [PSCustomObject]@{
            RuleId        = "OBJ001"
            RuleType      = "Object"
            Name          = "DisabledUserWithObjectPermissions"
            Description   = "DÃ©tecte les utilisateurs dÃ©sactivÃ©s avec des permissions sur des objets"
            Severity      = "Moyenne"
            CheckFunction = {
                param($ObjectPermissions, $DatabaseUsers, $DatabaseName)
                $results = @()
                $disabledUsers = $DatabaseUsers | Where-Object { $_.IsDisabled -eq 1 }
                foreach ($user in $disabledUsers) {
                    $userObjectPermissions = $ObjectPermissions | Where-Object { $_.GranteeName -eq $user.UserName }
                    if ($userObjectPermissions -and $userObjectPermissions.ObjectCount -gt 0) {
                        $results += [PSCustomObject]@{
                            DatabaseName      = $DatabaseName
                            UserName          = $user.UserName
                            Description       = "L'utilisateur dÃ©sactivÃ© possÃ¨de des permissions sur $($userObjectPermissions.ObjectCount) objets"
                            RecommendedAction = "RÃ©voquer les permissions ou rÃ©activer l'utilisateur si nÃ©cessaire"
                            AffectedObjects   = $userObjectPermissions.ObjectPermissions | ForEach-Object { $_.ObjectName }
                        }
                    }
                }
                return $results
            }
        },
        [PSCustomObject]@{
            RuleId        = "OBJ002"
            RuleType      = "Object"
            Name          = "GuestUserWithObjectPermissions"
            Description   = "DÃ©tecte si l'utilisateur guest a des permissions sur des objets"
            Severity      = "Ã‰levÃ©e"
            CheckFunction = {
                param($ObjectPermissions, $DatabaseUsers, $DatabaseName)
                $results = @()
                $guestObjectPermissions = $ObjectPermissions | Where-Object { $_.GranteeName -eq "guest" }
                if ($guestObjectPermissions -and $guestObjectPermissions.ObjectCount -gt 0) {
                    $results += [PSCustomObject]@{
                        DatabaseName      = $DatabaseName
                        UserName          = "guest"
                        Description       = "L'utilisateur guest possÃ¨de des permissions sur $($guestObjectPermissions.ObjectCount) objets"
                        RecommendedAction = "RÃ©voquer les permissions de l'utilisateur guest"
                        AffectedObjects   = $guestObjectPermissions.ObjectPermissions | ForEach-Object { $_.ObjectName }
                    }
                }
                return $results
            }
        },
        [PSCustomObject]@{
            RuleId        = "OBJ003"
            RuleType      = "Object"
            Name          = "ControlObjectPermission"
            Description   = "DÃ©tecte les utilisateurs avec la permission CONTROL sur des objets"
            Severity      = "Ã‰levÃ©e"
            CheckFunction = {
                param($ObjectPermissions, $DatabaseUsers, $DatabaseName)
                $results = @()
                foreach ($userPerm in $ObjectPermissions) {
                    $controlObjects = $userPerm.ObjectPermissions | Where-Object {
                        $_.Permissions | Where-Object {
                            $_.PermissionName -eq "CONTROL" -and $_.PermissionState -eq "GRANT"
                        }
                    }
                    if ($controlObjects -and $controlObjects.Count -gt 0) {
                        # Exclure les comptes systÃ¨me et dbo
                        if (-not $userPerm.GranteeName.StartsWith("##") -and $userPerm.GranteeName -ne "dbo") {
                            $results += [PSCustomObject]@{
                                DatabaseName      = $DatabaseName
                                UserName          = $userPerm.GranteeName
                                Description       = "L'utilisateur possÃ¨de la permission CONTROL sur $($controlObjects.Count) objets"
                                RecommendedAction = "VÃ©rifier si ce niveau de privilÃ¨ge est nÃ©cessaire"
                                AffectedObjects   = $controlObjects | ForEach-Object { $_.ObjectName }
                            }
                        }
                    }
                }
                return $results
            }
        },
        [PSCustomObject]@{
            RuleId        = "OBJ004"
            RuleType      = "Object"
            Name          = "ExcessiveTablePermissions"
            Description   = "DÃ©tecte les utilisateurs avec des permissions excessives sur des tables"
            Severity      = "Moyenne"
            CheckFunction = {
                param($ObjectPermissions, $DatabaseUsers, $DatabaseName)
                $results = @()
                foreach ($userPerm in $ObjectPermissions) {
                    $tableObjects = $userPerm.ObjectPermissions | Where-Object { $_.ObjectType -like "*TABLE*" }
                    if ($tableObjects -and $tableObjects.Count -gt 0) {
                        $excessivePermTables = $tableObjects | Where-Object {
                            $_.Permissions | Where-Object {
                                $_.PermissionName -in @("ALTER", "CONTROL", "TAKE OWNERSHIP", "DELETE", "INSERT", "UPDATE", "REFERENCES") -and
                                $_.PermissionState -eq "GRANT"
                            }
                        }
                        if ($excessivePermTables -and $excessivePermTables.Count -gt 0) {
                            # Exclure les comptes systÃ¨me et dbo
                            if (-not $userPerm.GranteeName.StartsWith("##") -and $userPerm.GranteeName -ne "dbo") {
                                $results += [PSCustomObject]@{
                                    DatabaseName      = $DatabaseName
                                    UserName          = $userPerm.GranteeName
                                    Description       = "L'utilisateur possÃ¨de des permissions potentiellement excessives sur $($excessivePermTables.Count) tables"
                                    RecommendedAction = "VÃ©rifier si ces permissions sont nÃ©cessaires"
                                    AffectedObjects   = $excessivePermTables | ForEach-Object { $_.ObjectName }
                                }
                            }
                        }
                    }
                }
                return $results
            }
        },
        [PSCustomObject]@{
            RuleId        = "OBJ005"
            RuleType      = "Object"
            Name          = "PublicRoleObjectPermissions"
            Description   = "DÃ©tecte si le rÃ´le public a des permissions sur des objets sensibles"
            Severity      = "Ã‰levÃ©e"
            CheckFunction = {
                param($ObjectPermissions, $DatabaseUsers, $DatabaseName)
                $results = @()
                $publicObjectPermissions = $ObjectPermissions | Where-Object { $_.GranteeName -eq "public" }
                if ($publicObjectPermissions -and $publicObjectPermissions.ObjectCount -gt 0) {
                    $sensitivePermissions = $publicObjectPermissions.ObjectPermissions | Where-Object {
                        $_.Permissions | Where-Object {
                            $_.PermissionName -in @("ALTER", "CONTROL", "TAKE OWNERSHIP", "DELETE", "INSERT", "UPDATE", "REFERENCES") -and
                            $_.PermissionState -eq "GRANT"
                        }
                    }
                    if ($sensitivePermissions -and $sensitivePermissions.Count -gt 0) {
                        $results += [PSCustomObject]@{
                            DatabaseName      = $DatabaseName
                            UserName          = "public"
                            Description       = "Le rÃ´le public possÃ¨de des permissions sensibles sur $($sensitivePermissions.Count) objets"
                            RecommendedAction = "RÃ©voquer les permissions sensibles du rÃ´le public"
                            AffectedObjects   = $sensitivePermissions | ForEach-Object { $_.ObjectName }
                        }
                    }
                }
                return $results
            }
        },
        [PSCustomObject]@{
            RuleId        = "OBJ006"
            RuleType      = "Object"
            Name          = "ConflictingPermissions"
            Description   = "DÃ©tecte les utilisateurs avec des permissions conflictuelles (GRANT et DENY) sur les mÃªmes objets"
            Severity      = "Moyenne"
            CheckFunction = {
                param($ObjectPermissions, $DatabaseUsers, $DatabaseName)
                $results = @()
                foreach ($userPerm in $ObjectPermissions) {
                    $conflictObjects = @()
                    foreach ($obj in $userPerm.ObjectPermissions) {
                        $permissionNames = $obj.Permissions | Select-Object -ExpandProperty PermissionName -Unique
                        foreach ($permName in $permissionNames) {
                            $grantedPerm = $obj.Permissions | Where-Object { $_.PermissionName -eq $permName -and $_.PermissionState -eq "GRANT" }
                            $deniedPerm = $obj.Permissions | Where-Object { $_.PermissionName -eq $permName -and $_.PermissionState -eq "DENY" }
                            if ($grantedPerm -and $deniedPerm) {
                                $conflictObjects += [PSCustomObject]@{
                                    ObjectName     = $obj.ObjectName
                                    PermissionName = $permName
                                }
                            }
                        }
                    }
                    if ($conflictObjects.Count -gt 0) {
                        $results += [PSCustomObject]@{
                            DatabaseName      = $DatabaseName
                            UserName          = $userPerm.GranteeName
                            Description       = "L'utilisateur possÃ¨de des permissions conflictuelles (GRANT et DENY) sur $($conflictObjects.Count) objets"
                            RecommendedAction = "RÃ©soudre les conflits de permissions"
                            AffectedObjects   = $conflictObjects | ForEach-Object { "$($_.ObjectName) ($($_.PermissionName))" }
                        }
                    }
                }
                return $results
            }
        }
    )

    # Filtrer les rÃ¨gles selon les paramÃ¨tres
    if ($RuleType -ne "All") {
        $rules = $rules | Where-Object { $_.RuleType -eq $RuleType }
    }

    if ($Severity -ne "All") {
        $rules = $rules | Where-Object { $_.Severity -eq $Severity }
    }

    return $rules
}

function Find-PermissionAnomalies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$ServerRoles,

        [Parameter(Mandatory = $true)]
        [array]$ServerPermissions,

        [Parameter(Mandatory = $true)]
        [array]$ServerLogins,

        [Parameter(Mandatory = $false)]
        [string[]]$RuleIds = @(),

        [Parameter(Mandatory = $false)]
        [string]$Severity = "All"
    )

    $anomalies = @()

    # Obtenir les rÃ¨gles de dÃ©tection d'anomalies au niveau serveur
    $rules = Get-SqlPermissionRules -RuleType "Server" -Severity $Severity

    # Filtrer par ID de rÃ¨gle si spÃ©cifiÃ©
    if ($RuleIds.Count -gt 0) {
        $rules = $rules | Where-Object { $RuleIds -contains $_.RuleId }
    }

    # Appliquer chaque rÃ¨gle
    foreach ($rule in $rules) {
        Write-Verbose "Application de la rÃ¨gle $($rule.RuleId): $($rule.Name)"

        # ExÃ©cuter la fonction de vÃ©rification de la rÃ¨gle
        $ruleResults = & $rule.CheckFunction $ServerLogins $ServerRoles $ServerPermissions

        # Ajouter les rÃ©sultats Ã  la liste des anomalies
        foreach ($result in $ruleResults) {
            $anomalies += [PSCustomObject]@{
                AnomalyType       = $rule.Name
                RuleId            = $rule.RuleId
                LoginName         = $result.LoginName
                Description       = $result.Description
                Severity          = $rule.Severity
                RecommendedAction = $result.RecommendedAction
            }
        }
    }

    return $anomalies
}

function Get-ObjectPermissions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$sqlParams
    )

    try {
        # RequÃªte pour obtenir les permissions explicites au niveau objet (tables, vues, procÃ©dures stockÃ©es, etc.)
        $query = @"
SELECT
    DP.name AS GranteeName,
    DP.type_desc AS GranteeType,
    OBJECT_SCHEMA_NAME(O.object_id) + '.' + O.name AS ObjectName,
    O.type_desc AS ObjectType,
    DPerm.permission_name AS PermissionName,
    DPerm.state_desc AS PermissionState
FROM sys.database_permissions DPerm
JOIN sys.database_principals DP ON DPerm.grantee_principal_id = DP.principal_id
JOIN sys.objects O ON DPerm.major_id = O.object_id
WHERE DPerm.class = 1  -- Objets (tables, vues, procÃ©dures stockÃ©es, etc.)
ORDER BY DP.name, O.name, DPerm.permission_name
"@

        # ExÃ©cuter la requÃªte
        $permissions = Invoke-Sqlcmd @sqlParams -Query $query -ErrorAction Stop

        # Organiser les rÃ©sultats par utilisateur/login et par objet
        $userObjectPermissions = @{}
        foreach ($permission in $permissions) {
            $granteeName = $permission.GranteeName
            $objectName = $permission.ObjectName

            if (-not $userObjectPermissions.ContainsKey($granteeName)) {
                $userObjectPermissions[$granteeName] = @{
                    GranteeName       = $granteeName
                    GranteeType       = $permission.GranteeType
                    ObjectPermissions = @{}
                }
            }

            if (-not $userObjectPermissions[$granteeName].ObjectPermissions.ContainsKey($objectName)) {
                $userObjectPermissions[$granteeName].ObjectPermissions[$objectName] = @{
                    ObjectName  = $objectName
                    ObjectType  = $permission.ObjectType
                    Permissions = @()
                }
            }

            $userObjectPermissions[$granteeName].ObjectPermissions[$objectName].Permissions += [PSCustomObject]@{
                PermissionName  = $permission.PermissionName
                PermissionState = $permission.PermissionState
            }
        }

        # Convertir en tableau d'objets
        $result = @()
        foreach ($user in $userObjectPermissions.Keys) {
            $objectPermList = @()
            foreach ($obj in $userObjectPermissions[$user].ObjectPermissions.Keys) {
                $objectPermList += [PSCustomObject]@{
                    ObjectName      = $userObjectPermissions[$user].ObjectPermissions[$obj].ObjectName
                    ObjectType      = $userObjectPermissions[$user].ObjectPermissions[$obj].ObjectType
                    Permissions     = $userObjectPermissions[$user].ObjectPermissions[$obj].Permissions
                    PermissionCount = $userObjectPermissions[$user].ObjectPermissions[$obj].Permissions.Count
                }
            }

            $result += [PSCustomObject]@{
                GranteeName          = $userObjectPermissions[$user].GranteeName
                GranteeType          = $userObjectPermissions[$user].GranteeType
                ObjectPermissions    = $objectPermList
                ObjectCount          = $objectPermList.Count
                TotalPermissionCount = ($objectPermList | Measure-Object -Property PermissionCount -Sum).Sum
            }
        }

        return $result
    } catch {
        Write-Error "Erreur lors de l'obtention des permissions au niveau objet: $($_.Exception.Message)"
        return @()
    }
}

function Get-DatabaseObjects {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$sqlParams
    )

    try {
        # RequÃªte pour obtenir les objets de base de donnÃ©es (tables, vues, procÃ©dures stockÃ©es, etc.)
        $query = @"
SELECT
    OBJECT_SCHEMA_NAME(object_id) AS SchemaName,
    name AS ObjectName,
    type_desc AS ObjectType,
    create_date AS CreateDate,
    modify_date AS ModifyDate,
    is_ms_shipped AS IsMsShipped
FROM sys.objects
WHERE type IN ('U', 'V', 'P', 'FN', 'IF', 'TF', 'TR')  -- Tables, vues, procÃ©dures stockÃ©es, fonctions, dÃ©clencheurs
ORDER BY type, SchemaName, name
"@

        # ExÃ©cuter la requÃªte
        $objects = Invoke-Sqlcmd @sqlParams -Query $query -ErrorAction Stop

        # Organiser les rÃ©sultats par type d'objet
        $objectsByType = @{}
        foreach ($obj in $objects) {
            $objectType = $obj.ObjectType

            if (-not $objectsByType.ContainsKey($objectType)) {
                $objectsByType[$objectType] = @()
            }

            $objectsByType[$objectType] += [PSCustomObject]@{
                SchemaName  = $obj.SchemaName
                ObjectName  = $obj.ObjectName
                FullName    = "$($obj.SchemaName).$($obj.ObjectName)"
                ObjectType  = $objectType
                CreateDate  = $obj.CreateDate
                ModifyDate  = $obj.ModifyDate
                IsMsShipped = $obj.IsMsShipped
            }
        }

        # Convertir en tableau d'objets
        $result = @()
        foreach ($type in $objectsByType.Keys) {
            $result += [PSCustomObject]@{
                ObjectType  = $type
                Objects     = $objectsByType[$type]
                ObjectCount = $objectsByType[$type].Count
            }
        }

        return $result
    } catch {
        Write-Error "Erreur lors de l'obtention des objets de base de donnÃ©es: $($_.Exception.Message)"
        return @()
    }
}

function Find-ObjectPermissionAnomalies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$ObjectPermissions,

        [Parameter(Mandatory = $true)]
        [array]$DatabaseUsers,

        [Parameter(Mandatory = $true)]
        [string]$DatabaseName,

        [Parameter(Mandatory = $false)]
        [string[]]$RuleIds = @(),

        [Parameter(Mandatory = $false)]
        [string]$Severity = "All"
    )

    $anomalies = @()

    # Obtenir les rÃ¨gles de dÃ©tection d'anomalies au niveau objet
    $rules = Get-SqlPermissionRules -RuleType "Object" -Severity $Severity

    # Filtrer par ID de rÃ¨gle si spÃ©cifiÃ©
    if ($RuleIds.Count -gt 0) {
        $rules = $rules | Where-Object { $RuleIds -contains $_.RuleId }
    }

    # Appliquer chaque rÃ¨gle
    foreach ($rule in $rules) {
        Write-Verbose "Application de la rÃ¨gle $($rule.RuleId): $($rule.Name)"

        # ExÃ©cuter la fonction de vÃ©rification de la rÃ¨gle
        $ruleResults = & $rule.CheckFunction $ObjectPermissions $DatabaseUsers $DatabaseName

        # Ajouter les rÃ©sultats Ã  la liste des anomalies
        foreach ($result in $ruleResults) {
            $anomalies += [PSCustomObject]@{
                AnomalyType       = $rule.Name
                RuleId            = $rule.RuleId
                DatabaseName      = $result.DatabaseName
                UserName          = $result.UserName
                Description       = $result.Description
                Severity          = $rule.Severity
                RecommendedAction = $result.RecommendedAction
                AffectedObjects   = $result.AffectedObjects
            }
        }
    }

    return $anomalies
}

function Export-PermissionReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$PermissionData,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $true)]
        [string]$OutputFormat
    )

    try {
        switch ($OutputFormat) {
            "HTML" {
                # CrÃ©er un rapport HTML
                $htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de permissions SQL Server</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2, h3 { color: #0066cc; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .severity-high { color: #cc0000; font-weight: bold; }
        .severity-medium { color: #ff9900; font-weight: bold; }
        .severity-low { color: #009900; }
        .summary { margin-bottom: 20px; padding: 10px; background-color: #f0f0f0; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>Rapport de permissions SQL Server</h1>
    <div class="summary">
        <p><strong>Instance SQL Server:</strong> $($PermissionData.ServerInstance)</p>
        <p><strong>Date d'analyse:</strong> $($PermissionData.AnalysisDate)</p>
        <p><strong>Nombre de rÃ´les serveur:</strong> $($PermissionData.ServerRoles.Count)</p>
        <p><strong>Nombre de logins:</strong> $($PermissionData.ServerLogins.Count)</p>
        <p><strong>Nombre d'anomalies dÃ©tectÃ©es au niveau serveur:</strong> $($PermissionData.ServerPermissionAnomalies.Count)</p>
        <p><strong>Analyse au niveau base de donnÃ©es:</strong> $($PermissionData.IncludeDatabaseLevel)</p>
        <p><strong>Nombre de bases de donnÃ©es analysÃ©es:</strong> $(($PermissionData.DatabaseRoles | Select-Object -Property DatabaseName -Unique).Count)</p>
        <p><strong>Nombre d'anomalies dÃ©tectÃ©es au niveau base de donnÃ©es:</strong> $($PermissionData.DatabasePermissionAnomalies.Count)</p>
    </div>

    <h2>Anomalies de permissions au niveau serveur</h2>
"@

                if ($PermissionData.ServerPermissionAnomalies.Count -gt 0) {
                    $htmlReport += @"
    <table>
        <tr>
            <th>Type d'anomalie</th>
            <th>Login</th>
            <th>Description</th>
            <th>SÃ©vÃ©ritÃ©</th>
            <th>Action recommandÃ©e</th>
        </tr>
"@
                    foreach ($anomaly in $PermissionData.ServerPermissionAnomalies) {
                        $severityClass = switch ($anomaly.Severity) {
                            "Ã‰levÃ©e" { "severity-high" }
                            "Moyenne" { "severity-medium" }
                            default { "severity-low" }
                        }

                        $htmlReport += @"
        <tr>
            <td>$($anomaly.AnomalyType)</td>
            <td>$($anomaly.LoginName)</td>
            <td>$($anomaly.Description)</td>
            <td class="$severityClass">$($anomaly.Severity)</td>
            <td>$($anomaly.RecommendedAction)</td>
        </tr>
"@
                    }
                    $htmlReport += @"
    </table>
"@
                } else {
                    $htmlReport += @"
    <p>Aucune anomalie dÃ©tectÃ©e au niveau serveur.</p>
"@
                }

                # Ajouter les anomalies au niveau base de donnÃ©es si l'analyse a Ã©tÃ© effectuÃ©e
                if ($PermissionData.IncludeDatabaseLevel) {
                    $htmlReport += @"

    <h2>Anomalies de permissions au niveau base de donnÃ©es</h2>
"@
                    if ($PermissionData.DatabasePermissionAnomalies.Count -gt 0) {
                        $htmlReport += @"
    <table>
        <tr>
            <th>Type d'anomalie</th>
            <th>Base de donnÃ©es</th>
            <th>Utilisateur</th>
            <th>Description</th>
            <th>SÃ©vÃ©ritÃ©</th>
            <th>Action recommandÃ©e</th>
        </tr>
"@
                        foreach ($anomaly in $PermissionData.DatabasePermissionAnomalies) {
                            $severityClass = switch ($anomaly.Severity) {
                                "Ã‰levÃ©e" { "severity-high" }
                                "Moyenne" { "severity-medium" }
                                default { "severity-low" }
                            }

                            $htmlReport += @"
        <tr>
            <td>$($anomaly.AnomalyType)</td>
            <td>$($anomaly.DatabaseName)</td>
            <td>$($anomaly.UserName)</td>
            <td>$($anomaly.Description)</td>
            <td class="$severityClass">$($anomaly.Severity)</td>
            <td>$($anomaly.RecommendedAction)</td>
        </tr>
"@
                        }
                        $htmlReport += @"
    </table>
"@
                    } else {
                        $htmlReport += @"
    <p>Aucune anomalie dÃ©tectÃ©e au niveau base de donnÃ©es.</p>
"@
                    }
                }

                $htmlReport += @"
    <h2>RÃ´les serveur</h2>
"@

                if ($PermissionData.ServerRoles.Count -gt 0) {
                    foreach ($role in $PermissionData.ServerRoles) {
                        $htmlReport += @"
    <h3>$($role.RoleName) ($($role.MemberCount) membres)</h3>
    <table>
        <tr>
            <th>Nom du membre</th>
            <th>Type</th>
            <th>Date de crÃ©ation</th>
            <th>DÃ©sactivÃ©</th>
        </tr>
"@
                        foreach ($member in $role.Members) {
                            $htmlReport += @"
        <tr>
            <td>$($member.MemberName)</td>
            <td>$($member.MemberType)</td>
            <td>$($member.CreateDate)</td>
            <td>$($member.IsDisabled)</td>
        </tr>
"@
                        }
                        $htmlReport += @"
    </table>
"@
                    }
                } else {
                    $htmlReport += @"
    <p>Aucun rÃ´le serveur trouvÃ©.</p>
"@
                }

                $htmlReport += @"
    <h2>Permissions explicites</h2>
"@

                if ($PermissionData.ServerPermissions.Count -gt 0) {
                    foreach ($grantee in $PermissionData.ServerPermissions) {
                        $htmlReport += @"
    <h3>$($grantee.GranteeName) ($($grantee.GranteeType)) - $($grantee.PermissionCount) permissions</h3>
    <table>
        <tr>
            <th>Objet sÃ©curisable</th>
            <th>Type d'objet</th>
            <th>Permission</th>
            <th>Ã‰tat</th>
        </tr>
"@
                        foreach ($permission in $grantee.Permissions) {
                            $htmlReport += @"
        <tr>
            <td>$($permission.SecurableName)</td>
            <td>$($permission.SecurableType)</td>
            <td>$($permission.PermissionName)</td>
            <td>$($permission.PermissionState)</td>
        </tr>
"@
                        }
                        $htmlReport += @"
    </table>
"@
                    }
                } else {
                    $htmlReport += @"
    <p>Aucune permission explicite trouvÃ©e.</p>
"@
                }

                $htmlReport += @"
    <h2>Logins SQL Server</h2>
    <table>
        <tr>
            <th>Nom du login</th>
            <th>Type</th>
            <th>Date de crÃ©ation</th>
            <th>DÃ©sactivÃ©</th>
            <th>Dernier changement de mot de passe</th>
            <th>Jours avant expiration</th>
            <th>ExpirÃ©</th>
            <th>VerrouillÃ©</th>
        </tr>
"@
                foreach ($login in $PermissionData.ServerLogins) {
                    $htmlReport += @"
        <tr>
            <td>$($login.LoginName)</td>
            <td>$($login.LoginType)</td>
            <td>$($login.CreateDate)</td>
            <td>$($login.IsDisabled)</td>
            <td>$($login.PasswordLastSetTime)</td>
            <td>$($login.DaysUntilExpiration)</td>
            <td>$($login.IsExpired)</td>
            <td>$($login.IsLocked)</td>
        </tr>
"@
                }
                $htmlReport += @"
    </table>
"@

                # Ajouter les informations sur les bases de donnÃ©es si l'analyse a Ã©tÃ© effectuÃ©e
                if ($PermissionData.IncludeDatabaseLevel -and $PermissionData.DatabaseRoles.Count -gt 0) {
                    $htmlReport += @"

    <h2>RÃ´les de base de donnÃ©es</h2>
"@

                    # Regrouper par base de donnÃ©es
                    $databaseNames = $PermissionData.DatabaseRoles | Select-Object -Property DatabaseName -Unique | ForEach-Object { $_.DatabaseName }

                    foreach ($dbName in $databaseNames) {
                        $htmlReport += @"
    <h3>Base de donnÃ©es: $dbName</h3>
"@

                        $dbRoles = $PermissionData.DatabaseRoles | Where-Object { $_.DatabaseName -eq $dbName }

                        foreach ($role in $dbRoles) {
                            $htmlReport += @"
    <h4>$($role.RoleName) ($($role.MemberCount) membres)</h4>
    <table>
        <tr>
            <th>Nom du membre</th>
            <th>Type</th>
            <th>Date de crÃ©ation</th>
            <th>DÃ©sactivÃ©</th>
        </tr>
"@
                            foreach ($member in $role.Members) {
                                $htmlReport += @"
        <tr>
            <td>$($member.MemberName)</td>
            <td>$($member.MemberType)</td>
            <td>$($member.CreateDate)</td>
            <td>$($member.IsDisabled)</td>
        </tr>
"@
                            }
                            $htmlReport += @"
    </table>
"@
                        }
                    }

                    $htmlReport += @"

    <h2>Permissions de base de donnÃ©es</h2>
"@

                    foreach ($dbName in $databaseNames) {
                        $htmlReport += @"
    <h3>Base de donnÃ©es: $dbName</h3>
"@

                        $dbPermissions = $PermissionData.DatabasePermissions | Where-Object { $_.DatabaseName -eq $dbName }

                        if ($dbPermissions.Count -gt 0) {
                            foreach ($grantee in $dbPermissions) {
                                $htmlReport += @"
    <h4>$($grantee.GranteeName) ($($grantee.GranteeType)) - $($grantee.PermissionCount) permissions</h4>
    <table>
        <tr>
            <th>Objet sÃ©curisable</th>
            <th>Type d'objet</th>
            <th>Permission</th>
            <th>Ã‰tat</th>
        </tr>
"@
                                foreach ($permission in $grantee.Permissions) {
                                    $htmlReport += @"
        <tr>
            <td>$($permission.SecurableName)</td>
            <td>$($permission.SecurableType)</td>
            <td>$($permission.PermissionName)</td>
            <td>$($permission.PermissionState)</td>
        </tr>
"@
                                }
                                $htmlReport += @"
    </table>
"@
                            }
                        } else {
                            $htmlReport += @"
    <p>Aucune permission explicite trouvÃ©e pour cette base de donnÃ©es.</p>
"@
                        }
                    }

                    $htmlReport += @"

    <h2>Utilisateurs de base de donnÃ©es</h2>
"@

                    foreach ($dbName in $databaseNames) {
                        $htmlReport += @"
    <h3>Base de donnÃ©es: $dbName</h3>
    <table>
        <tr>
            <th>Nom de l'utilisateur</th>
            <th>Type</th>
            <th>Login associÃ©</th>
            <th>SchÃ©ma par dÃ©faut</th>
            <th>Date de crÃ©ation</th>
            <th>DÃ©sactivÃ©</th>
        </tr>
"@

                        $dbUsers = $PermissionData.DatabaseUsers | Where-Object { $_.DatabaseName -eq $dbName }

                        foreach ($user in $dbUsers) {
                            $htmlReport += @"
        <tr>
            <td>$($user.UserName)</td>
            <td>$($user.UserType)</td>
            <td>$($user.LoginName)</td>
            <td>$($user.DefaultSchema)</td>
            <td>$($user.CreateDate)</td>
            <td>$($user.IsDisabled)</td>
        </tr>
"@
                        }

                        $htmlReport += @"
    </table>
"@
                    }
                }

                # Ajouter les informations sur les objets et leurs permissions si l'analyse a Ã©tÃ© effectuÃ©e
                if ($PermissionData.IncludeObjectLevel -and $PermissionData.ObjectPermissions.Count -gt 0) {
                    $htmlReport += @"

    <h2>Permissions au niveau objet</h2>
"@

                    # Regrouper par base de donnÃ©es
                    $databaseNames = $PermissionData.ObjectPermissions | Select-Object -Property DatabaseName -Unique | ForEach-Object { $_.DatabaseName }

                    foreach ($dbName in $databaseNames) {
                        $htmlReport += @"
    <h3>Base de donnÃ©es: $dbName</h3>
"@

                        $dbObjectPermissions = $PermissionData.ObjectPermissions | Where-Object { $_.DatabaseName -eq $dbName }

                        if ($dbObjectPermissions.Count -gt 0) {
                            foreach ($grantee in $dbObjectPermissions) {
                                $htmlReport += @"
    <h4>$($grantee.GranteeName) ($($grantee.GranteeType)) - $($grantee.ObjectCount) objets, $($grantee.TotalPermissionCount) permissions</h4>
    <table>
        <tr>
            <th>Nom de l'objet</th>
            <th>Type d'objet</th>
            <th>Permissions</th>
        </tr>
"@
                                foreach ($obj in $grantee.ObjectPermissions) {
                                    $permissionsStr = ($obj.Permissions | ForEach-Object { "$($_.PermissionName) ($($_.PermissionState))" }) -join ", "
                                    $htmlReport += @"
        <tr>
            <td>$($obj.ObjectName)</td>
            <td>$($obj.ObjectType)</td>
            <td>$permissionsStr</td>
        </tr>
"@
                                }
                                $htmlReport += @"
    </table>
"@
                            }
                        } else {
                            $htmlReport += @"
    <p>Aucune permission au niveau objet trouvÃ©e pour cette base de donnÃ©es.</p>
"@
                        }
                    }

                    # Ajouter les anomalies de permissions au niveau objet
                    if ($PermissionData.ObjectPermissionAnomalies.Count -gt 0) {
                        $htmlReport += @"

    <h2>Anomalies de permissions au niveau objet</h2>
    <table>
        <tr>
            <th>Type d'anomalie</th>
            <th>Base de donnÃ©es</th>
            <th>Utilisateur</th>
            <th>Description</th>
            <th>SÃ©vÃ©ritÃ©</th>
            <th>Action recommandÃ©e</th>
            <th>Objets affectÃ©s</th>
        </tr>
"@
                        foreach ($anomaly in $PermissionData.ObjectPermissionAnomalies) {
                            $severityClass = switch ($anomaly.Severity) {
                                "Ã‰levÃ©e" { "severity-high" }
                                "Moyenne" { "severity-medium" }
                                default { "severity-low" }
                            }

                            $affectedObjectsStr = ($anomaly.AffectedObjects -join ", ")
                            $htmlReport += @"
        <tr>
            <td>$($anomaly.AnomalyType)</td>
            <td>$($anomaly.DatabaseName)</td>
            <td>$($anomaly.UserName)</td>
            <td>$($anomaly.Description)</td>
            <td class="$severityClass">$($anomaly.Severity)</td>
            <td>$($anomaly.RecommendedAction)</td>
            <td>$affectedObjectsStr</td>
        </tr>
"@
                        }
                        $htmlReport += @"
    </table>
"@
                    } else {
                        $htmlReport += @"
    <h2>Anomalies de permissions au niveau objet</h2>
    <p>Aucune anomalie dÃ©tectÃ©e au niveau objet.</p>
"@
                    }
                }

                $htmlReport += @"
</body>
</html>
"@

                # Enregistrer le rapport HTML
                $htmlReport | Out-File -FilePath $OutputPath -Encoding UTF8
            }
            "CSV" {
                # CrÃ©er un rapport CSV pour chaque section

                # Anomalies au niveau serveur
                if ($PermissionData.ServerPermissionAnomalies.Count -gt 0) {
                    $csvPath = [System.IO.Path]::ChangeExtension($OutputPath, "server_anomalies.csv")
                    $PermissionData.ServerPermissionAnomalies | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
                }

                # Anomalies au niveau base de donnÃ©es
                if ($PermissionData.IncludeDatabaseLevel -and $PermissionData.DatabasePermissionAnomalies.Count -gt 0) {
                    $csvPath = [System.IO.Path]::ChangeExtension($OutputPath, "database_anomalies.csv")
                    $PermissionData.DatabasePermissionAnomalies | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
                }

                # RÃ´les serveur
                $serverRolesFlat = @()
                foreach ($role in $PermissionData.ServerRoles) {
                    foreach ($member in $role.Members) {
                        $serverRolesFlat += [PSCustomObject]@{
                            RoleName   = $role.RoleName
                            MemberName = $member.MemberName
                            MemberType = $member.MemberType
                            CreateDate = $member.CreateDate
                            IsDisabled = $member.IsDisabled
                        }
                    }
                }
                $csvPath = [System.IO.Path]::ChangeExtension($OutputPath, "server_roles.csv")
                $serverRolesFlat | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

                # Permissions explicites
                $serverPermissionsFlat = @()
                foreach ($grantee in $PermissionData.ServerPermissions) {
                    foreach ($permission in $grantee.Permissions) {
                        $serverPermissionsFlat += [PSCustomObject]@{
                            GranteeName     = $grantee.GranteeName
                            GranteeType     = $grantee.GranteeType
                            SecurableName   = $permission.SecurableName
                            SecurableType   = $permission.SecurableType
                            PermissionName  = $permission.PermissionName
                            PermissionState = $permission.PermissionState
                        }
                    }
                }
                $csvPath = [System.IO.Path]::ChangeExtension($OutputPath, "server_permissions.csv")
                $serverPermissionsFlat | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

                # Logins
                $csvPath = [System.IO.Path]::ChangeExtension($OutputPath, "server_logins.csv")
                $PermissionData.ServerLogins | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

                # Exporter les donnÃ©es de base de donnÃ©es si l'analyse a Ã©tÃ© effectuÃ©e
                if ($PermissionData.IncludeDatabaseLevel) {
                    # RÃ´les de base de donnÃ©es
                    if ($PermissionData.DatabaseRoles.Count -gt 0) {
                        $databaseRolesFlat = @()
                        foreach ($role in $PermissionData.DatabaseRoles) {
                            foreach ($member in $role.Members) {
                                $databaseRolesFlat += [PSCustomObject]@{
                                    DatabaseName = $role.DatabaseName
                                    RoleName     = $role.RoleName
                                    MemberName   = $member.MemberName
                                    MemberType   = $member.MemberType
                                    CreateDate   = $member.CreateDate
                                    IsDisabled   = $member.IsDisabled
                                }
                            }
                        }
                        $csvPath = [System.IO.Path]::ChangeExtension($OutputPath, "database_roles.csv")
                        $databaseRolesFlat | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
                    }

                    # Permissions de base de donnÃ©es
                    if ($PermissionData.DatabasePermissions.Count -gt 0) {
                        $databasePermissionsFlat = @()
                        foreach ($grantee in $PermissionData.DatabasePermissions) {
                            foreach ($permission in $grantee.Permissions) {
                                $databasePermissionsFlat += [PSCustomObject]@{
                                    DatabaseName    = $grantee.DatabaseName
                                    GranteeName     = $grantee.GranteeName
                                    GranteeType     = $grantee.GranteeType
                                    SecurableName   = $permission.SecurableName
                                    SecurableType   = $permission.SecurableType
                                    PermissionName  = $permission.PermissionName
                                    PermissionState = $permission.PermissionState
                                }
                            }
                        }
                        $csvPath = [System.IO.Path]::ChangeExtension($OutputPath, "database_permissions.csv")
                        $databasePermissionsFlat | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
                    }

                    # Utilisateurs de base de donnÃ©es
                    if ($PermissionData.DatabaseUsers.Count -gt 0) {
                        $csvPath = [System.IO.Path]::ChangeExtension($OutputPath, "database_users.csv")
                        $PermissionData.DatabaseUsers | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
                    }
                }

                # Exporter les donnÃ©es au niveau objet si l'analyse a Ã©tÃ© effectuÃ©e
                if ($PermissionData.IncludeObjectLevel) {
                    # Anomalies au niveau objet
                    if ($PermissionData.ObjectPermissionAnomalies.Count -gt 0) {
                        $csvPath = [System.IO.Path]::ChangeExtension($OutputPath, "object_anomalies.csv")
                        $PermissionData.ObjectPermissionAnomalies | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
                    }

                    # Objets de base de donnÃ©es
                    if ($PermissionData.DatabaseObjects.Count -gt 0) {
                        $databaseObjectsFlat = @()
                        foreach ($objType in $PermissionData.DatabaseObjects) {
                            foreach ($obj in $objType.Objects) {
                                $databaseObjectsFlat += [PSCustomObject]@{
                                    DatabaseName = $objType.DatabaseName
                                    SchemaName   = $obj.SchemaName
                                    ObjectName   = $obj.ObjectName
                                    FullName     = $obj.FullName
                                    ObjectType   = $obj.ObjectType
                                    CreateDate   = $obj.CreateDate
                                    ModifyDate   = $obj.ModifyDate
                                    IsMsShipped  = $obj.IsMsShipped
                                }
                            }
                        }
                        $csvPath = [System.IO.Path]::ChangeExtension($OutputPath, "database_objects.csv")
                        $databaseObjectsFlat | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
                    }

                    # Permissions au niveau objet
                    if ($PermissionData.ObjectPermissions.Count -gt 0) {
                        $objectPermissionsFlat = @()
                        foreach ($grantee in $PermissionData.ObjectPermissions) {
                            foreach ($obj in $grantee.ObjectPermissions) {
                                foreach ($permission in $obj.Permissions) {
                                    $objectPermissionsFlat += [PSCustomObject]@{
                                        DatabaseName    = $grantee.DatabaseName
                                        GranteeName     = $grantee.GranteeName
                                        GranteeType     = $grantee.GranteeType
                                        ObjectName      = $obj.ObjectName
                                        ObjectType      = $obj.ObjectType
                                        PermissionName  = $permission.PermissionName
                                        PermissionState = $permission.PermissionState
                                    }
                                }
                            }
                        }
                        $csvPath = [System.IO.Path]::ChangeExtension($OutputPath, "object_permissions.csv")
                        $objectPermissionsFlat | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
                    }
                }
            }
            "JSON" {
                # CrÃ©er un rapport JSON
                $PermissionData | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
            }
            "XML" {
                # CrÃ©er un rapport XML
                $PermissionData | Export-Clixml -Path $OutputPath -Encoding UTF8
            }
        }

        Write-Verbose "Rapport de permissions exportÃ© avec succÃ¨s: $OutputPath"
    } catch {
        Write-Error "Erreur lors de l'exportation du rapport de permissions: $($_.Exception.Message)"
    }
}

# Pas besoin d'exporter la fonction ici, elle sera exportÃ©e par le module
