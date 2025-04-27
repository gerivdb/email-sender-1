    param($ServerLogins, $ServerRoles, $ServerPermissions)
    $results = @()
    
    # 1. Vérifier les comptes SQL exemptés de la politique de mot de passe
    $exemptedFromPolicy = $ServerLogins | Where-Object { 
        $_.LoginType -eq "SQL_LOGIN" -and 
        ($_.IsPolicyChecked -eq 0 -or $_.IsExpirationChecked -eq 0) -and
        -not $_.IsDisabled
    }
    
    foreach ($login in $exemptedFromPolicy) {
        $policyStatus = if ($login.IsPolicyChecked -eq 0) { "non appliquée" } else { "appliquée" }
        $expirationStatus = if ($login.IsExpirationChecked -eq 0) { "non activée" } else { "activée" }
        
        $results += [PSCustomObject]@{
            LoginName = $login.LoginName
            Description = "Le login SQL a une configuration de mot de passe faible (politique: $policyStatus, expiration: $expirationStatus)"
            RecommendedAction = "Activer la politique de mot de passe et l'expiration pour ce compte"
        }
    }
    
    # 2. Vérifier les comptes avec des mots de passe qui n'expirent jamais
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
    
    # 3. Vérifier les comptes à privilèges élevés avec des configurations de mot de passe faibles
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
            Description = "Le login SQL avec des privilèges élevés a une configuration de mot de passe faible"
            RecommendedAction = "Activer la politique de mot de passe et l'expiration pour ce compte privilégié"
        }
    }
    
    # 4. Vérifier les comptes avec des mots de passe expirés
    $expiredPasswords = $ServerLogins | Where-Object { 
        $_.LoginType -eq "SQL_LOGIN" -and 
        $_.IsExpired -eq 1 -and
        -not $_.IsDisabled
    }
    
    foreach ($login in $expiredPasswords) {
        $results += [PSCustomObject]@{
            LoginName = $login.LoginName
            Description = "Le login SQL a un mot de passe expiré"
            RecommendedAction = "Changer le mot de passe du compte"
        }
    }
    
    return $results
