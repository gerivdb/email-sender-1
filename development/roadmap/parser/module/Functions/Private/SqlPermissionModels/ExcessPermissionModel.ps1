# ExcessPermissionModel.ps1
# DÃ©finit la structure de donnÃ©es pour reprÃ©senter les permissions excÃ©dentaires dans SQL Server

<#
.SYNOPSIS
    DÃ©finit les classes et structures de donnÃ©es pour reprÃ©senter les permissions excÃ©dentaires dans SQL Server.

.DESCRIPTION
    Ce fichier contient les dÃ©finitions des classes et structures de donnÃ©es utilisÃ©es pour reprÃ©senter
    les permissions excÃ©dentaires lors de la comparaison entre les permissions actuelles et un modÃ¨le de rÃ©fÃ©rence.
    Ces structures sont utilisÃ©es par les algorithmes de dÃ©tection d'Ã©carts de permissions.

.NOTES
    Version:        1.0
    Author:         RoadmapParser Team
    Creation Date:  2023-11-15
#>

# Classe pour reprÃ©senter une permission excÃ©dentaire au niveau serveur
class SqlServerExcessPermission {
    [string]$PermissionName      # Nom de la permission excÃ©dentaire (ex: CONNECT SQL, ALTER ANY LOGIN)
    [string]$LoginName           # Nom du login qui a cette permission en trop
    [string]$PermissionState     # Ã‰tat de la permission (GRANT, DENY)
    [string]$SecurableType       # Type d'Ã©lÃ©ment sÃ©curisable (SERVER)
    [string]$SecurableName       # Nom de l'Ã©lÃ©ment sÃ©curisable (gÃ©nÃ©ralement le nom du serveur)
    [string]$ModelName           # Nom du modÃ¨le de rÃ©fÃ©rence utilisÃ© pour la comparaison
    [string]$RiskLevel           # Niveau de risque (Critique, Ã‰levÃ©, Moyen, Faible)
    [string]$Impact              # Description de l'impact potentiel de cette permission excÃ©dentaire
    [string]$RecommendedAction   # Action recommandÃ©e pour corriger l'Ã©cart
    [string]$ScriptTemplate      # Template de script SQL pour supprimer la permission excÃ©dentaire

    # Constructeur par dÃ©faut
    SqlServerExcessPermission() {
        $this.SecurableType = "SERVER"
        $this.PermissionState = "GRANT"
        $this.RiskLevel = "Moyen"
    }

    # Constructeur avec paramÃ¨tres de base
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

    # MÃ©thode pour gÃ©nÃ©rer le script SQL de correction
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

    # MÃ©thode pour obtenir une description textuelle de la permission excÃ©dentaire
    [string] ToString() {
        return "Permission excÃ©dentaire: $($this.PermissionState) $($this.PermissionName) pour le login [$($this.LoginName)]"
    }
}

# Classe pour reprÃ©senter une permission excÃ©dentaire au niveau base de donnÃ©es
class SqlDatabaseExcessPermission {
    [string]$PermissionName      # Nom de la permission excÃ©dentaire (ex: SELECT, INSERT, UPDATE)
    [string]$DatabaseName        # Nom de la base de donnÃ©es
    [string]$UserName            # Nom de l'utilisateur de base de donnÃ©es qui a cette permission en trop
    [string]$PermissionState     # Ã‰tat de la permission (GRANT, DENY)
    [string]$SecurableType       # Type d'Ã©lÃ©ment sÃ©curisable (DATABASE, SCHEMA)
    [string]$SecurableName       # Nom de l'Ã©lÃ©ment sÃ©curisable (nom de la base de donnÃ©es ou du schÃ©ma)
    [string]$ModelName           # Nom du modÃ¨le de rÃ©fÃ©rence utilisÃ© pour la comparaison
    [string]$RiskLevel           # Niveau de risque (Critique, Ã‰levÃ©, Moyen, Faible)
    [string]$Impact              # Description de l'impact potentiel de cette permission excÃ©dentaire
    [string]$RecommendedAction   # Action recommandÃ©e pour corriger l'Ã©cart
    [string]$ScriptTemplate      # Template de script SQL pour supprimer la permission excÃ©dentaire

