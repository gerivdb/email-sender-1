    param($ServerLogins, $ServerRoles, $ServerPermissions, $DatabaseRoles, $DatabasePermissions, $DatabaseUsers)
    $results = @()
    
    # 1. DÃ©tecter les comptes dÃ©sactivÃ©s mais membres de rÃ´les
    $disabledLogins = $ServerLogins | Where-Object { $_.IsDisabled -eq $true }
    
    foreach ($login in $disabledLogins) {
        # VÃ©rifier si le login est membre d'un rÃ´le serveur
        $isServerRoleMember = $false
        foreach ($role in $ServerRoles) {
            if ($role.Members | Where-Object { $_.MemberName -eq $login.LoginName }) {
                $isServerRoleMember = $true
                break
            }
        }
        
        if ($isServerRoleMember) {
            $results += [PSCustomObject]@{
                LoginName = $login.LoginName
                Description = "Le login est dÃ©sactivÃ© mais est toujours membre de rÃ´les serveur"
                RecommendedAction = "Retirer le login des rÃ´les serveur avant de le dÃ©sactiver"
            }
        }
        
        # VÃ©rifier si le login a des utilisateurs de base de donnÃ©es associÃ©s qui sont membres de rÃ´les
        $dbUsers = $DatabaseUsers | Where-Object { $_.LoginName -eq $login.LoginName }
        
        foreach ($dbUser in $dbUsers) {
            $isDbRoleMember = $false
            foreach ($role in $DatabaseRoles | Where-Object { $_.DatabaseName -eq $dbUser.DatabaseName }) {
                if ($role.Members | Where-Object { $_.MemberName -eq $dbUser.UserName }) {
                    $isDbRoleMember = $true
                    break
                }
            }
            
            if ($isDbRoleMember) {
                $results += [PSCustomObject]@{
                    LoginName = $login.LoginName
                    Description = "Le login est dÃ©sactivÃ© mais son utilisateur de base de donnÃ©es '$($dbUser.UserName)' dans '$($dbUser.DatabaseName)' est toujours membre de rÃ´les"
                    RecommendedAction = "Retirer l'utilisateur des rÃ´les de base de donnÃ©es avant de dÃ©sactiver le login"
                }
            }
        }
    }
    
    # 2. DÃ©tecter les permissions DENY et GRANT contradictoires au niveau serveur
    foreach ($login in $ServerPermissions) {
        $permissionNames = $login.Permissions | ForEach-Object { $_.PermissionName } | Select-Object -Unique
        
        foreach ($permName in $permissionNames) {
            $grantedPerm = $login.Permissions | Where-Object { $_.PermissionName -eq $permName -and $_.PermissionState -eq "GRANT" }
            $deniedPerm = $login.Permissions | Where-Object { $_.PermissionName -eq $permName -and $_.PermissionState -eq "DENY" }
            
            if ($grantedPerm -and $deniedPerm) {
                $results += [PSCustomObject]@{
                    LoginName = $login.GranteeName
                    Description = "Le login a des permissions contradictoires: $permName est Ã  la fois GRANT et DENY"
                    RecommendedAction = "RÃ©soudre la contradiction en supprimant l'une des permissions"
                }
            }
        }
    }
    
    # 3. DÃ©tecter les permissions DENY et GRANT contradictoires au niveau base de donnÃ©es
    foreach ($dbPerm in $DatabasePermissions) {
        $permissionNames = $dbPerm.Permissions | ForEach-Object { $_.PermissionName } | Select-Object -Unique
        
        foreach ($permName in $permissionNames) {
            $grantedPerm = $dbPerm.Permissions | Where-Object { $_.PermissionName -eq $permName -and $_.PermissionState -eq "GRANT" }
            $deniedPerm = $dbPerm.Permissions | Where-Object { $_.PermissionName -eq $permName -and $_.PermissionState -eq "DENY" }
            
            if ($grantedPerm -and $deniedPerm) {
                $results += [PSCustomObject]@{
                    LoginName = $dbPerm.GranteeName
                    Description = "L'utilisateur '$($dbPerm.GranteeName)' dans la base de donnÃ©es '$($dbPerm.DatabaseName)' a des permissions contradictoires: $permName est Ã  la fois GRANT et DENY"
                    RecommendedAction = "RÃ©soudre la contradiction en supprimant l'une des permissions"
                }
            }
        }
    }
    
    # 4. DÃ©tecter les permissions redondantes (permissions explicites et via rÃ´les)
    # Pour chaque base de donnÃ©es
    $databaseNames = $DatabaseRoles | ForEach-Object { $_.DatabaseName } | Select-Object -Unique
    
    foreach ($dbName in $databaseNames) {
        # Obtenir tous les rÃ´les de la base de donnÃ©es
        $dbRoles = $DatabaseRoles | Where-Object { $_.DatabaseName -eq $dbName }
        
        # Obtenir toutes les permissions explicites de la base de donnÃ©es
        $dbExplicitPerms = $DatabasePermissions | Where-Object { $_.DatabaseName -eq $dbName }
        
        # Pour chaque utilisateur avec des permissions explicites
        foreach ($userPerm in $dbExplicitPerms) {
            # VÃ©rifier si l'utilisateur est membre de rÃ´les
            $userRoles = @()
            foreach ($role in $dbRoles) {
                if ($role.Members | Where-Object { $_.MemberName -eq $userPerm.GranteeName }) {
                    $userRoles += $role.RoleName
                }
            }
            
            # Si l'utilisateur est membre de rÃ´les, vÃ©rifier les permissions redondantes
            if ($userRoles.Count -gt 0) {
                # Permissions courantes par rÃ´le
                $rolePermissions = @{
                    "db_datareader" = @("SELECT")
                    "db_datawriter" = @("INSERT", "UPDATE", "DELETE")
                    "db_ddladmin" = @("CREATE TABLE", "ALTER TABLE", "CREATE PROCEDURE", "ALTER PROCEDURE")
                    "db_securityadmin" = @("CREATE USER", "ALTER USER", "CREATE ROLE", "ALTER ROLE")
                    "db_owner" = @("CONTROL")
                }
                
                # VÃ©rifier les permissions redondantes
                foreach ($roleName in $userRoles) {
                    if ($rolePermissions.ContainsKey($roleName)) {
                        foreach ($permName in $rolePermissions[$roleName]) {
                            $explicitPerm = $userPerm.Permissions | Where-Object { 
                                $_.PermissionName -eq $permName -and $_.PermissionState -eq "GRANT"
                            }
                            
                            if ($explicitPerm) {
                                $results += [PSCustomObject]@{
                                    LoginName = $userPerm.GranteeName
                                    Description = "L'utilisateur '$($userPerm.GranteeName)' dans la base de donnÃ©es '$dbName' a la permission '$permName' explicite qui est redondante avec son appartenance au rÃ´le '$roleName'"
                                    RecommendedAction = "Supprimer la permission explicite redondante"
                                }
                            }
                        }
                    }
                    
                    # Cas spÃ©cial pour db_owner qui inclut toutes les permissions
                    if ($roleName -eq "db_owner") {
                        if ($userPerm.Permissions.Count -gt 0) {
                            $results += [PSCustomObject]@{
                                LoginName = $userPerm.GranteeName
                                Description = "L'utilisateur '$($userPerm.GranteeName)' dans la base de donnÃ©es '$dbName' est membre du rÃ´le 'db_owner' mais a Ã©galement $($userPerm.Permissions.Count) permissions explicites redondantes"
                                RecommendedAction = "Supprimer les permissions explicites redondantes car db_owner inclut dÃ©jÃ  toutes les permissions"
                            }
                        }
                    }
                }
            }
        }
    }
    
    return $results
