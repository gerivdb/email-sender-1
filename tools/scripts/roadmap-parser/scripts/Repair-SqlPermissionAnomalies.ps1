# Repair-SqlPermissionAnomalies.ps1
# Script pour corriger automatiquement certaines anomalies courantes de permissions SQL Server

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [string]$ServerInstance,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.PSCredential]$Credential,

    [Parameter(Mandatory = $false)]
    [string[]]$RuleIds,

    [Parameter(Mandatory = $false)]
    [string[]]$ExcludeDatabases = @("tempdb", "model"),

    [Parameter(Mandatory = $false)]
    [switch]$IncludeObjectLevel,

    [Parameter(Mandatory = $false)]
    [switch]$GenerateScript,

    [Parameter(Mandatory = $false)]
    [string]$ScriptOutputPath,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

begin {
    # Importer le module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\module" -Resolve
    Import-Module $modulePath -Force

    # Paramètres de connexion SQL Server
    $sqlParams = @{
        ServerInstance = $ServerInstance
        Database = "master"
    }

    if ($Credential) {
        $sqlParams.Credential = $Credential
    }

    # Définir les règles qui peuvent être corrigées automatiquement
    $repairableRules = @{
        # Règles au niveau serveur
        "SVR-001" = @{
            Name = "DisabledLoginWithPermissions"
            Description = "Supprime les permissions des logins désactivés"
            RepairFunction = {
                param($Anomaly, $Connection)
                
                $loginName = $Anomaly.LoginName
                $sql = @"
-- Supprimer les permissions explicites du login désactivé
DECLARE @sql NVARCHAR(MAX) = '';
SELECT @sql = @sql + 'REVOKE ' + permission_name + ' TO [' + grantee_principal_name + '];' + CHAR(13)
FROM sys.server_permissions sp
JOIN sys.server_principals grantee ON sp.grantee_principal_id = grantee.principal_id
WHERE grantee.name = '$loginName';

-- Supprimer l'appartenance aux rôles serveur
DECLARE @role_name sysname;
DECLARE role_cursor CURSOR FOR
SELECT r.name
FROM sys.server_role_members rm
JOIN sys.server_principals r ON rm.role_principal_id = r.principal_id
JOIN sys.server_principals m ON rm.member_principal_id = m.principal_id
WHERE m.name = '$loginName';

OPEN role_cursor;
FETCH NEXT FROM role_cursor INTO @role_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = @sql + 'ALTER SERVER ROLE [' + @role_name + '] DROP MEMBER [' + '$loginName' + '];' + CHAR(13);
    FETCH NEXT FROM role_cursor INTO @role_name;
END

CLOSE role_cursor;
DEALLOCATE role_cursor;

EXEC sp_executesql @sql;
"@
                return $sql
            }
        }
        "SVR-003" = @{
            Name = "PasswordPolicyExempt"
            Description = "Active la politique de mot de passe pour les logins SQL"
            RepairFunction = {
                param($Anomaly, $Connection)
                
                $loginName = $Anomaly.LoginName
                $sql = @"
-- Activer la politique de mot de passe pour le login SQL
ALTER LOGIN [$loginName] WITH CHECK_POLICY = ON, CHECK_EXPIRATION = ON;
"@
                return $sql
            }
        }
        "SVR-004" = @{
            Name = "LockedAccount"
            Description = "Déverrouille les comptes verrouillés"
            RepairFunction = {
                param($Anomaly, $Connection)
                
                $loginName = $Anomaly.LoginName
                $sql = @"
-- Déverrouiller le compte
ALTER LOGIN [$loginName] WITH UNLOCK;
"@
                return $sql
            }
        }
        "SVR-009" = @{
            Name = "InactiveAccounts"
            Description = "Désactive les comptes inactifs"
            RepairFunction = {
                param($Anomaly, $Connection)
                
                $loginName = $Anomaly.LoginName
                $sql = @"
-- Désactiver le compte inactif
ALTER LOGIN [$loginName] DISABLE;
"@
                return $sql
            }
        }
        
        # Règles au niveau base de données
        "DB-001" = @{
            Name = "OrphanedUser"
            Description = "Supprime les utilisateurs orphelins"
            RepairFunction = {
                param($Anomaly, $Connection)
                
                $databaseName = $Anomaly.DatabaseName
                $userName = $Anomaly.UserName
                $sql = @"
USE [$databaseName];

-- Supprimer l'utilisateur orphelin
DROP USER [$userName];
"@
                return $sql
            }
        }
        "DB-002" = @{
            Name = "DisabledLoginWithDatabasePermissions"
            Description = "Supprime les permissions des utilisateurs associés à des logins désactivés"
            RepairFunction = {
                param($Anomaly, $Connection)
                
                $databaseName = $Anomaly.DatabaseName
                $userName = $Anomaly.UserName
                $sql = @"
USE [$databaseName];

-- Supprimer les permissions explicites de l'utilisateur
DECLARE @sql NVARCHAR(MAX) = '';
SELECT @sql = @sql + 'REVOKE ' + permission_name + ' ON ' + 
    CASE WHEN class_desc = 'DATABASE' THEN 'DATABASE::[$databaseName]' 
         ELSE COALESCE(OBJECT_SCHEMA_NAME(major_id) + '.' + OBJECT_NAME(major_id), 'SCHEMA::' + SCHEMA_NAME(major_id), 'DATABASE::[$databaseName]') 
    END + 
    ' FROM [' + grantee_principal_name + '];' + CHAR(13)
FROM sys.database_permissions dp
JOIN sys.database_principals grantee ON dp.grantee_principal_id = grantee.principal_id
WHERE grantee.name = '$userName';

-- Supprimer l'appartenance aux rôles de base de données
DECLARE @role_name sysname;
DECLARE role_cursor CURSOR FOR
SELECT r.name
FROM sys.database_role_members rm
JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
JOIN sys.database_principals m ON rm.member_principal_id = m.principal_id
WHERE m.name = '$userName';

OPEN role_cursor;
FETCH NEXT FROM role_cursor INTO @role_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = @sql + 'ALTER ROLE [' + @role_name + '] DROP MEMBER [' + '$userName' + '];' + CHAR(13);
    FETCH NEXT FROM role_cursor INTO @role_name;
END

CLOSE role_cursor;
DEALLOCATE role_cursor;

EXEC sp_executesql @sql;
"@
                return $sql
            }
        }
        "DB-005" = @{
            Name = "GuestUserPermissions"
            Description = "Révoque les permissions explicites accordées à l'utilisateur guest"
            RepairFunction = {
                param($Anomaly, $Connection)
                
                $databaseName = $Anomaly.DatabaseName
                $sql = @"
USE [$databaseName];

-- Révoquer les permissions explicites de l'utilisateur guest
DECLARE @sql NVARCHAR(MAX) = '';
SELECT @sql = @sql + 'REVOKE ' + permission_name + ' ON ' + 
    CASE WHEN class_desc = 'DATABASE' THEN 'DATABASE::[$databaseName]' 
         ELSE COALESCE(OBJECT_SCHEMA_NAME(major_id) + '.' + OBJECT_NAME(major_id), 'SCHEMA::' + SCHEMA_NAME(major_id), 'DATABASE::[$databaseName]') 
    END + 
    ' FROM [guest];' + CHAR(13)
FROM sys.database_permissions dp
JOIN sys.database_principals grantee ON dp.grantee_principal_id = grantee.principal_id
WHERE grantee.name = 'guest';

EXEC sp_executesql @sql;
"@
                return $sql
            }
        }
        
        # Règles au niveau objet
        "OBJ-002" = @{
            Name = "GuestUserWithObjectPermissions"
            Description = "Révoque les permissions de l'utilisateur guest sur des objets"
            RepairFunction = {
                param($Anomaly, $Connection)
                
                $databaseName = $Anomaly.DatabaseName
                $sql = @"
USE [$databaseName];

-- Révoquer les permissions de l'utilisateur guest sur des objets
DECLARE @sql NVARCHAR(MAX) = '';
SELECT @sql = @sql + 'REVOKE ' + permission_name + ' ON ' + 
    COALESCE(OBJECT_SCHEMA_NAME(major_id) + '.' + OBJECT_NAME(major_id), 'SCHEMA::' + SCHEMA_NAME(major_id)) + 
    ' FROM [guest];' + CHAR(13)
FROM sys.database_permissions dp
JOIN sys.database_principals grantee ON dp.grantee_principal_id = grantee.principal_id
WHERE grantee.name = 'guest'
AND class_desc IN ('OBJECT_OR_COLUMN', 'SCHEMA');

EXEC sp_executesql @sql;
"@
                return $sql
            }
        }
    }

    # Fonction pour exécuter une requête SQL
    function Invoke-SqlQuery {
        param (
            [Parameter(Mandatory = $true)]
            [string]$ServerInstance,

            [Parameter(Mandatory = $false)]
            [System.Management.Automation.PSCredential]$Credential,

            [Parameter(Mandatory = $true)]
            [string]$Database,

            [Parameter(Mandatory = $true)]
            [string]$Query
        )

        $connectionString = "Server=$ServerInstance;Database=$Database;Integrated Security=True;"
        if ($Credential) {
            $connectionString = "Server=$ServerInstance;Database=$Database;User Id=$($Credential.UserName);Password=$($Credential.GetNetworkCredential().Password);"
        }

        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = $connectionString

        $command = New-Object System.Data.SqlClient.SqlCommand
        $command.Connection = $connection
        $command.CommandText = $Query

        try {
            $connection.Open()
            $command.ExecuteNonQuery() | Out-Null
            $connection.Close()
            return $true
        }
        catch {
            if ($connection.State -eq [System.Data.ConnectionState]::Open) {
                $connection.Close()
            }
            Write-Error "Erreur lors de l'exécution de la requête: $_"
            return $false
        }
    }
}

