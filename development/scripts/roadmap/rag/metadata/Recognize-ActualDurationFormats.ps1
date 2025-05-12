<#
.SYNOPSIS
    Reconnaît les formats de durée réelle dans un texte.

.DESCRIPTION
    Ce script analyse un texte pour reconnaître et analyser différents formats d'expression de durée réelle.
    Il utilise un script Python pour l'analyse et retourne les résultats sous forme d'objets PowerShell.

.PARAMETER InputText
    Le texte à analyser.

.PARAMETER FilePath
    Le chemin vers un fichier à analyser.

.PARAMETER OutputFormat
    Le format de sortie des résultats (Text, JSON, CSV, Object). Par défaut: Object.

.PARAMETER IncludeContext
    Indique si le contexte des expressions doit être inclus dans les résultats.

.PARAMETER ConfidenceThreshold
    Seuil de confiance minimal pour les expressions détectées (entre 0 et 1). Par défaut: 0.5.

.EXAMPLE
    Recognize-ActualDurationFormats -InputText "Tâche: Développer la fonctionnalité X (a pris 4 heures)"

.EXAMPLE
    Recognize-ActualDurationFormats -FilePath "chemin/vers/fichier.txt" -OutputFormat "JSON"

.EXAMPLE
    Recognize-ActualDurationFormats -InputText "Tâche: 2.5 jours réels" -ConfidenceThreshold 0.7
#>

[CmdletBinding(DefaultParameterSetName="Text")]
param (
    [Parameter(Mandatory=$true, ParameterSetName="Text", Position=0)]
    [string]$InputText,
    
    [Parameter(Mandatory=$true, ParameterSetName="File")]
    [string]$FilePath,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Text", "JSON", "CSV", "Object")]
    [string]$OutputFormat = "Object",
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeContext,
    
    [Parameter(Mandatory=$false)]
    [ValidateRange(0, 1)]
    [double]$ConfidenceThreshold = 0.5
)

# Obtenir le répertoire du script
$scriptDir = $PSScriptRoot
if (-not $scriptDir) {
    $scriptDir = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
}
if (-not $scriptDir) {
    $scriptDir = Get-Location
}

# Vérifier si le script Python existe
$pythonScript = Join-Path -Path $scriptDir -ChildPath "recognize_actual_duration_formats.py"

if (-not (Test-Path -Path $pythonScript)) {
    Write-Error "Le script Python n'existe pas: $pythonScript"
    return
}

# Exécuter le script Python
try {
    # Configurer l'encodage pour PowerShell
    $OutputEncoding = [System.Text.Encoding]::UTF8
    
    # Exécuter le script Python directement
    if ($PSCmdlet.ParameterSetName -eq "Text") {
        # Cas où on analyse un texte
        if ($OutputFormat -eq "Text") {
            # Format texte - retourner directement la sortie du script Python
            $output = & python $pythonScript -t "$InputText" --format text
            return $output
        }
        elseif ($OutputFormat -eq "JSON") {
            # Format JSON - retourner la sortie du script Python en JSON
            $output = & python $pythonScript -t "$InputText" --format json
            return $output
        }
        elseif ($OutputFormat -eq "CSV") {
            # Format CSV - retourner la sortie du script Python en CSV
            $output = & python $pythonScript -t "$InputText" --format csv
            return $output
        }
        else {
            # Format Object - convertir la sortie JSON en objets PowerShell
            $output = & python $pythonScript -t "$InputText" --format json
            $result = $output | ConvertFrom-Json
        }
    }
    else {
        # Cas où on analyse un fichier
        if ($OutputFormat -eq "Text") {
            # Format texte - retourner directement la sortie du script Python
            $output = & python $pythonScript -i "$FilePath" --format text
            return $output
        }
        elseif ($OutputFormat -eq "JSON") {
            # Format JSON - retourner la sortie du script Python en JSON
            $output = & python $pythonScript -i "$FilePath" --format json
            return $output
        }
        elseif ($OutputFormat -eq "CSV") {
            # Format CSV - retourner la sortie du script Python en CSV
            $output = & python $pythonScript -i "$FilePath" --format csv
            return $output
        }
        else {
            # Format Object - convertir la sortie JSON en objets PowerShell
            $output = & python $pythonScript -i "$FilePath" --format json
            $result = $output | ConvertFrom-Json
        }
    }
    
    if (-not $result) {
        Write-Verbose "Aucun format de durée réelle reconnu."
        return @()
    }
    
    # Filtrer les résultats selon le seuil de confiance
    $filteredFormats = $result.recognized_formats | Where-Object { $_.confidence -ge $ConfidenceThreshold }
    
    # Supprimer le contexte si non demandé
    if (-not $IncludeContext) {
        $filteredFormats = $filteredFormats | ForEach-Object {
            $_ | Select-Object -Property * -ExcludeProperty context
        }
    }
    
    # Formater la sortie selon le format demandé
    switch ($OutputFormat) {
        "JSON" {
            return $filteredFormats | ConvertTo-Json -Depth 5
        }
        "Object" {
            return $filteredFormats
        }
    }
} catch {
    Write-Error "Erreur lors de l'exécution du script Python: $_"
    return
}
