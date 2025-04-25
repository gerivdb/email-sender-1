#Requires -Version 5.1
<#
.SYNOPSIS
    Gère les cas ambigus de détection de format.

.DESCRIPTION
    Ce script gère les cas ambigus de détection de format en utilisant un système de score de confiance.
    Il permet de résoudre automatiquement les cas ambigus ou de demander une confirmation à l'utilisateur.

.PARAMETER FilePath
    Le chemin du fichier à analyser.

.PARAMETER AutoResolve
    Indique si les cas ambigus doivent être résolus automatiquement sans intervention de l'utilisateur.

.PARAMETER RememberChoices
    Indique si les choix de l'utilisateur doivent être mémorisés pour les cas similaires.

.PARAMETER ShowDetails
    Indique si les détails de la détection doivent être affichés.

.PARAMETER AmbiguityThreshold
    Le seuil de différence de score en dessous duquel deux formats sont considérés comme ambigus.
    Par défaut, la valeur est 20.

.PARAMETER UserChoicesPath
    Le chemin vers le fichier JSON contenant les choix mémorisés de l'utilisateur.
    Par défaut, utilise 'UserFormatChoices.json' dans le même répertoire que ce script.

.EXAMPLE
    Handle-AmbiguousFormats -FilePath "C:\path\to\file.txt"
    Détecte le format du fichier spécifié et gère les cas ambigus.

.EXAMPLE
    Handle-AmbiguousFormats -FilePath "C:\path\to\file.txt" -AutoResolve
    Détecte le format du fichier spécifié et résout automatiquement les cas ambigus.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

