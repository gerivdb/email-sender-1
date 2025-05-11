<#
.SYNOPSIS
    Gestionnaire de contrôle d'accès pour le partage des vues.

.DESCRIPTION
    Ce module implémente le gestionnaire de contrôle d'accès qui permet de gérer
    les permissions d'accès aux vues partagées.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Importer le module d'authentification
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$authenticationManagerPath = Join-Path -Path $scriptDir -ChildPath "AuthenticationManager.ps1"

if (Test-Path -Path $authenticationManagerPath) {
    . $authenticationManagerPath
} else {
    throw "Le module AuthenticationManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $authenticationManagerPath"
}

# Classe pour représenter le gestionnaire de contrôle d'accès
class AccessControlManager {
    # Propriétés
    [hashtable]$Permissions
    [string]$ACLStorePath
    [bool]$EnableDebug

    # Constructeur par défaut
    AccessControlManager() {
        $this.Permissions = @{
            "READ"  = 1
            "WRITE" = 2
            "ADMIN" = 4
        }
        $this.ACLStorePath = Join-Path -Path $env:TEMP -ChildPath "ViewSharing\ACLStore"
        $this.EnableDebug = $false
    }

    # Constructeur avec paramètres
    AccessControlManager([string]$aclStorePath, [bool]$enableDebug) {
        $this.Permissions = @{
            "READ"  = 1
            "WRITE" = 2
            "ADMIN" = 4
        }
        $this.ACLStorePath = $aclStorePath
        $this.EnableDebug = $enableDebug
    }

    # Méthode pour écrire des messages de débogage
    [void] WriteDebug([string]$message) {
        if ($this.EnableDebug) {
            Write-Host "[DEBUG] [AccessControlManager] $message" -ForegroundColor Cyan
        }
    }

    # Méthode pour initialiser le stockage des ACL
    [void] InitializeACLStore() {
        $this.WriteDebug("Initialisation du stockage des ACL")

        try {
            # Créer le répertoire de stockage s'il n'existe pas
            if (-not (Test-Path -Path $this.ACLStorePath)) {
                New-Item -Path $this.ACLStorePath -ItemType Directory -Force | Out-Null
                $this.WriteDebug("Répertoire de stockage créé: $($this.ACLStorePath)")
            }

            $this.WriteDebug("Initialisation du stockage des ACL terminée")
        } catch {
            $this.WriteDebug("Erreur lors de l'initialisation du stockage des ACL - $($_.Exception.Message)")
            throw "Erreur lors de l'initialisation du stockage des ACL - $($_.Exception.Message)"
        }
    }

    # Méthode pour créer une ACL pour une ressource
    [bool] CreateACL([string]$resourceId, [string]$owner) {
        $this.WriteDebug("Création d'une ACL pour la ressource: $resourceId")

        try {
            # Initialiser le stockage des ACL si nécessaire
            $this.InitializeACLStore()

            # Vérifier si l'ACL existe déjà
            $aclFilePath = Join-Path -Path $this.ACLStorePath -ChildPath "$resourceId.json"

            if (Test-Path -Path $aclFilePath) {
                $this.WriteDebug("L'ACL pour la ressource $resourceId existe déjà")
                return $false
            }

            # Créer l'objet ACL
            $acl = @{
                ResourceId   = $resourceId
                Owner        = $owner
                CreatedAt    = (Get-Date).ToString('o')
                LastModified = (Get-Date).ToString('o')
                Entries      = @(
                    @{
                        Principal  = $owner
                        Permission = $this.Permissions["READ"] + $this.Permissions["WRITE"] + $this.Permissions["ADMIN"]
                        GrantedBy  = $owner
                        GrantedAt  = (Get-Date).ToString('o')
                    }
                )
            }

            # Enregistrer l'ACL
            $aclJson = $acl | ConvertTo-Json -Depth 10
            $aclJson | Out-File -FilePath $aclFilePath -Encoding utf8

            $this.WriteDebug("ACL créée avec succès pour la ressource $resourceId")
            return $true
        } catch {
            $this.WriteDebug("Erreur lors de la création de l'ACL - $($_.Exception.Message)")
            throw "Erreur lors de la création de l'ACL pour la ressource $resourceId - $($_.Exception.Message)"
        }
    }

