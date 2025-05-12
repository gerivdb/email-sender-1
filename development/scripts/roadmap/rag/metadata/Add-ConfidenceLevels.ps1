# Add-ConfidenceLevels.ps1
# Script pour ajouter des niveaux de confiance aux estimations
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$InputText,

    [Parameter(Mandatory = $false)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [string]$OutputFormat = "Hours",

    [Parameter(Mandatory = $false)]
    [switch]$IncludeOriginal,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Simple", "Advanced")]
    [string]$ConfidenceModel = "Simple"
)

# Importer les fonctions communes
$scriptDir = $PSScriptRoot
$commonFunctionsPath = Join-Path -Path $scriptDir -ChildPath "Common-Functions.ps1"

if (Test-Path -Path $commonFunctionsPath) {
    . $commonFunctionsPath
} else {
    Write-Error "Le fichier de fonctions communes n'existe pas: $commonFunctionsPath"
    return
}

# Fonction pour calculer le niveau de confiance simple
function Get-SimpleConfidenceLevel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Estimation
    )

    # Niveau de confiance par défaut
    $confidenceLevel = 0.8 # 80%

    # Ajuster le niveau de confiance en fonction du type d'estimation
    if ($Estimation.ContainsKey("EstimationType")) {
        switch ($Estimation.EstimationType) {
            "simple" {
                # Estimation simple, confiance moyenne
                $confidenceLevel = 0.8
            }
            "range" {
                # Estimation avec plage, confiance plus faible
                $confidenceLevel = 0.7

                # Calculer l'écart relatif
                if ($Estimation.ContainsKey("MinValue") -and $Estimation.ContainsKey("MaxValue")) {
                    $range = $Estimation.MaxValue - $Estimation.MinValue
                    $average = ($Estimation.MaxValue + $Estimation.MinValue) / 2

                    # Plus l'écart est grand, plus la confiance est faible
                    $relativeRange = $range / $average
                    $confidenceLevel = [Math]::Max(0.5, 0.8 - $relativeRange * 0.3)
                }
            }
            "margin" {
                # Estimation avec marge d'erreur, confiance moyenne-haute
                $confidenceLevel = 0.75

                # Calculer la marge relative
                if ($Estimation.ContainsKey("Margin") -and $Estimation.ContainsKey("OriginalValue")) {
                    $relativeMargin = $Estimation.Margin / $Estimation.OriginalValue

                    # Plus la marge est petite, plus la confiance est élevée
                    $confidenceLevel = [Math]::Max(0.6, 0.9 - $relativeMargin * 0.5)
                }
            }
            "composite" {
                # Estimation composite (XhYmin), confiance élevée
                $confidenceLevel = 0.85
            }
            default {
                $confidenceLevel = 0.8
            }
        }
    }

    # Ajuster en fonction des termes utilisés dans le texte original
    if ($Estimation.ContainsKey("OriginalText")) {
        $text = $Estimation.OriginalText.ToLower()

        # Termes qui augmentent la confiance
        $highConfidenceTerms = @("exactement", "precisement", "exact", "precis")
        foreach ($term in $highConfidenceTerms) {
            if ($text.Contains($term)) {
                $confidenceLevel = [Math]::Min(0.95, $confidenceLevel + 0.1)
                break
            }
        }

        # Termes qui diminuent la confiance
        $lowConfidenceTerms = @("environ", "approximativement", "a peu pres", "plus ou moins", "+/-", "±")
        foreach ($term in $lowConfidenceTerms) {
            if ($text.Contains($term)) {
                $confidenceLevel = [Math]::Max(0.5, $confidenceLevel - 0.1)
                break
            }
        }
    }

    # Vérifier également dans le contexte si disponible
    if ($Estimation.ContainsKey("Context")) {
        $context = $Estimation.Context.ToLower()

        # Termes qui augmentent la confiance
        $highConfidenceTerms = @("exactement", "precisement", "exact", "precis")
        foreach ($term in $highConfidenceTerms) {
            if ($context.Contains($term)) {
                $confidenceLevel = [Math]::Min(0.95, $confidenceLevel + 0.1)
                break
            }
        }

        # Termes qui diminuent la confiance
        $lowConfidenceTerms = @("environ", "approximativement", "a peu pres", "plus ou moins", "+/-", "±")
        foreach ($term in $lowConfidenceTerms) {
            if ($context.Contains($term)) {
                $confidenceLevel = [Math]::Max(0.5, $confidenceLevel - 0.1)
                break
            }
        }
    }

    # Arrondir à 2 décimales
    $confidenceLevel = [Math]::Round($confidenceLevel, 2)

    return $confidenceLevel
}

