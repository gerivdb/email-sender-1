<#
.SYNOPSIS
    Outils d'analyse des listes de contrôle d'accès (ACL) pour les fichiers, dossiers, registre et autres ressources.

.DESCRIPTION
    Ce module fournit des fonctions pour analyser, comparer et visualiser les listes de contrôle d'accès (ACL)
    sur différentes ressources du système, y compris les fichiers, dossiers, clés de registre, partages réseau
    et bases de données SQL Server.

.NOTES
    Nom du fichier : ACLAnalyzer.ps1
    Auteur        : Augment Code
    Version       : 1.0
    Prérequis     : PowerShell 5.1 ou supérieur
#>

#Requires -Version 5.1

# Fonction pour analyser les permissions NTFS d'un fichier ou dossier
function Get-NTFSPermission {
    <#
    .SYNOPSIS
        Analyse les permissions NTFS d'un fichier ou dossier.

    .DESCRIPTION
        Cette fonction analyse en détail les permissions NTFS d'un fichier ou dossier,
        y compris les droits spécifiques, les héritages, et les identités associées.

    .PARAMETER Path
        Le chemin du fichier ou dossier à analyser.

    .PARAMETER Recurse
        Indique si l'analyse doit être récursive pour les dossiers.

    .PARAMETER IncludeInherited
        Indique si les permissions héritées doivent être incluses dans l'analyse.

    .EXAMPLE
        Get-NTFSPermission -Path "C:\Data" -Recurse $false -IncludeInherited $true

    .OUTPUTS
        [PSCustomObject] avec des informations détaillées sur les permissions NTFS.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [bool]$Recurse = $false,

        [Parameter(Mandatory = $false)]
        [bool]$IncludeInherited = $true
    )

    begin {
        # Vérifier si le chemin existe
        if (-not (Test-Path -Path $Path)) {
            Write-Error "Le chemin '$Path' n'existe pas."
            return
        }

        # Fonction pour convertir les droits d'accès en chaîne lisible
        function ConvertTo-ReadableRights {
            param (
                [System.Security.AccessControl.FileSystemRights]$Rights
            )

            $readableRights = @()

            # Droits de base
            $basicRights = @{
                "FullControl" = [System.Security.AccessControl.FileSystemRights]::FullControl
                "Modify" = [System.Security.AccessControl.FileSystemRights]::Modify
                "ReadAndExecute" = [System.Security.AccessControl.FileSystemRights]::ReadAndExecute
                "Read" = [System.Security.AccessControl.FileSystemRights]::Read
                "Write" = [System.Security.AccessControl.FileSystemRights]::Write
            }

            # Droits spécifiques
            $specificRights = @{
                "ListDirectory" = [System.Security.AccessControl.FileSystemRights]::ListDirectory
                "ReadData" = [System.Security.AccessControl.FileSystemRights]::ReadData
                "WriteData" = [System.Security.AccessControl.FileSystemRights]::WriteData
                "CreateFiles" = [System.Security.AccessControl.FileSystemRights]::CreateFiles
                "CreateDirectories" = [System.Security.AccessControl.FileSystemRights]::CreateDirectories
                "AppendData" = [System.Security.AccessControl.FileSystemRights]::AppendData
                "ReadExtendedAttributes" = [System.Security.AccessControl.FileSystemRights]::ReadExtendedAttributes
                "WriteExtendedAttributes" = [System.Security.AccessControl.FileSystemRights]::WriteExtendedAttributes
                "ExecuteFile" = [System.Security.AccessControl.FileSystemRights]::ExecuteFile
                "DeleteSubdirectoriesAndFiles" = [System.Security.AccessControl.FileSystemRights]::DeleteSubdirectoriesAndFiles
                "ReadAttributes" = [System.Security.AccessControl.FileSystemRights]::ReadAttributes
                "WriteAttributes" = [System.Security.AccessControl.FileSystemRights]::WriteAttributes
                "Delete" = [System.Security.AccessControl.FileSystemRights]::Delete
                "ReadPermissions" = [System.Security.AccessControl.FileSystemRights]::ReadPermissions
                "ChangePermissions" = [System.Security.AccessControl.FileSystemRights]::ChangePermissions
                "TakeOwnership" = [System.Security.AccessControl.FileSystemRights]::TakeOwnership
                "Synchronize" = [System.Security.AccessControl.FileSystemRights]::Synchronize
            }

            # Vérifier d'abord les droits de base
            foreach ($right in $basicRights.Keys) {
                if (($Rights -band $basicRights[$right]) -eq $basicRights[$right]) {
                    $readableRights += $right
                    return $readableRights  # Si un droit de base est trouvé, on le retourne directement
                }
            }

            # Si aucun droit de base n'est trouvé, vérifier les droits spécifiques
            foreach ($right in $specificRights.Keys) {
                if (($Rights -band $specificRights[$right]) -eq $specificRights[$right]) {
                    $readableRights += $right
                }
            }

            return $readableRights
        }

        # Fonction pour convertir les flags d'héritage en chaîne lisible
        function ConvertTo-ReadableInheritanceFlags {
            param (
                [System.Security.AccessControl.InheritanceFlags]$InheritanceFlags,
                [System.Security.AccessControl.PropagationFlags]$PropagationFlags
            )

            $inheritance = @()

            # Flags d'héritage
            if ($InheritanceFlags -band [System.Security.AccessControl.InheritanceFlags]::ContainerInherit) {
                $inheritance += "Dossiers"
            }

            if ($InheritanceFlags -band [System.Security.AccessControl.InheritanceFlags]::ObjectInherit) {
                $inheritance += "Fichiers"
            }

            # Flags de propagation
            if ($PropagationFlags -band [System.Security.AccessControl.PropagationFlags]::NoPropagateInherit) {
                $inheritance += "Ne pas propager"
            }

            if ($PropagationFlags -band [System.Security.AccessControl.PropagationFlags]::InheritOnly) {
                $inheritance += "Héritage uniquement"
            }

            if ($inheritance.Count -eq 0) {
                return "Aucun"
            } else {
                return $inheritance -join ", "
            }
        }

        # Fonction pour obtenir le type d'objet (fichier ou dossier)
        function Get-ObjectType {
            param (
                [string]$Path
            )

            $item = Get-Item -Path $Path -Force
            if ($item -is [System.IO.DirectoryInfo]) {
                return "Dossier"
            } else {
                return "Fichier"
            }
        }
    }

    process {
        try {
            $results = @()

            # Obtenir les ACL de l'objet
            $acl = Get-Acl -Path $Path

            # Obtenir le type d'objet
            $objectType = Get-ObjectType -Path $Path

            # Analyser chaque règle d'accès
            foreach ($accessRule in $acl.Access) {
                # Ignorer les permissions héritées si demandé
                if (-not $IncludeInherited -and $accessRule.IsInherited) {
                    continue
                }

                # Convertir les droits en format lisible
                $readableRights = ConvertTo-ReadableRights -Rights $accessRule.FileSystemRights

                # Convertir les flags d'héritage en format lisible
                $readableInheritance = ConvertTo-ReadableInheritanceFlags -InheritanceFlags $accessRule.InheritanceFlags -PropagationFlags $accessRule.PropagationFlags

                # Créer un objet personnalisé pour cette règle d'accès
                $permissionInfo = [PSCustomObject]@{
                    Path = $Path
                    ObjectType = $objectType
                    IdentityReference = $accessRule.IdentityReference.Value
                    AccessControlType = $accessRule.AccessControlType.ToString()
                    Rights = $readableRights
                    RightsRaw = $accessRule.FileSystemRights.ToString()
                    Inheritance = $readableInheritance
                    IsInherited = $accessRule.IsInherited
                    InheritanceSource = if ($accessRule.IsInherited) { (Split-Path -Parent $Path) } else { "Directement assigné" }
                }

                $results += $permissionInfo
            }

            # Ajouter des informations sur le propriétaire
            $ownerInfo = [PSCustomObject]@{
                Path = $Path
                ObjectType = $objectType
                IdentityReference = $acl.Owner
                AccessControlType = "Propriétaire"
                Rights = "Contrôle total (implicite)"
                RightsRaw = "FullControl"
                Inheritance = "N/A"
                IsInherited = $false
                InheritanceSource = "Propriétaire du système de fichiers"
            }

            $results += $ownerInfo

            # Si récursif est demandé et que c'est un dossier, analyser les sous-dossiers et fichiers
            # Mais limiter la profondeur pour éviter les boucles infinies
            if ($Recurse -and $objectType -eq "Dossier") {
                # Limiter le nombre d'éléments à traiter
                $childItems = Get-ChildItem -Path $Path -Force | Select-Object -First 10

                foreach ($childItem in $childItems) {
                    # Éviter les liens symboliques qui pourraient créer des boucles
                    if (($childItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne [System.IO.FileAttributes]::ReparsePoint) {
                        $childResults = Get-NTFSPermission -Path $childItem.FullName -Recurse $false -IncludeInherited $IncludeInherited
                        $results += $childResults
                    }
                }
            }

            return $results
        }
        catch {
            Write-Error "Erreur lors de l'analyse des permissions NTFS pour '$Path': $($_.Exception.Message)"
        }
    }
}

