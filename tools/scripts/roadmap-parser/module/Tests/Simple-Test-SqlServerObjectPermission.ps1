# Test simplifié pour la fonction Analyze-SqlServerPermission avec analyse au niveau objet

# Importer la fonction à tester
$scriptPath = "$PSScriptRoot\..\Functions\Public\Analyze-SqlServerPermission.ps1"
Write-Host "Chargement du script: $scriptPath" -ForegroundColor Green
. $scriptPath

# Définir la variable d'environnement pour le test
$env:PESTER_TEST_RUN = $true

# Créer un mock pour Invoke-Sqlcmd
function Invoke-Sqlcmd {
    param (
        [Parameter(Mandatory = $false)]
        [string]$ServerInstance,
        
        [Parameter(Mandatory = $false)]
        [string]$Query,
        
        [Parameter(Mandatory = $false)]
        [string]$Database,
        
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]$Credential,
        
        [Parameter(Mandatory = $false)]
        [string]$ErrorAction
    )
    
    # Retourner des données de test en fonction de la requête
    if ($Query -like "*sys.databases*") {
        return @(
            [PSCustomObject]@{
                name = "TestDB"
            }
        )
    }
    elseif ($Query -like "*sys.objects*") {
        return @(
            [PSCustomObject]@{
                SchemaName = "dbo"
                ObjectName = "TestTable"
                ObjectType = "USER_TABLE"
                CreateDate = (Get-Date)
                ModifyDate = (Get-Date)
                IsMsShipped = $false
            }
        )
    }
    else {
        return @(
            [PSCustomObject]@{
                GranteeName = "TestUser"
                GranteeType = "SQL_USER"
                ObjectName = "dbo.TestTable"
                ObjectType = "USER_TABLE"
                PermissionName = "SELECT"
                PermissionState = "GRANT"
            }
        )
    }
}

# Créer un mock pour Get-Module
function Get-Module {
    param (
        [Parameter(Mandatory = $false)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [switch]$ListAvailable
    )
    
    return $true
}

# Créer un mock pour Import-Module
function Import-Module {
    param (
        [Parameter(Mandatory = $false)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [string]$ErrorAction
    )
    
    # Ne rien faire
}

# Tester la fonction
Write-Host "Test de la fonction Analyze-SqlServerPermission avec analyse au niveau objet..." -ForegroundColor Cyan

try {
    # Appeler la fonction avec les paramètres
    $result = Analyze-SqlServerPermission -ServerInstance "TestServer" -IncludeDatabaseLevel $true -IncludeObjectLevel $true
    
    # Vérifier les résultats
    if ($result) {
        Write-Host "Test réussi! La fonction a retourné un résultat." -ForegroundColor Green
        
        # Afficher quelques informations sur le résultat
        Write-Host "ServerInstance: $($result.ServerInstance)" -ForegroundColor Cyan
        Write-Host "IncludeObjectLevel: $($result.IncludeObjectLevel)" -ForegroundColor Cyan
        Write-Host "Nombre d'objets de base de données: $($result.DatabaseObjects.Count)" -ForegroundColor Cyan
        Write-Host "Nombre de permissions au niveau objet: $($result.ObjectPermissions.Count)" -ForegroundColor Cyan
        Write-Host "Nombre d'anomalies au niveau objet: $($result.ObjectPermissionAnomalies.Count)" -ForegroundColor Cyan
    } else {
        Write-Host "Test échoué! La fonction n'a pas retourné de résultat." -ForegroundColor Red
    }
} catch {
    Write-Host "Erreur lors de l'exécution de la fonction: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
}

Write-Host "Test terminé." -ForegroundColor Cyan
