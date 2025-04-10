#Requires -Version 5.1
<#
.SYNOPSIS
    Gère les cas ambigus de détection de format de fichiers.

.DESCRIPTION
    Ce script implémente un mécanisme pour gérer les cas où plusieurs formats sont possibles
    lors de la détection de format de fichiers. Il utilise un système de score de confiance
    pour identifier les cas ambigus et propose soit une résolution automatique basée sur des
    règles prédéfinies, soit une confirmation utilisateur interactive.

.PARAMETER FilePath
    Le chemin du fichier à analyser.

.PARAMETER AmbiguityThreshold
    Le seuil de différence de score en dessous duquel deux formats sont considérés comme ambigus.
    Par défaut, la valeur est de 20 (si la différence entre les deux meilleurs scores est inférieure à 20).

.PARAMETER AutoResolve
    Indique si le script doit tenter de résoudre automatiquement les cas ambigus sans intervention utilisateur.
    Par défaut, cette option est désactivée.

.PARAMETER RememberChoices
    Indique si le script doit mémoriser les choix de l'utilisateur pour des cas similaires.
    Par défaut, cette option est activée.

.PARAMETER ChoicesFilePath
    Le chemin du fichier JSON contenant les choix mémorisés.
    Par défaut, utilise 'UserFormatChoices.json' dans le même répertoire.

.EXAMPLE
    .\Handle-AmbiguousFormats.ps1 -FilePath "C:\path\to\file.txt"
    Analyse le fichier spécifié et gère les cas ambigus de détection de format.

.EXAMPLE
    .\Handle-AmbiguousFormats.ps1 -FilePath "C:\path\to\file.txt" -AmbiguityThreshold 10 -AutoResolve
    Analyse le fichier avec un seuil d'ambiguïté plus strict et tente de résoudre automatiquement les cas ambigus.

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
    [switch]$RememberChoices = $true,
    
    [Parameter(Mandatory = $false)]
    [string]$ChoicesFilePath = "$PSScriptRoot\UserFormatChoices.json"
)

# Importer le module de détection de format
$formatDetectionScript = "$PSScriptRoot\Improved-FormatDetection.ps1"
if (-not (Test-Path -Path $formatDetectionScript)) {
    Write-Error "Le script de détection de format '$formatDetectionScript' n'existe pas."
    exit 1
}

# Fonction pour charger les choix mémorisés
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
            Write-Warning "Erreur lors du chargement des choix mémorisés : $_"
            return @{}
        }
    }
    
    return @{}
}

# Fonction pour sauvegarder les choix mémorisés
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
        Write-Warning "Erreur lors de la sauvegarde des choix mémorisés : $_"
    }
}

# Fonction pour générer une clé unique pour un fichier
function Get-FileSignature {
    param (
        [string]$FilePath,
        [array]$FormatScores
    )
    
    # Créer une signature basée sur l'extension et les formats détectés
    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    $formatSignature = ($FormatScores | Sort-Object -Property Format | ForEach-Object { "$($_.Format):$($_.Score)" }) -join "|"
    
    return "$extension|$formatSignature"
}

# Fonction pour résoudre automatiquement les cas ambigus
function Resolve-AmbiguousFormat {
    param (
        [array]$FormatScores,
        [string]$FilePath
    )
    
    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    $topFormats = $FormatScores | Sort-Object -Property Score, Priority -Descending | Select-Object -First 2
    
    # Règles de résolution automatique
    
    # Règle 1: Si l'extension correspond à l'un des formats détectés, privilégier ce format
    foreach ($format in $topFormats) {
        $formatCriteria = ($formatCriteria.PSObject.Properties | Where-Object { $_.Name -eq $format.Format }).Value
        if ($formatCriteria -and $formatCriteria.Extensions -contains $extension) {
            return $format.Format
        }
    }
    
    # Règle 2: Cas spécifiques où le contenu est plus fiable
    $contentPriorityFormats = @("JPEG", "PNG", "GIF", "BMP", "PDF", "EXECUTABLE", "ZIP", "RAR", "7Z")
    foreach ($format in $topFormats) {
        if ($format.Format -in $contentPriorityFormats) {
            return $format.Format
        }
    }
    
    # Règle 3: Cas spécifiques où l'extension est plus fiable
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
    
    # Par défaut, retourner le format avec le score le plus élevé
    return $topFormats[0].Format
}

