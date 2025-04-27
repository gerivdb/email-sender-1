# MissingPermissionModel.ps1
# DÃ©finit la structure de donnÃ©es pour reprÃ©senter les permissions manquantes dans SQL Server

<#
.SYNOPSIS
    DÃ©finit les classes et structures de donnÃ©es pour reprÃ©senter les permissions manquantes dans SQL Server.

.DESCRIPTION
    Ce fichier contient les dÃ©finitions des classes et structures de donnÃ©es utilisÃ©es pour reprÃ©senter
    les permissions manquantes lors de la comparaison entre les permissions actuelles et un modÃ¨le de rÃ©fÃ©rence.
    Ces structures sont utilisÃ©es par les algorithmes de dÃ©tection d'Ã©carts de permissions.

.NOTES
    Version:        1.0
    Author:         RoadmapParser Team
    Creation Date:  2023-11-15
#>

# Classe pour reprÃ©senter une permission manquante au niveau serveur
class SqlServerMissingPermission {
    [string]$PermissionName      # Nom de la permission manquante (ex: CONNECT SQL, ALTER ANY LOGIN)
    [string]$LoginName           # Nom du login qui devrait avoir cette permission
    [string]$PermissionState     # Ã‰tat de la permission (GRANT, DENY)
    [string]$SecurableType       # Type d'Ã©lÃ©ment sÃ©curisable (SERVER)
    [string]$SecurableName       # Nom de l'Ã©lÃ©ment sÃ©curisable (gÃ©nÃ©ralement le nom du serveur)
    [string]$ExpectedInModel     # Nom du modÃ¨le de rÃ©fÃ©rence qui attend cette permission
    [string]$Severity            # SÃ©vÃ©ritÃ© de l'Ã©cart (Critique, Ã‰levÃ©e, Moyenne, Faible)
    [string]$Impact              # Description de l'impact potentiel de cette permission manquante
    [string]$RecommendedAction   # Action recommandÃ©e pour corriger l'Ã©cart
    [string]$ScriptTemplate      # Template de script SQL pour ajouter la permission manquante

    # Constructeur par dÃ©faut
    SqlServerMissingPermission() {
        $this.SecurableType = "SERVER"
        $this.PermissionState = "GRANT"
        $this.Severity = "Moyenne"
    }

    # Constructeur avec paramÃ¨tres de base
    SqlServerMissingPermission([string]$permissionName, [string]$loginName, [string]$permissionState) {
        $this.PermissionName = $permissionName
        $this.LoginName = $loginName
        $this.PermissionState = $permissionState
        $this.SecurableType = "SERVER"
        $this.Severity = "Moyenne"
    }

    # Constructeur complet
    SqlServerMissingPermission(
        [string]$permissionName,
        [string]$loginName,
        [string]$permissionState,
        [string]$securableName,
        [string]$expectedInModel,
        [string]$severity
    ) {
        $this.PermissionName = $permissionName
        $this.LoginName = $loginName
        $this.PermissionState = $permissionState
        $this.SecurableType = "SERVER"
        $this.SecurableName = $securableName
        $this.ExpectedInModel = $expectedInModel
        $this.Severity = $severity
    }