    # Méthode pour charger une ACL
    [PSObject] GetACL([string]$resourceId) {
        $this.WriteDebug("Chargement de l'ACL pour la ressource: $resourceId")

        try {
            # Vérifier si l'ACL existe
            $aclFilePath = Join-Path -Path $this.ACLStorePath -ChildPath "$resourceId.json"

            if (-not (Test-Path -Path $aclFilePath)) {
                $this.WriteDebug("L'ACL pour la ressource $resourceId n'existe pas")
                return $null
            }

            # Charger l'ACL
            $aclJson = Get-Content -Path $aclFilePath -Raw
            $acl = $aclJson | ConvertFrom-Json

            $this.WriteDebug("ACL chargée avec succès pour la ressource $resourceId")
            return $acl
        } catch {
            $this.WriteDebug("Erreur lors du chargement de l'ACL - $($_.Exception.Message)")
            throw "Erreur lors du chargement de l'ACL pour la ressource $resourceId - $($_.Exception.Message)"
        }
    }

    # Méthode pour ajouter une entrée à une ACL
    [bool] AddACLEntry([string]$resourceId, [string]$principal, [string[]]$permissions, [string]$grantedBy) {
        $this.WriteDebug("Ajout d'une entrée à l'ACL pour la ressource: $resourceId")

        try {
            # Charger l'ACL
            $acl = $this.GetACL($resourceId)

            if ($null -eq $acl) {
                $this.WriteDebug("L'ACL pour la ressource $resourceId n'existe pas")
                return $false
            }

            # Vérifier si le principal a déjà une entrée
            $existingEntry = $null

            foreach ($entry in $acl.Entries) {
                if ($entry.Principal -eq $principal) {
                    $existingEntry = $entry
                    break
                }
            }

            # Calculer la permission
            $permission = 0

            foreach ($perm in $permissions) {
                if ($this.Permissions.ContainsKey($perm)) {
                    $permission += $this.Permissions[$perm]
                } else {
                    $this.WriteDebug("Permission inconnue: $perm")
                }
            }

            # Mettre à jour ou ajouter l'entrée
            if ($null -ne $existingEntry) {
                $existingEntry.Permission = $permission
                $existingEntry.GrantedBy = $grantedBy
                $existingEntry.GrantedAt = (Get-Date).ToString('o')
            } else {
                $newEntry = @{
                    Principal  = $principal
                    Permission = $permission
                    GrantedBy  = $grantedBy
                    GrantedAt  = (Get-Date).ToString('o')
                }

                $acl.Entries += $newEntry
            }

            # Mettre à jour la date de dernière modification
            $acl.LastModified = (Get-Date).ToString('o')

            # Enregistrer l'ACL
            $aclFilePath = Join-Path -Path $this.ACLStorePath -ChildPath "$resourceId.json"
            $aclJson = $acl | ConvertTo-Json -Depth 10
            $aclJson | Out-File -FilePath $aclFilePath -Encoding utf8

            $this.WriteDebug("Entrée ajoutée avec succès à l'ACL pour la ressource $resourceId")
            return $true
        } catch {
            $this.WriteDebug("Erreur lors de l'ajout de l'entrée à l'ACL - $($_.Exception.Message)")
            throw "Erreur lors de l'ajout de l'entrée à l'ACL pour la ressource $resourceId - $($_.Exception.Message)"
        }
    }

