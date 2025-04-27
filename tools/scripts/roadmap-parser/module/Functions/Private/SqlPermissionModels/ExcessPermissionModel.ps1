# ExcessPermissionModel.ps1
# Définit la structure de données pour représenter les permissions excédentaires dans SQL Server

<#
.SYNOPSIS
    Définit les classes et structures de données pour représenter les permissions excédentaires dans SQL Server.

.DESCRIPTION
    Ce fichier contient les définitions des classes et structures de données utilisées pour représenter
    les permissions excédentaires lors de la comparaison entre les permissions actuelles et un modèle de référence.
    Ces structures sont utilisées par les algorithmes de détection d'écarts de permissions.

.NOTES
    Version:        1.0
    Author:         RoadmapParser Team
    Creation Date:  2023-11-15
#>

# Classe pour représenter une permission excédentaire au niveau serveur
class SqlServerExcessPermission {
    [string]$PermissionName      # Nom de la permission excédentaire (ex: CONNECT SQL, ALTER ANY LOGIN)
    [string]$LoginName           # Nom du login qui a cette permission en trop
    [string]$PermissionState     # État de la permission (GRANT, DENY)
    [string]$SecurableType       # Type d'élément sécurisable (SERVER)
    [string]$SecurableName       # Nom de l'élément sécurisable (généralement le nom du serveur)
    [string]$ModelName           # Nom du modèle de référence utilisé pour la comparaison
    [string]$RiskLevel           # Niveau de risque (Critique, Élevé, Moyen, Faible)
    [string]$Impact              # Description de l'impact potentiel de cette permission excédentaire
    [string]$RecommendedAction   # Action recommandée pour corriger l'écart
    [string]$ScriptTemplate      # Template de script SQL pour supprimer la permission excédentaire

    # Constructeur par défaut
    SqlServerExcessPermission() {
        $this.SecurableType = "SERVER"
        $this.PermissionState = "GRANT"
        $this.RiskLevel = "Moyen"
    }

    # Constructeur avec paramètres de base
    SqlServerExcessPermission([string]$permissionName, [string]$loginName, [string]$permissionState) {
        $this.PermissionName = $permissionName
        $this.LoginName = $loginName
        $this.PermissionState = $permissionState
        $this.SecurableType = "SERVER"
        $this.RiskLevel = "Moyen"
    }

    # Constructeur complet
    SqlServerExcessPermission(
        [string]$permissionName,
        [string]$loginName,
        [string]$permissionState,
        [string]$securableName,
        [string]$modelName,
        [string]$riskLevel
    ) {
        $this.PermissionName = $permissionName
        $this.LoginName = $loginName
        $this.PermissionState = $permissionState
        $this.SecurableType = "SERVER"
        $this.SecurableName = $securableName
        $this.ModelName = $modelName
        $this.RiskLevel = $riskLevel
    }

    # Méthode pour générer le script SQL de correction
    [string] GenerateFixScript() {
        if ([string]::IsNullOrEmpty($this.ScriptTemplate)) {
            return "REVOKE $($this.PermissionName) FROM [$($this.LoginName)];"
        }
        else {
            $script = $this.ScriptTemplate
            $script = $script.Replace("{PermissionName}", $this.PermissionName)
            $script = $script.Replace("{LoginName}", $this.LoginName)
            $script = $script.Replace("{PermissionState}", $this.PermissionState)
            $script = $script.Replace("{SecurableName}", $this.SecurableName)
            return $script
        }
    }

    # Méthode pour obtenir une description textuelle de la permission excédentaire
    [string] ToString() {
        return "Permission excédentaire: $($this.PermissionState) $($this.PermissionName) pour le login [$($this.LoginName)]"
    }
}

# Classe pour représenter une permission excédentaire au niveau base de données
class SqlDatabaseExcessPermission {
    [string]$PermissionName      # Nom de la permission excédentaire (ex: SELECT, INSERT, UPDATE)
    [string]$DatabaseName        # Nom de la base de données
    [string]$UserName            # Nom de l'utilisateur de base de données qui a cette permission en trop
    [string]$PermissionState     # État de la permission (GRANT, DENY)
    [string]$SecurableType       # Type d'élément sécurisable (DATABASE, SCHEMA)
    [string]$SecurableName       # Nom de l'élément sécurisable (nom de la base de données ou du schéma)
    [string]$ModelName           # Nom du modèle de référence utilisé pour la comparaison
    [string]$RiskLevel           # Niveau de risque (Critique, Élevé, Moyen, Faible)
    [string]$Impact              # Description de l'impact potentiel de cette permission excédentaire
    [string]$RecommendedAction   # Action recommandée pour corriger l'écart
    [string]$ScriptTemplate      # Template de script SQL pour supprimer la permission excédentaire

