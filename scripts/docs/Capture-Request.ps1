# Capture-Request.ps1
# Script pour capturer une demande spontanée et l'ajouter à la roadmap


# Capture-Request.ps1
# Script pour capturer une demande spontanée et l'ajouter à la roadmap

param (
    [Parameter(Mandatory = $true)

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Écrire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # Créer le répertoire de logs si nécessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'écriture dans le journal
    }
}
try {
    # Script principal
]
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
$roadmapPath = "Roadmap\roadmap_perso.md"""
$requestsLogPath = Join-Path -Path $scriptPath -ChildPath "requests-log.txt"

# Vérifier si le fichier roadmap existe
if (-not (Test-Path -Path $roadmapPath)) {
    Write-Error "Fichier roadmap non trouvé: $roadmapPath"
    exit 1
}

# Lire le contenu du fichier Markdown
$content = Get-Content -Path $roadmapPath -Encoding UTF8

# Vérifier si la catégorie "Demandes spontanées" existe, sinon la créer
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
    # Trouver la position pour insérer la nouvelle catégorie (avant le plan d'implémentation)
    $insertPosition = $content.Length
    for ($i = 0; $i -lt $content.Length; $i++) {
        if ($content[$i] -match "^## Plan d'implementation") {
            $insertPosition = $i
            break
        }
    }

    # Créer la nouvelle catégorie
    $newCategory = @"

## $Category. $categoryName
**Complexite**: Variable
**Temps estime**: Variable
**Progression**: 0%

"@

    # Insérer la nouvelle catégorie
    $content = $content[0..($insertPosition - 1)] + $newCategory + $content[$insertPosition..($content.Length - 1)]
    $categoryLine = $insertPosition
    $insertPosition += 4

    # Mettre à jour les variables pour la suite du script
    $taskInsertPosition = $categoryLine + 4
}
else {
    # Trouver la fin de la section pour insérer la nouvelle tâche
    $insertPosition = $content.Length
    for ($i = $categoryLine + 1; $i -lt $content.Length; $i++) {
        if ($content[$i] -match "^## ") {
            $insertPosition = $i
            break
        }
    }
}

# Compter les tâches existantes dans cette catégorie pour déterminer le nouvel ID
$taskCount = 0
$taskPattern = "- \[([ x])\] (.+?) \((.+?)\)"
for ($i = $categoryLine; $i -lt $insertPosition; $i++) {
    if ($content[$i] -match $taskPattern) {
        $taskCount++
    }
}

$newTaskId = "$Category.$($taskCount + 1)"

# Créer la nouvelle tâche
$newTask = "- [ ] $Request ($EstimatedDays jours)"
if ($Start) {
    $newTask += " - *Demarre le $(Get-Date -Format 'dd/MM/yyyy')*"
}

# Trouver la position exacte pour insérer la nouvelle tâche
$taskInsertPosition = $insertPosition
for ($i = $categoryLine + 4; $i -lt $insertPosition; $i++) {
    if ($content[$i] -match $taskPattern) {
        $taskInsertPosition = $i + 1
    }
}

# Insérer la nouvelle tâche
if ($taskInsertPosition -eq $insertPosition && $taskCount -eq 0) {
    # Première tâche dans la catégorie
    $content = $content[0..($categoryLine + 3)] + $newTask + $content[($categoryLine + 4)..($content.Length - 1)]
    $taskInsertPosition = $categoryLine + 4
}
else {
    $content = $content[0..($taskInsertPosition - 1)] + $newTask + $content[$taskInsertPosition..($content.Length - 1)]
}

# Ajouter une note si spécifiée
if ($Note) {
    $content = $content[0..($taskInsertPosition)] + "  > *Note: $Note*" + $content[($taskInsertPosition + 1)..($content.Length - 1)]
    $taskInsertPosition++
}

# Mettre à jour le pourcentage de progression de la section
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

# Enregistrer la demande dans le journal des demandes
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$logEntry = "[$timestamp] Catégorie: $Category, ID: $newTaskId, Demande: $Request"
if (-not (Test-Path -Path $requestsLogPath)) {
    New-Item -Path $requestsLogPath -ItemType File -Force | Out-Null
}
Add-Content -Path $requestsLogPath -Value $logEntry

Write-Host "Demande spontanée ajoutée avec succès à la roadmap (ID: $newTaskId)."

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "Exécution du script terminée."
}
