<#
.SYNOPSIS
    Mode de livraison du roadmap (DEV-R) pour implÃ©menter les tÃ¢ches du roadmap.
.DESCRIPTION
    Ce script exÃ©cute le mode de livraison du roadmap (DEV-R) pour implÃ©menter les tÃ¢ches du roadmap,
    permettant de dÃ©velopper et tester les fonctionnalitÃ©s de maniÃ¨re progressive.
.PARAMETER TaskIdentifier
    Identifiant de la tÃ¢che Ã  implÃ©menter.
.PARAMETER RoadmapPath
    Chemin vers le fichier de roadmap. Si non spÃ©cifiÃ©, utilise la valeur de configuration.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration. Par dÃ©faut, il s'agit de config.json dans le rÃ©pertoire config.
.PARAMETER OutputPath
    Chemin vers le rÃ©pertoire de sortie pour les fichiers gÃ©nÃ©rÃ©s.
.PARAMETER TestsPath
    Chemin vers le rÃ©pertoire des tests.
.PARAMETER Force
    Si spÃ©cifiÃ©, force l'exÃ©cution sans demander de confirmation.
.EXAMPLE
    .\dev-r-mode.ps1 -TaskIdentifier "1.1"
    ExÃ©cute le mode de livraison du roadmap pour la tÃ¢che 1.1.
.EXAMPLE
    .\dev-r-mode.ps1 -TaskIdentifier "1.1" -RoadmapPath "chemin/vers/roadmap.md" -Force
    ExÃ©cute le mode de livraison du roadmap pour la tÃ¢che 1.1 avec un chemin de roadmap personnalisÃ© et sans demander de confirmation.
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

# DÃ©finir le chemin du script et des modules
$scriptPath = $PSScriptRoot
$modulePath = "$PSScriptRoot\scripts\roadmap-parser\module\Functions"
$configFunctionsPath = "$modulePath\Private\Configuration"
$publicFunctionsPath = "$PSScriptRoot\scripts\roadmap-parser\Functions\Public"

# Afficher les informations de dÃ©marrage
Write-Host "ExÃ©cution du mode DEV-R (Roadmap Delivery)..." -ForegroundColor Cyan
Write-Host "TÃ¢che Ã  implÃ©menter : $TaskIdentifier" -ForegroundColor Cyan
Write-Host "Chemin du script : $scriptPath" -ForegroundColor Cyan
Write-Host "Chemin du module : $modulePath" -ForegroundColor Cyan
Write-Host "Chemin des fonctions de configuration : $configFunctionsPath" -ForegroundColor Cyan
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

# Importer la fonction Invoke-RoadmapDelivery
try {
    . "$publicFunctionsPath\Invoke-RoadmapDelivery.ps1"
    Write-Host "Fonction Invoke-RoadmapDelivery importÃ©e." -ForegroundColor Green
} catch {
    Write-Error "Erreur lors du chargement de la fonction Invoke-RoadmapDelivery : $_"
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
    
    # Utiliser les chemins de sortie et de tests spÃ©cifiÃ©s ou ceux de la configuration
    if (-not $OutputPath) {
        $OutputPath = $config.General.OutputPath
        Write-Host "RÃ©pertoire de sortie : Utilisation de la valeur de configuration" -ForegroundColor Cyan
    } else {
        Write-Host "RÃ©pertoire de sortie : $OutputPath" -ForegroundColor Cyan
    }
    
    if (-not $TestsPath) {
        $TestsPath = $config.General.TestsPath
        Write-Host "RÃ©pertoire des tests : Utilisation de la valeur de configuration" -ForegroundColor Cyan
    } else {
        Write-Host "RÃ©pertoire des tests : $TestsPath" -ForegroundColor Cyan
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
    
    if (-not $OutputPath) {
        $OutputPath = "output"
        Write-Host "RÃ©pertoire de sortie : Utilisation de la valeur par dÃ©faut" -ForegroundColor Yellow
    } else {
        Write-Host "RÃ©pertoire de sortie : $OutputPath" -ForegroundColor Cyan
    }
    
    if (-not $TestsPath) {
        $TestsPath = "tests"
        Write-Host "RÃ©pertoire des tests : Utilisation de la valeur par dÃ©faut" -ForegroundColor Yellow
    } else {
        Write-Host "RÃ©pertoire des tests : $TestsPath" -ForegroundColor Cyan
    }
}

# ExÃ©cuter le mode de livraison du roadmap
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
        Write-Host "Livraison terminÃ©e avec succÃ¨s." -ForegroundColor Green
        
        Write-Host "Fichiers implÃ©mentÃ©s :" -ForegroundColor Cyan
        foreach ($file in $result.ImplementedFiles) {
            Write-Host "  - $file" -ForegroundColor Cyan
        }
        
        Write-Host "Fichiers de test :" -ForegroundColor Cyan
        foreach ($file in $result.TestFiles) {
            Write-Host "  - $file" -ForegroundColor Cyan
        }
        
        # ExÃ©cuter les tests
        Write-Host "ExÃ©cution des tests..." -ForegroundColor Cyan
        
        if (Get-Module -Name Pester -ListAvailable) {
            $testResults = Invoke-Pester -Path $result.TestFiles -PassThru
            
            if ($testResults.FailedCount -eq 0) {
                Write-Host "Tous les tests ont rÃ©ussi." -ForegroundColor Green
            } else {
                Write-Host "Certains tests ont Ã©chouÃ©. Veuillez vÃ©rifier les rÃ©sultats." -ForegroundColor Red
            }
        } else {
            Write-Warning "Le module Pester n'est pas installÃ©. Les tests n'ont pas Ã©tÃ© exÃ©cutÃ©s."
            Write-Warning "Pour installer Pester, exÃ©cutez : Install-Module -Name Pester -Force -SkipPublisherCheck"
        }
    } else {
        Write-Host "Livraison terminÃ©e avec des erreurs." -ForegroundColor Red
        Write-Host "Erreurs :" -ForegroundColor Red
        foreach ($error in $result.Errors) {
            Write-Host "  - $error" -ForegroundColor Red
        }
    }
} catch {
    Write-Error "Erreur lors de l'exÃ©cution du mode de livraison du roadmap : $_"
    exit 1
}
