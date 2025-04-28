<#
.SYNOPSIS
    Outils d'analyse des listes de contrÃ´le d'accÃ¨s (ACL) pour les fichiers, dossiers, registre et autres ressources.

.DESCRIPTION
    Ce module fournit des fonctions pour analyser, comparer et visualiser les listes de contrÃ´le d'accÃ¨s (ACL)
    sur diffÃ©rentes ressources du systÃ¨me, y compris les fichiers, dossiers, clÃ©s de registre, partages rÃ©seau
    et bases de donnÃ©es SQL Server.

.NOTES
    Nom du fichier : ACLAnalyzer.ps1
    Auteur        : Augment Code
    Version       : 1.0
    PrÃ©requis     : PowerShell 5.1 ou supÃ©rieur
#>

#Requires -Version 5.1

# Fonction pour analyser les permissions NTFS d'un fichier ou dossier
function Get-NTFSPermission {
    <#
    .SYNOPSIS
        Analyse les permissions NTFS d'un fichier ou dossier.

    .DESCRIPTION
        Cette fonction analyse en dÃ©tail les permissions NTFS d'un fichier ou dossier,
        y compris les droits spÃ©cifiques, les hÃ©ritages, et les identitÃ©s associÃ©es.

    .PARAMETER Path
        Le chemin du fichier ou dossier Ã  analyser.

    .PARAMETER Recurse
        Indique si l'analyse doit Ãªtre rÃ©cursive pour les dossiers.

    .PARAMETER IncludeInherited
        Indique si les permissions hÃ©ritÃ©es doivent Ãªtre incluses dans l'analyse.

    .EXAMPLE
        Get-NTFSPermission -Path "C:\Data" -Recurse $false -IncludeInherited $true

    .OUTPUTS
        [PSCustomObject] avec des informations dÃ©taillÃ©es sur les permissions NTFS.
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
        # VÃ©rifier si le chemin existe
        if (-not (Test-Path -Path $Path)) {
            Write-Error "Le chemin '$Path' n'existe pas."
            return
        }

        # Fonction pour convertir les droits d'accÃ¨s en chaÃ®ne lisible
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

            # Droits spÃ©cifiques
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

            # VÃ©rifier d'abord les droits de base
            foreach ($right in $basicRights.Keys) {
                if (($Rights -band $basicRights[$right]) -eq $basicRights[$right]) {
                    $readableRights += $right
                    return $readableRights  # Si un droit de base est trouvÃ©, on le retourne directement
                }
            }

            # Si aucun droit de base n'est trouvÃ©, vÃ©rifier les droits spÃ©cifiques
            foreach ($right in $specificRights.Keys) {
                if (($Rights -band $specificRights[$right]) -eq $specificRights[$right]) {
                    $readableRights += $right
                }
            }

            return $readableRights
        }

        # Fonction pour convertir les flags d'hÃ©ritage en chaÃ®ne lisible
        function ConvertTo-ReadableInheritanceFlags {
            param (
                [System.Security.AccessControl.InheritanceFlags]$InheritanceFlags,
                [System.Security.AccessControl.PropagationFlags]$PropagationFlags
            )

            $inheritance = @()

            # Flags d'hÃ©ritage
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
                $inheritance += "HÃ©ritage uniquement"
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

            # Analyser chaque rÃ¨gle d'accÃ¨s
            foreach ($accessRule in $acl.Access) {
                # Ignorer les permissions hÃ©ritÃ©es si demandÃ©
                if (-not $IncludeInherited -and $accessRule.IsInherited) {
                    continue
                }

                # Convertir les droits en format lisible
                $readableRights = ConvertTo-ReadableRights -Rights $accessRule.FileSystemRights

                # Convertir les flags d'hÃ©ritage en format lisible
                $readableInheritance = ConvertTo-ReadableInheritanceFlags -InheritanceFlags $accessRule.InheritanceFlags -PropagationFlags $accessRule.PropagationFlags

                # CrÃ©er un objet personnalisÃ© pour cette rÃ¨gle d'accÃ¨s
                $permissionInfo = [PSCustomObject]@{
                    Path = $Path
                    ObjectType = $objectType
                    IdentityReference = $accessRule.IdentityReference.Value
                    AccessControlType = $accessRule.AccessControlType.ToString()
                    Rights = $readableRights
                    RightsRaw = $accessRule.FileSystemRights.ToString()
                    Inheritance = $readableInheritance
                    IsInherited = $accessRule.IsInherited
                    InheritanceSource = if ($accessRule.IsInherited) { (Split-Path -Parent $Path) } else { "Directement assignÃ©" }
                }

                $results += $permissionInfo
            }

            # Ajouter des informations sur le propriÃ©taire
            $ownerInfo = [PSCustomObject]@{
                Path = $Path
                ObjectType = $objectType
                IdentityReference = $acl.Owner
                AccessControlType = "PropriÃ©taire"
                Rights = "ContrÃ´le total (implicite)"
                RightsRaw = "FullControl"
                Inheritance = "N/A"
                IsInherited = $false
                InheritanceSource = "PropriÃ©taire du systÃ¨me de fichiers"
            }

            $results += $ownerInfo

            # Si rÃ©cursif est demandÃ© et que c'est un dossier, analyser les sous-dossiers et fichiers
            # Mais limiter la profondeur pour Ã©viter les boucles infinies
            if ($Recurse -and $objectType -eq "Dossier") {
                # Limiter le nombre d'Ã©lÃ©ments Ã  traiter
                $childItems = Get-ChildItem -Path $Path -Force | Select-Object -First 10

                foreach ($childItem in $childItems) {
                    # Ã‰viter les liens symboliques qui pourraient crÃ©er des boucles
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

# Fonction pour dÃ©tecter les anomalies dans les permissions NTFS
function Find-NTFSPermissionAnomaly {
    <#
    .SYNOPSIS
        DÃ©tecte les anomalies dans les permissions NTFS.

    .DESCRIPTION
        Cette fonction analyse les permissions NTFS et dÃ©tecte les anomalies potentielles
        comme les permissions excessives, les conflits, ou les configurations dangereuses.

    .PARAMETER Path
        Le chemin du fichier ou dossier Ã  analyser.

    .PARAMETER Recurse
        Indique si l'analyse doit Ãªtre rÃ©cursive pour les dossiers.

    .EXAMPLE
        Find-NTFSPermissionAnomaly -Path "C:\Data" -Recurse $true

    .OUTPUTS
        [PSCustomObject] avec des informations sur les anomalies dÃ©tectÃ©es.
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
        # VÃ©rifier si le chemin existe
        if (-not (Test-Path -Path $Path)) {
            Write-Error "Le chemin '$Path' n'existe pas."
            return
        }

        # DÃ©finir les groupes Ã  risque Ã©levÃ©
        $highRiskGroups = @(
            "Everyone",
            "Tout le monde",
            "Authenticated Users",
            "Utilisateurs authentifiÃ©s",
            "Users",
            "Utilisateurs",
            "ANONYMOUS LOGON",
            "Connexion anonyme"
        )

        # DÃ©finir les droits Ã  risque Ã©levÃ©
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

            # Obtenir les permissions NTFS (limiter la rÃ©cursivitÃ© pour Ã©viter les boucles infinies)
            if ($Recurse) {
                # Limiter la profondeur de rÃ©cursion
                $permissions = Get-NTFSPermission -Path $Path -Recurse $false -IncludeInherited $true

                # Traiter manuellement le premier niveau de rÃ©cursion
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

                # 1. DÃ©tecter les permissions Ã  risque Ã©levÃ© pour des groupes Ã  risque Ã©levÃ©
                foreach ($permission in $currentPermissions) {
                    if ($highRiskGroups -contains $permission.IdentityReference -and
                        $permission.AccessControlType -eq "Allow") {

                        $riskyRights = $permission.Rights | Where-Object { $highRiskRights -contains $_ }

                        if ($riskyRights) {
                            $anomalies += [PSCustomObject]@{
                                Path = $currentPath
                                AnomalyType = "HighRiskPermission"
                                Severity = "Ã‰levÃ©e"
                                Description = "Permissions Ã  risque Ã©levÃ© ($($riskyRights -join ', ')) accordÃ©es Ã  un groupe Ã  risque Ã©levÃ© ($($permission.IdentityReference))"
                                IdentityReference = $permission.IdentityReference
                                Rights = $permission.Rights
                                Recommendation = "Restreindre les permissions pour ce groupe ou utiliser un groupe plus spÃ©cifique"
                            }
                        }
                    }
                }

                # 2. DÃ©tecter les conflits de permissions (Allow vs Deny)
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
                                    Description = "Conflit de permissions pour $($allowRule.IdentityReference): les mÃªmes droits ($($commonRights.InputObject -join ', ')) sont Ã  la fois autorisÃ©s et refusÃ©s"
                                    IdentityReference = $allowRule.IdentityReference
                                    Rights = $commonRights.InputObject
                                    Recommendation = "RÃ©soudre le conflit en supprimant l'une des rÃ¨gles contradictoires"
                                }
                            }
                        }
                    }
                }

                # 3. DÃ©tecter les permissions redondantes
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
                                    Description = "Permissions redondantes pour $($identityGroup.Name) ($($typeGroup.Name)): $($typeGroup.Count) rÃ¨gles"
                                    IdentityReference = $identityGroup.Name
                                    Rights = ($typeGroup.Group | ForEach-Object { $_.Rights }) -join ', '
                                    Recommendation = "Consolider les rÃ¨gles redondantes en une seule rÃ¨gle"
                                }
                            }
                        }
                    }
                }

                # 4. DÃ©tecter les hÃ©ritages interrompus
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
                                Description = "L'hÃ©ritage des permissions est interrompu pour ce dossier"
                                IdentityReference = "N/A"
                                Rights = "N/A"
                                Recommendation = "VÃ©rifier si l'interruption de l'hÃ©ritage est intentionnelle"
                            }
                        }
                    }
                }
            }

            return $anomalies
        }
        catch {
            Write-Error "Erreur lors de la dÃ©tection des anomalies de permissions NTFS pour '$Path': $($_.Exception.Message)"
        }
    }
}

