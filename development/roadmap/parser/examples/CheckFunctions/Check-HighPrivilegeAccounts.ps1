    param($ServerLogins, $ServerRoles, $ServerPermissions)
    $results = @()
    
    # Liste des rÃ´les Ã  privilÃ¨ges Ã©levÃ©s
    $highPrivilegeRoles = @("sysadmin", "securityadmin", "serveradmin", "setupadmin", "dbcreator")
    
    # 1. DÃ©tecter les comptes membres de rÃ´les Ã  privilÃ¨ges Ã©levÃ©s
    foreach ($role in $ServerRoles | Where-Object { $highPrivilegeRoles -contains $_.RoleName }) {
        foreach ($member in $role.Members) {
            # Exclure les comptes systÃ¨me
            if (-not $member.MemberName.StartsWith("##") -and 
                -not $member.MemberName.StartsWith("NT ") -and
                -not $member.MemberName -eq "sa") {
                
                $results += [PSCustomObject]@{
                    LoginName = $member.MemberName
                    Description = "Le login est membre du rÃ´le serveur Ã  privilÃ¨ges Ã©levÃ©s: $($role.RoleName)"
                    RecommendedAction = "VÃ©rifier si ce niveau de privilÃ¨ge est nÃ©cessaire et conforme Ã  la politique de sÃ©curitÃ©"
                }
            }
        }
    }
    
    # 2. DÃ©tecter les comptes avec des permissions Ã©quivalentes Ã  des privilÃ¨ges Ã©levÃ©s
    $elevatedPermissions = @(
        "CONTROL SERVER", 
        "ALTER ANY LOGIN", 
        "ALTER ANY SERVER ROLE",
        "ALTER SERVER STATE",
        "ALTER SETTINGS",
        "CREATE DDL EVENT NOTIFICATION",
        "CREATE ENDPOINT",
        "CREATE SERVER ROLE",
        "CREATE TRACE EVENT NOTIFICATION",
        "EXTERNAL ACCESS ASSEMBLY",
        "UNSAFE ASSEMBLY"
    )
    
    foreach ($login in $ServerPermissions) {
        $hasElevatedPermissions = $login.Permissions | Where-Object {
            $elevatedPermissions -contains $_.PermissionName -and $_.PermissionState -eq "GRANT"
        }
        
        if ($hasElevatedPermissions -and 
            -not $login.GranteeName.StartsWith("##") -and 
            -not $login.GranteeName.StartsWith("NT ") -and
            -not $login.GranteeName -eq "sa") {
            
            $elevatedPermList = ($hasElevatedPermissions | ForEach-Object { $_.PermissionName }) -join ", "
            
            $results += [PSCustomObject]@{
                LoginName = $login.GranteeName
                Description = "Le login possÃ¨de des permissions Ã  privilÃ¨ges Ã©levÃ©s: $elevatedPermList"
                RecommendedAction = "VÃ©rifier si ces permissions sont nÃ©cessaires et conformes Ã  la politique de sÃ©curitÃ©"
            }
        }
    }
    
    # 3. VÃ©rifier si des comptes non-administratifs ont des permissions administratives
    $nonAdminWithAdminPerms = $ServerLogins | Where-Object {
        # Exclure les comptes systÃ¨me et administratifs connus
        -not $_.LoginName.StartsWith("##") -and
        -not $_.LoginName.StartsWith("NT ") -and
        -not $_.LoginName -eq "sa" -and
        -not $_.LoginName -like "*admin*" -and
        -not $_.LoginName -like "*dba*"
    }
    
    foreach ($login in $nonAdminWithAdminPerms) {
        # VÃ©rifier si le login est membre d'un rÃ´le Ã  privilÃ¨ges Ã©levÃ©s
        $isHighPrivMember = $false
        foreach ($role in $ServerRoles | Where-Object { $highPrivilegeRoles -contains $_.RoleName }) {
            if ($role.Members | Where-Object { $_.MemberName -eq $login.LoginName }) {
                $isHighPrivMember = $true
                break
            }
        }
        
        if ($isHighPrivMember) {
            $results += [PSCustomObject]@{
                LoginName = $login.LoginName
                Description = "Le login avec un nom non-administratif possÃ¨de des privilÃ¨ges administratifs"
                RecommendedAction = "VÃ©rifier si ce compte devrait avoir des privilÃ¨ges administratifs"
            }
        }
    }
    
    return $results
