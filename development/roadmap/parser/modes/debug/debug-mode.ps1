<#
.SYNOPSIS
    Mode de dÃ©bogage pour le systÃ¨me de roadmap.
.DESCRIPTION
    Ce script exÃ©cute le mode de dÃ©bogage pour le systÃ¨me de roadmap, permettant d'identifier et de rÃ©soudre les problÃ¨mes.
.PARAMETER TaskIdentifier
    Identifiant de la tÃ¢che Ã  dÃ©boguer.
.PARAMETER RoadmapPath
    Chemin vers le fichier de roadmap. Si non spÃ©cifiÃ©, utilise la valeur de configuration.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration. Par dÃ©faut, il s'agit de config.json dans le rÃ©pertoire config.
.PARAMETER GeneratePatch
    Si spÃ©cifiÃ©, gÃ©nÃ¨re un patch pour corriger les problÃ¨mes identifiÃ©s.
.PARAMETER IncludeStackTrace
    Si spÃ©cifiÃ©, inclut la trace de la pile dans les messages d'erreur.
.EXAMPLE
    .\debug-mode.ps1 -TaskIdentifier "1.1"
    ExÃ©cute le mode de dÃ©bogage pour la tÃ¢che 1.1.
.EXAMPLE
    .\debug-mode.ps1 -TaskIdentifier "1.1" -RoadmapPath "chemin/vers/roadmap.md" -GeneratePatch
    ExÃ©cute le mode de dÃ©bogage pour la tÃ¢che 1.1 avec un chemin de roadmap personnalisÃ© et gÃ©nÃ¨re un patch.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$TaskIdentifier,
    
    [Parameter()]
    [string]$RoadmapPath,
    
    [Parameter()]
    [string]$ConfigPath = "$PSScriptRoot\..\..\projet\config\config.json",
    
    [Parameter()]
    [switch]$GeneratePatch,
    
    [Parameter()]
    [switch]$IncludeStackTrace
)

# DÃ©finir le chemin du script et des modules
$scriptPath = $PSScriptRoot
$modulePath = "$PSScriptRoot\..\..\module\Functions"
$configFunctionsPath = "$modulePath\Private\Configuration"
$encodingFunctionsPath = "$modulePath\Private\Encoding"
$publicFunctionsPath = "$modulePath\Public"

# Afficher les informations de dÃ©bogage
Write-Host "ExÃ©cution du mode DEBUG..." -ForegroundColor Cyan
Write-Host "TÃ¢che Ã  dÃ©boguer : $TaskIdentifier" -ForegroundColor Cyan
Write-Host "Chemin du script : $scriptPath" -ForegroundColor Cyan
Write-Host "Chemin du module : $modulePath" -ForegroundColor Cyan
Write-Host "Chemin des fonctions de configuration : $configFunctionsPath" -ForegroundColor Cyan
Write-Host "Chemin des fonctions d'encodage : $encodingFunctionsPath" -ForegroundColor Cyan
Write-Host "Chemin des fonctions publiques : $publicFunctionsPath" -ForegroundColor Cyan

# Importer les fonctions de configuration
try {
    . "$configFunctionsPath\Initialize-Configuration.ps1"
    Write-Host "Fonction Initialize-Configuration importÃ©e." -ForegroundColor Green
    
    . "$configFunctionsPath\Get-Configuration.ps1"
    Write-Host "Fonction Get-Configuration importÃ©e." -ForegroundColor Green
    
    . "$configFunctionsPath\Test-Configuration.ps1"
    Write-Host "Fonction Test-Configuration importÃ©e." -ForegroundColor Green
    
    . "$configFunctionsPath\Set-DefaultConfiguration.ps1"
    Write-Host "Fonction Set-DefaultConfiguration importÃ©e." -ForegroundColor Green
} catch {
    Write-Warning "Erreur lors du chargement des fonctions de configuration : $_"
    Write-Warning "Utilisation des paramÃ¨tres par dÃ©faut."
}

# Importer les fonctions d'encodage
try {
    Get-ChildItem -Path $encodingFunctionsPath -Filter "*.ps1" | ForEach-Object {
        . $_.FullName
    }
    Write-Host "Fonctions d'encodage importÃ©es." -ForegroundColor Green
} catch {
    Write-Warning "Erreur lors du chargement des fonctions d'encodage : $_"
}

# Importer la fonction Invoke-RoadmapDebug
try {
    . "$publicFunctionsPath\Invoke-RoadmapDebug.ps1"
    Write-Host "Fonction Invoke-RoadmapDebug importÃ©e." -ForegroundColor Green
} catch {
    Write-Error "Erreur lors du chargement de la fonction Invoke-RoadmapDebug : $_"
    exit 1
}

# Charger la configuration
try {
    $config = Get-Configuration -ConfigPath $ConfigPath -ApplyDefaults
    Write-Host "Configuration chargÃ©e." -ForegroundColor Green
    
    # Utiliser le chemin de roadmap spÃ©cifiÃ© ou celui de la configuration
    if (-not $RoadmapPath) {
        $RoadmapPath = $config.General.RoadmapPath
        Write-Host "Fichier de roadmap : Utilisation de la valeur de configuration" -ForegroundColor Cyan
    } else {
        Write-Host "Fichier de roadmap : $RoadmapPath" -ForegroundColor Cyan
    }
} catch {
    Write-Warning "Erreur lors du chargement de la configuration : $_"
    Write-Warning "Utilisation des paramÃ¨tres par dÃ©faut."
    
    # DÃ©finir des valeurs par dÃ©faut si la configuration ne peut pas Ãªtre chargÃ©e
    if (-not $RoadmapPath) {
        $RoadmapPath = "Roadmap\roadmap_complete_converted.md"
        Write-Host "Fichier de roadmap : Utilisation de la valeur par dÃ©faut" -ForegroundColor Yellow
    } else {
        Write-Host "Fichier de roadmap : $RoadmapPath" -ForegroundColor Cyan
    }
}

# ExÃ©cuter le mode de dÃ©bogage
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
        Write-Host "DÃ©bogage terminÃ© avec succÃ¨s." -ForegroundColor Green
        
        if ($result.Patch) {
            Write-Host "Patch gÃ©nÃ©rÃ© :" -ForegroundColor Cyan
            Write-Host $result.Patch -ForegroundColor Yellow
        }
    } else {
        Write-Host "DÃ©bogage terminÃ© avec des erreurs." -ForegroundColor Red
        Write-Host "Erreurs :" -ForegroundColor Red
        foreach ($error in $result.Errors) {
            Write-Host "  - $error" -ForegroundColor Red
        }
    }
} catch {
    Write-Error "Erreur lors de l'exÃ©cution du mode de dÃ©bogage : $_"
    if ($IncludeStackTrace) {
        Write-Error $_.ScriptStackTrace
    }
    exit 1
}