# Fonction pour analyser l'hÃ©ritage des permissions NTFS
function Get-NTFSPermissionInheritance {
    <#
    .SYNOPSIS
        Analyse l'hÃ©ritage des permissions NTFS pour un fichier ou dossier.

    .DESCRIPTION
        Cette fonction analyse en dÃ©tail l'hÃ©ritage des permissions NTFS d'un fichier ou dossier,
        y compris les sources d'hÃ©ritage, les interruptions d'hÃ©ritage, et les permissions explicites.

    .PARAMETER Path
        Le chemin du fichier ou dossier Ã  analyser.

    .PARAMETER Recurse
        Indique si l'analyse doit Ãªtre rÃ©cursive pour les dossiers.

    .EXAMPLE
        Get-NTFSPermissionInheritance -Path "C:\Data" -Recurse $false

    .OUTPUTS
        [PSCustomObject] avec des informations dÃ©taillÃ©es sur l'hÃ©ritage des permissions NTFS.
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
        # VÃ©rifier si le chemin existe
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

        # Fonction pour vÃ©rifier si l'hÃ©ritage est activÃ©
        function Test-InheritanceEnabled {
            param (
                [System.Security.AccessControl.FileSystemSecurity]$Acl
            )

            return -not $Acl.AreAccessRulesProtected
        }
    }

    process {
        try {
            # VÃ©rifier si on a atteint la profondeur maximale
            if ($CurrentDepth -ge $MaxDepth) {
                Write-Verbose "Profondeur maximale atteinte ($MaxDepth) pour le chemin '$Path'"
                return @()
            }

            $results = @()

            # Obtenir les ACL de l'objet
            $acl = Get-Acl -Path $Path

            # Obtenir le type d'objet
            $objectType = Get-ObjectType -Path $Path

            # VÃ©rifier si l'hÃ©ritage est activÃ©
            $inheritanceEnabled = Test-InheritanceEnabled -Acl $acl

            # Obtenir le chemin parent
            $parentPath = Get-ParentPath -Path $Path

            # CrÃ©er un objet pour les informations d'hÃ©ritage
            $inheritanceInfo = [PSCustomObject]@{
                Path = $Path
                ObjectType = $objectType
                InheritanceEnabled = $inheritanceEnabled
                ParentPath = $parentPath
                ExplicitPermissions = @()
                InheritedPermissions = @()
                InheritanceBreakPoints = @()
            }

            # Analyser chaque rÃ¨gle d'accÃ¨s
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

            # VÃ©rifier s'il y a une interruption d'hÃ©ritage
            if (-not $inheritanceEnabled) {
                $inheritanceInfo.InheritanceBreakPoints += $Path
            }

            # Ajouter les informations d'hÃ©ritage aux rÃ©sultats
            $results += $inheritanceInfo

            # Si rÃ©cursif est demandÃ© et que c'est un dossier, analyser les sous-dossiers et fichiers
            # Mais seulement si on n'a pas atteint la profondeur maximale
            if ($Recurse -and $objectType -eq "Dossier" -and $CurrentDepth -lt $MaxDepth) {
                # Limiter le nombre d'Ã©lÃ©ments Ã  traiter pour Ã©viter les boucles infinies
                $childItems = Get-ChildItem -Path $Path -Force | Select-Object -First 10

                foreach ($childItem in $childItems) {
                    # Ã‰viter les liens symboliques qui pourraient crÃ©er des boucles
                    if (($childItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne [System.IO.FileAttributes]::ReparsePoint) {
                        $childResults = Get-NTFSPermissionInheritance -Path $childItem.FullName -Recurse $false -MaxDepth $MaxDepth -CurrentDepth ($CurrentDepth + 1)
                        $results += $childResults
                    }
                }
            }

            return $results
        }
        catch {
            Write-Error "Erreur lors de l'analyse de l'hÃ©ritage des permissions NTFS pour '$Path': $($_.Exception.Message)"
        }
    }
}

