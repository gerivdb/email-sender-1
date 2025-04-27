#Requires -Version 5.1
<#
.SYNOPSIS
    GÃ¨re les cas ambigus de dÃ©tection de format de fichiers.

.DESCRIPTION
    Ce script implÃ©mente un mÃ©canisme pour gÃ©rer les cas oÃ¹ plusieurs formats sont possibles
    lors de la dÃ©tection de format de fichiers. Il utilise un systÃ¨me de score de confiance
    pour identifier les cas ambigus et propose soit une rÃ©solution automatique basÃ©e sur des
    rÃ¨gles prÃ©dÃ©finies, soit une confirmation utilisateur interactive.

.PARAMETER FilePath
    Le chemin du fichier Ã  analyser.

.PARAMETER AmbiguityThreshold
    Le seuil de diffÃ©rence de score en dessous duquel deux formats sont considÃ©rÃ©s comme ambigus.
    Par dÃ©faut, la valeur est de 20 (si la diffÃ©rence entre les deux meilleurs scores est infÃ©rieure Ã  20).

.PARAMETER AutoResolve
    Indique si le script doit tenter de rÃ©soudre automatiquement les cas ambigus sans intervention utilisateur.
    Par dÃ©faut, cette option est dÃ©sactivÃ©e.

.PARAMETER RememberChoices
    Indique si le script doit mÃ©moriser les choix de l'utilisateur pour des cas similaires.
    Par dÃ©faut, cette option est activÃ©e.

.PARAMETER ChoicesFilePath
    Le chemin du fichier JSON contenant les choix mÃ©morisÃ©s.
    Par dÃ©faut, utilise 'UserFormatChoices.json' dans le mÃªme rÃ©pertoire.

.EXAMPLE
    .\Handle-AmbiguousFormats.ps1 -FilePath "C:\path\to\file.txt"
    Analyse le fichier spÃ©cifiÃ© et gÃ¨re les cas ambigus de dÃ©tection de format.

.EXAMPLE
    .\Handle-AmbiguousFormats.ps1 -FilePath "C:\path\to\file.txt" -AmbiguityThreshold 10 -AutoResolve
    Analyse le fichier avec un seuil d'ambiguÃ¯tÃ© plus strict et tente de rÃ©soudre automatiquement les cas ambigus.

.NOTES
    Auteur: Augment Agent
    Date: 2025-04-11
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [int]$AmbiguityThreshold = 20,

    [Parameter(Mandatory = $false)]
    [switch]$AutoResolve,

    [Parameter(Mandatory = $false)]
    [switch]$RememberChoices,

    [Parameter(Mandatory = $false)]
    [string]$ChoicesFilePath = "$PSScriptRoot\UserFormatChoices.json"
)

# Importer le module de dÃ©tection de format
$formatDetectionScript = "$PSScriptRoot\Improved-FormatDetection.ps1"
if (-not (Test-Path -Path $formatDetectionScript)) {
    Write-Error "Le script de dÃ©tection de format '$formatDetectionScript' n'existe pas."
    exit 1
}

# Fonction pour charger les choix mÃ©morisÃ©s
function Get-UserChoices {
    if (-not $RememberChoices) {
        return @{}
    }

    if (Test-Path -Path $ChoicesFilePath) {
        try {
            $choices = Get-Content -Path $ChoicesFilePath -Raw | ConvertFrom-Json -AsHashtable
            return $choices
        }
        catch {
            Write-Warning "Erreur lors du chargement des choix mÃ©morisÃ©s : $_"
            return @{}
        }
    }

    return @{}
}

# Fonction pour sauvegarder les choix mÃ©morisÃ©s
function Save-UserChoices {
    param (
        [hashtable]$Choices
    )

    if (-not $RememberChoices) {
        return
    }

    try {
        $Choices | ConvertTo-Json | Set-Content -Path $ChoicesFilePath -Encoding UTF8
    }
    catch {
        Write-Warning "Erreur lors de la sauvegarde des choix mÃ©morisÃ©s : $_"
    }
}

# Fonction pour gÃ©nÃ©rer une clÃ© unique pour un fichier
function Get-FileSignature {
    param (
        [string]$FilePath,
        [array]$FormatScores
    )

    # CrÃ©er une signature basÃ©e sur l'extension et les formats dÃ©tectÃ©s
    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    $formatSignature = ($FormatScores | Sort-Object -Property Format | ForEach-Object { "$($_.Format):$($_.Score)" }) -join "|"

    return "$extension|$formatSignature"
}

