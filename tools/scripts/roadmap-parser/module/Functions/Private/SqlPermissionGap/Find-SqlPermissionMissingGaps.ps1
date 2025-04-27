function Find-SqlPermissionMissingGaps {
    <#
    .SYNOPSIS
        Détecte les permissions manquantes par rapport à un modèle de référence.
    
    .DESCRIPTION
        Cette fonction compare les permissions actuelles d'une instance SQL Server avec un modèle de référence
        et identifie les permissions qui sont présentes dans le modèle mais absentes dans l'instance actuelle.
    
    .PARAMETER CurrentPermissions
        Les permissions actuelles de l'instance SQL Server.
    
    .PARAMETER ReferenceModel
        Le modèle de référence contenant les permissions attendues.
    
    .PARAMETER Level
        Le niveau de comparaison (Server, Database, Object).
    
    .PARAMETER ExcludeSystemObjects
        Indique si les objets système doivent être exclus de la comparaison.
    
    .PARAMETER ExcludeSystemPrincipals
        Indique si les principaux système doivent être exclus de la comparaison.
    
    .EXAMPLE
        Find-SqlPermissionMissingGaps -CurrentPermissions $currentPerms -ReferenceModel $refModel -Level "Server"
    
    .NOTES
        Cette fonction fait partie du module de détection d'écarts de permissions SQL Server.
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
        # Initialiser le tableau des écarts
        $missingGaps = @()
        
        # Fonction pour vérifier si un principal est un principal système
        function Test-IsSystemPrincipal {
            param (
                [string]$PrincipalName
            )
            
            return $PrincipalName -like "##*" -or 
                   $PrincipalName -eq "sa" -or 
                   $PrincipalName -like "NT SERVICE\*" -or 
                   $PrincipalName -like "NT AUTHORITY\*"
        }
        
        # Fonction pour vérifier si un objet est un objet système
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
                        # Ignorer les principaux système si demandé
                        if ($ExcludeSystemPrincipals -and (Test-IsSystemPrincipal -PrincipalName $refLogin.LoginName)) {
                            continue
                        }
                        
                        # Vérifier si le login existe dans les permissions actuelles
                        $currentLogin = $CurrentPermissions.Logins | Where-Object { $_.LoginName -eq $refLogin.LoginName }
                        
                        if (-not $currentLogin) {
                            # Le login est manquant
                            $missingGaps += [PSCustomObject]@{
                                Level = "Server"
                                GapType = "MissingLogin"
                                PrincipalName = $refLogin.LoginName
                                PrincipalType = $refLogin.LoginType
                                Description = "Le login '$($refLogin.LoginName)' est présent dans le modèle mais absent de l'instance actuelle"
                                Severity = "Élevée"
                                RecommendedAction = "Créer le login manquant avec les propriétés appropriées"
                                ReferenceDetails = $refLogin
                            }
                        }
                        else {
                            # Vérifier les propriétés du login
                            if ($refLogin.LoginType -ne $currentLogin.LoginType) {
                                $missingGaps += [PSCustomObject]@{
                                    Level = "Server"
                                    GapType = "LoginTypeMismatch"
                                    PrincipalName = $refLogin.LoginName
                                    PrincipalType = $refLogin.LoginType
                                    Description = "Le type du login '$($refLogin.LoginName)' est différent (Modèle: $($refLogin.LoginType), Actuel: $($currentLogin.LoginType))"
                                    Severity = "Moyenne"
                                    RecommendedAction = "Recréer le login avec le type correct"
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
                                    Description = "Le statut du login '$($refLogin.LoginName)' est différent (Modèle: $($refLogin.IsDisabled ? 'Désactivé' : 'Activé'), Actuel: $($currentLogin.IsDisabled ? 'Désactivé' : 'Activé'))"
                                    Severity = "Moyenne"
                                    RecommendedAction = "Modifier le statut du login pour correspondre au modèle"
                                    ReferenceDetails = $refLogin
                                    CurrentDetails = $currentLogin
                                }
                            }
                        }
                        
                        # Vérifier les rôles serveur
                        foreach ($refRole in $ReferenceModel.ServerRoles) {
                            # Vérifier si le login est membre du rôle dans le modèle
                            $isMemberInRef = $refRole.Members | Where-Object { $_.MemberName -eq $refLogin.LoginName }
                            
                            if ($isMemberInRef) {
                                # Vérifier si le rôle existe dans les permissions actuelles
                                $currentRole = $CurrentPermissions.ServerRoles | Where-Object { $_.RoleName -eq $refRole.RoleName }
                                
                                if (-not $currentRole) {
                                    # Le rôle est manquant
                                    $missingGaps += [PSCustomObject]@{
                                        Level = "Server"
                                        GapType = "MissingServerRole"
                                        PrincipalName = $refLogin.LoginName
                                        RoleName = $refRole.RoleName
                                        Description = "Le rôle serveur '$($refRole.RoleName)' est présent dans le modèle mais absent de l'instance actuelle"
                                        Severity = "Élevée"
                                        RecommendedAction = "Créer le rôle serveur manquant"
                                        ReferenceDetails = $refRole
                                    }
                                }
                                else {
                                    # Vérifier si le login est membre du rôle dans les permissions actuelles
                                    $isMemberInCurrent = $currentRole.Members | Where-Object { $_.MemberName -eq $refLogin.LoginName }
                                    
                                    if (-not $isMemberInCurrent) {
                                        # Le login n'est pas membre du rôle
                                        $missingGaps += [PSCustomObject]@{
                                            Level = "Server"
                                            GapType = "MissingServerRoleMembership"
                                            PrincipalName = $refLogin.LoginName
                                            RoleName = $refRole.RoleName
                                            Description = "Le login '$($refLogin.LoginName)' devrait être membre du rôle serveur '$($refRole.RoleName)'"
                                            Severity = "Moyenne"
                                            RecommendedAction = "Ajouter le login au rôle serveur"
                                            ReferenceDetails = $isMemberInRef
                                        }
                                    }
                                }
                            }
                        }
                        
                        # Vérifier les permissions explicites
                        foreach ($refPermission in $ReferenceModel.ServerPermissions) {
                            if ($refPermission.GranteeName -eq $refLogin.LoginName) {
                                # Vérifier si la permission existe dans les permissions actuelles
                                $currentPermission = $CurrentPermissions.ServerPermissions | 
                                                    Where-Object { $_.GranteeName -eq $refLogin.LoginName }
                                
                                if (-not $currentPermission) {
                                    # Aucune permission trouvée pour ce login
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
                                    # Vérifier chaque permission individuelle
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
                    # Comparer les utilisateurs de base de données
                    foreach ($refDb in $ReferenceModel.Databases) {
                        $currentDb = $CurrentPermissions.Databases | Where-Object { $_.DatabaseName -eq $refDb.DatabaseName }
                        
                        if (-not $currentDb) {
                            # La base de données est manquante
                            $missingGaps += [PSCustomObject]@{
                                Level = "Database"
                                GapType = "MissingDatabase"
                                DatabaseName = $refDb.DatabaseName
                                Description = "La base de données '$($refDb.DatabaseName)' est présente dans le modèle mais absente de l'instance actuelle"
                                Severity = "Élevée"
                                RecommendedAction = "Créer la base de données manquante"
                                ReferenceDetails = $refDb
                            }
                            continue
                        }
                        
                        # Comparer les utilisateurs
                        foreach ($refUser in $refDb.DatabaseUsers) {
                            # Ignorer les principaux système si demandé
                            if ($ExcludeSystemPrincipals -and (Test-IsSystemPrincipal -PrincipalName $refUser.UserName)) {
                                continue
                            }
                            
                            # Vérifier si l'utilisateur existe dans les permissions actuelles
                            $currentUser = $currentDb.DatabaseUsers | Where-Object { $_.UserName -eq $refUser.UserName }
                            
                            if (-not $currentUser) {
                                # L'utilisateur est manquant
                                $missingGaps += [PSCustomObject]@{
                                    Level = "Database"
                                    GapType = "MissingDatabaseUser"
                                    DatabaseName = $refDb.DatabaseName
                                    PrincipalName = $refUser.UserName
                                    Description = "L'utilisateur '$($refUser.UserName)' est présent dans le modèle pour la base de données '$($refDb.DatabaseName)' mais absent de l'instance actuelle"
                                    Severity = "Élevée"
                                    RecommendedAction = "Créer l'utilisateur manquant avec les propriétés appropriées"
                                    ReferenceDetails = $refUser
                                }
                            }
                            else {
                                # Vérifier les propriétés de l'utilisateur
                                if ($refUser.UserType -ne $currentUser.UserType) {
                                    $missingGaps += [PSCustomObject]@{
                                        Level = "Database"
                                        GapType = "DatabaseUserTypeMismatch"
                                        DatabaseName = $refDb.DatabaseName
                                        PrincipalName = $refUser.UserName
                                        Description = "Le type de l'utilisateur '$($refUser.UserName)' est différent (Modèle: $($refUser.UserType), Actuel: $($currentUser.UserType))"
                                        Severity = "Moyenne"
                                        RecommendedAction = "Recréer l'utilisateur avec le type correct"
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
                                        Description = "Le login associé à l'utilisateur '$($refUser.UserName)' est différent (Modèle: $($refUser.LoginName), Actuel: $($currentUser.LoginName))"
                                        Severity = "Moyenne"
                                        RecommendedAction = "Recréer l'utilisateur avec le login correct"
                                        ReferenceDetails = $refUser
                                        CurrentDetails = $currentUser
                                    }
                                }
                            }
                            
                            # Vérifier les rôles de base de données
                            foreach ($refDbRole in $refDb.DatabaseRoles) {
                                # Vérifier si l'utilisateur est membre du rôle dans le modèle
                                $isMemberInRef = $refDbRole.Members | Where-Object { $_.MemberName -eq $refUser.UserName }
                                
                                if ($isMemberInRef) {
                                    # Vérifier si le rôle existe dans les permissions actuelles
                                    $currentDbRole = $currentDb.DatabaseRoles | Where-Object { $_.RoleName -eq $refDbRole.RoleName }
                                    
                                    if (-not $currentDbRole) {
                                        # Le rôle est manquant
                                        $missingGaps += [PSCustomObject]@{
                                            Level = "Database"
                                            GapType = "MissingDatabaseRole"
                                            DatabaseName = $refDb.DatabaseName
                                            RoleName = $refDbRole.RoleName
                                            Description = "Le rôle de base de données '$($refDbRole.RoleName)' est présent dans le modèle mais absent de l'instance actuelle"
                                            Severity = "Élevée"
                                            RecommendedAction = "Créer le rôle de base de données manquant"
                                            ReferenceDetails = $refDbRole
                                        }
                                    }
                                    else {
                                        # Vérifier si l'utilisateur est membre du rôle dans les permissions actuelles
                                        $isMemberInCurrent = $currentDbRole.Members | Where-Object { $_.MemberName -eq $refUser.UserName }
                                        
                                        if (-not $isMemberInCurrent) {
                                            # L'utilisateur n'est pas membre du rôle
                                            $missingGaps += [PSCustomObject]@{
                                                Level = "Database"
                                                GapType = "MissingDatabaseRoleMembership"
                                                DatabaseName = $refDb.DatabaseName
                                                PrincipalName = $refUser.UserName
                                                RoleName = $refDbRole.RoleName
                                                Description = "L'utilisateur '$($refUser.UserName)' devrait être membre du rôle de base de données '$($refDbRole.RoleName)'"
                                                Severity = "Moyenne"
                                                RecommendedAction = "Ajouter l'utilisateur au rôle de base de données"
                                                ReferenceDetails = $isMemberInRef
                                            }
                                        }
                                    }
                                }
                            }
                            
                            # Vérifier les permissions explicites
                            foreach ($refDbPermission in $refDb.DatabasePermissions) {
                                if ($refDbPermission.GranteeName -eq $refUser.UserName) {
                                    # Vérifier si la permission existe dans les permissions actuelles
                                    $currentDbPermission = $currentDb.DatabasePermissions | 
                                                        Where-Object { $_.GranteeName -eq $refUser.UserName }
                                    
                                    if (-not $currentDbPermission) {
                                        # Aucune permission trouvée pour cet utilisateur
                                        $missingGaps += [PSCustomObject]@{
                                            Level = "Database"
                                            GapType = "MissingDatabasePermissions"
                                            DatabaseName = $refDb.DatabaseName
                                            PrincipalName = $refUser.UserName
                                            Description = "L'utilisateur '$($refUser.UserName)' n'a aucune permission explicite alors qu'il devrait en avoir"
                                            Severity = "Moyenne"
                                            RecommendedAction = "Accorder les permissions manquantes à l'utilisateur"
                                            ReferenceDetails = $refDbPermission
                                        }
                                    }
                                    else {
                                        # Vérifier chaque permission individuelle
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
                                                    RecommendedAction = "Accorder la permission manquante à l'utilisateur"
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
                            # La base de données est manquante (déjà signalé au niveau Database)
                            continue
                        }
                        
                        foreach ($refUser in $refDb.DatabaseUsers) {
                            # Ignorer les principaux système si demandé
                            if ($ExcludeSystemPrincipals -and (Test-IsSystemPrincipal -PrincipalName $refUser.UserName)) {
                                continue
                            }
                            
                            # Vérifier si l'utilisateur existe dans les permissions actuelles
                            $currentUser = $currentDb.DatabaseUsers | Where-Object { $_.UserName -eq $refUser.UserName }
                            
                            if (-not $currentUser) {
                                # L'utilisateur est manquant (déjà signalé au niveau Database)
                                continue
                            }
                            
                            # Vérifier les permissions au niveau objet
                            foreach ($refObjPerm in $refDb.ObjectPermissions) {
                                if ($refObjPerm.GranteeName -eq $refUser.UserName) {
                                    # Vérifier si l'utilisateur a des permissions d'objet dans les permissions actuelles
                                    $currentObjPerm = $currentDb.ObjectPermissions | 
                                                    Where-Object { $_.GranteeName -eq $refUser.UserName }
                                    
                                    if (-not $currentObjPerm) {
                                        # Aucune permission d'objet trouvée pour cet utilisateur
                                        $missingGaps += [PSCustomObject]@{
                                            Level = "Object"
                                            GapType = "MissingObjectPermissions"
                                            DatabaseName = $refDb.DatabaseName
                                            PrincipalName = $refUser.UserName
                                            Description = "L'utilisateur '$($refUser.UserName)' n'a aucune permission d'objet alors qu'il devrait en avoir"
                                            Severity = "Moyenne"
                                            RecommendedAction = "Accorder les permissions d'objet manquantes à l'utilisateur"
                                            ReferenceDetails = $refObjPerm
                                        }
                                    }
                                    else {
                                        # Vérifier chaque objet
                                        foreach ($refObj in $refObjPerm.ObjectPermissions) {
                                            # Ignorer les objets système si demandé
                                            if ($ExcludeSystemObjects -and (Test-IsSystemObject -ObjectName $refObj.ObjectName -SchemaName $refObj.SchemaName)) {
                                                continue
                                            }
                                            
                                            # Vérifier si l'objet existe dans les permissions actuelles
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
                                                # Vérifier chaque permission sur l'objet
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
            Write-Error "Erreur lors de la détection des permissions manquantes: $_"
        }
    }
    
    end {
        # Retourner les écarts détectés
        return $missingGaps
    }
}
