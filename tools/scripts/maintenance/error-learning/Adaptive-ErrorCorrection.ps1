<#
.SYNOPSIS
    Script d'apprentissage adaptatif pour les corrections d'erreurs PowerShell.
.DESCRIPTION
    Ce script analyse l'historique des corrections d'erreurs pour améliorer
    les suggestions de correction et créer des scripts auto-adaptatifs.
.PARAMETER TrainingMode
    Si spécifié, active le mode d'entraînement qui analyse les corrections manuelles.
.PARAMETER GenerateModel
    Si spécifié, génère un modèle de correction basé sur l'historique.
.PARAMETER ModelPath
    Chemin où enregistrer ou charger le modèle. Par défaut, utilise le répertoire data.
.PARAMETER TestScript
    Chemin du script à utiliser pour tester le modèle.
.EXAMPLE
    .\Adaptive-ErrorCorrection.ps1 -TrainingMode
    Analyse l'historique des corrections pour améliorer le modèle.
.EXAMPLE
    .\Adaptive-ErrorCorrection.ps1 -GenerateModel -ModelPath "C:\Models\correction-model.json"
    Génère un modèle de correction et l'enregistre dans le fichier spécifié.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$TrainingMode,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateModel,
    
    [Parameter(Mandatory = $false)]
    [string]$ModelPath = "",
    
    [Parameter(Mandatory = $false)]
    [string]$TestScript = ""
)

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "ErrorLearningSystem.psm1"
Import-Module $modulePath -Force

# Initialiser le système
Initialize-ErrorLearningSystem

# Définir le chemin du modèle par défaut
if (-not $ModelPath) {
    $ModelPath = Join-Path -Path $PSScriptRoot -ChildPath "data\correction-model.json"
}

# Fonction pour analyser l'historique des corrections
function Analyze-CorrectionHistory {
    [CmdletBinding()]
    param ()
    
    # Vérifier si le système est initialisé
    if (-not $script:IsInitialized) {
        Initialize-ErrorLearningSystem
    }
    
    # Récupérer toutes les erreurs avec des solutions
    $errors = $script:ErrorDatabase.Errors | Where-Object { $_.Solution }
    
    Write-Host "Analyse de $($errors.Count) erreurs avec des solutions..." -ForegroundColor Cyan
    
    # Regrouper les erreurs par type
    $errorsByType = @{}
    
    foreach ($error in $errors) {
        $errorType = $error.ErrorType
        
        if (-not $errorsByType.ContainsKey($errorType)) {
            $errorsByType[$errorType] = @()
        }
        
        $errorsByType[$errorType] += $error
    }
    
    # Analyser les patterns de correction pour chaque type d'erreur
    $correctionPatterns = @{}
    
    foreach ($errorType in $errorsByType.Keys) {
        $typeErrors = $errorsByType[$errorType]
        
        Write-Host "Analyse des corrections pour le type d'erreur : $errorType ($($typeErrors.Count) erreurs)" -ForegroundColor Yellow
        
        # Extraire les patterns de correction
        $patterns = @()
        
        foreach ($error in $typeErrors) {
            $solution = $error.Solution
            
            # Extraire le pattern de correction
            if ($solution -match "Remplacer `"(.+)`" par `"(.+)`"") {
                $originalCode = $matches[1]
                $correctedCode = $matches[2]
                
                # Créer un pattern de correction
                $pattern = @{
                    OriginalPattern = [regex]::Escape($originalCode)
                    CorrectedPattern = $correctedCode
                    Frequency = 1
                    Confidence = 0.5
                }
                
                # Vérifier si un pattern similaire existe déjà
                $existingPattern = $patterns | Where-Object { $_.OriginalPattern -eq $pattern.OriginalPattern }
                
                if ($existingPattern) {
                    # Mettre à jour le pattern existant
                    $existingPattern.Frequency++
                    $existingPattern.Confidence = [Math]::Min(1.0, $existingPattern.Confidence + 0.1)
                }
                else {
                    # Ajouter le nouveau pattern
                    $patterns += $pattern
                }
            }
        }
        
        # Trier les patterns par fréquence
        $patterns = $patterns | Sort-Object -Property Frequency -Descending
        
        # Ajouter les patterns au dictionnaire
        $correctionPatterns[$errorType] = $patterns
    }
    
    return $correctionPatterns
}

