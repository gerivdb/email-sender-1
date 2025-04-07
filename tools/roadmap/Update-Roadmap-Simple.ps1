# Update-Roadmap-Simple.ps1
# Script simplifiÃ© pour mettre Ã  jour la roadmap personnelle

param (
    [Parameter(Mandatory = $false)]
    [string]$TaskId,
    
    [Parameter(Mandatory = $false)]
    [switch]$Complete,
    
    [Parameter(Mandatory = $false)]
    [switch]$Start,
    
    [Parameter(Mandatory = $false)]
    [string]$Note
)

# Chemins des fichiers
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataPath = Join-Path -Path $scriptPath -ChildPath "roadmap-data.json"
$roadmapPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) -ChildPath "roadmap_perso.md"

# VÃ©rifier si les fichiers existent
if (-not (Test-Path -Path $dataPath)) {
    Write-Error "Fichier de donnÃ©es non trouvÃ©: $dataPath"
    exit 1
}

if (-not (Test-Path -Path $roadmapPath)) {
    Write-Error "Fichier roadmap non trouvÃ©: $roadmapPath"
    exit 1
}

# Charger les donnÃ©es JSON
try {
    $roadmapData = Get-Content -Path $dataPath -Raw | ConvertFrom-Json
}
catch {
    Write-Error "Erreur lors du chargement des donnÃ©es JSON: $_"
    exit 1
}

# Fonction pour mettre Ã  jour une tÃ¢che
function Update-Task {
    param (
        [string]$Id,
        [switch]$MarkComplete,
        [switch]$MarkStart,
        [string]$TaskNote
    )
    
    $taskFound = $false
    
    foreach ($category in $roadmapData.categories) {
        foreach ($task in $category.tasks) {
            if ($task.id -eq $Id) {
                $taskFound = $true
                
                if ($MarkComplete) {
                    $task.completed = $true
                    $task.completionDate = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
                    Write-Host "TÃ¢che $Id marquÃ©e comme terminÃ©e."
                }
                
                if ($MarkStart -and -not $task.startDate) {
                    $task.startDate = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
                    Write-Host "TÃ¢che $Id marquÃ©e comme dÃ©marrÃ©e."
                }
                
                if ($TaskNote) {
                    $task.notes = $TaskNote
                    Write-Host "Note ajoutÃ©e Ã  la tÃ¢che $Id."
                }
                
                # Mettre Ã  jour le pourcentage de progression de la catÃ©gorie
                $totalTasks = $category.tasks.Count
                $completedTasks = ($category.tasks | Where-Object { $_.completed -eq $true }).Count
                $category.progress = [math]::Round(($completedTasks / $totalTasks) * 100)
            }
        }
    }
    
    if (-not $taskFound) {
        Write-Error "TÃ¢che avec ID '$Id' non trouvÃ©e."
        return $false
    }
    
    return $true
}

# Si un ID de tÃ¢che est spÃ©cifiÃ©, mettre Ã  jour cette tÃ¢che
if ($TaskId) {
    $success = Update-Task -Id $TaskId -MarkComplete:$Complete -MarkStart:$Start -TaskNote $Note
    if (-not $success) { exit 1 }
}

# Mettre Ã  jour la date de derniÃ¨re modification
$roadmapData.lastUpdated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")

# Sauvegarder les donnÃ©es JSON
$roadmapData | ConvertTo-Json -Depth 10 | Set-Content -Path $dataPath

# Mettre Ã  jour le fichier Markdown avec les informations de progression
$content = Get-Content -Path $roadmapPath -Encoding UTF8

# Ajouter les informations de progression Ã  chaque section
for ($i = 0; $i -lt $content.Length; $i++) {
    $line = $content[$i]
    
    # Rechercher les lignes de titre de section (## 1. Documentation et formation)
    if ($line -match '## (\d+)\. (.+)') {
        $sectionNumber = [int]$matches[1]
        $category = $roadmapData.categories | Where-Object { $_.id -eq $sectionNumber }
        
        if ($category) {
            # VÃ©rifier si la ligne suivante contient dÃ©jÃ  "Progression"
            $hasProgressLine = $false
            for ($j = $i + 1; $j -lt [Math]::Min($i + 5, $content.Length); $j++) {
                if ($content[$j] -match '\*\*Progression\*\*') {
                    $hasProgressLine = $true
                    $content[$j] = "**Progression**: $($category.progress)%"
                    break
                }
            }
            
            # Si pas de ligne de progression, l'ajouter aprÃ¨s la ligne de temps estimÃ©
            if (-not $hasProgressLine) {
                for ($j = $i + 1; $j -lt [Math]::Min($i + 5, $content.Length); $j++) {
                    if ($content[$j] -match '\*\*Temps estim') {
                        $content[$j] += "`n**Progression**: $($category.progress)%"
                        break
                    }
                }
            }
        }
    }
    
    # Mettre Ã  jour les cases Ã  cocher
    if ($line -match '- \[([ x])\] (.+?) \((.+?)\)') {
        $taskDescription = $matches[2]
        
        # Trouver la tÃ¢che correspondante
        $taskFound = $false
        foreach ($category in $roadmapData.categories) {
            foreach ($task in $category.tasks) {
                if ($task.description -eq $taskDescription) {
                    $taskFound = $true
                    $checkbox = if ($task.completed) { "[x]" } else { "[ ]" }
                    
                    $newLine = "- $checkbox $taskDescription ($($task.estimatedDays) jours)"
                    
                    if ($task.startDate -and -not $task.completionDate) {
                        $startDate = [DateTime]::Parse($task.startDate)
                        $newLine += " - *DÃ©marrÃ© le $(Get-Date $startDate -Format 'dd/MM/yyyy')*"
                    }
                    
                    if ($task.completionDate) {
                        $completionDate = [DateTime]::Parse($task.completionDate)
                        $newLine += " - *TerminÃ© le $(Get-Date $completionDate -Format 'dd/MM/yyyy')*"
                    }
                    
                    $content[$i] = $newLine
                    
                    # Ajouter une note si elle existe
                    if ($task.notes -and $i + 1 -lt $content.Length -and -not ($content[$i + 1] -match '> \*Note:')) {
                        $content = $content[0..$i] + "  > *Note: $($task.notes)*" + $content[($i + 1)..($content.Length - 1)]
                        $i++
                    }
                    elseif ($task.notes -and $i + 1 -lt $content.Length -and $content[$i + 1] -match '> \*Note:') {
                        $content[$i + 1] = "  > *Note: $($task.notes)*"
                    }
                    
                    break
                }
            }
            if ($taskFound) { break }
        }
    }
}

# Mettre Ã  jour la date de derniÃ¨re mise Ã  jour
$dateUpdated = $false
for ($i = 0; $i -lt $content.Length; $i++) {
    if ($content[$i] -match '\*Derni.+re mise . jour:') {
        $content[$i] = "*DerniÃ¨re mise Ã  jour: $(Get-Date -Format 'dd/MM/yyyy HH:mm')*"
        $dateUpdated = $true
        break
    }
}

if (-not $dateUpdated) {
    $content += "---"
    $content += "*DerniÃ¨re mise Ã  jour: $(Get-Date -Format 'dd/MM/yyyy HH:mm')*"
}

# Sauvegarder le fichier Markdown
$utf8WithBom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllLines($roadmapPath, $content, $utf8WithBom)

Write-Host "Roadmap mise Ã  jour avec succÃ¨s."
