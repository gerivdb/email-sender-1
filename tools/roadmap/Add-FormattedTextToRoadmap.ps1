# Add-FormattedTextToRoadmap.ps1
# Script pour ajouter du texte formaté à la roadmap

param (
    [Parameter(Mandatory = $true)]
    [string]$Text,
    
    [Parameter(Mandatory = $false)]
    [string]$SectionTitle = "Nouvelle section",
    
    [Parameter(Mandatory = $false)]
    [string]$Complexity = "Moyenne",
    
    [Parameter(Mandatory = $false)]
    [string]$TimeEstimate = "3-5 jours",
    
    [Parameter(Mandatory = $false)]
    [string]$RoadmapFile = "roadmap_perso.md",
    
    [Parameter(Mandatory = $false)]
    [int]$SectionNumber = 0
)

# Chemin de la roadmap
$RoadmapPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath $RoadmapFile

# Vérifier que le fichier roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Error "Fichier roadmap non trouve: $RoadmapPath"
    exit 1
}

# Formater le texte en format roadmap
$FormatScript = Join-Path -Path $PSScriptRoot -ChildPath "Format-TextToRoadmap.ps1"
$FormattedText = & $FormatScript -Text $Text -SectionTitle $SectionTitle -Complexity $Complexity -TimeEstimate $TimeEstimate

# Lire le contenu de la roadmap
$RoadmapContent = Get-Content -Path $RoadmapPath -Raw

# Diviser le contenu en lignes
$RoadmapLines = $RoadmapContent -split "`r?`n"

# Trouver les sections existantes
$SectionIndices = @()
for ($i = 0; $i -lt $RoadmapLines.Count; $i++) {
    if ($RoadmapLines[$i] -match "^## \d+") {
        $SectionIndices += $i
    }
}

# Si aucune section n'est trouvée, ajouter à la fin
if ($SectionIndices.Count -eq 0) {
    $NewContent = $RoadmapContent + "`n`n" + $FormattedText
    Set-Content -Path $RoadmapPath -Value $NewContent
    Write-Host "Le texte formaté a été ajouté à la fin du fichier roadmap" -ForegroundColor Green
    exit 0
}

# Si le numéro de section est 0 ou supérieur au nombre de sections, ajouter à la fin
if ($SectionNumber -le 0 -or $SectionNumber -gt $SectionIndices.Count) {
    $LastSectionIndex = $SectionIndices[-1]
    
    # Trouver la fin de la dernière section
    $EndOfLastSection = $RoadmapLines.Count - 1
    for ($i = $LastSectionIndex + 1; $i -lt $RoadmapLines.Count; $i++) {
        if ($RoadmapLines[$i] -match "^## ") {
            $EndOfLastSection = $i - 1
            break
        }
    }
    
    # Insérer la nouvelle section après la dernière section
    $NewRoadmapLines = $RoadmapLines[0..$EndOfLastSection]
    $NewRoadmapLines += ""
    $NewRoadmapLines += $FormattedText -split "`r?`n"
    $NewRoadmapLines += $RoadmapLines[($EndOfLastSection + 1)..($RoadmapLines.Count - 1)]
    
    $NewContent = $NewRoadmapLines -join "`n"
    Set-Content -Path $RoadmapPath -Value $NewContent
    Write-Host "La nouvelle section a été ajoutée après la section $($SectionIndices.Count)" -ForegroundColor Green
    exit 0
}

# Insérer la nouvelle section à la position spécifiée
$InsertIndex = $SectionIndices[$SectionNumber - 1]

# Trouver la fin de la section précédente
$EndOfPrevSection = $InsertIndex - 1

# Insérer la nouvelle section
$NewRoadmapLines = $RoadmapLines[0..$EndOfPrevSection]
$NewRoadmapLines += ""
$NewRoadmapLines += $FormattedText -split "`r?`n"
$NewRoadmapLines += $RoadmapLines[$InsertIndex..($RoadmapLines.Count - 1)]

$NewContent = $NewRoadmapLines -join "`n"
Set-Content -Path $RoadmapPath -Value $NewContent
Write-Host "La nouvelle section a été insérée avant la section $SectionNumber" -ForegroundColor Green