# Fonction pour rÃ©soudre automatiquement les cas ambigus
function Resolve-AmbiguousFormat {
    param (
        [array]$FormatScores,
        [string]$FilePath
    )

    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    $topFormats = $FormatScores | Sort-Object -Property Score, Priority -Descending | Select-Object -First 2

    # RÃ¨gles de rÃ©solution automatique

    # RÃ¨gle 1: Si l'extension correspond Ã  l'un des formats dÃ©tectÃ©s, privilÃ©gier ce format
    foreach ($format in $topFormats) {
        $formatCriteria = ($formatCriteria.PSObject.Properties | Where-Object { $_.Name -eq $format.Format }).Value
        if ($formatCriteria -and $formatCriteria.Extensions -contains $extension) {
            return $format.Format
        }
    }

    # RÃ¨gle 2: Cas spÃ©cifiques oÃ¹ le contenu est plus fiable
    $contentPriorityFormats = @("JPEG", "PNG", "GIF", "BMP", "PDF", "EXECUTABLE", "ZIP", "RAR", "7Z")
    foreach ($format in $topFormats) {
        if ($format.Format -in $contentPriorityFormats) {
            return $format.Format
        }
    }

    # RÃ¨gle 3: Cas spÃ©cifiques oÃ¹ l'extension est plus fiable
    $extensionPriorityFormats = @{
        ".docx" = "WORD"
        ".xlsx" = "EXCEL"
        ".pptx" = "POWERPOINT"
        ".csv" = "CSV"
        ".xml" = "XML"
        ".json" = "JSON"
        ".html" = "HTML"
        ".htm" = "HTML"
        ".css" = "CSS"
        ".js" = "JAVASCRIPT"
        ".ps1" = "POWERSHELL"
        ".py" = "PYTHON"
        ".md" = "MARKDOWN"
        ".txt" = "TEXT"
    }

    if ($extensionPriorityFormats.ContainsKey($extension)) {
        $expectedFormat = $extensionPriorityFormats[$extension]
        foreach ($format in $topFormats) {
            if ($format.Format -eq $expectedFormat) {
                return $format.Format
            }
        }
    }

    # Par dÃ©faut, retourner le format avec le score le plus Ã©levÃ©
    return $topFormats[0].Format
}

# Fonction pour demander Ã  l'utilisateur de choisir un format
function Confirm-FormatDetection {
    param (
        [array]$FormatScores,
        [string]$FilePath
    )

    $fileName = [System.IO.Path]::GetFileName($FilePath)
    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()

    Write-Host "`n===== DÃ‰TECTION DE FORMAT AMBIGUÃ‹ =====" -ForegroundColor Yellow
    Write-Host "Fichier: $fileName" -ForegroundColor Cyan
    Write-Host "Extension: $extension" -ForegroundColor Cyan
    Write-Host "Plusieurs formats possibles ont Ã©tÃ© dÃ©tectÃ©s avec des scores similaires:`n" -ForegroundColor Yellow

    # Afficher les formats dÃ©tectÃ©s avec leur score
    $index = 1
    $formatOptions = @()

    foreach ($format in ($FormatScores | Sort-Object -Property Score, Priority -Descending | Select-Object -First 5)) {
        $scoreColor = switch ($format.Score) {
            {$_ -ge 90} { "Green" }
            {$_ -ge 70} { "Yellow" }
            {$_ -ge 50} { "White" }
            default { "Gray" }
        }

        $criteriaText = $format.MatchedCriteria -join ", "

        Write-Host "$index. " -NoNewline
        Write-Host "$($format.Format)" -NoNewline -ForegroundColor Cyan
        Write-Host " - Score: " -NoNewline
        Write-Host "$($format.Score)" -NoNewline -ForegroundColor $scoreColor
        Write-Host " - CritÃ¨res: $criteriaText"

        $formatOptions += $format.Format
        $index++
    }

    # Demander Ã  l'utilisateur de choisir
    Write-Host "`nVeuillez choisir le format correct pour ce fichier:" -ForegroundColor Yellow
    $choice = 0

    do {
        try {
            $userInput = Read-Host "Entrez le numÃ©ro du format (1-$($formatOptions.Count)) ou 'q' pour quitter"

            if ($userInput -eq 'q') {
                return $null
            }

            $choice = [int]$userInput

            if ($choice -lt 1 -or $choice -gt $formatOptions.Count) {
                Write-Host "Choix invalide. Veuillez entrer un nombre entre 1 et $($formatOptions.Count)." -ForegroundColor Red
                $choice = 0
            }
        }
        catch {
            Write-Host "EntrÃ©e invalide. Veuillez entrer un nombre." -ForegroundColor Red
            $choice = 0
        }
    } while ($choice -eq 0)

    return $formatOptions[$choice - 1]
}

