    param($ServerLogins, $ServerRoles, $ServerPermissions)
    $results = @()
    
    # DÃ©tecter les logins inactifs depuis plus de 90 jours
    $inactiveThreshold = (Get-Date).AddDays(-90)
    
    $inactiveLogins = $ServerLogins | Where-Object { 
        $_.LastLogin -ne $null -and 
        $_.LastLogin -lt $inactiveThreshold -and 
        -not $_.IsDisabled -and
        $_.LoginType -eq "SQL_LOGIN"
    }
    
    foreach ($login in $inactiveLogins) {
        $daysSinceLastLogin = [math]::Round(((Get-Date) - $login.LastLogin).TotalDays)
        
        $results += [PSCustomObject]@{
            LoginName = $login.LoginName
            Description = "Le login SQL n'a pas Ã©tÃ© utilisÃ© depuis $daysSinceLastLogin jours (dernier accÃ¨s: $($login.LastLogin.ToString('yyyy-MM-dd')))"
            RecommendedAction = "VÃ©rifier si ce compte est toujours nÃ©cessaire ou le dÃ©sactiver"
        }
    }
    
    return $results
