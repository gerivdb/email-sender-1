function Get-UserInfo {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Username,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeGroups
    )
    
    Write-Verbose "Récupération des informations pour l'utilisateur: $Username"
    
    $user = Get-User -Identity $Username
    $result = [PSCustomObject]@{
        Username = $user.SamAccountName
        DisplayName = $user.DisplayName
        Email = $user.EmailAddress
        Enabled = $user.Enabled
    }
    
    if ($IncludeGroups) {
        $groups = Get-UserGroups -Username $Username
        $result | Add-Member -MemberType NoteProperty -Name "Groups" -Value $groups
    }
    
    return $result
}

function Get-User {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Identity
    )
    
    Write-Verbose "Récupération de l'utilisateur: $Identity"
    
    # Simulation de récupération d'utilisateur
    return [PSCustomObject]@{
        SamAccountName = $Identity
        DisplayName = "Utilisateur $Identity"
        EmailAddress = "$Identity@example.com"
        Enabled = $true
    }
}

function Get-UserGroups {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Username
    )
    
    Write-Verbose "Récupération des groupes pour l'utilisateur: $Username"
    
    # Simulation de récupération de groupes
    return @(
        "Utilisateurs",
        "Développeurs",
        "Accès VPN"
    )
}

function Remove-UserAccess {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Username
    )
    
    Write-Verbose "Suppression des accès pour l'utilisateur: $Username"
    
    # Cette fonction n'est pas appelée dans ce script
}

# Appel de fonction en dehors d'une fonction
$userInfo = Get-UserInfo -Username "jdoe" -IncludeGroups
Write-Output $userInfo