    # Constructeur par dÃ©faut
    SqlDatabaseExcessPermission() {
        $this.SecurableType = "DATABASE"
        $this.PermissionState = "GRANT"
        $this.RiskLevel = "Moyen"
    }

    # Constructeur avec paramÃ¨tres de base
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

    # MÃ©thode pour gÃ©nÃ©rer le script SQL de correction
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

    # MÃ©thode pour obtenir une description textuelle de la permission excÃ©dentaire
    [string] ToString() {
        return "Permission excÃ©dentaire: $($this.PermissionState) $($this.PermissionName) pour l'utilisateur [$($this.UserName)] dans la base de donnÃ©es [$($this.DatabaseName)]"
    }
}

# Classe pour reprÃ©senter une permission excÃ©dentaire au niveau objet
class SqlObjectExcessPermission {
    [string]$PermissionName      # Nom de la permission excÃ©dentaire (ex: SELECT, INSERT, UPDATE)
    [string]$DatabaseName        # Nom de la base de donnÃ©es
    [string]$UserName            # Nom de l'utilisateur de base de donnÃ©es qui a cette permission en trop
    [string]$PermissionState     # Ã‰tat de la permission (GRANT, DENY)
    [string]$ObjectType          # Type d'objet (TABLE, VIEW, PROCEDURE, FUNCTION)
    [string]$SchemaName          # Nom du schÃ©ma
    [string]$ObjectName          # Nom de l'objet
    [string]$ColumnName          # Nom de la colonne (si applicable)
    [string]$ModelName           # Nom du modÃ¨le de rÃ©fÃ©rence utilisÃ© pour la comparaison
    [string]$RiskLevel           # Niveau de risque (Critique, Ã‰levÃ©, Moyen, Faible)
    [string]$Impact              # Description de l'impact potentiel de cette permission excÃ©dentaire
    [string]$RecommendedAction   # Action recommandÃ©e pour corriger l'Ã©cart
    [string]$ScriptTemplate      # Template de script SQL pour supprimer la permission excÃ©dentaire

    # Constructeur par dÃ©faut
    SqlObjectExcessPermission() {
        $this.PermissionState = "GRANT"
        $this.RiskLevel = "Moyen"
    }

    # Constructeur avec paramÃ¨tres de base
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

    # MÃ©thode pour gÃ©nÃ©rer le script SQL de correction
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

    # MÃ©thode pour obtenir une description textuelle de la permission excÃ©dentaire
    [string] ToString() {
        $objectFullName = "[$($this.SchemaName)].[$($this.ObjectName)]"
        
        $columnClause = ""
        if (-not [string]::IsNullOrEmpty($this.ColumnName)) {
            $columnClause = " (colonne: $($this.ColumnName))"
        }
        
        return "Permission excÃ©dentaire: $($this.PermissionState) $($this.PermissionName) pour l'utilisateur [$($this.UserName)] sur l'objet $objectFullName$columnClause dans la base de donnÃ©es [$($this.DatabaseName)]"
    }
}

# Classe pour reprÃ©senter un ensemble de permissions excÃ©dentaires
class SqlExcessPermissionsSet {
    [System.Collections.Generic.List[SqlServerExcessPermission]]$ServerPermissions
    [System.Collections.Generic.List[SqlDatabaseExcessPermission]]$DatabasePermissions
    [System.Collections.Generic.List[SqlObjectExcessPermission]]$ObjectPermissions
    [string]$ServerInstance
    [string]$ComparisonDate
    [string]$ModelName
    [int]$TotalCount
    [hashtable]$RiskLevelCounts

