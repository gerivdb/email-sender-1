<#
.SYNOPSIS
    Script pour exÃ©cuter le mode CHECK amÃ©liorÃ© et mettre Ã  jour les cases Ã  cocher dans le document actif.

.DESCRIPTION
    Ce script est un wrapper pour le mode CHECK amÃ©liorÃ© qui vÃ©rifie si les tÃ¢ches sont 100% implÃ©mentÃ©es
    et testÃ©es avec succÃ¨s, puis met Ã  jour automatiquement les cases Ã  cocher dans le document actif.
    Cette version amÃ©liorÃ©e garantit que tous les fichiers sont enregistrÃ©s en UTF-8 avec BOM.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap Ã  vÃ©rifier.
    Par dÃ©faut : "docs/plans/plan-modes-stepup.md"

.PARAMETER TaskIdentifier
    Identifiant de la tÃ¢che Ã  vÃ©rifier (par exemple, "1.2.3").
    Si non spÃ©cifiÃ©, toutes les tÃ¢ches seront vÃ©rifiÃ©es.

.PARAMETER ActiveDocumentPath
    Chemin vers le document actif Ã  mettre Ã  jour.
    Si non spÃ©cifiÃ©, le script tentera de dÃ©tecter automatiquement le document actif.

.PARAMETER Force
    Indique si les modifications doivent Ãªtre appliquÃ©es sans confirmation.

.EXAMPLE
    .\check.ps1

.EXAMPLE
    .\check.ps1 -TaskIdentifier "1.2.3" -Force

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.1
    Date de crÃ©ation: 2023-09-15
    Date de mise Ã  jour: 2025-05-01 - AmÃ©lioration de l'encodage UTF-8 avec BOM
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath = "docs/plans/plan-modes-stepup.md",

    [Parameter(Mandatory = $false)]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false)]
    [string]$ActiveDocumentPath,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Déterminer le chemin du script check-mode-enhanced.ps1
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "roadmap-parser\modes\check\check-mode-enhanced.ps1"

# Si le chemin n'existe pas, essayer un autre chemin
if (-not (Test-Path -Path $scriptPath)) {
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\roadmap-parser\modes\check\check-mode-enhanced.ps1"
}

# Si le chemin n'existe toujours pas, essayer un autre chemin
if (-not (Test-Path -Path $scriptPath)) {
    $scriptPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "roadmap-parser\modes\check\check-mode-enhanced.ps1"
}

# Si le chemin n'existe toujours pas, essayer un autre chemin
if (-not (Test-Path -Path $scriptPath)) {
    $scriptPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "roadmap-parser\modes\check\check-mode-enhanced.ps1"
}

# Si la version amÃ©liorÃ©e n'est pas trouvÃ©e, essayer la version standard
if (-not (Test-Path -Path $scriptPath)) {
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "roadmap-parser\modes\check\check-mode.ps1"

    if (Test-Path -Path $scriptPath) {
        Write-Warning "La version amÃ©liorÃ©e du mode CHECK n'a pas Ã©tÃ© trouvÃ©e. Utilisation de la version standard."
    }
}

# VÃ©rifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    Write-Error "Le script check-mode-enhanced.ps1 ou check-mode.ps1 est introuvable."
    exit 1
}

# Construire les paramÃ¨tres pour le script check-mode.ps1
$params = @{
    FilePath = $FilePath
    CheckActiveDocument = $true
    ImplementationPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\tools\scripts\roadmap-parser\module\Functions\Public"
    TestsPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\tools\scripts\roadmap-parser\module\Tests"
}

# Ajouter les paramÃ¨tres optionnels s'ils sont spÃ©cifiÃ©s
if ($TaskIdentifier) {
    $params.Add("TaskIdentifier", $TaskIdentifier)
}

if ($ActiveDocumentPath) {
    $params.Add("ActiveDocumentPath", $ActiveDocumentPath)
}

if ($Force) {
    $params.Add("Force", $true)
}

# Afficher les informations de dÃ©marrage
Write-Host "ExÃ©cution du mode CHECK amÃ©liorÃ©..." -ForegroundColor Cyan
Write-Host "Fichier de roadmap : $FilePath" -ForegroundColor Cyan
if ($TaskIdentifier) {
    Write-Host "TÃ¢che Ã  vÃ©rifier : $TaskIdentifier" -ForegroundColor Cyan
} else {
    Write-Host "VÃ©rification de toutes les tÃ¢ches" -ForegroundColor Cyan
}
if ($ActiveDocumentPath) {
    Write-Host "Document actif : $ActiveDocumentPath" -ForegroundColor Cyan
} else {
    Write-Host "DÃ©tection automatique du document actif" -ForegroundColor Cyan
}
if ($Force) {
    Write-Host "Mode force activÃ© : les modifications seront appliquÃ©es sans confirmation" -ForegroundColor Yellow
} else {
    Write-Host "Mode simulation activÃ© : les modifications ne seront pas appliquÃ©es" -ForegroundColor Gray
}

# ExÃ©cuter le script check-mode.ps1 avec les paramÃ¨tres
& $scriptPath @params

# Afficher un message de fin
Write-Host "`nExÃ©cution du mode CHECK amÃ©liorÃ© terminÃ©e." -ForegroundColor Cyan
