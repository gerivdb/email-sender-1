<#
.SYNOPSIS
    Analyse les permissions SQL Server au niveau serveur et base de données.

.DESCRIPTION
    Cette fonction analyse en détail les permissions SQL Server au niveau serveur et base de données,
    y compris les rôles serveur, les rôles de base de données, les permissions explicites, et les identités associées.

.PARAMETER ServerInstance
    Le nom de l'instance SQL Server (serveur\instance ou serveur).

.PARAMETER Database
    Le nom de la base de données à analyser. Si non spécifié, toutes les bases de données sont analysées.

.PARAMETER Credential
    Les informations d'identification à utiliser pour l'accès à la base de données.
    Si non spécifié, l'authentification Windows est utilisée.

.PARAMETER IncludeDatabaseLevel
    Indique si l'analyse doit inclure les permissions au niveau base de données.
    Par défaut: $true.

.PARAMETER OutputPath
    Le chemin où exporter le rapport de permissions. Si non spécifié, aucun rapport n'est généré.

.PARAMETER OutputFormat
    Le format du rapport de permissions (HTML, CSV, JSON, XML). Par défaut: HTML.

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
    [PSCustomObject] avec des détails sur les permissions au niveau serveur et base de données
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
        [ValidateSet("All", "Élevée", "Moyenne", "Faible")]
        [string]$Severity = "All"
    )

    begin {
        Write-Verbose "Démarrage de l'analyse des permissions SQL Server pour l'instance: $ServerInstance"

        # Vérifier si le module SqlServer est installé
        if (-not (Get-Module -Name SqlServer -ListAvailable)) {
            Write-Warning "Le module SqlServer n'est pas installé. Installation en cours..."
            try {
                if ($PSCmdlet.ShouldProcess("Module SqlServer", "Installation")) {
                    # Dans un environnement de test, nous ne voulons pas réellement installer le module
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
            # Dans un environnement de test, nous ne voulons pas réellement importer le module
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
            # Créer les paramètres de connexion
            $sqlParams = @{
                ServerInstance = $ServerInstance
            }

            if ($Credential) {
                $sqlParams.Add("Credential", $Credential)
            }

            # Analyser les permissions au niveau serveur
            Write-Verbose "Analyse des rôles serveur et des permissions..."

            # 1. Obtenir les rôles serveur et leurs membres
            $serverRoles = Get-ServerRoles @sqlParams

            # 2. Obtenir les permissions explicites au niveau serveur
            $serverPermissions = Get-ServerPermissions @sqlParams

            # 3. Obtenir les logins et leurs propriétés
            $serverLogins = Get-ServerLogins @sqlParams

            # 4. Détecter les anomalies de permissions au niveau serveur
            $serverPermissionAnomalies = Find-PermissionAnomalies -ServerRoles $serverRoles -ServerPermissions $serverPermissions -ServerLogins $serverLogins -RuleIds $RuleIds -Severity $Severity

            # Variables pour les permissions au niveau base de données
            $databaseRoles = @()
            $databasePermissions = @()
            $databaseUsers = @()
            $databasePermissionAnomalies = @()

            # Variables pour les permissions au niveau objet
            $databaseObjects = @()
            $objectPermissions = @()
            $objectPermissionAnomalies = @()

            # Analyser les permissions au niveau base de données si demandé
            if ($IncludeDatabaseLevel) {
                Write-Verbose "Analyse des permissions au niveau base de données..."

                # Obtenir la liste des bases de données à analyser
                $databases = @()
                if ($Database) {
                    # Analyser une base de données spécifique
                    $databases += $Database
                } else {
                    # Analyser toutes les bases de données
                    $dbQuery = "SELECT name FROM sys.databases WHERE state = 0 AND name NOT IN ('master', 'tempdb', 'model', 'msdb')"
                    $databases = (Invoke-Sqlcmd @sqlParams -Query $dbQuery).name
                }

                foreach ($db in $databases) {
                    Write-Verbose "Analyse de la base de données: $db"

                    # Créer les paramètres SQL avec la base de données
                    $dbSqlParams = $sqlParams.Clone()
                    $dbSqlParams.Add("Database", $db)

                    # 1. Obtenir les rôles de base de données et leurs membres
                    $dbRoles = Get-DatabaseRoles @dbSqlParams
                    foreach ($role in $dbRoles) {
                        $role | Add-Member -MemberType NoteProperty -Name "DatabaseName" -Value $db
                    }
                    $databaseRoles += $dbRoles

                    # 2. Obtenir les permissions explicites au niveau base de données
                    $dbPermissions = Get-DatabasePermissions @dbSqlParams
                    foreach ($perm in $dbPermissions) {
                        $perm | Add-Member -MemberType NoteProperty -Name "DatabaseName" -Value $db
                    }
                    $databasePermissions += $dbPermissions

                    # 3. Obtenir les utilisateurs de base de données
                    $dbUsers = Get-DatabaseUsers @dbSqlParams
                    foreach ($user in $dbUsers) {
                        $user | Add-Member -MemberType NoteProperty -Name "DatabaseName" -Value $db
                    }
                    $databaseUsers += $dbUsers
                }

                # 4. Détecter les anomalies de permissions au niveau base de données
                if ($databaseRoles.Count -gt 0 -or $databasePermissions.Count -gt 0 -or $databaseUsers.Count -gt 0) {
                    $databasePermissionAnomalies = Find-DatabasePermissionAnomalies -DatabaseRoles $databaseRoles -DatabasePermissions $databasePermissions -DatabaseUsers $databaseUsers -ServerLogins $serverLogins -RuleIds $RuleIds -Severity $Severity
                }

                # 5. Analyser les permissions au niveau objet si demandé
                if ($IncludeObjectLevel) {
                    Write-Verbose "Analyse des permissions au niveau objet..."

                    foreach ($db in $databases) {
                        Write-Verbose "Analyse des objets et permissions dans la base de données: $db"

                        # Créer les paramètres SQL avec la base de données
                        $dbSqlParams = $sqlParams.Clone()
                        $dbSqlParams.Add("Database", $db)

                        # 1. Obtenir les objets de base de données
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

                        # 3. Détecter les anomalies de permissions au niveau objet
                        if ($dbObjectPermissions.Count -gt 0) {
                            $dbObjectAnomalies = Find-ObjectPermissionAnomalies -ObjectPermissions $dbObjectPermissions -DatabaseUsers $dbUsers -DatabaseName $db -RuleIds $RuleIds -Severity $Severity
                            $objectPermissionAnomalies += $dbObjectAnomalies
                        }
                    }
                }
            }

            # Créer l'objet de résultat
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

            # Générer un rapport si demandé
            if ($OutputPath) {
                if ($PSCmdlet.ShouldProcess("Rapport de permissions", "Génération")) {
                    Export-PermissionReport -PermissionData $result -OutputPath $OutputPath -OutputFormat $OutputFormat
                }
            }

            # Retourner les résultats
            return $result
        } catch {
            Write-Error "Erreur lors de l'analyse des permissions SQL Server: $($_.Exception.Message)"
        }
    }

    end {
        Write-Verbose "Analyse des permissions SQL Server terminée pour l'instance: $ServerInstance"
    }
}

function Get-ServerRoles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$sqlParams
    )

    try {
        # Requête pour obtenir les rôles serveur et leurs membres
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

        # Exécuter la requête
        $roleMembers = Invoke-Sqlcmd @sqlParams -Query $query -ErrorAction Stop

        # Organiser les résultats par rôle
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
        Write-Error "Erreur lors de l'obtention des rôles serveur: $($_.Exception.Message)"
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
        # Requête pour obtenir les permissions explicites au niveau serveur
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

        # Exécuter la requête
        $permissions = Invoke-Sqlcmd @sqlParams -Query $query -ErrorAction Stop

        # Organiser les résultats par utilisateur/login
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
        # Requête pour obtenir les logins et leurs propriétés
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

        # Exécuter la requête
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
        # Requête pour obtenir les rôles de base de données et leurs membres
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

        # Exécuter la requête
        $roleMembers = Invoke-Sqlcmd @sqlParams -Query $query -ErrorAction Stop

        # Organiser les résultats par rôle
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
        Write-Error "Erreur lors de l'obtention des rôles de base de données: $($_.Exception.Message)"
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
        # Requête pour obtenir les permissions explicites au niveau base de données
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

        # Exécuter la requête
        $permissions = Invoke-Sqlcmd @sqlParams -Query $query -ErrorAction Stop

        # Organiser les résultats par utilisateur
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
        Write-Error "Erreur lors de l'obtention des permissions de base de données: $($_.Exception.Message)"
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
        # Requête pour obtenir les utilisateurs de base de données et leurs propriétés
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

        # Exécuter la requête
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
        Write-Error "Erreur lors de l'obtention des utilisateurs de base de données: $($_.Exception.Message)"
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

    # Obtenir les règles de détection d'anomalies au niveau base de données
    $rules = Get-SqlPermissionRules -RuleType "Database" -Severity $Severity

    # Filtrer par ID de règle si spécifié
    if ($RuleIds.Count -gt 0) {
        $rules = $rules | Where-Object { $RuleIds -contains $_.RuleId }
    }

    # Appliquer chaque règle
    foreach ($rule in $rules) {
        Write-Verbose "Application de la règle $($rule.RuleId): $($rule.Name)"

        # Exécuter la fonction de vérification de la règle
        $ruleResults = & $rule.CheckFunction $DatabaseUsers $DatabaseRoles $DatabasePermissions $ServerLogins

        # Ajouter les résultats à la liste des anomalies
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

    # Définir les règles de détection d'anomalies
    $rules = @(
        # Règles au niveau serveur
        [PSCustomObject]@{
            RuleId        = "SVR001"
            RuleType      = "Server"
            Name          = "DisabledLoginWithPermissions"
            Description   = "Détecte les logins désactivés qui possèdent encore des permissions"
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
                            Description       = "Le login désactivé possède des permissions ou est membre de rôles serveur"
                            RecommendedAction = "Révoquer les permissions ou retirer des rôles serveur"
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
            Description   = "Détecte les comptes avec des permissions élevées (sysadmin, securityadmin, serveradmin)"
            Severity      = "Élevée"
            CheckFunction = {
                param($ServerLogins, $ServerRoles, $ServerPermissions)
                $highPrivilegeRoles = @("sysadmin", "securityadmin", "serveradmin")
                $results = @()
                foreach ($role in $ServerRoles | Where-Object { $highPrivilegeRoles -contains $_.RoleName }) {
                    foreach ($member in $role.Members) {
                        # Exclure les comptes système
                        if (-not $member.MemberName.StartsWith("##")) {
                            $results += [PSCustomObject]@{
                                LoginName         = $member.MemberName
                                Description       = "Le login est membre du rôle serveur à privilèges élevés: $($role.RoleName)"
                                RecommendedAction = "Vérifier si ce niveau de privilège est nécessaire"
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
            Description   = "Détecte les comptes SQL exemptés de la politique de mot de passe"
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
                        Description       = "Le login SQL n'est pas soumis à la politique de mot de passe complète"
                        RecommendedAction = "Activer la vérification de politique et d'expiration de mot de passe"
                    }
                }
                return $results
            }
        },
        [PSCustomObject]@{
            RuleId        = "SVR004"
            RuleType      = "Server"
            Name          = "LockedAccount"
            Description   = "Détecte les comptes verrouillés"
            Severity      = "Moyenne"
            CheckFunction = {
                param($ServerLogins, $ServerRoles, $ServerPermissions)
                $results = @()
                $lockedAccounts = $ServerLogins | Where-Object { $_.IsLocked -eq 1 }
                foreach ($login in $lockedAccounts) {
                    $results += [PSCustomObject]@{
                        LoginName         = $login.LoginName
                        Description       = "Le compte est verrouillé"
                        RecommendedAction = "Déverrouiller le compte et investiguer la cause"
                    }
                }
                return $results
            }
        },
        [PSCustomObject]@{
            RuleId        = "SVR005"
            RuleType      = "Server"
            Name          = "ControlServerPermission"
            Description   = "Détecte les comptes avec la permission CONTROL SERVER (équivalent à sysadmin)"
            Severity      = "Élevée"
            CheckFunction = {
                param($ServerLogins, $ServerRoles, $ServerPermissions)
                $results = @()
                $controlServerPermissions = $ServerPermissions | Where-Object {
                    $_.Permissions | Where-Object {
                        $_.PermissionName -eq "CONTROL SERVER" -and $_.PermissionState -eq "GRANT"
                    }
                }
                foreach ($permission in $controlServerPermissions) {
                    # Exclure les comptes système
                    if (-not $permission.GranteeName.StartsWith("##")) {
                        $results += [PSCustomObject]@{
                            LoginName         = $permission.GranteeName
                            Description       = "Le login possède la permission CONTROL SERVER (équivalent à sysadmin)"
                            RecommendedAction = "Vérifier si ce niveau de privilège est nécessaire"
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
            Description   = "Détecte si le compte SA est activé et/ou a été renommé"
            Severity      = "Élevée"
            CheckFunction = {
                param($ServerLogins, $ServerRoles, $ServerPermissions)
                $results = @()
                $saAccount = $ServerLogins | Where-Object { $_.LoginName -eq "sa" }
                if ($saAccount -and $saAccount.IsDisabled -eq 0) {
                    $results += [PSCustomObject]@{
                        LoginName         = "sa"
                        Description       = "Le compte SA est activé"
                        RecommendedAction = "Désactiver le compte SA ou le renommer pour des raisons de sécurité"
                    }
                }
                return $results
            }
        },

        # Règles au niveau base de données
        [PSCustomObject]@{
            RuleId        = "DB001"
            RuleType      = "Database"
            Name          = "OrphanedUser"
            Description   = "Détecte les utilisateurs sans login associé (utilisateurs orphelins)"
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
                        Description       = "L'utilisateur de base de données n'a pas de login associé"
                        RecommendedAction = "Supprimer l'utilisateur ou le réassocier à un login"
                    }
                }
                return $results
            }
        },
        [PSCustomObject]@{
            RuleId        = "DB002"
            RuleType      = "Database"
            Name          = "DisabledLoginWithDatabaseUser"
            Description   = "Détecte les utilisateurs de base de données associés à des logins désactivés"
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
                        Description       = "L'utilisateur est associé à un login désactivé: $($user.LoginName)"
                        RecommendedAction = "Désactiver l'utilisateur de base de données ou réactiver le login"
                    }
                }
                return $results
            }
        },
        [PSCustomObject]@{
            RuleId        = "DB003"
            RuleType      = "Database"
            Name          = "HighPrivilegeDatabaseAccount"
            Description   = "Détecte les utilisateurs avec des permissions élevées (db_owner, db_securityadmin)"
            Severity      = "Élevée"
            CheckFunction = {
                param($DatabaseUsers, $DatabaseRoles, $DatabasePermissions, $ServerLogins)
                $results = @()
                $highPrivilegeRoles = @("db_owner", "db_securityadmin", "db_accessadmin")
                foreach ($role in $DatabaseRoles | Where-Object { $highPrivilegeRoles -contains $_.RoleName }) {
                    foreach ($member in $role.Members) {
                        # Exclure les comptes système
                        if (-not $member.MemberName.StartsWith("##") -and $member.MemberName -ne "dbo") {
                            $results += [PSCustomObject]@{
                                DatabaseName      = $role.DatabaseName
                                UserName          = $member.MemberName
                                Description       = "L'utilisateur est membre du rôle de base de données à privilèges élevés: $($role.RoleName)"
                                RecommendedAction = "Vérifier si ce niveau de privilège est nécessaire"
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
            Description   = "Détecte les utilisateurs avec la permission CONTROL sur la base de données"
            Severity      = "Élevée"
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
                    # Exclure les comptes système et dbo
                    if (-not $permission.GranteeName.StartsWith("##") -and $permission.GranteeName -ne "dbo") {
                        $results += [PSCustomObject]@{
                            DatabaseName      = $permission.DatabaseName
                            UserName          = $permission.GranteeName
                            Description       = "L'utilisateur possède la permission CONTROL sur la base de données (équivalent à db_owner)"
                            RecommendedAction = "Vérifier si ce niveau de privilège est nécessaire"
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
            Description   = "Détecte si l'utilisateur guest a des permissions explicites"
            Severity      = "Élevée"
            CheckFunction = {
                param($DatabaseUsers, $DatabaseRoles, $DatabasePermissions, $ServerLogins)
                $results = @()
                $guestUsers = $DatabasePermissions | Where-Object { $_.GranteeName -eq "guest" }
                foreach ($permission in $guestUsers) {
                    $results += [PSCustomObject]@{
                        DatabaseName      = $permission.DatabaseName
                        UserName          = "guest"
                        Description       = "L'utilisateur guest possède des permissions explicites"
                        RecommendedAction = "Révoquer les permissions de l'utilisateur guest"
                    }
                }
                return $results
            }
        },
        [PSCustomObject]@{
            RuleId        = "DB006"
            RuleType      = "Database"
            Name          = "PublicRoleExcessivePermissions"
            Description   = "Détecte si le rôle public a des permissions excessives"
            Severity      = "Élevée"
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
                        Description       = "Le rôle public possède des permissions potentiellement excessives: $permNames"
                        RecommendedAction = "Révoquer les permissions excessives du rôle public"
                    }
                }
                return $results
            }
        },

        # Règles au niveau objet
        [PSCustomObject]@{
            RuleId        = "OBJ001"
            RuleType      = "Object"
            Name          = "DisabledUserWithObjectPermissions"
            Description   = "Détecte les utilisateurs désactivés avec des permissions sur des objets"
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
                            Description       = "L'utilisateur désactivé possède des permissions sur $($userObjectPermissions.ObjectCount) objets"
                            RecommendedAction = "Révoquer les permissions ou réactiver l'utilisateur si nécessaire"
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
            Description   = "Détecte si l'utilisateur guest a des permissions sur des objets"
            Severity      = "Élevée"
            CheckFunction = {
                param($ObjectPermissions, $DatabaseUsers, $DatabaseName)
                $results = @()
                $guestObjectPermissions = $ObjectPermissions | Where-Object { $_.GranteeName -eq "guest" }
                if ($guestObjectPermissions -and $guestObjectPermissions.ObjectCount -gt 0) {
                    $results += [PSCustomObject]@{
                        DatabaseName      = $DatabaseName
                        UserName          = "guest"
                        Description       = "L'utilisateur guest possède des permissions sur $($guestObjectPermissions.ObjectCount) objets"
                        RecommendedAction = "Révoquer les permissions de l'utilisateur guest"
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
            Description   = "Détecte les utilisateurs avec la permission CONTROL sur des objets"
            Severity      = "Élevée"
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
                        # Exclure les comptes système et dbo
                        if (-not $userPerm.GranteeName.StartsWith("##") -and $userPerm.GranteeName -ne "dbo") {
                            $results += [PSCustomObject]@{
                                DatabaseName      = $DatabaseName
                                UserName          = $userPerm.GranteeName
                                Description       = "L'utilisateur possède la permission CONTROL sur $($controlObjects.Count) objets"
                                RecommendedAction = "Vérifier si ce niveau de privilège est nécessaire"
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
            Description   = "Détecte les utilisateurs avec des permissions excessives sur des tables"
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
                            # Exclure les comptes système et dbo
                            if (-not $userPerm.GranteeName.StartsWith("##") -and $userPerm.GranteeName -ne "dbo") {
                                $results += [PSCustomObject]@{
                                    DatabaseName      = $DatabaseName
                                    UserName          = $userPerm.GranteeName
                                    Description       = "L'utilisateur possède des permissions potentiellement excessives sur $($excessivePermTables.Count) tables"
                                    RecommendedAction = "Vérifier si ces permissions sont nécessaires"
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
            Description   = "Détecte si le rôle public a des permissions sur des objets sensibles"
            Severity      = "Élevée"
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
                            Description       = "Le rôle public possède des permissions sensibles sur $($sensitivePermissions.Count) objets"
                            RecommendedAction = "Révoquer les permissions sensibles du rôle public"
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
            Description   = "Détecte les utilisateurs avec des permissions conflictuelles (GRANT et DENY) sur les mêmes objets"
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
                            Description       = "L'utilisateur possède des permissions conflictuelles (GRANT et DENY) sur $($conflictObjects.Count) objets"
                            RecommendedAction = "Résoudre les conflits de permissions"
                            AffectedObjects   = $conflictObjects | ForEach-Object { "$($_.ObjectName) ($($_.PermissionName))" }
                        }
                    }
                }
                return $results
            }
        }
    )

    # Filtrer les règles selon les paramètres
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

    # Obtenir les règles de détection d'anomalies au niveau serveur
    $rules = Get-SqlPermissionRules -RuleType "Server" -Severity $Severity

    # Filtrer par ID de règle si spécifié
    if ($RuleIds.Count -gt 0) {
        $rules = $rules | Where-Object { $RuleIds -contains $_.RuleId }
    }

    # Appliquer chaque règle
    foreach ($rule in $rules) {
        Write-Verbose "Application de la règle $($rule.RuleId): $($rule.Name)"

        # Exécuter la fonction de vérification de la règle
        $ruleResults = & $rule.CheckFunction $ServerLogins $ServerRoles $ServerPermissions

        # Ajouter les résultats à la liste des anomalies
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
        # Requête pour obtenir les permissions explicites au niveau objet (tables, vues, procédures stockées, etc.)
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
WHERE DPerm.class = 1  -- Objets (tables, vues, procédures stockées, etc.)
ORDER BY DP.name, O.name, DPerm.permission_name
"@

        # Exécuter la requête
        $permissions = Invoke-Sqlcmd @sqlParams -Query $query -ErrorAction Stop

        # Organiser les résultats par utilisateur/login et par objet
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
        # Requête pour obtenir les objets de base de données (tables, vues, procédures stockées, etc.)
        $query = @"
SELECT
    OBJECT_SCHEMA_NAME(object_id) AS SchemaName,
    name AS ObjectName,
    type_desc AS ObjectType,
    create_date AS CreateDate,
    modify_date AS ModifyDate,
    is_ms_shipped AS IsMsShipped
FROM sys.objects
WHERE type IN ('U', 'V', 'P', 'FN', 'IF', 'TF', 'TR')  -- Tables, vues, procédures stockées, fonctions, déclencheurs
ORDER BY type, SchemaName, name
"@

        # Exécuter la requête
        $objects = Invoke-Sqlcmd @sqlParams -Query $query -ErrorAction Stop

        # Organiser les résultats par type d'objet
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
        Write-Error "Erreur lors de l'obtention des objets de base de données: $($_.Exception.Message)"
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

    # Obtenir les règles de détection d'anomalies au niveau objet
    $rules = Get-SqlPermissionRules -RuleType "Object" -Severity $Severity

    # Filtrer par ID de règle si spécifié
    if ($RuleIds.Count -gt 0) {
        $rules = $rules | Where-Object { $RuleIds -contains $_.RuleId }
    }

    # Appliquer chaque règle
    foreach ($rule in $rules) {
        Write-Verbose "Application de la règle $($rule.RuleId): $($rule.Name)"

        # Exécuter la fonction de vérification de la règle
        $ruleResults = & $rule.CheckFunction $ObjectPermissions $DatabaseUsers $DatabaseName

        # Ajouter les résultats à la liste des anomalies
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
                # Créer un rapport HTML
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
        <p><strong>Nombre de rôles serveur:</strong> $($PermissionData.ServerRoles.Count)</p>
        <p><strong>Nombre de logins:</strong> $($PermissionData.ServerLogins.Count)</p>
        <p><strong>Nombre d'anomalies détectées au niveau serveur:</strong> $($PermissionData.ServerPermissionAnomalies.Count)</p>
        <p><strong>Analyse au niveau base de données:</strong> $($PermissionData.IncludeDatabaseLevel)</p>
        <p><strong>Nombre de bases de données analysées:</strong> $(($PermissionData.DatabaseRoles | Select-Object -Property DatabaseName -Unique).Count)</p>
        <p><strong>Nombre d'anomalies détectées au niveau base de données:</strong> $($PermissionData.DatabasePermissionAnomalies.Count)</p>
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
            <th>Sévérité</th>
            <th>Action recommandée</th>
        </tr>
"@
                    foreach ($anomaly in $PermissionData.ServerPermissionAnomalies) {
                        $severityClass = switch ($anomaly.Severity) {
                            "Élevée" { "severity-high" }
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
    <p>Aucune anomalie détectée au niveau serveur.</p>
"@
                }

                # Ajouter les anomalies au niveau base de données si l'analyse a été effectuée
                if ($PermissionData.IncludeDatabaseLevel) {
                    $htmlReport += @"

    <h2>Anomalies de permissions au niveau base de données</h2>
"@
                    if ($PermissionData.DatabasePermissionAnomalies.Count -gt 0) {
                        $htmlReport += @"
    <table>
        <tr>
            <th>Type d'anomalie</th>
            <th>Base de données</th>
            <th>Utilisateur</th>
            <th>Description</th>
            <th>Sévérité</th>
            <th>Action recommandée</th>
        </tr>
"@
                        foreach ($anomaly in $PermissionData.DatabasePermissionAnomalies) {
                            $severityClass = switch ($anomaly.Severity) {
                                "Élevée" { "severity-high" }
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
    <p>Aucune anomalie détectée au niveau base de données.</p>
"@
                    }
                }

                $htmlReport += @"
    <h2>Rôles serveur</h2>
"@

                if ($PermissionData.ServerRoles.Count -gt 0) {
                    foreach ($role in $PermissionData.ServerRoles) {
                        $htmlReport += @"
    <h3>$($role.RoleName) ($($role.MemberCount) membres)</h3>
    <table>
        <tr>
            <th>Nom du membre</th>
            <th>Type</th>
            <th>Date de création</th>
            <th>Désactivé</th>
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
    <p>Aucun rôle serveur trouvé.</p>
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
            <th>Objet sécurisable</th>
            <th>Type d'objet</th>
            <th>Permission</th>
            <th>État</th>
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
    <p>Aucune permission explicite trouvée.</p>
"@
                }

                $htmlReport += @"
    <h2>Logins SQL Server</h2>
    <table>
        <tr>
            <th>Nom du login</th>
            <th>Type</th>
            <th>Date de création</th>
            <th>Désactivé</th>
            <th>Dernier changement de mot de passe</th>
            <th>Jours avant expiration</th>
            <th>Expiré</th>
            <th>Verrouillé</th>
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

                # Ajouter les informations sur les bases de données si l'analyse a été effectuée
                if ($PermissionData.IncludeDatabaseLevel -and $PermissionData.DatabaseRoles.Count -gt 0) {
                    $htmlReport += @"

    <h2>Rôles de base de données</h2>
"@

                    # Regrouper par base de données
                    $databaseNames = $PermissionData.DatabaseRoles | Select-Object -Property DatabaseName -Unique | ForEach-Object { $_.DatabaseName }

                    foreach ($dbName in $databaseNames) {
                        $htmlReport += @"
    <h3>Base de données: $dbName</h3>
"@

                        $dbRoles = $PermissionData.DatabaseRoles | Where-Object { $_.DatabaseName -eq $dbName }

                        foreach ($role in $dbRoles) {
                            $htmlReport += @"
    <h4>$($role.RoleName) ($($role.MemberCount) membres)</h4>
    <table>
        <tr>
            <th>Nom du membre</th>
            <th>Type</th>
            <th>Date de création</th>
            <th>Désactivé</th>
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

    <h2>Permissions de base de données</h2>
"@

                    foreach ($dbName in $databaseNames) {
                        $htmlReport += @"
    <h3>Base de données: $dbName</h3>
"@

                        $dbPermissions = $PermissionData.DatabasePermissions | Where-Object { $_.DatabaseName -eq $dbName }

                        if ($dbPermissions.Count -gt 0) {
                            foreach ($grantee in $dbPermissions) {
                                $htmlReport += @"
    <h4>$($grantee.GranteeName) ($($grantee.GranteeType)) - $($grantee.PermissionCount) permissions</h4>
    <table>
        <tr>
            <th>Objet sécurisable</th>
            <th>Type d'objet</th>
            <th>Permission</th>
            <th>État</th>
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
    <p>Aucune permission explicite trouvée pour cette base de données.</p>
"@
                        }
                    }

                    $htmlReport += @"

    <h2>Utilisateurs de base de données</h2>
"@

                    foreach ($dbName in $databaseNames) {
                        $htmlReport += @"
    <h3>Base de données: $dbName</h3>
    <table>
        <tr>
            <th>Nom de l'utilisateur</th>
            <th>Type</th>
            <th>Login associé</th>
            <th>Schéma par défaut</th>
            <th>Date de création</th>
            <th>Désactivé</th>
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

                # Ajouter les informations sur les objets et leurs permissions si l'analyse a été effectuée
                if ($PermissionData.IncludeObjectLevel -and $PermissionData.ObjectPermissions.Count -gt 0) {
                    $htmlReport += @"

    <h2>Permissions au niveau objet</h2>
"@

                    # Regrouper par base de données
                    $databaseNames = $PermissionData.ObjectPermissions | Select-Object -Property DatabaseName -Unique | ForEach-Object { $_.DatabaseName }

                    foreach ($dbName in $databaseNames) {
                        $htmlReport += @"
    <h3>Base de données: $dbName</h3>
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
    <p>Aucune permission au niveau objet trouvée pour cette base de données.</p>
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
            <th>Base de données</th>
            <th>Utilisateur</th>
            <th>Description</th>
            <th>Sévérité</th>
            <th>Action recommandée</th>
            <th>Objets affectés</th>
        </tr>
"@
                        foreach ($anomaly in $PermissionData.ObjectPermissionAnomalies) {
                            $severityClass = switch ($anomaly.Severity) {
                                "Élevée" { "severity-high" }
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
    <p>Aucune anomalie détectée au niveau objet.</p>
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
                # Créer un rapport CSV pour chaque section

                # Anomalies au niveau serveur
                if ($PermissionData.ServerPermissionAnomalies.Count -gt 0) {
                    $csvPath = [System.IO.Path]::ChangeExtension($OutputPath, "server_anomalies.csv")
                    $PermissionData.ServerPermissionAnomalies | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
                }

                # Anomalies au niveau base de données
                if ($PermissionData.IncludeDatabaseLevel -and $PermissionData.DatabasePermissionAnomalies.Count -gt 0) {
                    $csvPath = [System.IO.Path]::ChangeExtension($OutputPath, "database_anomalies.csv")
                    $PermissionData.DatabasePermissionAnomalies | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
                }

                # Rôles serveur
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

                # Exporter les données de base de données si l'analyse a été effectuée
                if ($PermissionData.IncludeDatabaseLevel) {
                    # Rôles de base de données
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

                    # Permissions de base de données
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

                    # Utilisateurs de base de données
                    if ($PermissionData.DatabaseUsers.Count -gt 0) {
                        $csvPath = [System.IO.Path]::ChangeExtension($OutputPath, "database_users.csv")
                        $PermissionData.DatabaseUsers | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
                    }
                }

                # Exporter les données au niveau objet si l'analyse a été effectuée
                if ($PermissionData.IncludeObjectLevel) {
                    # Anomalies au niveau objet
                    if ($PermissionData.ObjectPermissionAnomalies.Count -gt 0) {
                        $csvPath = [System.IO.Path]::ChangeExtension($OutputPath, "object_anomalies.csv")
                        $PermissionData.ObjectPermissionAnomalies | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
                    }

                    # Objets de base de données
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
                # Créer un rapport JSON
                $PermissionData | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
            }
            "XML" {
                # Créer un rapport XML
                $PermissionData | Export-Clixml -Path $OutputPath -Encoding UTF8
            }
        }

        Write-Verbose "Rapport de permissions exporté avec succès: $OutputPath"
    } catch {
        Write-Error "Erreur lors de l'exportation du rapport de permissions: $($_.Exception.Message)"
    }
}

# Pas besoin d'exporter la fonction ici, elle sera exportée par le module
