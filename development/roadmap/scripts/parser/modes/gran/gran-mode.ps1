<#
.SYNOPSIS
    Script pour dÃ©composer une tÃ¢che de roadmap en sous-tÃ¢ches plus granulaires (Mode GRAN).

.DESCRIPTION
    Ce script permet de dÃ©composer une tÃ¢che de roadmap en sous-tÃ¢ches plus granulaires
    directement dans le document. Il implÃ©mente le mode GRAN (GranularitÃ©) dÃ©crit dans
    la documentation des modes de fonctionnement.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap Ã  modifier.

.PARAMETER TaskIdentifier
    Identifiant de la tÃ¢che Ã  dÃ©composer (par exemple, "1.2.1.3.2.3").
    Si non spÃ©cifiÃ©, l'utilisateur sera invitÃ© Ã  le saisir.

.PARAMETER SubTasksFile
    Chemin vers un fichier contenant les sous-tÃ¢ches Ã  crÃ©er, une par ligne.
    Si non spÃ©cifiÃ©, l'utilisateur sera invitÃ© Ã  les saisir.

.PARAMETER IndentationStyle
    Style d'indentation Ã  utiliser. Par dÃ©faut, utilise le style dÃ©tectÃ© dans le document.
    Options : "Spaces2", "Spaces4", "Tab", "Auto".

.PARAMETER CheckboxStyle
    Style de case Ã  cocher Ã  utiliser. Par dÃ©faut, utilise le style dÃ©tectÃ© dans le document.
    Options : "GitHub", "Custom", "Auto".

.EXAMPLE
    .\development\scripts\gran-mode.ps1 -FilePath "Roadmap/roadmap_complete_converted.md" -TaskIdentifier "1.2.1.3.2.3"

.EXAMPLE
    .\development\scripts\gran-mode.ps1 -FilePath "Roadmap/roadmap_complete_converted.md" -TaskIdentifier "1.2.1.3.2.3" -SubTasksFile "subtasks.txt"

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
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

# Importer les fonctions nÃ©cessaires
# Utiliser des chemins absolus pour Ãªtre sÃ»r
$splitTaskPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\roadmap-parser\module\Functions\Public\Split-RoadmapTask.ps1"
$invokeGranPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\roadmap-parser\module\Functions\Public\Invoke-RoadmapGranularization.ps1"

# IMPORTANT: Ce script modifie DIRECTEMENT le document spÃ©cifiÃ©.
# La granularisation est appliquÃ©e en Ã©crasant (overwriting) le contenu existant.
# Aucun rÃ©sultat intermÃ©diaire n'est affichÃ© dans le terminal, seul le document est modifiÃ©.

if (Test-Path -Path $splitTaskPath) {
    . $splitTaskPath
    Write-Host "Fonction Split-RoadmapTask importÃ©e." -ForegroundColor Green
} else {
    throw "La fonction Split-RoadmapTask est introuvable Ã  l'emplacement : $splitTaskPath"
}

if (Test-Path -Path $invokeGranPath) {
    . $invokeGranPath
    Write-Host "Fonction Invoke-RoadmapGranularization importÃ©e." -ForegroundColor Green
} else {
    throw "La fonction Invoke-RoadmapGranularization est introuvable Ã  l'emplacement : $invokeGranPath"
}

# VÃ©rifier que le fichier de roadmap existe
if (-not (Test-Path -Path $FilePath)) {
    throw "Le fichier de roadmap spÃ©cifiÃ© n'existe pas : $FilePath"
}

# Lire les sous-tÃ¢ches Ã  partir du fichier si spÃ©cifiÃ©
$subTasksInput = ""
if ($SubTasksFile) {
    if (Test-Path -Path $SubTasksFile) {
        $subTasksInput = Get-Content -Path $SubTasksFile -Encoding UTF8 -Raw
    } else {
        throw "Le fichier de sous-tÃ¢ches spÃ©cifiÃ© n'existe pas : $SubTasksFile"
    }
}

# Appeler la fonction Invoke-RoadmapGranularization
Invoke-RoadmapGranularization -FilePath $FilePath -TaskIdentifier $TaskIdentifier -SubTasksInput $subTasksInput -IndentationStyle $IndentationStyle -CheckboxStyle $CheckboxStyle
