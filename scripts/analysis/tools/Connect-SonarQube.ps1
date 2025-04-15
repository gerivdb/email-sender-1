#Requires -Version 5.1
<#
.SYNOPSIS
    Connecteur pour SonarQube permettant d'analyser des projets avec SonarQube Scanner.

.DESCRIPTION
    Ce script fournit une interface pour analyser des projets avec SonarQube Scanner
    et récupérer les résultats depuis l'API SonarQube. Il peut être utilisé comme
    un plugin pour le système d'analyse ou comme un script autonome.

.PARAMETER ProjectKey
    Clé du projet SonarQube.

.PARAMETER ProjectName
    Nom du projet SonarQube.

.PARAMETER ProjectVersion
    Version du projet SonarQube.

.PARAMETER SourceDirectory
    Répertoire contenant les sources à analyser.

.PARAMETER SonarQubeUrl
    URL du serveur SonarQube. Par défaut: http://localhost:9000

.PARAMETER Token
    Token d'authentification pour l'API SonarQube.

.PARAMETER OutputPath
    Chemin du fichier de sortie pour les résultats. Si non spécifié, les résultats sont affichés dans la console.

.PARAMETER RegisterAsPlugin
    Enregistrer ce connecteur comme un plugin dans le système d'analyse.

.EXAMPLE
    .\Connect-SonarQube.ps1 -ProjectKey "my-project" -ProjectName "My Project" -ProjectVersion "1.0" -SourceDirectory "C:\Projects\MyProject"

.EXAMPLE
    .\Connect-SonarQube.ps1 -ProjectKey "my-project" -ProjectName "My Project" -ProjectVersion "1.0" -SourceDirectory "C:\Projects\MyProject" -SonarQubeUrl "http://sonarqube.example.com" -Token "your-token" -OutputPath "C:\Results\sonarqube-results.json"

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  15/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProjectKey,
    
    [Parameter(Mandatory = $false)]
    [string]$ProjectName,
    
    [Parameter(Mandatory = $false)]
    [string]$ProjectVersion,
    
    [Parameter(Mandatory = $false)]
    [string]$SourceDirectory,
    
    [Parameter(Mandatory = $false)]
    [string]$SonarQubeUrl = "http://localhost:9000",
    
    [Parameter(Mandatory = $false)]
    [string]$Token,
    
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

# Fonction d'analyse pour SonarQube
function Invoke-SonarQubeAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectKey,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectVersion,
        
        [Parameter(Mandatory = $true)]
        [string]$SourceDirectory,
        
        [Parameter(Mandatory = $false)]
        [string]$SonarQubeUrl = "http://localhost:9000",
        
        [Parameter(Mandatory = $false)]
        [string]$Token
    )
    
    # Vérifier si SonarQube Scanner est disponible
    if (-not (Test-AnalysisTool -ToolName "SonarQube")) {
        Write-Error "SonarQube Scanner n'est pas disponible. Installez-le et ajoutez-le au PATH."
        return $null
    }
    
    # Vérifier si le répertoire source existe
    if (-not (Test-Path -Path $SourceDirectory -PathType Container)) {
        Write-Error "Le répertoire source '$SourceDirectory' n'existe pas."
        return $null
    }
    
    # Préparer les paramètres pour l'analyse
    $params = @{
        ProjectKey = $ProjectKey
        ProjectName = $ProjectName
        ProjectVersion = $ProjectVersion
        SourceDirectory = $SourceDirectory
        SonarQubeUrl = $SonarQubeUrl
        ReturnUnifiedFormat = $true
    }
    
    if ($Token) {
        $params["Token"] = $Token
    }
    
    # Exécuter l'analyse
    try {
        $results = Invoke-SonarQubeTool @params
        return $results
    }
    catch {
        Write-Error "Erreur lors de l'analyse avec SonarQube: $_"
        return $null
    }
}

# Enregistrer le plugin si demandé
if ($RegisterAsPlugin) {
    $analyzeFunction = {
        param (
            [string]$FilePath,
            [string]$ProjectKey,
            [string]$ProjectName,
            [string]$ProjectVersion,
            [string]$SonarQubeUrl = "http://localhost:9000",
            [string]$Token = ""
        )
        
        # Utiliser le répertoire du fichier comme répertoire source si c'est un fichier
        $sourceDirectory = if (Test-Path -Path $FilePath -PathType Leaf) {
            Split-Path -Path $FilePath -Parent
        }
        else {
            $FilePath
        }
        
        # Générer un nom de projet par défaut si non spécifié
        if (-not $ProjectName) {
            $ProjectName = Split-Path -Path $sourceDirectory -Leaf
        }
        
        # Générer une clé de projet par défaut si non spécifiée
        if (-not $ProjectKey) {
            $ProjectKey = $ProjectName.ToLower() -replace '[^a-z0-9_-]', '-'
        }
        
        # Utiliser "1.0" comme version par défaut si non spécifiée
        if (-not $ProjectVersion) {
            $ProjectVersion = "1.0"
        }
        
        $params = @{
            ProjectKey = $ProjectKey
            ProjectName = $ProjectName
            ProjectVersion = $ProjectVersion
            SourceDirectory = $sourceDirectory
            SonarQubeUrl = $SonarQubeUrl
            ReturnUnifiedFormat = $true
        }
        
        if ($Token) {
            $params["Token"] = $Token
        }
        
        return Invoke-SonarQubeTool @params
    }
    
    # Enregistrer le plugin
    Register-AnalysisPlugin -Name "SonarQube" `
                           -Description "Analyse de projets avec SonarQube Scanner" `
                           -Version "1.0" `
                           -Author "EMAIL_SENDER_1" `
                           -Language "Generic" `
                           -AnalyzeFunction $analyzeFunction `
                           -Configuration @{
                               SonarQubeUrl = "http://localhost:9000"
                               Token = ""
                           } `
                           -Dependencies @("sonar-scanner") `
                           -Force
    
    Write-Host "Plugin SonarQube enregistré avec succès." -ForegroundColor Green
    return
}

# Exécuter l'analyse si les paramètres requis sont spécifiés
if ($ProjectKey -and $ProjectName -and $ProjectVersion -and $SourceDirectory) {
    $results = Invoke-SonarQubeAnalysis -ProjectKey $ProjectKey -ProjectName $ProjectName -ProjectVersion $ProjectVersion -SourceDirectory $SourceDirectory -SonarQubeUrl $SonarQubeUrl -Token $Token
    
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
                Write-Host "$($_.FileName) - Ligne $($_.Line)" -ForegroundColor Cyan
                Write-Host "[$($_.Severity)] $($_.RuleId): $($_.Message)" -ForegroundColor $severityColor
                Write-Host "Catégorie: $($_.Category)" -ForegroundColor "Gray"
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
    Write-Host "Paramètres requis manquants. Utilisez les paramètres -ProjectKey, -ProjectName, -ProjectVersion et -SourceDirectory pour exécuter une analyse." -ForegroundColor Yellow
    Write-Host "Exemple: .\Connect-SonarQube.ps1 -ProjectKey 'my-project' -ProjectName 'My Project' -ProjectVersion '1.0' -SourceDirectory 'C:\Projects\MyProject'" -ForegroundColor Yellow
}