    # Constructeur par défaut
    SqlDatabaseExcessPermission() {
        $this.SecurableType = "DATABASE"
        $this.PermissionState = "GRANT"
        $this.RiskLevel = "Moyen"
    }

    # Constructeur avec paramètres de base
    SqlDatabaseExcessPermission([string]$permissionName, [string]$databaseName, [string]$userName, [string]$permissionState) {
        $this.PermissionName = $permissionName
        $this.DatabaseName = $databaseName
        $this.UserName = $userName
        $this.PermissionState = $permissionState
        $this.SecurableType = "DATABASE"
        $this.SecurableName = $databaseName
        $this.RiskLevel = "Moyen"
    }

    # Constructeur complet
    SqlDatabaseExcessPermission(
        [string]$permissionName,
        [string]$databaseName,
        [string]$userName,
        [string]$permissionState,
        [string]$securableType,
        [string]$securableName,
        [string]$modelName,
        [string]$riskLevel
    ) {
        $this.PermissionName = $permissionName
        $this.DatabaseName = $databaseName
        $this.UserName = $userName
        $this.PermissionState = $permissionState
        $this.SecurableType = $securableType
        $this.SecurableName = $securableName
        $this.ModelName = $modelName
        $this.RiskLevel = $riskLevel
    }

    # Méthode pour générer le script SQL de correction
    [string] GenerateFixScript() {
        if ([string]::IsNullOrEmpty($this.ScriptTemplate)) {
            $securablePrefix = switch ($this.SecurableType) {
                "DATABASE" { "DATABASE::[$($this.DatabaseName)]" }
                "SCHEMA" { "SCHEMA::[$($this.SecurableName)]" }
                default { "[$($this.SecurableName)]" }
            }
            
            return "USE [$($this.DatabaseName)];`nREVOKE $($this.PermissionName) ON $securablePrefix FROM [$($this.UserName)];"
        }
        else {
            $script = $this.ScriptTemplate
            $script = $script.Replace("{PermissionName}", $this.PermissionName)
            $script = $script.Replace("{DatabaseName}", $this.DatabaseName)
            $script = $script.Replace("{UserName}", $this.UserName)
            $script = $script.Replace("{PermissionState}", $this.PermissionState)
            $script = $script.Replace("{SecurableType}", $this.SecurableType)
            $script = $script.Replace("{SecurableName}", $this.SecurableName)
            return $script
        }
    }

    # Méthode pour obtenir une description textuelle de la permission excédentaire
    [string] ToString() {
        return "Permission excédentaire: $($this.PermissionState) $($this.PermissionName) pour l'utilisateur [$($this.UserName)] dans la base de données [$($this.DatabaseName)]"
    }
}

# Classe pour représenter une permission excédentaire au niveau objet
class SqlObjectExcessPermission {
    [string]$PermissionName      # Nom de la permission excédentaire (ex: SELECT, INSERT, UPDATE)
    [string]$DatabaseName        # Nom de la base de données
    [string]$UserName            # Nom de l'utilisateur de base de données qui a cette permission en trop
    [string]$PermissionState     # État de la permission (GRANT, DENY)
    [string]$ObjectType          # Type d'objet (TABLE, VIEW, PROCEDURE, FUNCTION)
    [string]$SchemaName          # Nom du schéma
    [string]$ObjectName          # Nom de l'objet
    [string]$ColumnName          # Nom de la colonne (si applicable)
    [string]$ModelName           # Nom du modèle de référence utilisé pour la comparaison
    [string]$RiskLevel           # Niveau de risque (Critique, Élevé, Moyen, Faible)
    [string]$Impact              # Description de l'impact potentiel de cette permission excédentaire
    [string]$RecommendedAction   # Action recommandée pour corriger l'écart
    [string]$ScriptTemplate      # Template de script SQL pour supprimer la permission excédentaire

    # Constructeur par défaut
    SqlObjectExcessPermission() {
        $this.PermissionState = "GRANT"
        $this.RiskLevel = "Moyen"
    }

