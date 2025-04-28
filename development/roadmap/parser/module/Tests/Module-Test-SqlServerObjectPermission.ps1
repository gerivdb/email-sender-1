﻿# Test simplifiÃ© pour la fonction Analyze-SqlServerPermission avec analyse au niveau objet

# Importer le module temporaire
$modulePath = "$PSScriptRoot\Test-Module.psm1"
Write-Host "Chargement du module: $modulePath" -ForegroundColor Green
Import-Module $modulePath -Force

# DÃ©finir la variable d'environnement pour le test
$env:PESTER_TEST_RUN = $true

# CrÃ©er un mock pour Invoke-Sqlcmd
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
    
    # Retourner des donnÃ©es de test en fonction de la requÃªte
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

# CrÃ©er un mock pour Get-Module
function Get-Module {
    param (
        [Parameter(Mandatory = $false)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [switch]$ListAvailable
    )
    
    return $true
}

# Tester la fonction
Write-Host "Test de la fonction Analyze-SqlServerPermission avec analyse au niveau objet..." -ForegroundColor Cyan

try {
    # Afficher les commandes disponibles
    Write-Host "Commandes disponibles:" -ForegroundColor Cyan
    Get-Command -Module (Get-Module | Where-Object { $_.Path -eq $modulePath }) | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }
    
    # Appeler la fonction avec les paramÃ¨tres
    $result = Analyze-SqlServerPermission -ServerInstance "TestServer" -IncludeDatabaseLevel $true -IncludeObjectLevel $true
    
    # VÃ©rifier les rÃ©sultats
    if ($result) {
        Write-Host "Test rÃ©ussi! La fonction a retournÃ© un rÃ©sultat." -ForegroundColor Green
        
        # Afficher quelques informations sur le rÃ©sultat
        Write-Host "ServerInstance: $($result.ServerInstance)" -ForegroundColor Cyan
        Write-Host "IncludeObjectLevel: $($result.IncludeObjectLevel)" -ForegroundColor Cyan
        Write-Host "Nombre d'objets de base de donnÃ©es: $($result.DatabaseObjects.Count)" -ForegroundColor Cyan
        Write-Host "Nombre de permissions au niveau objet: $($result.ObjectPermissions.Count)" -ForegroundColor Cyan
        Write-Host "Nombre d'anomalies au niveau objet: $($result.ObjectPermissionAnomalies.Count)" -ForegroundColor Cyan
    } else {
        Write-Host "Test Ã©chouÃ©! La fonction n'a pas retournÃ© de rÃ©sultat." -ForegroundColor Red
    }
} catch {
    Write-Host "Erreur lors de l'exÃ©cution de la fonction: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
}

# Nettoyer
Remove-Module -Name (Get-Module | Where-Object { $_.Path -eq $modulePath }).Name -Force -ErrorAction SilentlyContinue

Write-Host "Test terminÃ©." -ForegroundColor Cyan
