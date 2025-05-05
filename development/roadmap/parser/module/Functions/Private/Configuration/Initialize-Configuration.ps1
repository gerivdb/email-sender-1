<#
.SYNOPSIS
    Initialise la configuration du systÃ¨me de roadmap.
.DESCRIPTION
    Cette fonction initialise la configuration en chargeant le fichier de configuration existant
    ou en crÃ©ant un nouveau fichier avec des valeurs par dÃ©faut si nÃ©cessaire.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration. Par dÃ©faut, il s'agit de config.json dans le rÃ©pertoire config.
.PARAMETER CreateIfMissing
    Si spÃ©cifiÃ©, crÃ©e un fichier de configuration avec des valeurs par dÃ©faut s'il n'existe pas.
.EXAMPLE
    $config = Initialize-Configuration -CreateIfMissing
    Initialise la configuration et crÃ©e un fichier de configuration par dÃ©faut s'il n'existe pas.
#>
function Initialize-Configuration {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$ConfigPath = "$PSScriptRoot\..\..\..\projet\config\config.json",

        [Parameter()]
        [switch]$CreateIfMissing
    )

    # DÃ©finir la configuration par dÃ©faut
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

    # VÃ©rifier si le fichier de configuration existe
    if (Test-Path $ConfigPath) {
        try {
            $config = Get-Content -Path $ConfigPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            Write-Verbose "Configuration chargÃ©e depuis $ConfigPath"
        } catch {
            Write-Warning "Erreur lors du chargement de la configuration depuis $ConfigPath : $($_.Exception.Message)"
            if ($CreateIfMissing) {
                $config = $defaultConfig
                Write-Verbose "Utilisation de la configuration par dÃ©faut"
            } else {
                throw "Ã‰chec du chargement de la configuration et CreateIfMissing n'est pas spÃ©cifiÃ©"
            }
        }
    } else {
        if ($CreateIfMissing) {
            # S'assurer que le rÃ©pertoire existe
            $configDir = Split-Path -Path $ConfigPath -Parent
            if (-not (Test-Path $configDir)) {
                New-Item -Path $configDir -ItemType Directory -Force | Out-Null
            }

            # CrÃ©er le fichier de configuration avec les valeurs par dÃ©faut
            $defaultConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $ConfigPath -Encoding UTF8
            Write-Verbose "Configuration par dÃ©faut crÃ©Ã©e Ã  $ConfigPath"
            $config = $defaultConfig
        } else {
            throw "Fichier de configuration introuvable Ã  $ConfigPath et CreateIfMissing n'est pas spÃ©cifiÃ©"
        }
    }

    return $config
}
