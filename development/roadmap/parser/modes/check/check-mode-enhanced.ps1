<#
.SYNOPSIS
    Script pour vÃƒÂ©rifier si les tÃƒÂ¢ches sÃƒÂ©lectionnÃƒÂ©es ont ÃƒÂ©tÃƒÂ© implÃƒÂ©mentÃƒÂ©es ÃƒÂ  100% et testÃƒÂ©es avec succÃƒÂ¨s ÃƒÂ  100% (Mode CHECK).
    Version amÃƒÂ©liorÃƒÂ©e avec support UTF-8 avec BOM et systÃƒÂ¨me de configuration.

.DESCRIPTION
    Ce script permet de vÃƒÂ©rifier si les tÃƒÂ¢ches sÃƒÂ©lectionnÃƒÂ©es ont ÃƒÂ©tÃƒÂ© implÃƒÂ©mentÃƒÂ©es ÃƒÂ  100% et testÃƒÂ©es
    avec succÃƒÂ¨s ÃƒÂ  100%. Si c'est le cas, il peut mettre ÃƒÂ  jour automatiquement le statut des tÃƒÂ¢ches
    dans la roadmap en cochant les cases correspondantes. Il implÃƒÂ©mente le mode CHECK dÃƒÂ©crit dans
    la documentation des modes de fonctionnement.
    Cette version amÃƒÂ©liorÃƒÂ©e garantit que tous les fichiers sont enregistrÃƒÂ©s en UTF-8 avec BOM et
    utilise un systÃƒÂ¨me de configuration centralisÃƒÂ©.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap ÃƒÂ  vÃƒÂ©rifier et mettre ÃƒÂ  jour.
    Si non spÃƒÂ©cifiÃƒÂ©, la valeur sera rÃƒÂ©cupÃƒÂ©rÃƒÂ©e depuis la configuration.

.PARAMETER TaskIdentifier
    Identifiant de la tÃƒÂ¢che ÃƒÂ  vÃƒÂ©rifier (par exemple, "1.2.1.3.2.3").
    Si non spÃƒÂ©cifiÃƒÂ©, l'utilisateur sera invitÃƒÂ© ÃƒÂ  le saisir.

.PARAMETER ImplementationPath
    Chemin vers le rÃƒÂ©pertoire contenant l'implÃƒÂ©mentation.
    Si non spÃƒÂ©cifiÃƒÂ©, le script tentera de le dÃƒÂ©duire automatiquement.

.PARAMETER TestsPath
    Chemin vers le rÃƒÂ©pertoire contenant les tests.
    Si non spÃƒÂ©cifiÃƒÂ©, le script tentera de le dÃƒÂ©duire automatiquement.

.PARAMETER UpdateRoadmap
    Indique si la roadmap doit ÃƒÂªtre mise ÃƒÂ  jour automatiquement.
    Par dÃƒÂ©faut : valeur de la configuration ou $true.

.PARAMETER GenerateReport
    Indique si un rapport doit ÃƒÂªtre gÃƒÂ©nÃƒÂ©rÃƒÂ©.
    Par dÃƒÂ©faut : $true.

.PARAMETER ActiveDocumentPath
    Chemin vers le document actif ÃƒÂ  vÃƒÂ©rifier et mettre ÃƒÂ  jour.
    Si non spÃƒÂ©cifiÃƒÂ©, le script tentera de dÃƒÂ©tecter automatiquement le document actif.

.PARAMETER CheckActiveDocument
    Indique si le document actif doit ÃƒÂªtre vÃƒÂ©rifiÃƒÂ© et mis ÃƒÂ  jour.
    Par dÃƒÂ©faut : valeur de la configuration ou $true.

.PARAMETER Force
    Indique si les modifications doivent ÃƒÂªtre appliquÃƒÂ©es sans confirmation.
    Par dÃƒÂ©faut : $false (mode simulation).

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration.
    Par dÃƒÂ©faut : config.json dans le rÃƒÂ©pertoire config.

.EXAMPLE
    .\check-mode-enhanced.ps1 -TaskIdentifier "1.2.3"

