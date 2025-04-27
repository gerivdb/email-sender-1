    param($ServerLogins, $ServerRoles, $ServerPermissions)
    $results = @()
    
    # Liste des rôles à privilèges élevés
    $highPrivilegeRoles = @("sysadmin", "securityadmin", "serveradmin", "setupadmin", "dbcreator")
    
    # 1. Détecter les comptes membres de rôles à privilèges élevés
    foreach ($role in $ServerRoles | Where-Object { $highPrivilegeRoles -contains $_.RoleName }) {
        foreach ($member in $role.Members) {
            # Exclure les comptes système
            if (-not $member.MemberName.StartsWith("##") -and 
                -not $member.MemberName.StartsWith("NT ") -and
                -not $member.MemberName -eq "sa") {
                
                $results += [PSCustomObject]@{
                    LoginName = $member.MemberName
                    Description = "Le login est membre du rôle serveur à privilèges élevés: $($role.RoleName)"
                    RecommendedAction = "Vérifier si ce niveau de privilège est nécessaire et conforme à la politique de sécurité"
                }
            }
        }
    }
    
    # 2. Détecter les comptes avec des permissions équivalentes à des privilèges élevés
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
                Description = "Le login possède des permissions à privilèges élevés: $elevatedPermList"
                RecommendedAction = "Vérifier si ces permissions sont nécessaires et conformes à la politique de sécurité"
            }
        }
    }
    
    # 3. Vérifier si des comptes non-administratifs ont des permissions administratives
    $nonAdminWithAdminPerms = $ServerLogins | Where-Object {
        # Exclure les comptes système et administratifs connus
        -not $_.LoginName.StartsWith("##") -and
        -not $_.LoginName.StartsWith("NT ") -and
        -not $_.LoginName -eq "sa" -and
        -not $_.LoginName -like "*admin*" -and
        -not $_.LoginName -like "*dba*"
    }
    
    foreach ($login in $nonAdminWithAdminPerms) {
        # Vérifier si le login est membre d'un rôle à privilèges élevés
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
                Description = "Le login avec un nom non-administratif possède des privilèges administratifs"
                RecommendedAction = "Vérifier si ce compte devrait avoir des privilèges administratifs"
            }
        }
    }
    
    return $results
