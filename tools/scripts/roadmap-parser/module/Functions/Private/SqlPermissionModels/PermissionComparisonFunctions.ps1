# PermissionComparisonFunctions.ps1
# ImplÃ©mente les fonctions de comparaison ensembliste pour identifier les permissions absentes

<#
.SYNOPSIS
    ImplÃ©mente les fonctions de comparaison ensembliste pour identifier les permissions absentes.

.DESCRIPTION
    Ce fichier contient les fonctions de comparaison ensembliste utilisÃ©es pour comparer
    les permissions actuelles avec un modÃ¨le de rÃ©fÃ©rence et identifier les permissions
    qui sont absentes. Ces fonctions sont utilisÃ©es par les algorithmes de dÃ©tection
    d'Ã©carts de permissions.

.NOTES
    Version:        1.0
    Author:         RoadmapParser Team
    Creation Date:  2023-11-15
#>

# Importer le modÃ¨le de permissions manquantes
$missingPermissionModelPath = Join-Path -Path $PSScriptRoot -ChildPath "MissingPermissionModel.ps1"
. $missingPermissionModelPath

# Fonction pour comparer deux ensembles de permissions au niveau serveur
function Compare-SqlServerPermissionSets {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$ReferencePermissions,
        
        [Parameter(Mandatory = $true)]
        [PSObject[]]$CurrentPermissions,
        
        [Parameter(Mandatory = $false)]
        [string]$ServerInstance = "Unknown",
        
        [Parameter(Mandatory = $false)]
        [string]$ModelName = "DefaultModel",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$SeverityMap = @{
            "CONNECT SQL" = "Critique"
            "ALTER ANY LOGIN" = "Ã‰levÃ©e"
            "CONTROL SERVER" = "Ã‰levÃ©e"
            "VIEW SERVER STATE" = "Moyenne"
            "VIEW ANY DATABASE" = "Moyenne"
            "DEFAULT" = "Moyenne"
        }
    )
    
    # CrÃ©er un ensemble de permissions manquantes
    $missingPermissions = New-SqlMissingPermissionsSet -ServerInstance $ServerInstance -ModelName $ModelName
    
    # CrÃ©er un dictionnaire des permissions actuelles pour une recherche plus rapide
    $currentPermDict = @{}
    foreach ($perm in $CurrentPermissions) {
        $key = "$($perm.PermissionName)|$($perm.LoginName)|$($perm.PermissionState)"
        $currentPermDict[$key] = $perm
    }
    
    # Comparer les permissions de rÃ©fÃ©rence avec les permissions actuelles
    foreach ($refPerm in $ReferencePermissions) {
        $key = "$($refPerm.PermissionName)|$($refPerm.LoginName)|$($refPerm.PermissionState)"
        
        # Si la permission de rÃ©fÃ©rence n'existe pas dans les permissions actuelles, elle est manquante
        if (-not $currentPermDict.ContainsKey($key)) {
            # DÃ©terminer la sÃ©vÃ©ritÃ© de la permission manquante
            $severity = $SeverityMap["DEFAULT"]
            if ($SeverityMap.ContainsKey($refPerm.PermissionName)) {
                $severity = $SeverityMap[$refPerm.PermissionName]
            }
            
            # CrÃ©er une permission manquante
            $missingPerm = New-SqlServerMissingPermission `
                -PermissionName $refPerm.PermissionName `
                -LoginName $refPerm.LoginName `
                -PermissionState $refPerm.PermissionState `
                -SecurableName $ServerInstance `
                -ExpectedInModel $ModelName `
                -Severity $severity
            
            # Ajouter des informations supplÃ©mentaires si disponibles
            if ($refPerm.PSObject.Properties.Name -contains "Description") {
                $missingPerm.Impact = $refPerm.Description
            }
            
            if ($refPerm.PSObject.Properties.Name -contains "RecommendedAction") {
                $missingPerm.RecommendedAction = $refPerm.RecommendedAction
            } else {
                $missingPerm.RecommendedAction = "Accorder la permission $($refPerm.PermissionName) Ã  $($refPerm.LoginName)"
            }
            
            # Ajouter la permission manquante Ã  l'ensemble
            $missingPermissions.AddServerPermission($missingPerm)
        }
    }
    
    return $missingPermissions
}

