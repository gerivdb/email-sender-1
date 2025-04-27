<#
.SYNOPSIS
    Mode de livraison du roadmap (DEV-R) pour implémenter les tâches du roadmap.
.DESCRIPTION
    Ce script exécute le mode de livraison du roadmap (DEV-R) pour implémenter les tâches du roadmap,
    permettant de développer et tester les fonctionnalités de manière progressive.
.PARAMETER TaskIdentifier
    Identifiant de la tâche à implémenter.
.PARAMETER RoadmapPath
    Chemin vers le fichier de roadmap. Si non spécifié, utilise la valeur de configuration.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration. Par défaut, il s'agit de config.json dans le répertoire config.
.PARAMETER OutputPath
    Chemin vers le répertoire de sortie pour les fichiers générés.
.PARAMETER TestsPath
    Chemin vers le répertoire des tests.
.PARAMETER Force
    Si spécifié, force l'exécution sans demander de confirmation.
.EXAMPLE
    .\dev-r-mode.ps1 -TaskIdentifier "1.1"
    Exécute le mode de livraison du roadmap pour la tâche 1.1.
.EXAMPLE
    .\dev-r-mode.ps1 -TaskIdentifier "1.1" -RoadmapPath "chemin/vers/roadmap.md" -Force
    Exécute le mode de livraison du roadmap pour la tâche 1.1 avec un chemin de roadmap personnalisé et sans demander de confirmation.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory = $true)]
    [string]$TaskIdentifier,
    
    [Parameter()]
    [string]$RoadmapPath,
    
    [Parameter()]
    [string]$ConfigPath = "$PSScriptRoot\scripts\roadmap-parser\config\config.json",
    
    [Parameter()]
    [string]$OutputPath,
    
    [Parameter()]
    [string]$TestsPath,
    
    [Parameter()]
    [switch]$Force
)

# Définir le chemin du script et des modules
$scriptPath = $PSScriptRoot
$modulePath = "$PSScriptRoot\scripts\roadmap-parser\module\Functions"
$configFunctionsPath = "$modulePath\Private\Configuration"
$publicFunctionsPath = "$PSScriptRoot\scripts\roadmap-parser\Functions\Public"

# Afficher les informations de démarrage
Write-Host "Exécution du mode DEV-R (Roadmap Delivery)..." -ForegroundColor Cyan
Write-Host "Tâche à implémenter : $TaskIdentifier" -ForegroundColor Cyan
Write-Host "Chemin du script : $scriptPath" -ForegroundColor Cyan
Write-Host "Chemin du module : $modulePath" -ForegroundColor Cyan
Write-Host "Chemin des fonctions de configuration : $configFunctionsPath" -ForegroundColor Cyan
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

# Importer la fonction Invoke-RoadmapDelivery
try {
    . "$publicFunctionsPath\Invoke-RoadmapDelivery.ps1"
    Write-Host "Fonction Invoke-RoadmapDelivery importée." -ForegroundColor Green
} catch {
    Write-Error "Erreur lors du chargement de la fonction Invoke-RoadmapDelivery : $_"
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
    
    # Utiliser les chemins de sortie et de tests spécifiés ou ceux de la configuration
    if (-not $OutputPath) {
        $OutputPath = $config.General.OutputPath
        Write-Host "Répertoire de sortie : Utilisation de la valeur de configuration" -ForegroundColor Cyan
    } else {
        Write-Host "Répertoire de sortie : $OutputPath" -ForegroundColor Cyan
    }
    
    if (-not $TestsPath) {
        $TestsPath = $config.General.TestsPath
        Write-Host "Répertoire des tests : Utilisation de la valeur de configuration" -ForegroundColor Cyan
    } else {
        Write-Host "Répertoire des tests : $TestsPath" -ForegroundColor Cyan
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
    
    if (-not $OutputPath) {
        $OutputPath = "output"
        Write-Host "Répertoire de sortie : Utilisation de la valeur par défaut" -ForegroundColor Yellow
    } else {
        Write-Host "Répertoire de sortie : $OutputPath" -ForegroundColor Cyan
    }
    
    if (-not $TestsPath) {
        $TestsPath = "tests"
        Write-Host "Répertoire des tests : Utilisation de la valeur par défaut" -ForegroundColor Yellow
    } else {
        Write-Host "Répertoire des tests : $TestsPath" -ForegroundColor Cyan
    }
}

# Exécuter le mode de livraison du roadmap
try {
    $params = @{
        TaskIdentifier = $TaskIdentifier
        RoadmapPath = $RoadmapPath
        OutputPath = $OutputPath
        TestsPath = $TestsPath
    }
    
    if ($Force) {
        $params.Add("Force", $true)
    }
    
    $result = Invoke-RoadmapDelivery @params
    
    if ($result.Success) {
        Write-Host "Livraison terminée avec succès." -ForegroundColor Green
        
        Write-Host "Fichiers implémentés :" -ForegroundColor Cyan
        foreach ($file in $result.ImplementedFiles) {
            Write-Host "  - $file" -ForegroundColor Cyan
        }
        
        Write-Host "Fichiers de test :" -ForegroundColor Cyan
        foreach ($file in $result.TestFiles) {
            Write-Host "  - $file" -ForegroundColor Cyan
        }
        
        # Exécuter les tests
        Write-Host "Exécution des tests..." -ForegroundColor Cyan
        
        if (Get-Module -Name Pester -ListAvailable) {
            $testResults = Invoke-Pester -Path $result.TestFiles -PassThru
            
            if ($testResults.FailedCount -eq 0) {
                Write-Host "Tous les tests ont réussi." -ForegroundColor Green
            } else {
                Write-Host "Certains tests ont échoué. Veuillez vérifier les résultats." -ForegroundColor Red
            }
        } else {
            Write-Warning "Le module Pester n'est pas installé. Les tests n'ont pas été exécutés."
            Write-Warning "Pour installer Pester, exécutez : Install-Module -Name Pester -Force -SkipPublisherCheck"
        }
    } else {
        Write-Host "Livraison terminée avec des erreurs." -ForegroundColor Red
        Write-Host "Erreurs :" -ForegroundColor Red
        foreach ($error in $result.Errors) {
            Write-Host "  - $error" -ForegroundColor Red
        }
    }
} catch {
    Write-Error "Erreur lors de l'exécution du mode de livraison du roadmap : $_"
    exit 1
}
