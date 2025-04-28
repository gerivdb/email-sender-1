    param($ServerLogins, $ServerRoles, $ServerPermissions)
    $results = @()
    
    # 1. VÃ©rifier les comptes SQL exemptÃ©s de la politique de mot de passe
    $exemptedFromPolicy = $ServerLogins | Where-Object { 
        $_.LoginType -eq "SQL_LOGIN" -and 
        ($_.IsPolicyChecked -eq 0 -or $_.IsExpirationChecked -eq 0) -and
        -not $_.IsDisabled
    }
    
    foreach ($login in $exemptedFromPolicy) {
        $policyStatus = if ($login.IsPolicyChecked -eq 0) { "non appliquÃ©e" } else { "appliquÃ©e" }
        $expirationStatus = if ($login.IsExpirationChecked -eq 0) { "non activÃ©e" } else { "activÃ©e" }
        
        $results += [PSCustomObject]@{
            LoginName = $login.LoginName
            Description = "Le login SQL a une configuration de mot de passe faible (politique: $policyStatus, expiration: $expirationStatus)"
            RecommendedAction = "Activer la politique de mot de passe et l'expiration pour ce compte"
        }
    }
    
    # 2. VÃ©rifier les comptes avec des mots de passe qui n'expirent jamais
    $nonExpiringPasswords = $ServerLogins | Where-Object { 
        $_.LoginType -eq "SQL_LOGIN" -and 
        $_.IsExpirationChecked -eq 0 -and
        -not $_.IsDisabled
    }
    
    foreach ($login in $nonExpiringPasswords) {
        $results += [PSCustomObject]@{
            LoginName = $login.LoginName
            Description = "Le login SQL a un mot de passe qui n'expire jamais"
            RecommendedAction = "Activer l'expiration du mot de passe pour ce compte"
        }
    }
    
    # 3. VÃ©rifier les comptes Ã  privilÃ¨ges Ã©levÃ©s avec des configurations de mot de passe faibles
    $highPrivilegeRoles = @("sysadmin", "securityadmin", "serveradmin")
    $highPrivilegeLogins = @()
    
    foreach ($role in $ServerRoles | Where-Object { $highPrivilegeRoles -contains $_.RoleName }) {
        foreach ($member in $role.Members) {
            if (-not $highPrivilegeLogins.Contains($member.MemberName)) {
                $highPrivilegeLogins += $member.MemberName
            }
        }
    }
    
    $highPrivWithWeakPassword = $ServerLogins | Where-Object { 
        $_.LoginType -eq "SQL_LOGIN" -and 
        $highPrivilegeLogins -contains $_.LoginName -and
        ($_.IsPolicyChecked -eq 0 -or $_.IsExpirationChecked -eq 0) -and
        -not $_.IsDisabled
    }
    
    foreach ($login in $highPrivWithWeakPassword) {
        $results += [PSCustomObject]@{
            LoginName = $login.LoginName
            Description = "Le login SQL avec des privilÃ¨ges Ã©levÃ©s a une configuration de mot de passe faible"
            RecommendedAction = "Activer la politique de mot de passe et l'expiration pour ce compte privilÃ©giÃ©"
        }
    }
    
    # 4. VÃ©rifier les comptes avec des mots de passe expirÃ©s
    $expiredPasswords = $ServerLogins | Where-Object { 
        $_.LoginType -eq "SQL_LOGIN" -and 
        $_.IsExpired -eq 1 -and
        -not $_.IsDisabled
    }
    
    foreach ($login in $expiredPasswords) {
        $results += [PSCustomObject]@{
            LoginName = $login.LoginName
            Description = "Le login SQL a un mot de passe expirÃ©"
            RecommendedAction = "Changer le mot de passe du compte"
        }
    }
    
    return $results
