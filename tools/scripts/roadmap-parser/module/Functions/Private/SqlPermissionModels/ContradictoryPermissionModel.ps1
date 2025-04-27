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

# Classe pour représenter une permission contradictoire au niveau base de données
class SqlDatabaseContradictoryPermission {
    [string]$PermissionName      # Nom de la permission contradictoire (ex: SELECT, INSERT, UPDATE)
    [string]$UserName            # Nom de l'utilisateur de base de données qui a cette permission contradictoire
    [string]$DatabaseName        # Nom de la base de données concernée
    [string]$GrantPermissionState # État de la permission accordée (GRANT)
    [string]$DenyPermissionState # État de la permission refusée (DENY)
    [string]$SecurableType       # Type d'élément sécurisable (DATABASE)
    [string]$SecurableName       # Nom de l'élément sécurisable (généralement le nom de la base de données)
    [string]$ModelName           # Nom du modèle de référence utilisé pour la comparaison
    [string]$ContradictionType   # Type de contradiction (GRANT/DENY, Héritage, Rôle/Utilisateur)
    [string]$RiskLevel           # Niveau de risque (Critique, Élevé, Moyen, Faible)
    [string]$Impact              # Description de l'impact potentiel de cette contradiction
    [string]$RecommendedAction   # Action recommandée pour corriger la contradiction
    [string]$ScriptTemplate      # Template de script SQL pour résoudre la contradiction
    [string]$LoginName           # Nom du login associé à l'utilisateur de base de données (si applicable)

    # Constructeur par défaut
    SqlDatabaseContradictoryPermission() {
        $this.SecurableType = "DATABASE"
        $this.GrantPermissionState = "GRANT"
        $this.DenyPermissionState = "DENY"
        $this.ContradictionType = "GRANT/DENY"
        $this.RiskLevel = "Moyen"
    }

    # Constructeur avec paramètres de base
    SqlDatabaseContradictoryPermission([string]$permissionName, [string]$userName, [string]$databaseName) {
        $this.PermissionName = $permissionName
        $this.UserName = $userName
        $this.DatabaseName = $databaseName
        $this.SecurableType = "DATABASE"
        $this.SecurableName = $databaseName
        $this.GrantPermissionState = "GRANT"
        $this.DenyPermissionState = "DENY"
        $this.ContradictionType = "GRANT/DENY"
        $this.RiskLevel = "Moyen"
    }

    # Constructeur complet
    SqlDatabaseContradictoryPermission(
        [string]$permissionName,
        [string]$userName,
        [string]$databaseName,
        [string]$contradictionType,
        [string]$modelName,
        [string]$riskLevel,
        [string]$loginName
    ) {
        $this.PermissionName = $permissionName
        $this.UserName = $userName
        $this.DatabaseName = $databaseName
        $this.SecurableType = "DATABASE"
        $this.SecurableName = $databaseName
        $this.ContradictionType = $contradictionType
        $this.ModelName = $modelName
        $this.RiskLevel = $riskLevel
        $this.GrantPermissionState = "GRANT"
        $this.DenyPermissionState = "DENY"
        $this.LoginName = $loginName
    }

    # Méthode pour générer un script de résolution
    [string] GenerateFixScript() {
        $script = "-- Script pour résoudre la contradiction de permission au niveau base de données`n"
        $script += "-- Base de données: $($this.DatabaseName), Utilisateur: $($this.UserName), Permission: $($this.PermissionName)`n"
        $script += "USE [$($this.DatabaseName)];`n"

        if ($this.ContradictionType -eq "GRANT/DENY") {
            $script += "-- Option 1: Supprimer la permission DENY (conserver GRANT)`n"
            $script += "REVOKE $($this.PermissionName) FROM [$($this.UserName)];`n"
            $script += "GRANT $($this.PermissionName) TO [$($this.UserName)];`n`n"

            $script += "-- Option 2: Supprimer la permission GRANT (conserver DENY)`n"
            $script += "REVOKE $($this.PermissionName) FROM [$($this.UserName)];`n"
            $script += "DENY $($this.PermissionName) TO [$($this.UserName)];`n"
        } elseif ($this.ContradictionType -eq "Héritage") {
            $script += "-- Résoudre la contradiction d'héritage`n"
            $script += "-- Vérifier les rôles de l'utilisateur et ajuster les permissions`n"
            $script += "-- Exemple: REVOKE $($this.PermissionName) FROM [$($this.UserName)];`n"
        } elseif ($this.ContradictionType -eq "Rôle/Utilisateur") {
            $script += "-- Résoudre la contradiction entre rôle et utilisateur`n"
            $script += "-- Vérifier les rôles de l'utilisateur et ajuster les permissions`n"
            $script += "-- Exemple: ALTER ROLE [role_name] DROP MEMBER [$($this.UserName)];`n"
        }

        return $script
    }

