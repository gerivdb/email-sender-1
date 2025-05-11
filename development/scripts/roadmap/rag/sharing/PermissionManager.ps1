<#
.SYNOPSIS
    Gestionnaire de permissions avancées pour le partage des vues.

.DESCRIPTION
    Ce module implémente le gestionnaire de permissions avancées qui permet de gérer
    les différents niveaux de permissions pour le partage des vues.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Importer le module de contrôle d'accès
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$accessControlManagerPath = Join-Path -Path $scriptDir -ChildPath "AccessControlManager.ps1"

if (Test-Path -Path $accessControlManagerPath) {
    . $accessControlManagerPath
}
else {
    throw "Le module AccessControlManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $accessControlManagerPath"
}

# Classe pour représenter le gestionnaire de permissions avancées
class PermissionManager {
    # Propriétés
    [hashtable]$PermissionLevels
    [string]$PermissionStorePath
    [bool]$EnableDebug

    # Constructeur par défaut
    PermissionManager() {
        $this.PermissionLevels = @{
            # Permissions de lecture
            "READ_BASIC" = @{
                Value = 1
                Description = "Lecture de base (métadonnées uniquement)"
                Category = "READ"
            }
            "READ_STANDARD" = @{
                Value = 2
                Description = "Lecture standard (contenu complet)"
                Category = "READ"
            }
            "READ_EXTENDED" = @{
                Value = 4
                Description = "Lecture étendue (historique et versions)"
                Category = "READ"
            }
            
            # Permissions d'écriture
            "WRITE_COMMENT" = @{
                Value = 8
                Description = "Écriture de commentaires"
                Category = "WRITE"
            }
            "WRITE_CONTENT" = @{
                Value = 16
                Description = "Modification du contenu"
                Category = "WRITE"
            }
            "WRITE_STRUCTURE" = @{
                Value = 32
                Description = "Modification de la structure"
                Category = "WRITE"
            }
            
            # Permissions d'administration
            "ADMIN_SHARE" = @{
                Value = 64
                Description = "Partage avec d'autres utilisateurs"
                Category = "ADMIN"
            }
            "ADMIN_PERMISSIONS" = @{
                Value = 128
                Description = "Gestion des permissions"
                Category = "ADMIN"
            }
            "ADMIN_OWNERSHIP" = @{
                Value = 256
                Description = "Transfert de propriété"
                Category = "ADMIN"
            }
        }
        
        $this.PermissionStorePath = Join-Path -Path $env:TEMP -ChildPath "ViewSharing\PermissionStore"
        $this.EnableDebug = $false
    }

    # Constructeur avec paramètres
    PermissionManager([string]$permissionStorePath, [bool]$enableDebug) {
        $this.PermissionLevels = @{
            # Permissions de lecture
            "READ_BASIC" = @{
                Value = 1
                Description = "Lecture de base (métadonnées uniquement)"
                Category = "READ"
            }
            "READ_STANDARD" = @{
                Value = 2
                Description = "Lecture standard (contenu complet)"
                Category = "READ"
            }
            "READ_EXTENDED" = @{
                Value = 4
                Description = "Lecture étendue (historique et versions)"
                Category = "READ"
            }
            
            # Permissions d'écriture
            "WRITE_COMMENT" = @{
                Value = 8
                Description = "Écriture de commentaires"
                Category = "WRITE"
            }
            "WRITE_CONTENT" = @{
                Value = 16
                Description = "Modification du contenu"
                Category = "WRITE"
            }
            "WRITE_STRUCTURE" = @{
                Value = 32
                Description = "Modification de la structure"
                Category = "WRITE"
            }
            
            # Permissions d'administration
            "ADMIN_SHARE" = @{
                Value = 64
                Description = "Partage avec d'autres utilisateurs"
                Category = "ADMIN"
            }
            "ADMIN_PERMISSIONS" = @{
                Value = 128
                Description = "Gestion des permissions"
                Category = "ADMIN"
            }
            "ADMIN_OWNERSHIP" = @{
                Value = 256
                Description = "Transfert de propriété"
                Category = "ADMIN"
            }
        }
        
        $this.PermissionStorePath = $permissionStorePath
        $this.EnableDebug = $enableDebug
    }

