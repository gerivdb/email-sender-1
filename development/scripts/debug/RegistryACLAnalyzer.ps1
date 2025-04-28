<#
.SYNOPSIS
    Outils d'analyse des listes de contrÃ´le d'accÃ¨s (ACL) pour les clÃ©s de registre Windows.

.DESCRIPTION
    Ce module fournit des fonctions pour analyser, comparer et visualiser les listes de contrÃ´le d'accÃ¨s (ACL)
    sur les clÃ©s de registre Windows, permettant d'identifier les problÃ¨mes de sÃ©curitÃ© potentiels.

.NOTES
    Nom du fichier : RegistryACLAnalyzer.ps1
    Auteur        : Augment Code
    Version       : 1.0
    PrÃ©requis     : PowerShell 5.1 ou supÃ©rieur
#>

#Requires -Version 5.1

# Fonction pour analyser les permissions de registre
function Get-RegistryPermission {
    <#
    .SYNOPSIS
        Analyse les permissions d'une clÃ© de registre.

    .DESCRIPTION
        Cette fonction analyse en dÃ©tail les permissions d'une clÃ© de registre,
        y compris les droits spÃ©cifiques, les hÃ©ritages, et les identitÃ©s associÃ©es.

    .PARAMETER Path
        Le chemin de la clÃ© de registre Ã  analyser (ex: "HKLM:\SOFTWARE\Microsoft").

    .PARAMETER Recurse
        Indique si l'analyse doit Ãªtre rÃ©cursive pour les sous-clÃ©s.

    .PARAMETER IncludeInherited
        Indique si les permissions hÃ©ritÃ©es doivent Ãªtre incluses dans l'analyse.

    .PARAMETER MaxDepth
        Profondeur maximale de rÃ©cursion pour Ã©viter les boucles infinies.

    .EXAMPLE
        Get-RegistryPermission -Path "HKLM:\SOFTWARE\Microsoft" -Recurse $false -IncludeInherited $true

    .OUTPUTS
        [PSCustomObject] avec des informations dÃ©taillÃ©es sur les permissions de registre.
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
        # VÃ©rifier si le chemin existe
        if (-not (Test-Path -Path $Path)) {
            Write-Error "Le chemin de registre '$Path' n'existe pas."
            return
        }

        # Fonction pour convertir les droits d'accÃ¨s en chaÃ®ne lisible
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

            # Droits spÃ©cifiques
            $specificRights = @{
                "QueryValues" = [System.Security.AccessControl.RegistryRights]::QueryValues
                "SetValue" = [System.Security.AccessControl.RegistryRights]::SetValue
                "CreateSubKey" = [System.Security.AccessControl.RegistryRights]::CreateSubKey
                "EnumerateSubKeys" = [System.Security.AccessControl.RegistryRights]::EnumerateSubKeys
                "Notify" = [System.Security.AccessControl.RegistryRights]::Notify
                "CreateLink" = [System.Security.AccessControl.RegistryRights]::CreateLink
                "Delete" = [System.Security.AccessControl.RegistryRights]::Delete
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
                $inheritance += "Sous-clÃ©s"
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

        # Fonction pour Ã©valuer le niveau de risque d'une permission
        function Get-PermissionRiskLevel {
            param (
                [string]$IdentityReference,
                [string]$RegistryRights,
                [bool]$IsInherited
            )

            $riskLevel = "Faible"

            # VÃ©rifier les identitÃ©s Ã  haut risque
            $highRiskIdentities = @(
                "Everyone", "Tout le monde", "Users", "Utilisateurs", "Authenticated Users", "Utilisateurs authentifiÃ©s"
            )

            # VÃ©rifier les permissions Ã  haut risque
            $highRiskPermissions = @(
                "FullControl", "WriteKey", "SetValue", "CreateSubKey", "Delete", "ChangePermissions", "TakeOwnership"
            )

            # Ã‰valuer le risque
            if ($highRiskIdentities -contains $IdentityReference) {
                if ($highRiskPermissions -contains $RegistryRights) {
                    $riskLevel = "Ã‰levÃ©"
                } else {
                    $riskLevel = "Moyen"
                }
            } elseif ($highRiskPermissions -contains $RegistryRights) {
                $riskLevel = "Moyen"
            }

            # Les permissions hÃ©ritÃ©es sont gÃ©nÃ©ralement moins risquÃ©es
            if ($IsInherited -and $riskLevel -eq "Moyen") {
                $riskLevel = "Faible"
            }

            return $riskLevel
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

            # Obtenir les ACL de la clÃ© de registre
            $acl = Get-Acl -Path $Path

            # Analyser chaque rÃ¨gle d'accÃ¨s
            foreach ($accessRule in $acl.Access) {
                # Ignorer les permissions hÃ©ritÃ©es si demandÃ©
                if (-not $IncludeInherited -and $accessRule.IsInherited) {
                    continue
                }

                # Convertir les droits en format lisible
                $readableRights = ConvertTo-ReadableRegistryRights -Rights $accessRule.RegistryRights

                # Convertir les flags d'hÃ©ritage en format lisible
                $readableInheritance = ConvertTo-ReadableInheritanceFlags -InheritanceFlags $accessRule.InheritanceFlags -PropagationFlags $accessRule.PropagationFlags

                # Ã‰valuer le niveau de risque
                $riskLevel = Get-PermissionRiskLevel -IdentityReference $accessRule.IdentityReference.Value -RegistryRights ($readableRights -join ", ") -IsInherited $accessRule.IsInherited

                # CrÃ©er un objet personnalisÃ© pour cette rÃ¨gle d'accÃ¨s
                $permissionInfo = [PSCustomObject]@{
                    Path = $Path
                    IdentityReference = $accessRule.IdentityReference.Value
                    AccessControlType = $accessRule.AccessControlType.ToString()
                    Rights = $readableRights
                    RightsRaw = $accessRule.RegistryRights.ToString()
                    Inheritance = $readableInheritance
                    IsInherited = $accessRule.IsInherited
                    InheritanceSource = if ($accessRule.IsInherited) { (Split-Path -Parent $Path) } else { "Directement assignÃ©" }
                    RiskLevel = $riskLevel
                }

                $results += $permissionInfo
            }

            # Ajouter des informations sur le propriÃ©taire
            $ownerInfo = [PSCustomObject]@{
                Path = $Path
                IdentityReference = $acl.Owner
                AccessControlType = "PropriÃ©taire"
                Rights = "ContrÃ´le total (implicite)"
                RightsRaw = "FullControl"
                Inheritance = "N/A"
                IsInherited = $false
                InheritanceSource = "PropriÃ©taire de la clÃ© de registre"
                RiskLevel = "Faible"
            }

            $results += $ownerInfo

            # Si rÃ©cursif est demandÃ©, analyser les sous-clÃ©s
            if ($Recurse -and $CurrentDepth -lt $MaxDepth) {
                # Limiter le nombre d'Ã©lÃ©ments Ã  traiter pour Ã©viter les boucles infinies
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

# Fonction pour analyser l'hÃ©ritage des permissions de registre
function Get-RegistryPermissionInheritance {
    <#
    .SYNOPSIS
        Analyse l'hÃ©ritage des permissions d'une clÃ© de registre.

    .DESCRIPTION
        Cette fonction analyse en dÃ©tail l'hÃ©ritage des permissions d'une clÃ© de registre,
        y compris les sources d'hÃ©ritage, les interruptions d'hÃ©ritage, et les permissions explicites.

    .PARAMETER Path
        Le chemin de la clÃ© de registre Ã  analyser (ex: "HKLM:\SOFTWARE\Microsoft").

    .PARAMETER Recurse
        Indique si l'analyse doit Ãªtre rÃ©cursive pour les sous-clÃ©s.

    .EXAMPLE
        Get-RegistryPermissionInheritance -Path "HKLM:\SOFTWARE\Microsoft" -Recurse $false

    .OUTPUTS
        [PSCustomObject] avec des informations dÃ©taillÃ©es sur l'hÃ©ritage des permissions de registre.
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

        # Fonction pour vÃ©rifier si l'hÃ©ritage est activÃ©
        function Test-InheritanceEnabled {
            param (
                [System.Security.AccessControl.RegistrySecurity]$Acl
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

            # Obtenir les ACL de la clÃ© de registre
            $acl = Get-Acl -Path $Path

            # VÃ©rifier si l'hÃ©ritage est activÃ©
            $inheritanceEnabled = Test-InheritanceEnabled -Acl $acl

            # Obtenir le chemin parent
            $parentPath = Get-ParentPath -Path $Path

            # CrÃ©er un objet pour les informations d'hÃ©ritage
            $inheritanceInfo = [PSCustomObject]@{
                Path = $Path
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

            # VÃ©rifier s'il y a une interruption d'hÃ©ritage
            if (-not $inheritanceEnabled) {
                $inheritanceInfo.InheritanceBreakPoints += $Path
            }

            # Ajouter les informations d'hÃ©ritage aux rÃ©sultats
            $results += $inheritanceInfo

            # Si rÃ©cursif est demandÃ©, analyser les sous-clÃ©s
            if ($Recurse -and $CurrentDepth -lt $MaxDepth) {
                # Limiter le nombre d'Ã©lÃ©ments Ã  traiter pour Ã©viter les boucles infinies
                $subKeys = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue | Select-Object -First 10

                foreach ($subKey in $subKeys) {
                    $childResults = Get-RegistryPermissionInheritance -Path $subKey.PSPath -Recurse $false -MaxDepth $MaxDepth -CurrentDepth ($CurrentDepth + 1)
                    $results += $childResults
                }
            }

            return $results
        }
        catch {
            Write-Error "Erreur lors de l'analyse de l'hÃ©ritage des permissions de registre pour '$Path': $($_.Exception.Message)"
        }
    }
}

# Fonction pour analyser les propriÃ©taires des clÃ©s de registre
function Get-RegistryOwnershipInfo {
    <#
    .SYNOPSIS
        Analyse les propriÃ©taires des clÃ©s de registre.

    .DESCRIPTION
        Cette fonction analyse en dÃ©tail les propriÃ©taires des clÃ©s de registre,
        y compris les SID, les domaines, et les types de comptes.

    .PARAMETER Path
        Le chemin de la clÃ© de registre Ã  analyser (ex: "HKLM:\SOFTWARE\Microsoft").

    .PARAMETER Recurse
        Indique si l'analyse doit Ãªtre rÃ©cursive pour les sous-clÃ©s.

    .EXAMPLE
        Get-RegistryOwnershipInfo -Path "HKLM:\SOFTWARE\Microsoft" -Recurse $false

    .OUTPUTS
        [PSCustomObject] avec des informations dÃ©taillÃ©es sur les propriÃ©taires des clÃ©s de registre.
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
            Write-Error "Le chemin de registre '$Path' n'existe pas."
            return
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

            # Obtenir les ACL de la clÃ© de registre
            $acl = Get-Acl -Path $Path

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
                $ownershipInfo.Recommendations += "VÃ©rifier si ce compte local devrait Ãªtre propriÃ©taire de cette clÃ© de registre"
                $ownershipInfo.RecommendedOwner = "Administrators"
            }

            # Ajouter les informations de propriÃ©tÃ© aux rÃ©sultats
            $results += $ownershipInfo

            # Si rÃ©cursif est demandÃ©, analyser les sous-clÃ©s
            if ($Recurse -and $CurrentDepth -lt $MaxDepth) {
                # Limiter le nombre d'Ã©lÃ©ments Ã  traiter pour Ã©viter les boucles infinies
                $subKeys = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue | Select-Object -First 10

                foreach ($subKey in $subKeys) {
                    $childResults = Get-RegistryOwnershipInfo -Path $subKey.PSPath -Recurse $false -MaxDepth $MaxDepth -CurrentDepth ($CurrentDepth + 1)
                    $results += $childResults
                }
            }

            return $results
        }
        catch {
            Write-Error "Erreur lors de l'analyse des propriÃ©taires de clÃ©s de registre pour '$Path': $($_.Exception.Message)"
        }
    }
}

# Fonction pour dÃ©tecter les anomalies dans les permissions de registre
function Find-RegistryPermissionAnomaly {
    <#
    .SYNOPSIS
        DÃ©tecte les anomalies dans les permissions de registre.

    .DESCRIPTION
        Cette fonction analyse les permissions de registre et dÃ©tecte les anomalies potentielles,
        comme les permissions trop permissives, les conflits, ou les hÃ©ritages interrompus.

    .PARAMETER Path
        Le chemin de la clÃ© de registre Ã  analyser (ex: "HKLM:\SOFTWARE\Microsoft").

    .PARAMETER Recurse
        Indique si l'analyse doit Ãªtre rÃ©cursive pour les sous-clÃ©s.

    .EXAMPLE
        Find-RegistryPermissionAnomaly -Path "HKLM:\SOFTWARE\Microsoft" -Recurse $false

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

            # IdentitÃ©s Ã  haut risque
            $highRiskIdentities = @(
                "Everyone", "Tout le monde", "Users", "Utilisateurs", "Authenticated Users", "Utilisateurs authentifiÃ©s"
            )

            # Droits Ã  haut risque
            $highRiskRights = @(
                "FullControl", "WriteKey", "SetValue", "CreateSubKey", "Delete", "ChangePermissions", "TakeOwnership"
            )

            # VÃ©rifier les permissions Ã  haut risque
            if ($highRiskIdentities -contains $IdentityReference -and ($Rights | Where-Object { $highRiskRights -contains $_ })) {
                return "HighRiskPermission"
            }

            # VÃ©rifier les interruptions d'hÃ©ritage
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

            # Obtenir les informations d'hÃ©ritage
            $inheritanceInfo = Get-RegistryPermissionInheritance -Path $Path -Recurse $false

            # Analyser chaque permission pour dÃ©tecter les anomalies
            foreach ($permission in $permissions) {
                # Ignorer le propriÃ©taire
                if ($permission.AccessControlType -eq "PropriÃ©taire") {
                    continue
                }

                # DÃ©tecter le type d'anomalie
                $anomalyType = Get-AnomalyType -IdentityReference $permission.IdentityReference -Rights $permission.Rights -IsInherited $permission.IsInherited -InheritanceEnabled $inheritanceInfo.InheritanceEnabled

                if ($anomalyType) {
                    # CrÃ©er un objet pour l'anomalie
                    $anomalyInfo = [PSCustomObject]@{
                        Path = $permission.Path
                        AnomalyType = $anomalyType
                        IdentityReference = $permission.IdentityReference
                        Rights = $permission.Rights
                        IsInherited = $permission.IsInherited
                        Severity = if ($anomalyType -eq "HighRiskPermission") { "Ã‰levÃ©e" } else { "Moyenne" }
                        Description = switch ($anomalyType) {
                            "HighRiskPermission" { "Permission Ã  risque Ã©levÃ© accordÃ©e Ã  '$($permission.IdentityReference)'" }
                            "InheritanceBreak" { "Interruption d'hÃ©ritage dÃ©tectÃ©e" }
                            default { "Anomalie inconnue" }
                        }
                        Recommendation = switch ($anomalyType) {
                            "HighRiskPermission" { "Restreindre les permissions pour '$($permission.IdentityReference)'" }
                            "InheritanceBreak" { "RÃ©activer l'hÃ©ritage des permissions" }
                            default { "VÃ©rifier manuellement les permissions" }
                        }
                    }

                    $results += $anomalyInfo
                }
            }

            # DÃ©tecter les conflits de permissions
            $identities = $permissions | Select-Object -ExpandProperty IdentityReference -Unique
            foreach ($identity in $identities) {
                $identityPermissions = $permissions | Where-Object { $_.IdentityReference -eq $identity }

                # VÃ©rifier s'il y a Ã  la fois des permissions Allow et Deny pour la mÃªme identitÃ©
                $allowPermissions = $identityPermissions | Where-Object { $_.AccessControlType -eq "Allow" }
                $denyPermissions = $identityPermissions | Where-Object { $_.AccessControlType -eq "Deny" }

                if ($allowPermissions -and $denyPermissions) {
                    # CrÃ©er un objet pour l'anomalie de conflit
                    $conflictInfo = [PSCustomObject]@{
                        Path = $Path
                        AnomalyType = "PermissionConflict"
                        IdentityReference = $identity
                        Rights = "Multiple"
                        IsInherited = $false
                        Severity = "Moyenne"
                        Description = "Conflit entre permissions Allow et Deny pour '$identity'"
                        Recommendation = "RÃ©soudre le conflit en supprimant les permissions redondantes"
                    }

                    $results += $conflictInfo
                }

                # VÃ©rifier s'il y a des permissions redondantes
                if ($identityPermissions.Count -gt 1) {
                    $explicitPermissions = $identityPermissions | Where-Object { -not $_.IsInherited }

                    if ($explicitPermissions.Count -gt 1) {
                        # CrÃ©er un objet pour l'anomalie de redondance
                        $redundantInfo = [PSCustomObject]@{
                            Path = $Path
                            AnomalyType = "RedundantPermission"
                            IdentityReference = $identity
                            Rights = "Multiple"
                            IsInherited = $false
                            Severity = "Faible"
                            Description = "Permissions redondantes pour '$identity'"
                            Recommendation = "Consolider les permissions en une seule rÃ¨gle"
                        }

                        $results += $redundantInfo
                    }
                }
            }

            # Si rÃ©cursif est demandÃ©, analyser les sous-clÃ©s
            if ($Recurse) {
                # Limiter le nombre d'Ã©lÃ©ments Ã  traiter pour Ã©viter les boucles infinies
                $subKeys = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue | Select-Object -First 10

                foreach ($subKey in $subKeys) {
                    $childResults = Find-RegistryPermissionAnomaly -Path $subKey.PSPath -Recurse $false
                    $results += $childResults
                }
            }

            return $results
        }
        catch {
            Write-Error "Erreur lors de la dÃ©tection des anomalies de permissions de registre pour '$Path': $($_.Exception.Message)"
        }
    }
}