# Fonction pour demander à l'utilisateur de choisir un format
function Confirm-FormatDetection {
    param (
        [array]$FormatScores,
        [string]$FilePath
    )
    
    $fileName = [System.IO.Path]::GetFileName($FilePath)
    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    
    Write-Host "`n===== DÉTECTION DE FORMAT AMBIGUË =====" -ForegroundColor Yellow
    Write-Host "Fichier: $fileName" -ForegroundColor Cyan
    Write-Host "Extension: $extension" -ForegroundColor Cyan
    Write-Host "Plusieurs formats possibles ont été détectés avec des scores similaires:`n" -ForegroundColor Yellow
    
    # Afficher les formats détectés avec leur score
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
        Write-Host " - Critères: $criteriaText"
        
        $formatOptions += $format.Format
        $index++
    }
    
    # Demander à l'utilisateur de choisir
    Write-Host "`nVeuillez choisir le format correct pour ce fichier:" -ForegroundColor Yellow
    $choice = 0
    
    do {
        try {
            $input = Read-Host "Entrez le numéro du format (1-$($formatOptions.Count)) ou 'q' pour quitter"
            
            if ($input -eq 'q') {
                return $null
            }
            
            $choice = [int]$input
            
            if ($choice -lt 1 -or $choice -gt $formatOptions.Count) {
                Write-Host "Choix invalide. Veuillez entrer un nombre entre 1 et $($formatOptions.Count)." -ForegroundColor Red
                $choice = 0
            }
        }
        catch {
            Write-Host "Entrée invalide. Veuillez entrer un nombre." -ForegroundColor Red
            $choice = 0
        }
    } while ($choice -eq 0)
    
    return $formatOptions[$choice - 1]
}

# Fonction principale
function Main {
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Error "Le fichier '$FilePath' n'existe pas."
        exit 1
    }
    
    # Charger les choix mémorisés
    $userChoices = Get-UserChoices
    
    # Exécuter le script de détection de format
    $detectionResult = & $formatDetectionScript -FilePath $FilePath -DetectEncoding -ReturnAllFormats
    
    # Vérifier si le résultat contient les scores de tous les formats
    if (-not $detectionResult.AllFormats) {
        Write-Error "Le script de détection de format n'a pas retourné les scores de tous les formats."
        exit 1
    }
    
    # Obtenir les deux formats avec les scores les plus élevés
    $topFormats = $detectionResult.AllFormats | Sort-Object -Property Score, Priority -Descending | Select-Object -First 2
    
    # Vérifier si le cas est ambigu
    $isAmbiguous = ($topFormats.Count -ge 2) -and (($topFormats[0].Score - $topFormats[1].Score) -lt $AmbiguityThreshold)
    
    if (-not $isAmbiguous) {
        # Cas non ambigu, retourner le résultat de la détection
        return $detectionResult
    }
    
    # Cas ambigu, vérifier si l'utilisateur a déjà fait un choix pour ce type de fichier
    $fileSignature = Get-FileSignature -FilePath $FilePath -FormatScores $detectionResult.AllFormats
    
    if ($userChoices.ContainsKey($fileSignature)) {
        $chosenFormat = $userChoices[$fileSignature]
        
        # Mettre à jour le résultat avec le format choisi
        $detectionResult.DetectedFormat = $chosenFormat
        
        # Mettre à jour le score de confiance
        $detectionResult.ConfidenceScore = ($detectionResult.AllFormats | Where-Object { $_.Format -eq $chosenFormat }).Score
        
        Write-Host "Format choisi précédemment pour ce type de fichier : $chosenFormat" -ForegroundColor Green
        
        return $detectionResult
    }
    
    # Résoudre le cas ambigu
    $resolvedFormat = $null
    
    if ($AutoResolve) {
        # Résolution automatique
        $resolvedFormat = Resolve-AmbiguousFormat -FormatScores $detectionResult.AllFormats -FilePath $FilePath
        Write-Host "Format résolu automatiquement : $resolvedFormat" -ForegroundColor Green
    }
    else {
        # Demander à l'utilisateur
        $resolvedFormat = Confirm-FormatDetection -FormatScores $detectionResult.AllFormats -FilePath $FilePath
        
        if ($null -eq $resolvedFormat) {
            Write-Host "Opération annulée par l'utilisateur." -ForegroundColor Yellow
            return $detectionResult
        }
        
        # Mémoriser le choix de l'utilisateur
        if ($RememberChoices) {
            $userChoices[$fileSignature] = $resolvedFormat
            Save-UserChoices -Choices $userChoices
            Write-Host "Choix mémorisé pour les fichiers similaires." -ForegroundColor Green
        }
    }
    
    # Mettre à jour le résultat avec le format résolu
    $detectionResult.DetectedFormat = $resolvedFormat
    
    # Mettre à jour le score de confiance
    $detectionResult.ConfidenceScore = ($detectionResult.AllFormats | Where-Object { $_.Format -eq $resolvedFormat }).Score
    
    return $detectionResult
}

# Exécuter le script
$result = Main
return $result
