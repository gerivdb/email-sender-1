# Capture-Request.ps1
# Script pour capturer une demande spontanÃ©e et l'ajouter Ã  la roadmap

param (
    [Parameter(Mandatory = $true)]
    [string]$Request,

    [Parameter(Mandatory = $false)]
    [string]$Category = "7",

    [Parameter(Mandatory = $false)]
    [string]$EstimatedDays = "1-3",

    [Parameter(Mandatory = $false)]
    [switch]$Start,

    [Parameter(Mandatory = $false)]
    [string]$Note
)

# Chemins des fichiers
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$roadmapPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) -ChildPath "roadmap_perso.md"
$requestsLogPath = Join-Path -Path $scriptPath -ChildPath "requests-log.txt"

# VÃ©rifier si le fichier roadmap existe
if (-not (Test-Path -Path $roadmapPath)) {
    Write-Error "Fichier roadmap non trouvÃ©: $roadmapPath"
    exit 1
}

# Lire le contenu du fichier Markdown
$content = Get-Content -Path $roadmapPath -Encoding UTF8

# VÃ©rifier si la catÃ©gorie "Demandes spontanÃ©es" existe, sinon la crÃ©er
$categoryPattern = "^## $Category\. (.+)"
$categoryFound = $false
$categoryLine = -1
$categoryName = "Demandes spontanees"

for ($i = 0; $i -lt $content.Length; $i++) {
    if ($content[$i] -match $categoryPattern) {
        $categoryFound = $true
        $categoryLine = $i
        $categoryName = $matches[1]
        break
    }
}

if (-not $categoryFound) {
    # Trouver la position pour insÃ©rer la nouvelle catÃ©gorie (avant le plan d'implÃ©mentation)
    $insertPosition = $content.Length
    for ($i = 0; $i -lt $content.Length; $i++) {
        if ($content[$i] -match "^## Plan d'implementation") {
            $insertPosition = $i
            break
        }
    }

    # CrÃ©er la nouvelle catÃ©gorie
    $newCategory = @"

## $Category. $categoryName
**Complexite**: Variable
**Temps estime**: Variable
**Progression**: 0%

"@

    # InsÃ©rer la nouvelle catÃ©gorie
    $content = $content[0..($insertPosition - 1)] + $newCategory + $content[$insertPosition..($content.Length - 1)]
    $categoryLine = $insertPosition
    $insertPosition += 4

    # Mettre Ã  jour les variables pour la suite du script
    $taskInsertPosition = $categoryLine + 4
}
else {
    # Trouver la fin de la section pour insÃ©rer la nouvelle tÃ¢che
    $insertPosition = $content.Length
    for ($i = $categoryLine + 1; $i -lt $content.Length; $i++) {
        if ($content[$i] -match "^## ") {
            $insertPosition = $i
            break
        }
    }
}

# Compter les tÃ¢ches existantes dans cette catÃ©gorie pour dÃ©terminer le nouvel ID
$taskCount = 0
$taskPattern = "- \[([ x])\] (.+?) \((.+?)\)"
for ($i = $categoryLine; $i -lt $insertPosition; $i++) {
    if ($content[$i] -match $taskPattern) {
        $taskCount++
    }
}

$newTaskId = "$Category.$($taskCount + 1)"

# CrÃ©er la nouvelle tÃ¢che
$newTask = "- [ ] $Request ($EstimatedDays jours)"
if ($Start) {
    $newTask += " - *Demarre le $(Get-Date -Format 'dd/MM/yyyy')*"
}

# Trouver la position exacte pour insÃ©rer la nouvelle tÃ¢che
$taskInsertPosition = $insertPosition
for ($i = $categoryLine + 4; $i -lt $insertPosition; $i++) {
    if ($content[$i] -match $taskPattern) {
        $taskInsertPosition = $i + 1
    }
}

# InsÃ©rer la nouvelle tÃ¢che
if ($taskInsertPosition -eq $insertPosition && $taskCount -eq 0) {
    # PremiÃ¨re tÃ¢che dans la catÃ©gorie
    $content = $content[0..($categoryLine + 3)] + $newTask + $content[($categoryLine + 4)..($content.Length - 1)]
    $taskInsertPosition = $categoryLine + 4
}
else {
    $content = $content[0..($taskInsertPosition - 1)] + $newTask + $content[$taskInsertPosition..($content.Length - 1)]
}

# Ajouter une note si spÃ©cifiÃ©e
if ($Note) {
    $content = $content[0..($taskInsertPosition)] + "  > *Note: $Note*" + $content[($taskInsertPosition + 1)..($content.Length - 1)]
    $taskInsertPosition++
}

# Mettre Ã  jour le pourcentage de progression de la section
$totalTasks = $taskCount + 1
$completedTasks = 0
for ($i = $categoryLine; $i -lt $insertPosition + 1; $i++) {
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

# Mettre Ã  jour la date de derniÃ¨re mise Ã  jour
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

# Enregistrer la demande dans le journal des demandes
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$logEntry = "[$timestamp] CatÃ©gorie: $Category, ID: $newTaskId, Demande: $Request"
if (-not (Test-Path -Path $requestsLogPath)) {
    New-Item -Path $requestsLogPath -ItemType File -Force | Out-Null
}
Add-Content -Path $requestsLogPath -Value $logEntry

Write-Host "Demande spontanÃ©e ajoutÃ©e avec succÃ¨s Ã  la roadmap (ID: $newTaskId)."