    # Méthode pour supprimer une entrée d'une ACL
    [bool] RemoveACLEntry([string]$resourceId, [string]$principal, [string]$removedBy) {
        $this.WriteDebug("Suppression d'une entrée de l'ACL pour la ressource: $resourceId")

        try {
            # Charger l'ACL
            $acl = $this.GetACL($resourceId)

            if ($null -eq $acl) {
                $this.WriteDebug("L'ACL pour la ressource $resourceId n'existe pas")
                return $false
            }

            # Vérifier si le principal est le propriétaire
            if ($acl.Owner -eq $principal) {
                $this.WriteDebug("Impossible de supprimer l'entrée du propriétaire")
                return $false
            }

            # Rechercher l'entrée à supprimer
            $newEntries = @()
            $entryFound = $false

            foreach ($entry in $acl.Entries) {
                if ($entry.Principal -ne $principal) {
                    $newEntries += $entry
                } else {
                    $entryFound = $true
                }
            }

            # Si l'entrée a été trouvée, mettre à jour l'ACL
            if ($entryFound) {
                $acl.Entries = $newEntries
                $acl.LastModified = (Get-Date).ToString('o')

                # Enregistrer l'ACL
                $aclFilePath = Join-Path -Path $this.ACLStorePath -ChildPath "$resourceId.json"
                $aclJson = $acl | ConvertTo-Json -Depth 10
                $aclJson | Out-File -FilePath $aclFilePath -Encoding utf8

                $this.WriteDebug("Entrée supprimée avec succès de l'ACL pour la ressource $resourceId")
                return $true
            } else {
                $this.WriteDebug("Entrée non trouvée dans l'ACL pour la ressource $resourceId")
                return $false
            }
        } catch {
            $this.WriteDebug("Erreur lors de la suppression de l'entrée de l'ACL - $($_.Exception.Message)")
            throw "Erreur lors de la suppression de l'entrée de l'ACL pour la ressource $resourceId - $($_.Exception.Message)"
        }
    }

    # Méthode pour vérifier si un principal a une permission
    [bool] CheckPermission([string]$resourceId, [string]$principal, [string]$permission) {
        $this.WriteDebug("Vérification de la permission $permission pour le principal $principal sur la ressource $resourceId")

        try {
            # Charger l'ACL
            $acl = $this.GetACL($resourceId)

            if ($null -eq $acl) {
                $this.WriteDebug("L'ACL pour la ressource $resourceId n'existe pas")
                return $false
            }

            # Vérifier si le principal est le propriétaire
            if ($acl.Owner -eq $principal) {
                $this.WriteDebug("Le principal est le propriétaire, toutes les permissions sont accordées")
                return $true
            }

            # Rechercher l'entrée du principal
            $principalEntry = $null

            foreach ($entry in $acl.Entries) {
                if ($entry.Principal -eq $principal) {
                    $principalEntry = $entry
                    break
                }
            }

            # Si aucune entrée n'a été trouvée, le principal n'a pas de permission
            if ($null -eq $principalEntry) {
                $this.WriteDebug("Aucune entrée trouvée pour le principal $principal")
                return $false
            }

            # Vérifier si la permission est accordée
            $permissionValue = $this.Permissions[$permission]
            $hasPermission = ($principalEntry.Permission -band $permissionValue) -eq $permissionValue

            if ($hasPermission) {
                $this.WriteDebug("Le principal $principal a la permission $permission")
            } else {
                $this.WriteDebug("Le principal $principal n'a pas la permission $permission")
            }
            return $hasPermission
        } catch {
            $this.WriteDebug("Erreur lors de la vérification de la permission - $($_.Exception.Message)")
            throw "Erreur lors de la vérification de la permission pour la ressource $resourceId - $($_.Exception.Message)"
        }
    }