# Fonction pour analyser les propriÃ©taires et groupes des fichiers et dossiers
function Get-NTFSOwnershipInfo {
    <#
    .SYNOPSIS
        Analyse les propriÃ©taires et groupes principaux des fichiers et dossiers.

    .DESCRIPTION
        Cette fonction analyse en dÃ©tail les propriÃ©taires et groupes principaux des fichiers et dossiers,
        y compris les SID, les domaines, et les types de comptes.

    .PARAMETER Path
        Le chemin du fichier ou dossier Ã  analyser.

    .PARAMETER Recurse
        Indique si l'analyse doit Ãªtre rÃ©cursive pour les dossiers.

    .EXAMPLE
        Get-NTFSOwnershipInfo -Path "C:\Data" -Recurse $false

    .OUTPUTS
        [PSCustomObject] avec des informations dÃ©taillÃ©es sur les propriÃ©taires et groupes.
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
        # VÃ©rifier si le chemin existe
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

        # Fonction pour obtenir les informations dÃ©taillÃ©es sur un compte
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
                        $accountName = $AccountName  # Garder le SID si la traduction Ã©choue
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

                # DÃ©terminer le type de compte
                $accountType = "Inconnu"

                if ($username -eq "SYSTEM" -or $username -eq "SystÃ¨me") {
                    $accountType = "SystÃ¨me"
                } elseif ($username -eq "Administrators" -or $username -eq "Administrateurs") {
                    $accountType = "Groupe d'administrateurs"
                } elseif ($username -eq "Administrator" -or $username -eq "Administrateur") {
                    $accountType = "Administrateur local"
                } elseif ($username -eq "Users" -or $username -eq "Utilisateurs") {
                    $accountType = "Groupe d'utilisateurs"
                } elseif ($username -eq "Everyone" -or $username -eq "Tout le monde") {
                    $accountType = "Groupe spÃ©cial"
                } elseif ($domain -eq "NT AUTHORITY" -or $domain -eq "AUTORITE NT") {
                    $accountType = "Compte systÃ¨me"
                } elseif ($domain -eq "BUILTIN") {
                    $accountType = "Groupe intÃ©grÃ©"
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
            # VÃ©rifier si on a atteint la profondeur maximale
            if ($CurrentDepth -ge $MaxDepth) {
                Write-Verbose "Profondeur maximale atteinte ($MaxDepth) pour le chemin '$Path'"
                return @()
            }

            $results = @()

            # Obtenir les ACL de l'objet
            $acl = Get-Acl -Path $Path

            # Obtenir le type d'objet
            $objectType = Get-ObjectType -Path $Path

            # Obtenir les informations sur le propriÃ©taire
            $ownerInfo = Get-AccountInfo -AccountName $acl.Owner

            # Obtenir les informations sur le groupe principal (si disponible)
            $groupInfo = $null
            if ($acl.Group) {
                $groupInfo = Get-AccountInfo -AccountName $acl.Group
            }

            # CrÃ©er un objet pour les informations de propriÃ©tÃ©
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

            # VÃ©rifier si l'utilisateur actuel peut changer le propriÃ©taire
            try {
                $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
                $currentUserInfo = Get-AccountInfo -AccountName $currentUser

                # VÃ©rifier si l'utilisateur actuel est le propriÃ©taire ou un administrateur
                $isOwner = $ownerInfo.FullName -eq $currentUserInfo.FullName
                $isAdmin = [System.Security.Principal.WindowsIdentity]::GetCurrent().Groups |
                           Where-Object { $_.Value -match "S-1-5-32-544" } |
                           Select-Object -First 1

                $ownershipInfo.CanChangeOwner = $isOwner -or ($isAdmin -ne $null)
            } catch {
                $ownershipInfo.CanChangeOwner = $false
            }

            # Ã‰valuer les risques de sÃ©curitÃ© liÃ©s au propriÃ©taire
            if ($ownerInfo.AccountType -eq "Groupe spÃ©cial" -or
                $ownerInfo.Username -eq "Everyone" -or
                $ownerInfo.Username -eq "Tout le monde" -or
                $ownerInfo.Username -eq "Users" -or
                $ownerInfo.Username -eq "Utilisateurs") {

                $ownershipInfo.SecurityRisk = $true
                $ownershipInfo.RiskLevel = "Ã‰levÃ©"
                $ownershipInfo.Recommendations += "Changer le propriÃ©taire pour un compte administrateur ou systÃ¨me"
                $ownershipInfo.RecommendedOwner = "Administrators"
            } elseif ($ownerInfo.AccountType -eq "Compte local" -and
                      $ownerInfo.Username -ne "Administrator" -and
                      $ownerInfo.Username -ne "Administrateur") {

                $ownershipInfo.SecurityRisk = $true
                $ownershipInfo.RiskLevel = "Moyen"
                $ownershipInfo.Recommendations += "VÃ©rifier si ce compte local devrait Ãªtre propriÃ©taire de cette ressource"
                $ownershipInfo.RecommendedOwner = "Administrators"
            }

            # Ajouter les informations de propriÃ©tÃ© aux rÃ©sultats
            $results += $ownershipInfo

            # Si rÃ©cursif est demandÃ© et que c'est un dossier, analyser les sous-dossiers et fichiers
            # Mais seulement si on n'a pas atteint la profondeur maximale
            if ($Recurse -and $objectType -eq "Dossier" -and $CurrentDepth -lt $MaxDepth) {
                # Limiter le nombre d'Ã©lÃ©ments Ã  traiter pour Ã©viter les boucles infinies
                $childItems = Get-ChildItem -Path $Path -Force | Select-Object -First 10

                foreach ($childItem in $childItems) {
                    # Ã‰viter les liens symboliques qui pourraient crÃ©er des boucles
                    if (($childItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne [System.IO.FileAttributes]::ReparsePoint) {
                        $childResults = Get-NTFSOwnershipInfo -Path $childItem.FullName -Recurse $false -MaxDepth $MaxDepth -CurrentDepth ($CurrentDepth + 1)
                        $results += $childResults
                    }
                }
            }

            return $results
        }
        catch {
            Write-Error "Erreur lors de l'analyse des propriÃ©taires et groupes pour '$Path': $($_.Exception.Message)"
        }
    }
}