# Fonction pour détecter les anomalies dans les permissions NTFS
function Find-NTFSPermissionAnomaly {
    <#
    .SYNOPSIS
        Détecte les anomalies dans les permissions NTFS.

    .DESCRIPTION
        Cette fonction analyse les permissions NTFS et détecte les anomalies potentielles
        comme les permissions excessives, les conflits, ou les configurations dangereuses.

    .PARAMETER Path
        Le chemin du fichier ou dossier à analyser.

    .PARAMETER Recurse
        Indique si l'analyse doit être récursive pour les dossiers.

    .EXAMPLE
        Find-NTFSPermissionAnomaly -Path "C:\Data" -Recurse $true

    .OUTPUTS
        [PSCustomObject] avec des informations sur les anomalies détectées.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [bool]$Recurse = $false
    )

    begin {
        # Vérifier si le chemin existe
        if (-not (Test-Path -Path $Path)) {
            Write-Error "Le chemin '$Path' n'existe pas."
            return
        }

        # Définir les groupes à risque élevé
        $highRiskGroups = @(
            "Everyone",
            "Tout le monde",
            "Authenticated Users",
            "Utilisateurs authentifiés",
            "Users",
            "Utilisateurs",
            "ANONYMOUS LOGON",
            "Connexion anonyme"
        )

        # Définir les droits à risque élevé
        $highRiskRights = @(
            "FullControl",
            "Modify",
            "WriteData",
            "CreateFiles",
            "CreateDirectories",
            "WriteExtendedAttributes",
            "WriteAttributes",
            "Delete",
            "DeleteSubdirectoriesAndFiles",
            "ChangePermissions",
            "TakeOwnership"
        )
    }

    process {
        try {
            $anomalies = @()

            # Obtenir les permissions NTFS (limiter la récursivité pour éviter les boucles infinies)
            if ($Recurse) {
                # Limiter la profondeur de récursion
                $permissions = Get-NTFSPermission -Path $Path -Recurse $false -IncludeInherited $true

                # Traiter manuellement le premier niveau de récursion
                $childItems = Get-ChildItem -Path $Path -Force | Select-Object -First 10
                foreach ($childItem in $childItems) {
                    if (($childItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne [System.IO.FileAttributes]::ReparsePoint) {
                        $childPermissions = Get-NTFSPermission -Path $childItem.FullName -Recurse $false -IncludeInherited $true
                        $permissions += $childPermissions
                    }
                }
            } else {
                $permissions = Get-NTFSPermission -Path $Path -Recurse $false -IncludeInherited $true
            }

            # Regrouper les permissions par chemin
            $permissionsByPath = $permissions | Group-Object -Property Path

            foreach ($pathGroup in $permissionsByPath) {
                $currentPath = $pathGroup.Name
                $currentPermissions = $pathGroup.Group

                # 1. Détecter les permissions à risque élevé pour des groupes à risque élevé
                foreach ($permission in $currentPermissions) {
                    if ($highRiskGroups -contains $permission.IdentityReference -and
                        $permission.AccessControlType -eq "Allow") {

                        $riskyRights = $permission.Rights | Where-Object { $highRiskRights -contains $_ }

                        if ($riskyRights) {
                            $anomalies += [PSCustomObject]@{
                                Path = $currentPath
                                AnomalyType = "HighRiskPermission"
                                Severity = "Élevée"
                                Description = "Permissions à risque élevé ($($riskyRights -join ', ')) accordées à un groupe à risque élevé ($($permission.IdentityReference))"
                                IdentityReference = $permission.IdentityReference
                                Rights = $permission.Rights
                                Recommendation = "Restreindre les permissions pour ce groupe ou utiliser un groupe plus spécifique"
                            }
                        }
                    }
                }

                # 2. Détecter les conflits de permissions (Allow vs Deny)
                $allowRules = $currentPermissions | Where-Object { $_.AccessControlType -eq "Allow" }
                $denyRules = $currentPermissions | Where-Object { $_.AccessControlType -eq "Deny" }

                foreach ($allowRule in $allowRules) {
                    foreach ($denyRule in $denyRules) {
                        if ($allowRule.IdentityReference -eq $denyRule.IdentityReference) {
                            $commonRights = Compare-Object -ReferenceObject $allowRule.Rights -DifferenceObject $denyRule.Rights -IncludeEqual -ExcludeDifferent

                            if ($commonRights) {
                                $anomalies += [PSCustomObject]@{
                                    Path = $currentPath
                                    AnomalyType = "PermissionConflict"
                                    Severity = "Moyenne"
                                    Description = "Conflit de permissions pour $($allowRule.IdentityReference): les mêmes droits ($($commonRights.InputObject -join ', ')) sont à la fois autorisés et refusés"
                                    IdentityReference = $allowRule.IdentityReference
                                    Rights = $commonRights.InputObject
                                    Recommendation = "Résoudre le conflit en supprimant l'une des règles contradictoires"
                                }
                            }
                        }
                    }
                }

                # 3. Détecter les permissions redondantes
                $identityGroups = $currentPermissions | Group-Object -Property IdentityReference

                foreach ($identityGroup in $identityGroups) {
                    if ($identityGroup.Count -gt 1) {
                        $sameTypeRules = $identityGroup.Group | Group-Object -Property AccessControlType

                        foreach ($typeGroup in $sameTypeRules) {
                            if ($typeGroup.Count -gt 1) {
                                $anomalies += [PSCustomObject]@{
                                    Path = $currentPath
                                    AnomalyType = "RedundantPermission"
                                    Severity = "Faible"
                                    Description = "Permissions redondantes pour $($identityGroup.Name) ($($typeGroup.Name)): $($typeGroup.Count) règles"
                                    IdentityReference = $identityGroup.Name
                                    Rights = ($typeGroup.Group | ForEach-Object { $_.Rights }) -join ', '
                                    Recommendation = "Consolider les règles redondantes en une seule règle"
                                }
                            }
                        }
                    }
                }

                # 4. Détecter les héritages interrompus
                $isFolder = (Get-Item -Path $currentPath -Force) -is [System.IO.DirectoryInfo]

                if ($isFolder) {
                    $parentPath = Split-Path -Parent $currentPath

                    if ($parentPath) {
                        $parentPermissions = Get-NTFSPermission -Path $parentPath -Recurse $false -IncludeInherited $false
                        $currentNonInheritedPermissions = $currentPermissions | Where-Object { -not $_.IsInherited }

                        if ($parentPermissions -and $currentNonInheritedPermissions) {
                            $anomalies += [PSCustomObject]@{
                                Path = $currentPath
                                AnomalyType = "InheritanceBreak"
                                Severity = "Information"
                                Description = "L'héritage des permissions est interrompu pour ce dossier"
                                IdentityReference = "N/A"
                                Rights = "N/A"
                                Recommendation = "Vérifier si l'interruption de l'héritage est intentionnelle"
                            }
                        }
                    }
                }
            }

            return $anomalies
        }
        catch {
            Write-Error "Erreur lors de la détection des anomalies de permissions NTFS pour '$Path': $($_.Exception.Message)"
        }
    }
}

