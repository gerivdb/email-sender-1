<#
.SYNOPSIS
    Initialise la configuration du système de roadmap.
.DESCRIPTION
    Cette fonction initialise la configuration en chargeant le fichier de configuration existant
    ou en créant un nouveau fichier avec des valeurs par défaut si nécessaire.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration. Par défaut, il s'agit de config.json dans le répertoire config.
.PARAMETER CreateIfMissing
    Si spécifié, crée un fichier de configuration avec des valeurs par défaut s'il n'existe pas.
.EXAMPLE
    $config = Initialize-Configuration -CreateIfMissing
    Initialise la configuration et crée un fichier de configuration par défaut s'il n'existe pas.
#>
function Initialize-Configuration {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$ConfigPath = "$PSScriptRoot\..\..\..\config\config.json",

        [Parameter()]
        [switch]$CreateIfMissing
    )

    # Définir la configuration par défaut
    $defaultConfig = @{
        General = @{
            RoadmapPath = "Roadmap\roadmap_complete_converted.md"
            Encoding    = "UTF8"
            DefaultMode = "check"
            LogPath     = "logs"
            LogLevel    = "INFO"
        }
        Paths   = @{
            OutputDirectory  = "output"
            TestsDirectory   = "tests"
            ScriptsDirectory = "tools\scripts"
            ModulePath       = "roadmap-parser\module"
            FunctionsPath    = "roadmap-parser\module\Functions"
        }
        Check   = @{
            AutoUpdateCheckboxes    = $true
            RequireFullTestCoverage = $true
            SimulationModeDefault   = $true
        }
        Modes   = @{
            Check  = @{
                Enabled    = $true
                ScriptPath = "tools\scripts\roadmap-parser\modes\check\check-mode-enhanced.ps1"
            }
            Debug  = @{
                Enabled          = $true
                ScriptPath       = "tools\scripts\roadmap-parser\modes\debug\debug-mode.ps1"
                GeneratePatch    = $true
                IncludeStackTrace = $true
            }
            Archi  = @{
                Enabled    = $false
                ScriptPath = "tools\scripts\archi-mode.ps1"
            }
            CBreak = @{
                Enabled    = $false
                ScriptPath = "tools\scripts\c-break-mode.ps1"
            }
            TEST   = @{
                Enabled           = $true
                ScriptPath        = "tools\scripts\test-mode.ps1"
                CoverageThreshold = 80
                GenerateReport    = $true
            }
        }
    }

    # Vérifier si le fichier de configuration existe
    if (Test-Path $ConfigPath) {
        try {
            $config = Get-Content -Path $ConfigPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            Write-Verbose "Configuration chargée depuis $ConfigPath"
        } catch {
            Write-Warning "Erreur lors du chargement de la configuration depuis $ConfigPath : $($_.Exception.Message)"
            if ($CreateIfMissing) {
                $config = $defaultConfig
                Write-Verbose "Utilisation de la configuration par défaut"
            } else {
                throw "Échec du chargement de la configuration et CreateIfMissing n'est pas spécifié"
            }
        }
    } else {
        if ($CreateIfMissing) {
            # S'assurer que le répertoire existe
            $configDir = Split-Path -Path $ConfigPath -Parent
            if (-not (Test-Path $configDir)) {
                New-Item -Path $configDir -ItemType Directory -Force | Out-Null
            }

            # Créer le fichier de configuration avec les valeurs par défaut
            $defaultConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $ConfigPath -Encoding UTF8
            Write-Verbose "Configuration par défaut créée à $ConfigPath"
            $config = $defaultConfig
        } else {
            throw "Fichier de configuration introuvable à $ConfigPath et CreateIfMissing n'est pas spécifié"
        }
    }

    return $config
}