    # Méthode pour obtenir une représentation textuelle
    [string] ToString() {
        return "Contradiction de permission: $($this.PermissionName) pour l'utilisateur [$($this.UserName)] dans la base de données [$($this.DatabaseName)] (Type: $($this.ContradictionType))"
    }

    # Méthode pour obtenir une description détaillée
    [string] GetDetailedDescription() {
        $description = "Contradiction de permission détectée:`n"
        $description += "- Permission: $($this.PermissionName)`n"
        $description += "- Base de données: $($this.DatabaseName)`n"
        $description += "- Utilisateur: $($this.UserName)`n"

        if ($this.LoginName) {
            $description += "- Login associé: $($this.LoginName)`n"
        }

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

# Fonction pour créer une nouvelle permission contradictoire au niveau base de données
function New-SqlDatabaseContradictoryPermission {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PermissionName,

        [Parameter(Mandatory = $true)]
        [string]$UserName,

        [Parameter(Mandatory = $true)]
        [string]$DatabaseName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("GRANT/DENY", "Héritage", "Rôle/Utilisateur")]
        [string]$ContradictionType = "GRANT/DENY",

        [Parameter(Mandatory = $false)]
        [string]$ModelName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Critique", "Élevé", "Moyen", "Faible")]
        [string]$RiskLevel = "Moyen",

        [Parameter(Mandatory = $false)]
        [string]$LoginName,

        [Parameter(Mandatory = $false)]
        [string]$Impact,

        [Parameter(Mandatory = $false)]
        [string]$RecommendedAction
    )

    $permission = [SqlDatabaseContradictoryPermission]::new(
        $PermissionName,
        $UserName,
        $DatabaseName,
        $ContradictionType,
        $ModelName,
        $RiskLevel,
        $LoginName
    )

    if ($Impact) {
        $permission.Impact = $Impact
    }

    if ($RecommendedAction) {
        $permission.RecommendedAction = $RecommendedAction
    }

    return $permission
}

# Classe pour représenter une permission contradictoire au niveau objet
class SqlObjectContradictoryPermission {
    [string]$PermissionName      # Nom de la permission contradictoire (ex: SELECT, INSERT, UPDATE)
    [string]$UserName            # Nom de l'utilisateur de base de données qui a cette permission contradictoire
    [string]$DatabaseName        # Nom de la base de données concernée
    [string]$SchemaName          # Nom du schéma de l'objet
    [string]$ObjectName          # Nom de l'objet (table, vue, procédure stockée, etc.)
    [string]$ObjectType          # Type d'objet (TABLE, VIEW, PROCEDURE, etc.)
    [string]$ColumnName          # Nom de la colonne (si applicable)
    [string]$GrantPermissionState # État de la permission accordée (GRANT)
    [string]$DenyPermissionState # État de la permission refusée (DENY)
    [string]$SecurableType       # Type d'élément sécurisable (OBJECT)
    [string]$SecurableName       # Nom de l'élément sécurisable (généralement le nom complet de l'objet)
    [string]$ModelName           # Nom du modèle de référence utilisé pour la comparaison
    [string]$ContradictionType   # Type de contradiction (GRANT/DENY, Héritage, Rôle/Utilisateur)
    [string]$RiskLevel           # Niveau de risque (Critique, Élevé, Moyen, Faible)
    [string]$Impact              # Description de l'impact potentiel de cette contradiction
    [string]$RecommendedAction   # Action recommandée pour corriger la contradiction
    [string]$ScriptTemplate      # Template de script SQL pour résoudre la contradiction
    [string]$LoginName           # Nom du login associé à l'utilisateur de base de données (si applicable)

