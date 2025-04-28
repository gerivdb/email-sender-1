    param($ServerLogins, $ServerRoles, $ServerPermissions, $DatabaseRoles, $DatabasePermissions, $DatabaseUsers)
    $results = @()
    
    # 1. Identifier les utilisateurs prÃ©sents dans plusieurs bases de donnÃ©es
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
    
    # 2. Identifier les utilisateurs avec des permissions Ã©levÃ©es dans plusieurs bases de donnÃ©es
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
    
    # 3. Identifier les utilisateurs avec des permissions CONTROL DATABASE dans plusieurs bases de donnÃ©es
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
    
    # 4. Analyser les rÃ©sultats et gÃ©nÃ©rer les anomalies
    
    # 4.1. Utilisateurs avec des permissions Ã©levÃ©es dans plusieurs bases de donnÃ©es
    foreach ($login in $userHighPrivDatabases.Keys) {
        if ($userHighPrivDatabases[$login].Count -gt 1) {
            # Exclure les comptes systÃ¨me et les comptes administratifs connus
            if (-not $login.StartsWith("##") -and 
                $login -ne "sa" -and
                -not $login.StartsWith("NT ")) {
                
                $databaseList = $userHighPrivDatabases[$login] -join ", "
                
                $results += [PSCustomObject]@{
                    LoginName = $login
                    Description = "Le login possÃ¨de des permissions Ã©levÃ©es (rÃ´les db_owner, db_securityadmin, etc.) dans plusieurs bases de donnÃ©es: $databaseList"
                    RecommendedAction = "VÃ©rifier si ce niveau de privilÃ¨ge est nÃ©cessaire dans toutes ces bases de donnÃ©es"
                }
            }
        }
    }
    
    # 4.2. Utilisateurs avec des permissions CONTROL DATABASE dans plusieurs bases de donnÃ©es
    foreach ($login in $userControlDatabases.Keys) {
        if ($userControlDatabases[$login].Count -gt 1) {
            # Exclure les comptes systÃ¨me et les comptes administratifs connus
            if (-not $login.StartsWith("##") -and 
                $login -ne "sa" -and
                -not $login.StartsWith("NT ")) {
                
                $databaseList = $userControlDatabases[$login] -join ", "
                
                $results += [PSCustomObject]@{
                    LoginName = $login
                    Description = "Le login possÃ¨de la permission CONTROL DATABASE dans plusieurs bases de donnÃ©es: $databaseList"
                    RecommendedAction = "VÃ©rifier si ce niveau de privilÃ¨ge est nÃ©cessaire dans toutes ces bases de donnÃ©es"
                }
            }
        }
    }
    
    # 4.3. Utilisateurs non-administratifs prÃ©sents dans un grand nombre de bases de donnÃ©es
    $databaseThreshold = 5  # Seuil Ã  partir duquel le nombre de bases de donnÃ©es est considÃ©rÃ© comme Ã©levÃ©
    
    foreach ($login in $userDatabases.Keys) {
        if ($userDatabases[$login].Count -gt $databaseThreshold) {
            # Exclure les comptes systÃ¨me, les comptes administratifs connus et les comptes de service
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
                    Description = "Le login non-administratif est prÃ©sent dans un nombre Ã©levÃ© de bases de donnÃ©es ($($userDatabases[$login].Count) > $databaseThreshold): $databaseList"
                    RecommendedAction = "VÃ©rifier si cet accÃ¨s Ã©tendu est nÃ©cessaire ou s'il peut Ãªtre limitÃ©"
                }
            }
        }
    }
    
    # 4.4. Utilisateurs avec des permissions dans des bases de donnÃ©es de diffÃ©rents environnements
    $environmentPatterns = @(
        @{ Pattern = "*dev*"; Environment = "DÃ©veloppement" },
        @{ Pattern = "*test*"; Environment = "Test" },
        @{ Pattern = "*qa*"; Environment = "Assurance qualitÃ©" },
        @{ Pattern = "*prod*"; Environment = "Production" },
        @{ Pattern = "*stage*"; Environment = "PrÃ©production" }
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
            # Exclure les comptes systÃ¨me et les comptes administratifs connus
            if (-not $login.StartsWith("##") -and 
                $login -ne "sa" -and
                -not $login.StartsWith("NT ")) {
                
                $environmentList = $userEnvironments.Keys -join ", "
                
                $results += [PSCustomObject]@{
                    LoginName = $login
                    Description = "Le login possÃ¨de des permissions dans des bases de donnÃ©es de diffÃ©rents environnements: $environmentList"
                    RecommendedAction = "SÃ©parer les accÃ¨s par environnement pour respecter la sÃ©paration des environnements"
                }
            }
        }
    }
    
    return $results
