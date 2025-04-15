#Requires -Version 5.1
<#
.SYNOPSIS
    Enregistre un plugin d'analyse dans le système d'analyse.

.DESCRIPTION
    Ce script permet d'enregistrer un plugin d'analyse dans le système d'analyse.
    Les plugins peuvent être des scripts PowerShell, des modules ou des connecteurs
    vers des outils d'analyse tiers.

.PARAMETER Path
    Chemin du fichier de plugin à enregistrer. Si non spécifié, le script recherche
    automatiquement les plugins dans le répertoire plugins.

.PARAMETER Force
    Remplacer un plugin existant avec le même nom.

.PARAMETER ListPlugins
    Afficher la liste des plugins enregistrés.

.PARAMETER EnablePlugin
    Activer un plugin spécifique.

.PARAMETER DisablePlugin
    Désactiver un plugin spécifique.

.PARAMETER ExportPlugin
    Exporter un plugin vers un fichier.

.PARAMETER OutputDirectory
    Répertoire de sortie pour l'exportation du plugin.

.EXAMPLE
    .\Register-AnalysisPlugin.ps1 -Path "C:\Plugins\MyPlugin.ps1"

.EXAMPLE
    .\Register-AnalysisPlugin.ps1 -ListPlugins

.EXAMPLE
    .\Register-AnalysisPlugin.ps1 -DisablePlugin "ESLint"

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  15/04/2025
#>

[CmdletBinding(DefaultParameterSetName = "Register")]
param (
    [Parameter(Mandatory = $false, ParameterSetName = "Register")]
    [string]$Path,
    
    [Parameter(Mandatory = $false, ParameterSetName = "Register")]
    [switch]$Force,
    
    [Parameter(Mandatory = $true, ParameterSetName = "List")]
    [switch]$ListPlugins,
    
    [Parameter(Mandatory = $true, ParameterSetName = "Enable")]
    [string]$EnablePlugin,
    
    [Parameter(Mandatory = $true, ParameterSetName = "Disable")]
    [string]$DisablePlugin,
    
    [Parameter(Mandatory = $true, ParameterSetName = "Export")]
    [string]$ExportPlugin,
    
    [Parameter(Mandatory = $false, ParameterSetName = "Export")]
    [string]$OutputDirectory
)

# Importer le module de gestion des plugins
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "modules"
$pluginManagerPath = Join-Path -Path $modulesPath -ChildPath "AnalysisPluginManager.psm1"

if (Test-Path -Path $pluginManagerPath) {
    Import-Module -Name $pluginManagerPath -Force
}
else {
    throw "Module AnalysisPluginManager.psm1 introuvable."
}

# Créer le répertoire de plugins s'il n'existe pas
$pluginsDirectory = Join-Path -Path $PSScriptRoot -ChildPath "plugins"
if (-not (Test-Path -Path $pluginsDirectory -PathType Container)) {
    try {
        New-Item -Path $pluginsDirectory -ItemType Directory -Force | Out-Null
        Write-Verbose "Répertoire de plugins '$pluginsDirectory' créé."
    }
    catch {
        Write-Error "Impossible de créer le répertoire de plugins '$pluginsDirectory': $_"
    }
}

# Fonction pour afficher la liste des plugins
function Show-PluginList {
    [CmdletBinding()]
    param ()
    
    $plugins = Get-AnalysisPlugin
    
    if ($null -eq $plugins -or $plugins.Count -eq 0) {
        Write-Host "Aucun plugin enregistré." -ForegroundColor Yellow
        return
    }
    
    Write-Host "Plugins enregistrés:" -ForegroundColor Cyan
    
    $plugins | ForEach-Object {
        $statusColor = if ($_.Enabled) { "Green" } else { "Red" }
        $status = if ($_.Enabled) { "Activé" } else { "Désactivé" }
        
        Write-Host ""
        Write-Host "$($_.Name) ($($_.Version))" -ForegroundColor Cyan
        Write-Host "  Description: $($_.Description)" -ForegroundColor "White"
        Write-Host "  Auteur: $($_.Author)" -ForegroundColor "White"
        Write-Host "  Langage: $($_.Language)" -ForegroundColor "White"
        Write-Host "  Statut: $status" -ForegroundColor $statusColor
        
        if ($_.ExecutionCount -gt 0) {
            Write-Host "  Exécutions: $($_.ExecutionCount)" -ForegroundColor "White"
            Write-Host "  Temps moyen: $($_.AverageExecutionTime) ms" -ForegroundColor "White"
            Write-Host "  Dernière exécution: $($_.LastExecutionTime)" -ForegroundColor "White"
        }
        
        if ($_.Dependencies.Count -gt 0) {
            Write-Host "  Dépendances: $($_.Dependencies -join ", ")" -ForegroundColor "White"
        }
    }
}

