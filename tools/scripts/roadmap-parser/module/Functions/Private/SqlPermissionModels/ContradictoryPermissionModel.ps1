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

# Classe pour représenter un ensemble de permissions contradictoires
class SqlContradictoryPermissionsSet {
    # Collections pour stocker les différents types de permissions contradictoires
    [System.Collections.Generic.List[SqlServerContradictoryPermission]]$ServerContradictions
    [System.Collections.Generic.List[SqlDatabaseContradictoryPermission]]$DatabaseContradictions
    [System.Collections.Generic.List[SqlObjectContradictoryPermission]]$ObjectContradictions

    # Métadonnées
    [string]$ServerName                # Nom du serveur SQL
    [string]$AnalysisDate              # Date de l'analyse
    [string]$AnalysisUser              # Utilisateur ayant effectué l'analyse
    [string]$ModelName                 # Nom du modèle de référence utilisé
    [int]$TotalContradictions          # Nombre total de contradictions
    [hashtable]$ContradictionsByType   # Nombre de contradictions par type
    [hashtable]$ContradictionsByRisk   # Nombre de contradictions par niveau de risque
    [string]$Description               # Description de l'ensemble de contradictions
    [string]$ReportTitle               # Titre du rapport

    # Constructeur par défaut
    SqlContradictoryPermissionsSet() {
        $this.ServerContradictions = New-Object System.Collections.Generic.List[SqlServerContradictoryPermission]
        $this.DatabaseContradictions = New-Object System.Collections.Generic.List[SqlDatabaseContradictoryPermission]
        $this.ObjectContradictions = New-Object System.Collections.Generic.List[SqlObjectContradictoryPermission]
        $this.AnalysisDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $this.AnalysisUser = $env:USERNAME
        $this.ContradictionsByType = @{
            "GRANT/DENY"       = 0
            "Héritage"         = 0
            "Rôle/Utilisateur" = 0
        }
        $this.ContradictionsByRisk = @{
            "Critique" = 0
            "Élevé"    = 0
            "Moyen"    = 0
            "Faible"   = 0
        }
    }

    # Constructeur avec paramètres de base
    SqlContradictoryPermissionsSet([string]$serverName, [string]$modelName) {
        $this.ServerContradictions = New-Object System.Collections.Generic.List[SqlServerContradictoryPermission]
        $this.DatabaseContradictions = New-Object System.Collections.Generic.List[SqlDatabaseContradictoryPermission]
        $this.ObjectContradictions = New-Object System.Collections.Generic.List[SqlObjectContradictoryPermission]
        $this.ServerName = $serverName
        $this.ModelName = $modelName
        $this.AnalysisDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $this.AnalysisUser = $env:USERNAME
        $this.ContradictionsByType = @{
            "GRANT/DENY"       = 0
            "Héritage"         = 0
            "Rôle/Utilisateur" = 0
        }
        $this.ContradictionsByRisk = @{
            "Critique" = 0
            "Élevé"    = 0
            "Moyen"    = 0
            "Faible"   = 0
        }
    }

    # Méthode pour ajouter une contradiction au niveau serveur
    [void] AddServerContradiction([SqlServerContradictoryPermission]$contradiction) {
        $this.ServerContradictions.Add($contradiction)
        $this.UpdateStatistics($contradiction.ContradictionType, $contradiction.RiskLevel)
    }

    # Méthode pour ajouter une contradiction au niveau base de données
    [void] AddDatabaseContradiction([SqlDatabaseContradictoryPermission]$contradiction) {
        $this.DatabaseContradictions.Add($contradiction)
        $this.UpdateStatistics($contradiction.ContradictionType, $contradiction.RiskLevel)
    }

    # Méthode pour ajouter une contradiction au niveau objet
    [void] AddObjectContradiction([SqlObjectContradictoryPermission]$contradiction) {
        $this.ObjectContradictions.Add($contradiction)
        $this.UpdateStatistics($contradiction.ContradictionType, $contradiction.RiskLevel)
    }

    # Méthode privée pour mettre à jour les statistiques
    hidden [void] UpdateStatistics([string]$contradictionType, [string]$riskLevel) {
        $this.TotalContradictions++

        if ($this.ContradictionsByType.ContainsKey($contradictionType)) {
            $this.ContradictionsByType[$contradictionType]++
        } else {
            $this.ContradictionsByType[$contradictionType] = 1
        }

        if ($this.ContradictionsByRisk.ContainsKey($riskLevel)) {
            $this.ContradictionsByRisk[$riskLevel]++
        } else {
            $this.ContradictionsByRisk[$riskLevel] = 1
        }
    }

