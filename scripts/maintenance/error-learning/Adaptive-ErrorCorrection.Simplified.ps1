<#
.SYNOPSIS
    Version simplifiée du script pour l'apprentissage adaptatif des corrections d'erreurs PowerShell.
.DESCRIPTION
    Ce script utilise l'apprentissage adaptatif pour améliorer les corrections d'erreurs
    en analysant les erreurs passées et en générant des modèles de correction.
.PARAMETER TrainingMode
    Si spécifié, exécute le script en mode d'apprentissage pour générer un modèle de correction.
.PARAMETER ModelPath
    Chemin du fichier de modèle de correction. Par défaut, utilise le chemin défini dans le module.
.EXAMPLE
    .\Adaptive-ErrorCorrection.Simplified.ps1 -TrainingMode
    Exécute le script en mode d'apprentissage pour générer un modèle de correction.
.EXAMPLE
    .\Adaptive-ErrorCorrection.Simplified.ps1 -ModelPath "C:\Models\correction-model.json"
    Utilise un modèle de correction personnalisé.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$TrainingMode,
    
    [Parameter(Mandatory = $false)]
    [string]$ModelPath = ""
)

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "ErrorLearningSystem.psm1"
Import-Module $modulePath -Force

# Initialiser le système
Initialize-ErrorLearningSystem

# Définir le chemin du modèle si non spécifié
if (-not $ModelPath) {
    $ModelPath = Join-Path -Path $PSScriptRoot -ChildPath "Models\correction-model.json"
}

# Créer le répertoire du modèle s'il n'existe pas
$modelDir = Split-Path -Path $ModelPath -Parent
if (-not (Test-Path -Path $modelDir)) {
    New-Item -Path $modelDir -ItemType Directory -Force | Out-Null
}

# Fonction pour générer un modèle de correction
function New-CorrectionModel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    Write-Host "Génération d'un modèle de correction..."
    
    # Obtenir l'analyse des erreurs
    $errorAnalysis = Get-PowerShellErrorAnalysis -IncludeStatistics
    
    # Définir les patterns de correction
    $correctionPatterns = @(
        @{
            ErrorType = "HardcodedPath"
            Pattern = '(?<!\\)["''](?:[A-Z]:\\|\\\\)[^"'']*["'']'
            Replacement = '(Join-Path -Path $PSScriptRoot -ChildPath "CHEMIN_RELATIF")'
            Description = "Remplace les chemins codés en dur par des chemins relatifs"
        },
        @{
            ErrorType = "NoErrorHandling"
            Pattern = '(?<!try\s*\{\s*)(?:Get-Content|Set-Content)(?!\s*-ErrorAction)'
            Replacement = '$1 -ErrorAction Stop'
            Description = "Ajoute une gestion d'erreurs aux cmdlets qui peuvent échouer"
        },
        @{
            ErrorType = "WriteHostUsage"
            Pattern = 'Write-Host'
            Replacement = 'Write-Output'
            Description = "Remplace Write-Host par Write-Output"
        },
        @{
            ErrorType = "ObsoleteCmdlet"
            Pattern = 'Get-WmiObject'
            Replacement = 'Get-CimInstance'
            Description = "Remplace les cmdlets obsolètes par des cmdlets modernes"
        }
    )
    
    # Créer le modèle
    $model = @{
        Metadata = @{
            Version = "1.0"
            CreationDate = Get-Date -Format "yyyy-MM-dd"
            LastUpdated = Get-Date -Format "yyyy-MM-dd"
        }
        Patterns = $correctionPatterns
    }
    
    # Convertir le modèle en JSON
    $modelJson = $model | ConvertTo-Json -Depth 3
    
    # Enregistrer le modèle
    Set-Content -Path $OutputPath -Value $modelJson -Force
    
    Write-Host "Modèle de correction généré avec succès : $OutputPath"
    
    return $model
}

# Fonction pour appliquer un modèle de correction
function Apply-CorrectionModel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModelPath,
        
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )
    
    Write-Host "Application du modèle de correction au script : $ScriptPath"
    
    # Vérifier si le modèle existe
    if (-not (Test-Path -Path $ModelPath)) {
        Write-Error "Le modèle de correction spécifié n'existe pas : $ModelPath"
        return $false
    }
    
    # Vérifier si le script existe
    if (-not (Test-Path -Path $ScriptPath)) {
        Write-Error "Le script spécifié n'existe pas : $ScriptPath"
        return $false
    }
    
    # Charger le modèle
    $model = Get-Content -Path $ModelPath -Raw | ConvertFrom-Json
    
    # Lire le contenu du script
    $scriptContent = Get-Content -Path $ScriptPath -Raw
    
    # Appliquer les patterns de correction
    $correctedContent = $scriptContent
    
    foreach ($pattern in $model.Patterns) {
        $correctedContent = $correctedContent -replace $pattern.Pattern, $pattern.Replacement
    }
    
    # Créer une sauvegarde du script original
    $backupPath = "$ScriptPath.bak"
    Copy-Item -Path $ScriptPath -Destination $backupPath -Force
    
    # Enregistrer le script corrigé
    Set-Content -Path $ScriptPath -Value $correctedContent -Force
    
    Write-Host "Corrections appliquées au script : $ScriptPath"
    Write-Host "Sauvegarde créée : $backupPath"
    
    return $true
}

# Exécuter en mode d'apprentissage si demandé
if ($TrainingMode) {
    $model = New-CorrectionModel -OutputPath $ModelPath
    Write-Host "Mode d'apprentissage terminé. Modèle généré : $ModelPath"
}
else {
    Write-Host "Mode d'application du modèle. Utilisez -TrainingMode pour générer un nouveau modèle."
    
    # Vérifier si le modèle existe
    if (-not (Test-Path -Path $ModelPath)) {
        Write-Warning "Le modèle de correction spécifié n'existe pas : $ModelPath"
        Write-Warning "Génération d'un nouveau modèle..."
        $model = New-CorrectionModel -OutputPath $ModelPath
    }
    else {
        Write-Host "Modèle de correction trouvé : $ModelPath"
        
        # Charger le modèle
        $model = Get-Content -Path $ModelPath -Raw | ConvertFrom-Json
        
        Write-Host "Modèle chargé avec succès."
        Write-Host "Version : $($model.Metadata.Version)"
        Write-Host "Date de création : $($model.Metadata.CreationDate)"
        Write-Host "Dernière mise à jour : $($model.Metadata.LastUpdated)"
        Write-Host "Nombre de patterns : $($model.Patterns.Count)"
    }
}

Write-Host "Script terminé."
