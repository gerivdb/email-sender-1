#Requires -Version 5.1
<#
.SYNOPSIS
    GÃ¨re les cas ambigus de dÃ©tection de format.

.DESCRIPTION
    Ce script gÃ¨re les cas ambigus de dÃ©tection de format en utilisant un systÃ¨me de score de confiance.
    Il permet de rÃ©soudre automatiquement les cas ambigus ou de demander une confirmation Ã  l'utilisateur.

.PARAMETER FilePath
    Le chemin du fichier Ã  analyser.

.PARAMETER AutoResolve
    Indique si les cas ambigus doivent Ãªtre rÃ©solus automatiquement sans intervention de l'utilisateur.

.PARAMETER RememberChoices
    Indique si les choix de l'utilisateur doivent Ãªtre mÃ©morisÃ©s pour les cas similaires.

.PARAMETER ShowDetails
    Indique si les dÃ©tails de la dÃ©tection doivent Ãªtre affichÃ©s.

.PARAMETER AmbiguityThreshold
    Le seuil de diffÃ©rence de score en dessous duquel deux formats sont considÃ©rÃ©s comme ambigus.
    Par dÃ©faut, la valeur est 20.

.PARAMETER UserChoicesPath
    Le chemin vers le fichier JSON contenant les choix mÃ©morisÃ©s de l'utilisateur.
    Par dÃ©faut, utilise 'UserFormatChoices.json' dans le mÃªme rÃ©pertoire que ce script.

.EXAMPLE
    Invoke-AmbiguousFormats -FilePath "C:\path\to\file.txt"
    DÃ©tecte le format du fichier spÃ©cifiÃ© et gÃ¨re les cas ambigus.

.EXAMPLE
    Invoke-AmbiguousFormats -FilePath "C:\path\to\file.txt" -AutoResolve
    DÃ©tecte le format du fichier spÃ©cifiÃ© et rÃ©sout automatiquement les cas ambigus.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

