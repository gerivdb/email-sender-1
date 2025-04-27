    param($ObjectPermissions, $DatabaseUsers, $DatabaseName)
    $results = @()
    
    # 1. DÃ©finir les modÃ¨les de noms d'objets sensibles
    $sensitiveObjectPatterns = @(
        # DonnÃ©es personnelles
        "*user*", "*customer*", "*client*", "*person*", "*employee*", "*member*",
        # DonnÃ©es financiÃ¨res
        "*account*", "*payment*", "*credit*", "*debit*", "*transaction*", "*financial*", "*money*", "*salary*", "*invoice*",
        # DonnÃ©es de sÃ©curitÃ©
        "*password*", "*credential*", "*secret*", "*secure*", "*security*", "*auth*", "*token*", "*key*",
        # DonnÃ©es mÃ©dicales
        "*patient*", "*medical*", "*health*", "*clinical*", "*diagnosis*", "*treatment*",
        # DonnÃ©es confidentielles
        "*confidential*", "*private*", "*sensitive*", "*restricted*", "*internal*",
        # Audit et journalisation
        "*audit*", "*log*", "*trace*", "*monitor*"
    )
    
    # 2. Identifier les objets sensibles
    $sensitiveObjects = @()
    
    foreach ($userPerm in $ObjectPermissions) {
        foreach ($obj in $userPerm.ObjectPermissions) {
            foreach ($pattern in $sensitiveObjectPatterns) {
                if ($obj.ObjectName -like $pattern) {
                    $sensitiveObjects += [PSCustomObject]@{
                        ObjectName = $obj.ObjectName
                        ObjectType = $obj.ObjectType
                        Pattern = $pattern
                    }
                    break  # Sortir de la boucle des patterns une fois qu'une correspondance est trouvÃ©e
                }
            }
        }
    }
    
    # Ã‰liminer les doublons
    $sensitiveObjects = $sensitiveObjects | Sort-Object -Property ObjectName, ObjectType -Unique
    
    # 3. VÃ©rifier les permissions sur les objets sensibles
    foreach ($userPerm in $ObjectPermissions) {
        $userSensitiveObjects = @()
        
        foreach ($obj in $userPerm.ObjectPermissions) {
            if ($sensitiveObjects | Where-Object { $_.ObjectName -eq $obj.ObjectName -and $_.ObjectType -eq $obj.ObjectType }) {
                $userSensitiveObjects += $obj
            }
        }
        
        if ($userSensitiveObjects.Count -gt 0) {
            # 3.1. VÃ©rifier les permissions de modification sur les objets sensibles
            $modifyPermObjects = $userSensitiveObjects | Where-Object {
                $_.Permissions | Where-Object {
                    $_.PermissionName -in @("INSERT", "UPDATE", "DELETE", "ALTER", "CONTROL", "TAKE OWNERSHIP") -and
                    $_.PermissionState -eq "GRANT"
                }
            }
            
            if ($modifyPermObjects -and $modifyPermObjects.Count -gt 0) {
                # Exclure les comptes systÃ¨me, dbo et les comptes de service connus
                if (-not $userPerm.GranteeName.StartsWith("##") -and 
                    $userPerm.GranteeName -ne "dbo" -and
                    -not $userPerm.GranteeName.EndsWith("_svc") -and
                    -not $userPerm.GranteeName.EndsWith("_service")) {
                    
                    $results += [PSCustomObject]@{
                        DatabaseName = $DatabaseName
                        UserName = $userPerm.GranteeName
                        Description = "L'utilisateur possÃ¨de des permissions de modification sur $($modifyPermObjects.Count) objets sensibles"
                        RecommendedAction = "Limiter les permissions aux opÃ©rations nÃ©cessaires (SELECT uniquement si possible)"
                        AffectedObjects = $modifyPermObjects | ForEach-Object { "$($_.ObjectName) ($($_.ObjectType))" }
                    }
                }
            }
            
            # 3.2. VÃ©rifier les permissions de lecture sur les objets trÃ¨s sensibles (mots de passe, donnÃ©es financiÃ¨res, etc.)
            $veryHighSensitivityPatterns = @("*password*", "*credential*", "*secret*", "*secure*", "*credit*", "*ssn*", "*social*security*", "*confidential*")
            $veryHighSensitivityObjects = $userSensitiveObjects | Where-Object {
                $obj = $_
                $veryHighSensitivityPatterns | Where-Object { $obj.ObjectName -like $_ }
            }
            
            if ($veryHighSensitivityObjects -and $veryHighSensitivityObjects.Count -gt 0) {
                # Exclure les comptes systÃ¨me, dbo et les comptes de service connus
                if (-not $userPerm.GranteeName.StartsWith("##") -and 
                    $userPerm.GranteeName -ne "dbo" -and
                    -not $userPerm.GranteeName.EndsWith("_svc") -and
                    -not $userPerm.GranteeName.EndsWith("_service")) {
                    
                    $results += [PSCustomObject]@{
                        DatabaseName = $DatabaseName
                        UserName = $userPerm.GranteeName
                        Description = "L'utilisateur possÃ¨de des permissions sur $($veryHighSensitivityObjects.Count) objets hautement sensibles"
                        RecommendedAction = "VÃ©rifier si cet accÃ¨s est nÃ©cessaire et conforme aux politiques de sÃ©curitÃ© et de confidentialitÃ©"
                        AffectedObjects = $veryHighSensitivityObjects | ForEach-Object { "$($_.ObjectName) ($($_.ObjectType))" }
                    }
                }
            }
            
            # 3.3. VÃ©rifier les utilisateurs non-administratifs avec accÃ¨s Ã  de nombreux objets sensibles
            $sensitivityThreshold = 10  # Seuil Ã  partir duquel le nombre d'objets sensibles est considÃ©rÃ© comme Ã©levÃ©
            
            if ($userSensitiveObjects.Count -gt $sensitivityThreshold) {
                # Exclure les comptes systÃ¨me, dbo, les comptes de service connus et les comptes administratifs
                if (-not $userPerm.GranteeName.StartsWith("##") -and 
                    $userPerm.GranteeName -ne "dbo" -and
                    -not $userPerm.GranteeName.EndsWith("_svc") -and
                    -not $userPerm.GranteeName.EndsWith("_service") -and
                    -not $userPerm.GranteeName -like "*admin*" -and
                    -not $userPerm.GranteeName -like "*dba*") {
                    
                    $results += [PSCustomObject]@{
                        DatabaseName = $DatabaseName
                        UserName = $userPerm.GranteeName
                        Description = "L'utilisateur non-administratif possÃ¨de des permissions sur un nombre Ã©levÃ© d'objets sensibles ($($userSensitiveObjects.Count) > $sensitivityThreshold)"
                        RecommendedAction = "VÃ©rifier si cet accÃ¨s Ã©tendu est nÃ©cessaire ou s'il peut Ãªtre limitÃ©"
                        AffectedObjects = "Nombre total d'objets sensibles: $($userSensitiveObjects.Count)"
                    }
                }
            }
        }
    }
    
    return $results
