#Requires -Version 5.1
<#
.SYNOPSIS
    DÃ©tecte le format d'un fichier.

.DESCRIPTION
    Ce script dÃ©tecte le format d'un fichier en utilisant des critÃ¨res avancÃ©s.

.PARAMETER FilePath
    Le chemin du fichier Ã  analyser.

.PARAMETER CriteriaPath
    Le chemin du fichier de critÃ¨res de dÃ©tection.

.PARAMETER IncludeAllFormats
    Indique si tous les formats dÃ©tectÃ©s doivent Ãªtre inclus dans le rÃ©sultat.

.PARAMETER MinimumScore
    Le score minimum pour qu'un format soit considÃ©rÃ© comme dÃ©tectÃ©.

.EXAMPLE
    Test-FileFormat -FilePath "C:\path\to\file.txt"
    DÃ©tecte le format du fichier spÃ©cifiÃ©.

.EXAMPLE
    Test-FileFormat -FilePath "C:\path\to\file.txt" -IncludeAllFormats
    DÃ©tecte le format du fichier spÃ©cifiÃ© et inclut tous les formats dÃ©tectÃ©s dans le rÃ©sultat.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

function Test-FileFormat {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$CriteriaPath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeAllFormats,

        [Parameter(Mandatory = $false)]
        [int]$MinimumScore = 0
    )

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        throw "Le fichier '$FilePath' n'existe pas."
    }

    # Utiliser le chemin de critÃ¨res par dÃ©faut si non spÃ©cifiÃ©
    if (-not $CriteriaPath) {
        $CriteriaPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Detectors\FormatDetectionCriteria.json"
    }

    # VÃ©rifier si le fichier de critÃ¨res existe
    if (-not (Test-Path -Path $CriteriaPath -PathType Leaf)) {
        throw "Le fichier de critÃ¨res '$CriteriaPath' n'existe pas."
    }

    # Charger les critÃ¨res de dÃ©tection
    $criteria = Get-Content -Path $CriteriaPath -Raw | ConvertFrom-Json

    # Obtenir les informations sur le fichier
    $fileInfo = Get-Item -Path $FilePath
    $fileExtension = $fileInfo.Extension.ToLower()
    $fileSize = $fileInfo.Length

    # DÃ©terminer si le fichier est binaire
    $isBinary = Test-BinaryFile -FilePath $FilePath

    # Initialiser les rÃ©sultats
    $results = @()

    # Analyser le fichier pour chaque format
    foreach ($format in $criteria.PSObject.Properties.Name) {
        $formatCriteria = $criteria.$format

        # VÃ©rifier la taille minimale
        if ($fileSize -lt $formatCriteria.MinimumSize) {
            continue
        }

        # Initialiser le score
        $score = 0
        $matchedCriteria = @()

        # VÃ©rifier l'extension
        if ($formatCriteria.Extensions -contains $fileExtension) {
            $score += $formatCriteria.ExtensionWeight
            $matchedCriteria += "Extension ($fileExtension)"
        }

        # Si le fichier est binaire, vÃ©rifier les signatures binaires
        if ($isBinary) {
            # TODO: ImplÃ©menter la vÃ©rification des signatures binaires
        }
        else {
            # Lire le contenu du fichier
            $content = Get-Content -Path $FilePath -Raw

            # VÃ©rifier les motifs d'en-tÃªte
            foreach ($pattern in $formatCriteria.HeaderPatterns) {
                if ($content -match $pattern) {
                    $score += $formatCriteria.HeaderWeight / $formatCriteria.HeaderPatterns.Count
                    $matchedCriteria += "En-tÃªte ($pattern)"
                    break
                }
            }

            # VÃ©rifier les motifs de contenu
            foreach ($pattern in $formatCriteria.ContentPatterns) {
                if ($content -match $pattern) {
                    $score += $formatCriteria.ContentWeight / $formatCriteria.ContentPatterns.Count
                    $matchedCriteria += "Contenu ($pattern)"
                }
            }

            # VÃ©rifier les motifs de structure
            foreach ($pattern in $formatCriteria.StructurePatterns) {
                if ($content -match $pattern) {
                    $score += $formatCriteria.StructureWeight / $formatCriteria.StructurePatterns.Count
                    $matchedCriteria += "Structure ($pattern)"
                }
            }
        }

        # VÃ©rifier si le nombre de critÃ¨res requis est atteint
        if ($matchedCriteria.Count -lt $formatCriteria.RequiredPatternCount) {
            continue
        }

        # VÃ©rifier si l'en-tÃªte est requis et prÃ©sent
        if ($formatCriteria.RequireHeader -and -not ($matchedCriteria -like "En-tÃªte*")) {
            continue
        }

        # Ajouter le rÃ©sultat
        $results += [PSCustomObject]@{
            Format = $formatCriteria.Name
            Score = [Math]::Round($score)
            Priority = $formatCriteria.Priority
            MatchedCriteria = $matchedCriteria
        }
    }

    # Filtrer les rÃ©sultats par score minimum
    $results = $results | Where-Object { $_.Score -ge $MinimumScore }

    # Trier les rÃ©sultats par score et prioritÃ©
    $results = $results | Sort-Object -Property Score, Priority -Descending

    # CrÃ©er le rÃ©sultat
    $result = [PSCustomObject]@{
        FilePath = $FilePath
        Size = $fileSize
        IsBinary = $isBinary
        DetectedFormat = if ($results.Count -gt 0) { $results[0].Format } else { $null }
        ConfidenceScore = if ($results.Count -gt 0) { $results[0].Score } else { 0 }
        MatchedCriteria = if ($results.Count -gt 0) { $results[0].MatchedCriteria -join ", " } else { "" }
    }

    # Ajouter tous les formats dÃ©tectÃ©s si demandÃ©
    if ($IncludeAllFormats) {
        $result | Add-Member -MemberType NoteProperty -Name "AllFormats" -Value $results
    }

    return $result
}

# Fonction pour dÃ©terminer si un fichier est binaire
function Test-BinaryFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    # Lire les premiers octets du fichier
    $bytes = Get-Content -Path $FilePath -Encoding Byte -TotalCount 1000

    # Compter le nombre d'octets nuls
    $nullCount = ($bytes | Where-Object { $_ -eq 0 }).Count

    # Si plus de 10% des octets sont nuls, considÃ©rer le fichier comme binaire
    return ($nullCount / $bytes.Count) -gt 0.1
}

# Exporter les fonctions
Export-ModuleMember -Function Test-FileFormat
