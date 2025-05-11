<#
.SYNOPSIS
    Module de délégation de permissions pour le partage des vues.

.DESCRIPTION
    Ce module implémente le système de délégation de permissions qui permet
    aux utilisateurs de déléguer leurs droits à d'autres utilisateurs.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Importer le module de gestion des permissions
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$permissionManagerPath = Join-Path -Path $scriptDir -ChildPath "PermissionManager.ps1"

if (Test-Path -Path $permissionManagerPath) {
    . $permissionManagerPath
}
else {
    throw "Le module PermissionManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $permissionManagerPath"
}

# Classe pour représenter le système de délégation de permissions
class PermissionDelegation {
    # Propriétés
    [string]$DelegationStorePath
    [bool]$EnableDebug

    # Constructeur par défaut
    PermissionDelegation() {
        $this.DelegationStorePath = Join-Path -Path $env:TEMP -ChildPath "ViewSharing\DelegationStore"
        $this.EnableDebug = $false
    }

    # Constructeur avec paramètres
    PermissionDelegation([string]$delegationStorePath, [bool]$enableDebug) {
        $this.DelegationStorePath = $delegationStorePath
        $this.EnableDebug = $enableDebug
    }

    # Méthode pour écrire des messages de débogage
    [void] WriteDebug([string]$message) {
        if ($this.EnableDebug) {
            Write-Host "[DEBUG] [PermissionDelegation] $message" -ForegroundColor Cyan
        }
    }

    # Méthode pour initialiser le stockage des délégations
    [void] InitializeDelegationStore() {
        $this.WriteDebug("Initialisation du stockage des délégations")
        
        try {
            # Créer le répertoire de stockage s'il n'existe pas
            if (-not (Test-Path -Path $this.DelegationStorePath)) {
                New-Item -Path $this.DelegationStorePath -ItemType Directory -Force | Out-Null
                $this.WriteDebug("Répertoire de stockage créé: $($this.DelegationStorePath)")
            }
            
            $this.WriteDebug("Initialisation du stockage des délégations terminée")
        }
        catch {
            $this.WriteDebug("Erreur lors de l'initialisation du stockage des délégations - $($_.Exception.Message)")
            throw "Erreur lors de l'initialisation du stockage des délégations - $($_.Exception.Message)"
        }
    }

    # Méthode pour vérifier si un utilisateur peut déléguer une permission
    [bool] CanDelegatePermission([string]$resourceId, [string]$delegator, [string]$permission) {
        $this.WriteDebug("Vérification si $delegator peut déléguer la permission $permission sur la ressource $resourceId")
        
        # Vérifier si l'utilisateur a la permission ADMIN_PERMISSIONS
        $permManager = New-PermissionManager -EnableDebug:$this.EnableDebug
        $hasAdminPermission = $permManager.HasPermission($resourceId, $delegator, "ADMIN_PERMISSIONS")
        
        if ($hasAdminPermission) {
            $this.WriteDebug("$delegator a la permission ADMIN_PERMISSIONS et peut déléguer $permission")
            return $true
        }
        
        # Vérifier si l'utilisateur a la permission qu'il souhaite déléguer
        $hasPermission = $permManager.HasPermission($resourceId, $delegator, $permission)
        
        if (-not $hasPermission) {
            $this.WriteDebug("$delegator n'a pas la permission $permission et ne peut pas la déléguer")
            return $false
        }
        
        # Vérifier si l'utilisateur a déjà délégué cette permission
        $delegations = $this.GetDelegations($resourceId, $delegator)
        
        foreach ($delegation in $delegations) {
            if ($delegation.Permission -eq $permission) {
                $this.WriteDebug("$delegator a déjà délégué la permission $permission")
                return $true
            }
        }
        
        $this.WriteDebug("$delegator peut déléguer la permission $permission")
        return $true
    }

    # Méthode pour créer une délégation de permission
    [bool] CreateDelegation([string]$resourceId, [string]$delegator, [string]$delegatee, [string]$permission, [datetime]$expirationDate) {
        $this.WriteDebug("Création d'une délégation de permission $permission de $delegator à $delegatee sur la ressource $resourceId")
        
        try {
            # Initialiser le stockage des délégations
            $this.InitializeDelegationStore()
            
            # Vérifier si l'utilisateur peut déléguer cette permission
            if (-not $this.CanDelegatePermission($resourceId, $delegator, $permission)) {
                $this.WriteDebug("$delegator ne peut pas déléguer la permission $permission")
                return $false
            }
            
            # Créer l'objet délégation
            $delegation = @{
                ResourceId = $resourceId
                Delegator = $delegator
                Delegatee = $delegatee
                Permission = $permission
                CreatedAt = (Get-Date).ToString('o')
                ExpirationDate = $expirationDate.ToString('o')
                IsActive = $true
            }
            
            # Enregistrer la délégation
            $delegationFilePath = Join-Path -Path $this.DelegationStorePath -ChildPath "$resourceId-$delegator-$delegatee-$permission.json"
            $delegationJson = $delegation | ConvertTo-Json
            $delegationJson | Out-File -FilePath $delegationFilePath -Encoding utf8
            
            # Accorder la permission au délégataire
            $permManager = New-PermissionManager -EnableDebug:$this.EnableDebug
            $result = $permManager.GrantPermission($resourceId, $delegatee, $permission, $delegator)
            
            if (-not $result) {
                $this.WriteDebug("Échec de l'attribution de la permission $permission à $delegatee")
                return $false
            }
            
            $this.WriteDebug("Délégation créée avec succès")
            return $true
        }
        catch {
            $this.WriteDebug("Erreur lors de la création de la délégation - $($_.Exception.Message)")
            throw "Erreur lors de la création de la délégation - $($_.Exception.Message)"
        }
    }