.EXAMPLE
    .\check-mode-enhanced.ps1 -TaskIdentifier "1.2.3" -Force

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.2
    Date de crÃƒÂ©ation: 2023-08-15
    Date de mise ÃƒÂ  jour: 2025-05-01 - AmÃƒÂ©lioration de l'encodage UTF-8 avec BOM et systÃƒÂ¨me de configuration
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false)]
    [string]$ImplementationPath,

    [Parameter(Mandatory = $false)]
    [string]$TestsPath,

    [Parameter(Mandatory = $false)]
    [switch]$UpdateRoadmap,

    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport = $true,

    [Parameter(Mandatory = $false, HelpMessage = "Chemin vers le document actif ÃƒÂ  vÃƒÂ©rifier et mettre ÃƒÂ  jour. Si non spÃƒÂ©cifiÃƒÂ©, le document actif sera dÃƒÂ©tectÃƒÂ© automatiquement.")]
    [string]$ActiveDocumentPath,

    [Parameter(Mandatory = $false)]
    [switch]$CheckActiveDocument,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath
)

# Importer les fonctions nÃƒÂ©cessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) -ChildPath "module\Functions"
$publicPath = Join-Path -Path $modulePath -ChildPath "Public"
$privatePath = Join-Path -Path $modulePath -ChildPath "Private"

# Chemins des fonctions de configuration
$configPath = Join-Path -Path $privatePath -ChildPath "Configuration"
$initConfigPath = Join-Path -Path $configPath -ChildPath "Initialize-Configuration.ps1"
$getConfigPath = Join-Path -Path $configPath -ChildPath "Get-Configuration.ps1"
$testConfigPath = Join-Path -Path $configPath -ChildPath "Test-Configuration.ps1"
$setDefaultConfigPath = Join-Path -Path $configPath -ChildPath "Set-DefaultConfiguration.ps1"

# Chemins des fonctions d'encodage
$encodingPath = Join-Path -Path $privatePath -ChildPath "Encoding"
$encodingHelpersPath = Join-Path -Path $encodingPath -ChildPath "Encoding-Helpers.ps1"

# Chemins des fonctions publiques
$invokeCheckPath = Join-Path -Path $publicPath -ChildPath "Invoke-RoadmapCheck.ps1"
$updateTaskPath = Join-Path -Path $publicPath -ChildPath "Update-RoadmapTaskStatus.ps1"
$updateCheckboxesPath = Join-Path -Path $publicPath -ChildPath "Update-ActiveDocumentCheckboxes-Enhanced.ps1"

# Si les chemins n'existent pas, essayer d'autres chemins
if (-not (Test-Path -Path $modulePath)) {
    $modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptPath))) -ChildPath "module\Functions"
    $publicPath = Join-Path -Path $modulePath -ChildPath "Public"
    $privatePath = Join-Path -Path $modulePath -ChildPath "Private"

    # Mettre ÃƒÂ  jour les chemins
    $configPath = Join-Path -Path $privatePath -ChildPath "Configuration"
    $initConfigPath = Join-Path -Path $configPath -ChildPath "Initialize-Configuration.ps1"
    $getConfigPath = Join-Path -Path $configPath -ChildPath "Get-Configuration.ps1"
    $testConfigPath = Join-Path -Path $configPath -ChildPath "Test-Configuration.ps1"
    $setDefaultConfigPath = Join-Path -Path $configPath -ChildPath "Set-DefaultConfiguration.ps1"

    $encodingPath = Join-Path -Path $privatePath -ChildPath "Encoding"
    $encodingHelpersPath = Join-Path -Path $encodingPath -ChildPath "Encoding-Helpers.ps1"

    $invokeCheckPath = Join-Path -Path $publicPath -ChildPath "Invoke-RoadmapCheck.ps1"
    $updateTaskPath = Join-Path -Path $publicPath -ChildPath "Update-RoadmapTaskStatus.ps1"
    $updateCheckboxesPath = Join-Path -Path $publicPath -ChildPath "Update-ActiveDocumentCheckboxes-Enhanced.ps1"
}

