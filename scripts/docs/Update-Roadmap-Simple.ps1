# Update-Roadmap-Simple.ps1
# Script simplifié pour mettre à jour la roadmap personnelle

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
$roadmapPath = "Roadmap\roadmap_perso.md"""

# Vérifier si les fichiers existent
if (-not (Test-Path -Path $dataPath)) {
    Write-Error "Fichier de données non trouvé: $dataPath"
    exit 1
}

if (-not (Test-Path -Path $roadmapPath)) {
    Write-Error "Fichier roadmap non trouvé: $roadmapPath"
    exit 1
}

# Charger les données JSON
try {
    $roadmapData = Get-Content -Path $dataPath -Raw | ConvertFrom-Json
}
catch {
    Write-Error "Erreur lors du chargement des données JSON: $_"
    exit 1
}

# Fonction pour mettre à jour une tâche
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
                    Write-Host "Tâche $Id marquée comme terminée."
                }
                
                if ($MarkStart -and -not $task.startDate) {
                    $task.startDate = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
                    Write-Host "Tâche $Id marquée comme démarrée."
                }
                
                if ($TaskNote) {
                    $task.notes = $TaskNote
                    Write-Host "Note ajoutée à la tâche $Id."
                }
                
                # Mettre à jour le pourcentage de progression de la catégorie
                $totalTasks = $category.tasks.Count
                $completedTasks = ($category.tasks | Where-Object { $_.completed -eq $true }).Count
                $category.progress = [math]::Round(($completedTasks / $totalTasks) * 100)
            }
        }
    }
    
    if (-not $taskFound) {
        Write-Error "Tâche avec ID '$Id' non trouvée."
        return $false
    }
    
    return $true
}

# Si un ID de tâche est spécifié, mettre à jour cette tâche
if ($TaskId) {
    $success = Update-Task -Id $TaskId -MarkComplete:$Complete -MarkStart:$Start -TaskNote $Note
    if (-not $success) { exit 1 }
}

# Mettre à jour la date de dernière modification
$roadmapData.lastUpdated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")

# Sauvegarder les données JSON
$roadmapData | ConvertTo-Json -Depth 10 | Set-Content -Path $dataPath

# Mettre à jour le fichier Markdown avec les informations de progression
$content = Get-Content -Path $roadmapPath -Encoding UTF8

# Ajouter les informations de progression à chaque section
for ($i = 0; $i -lt $content.Length; $i++) {
    $line = $content[$i]
    
    # Rechercher les lignes de titre de section (## 1. Documentation et formation)
    if ($line -match '## (\d+)\. (.+)') {
        $sectionNumber = [int]$matches[1]
        $category = $roadmapData.categories | Where-Object { $_.id -eq $sectionNumber }
        
        if ($category) {
            # Vérifier si la ligne suivante contient déjà "Progression"
            $hasProgressLine = $false
            for ($j = $i + 1; $j -lt [Math]::Min($i + 5, $content.Length); $j++) {
                if ($content[$j] -match '\*\*Progression\*\*') {
                    $hasProgressLine = $true
                    $content[$j] = "**Progression**: $($category.progress)%"
                    break
                }
            }
            
            # Si pas de ligne de progression, l'ajouter après la ligne de temps estimé
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
    
    # Mettre à jour les cases à cocher
    if ($line -match '- \[([ x])\] (.+?) \((.+?)\)') {
        $taskDescription = $matches[2]
        
        # Trouver la tâche correspondante
        $taskFound = $false
        foreach ($category in $roadmapData.categories) {
            foreach ($task in $category.tasks) {
                if ($task.description -eq $taskDescription) {
                    $taskFound = $true
                    $checkbox = if ($task.completed) { "[x]" } else { "[ ]" }
                    
                    $newLine = "- $checkbox $taskDescription ($($task.estimatedDays) jours)"
                    
                    if ($task.startDate -and -not $task.completionDate) {
                        $startDate = [DateTime]::Parse($task.startDate)
                        $newLine += " - *Démarré le $(Get-Date $startDate -Format 'dd/MM/yyyy')*"
                    }
                    
                    if ($task.completionDate) {
                        $completionDate = [DateTime]::Parse($task.completionDate)
                        $newLine += " - *Terminé le $(Get-Date $completionDate -Format 'dd/MM/yyyy')*"
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

# Mettre à jour la date de dernière mise à jour
$dateUpdated = $false
for ($i = 0; $i -lt $content.Length; $i++) {
    if ($content[$i] -match '\*Derni.+re mise . jour:') {
        $content[$i] = "*Dernière mise à jour: $(Get-Date -Format 'dd/MM/yyyy HH:mm')*"
        $dateUpdated = $true
        break
    }
}

if (-not $dateUpdated) {
    $content += "---"
    $content += "*Dernière mise à jour: $(Get-Date -Format 'dd/MM/yyyy HH:mm')*"
}

# Sauvegarder le fichier Markdown
$utf8WithBom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllLines($roadmapPath, $content, $utf8WithBom)

Write-Host "Roadmap mise à jour avec succès."