    # Méthode pour révoquer une délégation de permission
    [bool] RevokeDelegation([string]$resourceId, [string]$delegator, [string]$delegatee, [string]$permission) {
        $this.WriteDebug("Révocation de la délégation de permission $permission de $delegator à $delegatee sur la ressource $resourceId")
        
        try {
            # Vérifier si la délégation existe
            $delegationFilePath = Join-Path -Path $this.DelegationStorePath -ChildPath "$resourceId-$delegator-$delegatee-$permission.json"
            
            if (-not (Test-Path -Path $delegationFilePath)) {
                $this.WriteDebug("La délégation n'existe pas")
                return $false
            }
            
            # Charger la délégation
            $delegationJson = Get-Content -Path $delegationFilePath -Raw
            $delegation = $delegationJson | ConvertFrom-Json
            
            # Vérifier si la délégation est active
            if (-not $delegation.IsActive) {
                $this.WriteDebug("La délégation est déjà inactive")
                return $false
            }
            
            # Désactiver la délégation
            $delegation.IsActive = $false
            
            # Enregistrer la délégation mise à jour
            $delegationJson = $delegation | ConvertTo-Json
            $delegationJson | Out-File -FilePath $delegationFilePath -Encoding utf8
            
            # Révoquer la permission du délégataire
            $permManager = New-PermissionManager -EnableDebug:$this.EnableDebug
            $result = $permManager.RevokePermission($resourceId, $delegatee, $permission, $delegator)
            
            if (-not $result) {
                $this.WriteDebug("Échec de la révocation de la permission $permission de $delegatee")
                return $false
            }
            
            $this.WriteDebug("Délégation révoquée avec succès")
            return $true
        }
        catch {
            $this.WriteDebug("Erreur lors de la révocation de la délégation - $($_.Exception.Message)")
            throw "Erreur lors de la révocation de la délégation - $($_.Exception.Message)"
        }
    }

    # Méthode pour obtenir toutes les délégations d'un utilisateur
    [array] GetDelegations([string]$resourceId, [string]$delegator) {
        $this.WriteDebug("Récupération des délégations pour $delegator sur la ressource $resourceId")
        
        try {
            $delegations = @()
            
            # Vérifier si le répertoire de stockage existe
            if (-not (Test-Path -Path $this.DelegationStorePath)) {
                $this.WriteDebug("Le répertoire de stockage n'existe pas")
                return $delegations
            }
            
            # Rechercher les fichiers de délégation
            $delegationFiles = Get-ChildItem -Path $this.DelegationStorePath -Filter "$resourceId-$delegator-*.json"
            
            foreach ($file in $delegationFiles) {
                $delegationJson = Get-Content -Path $file.FullName -Raw
                $delegation = $delegationJson | ConvertFrom-Json
                
                # Vérifier si la délégation est active et non expirée
                if ($delegation.IsActive) {
                    $expirationDate = [datetime]::Parse($delegation.ExpirationDate)
                    
                    if ($expirationDate -gt (Get-Date)) {
                        $delegations += $delegation
                    }
                    else {
                        $this.WriteDebug("La délégation est expirée")
                        
                        # Désactiver la délégation expirée
                        $delegation.IsActive = $false
                        $delegationJson = $delegation | ConvertTo-Json
                        $delegationJson | Out-File -FilePath $file.FullName -Encoding utf8
                        
                        # Révoquer la permission du délégataire
                        $permManager = New-PermissionManager -EnableDebug:$this.EnableDebug
                        $permManager.RevokePermission($resourceId, $delegation.Delegatee, $delegation.Permission, $delegator)
                    }
                }
            }
            
            $this.WriteDebug("$($delegations.Count) délégations récupérées")
            return $delegations
        }
        catch {
            $this.WriteDebug("Erreur lors de la récupération des délégations - $($_.Exception.Message)")
            throw "Erreur lors de la récupération des délégations - $($_.Exception.Message)"
        }
    }