    # Constructeur avec paramètres de base
    SqlObjectExcessPermission(
        [string]$permissionName,
        [string]$databaseName,
        [string]$userName,
        [string]$permissionState,
        [string]$objectType,
        [string]$schemaName,
        [string]$objectName
    ) {
        $this.PermissionName = $permissionName
        $this.DatabaseName = $databaseName
        $this.UserName = $userName
        $this.PermissionState = $permissionState
        $this.ObjectType = $objectType
        $this.SchemaName = $schemaName
        $this.ObjectName = $objectName
        $this.RiskLevel = "Moyen"
    }

    # Constructeur complet
    SqlObjectExcessPermission(
        [string]$permissionName,
        [string]$databaseName,
        [string]$userName,
        [string]$permissionState,
        [string]$objectType,
        [string]$schemaName,
        [string]$objectName,
        [string]$columnName,
        [string]$modelName,
        [string]$riskLevel
    ) {
        $this.PermissionName = $permissionName
        $this.DatabaseName = $databaseName
        $this.UserName = $userName
        $this.PermissionState = $permissionState
        $this.ObjectType = $objectType
        $this.SchemaName = $schemaName
        $this.ObjectName = $objectName
        $this.ColumnName = $columnName
        $this.ModelName = $modelName
        $this.RiskLevel = $riskLevel
    }

    # Méthode pour générer le script SQL de correction
    [string] GenerateFixScript() {
        if ([string]::IsNullOrEmpty($this.ScriptTemplate)) {
            $objectFullName = "[$($this.SchemaName)].[$($this.ObjectName)]"
            
            $columnClause = ""
            if (-not [string]::IsNullOrEmpty($this.ColumnName)) {
                $columnClause = "($($this.ColumnName))"
            }
            
            return "USE [$($this.DatabaseName)];`nREVOKE $($this.PermissionName)$columnClause ON $objectFullName FROM [$($this.UserName)];"
        }
        else {
            $script = $this.ScriptTemplate
            $script = $script.Replace("{PermissionName}", $this.PermissionName)
            $script = $script.Replace("{DatabaseName}", $this.DatabaseName)
            $script = $script.Replace("{UserName}", $this.UserName)
            $script = $script.Replace("{PermissionState}", $this.PermissionState)
            $script = $script.Replace("{ObjectType}", $this.ObjectType)
            $script = $script.Replace("{SchemaName}", $this.SchemaName)
            $script = $script.Replace("{ObjectName}", $this.ObjectName)
            $script = $script.Replace("{ColumnName}", $this.ColumnName)
            return $script
        }
    }

    # Méthode pour obtenir une description textuelle de la permission excédentaire
    [string] ToString() {
        $objectFullName = "[$($this.SchemaName)].[$($this.ObjectName)]"
        
        $columnClause = ""
        if (-not [string]::IsNullOrEmpty($this.ColumnName)) {
            $columnClause = " (colonne: $($this.ColumnName))"
        }
        
        return "Permission excédentaire: $($this.PermissionState) $($this.PermissionName) pour l'utilisateur [$($this.UserName)] sur l'objet $objectFullName$columnClause dans la base de données [$($this.DatabaseName)]"
    }
}

# Classe pour représenter un ensemble de permissions excédentaires
class SqlExcessPermissionsSet {
    [System.Collections.Generic.List[SqlServerExcessPermission]]$ServerPermissions
    [System.Collections.Generic.List[SqlDatabaseExcessPermission]]$DatabasePermissions
    [System.Collections.Generic.List[SqlObjectExcessPermission]]$ObjectPermissions
    [string]$ServerInstance
    [string]$ComparisonDate
    [string]$ModelName
    [int]$TotalCount
    [hashtable]$RiskLevelCounts

    # Constructeur par défaut
    SqlExcessPermissionsSet() {
        $this.ServerPermissions = New-Object System.Collections.Generic.List[SqlServerExcessPermission]
        $this.DatabasePermissions = New-Object System.Collections.Generic.List[SqlDatabaseExcessPermission]
        $this.ObjectPermissions = New-Object System.Collections.Generic.List[SqlObjectExcessPermission]
        $this.ComparisonDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $this.RiskLevelCounts = @{
            "Critique" = 0
            "Élevé" = 0
            "Moyen" = 0
            "Faible" = 0
        }
    }

    # Constructeur avec paramètres
    SqlExcessPermissionsSet([string]$serverInstance, [string]$modelName) {
        $this.ServerPermissions = New-Object System.Collections.Generic.List[SqlServerExcessPermission]
        $this.DatabasePermissions = New-Object System.Collections.Generic.List[SqlDatabaseExcessPermission]
        $this.ObjectPermissions = New-Object System.Collections.Generic.List[SqlObjectExcessPermission]
        $this.ServerInstance = $serverInstance
        $this.ModelName = $modelName
        $this.ComparisonDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $this.RiskLevelCounts = @{
            "Critique" = 0
            "Élevé" = 0
            "Moyen" = 0
            "Faible" = 0
        }
    }