    # Méthode pour obtenir toutes les contradictions
    [array] GetAllContradictions() {
        $allContradictions = @()
        $allContradictions += $this.ServerContradictions
        $allContradictions += $this.DatabaseContradictions
        $allContradictions += $this.ObjectContradictions
        return $allContradictions
    }

    # Méthode pour filtrer les contradictions par niveau de risque
    [array] FilterByRiskLevel([string]$riskLevel) {
        $filtered = @()

        foreach ($contradiction in $this.ServerContradictions) {
            if ($contradiction.RiskLevel -eq $riskLevel) {
                $filtered += $contradiction
            }
        }

        foreach ($contradiction in $this.DatabaseContradictions) {
            if ($contradiction.RiskLevel -eq $riskLevel) {
                $filtered += $contradiction
            }
        }

        foreach ($contradiction in $this.ObjectContradictions) {
            if ($contradiction.RiskLevel -eq $riskLevel) {
                $filtered += $contradiction
            }
        }

        return $filtered
    }

    # Méthode pour filtrer les contradictions par type
    [array] FilterByType([string]$contradictionType) {
        $filtered = @()

        foreach ($contradiction in $this.ServerContradictions) {
            if ($contradiction.ContradictionType -eq $contradictionType) {
                $filtered += $contradiction
            }
        }

        foreach ($contradiction in $this.DatabaseContradictions) {
            if ($contradiction.ContradictionType -eq $contradictionType) {
                $filtered += $contradiction
            }
        }

        foreach ($contradiction in $this.ObjectContradictions) {
            if ($contradiction.ContradictionType -eq $contradictionType) {
                $filtered += $contradiction
            }
        }

        return $filtered
    }

    # Méthode pour filtrer les contradictions par login/utilisateur
    [array] FilterByUser([string]$userName) {
        $filtered = @()

        foreach ($contradiction in $this.ServerContradictions) {
            if ($contradiction.LoginName -eq $userName) {
                $filtered += $contradiction
            }
        }

        foreach ($contradiction in $this.DatabaseContradictions) {
            if ($contradiction.UserName -eq $userName -or $contradiction.LoginName -eq $userName) {
                $filtered += $contradiction
            }
        }

        foreach ($contradiction in $this.ObjectContradictions) {
            if ($contradiction.UserName -eq $userName -or $contradiction.LoginName -eq $userName) {
                $filtered += $contradiction
            }
        }

        return $filtered
    }

    # Méthode pour générer un rapport de synthèse
    [string] GenerateSummaryReport() {
        $report = "Rapport de synthèse des permissions contradictoires`n"
        $report += "================================================`n`n"
        $report += "Serveur: $($this.ServerName)`n"
        $report += "Date d'analyse: $($this.AnalysisDate)`n"
        $report += "Utilisateur: $($this.AnalysisUser)`n"

        if ($this.ModelName) {
            $report += "Modèle de référence: $($this.ModelName)`n"
        }

        $report += "`nNombre total de contradictions: $($this.TotalContradictions)`n`n"

        $report += "Répartition par niveau de risque:`n"
        foreach ($key in $this.ContradictionsByRisk.Keys | Sort-Object @{Expression = {
                    switch ($_) {
                        "Critique" { 0 }
                        "Élevé" { 1 }
                        "Moyen" { 2 }
                        "Faible" { 3 }
                        default { 4 }
                    }
                }
            }) {
            $report += "- $($key): $($this.ContradictionsByRisk[$key])`n"
        }

        $report += "`nRépartition par type de contradiction:`n"
        foreach ($key in $this.ContradictionsByType.Keys) {
            $report += "- $($key): $($this.ContradictionsByType[$key])`n"
        }

        $report += "`nDétail des contradictions:`n"
        $report += "- Niveau serveur: $($this.ServerContradictions.Count)`n"
        $report += "- Niveau base de données: $($this.DatabaseContradictions.Count)`n"
        $report += "- Niveau objet: $($this.ObjectContradictions.Count)`n"

        return $report
    }