# Afficher les chemins pour le dÃƒÂ©bogage
Write-Host "Chemin du script : $scriptPath" -ForegroundColor Yellow
Write-Host "Chemin du module : $modulePath" -ForegroundColor Yellow
Write-Host "Chemin des fonctions de configuration : $configPath" -ForegroundColor Yellow
Write-Host "Chemin des fonctions d'encodage : $encodingPath" -ForegroundColor Yellow
Write-Host "Chemin des fonctions publiques : $publicPath" -ForegroundColor Yellow

# Importer les fonctions de configuration
$configFunctionsImported = $true

if (Test-Path -Path $initConfigPath) {
    try {
        . $initConfigPath
        Write-Host "Fonction Initialize-Configuration importÃƒÂ©e." -ForegroundColor Green
    } catch {
        Write-Warning "Erreur lors de l'importation de la fonction Initialize-Configuration : $($_.Exception.Message)"
        $configFunctionsImported = $false
    }
} else {
    Write-Warning "La fonction Initialize-Configuration est introuvable ÃƒÂ  l'emplacement : $initConfigPath"
    $configFunctionsImported = $false
}

if (Test-Path -Path $getConfigPath) {
    try {
        . $getConfigPath
        Write-Host "Fonction Get-Configuration importÃƒÂ©e." -ForegroundColor Green
    } catch {
        Write-Warning "Erreur lors de l'importation de la fonction Get-Configuration : $($_.Exception.Message)"
        $configFunctionsImported = $false
    }
} else {
    Write-Warning "La fonction Get-Configuration est introuvable ÃƒÂ  l'emplacement : $getConfigPath"
    $configFunctionsImported = $false
}

if (Test-Path -Path $testConfigPath) {
    try {
        . $testConfigPath
        Write-Host "Fonction Test-Configuration importÃƒÂ©e." -ForegroundColor Green
    } catch {
        Write-Warning "Erreur lors de l'importation de la fonction Test-Configuration : $($_.Exception.Message)"
        $configFunctionsImported = $false
    }
} else {
    Write-Warning "La fonction Test-Configuration est introuvable ÃƒÂ  l'emplacement : $testConfigPath"
    $configFunctionsImported = $false
}

if (Test-Path -Path $setDefaultConfigPath) {
    try {
        . $setDefaultConfigPath
        Write-Host "Fonction Set-DefaultConfiguration importÃƒÂ©e." -ForegroundColor Green
    } catch {
        Write-Warning "Erreur lors de l'importation de la fonction Set-DefaultConfiguration : $($_.Exception.Message)"
        $configFunctionsImported = $false
    }
} else {
    Write-Warning "La fonction Set-DefaultConfiguration est introuvable ÃƒÂ  l'emplacement : $setDefaultConfigPath"
    $configFunctionsImported = $false
}

# Importer les fonctions d'encodage
if (Test-Path -Path $encodingHelpersPath) {
    try {
        . $encodingHelpersPath
        Write-Host "Fonctions d'encodage importÃƒÂ©es." -ForegroundColor Green
    } catch {
        Write-Warning "Erreur lors de l'importation des fonctions d'encodage : $($_.Exception.Message)"
    }
} else {
    Write-Warning "Les fonctions d'encodage sont introuvables ÃƒÂ  l'emplacement : $encodingHelpersPath"
}

# Importer les fonctions publiques
$invokeCheckEnhancedPath = Join-Path -Path $publicPath -ChildPath "Invoke-RoadmapCheck-Enhanced.ps1"