# Fonction pour gÃ©nÃ©rer un rapport des permissions de registre
function New-RegistryPermissionReport {
    <#
    .SYNOPSIS
        GÃ©nÃ¨re un rapport dÃ©taillÃ© des permissions de registre.

    .DESCRIPTION
        Cette fonction gÃ©nÃ¨re un rapport dÃ©taillÃ© des permissions de registre,
        y compris les anomalies dÃ©tectÃ©es, les propriÃ©taires, et les hÃ©ritages.

    .PARAMETER Path
        Le chemin de la clÃ© de registre Ã  analyser (ex: "HKLM:\SOFTWARE\Microsoft").

    .PARAMETER OutputFormat
        Le format du rapport. Valeurs possibles : "Text", "HTML", "JSON".

    .PARAMETER IncludeOwnership
        Indique si les informations de propriÃ©tÃ© doivent Ãªtre incluses dans le rapport.

    .PARAMETER IncludeInheritance
        Indique si les informations d'hÃ©ritage doivent Ãªtre incluses dans le rapport.

    .PARAMETER IncludeAnomalies
        Indique si les anomalies dÃ©tectÃ©es doivent Ãªtre incluses dans le rapport.

    .EXAMPLE
        New-RegistryPermissionReport -Path "HKLM:\SOFTWARE\Microsoft" -OutputFormat "HTML"

    .OUTPUTS
        [string] Le rapport gÃ©nÃ©rÃ© dans le format spÃ©cifiÃ©.
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
        # VÃ©rifier si le chemin existe
        if (-not (Test-Path -Path $Path)) {
            Write-Error "Le chemin de registre '$Path' n'existe pas."
            return
        }
    }

    process {
        try {
            # Collecter les donnÃ©es
            $permissions = Get-RegistryPermission -Path $Path -Recurse $false -IncludeInherited $true
            $ownershipInfo = if ($IncludeOwnership) { Get-RegistryOwnershipInfo -Path $Path -Recurse $false } else { $null }
            $inheritanceInfo = if ($IncludeInheritance) { Get-RegistryPermissionInheritance -Path $Path -Recurse $false } else { $null }
            $anomalies = if ($IncludeAnomalies) { Find-RegistryPermissionAnomaly -Path $Path -Recurse $false } else { $null }

            # CrÃ©er l'objet de rapport
            $reportData = [PSCustomObject]@{
                ReportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Path = $Path
                Permissions = $permissions
                OwnershipInfo = $ownershipInfo
                InheritanceInfo = $inheritanceInfo
                Anomalies = $anomalies
            }

            # GÃ©nÃ©rer le rapport selon le format spÃ©cifiÃ©
            switch ($OutputFormat) {
                "Text" {
                    $report = @"
==========================================================================
RAPPORT D'ANALYSE DES PERMISSIONS DE REGISTRE
==========================================================================
Date du rapport: $($reportData.ReportDate)
Chemin analysÃ©: $($reportData.Path)
==========================================================================

"@

                    # Ajouter les informations de permissions
                    $report += @"
PERMISSIONS:
----------------------------------------------------------
"@

                    foreach ($permission in $permissions) {
                        $report += @"

IdentitÃ©: $($permission.IdentityReference)
Type d'accÃ¨s: $($permission.AccessControlType)
Droits: $($permission.Rights -join ", ")
HÃ©ritÃ©: $($permission.IsInherited)
Niveau de risque: $($permission.RiskLevel)

"@
                    }

                    # Ajouter les informations de propriÃ©tÃ© si demandÃ©
                    if ($IncludeOwnership -and $ownershipInfo) {
                        $report += @"

PROPRIÃ‰TÃ‰:
----------------------------------------------------------
PropriÃ©taire: $($ownershipInfo.Owner.FullName)
Type de compte: $($ownershipInfo.Owner.AccountType)
Risque de sÃ©curitÃ©: $($ownershipInfo.SecurityRisk)
Niveau de risque: $($ownershipInfo.RiskLevel)

"@

                        if ($ownershipInfo.Recommendations.Count -gt 0) {
                            $report += "Recommandations: " + ($ownershipInfo.Recommendations -join ", ") + "`n"
                        }
                    }

                    # Ajouter les informations d'hÃ©ritage si demandÃ©
                    if ($IncludeInheritance -and $inheritanceInfo) {
                        $report += @"

HÃ‰RITAGE:
----------------------------------------------------------
HÃ©ritage activÃ©: $($inheritanceInfo.InheritanceEnabled)
Chemin parent: $($inheritanceInfo.ParentPath)
Permissions explicites: $($inheritanceInfo.ExplicitPermissions.Count)
Permissions hÃ©ritÃ©es: $($inheritanceInfo.InheritedPermissions.Count)

"@
                    }

                    # Ajouter les anomalies si demandÃ©
                    if ($IncludeAnomalies -and $anomalies -and $anomalies.Count -gt 0) {
                        $report += @"

ANOMALIES DÃ‰TECTÃ‰ES:
----------------------------------------------------------
"@

                        foreach ($anomaly in $anomalies) {
                            $report += @"

Type d'anomalie: $($anomaly.AnomalyType)
IdentitÃ©: $($anomaly.IdentityReference)
SÃ©vÃ©ritÃ©: $($anomaly.Severity)
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
        <p>Chemin analysÃ©: $($reportData.Path)</p>
    </div>

    <h2>Permissions</h2>
    <table>
        <tr>
            <th>IdentitÃ©</th>
            <th>Type d'accÃ¨s</th>
            <th>Droits</th>
            <th>HÃ©ritÃ©</th>
            <th>Niveau de risque</th>
        </tr>
"@

                    foreach ($permission in $permissions) {
                        $riskClass = switch ($permission.RiskLevel) {
                            "Ã‰levÃ©" { "risk-high" }
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

                    # Ajouter les informations de propriÃ©tÃ© si demandÃ©
                    if ($IncludeOwnership -and $ownershipInfo) {
                        $ownerRiskClass = switch ($ownershipInfo.RiskLevel) {
                            "Ã‰levÃ©" { "risk-high" }
                            "Moyen" { "risk-medium" }
                            "Faible" { "risk-low" }
                            default { "" }
                        }

                        $htmlReport += @"
    <h2>PropriÃ©tÃ©</h2>
    <table>
        <tr>
            <th>PropriÃ©taire</th>
            <th>Type de compte</th>
            <th>Risque de sÃ©curitÃ©</th>
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

                    # Ajouter les informations d'hÃ©ritage si demandÃ©
                    if ($IncludeInheritance -and $inheritanceInfo) {
                        $htmlReport += @"
    <h2>HÃ©ritage</h2>
    <table>
        <tr>
            <th>HÃ©ritage activÃ©</th>
            <th>Chemin parent</th>
            <th>Permissions explicites</th>
            <th>Permissions hÃ©ritÃ©es</th>
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

                    # Ajouter les anomalies si demandÃ©
                    if ($IncludeAnomalies -and $anomalies -and $anomalies.Count -gt 0) {
                        $htmlReport += @"
    <h2>Anomalies dÃ©tectÃ©es</h2>
    <table>
        <tr>
            <th>Type d'anomalie</th>
            <th>IdentitÃ©</th>
            <th>SÃ©vÃ©ritÃ©</th>
            <th>Description</th>
            <th>Recommandation</th>
        </tr>
"@

                        foreach ($anomaly in $anomalies) {
                            $anomalyRiskClass = switch ($anomaly.Severity) {
                                "Ã‰levÃ©e" { "risk-high" }
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
        <p>Rapport gÃ©nÃ©rÃ© par RegistryACLAnalyzer</p>
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
            Write-Error "Erreur lors de la gÃ©nÃ©ration du rapport de permissions de registre pour '$Path': $($_.Exception.Message)"
        }
    }
}

# Fonction pour corriger automatiquement les anomalies de permissions de registre
function Repair-RegistryPermissionAnomaly {
    <#
    .SYNOPSIS
        Corrige automatiquement les anomalies de permissions de registre dÃ©tectÃ©es.

    .DESCRIPTION
        Cette fonction corrige automatiquement les anomalies de permissions de registre dÃ©tectÃ©es
        par la fonction Find-RegistryPermissionAnomaly, comme les permissions trop permissives,
        les conflits, ou les hÃ©ritages interrompus.

    .PARAMETER Path
        Le chemin de la clÃ© de registre Ã  corriger (ex: "HKLM:\SOFTWARE\Microsoft").

    .PARAMETER AnomalyType
        Le type d'anomalie Ã  corriger. Si non spÃ©cifiÃ©, toutes les anomalies seront corrigÃ©es.
        Valeurs possibles : "HighRiskPermission", "PermissionConflict", "RedundantPermission", "InheritanceBreak".

    .PARAMETER WhatIf
        Indique si la fonction doit simuler les corrections sans les appliquer.

    .PARAMETER Force
        Force l'application des corrections sans demander de confirmation.

    .EXAMPLE
        Repair-RegistryPermissionAnomaly -Path "HKLM:\SOFTWARE\Microsoft" -AnomalyType "HighRiskPermission" -WhatIf

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
            Write-Error "Le chemin de registre '$Path' n'existe pas."
            return
        }

        # VÃ©rifier si l'utilisateur a les privilÃ¨ges d'administrateur
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) {
            Write-Warning "Cette fonction nÃ©cessite des privilÃ¨ges d'administrateur pour fonctionner correctement."
        }
    }

    process {
        try {
            $results = @()

            # DÃ©tecter les anomalies
            $anomalies = Find-RegistryPermissionAnomaly -Path $Path

            # Filtrer les anomalies par type si spÃ©cifiÃ©
            if ($AnomalyType -ne "All") {
                $anomalies = $anomalies | Where-Object { $_.AnomalyType -eq $AnomalyType }
            }

            if (-not $anomalies) {
                Write-Host "Aucune anomalie Ã  corriger pour le chemin '$Path'."
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

                        # Trouver la rÃ¨gle Ã  risque Ã©levÃ©
                        $highRiskRule = $acl.Access | Where-Object {
                            $_.IdentityReference.Value -eq $anomaly.IdentityReference
                        }

                        if ($highRiskRule) {
                            $correctionDescription = "Suppression de la permission Ã  risque Ã©levÃ© pour $($anomaly.IdentityReference)"

                            if ($Force -or $PSCmdlet.ShouldProcess($anomaly.Path, $correctionDescription)) {
                                # Supprimer la rÃ¨gle Ã  risque Ã©levÃ©
                                foreach ($rule in $highRiskRule) {
                                    $acl.RemoveAccessRule($rule)
                                }

                                # Ajouter une rÃ¨gle plus restrictive si nÃ©cessaire
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
                                $correctionInfo.CorrectionDescription = "$correctionDescription (non appliquÃ©)"
                            }
                        } else {
                            $correctionInfo.CorrectionDescription = "RÃ¨gle Ã  risque Ã©levÃ© non trouvÃ©e"
                        }
                    }

                    "PermissionConflict" {
                        # Obtenir l'ACL actuelle du chemin de l'anomalie
                        $acl = Get-Acl -Path $anomaly.Path

                        # Trouver les rÃ¨gles en conflit
                        $conflictRules = $acl.Access | Where-Object {
                            $_.IdentityReference.Value -eq $anomaly.IdentityReference
                        }

                        if ($conflictRules) {
                            $correctionDescription = "RÃ©solution du conflit de permissions pour $($anomaly.IdentityReference)"

                            if ($Force -or $PSCmdlet.ShouldProcess($anomaly.Path, $correctionDescription)) {
                                # Supprimer toutes les rÃ¨gles en conflit
                                foreach ($rule in $conflictRules) {
                                    $acl.RemoveAccessRule($rule)
                                }

                                # Ajouter une nouvelle rÃ¨gle consolidÃ©e
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
                        $acl = Get-Acl -Path $anomaly.Path

                        # Trouver les rÃ¨gles redondantes
                        $redundantRules = $acl.Access | Where-Object {
                            $_.IdentityReference.Value -eq $anomaly.IdentityReference
                        }

                        if ($redundantRules -and $redundantRules.Count -gt 1) {
                            $correctionDescription = "Consolidation des permissions redondantes pour $($anomaly.IdentityReference)"

                            if ($Force -or $PSCmdlet.ShouldProcess($anomaly.Path, $correctionDescription)) {
                                # Supprimer toutes les rÃ¨gles redondantes
                                foreach ($rule in $redundantRules) {
                                    $acl.RemoveAccessRule($rule)
                                }

                                # DÃ©terminer les droits combinÃ©s
                                $combinedRights = [System.Security.AccessControl.RegistryRights]::ReadKey

                                # Ajouter une nouvelle rÃ¨gle consolidÃ©e
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
                        $acl = Get-Acl -Path $anomaly.Path

                        $correctionDescription = "RÃ©activation de l'hÃ©ritage des permissions"

                        if ($Force -or $PSCmdlet.ShouldProcess($anomaly.Path, $correctionDescription)) {
                            # RÃ©activer l'hÃ©ritage
                            $acl.SetAccessRuleProtection($false, $true)  # Activer l'hÃ©ritage et conserver les rÃ¨gles existantes
                            Set-Acl -Path $anomaly.Path -AclObject $acl

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
            Write-Error "Erreur lors de la correction des anomalies de permissions de registre pour '$Path': $($_.Exception.Message)"
        }
    }
}

# Fonction pour comparer les permissions entre diffÃ©rentes clÃ©s de registre
function Compare-RegistryPermission {
    <#
    .SYNOPSIS
        Compare les permissions entre deux clÃ©s de registre.

    .DESCRIPTION
        Cette fonction compare les permissions entre deux clÃ©s de registre et identifie
        les diffÃ©rences, comme les permissions manquantes, supplÃ©mentaires ou modifiÃ©es.

    .PARAMETER ReferencePath
        Le chemin de la clÃ© de registre de rÃ©fÃ©rence pour la comparaison.

    .PARAMETER DifferencePath
        Le chemin de la clÃ© de registre Ã  comparer avec la rÃ©fÃ©rence.

    .PARAMETER IncludeInherited
        Indique si les permissions hÃ©ritÃ©es doivent Ãªtre incluses dans la comparaison.

    .PARAMETER Recurse
        Indique si la comparaison doit Ãªtre rÃ©cursive pour les sous-clÃ©s.

    .EXAMPLE
        Compare-RegistryPermission -ReferencePath "HKLM:\SOFTWARE\Microsoft" -DifferencePath "HKLM:\SOFTWARE\Classes" -IncludeInherited $true

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
        [bool]$IncludeInherited = $true,

        [Parameter(Mandatory = $false)]
        [bool]$Recurse = $false
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
            # Obtenir les permissions normalisÃ©es des deux chemins
            $referencePermissions = Get-NormalizedPermissions -Path $ReferencePath -IncludeInherited $IncludeInherited -Recurse $Recurse
            $differencePermissions = Get-NormalizedPermissions -Path $DifferencePath -IncludeInherited $IncludeInherited -Recurse $Recurse

            # CrÃ©er des collections pour les diffÃ©rences
            $missingPermissions = @()
            $additionalPermissions = @()
            $modifiedPermissions = @()

            # Comparer les permissions de rÃ©fÃ©rence avec les permissions de diffÃ©rence
            foreach ($refPerm in $referencePermissions) {
                $matchingPerm = $differencePermissions | Where-Object {
                    $_.RelativePath -eq $refPerm.RelativePath -and
                    $_.IdentityReference -eq $refPerm.IdentityReference -and
                    $_.AccessControlType -eq $refPerm.AccessControlType
                }

                if (-not $matchingPerm) {
                    # Permission manquante dans le chemin de diffÃ©rence
                    $missingPermissions += [PSCustomObject]@{
                        Path = $refPerm.RelativePath
                        IdentityReference = $refPerm.IdentityReference
                        AccessControlType = $refPerm.AccessControlType
                        Rights = $refPerm.Rights
                        IsInherited = $refPerm.IsInherited
                    }
                } elseif ($refPerm.Rights -ne $matchingPerm.Rights) {
                    # Permission modifiÃ©e
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

            # Trouver les permissions supplÃ©mentaires dans le chemin de diffÃ©rence
            foreach ($diffPerm in $differencePermissions) {
                $matchingPerm = $referencePermissions | Where-Object {
                    $_.RelativePath -eq $diffPerm.RelativePath -and
                    $_.IdentityReference -eq $diffPerm.IdentityReference -and
                    $_.AccessControlType -eq $diffPerm.AccessControlType
                }

                if (-not $matchingPerm) {
                    # Permission supplÃ©mentaire dans le chemin de diffÃ©rence
                    $additionalPermissions += [PSCustomObject]@{
                        Path = $diffPerm.RelativePath
                        IdentityReference = $diffPerm.IdentityReference
                        AccessControlType = $diffPerm.AccessControlType
                        Rights = $diffPerm.Rights
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
        Exporte les permissions d'une clÃ© de registre vers un fichier.

    .DESCRIPTION
        Cette fonction exporte les permissions d'une clÃ© de registre vers un fichier JSON, XML ou CSV,
        permettant de sauvegarder une configuration de sÃ©curitÃ© pour une restauration ultÃ©rieure.

    .PARAMETER Path
        Le chemin de la clÃ© de registre dont les permissions doivent Ãªtre exportÃ©es.

    .PARAMETER OutputPath
        Le chemin du fichier de sortie oÃ¹ les permissions seront exportÃ©es.

    .PARAMETER Format
        Le format du fichier d'exportation. Valeurs possibles : "JSON", "XML", "CSV".

    .PARAMETER Recurse
        Indique si l'exportation doit Ãªtre rÃ©cursive pour les sous-clÃ©s.

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
        # VÃ©rifier si le chemin existe
        if (-not (Test-Path -Path $Path)) {
            Write-Error "Le chemin de registre '$Path' n'existe pas."
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
            # Obtenir les permissions de registre
            $permissions = Get-RegistryPermission -Path $Path -Recurse $Recurse -IncludeInherited $true

            # Obtenir les informations d'hÃ©ritage
            $inheritanceInfo = Get-RegistryPermissionInheritance -Path $Path -Recurse $Recurse

            # CrÃ©er un objet d'exportation avec des mÃ©tadonnÃ©es
            $exportObject = [PSCustomObject]@{
                ExportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                SourcePath = $Path
                Recurse = $Recurse
                Permissions = $permissions
                InheritanceInfo = $inheritanceInfo
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

            Write-Host "Permissions de registre exportÃ©es avec succÃ¨s vers '$OutputPath'."
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
        Importe les permissions de registre depuis un fichier et les applique Ã  une clÃ© de registre.

    .DESCRIPTION
        Cette fonction importe les permissions de registre depuis un fichier JSON, XML ou CSV
        et les applique Ã  une clÃ© de registre spÃ©cifiÃ©e, permettant de restaurer une configuration de sÃ©curitÃ©.

    .PARAMETER InputPath
        Le chemin du fichier d'entrÃ©e contenant les permissions Ã  importer.

    .PARAMETER TargetPath
        Le chemin de la clÃ© de registre Ã  laquelle les permissions doivent Ãªtre appliquÃ©es.
        Si non spÃ©cifiÃ©, le chemin source original sera utilisÃ©.

    .PARAMETER Format
        Le format du fichier d'importation. Valeurs possibles : "JSON", "XML", "CSV".

    .PARAMETER WhatIf
        Indique si la fonction doit simuler l'importation sans appliquer les permissions.

    .PARAMETER Force
        Force l'application des permissions sans demander de confirmation.

    .EXAMPLE
        Import-RegistryPermission -InputPath "C:\Backup\RegistryPermissions.json" -TargetPath "HKLM:\SOFTWARE\Test" -Format "JSON" -WhatIf

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

        # VÃ©rifier si l'utilisateur a les privilÃ¨ges d'administrateur
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) {
            Write-Warning "Cette fonction nÃ©cessite des privilÃ¨ges d'administrateur pour fonctionner correctement."
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

                $targetItemPath = if ($relativePath -eq "") {
                    $actualTargetPath
                } else {
                    Join-Path -Path $actualTargetPath -ChildPath $relativePath
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
                    Rights = $perm.Rights
                    Applied = $false
                }

                # Appliquer la permission si ce n'est pas une permission hÃ©ritÃ©e
                if (-not $perm.IsInherited) {
                    $description = "Application de la permission '$($perm.Rights -join ", ")' pour '$($perm.IdentityReference)' sur '$targetItemPath'"

                    if ($Force -or $PSCmdlet.ShouldProcess($targetItemPath, $description)) {
                        try {
                            # Obtenir l'ACL actuelle
                            $acl = Get-Acl -Path $targetItemPath

                            # CrÃ©er la rÃ¨gle d'accÃ¨s
                            $identity = New-Object System.Security.Principal.NTAccount($perm.IdentityReference)

                            # DÃ©terminer les droits de registre
                            $registryRights = [System.Security.AccessControl.RegistryRights]::ReadKey

                            # CrÃ©er la rÃ¨gle d'accÃ¨s
                            $rule = New-Object System.Security.AccessControl.RegistryAccessRule(
                                $identity,
                                $registryRights,
                                [System.Security.AccessControl.InheritanceFlags]::ContainerInherit,
                                [System.Security.AccessControl.PropagationFlags]::None,
                                [System.Security.AccessControl.AccessControlType]::Allow
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

            # Appliquer les informations d'hÃ©ritage si disponibles
            if ($importObject.InheritanceInfo) {
                foreach ($inhInfo in $importObject.InheritanceInfo) {
                    # DÃ©terminer le chemin relatif et le chemin cible complet
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

                    # VÃ©rifier si le chemin cible existe
                    if (-not (Test-Path -Path $targetItemPath)) {
                        Write-Warning "Le chemin cible '$targetItemPath' n'existe pas et sera ignorÃ©."
                        continue
                    }

                    $inheritanceInfo = [PSCustomObject]@{
                        SourcePath = $inhInfo.Path
                        TargetPath = $targetItemPath
                        InheritanceEnabled = $inhInfo.InheritanceEnabled
                        Applied = $false
                    }

                    $description = if ($inhInfo.InheritanceEnabled) {
                        "Activation de l'hÃ©ritage des permissions sur '$targetItemPath'"
                    } else {
                        "DÃ©sactivation de l'hÃ©ritage des permissions sur '$targetItemPath'"
                    }

                    if ($Force -or $PSCmdlet.ShouldProcess($targetItemPath, $description)) {
                        try {
                            # Obtenir l'ACL actuelle
                            $acl = Get-Acl -Path $targetItemPath

                            # Appliquer l'Ã©tat d'hÃ©ritage
                            $acl.SetAccessRuleProtection(-not $inhInfo.InheritanceEnabled, $true)
                            Set-Acl -Path $targetItemPath -AclObject $acl

                            $inheritanceInfo.Applied = $true
                        } catch {
                            Write-Warning "Erreur lors de l'application de l'hÃ©ritage sur '$targetItemPath': $($_.Exception.Message)"
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

# Exporter les fonctions si le script est importÃ© comme module
if ($MyInvocation.Line -match '^\. ') {
    # Le script est sourcÃ© directement, pas besoin d'exporter
} elseif ($MyInvocation.MyCommand.Path -eq $null) {
    # Le script est exÃ©cutÃ© directement, pas besoin d'exporter
} else {
    # Le script est importÃ© comme module, exporter les fonctions
    Export-ModuleMember -Function Get-RegistryPermission, Get-RegistryPermissionInheritance, Get-RegistryOwnershipInfo, Find-RegistryPermissionAnomaly, New-RegistryPermissionReport, Repair-RegistryPermissionAnomaly, Compare-RegistryPermission, Export-RegistryPermission, Import-RegistryPermission
}