process {
    try {
        Write-Verbose "Recherche des anomalies de permissions SQL Server pour l'instance: $ServerInstance"

        # Analyser les permissions SQL Server
        $analyzeParams = $sqlParams.Clone()
        $analyzeParams.IncludeObjectLevel = $IncludeObjectLevel
        $analyzeParams.ExcludeDatabases = $ExcludeDatabases
        $analyzeParams.OutputFormat = "JSON"
        
        if ($RuleIds) {
            $analyzeParams.RuleIds = $RuleIds
        }
        else {
            # Utiliser uniquement les règles qui peuvent être corrigées automatiquement
            $analyzeParams.RuleIds = $repairableRules.Keys
        }

        Write-Verbose "Exécution de l'analyse avec les règles: $($analyzeParams.RuleIds -join ', ')"
        $result = Analyze-SqlServerPermission @analyzeParams

        Write-Verbose "Analyse terminée. Nombre total d'anomalies détectées: $($result.TotalAnomalies)"

        # Filtrer les anomalies qui peuvent être corrigées automatiquement
        $repairableAnomalies = @()
        
        foreach ($anomaly in $result.ServerAnomalies) {
            if ($repairableRules.ContainsKey($anomaly.RuleId)) {
                $repairableAnomalies += $anomaly
            }
        }
        
        foreach ($anomaly in $result.DatabaseAnomalies) {
            if ($repairableRules.ContainsKey($anomaly.RuleId)) {
                $repairableAnomalies += $anomaly
            }
        }
        
        foreach ($anomaly in $result.ObjectAnomalies) {
            if ($repairableRules.ContainsKey($anomaly.RuleId)) {
                $repairableAnomalies += $anomaly
            }
        }

        Write-Verbose "Nombre d'anomalies réparables: $($repairableAnomalies.Count)"

        if ($repairableAnomalies.Count -eq 0) {
            Write-Host "Aucune anomalie réparable détectée." -ForegroundColor Green
            return
        }

        # Générer les scripts de correction
        $repairScripts = @()
        
        foreach ($anomaly in $repairableAnomalies) {
            $rule = $repairableRules[$anomaly.RuleId]
            $repairScript = & $rule.RepairFunction $anomaly $sqlParams.ServerInstance
            
            $repairScripts += [PSCustomObject]@{
                RuleId = $anomaly.RuleId
                RuleName = $rule.Name
                Description = $rule.Description
                Anomaly = $anomaly
                Script = $repairScript
            }
        }

        # Générer un script SQL combiné si demandé
        if ($GenerateScript) {
            $combinedScript = @"
-- Script de correction des anomalies de permissions SQL Server
-- Instance: $ServerInstance
-- Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
-- Nombre d'anomalies: $($repairableAnomalies.Count)

"@

            foreach ($script in $repairScripts) {
                $combinedScript += @"
-- =============================================
-- Correction de l'anomalie: $($script.RuleId) - $($script.RuleName)
-- Description: $($script.Description)
-- =============================================
$($script.Script)

"@
            }

            if ($ScriptOutputPath) {
                $combinedScript | Out-File -FilePath $ScriptOutputPath -Encoding UTF8
                Write-Host "Script de correction généré: $ScriptOutputPath" -ForegroundColor Green
            }
            else {
                Write-Host "Script de correction:" -ForegroundColor Green
                Write-Host $combinedScript
            }
        }
        else {
            # Exécuter les corrections
            $correctedCount = 0
            $failedCount = 0
            
            foreach ($script in $repairScripts) {
                $anomaly = $script.Anomaly
                $database = "master"
                
                if ($anomaly.PSObject.Properties.Name -contains "DatabaseName") {
                    $database = $anomaly.DatabaseName
                }
                
                if ($PSCmdlet.ShouldProcess("$ServerInstance - $database", "Corriger l'anomalie $($script.RuleId) - $($script.RuleName)")) {
                    Write-Verbose "Correction de l'anomalie $($script.RuleId) - $($script.RuleName)"
                    
                    $success = Invoke-SqlQuery -ServerInstance $ServerInstance -Credential $Credential -Database $database -Query $script.Script
                    
                    if ($success) {
                        Write-Verbose "Anomalie corrigée avec succès."
                        $correctedCount++
                    }
                    else {
                        Write-Warning "Échec de la correction de l'anomalie."
                        $failedCount++
                    }
                }
            }
            
            Write-Host "Correction terminée." -ForegroundColor Green
            Write-Host "Anomalies corrigées: $correctedCount" -ForegroundColor Green
            Write-Host "Échecs de correction: $failedCount" -ForegroundColor $(if ($failedCount -gt 0) { "Red" } else { "Green" })
        }
    }
    catch {
        Write-Error "Erreur lors de la correction des anomalies: $_"
    }
}
