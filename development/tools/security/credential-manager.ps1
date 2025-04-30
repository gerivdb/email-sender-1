<#
.SYNOPSIS
    Gestionnaire de credentials pour les API keys et autres informations sensibles.

.DESCRIPTION
    Ce script fournit des fonctions pour gérer les credentials de manière sécurisée.
    Il utilise le SecretManagement de PowerShell lorsque disponible, sinon il utilise
    des variables d'environnement ou un fichier chiffré.

.NOTES
    Auteur: Security Team
    Version: 1.0
    Date de création: 2025-06-02
#>

# Fonction pour récupérer un credential
function Get-SecureCredential {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [string]$DefaultValue = $null,
        
        [Parameter(Mandatory = $false)]
        [switch]$Required
    )
    
    # Vérifier si le module SecretManagement est disponible
    $useSecretManagement = $false
    if (Get-Module -ListAvailable -Name Microsoft.PowerShell.SecretManagement) {
        $useSecretManagement = $true
    }
    
    # Essayer de récupérer le credential depuis SecretManagement
    if ($useSecretManagement) {
        try {
            $secret = Get-Secret -Name $Name -ErrorAction SilentlyContinue
            if ($secret) {
                return $secret
            }
        } catch {
            Write-Verbose "Impossible de récupérer le credential depuis SecretManagement : $_"
        }
    }
    
    # Essayer de récupérer le credential depuis les variables d'environnement
    $envValue = [Environment]::GetEnvironmentVariable($Name)
    if ($envValue) {
        return $envValue
    }
    
    # Essayer de récupérer le credential depuis le fichier de credentials
    $credentialsFile = Join-Path -Path $PSScriptRoot -ChildPath "credentials.json"
    if (Test-Path -Path $credentialsFile) {
        try {
            $credentials = Get-Content -Path $credentialsFile -Raw | ConvertFrom-Json
            if ($credentials.PSObject.Properties.Name -contains $Name) {
                return $credentials.$Name
            }
        } catch {
            Write-Verbose "Impossible de récupérer le credential depuis le fichier de credentials : $_"
        }
    }
    
    # Si un credential par défaut est fourni, l'utiliser
    if ($DefaultValue) {
        return $DefaultValue
    }
    
    # Si le credential est requis et qu'il n'a pas été trouvé, lever une exception
    if ($Required) {
        throw "Le credential '$Name' est requis mais n'a pas été trouvé."
    }
    
    # Sinon, retourner null
    return $null
}

# Fonction pour enregistrer un credential
function Set-SecureCredential {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$Value,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("SecretManagement", "Environment", "File")]
        [string]$StorageType = "Environment"
    )
    
    # Enregistrer le credential dans SecretManagement
    if ($StorageType -eq "SecretManagement") {
        if (Get-Module -ListAvailable -Name Microsoft.PowerShell.SecretManagement) {
            try {
                Set-Secret -Name $Name -Secret $Value
                Write-Host "Credential '$Name' enregistré dans SecretManagement." -ForegroundColor Green
                return $true
            } catch {
                Write-Warning "Impossible d'enregistrer le credential dans SecretManagement : $_"
            }
        } else {
            Write-Warning "Le module SecretManagement n'est pas disponible. Utilisation du stockage alternatif."
        }
    }
    
    # Enregistrer le credential dans les variables d'environnement
    if ($StorageType -eq "Environment") {
        try {
            [Environment]::SetEnvironmentVariable($Name, $Value, "Process")
            Write-Host "Credential '$Name' enregistré dans les variables d'environnement (Process)." -ForegroundColor Green
            return $true
        } catch {
            Write-Warning "Impossible d'enregistrer le credential dans les variables d'environnement : $_"
        }
    }
    
    # Enregistrer le credential dans le fichier de credentials
    if ($StorageType -eq "File") {
        $credentialsFile = Join-Path -Path $PSScriptRoot -ChildPath "credentials.json"
        
        # Créer ou charger le fichier de credentials
        if (Test-Path -Path $credentialsFile) {
            try {
                $credentials = Get-Content -Path $credentialsFile -Raw | ConvertFrom-Json
            } catch {
                $credentials = [PSCustomObject]@{}
            }
        } else {
            $credentials = [PSCustomObject]@{}
        }
        
        # Ajouter ou mettre à jour le credential
        $credentials | Add-Member -MemberType NoteProperty -Name $Name -Value $Value -Force
        
        # Enregistrer le fichier de credentials
        try {
            $credentials | ConvertTo-Json | Set-Content -Path $credentialsFile -Encoding UTF8
            Write-Host "Credential '$Name' enregistré dans le fichier de credentials." -ForegroundColor Green
            return $true
        } catch {
            Write-Warning "Impossible d'enregistrer le credential dans le fichier de credentials : $_"
        }
    }
    
    # Si aucun stockage n'a fonctionné, retourner false
    return $false
}