    # Méthode pour journaliser un accès
    [void] LogAccess([string]$resourceId, [string]$principal, [string]$action, [bool]$success) {
        $this.WriteDebug("Journalisation d'un accès à la ressource: $resourceId")

        try {
            # Initialiser le stockage des ACL si nécessaire
            $this.InitializeACLStore()

            # Préparer le chemin du journal
            $logPath = Join-Path -Path $this.ACLStorePath -ChildPath "access_log.csv"

            # Créer le journal s'il n'existe pas
            if (-not (Test-Path -Path $logPath)) {
                "Timestamp,ResourceId,Principal,Action,Success" | Out-File -FilePath $logPath -Encoding utf8
            }

            # Ajouter l'entrée au journal
            $timestamp = (Get-Date).ToString('o')
            "$timestamp,$resourceId,$principal,$action,$success" | Out-File -FilePath $logPath -Encoding utf8 -Append

            $this.WriteDebug("Accès journalisé avec succès")
        } catch {
            $this.WriteDebug("Erreur lors de la journalisation de l'accès - $($_.Exception.Message)")
            # Ne pas lever d'exception pour éviter d'interrompre le flux principal
        }
    }

    # Méthode pour changer le propriétaire d'une ressource
    [bool] ChangeOwner([string]$resourceId, [string]$newOwner, [string]$requestedBy) {
        $this.WriteDebug("Changement du propriétaire de la ressource: $resourceId")

        try {
            # Charger l'ACL
            $acl = $this.GetACL($resourceId)

            if ($null -eq $acl) {
                $this.WriteDebug("L'ACL pour la ressource $resourceId n'existe pas")
                return $false
            }

            # Vérifier si le demandeur est le propriétaire actuel ou un administrateur
            $isOwner = $acl.Owner -eq $requestedBy
            $isAdmin = $false

            if (-not $isOwner) {
                foreach ($entry in $acl.Entries) {
                    if ($entry.Principal -eq $requestedBy) {
                        $isAdmin = ($entry.Permission -band $this.Permissions["ADMIN"]) -eq $this.Permissions["ADMIN"]
                        break
                    }
                }
            }

            if (-not ($isOwner -or $isAdmin)) {
                $this.WriteDebug("Le demandeur n'a pas les droits pour changer le propriétaire")
                return $false
            }

            # Mettre à jour le propriétaire
            $oldOwner = $acl.Owner
            $acl.Owner = $newOwner
            $acl.LastModified = (Get-Date).ToString('o')

            # Mettre à jour les entrées
            $newOwnerEntry = $null

            foreach ($entry in $acl.Entries) {
                if ($entry.Principal -eq $newOwner) {
                    $newOwnerEntry = $entry
                    break
                }
            }

            if ($null -eq $newOwnerEntry) {
                # Ajouter une entrée pour le nouveau propriétaire
                $newEntry = @{
                    Principal  = $newOwner
                    Permission = $this.Permissions["READ"] + $this.Permissions["WRITE"] + $this.Permissions["ADMIN"]
                    GrantedBy  = $requestedBy
                    GrantedAt  = (Get-Date).ToString('o')
                }

                $acl.Entries += $newEntry
            } else {
                # Mettre à jour l'entrée existante
                $newOwnerEntry.Permission = $this.Permissions["READ"] + $this.Permissions["WRITE"] + $this.Permissions["ADMIN"]
                $newOwnerEntry.GrantedBy = $requestedBy
                $newOwnerEntry.GrantedAt = (Get-Date).ToString('o')
            }

            # Enregistrer l'ACL
            $aclFilePath = Join-Path -Path $this.ACLStorePath -ChildPath "$resourceId.json"
            $aclJson = $acl | ConvertTo-Json -Depth 10
            $aclJson | Out-File -FilePath $aclFilePath -Encoding utf8

            # Journaliser le changement de propriétaire
            $this.LogAccess($resourceId, $requestedBy, "CHANGE_OWNER", $true)

            $this.WriteDebug("Propriétaire changé avec succès pour la ressource $resourceId")
            return $true
        } catch {
            $this.WriteDebug("Erreur lors du changement de propriétaire - $($_.Exception.Message)")
            throw "Erreur lors du changement de propriétaire pour la ressource $resourceId - $($_.Exception.Message)"
        }
    }

