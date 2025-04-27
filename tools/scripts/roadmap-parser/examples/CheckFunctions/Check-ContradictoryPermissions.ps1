    param($ServerLogins, $ServerRoles, $ServerPermissions, $DatabaseRoles, $DatabasePermissions, $DatabaseUsers)
    $results = @()
    
    # 1. Détecter les comptes désactivés mais membres de rôles
    $disabledLogins = $ServerLogins | Where-Object { $_.IsDisabled -eq $true }
    
    foreach ($login in $disabledLogins) {
        # Vérifier si le login est membre d'un rôle serveur
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
                Description = "Le login est désactivé mais est toujours membre de rôles serveur"
                RecommendedAction = "Retirer le login des rôles serveur avant de le désactiver"
            }
        }
        
        # Vérifier si le login a des utilisateurs de base de données associés qui sont membres de rôles
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
                    Description = "Le login est désactivé mais son utilisateur de base de données '$($dbUser.UserName)' dans '$($dbUser.DatabaseName)' est toujours membre de rôles"
                    RecommendedAction = "Retirer l'utilisateur des rôles de base de données avant de désactiver le login"
                }
            }
        }
    }
    
    # 2. Détecter les permissions DENY et GRANT contradictoires au niveau serveur
    foreach ($login in $ServerPermissions) {
        $permissionNames = $login.Permissions | ForEach-Object { $_.PermissionName } | Select-Object -Unique
        
        foreach ($permName in $permissionNames) {
            $grantedPerm = $login.Permissions | Where-Object { $_.PermissionName -eq $permName -and $_.PermissionState -eq "GRANT" }
            $deniedPerm = $login.Permissions | Where-Object { $_.PermissionName -eq $permName -and $_.PermissionState -eq "DENY" }
            
            if ($grantedPerm -and $deniedPerm) {
                $results += [PSCustomObject]@{
                    LoginName = $login.GranteeName
                    Description = "Le login a des permissions contradictoires: $permName est à la fois GRANT et DENY"
                    RecommendedAction = "Résoudre la contradiction en supprimant l'une des permissions"
                }
            }
        }
    }
    
    # 3. Détecter les permissions DENY et GRANT contradictoires au niveau base de données
    foreach ($dbPerm in $DatabasePermissions) {
        $permissionNames = $dbPerm.Permissions | ForEach-Object { $_.PermissionName } | Select-Object -Unique
        
        foreach ($permName in $permissionNames) {
            $grantedPerm = $dbPerm.Permissions | Where-Object { $_.PermissionName -eq $permName -and $_.PermissionState -eq "GRANT" }
            $deniedPerm = $dbPerm.Permissions | Where-Object { $_.PermissionName -eq $permName -and $_.PermissionState -eq "DENY" }
            
            if ($grantedPerm -and $deniedPerm) {
                $results += [PSCustomObject]@{
                    LoginName = $dbPerm.GranteeName
                    Description = "L'utilisateur '$($dbPerm.GranteeName)' dans la base de données '$($dbPerm.DatabaseName)' a des permissions contradictoires: $permName est à la fois GRANT et DENY"
                    RecommendedAction = "Résoudre la contradiction en supprimant l'une des permissions"
                }
            }
        }
    }
    
    # 4. Détecter les permissions redondantes (permissions explicites et via rôles)
    # Pour chaque base de données
    $databaseNames = $DatabaseRoles | ForEach-Object { $_.DatabaseName } | Select-Object -Unique
    
    foreach ($dbName in $databaseNames) {
        # Obtenir tous les rôles de la base de données
        $dbRoles = $DatabaseRoles | Where-Object { $_.DatabaseName -eq $dbName }
        
        # Obtenir toutes les permissions explicites de la base de données
        $dbExplicitPerms = $DatabasePermissions | Where-Object { $_.DatabaseName -eq $dbName }
        
        # Pour chaque utilisateur avec des permissions explicites
        foreach ($userPerm in $dbExplicitPerms) {
            # Vérifier si l'utilisateur est membre de rôles
            $userRoles = @()
            foreach ($role in $dbRoles) {
                if ($role.Members | Where-Object { $_.MemberName -eq $userPerm.GranteeName }) {
                    $userRoles += $role.RoleName
                }
            }
            
            # Si l'utilisateur est membre de rôles, vérifier les permissions redondantes
            if ($userRoles.Count -gt 0) {
                # Permissions courantes par rôle
                $rolePermissions = @{
                    "db_datareader" = @("SELECT")
                    "db_datawriter" = @("INSERT", "UPDATE", "DELETE")
                    "db_ddladmin" = @("CREATE TABLE", "ALTER TABLE", "CREATE PROCEDURE", "ALTER PROCEDURE")
                    "db_securityadmin" = @("CREATE USER", "ALTER USER", "CREATE ROLE", "ALTER ROLE")
                    "db_owner" = @("CONTROL")
                }
                
                # Vérifier les permissions redondantes
                foreach ($roleName in $userRoles) {
                    if ($rolePermissions.ContainsKey($roleName)) {
                        foreach ($permName in $rolePermissions[$roleName]) {
                            $explicitPerm = $userPerm.Permissions | Where-Object { 
                                $_.PermissionName -eq $permName -and $_.PermissionState -eq "GRANT"
                            }
                            
                            if ($explicitPerm) {
                                $results += [PSCustomObject]@{
                                    LoginName = $userPerm.GranteeName
                                    Description = "L'utilisateur '$($userPerm.GranteeName)' dans la base de données '$dbName' a la permission '$permName' explicite qui est redondante avec son appartenance au rôle '$roleName'"
                                    RecommendedAction = "Supprimer la permission explicite redondante"
                                }
                            }
                        }
                    }
                    
                    # Cas spécial pour db_owner qui inclut toutes les permissions
                    if ($roleName -eq "db_owner") {
                        if ($userPerm.Permissions.Count -gt 0) {
                            $results += [PSCustomObject]@{
                                LoginName = $userPerm.GranteeName
                                Description = "L'utilisateur '$($userPerm.GranteeName)' dans la base de données '$dbName' est membre du rôle 'db_owner' mais a également $($userPerm.Permissions.Count) permissions explicites redondantes"
                                RecommendedAction = "Supprimer les permissions explicites redondantes car db_owner inclut déjà toutes les permissions"
                            }
                        }
                    }
                }
            }
        }
    }
    
    return $results
