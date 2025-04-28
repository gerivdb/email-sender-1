<#
.SYNOPSIS
    Script pour exécuter le mode CHECK amélioré et mettre à jour les cases à cocher dans le document actif.
    Version adaptée pour utiliser la configuration unifiée.

.DESCRIPTION
    Ce script est un wrapper pour le mode CHECK amélioré qui vérifie si les tâches sont 100% implémentées
    et testées avec succès, puis met à jour automatiquement les cases à cocher dans le document actif.
    Cette version améliorée garantit que tous les fichiers sont enregistrés en UTF-8 avec BOM et
    utilise le système de configuration unifié.

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
    Chemin vers le fichier de configuration unifiée.
    Par défaut : "development\config\unified-config.json".

.EXAMPLE
    .\check.ps1 -TaskIdentifier "1.2.3"

.EXAMPLE
    .\check.ps1 -TaskIdentifier "1.2.3" -Force

.NOTES
    Auteur: RoadmapParser Team
    Version: 2.0
    Date de création: 2023-09-15
    Date de mise à jour: 2023-06-01 - Adaptation pour utiliser la configuration unifiée
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
    [string]$ConfigPath = "development\config\unified-config.json"
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
$projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
if (-not [System.IO.Path]::IsPathRooted($ConfigPath)) {
    $ConfigPath = Join-Path -Path $projectRoot -ChildPath $ConfigPath
}

# Vérifier que le fichier de configuration existe
if (-not (Test-Path -Path $ConfigPath)) {
    Write-Warning "Le fichier de configuration unifié est introuvable : $ConfigPath"
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
            $ConfigPath = $fullPath
            break
        }
    }

    # Si aucun fichier de configuration n'est trouvé, utiliser le chemin par défaut
    if (-not (Test-Path -Path $ConfigPath)) {
        Write-Warning "Aucun fichier de configuration trouvé. Utilisation du chemin par défaut."
        $ConfigPath = Join-Path -Path $projectRoot -ChildPath "development\config\unified-config.json"
    }
}

# Construire les paramètres pour le script check-mode.ps1
$params = @{
    CheckActiveDocument = $true
}

# Ajouter le chemin de configuration
if ($ConfigPath -and (Test-Path -Path $ConfigPath)) {
    $params.Add("ConfigPath", $ConfigPath)
    Write-Host "Utilisation du fichier de configuration unifié : $ConfigPath" -ForegroundColor Cyan

    # Charger la configuration unifiée pour utiliser ses valeurs
    try {
        $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json

        # Utiliser les valeurs de la configuration si les paramètres ne sont pas spécifiés
        if (-not $FilePath -and $config.Modes.Check.DefaultRoadmapFile) {
            $FilePath = Join-Path -Path $projectRoot -ChildPath $config.Modes.Check.DefaultRoadmapFile
            Write-Host "Utilisation du fichier de roadmap depuis la configuration : $FilePath" -ForegroundColor Cyan
        }

        if (-not $ActiveDocumentPath -and $config.Modes.Check.DefaultActiveDocumentPath) {
            $ActiveDocumentPath = Join-Path -Path $projectRoot -ChildPath $config.Modes.Check.DefaultActiveDocumentPath
            Write-Host "Utilisation du document actif depuis la configuration : $ActiveDocumentPath" -ForegroundColor Cyan
        }
    } catch {
        Write-Warning "Erreur lors du chargement de la configuration : $_"
    }
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
# $projectRoot est déjà défini plus haut

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
        "projet\roadmaps\Roadmap\roadmap_complete_converted.md",
        "docs\plans\roadmap_complete_2.md",
        "docs\development\roadmap\plans\roadmap_complete_2.md",
        "docs\development\roadmap\roadmap_complete_converted.md"
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

    # Si le fichier n'est toujours pas trouvé, utiliser la valeur de la configuration unifiée
    if (-not (Test-Path -Path $FilePath) -and $config -and $config.General.RoadmapPath) {
        $fullPath = Join-Path -Path $projectRoot -ChildPath $config.General.RoadmapPath
        if (Test-Path -Path $fullPath) {
            Write-Host "Fichier de roadmap trouvé dans la configuration unifiée : $fullPath" -ForegroundColor Green
            $FilePath = $fullPath
            $params["FilePath"] = $FilePath
        }
    }
}

# Exécuter le script check-mode.ps1 avec les paramètres
$result = & $scriptPath @params

# Afficher un message de fin
Write-Host "`nExécution du mode CHECK amélioré terminée." -ForegroundColor Cyan

# Retourner le résultat
return $result