if (Test-Path -Path $invokeCheckEnhancedPath) {
    try {
        . $invokeCheckEnhancedPath
        Write-Host "Fonction Invoke-RoadmapCheck importÃƒÂ©e depuis la version amÃƒÂ©liorÃƒÂ©e." -ForegroundColor Green
    } catch {
        Write-Warning "Erreur lors de l'importation de la fonction Invoke-RoadmapCheck amÃƒÂ©liorÃƒÂ©e : $($_.Exception.Message)"

        # Essayer la version standard
        if (Test-Path -Path $invokeCheckPath) {
            try {
                . $invokeCheckPath
                Write-Host "Fonction Invoke-RoadmapCheck importÃƒÂ©e depuis la version standard." -ForegroundColor Green
            } catch {
                throw "Erreur lors de l'importation de la fonction Invoke-RoadmapCheck : $($_.Exception.Message)"
            }
        } else {
            throw "La fonction Invoke-RoadmapCheck est introuvable ÃƒÂ  l'emplacement : $invokeCheckPath"
        }
    }
} else {
    # Utiliser la version standard
    if (Test-Path -Path $invokeCheckPath) {
        try {
            . $invokeCheckPath
            Write-Host "Fonction Invoke-RoadmapCheck importÃƒÂ©e depuis la version standard." -ForegroundColor Green
        } catch {
            throw "Erreur lors de l'importation de la fonction Invoke-RoadmapCheck : $($_.Exception.Message)"
        }
    } else {
        throw "La fonction Invoke-RoadmapCheck est introuvable ÃƒÂ  l'emplacement : $invokeCheckPath"
    }
}

if (Test-Path -Path $updateTaskPath) {
    try {
        . $updateTaskPath
        Write-Host "Fonction Update-RoadmapTaskStatus importÃƒÂ©e." -ForegroundColor Green
    } catch {
        throw "Erreur lors de l'importation de la fonction Update-RoadmapTaskStatus : $($_.Exception.Message)"
    }
} else {
    throw "La fonction Update-RoadmapTaskStatus est introuvable ÃƒÂ  l'emplacement : $updateTaskPath"
}

if (Test-Path -Path $updateCheckboxesPath) {
    try {
        . $updateCheckboxesPath
        Write-Host "Fonction Update-ActiveDocumentCheckboxes-Enhanced importÃƒÂ©e." -ForegroundColor Green
    } catch {
        Write-Warning "Erreur lors de l'importation de la fonction Update-ActiveDocumentCheckboxes-Enhanced : $($_.Exception.Message)"
    }
} else {
    Write-Warning "La fonction Update-ActiveDocumentCheckboxes-Enhanced est introuvable ÃƒÂ  l'emplacement : $updateCheckboxesPath. La mise ÃƒÂ  jour automatique des cases ÃƒÂ  cocher dans le document actif ne sera pas disponible."
}

