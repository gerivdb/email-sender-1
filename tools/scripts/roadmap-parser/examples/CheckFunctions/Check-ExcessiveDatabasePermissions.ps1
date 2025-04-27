    param($DatabaseUsers, $DatabaseRoles, $DatabasePermissions, $ServerLogins)
    $results = @()
    
    # 1. DÃ©tecter les utilisateurs avec des permissions CONTROL sur la base de donnÃ©es
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
                RecommendedAction = "Remplacer par des permissions plus spÃ©cifiques ou ajouter Ã  db_owner si nÃ©cessaire"
            }
        }
    }
    
    # 2. DÃ©tecter les utilisateurs avec des permissions ALTER sur la base de donnÃ©es
    $alterDatabasePermissions = $DatabasePermissions | Where-Object {
        $_.Permissions | Where-Object {
            $_.PermissionName -eq "ALTER" -and 
            $_.SecurableType -eq "DATABASE" -and 
            $_.PermissionState -eq "GRANT"
        }
    }

    foreach ($permission in $alterDatabasePermissions) {
        # Exclure les comptes systÃ¨me et dbo
        if (-not $permission.GranteeName.StartsWith("##") -and $permission.GranteeName -ne "dbo") {
            $results += [PSCustomObject]@{
                DatabaseName = $permission.DatabaseName
                UserName = $permission.GranteeName
                Description = "L'utilisateur possÃ¨de la permission ALTER sur la base de donnÃ©es"
                RecommendedAction = "Remplacer par des permissions plus spÃ©cifiques si possible"
            }
        }
    }
    
    # 3. DÃ©tecter les utilisateurs avec des permissions TAKE OWNERSHIP
    $takeOwnershipPermissions = $DatabasePermissions | Where-Object {
        $_.Permissions | Where-Object {
            $_.PermissionName -eq "TAKE OWNERSHIP" -and 
            $_.PermissionState -eq "GRANT"
        }
    }

    foreach ($permission in $takeOwnershipPermissions) {
        # Exclure les comptes systÃ¨me et dbo
        if (-not $permission.GranteeName.StartsWith("##") -and $permission.GranteeName -ne "dbo") {
            $results += [PSCustomObject]@{
                DatabaseName = $permission.DatabaseName
                UserName = $permission.GranteeName
                Description = "L'utilisateur possÃ¨de la permission TAKE OWNERSHIP qui permet de s'approprier n'importe quel objet"
                RecommendedAction = "RÃ©voquer cette permission et utiliser des propriÃ©taires spÃ©cifiques pour les objets"
            }
        }
    }
    
    # 4. DÃ©tecter les utilisateurs avec des permissions IMPERSONATE
    $impersonatePermissions = $DatabasePermissions | Where-Object {
        $_.Permissions | Where-Object {
            $_.PermissionName -eq "IMPERSONATE" -and 
            $_.PermissionState -eq "GRANT"
        }
    }

    foreach ($permission in $impersonatePermissions) {
        # Exclure les comptes systÃ¨me et dbo
        if (-not $permission.GranteeName.StartsWith("##") -and $permission.GranteeName -ne "dbo") {
            $results += [PSCustomObject]@{
                DatabaseName = $permission.DatabaseName
                UserName = $permission.GranteeName
                Description = "L'utilisateur possÃ¨de la permission IMPERSONATE qui permet d'usurper l'identitÃ© d'autres utilisateurs"
                RecommendedAction = "RÃ©voquer cette permission et utiliser des rÃ´les pour gÃ©rer les accÃ¨s"
            }
        }
    }
    
    # 5. DÃ©tecter les utilisateurs membres de plusieurs rÃ´les Ã  privilÃ¨ges Ã©levÃ©s
    $highPrivilegeRoles = @("db_owner", "db_securityadmin", "db_accessadmin", "db_ddladmin", "db_backupoperator")
    
    # CrÃ©er un dictionnaire pour compter les rÃ´les Ã  privilÃ¨ges Ã©levÃ©s par utilisateur
    $userHighPrivRoleCount = @{}
    
    foreach ($role in $DatabaseRoles | Where-Object { $highPrivilegeRoles -contains $_.RoleName }) {
        foreach ($member in $role.Members) {
            $key = "$($role.DatabaseName):$($member.MemberName)"
            
            if (-not $userHighPrivRoleCount.ContainsKey($key)) {
                $userHighPrivRoleCount[$key] = @{
                    DatabaseName = $role.DatabaseName
                    UserName = $member.MemberName
                    RoleCount = 0
                    Roles = @()
                }
            }
            
            $userHighPrivRoleCount[$key].RoleCount++
            $userHighPrivRoleCount[$key].Roles += $role.RoleName
        }
    }
    
    # Identifier les utilisateurs membres de plusieurs rÃ´les Ã  privilÃ¨ges Ã©levÃ©s
    foreach ($key in $userHighPrivRoleCount.Keys) {
        if ($userHighPrivRoleCount[$key].RoleCount -gt 1) {
            $user = $userHighPrivRoleCount[$key]
            $rolesList = $user.Roles -join ", "
            
            # Exclure les comptes systÃ¨me et dbo
            if (-not $user.UserName.StartsWith("##") -and $user.UserName -ne "dbo") {
                $results += [PSCustomObject]@{
                    DatabaseName = $user.DatabaseName
                    UserName = $user.UserName
                    Description = "L'utilisateur est membre de plusieurs rÃ´les Ã  privilÃ¨ges Ã©levÃ©s: $rolesList"
                    RecommendedAction = "Limiter l'appartenance Ã  un seul rÃ´le Ã  privilÃ¨ges Ã©levÃ©s si possible"
                }
            }
        }
    }
    
    return $results
