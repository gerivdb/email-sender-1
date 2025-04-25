<#
.SYNOPSIS
    Script pour décomposer une tâche de roadmap en sous-tâches plus granulaires (Mode GRAN).

.DESCRIPTION
    Ce script permet de décomposer une tâche de roadmap en sous-tâches plus granulaires
    directement dans le document. Il implémente le mode GRAN (Granularité) décrit dans
    la documentation des modes de fonctionnement.

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

.EXAMPLE
    .\scripts\gran-mode.ps1 -FilePath "Roadmap/roadmap_complete_converted.md" -TaskIdentifier "1.2.1.3.2.3"

.EXAMPLE
    .\scripts\gran-mode.ps1 -FilePath "Roadmap/roadmap_complete_converted.md" -TaskIdentifier "1.2.1.3.2.3" -SubTasksFile "subtasks.txt"

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
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
    [string]$CheckboxStyle = "Auto"
)

# Importer les fonctions nécessaires
# Utiliser des chemins absolus pour être sûr
$splitTaskPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\roadmap-parser\module\Functions\Public\Split-RoadmapTask.ps1"
$invokeGranPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\roadmap-parser\module\Functions\Public\Invoke-RoadmapGranularization.ps1"

# IMPORTANT: Ce script modifie DIRECTEMENT le document spécifié.
# La granularisation est appliquée en écrasant (overwriting) le contenu existant.
# Aucun résultat intermédiaire n'est affiché dans le terminal, seul le document est modifié.

if (Test-Path -Path $splitTaskPath) {
    . $splitTaskPath
    Write-Host "Fonction Split-RoadmapTask importée." -ForegroundColor Green
} else {
    throw "La fonction Split-RoadmapTask est introuvable à l'emplacement : $splitTaskPath"
}

if (Test-Path -Path $invokeGranPath) {
    . $invokeGranPath
    Write-Host "Fonction Invoke-RoadmapGranularization importée." -ForegroundColor Green
} else {
    throw "La fonction Invoke-RoadmapGranularization est introuvable à l'emplacement : $invokeGranPath"
}

# Vérifier que le fichier de roadmap existe
if (-not (Test-Path -Path $FilePath)) {
    throw "Le fichier de roadmap spécifié n'existe pas : $FilePath"
}

# Lire les sous-tâches à partir du fichier si spécifié
$subTasksInput = ""
if ($SubTasksFile) {
    if (Test-Path -Path $SubTasksFile) {
        $subTasksInput = Get-Content -Path $SubTasksFile -Encoding UTF8 -Raw
    } else {
        throw "Le fichier de sous-tâches spécifié n'existe pas : $SubTasksFile"
    }
}

# Appeler la fonction Invoke-RoadmapGranularization
Invoke-RoadmapGranularization -FilePath $FilePath -TaskIdentifier $TaskIdentifier -SubTasksInput $subTasksInput -IndentationStyle $IndentationStyle -CheckboxStyle $CheckboxStyle
