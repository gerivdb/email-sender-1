<#
.SYNOPSIS
    Script d'apprentissage adaptatif pour les corrections d'erreurs PowerShell.
.DESCRIPTION
    Ce script analyse l'historique des corrections d'erreurs pour amÃ©liorer
    les suggestions de correction et crÃ©er des scripts auto-adaptatifs.
.PARAMETER TrainingMode
    Si spÃ©cifiÃ©, active le mode d'entraÃ®nement qui analyse les corrections manuelles.
.PARAMETER GenerateModel
    Si spÃ©cifiÃ©, gÃ©nÃ¨re un modÃ¨le de correction basÃ© sur l'historique.
.PARAMETER ModelPath
    Chemin oÃ¹ enregistrer ou charger le modÃ¨le. Par dÃ©faut, utilise le rÃ©pertoire data.
.PARAMETER TestScript
    Chemin du script Ã  utiliser pour tester le modÃ¨le.
.EXAMPLE
    .\Adaptive-ErrorCorrection.ps1 -TrainingMode
    Analyse l'historique des corrections pour amÃ©liorer le modÃ¨le.
.EXAMPLE
    .\Adaptive-ErrorCorrection.ps1 -GenerateModel -ModelPath "C:\Models\correction-model.json"
    GÃ©nÃ¨re un modÃ¨le de correction et l'enregistre dans le fichier spÃ©cifiÃ©.
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

# Initialiser le systÃ¨me
Initialize-ErrorLearningSystem

# DÃ©finir le chemin du modÃ¨le par dÃ©faut
if (-not $ModelPath) {
    $ModelPath = Join-Path -Path $PSScriptRoot -ChildPath "data\correction-model.json"
}

# Fonction pour analyser l'historique des corrections
function Test-CorrectionHistory {
    [CmdletBinding()]
    param ()
    
    # VÃ©rifier si le systÃ¨me est initialisÃ©
    if (-not $script:IsInitialized) {
        Initialize-ErrorLearningSystem
    }
    
    # RÃ©cupÃ©rer toutes les erreurs avec des solutions
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
                
                # CrÃ©er un pattern de correction
                $pattern = @{
                    OriginalPattern = [regex]::Escape($originalCode)
                    CorrectedPattern = $correctedCode
                    Frequency = 1
                    Confidence = 0.5
                }
                
                # VÃ©rifier si un pattern similaire existe dÃ©jÃ 
                $existingPattern = $patterns | Where-Object { $_.OriginalPattern -eq $pattern.OriginalPattern }
                
                if ($existingPattern) {
                    # Mettre Ã  jour le pattern existant
                    $existingPattern.Frequency++
                    $existingPattern.Confidence = [Math]::Min(1.0, $existingPattern.Confidence + 0.1)
                }
                else {
                    # Ajouter le nouveau pattern
                    $patterns += $pattern
                }
            }
        }
        
        # Trier les patterns par frÃ©quence
        $patterns = $patterns | Sort-Object -Property Frequency -Descending
        
        # Ajouter les patterns au dictionnaire
        $correctionPatterns[$errorType] = $patterns
    }
    
    return $correctionPatterns
}

# Fonction pour gÃ©nÃ©rer un modÃ¨le de correction
function New-CorrectionModel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$CorrectionPatterns,
        
        [Parameter(Mandatory = $true)]
        [string]$ModelPath
    )
    
    # CrÃ©er le modÃ¨le
    $model = @{
        Metadata = @{
            CreationDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Version = "1.0"
            ErrorCount = ($CorrectionPatterns.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
            PatternCount = ($CorrectionPatterns.Keys | Measure-Object).Count
        }
        Patterns = $CorrectionPatterns
    }
    
    # CrÃ©er le rÃ©pertoire parent si nÃ©cessaire
    $modelDir = Split-Path -Path $ModelPath -Parent
    if (-not (Test-Path -Path $modelDir)) {
        New-Item -Path $modelDir -ItemType Directory -Force | Out-Null
    }
    
    # Enregistrer le modÃ¨le
    $model | ConvertTo-Json -Depth 10 | Set-Content -Path $ModelPath -Force
    
    Write-Host "ModÃ¨le de correction gÃ©nÃ©rÃ© : $ModelPath" -ForegroundColor Green
    Write-Host "  Types d'erreurs : $($model.Metadata.PatternCount)" -ForegroundColor Yellow
    Write-Host "  Patterns de correction : $($model.Metadata.ErrorCount)" -ForegroundColor Yellow
    
    return $model
}