function Handle-AmbiguousFormats {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$AutoResolve,
        
        [Parameter(Mandatory = $false)]
        [switch]$RememberChoices,
        
        [Parameter(Mandatory = $false)]
        [switch]$ShowDetails,
        
        [Parameter(Mandatory = $false)]
        [int]$AmbiguityThreshold = 20,
        
        [Parameter(Mandatory = $false)]
        [string]$UserChoicesPath = (Join-Path -Path $PSScriptRoot -ChildPath "UserFormatChoices.json")
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        throw "Le fichier '$FilePath' n'existe pas."
    }
    
    # Détecter le format du fichier
    $detectionResult = Detect-FileFormat -FilePath $FilePath -IncludeAllFormats
    
    # Si aucun format n'a été détecté, retourner le résultat tel quel
    if (-not $detectionResult.DetectedFormat) {
        return $detectionResult
    }
    
    # Vérifier s'il y a des cas ambigus
    $topFormats = $detectionResult.AllFormats | Sort-Object -Property Score, Priority -Descending | Select-Object -First 2
    
    if ($topFormats.Count -lt 2) {
        return $detectionResult
    }
    
    $scoreDifference = $topFormats[0].Score - $topFormats[1].Score
    
    # Si la différence de score est supérieure au seuil, ce n'est pas ambigu
    if ($scoreDifference -ge $AmbiguityThreshold) {
        return $detectionResult
    }
    
    # C'est un cas ambigu, afficher les détails si demandé
    if ($ShowDetails) {
        Write-Host "Cas ambigu détecté pour le fichier '$FilePath'" -ForegroundColor Yellow
        Write-Host "Formats possibles :" -ForegroundColor Yellow
        
        foreach ($format in $topFormats) {
            Write-Host "  - $($format.Format) (Score: $($format.Score)%, Priorité: $($format.Priority))" -ForegroundColor Cyan
            Write-Host "    Critères correspondants : $($format.MatchedCriteria -join ", ")" -ForegroundColor Gray
        }
        
        Write-Host ""
    }
    
    # Créer une clé unique pour ce cas ambigu
    $fileExtension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    $ambiguityKey = "$fileExtension|$($topFormats[0].Format):$($topFormats[0].Score)|$($topFormats[1].Format):$($topFormats[1].Score)"
    
    # Vérifier si un choix a déjà été mémorisé pour ce cas
    $userChoice = $null
    
    if ($RememberChoices -and (Test-Path -Path $UserChoicesPath)) {
        try {
            $userChoices = Get-Content -Path $UserChoicesPath -Raw | ConvertFrom-Json -AsHashtable
            
            if ($userChoices.ContainsKey($ambiguityKey)) {
                $userChoice = $userChoices[$ambiguityKey]
                
                if ($ShowDetails) {
                    Write-Host "Choix mémorisé trouvé pour ce cas : $userChoice" -ForegroundColor Green
                }
            }
        }
        catch {
            Write-Warning "Erreur lors du chargement des choix mémorisés : $_"
        }
    }
    
    # Si un choix a été mémorisé, l'utiliser
    if ($userChoice) {
        $selectedFormat = $userChoice
    }
    # Sinon, résoudre automatiquement ou demander à l'utilisateur
    else {
        if ($AutoResolve) {
            # Résoudre automatiquement en fonction de la priorité
            $selectedFormat = $topFormats | Sort-Object -Property Priority -Descending | Select-Object -First 1 -ExpandProperty Format
            
            if ($ShowDetails) {
                Write-Host "Résolution automatique : $selectedFormat (priorité plus élevée)" -ForegroundColor Green
            }
        }
        else {
            # Demander à l'utilisateur
            $selectedFormat = Confirm-FormatDetection -Formats $topFormats
            
            # Mémoriser le choix si demandé
            if ($RememberChoices -and $selectedFormat) {
                try {
                    $userChoices = @{}
                    
                    if (Test-Path -Path $UserChoicesPath) {
                        $userChoices = Get-Content -Path $UserChoicesPath -Raw | ConvertFrom-Json -AsHashtable
                    }
                    
                    $userChoices[$ambiguityKey] = $selectedFormat
                    $userChoices | ConvertTo-Json | Set-Content -Path $UserChoicesPath -Encoding UTF8
                    
                    if ($ShowDetails) {
                        Write-Host "Choix mémorisé pour les cas similaires." -ForegroundColor Green
                    }
                }
                catch {
                    Write-Warning "Erreur lors de la mémorisation du choix : $_"
                }
            }
        }
    }
    
    # Mettre à jour le résultat avec le format sélectionné
    $selectedFormatInfo = $detectionResult.AllFormats | Where-Object { $_.Format -eq $selectedFormat } | Select-Object -First 1
    
    if ($selectedFormatInfo) {
        $detectionResult.DetectedFormat = $selectedFormat
        $detectionResult.ConfidenceScore = $selectedFormatInfo.Score
        $detectionResult.MatchedCriteria = $selectedFormatInfo.MatchedCriteria -join ", "
    }
    
    return $detectionResult
}

# Fonction pour demander une confirmation à l'utilisateur
function Confirm-FormatDetection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Formats
    )
    
    Write-Host "Plusieurs formats possibles ont été détectés." -ForegroundColor Yellow
    Write-Host "Veuillez sélectionner le format correct :" -ForegroundColor Yellow
    
    $formatOptions = @()
    $index = 1
    
    foreach ($format in $Formats) {
        Write-Host "  $index. $($format.Format) (Score: $($format.Score)%, Priorité: $($format.Priority))" -ForegroundColor Cyan
        $formatOptions += $format.Format
        $index++
    }
    
    Write-Host ""
    
    while ($true) {
        $userInput = Read-Host "Entrez le numéro du format (1-$($formatOptions.Count)) ou 'q' pour quitter"
        
        if ($userInput -eq 'q') {
            return $null
        }
        
        try {
            $choice = [int]$userInput
            
            if ($choice -ge 1 -and $choice -le $formatOptions.Count) {
                return $formatOptions[$choice - 1]
            }
            else {
                Write-Host "Choix invalide. Veuillez entrer un nombre entre 1 et $($formatOptions.Count)." -ForegroundColor Red
            }
        }
        catch {
            Write-Host "Entrée invalide. Veuillez entrer un nombre." -ForegroundColor Red
        }
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Handle-AmbiguousFormats