# Fonction pour générer un modèle de correction
function Generate-CorrectionModel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$CorrectionPatterns,
        
        [Parameter(Mandatory = $true)]
        [string]$ModelPath
    )
    
    # Créer le modèle
    $model = @{
        Metadata = @{
            CreationDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Version = "1.0"
            ErrorCount = ($CorrectionPatterns.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
            PatternCount = ($CorrectionPatterns.Keys | Measure-Object).Count
        }
        Patterns = $CorrectionPatterns
    }
    
    # Créer le répertoire parent si nécessaire
    $modelDir = Split-Path -Path $ModelPath -Parent
    if (-not (Test-Path -Path $modelDir)) {
        New-Item -Path $modelDir -ItemType Directory -Force | Out-Null
    }
    
    # Enregistrer le modèle
    $model | ConvertTo-Json -Depth 10 | Set-Content -Path $ModelPath -Force
    
    Write-Host "Modèle de correction généré : $ModelPath" -ForegroundColor Green
    Write-Host "  Types d'erreurs : $($model.Metadata.PatternCount)" -ForegroundColor Yellow
    Write-Host "  Patterns de correction : $($model.Metadata.ErrorCount)" -ForegroundColor Yellow
    
    return $model
}

# Fonction pour charger un modèle de correction
function Load-CorrectionModel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModelPath
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $ModelPath)) {
        Write-Error "Le fichier de modèle spécifié n'existe pas : $ModelPath"
        return $null
    }
    
    # Charger le modèle
    try {
        $model = Get-Content -Path $ModelPath -Raw | ConvertFrom-Json -AsHashtable
        
        Write-Host "Modèle de correction chargé : $ModelPath" -ForegroundColor Green
        Write-Host "  Date de création : $($model.Metadata.CreationDate)" -ForegroundColor Yellow
        Write-Host "  Version : $($model.Metadata.Version)" -ForegroundColor Yellow
        Write-Host "  Types d'erreurs : $($model.Metadata.PatternCount)" -ForegroundColor Yellow
        Write-Host "  Patterns de correction : $($model.Metadata.ErrorCount)" -ForegroundColor Yellow
        
        return $model
    }
    catch {
        Write-Error "Erreur lors du chargement du modèle : $_"
        return $null
    }
}

# Fonction pour appliquer le modèle à un script
function Apply-CorrectionModel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Model,
        
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )
    
    # Vérifier si le script existe
    if (-not (Test-Path -Path $ScriptPath)) {
        Write-Error "Le script spécifié n'existe pas : $ScriptPath"
        return $false
    }
    
    # Lire le contenu du script
    $scriptContent = Get-Content -Path $ScriptPath -Raw
    $scriptLines = Get-Content -Path $ScriptPath
    
    # Créer une sauvegarde du script
    $backupPath = "$ScriptPath.bak"
    Copy-Item -Path $ScriptPath -Destination $backupPath -Force
    
    # Appliquer les patterns de correction
    $correctionsMade = 0
    $patterns = $Model.Patterns
    
    foreach ($errorType in $patterns.Keys) {
        $typePatterns = $patterns[$errorType]
        
        Write-Host "Application des patterns pour le type d'erreur : $errorType ($($typePatterns.Count) patterns)" -ForegroundColor Yellow
        
        foreach ($pattern in $typePatterns) {
            $originalPattern = $pattern.OriginalPattern
            $correctedPattern = $pattern.CorrectedPattern
            $confidence = $pattern.Confidence
            
            # Appliquer le pattern uniquement si la confiance est suffisante
            if ($confidence -ge 0.7) {
                try {
                    $newContent = [regex]::Replace($scriptContent, $originalPattern, $correctedPattern)
                    
                    # Vérifier si le contenu a été modifié
                    if ($newContent -ne $scriptContent) {
                        $scriptContent = $newContent
                        $correctionsMade++
                        
                        Write-Host "  Pattern appliqué : $originalPattern -> $correctedPattern (Confiance : $confidence)" -ForegroundColor Green
                    }
                }
                catch {
                    Write-Warning "Erreur lors de l'application du pattern : $_"
                }
            }
        }
    }
    
    # Enregistrer le script corrigé
    if ($correctionsMade -gt 0) {
        $scriptContent | Out-File -FilePath $ScriptPath -Encoding utf8
        
        Write-Host "Script corrigé : $ScriptPath" -ForegroundColor Green
        Write-Host "Corrections appliquées : $correctionsMade" -ForegroundColor Yellow
        Write-Host "Sauvegarde créée : $backupPath" -ForegroundColor Yellow
        
        return $true
    }
    else {
        Write-Host "Aucune correction appliquée au script." -ForegroundColor Yellow
        
        # Supprimer la sauvegarde inutile
        Remove-Item -Path $backupPath -Force
        
        return $false
    }
}