# Fonction pour analyser l'héritage des permissions NTFS
function Get-NTFSPermissionInheritance {
    <#
    .SYNOPSIS
        Analyse l'héritage des permissions NTFS pour un fichier ou dossier.

    .DESCRIPTION
        Cette fonction analyse en détail l'héritage des permissions NTFS d'un fichier ou dossier,
        y compris les sources d'héritage, les interruptions d'héritage, et les permissions explicites.

    .PARAMETER Path
        Le chemin du fichier ou dossier à analyser.

    .PARAMETER Recurse
        Indique si l'analyse doit être récursive pour les dossiers.

    .EXAMPLE
        Get-NTFSPermissionInheritance -Path "C:\Data" -Recurse $false

    .OUTPUTS
        [PSCustomObject] avec des informations détaillées sur l'héritage des permissions NTFS.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [bool]$Recurse = $false,

        [Parameter(Mandatory = $false, DontShow)]
        [int]$MaxDepth = 3,

        [Parameter(Mandatory = $false, DontShow)]
        [int]$CurrentDepth = 0
    )

    begin {
        # Vérifier si le chemin existe
        if (-not (Test-Path -Path $Path)) {
            Write-Error "Le chemin '$Path' n'existe pas."
            return
        }

        # Fonction pour obtenir le type d'objet (fichier ou dossier)
        function Get-ObjectType {
            param (
                [string]$Path
            )

            $item = Get-Item -Path $Path -Force
            if ($item -is [System.IO.DirectoryInfo]) {
                return "Dossier"
            } else {
                return "Fichier"
            }
        }

        # Fonction pour obtenir le chemin parent
        function Get-ParentPath {
            param (
                [string]$Path
            )

            return Split-Path -Parent $Path
        }

        # Fonction pour vérifier si l'héritage est activé
        function Test-InheritanceEnabled {
            param (
                [System.Security.AccessControl.FileSystemSecurity]$Acl
            )

            return -not $Acl.AreAccessRulesProtected
        }
    }

    process {
        try {
            # Vérifier si on a atteint la profondeur maximale
            if ($CurrentDepth -ge $MaxDepth) {
                Write-Verbose "Profondeur maximale atteinte ($MaxDepth) pour le chemin '$Path'"
                return @()
            }

            $results = @()

            # Obtenir les ACL de l'objet
            $acl = Get-Acl -Path $Path

            # Obtenir le type d'objet
            $objectType = Get-ObjectType -Path $Path

            # Vérifier si l'héritage est activé
            $inheritanceEnabled = Test-InheritanceEnabled -Acl $acl

            # Obtenir le chemin parent
            $parentPath = Get-ParentPath -Path $Path

            # Créer un objet pour les informations d'héritage
            $inheritanceInfo = [PSCustomObject]@{
                Path = $Path
                ObjectType = $objectType
                InheritanceEnabled = $inheritanceEnabled
                ParentPath = $parentPath
                ExplicitPermissions = @()
                InheritedPermissions = @()
                InheritanceBreakPoints = @()
            }

            # Analyser chaque règle d'accès
            foreach ($accessRule in $acl.Access) {
                $permissionInfo = [PSCustomObject]@{
                    IdentityReference = $accessRule.IdentityReference.Value
                    AccessControlType = $accessRule.AccessControlType.ToString()
                    FileSystemRights = $accessRule.FileSystemRights.ToString()
                    IsInherited = $accessRule.IsInherited
                    InheritanceFlags = $accessRule.InheritanceFlags.ToString()
                    PropagationFlags = $accessRule.PropagationFlags.ToString()
                }

                if ($accessRule.IsInherited) {
                    $inheritanceInfo.InheritedPermissions += $permissionInfo
                } else {
                    $inheritanceInfo.ExplicitPermissions += $permissionInfo
                }
            }

            # Vérifier s'il y a une interruption d'héritage
            if (-not $inheritanceEnabled) {
                $inheritanceInfo.InheritanceBreakPoints += $Path
            }

            # Ajouter les informations d'héritage aux résultats
            $results += $inheritanceInfo

            # Si récursif est demandé et que c'est un dossier, analyser les sous-dossiers et fichiers
            # Mais seulement si on n'a pas atteint la profondeur maximale
            if ($Recurse -and $objectType -eq "Dossier" -and $CurrentDepth -lt $MaxDepth) {
                # Limiter le nombre d'éléments à traiter pour éviter les boucles infinies
                $childItems = Get-ChildItem -Path $Path -Force | Select-Object -First 10

                foreach ($childItem in $childItems) {
                    # Éviter les liens symboliques qui pourraient créer des boucles
                    if (($childItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne [System.IO.FileAttributes]::ReparsePoint) {
                        $childResults = Get-NTFSPermissionInheritance -Path $childItem.FullName -Recurse $false -MaxDepth $MaxDepth -CurrentDepth ($CurrentDepth + 1)
                        $results += $childResults
                    }
                }
            }

            return $results
        }
        catch {
            Write-Error "Erreur lors de l'analyse de l'héritage des permissions NTFS pour '$Path': $($_.Exception.Message)"
        }
    }
}