    # Constructeur par défaut
    SqlObjectContradictoryPermission() {
        $this.SecurableType = "OBJECT"
        $this.GrantPermissionState = "GRANT"
        $this.DenyPermissionState = "DENY"
        $this.ContradictionType = "GRANT/DENY"
        $this.RiskLevel = "Moyen"
    }

    # Constructeur avec paramètres de base
    SqlObjectContradictoryPermission([string]$permissionName, [string]$userName, [string]$databaseName, [string]$objectName) {
        $this.PermissionName = $permissionName
        $this.UserName = $userName
        $this.DatabaseName = $databaseName
        $this.ObjectName = $objectName
        $this.SecurableType = "OBJECT"
        $this.SecurableName = $objectName
        $this.GrantPermissionState = "GRANT"
        $this.DenyPermissionState = "DENY"
        $this.ContradictionType = "GRANT/DENY"
        $this.RiskLevel = "Moyen"
    }

    # Constructeur complet
    SqlObjectContradictoryPermission(
        [string]$permissionName,
        [string]$userName,
        [string]$databaseName,
        [string]$schemaName,
        [string]$objectName,
        [string]$objectType,
        [string]$contradictionType,
        [string]$modelName,
        [string]$riskLevel,
        [string]$loginName,
        [string]$columnName
    ) {
        $this.PermissionName = $permissionName
        $this.UserName = $userName
        $this.DatabaseName = $databaseName
        $this.SchemaName = $schemaName
        $this.ObjectName = $objectName
        $this.ObjectType = $objectType
        $this.ColumnName = $columnName
        $this.SecurableType = "OBJECT"

        if ($schemaName -and $objectName) {
            $this.SecurableName = "$schemaName.$objectName"
        } else {
            $this.SecurableName = $objectName
        }

        $this.ContradictionType = $contradictionType
        $this.ModelName = $modelName
        $this.RiskLevel = $riskLevel
        $this.GrantPermissionState = "GRANT"
        $this.DenyPermissionState = "DENY"
        $this.LoginName = $loginName
    }

    # Méthode pour générer un script de résolution
    [string] GenerateFixScript() {
        $script = "-- Script pour résoudre la contradiction de permission au niveau objet`n"

        if ($this.ColumnName) {
            $script += "-- Base de données: $($this.DatabaseName), Schéma: $($this.SchemaName), Objet: $($this.ObjectName), Colonne: $($this.ColumnName), Utilisateur: $($this.UserName), Permission: $($this.PermissionName)`n"
        } else {
            $script += "-- Base de données: $($this.DatabaseName), Schéma: $($this.SchemaName), Objet: $($this.ObjectName), Utilisateur: $($this.UserName), Permission: $($this.PermissionName)`n"
        }

        $script += "USE [$($this.DatabaseName)];`n"

        $objectFullName = if ($this.SchemaName) { "[$($this.SchemaName)].[$($this.ObjectName)]" } else { "[$($this.ObjectName)]" }
        $columnSpec = if ($this.ColumnName) { "($($this.ColumnName))" } else { "" }

        if ($this.ContradictionType -eq "GRANT/DENY") {
            $script += "-- Option 1: Supprimer la permission DENY (conserver GRANT)`n"
            $script += "REVOKE $($this.PermissionName) ON $objectFullName$columnSpec FROM [$($this.UserName)];`n"
            $script += "GRANT $($this.PermissionName) ON $objectFullName$columnSpec TO [$($this.UserName)];`n`n"

            $script += "-- Option 2: Supprimer la permission GRANT (conserver DENY)`n"
            $script += "REVOKE $($this.PermissionName) ON $objectFullName$columnSpec FROM [$($this.UserName)];`n"
            $script += "DENY $($this.PermissionName) ON $objectFullName$columnSpec TO [$($this.UserName)];`n"
        } elseif ($this.ContradictionType -eq "Héritage") {
            $script += "-- Résoudre la contradiction d'héritage`n"
            $script += "-- Vérifier les rôles de l'utilisateur et ajuster les permissions`n"
            $script += "-- Exemple: REVOKE $($this.PermissionName) ON $objectFullName$columnSpec FROM [$($this.UserName)];`n"
        } elseif ($this.ContradictionType -eq "Rôle/Utilisateur") {
            $script += "-- Résoudre la contradiction entre rôle et utilisateur`n"
            $script += "-- Vérifier les rôles de l'utilisateur et ajuster les permissions`n"
            $script += "-- Exemple: ALTER ROLE [role_name] DROP MEMBER [$($this.UserName)];`n"
        }

        return $script
    }

