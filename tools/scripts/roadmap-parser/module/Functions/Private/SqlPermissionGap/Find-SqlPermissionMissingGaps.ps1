function Find-SqlPermissionMissingGaps {
    <#
    .SYNOPSIS
        DÃ©tecte les permissions manquantes par rapport Ã  un modÃ¨le de rÃ©fÃ©rence.
    
    .DESCRIPTION
        Cette fonction compare les permissions actuelles d'une instance SQL Server avec un modÃ¨le de rÃ©fÃ©rence
        et identifie les permissions qui sont prÃ©sentes dans le modÃ¨le mais absentes dans l'instance actuelle.
    
    .PARAMETER CurrentPermissions
        Les permissions actuelles de l'instance SQL Server.
    
    .PARAMETER ReferenceModel
        Le modÃ¨le de rÃ©fÃ©rence contenant les permissions attendues.
    
    .PARAMETER Level
        Le niveau de comparaison (Server, Database, Object).
    
    .PARAMETER ExcludeSystemObjects
        Indique si les objets systÃ¨me doivent Ãªtre exclus de la comparaison.
    
    .PARAMETER ExcludeSystemPrincipals
        Indique si les principaux systÃ¨me doivent Ãªtre exclus de la comparaison.
    
    .EXAMPLE
        Find-SqlPermissionMissingGaps -CurrentPermissions $currentPerms -ReferenceModel $refModel -Level "Server"
    
    .NOTES
        Cette fonction fait partie du module de dÃ©tection d'Ã©carts de permissions SQL Server.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$CurrentPermissions,
        
        [Parameter(Mandatory = $true)]
        [PSObject]$ReferenceModel,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Server", "Database", "Object")]
        [string]$Level,
        
        [Parameter(Mandatory = $false)]
        [switch]$ExcludeSystemObjects,
        
        [Parameter(Mandatory = $false)]
        [switch]$ExcludeSystemPrincipals
    )
    
    begin {
        # Initialiser le tableau des Ã©carts
        $missingGaps = @()
        
        # Fonction pour vÃ©rifier si un principal est un principal systÃ¨me
        function Test-IsSystemPrincipal {
            param (
                [string]$PrincipalName
            )
            
            return $PrincipalName -like "##*" -or 
                   $PrincipalName -eq "sa" -or 
                   $PrincipalName -like "NT SERVICE\*" -or 
                   $PrincipalName -like "NT AUTHORITY\*"
        }
        
        # Fonction pour vÃ©rifier si un objet est un objet systÃ¨me
        function Test-IsSystemObject {
            param (
                [string]$ObjectName,
                [string]$SchemaName
            )
            
            return $SchemaName -eq "sys" -or 
                   $SchemaName -eq "INFORMATION_SCHEMA" -or 
                   $ObjectName -like "sys*" -or 
                   $ObjectName -like "msdb*"
        }
    }
    
    process {
        try {
            # Traitement en fonction du niveau
            switch ($Level) {
                "Server" {
                    # Comparer les logins
                    foreach ($refLogin in $ReferenceModel.Logins) {
                        # Ignorer les principaux systÃ¨me si demandÃ©
                        if ($ExcludeSystemPrincipals -and (Test-IsSystemPrincipal -PrincipalName $refLogin.LoginName)) {
                            continue
                        }
                        
                        # VÃ©rifier si le login existe dans les permissions actuelles
                        $currentLogin = $CurrentPermissions.Logins | Where-Object { $_.LoginName -eq $refLogin.LoginName }
                        
                        if (-not $currentLogin) {
                            # Le login est manquant
                            $missingGaps += [PSCustomObject]@{
                                Level = "Server"
                                GapType = "MissingLogin"
                                PrincipalName = $refLogin.LoginName
                                PrincipalType = $refLogin.LoginType
                                Description = "Le login '$($refLogin.LoginName)' est prÃ©sent dans le modÃ¨le mais absent de l'instance actuelle"
                                Severity = "Ã‰levÃ©e"
                                RecommendedAction = "CrÃ©er le login manquant avec les propriÃ©tÃ©s appropriÃ©es"
                                ReferenceDetails = $refLogin
                            }
                        }
                        else {
                            # VÃ©rifier les propriÃ©tÃ©s du login
                            if ($refLogin.LoginType -ne $currentLogin.LoginType) {
                                $missingGaps += [PSCustomObject]@{
                                    Level = "Server"
                                    GapType = "LoginTypeMismatch"
                                    PrincipalName = $refLogin.LoginName
                                    PrincipalType = $refLogin.LoginType
                                    Description = "Le type du login '$($refLogin.LoginName)' est diffÃ©rent (ModÃ¨le: $($refLogin.LoginType), Actuel: $($currentLogin.LoginType))"
                                    Severity = "Moyenne"
                                    RecommendedAction = "RecrÃ©er le login avec le type correct"
                                    ReferenceDetails = $refLogin
                                    CurrentDetails = $currentLogin
                                }
                            }
                            
                            if ($refLogin.IsDisabled -ne $currentLogin.IsDisabled) {
                                $missingGaps += [PSCustomObject]@{
                                    Level = "Server"
                                    GapType = "LoginStatusMismatch"
                                    PrincipalName = $refLogin.LoginName
                                    PrincipalType = $refLogin.LoginType
                                    Description = "Le statut du login '$($refLogin.LoginName)' est diffÃ©rent (ModÃ¨le: $($refLogin.IsDisabled ? 'DÃ©sactivÃ©' : 'ActivÃ©'), Actuel: $($currentLogin.IsDisabled ? 'DÃ©sactivÃ©' : 'ActivÃ©'))"
                                    Severity = "Moyenne"
                                    RecommendedAction = "Modifier le statut du login pour correspondre au modÃ¨le"
                                    ReferenceDetails = $refLogin
                                    CurrentDetails = $currentLogin
                                }
                            }
                        }
                        
                        # VÃ©rifier les rÃ´les serveur
                        foreach ($refRole in $ReferenceModel.ServerRoles) {
                            # VÃ©rifier si le login est membre du rÃ´le dans le modÃ¨le
                            $isMemberInRef = $refRole.Members | Where-Object { $_.MemberName -eq $refLogin.LoginName }
                            
                            if ($isMemberInRef) {
                                # VÃ©rifier si le rÃ´le existe dans les permissions actuelles
                                $currentRole = $CurrentPermissions.ServerRoles | Where-Object { $_.RoleName -eq $refRole.RoleName }
                                
                                if (-not $currentRole) {
                                    # Le rÃ´le est manquant
                                    $missingGaps += [PSCustomObject]@{
                                        Level = "Server"
                                        GapType = "MissingServerRole"
                                        PrincipalName = $refLogin.LoginName
                                        RoleName = $refRole.RoleName
                                        Description = "Le rÃ´le serveur '$($refRole.RoleName)' est prÃ©sent dans le modÃ¨le mais absent de l'instance actuelle"
                                        Severity = "Ã‰levÃ©e"
                                        RecommendedAction = "CrÃ©er le rÃ´le serveur manquant"
                                        ReferenceDetails = $refRole
                                    }
                                }
                                else {
                                    # VÃ©rifier si le login est membre du rÃ´le dans les permissions actuelles
                                    $isMemberInCurrent = $currentRole.Members | Where-Object { $_.MemberName -eq $refLogin.LoginName }
                                    
                                    if (-not $isMemberInCurrent) {
                                        # Le login n'est pas membre du rÃ´le
                                        $missingGaps += [PSCustomObject]@{
                                            Level = "Server"
                                            GapType = "MissingServerRoleMembership"
                                            PrincipalName = $refLogin.LoginName
                                            RoleName = $refRole.RoleName
                                            Description = "Le login '$($refLogin.LoginName)' devrait Ãªtre membre du rÃ´le serveur '$($refRole.RoleName)'"
                                            Severity = "Moyenne"
                                            RecommendedAction = "Ajouter le login au rÃ´le serveur"
                                            ReferenceDetails = $isMemberInRef
                                        }
                                    }
                                }
                            }
                        }
                        
                        # VÃ©rifier les permissions explicites
                        foreach ($refPermission in $ReferenceModel.ServerPermissions) {
                            if ($refPermission.GranteeName -eq $refLogin.LoginName) {
                                # VÃ©rifier si la permission existe dans les permissions actuelles
                                $currentPermission = $CurrentPermissions.ServerPermissions | 
                                                    Where-Object { $_.GranteeName -eq $refLogin.LoginName }
                                
                                if (-not $currentPermission) {
                                    # Aucune permission trouvÃ©e pour ce login
                                    $missingGaps += [PSCustomObject]@{
                                        Level = "Server"
                                        GapType = "MissingServerPermissions"
                                        PrincipalName = $refLogin.LoginName
                                        Description = "Le login '$($refLogin.LoginName)' n'a aucune permission explicite alors qu'il devrait en avoir"
                                        Severity = "Moyenne"
                                        RecommendedAction = "Accorder les permissions manquantes au login"
                                        ReferenceDetails = $refPermission
                                    }
                                }
                                else {
                                    # VÃ©rifier chaque permission individuelle
                                    foreach ($refPerm in $refPermission.Permissions) {
                                        $matchingPerm = $currentPermission.Permissions | 
                                                        Where-Object { 
                                                            $_.PermissionName -eq $refPerm.PermissionName -and 
                                                            $_.PermissionState -eq $refPerm.PermissionState -and
                                                            $_.SecurableType -eq $refPerm.SecurableType -and
                                                            $_.SecurableName -eq $refPerm.SecurableName
                                                        }
                                        
                                        if (-not $matchingPerm) {
                                            # Permission manquante
                                            $missingGaps += [PSCustomObject]@{
                                                Level = "Server"
                                                GapType = "MissingServerPermission"
                                                PrincipalName = $refLogin.LoginName
                                                PermissionName = $refPerm.PermissionName
                                                PermissionState = $refPerm.PermissionState
                                                SecurableType = $refPerm.SecurableType
                                                SecurableName = $refPerm.SecurableName
                                                Description = "Le login '$($refLogin.LoginName)' devrait avoir la permission '$($refPerm.PermissionState) $($refPerm.PermissionName)' sur $($refPerm.SecurableType) '$($refPerm.SecurableName)'"
                                                Severity = "Moyenne"
                                                RecommendedAction = "Accorder la permission manquante au login"
                                                ReferenceDetails = $refPerm
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                "Database" {
                    # Comparer les utilisateurs de base de donnÃ©es
                    foreach ($refDb in $ReferenceModel.Databases) {
                        $currentDb = $CurrentPermissions.Databases | Where-Object { $_.DatabaseName -eq $refDb.DatabaseName }
                        
                        if (-not $currentDb) {
                            # La base de donnÃ©es est manquante
                            $missingGaps += [PSCustomObject]@{
                                Level = "Database"
                                GapType = "MissingDatabase"
                                DatabaseName = $refDb.DatabaseName
                                Description = "La base de donnÃ©es '$($refDb.DatabaseName)' est prÃ©sente dans le modÃ¨le mais absente de l'instance actuelle"
                                Severity = "Ã‰levÃ©e"
                                RecommendedAction = "CrÃ©er la base de donnÃ©es manquante"
                                ReferenceDetails = $refDb
                            }
                            continue
                        }
                        
                        # Comparer les utilisateurs
                        foreach ($refUser in $refDb.DatabaseUsers) {
                            # Ignorer les principaux systÃ¨me si demandÃ©
                            if ($ExcludeSystemPrincipals -and (Test-IsSystemPrincipal -PrincipalName $refUser.UserName)) {
                                continue
                            }
                            
                            # VÃ©rifier si l'utilisateur existe dans les permissions actuelles
                            $currentUser = $currentDb.DatabaseUsers | Where-Object { $_.UserName -eq $refUser.UserName }
                            
                            if (-not $currentUser) {
                                # L'utilisateur est manquant
                                $missingGaps += [PSCustomObject]@{
                                    Level = "Database"
                                    GapType = "MissingDatabaseUser"
                                    DatabaseName = $refDb.DatabaseName
                                    PrincipalName = $refUser.UserName
                                    Description = "L'utilisateur '$($refUser.UserName)' est prÃ©sent dans le modÃ¨le pour la base de donnÃ©es '$($refDb.DatabaseName)' mais absent de l'instance actuelle"
                                    Severity = "Ã‰levÃ©e"
                                    RecommendedAction = "CrÃ©er l'utilisateur manquant avec les propriÃ©tÃ©s appropriÃ©es"
                                    ReferenceDetails = $refUser
                                }
                            }
                            else {
                                # VÃ©rifier les propriÃ©tÃ©s de l'utilisateur
                                if ($refUser.UserType -ne $currentUser.UserType) {
                                    $missingGaps += [PSCustomObject]@{
                                        Level = "Database"
                                        GapType = "DatabaseUserTypeMismatch"
                                        DatabaseName = $refDb.DatabaseName
                                        PrincipalName = $refUser.UserName
                                        Description = "Le type de l'utilisateur '$($refUser.UserName)' est diffÃ©rent (ModÃ¨le: $($refUser.UserType), Actuel: $($currentUser.UserType))"
                                        Severity = "Moyenne"
                                        RecommendedAction = "RecrÃ©er l'utilisateur avec le type correct"
                                        ReferenceDetails = $refUser
                                        CurrentDetails = $currentUser
                                    }
                                }
                                
                                if ($refUser.LoginName -ne $currentUser.LoginName) {
                                    $missingGaps += [PSCustomObject]@{
                                        Level = "Database"
                                        GapType = "DatabaseUserLoginMismatch"
                                        DatabaseName = $refDb.DatabaseName
                                        PrincipalName = $refUser.UserName
                                        Description = "Le login associÃ© Ã  l'utilisateur '$($refUser.UserName)' est diffÃ©rent (ModÃ¨le: $($refUser.LoginName), Actuel: $($currentUser.LoginName))"
                                        Severity = "Moyenne"
                                        RecommendedAction = "RecrÃ©er l'utilisateur avec le login correct"
                                        ReferenceDetails = $refUser
                                        CurrentDetails = $currentUser
                                    }
                                }
                            }
                            
                            # VÃ©rifier les rÃ´les de base de donnÃ©es
                            foreach ($refDbRole in $refDb.DatabaseRoles) {
                                # VÃ©rifier si l'utilisateur est membre du rÃ´le dans le modÃ¨le
                                $isMemberInRef = $refDbRole.Members | Where-Object { $_.MemberName -eq $refUser.UserName }
                                
                                if ($isMemberInRef) {
                                    # VÃ©rifier si le rÃ´le existe dans les permissions actuelles
                                    $currentDbRole = $currentDb.DatabaseRoles | Where-Object { $_.RoleName -eq $refDbRole.RoleName }
                                    
                                    if (-not $currentDbRole) {
                                        # Le rÃ´le est manquant
                                        $missingGaps += [PSCustomObject]@{
                                            Level = "Database"
                                            GapType = "MissingDatabaseRole"
                                            DatabaseName = $refDb.DatabaseName
                                            RoleName = $refDbRole.RoleName
                                            Description = "Le rÃ´le de base de donnÃ©es '$($refDbRole.RoleName)' est prÃ©sent dans le modÃ¨le mais absent de l'instance actuelle"
                                            Severity = "Ã‰levÃ©e"
                                            RecommendedAction = "CrÃ©er le rÃ´le de base de donnÃ©es manquant"
                                            ReferenceDetails = $refDbRole
                                        }
                                    }
                                    else {
                                        # VÃ©rifier si l'utilisateur est membre du rÃ´le dans les permissions actuelles
                                        $isMemberInCurrent = $currentDbRole.Members | Where-Object { $_.MemberName -eq $refUser.UserName }
                                        
                                        if (-not $isMemberInCurrent) {
                                            # L'utilisateur n'est pas membre du rÃ´le
                                            $missingGaps += [PSCustomObject]@{
                                                Level = "Database"
                                                GapType = "MissingDatabaseRoleMembership"
                                                DatabaseName = $refDb.DatabaseName
                                                PrincipalName = $refUser.UserName
                                                RoleName = $refDbRole.RoleName
                                                Description = "L'utilisateur '$($refUser.UserName)' devrait Ãªtre membre du rÃ´le de base de donnÃ©es '$($refDbRole.RoleName)'"
                                                Severity = "Moyenne"
                                                RecommendedAction = "Ajouter l'utilisateur au rÃ´le de base de donnÃ©es"
                                                ReferenceDetails = $isMemberInRef
                                            }
                                        }
                                    }
                                }
                            }
                            
                            # VÃ©rifier les permissions explicites
                            foreach ($refDbPermission in $refDb.DatabasePermissions) {
                                if ($refDbPermission.GranteeName -eq $refUser.UserName) {
                                    # VÃ©rifier si la permission existe dans les permissions actuelles
                                    $currentDbPermission = $currentDb.DatabasePermissions | 
                                                        Where-Object { $_.GranteeName -eq $refUser.UserName }
                                    
                                    if (-not $currentDbPermission) {
                                        # Aucune permission trouvÃ©e pour cet utilisateur
                                        $missingGaps += [PSCustomObject]@{
                                            Level = "Database"
                                            GapType = "MissingDatabasePermissions"
                                            DatabaseName = $refDb.DatabaseName
                                            PrincipalName = $refUser.UserName
                                            Description = "L'utilisateur '$($refUser.UserName)' n'a aucune permission explicite alors qu'il devrait en avoir"
                                            Severity = "Moyenne"
                                            RecommendedAction = "Accorder les permissions manquantes Ã  l'utilisateur"
                                            ReferenceDetails = $refDbPermission
                                        }
                                    }
                                    else {
                                        # VÃ©rifier chaque permission individuelle
                                        foreach ($refDbPerm in $refDbPermission.Permissions) {
                                            $matchingDbPerm = $currentDbPermission.Permissions | 
                                                            Where-Object { 
                                                                $_.PermissionName -eq $refDbPerm.PermissionName -and 
                                                                $_.PermissionState -eq $refDbPerm.PermissionState -and
                                                                $_.SecurableType -eq $refDbPerm.SecurableType -and
                                                                $_.SecurableName -eq $refDbPerm.SecurableName
                                                            }
                                            
                                            if (-not $matchingDbPerm) {
                                                # Permission manquante
                                                $missingGaps += [PSCustomObject]@{
                                                    Level = "Database"
                                                    GapType = "MissingDatabasePermission"
                                                    DatabaseName = $refDb.DatabaseName
                                                    PrincipalName = $refUser.UserName
                                                    PermissionName = $refDbPerm.PermissionName
                                                    PermissionState = $refDbPerm.PermissionState
                                                    SecurableType = $refDbPerm.SecurableType
                                                    SecurableName = $refDbPerm.SecurableName
                                                    Description = "L'utilisateur '$($refUser.UserName)' devrait avoir la permission '$($refDbPerm.PermissionState) $($refDbPerm.PermissionName)' sur $($refDbPerm.SecurableType) '$($refDbPerm.SecurableName)'"
                                                    Severity = "Moyenne"
                                                    RecommendedAction = "Accorder la permission manquante Ã  l'utilisateur"
                                                    ReferenceDetails = $refDbPerm
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                "Object" {
                    # Comparer les permissions au niveau objet
                    foreach ($refDb in $ReferenceModel.Databases) {
                        $currentDb = $CurrentPermissions.Databases | Where-Object { $_.DatabaseName -eq $refDb.DatabaseName }
                        
                        if (-not $currentDb) {
                            # La base de donnÃ©es est manquante (dÃ©jÃ  signalÃ© au niveau Database)
                            continue
                        }
                        
                        foreach ($refUser in $refDb.DatabaseUsers) {
                            # Ignorer les principaux systÃ¨me si demandÃ©
                            if ($ExcludeSystemPrincipals -and (Test-IsSystemPrincipal -PrincipalName $refUser.UserName)) {
                                continue
                            }
                            
                            # VÃ©rifier si l'utilisateur existe dans les permissions actuelles
                            $currentUser = $currentDb.DatabaseUsers | Where-Object { $_.UserName -eq $refUser.UserName }
                            
                            if (-not $currentUser) {
                                # L'utilisateur est manquant (dÃ©jÃ  signalÃ© au niveau Database)
                                continue
                            }
                            
                            # VÃ©rifier les permissions au niveau objet
                            foreach ($refObjPerm in $refDb.ObjectPermissions) {
                                if ($refObjPerm.GranteeName -eq $refUser.UserName) {
                                    # VÃ©rifier si l'utilisateur a des permissions d'objet dans les permissions actuelles
                                    $currentObjPerm = $currentDb.ObjectPermissions | 
                                                    Where-Object { $_.GranteeName -eq $refUser.UserName }
                                    
                                    if (-not $currentObjPerm) {
                                        # Aucune permission d'objet trouvÃ©e pour cet utilisateur
                                        $missingGaps += [PSCustomObject]@{
                                            Level = "Object"
                                            GapType = "MissingObjectPermissions"
                                            DatabaseName = $refDb.DatabaseName
                                            PrincipalName = $refUser.UserName
                                            Description = "L'utilisateur '$($refUser.UserName)' n'a aucune permission d'objet alors qu'il devrait en avoir"
                                            Severity = "Moyenne"
                                            RecommendedAction = "Accorder les permissions d'objet manquantes Ã  l'utilisateur"
                                            ReferenceDetails = $refObjPerm
                                        }
                                    }
                                    else {
                                        # VÃ©rifier chaque objet
                                        foreach ($refObj in $refObjPerm.ObjectPermissions) {
                                            # Ignorer les objets systÃ¨me si demandÃ©
                                            if ($ExcludeSystemObjects -and (Test-IsSystemObject -ObjectName $refObj.ObjectName -SchemaName $refObj.SchemaName)) {
                                                continue
                                            }
                                            
                                            # VÃ©rifier si l'objet existe dans les permissions actuelles
                                            $currentObj = $currentObjPerm.ObjectPermissions | 
                                                        Where-Object { 
                                                            $_.ObjectName -eq $refObj.ObjectName -and 
                                                            $_.SchemaName -eq $refObj.SchemaName -and
                                                            $_.ObjectType -eq $refObj.ObjectType
                                                        }
                                            
                                            if (-not $currentObj) {
                                                # L'objet est manquant ou l'utilisateur n'a pas de permissions sur cet objet
                                                $missingGaps += [PSCustomObject]@{
                                                    Level = "Object"
                                                    GapType = "MissingObjectPermission"
                                                    DatabaseName = $refDb.DatabaseName
                                                    PrincipalName = $refUser.UserName
                                                    ObjectName = $refObj.ObjectName
                                                    SchemaName = $refObj.SchemaName
                                                    ObjectType = $refObj.ObjectType
                                                    Description = "L'utilisateur '$($refUser.UserName)' devrait avoir des permissions sur l'objet '$($refObj.SchemaName).$($refObj.ObjectName)' ($($refObj.ObjectType))"
                                                    Severity = "Moyenne"
                                                    RecommendedAction = "Accorder les permissions manquantes sur l'objet"
                                                    ReferenceDetails = $refObj
                                                }
                                            }
                                            else {
                                                # VÃ©rifier chaque permission sur l'objet
                                                foreach ($refObjPermDetail in $refObj.Permissions) {
                                                    $matchingObjPerm = $currentObj.Permissions | 
                                                                    Where-Object { 
                                                                        $_.PermissionName -eq $refObjPermDetail.PermissionName -and 
                                                                        $_.PermissionState -eq $refObjPermDetail.PermissionState
                                                                    }
                                                    
                                                    if (-not $matchingObjPerm) {
                                                        # Permission manquante sur l'objet
                                                        $missingGaps += [PSCustomObject]@{
                                                            Level = "Object"
                                                            GapType = "MissingObjectPermissionDetail"
                                                            DatabaseName = $refDb.DatabaseName
                                                            PrincipalName = $refUser.UserName
                                                            ObjectName = $refObj.ObjectName
                                                            SchemaName = $refObj.SchemaName
                                                            ObjectType = $refObj.ObjectType
                                                            PermissionName = $refObjPermDetail.PermissionName
                                                            PermissionState = $refObjPermDetail.PermissionState
                                                            Description = "L'utilisateur '$($refUser.UserName)' devrait avoir la permission '$($refObjPermDetail.PermissionState) $($refObjPermDetail.PermissionName)' sur l'objet '$($refObj.SchemaName).$($refObj.ObjectName)' ($($refObj.ObjectType))"
                                                            Severity = "Moyenne"
                                                            RecommendedAction = "Accorder la permission manquante sur l'objet"
                                                            ReferenceDetails = $refObjPermDetail
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        catch {
            Write-Error "Erreur lors de la dÃ©tection des permissions manquantes: $_"
        }
    }
    
    end {
        # Retourner les Ã©carts dÃ©tectÃ©s
        return $missingGaps
    }
}