# Fonction pour analyser les propriétaires et groupes des fichiers et dossiers
function Get-NTFSOwnershipInfo {
    <#
    .SYNOPSIS
        Analyse les propriétaires et groupes principaux des fichiers et dossiers.

    .DESCRIPTION
        Cette fonction analyse en détail les propriétaires et groupes principaux des fichiers et dossiers,
        y compris les SID, les domaines, et les types de comptes.

    .PARAMETER Path
        Le chemin du fichier ou dossier à analyser.

    .PARAMETER Recurse
        Indique si l'analyse doit être récursive pour les dossiers.

    .EXAMPLE
        Get-NTFSOwnershipInfo -Path "C:\Data" -Recurse $false

    .OUTPUTS
        [PSCustomObject] avec des informations détaillées sur les propriétaires et groupes.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [bool]$Recurse = $false,

        [Parameter(Mandatory = $false, DontShow)]
        [int]$MaxDepth = 3,

        [Parameter(Mandatory = $false, DontShow)]
        [int]$CurrentDepth = 0
    )

    begin {
        # Vérifier si le chemin existe
        if (-not (Test-Path -Path $Path)) {
            Write-Error "Le chemin '$Path' n'existe pas."
            return
        }

        # Fonction pour obtenir le type d'objet (fichier ou dossier)
        function Get-ObjectType {
            param (
                [string]$Path
            )

            $item = Get-Item -Path $Path -Force
            if ($item -is [System.IO.DirectoryInfo]) {
                return "Dossier"
            } else {
                return "Fichier"
            }
        }

        # Fonction pour obtenir les informations détaillées sur un compte
        function Get-AccountInfo {
            param (
                [string]$AccountName
            )

            try {
                if ($AccountName -match '^S-\d-\d+-(\d+-){1,14}\d+$') {
                    # C'est un SID, essayer de le traduire
                    $sid = New-Object System.Security.Principal.SecurityIdentifier($AccountName)
                    try {
                        $account = $sid.Translate([System.Security.Principal.NTAccount])
                        $accountName = $account.Value
                    } catch {
                        $accountName = $AccountName  # Garder le SID si la traduction échoue
                    }
                }

                if ($AccountName -match '\\') {
                    $parts = $AccountName -split '\\'
                    $domain = $parts[0]
                    $username = $parts[1]
                } else {
                    $domain = [Environment]::MachineName
                    $username = $AccountName
                }

                # Déterminer le type de compte
                $accountType = "Inconnu"

                if ($username -eq "SYSTEM" -or $username -eq "Système") {
                    $accountType = "Système"
                } elseif ($username -eq "Administrators" -or $username -eq "Administrateurs") {
                    $accountType = "Groupe d'administrateurs"
                } elseif ($username -eq "Administrator" -or $username -eq "Administrateur") {
                    $accountType = "Administrateur local"
                } elseif ($username -eq "Users" -or $username -eq "Utilisateurs") {
                    $accountType = "Groupe d'utilisateurs"
                } elseif ($username -eq "Everyone" -or $username -eq "Tout le monde") {
                    $accountType = "Groupe spécial"
                } elseif ($domain -eq "NT AUTHORITY" -or $domain -eq "AUTORITE NT") {
                    $accountType = "Compte système"
                } elseif ($domain -eq "BUILTIN") {
                    $accountType = "Groupe intégré"
                } elseif ($domain -eq [Environment]::MachineName) {
                    $accountType = "Compte local"
                } else {
                    $accountType = "Compte de domaine"
                }

                return [PSCustomObject]@{
                    FullName = $AccountName
                    Domain = $domain
                    Username = $username
                    AccountType = $accountType
                }
            } catch {
                return [PSCustomObject]@{
                    FullName = $AccountName
                    Domain = "Inconnu"
                    Username = $AccountName
                    AccountType = "Inconnu"
                }
            }
        }
    }

    process {
        try {
            # Vérifier si on a atteint la profondeur maximale
            if ($CurrentDepth -ge $MaxDepth) {
                Write-Verbose "Profondeur maximale atteinte ($MaxDepth) pour le chemin '$Path'"
                return @()
            }

            $results = @()

            # Obtenir les ACL de l'objet
            $acl = Get-Acl -Path $Path

            # Obtenir le type d'objet
            $objectType = Get-ObjectType -Path $Path

            # Obtenir les informations sur le propriétaire
            $ownerInfo = Get-AccountInfo -AccountName $acl.Owner

            # Obtenir les informations sur le groupe principal (si disponible)
            $groupInfo = $null
            if ($acl.Group) {
                $groupInfo = Get-AccountInfo -AccountName $acl.Group
            }

            # Créer un objet pour les informations de propriété
            $ownershipInfo = [PSCustomObject]@{
                Path = $Path
                ObjectType = $objectType
                Owner = $ownerInfo
                Group = $groupInfo
                CanChangeOwner = $false
                RecommendedOwner = $null
                SecurityRisk = $false
                RiskLevel = "Faible"
                Recommendations = @()
            }

            # Vérifier si l'utilisateur actuel peut changer le propriétaire
            try {
                $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
                $currentUserInfo = Get-AccountInfo -AccountName $currentUser

                # Vérifier si l'utilisateur actuel est le propriétaire ou un administrateur
                $isOwner = $ownerInfo.FullName -eq $currentUserInfo.FullName
                $isAdmin = [System.Security.Principal.WindowsIdentity]::GetCurrent().Groups |
                           Where-Object { $_.Value -match "S-1-5-32-544" } |
                           Select-Object -First 1

                $ownershipInfo.CanChangeOwner = $isOwner -or ($isAdmin -ne $null)
            } catch {
                $ownershipInfo.CanChangeOwner = $false
            }

            # Évaluer les risques de sécurité liés au propriétaire
            if ($ownerInfo.AccountType -eq "Groupe spécial" -or
                $ownerInfo.Username -eq "Everyone" -or
                $ownerInfo.Username -eq "Tout le monde" -or
                $ownerInfo.Username -eq "Users" -or
                $ownerInfo.Username -eq "Utilisateurs") {

                $ownershipInfo.SecurityRisk = $true
                $ownershipInfo.RiskLevel = "Élevé"
                $ownershipInfo.Recommendations += "Changer le propriétaire pour un compte administrateur ou système"
                $ownershipInfo.RecommendedOwner = "Administrators"
            } elseif ($ownerInfo.AccountType -eq "Compte local" -and
                      $ownerInfo.Username -ne "Administrator" -and
                      $ownerInfo.Username -ne "Administrateur") {

                $ownershipInfo.SecurityRisk = $true
                $ownershipInfo.RiskLevel = "Moyen"
                $ownershipInfo.Recommendations += "Vérifier si ce compte local devrait être propriétaire de cette ressource"
                $ownershipInfo.RecommendedOwner = "Administrators"
            }

            # Ajouter les informations de propriété aux résultats
            $results += $ownershipInfo

            # Si récursif est demandé et que c'est un dossier, analyser les sous-dossiers et fichiers
            # Mais seulement si on n'a pas atteint la profondeur maximale
            if ($Recurse -and $objectType -eq "Dossier" -and $CurrentDepth -lt $MaxDepth) {
                # Limiter le nombre d'éléments à traiter pour éviter les boucles infinies
                $childItems = Get-ChildItem -Path $Path -Force | Select-Object -First 10

                foreach ($childItem in $childItems) {
                    # Éviter les liens symboliques qui pourraient créer des boucles
                    if (($childItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne [System.IO.FileAttributes]::ReparsePoint) {
                        $childResults = Get-NTFSOwnershipInfo -Path $childItem.FullName -Recurse $false -MaxDepth $MaxDepth -CurrentDepth ($CurrentDepth + 1)
                        $results += $childResults
                    }
                }
            }

            return $results
        }
        catch {
            Write-Error "Erreur lors de l'analyse des propriétaires et groupes pour '$Path': $($_.Exception.Message)"
        }
    }
}