    # Méthode pour écrire des messages de débogage
    [void] WriteDebug([string]$message) {
        if ($this.EnableDebug) {
            Write-Host "[DEBUG] [PermissionManager] $message" -ForegroundColor Cyan
        }
    }

    # Méthode pour initialiser le stockage des permissions
    [void] InitializePermissionStore() {
        $this.WriteDebug("Initialisation du stockage des permissions")
        
        try {
            # Créer le répertoire de stockage s'il n'existe pas
            if (-not (Test-Path -Path $this.PermissionStorePath)) {
                New-Item -Path $this.PermissionStorePath -ItemType Directory -Force | Out-Null
                $this.WriteDebug("Répertoire de stockage créé: $($this.PermissionStorePath)")
            }
            
            # Créer les sous-répertoires pour chaque catégorie de permission
            $readStorePath = Join-Path -Path $this.PermissionStorePath -ChildPath "Read"
            $writeStorePath = Join-Path -Path $this.PermissionStorePath -ChildPath "Write"
            $adminStorePath = Join-Path -Path $this.PermissionStorePath -ChildPath "Admin"
            
            if (-not (Test-Path -Path $readStorePath)) {
                New-Item -Path $readStorePath -ItemType Directory -Force | Out-Null
                $this.WriteDebug("Répertoire de stockage des permissions de lecture créé: $readStorePath")
            }
            
            if (-not (Test-Path -Path $writeStorePath)) {
                New-Item -Path $writeStorePath -ItemType Directory -Force | Out-Null
                $this.WriteDebug("Répertoire de stockage des permissions d'écriture créé: $writeStorePath")
            }
            
            if (-not (Test-Path -Path $adminStorePath)) {
                New-Item -Path $adminStorePath -ItemType Directory -Force | Out-Null
                $this.WriteDebug("Répertoire de stockage des permissions d'administration créé: $adminStorePath")
            }
            
            $this.WriteDebug("Initialisation du stockage des permissions terminée")
        }
        catch {
            $this.WriteDebug("Erreur lors de l'initialisation du stockage des permissions - $($_.Exception.Message)")
            throw "Erreur lors de l'initialisation du stockage des permissions - $($_.Exception.Message)"
        }
    }

    # Méthode pour obtenir la valeur numérique d'une permission
    [int] GetPermissionValue([string]$permissionName) {
        if ($this.PermissionLevels.ContainsKey($permissionName)) {
            return $this.PermissionLevels[$permissionName].Value
        }
        
        return 0
    }

    # Méthode pour obtenir la catégorie d'une permission
    [string] GetPermissionCategory([string]$permissionName) {
        if ($this.PermissionLevels.ContainsKey($permissionName)) {
            return $this.PermissionLevels[$permissionName].Category
        }
        
        return ""
    }

    # Méthode pour obtenir la description d'une permission
    [string] GetPermissionDescription([string]$permissionName) {
        if ($this.PermissionLevels.ContainsKey($permissionName)) {
            return $this.PermissionLevels[$permissionName].Description
        }
        
        return ""
    }

    # Méthode pour obtenir toutes les permissions d'une catégorie
    [array] GetPermissionsByCategory([string]$category) {
        $permissions = @()
        
        foreach ($permName in $this.PermissionLevels.Keys) {
            if ($this.PermissionLevels[$permName].Category -eq $category) {
                $permissions += $permName
            }
        }
        
        return $permissions
    }

    # Méthode pour vérifier si un utilisateur a une permission spécifique
    [bool] HasPermission([string]$resourceId, [string]$principal, [string]$permissionName) {
        $this.WriteDebug("Vérification de la permission $permissionName pour le principal $principal sur la ressource $resourceId")
        
        # Obtenir la valeur de la permission
        $permValue = $this.GetPermissionValue($permissionName)
        
        if ($permValue -eq 0) {
            $this.WriteDebug("Permission inconnue: $permissionName")
            return $false
        }
        
        # Obtenir la catégorie de la permission
        $category = $this.GetPermissionCategory($permissionName)
        
        # Vérifier si l'utilisateur a la permission via le gestionnaire de contrôle d'accès
        $acManager = New-AccessControlManager -ACLStorePath (Join-Path -Path $this.PermissionStorePath -ChildPath "ACL") -EnableDebug:$this.EnableDebug
        
        # Pour les permissions de lecture
        if ($category -eq "READ") {
            return $acManager.CheckAccess($resourceId, $principal, "READ")
        }
        # Pour les permissions d'écriture
        elseif ($category -eq "WRITE") {
            return $acManager.CheckAccess($resourceId, $principal, "WRITE")
        }
        # Pour les permissions d'administration
        elseif ($category -eq "ADMIN") {
            return $acManager.CheckAccess($resourceId, $principal, "ADMIN")
        }
        
        return $false
    }