# Charger la configuration
try {
    # DÃƒÂ©terminer le chemin de configuration
    if (-not $ConfigPath) {
        # Essayer plusieurs chemins possibles pour le fichier de configuration
        $possibleConfigPaths = @(
            "$PSScriptRoot\..\..\..\projet\config\config.json",
            "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\tools\scripts\roadmap-parser\config\config.json"
        )

        foreach ($path in $possibleConfigPaths) {
            if (Test-Path -Path $path) {
                $ConfigPath = $path
                Write-Host "Fichier de configuration trouvÃƒÂ© ÃƒÂ  l'emplacement : $ConfigPath" -ForegroundColor Green
                break
            }
        }

        if (-not $ConfigPath) {
            Write-Warning "Aucun fichier de configuration trouvÃƒÂ©. Utilisation des paramÃƒÂ¨tres par dÃƒÂ©faut."
        }
    }

    # VÃƒÂ©rifier si le fichier de configuration existe
    if ($ConfigPath -and (Test-Path -Path $ConfigPath)) {
        # Charger la configuration directement depuis le fichier JSON
        try {
            $configJson = Get-Content -Path $ConfigPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            Write-Host "Configuration chargÃƒÂ©e directement depuis $ConfigPath" -ForegroundColor Green

            # Appliquer les valeurs de configuration aux paramÃƒÂ¨tres non spÃƒÂ©cifiÃƒÂ©s
            if ($null -ne $configJson) {
                # FilePath
                if (-not $PSBoundParameters.ContainsKey('FilePath') -and $configJson.General.PSObject.Properties.Name.Contains('RoadmapPath')) {
                    $FilePath = $configJson.General.RoadmapPath

                    # Convertir le chemin relatif en chemin absolu si nÃƒÂ©cessaire
                    if (-not [System.IO.Path]::IsPathRooted($FilePath)) {
                        $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
                        $FilePath = Join-Path -Path $projectRoot -ChildPath $FilePath
                    }

                    Write-Host "Utilisation du chemin de roadmap depuis la configuration : $FilePath" -ForegroundColor Cyan
                }

                # UpdateRoadmap
                if (-not $PSBoundParameters.ContainsKey('UpdateRoadmap') -and $configJson.Check.PSObject.Properties.Name.Contains('AutoUpdateCheckboxes')) {
                    $UpdateRoadmap = $configJson.Check.AutoUpdateCheckboxes
                    Write-Host "Utilisation de la valeur de mise ÃƒÂ  jour automatique depuis la configuration : $UpdateRoadmap" -ForegroundColor Cyan
                }

                # CheckActiveDocument
                if (-not $PSBoundParameters.ContainsKey('CheckActiveDocument') -and $configJson.Check.PSObject.Properties.Name.Contains('AutoUpdateCheckboxes')) {
                    $CheckActiveDocument = $configJson.Check.AutoUpdateCheckboxes
                    Write-Host "Utilisation de la valeur de vÃƒÂ©rification du document actif depuis la configuration : $CheckActiveDocument" -ForegroundColor Cyan
                }

                # Force (mode simulation par dÃƒÂ©faut)
                if (-not $PSBoundParameters.ContainsKey('Force') -and $configJson.Check.PSObject.Properties.Name.Contains('SimulationModeDefault')) {
                    $Force = -not $configJson.Check.SimulationModeDefault
                    Write-Host "Utilisation du mode simulation depuis la configuration : $(-not $Force)" -ForegroundColor Cyan
                }
            }
        } catch {
            Write-Warning "Erreur lors du chargement direct de la configuration depuis $ConfigPath : $($_.Exception.Message)"
            Write-Warning "Utilisation des paramÃƒÂ¨tres par dÃƒÂ©faut."
        }
    } else {
        # Essayer d'utiliser les fonctions de configuration si disponibles
        if ($configFunctionsImported -and (Get-Command -Name Get-Configuration -ErrorAction SilentlyContinue)) {
            $config = Get-Configuration -ConfigPath $ConfigPath -ApplyDefaults
            Write-Host "Configuration chargÃƒÂ©e via Get-Configuration depuis $ConfigPath" -ForegroundColor Green

            # Appliquer les valeurs de configuration aux paramÃƒÂ¨tres non spÃƒÂ©cifiÃƒÂ©s
            if ($null -ne $config) {
                # FilePath
                if (-not $PSBoundParameters.ContainsKey('FilePath') -and $config.General.PSObject.Properties.Name.Contains('RoadmapPath')) {
                    $FilePath = $config.General.RoadmapPath

                    # Convertir le chemin relatif en chemin absolu si nÃƒÂ©cessaire
                    if (-not [System.IO.Path]::IsPathRooted($FilePath)) {
                        $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
                        $FilePath = Join-Path -Path $projectRoot -ChildPath $FilePath
                    }

                    Write-Host "Utilisation du chemin de roadmap depuis la configuration : $FilePath" -ForegroundColor Cyan
                }

                # UpdateRoadmap
                if (-not $PSBoundParameters.ContainsKey('UpdateRoadmap') -and $config.Check.PSObject.Properties.Name.Contains('AutoUpdateCheckboxes')) {
                    $UpdateRoadmap = $config.Check.AutoUpdateCheckboxes
                    Write-Host "Utilisation de la valeur de mise ÃƒÂ  jour automatique depuis la configuration : $UpdateRoadmap" -ForegroundColor Cyan
                }

                # CheckActiveDocument
                if (-not $PSBoundParameters.ContainsKey('CheckActiveDocument') -and $config.Check.PSObject.Properties.Name.Contains('AutoUpdateCheckboxes')) {
                    $CheckActiveDocument = $config.Check.AutoUpdateCheckboxes
                    Write-Host "Utilisation de la valeur de vÃƒÂ©rification du document actif depuis la configuration : $CheckActiveDocument" -ForegroundColor Cyan
                }

                # Force (mode simulation par dÃƒÂ©faut)
                if (-not $PSBoundParameters.ContainsKey('Force') -and $config.Check.PSObject.Properties.Name.Contains('SimulationModeDefault')) {
                    $Force = -not $config.Check.SimulationModeDefault
                    Write-Host "Utilisation du mode simulation depuis la configuration : $(-not $Force)" -ForegroundColor Cyan
                }
            }
        } else {
            Write-Warning "Le fichier de configuration n'existe pas ÃƒÂ  l'emplacement $ConfigPath et les fonctions de configuration ne sont pas disponibles."
            Write-Warning "Utilisation des paramÃƒÂ¨tres par dÃƒÂ©faut."
        }
    }
} catch {
    Write-Warning "Erreur lors du chargement de la configuration : $($_.Exception.Message)"
    Write-Warning "Utilisation des paramÃƒÂ¨tres par dÃƒÂ©faut."
}