# Fonction pour générer un rapport de permissions NTFS
function New-NTFSPermissionReport {
    <#
    .SYNOPSIS
        Génère un rapport détaillé des permissions NTFS pour un fichier ou dossier.

    .DESCRIPTION
        Cette fonction génère un rapport détaillé des permissions NTFS pour un fichier ou dossier,
        y compris les permissions, les héritages, les propriétaires, et les anomalies détectées.

    .PARAMETER Path
        Le chemin du fichier ou dossier à analyser.

    .PARAMETER Recurse
        Indique si l'analyse doit être récursive pour les dossiers.

    .PARAMETER OutputFormat
        Le format de sortie du rapport (Text, CSV, HTML, JSON).

    .PARAMETER OutputPath
        Le chemin où enregistrer le rapport. Si non spécifié, le rapport est affiché à l'écran.

    .EXAMPLE
        New-NTFSPermissionReport -Path "C:\Data" -Recurse $true -OutputFormat "HTML" -OutputPath "C:\Reports\permissions.html"

    .OUTPUTS
        Un rapport de permissions au format spécifié.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [bool]$Recurse = $false,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "CSV", "HTML", "JSON")]
        [string]$OutputFormat = "Text",

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = $null
    )

    begin {
        # Vérifier si le chemin existe
        if (-not (Test-Path -Path $Path)) {
            Write-Error "Le chemin '$Path' n'existe pas."
            return
        }

        # Fonction pour générer un rapport au format texte
        function ConvertTo-TextReport {
            param (
                [PSCustomObject]$Data
            )

            $report = @"
=======================================================================
RAPPORT D'ANALYSE DES PERMISSIONS NTFS
=======================================================================
Chemin: $($Data.Path)
Date d'analyse: $($Data.AnalysisDate)
=======================================================================

RÉSUMÉ
-----------------------------------------------------------------------
Nombre total d'objets analysés: $($Data.Summary.TotalObjects)
Fichiers: $($Data.Summary.Files)
Dossiers: $($Data.Summary.Directories)
Anomalies détectées: $($Data.Summary.Anomalies)
Niveau de risque global: $($Data.Summary.RiskLevel)
=======================================================================

DÉTAILS DES PERMISSIONS
-----------------------------------------------------------------------
"@

            foreach ($item in $Data.Permissions) {
                $report += @"

Objet: $($item.Path) ($($item.ObjectType))
Propriétaire: $($item.Owner.FullName) ($($item.Owner.AccountType))
Héritage activé: $($item.InheritanceEnabled)

Permissions explicites:
"@

                if ($item.ExplicitPermissions.Count -eq 0) {
                    $report += "  Aucune permission explicite`n"
                } else {
                    foreach ($perm in $item.ExplicitPermissions) {
                        $report += "  $($perm.IdentityReference) : $($perm.AccessControlType) $($perm.FileSystemRights)`n"
                    }
                }

                $report += @"

Permissions héritées:
"@

                if ($item.InheritedPermissions.Count -eq 0) {
                    $report += "  Aucune permission héritée`n"
                } else {
                    foreach ($perm in $item.InheritedPermissions) {
                        $report += "  $($perm.IdentityReference) : $($perm.AccessControlType) $($perm.FileSystemRights)`n"
                    }
                }

                $report += "`n"
            }

            $report += @"
ANOMALIES DÉTECTÉES
-----------------------------------------------------------------------
"@

            if ($Data.Anomalies.Count -eq 0) {
                $report += "Aucune anomalie détectée.`n"
            } else {
                foreach ($anomaly in $Data.Anomalies) {
                    $report += @"

Chemin: $($anomaly.Path)
Type d'anomalie: $($anomaly.AnomalyType)
Sévérité: $($anomaly.Severity)
Description: $($anomaly.Description)
Recommandation: $($anomaly.Recommendation)

"@
                }
            }

            $report += @"
=======================================================================
FIN DU RAPPORT
=======================================================================
"@

            return $report
        }

        # Fonction pour générer un rapport au format HTML
        function ConvertTo-HtmlReport {
            param (
                [PSCustomObject]$Data
            )

            $htmlHeader = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport d'analyse des permissions NTFS</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        .header {
            background-color: #2c3e50;
            color: white;
            padding: 20px;
            margin-bottom: 20px;
        }
        .summary {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .item {
            background-color: #fff;
            border: 1px solid #ddd;
            padding: 15px;
            margin-bottom: 15px;
            border-radius: 5px;
        }
        .permissions {
            margin-left: 20px;
        }
        .anomaly {
            background-color: #fff3cd;
            border: 1px solid #ffeeba;
            padding: 15px;
            margin-bottom: 15px;
            border-radius: 5px;
        }
        .severity-high {
            border-left: 5px solid #dc3545;
        }
        .severity-medium {
            border-left: 5px solid #ffc107;
        }
        .severity-low {
            border-left: 5px solid #28a745;
        }
        .severity-info {
            border-left: 5px solid #17a2b8;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 15px;
        }
        th, td {
            padding: 8px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f2f2f2;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 10px;
            border-top: 1px solid #ddd;
            color: #777;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Rapport d'analyse des permissions NTFS</h1>
            <p>Chemin: $($Data.Path)</p>
            <p>Date d'analyse: $($Data.AnalysisDate)</p>
        </div>

        <div class="summary">
            <h2>Résumé</h2>
            <p>Nombre total d'objets analysés: $($Data.Summary.TotalObjects)</p>
            <p>Fichiers: $($Data.Summary.Files)</p>
            <p>Dossiers: $($Data.Summary.Directories)</p>
            <p>Anomalies détectées: $($Data.Summary.Anomalies)</p>
            <p>Niveau de risque global: $($Data.Summary.RiskLevel)</p>
        </div>

        <h2>Détails des permissions</h2>
"@

            $htmlItems = ""
            foreach ($item in $Data.Permissions) {
                $htmlItems += @"
        <div class="item">
            <h3>$($item.Path) ($($item.ObjectType))</h3>
            <p><strong>Propriétaire:</strong> $($item.Owner.FullName) ($($item.Owner.AccountType))</p>
            <p><strong>Héritage activé:</strong> $($item.InheritanceEnabled)</p>

            <h4>Permissions explicites</h4>
"@

                if ($item.ExplicitPermissions.Count -eq 0) {
                    $htmlItems += "            <p>Aucune permission explicite</p>`n"
                } else {
                    $htmlItems += @"
            <table>
                <tr>
                    <th>Identité</th>
                    <th>Type d'accès</th>
                    <th>Droits</th>
                </tr>
"@

                    foreach ($perm in $item.ExplicitPermissions) {
                        $htmlItems += @"
                <tr>
                    <td>$($perm.IdentityReference)</td>
                    <td>$($perm.AccessControlType)</td>
                    <td>$($perm.FileSystemRights)</td>
                </tr>
"@
                    }

                    $htmlItems += "            </table>`n"
                }

                $htmlItems += @"

            <h4>Permissions héritées</h4>
"@

                if ($item.InheritedPermissions.Count -eq 0) {
                    $htmlItems += "            <p>Aucune permission héritée</p>`n"
                } else {
                    $htmlItems += @"
            <table>
                <tr>
                    <th>Identité</th>
                    <th>Type d'accès</th>
                    <th>Droits</th>
                </tr>
"@

                    foreach ($perm in $item.InheritedPermissions) {
                        $htmlItems += @"
                <tr>
                    <td>$($perm.IdentityReference)</td>
                    <td>$($perm.AccessControlType)</td>
                    <td>$($perm.FileSystemRights)</td>
                </tr>
"@
                    }

                    $htmlItems += "            </table>`n"
                }

                $htmlItems += "        </div>`n"
            }

            $htmlAnomalies = @"

        <h2>Anomalies détectées</h2>
"@

            if ($Data.Anomalies.Count -eq 0) {
                $htmlAnomalies += "        <p>Aucune anomalie détectée.</p>`n"
            } else {
                foreach ($anomaly in $Data.Anomalies) {
                    $severityClass = "severity-info"
                    if ($anomaly.Severity -eq "Élevée") {
                        $severityClass = "severity-high"
                    } elseif ($anomaly.Severity -eq "Moyenne") {
                        $severityClass = "severity-medium"
                    } elseif ($anomaly.Severity -eq "Faible") {
                        $severityClass = "severity-low"
                    }

                    $htmlAnomalies += @"
        <div class="anomaly $severityClass">
            <h3>$($anomaly.AnomalyType)</h3>
            <p><strong>Chemin:</strong> $($anomaly.Path)</p>
            <p><strong>Sévérité:</strong> $($anomaly.Severity)</p>
            <p><strong>Description:</strong> $($anomaly.Description)</p>
            <p><strong>Recommandation:</strong> $($anomaly.Recommendation)</p>
        </div>
"@
                }
            }

            $htmlFooter = @"

        <div class="footer">
            <p>Rapport généré le $($Data.AnalysisDate) avec ACLAnalyzer</p>
        </div>
    </div>
</body>
</html>
"@

            return $htmlHeader + $htmlItems + $htmlAnomalies + $htmlFooter
        }
    }

    process {
        try {
            # Collecter les données pour le rapport
            $reportData = [PSCustomObject]@{
                Path = $Path
                AnalysisDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Permissions = @()
                Anomalies = @()
                Summary = [PSCustomObject]@{
                    TotalObjects = 0
                    Files = 0
                    Directories = 0
                    Anomalies = 0
                    RiskLevel = "Faible"
                }
            }

            # Obtenir les permissions NTFS
            $permissions = Get-NTFSPermission -Path $Path -Recurse $Recurse -IncludeInherited $true

            # Obtenir les informations d'héritage
            $inheritanceInfo = Get-NTFSPermissionInheritance -Path $Path -Recurse $Recurse

            # Obtenir les informations de propriété
            $ownershipInfo = Get-NTFSOwnershipInfo -Path $Path -Recurse $Recurse

            # Obtenir les anomalies
            $anomalies = Find-NTFSPermissionAnomaly -Path $Path -Recurse $Recurse

            # Regrouper les permissions par chemin
            $permissionsByPath = $permissions | Group-Object -Property Path

            # Regrouper les informations d'héritage par chemin
            $inheritanceByPath = $inheritanceInfo | Group-Object -Property Path

            # Regrouper les informations de propriété par chemin
            $ownershipByPath = $ownershipInfo | Group-Object -Property Path

            # Combiner les informations pour chaque chemin
            $paths = @($permissionsByPath.Name) + @($inheritanceByPath.Name) + @($ownershipByPath.Name) | Select-Object -Unique

            foreach ($path in $paths) {
                $permGroup = $permissionsByPath | Where-Object { $_.Name -eq $path }
                $inheritGroup = $inheritanceByPath | Where-Object { $_.Name -eq $path }
                $ownerGroup = $ownershipByPath | Where-Object { $_.Name -eq $path }

                $objectType = "Inconnu"
                $owner = $null
                $inheritanceEnabled = $true
                $explicitPermissions = @()
                $inheritedPermissions = @()

                if ($permGroup) {
                    $objectType = $permGroup.Group[0].ObjectType
                    $permGroup.Group | ForEach-Object {
                        if ($_.IsInherited) {
                            $inheritedPermissions += $_
                        } else {
                            $explicitPermissions += $_
                        }
                    }
                }

                if ($inheritGroup) {
                    $objectType = $inheritGroup.Group[0].ObjectType
                    $inheritanceEnabled = $inheritGroup.Group[0].InheritanceEnabled
                }

                if ($ownerGroup) {
                    $objectType = $ownerGroup.Group[0].ObjectType
                    $owner = $ownerGroup.Group[0].Owner
                }

                $itemInfo = [PSCustomObject]@{
                    Path = $path
                    ObjectType = $objectType
                    Owner = $owner
                    InheritanceEnabled = $inheritanceEnabled
                    ExplicitPermissions = $explicitPermissions
                    InheritedPermissions = $inheritedPermissions
                }

                $reportData.Permissions += $itemInfo

                # Mettre à jour les statistiques
                $reportData.Summary.TotalObjects++
                if ($objectType -eq "Fichier") {
                    $reportData.Summary.Files++
                } elseif ($objectType -eq "Dossier") {
                    $reportData.Summary.Directories++
                }
            }

            # Ajouter les anomalies au rapport
            $reportData.Anomalies = $anomalies
            $reportData.Summary.Anomalies = $anomalies.Count

            # Déterminer le niveau de risque global
            $highRiskCount = ($anomalies | Where-Object { $_.Severity -eq "Élevée" }).Count
            $mediumRiskCount = ($anomalies | Where-Object { $_.Severity -eq "Moyenne" }).Count

            if ($highRiskCount -gt 0) {
                $reportData.Summary.RiskLevel = "Élevé"
            } elseif ($mediumRiskCount -gt 0) {
                $reportData.Summary.RiskLevel = "Moyen"
            } else {
                $reportData.Summary.RiskLevel = "Faible"
            }

            # Générer le rapport au format demandé
            $reportContent = $null

            switch ($OutputFormat) {
                "Text" {
                    $reportContent = ConvertTo-TextReport -Data $reportData
                }
                "CSV" {
                    # Créer un tableau d'objets pour l'export CSV
                    $csvData = @()

                    foreach ($item in $reportData.Permissions) {
                        $csvItem = [PSCustomObject]@{
                            Path = $item.Path
                            ObjectType = $item.ObjectType
                            Owner = $item.Owner.FullName
                            OwnerType = $item.Owner.AccountType
                            InheritanceEnabled = $item.InheritanceEnabled
                            ExplicitPermissionsCount = $item.ExplicitPermissions.Count
                            InheritedPermissionsCount = $item.InheritedPermissions.Count
                        }

                        $csvData += $csvItem
                    }

                    $reportContent = $csvData | ConvertTo-Csv -NoTypeInformation
                }
                "HTML" {
                    $reportContent = ConvertTo-HtmlReport -Data $reportData
                }
                "JSON" {
                    $reportContent = $reportData | ConvertTo-Json -Depth 10
                }
            }

            # Enregistrer ou afficher le rapport
            if ($OutputPath) {
                $reportContent | Out-File -FilePath $OutputPath -Encoding utf8
                Write-Host "Rapport enregistré dans '$OutputPath'."
            } else {
                return $reportContent
            }
        }
        catch {
            Write-Error "Erreur lors de la génération du rapport de permissions NTFS pour '$Path': $($_.Exception.Message)"
        }
    }
}