# Traiter les différentes actions
switch ($PSCmdlet.ParameterSetName) {
    "Register" {
        if ($Path) {
            # Enregistrer un plugin spécifique
            if (-not (Test-Path -Path $Path -PathType Leaf)) {
                Write-Error "Le fichier '$Path' n'existe pas."
                return
            }
            
            $result = Import-AnalysisPlugin -Path $Path -Force:$Force
            
            if ($result) {
                Write-Host "Plugin enregistré avec succès: $Path" -ForegroundColor Green
            }
            else {
                Write-Error "Échec de l'enregistrement du plugin: $Path"
            }
        }
        else {
            # Rechercher et enregistrer automatiquement les plugins
            $pluginFiles = Find-AnalysisPlugins -Register -Force:$Force
            
            if ($pluginFiles.Count -gt 0) {
                Write-Host "$($pluginFiles.Count) plugins enregistrés avec succès:" -ForegroundColor Green
                $pluginFiles | ForEach-Object {
                    Write-Host "  - $_" -ForegroundColor "White"
                }
            }
            else {
                Write-Host "Aucun plugin trouvé à enregistrer." -ForegroundColor Yellow
                
                # Proposer d'enregistrer les connecteurs intégrés
                $toolsDirectory = Join-Path -Path $PSScriptRoot -ChildPath "tools"
                $connectors = Get-ChildItem -Path $toolsDirectory -Filter "Connect-*.ps1" -ErrorAction SilentlyContinue
                
                if ($connectors.Count -gt 0) {
                    Write-Host "`nConnecteurs intégrés disponibles:" -ForegroundColor Cyan
                    $connectors | ForEach-Object {
                        Write-Host "  - $($_.Name)" -ForegroundColor "White"
                    }
                    
                    $registerConnectors = Read-Host "Voulez-vous enregistrer ces connecteurs comme plugins? (O/N)"
                    
                    if ($registerConnectors -eq "O" -or $registerConnectors -eq "o") {
                        foreach ($connector in $connectors) {
                            Write-Host "Enregistrement de $($connector.Name)..." -ForegroundColor Cyan
                            & $connector.FullName -RegisterAsPlugin
                        }
                    }
                }
            }
        }
    }
    "List" {
        # Afficher la liste des plugins
        Show-PluginList
    }
    "Enable" {
        # Activer un plugin
        $result = Set-AnalysisPluginState -Name $EnablePlugin -Enabled $true
        
        if ($result) {
            Write-Host "Plugin '$EnablePlugin' activé." -ForegroundColor Green
        }
        else {
            Write-Error "Échec de l'activation du plugin '$EnablePlugin'."
        }
    }
    "Disable" {
        # Désactiver un plugin
        $result = Set-AnalysisPluginState -Name $DisablePlugin -Enabled $false
        
        if ($result) {
            Write-Host "Plugin '$DisablePlugin' désactivé." -ForegroundColor Green
        }
        else {
            Write-Error "Échec de la désactivation du plugin '$DisablePlugin'."
        }
    }
    "Export" {
        # Exporter un plugin
        if (-not $OutputDirectory) {
            $OutputDirectory = $pluginsDirectory
        }
        
        $result = Export-AnalysisPlugin -Name $ExportPlugin -OutputDirectory $OutputDirectory -Force
        
        if ($result) {
            Write-Host "Plugin '$ExportPlugin' exporté vers '$OutputDirectory'." -ForegroundColor Green
        }
        else {
            Write-Error "Échec de l'exportation du plugin '$ExportPlugin'."
        }
    }
}