# Fonction pour comparer deux ensembles de permissions au niveau base de donnÃ©es
function Compare-SqlDatabasePermissionSets {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$ReferencePermissions,
        
        [Parameter(Mandatory = $true)]
        [PSObject[]]$CurrentPermissions,
        
        [Parameter(Mandatory = $true)]
        [string]$DatabaseName,
        
        [Parameter(Mandatory = $false)]
        [string]$ServerInstance = "Unknown",
        
        [Parameter(Mandatory = $false)]
        [string]$ModelName = "DefaultModel",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$SeverityMap = @{
            "CONNECT" = "Critique"
            "CONTROL" = "Ã‰levÃ©e"
            "ALTER" = "Ã‰levÃ©e"
            "SELECT" = "Moyenne"
            "INSERT" = "Moyenne"
            "UPDATE" = "Moyenne"
            "DELETE" = "Moyenne"
            "EXECUTE" = "Moyenne"
            "DEFAULT" = "Moyenne"
        }
    )
    
    # CrÃ©er un ensemble de permissions manquantes
    $missingPermissions = New-SqlMissingPermissionsSet -ServerInstance $ServerInstance -ModelName $ModelName
    
    # CrÃ©er un dictionnaire des permissions actuelles pour une recherche plus rapide
    $currentPermDict = @{}
    foreach ($perm in $CurrentPermissions) {
        $key = "$($perm.PermissionName)|$($perm.UserName)|$($perm.PermissionState)|$($perm.SecurableType)|$($perm.SecurableName)"
        $currentPermDict[$key] = $perm
    }
    
    # Comparer les permissions de rÃ©fÃ©rence avec les permissions actuelles
    foreach ($refPerm in $ReferencePermissions) {
        $key = "$($refPerm.PermissionName)|$($refPerm.UserName)|$($refPerm.PermissionState)|$($refPerm.SecurableType)|$($refPerm.SecurableName)"
        
        # Si la permission de rÃ©fÃ©rence n'existe pas dans les permissions actuelles, elle est manquante
        if (-not $currentPermDict.ContainsKey($key)) {
            # DÃ©terminer la sÃ©vÃ©ritÃ© de la permission manquante
            $severity = $SeverityMap["DEFAULT"]
            if ($SeverityMap.ContainsKey($refPerm.PermissionName)) {
                $severity = $SeverityMap[$refPerm.PermissionName]
            }
            
            # CrÃ©er une permission manquante
            $missingPerm = New-SqlDatabaseMissingPermission `
                -PermissionName $refPerm.PermissionName `
                -DatabaseName $DatabaseName `
                -UserName $refPerm.UserName `
                -PermissionState $refPerm.PermissionState `
                -SecurableType $refPerm.SecurableType `
                -SecurableName $refPerm.SecurableName `
                -ExpectedInModel $ModelName `
                -Severity $severity
            
            # Ajouter des informations supplÃ©mentaires si disponibles
            if ($refPerm.PSObject.Properties.Name -contains "Description") {
                $missingPerm.Impact = $refPerm.Description
            }
            
            if ($refPerm.PSObject.Properties.Name -contains "RecommendedAction") {
                $missingPerm.RecommendedAction = $refPerm.RecommendedAction
            } else {
                $securableDesc = if ($refPerm.SecurableType -eq "DATABASE") { "la base de donnÃ©es $DatabaseName" } else { "le schÃ©ma $($refPerm.SecurableName)" }
                $missingPerm.RecommendedAction = "Accorder la permission $($refPerm.PermissionName) sur $securableDesc Ã  $($refPerm.UserName)"
            }
            
            # Ajouter la permission manquante Ã  l'ensemble
            $missingPermissions.AddDatabasePermission($missingPerm)
        }
    }
    
    return $missingPermissions
}

