<#
.SYNOPSIS
    Outils d'analyse des listes de contrôle d'accès (ACL) pour les clés de registre Windows.

.DESCRIPTION
    Ce module fournit des fonctions pour analyser, comparer et visualiser les listes de contrôle d'accès (ACL)
    sur les clés de registre Windows, permettant d'identifier les problèmes de sécurité potentiels.

.NOTES
    Nom du fichier : RegistryACLAnalyzer.ps1
    Auteur        : Augment Code
    Version       : 1.0
    Prérequis     : PowerShell 5.1 ou supérieur
#>

#Requires -Version 5.1

# Fonction pour analyser les permissions de registre
function Get-RegistryPermission {
    <#
    .SYNOPSIS
        Analyse les permissions d'une clé de registre.

    .DESCRIPTION
        Cette fonction analyse en détail les permissions d'une clé de registre,
        y compris les droits spécifiques, les héritages, et les identités associées.

    .PARAMETER Path
        Le chemin de la clé de registre à analyser (ex: "HKLM:\SOFTWARE\Microsoft").

    .PARAMETER Recurse
        Indique si l'analyse doit être récursive pour les sous-clés.

    .PARAMETER IncludeInherited
        Indique si les permissions héritées doivent être incluses dans l'analyse.

    .PARAMETER MaxDepth
        Profondeur maximale de récursion pour éviter les boucles infinies.

    .EXAMPLE
        Get-RegistryPermission -Path "HKLM:\SOFTWARE\Microsoft" -Recurse $false -IncludeInherited $true

    .OUTPUTS
        [PSCustomObject] avec des informations détaillées sur les permissions de registre.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [bool]$Recurse = $false,

        [Parameter(Mandatory = $false)]
        [bool]$IncludeInherited = $true,

        [Parameter(Mandatory = $false, DontShow)]
        [int]$MaxDepth = 3,

        [Parameter(Mandatory = $false, DontShow)]
        [int]$CurrentDepth = 0
    )

    begin {
        # Vérifier si le chemin existe
        if (-not (Test-Path -Path $Path)) {
            Write-Error "Le chemin de registre '$Path' n'existe pas."
            return
        }

        # Fonction pour convertir les droits d'accès en chaîne lisible
        function ConvertTo-ReadableRegistryRights {
            param (
                [System.Security.AccessControl.RegistryRights]$Rights
            )

            $readableRights = @()

            # Droits de base
            $basicRights = @{
                "FullControl" = [System.Security.AccessControl.RegistryRights]::FullControl
                "ReadKey" = [System.Security.AccessControl.RegistryRights]::ReadKey
                "WriteKey" = [System.Security.AccessControl.RegistryRights]::WriteKey
                "ReadPermissions" = [System.Security.AccessControl.RegistryRights]::ReadPermissions
                "ChangePermissions" = [System.Security.AccessControl.RegistryRights]::ChangePermissions
                "TakeOwnership" = [System.Security.AccessControl.RegistryRights]::TakeOwnership
            }

            # Droits spécifiques
            $specificRights = @{
                "QueryValues" = [System.Security.AccessControl.RegistryRights]::QueryValues
                "SetValue" = [System.Security.AccessControl.RegistryRights]::SetValue
                "CreateSubKey" = [System.Security.AccessControl.RegistryRights]::CreateSubKey
                "EnumerateSubKeys" = [System.Security.AccessControl.RegistryRights]::EnumerateSubKeys
                "Notify" = [System.Security.AccessControl.RegistryRights]::Notify
                "CreateLink" = [System.Security.AccessControl.RegistryRights]::CreateLink
                "Delete" = [System.Security.AccessControl.RegistryRights]::Delete
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
                $inheritance += "Sous-clés"
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

        # Fonction pour évaluer le niveau de risque d'une permission
        function Get-PermissionRiskLevel {
            param (
                [string]$IdentityReference,
                [string]$RegistryRights,
                [bool]$IsInherited
            )

            $riskLevel = "Faible"

            # Vérifier les identités à haut risque
            $highRiskIdentities = @(
                "Everyone", "Tout le monde", "Users", "Utilisateurs", "Authenticated Users", "Utilisateurs authentifiés"
            )

            # Vérifier les permissions à haut risque
            $highRiskPermissions = @(
                "FullControl", "WriteKey", "SetValue", "CreateSubKey", "Delete", "ChangePermissions", "TakeOwnership"
            )

            # Évaluer le risque
            if ($highRiskIdentities -contains $IdentityReference) {
                if ($highRiskPermissions -contains $RegistryRights) {
                    $riskLevel = "Élevé"
                } else {
                    $riskLevel = "Moyen"
                }
            } elseif ($highRiskPermissions -contains $RegistryRights) {
                $riskLevel = "Moyen"
            }

            # Les permissions héritées sont généralement moins risquées
            if ($IsInherited -and $riskLevel -eq "Moyen") {
                $riskLevel = "Faible"
            }

            return $riskLevel
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

            # Obtenir les ACL de la clé de registre
            $acl = Get-Acl -Path $Path

            # Analyser chaque règle d'accès
            foreach ($accessRule in $acl.Access) {
                # Ignorer les permissions héritées si demandé
                if (-not $IncludeInherited -and $accessRule.IsInherited) {
                    continue
                }

                # Convertir les droits en format lisible
                $readableRights = ConvertTo-ReadableRegistryRights -Rights $accessRule.RegistryRights

                # Convertir les flags d'héritage en format lisible
                $readableInheritance = ConvertTo-ReadableInheritanceFlags -InheritanceFlags $accessRule.InheritanceFlags -PropagationFlags $accessRule.PropagationFlags

                # Évaluer le niveau de risque
                $riskLevel = Get-PermissionRiskLevel -IdentityReference $accessRule.IdentityReference.Value -RegistryRights ($readableRights -join ", ") -IsInherited $accessRule.IsInherited

                # Créer un objet personnalisé pour cette règle d'accès
                $permissionInfo = [PSCustomObject]@{
                    Path = $Path
                    IdentityReference = $accessRule.IdentityReference.Value
                    AccessControlType = $accessRule.AccessControlType.ToString()
                    Rights = $readableRights
                    RightsRaw = $accessRule.RegistryRights.ToString()
                    Inheritance = $readableInheritance
                    IsInherited = $accessRule.IsInherited
                    InheritanceSource = if ($accessRule.IsInherited) { (Split-Path -Parent $Path) } else { "Directement assigné" }
                    RiskLevel = $riskLevel
                }

                $results += $permissionInfo
            }

            # Ajouter des informations sur le propriétaire
            $ownerInfo = [PSCustomObject]@{
                Path = $Path
                IdentityReference = $acl.Owner
                AccessControlType = "Propriétaire"
                Rights = "Contrôle total (implicite)"
                RightsRaw = "FullControl"
                Inheritance = "N/A"
                IsInherited = $false
                InheritanceSource = "Propriétaire de la clé de registre"
                RiskLevel = "Faible"
            }

            $results += $ownerInfo

            # Si récursif est demandé, analyser les sous-clés
            if ($Recurse -and $CurrentDepth -lt $MaxDepth) {
                # Limiter le nombre d'éléments à traiter pour éviter les boucles infinies
                $subKeys = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue | Select-Object -First 10

                foreach ($subKey in $subKeys) {
                    $childResults = Get-RegistryPermission -Path $subKey.PSPath -Recurse $false -IncludeInherited $IncludeInherited -MaxDepth $MaxDepth -CurrentDepth ($CurrentDepth + 1)
                    $results += $childResults
                }
            }

            return $results
        }
        catch {
            Write-Error "Erreur lors de l'analyse des permissions de registre pour '$Path': $($_.Exception.Message)"
        }
    }
}

# Fonction pour analyser l'héritage des permissions de registre
function Get-RegistryPermissionInheritance {
    <#
    .SYNOPSIS
        Analyse l'héritage des permissions d'une clé de registre.

    .DESCRIPTION
        Cette fonction analyse en détail l'héritage des permissions d'une clé de registre,
        y compris les sources d'héritage, les interruptions d'héritage, et les permissions explicites.

    .PARAMETER Path
        Le chemin de la clé de registre à analyser (ex: "HKLM:\SOFTWARE\Microsoft").

    .PARAMETER Recurse
        Indique si l'analyse doit être récursive pour les sous-clés.

    .EXAMPLE
        Get-RegistryPermissionInheritance -Path "HKLM:\SOFTWARE\Microsoft" -Recurse $false

    .OUTPUTS
        [PSCustomObject] avec des informations détaillées sur l'héritage des permissions de registre.
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
            Write-Error "Le chemin de registre '$Path' n'existe pas."
            return
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
                [System.Security.AccessControl.RegistrySecurity]$Acl
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

            # Obtenir les ACL de la clé de registre
            $acl = Get-Acl -Path $Path

            # Vérifier si l'héritage est activé
            $inheritanceEnabled = Test-InheritanceEnabled -Acl $acl

            # Obtenir le chemin parent
            $parentPath = Get-ParentPath -Path $Path

            # Créer un objet pour les informations d'héritage
            $inheritanceInfo = [PSCustomObject]@{
                Path = $Path
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
                    RegistryRights = $accessRule.RegistryRights.ToString()
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

            # Si récursif est demandé, analyser les sous-clés
            if ($Recurse -and $CurrentDepth -lt $MaxDepth) {
                # Limiter le nombre d'éléments à traiter pour éviter les boucles infinies
                $subKeys = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue | Select-Object -First 10

                foreach ($subKey in $subKeys) {
                    $childResults = Get-RegistryPermissionInheritance -Path $subKey.PSPath -Recurse $false -MaxDepth $MaxDepth -CurrentDepth ($CurrentDepth + 1)
                    $results += $childResults
                }
            }

            return $results
        }
        catch {
            Write-Error "Erreur lors de l'analyse de l'héritage des permissions de registre pour '$Path': $($_.Exception.Message)"
        }
    }
}

