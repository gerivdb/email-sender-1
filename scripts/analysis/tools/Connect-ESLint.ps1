#Requires -Version 5.1
<#
.SYNOPSIS
    Connecteur pour ESLint permettant d'analyser des fichiers JavaScript/TypeScript.

.DESCRIPTION
    Ce script fournit une interface pour analyser des fichiers JavaScript, TypeScript et autres
    avec ESLint et convertir les résultats vers un format unifié. Il peut être utilisé comme
    un plugin pour le système d'analyse ou comme un script autonome.

.PARAMETER FilePath
    Chemin du fichier ou du répertoire à analyser.

.PARAMETER ConfigFile
    Chemin du fichier de configuration ESLint à utiliser. Si non spécifié, ESLint utilisera
    sa recherche automatique de configuration.

.PARAMETER Fix
    Corriger automatiquement les problèmes qui peuvent être corrigés.

.PARAMETER OutputPath
    Chemin du fichier de sortie pour les résultats. Si non spécifié, les résultats sont affichés dans la console.

.PARAMETER RegisterAsPlugin
    Enregistrer ce connecteur comme un plugin dans le système d'analyse.

.EXAMPLE
    .\Connect-ESLint.ps1 -FilePath "C:\Projects\MyProject\src" -ConfigFile "C:\Projects\MyProject\.eslintrc.json"

.EXAMPLE
    .\Connect-ESLint.ps1 -FilePath "C:\Projects\MyProject\src\app.js" -Fix -OutputPath "C:\Results\eslint-results.json"

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
    [switch]$Fix,
    
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

# Fonction d'analyse pour ESLint
function Invoke-ESLintAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigFile,
        
        [Parameter(Mandatory = $false)]
        [switch]$Fix
    )
    
    # Vérifier si ESLint est disponible
    if (-not (Test-AnalysisTool -ToolName "ESLint")) {
        Write-Error "ESLint n'est pas disponible. Installez-le avec 'npm install -g eslint' ou 'npm install eslint --save-dev'."
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
    
    if ($ConfigFile) {
        $params["ConfigFile"] = $ConfigFile
    }
    
    if ($Fix) {
        $params["Fix"] = $true
    }
    
    # Exécuter l'analyse
    try {
        if (Test-Path -Path $FilePath -PathType Container) {
            # Analyser un répertoire
            $results = @()
            $jsFiles = Get-ChildItem -Path $FilePath -Include "*.js", "*.jsx", "*.ts", "*.tsx", "*.vue" -Recurse -File
            
            foreach ($file in $jsFiles) {
                $fileParams = $params.Clone()
                $fileParams["FilePath"] = $file.FullName
                
                $fileResults = Invoke-ESLintTool @fileParams
                if ($null -ne $fileResults) {
                    $results += $fileResults
                }
            }
        }
        else {
            # Analyser un fichier
            $results = Invoke-ESLintTool @params
        }
        
        return $results
    }
    catch {
        Write-Error "Erreur lors de l'analyse avec ESLint: $_"
        return $null
    }
}

# Enregistrer le plugin si demandé
if ($RegisterAsPlugin) {
    $analyzeFunction = {
        param (
            [string]$FilePath,
            [string]$ConfigFile = "",
            [switch]$Fix
        )
        
        $params = @{
            FilePath = $FilePath
            ReturnUnifiedFormat = $true
        }
        
        if ($ConfigFile) {
            $params["ConfigFile"] = $ConfigFile
        }
        
        if ($Fix) {
            $params["Fix"] = $true
        }
        
        # Exécuter l'analyse
        if (Test-Path -Path $FilePath -PathType Container) {
            # Analyser un répertoire
            $results = @()
            $jsFiles = Get-ChildItem -Path $FilePath -Include "*.js", "*.jsx", "*.ts", "*.tsx", "*.vue" -Recurse -File
            
            foreach ($file in $jsFiles) {
                $fileParams = $params.Clone()
                $fileParams["FilePath"] = $file.FullName
                
                $fileResults = Invoke-ESLintTool @fileParams
                if ($null -ne $fileResults) {
                    $results += $fileResults
                }
            }
            
            return $results
        }
        else {
            # Analyser un fichier
            return Invoke-ESLintTool @params
        }
    }
    
    # Enregistrer le plugin
    Register-AnalysisPlugin -Name "ESLint" `
                           -Description "Analyse des fichiers JavaScript/TypeScript avec ESLint" `
                           -Version "1.0" `
                           -Author "EMAIL_SENDER_1" `
                           -Language "JavaScript" `
                           -AnalyzeFunction $analyzeFunction `
                           -Configuration @{
                               ConfigFile = ""
                               Fix = $false
                           } `
                           -Dependencies @("eslint") `
                           -Force
    
    Write-Host "Plugin ESLint enregistré avec succès." -ForegroundColor Green
    return
}

# Exécuter l'analyse si un chemin est spécifié
if ($FilePath) {
    $results = Invoke-ESLintAnalysis -FilePath $FilePath -ConfigFile $ConfigFile -Fix:$Fix
    
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
    Write-Host "Exemple: .\Connect-ESLint.ps1 -FilePath 'C:\Projects\MyProject\src' -ConfigFile 'C:\Projects\MyProject\.eslintrc.json'" -ForegroundColor Yellow
}