# Fonction pour comparer deux ensembles de permissions au niveau objet
function Compare-SqlObjectPermissionSets {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$ReferencePermissions,
        
        [Parameter(Mandatory = $true)]
        [PSObject[]]$CurrentPermissions,
        
        [Parameter(Mandatory = $true)]
        [string]$DatabaseName,
        
        [Parameter(Mandatory = $false)]
        [string]$ServerInstance = "Unknown",
        
        [Parameter(Mandatory = $false)]
        [string]$ModelName = "DefaultModel",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$SeverityMap = @{
            "EXECUTE" = "Critique"
            "SELECT" = "Moyenne"
            "INSERT" = "Moyenne"
            "UPDATE" = "Moyenne"
            "DELETE" = "Moyenne"
            "CONTROL" = "Ã‰levÃ©e"
            "ALTER" = "Ã‰levÃ©e"
            "REFERENCES" = "Faible"
            "DEFAULT" = "Moyenne"
        },
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ObjectTypeSeverityMap = @{
            "TABLE" = @{
                "SELECT" = "Moyenne"
                "INSERT" = "Moyenne"
                "UPDATE" = "Moyenne"
                "DELETE" = "Moyenne"
            }
            "PROCEDURE" = @{
                "EXECUTE" = "Critique"
            }
            "FUNCTION" = @{
                "EXECUTE" = "Critique"
            }
            "VIEW" = @{
                "SELECT" = "Moyenne"
            }
        }
    )
    
    # CrÃ©er un ensemble de permissions manquantes
    $missingPermissions = New-SqlMissingPermissionsSet -ServerInstance $ServerInstance -ModelName $ModelName
    
    # CrÃ©er un dictionnaire des permissions actuelles pour une recherche plus rapide
    $currentPermDict = @{}
    foreach ($perm in $CurrentPermissions) {
        $key = "$($perm.PermissionName)|$($perm.UserName)|$($perm.PermissionState)|$($perm.ObjectType)|$($perm.SchemaName)|$($perm.ObjectName)|$($perm.ColumnName)"
        $currentPermDict[$key] = $perm
    }
    
    # Comparer les permissions de rÃ©fÃ©rence avec les permissions actuelles
    foreach ($refPerm in $ReferencePermissions) {
        $key = "$($refPerm.PermissionName)|$($refPerm.UserName)|$($refPerm.PermissionState)|$($refPerm.ObjectType)|$($refPerm.SchemaName)|$($refPerm.ObjectName)|$($refPerm.ColumnName)"
        
        # Si la permission de rÃ©fÃ©rence n'existe pas dans les permissions actuelles, elle est manquante
        if (-not $currentPermDict.ContainsKey($key)) {
            # DÃ©terminer la sÃ©vÃ©ritÃ© de la permission manquante
            $severity = $SeverityMap["DEFAULT"]
            
            # VÃ©rifier si une sÃ©vÃ©ritÃ© spÃ©cifique est dÃ©finie pour cette combinaison de type d'objet et de permission
            if ($ObjectTypeSeverityMap.ContainsKey($refPerm.ObjectType) -and 
                $ObjectTypeSeverityMap[$refPerm.ObjectType].ContainsKey($refPerm.PermissionName)) {
                $severity = $ObjectTypeSeverityMap[$refPerm.ObjectType][$refPerm.PermissionName]
            }
            # Sinon, utiliser la sÃ©vÃ©ritÃ© gÃ©nÃ©rale pour cette permission
            elseif ($SeverityMap.ContainsKey($refPerm.PermissionName)) {
                $severity = $SeverityMap[$refPerm.PermissionName]
            }
            
            # CrÃ©er une permission manquante
            $missingPerm = New-SqlObjectMissingPermission `
                -PermissionName $refPerm.PermissionName `
                -DatabaseName $DatabaseName `
                -UserName $refPerm.UserName `
                -PermissionState $refPerm.PermissionState `
                -ObjectType $refPerm.ObjectType `
                -SchemaName $refPerm.SchemaName `
                -ObjectName $refPerm.ObjectName `
                -ColumnName $refPerm.ColumnName `
                -ExpectedInModel $ModelName `
                -Severity $severity
            
            # Ajouter des informations supplÃ©mentaires si disponibles
            if ($refPerm.PSObject.Properties.Name -contains "Description") {
                $missingPerm.Impact = $refPerm.Description
            }
            
            if ($refPerm.PSObject.Properties.Name -contains "RecommendedAction") {
                $missingPerm.RecommendedAction = $refPerm.RecommendedAction
            } else {
                $objectDesc = "[$($refPerm.SchemaName)].[$($refPerm.ObjectName)]"
                $columnDesc = if (-not [string]::IsNullOrEmpty($refPerm.ColumnName)) { " (colonne: $($refPerm.ColumnName))" } else { "" }
                $missingPerm.RecommendedAction = "Accorder la permission $($refPerm.PermissionName) sur l'objet $objectDesc$columnDesc Ã  $($refPerm.UserName)"
            }
            
            # Ajouter la permission manquante Ã  l'ensemble
            $missingPermissions.AddObjectPermission($missingPerm)
        }
    }
    
    return $missingPermissions
}

