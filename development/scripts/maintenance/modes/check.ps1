<#
.SYNOPSIS
    Script pour exÃ©cuter le mode CHECK amÃ©liorÃ© et mettre Ã  jour les cases Ã  cocher dans le document actif.
    Version adaptÃ©e pour utiliser la configuration unifiÃ©e.

.DESCRIPTION
    Ce script est un wrapper pour le mode CHECK amÃ©liorÃ© qui vÃ©rifie si les tÃ¢ches sont 100% implÃ©mentÃ©es
    et testÃ©es avec succÃ¨s, puis met Ã  jour automatiquement les cases Ã  cocher dans le document actif.
    Cette version amÃ©liorÃ©e garantit que tous les fichiers sont enregistrÃ©s en UTF-8 avec BOM et
    utilise le systÃ¨me de configuration unifiÃ©.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap Ã  vÃ©rifier.
    Si non spÃ©cifiÃ©, la valeur sera rÃ©cupÃ©rÃ©e depuis la configuration.

.PARAMETER TaskIdentifier
    Identifiant de la tÃ¢che Ã  vÃ©rifier (par exemple, "1.2.3").
    Si non spÃ©cifiÃ©, toutes les tÃ¢ches seront vÃ©rifiÃ©es.

.PARAMETER ActiveDocumentPath
    Chemin vers le document actif Ã  mettre Ã  jour.
    Si non spÃ©cifiÃ©, le script tentera de dÃ©tecter automatiquement le document actif.

.PARAMETER Force
    Indique si les modifications doivent Ãªtre appliquÃ©es sans confirmation.
    Par dÃ©faut : $false (mode simulation).

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration unifiÃ©e.
    Par dÃ©faut : "development\config\unified-config.json".

.EXAMPLE
    .\check.ps1 -TaskIdentifier "1.2.3"

.EXAMPLE
    .\check.ps1 -TaskIdentifier "1.2.3" -Force

.NOTES
    Auteur: RoadmapParser Team
    Version: 2.0
    Date de crÃ©ation: 2023-09-15
    Date de mise Ã  jour: 2023-06-01 - Adaptation pour utiliser la configuration unifiÃ©e
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

# DÃ©terminer le chemin du script check-mode-enhanced.ps1
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

# DÃ©terminer le chemin de configuration
$projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
if (-not [System.IO.Path]::IsPathRooted($ConfigPath)) {
    $ConfigPath = Join-Path -Path $projectRoot -ChildPath $ConfigPath
}

# VÃ©rifier que le fichier de configuration existe
if (-not (Test-Path -Path $ConfigPath)) {
    Write-Warning "Le fichier de configuration unifiÃ© est introuvable : $ConfigPath"
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
            Write-Host "Fichier de configuration trouvÃ© Ã  l'emplacement : $fullPath" -ForegroundColor Green
            $ConfigPath = $fullPath
            break
        }
    }

    # Si aucun fichier de configuration n'est trouvÃ©, utiliser le chemin par dÃ©faut
    if (-not (Test-Path -Path $ConfigPath)) {
        Write-Warning "Aucun fichier de configuration trouvÃ©. Utilisation du chemin par dÃ©faut."
        $ConfigPath = Join-Path -Path $projectRoot -ChildPath "development\config\unified-config.json"
    }
}

# Construire les paramÃ¨tres pour le script check-mode.ps1
$params = @{
    CheckActiveDocument = $true
}

# Ajouter le chemin de configuration
if ($ConfigPath -and (Test-Path -Path $ConfigPath)) {
    $params.Add("ConfigPath", $ConfigPath)
    Write-Host "Utilisation du fichier de configuration unifiÃ© : $ConfigPath" -ForegroundColor Cyan

    # Charger la configuration unifiÃ©e pour utiliser ses valeurs
    try {
        $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json

        # Utiliser les valeurs de la configuration si les paramÃ¨tres ne sont pas spÃ©cifiÃ©s
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

# Ajouter les paramÃ¨tres optionnels s'ils sont spÃ©cifiÃ©s
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
# $projectRoot est dÃ©jÃ  dÃ©fini plus haut

if ($FilePath -and -not [System.IO.Path]::IsPathRooted($FilePath)) {
    $FilePath = Join-Path -Path $projectRoot -ChildPath $FilePath
    $params["FilePath"] = $FilePath
}

if ($ActiveDocumentPath -and -not [System.IO.Path]::IsPathRooted($ActiveDocumentPath)) {
    $ActiveDocumentPath = Join-Path -Path $projectRoot -ChildPath $ActiveDocumentPath
    $params["ActiveDocumentPath"] = $ActiveDocumentPath
}

# Afficher les informations de dÃ©marrage
Write-Host "ExÃ©cution du mode CHECK amÃ©liorÃ©..." -ForegroundColor Cyan

if ($FilePath) {
    Write-Host "Fichier de roadmap : $FilePath" -ForegroundColor Cyan
} else {
    Write-Host "Fichier de roadmap : Utilisation de la valeur de configuration" -ForegroundColor Cyan
}

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

# VÃ©rifier si le fichier de roadmap existe
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
            Write-Host "Fichier de roadmap trouvÃ© Ã  l'emplacement : $fullPath" -ForegroundColor Green
            $FilePath = $fullPath
            $params["FilePath"] = $FilePath
            break
        }
    }

    # Si le fichier n'est toujours pas trouvÃ©, utiliser la valeur de la configuration unifiÃ©e
    if (-not (Test-Path -Path $FilePath) -and $config -and $config.General.RoadmapPath) {
        $fullPath = Join-Path -Path $projectRoot -ChildPath $config.General.RoadmapPath
        if (Test-Path -Path $fullPath) {
            Write-Host "Fichier de roadmap trouvÃ© dans la configuration unifiÃ©e : $fullPath" -ForegroundColor Green
            $FilePath = $fullPath
            $params["FilePath"] = $FilePath
        }
    }
}

# ExÃ©cuter le script check-mode.ps1 avec les paramÃ¨tres
$result = & $scriptPath @params

# Afficher un message de fin
Write-Host "`nExÃ©cution du mode CHECK amÃ©liorÃ© terminÃ©e." -ForegroundColor Cyan

# Retourner le rÃ©sultat
return $result
