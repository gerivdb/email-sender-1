# ContradictoryPermissionModel.ps1
# Définit la structure de données pour représenter les permissions contradictoires dans SQL Server

<#
.SYNOPSIS
    Définit les classes et structures de données pour représenter les permissions contradictoires dans SQL Server.

.DESCRIPTION
    Ce fichier contient les définitions des classes et structures de données utilisées pour représenter
    les permissions contradictoires lors de la détection d'écarts de permissions.
    Ces structures sont utilisées par les algorithmes de détection de contradictions de permissions.

.NOTES
    Version:        1.0
    Author:         RoadmapParser Team
    Creation Date:  2023-11-20
#>

# Classe pour représenter une permission contradictoire au niveau serveur
class SqlServerContradictoryPermission {
    [string]$PermissionName      # Nom de la permission contradictoire (ex: CONNECT SQL, ALTER ANY LOGIN)
    [string]$LoginName           # Nom du login qui a cette permission contradictoire
    [string]$GrantPermissionState # État de la permission accordée (GRANT)
    [string]$DenyPermissionState # État de la permission refusée (DENY)
    [string]$SecurableType       # Type d'élément sécurisable (SERVER)
    [string]$SecurableName       # Nom de l'élément sécurisable (généralement le nom du serveur)
    [string]$ModelName           # Nom du modèle de référence utilisé pour la comparaison
    [string]$ContradictionType   # Type de contradiction (GRANT/DENY, Héritage, Rôle/Utilisateur)
    [string]$RiskLevel           # Niveau de risque (Critique, Élevé, Moyen, Faible)
    [string]$Impact              # Description de l'impact potentiel de cette contradiction
    [string]$RecommendedAction   # Action recommandée pour corriger la contradiction
    [string]$ScriptTemplate      # Template de script SQL pour résoudre la contradiction

    # Constructeur par défaut
    SqlServerContradictoryPermission() {
        $this.SecurableType = "SERVER"
        $this.GrantPermissionState = "GRANT"
        $this.DenyPermissionState = "DENY"
        $this.ContradictionType = "GRANT/DENY"
        $this.RiskLevel = "Moyen"
    }

    # Constructeur avec paramètres de base
    SqlServerContradictoryPermission([string]$permissionName, [string]$loginName) {
        $this.PermissionName = $permissionName
        $this.LoginName = $loginName
        $this.SecurableType = "SERVER"
        $this.GrantPermissionState = "GRANT"
        $this.DenyPermissionState = "DENY"
        $this.ContradictionType = "GRANT/DENY"
        $this.RiskLevel = "Moyen"
    }

    # Constructeur complet
    SqlServerContradictoryPermission(
        [string]$permissionName,
        [string]$loginName,
        [string]$securableName,
        [string]$contradictionType,
        [string]$modelName,
        [string]$riskLevel
    ) {
        $this.PermissionName = $permissionName
        $this.LoginName = $loginName
        $this.SecurableType = "SERVER"
        $this.SecurableName = $securableName
        $this.ContradictionType = $contradictionType
        $this.ModelName = $modelName
        $this.RiskLevel = $riskLevel
        $this.GrantPermissionState = "GRANT"
        $this.DenyPermissionState = "DENY"
    }

    # Méthode pour générer un script de résolution
    [string] GenerateFixScript() {
        $script = "-- Script pour résoudre la contradiction de permission au niveau serveur`n"
        $script += "-- Login: $($this.LoginName), Permission: $($this.PermissionName)`n"
        $script += "USE [master];`n"

        if ($this.ContradictionType -eq "GRANT/DENY") {
            $script += "-- Option 1: Supprimer la permission DENY (conserver GRANT)`n"
            $script += "REVOKE $($this.PermissionName) FROM [$($this.LoginName)];`n"
            $script += "GRANT $($this.PermissionName) TO [$($this.LoginName)];`n`n"

            $script += "-- Option 2: Supprimer la permission GRANT (conserver DENY)`n"
            $script += "REVOKE $($this.PermissionName) FROM [$($this.LoginName)];`n"
            $script += "DENY $($this.PermissionName) TO [$($this.LoginName)];`n"
        } elseif ($this.ContradictionType -eq "Héritage") {
            $script += "-- Résoudre la contradiction d'héritage`n"
            $script += "-- Vérifier les rôles du login et ajuster les permissions`n"
            $script += "-- Exemple: REVOKE $($this.PermissionName) FROM [$($this.LoginName)];`n"
        } elseif ($this.ContradictionType -eq "Rôle/Utilisateur") {
            $script += "-- Résoudre la contradiction entre rôle et utilisateur`n"
            $script += "-- Vérifier les rôles du login et ajuster les permissions`n"
            $script += "-- Exemple: ALTER SERVER ROLE [role_name] DROP MEMBER [$($this.LoginName)];`n"
        }

        return $script
    }

    # Méthode pour obtenir une représentation textuelle
    [string] ToString() {
        return "Contradiction de permission: $($this.PermissionName) pour le login [$($this.LoginName)] (Type: $($this.ContradictionType))"
    }

    # Méthode pour obtenir une description détaillée
    [string] GetDetailedDescription() {
        $description = "Contradiction de permission détectée:`n"
        $description += "- Permission: $($this.PermissionName)`n"
        $description += "- Login: $($this.LoginName)`n"
        $description += "- Type de contradiction: $($this.ContradictionType)`n"
        $description += "- Niveau de risque: $($this.RiskLevel)`n"

        if ($this.Impact) {
            $description += "- Impact potentiel: $($this.Impact)`n"
        }

        if ($this.RecommendedAction) {
            $description += "- Action recommandée: $($this.RecommendedAction)`n"
        }

        return $description
    }
}

# Fonction pour créer une nouvelle permission contradictoire au niveau serveur
function New-SqlServerContradictoryPermission {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PermissionName,

        [Parameter(Mandatory = $true)]
        [string]$LoginName,

        [Parameter(Mandatory = $false)]
        [string]$SecurableName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("GRANT/DENY", "Héritage", "Rôle/Utilisateur")]
        [string]$ContradictionType = "GRANT/DENY",

        [Parameter(Mandatory = $false)]
        [string]$ModelName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Critique", "Élevé", "Moyen", "Faible")]
        [string]$RiskLevel = "Moyen",

        [Parameter(Mandatory = $false)]
        [string]$Impact,

        [Parameter(Mandatory = $false)]
        [string]$RecommendedAction
    )

    $permission = [SqlServerContradictoryPermission]::new(
        $PermissionName,
        $LoginName,
        $SecurableName,
        $ContradictionType,
        $ModelName,
        $RiskLevel
    )

    if ($Impact) {
        $permission.Impact = $Impact
    }

    if ($RecommendedAction) {
        $permission.RecommendedAction = $RecommendedAction
    }

    return $permission
}

# Note: Les fonctions seront exportées par le module principal
# Export-ModuleMember -Function New-SqlServerContradictoryPermission
