#Requires -Version 5.1
<#
.SYNOPSIS
    Connecteur pour PSScriptAnalyzer permettant d'analyser des scripts PowerShell.

.DESCRIPTION
    Ce script fournit une interface pour analyser des scripts PowerShell avec PSScriptAnalyzer
    et convertir les rÃ©sultats vers un format unifiÃ©. Il peut Ãªtre utilisÃ© comme un plugin
    pour le systÃ¨me d'analyse ou comme un script autonome.

.PARAMETER FilePath
    Chemin du fichier ou du rÃ©pertoire Ã  analyser.

.PARAMETER IncludeRule
    RÃ¨gles Ã  inclure dans l'analyse. Si non spÃ©cifiÃ©, toutes les rÃ¨gles sont incluses.

.PARAMETER ExcludeRule
    RÃ¨gles Ã  exclure de l'analyse.

.PARAMETER Severity
    SÃ©vÃ©ritÃ© des problÃ¨mes Ã  inclure dans l'analyse. Valeurs possibles: Error, Warning, Information, All.

.PARAMETER Recurse
    Analyser rÃ©cursivement les sous-rÃ©pertoires si FilePath est un rÃ©pertoire.

.PARAMETER OutputPath
    Chemin du fichier de sortie pour les rÃ©sultats. Si non spÃ©cifiÃ©, les rÃ©sultats sont affichÃ©s dans la console.

.PARAMETER RegisterAsPlugin
    Enregistrer ce connecteur comme un plugin dans le systÃ¨me d'analyse.

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
    
    # VÃ©rifier si PSScriptAnalyzer est disponible
    if (-not (Test-AnalysisTool -ToolName "PSScriptAnalyzer")) {
        Write-Error "PSScriptAnalyzer n'est pas disponible. Installez-le avec 'Install-Module -Name PSScriptAnalyzer'."
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
    
    # ExÃ©cuter l'analyse
    try {
        if (Test-Path -Path $FilePath -PathType Container) {
            # Analyser un rÃ©pertoire
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

# Enregistrer le plugin si demandÃ©
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
        
        # ExÃ©cuter l'analyse
        if (Test-Path -Path $FilePath -PathType Container) {
            # Analyser un rÃ©pertoire
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
    
    Write-Host "Plugin PSScriptAnalyzer enregistrÃ© avec succÃ¨s." -ForegroundColor Green
    return
}

# ExÃ©cuter l'analyse si un chemin est spÃ©cifiÃ©
if ($FilePath) {
    $results = Invoke-PSScriptAnalyzerAnalysis -FilePath $FilePath -IncludeRule $IncludeRule -ExcludeRule $ExcludeRule -Severity $Severity -Recurse:$Recurse
    
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
                
                if ($_.Suggestion) {
                    Write-Host "Suggestion: $($_.Suggestion)" -ForegroundColor "Green"
                }
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
    Write-Host "Exemple: .\Connect-PSScriptAnalyzer.ps1 -FilePath 'C:\Scripts\MyScript.ps1' -Severity Error, Warning" -ForegroundColor Yellow
}