    # Méthode pour obtenir toutes les permissions d'un utilisateur sur une ressource
    [hashtable] GetUserPermissions([string]$resourceId, [string]$principal) {
        $this.WriteDebug("Récupération des permissions pour le principal $principal sur la ressource $resourceId")
        
        $permissions = @{}
        
        # Vérifier chaque permission
        foreach ($permName in $this.PermissionLevels.Keys) {
            $hasPermission = $this.HasPermission($resourceId, $principal, $permName)
            $permissions[$permName] = $hasPermission
        }
        
        return $permissions
    }

    # Méthode pour créer un ensemble de permissions par défaut pour une ressource
    [bool] CreateDefaultPermissions([string]$resourceId, [string]$owner) {
        $this.WriteDebug("Création des permissions par défaut pour la ressource $resourceId")
        
        try {
            # Initialiser le stockage des permissions
            $this.InitializePermissionStore()
            
            # Créer l'ACL pour la ressource
            $acManager = New-AccessControlManager -ACLStorePath (Join-Path -Path $this.PermissionStorePath -ChildPath "ACL") -EnableDebug:$this.EnableDebug
            $result = $acManager.CreateACL($resourceId, $owner)
            
            if (-not $result) {
                $this.WriteDebug("Échec de la création de l'ACL pour la ressource $resourceId")
                return $false
            }
            
            $this.WriteDebug("Permissions par défaut créées avec succès pour la ressource $resourceId")
            return $true
        }
        catch {
            $this.WriteDebug("Erreur lors de la création des permissions par défaut - $($_.Exception.Message)")
            throw "Erreur lors de la création des permissions par défaut pour la ressource $resourceId - $($_.Exception.Message)"
        }
    }

    # Méthode pour accorder une permission à un utilisateur
    [bool] GrantPermission([string]$resourceId, [string]$principal, [string]$permissionName, [string]$grantedBy) {
        $this.WriteDebug("Attribution de la permission $permissionName au principal $principal sur la ressource $resourceId")
        
        # Obtenir la catégorie de la permission
        $category = $this.GetPermissionCategory($permissionName)
        
        if ([string]::IsNullOrEmpty($category)) {
            $this.WriteDebug("Permission inconnue: $permissionName")
            return $false
        }
        
        # Accorder la permission via le gestionnaire de contrôle d'accès
        $acManager = New-AccessControlManager -ACLStorePath (Join-Path -Path $this.PermissionStorePath -ChildPath "ACL") -EnableDebug:$this.EnableDebug
        
        # Ajouter l'entrée à l'ACL
        $result = $acManager.AddACLEntry($resourceId, $principal, @($category), $grantedBy)
        
        if ($result) {
            $this.WriteDebug("Permission $permissionName accordée avec succès")
        }
        else {
            $this.WriteDebug("Échec de l'attribution de la permission $permissionName")
        }
        
        return $result
    }

    # Méthode pour révoquer une permission d'un utilisateur
    [bool] RevokePermission([string]$resourceId, [string]$principal, [string]$permissionName, [string]$revokedBy) {
        $this.WriteDebug("Révocation de la permission $permissionName du principal $principal sur la ressource $resourceId")
        
        # Obtenir la catégorie de la permission
        $category = $this.GetPermissionCategory($permissionName)
        
        if ([string]::IsNullOrEmpty($category)) {
            $this.WriteDebug("Permission inconnue: $permissionName")
            return $false
        }
        
        # Révoquer la permission via le gestionnaire de contrôle d'accès
        $acManager = New-AccessControlManager -ACLStorePath (Join-Path -Path $this.PermissionStorePath -ChildPath "ACL") -EnableDebug:$this.EnableDebug
        
        # Supprimer l'entrée de l'ACL
        $result = $acManager.RemoveACLEntry($resourceId, $principal, $revokedBy)
        
        if ($result) {
            $this.WriteDebug("Permission $permissionName révoquée avec succès")
        }
        else {
            $this.WriteDebug("Échec de la révocation de la permission $permissionName")
        }
        
        return $result
    }
}

