# Convert-EstimationToStandard.ps1
# Script pour convertir les estimations en format standard
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
    [switch]$IncludeOriginal
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

# Fonction pour convertir une valeur d'une unité à une autre
function Convert-TimeUnitValue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double]$Value,

        [Parameter(Mandatory = $true)]
        [string]$FromUnit,

        [Parameter(Mandatory = $true)]
        [string]$ToUnit
    )

    # Facteurs de conversion vers des heures
    $conversionFactors = @{
        "Minutes" = 1 / 60
        "Hours"   = 1
        "Days"    = 8       # 1 jour = 8 heures
        "Weeks"   = 40     # 1 semaine = 40 heures (5 jours * 8 heures)
        "Months"  = 160   # 1 mois = 160 heures (4 semaines * 40 heures)
    }

    # Convertir en heures d'abord
    $valueInHours = $Value * $conversionFactors[$FromUnit]

    # Puis convertir de heures vers l'unité cible
    $standardValue = $valueInHours / $conversionFactors[$ToUnit]

    # Arrondir à 2 décimales
    $standardValue = [Math]::Round($standardValue, 2)

    return $standardValue
}

# Fonction pour extraire et normaliser les estimations d'un texte
function Get-NormalizedEstimations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $false)]
        [string]$TargetUnit = "Hours",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeOriginal
    )

    # Utiliser le script de normalisation des estimations
    $normalizeScript = Join-Path -Path $scriptDir -ChildPath "normalize_estimations.py"

    if (-not (Test-Path -Path $normalizeScript)) {
        Write-Error "Le script de normalisation n'existe pas: $normalizeScript"
        return $null
    }

    # Extraire et normaliser les estimations
    $normalizedJson = python $normalizeScript -t $Text -u $TargetUnit --format json

    if (-not $normalizedJson) {
        Write-Verbose "Aucune estimation trouvée dans le texte."
        return @()
    }

    # Convertir le JSON en objet PowerShell
    $normalizedEstimations = $normalizedJson | ConvertFrom-Json

    # Convertir en format PowerShell
    $result = @()

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

        $result += $normalized
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

    # Extraire et normaliser les estimations
    $normalizedEstimations = Get-NormalizedEstimations -Text $textToAnalyze -TargetUnit $OutputFormat -IncludeOriginal:$IncludeOriginal

    # Formater la sortie
    if ($normalizedEstimations.Count -eq 0) {
        Write-Output "Aucune estimation trouvée."
    } else {
        return $normalizedEstimations
    }
}

# Exécuter la fonction principale
Main
