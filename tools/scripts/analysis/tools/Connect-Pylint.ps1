#Requires -Version 5.1
<#
.SYNOPSIS
    Connecteur pour Pylint permettant d'analyser des fichiers Python.

.DESCRIPTION
    Ce script fournit une interface pour analyser des fichiers Python avec Pylint
    et convertir les rÃ©sultats vers un format unifiÃ©. Il peut Ãªtre utilisÃ© comme
    un plugin pour le systÃ¨me d'analyse ou comme un script autonome.

.PARAMETER FilePath
    Chemin du fichier ou du rÃ©pertoire Ã  analyser.

.PARAMETER ConfigFile
    Chemin du fichier de configuration Pylint Ã  utiliser. Si non spÃ©cifiÃ©, Pylint
    utilisera sa recherche automatique de configuration.

.PARAMETER DisableRules
    RÃ¨gles Ã  dÃ©sactiver lors de l'analyse.

.PARAMETER EnableRules
    RÃ¨gles Ã  activer lors de l'analyse.

.PARAMETER OutputPath
    Chemin du fichier de sortie pour les rÃ©sultats. Si non spÃ©cifiÃ©, les rÃ©sultats sont affichÃ©s dans la console.

.PARAMETER RegisterAsPlugin
    Enregistrer ce connecteur comme un plugin dans le systÃ¨me d'analyse.

.EXAMPLE
    .\Connect-Pylint.ps1 -FilePath "C:\Projects\MyProject\src\script.py"

.EXAMPLE
    .\Connect-Pylint.ps1 -FilePath "C:\Projects\MyProject\src" -ConfigFile "C:\Projects\MyProject\.pylintrc" -OutputPath "C:\Results\pylint-results.json"

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  15/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath,
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigFile,
    
    [Parameter(Mandatory = $false)]
    [string[]]$DisableRules = @(),
    
    [Parameter(Mandatory = $false)]
    [string[]]$EnableRules = @(),
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$RegisterAsPlugin
)

# Importer les modules requis
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
$analysisToolsPath = Join-Path -Path $modulesPath -ChildPath "AnalysisTools.psm1"
$pluginManagerPath = Join-Path -Path $modulesPath -ChildPath "AnalysisPluginManager.psm1"

if (Test-Path -Path $analysisToolsPath) {
    Import-Module -Name $analysisToolsPath -Force
}
else {
    throw "Module AnalysisTools.psm1 introuvable."
}

if ($RegisterAsPlugin -and (Test-Path -Path $pluginManagerPath)) {
    Import-Module -Name $pluginManagerPath -Force
}

# Fonction d'analyse pour Pylint
function Invoke-PylintAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigFile,
        
        [Parameter(Mandatory = $false)]
        [string[]]$DisableRules = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$EnableRules = @()
    )
    
    # VÃ©rifier si Pylint est disponible
    if (-not (Test-AnalysisTool -ToolName "Pylint")) {
        Write-Error "Pylint n'est pas disponible. Installez-le avec 'pip install pylint'."
        return $null
    }
    
    # VÃ©rifier si le chemin existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "Le chemin '$FilePath' n'existe pas."
        return $null
    }
    
    # PrÃ©parer les paramÃ¨tres pour l'analyse
    $params = @{
        FilePath = $FilePath
        ReturnUnifiedFormat = $true
    }
    
    if ($ConfigFile) {
        $params["ConfigFile"] = $ConfigFile
    }
    
    if ($DisableRules.Count -gt 0) {
        $params["DisableRules"] = $DisableRules
    }
    
    if ($EnableRules.Count -gt 0) {
        $params["EnableRules"] = $EnableRules
    }
    
    # ExÃ©cuter l'analyse
    try {
        if (Test-Path -Path $FilePath -PathType Container) {
            # Analyser un rÃ©pertoire
            $results = @()
            $pyFiles = Get-ChildItem -Path $FilePath -Include "*.py" -Recurse -File
            
            foreach ($file in $pyFiles) {
                $fileParams = $params.Clone()
                $fileParams["FilePath"] = $file.FullName
                
                $fileResults = Invoke-PylintTool @fileParams
                if ($null -ne $fileResults) {
                    $results += $fileResults
                }
            }
        }
        else {
            # Analyser un fichier
            $results = Invoke-PylintTool @params
        }
        
        return $results
    }
    catch {
        Write-Error "Erreur lors de l'analyse avec Pylint: $_"
        return $null
    }
}

