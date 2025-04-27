    param($DatabaseUsers, $DatabaseRoles, $DatabasePermissions, $ServerLogins)
    $results = @()
    
    # 1. Détecter les utilisateurs avec des permissions CONTROL sur la base de données
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
                RecommendedAction = "Remplacer par des permissions plus spécifiques ou ajouter à db_owner si nécessaire"
            }
        }
    }
    
    # 2. Détecter les utilisateurs avec des permissions ALTER sur la base de données
    $alterDatabasePermissions = $DatabasePermissions | Where-Object {
        $_.Permissions | Where-Object {
            $_.PermissionName -eq "ALTER" -and 
            $_.SecurableType -eq "DATABASE" -and 
            $_.PermissionState -eq "GRANT"
        }
    }

    foreach ($permission in $alterDatabasePermissions) {
        # Exclure les comptes système et dbo
        if (-not $permission.GranteeName.StartsWith("##") -and $permission.GranteeName -ne "dbo") {
            $results += [PSCustomObject]@{
                DatabaseName = $permission.DatabaseName
                UserName = $permission.GranteeName
                Description = "L'utilisateur possède la permission ALTER sur la base de données"
                RecommendedAction = "Remplacer par des permissions plus spécifiques si possible"
            }
        }
    }
    
    # 3. Détecter les utilisateurs avec des permissions TAKE OWNERSHIP
    $takeOwnershipPermissions = $DatabasePermissions | Where-Object {
        $_.Permissions | Where-Object {
            $_.PermissionName -eq "TAKE OWNERSHIP" -and 
            $_.PermissionState -eq "GRANT"
        }
    }

    foreach ($permission in $takeOwnershipPermissions) {
        # Exclure les comptes système et dbo
        if (-not $permission.GranteeName.StartsWith("##") -and $permission.GranteeName -ne "dbo") {
            $results += [PSCustomObject]@{
                DatabaseName = $permission.DatabaseName
                UserName = $permission.GranteeName
                Description = "L'utilisateur possède la permission TAKE OWNERSHIP qui permet de s'approprier n'importe quel objet"
                RecommendedAction = "Révoquer cette permission et utiliser des propriétaires spécifiques pour les objets"
            }
        }
    }
    
    # 4. Détecter les utilisateurs avec des permissions IMPERSONATE
    $impersonatePermissions = $DatabasePermissions | Where-Object {
        $_.Permissions | Where-Object {
            $_.PermissionName -eq "IMPERSONATE" -and 
            $_.PermissionState -eq "GRANT"
        }
    }

    foreach ($permission in $impersonatePermissions) {
        # Exclure les comptes système et dbo
        if (-not $permission.GranteeName.StartsWith("##") -and $permission.GranteeName -ne "dbo") {
            $results += [PSCustomObject]@{
                DatabaseName = $permission.DatabaseName
                UserName = $permission.GranteeName
                Description = "L'utilisateur possède la permission IMPERSONATE qui permet d'usurper l'identité d'autres utilisateurs"
                RecommendedAction = "Révoquer cette permission et utiliser des rôles pour gérer les accès"
            }
        }
    }
    
    # 5. Détecter les utilisateurs membres de plusieurs rôles à privilèges élevés
    $highPrivilegeRoles = @("db_owner", "db_securityadmin", "db_accessadmin", "db_ddladmin", "db_backupoperator")
    
    # Créer un dictionnaire pour compter les rôles à privilèges élevés par utilisateur
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
    
    # Identifier les utilisateurs membres de plusieurs rôles à privilèges élevés
    foreach ($key in $userHighPrivRoleCount.Keys) {
        if ($userHighPrivRoleCount[$key].RoleCount -gt 1) {
            $user = $userHighPrivRoleCount[$key]
            $rolesList = $user.Roles -join ", "
            
            # Exclure les comptes système et dbo
            if (-not $user.UserName.StartsWith("##") -and $user.UserName -ne "dbo") {
                $results += [PSCustomObject]@{
                    DatabaseName = $user.DatabaseName
                    UserName = $user.UserName
                    Description = "L'utilisateur est membre de plusieurs rôles à privilèges élevés: $rolesList"
                    RecommendedAction = "Limiter l'appartenance à un seul rôle à privilèges élevés si possible"
                }
            }
        }
    }
    
    return $results
