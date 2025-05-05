<#
.SYNOPSIS
    RÃ©cupÃ¨re la configuration du systÃ¨me de roadmap.
.DESCRIPTION
    Cette fonction rÃ©cupÃ¨re la configuration en chargeant le fichier de configuration
    et en appliquant des valeurs par dÃ©faut si nÃ©cessaire.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration. Par dÃ©faut, il s'agit de config.json dans le rÃ©pertoire config.
.PARAMETER ApplyDefaults
    Si spÃ©cifiÃ©, applique des valeurs par dÃ©faut aux propriÃ©tÃ©s manquantes.
.PARAMETER Validate
    Si spÃ©cifiÃ©, valide la configuration et gÃ©nÃ¨re une erreur si elle est invalide.
.EXAMPLE
    $config = Get-Configuration -ApplyDefaults
    RÃ©cupÃ¨re la configuration et applique des valeurs par dÃ©faut aux propriÃ©tÃ©s manquantes.
.EXAMPLE
    $config = Get-Configuration -ConfigPath "chemin/vers/config.json" -Validate
    RÃ©cupÃ¨re la configuration Ã  partir du chemin spÃ©cifiÃ© et la valide.
#>
function Get-Configuration {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$ConfigPath = "$PSScriptRoot\..\..\..\projet\config\config.json",
        
        [Parameter()]
        [switch]$ApplyDefaults,
        
        [Parameter()]
        [switch]$Validate
    )
    
    try {
        $config = Initialize-Configuration -ConfigPath $ConfigPath -CreateIfMissing:$ApplyDefaults -ErrorAction Stop
        
        # Valider la configuration
        $validationResult = Test-Configuration -Config $config -Detailed
        
        if (-not $validationResult.IsValid) {
            Write-Warning "La validation de la configuration a Ã©chouÃ©:"
            foreach ($result in $validationResult.Results) {
                Write-Warning "  - $result"
            }
            
            if ($ApplyDefaults) {
                Write-Verbose "Application des valeurs par dÃ©faut Ã  la configuration invalide"
                $config = Set-DefaultConfiguration -Config $config
            }
            elseif ($Validate) {
                throw "La validation de la configuration a Ã©chouÃ©. Utilisez -ApplyDefaults pour appliquer des valeurs par dÃ©faut."
            }
            else {
                Write-Warning "La configuration est invalide. Utilisez -ApplyDefaults pour appliquer des valeurs par dÃ©faut."
            }
        }
        
        return $config
    }
    catch {
        Write-Error "Erreur lors de la rÃ©cupÃ©ration de la configuration: $_"
        if ($ApplyDefaults) {
            Write-Warning "Utilisation de la configuration par dÃ©faut"
            return Initialize-Configuration -CreateIfMissing -ErrorAction Stop
        }
        else {
            throw
        }
    }
}
