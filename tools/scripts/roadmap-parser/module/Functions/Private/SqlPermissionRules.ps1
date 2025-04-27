# SqlPermissionRules.ps1
# Contient les règles de détection d'anomalies pour les permissions SQL Server

function Get-SqlPermissionRules {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Server", "Database", "Object")]
        [string]$RuleType,

        [Parameter(Mandatory = $false)]
        [ValidateSet("All", "Élevée", "Moyenne", "Faible")]
        [string]$Severity = "All"
    )

    # Définir toutes les règles
    $allRules = @()

    # Règles au niveau serveur
    if ($RuleType -eq "Server") {
        $allRules += @(
            [PSCustomObject]@{
                RuleId = "SVR-001"
                Name = "DisabledLoginWithPermissions"
                Description = "Détecte les logins désactivés qui possèdent des permissions ou sont membres de rôles serveur"
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
                                Description = "Le login désactivé possède des permissions ou est membre de rôles serveur"
                                RecommendedAction = "Révoquer les permissions ou retirer des rôles serveur"
                            }
                        }
                    }
                    
                    return $results
                }
            },
            [PSCustomObject]@{
                RuleId = "SVR-002"
                Name = "HighPrivilegeAccount"
                Description = "Détecte les logins membres de rôles serveur à privilèges élevés (sysadmin, securityadmin, serveradmin)"
                Severity = "Élevée"
                RuleType = "Server"
                CheckFunction = {
                    param($ServerLogins, $ServerRoles, $ServerPermissions)
                    $results = @()
                    
                    $highPrivilegeRoles = @("sysadmin", "securityadmin", "serveradmin")
                    foreach ($role in $ServerRoles | Where-Object { $highPrivilegeRoles -contains $_.RoleName }) {
                        foreach ($member in $role.Members) {
                            # Exclure les comptes système
                            if (-not $member.MemberName.StartsWith("##")) {
                                $results += [PSCustomObject]@{
                                    LoginName = $member.MemberName
                                    Description = "Le login est membre du rôle serveur à privilèges élevés: $($role.RoleName)"
                                    RecommendedAction = "Vérifier si ce niveau de privilège est nécessaire"
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
                Description = "Détecte les logins SQL exemptés de la politique de mot de passe"
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
                            Description = "Le login SQL n'est pas soumis à la politique de mot de passe complète"
                            RecommendedAction = "Activer la vérification de politique et d'expiration de mot de passe"
                        }
                    }
                    
                    return $results
                }
            },
            [PSCustomObject]@{
                RuleId = "SVR-004"
                Name = "LockedAccount"
                Description = "Détecte les logins verrouillés"
                Severity = "Moyenne"
                RuleType = "Server"
                CheckFunction = {
                    param($ServerLogins, $ServerRoles, $ServerPermissions)
                    $results = @()
                    
                    $lockedAccounts = $ServerLogins | Where-Object { $_.IsLocked -eq 1 }
                    foreach ($login in $lockedAccounts) {
                        $results += [PSCustomObject]@{
                            LoginName = $login.LoginName
                            Description = "Le compte est verrouillé"
                            RecommendedAction = "Déverrouiller le compte et investiguer la cause"
                        }
                    }
                    
                    return $results
                }
            },
            [PSCustomObject]@{
                RuleId = "SVR-005"
                Name = "ControlServerPermission"
                Description = "Détecte les logins avec la permission CONTROL SERVER (équivalent à sysadmin)"
                Severity = "Élevée"
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
                        # Exclure les comptes système
                        if (-not $permission.GranteeName.StartsWith("##")) {
                            $results += [PSCustomObject]@{
                                LoginName = $permission.GranteeName
                                Description = "Le login possède la permission CONTROL SERVER (équivalent à sysadmin)"
                                RecommendedAction = "Vérifier si ce niveau de privilège est nécessaire"
                            }
                        }
                    }
                    
                    return $results
                }
            },
            [PSCustomObject]@{
                RuleId = "SVR-006"
                Name = "ExpiredPassword"
                Description = "Détecte les logins SQL avec des mots de passe expirés"
                Severity = "Moyenne"
                RuleType = "Server"
                CheckFunction = {
                    param($ServerLogins, $ServerRoles, $ServerPermissions)
                    $results = @()
                    
                    $expiredPasswords = $ServerLogins | Where-Object { $_.IsExpired -eq 1 -and $_.LoginType -eq "SQL_LOGIN" }
                    foreach ($login in $expiredPasswords) {
                        $results += [PSCustomObject]@{
                            LoginName = $login.LoginName
                            Description = "Le mot de passe du login SQL est expiré"
                            RecommendedAction = "Changer le mot de passe du compte"
                        }
                    }
                    
                    return $results
                }
            }
        )
    }
    
    # Règles au niveau base de données
    elseif ($RuleType -eq "Database") {
        $allRules += @(
            [PSCustomObject]@{
                RuleId = "DB-001"
                Name = "OrphanedUser"
                Description = "Détecte les utilisateurs de base de données sans login associé"
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
                            Description = "L'utilisateur de base de données n'a pas de login associé"
                            RecommendedAction = "Supprimer l'utilisateur ou le réassocier à un login"
                        }
                    }
                    
                    return $results
                }
            },
            [PSCustomObject]@{
                RuleId = "DB-002"
                Name = "DisabledLoginWithDatabasePermissions"
                Description = "Détecte les utilisateurs associés à des logins désactivés mais ayant des permissions"
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
                                Description = "L'utilisateur est associé à un login désactivé mais possède des permissions ou est membre de rôles"
                                RecommendedAction = "Révoquer les permissions ou retirer des rôles de base de données"
                            }
                        }
                    }
                    
                    return $results
                }
            },
            [PSCustomObject]@{
                RuleId = "DB-003"
                Name = "HighPrivilegeDatabaseAccount"
                Description = "Détecte les utilisateurs membres de rôles de base de données à privilèges élevés"
                Severity = "Élevée"
                RuleType = "Database"
                CheckFunction = {
                    param($DatabaseUsers, $DatabaseRoles, $DatabasePermissions, $ServerLogins)
                    $results = @()
                    
                    $highPrivilegeRoles = @("db_owner", "db_securityadmin", "db_accessadmin")
                    foreach ($role in $DatabaseRoles | Where-Object { $highPrivilegeRoles -contains $_.RoleName }) {
                        foreach ($member in $role.Members) {
                            # Exclure les comptes système
                            if (-not $member.MemberName.StartsWith("##") -and $member.MemberName -ne "dbo") {
                                $results += [PSCustomObject]@{
                                    DatabaseName = $role.DatabaseName
                                    UserName = $member.MemberName
                                    Description = "L'utilisateur est membre du rôle de base de données à privilèges élevés: $($role.RoleName)"
                                    RecommendedAction = "Vérifier si ce niveau de privilège est nécessaire"
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
                Description = "Détecte les utilisateurs avec la permission CONTROL sur la base de données"
                Severity = "Élevée"
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
                        # Exclure les comptes système et dbo
                        if (-not $permission.GranteeName.StartsWith("##") -and $permission.GranteeName -ne "dbo") {
                            $results += [PSCustomObject]@{
                                DatabaseName = $permission.DatabaseName
                                UserName = $permission.GranteeName
                                Description = "L'utilisateur possède la permission CONTROL sur la base de données (équivalent à db_owner)"
                                RecommendedAction = "Vérifier si ce niveau de privilège est nécessaire"
                            }
                        }
                    }
                    
                    return $results
                }
            },
            [PSCustomObject]@{
                RuleId = "DB-005"
                Name = "GuestUserPermissions"
                Description = "Détecte les permissions explicites accordées à l'utilisateur guest"
                Severity = "Élevée"
                RuleType = "Database"
                CheckFunction = {
                    param($DatabaseUsers, $DatabaseRoles, $DatabasePermissions, $ServerLogins)
                    $results = @()
                    
                    $guestUsers = $DatabasePermissions | Where-Object { $_.GranteeName -eq "guest" }
                    foreach ($permission in $guestUsers) {
                        $results += [PSCustomObject]@{
                            DatabaseName = $permission.DatabaseName
                            UserName = "guest"
                            Description = "L'utilisateur guest possède des permissions explicites"
                            RecommendedAction = "Révoquer les permissions de l'utilisateur guest"
                        }
                    }
                    
                    return $results
                }
            }
        )
    }
    
    # Règles au niveau objet
    elseif ($RuleType -eq "Object") {
        $allRules += @(
            [PSCustomObject]@{
                RuleId = "OBJ-001"
                Name = "DisabledUserWithObjectPermissions"
                Description = "Détecte les utilisateurs désactivés avec des permissions sur des objets"
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
                                Description = "L'utilisateur désactivé possède des permissions sur $($userObjectPermissions.ObjectCount) objets"
                                RecommendedAction = "Révoquer les permissions ou réactiver l'utilisateur si nécessaire"
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
                Description = "Détecte les permissions accordées à l'utilisateur guest sur des objets"
                Severity = "Élevée"
                RuleType = "Object"
                CheckFunction = {
                    param($ObjectPermissions, $DatabaseUsers, $DatabaseName)
                    $results = @()
                    
                    $guestObjectPermissions = $ObjectPermissions | Where-Object { $_.GranteeName -eq "guest" }
                    if ($guestObjectPermissions -and $guestObjectPermissions.ObjectCount -gt 0) {
                        $results += [PSCustomObject]@{
                            DatabaseName = $DatabaseName
                            UserName = "guest"
                            Description = "L'utilisateur guest possède des permissions sur $($guestObjectPermissions.ObjectCount) objets"
                            RecommendedAction = "Révoquer les permissions de l'utilisateur guest"
                            AffectedObjects = $guestObjectPermissions.ObjectPermissions | ForEach-Object { $_.ObjectName }
                        }
                    }
                    
                    return $results
                }
            },
            [PSCustomObject]@{
                RuleId = "OBJ-003"
                Name = "ControlObjectPermission"
                Description = "Détecte les utilisateurs avec la permission CONTROL sur des objets"
                Severity = "Élevée"
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
                            # Exclure les comptes système et dbo
                            if (-not $userPerm.GranteeName.StartsWith("##") -and $userPerm.GranteeName -ne "dbo") {
                                $results += [PSCustomObject]@{
                                    DatabaseName = $DatabaseName
                                    UserName = $userPerm.GranteeName
                                    Description = "L'utilisateur possède la permission CONTROL sur $($controlObjects.Count) objets"
                                    RecommendedAction = "Vérifier si ce niveau de privilège est nécessaire"
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
                Description = "Détecte les utilisateurs avec des permissions potentiellement excessives sur des tables"
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
                                # Exclure les comptes système et dbo
                                if (-not $userPerm.GranteeName.StartsWith("##") -and $userPerm.GranteeName -ne "dbo") {
                                    $results += [PSCustomObject]@{
                                        DatabaseName = $DatabaseName
                                        UserName = $userPerm.GranteeName
                                        Description = "L'utilisateur possède des permissions potentiellement excessives sur $($excessivePermTables.Count) tables"
                                        RecommendedAction = "Vérifier si ces permissions sont nécessaires"
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

    # Filtrer par sévérité si demandé
    if ($Severity -ne "All") {
        $allRules = $allRules | Where-Object { $_.Severity -eq $Severity }
    }

    return $allRules
}

# Exporter la fonction
Export-ModuleMember -Function Get-SqlPermissionRules