    # Méthode pour obtenir une représentation textuelle
    [string] ToString() {
        $objectInfo = if ($this.SchemaName) { "[$($this.SchemaName)].[$($this.ObjectName)]" } else { "[$($this.ObjectName)]" }
        $columnInfo = if ($this.ColumnName) { " (colonne: $($this.ColumnName))" } else { "" }

        return "Contradiction de permission: $($this.PermissionName) pour l'utilisateur [$($this.UserName)] sur l'objet $objectInfo$columnInfo dans la base de données [$($this.DatabaseName)] (Type: $($this.ContradictionType))"
    }

    # Méthode pour obtenir une description détaillée
    [string] GetDetailedDescription() {
        $description = "Contradiction de permission détectée:`n"
        $description += "- Permission: $($this.PermissionName)`n"
        $description += "- Base de données: $($this.DatabaseName)`n"

        if ($this.SchemaName) {
            $description += "- Schéma: $($this.SchemaName)`n"
        }

        $description += "- Objet: $($this.ObjectName)`n"

        if ($this.ObjectType) {
            $description += "- Type d'objet: $($this.ObjectType)`n"
        }

        if ($this.ColumnName) {
            $description += "- Colonne: $($this.ColumnName)`n"
        }

        $description += "- Utilisateur: $($this.UserName)`n"

        if ($this.LoginName) {
            $description += "- Login associé: $($this.LoginName)`n"
        }

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

# Fonction pour créer une nouvelle permission contradictoire au niveau objet
function New-SqlObjectContradictoryPermission {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PermissionName,

        [Parameter(Mandatory = $true)]
        [string]$UserName,

        [Parameter(Mandatory = $true)]
        [string]$DatabaseName,

        [Parameter(Mandatory = $false)]
        [string]$SchemaName = "dbo",

        [Parameter(Mandatory = $true)]
        [string]$ObjectName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("TABLE", "VIEW", "PROCEDURE", "FUNCTION", "ASSEMBLY", "TYPE", "DEFAULT", "RULE", "SYNONYM")]
        [string]$ObjectType,

        [Parameter(Mandatory = $false)]
        [string]$ColumnName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("GRANT/DENY", "Héritage", "Rôle/Utilisateur")]
        [string]$ContradictionType = "GRANT/DENY",

        [Parameter(Mandatory = $false)]
        [string]$ModelName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Critique", "Élevé", "Moyen", "Faible")]
        [string]$RiskLevel = "Moyen",

        [Parameter(Mandatory = $false)]
        [string]$LoginName,

        [Parameter(Mandatory = $false)]
        [string]$Impact,

        [Parameter(Mandatory = $false)]
        [string]$RecommendedAction
    )

    $permission = [SqlObjectContradictoryPermission]::new(
        $PermissionName,
        $UserName,
        $DatabaseName,
        $SchemaName,
        $ObjectName,
        $ObjectType,
        $ContradictionType,
        $ModelName,
        $RiskLevel,
        $LoginName,
        $ColumnName
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
# Export-ModuleMember -Function New-SqlServerContradictoryPermission, New-SqlDatabaseContradictoryPermission, New-SqlObjectContradictoryPermission