# Fonction principale pour comparer les permissions SQL Server avec un modÃ¨le de rÃ©fÃ©rence
function Compare-SqlPermissionsWithModel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$ReferenceModel,
        
        [Parameter(Mandatory = $true)]
        [PSObject]$CurrentPermissions,
        
        [Parameter(Mandatory = $false)]
        [string]$ServerInstance = "Unknown",
        
        [Parameter(Mandatory = $false)]
        [string[]]$ExcludeDatabases = @("master", "model", "msdb", "tempdb"),
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeServerLevel = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeDatabaseLevel = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeObjectLevel = $true,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ServerSeverityMap,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$DatabaseSeverityMap,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ObjectSeverityMap,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ObjectTypeSeverityMap
    )
    
    # CrÃ©er un ensemble de permissions manquantes
    $missingPermissions = New-SqlMissingPermissionsSet -ServerInstance $ServerInstance -ModelName $ReferenceModel.ModelName
    
    # Comparer les permissions au niveau serveur
    if ($IncludeServerLevel -and 
        $ReferenceModel.PSObject.Properties.Name -contains "ServerPermissions" -and 
        $CurrentPermissions.PSObject.Properties.Name -contains "ServerPermissions") {
        
        $serverParams = @{
            ReferencePermissions = $ReferenceModel.ServerPermissions
            CurrentPermissions = $CurrentPermissions.ServerPermissions
            ServerInstance = $ServerInstance
            ModelName = $ReferenceModel.ModelName
        }
        
        if ($PSBoundParameters.ContainsKey("ServerSeverityMap")) {
            $serverParams.SeverityMap = $ServerSeverityMap
        }
        
        $serverMissingPermissions = Compare-SqlServerPermissionSets @serverParams
        
        # Ajouter les permissions manquantes au niveau serveur Ã  l'ensemble global
        foreach ($perm in $serverMissingPermissions.ServerPermissions) {
            $missingPermissions.AddServerPermission($perm)
        }
    }
    
    # Comparer les permissions au niveau base de donnÃ©es
    if ($IncludeDatabaseLevel -and 
        $ReferenceModel.PSObject.Properties.Name -contains "DatabasePermissions" -and 
        $CurrentPermissions.PSObject.Properties.Name -contains "DatabasePermissions") {
        
        # Regrouper les permissions de rÃ©fÃ©rence par base de donnÃ©es
        $refDbGroups = $ReferenceModel.DatabasePermissions | Group-Object -Property DatabaseName
        
        # Regrouper les permissions actuelles par base de donnÃ©es
        $currentDbGroups = $CurrentPermissions.DatabasePermissions | Group-Object -Property DatabaseName
        
        # CrÃ©er un dictionnaire des permissions actuelles par base de donnÃ©es pour une recherche plus rapide
        $currentDbDict = @{}
        foreach ($dbGroup in $currentDbGroups) {
            $currentDbDict[$dbGroup.Name] = $dbGroup.Group
        }
        
        # Comparer les permissions pour chaque base de donnÃ©es dans le modÃ¨le de rÃ©fÃ©rence
        foreach ($dbGroup in $refDbGroups) {
            $dbName = $dbGroup.Name
            
            # Ignorer les bases de donnÃ©es exclues
            if ($ExcludeDatabases -contains $dbName) {
                continue
            }
            
            # Si la base de donnÃ©es existe dans les permissions actuelles
            if ($currentDbDict.ContainsKey($dbName)) {
                $dbParams = @{
                    ReferencePermissions = $dbGroup.Group
                    CurrentPermissions = $currentDbDict[$dbName]
                    DatabaseName = $dbName
                    ServerInstance = $ServerInstance
                    ModelName = $ReferenceModel.ModelName
                }
                
                if ($PSBoundParameters.ContainsKey("DatabaseSeverityMap")) {
                    $dbParams.SeverityMap = $DatabaseSeverityMap
                }
                
                $dbMissingPermissions = Compare-SqlDatabasePermissionSets @dbParams
                
                # Ajouter les permissions manquantes au niveau base de donnÃ©es Ã  l'ensemble global
                foreach ($perm in $dbMissingPermissions.DatabasePermissions) {
                    $missingPermissions.AddDatabasePermission($perm)
                }
            }
            # Si la base de donnÃ©es n'existe pas dans les permissions actuelles, toutes les permissions sont manquantes
            else {
                foreach ($refPerm in $dbGroup.Group) {
                    # DÃ©terminer la sÃ©vÃ©ritÃ© de la permission manquante
                    $severity = "Moyenne"
                    if ($PSBoundParameters.ContainsKey("DatabaseSeverityMap") -and 
                        $DatabaseSeverityMap.ContainsKey($refPerm.PermissionName)) {
                        $severity = $DatabaseSeverityMap[$refPerm.PermissionName]
                    }
                    
                    # CrÃ©er une permission manquante
                    $missingPerm = New-SqlDatabaseMissingPermission `
                        -PermissionName $refPerm.PermissionName `
                        -DatabaseName $dbName `
                        -UserName $refPerm.UserName `
                        -PermissionState $refPerm.PermissionState `
                        -SecurableType $refPerm.SecurableType `
                        -SecurableName $refPerm.SecurableName `
                        -ExpectedInModel $ReferenceModel.ModelName `
                        -Severity $severity
                    
                    # Ajouter des informations supplÃ©mentaires si disponibles
                    if ($refPerm.PSObject.Properties.Name -contains "Description") {
                        $missingPerm.Impact = $refPerm.Description
                    } else {
                        $missingPerm.Impact = "La base de donnÃ©es $dbName n'existe pas ou n'est pas accessible"
                    }
                    
                    if ($refPerm.PSObject.Properties.Name -contains "RecommendedAction") {
                        $missingPerm.RecommendedAction = $refPerm.RecommendedAction
                    } else {
                        $missingPerm.RecommendedAction = "CrÃ©er la base de donnÃ©es $dbName ou vÃ©rifier les permissions d'accÃ¨s"
                    }
                    
                    # Ajouter la permission manquante Ã  l'ensemble global
                    $missingPermissions.AddDatabasePermission($missingPerm)
                }
            }
        }
    }
    
    # Comparer les permissions au niveau objet
    if ($IncludeObjectLevel -and 
        $ReferenceModel.PSObject.Properties.Name -contains "ObjectPermissions" -and 
        $CurrentPermissions.PSObject.Properties.Name -contains "ObjectPermissions") {
        
        # Regrouper les permissions de rÃ©fÃ©rence par base de donnÃ©es
        $refObjDbGroups = $ReferenceModel.ObjectPermissions | Group-Object -Property DatabaseName
        
        # Regrouper les permissions actuelles par base de donnÃ©es
        $currentObjDbGroups = $CurrentPermissions.ObjectPermissions | Group-Object -Property DatabaseName
        
        # CrÃ©er un dictionnaire des permissions actuelles par base de donnÃ©es pour une recherche plus rapide
        $currentObjDbDict = @{}
        foreach ($dbGroup in $currentObjDbGroups) {
            $currentObjDbDict[$dbGroup.Name] = $dbGroup.Group
        }
        
        # Comparer les permissions pour chaque base de donnÃ©es dans le modÃ¨le de rÃ©fÃ©rence
        foreach ($dbGroup in $refObjDbGroups) {
            $dbName = $dbGroup.Name
            
            # Ignorer les bases de donnÃ©es exclues
            if ($ExcludeDatabases -contains $dbName) {
                continue
            }
            
            # Si la base de donnÃ©es existe dans les permissions actuelles
            if ($currentObjDbDict.ContainsKey($dbName)) {
                $objParams = @{
                    ReferencePermissions = $dbGroup.Group
                    CurrentPermissions = $currentObjDbDict[$dbName]
                    DatabaseName = $dbName
                    ServerInstance = $ServerInstance
                    ModelName = $ReferenceModel.ModelName
                }
                
                if ($PSBoundParameters.ContainsKey("ObjectSeverityMap")) {
                    $objParams.SeverityMap = $ObjectSeverityMap
                }
                
                if ($PSBoundParameters.ContainsKey("ObjectTypeSeverityMap")) {
                    $objParams.ObjectTypeSeverityMap = $ObjectTypeSeverityMap
                }
                
                $objMissingPermissions = Compare-SqlObjectPermissionSets @objParams
                
                # Ajouter les permissions manquantes au niveau objet Ã  l'ensemble global
                foreach ($perm in $objMissingPermissions.ObjectPermissions) {
                    $missingPermissions.AddObjectPermission($perm)
                }
            }
            # Si la base de donnÃ©es n'existe pas dans les permissions actuelles, toutes les permissions sont manquantes
            else {
                foreach ($refPerm in $dbGroup.Group) {
                    # DÃ©terminer la sÃ©vÃ©ritÃ© de la permission manquante
                    $severity = "Moyenne"
                    if ($PSBoundParameters.ContainsKey("ObjectSeverityMap") -and 
                        $ObjectSeverityMap.ContainsKey($refPerm.PermissionName)) {
                        $severity = $ObjectSeverityMap[$refPerm.PermissionName]
                    }
                    
                    # CrÃ©er une permission manquante
                    $missingPerm = New-SqlObjectMissingPermission `
                        -PermissionName $refPerm.PermissionName `
                        -DatabaseName $dbName `
                        -UserName $refPerm.UserName `
                        -PermissionState $refPerm.PermissionState `
                        -ObjectType $refPerm.ObjectType `
                        -SchemaName $refPerm.SchemaName `
                        -ObjectName $refPerm.ObjectName `
                        -ColumnName $refPerm.ColumnName `
                        -ExpectedInModel $ReferenceModel.ModelName `
                        -Severity $severity
                    
                    # Ajouter des informations supplÃ©mentaires si disponibles
                    if ($refPerm.PSObject.Properties.Name -contains "Description") {
                        $missingPerm.Impact = $refPerm.Description
                    } else {
                        $missingPerm.Impact = "La base de donnÃ©es $dbName n'existe pas ou n'est pas accessible"
                    }
                    
                    if ($refPerm.PSObject.Properties.Name -contains "RecommendedAction") {
                        $missingPerm.RecommendedAction = $refPerm.RecommendedAction
                    } else {
                        $missingPerm.RecommendedAction = "CrÃ©er la base de donnÃ©es $dbName ou vÃ©rifier les permissions d'accÃ¨s"
                    }
                    
                    # Ajouter la permission manquante Ã  l'ensemble global
                    $missingPermissions.AddObjectPermission($missingPerm)
                }
            }
        }
    }
    
    return $missingPermissions
}

# Exporter les fonctions
Export-ModuleMember -Function Compare-SqlServerPermissionSets, Compare-SqlDatabasePermissionSets, Compare-SqlObjectPermissionSets, Compare-SqlPermissionsWithModel
