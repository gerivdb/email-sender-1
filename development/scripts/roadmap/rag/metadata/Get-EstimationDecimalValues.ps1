# Get-EstimationDecimalValues.ps1
# Script pour extraire les valeurs d'estimation décimales dans un texte en utilisant Python
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$InputText,

    [Parameter(Mandatory = $false)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [string]$OutputFormat = "Text"
)

# Fonction principale
function Main {
    # Vérifier si un texte d'entrée ou un chemin de fichier a été fourni
    if (-not $InputText -and -not $FilePath) {
        Write-Error "Vous devez fournir soit un texte d'entrée, soit un chemin de fichier."
        return
    }

    # Vérifier si Python est installé
    try {
        $pythonVersion = python --version
        Write-Verbose "Python est installé: $pythonVersion"
    } catch {
        Write-Error "Python n'est pas installé ou n'est pas dans le PATH."
        return
    }

    # Déterminer le chemin du script Python
    $scriptDir = $PSScriptRoot
    $pythonScript = Join-Path -Path $scriptDir -ChildPath "extract_decimal_values.py"

    # Vérifier si le script Python existe
    if (-not (Test-Path -Path $pythonScript)) {
        Write-Error "Le script Python n'existe pas: $pythonScript"
        return
    }

    # Exécuter le script Python
    try {
        if ($InputText) {
            $result = python $pythonScript -t $InputText --format $OutputFormat.ToLower()
        } elseif ($FilePath) {
            $result = python $pythonScript -i $FilePath --format $OutputFormat.ToLower()
        }

        return $result
    } catch {
        Write-Error "Une erreur s'est produite lors de l'exécution du script Python: $_"
        return
    }
}

# Exécuter la fonction principale
Main