# Fonction pour corriger automatiquement les anomalies de permissions NTFS
function Repair-NTFSPermissionAnomaly {
    <#
    .SYNOPSIS
        Corrige automatiquement les anomalies de permissions NTFS détectées.

    .DESCRIPTION
        Cette fonction corrige automatiquement les anomalies de permissions NTFS détectées
        par la fonction Find-NTFSPermissionAnomaly, comme les permissions trop permissives,
        les conflits, ou les héritages interrompus.

    .PARAMETER Path
        Le chemin du fichier ou dossier à corriger.

    .PARAMETER AnomalyType
        Le type d'anomalie à corriger. Si non spécifié, toutes les anomalies seront corrigées.
        Valeurs possibles : "HighRiskPermission", "PermissionConflict", "RedundantPermission", "InheritanceBreak".

    .PARAMETER WhatIf
        Indique si la fonction doit simuler les corrections sans les appliquer.

    .PARAMETER Force
        Force l'application des corrections sans demander de confirmation.

    .EXAMPLE
        Repair-NTFSPermissionAnomaly -Path "C:\Data" -AnomalyType "HighRiskPermission" -WhatIf

    .OUTPUTS
        [PSCustomObject] avec des informations sur les corrections effectuées.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("HighRiskPermission", "PermissionConflict", "RedundantPermission", "InheritanceBreak", "All")]
        [string]$AnomalyType = "All",

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    begin {
        # Vérifier si le chemin existe
        if (-not (Test-Path -Path $Path)) {
            Write-Error "Le chemin '$Path' n'existe pas."
            return
        }

        # Fonction pour obtenir le type d'objet (fichier ou dossier)
        function Get-ObjectType {
            param (
                [string]$Path
            )

            $item = Get-Item -Path $Path -Force
            if ($item -is [System.IO.DirectoryInfo]) {
                return "Dossier"
            } else {
                return "Fichier"
            }
        }
    }

    process {
        try {
            $results = @()

            # Détecter les anomalies
            $anomalies = Find-NTFSPermissionAnomaly -Path $Path

            # Filtrer les anomalies par type si spécifié
            if ($AnomalyType -ne "All") {
                $anomalies = $anomalies | Where-Object { $_.AnomalyType -eq $AnomalyType }
            }

            if (-not $anomalies) {
                Write-Host "Aucune anomalie à corriger pour le chemin '$Path'."
                return
            }

            # Obtenir les ACL de l'objet
            $acl = Get-Acl -Path $Path

            # Obtenir le type d'objet
            $objectType = Get-ObjectType -Path $Path

            # Traiter chaque anomalie
            foreach ($anomaly in $anomalies) {
                $correctionInfo = [PSCustomObject]@{
                    Path = $anomaly.Path
                    AnomalyType = $anomaly.AnomalyType
                    Description = $anomaly.Description
                    CorrectionApplied = $false
                    CorrectionDescription = ""
                }

                # Corriger selon le type d'anomalie
                switch ($anomaly.AnomalyType) {
                    "HighRiskPermission" {
                        # Obtenir l'ACL actuelle du chemin de l'anomalie
                        $itemAcl = Get-Acl -Path $anomaly.Path

                        # Trouver la règle à risque élevé
                        $highRiskRule = $itemAcl.Access | Where-Object {
                            $_.IdentityReference.Value -eq $anomaly.IdentityReference -and
                            $_.FileSystemRights.ToString() -match $anomaly.Rights
                        }

                        if ($highRiskRule) {
                            $correctionDescription = "Suppression de la permission à risque élevé pour $($anomaly.IdentityReference)"

                            if ($Force -or $PSCmdlet.ShouldProcess($anomaly.Path, $correctionDescription)) {
                                # Supprimer la règle à risque élevé
                                $itemAcl.RemoveAccessRule($highRiskRule)

                                # Ajouter une règle plus restrictive si nécessaire
                                $identity = New-Object System.Security.Principal.NTAccount($anomaly.IdentityReference)
                                $newRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                                    $identity,
                                    "ReadAndExecute",  # Droits plus restrictifs
                                    $highRiskRule.InheritanceFlags,
                                    $highRiskRule.PropagationFlags,
                                    "Allow"
                                )

                                $itemAcl.AddAccessRule($newRule)
                                Set-Acl -Path $anomaly.Path -AclObject $itemAcl

                                $correctionInfo.CorrectionApplied = $true
                                $correctionInfo.CorrectionDescription = "$correctionDescription et ajout d'une permission plus restrictive (ReadAndExecute)"
                            } else {
                                $correctionInfo.CorrectionDescription = "$correctionDescription (non appliqué)"
                            }
                        } else {
                            $correctionInfo.CorrectionDescription = "Règle à risque élevé non trouvée"
                        }
                    }

                    "PermissionConflict" {
                        # Obtenir l'ACL actuelle du chemin de l'anomalie
                        $itemAcl = Get-Acl -Path $anomaly.Path

                        # Trouver les règles en conflit
                        $conflictRules = $itemAcl.Access | Where-Object {
                            $_.IdentityReference.Value -eq $anomaly.IdentityReference
                        }

                        if ($conflictRules) {
                            $correctionDescription = "Résolution du conflit de permissions pour $($anomaly.IdentityReference)"

                            if ($Force -or $PSCmdlet.ShouldProcess($anomaly.Path, $correctionDescription)) {
                                # Supprimer toutes les règles en conflit
                                foreach ($rule in $conflictRules) {
                                    $itemAcl.RemoveAccessRule($rule)
                                }

                                # Ajouter une nouvelle règle consolidée
                                $identity = New-Object System.Security.Principal.NTAccount($anomaly.IdentityReference)
                                $newRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                                    $identity,
                                    "ReadAndExecute",  # Droits de base
                                    "ContainerInherit,ObjectInherit",
                                    "None",
                                    "Allow"
                                )

                                $itemAcl.AddAccessRule($newRule)
                                Set-Acl -Path $anomaly.Path -AclObject $itemAcl

                                $correctionInfo.CorrectionApplied = $true
                                $correctionInfo.CorrectionDescription = "$correctionDescription en consolidant les règles"
                            } else {
                                $correctionInfo.CorrectionDescription = "$correctionDescription (non appliqué)"
                            }
                        } else {
                            $correctionInfo.CorrectionDescription = "Règles en conflit non trouvées"
                        }
                    }

                    "RedundantPermission" {
                        # Obtenir l'ACL actuelle du chemin de l'anomalie
                        $itemAcl = Get-Acl -Path $anomaly.Path

                        # Trouver les règles redondantes
                        $redundantRules = $itemAcl.Access | Where-Object {
                            $_.IdentityReference.Value -eq $anomaly.IdentityReference
                        }

                        if ($redundantRules -and $redundantRules.Count -gt 1) {
                            $correctionDescription = "Consolidation des permissions redondantes pour $($anomaly.IdentityReference)"

                            if ($Force -or $PSCmdlet.ShouldProcess($anomaly.Path, $correctionDescription)) {
                                # Supprimer toutes les règles redondantes
                                foreach ($rule in $redundantRules) {
                                    $itemAcl.RemoveAccessRule($rule)
                                }

                                # Déterminer les droits combinés
                                $combinedRights = [System.Security.AccessControl.FileSystemRights]::None
                                foreach ($rule in $redundantRules) {
                                    if ($rule.AccessControlType -eq [System.Security.AccessControl.AccessControlType]::Allow) {
                                        $combinedRights = $combinedRights -bor $rule.FileSystemRights
                                    }
                                }

                                # Ajouter une nouvelle règle consolidée
                                $identity = New-Object System.Security.Principal.NTAccount($anomaly.IdentityReference)
                                $newRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                                    $identity,
                                    $combinedRights,
                                    "ContainerInherit,ObjectInherit",
                                    "None",
                                    "Allow"
                                )

                                $itemAcl.AddAccessRule($newRule)
                                Set-Acl -Path $anomaly.Path -AclObject $itemAcl

                                $correctionInfo.CorrectionApplied = $true
                                $correctionInfo.CorrectionDescription = "$correctionDescription en une seule règle"
                            } else {
                                $correctionInfo.CorrectionDescription = "$correctionDescription (non appliqué)"
                            }
                        } else {
                            $correctionInfo.CorrectionDescription = "Règles redondantes non trouvées"
                        }
                    }

                    "InheritanceBreak" {
                        # Obtenir l'ACL actuelle du chemin de l'anomalie
                        $itemAcl = Get-Acl -Path $anomaly.Path

                        $correctionDescription = "Réactivation de l'héritage des permissions"

                        if ($Force -or $PSCmdlet.ShouldProcess($anomaly.Path, $correctionDescription)) {
                            # Réactiver l'héritage
                            $itemAcl.SetAccessRuleProtection($false, $true)  # Activer l'héritage et conserver les règles existantes
                            Set-Acl -Path $anomaly.Path -AclObject $itemAcl

                            $correctionInfo.CorrectionApplied = $true
                            $correctionInfo.CorrectionDescription = $correctionDescription
                        } else {
                            $correctionInfo.CorrectionDescription = "$correctionDescription (non appliqué)"
                        }
                    }

                    default {
                        $correctionInfo.CorrectionDescription = "Type d'anomalie non pris en charge"
                    }
                }

                $results += $correctionInfo
            }

            return $results
        }
        catch {
            Write-Error "Erreur lors de la correction des anomalies de permissions NTFS pour '$Path': $($_.Exception.Message)"
        }
    }
}