# Fonction pour supprimer un credential
function Remove-SecureCredential {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("SecretManagement", "Environment", "File", "All")]
        [string]$StorageType = "All"
    )
    
    $removed = $false
    
    # Supprimer le credential de SecretManagement
    if ($StorageType -eq "SecretManagement" -or $StorageType -eq "All") {
        if (Get-Module -ListAvailable -Name Microsoft.PowerShell.SecretManagement) {
            try {
                if (Get-Secret -Name $Name -ErrorAction SilentlyContinue) {
                    Remove-Secret -Name $Name
                    Write-Host "Credential '$Name' supprimé de SecretManagement." -ForegroundColor Green
                    $removed = $true
                }
            } catch {
                Write-Warning "Impossible de supprimer le credential de SecretManagement : $_"
            }
        }
    }
    
    # Supprimer le credential des variables d'environnement
    if ($StorageType -eq "Environment" -or $StorageType -eq "All") {
        try {
            if ([Environment]::GetEnvironmentVariable($Name)) {
                [Environment]::SetEnvironmentVariable($Name, $null, "Process")
                Write-Host "Credential '$Name' supprimé des variables d'environnement (Process)." -ForegroundColor Green
                $removed = $true
            }
        } catch {
            Write-Warning "Impossible de supprimer le credential des variables d'environnement : $_"
        }
    }
    
    # Supprimer le credential du fichier de credentials
    if ($StorageType -eq "File" -or $StorageType -eq "All") {
        $credentialsFile = Join-Path -Path $PSScriptRoot -ChildPath "credentials.json"
        
        if (Test-Path -Path $credentialsFile) {
            try {
                $credentials = Get-Content -Path $credentialsFile -Raw | ConvertFrom-Json
                
                if ($credentials.PSObject.Properties.Name -contains $Name) {
                    $credentials.PSObject.Properties.Remove($Name)
                    $credentials | ConvertTo-Json | Set-Content -Path $credentialsFile -Encoding UTF8
                    Write-Host "Credential '$Name' supprimé du fichier de credentials." -ForegroundColor Green
                    $removed = $true
                }
            } catch {
                Write-Warning "Impossible de supprimer le credential du fichier de credentials : $_"
            }
        }
    }
    
    return $removed
}

# Fonction pour lister tous les credentials disponibles
function Get-SecureCredentialList {
    [CmdletBinding()]
    param ()
    
    $credentialList = @()
    
    # Récupérer les credentials depuis SecretManagement
    if (Get-Module -ListAvailable -Name Microsoft.PowerShell.SecretManagement) {
        try {
            $secretManagementCredentials = Get-SecretInfo | Select-Object -ExpandProperty Name
            foreach ($name in $secretManagementCredentials) {
                $credentialList += [PSCustomObject]@{
                    Name = $name
                    Source = "SecretManagement"
                }
            }
        } catch {
            Write-Warning "Impossible de récupérer les credentials depuis SecretManagement : $_"
        }
    }
    
    # Récupérer les credentials depuis le fichier de credentials
    $credentialsFile = Join-Path -Path $PSScriptRoot -ChildPath "credentials.json"
    if (Test-Path -Path $credentialsFile) {
        try {
            $credentials = Get-Content -Path $credentialsFile -Raw | ConvertFrom-Json
            foreach ($name in $credentials.PSObject.Properties.Name) {
                $credentialList += [PSCustomObject]@{
                    Name = $name
                    Source = "File"
                }
            }
        } catch {
            Write-Warning "Impossible de récupérer les credentials depuis le fichier de credentials : $_"
        }
    }
    
    return $credentialList
}

# Exporter les fonctions
Export-ModuleMember -Function Get-SecureCredential, Set-SecureCredential, Remove-SecureCredential, Get-SecureCredentialList