# Fonction pour charger un modÃ¨le de correction
function Import-CorrectionModel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModelPath
    )
    
    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $ModelPath)) {
        Write-Error "Le fichier de modÃ¨le spÃ©cifiÃ© n'existe pas : $ModelPath"
        return $null
    }
    
    # Charger le modÃ¨le
    try {
        $model = Get-Content -Path $ModelPath -Raw | ConvertFrom-Json -AsHashtable
        
        Write-Host "ModÃ¨le de correction chargÃ© : $ModelPath" -ForegroundColor Green
        Write-Host "  Date de crÃ©ation : $($model.Metadata.CreationDate)" -ForegroundColor Yellow
        Write-Host "  Version : $($model.Metadata.Version)" -ForegroundColor Yellow
        Write-Host "  Types d'erreurs : $($model.Metadata.PatternCount)" -ForegroundColor Yellow
        Write-Host "  Patterns de correction : $($model.Metadata.ErrorCount)" -ForegroundColor Yellow
        
        return $model
    }
    catch {
        Write-Error "Erreur lors du chargement du modÃ¨le : $_"
        return $null
    }
}

# Fonction pour appliquer le modÃ¨le Ã  un script
function Set-CorrectionModel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Model,
        
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )
    
    # VÃ©rifier si le script existe
    if (-not (Test-Path -Path $ScriptPath)) {
        Write-Error "Le script spÃ©cifiÃ© n'existe pas : $ScriptPath"
        return $false
    }
    
    # Lire le contenu du script
    $scriptContent = Get-Content -Path $ScriptPath -Raw
    $scriptLines = Get-Content -Path $ScriptPath
    
    # CrÃ©er une sauvegarde du script
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
                    
                    # VÃ©rifier si le contenu a Ã©tÃ© modifiÃ©
                    if ($newContent -ne $scriptContent) {
                        $scriptContent = $newContent
                        $correctionsMade++
                        
                        Write-Host "  Pattern appliquÃ© : $originalPattern -> $correctedPattern (Confiance : $confidence)" -ForegroundColor Green
                    }
                }
                catch {
                    Write-Warning "Erreur lors de l'application du pattern : $_"
                }
            }
        }
    }
    
    # Enregistrer le script corrigÃ©
    if ($correctionsMade -gt 0) {
        $scriptContent | Out-File -FilePath $ScriptPath -Encoding utf8
        
        Write-Host "Script corrigÃ© : $ScriptPath" -ForegroundColor Green
        Write-Host "Corrections appliquÃ©es : $correctionsMade" -ForegroundColor Yellow
        Write-Host "Sauvegarde crÃ©Ã©e : $backupPath" -ForegroundColor Yellow
        
        return $true
    }
    else {
        Write-Host "Aucune correction appliquÃ©e au script." -ForegroundColor Yellow
        
        # Supprimer la sauvegarde inutile
        Remove-Item -Path $backupPath -Force
        
        return $false
    }
}