# Fonction pour tester le modèle
function Test-CorrectionModel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Model,
        
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )
    
    # Vérifier si le script existe
    if (-not (Test-Path -Path $ScriptPath)) {
        Write-Error "Le script spécifié n'existe pas : $ScriptPath"
        return $false
    }
    
    # Lire le contenu du script
    $scriptContent = Get-Content -Path $ScriptPath -Raw
    
    # Créer une copie temporaire du script
    $tempPath = [System.IO.Path]::GetTempFileName() + ".ps1"
    $scriptContent | Out-File -FilePath $tempPath -Encoding utf8
    
    # Appliquer le modèle à la copie temporaire
    $result = Apply-CorrectionModel -Model $Model -ScriptPath $tempPath
    
    # Supprimer la copie temporaire
    Remove-Item -Path $tempPath -Force
    
    return $result
}

# Mode d'entraînement
if ($TrainingMode) {
    Write-Host "Mode d'entraînement activé." -ForegroundColor Cyan
    
    # Analyser l'historique des corrections
    $correctionPatterns = Analyze-CorrectionHistory
    
    # Générer un modèle
    $model = Generate-CorrectionModel -CorrectionPatterns $correctionPatterns -ModelPath $ModelPath
    
    Write-Host "Entraînement terminé." -ForegroundColor Green
}
# Mode de génération de modèle
elseif ($GenerateModel) {
    Write-Host "Génération du modèle de correction..." -ForegroundColor Cyan
    
    # Analyser l'historique des corrections
    $correctionPatterns = Analyze-CorrectionHistory
    
    # Générer un modèle
    $model = Generate-CorrectionModel -CorrectionPatterns $correctionPatterns -ModelPath $ModelPath
    
    Write-Host "Génération du modèle terminée." -ForegroundColor Green
}
# Mode de test
elseif ($TestScript) {
    Write-Host "Test du modèle de correction..." -ForegroundColor Cyan
    
    # Charger le modèle
    $model = Load-CorrectionModel -ModelPath $ModelPath
    
    if ($model) {
        # Tester le modèle
        $result = Test-CorrectionModel -Model $model -ScriptPath $TestScript
        
        if ($result) {
            Write-Host "Test réussi : le modèle a appliqué des corrections au script." -ForegroundColor Green
        }
        else {
            Write-Host "Test terminé : le modèle n'a pas appliqué de corrections au script." -ForegroundColor Yellow
        }
    }
    
    Write-Host "Test terminé." -ForegroundColor Green
}
# Mode par défaut
else {
    Write-Host "Aucun mode spécifié. Utilisation du mode par défaut." -ForegroundColor Cyan
    
    # Charger le modèle s'il existe
    if (Test-Path -Path $ModelPath) {
        $model = Load-CorrectionModel -ModelPath $ModelPath
        
        if ($model) {
            Write-Host "Modèle chargé avec succès." -ForegroundColor Green
        }
        else {
            Write-Host "Impossible de charger le modèle. Génération d'un nouveau modèle..." -ForegroundColor Yellow
            
            # Analyser l'historique des corrections
            $correctionPatterns = Analyze-CorrectionHistory
            
            # Générer un modèle
            $model = Generate-CorrectionModel -CorrectionPatterns $correctionPatterns -ModelPath $ModelPath
        }
    }
    else {
        Write-Host "Aucun modèle trouvé. Génération d'un nouveau modèle..." -ForegroundColor Yellow
        
        # Analyser l'historique des corrections
        $correctionPatterns = Analyze-CorrectionHistory
        
        # Générer un modèle
        $model = Generate-CorrectionModel -CorrectionPatterns $correctionPatterns -ModelPath $ModelPath
    }
    
    Write-Host "Opération terminée." -ForegroundColor Green
}
