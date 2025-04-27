    param($ObjectPermissions, $DatabaseUsers, $DatabaseName)
    $results = @()
    
    # 1. Détecter les utilisateurs avec des permissions CONTROL sur des objets sensibles
    $sensitiveObjectTypes = @("USER_TABLE", "VIEW", "PROCEDURE", "FUNCTION", "ASSEMBLY")
    
    foreach ($userPerm in $ObjectPermissions) {
        $controlObjects = $userPerm.ObjectPermissions | Where-Object {
            $sensitiveObjectTypes -contains $_.ObjectType -and
            $_.Permissions | Where-Object {
                $_.PermissionName -eq "CONTROL" -and $_.PermissionState -eq "GRANT"
            }
        }

        if ($controlObjects -and $controlObjects.Count -gt 0) {
            # Exclure les comptes système et dbo
            if (-not $userPerm.GranteeName.StartsWith("##") -and $userPerm.GranteeName -ne "dbo") {
                $results += [PSCustomObject]@{
                    DatabaseName = $DatabaseName
                    UserName = $userPerm.GranteeName
                    Description = "L'utilisateur possède la permission CONTROL sur $($controlObjects.Count) objets sensibles"
                    RecommendedAction = "Remplacer par des permissions plus spécifiques (SELECT, INSERT, UPDATE, EXECUTE, etc.)"
                    AffectedObjects = $controlObjects | ForEach-Object { $_.ObjectName }
                }
            }
        }
    }
    
    # 2. Détecter les utilisateurs avec des permissions ALTER sur des objets sensibles
    foreach ($userPerm in $ObjectPermissions) {
        $alterObjects = $userPerm.ObjectPermissions | Where-Object {
            $sensitiveObjectTypes -contains $_.ObjectType -and
            $_.Permissions | Where-Object {
                $_.PermissionName -eq "ALTER" -and $_.PermissionState -eq "GRANT"
            }
        }

        if ($alterObjects -and $alterObjects.Count -gt 0) {
            # Exclure les comptes système et dbo
            if (-not $userPerm.GranteeName.StartsWith("##") -and $userPerm.GranteeName -ne "dbo") {
                $results += [PSCustomObject]@{
                    DatabaseName = $DatabaseName
                    UserName = $userPerm.GranteeName
                    Description = "L'utilisateur possède la permission ALTER sur $($alterObjects.Count) objets sensibles"
                    RecommendedAction = "Limiter les permissions de modification aux administrateurs de base de données"
                    AffectedObjects = $alterObjects | ForEach-Object { $_.ObjectName }
                }
            }
        }
    }
    
    # 3. Détecter les utilisateurs avec des permissions TAKE OWNERSHIP sur des objets
    foreach ($userPerm in $ObjectPermissions) {
        $takeOwnershipObjects = $userPerm.ObjectPermissions | Where-Object {
            $_.Permissions | Where-Object {
                $_.PermissionName -eq "TAKE OWNERSHIP" -and $_.PermissionState -eq "GRANT"
            }
        }

        if ($takeOwnershipObjects -and $takeOwnershipObjects.Count -gt 0) {
            # Exclure les comptes système et dbo
            if (-not $userPerm.GranteeName.StartsWith("##") -and $userPerm.GranteeName -ne "dbo") {
                $results += [PSCustomObject]@{
                    DatabaseName = $DatabaseName
                    UserName = $userPerm.GranteeName
                    Description = "L'utilisateur possède la permission TAKE OWNERSHIP sur $($takeOwnershipObjects.Count) objets"
                    RecommendedAction = "Révoquer cette permission et utiliser des propriétaires spécifiques pour les objets"
                    AffectedObjects = $takeOwnershipObjects | ForEach-Object { $_.ObjectName }
                }
            }
        }
    }
    
    # 4. Détecter les utilisateurs avec des permissions excessives sur des tables contenant des données sensibles
    $potentiallySensitiveTables = $ObjectPermissions | ForEach-Object { 
        $_.ObjectPermissions | Where-Object { 
            $_.ObjectType -eq "USER_TABLE" -and 
            ($_.ObjectName -like "*user*" -or 
             $_.ObjectName -like "*customer*" -or 
             $_.ObjectName -like "*account*" -or 
             $_.ObjectName -like "*password*" -or 
             $_.ObjectName -like "*credit*" -or 
             $_.ObjectName -like "*payment*" -or 
             $_.ObjectName -like "*personal*" -or 
             $_.ObjectName -like "*secure*" -or 
             $_.ObjectName -like "*confidential*" -or 
             $_.ObjectName -like "*private*")
        }
    } | Select-Object -Unique

    foreach ($userPerm in $ObjectPermissions) {
        $sensitiveTables = $userPerm.ObjectPermissions | Where-Object {
            $table = $_
            $potentiallySensitiveTables | Where-Object { $_.ObjectName -eq $table.ObjectName }
        }
        
        if ($sensitiveTables -and $sensitiveTables.Count -gt 0) {
            $excessivePermTables = $sensitiveTables | Where-Object {
                $_.Permissions | Where-Object {
                    $_.PermissionName -in @("CONTROL", "ALTER", "TAKE OWNERSHIP", "DELETE", "INSERT", "UPDATE", "REFERENCES") -and
                    $_.PermissionState -eq "GRANT"
                }
            }

            if ($excessivePermTables -and $excessivePermTables.Count -gt 0) {
                # Exclure les comptes système et dbo
                if (-not $userPerm.GranteeName.StartsWith("##") -and $userPerm.GranteeName -ne "dbo") {
                    $results += [PSCustomObject]@{
                        DatabaseName = $DatabaseName
                        UserName = $userPerm.GranteeName
                        Description = "L'utilisateur possède des permissions potentiellement excessives sur $($excessivePermTables.Count) tables contenant des données sensibles"
                        RecommendedAction = "Limiter les permissions aux opérations nécessaires (SELECT uniquement si possible)"
                        AffectedObjects = $excessivePermTables | ForEach-Object { $_.ObjectName }
                    }
                }
            }
        }
    }
    
    # 5. Détecter les utilisateurs avec des permissions sur un grand nombre d'objets
    $objectCountThreshold = 50  # Seuil à partir duquel le nombre d'objets est considéré comme excessif
    
    foreach ($userPerm in $ObjectPermissions) {
        if ($userPerm.ObjectCount -gt $objectCountThreshold) {
            # Exclure les comptes système, dbo et les comptes de service connus
            if (-not $userPerm.GranteeName.StartsWith("##") -and 
                $userPerm.GranteeName -ne "dbo" -and
                -not $userPerm.GranteeName.EndsWith("_svc") -and
                -not $userPerm.GranteeName.EndsWith("_service")) {
                
                $results += [PSCustomObject]@{
                    DatabaseName = $DatabaseName
                    UserName = $userPerm.GranteeName
                    Description = "L'utilisateur possède des permissions sur un nombre excessif d'objets ($($userPerm.ObjectCount) > $objectCountThreshold)"
                    RecommendedAction = "Vérifier si ces permissions sont nécessaires ou si elles peuvent être gérées via des rôles"
                    AffectedObjects = "Nombre total d'objets: $($userPerm.ObjectCount)"
                }
            }
        }
    }
    
    return $results