# Fonction pour tester le modÃ¨le
function Test-CorrectionModel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Model,
        
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )
    
    # VÃ©rifier si le script existe
    if (-not (Test-Path -Path $ScriptPath)) {
        Write-Error "Le script spÃ©cifiÃ© n'existe pas : $ScriptPath"
        return $false
    }
    
    # Lire le contenu du script
    $scriptContent = Get-Content -Path $ScriptPath -Raw
    
    # CrÃ©er une copie temporaire du script
    $tempPath = [System.IO.Path]::GetTempFileName() + ".ps1"
    $scriptContent | Out-File -FilePath $tempPath -Encoding utf8
    
    # Appliquer le modÃ¨le Ã  la copie temporaire
    $result = Set-CorrectionModel -Model $Model -ScriptPath $tempPath
    
    # Supprimer la copie temporaire
    Remove-Item -Path $tempPath -Force
    
    return $result
}

# Mode d'entraÃ®nement
if ($TrainingMode) {
    Write-Host "Mode d'entraÃ®nement activÃ©." -ForegroundColor Cyan
    
    # Analyser l'historique des corrections
    $correctionPatterns = Test-CorrectionHistory
    
    # GÃ©nÃ©rer un modÃ¨le
    $model = New-CorrectionModel -CorrectionPatterns $correctionPatterns -ModelPath $ModelPath
    
    Write-Host "EntraÃ®nement terminÃ©." -ForegroundColor Green
}
# Mode de gÃ©nÃ©ration de modÃ¨le
elseif ($GenerateModel) {
    Write-Host "GÃ©nÃ©ration du modÃ¨le de correction..." -ForegroundColor Cyan
    
    # Analyser l'historique des corrections
    $correctionPatterns = Test-CorrectionHistory
    
    # GÃ©nÃ©rer un modÃ¨le
    $model = New-CorrectionModel -CorrectionPatterns $correctionPatterns -ModelPath $ModelPath
    
    Write-Host "GÃ©nÃ©ration du modÃ¨le terminÃ©e." -ForegroundColor Green
}
# Mode de test
elseif ($TestScript) {
    Write-Host "Test du modÃ¨le de correction..." -ForegroundColor Cyan
    
    # Charger le modÃ¨le
    $model = Import-CorrectionModel -ModelPath $ModelPath
    
    if ($model) {
        # Tester le modÃ¨le
        $result = Test-CorrectionModel -Model $model -ScriptPath $TestScript
        
        if ($result) {
            Write-Host "Test rÃ©ussi : le modÃ¨le a appliquÃ© des corrections au script." -ForegroundColor Green
        }
        else {
            Write-Host "Test terminÃ© : le modÃ¨le n'a pas appliquÃ© de corrections au script." -ForegroundColor Yellow
        }
    }
    
    Write-Host "Test terminÃ©." -ForegroundColor Green
}
# Mode par dÃ©faut
else {
    Write-Host "Aucun mode spÃ©cifiÃ©. Utilisation du mode par dÃ©faut." -ForegroundColor Cyan
    
    # Charger le modÃ¨le s'il existe
    if (Test-Path -Path $ModelPath) {
        $model = Import-CorrectionModel -ModelPath $ModelPath
        
        if ($model) {
            Write-Host "ModÃ¨le chargÃ© avec succÃ¨s." -ForegroundColor Green
        }
        else {
            Write-Host "Impossible de charger le modÃ¨le. GÃ©nÃ©ration d'un nouveau modÃ¨le..." -ForegroundColor Yellow
            
            # Analyser l'historique des corrections
            $correctionPatterns = Test-CorrectionHistory
            
            # GÃ©nÃ©rer un modÃ¨le
            $model = New-CorrectionModel -CorrectionPatterns $correctionPatterns -ModelPath $ModelPath
        }
    }
    else {
        Write-Host "Aucun modÃ¨le trouvÃ©. GÃ©nÃ©ration d'un nouveau modÃ¨le..." -ForegroundColor Yellow
        
        # Analyser l'historique des corrections
        $correctionPatterns = Test-CorrectionHistory
        
        # GÃ©nÃ©rer un modÃ¨le
        $model = New-CorrectionModel -CorrectionPatterns $correctionPatterns -ModelPath $ModelPath
    }
    
    Write-Host "OpÃ©ration terminÃ©e." -ForegroundColor Green
}