# Fonction pour comparer les permissions NTFS entre deux chemins
function Compare-NTFSPermission {
    <#
    .SYNOPSIS
        Compare les permissions NTFS entre deux chemins.

    .DESCRIPTION
        Cette fonction compare les permissions NTFS entre deux chemins et identifie
        les différences, comme les permissions manquantes, supplémentaires ou modifiées.

    .PARAMETER ReferencePath
        Le chemin de référence pour la comparaison.

    .PARAMETER DifferencePath
        Le chemin à comparer avec la référence.

    .PARAMETER IncludeInherited
        Indique si les permissions héritées doivent être incluses dans la comparaison.

    .EXAMPLE
        Compare-NTFSPermission -ReferencePath "C:\Data\Reference" -DifferencePath "C:\Data\Target" -IncludeInherited $true

    .OUTPUTS
        [PSCustomObject] avec des informations sur les différences de permissions.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$ReferencePath,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$DifferencePath,

        [Parameter(Mandatory = $false)]
        [bool]$IncludeInherited = $true
    )

    begin {
        # Vérifier si les chemins existent
        if (-not (Test-Path -Path $ReferencePath)) {
            Write-Error "Le chemin de référence '$ReferencePath' n'existe pas."
            return
        }

        if (-not (Test-Path -Path $DifferencePath)) {
            Write-Error "Le chemin à comparer '$DifferencePath' n'existe pas."
            return
        }
    }

    process {
        try {
            # Obtenir les permissions des deux chemins
            $referencePermissions = Get-NTFSPermission -Path $ReferencePath -Recurse $false -IncludeInherited $IncludeInherited
            $differencePermissions = Get-NTFSPermission -Path $DifferencePath -Recurse $false -IncludeInherited $IncludeInherited

            # Créer des collections pour les différences
            $missingPermissions = @()
            $additionalPermissions = @()
            $modifiedPermissions = @()

            # Comparer les permissions de référence avec les permissions de différence
            foreach ($refPerm in $referencePermissions) {
                $matchingPerm = $differencePermissions | Where-Object {
                    $_.IdentityReference -eq $refPerm.IdentityReference -and
                    $_.AccessControlType -eq $refPerm.AccessControlType
                }

                if (-not $matchingPerm) {
                    # Permission manquante dans le chemin de différence
                    $missingPermissions += [PSCustomObject]@{
                        IdentityReference = $refPerm.IdentityReference
                        AccessControlType = $refPerm.AccessControlType
                        FileSystemRights = $refPerm.FileSystemRights
                        IsInherited = $refPerm.IsInherited
                    }
                } elseif ($matchingPerm.FileSystemRights -ne $refPerm.FileSystemRights) {
                    # Permission modifiée
                    $modifiedPermissions += [PSCustomObject]@{
                        IdentityReference = $refPerm.IdentityReference
                        AccessControlType = $refPerm.AccessControlType
                        ReferenceRights = $refPerm.FileSystemRights
                        DifferenceRights = $matchingPerm.FileSystemRights
                        IsInherited = $refPerm.IsInherited
                    }
                }
            }

            # Trouver les permissions supplémentaires dans le chemin de différence
            foreach ($diffPerm in $differencePermissions) {
                $matchingPerm = $referencePermissions | Where-Object {
                    $_.IdentityReference -eq $diffPerm.IdentityReference -and
                    $_.AccessControlType -eq $diffPerm.AccessControlType
                }

                if (-not $matchingPerm) {
                    # Permission supplémentaire dans le chemin de différence
                    $additionalPermissions += [PSCustomObject]@{
                        IdentityReference = $diffPerm.IdentityReference
                        AccessControlType = $diffPerm.AccessControlType
                        FileSystemRights = $diffPerm.FileSystemRights
                        IsInherited = $diffPerm.IsInherited
                    }
                }
            }

            # Créer l'objet de résultat
            $result = [PSCustomObject]@{
                ReferencePath = $ReferencePath
                DifferencePath = $DifferencePath
                MissingPermissions = $missingPermissions
                AdditionalPermissions = $additionalPermissions
                ModifiedPermissions = $modifiedPermissions
                HasDifferences = ($missingPermissions.Count -gt 0 -or $additionalPermissions.Count -gt 0 -or $modifiedPermissions.Count -gt 0)
            }

            return $result
        }
        catch {
            Write-Error "Erreur lors de la comparaison des permissions NTFS: $($_.Exception.Message)"
        }
    }
}