# Enregistrer le plugin si demandÃ©
if ($RegisterAsPlugin) {
    $analyzeFunction = {
        param (
            [string]$FilePath,
            [string]$ConfigFile = "",
            [string[]]$DisableRules = @(),
            [string[]]$EnableRules = @()
        )
        
        $params = @{
            FilePath = $FilePath
            ReturnUnifiedFormat = $true
        }
        
        if ($ConfigFile) {
            $params["ConfigFile"] = $ConfigFile
        }
        
        if ($DisableRules.Count -gt 0) {
            $params["DisableRules"] = $DisableRules
        }
        
        if ($EnableRules.Count -gt 0) {
            $params["EnableRules"] = $EnableRules
        }
        
        # ExÃ©cuter l'analyse
        if (Test-Path -Path $FilePath -PathType Container) {
            # Analyser un rÃ©pertoire
            $results = @()
            $pyFiles = Get-ChildItem -Path $FilePath -Include "*.py" -Recurse -File
            
            foreach ($file in $pyFiles) {
                $fileParams = $params.Clone()
                $fileParams["FilePath"] = $file.FullName
                
                $fileResults = Invoke-PylintTool @fileParams
                if ($null -ne $fileResults) {
                    $results += $fileResults
                }
            }
            
            return $results
        }
        else {
            # Analyser un fichier
            return Invoke-PylintTool @params
        }
    }
    
    # Enregistrer le plugin
    Register-AnalysisPlugin -Name "Pylint" `
                           -Description "Analyse des fichiers Python avec Pylint" `
                           -Version "1.0" `
                           -Author "EMAIL_SENDER_1" `
                           -Language "Python" `
                           -AnalyzeFunction $analyzeFunction `
                           -Configuration @{
                               ConfigFile = ""
                               DisableRules = @()
                               EnableRules = @()
                           } `
                           -Dependencies @("pylint") `
                           -Force
    
    Write-Host "Plugin Pylint enregistrÃ© avec succÃ¨s." -ForegroundColor Green
    return
}

# ExÃ©cuter l'analyse si un chemin est spÃ©cifiÃ©
if ($FilePath) {
    $results = Invoke-PylintAnalysis -FilePath $FilePath -ConfigFile $ConfigFile -DisableRules $DisableRules -EnableRules $EnableRules
    
    # Afficher un rÃ©sumÃ© des rÃ©sultats
    if ($null -ne $results) {
        $totalIssues = $results.Count
        $errorCount = ($results | Where-Object { $_.Severity -eq "Error" }).Count
        $warningCount = ($results | Where-Object { $_.Severity -eq "Warning" }).Count
        $infoCount = ($results | Where-Object { $_.Severity -eq "Information" }).Count
        
        Write-Host "Analyse terminÃ©e avec $totalIssues problÃ¨mes dÃ©tectÃ©s:" -ForegroundColor Cyan
        Write-Host "  - Erreurs: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
        Write-Host "  - Avertissements: $warningCount" -ForegroundColor $(if ($warningCount -gt 0) { "Yellow" } else { "Green" })
        Write-Host "  - Informations: $infoCount" -ForegroundColor "Blue"
        
        # Afficher les rÃ©sultats dÃ©taillÃ©s
        if ($totalIssues -gt 0) {
            $results | ForEach-Object {
                $severityColor = switch ($_.Severity) {
                    "Error" { "Red" }
                    "Warning" { "Yellow" }
                    "Information" { "Blue" }
                    default { "White" }
                }
                
                Write-Host ""
                Write-Host "$($_.FileName) - Ligne $($_.Line), Colonne $($_.Column)" -ForegroundColor Cyan
                Write-Host "[$($_.Severity)] $($_.RuleId): $($_.Message)" -ForegroundColor $severityColor
                Write-Host "CatÃ©gorie: $($_.Category)" -ForegroundColor "Gray"
            }
        }
        
        # Enregistrer les rÃ©sultats dans un fichier si demandÃ©
        if ($OutputPath) {
            try {
                $results | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding utf8 -Force
                Write-Host "RÃ©sultats enregistrÃ©s dans '$OutputPath'." -ForegroundColor Green
            }
            catch {
                Write-Error "Erreur lors de l'enregistrement des rÃ©sultats: $_"
            }
        }
    }
}
else {
    Write-Host "Aucun chemin spÃ©cifiÃ©. Utilisez le paramÃ¨tre -FilePath pour analyser un fichier ou un rÃ©pertoire." -ForegroundColor Yellow
    Write-Host "Exemple: .\Connect-Pylint.ps1 -FilePath 'C:\Projects\MyProject\src\script.py'" -ForegroundColor Yellow
}
