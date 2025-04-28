    param($ServerLogins, $ServerRoles, $ServerPermissions, $DatabaseRoles, $DatabasePermissions, $DatabaseUsers)
    $results = @()
    
    # 1. DÃ©tecter les utilisateurs membres de rÃ´les imbriquÃ©s
    # CrÃ©er un dictionnaire des rÃ´les personnalisÃ©s et de leurs membres
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
    
    # Identifier les rÃ´les qui sont membres d'autres rÃ´les (rÃ´les imbriquÃ©s)
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
    
    # Identifier les utilisateurs qui sont membres de rÃ´les imbriquÃ©s
    foreach ($roleKey in $customRoles.Keys) {
        $role = $customRoles[$roleKey]
        
        # VÃ©rifier si ce rÃ´le est imbriquÃ© dans d'autres rÃ´les
        if ($nestedRoles.ContainsKey($roleKey)) {
            $nestedRole = $nestedRoles[$roleKey]
            $parentRolesList = $nestedRole.ParentRoles -join ", "
            
            foreach ($member in $role.Members) {
                # Exclure les autres rÃ´les
                $memberRoleKey = "$($role.DatabaseName):$member"
                if (-not $customRoles.ContainsKey($memberRoleKey)) {
                    $dbUser = $DatabaseUsers | Where-Object { 
                        $_.DatabaseName -eq $role.DatabaseName -and $_.UserName -eq $member 
                    }
                    
                    if ($dbUser -and -not [string]::IsNullOrEmpty($dbUser.LoginName)) {
                        $results += [PSCustomObject]@{
                            LoginName = $dbUser.LoginName
                            Description = "L'utilisateur '$member' dans la base de donnÃ©es '$($role.DatabaseName)' est membre du rÃ´le '$($role.RoleName)' qui est imbriquÃ© dans d'autres rÃ´les: $parentRolesList"
                            RecommendedAction = "VÃ©rifier si l'utilisateur a besoin de toutes les permissions hÃ©ritÃ©es via ces rÃ´les imbriquÃ©s"
                        }
                    }
                }
            }
        }
    }
    
    # 2. DÃ©tecter les utilisateurs avec des permissions implicites via le rÃ´le public
    # Identifier les permissions accordÃ©es au rÃ´le public
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
    
    # Identifier les utilisateurs qui bÃ©nÃ©ficient de permissions via le rÃ´le public
    foreach ($dbName in $publicPermissions.Keys) {
        if ($publicPermissions[$dbName].Count -gt 0) {
            $permissionsList = ($publicPermissions[$dbName] | ForEach-Object { "$($_.PermissionName) on $($_.SecurableType)" }) -join ", "
            
            $dbUsers = $DatabaseUsers | Where-Object { $_.DatabaseName -eq $dbName }
            
            foreach ($dbUser in $dbUsers) {
                if (-not [string]::IsNullOrEmpty($dbUser.LoginName)) {
                    # Exclure les comptes systÃ¨me et dbo
                    if (-not $dbUser.LoginName.StartsWith("##") -and $dbUser.UserName -ne "dbo") {
                        $results += [PSCustomObject]@{
                            LoginName = $dbUser.LoginName
                            Description = "L'utilisateur '$($dbUser.UserName)' dans la base de donnÃ©es '$dbName' bÃ©nÃ©ficie de permissions implicites via le rÃ´le public: $permissionsList"
                            RecommendedAction = "VÃ©rifier si ces permissions accordÃ©es au rÃ´le public sont nÃ©cessaires ou si elles devraient Ãªtre plus restrictives"
                        }
                    }
                }
            }
        }
    }
    
    # 3. DÃ©tecter les utilisateurs avec des permissions hÃ©ritÃ©es via l'appartenance Ã  des rÃ´les Windows/AD
    $windowsGroupLogins = $ServerLogins | Where-Object { 
        $_.LoginType -eq "WINDOWS_GROUP" -and
        -not $_.LoginName.StartsWith("##") -and
        -not $_.LoginName.StartsWith("NT ")
    }
    
    foreach ($groupLogin in $windowsGroupLogins) {
        # VÃ©rifier si le groupe a des permissions au niveau serveur
        $hasServerPermissions = $false
        
        # VÃ©rifier l'appartenance aux rÃ´les serveur
        foreach ($role in $ServerRoles) {
            if ($role.Members | Where-Object { $_.MemberName -eq $groupLogin.LoginName }) {
                $hasServerPermissions = $true
                break
            }
        }
        
        # VÃ©rifier les permissions explicites au niveau serveur
        if (-not $hasServerPermissions) {
            $serverPerm = $ServerPermissions | Where-Object { $_.GranteeName -eq $groupLogin.LoginName }
            if ($serverPerm -and $serverPerm.Permissions.Count -gt 0) {
                $hasServerPermissions = $true
            }
        }
        
        if ($hasServerPermissions) {
            $results += [PSCustomObject]@{
                LoginName = $groupLogin.LoginName
                Description = "Le groupe Windows/AD '$($groupLogin.LoginName)' possÃ¨de des permissions au niveau serveur qui sont hÃ©ritÃ©es par tous les membres du groupe"
                RecommendedAction = "VÃ©rifier si tous les membres du groupe ont besoin de ces permissions ou si des permissions individuelles seraient plus appropriÃ©es"
            }
        }
        
        # VÃ©rifier si le groupe a des utilisateurs de base de donnÃ©es associÃ©s
        $groupDbUsers = $DatabaseUsers | Where-Object { $_.LoginName -eq $groupLogin.LoginName }
        
        foreach ($dbUser in $groupDbUsers) {
            # VÃ©rifier l'appartenance aux rÃ´les de base de donnÃ©es
            $isRoleMember = $false
            foreach ($role in $DatabaseRoles | Where-Object { $_.DatabaseName -eq $dbUser.DatabaseName }) {
                if ($role.Members | Where-Object { $_.MemberName -eq $dbUser.UserName }) {
                    $isRoleMember = $true
                    break
                }
            }
            
            # VÃ©rifier les permissions explicites au niveau base de donnÃ©es
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
                    Description = "Le groupe Windows/AD '$($groupLogin.LoginName)' possÃ¨de des permissions dans la base de donnÃ©es '$($dbUser.DatabaseName)' qui sont hÃ©ritÃ©es par tous les membres du groupe"
                    RecommendedAction = "VÃ©rifier si tous les membres du groupe ont besoin de ces permissions ou si des permissions individuelles seraient plus appropriÃ©es"
                }
            }
        }
    }
    
    # 4. DÃ©tecter les utilisateurs avec des permissions hÃ©ritÃ©es via l'appartenance Ã  db_owner
    foreach ($dbRole in $DatabaseRoles | Where-Object { $_.RoleName -eq "db_owner" }) {
        foreach ($member in $dbRole.Members) {
            # Exclure les comptes systÃ¨me et dbo
            if (-not $member.MemberName.StartsWith("##") -and $member.MemberName -ne "dbo") {
                $dbUser = $DatabaseUsers | Where-Object { 
                    $_.DatabaseName -eq $dbRole.DatabaseName -and $_.UserName -eq $member.MemberName 
                }
                
                if ($dbUser -and -not [string]::IsNullOrEmpty($dbUser.LoginName)) {
                    $results += [PSCustomObject]@{
                        LoginName = $dbUser.LoginName
                        Description = "L'utilisateur '$($member.MemberName)' dans la base de donnÃ©es '$($dbRole.DatabaseName)' est membre du rÃ´le db_owner qui accorde implicitement toutes les permissions"
                        RecommendedAction = "VÃ©rifier si l'utilisateur a besoin de toutes les permissions ou si des rÃ´les plus spÃ©cifiques seraient suffisants"
                    }
                }
            }
        }
    }
    
    return $results
