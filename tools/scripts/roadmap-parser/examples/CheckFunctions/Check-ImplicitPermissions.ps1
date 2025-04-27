    param($ServerLogins, $ServerRoles, $ServerPermissions, $DatabaseRoles, $DatabasePermissions, $DatabaseUsers)
    $results = @()
    
    # 1. Détecter les utilisateurs membres de rôles imbriqués
    # Créer un dictionnaire des rôles personnalisés et de leurs membres
    $customRoles = @{}
    
    foreach ($dbRole in $DatabaseRoles | Where-Object { 
        $_.RoleName -ne "db_owner" -and
        $_.RoleName -ne "db_securityadmin" -and
        $_.RoleName -ne "db_accessadmin" -and
        $_.RoleName -ne "db_ddladmin" -and
        $_.RoleName -ne "db_backupoperator" -and
        $_.RoleName -ne "db_datareader" -and
        $_.RoleName -ne "db_datawriter" -and
        $_.RoleName -ne "db_denydatareader" -and
        $_.RoleName -ne "db_denydatawriter" -and
        $_.RoleName -ne "public"
    }) {
        $key = "$($dbRole.DatabaseName):$($dbRole.RoleName)"
        
        if (-not $customRoles.ContainsKey($key)) {
            $customRoles[$key] = @{
                DatabaseName = $dbRole.DatabaseName
                RoleName = $dbRole.RoleName
                Members = @()
            }
        }
        
        foreach ($member in $dbRole.Members) {
            $customRoles[$key].Members += $member.MemberName
        }
    }
    
    # Identifier les rôles qui sont membres d'autres rôles (rôles imbriqués)
    $nestedRoles = @{}
    
    foreach ($roleKey in $customRoles.Keys) {
        $role = $customRoles[$roleKey]
        
        foreach ($member in $role.Members) {
            $memberRoleKey = "$($role.DatabaseName):$member"
            
            if ($customRoles.ContainsKey($memberRoleKey)) {
                if (-not $nestedRoles.ContainsKey($memberRoleKey)) {
                    $nestedRoles[$memberRoleKey] = @{
                        DatabaseName = $role.DatabaseName
                        RoleName = $member
                        ParentRoles = @()
                    }
                }
                
                $nestedRoles[$memberRoleKey].ParentRoles += $role.RoleName
            }
        }
    }
    
    # Identifier les utilisateurs qui sont membres de rôles imbriqués
    foreach ($roleKey in $customRoles.Keys) {
        $role = $customRoles[$roleKey]
        
        # Vérifier si ce rôle est imbriqué dans d'autres rôles
        if ($nestedRoles.ContainsKey($roleKey)) {
            $nestedRole = $nestedRoles[$roleKey]
            $parentRolesList = $nestedRole.ParentRoles -join ", "
            
            foreach ($member in $role.Members) {
                # Exclure les autres rôles
                $memberRoleKey = "$($role.DatabaseName):$member"
                if (-not $customRoles.ContainsKey($memberRoleKey)) {
                    $dbUser = $DatabaseUsers | Where-Object { 
                        $_.DatabaseName -eq $role.DatabaseName -and $_.UserName -eq $member 
                    }
                    
                    if ($dbUser -and -not [string]::IsNullOrEmpty($dbUser.LoginName)) {
                        $results += [PSCustomObject]@{
                            LoginName = $dbUser.LoginName
                            Description = "L'utilisateur '$member' dans la base de données '$($role.DatabaseName)' est membre du rôle '$($role.RoleName)' qui est imbriqué dans d'autres rôles: $parentRolesList"
                            RecommendedAction = "Vérifier si l'utilisateur a besoin de toutes les permissions héritées via ces rôles imbriqués"
                        }
                    }
                }
            }
        }
    }
    
    # 2. Détecter les utilisateurs avec des permissions implicites via le rôle public
    # Identifier les permissions accordées au rôle public
    $publicPermissions = @{}
    
    foreach ($dbPerm in $DatabasePermissions | Where-Object { $_.GranteeName -eq "public" }) {
        if (-not $publicPermissions.ContainsKey($dbPerm.DatabaseName)) {
            $publicPermissions[$dbPerm.DatabaseName] = @()
        }
        
        foreach ($perm in $dbPerm.Permissions) {
            $publicPermissions[$dbPerm.DatabaseName] += [PSCustomObject]@{
                PermissionName = $perm.PermissionName
                SecurableType = $perm.SecurableType
                SecurableName = $perm.SecurableName
                PermissionState = $perm.PermissionState
            }
        }
    }
    
    # Identifier les utilisateurs qui bénéficient de permissions via le rôle public
    foreach ($dbName in $publicPermissions.Keys) {
        if ($publicPermissions[$dbName].Count -gt 0) {
            $permissionsList = ($publicPermissions[$dbName] | ForEach-Object { "$($_.PermissionName) on $($_.SecurableType)" }) -join ", "
            
            $dbUsers = $DatabaseUsers | Where-Object { $_.DatabaseName -eq $dbName }
            
            foreach ($dbUser in $dbUsers) {
                if (-not [string]::IsNullOrEmpty($dbUser.LoginName)) {
                    # Exclure les comptes système et dbo
                    if (-not $dbUser.LoginName.StartsWith("##") -and $dbUser.UserName -ne "dbo") {
                        $results += [PSCustomObject]@{
                            LoginName = $dbUser.LoginName
                            Description = "L'utilisateur '$($dbUser.UserName)' dans la base de données '$dbName' bénéficie de permissions implicites via le rôle public: $permissionsList"
                            RecommendedAction = "Vérifier si ces permissions accordées au rôle public sont nécessaires ou si elles devraient être plus restrictives"
                        }
                    }
                }
            }
        }
    }
    
    # 3. Détecter les utilisateurs avec des permissions héritées via l'appartenance à des rôles Windows/AD
    $windowsGroupLogins = $ServerLogins | Where-Object { 
        $_.LoginType -eq "WINDOWS_GROUP" -and
        -not $_.LoginName.StartsWith("##") -and
        -not $_.LoginName.StartsWith("NT ")
    }
    
    foreach ($groupLogin in $windowsGroupLogins) {
        # Vérifier si le groupe a des permissions au niveau serveur
        $hasServerPermissions = $false
        
        # Vérifier l'appartenance aux rôles serveur
        foreach ($role in $ServerRoles) {
            if ($role.Members | Where-Object { $_.MemberName -eq $groupLogin.LoginName }) {
                $hasServerPermissions = $true
                break
            }
        }
        
        # Vérifier les permissions explicites au niveau serveur
        if (-not $hasServerPermissions) {
            $serverPerm = $ServerPermissions | Where-Object { $_.GranteeName -eq $groupLogin.LoginName }
            if ($serverPerm -and $serverPerm.Permissions.Count -gt 0) {
                $hasServerPermissions = $true
            }
        }
        
        if ($hasServerPermissions) {
            $results += [PSCustomObject]@{
                LoginName = $groupLogin.LoginName
                Description = "Le groupe Windows/AD '$($groupLogin.LoginName)' possède des permissions au niveau serveur qui sont héritées par tous les membres du groupe"
                RecommendedAction = "Vérifier si tous les membres du groupe ont besoin de ces permissions ou si des permissions individuelles seraient plus appropriées"
            }
        }
        
        # Vérifier si le groupe a des utilisateurs de base de données associés
        $groupDbUsers = $DatabaseUsers | Where-Object { $_.LoginName -eq $groupLogin.LoginName }
        
        foreach ($dbUser in $groupDbUsers) {
            # Vérifier l'appartenance aux rôles de base de données
            $isRoleMember = $false
            foreach ($role in $DatabaseRoles | Where-Object { $_.DatabaseName -eq $dbUser.DatabaseName }) {
                if ($role.Members | Where-Object { $_.MemberName -eq $dbUser.UserName }) {
                    $isRoleMember = $true
                    break
                }
            }
            
            # Vérifier les permissions explicites au niveau base de données
            $hasDbPermissions = $false
            $dbPerm = $DatabasePermissions | Where-Object { 
                $_.DatabaseName -eq $dbUser.DatabaseName -and $_.GranteeName -eq $dbUser.UserName 
            }
            if ($dbPerm -and $dbPerm.Permissions.Count -gt 0) {
                $hasDbPermissions = $true
            }
            
            if ($isRoleMember -or $hasDbPermissions) {
                $results += [PSCustomObject]@{
                    LoginName = $groupLogin.LoginName
                    Description = "Le groupe Windows/AD '$($groupLogin.LoginName)' possède des permissions dans la base de données '$($dbUser.DatabaseName)' qui sont héritées par tous les membres du groupe"
                    RecommendedAction = "Vérifier si tous les membres du groupe ont besoin de ces permissions ou si des permissions individuelles seraient plus appropriées"
                }
            }
        }
    }
    
    # 4. Détecter les utilisateurs avec des permissions héritées via l'appartenance à db_owner
    foreach ($dbRole in $DatabaseRoles | Where-Object { $_.RoleName -eq "db_owner" }) {
        foreach ($member in $dbRole.Members) {
            # Exclure les comptes système et dbo
            if (-not $member.MemberName.StartsWith("##") -and $member.MemberName -ne "dbo") {
                $dbUser = $DatabaseUsers | Where-Object { 
                    $_.DatabaseName -eq $dbRole.DatabaseName -and $_.UserName -eq $member.MemberName 
                }
                
                if ($dbUser -and -not [string]::IsNullOrEmpty($dbUser.LoginName)) {
                    $results += [PSCustomObject]@{
                        LoginName = $dbUser.LoginName
                        Description = "L'utilisateur '$($member.MemberName)' dans la base de données '$($dbRole.DatabaseName)' est membre du rôle db_owner qui accorde implicitement toutes les permissions"
                        RecommendedAction = "Vérifier si l'utilisateur a besoin de toutes les permissions ou si des rôles plus spécifiques seraient suffisants"
                    }
                }
            }
        }
    }
    
    return $results