# Fonction pour analyser les propriétaires des clés de registre
function Get-RegistryOwnershipInfo {
    <#
    .SYNOPSIS
        Analyse les propriétaires des clés de registre.

    .DESCRIPTION
        Cette fonction analyse en détail les propriétaires des clés de registre,
        y compris les SID, les domaines, et les types de comptes.

    .PARAMETER Path
        Le chemin de la clé de registre à analyser (ex: "HKLM:\SOFTWARE\Microsoft").

    .PARAMETER Recurse
        Indique si l'analyse doit être récursive pour les sous-clés.

    .EXAMPLE
        Get-RegistryOwnershipInfo -Path "HKLM:\SOFTWARE\Microsoft" -Recurse $false

    .OUTPUTS
        [PSCustomObject] avec des informations détaillées sur les propriétaires des clés de registre.
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
            Write-Error "Le chemin de registre '$Path' n'existe pas."
            return
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

            # Obtenir les ACL de la clé de registre
            $acl = Get-Acl -Path $Path

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
                $ownershipInfo.Recommendations += "Vérifier si ce compte local devrait être propriétaire de cette clé de registre"
                $ownershipInfo.RecommendedOwner = "Administrators"
            }

            # Ajouter les informations de propriété aux résultats
            $results += $ownershipInfo

            # Si récursif est demandé, analyser les sous-clés
            if ($Recurse -and $CurrentDepth -lt $MaxDepth) {
                # Limiter le nombre d'éléments à traiter pour éviter les boucles infinies
                $subKeys = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue | Select-Object -First 10

                foreach ($subKey in $subKeys) {
                    $childResults = Get-RegistryOwnershipInfo -Path $subKey.PSPath -Recurse $false -MaxDepth $MaxDepth -CurrentDepth ($CurrentDepth + 1)
                    $results += $childResults
                }
            }

            return $results
        }
        catch {
            Write-Error "Erreur lors de l'analyse des propriétaires de clés de registre pour '$Path': $($_.Exception.Message)"
        }
    }
}