    # MÃ©thode pour gÃ©nÃ©rer le script SQL de correction
    [string] GenerateFixScript() {
        if ([string]::IsNullOrEmpty($this.ScriptTemplate)) {
            return "$($this.PermissionState) $($this.PermissionName) TO [$($this.LoginName)];"
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

    # MÃ©thode pour obtenir une description textuelle de la permission manquante
    [string] ToString() {
        return "Permission manquante: $($this.PermissionState) $($this.PermissionName) pour le login [$($this.LoginName)]"
    }
}

# Classe pour reprÃ©senter une permission manquante au niveau base de donnÃ©es
class SqlDatabaseMissingPermission {
    [string]$PermissionName      # Nom de la permission manquante (ex: SELECT, INSERT, UPDATE)
    [string]$DatabaseName        # Nom de la base de donnÃ©es
    [string]$UserName            # Nom de l'utilisateur de base de donnÃ©es qui devrait avoir cette permission
    [string]$PermissionState     # Ã‰tat de la permission (GRANT, DENY)
    [string]$SecurableType       # Type d'Ã©lÃ©ment sÃ©curisable (DATABASE, SCHEMA)
    [string]$SecurableName       # Nom de l'Ã©lÃ©ment sÃ©curisable (nom de la base de donnÃ©es ou du schÃ©ma)
    [string]$ExpectedInModel     # Nom du modÃ¨le de rÃ©fÃ©rence qui attend cette permission
    [string]$Severity            # SÃ©vÃ©ritÃ© de l'Ã©cart (Critique, Ã‰levÃ©e, Moyenne, Faible)
    [string]$Impact              # Description de l'impact potentiel de cette permission manquante
    [string]$RecommendedAction   # Action recommandÃ©e pour corriger l'Ã©cart
    [string]$ScriptTemplate      # Template de script SQL pour ajouter la permission manquante

    # Constructeur par dÃ©faut
    SqlDatabaseMissingPermission() {
        $this.SecurableType = "DATABASE"
        $this.PermissionState = "GRANT"
        $this.Severity = "Moyenne"
    }

    # Constructeur avec paramÃ¨tres de base
    SqlDatabaseMissingPermission([string]$permissionName, [string]$databaseName, [string]$userName, [string]$permissionState) {
        $this.PermissionName = $permissionName
        $this.DatabaseName = $databaseName
        $this.UserName = $userName
        $this.PermissionState = $permissionState
        $this.SecurableType = "DATABASE"
        $this.SecurableName = $databaseName
        $this.Severity = "Moyenne"
    }

    # Constructeur complet
    SqlDatabaseMissingPermission(
        [string]$permissionName,
        [string]$databaseName,
        [string]$userName,
        [string]$permissionState,
        [string]$securableType,
        [string]$securableName,
        [string]$expectedInModel,
        [string]$severity
    ) {
        $this.PermissionName = $permissionName
        $this.DatabaseName = $databaseName
        $this.UserName = $userName
        $this.PermissionState = $permissionState
        $this.SecurableType = $securableType
        $this.SecurableName = $securableName
        $this.ExpectedInModel = $expectedInModel
        $this.Severity = $severity
    }

    # MÃ©thode pour gÃ©nÃ©rer le script SQL de correction
    [string] GenerateFixScript() {
        if ([string]::IsNullOrEmpty($this.ScriptTemplate)) {
            $securablePrefix = switch ($this.SecurableType) {
                "DATABASE" { "DATABASE::[$($this.DatabaseName)]" }
                "SCHEMA" { "SCHEMA::[$($this.SecurableName)]" }
                default { "[$($this.SecurableName)]" }
            }
            
            return "USE [$($this.DatabaseName)];`n$($this.PermissionState) $($this.PermissionName) ON $securablePrefix TO [$($this.UserName)];"
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

    # MÃ©thode pour obtenir une description textuelle de la permission manquante
    [string] ToString() {
        return "Permission manquante: $($this.PermissionState) $($this.PermissionName) pour l'utilisateur [$($this.UserName)] dans la base de donnÃ©es [$($this.DatabaseName)]"
    }
}

# Classe pour reprÃ©senter une permission manquante au niveau objet
class SqlObjectMissingPermission {
    [string]$PermissionName      # Nom de la permission manquante (ex: SELECT, INSERT, UPDATE)
    [string]$DatabaseName        # Nom de la base de donnÃ©es
    [string]$UserName            # Nom de l'utilisateur de base de donnÃ©es qui devrait avoir cette permission
    [string]$PermissionState     # Ã‰tat de la permission (GRANT, DENY)
    [string]$ObjectType          # Type d'objet (TABLE, VIEW, PROCEDURE, FUNCTION)
    [string]$SchemaName          # Nom du schÃ©ma
    [string]$ObjectName          # Nom de l'objet
    [string]$ColumnName          # Nom de la colonne (si applicable)
    [string]$ExpectedInModel     # Nom du modÃ¨le de rÃ©fÃ©rence qui attend cette permission
    [string]$Severity            # SÃ©vÃ©ritÃ© de l'Ã©cart (Critique, Ã‰levÃ©e, Moyenne, Faible)
    [string]$Impact              # Description de l'impact potentiel de cette permission manquante
    [string]$RecommendedAction   # Action recommandÃ©e pour corriger l'Ã©cart
    [string]$ScriptTemplate      # Template de script SQL pour ajouter la permission manquante

    # Constructeur par dÃ©faut
    SqlObjectMissingPermission() {
        $this.PermissionState = "GRANT"
        $this.Severity = "Moyenne"
    }

    # Constructeur avec paramÃ¨tres de base
    SqlObjectMissingPermission(
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
        $this.Severity = "Moyenne"
    }

    # Constructeur complet
    SqlObjectMissingPermission(
        [string]$permissionName,
        [string]$databaseName,
        [string]$userName,
        [string]$permissionState,
        [string]$objectType,
        [string]$schemaName,
        [string]$objectName,
        [string]$columnName,
        [string]$expectedInModel,
        [string]$severity
    ) {
        $this.PermissionName = $permissionName
        $this.DatabaseName = $databaseName
        $this.UserName = $userName
        $this.PermissionState = $permissionState
        $this.ObjectType = $objectType
        $this.SchemaName = $schemaName
        $this.ObjectName = $objectName
        $this.ColumnName = $columnName
        $this.ExpectedInModel = $expectedInModel
        $this.Severity = $severity
    }

    # MÃ©thode pour gÃ©nÃ©rer le script SQL de correction
    [string] GenerateFixScript() {
        if ([string]::IsNullOrEmpty($this.ScriptTemplate)) {
            $objectFullName = "[$($this.SchemaName)].[$($this.ObjectName)]"
            
            $columnClause = ""
            if (-not [string]::IsNullOrEmpty($this.ColumnName)) {
                $columnClause = "($($this.ColumnName))"
            }
            
            return "USE [$($this.DatabaseName)];`n$($this.PermissionState) $($this.PermissionName)$columnClause ON $objectFullName TO [$($this.UserName)];"
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

    # MÃ©thode pour obtenir une description textuelle de la permission manquante
    [string] ToString() {
        $objectFullName = "[$($this.SchemaName)].[$($this.ObjectName)]"
        
        $columnClause = ""
        if (-not [string]::IsNullOrEmpty($this.ColumnName)) {
            $columnClause = " (colonne: $($this.ColumnName))"
        }
        
        return "Permission manquante: $($this.PermissionState) $($this.PermissionName) pour l'utilisateur [$($this.UserName)] sur l'objet $objectFullName$columnClause dans la base de donnÃ©es [$($this.DatabaseName)]"
    }
}

# Classe pour reprÃ©senter un ensemble de permissions manquantes
class SqlMissingPermissionsSet {
    [System.Collections.Generic.List[SqlServerMissingPermission]]$ServerPermissions
    [System.Collections.Generic.List[SqlDatabaseMissingPermission]]$DatabasePermissions
    [System.Collections.Generic.List[SqlObjectMissingPermission]]$ObjectPermissions
    [string]$ServerInstance
    [string]$ComparisonDate
    [string]$ModelName
    [int]$TotalCount
    [hashtable]$SeverityCounts

    # Constructeur par dÃ©faut
    SqlMissingPermissionsSet() {
        $this.ServerPermissions = New-Object System.Collections.Generic.List[SqlServerMissingPermission]
        $this.DatabasePermissions = New-Object System.Collections.Generic.List[SqlDatabaseMissingPermission]
        $this.ObjectPermissions = New-Object System.Collections.Generic.List[SqlObjectMissingPermission]
        $this.ComparisonDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $this.SeverityCounts = @{
            "Critique" = 0
            "Ã‰levÃ©e" = 0
            "Moyenne" = 0
            "Faible" = 0
        }
    }

    # Constructeur avec paramÃ¨tres
    SqlMissingPermissionsSet([string]$serverInstance, [string]$modelName) {
        $this.ServerPermissions = New-Object System.Collections.Generic.List[SqlServerMissingPermission]
        $this.DatabasePermissions = New-Object System.Collections.Generic.List[SqlDatabaseMissingPermission]
        $this.ObjectPermissions = New-Object System.Collections.Generic.List[SqlObjectMissingPermission]
        $this.ServerInstance = $serverInstance
        $this.ModelName = $modelName
        $this.ComparisonDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $this.SeverityCounts = @{
            "Critique" = 0
            "Ã‰levÃ©e" = 0
            "Moyenne" = 0
            "Faible" = 0
        }
    }

    # MÃ©thode pour ajouter une permission manquante au niveau serveur
    [void] AddServerPermission([SqlServerMissingPermission]$permission) {
        $this.ServerPermissions.Add($permission)
        $this.UpdateCounts($permission.Severity)
    }

    # MÃ©thode pour ajouter une permission manquante au niveau base de donnÃ©es
    [void] AddDatabasePermission([SqlDatabaseMissingPermission]$permission) {
        $this.DatabasePermissions.Add($permission)
        $this.UpdateCounts($permission.Severity)
    }

    # MÃ©thode pour ajouter une permission manquante au niveau objet
    [void] AddObjectPermission([SqlObjectMissingPermission]$permission) {
        $this.ObjectPermissions.Add($permission)
        $this.UpdateCounts($permission.Severity)
    }

    # MÃ©thode privÃ©e pour mettre Ã  jour les compteurs
    hidden [void] UpdateCounts([string]$severity) {
        if ($this.SeverityCounts.ContainsKey($severity)) {
            $this.SeverityCounts[$severity]++
        }
        $this.TotalCount = $this.ServerPermissions.Count + $this.DatabasePermissions.Count + $this.ObjectPermissions.Count
    }

    # MÃ©thode pour filtrer les permissions par sÃ©vÃ©ritÃ©
    [SqlMissingPermissionsSet] FilterBySeverity([string]$severity) {
        $result = [SqlMissingPermissionsSet]::new($this.ServerInstance, $this.ModelName)
        
        foreach ($perm in $this.ServerPermissions) {
            if ($perm.Severity -eq $severity) {
                $result.AddServerPermission($perm)
            }
        }
        
        foreach ($perm in $this.DatabasePermissions) {
            if ($perm.Severity -eq $severity) {
                $result.AddDatabasePermission($perm)
            }
        }
        
        foreach ($perm in $this.ObjectPermissions) {
            if ($perm.Severity -eq $severity) {
                $result.AddObjectPermission($perm)
            }
        }
        
        return $result
    }

    # MÃ©thode pour gÃ©nÃ©rer un script SQL de correction pour toutes les permissions manquantes
    [string] GenerateFixScript() {
        $script = "-- Script de correction des permissions manquantes`n"
        $script += "-- Instance: $($this.ServerInstance)`n"
        $script += "-- Date: $($this.ComparisonDate)`n"
        $script += "-- ModÃ¨le de rÃ©fÃ©rence: $($this.ModelName)`n`n"
        
        if ($this.ServerPermissions.Count -gt 0) {
            $script += "-- Permissions manquantes au niveau serveur`n"
            foreach ($perm in $this.ServerPermissions) {
                $script += $perm.GenerateFixScript() + "`n"
            }
            $script += "`n"
        }
        
        # Regrouper les permissions de base de donnÃ©es par base de donnÃ©es
        $dbGroups = $this.DatabasePermissions | Group-Object -Property DatabaseName
        
        foreach ($dbGroup in $dbGroups) {
            $script += "-- Permissions manquantes pour la base de donnÃ©es [$($dbGroup.Name)]`n"
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
            $script += "-- Permissions manquantes pour les objets de la base de donnÃ©es [$($objGroup.Name)]`n"
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

    # MÃ©thode pour obtenir un rÃ©sumÃ© des permissions manquantes
    [string] GetSummary() {
        $summary = "RÃ©sumÃ© des permissions manquantes pour l'instance $($this.ServerInstance)`n"
        $summary += "Comparaison avec le modÃ¨le: $($this.ModelName)`n"
        $summary += "Date: $($this.ComparisonDate)`n`n"
        
        $summary += "Nombre total de permissions manquantes: $($this.TotalCount)`n"
        $summary += "- Permissions serveur: $($this.ServerPermissions.Count)`n"
        $summary += "- Permissions base de donnÃ©es: $($this.DatabasePermissions.Count)`n"
        $summary += "- Permissions objet: $($this.ObjectPermissions.Count)`n`n"
        
        $summary += "RÃ©partition par sÃ©vÃ©ritÃ©:`n"
        $summary += "- Critique: $($this.SeverityCounts['Critique'])`n"
        $summary += "- Ã‰levÃ©e: $($this.SeverityCounts['Ã‰levÃ©e'])`n"
        $summary += "- Moyenne: $($this.SeverityCounts['Moyenne'])`n"
        $summary += "- Faible: $($this.SeverityCounts['Faible'])`n"
        
        return $summary
    }
}

# Fonction pour crÃ©er un nouvel ensemble de permissions manquantes
function New-SqlMissingPermissionsSet {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ServerInstance,
        
        [Parameter(Mandatory = $false)]
        [string]$ModelName = "DefaultModel"
    )
    
    return [SqlMissingPermissionsSet]::new($ServerInstance, $ModelName)
}

# Fonction pour crÃ©er une nouvelle permission manquante au niveau serveur
function New-SqlServerMissingPermission {
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
        [string]$ExpectedInModel,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Critique", "Ã‰levÃ©e", "Moyenne", "Faible")]
        [string]$Severity = "Moyenne"
    )
    
    return [SqlServerMissingPermission]::new($PermissionName, $LoginName, $PermissionState, $SecurableName, $ExpectedInModel, $Severity)
}

# Fonction pour crÃ©er une nouvelle permission manquante au niveau base de donnÃ©es
function New-SqlDatabaseMissingPermission {
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
        [string]$ExpectedInModel,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Critique", "Ã‰levÃ©e", "Moyenne", "Faible")]
        [string]$Severity = "Moyenne"
    )
    
    if ([string]::IsNullOrEmpty($SecurableName)) {
        $SecurableName = $DatabaseName
    }
    
    return [SqlDatabaseMissingPermission]::new($PermissionName, $DatabaseName, $UserName, $PermissionState, $SecurableType, $SecurableName, $ExpectedInModel, $Severity)
}

# Fonction pour crÃ©er une nouvelle permission manquante au niveau objet
function New-SqlObjectMissingPermission {
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
        [string]$ExpectedInModel,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Critique", "Ã‰levÃ©e", "Moyenne", "Faible")]
        [string]$Severity = "Moyenne"
    )
    
    return [SqlObjectMissingPermission]::new($PermissionName, $DatabaseName, $UserName, $PermissionState, $ObjectType, $SchemaName, $ObjectName, $ColumnName, $ExpectedInModel, $Severity)
}

# Exporter les fonctions
Export-ModuleMember -Function New-SqlMissingPermissionsSet, New-SqlServerMissingPermission, New-SqlDatabaseMissingPermission, New-SqlObjectMissingPermission
