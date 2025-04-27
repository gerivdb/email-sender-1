<#
.SYNOPSIS
    Script pour exécuter le mode CHECK amélioré et mettre à jour les cases à cocher dans le document actif.

.DESCRIPTION
    Ce script est un wrapper pour le mode CHECK amélioré qui vérifie si les tâches sont 100% implémentées
    et testées avec succès, puis met à jour automatiquement les cases à cocher dans le document actif.
    Cette version améliorée garantit que tous les fichiers sont enregistrés en UTF-8 avec BOM.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap à vérifier.
    Par défaut : "docs/plans/plan-modes-stepup.md"

.PARAMETER TaskIdentifier
    Identifiant de la tâche à vérifier (par exemple, "1.2.3").
    Si non spécifié, toutes les tâches seront vérifiées.

.PARAMETER ActiveDocumentPath
    Chemin vers le document actif à mettre à jour.
    Si non spécifié, le script tentera de détecter automatiquement le document actif.

.PARAMETER Force
    Indique si les modifications doivent être appliquées sans confirmation.

.EXAMPLE
    .\check-enhanced.ps1

.EXAMPLE
    .\check-enhanced.ps1 -TaskIdentifier "1.2.3" -Force

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.1
    Date de création: 2023-09-15
    Date de mise à jour: 2025-05-01 - Amélioration de l'encodage UTF-8 avec BOM
#>

[CmdletBinding()]
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

# Si le chemin n'existe pas, essayer d'autres chemins
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

# Vérifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    Write-Error "Le script check-mode-enhanced.ps1 est introuvable à l'emplacement : $scriptPath"
    exit 1
}

# Construire les paramètres pour le script check-mode-enhanced.ps1
$params = @{
    FilePath = $FilePath
    CheckActiveDocument = $true
    ImplementationPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\tools\scripts\roadmap-parser\module\Functions\Public"
    TestsPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\tools\scripts\roadmap-parser\module\Tests"
}

# Ajouter les paramètres optionnels s'ils sont spécifiés
if ($TaskIdentifier) {
    $params.Add("TaskIdentifier", $TaskIdentifier)
}

if ($ActiveDocumentPath) {
    $params.Add("ActiveDocumentPath", $ActiveDocumentPath)
}

if ($Force) {
    $params.Add("Force", $true)
}

# Afficher les informations de démarrage
Write-Host "Exécution du mode CHECK amélioré..." -ForegroundColor Cyan
Write-Host "Fichier de roadmap : $FilePath" -ForegroundColor Cyan
if ($TaskIdentifier) {
    Write-Host "Tâche à vérifier : $TaskIdentifier" -ForegroundColor Cyan
} else {
    Write-Host "Vérification de toutes les tâches" -ForegroundColor Cyan
}
if ($ActiveDocumentPath) {
    Write-Host "Document actif : $ActiveDocumentPath" -ForegroundColor Cyan
} else {
    Write-Host "Détection automatique du document actif" -ForegroundColor Cyan
}
if ($Force) {
    Write-Host "Mode force activé : les modifications seront appliquées sans confirmation" -ForegroundColor Yellow
} else {
    Write-Host "Mode simulation activé : les modifications ne seront pas appliquées" -ForegroundColor Gray
}

# Exécuter le script check-mode-enhanced.ps1 avec les paramètres
& $scriptPath @params

# Afficher un message de fin
Write-Host "`nExécution du mode CHECK amélioré terminée." -ForegroundColor Cyan