    # Méthode pour obtenir toutes les délégations reçues par un utilisateur
    [array] GetReceivedDelegations([string]$resourceId, [string]$delegatee) {
        $this.WriteDebug("Récupération des délégations reçues par $delegatee sur la ressource $resourceId")
        
        try {
            $delegations = @()
            
            # Vérifier si le répertoire de stockage existe
            if (-not (Test-Path -Path $this.DelegationStorePath)) {
                $this.WriteDebug("Le répertoire de stockage n'existe pas")
                return $delegations
            }
            
            # Rechercher les fichiers de délégation
            $delegationFiles = Get-ChildItem -Path $this.DelegationStorePath -Filter "$resourceId-*-$delegatee-*.json"
            
            foreach ($file in $delegationFiles) {
                $delegationJson = Get-Content -Path $file.FullName -Raw
                $delegation = $delegationJson | ConvertFrom-Json
                
                # Vérifier si la délégation est active et non expirée
                if ($delegation.IsActive) {
                    $expirationDate = [datetime]::Parse($delegation.ExpirationDate)
                    
                    if ($expirationDate -gt (Get-Date)) {
                        $delegations += $delegation
                    }
                    else {
                        $this.WriteDebug("La délégation est expirée")
                        
                        # Désactiver la délégation expirée
                        $delegation.IsActive = $false
                        $delegationJson = $delegation | ConvertTo-Json
                        $delegationJson | Out-File -FilePath $file.FullName -Encoding utf8
                        
                        # Révoquer la permission du délégataire
                        $permManager = New-PermissionManager -EnableDebug:$this.EnableDebug
                        $permManager.RevokePermission($resourceId, $delegation.Delegatee, $delegation.Permission, $delegation.Delegator)
                    }
                }
            }
            
            $this.WriteDebug("$($delegations.Count) délégations reçues récupérées")
            return $delegations
        }
        catch {
            $this.WriteDebug("Erreur lors de la récupération des délégations reçues - $($_.Exception.Message)")
            throw "Erreur lors de la récupération des délégations reçues - $($_.Exception.Message)"
        }
    }
}

# Fonction pour créer un nouveau système de délégation de permissions
function New-PermissionDelegation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$DelegationStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\DelegationStore"),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )
    
    return [PermissionDelegation]::new($DelegationStorePath, $EnableDebug)
}

# Fonction pour créer une délégation de permission
function New-PermissionDelegationEntry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceId,
        
        [Parameter(Mandatory = $true)]
        [string]$Delegator,
        
        [Parameter(Mandatory = $true)]
        [string]$Delegatee,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("READ_BASIC", "READ_STANDARD", "READ_EXTENDED", "WRITE_COMMENT", "WRITE_CONTENT", "WRITE_STRUCTURE", "ADMIN_SHARE", "ADMIN_PERMISSIONS", "ADMIN_OWNERSHIP")]
        [string]$Permission,
        
        [Parameter(Mandatory = $false)]
        [datetime]$ExpirationDate = (Get-Date).AddDays(30),
        
        [Parameter(Mandatory = $false)]
        [string]$DelegationStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\DelegationStore"),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )
    
    $delegation = New-PermissionDelegation -DelegationStorePath $DelegationStorePath -EnableDebug:$EnableDebug
    return $delegation.CreateDelegation($ResourceId, $Delegator, $Delegatee, $Permission, $ExpirationDate)
}

# Fonction pour révoquer une délégation de permission
function Remove-PermissionDelegationEntry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceId,
        
        [Parameter(Mandatory = $true)]
        [string]$Delegator,
        
        [Parameter(Mandatory = $true)]
        [string]$Delegatee,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("READ_BASIC", "READ_STANDARD", "READ_EXTENDED", "WRITE_COMMENT", "WRITE_CONTENT", "WRITE_STRUCTURE", "ADMIN_SHARE", "ADMIN_PERMISSIONS", "ADMIN_OWNERSHIP")]
        [string]$Permission,
        
        [Parameter(Mandatory = $false)]
        [string]$DelegationStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\DelegationStore"),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )
    
    $delegation = New-PermissionDelegation -DelegationStorePath $DelegationStorePath -EnableDebug:$EnableDebug
    return $delegation.RevokeDelegation($ResourceId, $Delegator, $Delegatee, $Permission)
}

# Fonction pour obtenir les délégations d'un utilisateur
function Get-UserDelegations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceId,
        
        [Parameter(Mandatory = $true)]
        [string]$Delegator,
        
        [Parameter(Mandatory = $false)]
        [string]$DelegationStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\DelegationStore"),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )
    
    $delegation = New-PermissionDelegation -DelegationStorePath $DelegationStorePath -EnableDebug:$EnableDebug
    return $delegation.GetDelegations($ResourceId, $Delegator)
}

# Fonction pour obtenir les délégations reçues par un utilisateur
function Get-ReceivedDelegations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceId,
        
        [Parameter(Mandatory = $true)]
        [string]$Delegatee,
        
        [Parameter(Mandatory = $false)]
        [string]$DelegationStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\DelegationStore"),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )
    
    $delegation = New-PermissionDelegation -DelegationStorePath $DelegationStorePath -EnableDebug:$EnableDebug
    return $delegation.GetReceivedDelegations($ResourceId, $Delegatee)
}

# Exporter les fonctions
# Export-ModuleMember -Function New-PermissionDelegation, New-PermissionDelegationEntry, Remove-PermissionDelegationEntry, Get-UserDelegations, Get-ReceivedDelegations