    # Méthode pour vérifier l'accès à une ressource
    [bool] CheckAccess([string]$resourceId, [string]$principal, [string]$permission) {
        $this.WriteDebug("Vérification de l'accès à la ressource: $resourceId")

        try {
            # Vérifier la permission
            $hasPermission = $this.CheckPermission($resourceId, $principal, $permission)

            # Journaliser l'accès
            $this.LogAccess($resourceId, $principal, "CHECK_$permission", $hasPermission)

            return $hasPermission
        } catch {
            $this.WriteDebug("Erreur lors de la vérification de l'accès - $($_.Exception.Message)")
            throw "Erreur lors de la vérification de l'accès à la ressource $resourceId - $($_.Exception.Message)"
        }
    }
}

# Fonction pour créer un nouveau gestionnaire de contrôle d'accès
function New-AccessControlManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ACLStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\ACLStore"),

        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    return [AccessControlManager]::new($ACLStorePath, $EnableDebug)
}

# Fonction pour créer une ACL pour une ressource
function New-ResourceACL {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceId,

        [Parameter(Mandatory = $true)]
        [string]$Owner,

        [Parameter(Mandatory = $false)]
        [string]$ACLStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\ACLStore"),

        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    $manager = New-AccessControlManager -ACLStorePath $ACLStorePath -EnableDebug:$EnableDebug
    return $manager.CreateACL($ResourceId, $Owner)
}

# Fonction pour ajouter une entrée à une ACL
function Add-ACLEntry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceId,

        [Parameter(Mandatory = $true)]
        [string]$Principal,

        [Parameter(Mandatory = $true)]
        [ValidateSet("READ", "WRITE", "ADMIN")]
        [string[]]$Permissions,

        [Parameter(Mandatory = $true)]
        [string]$GrantedBy,

        [Parameter(Mandatory = $false)]
        [string]$ACLStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\ACLStore"),

        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    $manager = New-AccessControlManager -ACLStorePath $ACLStorePath -EnableDebug:$EnableDebug
    return $manager.AddACLEntry($ResourceId, $Principal, $Permissions, $GrantedBy)
}

# Fonction pour supprimer une entrée d'une ACL
function Remove-ACLEntry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceId,

        [Parameter(Mandatory = $true)]
        [string]$Principal,

        [Parameter(Mandatory = $true)]
        [string]$RemovedBy,

        [Parameter(Mandatory = $false)]
        [string]$ACLStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\ACLStore"),

        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    $manager = New-AccessControlManager -ACLStorePath $ACLStorePath -EnableDebug:$EnableDebug
    return $manager.RemoveACLEntry($ResourceId, $Principal, $RemovedBy)
}

# Fonction pour vérifier l'accès à une ressource
function Test-ResourceAccess {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceId,

        [Parameter(Mandatory = $true)]
        [string]$Principal,

        [Parameter(Mandatory = $true)]
        [ValidateSet("READ", "WRITE", "ADMIN")]
        [string]$Permission,

        [Parameter(Mandatory = $false)]
        [string]$ACLStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\ACLStore"),

        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    $manager = New-AccessControlManager -ACLStorePath $ACLStorePath -EnableDebug:$EnableDebug
    return $manager.CheckAccess($ResourceId, $Principal, $Permission)
}

# Fonction pour changer le propriétaire d'une ressource
function Set-ResourceOwner {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceId,

        [Parameter(Mandatory = $true)]
        [string]$NewOwner,

        [Parameter(Mandatory = $true)]
        [string]$RequestedBy,

        [Parameter(Mandatory = $false)]
        [string]$ACLStorePath = (Join-Path -Path $env:TEMP -ChildPath "ViewSharing\ACLStore"),

        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    $manager = New-AccessControlManager -ACLStorePath $ACLStorePath -EnableDebug:$EnableDebug
    return $manager.ChangeOwner($ResourceId, $NewOwner, $RequestedBy)
}

# Exporter les fonctions
# Export-ModuleMember -Function New-AccessControlManager, New-ResourceACL, Add-ACLEntry, Remove-ACLEntry, Test-ResourceAccess, Set-ResourceOwner