# Fonction pour créer un nouveau gestionnaire de permissions
function New-PermissionManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$PermissionStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\PermissionStore"),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )
    
    return [PermissionManager]::new($PermissionStorePath, $EnableDebug)
}

# Fonction pour vérifier si un utilisateur a une permission
function Test-UserPermission {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceId,
        
        [Parameter(Mandatory = $true)]
        [string]$Principal,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("READ_BASIC", "READ_STANDARD", "READ_EXTENDED", "WRITE_COMMENT", "WRITE_CONTENT", "WRITE_STRUCTURE", "ADMIN_SHARE", "ADMIN_PERMISSIONS", "ADMIN_OWNERSHIP")]
        [string]$Permission,
        
        [Parameter(Mandatory = $false)]
        [string]$PermissionStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\PermissionStore"),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )
    
    $manager = New-PermissionManager -PermissionStorePath $PermissionStorePath -EnableDebug:$EnableDebug
    return $manager.HasPermission($ResourceId, $Principal, $Permission)
}

# Fonction pour obtenir toutes les permissions d'un utilisateur
function Get-UserPermissions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceId,
        
        [Parameter(Mandatory = $true)]
        [string]$Principal,
        
        [Parameter(Mandatory = $false)]
        [string]$PermissionStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\PermissionStore"),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )
    
    $manager = New-PermissionManager -PermissionStorePath $PermissionStorePath -EnableDebug:$EnableDebug
    return $manager.GetUserPermissions($ResourceId, $Principal)
}

# Fonction pour créer des permissions par défaut
function New-DefaultPermissions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceId,
        
        [Parameter(Mandatory = $true)]
        [string]$Owner,
        
        [Parameter(Mandatory = $false)]
        [string]$PermissionStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\PermissionStore"),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )
    
    $manager = New-PermissionManager -PermissionStorePath $PermissionStorePath -EnableDebug:$EnableDebug
    return $manager.CreateDefaultPermissions($ResourceId, $Owner)
}

# Fonction pour accorder une permission
function Grant-UserPermission {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceId,
        
        [Parameter(Mandatory = $true)]
        [string]$Principal,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("READ_BASIC", "READ_STANDARD", "READ_EXTENDED", "WRITE_COMMENT", "WRITE_CONTENT", "WRITE_STRUCTURE", "ADMIN_SHARE", "ADMIN_PERMISSIONS", "ADMIN_OWNERSHIP")]
        [string]$Permission,
        
        [Parameter(Mandatory = $true)]
        [string]$GrantedBy,
        
        [Parameter(Mandatory = $false)]
        [string]$PermissionStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\PermissionStore"),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )
    
    $manager = New-PermissionManager -PermissionStorePath $PermissionStorePath -EnableDebug:$EnableDebug
    return $manager.GrantPermission($ResourceId, $Principal, $Permission, $GrantedBy)
}

# Fonction pour révoquer une permission
function Revoke-UserPermission {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceId,
        
        [Parameter(Mandatory = $true)]
        [string]$Principal,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("READ_BASIC", "READ_STANDARD", "READ_EXTENDED", "WRITE_COMMENT", "WRITE_CONTENT", "WRITE_STRUCTURE", "ADMIN_SHARE", "ADMIN_PERMISSIONS", "ADMIN_OWNERSHIP")]
        [string]$Permission,
        
        [Parameter(Mandatory = $true)]
        [string]$RevokedBy,
        
        [Parameter(Mandatory = $false)]
        [string]$PermissionStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\PermissionStore"),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )
    
    $manager = New-PermissionManager -PermissionStorePath $PermissionStorePath -EnableDebug:$EnableDebug
    return $manager.RevokePermission($ResourceId, $Principal, $Permission, $RevokedBy)
}

# Exporter les fonctions
# Export-ModuleMember -Function New-PermissionManager, Test-UserPermission, Get-UserPermissions, New-DefaultPermissions, Grant-UserPermission, Revoke-UserPermission
