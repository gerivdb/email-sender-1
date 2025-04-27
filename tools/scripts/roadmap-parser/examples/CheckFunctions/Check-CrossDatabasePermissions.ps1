    param($ServerLogins, $ServerRoles, $ServerPermissions, $DatabaseRoles, $DatabasePermissions, $DatabaseUsers)
    $results = @()
    
    # 1. Identifier les utilisateurs présents dans plusieurs bases de données
    $userDatabases = @{}
    
    foreach ($dbUser in $DatabaseUsers) {
        if (-not [string]::IsNullOrEmpty($dbUser.LoginName)) {
            if (-not $userDatabases.ContainsKey($dbUser.LoginName)) {
                $userDatabases[$dbUser.LoginName] = @()
            }
            
            if (-not $userDatabases[$dbUser.LoginName].Contains($dbUser.DatabaseName)) {
                $userDatabases[$dbUser.LoginName] += $dbUser.DatabaseName
            }
        }
    }
    
    # 2. Identifier les utilisateurs avec des permissions élevées dans plusieurs bases de données
    $highPrivilegeRoles = @("db_owner", "db_securityadmin", "db_accessadmin", "db_ddladmin")
    $userHighPrivDatabases = @{}
    
    foreach ($dbRole in $DatabaseRoles | Where-Object { $highPrivilegeRoles -contains $_.RoleName }) {
        foreach ($member in $dbRole.Members) {
            $dbUser = $DatabaseUsers | Where-Object { 
                $_.DatabaseName -eq $dbRole.DatabaseName -and $_.UserName -eq $member.MemberName 
            }
            
            if ($dbUser -and -not [string]::IsNullOrEmpty($dbUser.LoginName)) {
                if (-not $userHighPrivDatabases.ContainsKey($dbUser.LoginName)) {
                    $userHighPrivDatabases[$dbUser.LoginName] = @()
                }
                
                if (-not $userHighPrivDatabases[$dbUser.LoginName].Contains($dbRole.DatabaseName)) {
                    $userHighPrivDatabases[$dbUser.LoginName] += $dbRole.DatabaseName
                }
            }
        }
    }
    
    # 3. Identifier les utilisateurs avec des permissions CONTROL DATABASE dans plusieurs bases de données
    $userControlDatabases = @{}
    
    foreach ($dbPerm in $DatabasePermissions) {
        $hasControlPermission = $dbPerm.Permissions | Where-Object {
            $_.PermissionName -eq "CONTROL" -and $_.SecurableType -eq "DATABASE" -and $_.PermissionState -eq "GRANT"
        }
        
        if ($hasControlPermission) {
            $dbUser = $DatabaseUsers | Where-Object { 
                $_.DatabaseName -eq $dbPerm.DatabaseName -and $_.UserName -eq $dbPerm.GranteeName 
            }
            
            if ($dbUser -and -not [string]::IsNullOrEmpty($dbUser.LoginName)) {
                if (-not $userControlDatabases.ContainsKey($dbUser.LoginName)) {
                    $userControlDatabases[$dbUser.LoginName] = @()
                }
                
                if (-not $userControlDatabases[$dbUser.LoginName].Contains($dbPerm.DatabaseName)) {
                    $userControlDatabases[$dbUser.LoginName] += $dbPerm.DatabaseName
                }
            }
        }
    }
    
    # 4. Analyser les résultats et générer les anomalies
    
    # 4.1. Utilisateurs avec des permissions élevées dans plusieurs bases de données
    foreach ($login in $userHighPrivDatabases.Keys) {
        if ($userHighPrivDatabases[$login].Count -gt 1) {
            # Exclure les comptes système et les comptes administratifs connus
            if (-not $login.StartsWith("##") -and 
                $login -ne "sa" -and
                -not $login.StartsWith("NT ")) {
                
                $databaseList = $userHighPrivDatabases[$login] -join ", "
                
                $results += [PSCustomObject]@{
                    LoginName = $login
                    Description = "Le login possède des permissions élevées (rôles db_owner, db_securityadmin, etc.) dans plusieurs bases de données: $databaseList"
                    RecommendedAction = "Vérifier si ce niveau de privilège est nécessaire dans toutes ces bases de données"
                }
            }
        }
    }
    
    # 4.2. Utilisateurs avec des permissions CONTROL DATABASE dans plusieurs bases de données
    foreach ($login in $userControlDatabases.Keys) {
        if ($userControlDatabases[$login].Count -gt 1) {
            # Exclure les comptes système et les comptes administratifs connus
            if (-not $login.StartsWith("##") -and 
                $login -ne "sa" -and
                -not $login.StartsWith("NT ")) {
                
                $databaseList = $userControlDatabases[$login] -join ", "
                
                $results += [PSCustomObject]@{
                    LoginName = $login
                    Description = "Le login possède la permission CONTROL DATABASE dans plusieurs bases de données: $databaseList"
                    RecommendedAction = "Vérifier si ce niveau de privilège est nécessaire dans toutes ces bases de données"
                }
            }
        }
    }
    
    # 4.3. Utilisateurs non-administratifs présents dans un grand nombre de bases de données
    $databaseThreshold = 5  # Seuil à partir duquel le nombre de bases de données est considéré comme élevé
    
    foreach ($login in $userDatabases.Keys) {
        if ($userDatabases[$login].Count -gt $databaseThreshold) {
            # Exclure les comptes système, les comptes administratifs connus et les comptes de service
            if (-not $login.StartsWith("##") -and 
                $login -ne "sa" -and
                -not $login.StartsWith("NT ") -and
                -not $login -like "*admin*" -and
                -not $login -like "*dba*" -and
                -not $login.EndsWith("_svc") -and
                -not $login.EndsWith("_service")) {
                
                $databaseList = $userDatabases[$login] -join ", "
                
                $results += [PSCustomObject]@{
                    LoginName = $login
                    Description = "Le login non-administratif est présent dans un nombre élevé de bases de données ($($userDatabases[$login].Count) > $databaseThreshold): $databaseList"
                    RecommendedAction = "Vérifier si cet accès étendu est nécessaire ou s'il peut être limité"
                }
            }
        }
    }
    
    # 4.4. Utilisateurs avec des permissions dans des bases de données de différents environnements
    $environmentPatterns = @(
        @{ Pattern = "*dev*"; Environment = "Développement" },
        @{ Pattern = "*test*"; Environment = "Test" },
        @{ Pattern = "*qa*"; Environment = "Assurance qualité" },
        @{ Pattern = "*prod*"; Environment = "Production" },
        @{ Pattern = "*stage*"; Environment = "Préproduction" }
    )
    
    foreach ($login in $userDatabases.Keys) {
        $userEnvironments = @{}
        
        foreach ($dbName in $userDatabases[$login]) {
            foreach ($envPattern in $environmentPatterns) {
                if ($dbName -like $envPattern.Pattern) {
                    if (-not $userEnvironments.ContainsKey($envPattern.Environment)) {
                        $userEnvironments[$envPattern.Environment] = @()
                    }
                    
                    $userEnvironments[$envPattern.Environment] += $dbName
                }
            }
        }
        
        if ($userEnvironments.Keys.Count -gt 1) {
            # Exclure les comptes système et les comptes administratifs connus
            if (-not $login.StartsWith("##") -and 
                $login -ne "sa" -and
                -not $login.StartsWith("NT ")) {
                
                $environmentList = $userEnvironments.Keys -join ", "
                
                $results += [PSCustomObject]@{
                    LoginName = $login
                    Description = "Le login possède des permissions dans des bases de données de différents environnements: $environmentList"
                    RecommendedAction = "Séparer les accès par environnement pour respecter la séparation des environnements"
                }
            }
        }
    }
    
    return $results
