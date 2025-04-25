# Add-Task.ps1
# Script pour ajouter une nouvelle tâche à la roadmap

param (
    [Parameter(Mandatory = $true)]
    [string]$CategoryId,
    
    [Parameter(Mandatory = $true)]
    [string]$Description,
    
    [Parameter(Mandatory = $false)]
    [string]$EstimatedDays = "1-2",
    
    [Parameter(Mandatory = $false)]
    [switch]$Start,
    
    [Parameter(Mandatory = $false)]
    [string]$Note
)

# Chemins des fichiers
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$roadmapPath = "Roadmap\roadmap_perso.md"""

# Vérifier si le fichier existe
if (-not (Test-Path -Path $roadmapPath)) {
    Write-Error "Fichier roadmap non trouvé: $roadmapPath"
    exit 1
}

# Lire le contenu du fichier Markdown
$content = Get-Content -Path $roadmapPath -Encoding UTF8

# Trouver la section correspondant à la catégorie
$categoryPattern = "^## $CategoryId\. (.+)"
$categoryFound = $false
$categoryLine = -1
$categoryName = ""

for ($i = 0; $i -lt $content.Length; $i++) {
    if ($content[$i] -match $categoryPattern) {
        $categoryFound = $true
        $categoryLine = $i
        $categoryName = $matches[1]
        break
    }
}

if (-not $categoryFound) {
    Write-Error "Catégorie avec ID '$CategoryId' non trouvée."
    exit 1
}

# Trouver la fin de la section pour insérer la nouvelle tâche
$endOfSection = $content.Length
for ($i = $categoryLine + 1; $i -lt $content.Length; $i++) {
    if ($content[$i] -match "^## ") {
        $endOfSection = $i - 1
        break
    }
}

# Compter les tâches existantes dans cette catégorie pour déterminer le nouvel ID
$taskCount = 0
$taskPattern = "- \[([ x])\] (.+?) \((.+?)\)"
for ($i = $categoryLine; $i -lt $endOfSection; $i++) {
    if ($content[$i] -match $taskPattern) {
        $taskCount++
    }
}

$newTaskId = "$CategoryId.$($taskCount + 1)"

# Créer la nouvelle tâche
$newTask = "- [ ] $Description ($EstimatedDays jours)"
if ($Start) {
    $newTask += " - *Demarre le $(Get-Date -Format 'dd/MM/yyyy')*"
}

# Insérer la nouvelle tâche à la fin de la section
$insertPosition = $endOfSection
while ($insertPosition -gt $categoryLine && -not ($content[$insertPosition] -match $taskPattern)) {
    $insertPosition--
}
$insertPosition++

$content = $content[0..($insertPosition - 1)] + $newTask + $content[$insertPosition..($content.Length - 1)]

# Ajouter une note si spécifiée
if ($Note) {
    $content = $content[0..($insertPosition)] + "  > *Note: $Note*" + $content[($insertPosition + 1)..($content.Length - 1)]
    $insertPosition++
}

# Mettre à jour le pourcentage de progression de la section
$totalTasks = $taskCount + 1
$completedTasks = 0
for ($i = $categoryLine; $i -lt $endOfSection + 1; $i++) {
    if ($content[$i] -match "- \[x\]") {
        $completedTasks++
    }
}

$progress = [math]::Round(($completedTasks / $totalTasks) * 100)

# Trouver la ligne de progression
for ($i = $categoryLine + 1; $i -lt $categoryLine + 5; $i++) {
    if ($content[$i] -match "\*\*Progression\*\*: (\d+)%") {
        $content[$i] = $content[$i] -replace "\*\*Progression\*\*: \d+%", "**Progression**: $progress%"
        break
    }
}

# Mettre à jour la date de dernière mise à jour
$dateUpdated = $false
for ($i = 0; $i -lt $content.Length; $i++) {
    if ($content[$i] -match "\*Derniere mise a jour:") {
        $content[$i] = "*Derniere mise a jour: $(Get-Date -Format 'dd/MM/yyyy HH:mm')*"
        $dateUpdated = $true
        break
    }
}

if (-not $dateUpdated) {
    $content += "---"
    $content += "*Derniere mise a jour: $(Get-Date -Format 'dd/MM/yyyy HH:mm')*"
}

# Sauvegarder le fichier Markdown
$content | Out-File -FilePath $roadmapPath -Encoding ascii

Write-Host "Tâche $newTaskId ajoutée avec succès à la catégorie '$categoryName'."
