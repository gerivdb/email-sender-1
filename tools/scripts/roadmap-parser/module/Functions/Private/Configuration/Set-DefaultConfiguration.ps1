<#
.SYNOPSIS
    Applique des valeurs par défaut à une configuration.
.DESCRIPTION
    Cette fonction applique des valeurs par défaut aux propriétés manquantes d'une configuration.
.PARAMETER Config
    L'objet de configuration à compléter.
.EXAMPLE
    $config = Set-DefaultConfiguration -Config $config
    Applique des valeurs par défaut à la configuration.
#>
function Set-DefaultConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config
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
    
    # Créer un nouvel objet pour stocker la configuration fusionnée
    $mergedConfig = [PSCustomObject]@{}
    
    # Fusionner les sections principales
    foreach ($section in $defaultConfig.Keys) {
        if (-not $Config.PSObject.Properties.Name.Contains($section)) {
            $mergedConfig | Add-Member -MemberType NoteProperty -Name $section -Value ([PSCustomObject]$defaultConfig[$section])
        }
        else {
            $mergedSection = [PSCustomObject]@{}
            
            # Fusionner les propriétés de la section
            foreach ($prop in $defaultConfig[$section].Keys) {
                if (-not $Config.$section.PSObject.Properties.Name.Contains($prop)) {
                    $mergedSection | Add-Member -MemberType NoteProperty -Name $prop -Value $defaultConfig[$section][$prop]
                }
                else {
                    $mergedSection | Add-Member -MemberType NoteProperty -Name $prop -Value $Config.$section.$prop
                }
            }
            
            # Ajouter les propriétés supplémentaires de la configuration existante
            foreach ($prop in $Config.$section.PSObject.Properties.Name) {
                if (-not $mergedSection.PSObject.Properties.Name.Contains($prop)) {
                    $mergedSection | Add-Member -MemberType NoteProperty -Name $prop -Value $Config.$section.$prop
                }
            }
            
            $mergedConfig | Add-Member -MemberType NoteProperty -Name $section -Value $mergedSection
        }
    }
    
    # Ajouter les sections supplémentaires de la configuration existante
    foreach ($section in $Config.PSObject.Properties.Name) {
        if (-not $mergedConfig.PSObject.Properties.Name.Contains($section)) {
            $mergedConfig | Add-Member -MemberType NoteProperty -Name $section -Value $Config.$section
        }
    }
    
    return $mergedConfig
}