function Invoke-AmbiguousFormats {
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
    
    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        throw "Le fichier '$FilePath' n'existe pas."
    }
    
    # DÃ©tecter le format du fichier
    $detectionResult = Detect-FileFormat -FilePath $FilePath -IncludeAllFormats
    
    # Si aucun format n'a Ã©tÃ© dÃ©tectÃ©, retourner le rÃ©sultat tel quel
    if (-not $detectionResult.DetectedFormat) {
        return $detectionResult
    }
    
    # VÃ©rifier s'il y a des cas ambigus
    $topFormats = $detectionResult.AllFormats | Sort-Object -Property Score, Priority -Descending | Select-Object -First 2
    
    if ($topFormats.Count -lt 2) {
        return $detectionResult
    }
    
    $scoreDifference = $topFormats[0].Score - $topFormats[1].Score
    
    # Si la diffÃ©rence de score est supÃ©rieure au seuil, ce n'est pas ambigu
    if ($scoreDifference -ge $AmbiguityThreshold) {
        return $detectionResult
    }
    
    # C'est un cas ambigu, afficher les dÃ©tails si demandÃ©
    if ($ShowDetails) {
        Write-Host "Cas ambigu dÃ©tectÃ© pour le fichier '$FilePath'" -ForegroundColor Yellow
        Write-Host "Formats possibles :" -ForegroundColor Yellow
        
        foreach ($format in $topFormats) {
            Write-Host "  - $($format.Format) (Score: $($format.Score)%, PrioritÃ©: $($format.Priority))" -ForegroundColor Cyan
            Write-Host "    CritÃ¨res correspondants : $($format.MatchedCriteria -join ", ")" -ForegroundColor Gray
        }
        
        Write-Host ""
    }
    
    # CrÃ©er une clÃ© unique pour ce cas ambigu
    $fileExtension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    $ambiguityKey = "$fileExtension|$($topFormats[0].Format):$($topFormats[0].Score)|$($topFormats[1].Format):$($topFormats[1].Score)"
    
    # VÃ©rifier si un choix a dÃ©jÃ  Ã©tÃ© mÃ©morisÃ© pour ce cas
    $userChoice = $null
    
    if ($RememberChoices -and (Test-Path -Path $UserChoicesPath)) {
        try {
            $userChoices = Get-Content -Path $UserChoicesPath -Raw | ConvertFrom-Json -AsHashtable
            
            if ($userChoices.ContainsKey($ambiguityKey)) {
                $userChoice = $userChoices[$ambiguityKey]
                
                if ($ShowDetails) {
                    Write-Host "Choix mÃ©morisÃ© trouvÃ© pour ce cas : $userChoice" -ForegroundColor Green
                }
            }
        }
        catch {
            Write-Warning "Erreur lors du chargement des choix mÃ©morisÃ©s : $_"
        }
    }
    
    # Si un choix a Ã©tÃ© mÃ©morisÃ©, l'utiliser
    if ($userChoice) {
        $selectedFormat = $userChoice
    }
    # Sinon, rÃ©soudre automatiquement ou demander Ã  l'utilisateur
    else {
        if ($AutoResolve) {
            # RÃ©soudre automatiquement en fonction de la prioritÃ©
            $selectedFormat = $topFormats | Sort-Object -Property Priority -Descending | Select-Object -First 1 -ExpandProperty Format
            
            if ($ShowDetails) {
                Write-Host "RÃ©solution automatique : $selectedFormat (prioritÃ© plus Ã©levÃ©e)" -ForegroundColor Green
            }
        }
        else {
            # Demander Ã  l'utilisateur
            $selectedFormat = Confirm-FormatDetection -Formats $topFormats
            
            # MÃ©moriser le choix si demandÃ©
            if ($RememberChoices -and $selectedFormat) {
                try {
                    $userChoices = @{}
                    
                    if (Test-Path -Path $UserChoicesPath) {
                        $userChoices = Get-Content -Path $UserChoicesPath -Raw | ConvertFrom-Json -AsHashtable
                    }
                    
                    $userChoices[$ambiguityKey] = $selectedFormat
                    $userChoices | ConvertTo-Json | Set-Content -Path $UserChoicesPath -Encoding UTF8
                    
                    if ($ShowDetails) {
                        Write-Host "Choix mÃ©morisÃ© pour les cas similaires." -ForegroundColor Green
                    }
                }
                catch {
                    Write-Warning "Erreur lors de la mÃ©morisation du choix : $_"
                }
            }
        }
    }
    
    # Mettre Ã  jour le rÃ©sultat avec le format sÃ©lectionnÃ©
    $selectedFormatInfo = $detectionResult.AllFormats | Where-Object { $_.Format -eq $selectedFormat } | Select-Object -First 1
    
    if ($selectedFormatInfo) {
        $detectionResult.DetectedFormat = $selectedFormat
        $detectionResult.ConfidenceScore = $selectedFormatInfo.Score
        $detectionResult.MatchedCriteria = $selectedFormatInfo.MatchedCriteria -join ", "
    }
    
    return $detectionResult
}

# Fonction pour demander une confirmation Ã  l'utilisateur
function Confirm-FormatDetection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Formats
    )
    
    Write-Host "Plusieurs formats possibles ont Ã©tÃ© dÃ©tectÃ©s." -ForegroundColor Yellow
    Write-Host "Veuillez sÃ©lectionner le format correct :" -ForegroundColor Yellow
    
    $formatOptions = @()
    $index = 1
    
    foreach ($format in $Formats) {
        Write-Host "  $index. $($format.Format) (Score: $($format.Score)%, PrioritÃ©: $($format.Priority))" -ForegroundColor Cyan
        $formatOptions += $format.Format
        $index++
    }
    
    Write-Host ""
    
    while ($true) {
        $userInput = Read-Host "Entrez le numÃ©ro du format (1-$($formatOptions.Count)) ou 'q' pour quitter"
        
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
            Write-Host "EntrÃ©e invalide. Veuillez entrer un nombre." -ForegroundColor Red
        }
    }
}

# Exporter les fonctions
Export-ModuleMember -function Invoke-AmbiguousFormats