# VÃƒÂ©rifier que le fichier de roadmap existe
if (-not $FilePath) {
    # Utiliser une valeur par dÃƒÂ©faut si la configuration n'est pas disponible
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

    # Essayer de trouver le fichier de roadmap
    $possiblePaths = @(
        "docs\plans\roadmap_complete_2.md",
        "docs\development\roadmap\roadmap_complete_converted.md",
        "docs\development\roadmap\plans\roadmap_complete_2.md"
    )

    foreach ($path in $possiblePaths) {
        $fullPath = Join-Path -Path $projectRoot -ChildPath $path
        if (Test-Path -Path $fullPath) {
            $FilePath = $fullPath
            Write-Host "Fichier de roadmap trouvÃƒÂ© ÃƒÂ  l'emplacement : $FilePath" -ForegroundColor Green
            break
        }
    }

    if (-not $FilePath) {
        Write-Warning "Le chemin du fichier de roadmap n'est pas spÃƒÂ©cifiÃƒÂ© et n'a pas pu ÃƒÂªtre rÃƒÂ©cupÃƒÂ©rÃƒÂ© depuis la configuration. Utilisation de la valeur par dÃƒÂ©faut : Roadmap\roadmap_complete_converted.md"
        $FilePath = "Roadmap\roadmap_complete_converted.md"
    }
}

if (-not (Test-Path -Path $FilePath)) {
    throw "Le fichier de roadmap spÃƒÂ©cifiÃƒÂ© n'existe pas : $FilePath"
}

# DÃƒÂ©tecter automatiquement le document actif si nÃƒÂ©cessaire
if ($CheckActiveDocument -and -not $ActiveDocumentPath) {
    Write-Host "DÃƒÂ©tection automatique du document actif..." -ForegroundColor Cyan

    # MÃƒÂ©thode 1: VÃƒÂ©rifier la variable d'environnement VSCODE_ACTIVE_DOCUMENT
    if ($env:VSCODE_ACTIVE_DOCUMENT -and (Test-Path -Path $env:VSCODE_ACTIVE_DOCUMENT)) {
        $ActiveDocumentPath = $env:VSCODE_ACTIVE_DOCUMENT
        Write-Host "Document actif dÃƒÂ©tectÃƒÂ© via variable d'environnement : $ActiveDocumentPath" -ForegroundColor Green
    }
    # MÃƒÂ©thode 2: Rechercher les fichiers Markdown rÃƒÂ©cemment modifiÃƒÂ©s
    else {
        $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
        $recentMdFiles = Get-ChildItem -Path $projectRoot -Filter "*.md" -Recurse |
            Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-30) } |
            Sort-Object LastWriteTime -Descending

        if ($recentMdFiles.Count -gt 0) {
            $ActiveDocumentPath = $recentMdFiles[0].FullName
            Write-Host "Document actif dÃƒÂ©tectÃƒÂ© automatiquement (fichier rÃƒÂ©cemment modifiÃƒÂ©) : $ActiveDocumentPath" -ForegroundColor Green
        } else {
            Write-Warning "Aucun document actif n'a pu ÃƒÂªtre dÃƒÂ©tectÃƒÂ© automatiquement. La vÃƒÂ©rification du document actif sera dÃƒÂ©sactivÃƒÂ©e."
            $CheckActiveDocument = $false
        }
    }
}