    # Méthode pour ajouter une permission excédentaire au niveau serveur
    [void] AddServerPermission([SqlServerExcessPermission]$permission) {
        $this.ServerPermissions.Add($permission)
        $this.UpdateCounts($permission.RiskLevel)
    }

    # Méthode pour ajouter une permission excédentaire au niveau base de données
    [void] AddDatabasePermission([SqlDatabaseExcessPermission]$permission) {
        $this.DatabasePermissions.Add($permission)
        $this.UpdateCounts($permission.RiskLevel)
    }

    # Méthode pour ajouter une permission excédentaire au niveau objet
    [void] AddObjectPermission([SqlObjectExcessPermission]$permission) {
        $this.ObjectPermissions.Add($permission)
        $this.UpdateCounts($permission.RiskLevel)
    }

    # Méthode privée pour mettre à jour les compteurs
    hidden [void] UpdateCounts([string]$riskLevel) {
        if ($this.RiskLevelCounts.ContainsKey($riskLevel)) {
            $this.RiskLevelCounts[$riskLevel]++
        }
        $this.TotalCount = $this.ServerPermissions.Count + $this.DatabasePermissions.Count + $this.ObjectPermissions.Count
    }

    # Méthode pour filtrer les permissions par niveau de risque
    [SqlExcessPermissionsSet] FilterByRiskLevel([string]$riskLevel) {
        $result = [SqlExcessPermissionsSet]::new($this.ServerInstance, $this.ModelName)
        
        foreach ($perm in $this.ServerPermissions) {
            if ($perm.RiskLevel -eq $riskLevel) {
                $result.AddServerPermission($perm)
            }
        }
        
        foreach ($perm in $this.DatabasePermissions) {
            if ($perm.RiskLevel -eq $riskLevel) {
                $result.AddDatabasePermission($perm)
            }
        }
        
        foreach ($perm in $this.ObjectPermissions) {
            if ($perm.RiskLevel -eq $riskLevel) {
                $result.AddObjectPermission($perm)
            }
        }
        
        return $result
    }

    # Méthode pour générer un script SQL de correction pour toutes les permissions excédentaires
    [string] GenerateFixScript() {
        $script = "-- Script de correction des permissions excédentaires`n"
        $script += "-- Instance: $($this.ServerInstance)`n"
        $script += "-- Date: $($this.ComparisonDate)`n"
        $script += "-- Modèle de référence: $($this.ModelName)`n`n"
        
        if ($this.ServerPermissions.Count -gt 0) {
            $script += "-- Permissions excédentaires au niveau serveur`n"
            foreach ($perm in $this.ServerPermissions) {
                $script += $perm.GenerateFixScript() + "`n"
            }
            $script += "`n"
        }
        
        # Regrouper les permissions de base de données par base de données
        $dbGroups = $this.DatabasePermissions | Group-Object -Property DatabaseName
        
        foreach ($dbGroup in $dbGroups) {
            $script += "-- Permissions excédentaires pour la base de données [$($dbGroup.Name)]`n"
            $script += "USE [$($dbGroup.Name)];`n"
            
            foreach ($perm in $dbGroup.Group) {
                # Supprimer la partie USE [database] car elle est déjà incluse
                $permScript = $perm.GenerateFixScript() -replace "USE \[[^\]]+\];`n", ""
                $script += $permScript + "`n"
            }
            
            $script += "`n"
        }
        
        # Regrouper les permissions d'objet par base de données
        $objGroups = $this.ObjectPermissions | Group-Object -Property DatabaseName
        
        foreach ($objGroup in $objGroups) {
            $script += "-- Permissions excédentaires pour les objets de la base de données [$($objGroup.Name)]`n"
            $script += "USE [$($objGroup.Name)];`n"
            
            foreach ($perm in $objGroup.Group) {
                # Supprimer la partie USE [database] car elle est déjà incluse
                $permScript = $perm.GenerateFixScript() -replace "USE \[[^\]]+\];`n", ""
                $script += $permScript + "`n"
            }
            
            $script += "`n"
        }
        
        return $script
    }

