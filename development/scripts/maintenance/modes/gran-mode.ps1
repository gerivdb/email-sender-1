<#
.SYNOPSIS
    Script pour décomposer une tâche de roadmap en sous-tâches plus granulaires (Mode GRAN).
    Version adaptée pour utiliser la configuration unifiée.

.DESCRIPTION
    Ce script permet de décomposer une tâche de roadmap en sous-tâches plus granulaires
    directement dans le document. Il implémente le mode GRAN (Granularité) décrit dans
    la documentation des modes de fonctionnement.
    Cette version est adaptée pour utiliser la configuration unifiée.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap à modifier.

.PARAMETER TaskIdentifier
    Identifiant de la tâche à décomposer (par exemple, "1.2.1.3.2.3").
    Si non spécifié, l'utilisateur sera invité à le saisir.

.PARAMETER SubTasksFile
    Chemin vers un fichier contenant les sous-tâches à créer, une par ligne.
    Si non spécifié, l'utilisateur sera invité à les saisir.

.PARAMETER IndentationStyle
    Style d'indentation à utiliser. Par défaut, utilise le style détecté dans le document.
    Options : "Spaces2", "Spaces4", "Tab", "Auto".

.PARAMETER CheckboxStyle
    Style de case à cocher à utiliser. Par défaut, utilise le style détecté dans le document.
    Options : "GitHub", "Custom", "Auto".

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration unifiée.
    Par défaut : "development\config\unified-config.json".

.EXAMPLE
    .\gran-mode.ps1 -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3"

.EXAMPLE
    .\gran-mode.ps1 -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3" -SubTasksFile "templates\subtasks.txt"

.NOTES
    Auteur: RoadmapParser Team
    Version: 2.0
    Date de création: 2023-08-15
    Date de mise à jour: 2023-06-01 - Adaptation pour utiliser la configuration unifiée
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false)]
    [string]$SubTasksFile,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Spaces2", "Spaces4", "Tab", "Auto")]
    [string]$IndentationStyle = "Auto",

    [Parameter(Mandatory = $false)]
    [ValidateSet("GitHub", "Custom", "Auto")]
    [string]$CheckboxStyle = "Auto",

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "development\config\unified-config.json"
)

# Déterminer le chemin du projet
$projectRoot = $PSScriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and 
       -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Error "Impossible de déterminer le chemin du projet."
        exit 1
    }
}

# Charger la configuration unifiée
$configPath = Join-Path -Path $projectRoot -ChildPath $ConfigPath
if (Test-Path -Path $configPath) {
    try {
        $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
    } catch {
        Write-Error "Erreur lors du chargement de la configuration : $_"
        exit 1
    }
} else {
    Write-Warning "Le fichier de configuration est introuvable : $configPath"
    Write-Warning "Tentative de recherche d'un fichier de configuration alternatif..."
    
    # Essayer de trouver un fichier de configuration alternatif
    $alternativePaths = @(
        "development\config\unified-config.json",
        "development\roadmap\parser\config\modes-config.json",
        "development\roadmap\parser\config\config.json"
    )
    
    foreach ($path in $alternativePaths) {
        $fullPath = Join-Path -Path $projectRoot -ChildPath $path
        if (Test-Path -Path $fullPath) {
            Write-Host "Fichier de configuration trouvé à l'emplacement : $fullPath" -ForegroundColor Green
            $configPath = $fullPath
            try {
                $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
                break
            } catch {
                Write-Warning "Erreur lors du chargement de la configuration : $_"
            }
        }
    }
    
    if (-not $config) {
        Write-Error "Aucun fichier de configuration valide trouvé."
        exit 1
    }
}

# Utiliser les valeurs de la configuration si les paramètres ne sont pas spécifiés
if (-not $FilePath) {
    if ($config.Modes.Gran.DefaultRoadmapFile) {
        $FilePath = Join-Path -Path $projectRoot -ChildPath $config.Modes.Gran.DefaultRoadmapFile
    } elseif ($config.General.ActiveDocumentPath) {
        $FilePath = Join-Path -Path $projectRoot -ChildPath $config.General.ActiveDocumentPath
    } else {
        Write-Error "Aucun fichier de roadmap spécifié et aucun fichier par défaut trouvé dans la configuration."
        exit 1
    }
}