# Fonction pour détecter les anomalies dans les permissions de registre
function Find-RegistryPermissionAnomaly {
    <#
    .SYNOPSIS
        Détecte les anomalies dans les permissions de registre.

    .DESCRIPTION
        Cette fonction analyse les permissions de registre et détecte les anomalies potentielles,
        comme les permissions trop permissives, les conflits, ou les héritages interrompus.

    .PARAMETER Path
        Le chemin de la clé de registre à analyser (ex: "HKLM:\SOFTWARE\Microsoft").

    .PARAMETER Recurse
        Indique si l'analyse doit être récursive pour les sous-clés.

    .EXAMPLE
        Find-RegistryPermissionAnomaly -Path "HKLM:\SOFTWARE\Microsoft" -Recurse $false

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
            Write-Error "Le chemin de registre '$Path' n'existe pas."
            return
        }

        # Fonction pour obtenir le type d'anomalie
        function Get-AnomalyType {
            param (
                [string]$IdentityReference,
                [string]$Rights,
                [bool]$IsInherited,
                [bool]$InheritanceEnabled
            )

            # Identités à haut risque
            $highRiskIdentities = @(
                "Everyone", "Tout le monde", "Users", "Utilisateurs", "Authenticated Users", "Utilisateurs authentifiés"
            )

            # Droits à haut risque
            $highRiskRights = @(
                "FullControl", "WriteKey", "SetValue", "CreateSubKey", "Delete", "ChangePermissions", "TakeOwnership"
            )

            # Vérifier les permissions à haut risque
            if ($highRiskIdentities -contains $IdentityReference -and ($Rights | Where-Object { $highRiskRights -contains $_ })) {
                return "HighRiskPermission"
            }

            # Vérifier les interruptions d'héritage
            if (-not $InheritanceEnabled) {
                return "InheritanceBreak"
            }

            return $null
        }
    }

    process {
        try {
            $results = @()

            # Obtenir les permissions de registre
            $permissions = Get-RegistryPermission -Path $Path -Recurse $false -IncludeInherited $true

            # Obtenir les informations d'héritage
            $inheritanceInfo = Get-RegistryPermissionInheritance -Path $Path -Recurse $false

            # Analyser chaque permission pour détecter les anomalies
            foreach ($permission in $permissions) {
                # Ignorer le propriétaire
                if ($permission.AccessControlType -eq "Propriétaire") {
                    continue
                }

                # Détecter le type d'anomalie
                $anomalyType = Get-AnomalyType -IdentityReference $permission.IdentityReference -Rights $permission.Rights -IsInherited $permission.IsInherited -InheritanceEnabled $inheritanceInfo.InheritanceEnabled

                if ($anomalyType) {
                    # Créer un objet pour l'anomalie
                    $anomalyInfo = [PSCustomObject]@{
                        Path = $permission.Path
                        AnomalyType = $anomalyType
                        IdentityReference = $permission.IdentityReference
                        Rights = $permission.Rights
                        IsInherited = $permission.IsInherited
                        Severity = if ($anomalyType -eq "HighRiskPermission") { "Élevée" } else { "Moyenne" }
                        Description = switch ($anomalyType) {
                            "HighRiskPermission" { "Permission à risque élevé accordée à '$($permission.IdentityReference)'" }
                            "InheritanceBreak" { "Interruption d'héritage détectée" }
                            default { "Anomalie inconnue" }
                        }
                        Recommendation = switch ($anomalyType) {
                            "HighRiskPermission" { "Restreindre les permissions pour '$($permission.IdentityReference)'" }
                            "InheritanceBreak" { "Réactiver l'héritage des permissions" }
                            default { "Vérifier manuellement les permissions" }
                        }
                    }

                    $results += $anomalyInfo
                }
            }

            # Détecter les conflits de permissions
            $identities = $permissions | Select-Object -ExpandProperty IdentityReference -Unique
            foreach ($identity in $identities) {
                $identityPermissions = $permissions | Where-Object { $_.IdentityReference -eq $identity }

                # Vérifier s'il y a à la fois des permissions Allow et Deny pour la même identité
                $allowPermissions = $identityPermissions | Where-Object { $_.AccessControlType -eq "Allow" }
                $denyPermissions = $identityPermissions | Where-Object { $_.AccessControlType -eq "Deny" }

                if ($allowPermissions -and $denyPermissions) {
                    # Créer un objet pour l'anomalie de conflit
                    $conflictInfo = [PSCustomObject]@{
                        Path = $Path
                        AnomalyType = "PermissionConflict"
                        IdentityReference = $identity
                        Rights = "Multiple"
                        IsInherited = $false
                        Severity = "Moyenne"
                        Description = "Conflit entre permissions Allow et Deny pour '$identity'"
                        Recommendation = "Résoudre le conflit en supprimant les permissions redondantes"
                    }

                    $results += $conflictInfo
                }

                # Vérifier s'il y a des permissions redondantes
                if ($identityPermissions.Count -gt 1) {
                    $explicitPermissions = $identityPermissions | Where-Object { -not $_.IsInherited }

                    if ($explicitPermissions.Count -gt 1) {
                        # Créer un objet pour l'anomalie de redondance
                        $redundantInfo = [PSCustomObject]@{
                            Path = $Path
                            AnomalyType = "RedundantPermission"
                            IdentityReference = $identity
                            Rights = "Multiple"
                            IsInherited = $false
                            Severity = "Faible"
                            Description = "Permissions redondantes pour '$identity'"
                            Recommendation = "Consolider les permissions en une seule règle"
                        }

                        $results += $redundantInfo
                    }
                }
            }

            # Si récursif est demandé, analyser les sous-clés
            if ($Recurse) {
                # Limiter le nombre d'éléments à traiter pour éviter les boucles infinies
                $subKeys = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue | Select-Object -First 10

                foreach ($subKey in $subKeys) {
                    $childResults = Find-RegistryPermissionAnomaly -Path $subKey.PSPath -Recurse $false
                    $results += $childResults
                }
            }

            return $results
        }
        catch {
            Write-Error "Erreur lors de la détection des anomalies de permissions de registre pour '$Path': $($_.Exception.Message)"
        }
    }
}

