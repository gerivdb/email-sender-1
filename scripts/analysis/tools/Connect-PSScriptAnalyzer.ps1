#Requires -Version 5.1
<#
.SYNOPSIS
    Connecteur pour PSScriptAnalyzer permettant d'analyser des scripts PowerShell.

.DESCRIPTION
    Ce script fournit une interface pour analyser des scripts PowerShell avec PSScriptAnalyzer
    et convertir les résultats vers un format unifié. Il peut être utilisé comme un plugin
    pour le système d'analyse ou comme un script autonome.

.PARAMETER FilePath
    Chemin du fichier ou du répertoire à analyser.

.PARAMETER IncludeRule
    Règles à inclure dans l'analyse. Si non spécifié, toutes les règles sont incluses.

.PARAMETER ExcludeRule
    Règles à exclure de l'analyse.

.PARAMETER Severity
    Sévérité des problèmes à inclure dans l'analyse. Valeurs possibles: Error, Warning, Information, All.

.PARAMETER Recurse
    Analyser récursivement les sous-répertoires si FilePath est un répertoire.

.PARAMETER OutputPath
    Chemin du fichier de sortie pour les résultats. Si non spécifié, les résultats sont affichés dans la console.

.PARAMETER RegisterAsPlugin
    Enregistrer ce connecteur comme un plugin dans le système d'analyse.

.EXAMPLE
    .\Connect-PSScriptAnalyzer.ps1 -FilePath "C:\Scripts\MyScript.ps1" -Severity Error, Warning

.EXAMPLE
    .\Connect-PSScriptAnalyzer.ps1 -FilePath "C:\Scripts" -Recurse -OutputPath "C:\Results\analysis.json"

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
    [string[]]$IncludeRule = @(),
    
    [Parameter(Mandatory = $false)]
    [string[]]$ExcludeRule = @(),
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Information", "All")]
    [string[]]$Severity = @("Error", "Warning", "Information"),
    
    [Parameter(Mandatory = $false)]
    [switch]$Recurse,
    
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

# Fonction d'analyse pour PSScriptAnalyzer
function Invoke-PSScriptAnalyzerAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string[]]$IncludeRule = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$ExcludeRule = @(),
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Error", "Warning", "Information", "All")]
        [string[]]$Severity = @("Error", "Warning", "Information"),
        
        [Parameter(Mandatory = $false)]
        [switch]$Recurse
    )
    
    # Vérifier si PSScriptAnalyzer est disponible
    if (-not (Test-AnalysisTool -ToolName "PSScriptAnalyzer")) {
        Write-Error "PSScriptAnalyzer n'est pas disponible. Installez-le avec 'Install-Module -Name PSScriptAnalyzer'."
        return $null
    }
    
    # Vérifier si le chemin existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "Le chemin '$FilePath' n'existe pas."
        return $null
    }
    
    # Préparer les paramètres pour l'analyse
    $params = @{
        FilePath = $FilePath
        ReturnUnifiedFormat = $true
    }
    
    if ($IncludeRule.Count -gt 0) {
        $params["IncludeRule"] = $IncludeRule
    }
    
    if ($ExcludeRule.Count -gt 0) {
        $params["ExcludeRule"] = $ExcludeRule
    }
    
    if ($Severity -notcontains "All") {
        $params["Severity"] = $Severity
    }
    
    if ($Recurse) {
        $params["Recurse"] = $true
    }
    
    # Exécuter l'analyse
    try {
        if (Test-Path -Path $FilePath -PathType Container) {
            # Analyser un répertoire
            $results = Invoke-DirectoryAnalysis -DirectoryPath $FilePath -Include "*.ps1", "*.psm1", "*.psd1" -Recurse:$Recurse -ToolParameters @{
                IncludeRule = $IncludeRule
                ExcludeRule = $ExcludeRule
                Severity = $Severity
            }
        }
        else {
            # Analyser un fichier
            $results = Invoke-PSScriptAnalyzerTool @params
        }
        
        return $results
    }
    catch {
        Write-Error "Erreur lors de l'analyse avec PSScriptAnalyzer: $_"
        return $null
    }
}