    # Constructeur par dÃ©faut
    SqlExcessPermissionsSet() {
        $this.ServerPermissions = New-Object System.Collections.Generic.List[SqlServerExcessPermission]
        $this.DatabasePermissions = New-Object System.Collections.Generic.List[SqlDatabaseExcessPermission]
        $this.ObjectPermissions = New-Object System.Collections.Generic.List[SqlObjectExcessPermission]
        $this.ComparisonDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $this.RiskLevelCounts = @{
            "Critique" = 0
            "Ã‰levÃ©" = 0
            "Moyen" = 0
            "Faible" = 0
        }
    }

    # Constructeur avec paramÃ¨tres
    SqlExcessPermissionsSet([string]$serverInstance, [string]$modelName) {
        $this.ServerPermissions = New-Object System.Collections.Generic.List[SqlServerExcessPermission]
        $this.DatabasePermissions = New-Object System.Collections.Generic.List[SqlDatabaseExcessPermission]
        $this.ObjectPermissions = New-Object System.Collections.Generic.List[SqlObjectExcessPermission]
        $this.ServerInstance = $serverInstance
        $this.ModelName = $modelName
        $this.ComparisonDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $this.RiskLevelCounts = @{
            "Critique" = 0
            "Ã‰levÃ©" = 0
            "Moyen" = 0
            "Faible" = 0
        }
    }

    # MÃ©thode pour ajouter une permission excÃ©dentaire au niveau serveur
    [void] AddServerPermission([SqlServerExcessPermission]$permission) {
        $this.ServerPermissions.Add($permission)
        $this.UpdateCounts($permission.RiskLevel)
    }

    # MÃ©thode pour ajouter une permission excÃ©dentaire au niveau base de donnÃ©es
    [void] AddDatabasePermission([SqlDatabaseExcessPermission]$permission) {
        $this.DatabasePermissions.Add($permission)
        $this.UpdateCounts($permission.RiskLevel)
    }

    # MÃ©thode pour ajouter une permission excÃ©dentaire au niveau objet
    [void] AddObjectPermission([SqlObjectExcessPermission]$permission) {
        $this.ObjectPermissions.Add($permission)
        $this.UpdateCounts($permission.RiskLevel)
    }

    # MÃ©thode privÃ©e pour mettre Ã  jour les compteurs
    hidden [void] UpdateCounts([string]$riskLevel) {
        if ($this.RiskLevelCounts.ContainsKey($riskLevel)) {
            $this.RiskLevelCounts[$riskLevel]++
        }
        $this.TotalCount = $this.ServerPermissions.Count + $this.DatabasePermissions.Count + $this.ObjectPermissions.Count
    }

    # MÃ©thode pour filtrer les permissions par niveau de risque
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

    # MÃ©thode pour gÃ©nÃ©rer un script SQL de correction pour toutes les permissions excÃ©dentaires
    [string] GenerateFixScript() {
        $script = "-- Script de correction des permissions excÃ©dentaires`n"
        $script += "-- Instance: $($this.ServerInstance)`n"
        $script += "-- Date: $($this.ComparisonDate)`n"
        $script += "-- ModÃ¨le de rÃ©fÃ©rence: $($this.ModelName)`n`n"
        
        if ($this.ServerPermissions.Count -gt 0) {
            $script += "-- Permissions excÃ©dentaires au niveau serveur`n"
            foreach ($perm in $this.ServerPermissions) {
                $script += $perm.GenerateFixScript() + "`n"
            }
            $script += "`n"
        }
        
        # Regrouper les permissions de base de donnÃ©es par base de donnÃ©es
        $dbGroups = $this.DatabasePermissions | Group-Object -Property DatabaseName
        
        foreach ($dbGroup in $dbGroups) {
            $script += "-- Permissions excÃ©dentaires pour la base de donnÃ©es [$($dbGroup.Name)]`n"
            $script += "USE [$($dbGroup.Name)];`n"
            
            foreach ($perm in $dbGroup.Group) {
                # Supprimer la partie USE [database] car elle est dÃ©jÃ  incluse
                $permScript = $perm.GenerateFixScript() -replace "USE \[[^\]]+\];`n", ""
                $script += $permScript + "`n"
            }
            
            $script += "`n"
        }
        
        # Regrouper les permissions d'objet par base de donnÃ©es
        $objGroups = $this.ObjectPermissions | Group-Object -Property DatabaseName
        
        foreach ($objGroup in $objGroups) {
            $script += "-- Permissions excÃ©dentaires pour les objets de la base de donnÃ©es [$($objGroup.Name)]`n"
            $script += "USE [$($objGroup.Name)];`n"
            
            foreach ($perm in $objGroup.Group) {
                # Supprimer la partie USE [database] car elle est dÃ©jÃ  incluse
                $permScript = $perm.GenerateFixScript() -replace "USE \[[^\]]+\];`n", ""
                $script += $permScript + "`n"
            }
            
            $script += "`n"
        }
        
        return $script
    }