# Fonction principale
function Main {
    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Error "Le fichier '$FilePath' n'existe pas."
        exit 1
    }

    # Charger les choix mÃ©morisÃ©s
    $userChoices = Get-UserChoices

    # ExÃ©cuter le script de dÃ©tection de format
    $detectionResult = & $formatDetectionScript -FilePath $FilePath -DetectEncoding -ReturnAllFormats

    # VÃ©rifier si le rÃ©sultat contient les scores de tous les formats
    if (-not $detectionResult.AllFormats) {
        Write-Error "Le script de dÃ©tection de format n'a pas retournÃ© les scores de tous les formats."
        exit 1
    }

    # Obtenir les deux formats avec les scores les plus Ã©levÃ©s
    $topFormats = $detectionResult.AllFormats | Sort-Object -Property Score, Priority -Descending | Select-Object -First 2

    # VÃ©rifier si le cas est ambigu
    $isAmbiguous = ($topFormats.Count -ge 2) -and (($topFormats[0].Score - $topFormats[1].Score) -lt $AmbiguityThreshold)

    if (-not $isAmbiguous) {
        # Cas non ambigu, retourner le rÃ©sultat de la dÃ©tection
        return $detectionResult
    }

    # Cas ambigu, vÃ©rifier si l'utilisateur a dÃ©jÃ  fait un choix pour ce type de fichier
    $fileSignature = Get-FileSignature -FilePath $FilePath -FormatScores $detectionResult.AllFormats

    if ($userChoices.ContainsKey($fileSignature)) {
        $chosenFormat = $userChoices[$fileSignature]

        # Mettre Ã  jour le rÃ©sultat avec le format choisi
        $detectionResult.DetectedFormat = $chosenFormat

        # Mettre Ã  jour le score de confiance
        $detectionResult.ConfidenceScore = ($detectionResult.AllFormats | Where-Object { $_.Format -eq $chosenFormat }).Score

        Write-Host "Format choisi prÃ©cÃ©demment pour ce type de fichier : $chosenFormat" -ForegroundColor Green

        return $detectionResult
    }

    # RÃ©soudre le cas ambigu
    $resolvedFormat = $null

    if ($AutoResolve) {
        # RÃ©solution automatique
        $resolvedFormat = Resolve-AmbiguousFormat -FormatScores $detectionResult.AllFormats -FilePath $FilePath
        Write-Host "Format rÃ©solu automatiquement : $resolvedFormat" -ForegroundColor Green
    }
    else {
        # Demander Ã  l'utilisateur
        $resolvedFormat = Confirm-FormatDetection -FormatScores $detectionResult.AllFormats -FilePath $FilePath

        if ($null -eq $resolvedFormat) {
            Write-Host "OpÃ©ration annulÃ©e par l'utilisateur." -ForegroundColor Yellow
            return $detectionResult
        }

        # MÃ©moriser le choix de l'utilisateur
        if ($RememberChoices) {
            $userChoices[$fileSignature] = $resolvedFormat
            Save-UserChoices -Choices $userChoices
            Write-Host "Choix mÃ©morisÃ© pour les fichiers similaires." -ForegroundColor Green
        }
    }

    # Mettre Ã  jour le rÃ©sultat avec le format rÃ©solu
    $detectionResult.DetectedFormat = $resolvedFormat

    # Mettre Ã  jour le score de confiance
    $detectionResult.ConfidenceScore = ($detectionResult.AllFormats | Where-Object { $_.Format -eq $resolvedFormat }).Score

    return $detectionResult
}

# ExÃ©cuter le script
$result = Main
return $result