# Fonction pour générer un rapport des permissions de registre
function New-RegistryPermissionReport {
    <#
    .SYNOPSIS
        Génère un rapport détaillé des permissions de registre.

    .DESCRIPTION
        Cette fonction génère un rapport détaillé des permissions de registre,
        y compris les anomalies détectées, les propriétaires, et les héritages.

    .PARAMETER Path
        Le chemin de la clé de registre à analyser (ex: "HKLM:\SOFTWARE\Microsoft").

    .PARAMETER OutputFormat
        Le format du rapport. Valeurs possibles : "Text", "HTML", "JSON".

    .PARAMETER IncludeOwnership
        Indique si les informations de propriété doivent être incluses dans le rapport.

    .PARAMETER IncludeInheritance
        Indique si les informations d'héritage doivent être incluses dans le rapport.

    .PARAMETER IncludeAnomalies
        Indique si les anomalies détectées doivent être incluses dans le rapport.

    .EXAMPLE
        New-RegistryPermissionReport -Path "HKLM:\SOFTWARE\Microsoft" -OutputFormat "HTML"

    .OUTPUTS
        [string] Le rapport généré dans le format spécifié.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "HTML", "JSON")]
        [string]$OutputFormat = "Text",

        [Parameter(Mandatory = $false)]
        [bool]$IncludeOwnership = $true,

        [Parameter(Mandatory = $false)]
        [bool]$IncludeInheritance = $true,

        [Parameter(Mandatory = $false)]
        [bool]$IncludeAnomalies = $true
    )

    begin {
        # Vérifier si le chemin existe
        if (-not (Test-Path -Path $Path)) {
            Write-Error "Le chemin de registre '$Path' n'existe pas."
            return
        }
    }

    process {
        try {
            # Collecter les données
            $permissions = Get-RegistryPermission -Path $Path -Recurse $false -IncludeInherited $true
            $ownershipInfo = if ($IncludeOwnership) { Get-RegistryOwnershipInfo -Path $Path -Recurse $false } else { $null }
            $inheritanceInfo = if ($IncludeInheritance) { Get-RegistryPermissionInheritance -Path $Path -Recurse $false } else { $null }
            $anomalies = if ($IncludeAnomalies) { Find-RegistryPermissionAnomaly -Path $Path -Recurse $false } else { $null }

            # Créer l'objet de rapport
            $reportData = [PSCustomObject]@{
                ReportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Path = $Path
                Permissions = $permissions
                OwnershipInfo = $ownershipInfo
                InheritanceInfo = $inheritanceInfo
                Anomalies = $anomalies
            }

            # Générer le rapport selon le format spécifié
            switch ($OutputFormat) {
                "Text" {
                    $report = @"
==========================================================================
RAPPORT D'ANALYSE DES PERMISSIONS DE REGISTRE
==========================================================================
Date du rapport: $($reportData.ReportDate)
Chemin analysé: $($reportData.Path)
==========================================================================

"@

                    # Ajouter les informations de permissions
                    $report += @"
PERMISSIONS:
----------------------------------------------------------
"@

                    foreach ($permission in $permissions) {
                        $report += @"

Identité: $($permission.IdentityReference)
Type d'accès: $($permission.AccessControlType)
Droits: $($permission.Rights -join ", ")
Hérité: $($permission.IsInherited)
Niveau de risque: $($permission.RiskLevel)

"@
                    }

                    # Ajouter les informations de propriété si demandé
                    if ($IncludeOwnership -and $ownershipInfo) {
                        $report += @"

PROPRIÉTÉ:
----------------------------------------------------------
Propriétaire: $($ownershipInfo.Owner.FullName)
Type de compte: $($ownershipInfo.Owner.AccountType)
Risque de sécurité: $($ownershipInfo.SecurityRisk)
Niveau de risque: $($ownershipInfo.RiskLevel)

"@

                        if ($ownershipInfo.Recommendations.Count -gt 0) {
                            $report += "Recommandations: " + ($ownershipInfo.Recommendations -join ", ") + "`n"
                        }
                    }

                    # Ajouter les informations d'héritage si demandé
                    if ($IncludeInheritance -and $inheritanceInfo) {
                        $report += @"

HÉRITAGE:
----------------------------------------------------------
Héritage activé: $($inheritanceInfo.InheritanceEnabled)
Chemin parent: $($inheritanceInfo.ParentPath)
Permissions explicites: $($inheritanceInfo.ExplicitPermissions.Count)
Permissions héritées: $($inheritanceInfo.InheritedPermissions.Count)

"@
                    }

                    # Ajouter les anomalies si demandé
                    if ($IncludeAnomalies -and $anomalies -and $anomalies.Count -gt 0) {
                        $report += @"

ANOMALIES DÉTECTÉES:
----------------------------------------------------------
"@

                        foreach ($anomaly in $anomalies) {
                            $report += @"

Type d'anomalie: $($anomaly.AnomalyType)
Identité: $($anomaly.IdentityReference)
Sévérité: $($anomaly.Severity)
Description: $($anomaly.Description)
Recommandation: $($anomaly.Recommendation)

"@
                        }
                    }

                    $report += @"
==========================================================================
FIN DU RAPPORT
==========================================================================
"@

                    return $report
                }

                "HTML" {
                    $htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport d'analyse des permissions de registre</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #2c3e50; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .risk-high { color: #e74c3c; font-weight: bold; }
        .risk-medium { color: #f39c12; }
        .risk-low { color: #27ae60; }
        .header { background-color: #2c3e50; color: white; padding: 10px; margin-bottom: 20px; }
        .footer { background-color: #f2f2f2; padding: 10px; margin-top: 20px; text-align: center; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Rapport d'analyse des permissions de registre</h1>
        <p>Date du rapport: $($reportData.ReportDate)</p>
        <p>Chemin analysé: $($reportData.Path)</p>
    </div>

    <h2>Permissions</h2>
    <table>
        <tr>
            <th>Identité</th>
            <th>Type d'accès</th>
            <th>Droits</th>
            <th>Hérité</th>
            <th>Niveau de risque</th>
        </tr>
"@

                    foreach ($permission in $permissions) {
                        $riskClass = switch ($permission.RiskLevel) {
                            "Élevé" { "risk-high" }
                            "Moyen" { "risk-medium" }
                            "Faible" { "risk-low" }
                            default { "" }
                        }

                        $htmlReport += @"
        <tr>
            <td>$($permission.IdentityReference)</td>
            <td>$($permission.AccessControlType)</td>
            <td>$($permission.Rights -join ", ")</td>
            <td>$($permission.IsInherited)</td>
            <td class="$riskClass">$($permission.RiskLevel)</td>
        </tr>
"@
                    }

                    $htmlReport += @"
    </table>
"@

                    # Ajouter les informations de propriété si demandé
                    if ($IncludeOwnership -and $ownershipInfo) {
                        $ownerRiskClass = switch ($ownershipInfo.RiskLevel) {
                            "Élevé" { "risk-high" }
                            "Moyen" { "risk-medium" }
                            "Faible" { "risk-low" }
                            default { "" }
                        }

                        $htmlReport += @"
    <h2>Propriété</h2>
    <table>
        <tr>
            <th>Propriétaire</th>
            <th>Type de compte</th>
            <th>Risque de sécurité</th>
            <th>Niveau de risque</th>
            <th>Recommandations</th>
        </tr>
        <tr>
            <td>$($ownershipInfo.Owner.FullName)</td>
            <td>$($ownershipInfo.Owner.AccountType)</td>
            <td>$($ownershipInfo.SecurityRisk)</td>
            <td class="$ownerRiskClass">$($ownershipInfo.RiskLevel)</td>
            <td>$($ownershipInfo.Recommendations -join ", ")</td>
        </tr>
    </table>
"@
                    }

                    # Ajouter les informations d'héritage si demandé
                    if ($IncludeInheritance -and $inheritanceInfo) {
                        $htmlReport += @"
    <h2>Héritage</h2>
    <table>
        <tr>
            <th>Héritage activé</th>
            <th>Chemin parent</th>
            <th>Permissions explicites</th>
            <th>Permissions héritées</th>
        </tr>
        <tr>
            <td>$($inheritanceInfo.InheritanceEnabled)</td>
            <td>$($inheritanceInfo.ParentPath)</td>
            <td>$($inheritanceInfo.ExplicitPermissions.Count)</td>
            <td>$($inheritanceInfo.InheritedPermissions.Count)</td>
        </tr>
    </table>
"@
                    }

                    # Ajouter les anomalies si demandé
                    if ($IncludeAnomalies -and $anomalies -and $anomalies.Count -gt 0) {
                        $htmlReport += @"
    <h2>Anomalies détectées</h2>
    <table>
        <tr>
            <th>Type d'anomalie</th>
            <th>Identité</th>
            <th>Sévérité</th>
            <th>Description</th>
            <th>Recommandation</th>
        </tr>
"@

                        foreach ($anomaly in $anomalies) {
                            $anomalyRiskClass = switch ($anomaly.Severity) {
                                "Élevée" { "risk-high" }
                                "Moyenne" { "risk-medium" }
                                "Faible" { "risk-low" }
                                default { "" }
                            }

                            $htmlReport += @"
        <tr>
            <td>$($anomaly.AnomalyType)</td>
            <td>$($anomaly.IdentityReference)</td>
            <td class="$anomalyRiskClass">$($anomaly.Severity)</td>
            <td>$($anomaly.Description)</td>
            <td>$($anomaly.Recommendation)</td>
        </tr>
"@
                        }

                        $htmlReport += @"
    </table>
"@
                    }

                    $htmlReport += @"
    <div class="footer">
        <p>Rapport généré par RegistryACLAnalyzer</p>
    </div>
</body>
</html>
"@

                    return $htmlReport
                }

                "JSON" {
                    return $reportData | ConvertTo-Json -Depth 10
                }
            }
        }
        catch {
            Write-Error "Erreur lors de la génération du rapport de permissions de registre pour '$Path': $($_.Exception.Message)"
        }
    }
}

# Fonction pour corriger automatiquement les anomalies de permissions de registre
function Repair-RegistryPermissionAnomaly {
    <#
    .SYNOPSIS
        Corrige automatiquement les anomalies de permissions de registre détectées.

    .DESCRIPTION
        Cette fonction corrige automatiquement les anomalies de permissions de registre détectées
        par la fonction Find-RegistryPermissionAnomaly, comme les permissions trop permissives,
        les conflits, ou les héritages interrompus.

    .PARAMETER Path
        Le chemin de la clé de registre à corriger (ex: "HKLM:\SOFTWARE\Microsoft").

    .PARAMETER AnomalyType
        Le type d'anomalie à corriger. Si non spécifié, toutes les anomalies seront corrigées.
        Valeurs possibles : "HighRiskPermission", "PermissionConflict", "RedundantPermission", "InheritanceBreak".

    .PARAMETER WhatIf
        Indique si la fonction doit simuler les corrections sans les appliquer.

    .PARAMETER Force
        Force l'application des corrections sans demander de confirmation.

    .EXAMPLE
        Repair-RegistryPermissionAnomaly -Path "HKLM:\SOFTWARE\Microsoft" -AnomalyType "HighRiskPermission" -WhatIf

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
            Write-Error "Le chemin de registre '$Path' n'existe pas."
            return
        }

        # Vérifier si l'utilisateur a les privilèges d'administrateur
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) {
            Write-Warning "Cette fonction nécessite des privilèges d'administrateur pour fonctionner correctement."
        }
    }

    process {
        try {
            $results = @()

            # Détecter les anomalies
            $anomalies = Find-RegistryPermissionAnomaly -Path $Path

            # Filtrer les anomalies par type si spécifié
            if ($AnomalyType -ne "All") {
                $anomalies = $anomalies | Where-Object { $_.AnomalyType -eq $AnomalyType }
            }

            if (-not $anomalies) {
                Write-Host "Aucune anomalie à corriger pour le chemin '$Path'."
                return
            }

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
                        $acl = Get-Acl -Path $anomaly.Path

                        # Trouver la règle à risque élevé
                        $highRiskRule = $acl.Access | Where-Object {
                            $_.IdentityReference.Value -eq $anomaly.IdentityReference
                        }

                        if ($highRiskRule) {
                            $correctionDescription = "Suppression de la permission à risque élevé pour $($anomaly.IdentityReference)"

                            if ($Force -or $PSCmdlet.ShouldProcess($anomaly.Path, $correctionDescription)) {
                                # Supprimer la règle à risque élevé
                                foreach ($rule in $highRiskRule) {
                                    $acl.RemoveAccessRule($rule)
                                }

                                # Ajouter une règle plus restrictive si nécessaire
                                $identity = New-Object System.Security.Principal.NTAccount($anomaly.IdentityReference)
                                $newRule = New-Object System.Security.AccessControl.RegistryAccessRule(
                                    $identity,
                                    [System.Security.AccessControl.RegistryRights]::ReadKey,
                                    [System.Security.AccessControl.InheritanceFlags]::ContainerInherit,
                                    [System.Security.AccessControl.PropagationFlags]::None,
                                    [System.Security.AccessControl.AccessControlType]::Allow
                                )

                                $acl.AddAccessRule($newRule)
                                Set-Acl -Path $anomaly.Path -AclObject $acl

                                $correctionInfo.CorrectionApplied = $true
                                $correctionInfo.CorrectionDescription = "$correctionDescription et ajout d'une permission plus restrictive (ReadKey)"
                            } else {
                                $correctionInfo.CorrectionDescription = "$correctionDescription (non appliqué)"
                            }
                        } else {
                            $correctionInfo.CorrectionDescription = "Règle à risque élevé non trouvée"
                        }
                    }

                    "PermissionConflict" {
                        # Obtenir l'ACL actuelle du chemin de l'anomalie
                        $acl = Get-Acl -Path $anomaly.Path

                        # Trouver les règles en conflit
                        $conflictRules = $acl.Access | Where-Object {
                            $_.IdentityReference.Value -eq $anomaly.IdentityReference
                        }

                        if ($conflictRules) {
                            $correctionDescription = "Résolution du conflit de permissions pour $($anomaly.IdentityReference)"

                            if ($Force -or $PSCmdlet.ShouldProcess($anomaly.Path, $correctionDescription)) {
                                # Supprimer toutes les règles en conflit
                                foreach ($rule in $conflictRules) {
                                    $acl.RemoveAccessRule($rule)
                                }

                                # Ajouter une nouvelle règle consolidée
                                $identity = New-Object System.Security.Principal.NTAccount($anomaly.IdentityReference)
                                $newRule = New-Object System.Security.AccessControl.RegistryAccessRule(
                                    $identity,
                                    [System.Security.AccessControl.RegistryRights]::ReadKey,
                                    [System.Security.AccessControl.InheritanceFlags]::ContainerInherit,
                                    [System.Security.AccessControl.PropagationFlags]::None,
                                    [System.Security.AccessControl.AccessControlType]::Allow
                                )

                                $acl.AddAccessRule($newRule)
                                Set-Acl -Path $anomaly.Path -AclObject $acl

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
                        $acl = Get-Acl -Path $anomaly.Path

                        # Trouver les règles redondantes
                        $redundantRules = $acl.Access | Where-Object {
                            $_.IdentityReference.Value -eq $anomaly.IdentityReference
                        }

                        if ($redundantRules -and $redundantRules.Count -gt 1) {
                            $correctionDescription = "Consolidation des permissions redondantes pour $($anomaly.IdentityReference)"

                            if ($Force -or $PSCmdlet.ShouldProcess($anomaly.Path, $correctionDescription)) {
                                # Supprimer toutes les règles redondantes
                                foreach ($rule in $redundantRules) {
                                    $acl.RemoveAccessRule($rule)
                                }

                                # Déterminer les droits combinés
                                $combinedRights = [System.Security.AccessControl.RegistryRights]::ReadKey

                                # Ajouter une nouvelle règle consolidée
                                $identity = New-Object System.Security.Principal.NTAccount($anomaly.IdentityReference)
                                $newRule = New-Object System.Security.AccessControl.RegistryAccessRule(
                                    $identity,
                                    $combinedRights,
                                    [System.Security.AccessControl.InheritanceFlags]::ContainerInherit,
                                    [System.Security.AccessControl.PropagationFlags]::None,
                                    [System.Security.AccessControl.AccessControlType]::Allow
                                )

                                $acl.AddAccessRule($newRule)
                                Set-Acl -Path $anomaly.Path -AclObject $acl

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
                        $acl = Get-Acl -Path $anomaly.Path

                        $correctionDescription = "Réactivation de l'héritage des permissions"

                        if ($Force -or $PSCmdlet.ShouldProcess($anomaly.Path, $correctionDescription)) {
                            # Réactiver l'héritage
                            $acl.SetAccessRuleProtection($false, $true)  # Activer l'héritage et conserver les règles existantes
                            Set-Acl -Path $anomaly.Path -AclObject $acl

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
            Write-Error "Erreur lors de la correction des anomalies de permissions de registre pour '$Path': $($_.Exception.Message)"
        }
    }
}

# Fonction pour comparer les permissions entre différentes clés de registre
function Compare-RegistryPermission {
    <#
    .SYNOPSIS
        Compare les permissions entre deux clés de registre.

    .DESCRIPTION
        Cette fonction compare les permissions entre deux clés de registre et identifie
        les différences, comme les permissions manquantes, supplémentaires ou modifiées.

    .PARAMETER ReferencePath
        Le chemin de la clé de registre de référence pour la comparaison.

    .PARAMETER DifferencePath
        Le chemin de la clé de registre à comparer avec la référence.

    .PARAMETER IncludeInherited
        Indique si les permissions héritées doivent être incluses dans la comparaison.

    .PARAMETER Recurse
        Indique si la comparaison doit être récursive pour les sous-clés.

    .EXAMPLE
        Compare-RegistryPermission -ReferencePath "HKLM:\SOFTWARE\Microsoft" -DifferencePath "HKLM:\SOFTWARE\Classes" -IncludeInherited $true

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
        [bool]$IncludeInherited = $true,

        [Parameter(Mandatory = $false)]
        [bool]$Recurse = $false
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

        # Fonction pour normaliser les permissions pour la comparaison
        function Get-NormalizedPermissions {
            param (
                [string]$Path,
                [bool]$IncludeInherited,
                [bool]$Recurse
            )

            $permissions = Get-RegistryPermission -Path $Path -Recurse $Recurse -IncludeInherited $IncludeInherited

            # Normaliser les chemins pour la comparaison
            $normalizedPermissions = @()
            foreach ($permission in $permissions) {
                $relativePath = $permission.Path.Substring($Path.Length)
                if ($relativePath -eq "") {
                    $relativePath = "\"
                }

                $normalizedPermission = [PSCustomObject]@{
                    RelativePath = $relativePath
                    IdentityReference = $permission.IdentityReference
                    AccessControlType = $permission.AccessControlType
                    Rights = $permission.Rights
                    IsInherited = $permission.IsInherited
                }

                $normalizedPermissions += $normalizedPermission
            }

            return $normalizedPermissions
        }
    }

    process {
        try {
            # Obtenir les permissions normalisées des deux chemins
            $referencePermissions = Get-NormalizedPermissions -Path $ReferencePath -IncludeInherited $IncludeInherited -Recurse $Recurse
            $differencePermissions = Get-NormalizedPermissions -Path $DifferencePath -IncludeInherited $IncludeInherited -Recurse $Recurse

            # Créer des collections pour les différences
            $missingPermissions = @()
            $additionalPermissions = @()
            $modifiedPermissions = @()

            # Comparer les permissions de référence avec les permissions de différence
            foreach ($refPerm in $referencePermissions) {
                $matchingPerm = $differencePermissions | Where-Object {
                    $_.RelativePath -eq $refPerm.RelativePath -and
                    $_.IdentityReference -eq $refPerm.IdentityReference -and
                    $_.AccessControlType -eq $refPerm.AccessControlType
                }

                if (-not $matchingPerm) {
                    # Permission manquante dans le chemin de différence
                    $missingPermissions += [PSCustomObject]@{
                        Path = $refPerm.RelativePath
                        IdentityReference = $refPerm.IdentityReference
                        AccessControlType = $refPerm.AccessControlType
                        Rights = $refPerm.Rights
                        IsInherited = $refPerm.IsInherited
                    }
                } elseif ($refPerm.Rights -ne $matchingPerm.Rights) {
                    # Permission modifiée
                    $modifiedPermissions += [PSCustomObject]@{
                        Path = $refPerm.RelativePath
                        IdentityReference = $refPerm.IdentityReference
                        AccessControlType = $refPerm.AccessControlType
                        ReferenceRights = $refPerm.Rights
                        DifferenceRights = $matchingPerm.Rights
                        IsInherited = $refPerm.IsInherited
                    }
                }
            }

            # Trouver les permissions supplémentaires dans le chemin de différence
            foreach ($diffPerm in $differencePermissions) {
                $matchingPerm = $referencePermissions | Where-Object {
                    $_.RelativePath -eq $diffPerm.RelativePath -and
                    $_.IdentityReference -eq $diffPerm.IdentityReference -and
                    $_.AccessControlType -eq $diffPerm.AccessControlType
                }

                if (-not $matchingPerm) {
                    # Permission supplémentaire dans le chemin de différence
                    $additionalPermissions += [PSCustomObject]@{
                        Path = $diffPerm.RelativePath
                        IdentityReference = $diffPerm.IdentityReference
                        AccessControlType = $diffPerm.AccessControlType
                        Rights = $diffPerm.Rights
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
                Summary = [PSCustomObject]@{
                    TotalPermissionsInReference = $referencePermissions.Count
                    TotalPermissionsInDifference = $differencePermissions.Count
                    MissingPermissionsCount = $missingPermissions.Count
                    AdditionalPermissionsCount = $additionalPermissions.Count
                    ModifiedPermissionsCount = $modifiedPermissions.Count
                }
            }

            return $result
        }
        catch {
            Write-Error "Erreur lors de la comparaison des permissions de registre: $($_.Exception.Message)"
        }
    }
}

# Fonction pour exporter les permissions de registre vers un fichier
function Export-RegistryPermission {
    <#
    .SYNOPSIS
        Exporte les permissions d'une clé de registre vers un fichier.

    .DESCRIPTION
        Cette fonction exporte les permissions d'une clé de registre vers un fichier JSON, XML ou CSV,
        permettant de sauvegarder une configuration de sécurité pour une restauration ultérieure.

    .PARAMETER Path
        Le chemin de la clé de registre dont les permissions doivent être exportées.

    .PARAMETER OutputPath
        Le chemin du fichier de sortie où les permissions seront exportées.

    .PARAMETER Format
        Le format du fichier d'exportation. Valeurs possibles : "JSON", "XML", "CSV".

    .PARAMETER Recurse
        Indique si l'exportation doit être récursive pour les sous-clés.

    .EXAMPLE
        Export-RegistryPermission -Path "HKLM:\SOFTWARE\Microsoft" -OutputPath "C:\Backup\RegistryPermissions.json" -Format "JSON" -Recurse $true

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
            Write-Error "Le chemin de registre '$Path' n'existe pas."
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
            # Obtenir les permissions de registre
            $permissions = Get-RegistryPermission -Path $Path -Recurse $Recurse -IncludeInherited $true

            # Obtenir les informations d'héritage
            $inheritanceInfo = Get-RegistryPermissionInheritance -Path $Path -Recurse $Recurse

            # Créer un objet d'exportation avec des métadonnées
            $exportObject = [PSCustomObject]@{
                ExportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                SourcePath = $Path
                Recurse = $Recurse
                Permissions = $permissions
                InheritanceInfo = $inheritanceInfo
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
                            IdentityReference = $perm.IdentityReference
                            AccessControlType = $perm.AccessControlType
                            Rights = ($perm.Rights -join ",")
                            IsInherited = $perm.IsInherited
                            InheritanceFlags = $perm.Inheritance
                        }
                        $flatPermissions += $flatPerm
                    }
                    $flatPermissions | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding utf8
                }
            }

            Write-Host "Permissions de registre exportées avec succès vers '$OutputPath'."
            return $OutputPath
        }
        catch {
            Write-Error "Erreur lors de l'exportation des permissions de registre: $($_.Exception.Message)"
        }
    }
}

# Fonction pour importer les permissions de registre depuis un fichier
function Import-RegistryPermission {
    <#
    .SYNOPSIS
        Importe les permissions de registre depuis un fichier et les applique à une clé de registre.

    .DESCRIPTION
        Cette fonction importe les permissions de registre depuis un fichier JSON, XML ou CSV
        et les applique à une clé de registre spécifiée, permettant de restaurer une configuration de sécurité.

    .PARAMETER InputPath
        Le chemin du fichier d'entrée contenant les permissions à importer.

    .PARAMETER TargetPath
        Le chemin de la clé de registre à laquelle les permissions doivent être appliquées.
        Si non spécifié, le chemin source original sera utilisé.

    .PARAMETER Format
        Le format du fichier d'importation. Valeurs possibles : "JSON", "XML", "CSV".

    .PARAMETER WhatIf
        Indique si la fonction doit simuler l'importation sans appliquer les permissions.

    .PARAMETER Force
        Force l'application des permissions sans demander de confirmation.

    .EXAMPLE
        Import-RegistryPermission -InputPath "C:\Backup\RegistryPermissions.json" -TargetPath "HKLM:\SOFTWARE\Test" -Format "JSON" -WhatIf

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

        # Vérifier si l'utilisateur a les privilèges d'administrateur
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) {
            Write-Warning "Cette fonction nécessite des privilèges d'administrateur pour fonctionner correctement."
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
                    $csvData = Import-Csv -Path $InputPath
                    $permissions = @()
                    foreach ($row in $csvData) {
                        $perm = [PSCustomObject]@{
                            Path = $row.Path
                            IdentityReference = $row.IdentityReference
                            AccessControlType = $row.AccessControlType
                            Rights = $row.Rights -split ","
                            IsInherited = [System.Convert]::ToBoolean($row.IsInherited)
                            Inheritance = $row.InheritanceFlags
                        }
                        $permissions += $perm
                    }

                    $importObject = [PSCustomObject]@{
                        ExportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                        SourcePath = $permissions[0].Path
                        Recurse = $false
                        Permissions = $permissions
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

                $targetItemPath = if ($relativePath -eq "") {
                    $actualTargetPath
                } else {
                    Join-Path -Path $actualTargetPath -ChildPath $relativePath
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
                    Rights = $perm.Rights
                    Applied = $false
                }

                # Appliquer la permission si ce n'est pas une permission héritée
                if (-not $perm.IsInherited) {
                    $description = "Application de la permission '$($perm.Rights -join ", ")' pour '$($perm.IdentityReference)' sur '$targetItemPath'"

                    if ($Force -or $PSCmdlet.ShouldProcess($targetItemPath, $description)) {
                        try {
                            # Obtenir l'ACL actuelle
                            $acl = Get-Acl -Path $targetItemPath

                            # Créer la règle d'accès
                            $identity = New-Object System.Security.Principal.NTAccount($perm.IdentityReference)

                            # Déterminer les droits de registre
                            $registryRights = [System.Security.AccessControl.RegistryRights]::ReadKey

                            # Créer la règle d'accès
                            $rule = New-Object System.Security.AccessControl.RegistryAccessRule(
                                $identity,
                                $registryRights,
                                [System.Security.AccessControl.InheritanceFlags]::ContainerInherit,
                                [System.Security.AccessControl.PropagationFlags]::None,
                                [System.Security.AccessControl.AccessControlType]::Allow
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

            # Appliquer les informations d'héritage si disponibles
            if ($importObject.InheritanceInfo) {
                foreach ($inhInfo in $importObject.InheritanceInfo) {
                    # Déterminer le chemin relatif et le chemin cible complet
                    $relativePath = if ($inhInfo.Path -eq $importObject.SourcePath) {
                        ""
                    } else {
                        $inhInfo.Path.Substring($importObject.SourcePath.Length)
                    }

                    $targetItemPath = if ($relativePath -eq "") {
                        $actualTargetPath
                    } else {
                        Join-Path -Path $actualTargetPath -ChildPath $relativePath
                    }

                    # Vérifier si le chemin cible existe
                    if (-not (Test-Path -Path $targetItemPath)) {
                        Write-Warning "Le chemin cible '$targetItemPath' n'existe pas et sera ignoré."
                        continue
                    }

                    $inheritanceInfo = [PSCustomObject]@{
                        SourcePath = $inhInfo.Path
                        TargetPath = $targetItemPath
                        InheritanceEnabled = $inhInfo.InheritanceEnabled
                        Applied = $false
                    }

                    $description = if ($inhInfo.InheritanceEnabled) {
                        "Activation de l'héritage des permissions sur '$targetItemPath'"
                    } else {
                        "Désactivation de l'héritage des permissions sur '$targetItemPath'"
                    }

                    if ($Force -or $PSCmdlet.ShouldProcess($targetItemPath, $description)) {
                        try {
                            # Obtenir l'ACL actuelle
                            $acl = Get-Acl -Path $targetItemPath

                            # Appliquer l'état d'héritage
                            $acl.SetAccessRuleProtection(-not $inhInfo.InheritanceEnabled, $true)
                            Set-Acl -Path $targetItemPath -AclObject $acl

                            $inheritanceInfo.Applied = $true
                        } catch {
                            Write-Warning "Erreur lors de l'application de l'héritage sur '$targetItemPath': $($_.Exception.Message)"
                        }
                    }

                    $results += $inheritanceInfo
                }
            }

            return $results
        }
        catch {
            Write-Error "Erreur lors de l'importation des permissions de registre: $($_.Exception.Message)"
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
    Export-ModuleMember -Function Get-RegistryPermission, Get-RegistryPermissionInheritance, Get-RegistryOwnershipInfo, Find-RegistryPermissionAnomaly, New-RegistryPermissionReport, Repair-RegistryPermissionAnomaly, Compare-RegistryPermission, Export-RegistryPermission, Import-RegistryPermission
}
