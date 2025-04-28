# Capture-Request-Simple.ps1
# Script simplifiÃ© pour capturer une demande spontanÃ©e et l'ajouter Ã  la roadmap


# Capture-Request-Simple.ps1
# Script simplifiÃ© pour capturer une demande spontanÃ©e et l'ajouter Ã  la roadmap

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
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
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

# VÃ©rifier si le fichier roadmap existe
if (-not (Test-Path -Path $roadmapPath)) {
    Write-Error "Fichier roadmap non trouvÃ©: $roadmapPath"
    exit 1
}

# Lire le contenu du fichier Markdown
$content = Get-Content -Path $roadmapPath -Encoding UTF8

# Rechercher la section correspondant Ã  la catÃ©gorie
$categoryPattern = "^## $Category\. (.+)"
$categoryFound = $false
$categoryLine = -1

for ($i = 0; $i -lt $content.Length; $i++) {
    if ($content[$i] -match $categoryPattern) {
        $categoryFound = $true
        $categoryLine = $i
        $categoryName = $matches[1]
        break
    }
}

if (-not $categoryFound) {
    Write-Error "CatÃ©gorie $Category non trouvÃ©e dans la roadmap."
    exit 1
}

# Trouver la fin de la section pour insÃ©rer la nouvelle tÃ¢che
$endOfSection = $content.Length
for ($i = $categoryLine + 1; $i -lt $content.Length; $i++) {
    if ($content[$i] -match "^## ") {
        $endOfSection = $i - 1
        break
    }
}

# Compter les tÃ¢ches existantes dans cette catÃ©gorie
$taskCount = 0
$taskPattern = "- \[([ x])\] (.+?) \((.+?)\)"
for ($i = $categoryLine; $i -lt $endOfSection; $i++) {
    if ($content[$i] -match $taskPattern) {
        $taskCount++
    }
}

# CrÃ©er la nouvelle tÃ¢che
$newTaskId = "$Category.$($taskCount + 1)"
$newTask = "- [ ] $Request ($EstimatedDays jours)"
if ($Start) {
    $newTask += " - *Demarre le $(Get-Date -Format 'dd/MM/yyyy')*"
}

# Trouver la position pour insÃ©rer la nouvelle tÃ¢che (aprÃ¨s la derniÃ¨re tÃ¢che ou aprÃ¨s la ligne de progression)
$insertPosition = $categoryLine + 3  # Par dÃ©faut, aprÃ¨s la ligne de progression
for ($i = $categoryLine + 1; $i -lt $endOfSection; $i++) {
    if ($content[$i] -match $taskPattern) {
        $insertPosition = $i + 1
    }
}

# InsÃ©rer la nouvelle tÃ¢che
$content = $content[0..($insertPosition - 1)] + $newTask + $content[$insertPosition..($content.Length - 1)]

# Ajouter une note si spÃ©cifiÃ©e
if ($Note) {
    $content = $content[0..($insertPosition)] + "  > *Note: $Note*" + $content[($insertPosition + 1)..($content.Length - 1)]
}

# Mettre Ã  jour le pourcentage de progression
$totalTasks = $taskCount + 1
$completedTasks = 0
for ($i = $categoryLine; $i -lt $endOfSection + 2; $i++) {
    if ($content[$i] -match "- \[x\]") {
        $completedTasks++
    }
}

$progress = [math]::Round(($completedTasks / $totalTasks) * 100)

# Mettre Ã  jour la ligne de progression
for ($i = $categoryLine + 1; $i -lt $categoryLine + 4; $i++) {
    if ($content[$i] -match "\*\*Progression\*\*: (\d+)%") {
        $content[$i] = $content[$i] -replace "\*\*Progression\*\*: \d+%", "**Progression**: $progress%"
        break
    }
}

# Mettre Ã  jour la date de derniÃ¨re mise Ã  jour
for ($i = 0; $i -lt $content.Length; $i++) {
    if ($content[$i] -match "\*Derniere mise a jour:") {
        $content[$i] = "*Derniere mise a jour: $(Get-Date -Format 'dd/MM/yyyy HH:mm')*"
        break
    }
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

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