# Fonction pour calculer le niveau de confiance avancé
function Get-AdvancedConfidenceLevel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Estimation,

        [Parameter(Mandatory = $false)]
        [hashtable]$HistoricalData = $null
    )

    # Obtenir d'abord le niveau de confiance simple
    $confidenceLevel = Get-SimpleConfidenceLevel -Estimation $Estimation

    # Facteurs supplémentaires pour le modèle avancé

    # 1. Précision des termes utilisés
    if ($Estimation.ContainsKey("OriginalText")) {
        $text = $Estimation.OriginalText.ToLower()

        # Termes précis (heures exactes vs. jours approximatifs)
        if ($Estimation.OriginalUnit -eq "Hours" -or $Estimation.OriginalUnit -eq "Minutes") {
            $confidenceLevel += 0.05
        } elseif ($Estimation.OriginalUnit -eq "Months") {
            $confidenceLevel -= 0.1
        } elseif ($Estimation.OriginalUnit -eq "Weeks") {
            $confidenceLevel -= 0.05
        }

        # Valeurs décimales indiquent plus de précision
        if ($text -match "\d+[.,]\d+") {
            $confidenceLevel += 0.03
        }
    }

    # 2. Utiliser des données historiques si disponibles
    if ($null -ne $HistoricalData -and $HistoricalData.ContainsKey("AccuracyFactor")) {
        $confidenceLevel *= $HistoricalData.AccuracyFactor
    }

    # Limiter entre 0.1 et 0.99
    $confidenceLevel = [Math]::Max(0.1, [Math]::Min(0.99, $confidenceLevel))

    # Arrondir à 2 décimales
    $confidenceLevel = [Math]::Round($confidenceLevel, 2)

    return $confidenceLevel
}

# Fonction pour ajouter des niveaux de confiance aux estimations
function Add-ConfidenceLevels {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Estimations,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Simple", "Advanced")]
        [string]$Model = "Simple",

        [Parameter(Mandatory = $false)]
        [hashtable]$HistoricalData = $null
    )

    $result = @()

    foreach ($est in $Estimations) {
        # Créer une copie de l'estimation
        $estimation = @{}
        foreach ($key in $est.Keys) {
            $estimation[$key] = $est[$key]
        }

        # Calculer le niveau de confiance
        if ($Model -eq "Simple") {
            $estimation["ConfidenceLevel"] = Get-SimpleConfidenceLevel -Estimation $estimation
        } else {
            $estimation["ConfidenceLevel"] = Get-AdvancedConfidenceLevel -Estimation $estimation -HistoricalData $HistoricalData
        }

        # Ajouter des informations supplémentaires sur la confiance
        $confidenceLevel = $estimation["ConfidenceLevel"]
        if ($confidenceLevel -ge 0.9) {
            $estimation["ConfidenceDescription"] = "Tres elevee"
        } elseif ($confidenceLevel -ge 0.8) {
            $estimation["ConfidenceDescription"] = "Elevee"
        } elseif ($confidenceLevel -ge 0.7) {
            $estimation["ConfidenceDescription"] = "Bonne"
        } elseif ($confidenceLevel -ge 0.6) {
            $estimation["ConfidenceDescription"] = "Moyenne"
        } elseif ($confidenceLevel -ge 0.5) {
            $estimation["ConfidenceDescription"] = "Moderee"
        } elseif ($confidenceLevel -ge 0.4) {
            $estimation["ConfidenceDescription"] = "Faible"
        } else {
            $estimation["ConfidenceDescription"] = "Tres faible"
        }

        $result += $estimation
    }

    return $result
}

# Fonction principale
function Main {
    # Vérifier si un texte d'entrée ou un chemin de fichier a été fourni
    if (-not $InputText -and -not $FilePath) {
        Write-Error "Vous devez fournir soit un texte d'entrée, soit un chemin de fichier."
        return
    }

    # Obtenir le texte à analyser
    $textToAnalyze = ""

    if ($InputText) {
        $textToAnalyze = $InputText
    } elseif ($FilePath) {
        if (Test-Path -Path $FilePath) {
            $textToAnalyze = Get-Content -Path $FilePath -Raw
        } else {
            Write-Error "Le fichier spécifié n'existe pas: $FilePath"
            return
        }
    }

    # Utiliser directement le script Python de normalisation
    $normalizeScript = Join-Path -Path $scriptDir -ChildPath "normalize_estimations.py"

    if (-not (Test-Path -Path $normalizeScript)) {
        Write-Error "Le script de normalisation n'existe pas: $normalizeScript"
        return
    }

    # Obtenir les estimations normalisées
    $normalizedJson = python $normalizeScript -t $textToAnalyze -u $OutputFormat --format json

    if (-not $normalizedJson) {
        Write-Verbose "Aucune estimation trouvée dans le texte."
        return @()
    }

    # Convertir le JSON en objet PowerShell
    $normalizedEstimations = $normalizedJson | ConvertFrom-Json

    # Convertir en format PowerShell
    $estimations = @()

    foreach ($est in $normalizedEstimations) {
        $normalized = @{
            OriginalValue = $est.original_value
            OriginalUnit  = $est.original_unit
            StandardValue = $est.standard_value
            StandardUnit  = $est.standard_unit
            ValueInHours  = $est.value_in_hours
        }

        # Ajouter les informations originales si demandé
        if ($IncludeOriginal) {
            $normalized.OriginalText = $est.original_text
            $normalized.Context = $est.context
        }

        $estimations += $normalized
    }

    $normalizedEstimations = $estimations

    if (-not $normalizedEstimations -or $normalizedEstimations.Count -eq 0) {
        Write-Output "Aucune estimation trouvée."
        return
    }

    # Ajouter les niveaux de confiance
    $estimationsWithConfidence = Add-ConfidenceLevels -Estimations $normalizedEstimations -Model $ConfidenceModel

    return $estimationsWithConfidence
}

# Exécuter la fonction principale
Main