    # Méthode pour obtenir un résumé des permissions excédentaires
    [string] GetSummary() {
        $summary = "Résumé des permissions excédentaires pour l'instance $($this.ServerInstance)`n"
        $summary += "Comparaison avec le modèle: $($this.ModelName)`n"
        $summary += "Date: $($this.ComparisonDate)`n`n"
        
        $summary += "Nombre total de permissions excédentaires: $($this.TotalCount)`n"
        $summary += "- Permissions serveur: $($this.ServerPermissions.Count)`n"
        $summary += "- Permissions base de données: $($this.DatabasePermissions.Count)`n"
        $summary += "- Permissions objet: $($this.ObjectPermissions.Count)`n`n"
        
        $summary += "Répartition par niveau de risque:`n"
        $summary += "- Critique: $($this.RiskLevelCounts['Critique'])`n"
        $summary += "- Élevé: $($this.RiskLevelCounts['Élevé'])`n"
        $summary += "- Moyen: $($this.RiskLevelCounts['Moyen'])`n"
        $summary += "- Faible: $($this.RiskLevelCounts['Faible'])`n"
        
        return $summary
    }
}

# Fonction pour créer un nouvel ensemble de permissions excédentaires
function New-SqlExcessPermissionsSet {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ServerInstance,
        
        [Parameter(Mandatory = $false)]
        [string]$ModelName = "DefaultModel"
    )
    
    return [SqlExcessPermissionsSet]::new($ServerInstance, $ModelName)
}

# Fonction pour créer une nouvelle permission excédentaire au niveau serveur
function New-SqlServerExcessPermission {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PermissionName,
        
        [Parameter(Mandatory = $true)]
        [string]$LoginName,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("GRANT", "DENY")]
        [string]$PermissionState = "GRANT",
        
        [Parameter(Mandatory = $false)]
        [string]$SecurableName,
        
        [Parameter(Mandatory = $false)]
        [string]$ModelName,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Critique", "Élevé", "Moyen", "Faible")]
        [string]$RiskLevel = "Moyen"
    )
    
    return [SqlServerExcessPermission]::new($PermissionName, $LoginName, $PermissionState, $SecurableName, $ModelName, $RiskLevel)
}

# Fonction pour créer une nouvelle permission excédentaire au niveau base de données
function New-SqlDatabaseExcessPermission {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PermissionName,
        
        [Parameter(Mandatory = $true)]
        [string]$DatabaseName,
        
        [Parameter(Mandatory = $true)]
        [string]$UserName,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("GRANT", "DENY")]
        [string]$PermissionState = "GRANT",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("DATABASE", "SCHEMA")]
        [string]$SecurableType = "DATABASE",
        
        [Parameter(Mandatory = $false)]
        [string]$SecurableName,
        
        [Parameter(Mandatory = $false)]
        [string]$ModelName,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Critique", "Élevé", "Moyen", "Faible")]
        [string]$RiskLevel = "Moyen"
    )
    
    if ([string]::IsNullOrEmpty($SecurableName)) {
        $SecurableName = $DatabaseName
    }
    
    return [SqlDatabaseExcessPermission]::new($PermissionName, $DatabaseName, $UserName, $PermissionState, $SecurableType, $SecurableName, $ModelName, $RiskLevel)
}

# Fonction pour créer une nouvelle permission excédentaire au niveau objet
function New-SqlObjectExcessPermission {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PermissionName,
        
        [Parameter(Mandatory = $true)]
        [string]$DatabaseName,
        
        [Parameter(Mandatory = $true)]
        [string]$UserName,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("GRANT", "DENY")]
        [string]$PermissionState = "GRANT",
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("TABLE", "VIEW", "PROCEDURE", "FUNCTION", "ASSEMBLY", "TYPE")]
        [string]$ObjectType,
        
        [Parameter(Mandatory = $true)]
        [string]$SchemaName,
        
        [Parameter(Mandatory = $true)]
        [string]$ObjectName,
        
        [Parameter(Mandatory = $false)]
        [string]$ColumnName,
        
        [Parameter(Mandatory = $false)]
        [string]$ModelName,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Critique", "Élevé", "Moyen", "Faible")]
        [string]$RiskLevel = "Moyen"
    )
    
    return [SqlObjectExcessPermission]::new($PermissionName, $DatabaseName, $UserName, $PermissionState, $ObjectType, $SchemaName, $ObjectName, $ColumnName, $ModelName, $RiskLevel)
}

# Exporter les fonctions
Export-ModuleMember -Function New-SqlExcessPermissionsSet, New-SqlServerExcessPermission, New-SqlDatabaseExcessPermission, New-SqlObjectExcessPermission