    # MÃ©thode pour obtenir un rÃ©sumÃ© des permissions excÃ©dentaires
    [string] GetSummary() {
        $summary = "RÃ©sumÃ© des permissions excÃ©dentaires pour l'instance $($this.ServerInstance)`n"
        $summary += "Comparaison avec le modÃ¨le: $($this.ModelName)`n"
        $summary += "Date: $($this.ComparisonDate)`n`n"
        
        $summary += "Nombre total de permissions excÃ©dentaires: $($this.TotalCount)`n"
        $summary += "- Permissions serveur: $($this.ServerPermissions.Count)`n"
        $summary += "- Permissions base de donnÃ©es: $($this.DatabasePermissions.Count)`n"
        $summary += "- Permissions objet: $($this.ObjectPermissions.Count)`n`n"
        
        $summary += "RÃ©partition par niveau de risque:`n"
        $summary += "- Critique: $($this.RiskLevelCounts['Critique'])`n"
        $summary += "- Ã‰levÃ©: $($this.RiskLevelCounts['Ã‰levÃ©'])`n"
        $summary += "- Moyen: $($this.RiskLevelCounts['Moyen'])`n"
        $summary += "- Faible: $($this.RiskLevelCounts['Faible'])`n"
        
        return $summary
    }
}

# Fonction pour crÃ©er un nouvel ensemble de permissions excÃ©dentaires
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

# Fonction pour crÃ©er une nouvelle permission excÃ©dentaire au niveau serveur
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
        [ValidateSet("Critique", "Ã‰levÃ©", "Moyen", "Faible")]
        [string]$RiskLevel = "Moyen"
    )
    
    return [SqlServerExcessPermission]::new($PermissionName, $LoginName, $PermissionState, $SecurableName, $ModelName, $RiskLevel)
}

# Fonction pour crÃ©er une nouvelle permission excÃ©dentaire au niveau base de donnÃ©es
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
        [ValidateSet("Critique", "Ã‰levÃ©", "Moyen", "Faible")]
        [string]$RiskLevel = "Moyen"
    )
    
    if ([string]::IsNullOrEmpty($SecurableName)) {
        $SecurableName = $DatabaseName
    }
    
    return [SqlDatabaseExcessPermission]::new($PermissionName, $DatabaseName, $UserName, $PermissionState, $SecurableType, $SecurableName, $ModelName, $RiskLevel)
}

# Fonction pour crÃ©er une nouvelle permission excÃ©dentaire au niveau objet
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
        [ValidateSet("Critique", "Ã‰levÃ©", "Moyen", "Faible")]
        [string]$RiskLevel = "Moyen"
    )
    
    return [SqlObjectExcessPermission]::new($PermissionName, $DatabaseName, $UserName, $PermissionState, $ObjectType, $SchemaName, $ObjectName, $ColumnName, $ModelName, $RiskLevel)
}

# Exporter les fonctions
Export-ModuleMember -Function New-SqlExcessPermissionsSet, New-SqlServerExcessPermission, New-SqlDatabaseExcessPermission, New-SqlObjectExcessPermission