# Enregistrer le plugin si demandé
if ($RegisterAsPlugin) {
    $analyzeFunction = {
        param (
            [string]$FilePath,
            [string[]]$IncludeRule = @(),
            [string[]]$ExcludeRule = @(),
            [string[]]$Severity = @("Error", "Warning", "Information"),
            [switch]$Recurse
        )
        
        $params = @{
            FilePath = $FilePath
            ReturnUnifiedFormat = $true
        }
        
        if ($IncludeRule.Count -gt 0) {
            $params["IncludeRule"] = $IncludeRule
        }
        
        if ($ExcludeRule.Count -gt 0) {
            $params["ExcludeRule"] = $ExcludeRule
        }
        
        if ($Severity -notcontains "All") {
            $params["Severity"] = $Severity
        }
        
        if ($Recurse) {
            $params["Recurse"] = $true
        }
        
        # Exécuter l'analyse
        if (Test-Path -Path $FilePath -PathType Container) {
            # Analyser un répertoire
            return Invoke-DirectoryAnalysis -DirectoryPath $FilePath -Include "*.ps1", "*.psm1", "*.psd1" -Recurse:$Recurse -ToolParameters @{
                IncludeRule = $IncludeRule
                ExcludeRule = $ExcludeRule
                Severity = $Severity
            }
        }
        else {
            # Analyser un fichier
            return Invoke-PSScriptAnalyzerTool @params
        }
    }
    
    # Enregistrer le plugin
    Register-AnalysisPlugin -Name "PSScriptAnalyzer" `
                           -Description "Analyse des scripts PowerShell avec PSScriptAnalyzer" `
                           -Version "1.0" `
                           -Author "EMAIL_SENDER_1" `
                           -Language "PowerShell" `
                           -AnalyzeFunction $analyzeFunction `
                           -Configuration @{
                               IncludeRule = @()
                               ExcludeRule = @()
                               Severity = @("Error", "Warning", "Information")
                           } `
                           -Dependencies @("PSScriptAnalyzer") `
                           -Force
    
    Write-Host "Plugin PSScriptAnalyzer enregistré avec succès." -ForegroundColor Green
    return
}

# Exécuter l'analyse si un chemin est spécifié
if ($FilePath) {
    $results = Invoke-PSScriptAnalyzerAnalysis -FilePath $FilePath -IncludeRule $IncludeRule -ExcludeRule $ExcludeRule -Severity $Severity -Recurse:$Recurse
    
    # Afficher un résumé des résultats
    if ($null -ne $results) {
        $totalIssues = $results.Count
        $errorCount = ($results | Where-Object { $_.Severity -eq "Error" }).Count
        $warningCount = ($results | Where-Object { $_.Severity -eq "Warning" }).Count
        $infoCount = ($results | Where-Object { $_.Severity -eq "Information" }).Count
        
        Write-Host "Analyse terminée avec $totalIssues problèmes détectés:" -ForegroundColor Cyan
        Write-Host "  - Erreurs: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
        Write-Host "  - Avertissements: $warningCount" -ForegroundColor $(if ($warningCount -gt 0) { "Yellow" } else { "Green" })
        Write-Host "  - Informations: $infoCount" -ForegroundColor "Blue"
        
        # Afficher les résultats détaillés
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
                
                if ($_.Suggestion) {
                    Write-Host "Suggestion: $($_.Suggestion)" -ForegroundColor "Green"
                }
            }
        }
        
        # Enregistrer les résultats dans un fichier si demandé
        if ($OutputPath) {
            try {
                $results | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding utf8 -Force
                Write-Host "Résultats enregistrés dans '$OutputPath'." -ForegroundColor Green
            }
            catch {
                Write-Error "Erreur lors de l'enregistrement des résultats: $_"
            }
        }
    }
}
else {
    Write-Host "Aucun chemin spécifié. Utilisez le paramètre -FilePath pour analyser un fichier ou un répertoire." -ForegroundColor Yellow
    Write-Host "Exemple: .\Connect-PSScriptAnalyzer.ps1 -FilePath 'C:\Scripts\MyScript.ps1' -Severity Error, Warning" -ForegroundColor Yellow
}
