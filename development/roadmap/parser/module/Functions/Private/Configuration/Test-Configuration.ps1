<#
.SYNOPSIS
    Teste la validitÃ© d'une configuration.
.DESCRIPTION
    Cette fonction vÃ©rifie si une configuration contient toutes les sections et propriÃ©tÃ©s requises.
.PARAMETER Config
    L'objet de configuration Ã  tester.
.PARAMETER Detailed
    Si spÃ©cifiÃ©, renvoie un objet dÃ©taillÃ© contenant les rÃ©sultats de validation.
.EXAMPLE
    $isValid = Test-Configuration -Config $config
    Teste si la configuration est valide et renvoie un boolÃ©en.
.EXAMPLE
    $validationResult = Test-Configuration -Config $config -Detailed
    Teste si la configuration est valide et renvoie un objet dÃ©taillÃ© contenant les rÃ©sultats de validation.
#>
function Test-Configuration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config,
        
        [Parameter()]
        [switch]$Detailed
    )
    
    $isValid = $true
    $validationResults = @()
    
    # Sections requises
    $requiredSections = @('General', 'Paths', 'Check', 'Modes')
    foreach ($section in $requiredSections) {
        if (-not $Config.PSObject.Properties.Name.Contains($section)) {
            $isValid = $false
            $validationResults += "Section requise manquante: $section"
        }
    }
    
    # PropriÃ©tÃ©s requises dans General
    if ($Config.PSObject.Properties.Name.Contains('General')) {
        $requiredGeneralProps = @('RoadmapPath', 'Encoding', 'DefaultMode')
        foreach ($prop in $requiredGeneralProps) {
            if (-not $Config.General.PSObject.Properties.Name.Contains($prop)) {
                $isValid = $false
                $validationResults += "PropriÃ©tÃ© requise manquante dans la section General: $prop"
            }
        }
    }
    
    # PropriÃ©tÃ©s requises dans Paths
    if ($Config.PSObject.Properties.Name.Contains('Paths')) {
        $requiredPathsProps = @('OutputDirectory', 'TestsDirectory', 'ScriptsDirectory')
        foreach ($prop in $requiredPathsProps) {
            if (-not $Config.Paths.PSObject.Properties.Name.Contains($prop)) {
                $isValid = $false
                $validationResults += "PropriÃ©tÃ© requise manquante dans la section Paths: $prop"
            }
        }
    }
    
    # PropriÃ©tÃ©s requises dans Check
    if ($Config.PSObject.Properties.Name.Contains('Check')) {
        $requiredCheckProps = @('AutoUpdateCheckboxes', 'RequireFullTestCoverage', 'SimulationModeDefault')
        foreach ($prop in $requiredCheckProps) {
            if (-not $Config.Check.PSObject.Properties.Name.Contains($prop)) {
                $isValid = $false
                $validationResults += "PropriÃ©tÃ© requise manquante dans la section Check: $prop"
            }
        }
    }
    
    # Modes requis
    if ($Config.PSObject.Properties.Name.Contains('Modes')) {
        $requiredModes = @('Check', 'Debug')
        foreach ($mode in $requiredModes) {
            if (-not $Config.Modes.PSObject.Properties.Name.Contains($mode)) {
                $isValid = $false
                $validationResults += "Mode requis manquant: $mode"
            }
            elseif (-not $Config.Modes.$mode.PSObject.Properties.Name.Contains('Enabled') -or 
                   -not $Config.Modes.$mode.PSObject.Properties.Name.Contains('ScriptPath')) {
                $isValid = $false
                $validationResults += "Le mode $mode manque de propriÃ©tÃ©s requises (Enabled ou ScriptPath)"
            }
        }
    }
    
    if ($Detailed) {
        return @{
            IsValid = $isValid
            Results = $validationResults
        }
    }
    else {
        return $isValid
    }
}
