# SqlPermissionRules.ps1
# Contient les rÃ¨gles de dÃ©tection d'anomalies pour les permissions SQL Server

function Get-SqlPermissionRules {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Server", "Database", "Object")]
        [string]$RuleType,

        [Parameter(Mandatory = $false)]
        [ValidateSet("All", "Ã‰levÃ©e", "Moyenne", "Faible")]
        [string]$Severity = "All"
    )

    # DÃ©finir toutes les rÃ¨gles
    $allRules = @()

    # RÃ¨gles au niveau serveur
    if ($RuleType -eq "Server") {
        $allRules += @(
            [PSCustomObject]@{
                RuleId = "SVR-001"
                Name = "DisabledLoginWithPermissions"
                Description = "DÃ©tecte les logins dÃ©sactivÃ©s qui possÃ¨dent des permissions ou sont membres de rÃ´les serveur"
                Severity = "Moyenne"
                RuleType = "Server"
                CheckFunction = {
                    param($ServerLogins, $ServerRoles, $ServerPermissions)
                    $results = @()
                    
                    $disabledLoginsWithPermissions = $ServerLogins | Where-Object { $_.IsDisabled -eq $true }
                    foreach ($login in $disabledLoginsWithPermissions) {
                        $hasPermissions = $ServerPermissions | Where-Object { $_.GranteeName -eq $login.LoginName }
                        $isRoleMember = $ServerRoles | ForEach-Object { $_.Members } | Where-Object { $_.MemberName -eq $login.LoginName }

                        if ($hasPermissions -or $isRoleMember) {
                            $results += [PSCustomObject]@{
                                LoginName = $login.LoginName
                                Description = "Le login dÃ©sactivÃ© possÃ¨de des permissions ou est membre de rÃ´les serveur"
                                RecommendedAction = "RÃ©voquer les permissions ou retirer des rÃ´les serveur"
                            }
                        }
                    }
                    
                    return $results
                }
            },
            [PSCustomObject]@{
                RuleId = "SVR-002"
                Name = "HighPrivilegeAccount"
                Description = "DÃ©tecte les logins membres de rÃ´les serveur Ã  privilÃ¨ges Ã©levÃ©s (sysadmin, securityadmin, serveradmin)"
                Severity = "Ã‰levÃ©e"
                RuleType = "Server"
                CheckFunction = {
                    param($ServerLogins, $ServerRoles, $ServerPermissions)
                    $results = @()
                    
                    $highPrivilegeRoles = @("sysadmin", "securityadmin", "serveradmin")
                    foreach ($role in $ServerRoles | Where-Object { $highPrivilegeRoles -contains $_.RoleName }) {
                        foreach ($member in $role.Members) {
                            # Exclure les comptes systÃ¨me
                            if (-not $member.MemberName.StartsWith("##")) {
                                $results += [PSCustomObject]@{
                                    LoginName = $member.MemberName
                                    Description = "Le login est membre du rÃ´le serveur Ã  privilÃ¨ges Ã©levÃ©s: $($role.RoleName)"
                                    RecommendedAction = "VÃ©rifier si ce niveau de privilÃ¨ge est nÃ©cessaire"
                                }
                            }
                        }
                    }
                    
                    return $results
                }
            },
            [PSCustomObject]@{
                RuleId = "SVR-003"
                Name = "PasswordPolicyExempt"
                Description = "DÃ©tecte les logins SQL exemptÃ©s de la politique de mot de passe"
                Severity = "Moyenne"
                RuleType = "Server"
                CheckFunction = {
                    param($ServerLogins, $ServerRoles, $ServerPermissions)
                    $results = @()
                    
                    $sqlLoginsWithoutPolicy = $ServerLogins | Where-Object { 
                        $_.LoginType -eq "SQL_LOGIN" -and 
                        ($_.IsPolicyChecked -eq 0 -or $_.IsExpirationChecked -eq 0)
                    }
                    foreach ($login in $sqlLoginsWithoutPolicy) {
                        $results += [PSCustomObject]@{
                            LoginName = $login.LoginName
                            Description = "Le login SQL n'est pas soumis Ã  la politique de mot de passe complÃ¨te"
                            RecommendedAction = "Activer la vÃ©rification de politique et d'expiration de mot de passe"
                        }
                    }
                    
                    return $results
                }
            },
            [PSCustomObject]@{
                RuleId = "SVR-004"
                Name = "LockedAccount"
                Description = "DÃ©tecte les logins verrouillÃ©s"
                Severity = "Moyenne"
                RuleType = "Server"
                CheckFunction = {
                    param($ServerLogins, $ServerRoles, $ServerPermissions)
                    $results = @()
                    
                    $lockedAccounts = $ServerLogins | Where-Object { $_.IsLocked -eq 1 }
                    foreach ($login in $lockedAccounts) {
                        $results += [PSCustomObject]@{
                            LoginName = $login.LoginName
                            Description = "Le compte est verrouillÃ©"
                            RecommendedAction = "DÃ©verrouiller le compte et investiguer la cause"
                        }
                    }
                    
                    return $results
                }
            },
            [PSCustomObject]@{
                RuleId = "SVR-005"
                Name = "ControlServerPermission"
                Description = "DÃ©tecte les logins avec la permission CONTROL SERVER (Ã©quivalent Ã  sysadmin)"
                Severity = "Ã‰levÃ©e"
                RuleType = "Server"
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
                                LoginName = $permission.GranteeName
                                Description = "Le login possÃ¨de la permission CONTROL SERVER (Ã©quivalent Ã  sysadmin)"
                                RecommendedAction = "VÃ©rifier si ce niveau de privilÃ¨ge est nÃ©cessaire"
                            }
                        }
                    }
                    
                    return $results
                }
            },
            [PSCustomObject]@{
                RuleId = "SVR-006"
                Name = "ExpiredPassword"
                Description = "DÃ©tecte les logins SQL avec des mots de passe expirÃ©s"
                Severity = "Moyenne"
                RuleType = "Server"
                CheckFunction = {
                    param($ServerLogins, $ServerRoles, $ServerPermissions)
                    $results = @()
                    
                    $expiredPasswords = $ServerLogins | Where-Object { $_.IsExpired -eq 1 -and $_.LoginType -eq "SQL_LOGIN" }
                    foreach ($login in $expiredPasswords) {
                        $results += [PSCustomObject]@{
                            LoginName = $login.LoginName
                            Description = "Le mot de passe du login SQL est expirÃ©"
                            RecommendedAction = "Changer le mot de passe du compte"
                        }
                    }
                    
                    return $results
                }
            }
        )
    }
    
    # RÃ¨gles au niveau base de donnÃ©es
    elseif ($RuleType -eq "Database") {
        $allRules += @(
            [PSCustomObject]@{
                RuleId = "DB-001"
                Name = "OrphanedUser"
                Description = "DÃ©tecte les utilisateurs de base de donnÃ©es sans login associÃ©"
                Severity = "Moyenne"
                RuleType = "Database"
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
                            DatabaseName = $user.DatabaseName
                            UserName = $user.UserName
                            Description = "L'utilisateur de base de donnÃ©es n'a pas de login associÃ©"
                            RecommendedAction = "Supprimer l'utilisateur ou le rÃ©associer Ã  un login"
                        }
                    }
                    
                    return $results
                }
            },
            [PSCustomObject]@{
                RuleId = "DB-002"
                Name = "DisabledLoginWithDatabasePermissions"
                Description = "DÃ©tecte les utilisateurs associÃ©s Ã  des logins dÃ©sactivÃ©s mais ayant des permissions"
                Severity = "Moyenne"
                RuleType = "Database"
                CheckFunction = {
                    param($DatabaseUsers, $DatabaseRoles, $DatabasePermissions, $ServerLogins)
                    $results = @()
                    
                    $disabledLoginUsers = $DatabaseUsers | Where-Object { $_.IsDisabled -eq $true }
                    foreach ($user in $disabledLoginUsers) {
                        $hasPermissions = $DatabasePermissions | Where-Object { 
                            $_.DatabaseName -eq $user.DatabaseName -and $_.GranteeName -eq $user.UserName 
                        }
                        $isRoleMember = $DatabaseRoles | Where-Object { 
                            $_.DatabaseName -eq $user.DatabaseName 
                        } | ForEach-Object { 
                            $_.Members 
                        } | Where-Object { 
                            $_.MemberName -eq $user.UserName 
                        }

                        if ($hasPermissions -or $isRoleMember) {
                            $results += [PSCustomObject]@{
                                DatabaseName = $user.DatabaseName
                                UserName = $user.UserName
                                Description = "L'utilisateur est associÃ© Ã  un login dÃ©sactivÃ© mais possÃ¨de des permissions ou est membre de rÃ´les"
                                RecommendedAction = "RÃ©voquer les permissions ou retirer des rÃ´les de base de donnÃ©es"
                            }
                        }
                    }
                    
                    return $results
                }
            },
            [PSCustomObject]@{
                RuleId = "DB-003"
                Name = "HighPrivilegeDatabaseAccount"
                Description = "DÃ©tecte les utilisateurs membres de rÃ´les de base de donnÃ©es Ã  privilÃ¨ges Ã©levÃ©s"
                Severity = "Ã‰levÃ©e"
                RuleType = "Database"
                CheckFunction = {
                    param($DatabaseUsers, $DatabaseRoles, $DatabasePermissions, $ServerLogins)
                    $results = @()
                    
                    $highPrivilegeRoles = @("db_owner", "db_securityadmin", "db_accessadmin")
                    foreach ($role in $DatabaseRoles | Where-Object { $highPrivilegeRoles -contains $_.RoleName }) {
                        foreach ($member in $role.Members) {
                            # Exclure les comptes systÃ¨me
                            if (-not $member.MemberName.StartsWith("##") -and $member.MemberName -ne "dbo") {
                                $results += [PSCustomObject]@{
                                    DatabaseName = $role.DatabaseName
                                    UserName = $member.MemberName
                                    Description = "L'utilisateur est membre du rÃ´le de base de donnÃ©es Ã  privilÃ¨ges Ã©levÃ©s: $($role.RoleName)"
                                    RecommendedAction = "VÃ©rifier si ce niveau de privilÃ¨ge est nÃ©cessaire"
                                }
                            }
                        }
                    }
                    
                    return $results
                }
            },
            [PSCustomObject]@{
                RuleId = "DB-004"
                Name = "ControlDatabasePermission"
                Description = "DÃ©tecte les utilisateurs avec la permission CONTROL sur la base de donnÃ©es"
                Severity = "Ã‰levÃ©e"
                RuleType = "Database"
                CheckFunction = {
                    param($DatabaseUsers, $DatabaseRoles, $DatabasePermissions, $ServerLogins)
                    $results = @()
                    
                    $controlDatabasePermissions = $DatabasePermissions | Where-Object {
                        $_.Permissions | Where-Object {
                            $_.PermissionName -eq "CONTROL" -and 
                            $_.SecurableType -eq "DATABASE" -and 
                            $_.PermissionState -eq "GRANT"
                        }
                    }

                    foreach ($permission in $controlDatabasePermissions) {
                        # Exclure les comptes systÃ¨me et dbo
                        if (-not $permission.GranteeName.StartsWith("##") -and $permission.GranteeName -ne "dbo") {
                            $results += [PSCustomObject]@{
                                DatabaseName = $permission.DatabaseName
                                UserName = $permission.GranteeName
                                Description = "L'utilisateur possÃ¨de la permission CONTROL sur la base de donnÃ©es (Ã©quivalent Ã  db_owner)"
                                RecommendedAction = "VÃ©rifier si ce niveau de privilÃ¨ge est nÃ©cessaire"
                            }
                        }
                    }
                    
                    return $results
                }
            },
            [PSCustomObject]@{
                RuleId = "DB-005"
                Name = "GuestUserPermissions"
                Description = "DÃ©tecte les permissions explicites accordÃ©es Ã  l'utilisateur guest"
                Severity = "Ã‰levÃ©e"
                RuleType = "Database"
                CheckFunction = {
                    param($DatabaseUsers, $DatabaseRoles, $DatabasePermissions, $ServerLogins)
                    $results = @()
                    
                    $guestUsers = $DatabasePermissions | Where-Object { $_.GranteeName -eq "guest" }
                    foreach ($permission in $guestUsers) {
                        $results += [PSCustomObject]@{
                            DatabaseName = $permission.DatabaseName
                            UserName = "guest"
                            Description = "L'utilisateur guest possÃ¨de des permissions explicites"
                            RecommendedAction = "RÃ©voquer les permissions de l'utilisateur guest"
                        }
                    }
                    
                    return $results
                }
            }
        )
    }
    
    # RÃ¨gles au niveau objet
    elseif ($RuleType -eq "Object") {
        $allRules += @(
            [PSCustomObject]@{
                RuleId = "OBJ-001"
                Name = "DisabledUserWithObjectPermissions"
                Description = "DÃ©tecte les utilisateurs dÃ©sactivÃ©s avec des permissions sur des objets"
                Severity = "Moyenne"
                RuleType = "Object"
                CheckFunction = {
                    param($ObjectPermissions, $DatabaseUsers, $DatabaseName)
                    $results = @()
                    
                    $disabledUsers = $DatabaseUsers | Where-Object { $_.IsDisabled -eq 1 }
                    foreach ($user in $disabledUsers) {
                        $userObjectPermissions = $ObjectPermissions | Where-Object { $_.GranteeName -eq $user.UserName }
                        
                        if ($userObjectPermissions -and $userObjectPermissions.ObjectCount -gt 0) {
                            $results += [PSCustomObject]@{
                                DatabaseName = $DatabaseName
                                UserName = $user.UserName
                                Description = "L'utilisateur dÃ©sactivÃ© possÃ¨de des permissions sur $($userObjectPermissions.ObjectCount) objets"
                                RecommendedAction = "RÃ©voquer les permissions ou rÃ©activer l'utilisateur si nÃ©cessaire"
                                AffectedObjects = $userObjectPermissions.ObjectPermissions | ForEach-Object { $_.ObjectName }
                            }
                        }
                    }
                    
                    return $results
                }
            },
            [PSCustomObject]@{
                RuleId = "OBJ-002"
                Name = "GuestUserWithObjectPermissions"
                Description = "DÃ©tecte les permissions accordÃ©es Ã  l'utilisateur guest sur des objets"
                Severity = "Ã‰levÃ©e"
                RuleType = "Object"
                CheckFunction = {
                    param($ObjectPermissions, $DatabaseUsers, $DatabaseName)
                    $results = @()
                    
                    $guestObjectPermissions = $ObjectPermissions | Where-Object { $_.GranteeName -eq "guest" }
                    if ($guestObjectPermissions -and $guestObjectPermissions.ObjectCount -gt 0) {
                        $results += [PSCustomObject]@{
                            DatabaseName = $DatabaseName
                            UserName = "guest"
                            Description = "L'utilisateur guest possÃ¨de des permissions sur $($guestObjectPermissions.ObjectCount) objets"
                            RecommendedAction = "RÃ©voquer les permissions de l'utilisateur guest"
                            AffectedObjects = $guestObjectPermissions.ObjectPermissions | ForEach-Object { $_.ObjectName }
                        }
                    }
                    
                    return $results
                }
            },
            [PSCustomObject]@{
                RuleId = "OBJ-003"
                Name = "ControlObjectPermission"
                Description = "DÃ©tecte les utilisateurs avec la permission CONTROL sur des objets"
                Severity = "Ã‰levÃ©e"
                RuleType = "Object"
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
                                    DatabaseName = $DatabaseName
                                    UserName = $userPerm.GranteeName
                                    Description = "L'utilisateur possÃ¨de la permission CONTROL sur $($controlObjects.Count) objets"
                                    RecommendedAction = "VÃ©rifier si ce niveau de privilÃ¨ge est nÃ©cessaire"
                                    AffectedObjects = $controlObjects | ForEach-Object { $_.ObjectName }
                                }
                            }
                        }
                    }
                    
                    return $results
                }
            },
            [PSCustomObject]@{
                RuleId = "OBJ-004"
                Name = "ExcessiveTablePermissions"
                Description = "DÃ©tecte les utilisateurs avec des permissions potentiellement excessives sur des tables"
                Severity = "Moyenne"
                RuleType = "Object"
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
                                        DatabaseName = $DatabaseName
                                        UserName = $userPerm.GranteeName
                                        Description = "L'utilisateur possÃ¨de des permissions potentiellement excessives sur $($excessivePermTables.Count) tables"
                                        RecommendedAction = "VÃ©rifier si ces permissions sont nÃ©cessaires"
                                        AffectedObjects = $excessivePermTables | ForEach-Object { $_.ObjectName }
                                    }
                                }
                            }
                        }
                    }
                    
                    return $results
                }
            }
        )
    }

    # Filtrer par sÃ©vÃ©ritÃ© si demandÃ©
    if ($Severity -ne "All") {
        $allRules = $allRules | Where-Object { $_.Severity -eq $Severity }
    }

    return $allRules
}

# Exporter la fonction
Export-ModuleMember -Function Get-SqlPermissionRules