if (-not $SubTasksFile -and $config.Modes.Gran.SubTasksFile) {
    $SubTasksFile = Join-Path -Path $projectRoot -ChildPath $config.Modes.Gran.SubTasksFile
}

if ($IndentationStyle -eq "Auto" -and $config.Modes.Gran.IndentationStyle) {
    $IndentationStyle = $config.Modes.Gran.IndentationStyle
}

if ($CheckboxStyle -eq "Auto" -and $config.Modes.Gran.CheckboxStyle) {
    $CheckboxStyle = $config.Modes.Gran.CheckboxStyle
}

# Convertir les chemins relatifs en chemins absolus
if (-not [System.IO.Path]::IsPathRooted($FilePath)) {
    $FilePath = Join-Path -Path $projectRoot -ChildPath $FilePath
}

if ($SubTasksFile -and -not [System.IO.Path]::IsPathRooted($SubTasksFile)) {
    $SubTasksFile = Join-Path -Path $projectRoot -ChildPath $SubTasksFile
}

# Vérifier que le fichier de roadmap existe
if (-not (Test-Path -Path $FilePath)) {
    Write-Error "Le fichier de roadmap spécifié n'existe pas : $FilePath"
    exit 1
}

# Importer le module RoadmapParser
$modulePath = Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\module\RoadmapParser.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Error "Le module RoadmapParser est introuvable : $modulePath"
    exit 1
}

# Afficher les paramètres
Write-Host "Mode GRAN - Décomposition de tâches en sous-tâches" -ForegroundColor Cyan
Write-Host "Fichier de roadmap : $FilePath" -ForegroundColor Gray
if ($TaskIdentifier) {
    Write-Host "Identifiant de tâche : $TaskIdentifier" -ForegroundColor Gray
}
if ($SubTasksFile) {
    Write-Host "Fichier de sous-tâches : $SubTasksFile" -ForegroundColor Gray
}
Write-Host "Style d'indentation : $IndentationStyle" -ForegroundColor Gray
Write-Host "Style de case à cocher : $CheckboxStyle" -ForegroundColor Gray
Write-Host ""

# Lire les sous-tâches à partir du fichier si spécifié
$subTasksInput = ""
if ($SubTasksFile) {
    if (Test-Path -Path $SubTasksFile) {
        $subTasksInput = Get-Content -Path $SubTasksFile -Encoding UTF8 -Raw
        Write-Host "Sous-tâches lues depuis le fichier : $SubTasksFile" -ForegroundColor Green
    } else {
        Write-Error "Le fichier de sous-tâches spécifié n'existe pas : $SubTasksFile"
        exit 1
    }
}

# IMPORTANT: Ce script modifie DIRECTEMENT le document spécifié.
# La granularisation est appliquée en écrasant (overwriting) le contenu existant.
# Aucun résultat intermédiaire n'est affiché dans le terminal, seul le document est modifié.
Write-Host "ATTENTION: Ce script va modifier directement le document spécifié." -ForegroundColor Yellow
Write-Host "La granularisation sera appliquée en écrasant le contenu existant." -ForegroundColor Yellow
Write-Host "Aucun résultat intermédiaire ne sera affiché dans le terminal, seul le document sera modifié." -ForegroundColor Yellow
Write-Host ""

# Appeler la fonction Invoke-RoadmapGranularization
$params = @{
    FilePath = $FilePath
    IndentationStyle = $IndentationStyle
    CheckboxStyle = $CheckboxStyle
}

if ($TaskIdentifier) {
    $params.TaskIdentifier = $TaskIdentifier
}

if ($subTasksInput) {
    $params.SubTasksInput = $subTasksInput
}

$result = Invoke-RoadmapGranularization @params

# Afficher un message de fin
Write-Host "`nExécution du mode GRAN terminée." -ForegroundColor Cyan
Write-Host "Le document a été modifié : $FilePath" -ForegroundColor Green

# Retourner le résultat
return $result