# VÃƒÂ©rifier si le document actif existe
if ($CheckActiveDocument -and $ActiveDocumentPath) {
    if (-not (Test-Path -Path $ActiveDocumentPath)) {
        Write-Warning "Le document actif spÃƒÂ©cifiÃƒÂ© n'existe pas : $ActiveDocumentPath. La vÃƒÂ©rification du document actif sera dÃƒÂ©sactivÃƒÂ©e."
        $CheckActiveDocument = $false
    }
}

# Appeler la fonction Invoke-RoadmapCheck
$result = Invoke-RoadmapCheck -FilePath $FilePath -TaskIdentifier $TaskIdentifier -ImplementationPath $ImplementationPath -TestsPath $TestsPath -UpdateRoadmap $UpdateRoadmap -GenerateReport $GenerateReport

# VÃƒÂ©rifier et mettre ÃƒÂ  jour les cases ÃƒÂ  cocher dans le document actif si demandÃƒÂ©
if ($CheckActiveDocument -and $ActiveDocumentPath) {
    Write-Host "`nVÃƒÂ©rification et mise ÃƒÂ  jour des cases ÃƒÂ  cocher dans le document actif : $ActiveDocumentPath" -ForegroundColor Cyan

    # Extraire les rÃƒÂ©sultats d'implÃƒÂ©mentation et de tests
    $implementationResults = @{}
    $testResults = @{}

    foreach ($task in $result.Tasks) {
        $implementationResults[$task.Id] = $task.Implementation
        $testResults[$task.Id] = $task.Tests
    }

    # Utiliser la fonction Update-ActiveDocumentCheckboxes-Enhanced si disponible
    if (Get-Command -Name Update-ActiveDocumentCheckboxes-Enhanced -ErrorAction SilentlyContinue) {
        # PrÃƒÂ©parer les paramÃƒÂ¨tres pour la fonction
        $updateParams = @{
            DocumentPath          = $ActiveDocumentPath
            ImplementationResults = $implementationResults
            TestResults           = $testResults
        }

        # Ajouter le paramÃƒÂ¨tre WhatIf si Force n'est pas spÃƒÂ©cifiÃƒÂ©
        if (-not $Force) {
            $updateParams.Add("WhatIf", $true)
        }

        # Appeler la fonction avec les paramÃƒÂ¨tres
        $updateResult = Update-ActiveDocumentCheckboxes-Enhanced @updateParams
        $tasksUpdated = $updateResult
    } else {
        # MÃƒÂ©thode alternative si la fonction n'est pas disponible
        Write-Warning "La fonction Update-ActiveDocumentCheckboxes-Enhanced n'est pas disponible. Utilisation d'une mÃƒÂ©thode alternative."

        # Lire le contenu du document actif
        $activeDocumentContent = Get-Content -Path $ActiveDocumentPath -Encoding UTF8
        $tasksUpdated = 0
        $modified = $false

        # Pour chaque tÃƒÂ¢che vÃƒÂ©rifiÃƒÂ©e
        foreach ($task in $result.Tasks) {
            # Si la tÃƒÂ¢che est implÃƒÂ©mentÃƒÂ©e ÃƒÂ  100% et testÃƒÂ©e avec succÃƒÂ¨s ÃƒÂ  100%
            if ($task.Implementation.ImplementationComplete -and $task.Tests.TestsComplete -and $task.Tests.TestsSuccessful) {
                # Rechercher la tÃƒÂ¢che dans le document actif (diffÃƒÂ©rents formats possibles)
                $taskPatterns = @(
                    "- \[ \] \*\*$($task.Id)\*\*",
                    "- \[ \] $($task.Id)",
                    "- \[ \] $($task.Title)"
                )

                foreach ($pattern in $taskPatterns) {
                    $newContent = $activeDocumentContent -replace $pattern, "- [x] $($task.Id)"

                    # Si le contenu a changÃƒÂ©, c'est que la tÃƒÂ¢che a ÃƒÂ©tÃƒÂ© trouvÃƒÂ©e et mise ÃƒÂ  jour
                    if ($newContent -ne $activeDocumentContent) {
                        $activeDocumentContent = $newContent
                        $modified = $true
                        $tasksUpdated++
                        Write-Host "  TÃƒÂ¢che $($task.Id) - $($task.Title) : Case ÃƒÂ  cocher mise ÃƒÂ  jour" -ForegroundColor Green
                        break
                    }
                }
            }
        }

        # Enregistrer les modifications si nÃƒÂ©cessaire
        if ($modified -and $Force) {
            # Utiliser UTF-8 avec BOM pour l'enregistrement
            $utf8WithBom = New-Object System.Text.UTF8Encoding $true
            [System.IO.File]::WriteAllLines($ActiveDocumentPath, $activeDocumentContent, $utf8WithBom)

            # VÃƒÂ©rifier que le fichier a bien ÃƒÂ©tÃƒÂ© enregistrÃƒÂ© en UTF-8 avec BOM
            $bytes = [System.IO.File]::ReadAllBytes($ActiveDocumentPath)
            $hasBOM = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF

            if (-not $hasBOM) {
                Write-Warning "Le fichier n'a pas ÃƒÂ©tÃƒÂ© correctement enregistrÃƒÂ© en UTF-8 avec BOM. Tentative de correction..."
                # Forcer l'encodage UTF-8 avec BOM
                $content = [System.IO.File]::ReadAllText($ActiveDocumentPath)
                [System.IO.File]::WriteAllText($ActiveDocumentPath, $content, $utf8WithBom)
            }

            Write-Host "  $tasksUpdated cases ÃƒÂ  cocher mises ÃƒÂ  jour dans le document actif." -ForegroundColor Green
        } elseif ($modified) {
            Write-Host "  $tasksUpdated cases ÃƒÂ  cocher seraient mises ÃƒÂ  jour dans le document actif (mode simulation)." -ForegroundColor Yellow
        } else {
            Write-Host "  Aucune case ÃƒÂ  cocher n'a ÃƒÂ©tÃƒÂ© mise ÃƒÂ  jour dans le document actif." -ForegroundColor Gray
        }
    }
}

