#Requires -Version 5.1
<#
.SYNOPSIS
    Installe le module MCPClient.
.DESCRIPTION
    Ce script installe le module MCPClient dans le répertoire des modules PowerShell de l'utilisateur.
.EXAMPLE
    .\Install-MCPClient.ps1
    Installe le module MCPClient.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-18
#>
[CmdletBinding()]
param ()

# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console avec couleur
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
}

# Fonction principale
function Install-MCPClient {
    [CmdletBinding()]
    param ()
    
    try {
        # Chemin du module source
        $sourcePath = Join-Path -Path $PSScriptRoot -ChildPath "MCPClient.psm1"
        
        # Vérifier si le module source existe
        if (-not (Test-Path $sourcePath)) {
            Write-Log "Module source introuvable à $sourcePath" -Level "ERROR"
            return
        }
        
        # Chemin du répertoire des modules PowerShell de l'utilisateur
        $modulesPath = $env:PSModulePath -split ';' | Where-Object { $_ -like "*$env:USERNAME*" } | Select-Object -First 1
        
        # Si le répertoire des modules n'existe pas, utiliser le répertoire Documents\WindowsPowerShell\Modules
        if (-not $modulesPath) {
            $modulesPath = Join-Path -Path ([Environment]::GetFolderPath("MyDocuments")) -ChildPath "WindowsPowerShell\Modules"
            
            # Créer le répertoire s'il n'existe pas
            if (-not (Test-Path $modulesPath)) {
                New-Item -Path $modulesPath -ItemType Directory -Force | Out-Null
                Write-Log "Création du répertoire des modules PowerShell à $modulesPath" -Level "INFO"
            }
        }
        
        # Chemin du répertoire du module MCPClient
        $moduleDir = Join-Path -Path $modulesPath -ChildPath "MCPClient"
        
        # Créer le répertoire du module s'il n'existe pas
        if (-not (Test-Path $moduleDir)) {
            New-Item -Path $moduleDir -ItemType Directory -Force | Out-Null
            Write-Log "Création du répertoire du module MCPClient à $moduleDir" -Level "INFO"
        }
        
        # Chemin du fichier de module de destination
        $destPath = Join-Path -Path $moduleDir -ChildPath "MCPClient.psm1"
        
        # Copier le fichier de module
        Copy-Item -Path $sourcePath -Destination $destPath -Force
        Write-Log "Module MCPClient copié vers $destPath" -Level "SUCCESS"
        
        # Créer le fichier de manifeste du module
        $manifestPath = Join-Path -Path $moduleDir -ChildPath "MCPClient.psd1"
        
        # Créer le manifeste du module
        New-ModuleManifest -Path $manifestPath `
            -RootModule "MCPClient.psm1" `
            -ModuleVersion "1.0.0" `
            -Author "EMAIL_SENDER_1 Team" `
            -Description "Module PowerShell pour interagir avec un serveur MCP" `
            -PowerShellVersion "5.1" `
            -FunctionsToExport @("Initialize-MCPConnection", "Get-MCPTools", "Invoke-MCPTool", "Add-MCPNumbers", "ConvertTo-MCPProduct", "Get-MCPSystemInfo")
        
        Write-Log "Manifeste du module créé à $manifestPath" -Level "SUCCESS"
        
        # Importer le module pour vérifier qu'il fonctionne
        Import-Module -Name "MCPClient" -Force
        Write-Log "Module MCPClient importé avec succès" -Level "SUCCESS"
        
        # Afficher les commandes disponibles
        $commands = Get-Command -Module "MCPClient"
        Write-Log "Commandes disponibles dans le module MCPClient :" -Level "INFO"
        $commands | ForEach-Object { Write-Log "  - $($_.Name)" -Level "INFO" }
        
        Write-Log "Installation du module MCPClient terminée avec succès" -Level "SUCCESS"
        Write-Log "Vous pouvez maintenant utiliser le module MCPClient dans vos scripts PowerShell" -Level "INFO"
    }
    catch {
        Write-Log "Erreur lors de l'installation du module MCPClient : $($_.Exception.Message)" -Level "ERROR"
    }
}

# Exécuter la fonction principale
Install-MCPClient -Verbose
