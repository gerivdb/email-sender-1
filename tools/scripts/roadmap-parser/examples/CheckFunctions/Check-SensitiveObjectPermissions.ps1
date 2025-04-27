    param($ObjectPermissions, $DatabaseUsers, $DatabaseName)
    $results = @()
    
    # 1. Définir les modèles de noms d'objets sensibles
    $sensitiveObjectPatterns = @(
        # Données personnelles
        "*user*", "*customer*", "*client*", "*person*", "*employee*", "*member*",
        # Données financières
        "*account*", "*payment*", "*credit*", "*debit*", "*transaction*", "*financial*", "*money*", "*salary*", "*invoice*",
        # Données de sécurité
        "*password*", "*credential*", "*secret*", "*secure*", "*security*", "*auth*", "*token*", "*key*",
        # Données médicales
        "*patient*", "*medical*", "*health*", "*clinical*", "*diagnosis*", "*treatment*",
        # Données confidentielles
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
                    break  # Sortir de la boucle des patterns une fois qu'une correspondance est trouvée
                }
            }
        }
    }
    
    # Éliminer les doublons
    $sensitiveObjects = $sensitiveObjects | Sort-Object -Property ObjectName, ObjectType -Unique
    
    # 3. Vérifier les permissions sur les objets sensibles
    foreach ($userPerm in $ObjectPermissions) {
        $userSensitiveObjects = @()
        
        foreach ($obj in $userPerm.ObjectPermissions) {
            if ($sensitiveObjects | Where-Object { $_.ObjectName -eq $obj.ObjectName -and $_.ObjectType -eq $obj.ObjectType }) {
                $userSensitiveObjects += $obj
            }
        }
        
        if ($userSensitiveObjects.Count -gt 0) {
            # 3.1. Vérifier les permissions de modification sur les objets sensibles
            $modifyPermObjects = $userSensitiveObjects | Where-Object {
                $_.Permissions | Where-Object {
                    $_.PermissionName -in @("INSERT", "UPDATE", "DELETE", "ALTER", "CONTROL", "TAKE OWNERSHIP") -and
                    $_.PermissionState -eq "GRANT"
                }
            }
            
            if ($modifyPermObjects -and $modifyPermObjects.Count -gt 0) {
                # Exclure les comptes système, dbo et les comptes de service connus
                if (-not $userPerm.GranteeName.StartsWith("##") -and 
                    $userPerm.GranteeName -ne "dbo" -and
                    -not $userPerm.GranteeName.EndsWith("_svc") -and
                    -not $userPerm.GranteeName.EndsWith("_service")) {
                    
                    $results += [PSCustomObject]@{
                        DatabaseName = $DatabaseName
                        UserName = $userPerm.GranteeName
                        Description = "L'utilisateur possède des permissions de modification sur $($modifyPermObjects.Count) objets sensibles"
                        RecommendedAction = "Limiter les permissions aux opérations nécessaires (SELECT uniquement si possible)"
                        AffectedObjects = $modifyPermObjects | ForEach-Object { "$($_.ObjectName) ($($_.ObjectType))" }
                    }
                }
            }
            
            # 3.2. Vérifier les permissions de lecture sur les objets très sensibles (mots de passe, données financières, etc.)
            $veryHighSensitivityPatterns = @("*password*", "*credential*", "*secret*", "*secure*", "*credit*", "*ssn*", "*social*security*", "*confidential*")
            $veryHighSensitivityObjects = $userSensitiveObjects | Where-Object {
                $obj = $_
                $veryHighSensitivityPatterns | Where-Object { $obj.ObjectName -like $_ }
            }
            
            if ($veryHighSensitivityObjects -and $veryHighSensitivityObjects.Count -gt 0) {
                # Exclure les comptes système, dbo et les comptes de service connus
                if (-not $userPerm.GranteeName.StartsWith("##") -and 
                    $userPerm.GranteeName -ne "dbo" -and
                    -not $userPerm.GranteeName.EndsWith("_svc") -and
                    -not $userPerm.GranteeName.EndsWith("_service")) {
                    
                    $results += [PSCustomObject]@{
                        DatabaseName = $DatabaseName
                        UserName = $userPerm.GranteeName
                        Description = "L'utilisateur possède des permissions sur $($veryHighSensitivityObjects.Count) objets hautement sensibles"
                        RecommendedAction = "Vérifier si cet accès est nécessaire et conforme aux politiques de sécurité et de confidentialité"
                        AffectedObjects = $veryHighSensitivityObjects | ForEach-Object { "$($_.ObjectName) ($($_.ObjectType))" }
                    }
                }
            }
            
            # 3.3. Vérifier les utilisateurs non-administratifs avec accès à de nombreux objets sensibles
            $sensitivityThreshold = 10  # Seuil à partir duquel le nombre d'objets sensibles est considéré comme élevé
            
            if ($userSensitiveObjects.Count -gt $sensitivityThreshold) {
                # Exclure les comptes système, dbo, les comptes de service connus et les comptes administratifs
                if (-not $userPerm.GranteeName.StartsWith("##") -and 
                    $userPerm.GranteeName -ne "dbo" -and
                    -not $userPerm.GranteeName.EndsWith("_svc") -and
                    -not $userPerm.GranteeName.EndsWith("_service") -and
                    -not $userPerm.GranteeName -like "*admin*" -and
                    -not $userPerm.GranteeName -like "*dba*") {
                    
                    $results += [PSCustomObject]@{
                        DatabaseName = $DatabaseName
                        UserName = $userPerm.GranteeName
                        Description = "L'utilisateur non-administratif possède des permissions sur un nombre élevé d'objets sensibles ($($userSensitiveObjects.Count) > $sensitivityThreshold)"
                        RecommendedAction = "Vérifier si cet accès étendu est nécessaire ou s'il peut être limité"
                        AffectedObjects = "Nombre total d'objets sensibles: $($userSensitiveObjects.Count)"
                    }
                }
            }
        }
    }
    
    return $results