# Fonction pour exporter les permissions NTFS vers un fichier
function Export-NTFSPermission {
    <#
    .SYNOPSIS
        Exporte les permissions NTFS d'un chemin vers un fichier.

    .DESCRIPTION
        Cette fonction exporte les permissions NTFS d'un chemin vers un fichier JSON ou XML,
        permettant de sauvegarder une configuration de sécurité pour une restauration ultérieure.

    .PARAMETER Path
        Le chemin du fichier ou dossier dont les permissions doivent être exportées.

    .PARAMETER OutputPath
        Le chemin du fichier de sortie où les permissions seront exportées.

    .PARAMETER Format
        Le format du fichier d'exportation. Valeurs possibles : "JSON", "XML", "CSV".

    .PARAMETER Recurse
        Indique si l'exportation doit être récursive pour les dossiers.

    .EXAMPLE
        Export-NTFSPermission -Path "C:\Data" -OutputPath "C:\Backup\DataPermissions.json" -Format "JSON" -Recurse $true

    .OUTPUTS
        [string] Le chemin du fichier d'exportation.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "XML", "CSV")]
        [string]$Format = "JSON",

        [Parameter(Mandatory = $false)]
        [bool]$Recurse = $false
    )

    begin {
        # Vérifier si le chemin existe
        if (-not (Test-Path -Path $Path)) {
            Write-Error "Le chemin '$Path' n'existe pas."
            return
        }

        # Vérifier si le dossier de sortie existe
        $outputFolder = Split-Path -Parent $OutputPath
        if (-not (Test-Path -Path $outputFolder)) {
            try {
                New-Item -Path $outputFolder -ItemType Directory -Force | Out-Null
            } catch {
                Write-Error "Impossible de créer le dossier de sortie '$outputFolder': $($_.Exception.Message)"
                return
            }
        }
    }

    process {
        try {
            # Obtenir les permissions NTFS
            $permissions = Get-NTFSPermission -Path $Path -Recurse $Recurse -IncludeInherited $true

            # Créer un objet d'exportation avec des métadonnées
            $exportObject = [PSCustomObject]@{
                ExportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                SourcePath = $Path
                Recurse = $Recurse
                Permissions = $permissions
            }

            # Exporter selon le format spécifié
            switch ($Format) {
                "JSON" {
                    $exportObject | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8
                }
                "XML" {
                    $exportObject | Export-Clixml -Path $OutputPath -Encoding utf8
                }
                "CSV" {
                    # Pour CSV, nous devons aplatir les données
                    $flatPermissions = @()
                    foreach ($perm in $permissions) {
                        $flatPerm = [PSCustomObject]@{
                            Path = $perm.Path
                            ObjectType = $perm.ObjectType
                            IdentityReference = $perm.IdentityReference
                            AccessControlType = $perm.AccessControlType
                            FileSystemRights = $perm.FileSystemRights
                            IsInherited = $perm.IsInherited
                            InheritanceFlags = $perm.InheritanceFlags
                            PropagationFlags = $perm.PropagationFlags
                        }
                        $flatPermissions += $flatPerm
                    }
                    $flatPermissions | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding utf8
                }
            }

            Write-Host "Permissions NTFS exportées avec succès vers '$OutputPath'."
            return $OutputPath
        }
        catch {
            Write-Error "Erreur lors de l'exportation des permissions NTFS: $($_.Exception.Message)"
        }
    }
}

# Fonction pour importer les permissions NTFS depuis un fichier
function Import-NTFSPermission {
    <#
    .SYNOPSIS
        Importe les permissions NTFS depuis un fichier et les applique à un chemin.

    .DESCRIPTION
        Cette fonction importe les permissions NTFS depuis un fichier JSON, XML ou CSV
        et les applique à un chemin spécifié, permettant de restaurer une configuration de sécurité.

    .PARAMETER InputPath
        Le chemin du fichier d'entrée contenant les permissions à importer.

    .PARAMETER TargetPath
        Le chemin du fichier ou dossier auquel les permissions doivent être appliquées.
        Si non spécifié, le chemin source original sera utilisé.

    .PARAMETER Format
        Le format du fichier d'importation. Valeurs possibles : "JSON", "XML", "CSV".

    .PARAMETER WhatIf
        Indique si la fonction doit simuler l'importation sans appliquer les permissions.

    .PARAMETER Force
        Force l'application des permissions sans demander de confirmation.

    .EXAMPLE
        Import-NTFSPermission -InputPath "C:\Backup\DataPermissions.json" -TargetPath "D:\Data" -Format "JSON" -WhatIf

    .OUTPUTS
        [PSCustomObject] avec des informations sur les permissions appliquées.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$InputPath,

        [Parameter(Mandatory = $false, Position = 1)]
        [string]$TargetPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "XML", "CSV")]
        [string]$Format = "JSON",

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    begin {
        # Vérifier si le fichier d'entrée existe
        if (-not (Test-Path -Path $InputPath)) {
            Write-Error "Le fichier d'entrée '$InputPath' n'existe pas."
            return
        }
    }

    process {
        try {
            # Importer les permissions selon le format spécifié
            $importObject = $null
            switch ($Format) {
                "JSON" {
                    $importObject = Get-Content -Path $InputPath -Raw | ConvertFrom-Json
                }
                "XML" {
                    $importObject = Import-Clixml -Path $InputPath
                }
                "CSV" {
                    $importObject = [PSCustomObject]@{
                        ExportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                        SourcePath = ""
                        Recurse = $false
                        Permissions = Import-Csv -Path $InputPath
                    }
                }
            }

            # Déterminer le chemin cible
            $actualTargetPath = if ($TargetPath) { $TargetPath } else { $importObject.SourcePath }

            # Vérifier si le chemin cible existe
            if (-not (Test-Path -Path $actualTargetPath)) {
                Write-Error "Le chemin cible '$actualTargetPath' n'existe pas."
                return
            }

            $results = @()

            # Appliquer les permissions
            foreach ($perm in $importObject.Permissions) {
                # Déterminer le chemin relatif et le chemin cible complet
                $relativePath = if ($perm.Path -eq $importObject.SourcePath) {
                    ""
                } else {
                    $perm.Path.Substring($importObject.SourcePath.Length)
                }

                $targetItemPath = if ($relativePath) {
                    Join-Path -Path $actualTargetPath -ChildPath $relativePath
                } else {
                    $actualTargetPath
                }

                # Vérifier si le chemin cible existe
                if (-not (Test-Path -Path $targetItemPath)) {
                    Write-Warning "Le chemin cible '$targetItemPath' n'existe pas et sera ignoré."
                    continue
                }

                $permissionInfo = [PSCustomObject]@{
                    SourcePath = $perm.Path
                    TargetPath = $targetItemPath
                    IdentityReference = $perm.IdentityReference
                    AccessControlType = $perm.AccessControlType
                    FileSystemRights = $perm.FileSystemRights
                    Applied = $false
                }

                # Appliquer la permission si ce n'est pas une permission héritée
                if (-not $perm.IsInherited) {
                    $description = "Application de la permission '$($perm.FileSystemRights)' pour '$($perm.IdentityReference)' sur '$targetItemPath'"

                    if ($Force -or $PSCmdlet.ShouldProcess($targetItemPath, $description)) {
                        try {
                            # Obtenir l'ACL actuelle
                            $acl = Get-Acl -Path $targetItemPath

                            # Créer la règle d'accès
                            $identity = New-Object System.Security.Principal.NTAccount($perm.IdentityReference)
                            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                                $identity,
                                $perm.FileSystemRights,
                                $perm.InheritanceFlags,
                                $perm.PropagationFlags,
                                $perm.AccessControlType
                            )

                            # Ajouter la règle et appliquer l'ACL
                            $acl.AddAccessRule($rule)
                            Set-Acl -Path $targetItemPath -AclObject $acl

                            $permissionInfo.Applied = $true
                        } catch {
                            Write-Warning "Erreur lors de l'application de la permission sur '$targetItemPath': $($_.Exception.Message)"
                        }
                    }
                } else {
                    $permissionInfo.Applied = "Ignoré (permission héritée)"
                }

                $results += $permissionInfo
            }

            return $results
        }
        catch {
            Write-Error "Erreur lors de l'importation des permissions NTFS: $($_.Exception.Message)"
        }
    }
}

# Exporter les fonctions si le script est importé comme module
if ($MyInvocation.Line -match '^\. ') {
    # Le script est sourcé directement, pas besoin d'exporter
} elseif ($MyInvocation.MyCommand.Path -eq $null) {
    # Le script est exécuté directement, pas besoin d'exporter
} else {
    # Le script est importé comme module, exporter les fonctions
    Export-ModuleMember -Function Get-NTFSPermission, Find-NTFSPermissionAnomaly, Get-NTFSPermissionInheritance, Get-NTFSOwnershipInfo, New-NTFSPermissionReport, Repair-NTFSPermissionAnomaly, Compare-NTFSPermission, Export-NTFSPermission, Import-NTFSPermission
}