    # Méthode pour générer un rapport détaillé
    [string] GenerateDetailedReport() {
        $report = $this.GenerateSummaryReport()
        $report += "`n`nDétail des contradictions au niveau serveur:`n"
        $report += "-------------------------------------------`n"

        if ($this.ServerContradictions.Count -eq 0) {
            $report += "Aucune contradiction détectée au niveau serveur.`n"
        } else {
            foreach ($contradiction in $this.ServerContradictions) {
                $report += "`n$($contradiction.ToString())`n"
                $report += "Niveau de risque: $($contradiction.RiskLevel)`n"
                if ($contradiction.Impact) {
                    $report += "Impact: $($contradiction.Impact)`n"
                }
                if ($contradiction.RecommendedAction) {
                    $report += "Action recommandée: $($contradiction.RecommendedAction)`n"
                }
                $report += "---`n"
            }
        }

        $report += "`n`nDétail des contradictions au niveau base de données:`n"
        $report += "---------------------------------------------------`n"

        if ($this.DatabaseContradictions.Count -eq 0) {
            $report += "Aucune contradiction détectée au niveau base de données.`n"
        } else {
            foreach ($contradiction in $this.DatabaseContradictions) {
                $report += "`n$($contradiction.ToString())`n"
                $report += "Niveau de risque: $($contradiction.RiskLevel)`n"
                if ($contradiction.Impact) {
                    $report += "Impact: $($contradiction.Impact)`n"
                }
                if ($contradiction.RecommendedAction) {
                    $report += "Action recommandée: $($contradiction.RecommendedAction)`n"
                }
                $report += "---`n"
            }
        }

        $report += "`n`nDétail des contradictions au niveau objet:`n"
        $report += "-------------------------------------------`n"

        if ($this.ObjectContradictions.Count -eq 0) {
            $report += "Aucune contradiction détectée au niveau objet.`n"
        } else {
            foreach ($contradiction in $this.ObjectContradictions) {
                $report += "`n$($contradiction.ToString())`n"
                $report += "Niveau de risque: $($contradiction.RiskLevel)`n"
                if ($contradiction.Impact) {
                    $report += "Impact: $($contradiction.Impact)`n"
                }
                if ($contradiction.RecommendedAction) {
                    $report += "Action recommandée: $($contradiction.RecommendedAction)`n"
                }
                $report += "---`n"
            }
        }

        return $report
    }

    # Méthode pour générer un script de résolution pour toutes les contradictions
    [string] GenerateFixScript() {
        $script = "-- Script pour résoudre toutes les contradictions de permissions`n"
        $script += "-- Serveur: $($this.ServerName)`n"
        $script += "-- Date de génération: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")`n"
        $script += "-- Nombre total de contradictions: $($this.TotalContradictions)`n`n"

        $script += "-- Résolution des contradictions au niveau serveur`n"
        $script += "-- ------------------------------------------------`n"

        if ($this.ServerContradictions.Count -eq 0) {
            $script += "-- Aucune contradiction détectée au niveau serveur.`n"
        } else {
            foreach ($contradiction in $this.ServerContradictions) {
                $script += "`n$($contradiction.GenerateFixScript())`n"
            }
        }

        $script += "`n-- Résolution des contradictions au niveau base de données`n"
        $script += "-- --------------------------------------------------------`n"

        if ($this.DatabaseContradictions.Count -eq 0) {
            $script += "-- Aucune contradiction détectée au niveau base de données.`n"
        } else {
            foreach ($contradiction in $this.DatabaseContradictions) {
                $script += "`n$($contradiction.GenerateFixScript())`n"
            }
        }

        $script += "`n-- Résolution des contradictions au niveau objet`n"
        $script += "-- ------------------------------------------------`n"

        if ($this.ObjectContradictions.Count -eq 0) {
            $script += "-- Aucune contradiction détectée au niveau objet.`n"
        } else {
            foreach ($contradiction in $this.ObjectContradictions) {
                $script += "`n$($contradiction.GenerateFixScript())`n"
            }
        }

        return $script
    }

    # Méthode pour obtenir une représentation textuelle
    [string] ToString() {
        return "Ensemble de $($this.TotalContradictions) permissions contradictoires sur le serveur $($this.ServerName)"
    }
}

# Fonction pour créer un nouvel ensemble de permissions contradictoires
function New-SqlContradictoryPermissionsSet {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false)]
        [string]$ModelName,

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [string]$ReportTitle = "Rapport de permissions contradictoires"
    )

    $permissionsSet = [SqlContradictoryPermissionsSet]::new($ServerName, $ModelName)

    if ($Description) {
        $permissionsSet.Description = $Description
    }

    $permissionsSet.ReportTitle = $ReportTitle

    return $permissionsSet
}

# Note: Les fonctions seront exportées par le module principal
# Export-ModuleMember -Function New-SqlServerContradictoryPermission, New-SqlDatabaseContradictoryPermission, New-SqlObjectContradictoryPermission, New-SqlContradictoryPermissionsSet
