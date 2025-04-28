<#
.SYNOPSIS
    Script pour exécuter le mode CHECK amélioré et mettre à jour les cases à cocher dans le document actif.

.DESCRIPTION
    Ce script est un wrapper pour le mode CHECK amélioré qui vérifie si les tâches sont 100% implémentées
    et testées avec succès, puis met à jour automatiquement les cases à cocher dans le document actif.
    Cette version améliorée garantit que tous les fichiers sont enregistrés en UTF-8 avec BOM et
    utilise un système de configuration centralisé.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap à vérifier.
    Si non spécifié, la valeur sera récupérée depuis la configuration.

.PARAMETER TaskIdentifier
    Identifiant de la tâche à vérifier (par exemple, "1.2.3").
    Si non spécifié, toutes les tâches seront vérifiées.

.PARAMETER ActiveDocumentPath
    Chemin vers le document actif à mettre à jour.
    Si non spécifié, le script tentera de détecter automatiquement le document actif.

.PARAMETER Force
    Indique si les modifications doivent être appliquées sans confirmation.
    Par défaut : $false (mode simulation).

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration.
    Par défaut : config.json dans le répertoire config.

.EXAMPLE
    .\check.ps1 -TaskIdentifier "1.2.3"

.EXAMPLE
    .\check.ps1 -TaskIdentifier "1.2.3" -Force

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.2
    Date de création: 2023-09-15
    Date de mise à jour: 2025-05-01 - Amélioration de l'encodage UTF-8 avec BOM et système de configuration
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false)]
    [string]$ActiveDocumentPath,

    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath
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

# Si la version améliorée n'est pas trouvée, essayer la version standard
if (-not (Test-Path -Path $scriptPath)) {
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "roadmap-parser\modes\check\check-mode.ps1"

    if (Test-Path -Path $scriptPath) {
        Write-Warning "La version améliorée du mode CHECK n'a pas été trouvée. Utilisation de la version standard."
    }
}

# Vérifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    Write-Error "Le script check-mode-enhanced.ps1 ou check-mode.ps1 est introuvable."
    exit 1
}

# Déterminer le chemin de configuration
if (-not $ConfigPath) {
    $ConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "roadmap-parser\config\config.json"
    
    # Si le chemin n'existe pas, essayer un autre chemin
    if (-not (Test-Path -Path $ConfigPath)) {
        $ConfigPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "roadmap-parser\config\config.json"
    }
}

# Construire les paramètres pour le script check-mode.ps1
$params = @{
    CheckActiveDocument = $true
}

# Ajouter le chemin de configuration
if ($ConfigPath -and (Test-Path -Path $ConfigPath)) {
    $params.Add("ConfigPath", $ConfigPath)
    Write-Host "Utilisation du fichier de configuration : $ConfigPath" -ForegroundColor Cyan
}

# Ajouter les paramètres optionnels s'ils sont spécifiés
if ($FilePath) {
    $params.Add("FilePath", $FilePath)
}

if ($TaskIdentifier) {
    $params.Add("TaskIdentifier", $TaskIdentifier)
}

if ($ActiveDocumentPath) {
    $params.Add("ActiveDocumentPath", $ActiveDocumentPath)
}

if ($Force) {
    $params.Add("Force", $true)
}

# Convertir les chemins relatifs en chemins absolus
$projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

if ($FilePath -and -not [System.IO.Path]::IsPathRooted($FilePath)) {
    $FilePath = Join-Path -Path $projectRoot -ChildPath $FilePath
    $params["FilePath"] = $FilePath
}

if ($ActiveDocumentPath -and -not [System.IO.Path]::IsPathRooted($ActiveDocumentPath)) {
    $ActiveDocumentPath = Join-Path -Path $projectRoot -ChildPath $ActiveDocumentPath
    $params["ActiveDocumentPath"] = $ActiveDocumentPath
}

# Afficher les informations de démarrage
Write-Host "Exécution du mode CHECK amélioré..." -ForegroundColor Cyan

if ($FilePath) {
    Write-Host "Fichier de roadmap : $FilePath" -ForegroundColor Cyan
} else {
    Write-Host "Fichier de roadmap : Utilisation de la valeur de configuration" -ForegroundColor Cyan
}

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

# Vérifier si le fichier de roadmap existe
if ($FilePath -and -not (Test-Path -Path $FilePath)) {
    # Essayer de trouver le fichier de roadmap
    $possiblePaths = @(
        "docs\development\roadmap\roadmap_complete_converted.md",
        "docs\plans\roadmap_complete_2.md",
        "docs\development\roadmap\plans\roadmap_complete_2.md"
    )
    
    foreach ($path in $possiblePaths) {
        $fullPath = Join-Path -Path $projectRoot -ChildPath $path
        if (Test-Path -Path $fullPath) {
            Write-Host "Fichier de roadmap trouvé à l'emplacement : $fullPath" -ForegroundColor Green
            $FilePath = $fullPath
            $params["FilePath"] = $FilePath
            break
        }
    }
}

# Exécuter le script check-mode.ps1 avec les paramètres
& $scriptPath @params

# Afficher un message de fin
Write-Host "`nExécution du mode CHECK amélioré terminée." -ForegroundColor Cyan
