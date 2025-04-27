<#
.SYNOPSIS
    Mode de débogage pour le système de roadmap.
.DESCRIPTION
    Ce script exécute le mode de débogage pour le système de roadmap, permettant d'identifier et de résoudre les problèmes.
.PARAMETER TaskIdentifier
    Identifiant de la tâche à déboguer.
.PARAMETER RoadmapPath
    Chemin vers le fichier de roadmap. Si non spécifié, utilise la valeur de configuration.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration. Par défaut, il s'agit de config.json dans le répertoire config.
.PARAMETER GeneratePatch
    Si spécifié, génère un patch pour corriger les problèmes identifiés.
.PARAMETER IncludeStackTrace
    Si spécifié, inclut la trace de la pile dans les messages d'erreur.
.EXAMPLE
    .\debug-mode.ps1 -TaskIdentifier "1.1"
    Exécute le mode de débogage pour la tâche 1.1.
.EXAMPLE
    .\debug-mode.ps1 -TaskIdentifier "1.1" -RoadmapPath "chemin/vers/roadmap.md" -GeneratePatch
    Exécute le mode de débogage pour la tâche 1.1 avec un chemin de roadmap personnalisé et génère un patch.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$TaskIdentifier,
    
    [Parameter()]
    [string]$RoadmapPath,
    
    [Parameter()]
    [string]$ConfigPath = "$PSScriptRoot\..\..\config\config.json",
    
    [Parameter()]
    [switch]$GeneratePatch,
    
    [Parameter()]
    [switch]$IncludeStackTrace
)

# Définir le chemin du script et des modules
$scriptPath = $PSScriptRoot
$modulePath = "$PSScriptRoot\..\..\module\Functions"
$configFunctionsPath = "$modulePath\Private\Configuration"
$encodingFunctionsPath = "$modulePath\Private\Encoding"
$publicFunctionsPath = "$modulePath\Public"

# Afficher les informations de débogage
Write-Host "Exécution du mode DEBUG..." -ForegroundColor Cyan
Write-Host "Tâche à déboguer : $TaskIdentifier" -ForegroundColor Cyan
Write-Host "Chemin du script : $scriptPath" -ForegroundColor Cyan
Write-Host "Chemin du module : $modulePath" -ForegroundColor Cyan
Write-Host "Chemin des fonctions de configuration : $configFunctionsPath" -ForegroundColor Cyan
Write-Host "Chemin des fonctions d'encodage : $encodingFunctionsPath" -ForegroundColor Cyan
Write-Host "Chemin des fonctions publiques : $publicFunctionsPath" -ForegroundColor Cyan

# Importer les fonctions de configuration
try {
    . "$configFunctionsPath\Initialize-Configuration.ps1"
    Write-Host "Fonction Initialize-Configuration importée." -ForegroundColor Green
    
    . "$configFunctionsPath\Get-Configuration.ps1"
    Write-Host "Fonction Get-Configuration importée." -ForegroundColor Green
    
    . "$configFunctionsPath\Test-Configuration.ps1"
    Write-Host "Fonction Test-Configuration importée." -ForegroundColor Green
    
    . "$configFunctionsPath\Set-DefaultConfiguration.ps1"
    Write-Host "Fonction Set-DefaultConfiguration importée." -ForegroundColor Green
} catch {
    Write-Warning "Erreur lors du chargement des fonctions de configuration : $_"
    Write-Warning "Utilisation des paramètres par défaut."
}

# Importer les fonctions d'encodage
try {
    Get-ChildItem -Path $encodingFunctionsPath -Filter "*.ps1" | ForEach-Object {
        . $_.FullName
    }
    Write-Host "Fonctions d'encodage importées." -ForegroundColor Green
} catch {
    Write-Warning "Erreur lors du chargement des fonctions d'encodage : $_"
}

# Importer la fonction Invoke-RoadmapDebug
try {
    . "$publicFunctionsPath\Invoke-RoadmapDebug.ps1"
    Write-Host "Fonction Invoke-RoadmapDebug importée." -ForegroundColor Green
} catch {
    Write-Error "Erreur lors du chargement de la fonction Invoke-RoadmapDebug : $_"
    exit 1
}

# Charger la configuration
try {
    $config = Get-Configuration -ConfigPath $ConfigPath -ApplyDefaults
    Write-Host "Configuration chargée." -ForegroundColor Green
    
    # Utiliser le chemin de roadmap spécifié ou celui de la configuration
    if (-not $RoadmapPath) {
        $RoadmapPath = $config.General.RoadmapPath
        Write-Host "Fichier de roadmap : Utilisation de la valeur de configuration" -ForegroundColor Cyan
    } else {
        Write-Host "Fichier de roadmap : $RoadmapPath" -ForegroundColor Cyan
    }
} catch {
    Write-Warning "Erreur lors du chargement de la configuration : $_"
    Write-Warning "Utilisation des paramètres par défaut."
    
    # Définir des valeurs par défaut si la configuration ne peut pas être chargée
    if (-not $RoadmapPath) {
        $RoadmapPath = "Roadmap\roadmap_complete_converted.md"
        Write-Host "Fichier de roadmap : Utilisation de la valeur par défaut" -ForegroundColor Yellow
    } else {
        Write-Host "Fichier de roadmap : $RoadmapPath" -ForegroundColor Cyan
    }
}

# Exécuter le mode de débogage
try {
    $params = @{
        TaskIdentifier = $TaskIdentifier
        RoadmapPath = $RoadmapPath
    }
    
    if ($GeneratePatch) {
        $params.Add("GeneratePatch", $true)
    }
    
    if ($IncludeStackTrace) {
        $params.Add("IncludeStackTrace", $true)
    }
    
    $result = Invoke-RoadmapDebug @params
    
    if ($result.Success) {
        Write-Host "Débogage terminé avec succès." -ForegroundColor Green
        
        if ($result.Patch) {
            Write-Host "Patch généré :" -ForegroundColor Cyan
            Write-Host $result.Patch -ForegroundColor Yellow
        }
    } else {
        Write-Host "Débogage terminé avec des erreurs." -ForegroundColor Red
        Write-Host "Erreurs :" -ForegroundColor Red
        foreach ($error in $result.Errors) {
            Write-Host "  - $error" -ForegroundColor Red
        }
    }
} catch {
    Write-Error "Erreur lors de l'exécution du mode de débogage : $_"
    if ($IncludeStackTrace) {
        Write-Error $_.ScriptStackTrace
    }
    exit 1
}