# Afficher un rÃƒÂ©sumÃƒÂ© des rÃƒÂ©sultats
Write-Host "`nRÃƒÂ©sumÃƒÂ© des rÃƒÂ©sultats :" -ForegroundColor Cyan
Write-Host "  TÃƒÂ¢che principale : $($result.MainTaskId)" -ForegroundColor Cyan
Write-Host "  Nombre total de tÃƒÂ¢ches : $($result.Tasks.Count)" -ForegroundColor Cyan
Write-Host "  TÃƒÂ¢ches implÃƒÂ©mentÃƒÂ©es ÃƒÂ  100% : $($result.Tasks | Where-Object { $_.Implementation.ImplementationComplete } | Measure-Object).Count" -ForegroundColor Cyan
Write-Host "  TÃƒÂ¢ches testÃƒÂ©es ÃƒÂ  100% : $($result.Tasks | Where-Object { $_.Tests.TestsComplete -and $_.Tests.TestsSuccessful } | Measure-Object).Count" -ForegroundColor Cyan

if ($UpdateRoadmap) {
    Write-Host "  TÃƒÂ¢ches mises ÃƒÂ  jour dans la roadmap : $($result.TasksUpdated)" -ForegroundColor Cyan
}

if ($CheckActiveDocument -and $ActiveDocumentPath) {
    Write-Host "  TÃƒÂ¢ches mises ÃƒÂ  jour dans le document actif : $tasksUpdated" -ForegroundColor Cyan
}

# Afficher un message de fin
Write-Host "`nVÃƒÂ©rification terminÃƒÂ©e." -ForegroundColor Green