# Fonction pour gÃ©nÃ©rer un rapport de permissions NTFS
function New-NTFSPermissionReport {
    <#
    .SYNOPSIS
        GÃ©nÃ¨re un rapport dÃ©taillÃ© des permissions NTFS pour un fichier ou dossier.

    .DESCRIPTION
        Cette fonction gÃ©nÃ¨re un rapport dÃ©taillÃ© des permissions NTFS pour un fichier ou dossier,
        y compris les permissions, les hÃ©ritages, les propriÃ©taires, et les anomalies dÃ©tectÃ©es.

    .PARAMETER Path
        Le chemin du fichier ou dossier Ã  analyser.

    .PARAMETER Recurse
        Indique si l'analyse doit Ãªtre rÃ©cursive pour les dossiers.

    .PARAMETER OutputFormat
        Le format de sortie du rapport (Text, CSV, HTML, JSON).

    .PARAMETER OutputPath
        Le chemin oÃ¹ enregistrer le rapport. Si non spÃ©cifiÃ©, le rapport est affichÃ© Ã  l'Ã©cran.

    .EXAMPLE
        New-NTFSPermissionReport -Path "C:\Data" -Recurse $true -OutputFormat "HTML" -OutputPath "C:\Reports\permissions.html"

    .OUTPUTS
        Un rapport de permissions au format spÃ©cifiÃ©.
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
        # VÃ©rifier si le chemin existe
        if (-not (Test-Path -Path $Path)) {
            Write-Error "Le chemin '$Path' n'existe pas."
            return
        }

        # Fonction pour gÃ©nÃ©rer un rapport au format texte
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

RÃ‰SUMÃ‰
-----------------------------------------------------------------------
Nombre total d'objets analysÃ©s: $($Data.Summary.TotalObjects)
Fichiers: $($Data.Summary.Files)
Dossiers: $($Data.Summary.Directories)
Anomalies dÃ©tectÃ©es: $($Data.Summary.Anomalies)
Niveau de risque global: $($Data.Summary.RiskLevel)
=======================================================================

DÃ‰TAILS DES PERMISSIONS
-----------------------------------------------------------------------
"@

            foreach ($item in $Data.Permissions) {
                $report += @"

Objet: $($item.Path) ($($item.ObjectType))
PropriÃ©taire: $($item.Owner.FullName) ($($item.Owner.AccountType))
HÃ©ritage activÃ©: $($item.InheritanceEnabled)

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

Permissions hÃ©ritÃ©es:
"@

                if ($item.InheritedPermissions.Count -eq 0) {
                    $report += "  Aucune permission hÃ©ritÃ©e`n"
                } else {
                    foreach ($perm in $item.InheritedPermissions) {
                        $report += "  $($perm.IdentityReference) : $($perm.AccessControlType) $($perm.FileSystemRights)`n"
                    }
                }

                $report += "`n"
            }

            $report += @"
ANOMALIES DÃ‰TECTÃ‰ES
-----------------------------------------------------------------------
"@

            if ($Data.Anomalies.Count -eq 0) {
                $report += "Aucune anomalie dÃ©tectÃ©e.`n"
            } else {
                foreach ($anomaly in $Data.Anomalies) {
                    $report += @"

Chemin: $($anomaly.Path)
Type d'anomalie: $($anomaly.AnomalyType)
SÃ©vÃ©ritÃ©: $($anomaly.Severity)
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

        # Fonction pour gÃ©nÃ©rer un rapport au format HTML
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
            <h2>RÃ©sumÃ©</h2>
            <p>Nombre total d'objets analysÃ©s: $($Data.Summary.TotalObjects)</p>
            <p>Fichiers: $($Data.Summary.Files)</p>
            <p>Dossiers: $($Data.Summary.Directories)</p>
            <p>Anomalies dÃ©tectÃ©es: $($Data.Summary.Anomalies)</p>
            <p>Niveau de risque global: $($Data.Summary.RiskLevel)</p>
        </div>

        <h2>DÃ©tails des permissions</h2>
"@

            $htmlItems = ""
            foreach ($item in $Data.Permissions) {
                $htmlItems += @"
        <div class="item">
            <h3>$($item.Path) ($($item.ObjectType))</h3>
            <p><strong>PropriÃ©taire:</strong> $($item.Owner.FullName) ($($item.Owner.AccountType))</p>
            <p><strong>HÃ©ritage activÃ©:</strong> $($item.InheritanceEnabled)</p>

            <h4>Permissions explicites</h4>
"@

                if ($item.ExplicitPermissions.Count -eq 0) {
                    $htmlItems += "            <p>Aucune permission explicite</p>`n"
                } else {
                    $htmlItems += @"
            <table>
                <tr>
                    <th>IdentitÃ©</th>
                    <th>Type d'accÃ¨s</th>
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

            <h4>Permissions hÃ©ritÃ©es</h4>
"@

                if ($item.InheritedPermissions.Count -eq 0) {
                    $htmlItems += "            <p>Aucune permission hÃ©ritÃ©e</p>`n"
                } else {
                    $htmlItems += @"
            <table>
                <tr>
                    <th>IdentitÃ©</th>
                    <th>Type d'accÃ¨s</th>
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

        <h2>Anomalies dÃ©tectÃ©es</h2>
"@

            if ($Data.Anomalies.Count -eq 0) {
                $htmlAnomalies += "        <p>Aucune anomalie dÃ©tectÃ©e.</p>`n"
            } else {
                foreach ($anomaly in $Data.Anomalies) {
                    $severityClass = "severity-info"
                    if ($anomaly.Severity -eq "Ã‰levÃ©e") {
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
            <p><strong>SÃ©vÃ©ritÃ©:</strong> $($anomaly.Severity)</p>
            <p><strong>Description:</strong> $($anomaly.Description)</p>
            <p><strong>Recommandation:</strong> $($anomaly.Recommendation)</p>
        </div>
"@
                }
            }

            $htmlFooter = @"

        <div class="footer">
            <p>Rapport gÃ©nÃ©rÃ© le $($Data.AnalysisDate) avec ACLAnalyzer</p>
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
            # Collecter les donnÃ©es pour le rapport
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

            # Obtenir les informations d'hÃ©ritage
            $inheritanceInfo = Get-NTFSPermissionInheritance -Path $Path -Recurse $Recurse

            # Obtenir les informations de propriÃ©tÃ©
            $ownershipInfo = Get-NTFSOwnershipInfo -Path $Path -Recurse $Recurse

            # Obtenir les anomalies
            $anomalies = Find-NTFSPermissionAnomaly -Path $Path -Recurse $Recurse

            # Regrouper les permissions par chemin
            $permissionsByPath = $permissions | Group-Object -Property Path

            # Regrouper les informations d'hÃ©ritage par chemin
            $inheritanceByPath = $inheritanceInfo | Group-Object -Property Path

            # Regrouper les informations de propriÃ©tÃ© par chemin
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

                # Mettre Ã  jour les statistiques
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

            # DÃ©terminer le niveau de risque global
            $highRiskCount = ($anomalies | Where-Object { $_.Severity -eq "Ã‰levÃ©e" }).Count
            $mediumRiskCount = ($anomalies | Where-Object { $_.Severity -eq "Moyenne" }).Count

            if ($highRiskCount -gt 0) {
                $reportData.Summary.RiskLevel = "Ã‰levÃ©"
            } elseif ($mediumRiskCount -gt 0) {
                $reportData.Summary.RiskLevel = "Moyen"
            } else {
                $reportData.Summary.RiskLevel = "Faible"
            }

            # GÃ©nÃ©rer le rapport au format demandÃ©
            $reportContent = $null

            switch ($OutputFormat) {
                "Text" {
                    $reportContent = ConvertTo-TextReport -Data $reportData
                }
                "CSV" {
                    # CrÃ©er un tableau d'objets pour l'export CSV
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
                Write-Host "Rapport enregistrÃ© dans '$OutputPath'."
            } else {
                return $reportContent
            }
        }
        catch {
            Write-Error "Erreur lors de la gÃ©nÃ©ration du rapport de permissions NTFS pour '$Path': $($_.Exception.Message)"
        }
    }
}

# Fonction pour corriger automatiquement les anomalies de permissions NTFS
function Repair-NTFSPermissionAnomaly {
    <#
    .SYNOPSIS
        Corrige automatiquement les anomalies de permissions NTFS dÃ©tectÃ©es.

    .DESCRIPTION
        Cette fonction corrige automatiquement les anomalies de permissions NTFS dÃ©tectÃ©es
        par la fonction Find-NTFSPermissionAnomaly, comme les permissions trop permissives,
        les conflits, ou les hÃ©ritages interrompus.

    .PARAMETER Path
        Le chemin du fichier ou dossier Ã  corriger.

    .PARAMETER AnomalyType
        Le type d'anomalie Ã  corriger. Si non spÃ©cifiÃ©, toutes les anomalies seront corrigÃ©es.
        Valeurs possibles : "HighRiskPermission", "PermissionConflict", "RedundantPermission", "InheritanceBreak".

    .PARAMETER WhatIf
        Indique si la fonction doit simuler les corrections sans les appliquer.

    .PARAMETER Force
        Force l'application des corrections sans demander de confirmation.

    .EXAMPLE
        Repair-NTFSPermissionAnomaly -Path "C:\Data" -AnomalyType "HighRiskPermission" -WhatIf

    .OUTPUTS
        [PSCustomObject] avec des informations sur les corrections effectuÃ©es.
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
        # VÃ©rifier si le chemin existe
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

            # DÃ©tecter les anomalies
            $anomalies = Find-NTFSPermissionAnomaly -Path $Path

            # Filtrer les anomalies par type si spÃ©cifiÃ©
            if ($AnomalyType -ne "All") {
                $anomalies = $anomalies | Where-Object { $_.AnomalyType -eq $AnomalyType }
            }

            if (-not $anomalies) {
                Write-Host "Aucune anomalie Ã  corriger pour le chemin '$Path'."
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

                        # Trouver la rÃ¨gle Ã  risque Ã©levÃ©
                        $highRiskRule = $itemAcl.Access | Where-Object {
                            $_.IdentityReference.Value -eq $anomaly.IdentityReference -and
                            $_.FileSystemRights.ToString() -match $anomaly.Rights
                        }

                        if ($highRiskRule) {
                            $correctionDescription = "Suppression de la permission Ã  risque Ã©levÃ© pour $($anomaly.IdentityReference)"

                            if ($Force -or $PSCmdlet.ShouldProcess($anomaly.Path, $correctionDescription)) {
                                # Supprimer la rÃ¨gle Ã  risque Ã©levÃ©
                                $itemAcl.RemoveAccessRule($highRiskRule)

                                # Ajouter une rÃ¨gle plus restrictive si nÃ©cessaire
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
                                $correctionInfo.CorrectionDescription = "$correctionDescription (non appliquÃ©)"
                            }
                        } else {
                            $correctionInfo.CorrectionDescription = "RÃ¨gle Ã  risque Ã©levÃ© non trouvÃ©e"
                        }
                    }

                    "PermissionConflict" {
                        # Obtenir l'ACL actuelle du chemin de l'anomalie
                        $itemAcl = Get-Acl -Path $anomaly.Path

                        # Trouver les rÃ¨gles en conflit
                        $conflictRules = $itemAcl.Access | Where-Object {
                            $_.IdentityReference.Value -eq $anomaly.IdentityReference
                        }

                        if ($conflictRules) {
                            $correctionDescription = "RÃ©solution du conflit de permissions pour $($anomaly.IdentityReference)"

                            if ($Force -or $PSCmdlet.ShouldProcess($anomaly.Path, $correctionDescription)) {
                                # Supprimer toutes les rÃ¨gles en conflit
                                foreach ($rule in $conflictRules) {
                                    $itemAcl.RemoveAccessRule($rule)
                                }

                                # Ajouter une nouvelle rÃ¨gle consolidÃ©e
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
                                $correctionInfo.CorrectionDescription = "$correctionDescription en consolidant les rÃ¨gles"
                            } else {
                                $correctionInfo.CorrectionDescription = "$correctionDescription (non appliquÃ©)"
                            }
                        } else {
                            $correctionInfo.CorrectionDescription = "RÃ¨gles en conflit non trouvÃ©es"
                        }
                    }

                    "RedundantPermission" {
                        # Obtenir l'ACL actuelle du chemin de l'anomalie
                        $itemAcl = Get-Acl -Path $anomaly.Path

                        # Trouver les rÃ¨gles redondantes
                        $redundantRules = $itemAcl.Access | Where-Object {
                            $_.IdentityReference.Value -eq $anomaly.IdentityReference
                        }

                        if ($redundantRules -and $redundantRules.Count -gt 1) {
                            $correctionDescription = "Consolidation des permissions redondantes pour $($anomaly.IdentityReference)"

                            if ($Force -or $PSCmdlet.ShouldProcess($anomaly.Path, $correctionDescription)) {
                                # Supprimer toutes les rÃ¨gles redondantes
                                foreach ($rule in $redundantRules) {
                                    $itemAcl.RemoveAccessRule($rule)
                                }

                                # DÃ©terminer les droits combinÃ©s
                                $combinedRights = [System.Security.AccessControl.FileSystemRights]::None
                                foreach ($rule in $redundantRules) {
                                    if ($rule.AccessControlType -eq [System.Security.AccessControl.AccessControlType]::Allow) {
                                        $combinedRights = $combinedRights -bor $rule.FileSystemRights
                                    }
                                }

                                # Ajouter une nouvelle rÃ¨gle consolidÃ©e
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
                                $correctionInfo.CorrectionDescription = "$correctionDescription en une seule rÃ¨gle"
                            } else {
                                $correctionInfo.CorrectionDescription = "$correctionDescription (non appliquÃ©)"
                            }
                        } else {
                            $correctionInfo.CorrectionDescription = "RÃ¨gles redondantes non trouvÃ©es"
                        }
                    }

                    "InheritanceBreak" {
                        # Obtenir l'ACL actuelle du chemin de l'anomalie
                        $itemAcl = Get-Acl -Path $anomaly.Path

                        $correctionDescription = "RÃ©activation de l'hÃ©ritage des permissions"

                        if ($Force -or $PSCmdlet.ShouldProcess($anomaly.Path, $correctionDescription)) {
                            # RÃ©activer l'hÃ©ritage
                            $itemAcl.SetAccessRuleProtection($false, $true)  # Activer l'hÃ©ritage et conserver les rÃ¨gles existantes
                            Set-Acl -Path $anomaly.Path -AclObject $itemAcl

                            $correctionInfo.CorrectionApplied = $true
                            $correctionInfo.CorrectionDescription = $correctionDescription
                        } else {
                            $correctionInfo.CorrectionDescription = "$correctionDescription (non appliquÃ©)"
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
        les diffÃ©rences, comme les permissions manquantes, supplÃ©mentaires ou modifiÃ©es.

    .PARAMETER ReferencePath
        Le chemin de rÃ©fÃ©rence pour la comparaison.

    .PARAMETER DifferencePath
        Le chemin Ã  comparer avec la rÃ©fÃ©rence.

    .PARAMETER IncludeInherited
        Indique si les permissions hÃ©ritÃ©es doivent Ãªtre incluses dans la comparaison.

    .EXAMPLE
        Compare-NTFSPermission -ReferencePath "C:\Data\Reference" -DifferencePath "C:\Data\Target" -IncludeInherited $true

    .OUTPUTS
        [PSCustomObject] avec des informations sur les diffÃ©rences de permissions.
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
        # VÃ©rifier si les chemins existent
        if (-not (Test-Path -Path $ReferencePath)) {
            Write-Error "Le chemin de rÃ©fÃ©rence '$ReferencePath' n'existe pas."
            return
        }

        if (-not (Test-Path -Path $DifferencePath)) {
            Write-Error "Le chemin Ã  comparer '$DifferencePath' n'existe pas."
            return
        }
    }

    process {
        try {
            # Obtenir les permissions des deux chemins
            $referencePermissions = Get-NTFSPermission -Path $ReferencePath -Recurse $false -IncludeInherited $IncludeInherited
            $differencePermissions = Get-NTFSPermission -Path $DifferencePath -Recurse $false -IncludeInherited $IncludeInherited

            # CrÃ©er des collections pour les diffÃ©rences
            $missingPermissions = @()
            $additionalPermissions = @()
            $modifiedPermissions = @()

            # Comparer les permissions de rÃ©fÃ©rence avec les permissions de diffÃ©rence
            foreach ($refPerm in $referencePermissions) {
                $matchingPerm = $differencePermissions | Where-Object {
                    $_.IdentityReference -eq $refPerm.IdentityReference -and
                    $_.AccessControlType -eq $refPerm.AccessControlType
                }

                if (-not $matchingPerm) {
                    # Permission manquante dans le chemin de diffÃ©rence
                    $missingPermissions += [PSCustomObject]@{
                        IdentityReference = $refPerm.IdentityReference
                        AccessControlType = $refPerm.AccessControlType
                        FileSystemRights = $refPerm.FileSystemRights
                        IsInherited = $refPerm.IsInherited
                    }
                } elseif ($matchingPerm.FileSystemRights -ne $refPerm.FileSystemRights) {
                    # Permission modifiÃ©e
                    $modifiedPermissions += [PSCustomObject]@{
                        IdentityReference = $refPerm.IdentityReference
                        AccessControlType = $refPerm.AccessControlType
                        ReferenceRights = $refPerm.FileSystemRights
                        DifferenceRights = $matchingPerm.FileSystemRights
                        IsInherited = $refPerm.IsInherited
                    }
                }
            }

            # Trouver les permissions supplÃ©mentaires dans le chemin de diffÃ©rence
            foreach ($diffPerm in $differencePermissions) {
                $matchingPerm = $referencePermissions | Where-Object {
                    $_.IdentityReference -eq $diffPerm.IdentityReference -and
                    $_.AccessControlType -eq $diffPerm.AccessControlType
                }

                if (-not $matchingPerm) {
                    # Permission supplÃ©mentaire dans le chemin de diffÃ©rence
                    $additionalPermissions += [PSCustomObject]@{
                        IdentityReference = $diffPerm.IdentityReference
                        AccessControlType = $diffPerm.AccessControlType
                        FileSystemRights = $diffPerm.FileSystemRights
                        IsInherited = $diffPerm.IsInherited
                    }
                }
            }

            # CrÃ©er l'objet de rÃ©sultat
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
        permettant de sauvegarder une configuration de sÃ©curitÃ© pour une restauration ultÃ©rieure.

    .PARAMETER Path
        Le chemin du fichier ou dossier dont les permissions doivent Ãªtre exportÃ©es.

    .PARAMETER OutputPath
        Le chemin du fichier de sortie oÃ¹ les permissions seront exportÃ©es.

    .PARAMETER Format
        Le format du fichier d'exportation. Valeurs possibles : "JSON", "XML", "CSV".

    .PARAMETER Recurse
        Indique si l'exportation doit Ãªtre rÃ©cursive pour les dossiers.

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
        # VÃ©rifier si le chemin existe
        if (-not (Test-Path -Path $Path)) {
            Write-Error "Le chemin '$Path' n'existe pas."
            return
        }

        # VÃ©rifier si le dossier de sortie existe
        $outputFolder = Split-Path -Parent $OutputPath
        if (-not (Test-Path -Path $outputFolder)) {
            try {
                New-Item -Path $outputFolder -ItemType Directory -Force | Out-Null
            } catch {
                Write-Error "Impossible de crÃ©er le dossier de sortie '$outputFolder': $($_.Exception.Message)"
                return
            }
        }
    }

    process {
        try {
            # Obtenir les permissions NTFS
            $permissions = Get-NTFSPermission -Path $Path -Recurse $Recurse -IncludeInherited $true

            # CrÃ©er un objet d'exportation avec des mÃ©tadonnÃ©es
            $exportObject = [PSCustomObject]@{
                ExportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                SourcePath = $Path
                Recurse = $Recurse
                Permissions = $permissions
            }

            # Exporter selon le format spÃ©cifiÃ©
            switch ($Format) {
                "JSON" {
                    $exportObject | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8
                }
                "XML" {
                    $exportObject | Export-Clixml -Path $OutputPath -Encoding utf8
                }
                "CSV" {
                    # Pour CSV, nous devons aplatir les donnÃ©es
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

            Write-Host "Permissions NTFS exportÃ©es avec succÃ¨s vers '$OutputPath'."
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
        Importe les permissions NTFS depuis un fichier et les applique Ã  un chemin.

    .DESCRIPTION
        Cette fonction importe les permissions NTFS depuis un fichier JSON, XML ou CSV
        et les applique Ã  un chemin spÃ©cifiÃ©, permettant de restaurer une configuration de sÃ©curitÃ©.

    .PARAMETER InputPath
        Le chemin du fichier d'entrÃ©e contenant les permissions Ã  importer.

    .PARAMETER TargetPath
        Le chemin du fichier ou dossier auquel les permissions doivent Ãªtre appliquÃ©es.
        Si non spÃ©cifiÃ©, le chemin source original sera utilisÃ©.

    .PARAMETER Format
        Le format du fichier d'importation. Valeurs possibles : "JSON", "XML", "CSV".

    .PARAMETER WhatIf
        Indique si la fonction doit simuler l'importation sans appliquer les permissions.

    .PARAMETER Force
        Force l'application des permissions sans demander de confirmation.

    .EXAMPLE
        Import-NTFSPermission -InputPath "C:\Backup\DataPermissions.json" -TargetPath "D:\Data" -Format "JSON" -WhatIf

    .OUTPUTS
        [PSCustomObject] avec des informations sur les permissions appliquÃ©es.
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
        # VÃ©rifier si le fichier d'entrÃ©e existe
        if (-not (Test-Path -Path $InputPath)) {
            Write-Error "Le fichier d'entrÃ©e '$InputPath' n'existe pas."
            return
        }
    }

    process {
        try {
            # Importer les permissions selon le format spÃ©cifiÃ©
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

            # DÃ©terminer le chemin cible
            $actualTargetPath = if ($TargetPath) { $TargetPath } else { $importObject.SourcePath }

            # VÃ©rifier si le chemin cible existe
            if (-not (Test-Path -Path $actualTargetPath)) {
                Write-Error "Le chemin cible '$actualTargetPath' n'existe pas."
                return
            }

            $results = @()

            # Appliquer les permissions
            foreach ($perm in $importObject.Permissions) {
                # DÃ©terminer le chemin relatif et le chemin cible complet
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

                # VÃ©rifier si le chemin cible existe
                if (-not (Test-Path -Path $targetItemPath)) {
                    Write-Warning "Le chemin cible '$targetItemPath' n'existe pas et sera ignorÃ©."
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

                # Appliquer la permission si ce n'est pas une permission hÃ©ritÃ©e
                if (-not $perm.IsInherited) {
                    $description = "Application de la permission '$($perm.FileSystemRights)' pour '$($perm.IdentityReference)' sur '$targetItemPath'"

                    if ($Force -or $PSCmdlet.ShouldProcess($targetItemPath, $description)) {
                        try {
                            # Obtenir l'ACL actuelle
                            $acl = Get-Acl -Path $targetItemPath

                            # CrÃ©er la rÃ¨gle d'accÃ¨s
                            $identity = New-Object System.Security.Principal.NTAccount($perm.IdentityReference)
                            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                                $identity,
                                $perm.FileSystemRights,
                                $perm.InheritanceFlags,
                                $perm.PropagationFlags,
                                $perm.AccessControlType
                            )

                            # Ajouter la rÃ¨gle et appliquer l'ACL
                            $acl.AddAccessRule($rule)
                            Set-Acl -Path $targetItemPath -AclObject $acl

                            $permissionInfo.Applied = $true
                        } catch {
                            Write-Warning "Erreur lors de l'application de la permission sur '$targetItemPath': $($_.Exception.Message)"
                        }
                    }
                } else {
                    $permissionInfo.Applied = "IgnorÃ© (permission hÃ©ritÃ©e)"
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

# Exporter les fonctions si le script est importÃ© comme module
if ($MyInvocation.Line -match '^\. ') {
    # Le script est sourcÃ© directement, pas besoin d'exporter
} elseif ($MyInvocation.MyCommand.Path -eq $null) {
    # Le script est exÃ©cutÃ© directement, pas besoin d'exporter
} else {
    # Le script est importÃ© comme module, exporter les fonctions
    Export-ModuleMember -Function Get-NTFSPermission, Find-NTFSPermissionAnomaly, Get-NTFSPermissionInheritance, Get-NTFSOwnershipInfo, New-NTFSPermissionReport, Repair-NTFSPermissionAnomaly, Compare-NTFSPermission, Export-NTFSPermission, Import-NTFSPermission
}
