    param($ServerLogins, $ServerRoles, $ServerPermissions)
    $results = @()
    
    # Configurer les seuils d'inactivitÃ© (en jours)
    $warningThreshold = 60    # Avertissement pour les comptes inactifs depuis 60 jours
    $criticalThreshold = 90   # Alerte critique pour les comptes inactifs depuis 90 jours
    
    # Date actuelle
    $currentDate = Get-Date
    
    # Calculer les dates seuils
    $warningDate = $currentDate.AddDays(-$warningThreshold)
    $criticalDate = $currentDate.AddDays(-$criticalThreshold)
    
    # Filtrer les logins SQL qui ont une date de derniÃ¨re connexion
    $loginsWithLastLogin = $ServerLogins | Where-Object { 
        $_.LoginType -eq "SQL_LOGIN" -and 
        $_.LastLogin -ne $null -and 
        -not $_.IsDisabled
    }
    
    foreach ($login in $loginsWithLastLogin) {
        # Calculer le nombre de jours depuis la derniÃ¨re connexion
        $daysSinceLastLogin = [math]::Round(($currentDate - $login.LastLogin).TotalDays)
        
        # VÃ©rifier si le compte est critique (inactif depuis plus de 90 jours)
        if ($login.LastLogin -lt $criticalDate) {
            $results += [PSCustomObject]@{
                LoginName = $login.LoginName
                Description = "Le login SQL est inactif depuis $daysSinceLastLogin jours (dernier accÃ¨s: $($login.LastLogin.ToString('yyyy-MM-dd')))"
                RecommendedAction = "DÃ©sactiver le compte ou le supprimer s'il n'est plus nÃ©cessaire"
            }
        }
        # VÃ©rifier si le compte est en avertissement (inactif depuis plus de 60 jours)
        elseif ($login.LastLogin -lt $warningDate) {
            $results += [PSCustomObject]@{
                LoginName = $login.LoginName
                Description = "Le login SQL est inactif depuis $daysSinceLastLogin jours (dernier accÃ¨s: $($login.LastLogin.ToString('yyyy-MM-dd')))"
                RecommendedAction = "VÃ©rifier si ce compte est toujours nÃ©cessaire"
            }
        }
    }
    
    # VÃ©rifier les comptes qui n'ont jamais Ã©tÃ© utilisÃ©s
    $neverUsedLogins = $ServerLogins | Where-Object { 
        $_.LoginType -eq "SQL_LOGIN" -and 
        $_.LastLogin -eq $null -and 
        $_.CreateDate -lt $warningDate -and
        -not $_.IsDisabled
    }
    
    foreach ($login in $neverUsedLogins) {
        $daysSinceCreation = [math]::Round(($currentDate - $login.CreateDate).TotalDays)
        
        $results += [PSCustomObject]@{
            LoginName = $login.LoginName
            Description = "Le login SQL a Ã©tÃ© crÃ©Ã© il y a $daysSinceCreation jours mais n'a jamais Ã©tÃ© utilisÃ©"
            RecommendedAction = "DÃ©sactiver le compte ou le supprimer s'il n'est plus nÃ©cessaire"
        }
    }
    
    return $results
