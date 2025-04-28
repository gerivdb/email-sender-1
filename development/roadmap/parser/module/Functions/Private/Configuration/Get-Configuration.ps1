<#
.SYNOPSIS
    Récupère la configuration du système de roadmap.
.DESCRIPTION
    Cette fonction récupère la configuration en chargeant le fichier de configuration
    et en appliquant des valeurs par défaut si nécessaire.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration. Par défaut, il s'agit de config.json dans le répertoire config.
.PARAMETER ApplyDefaults
    Si spécifié, applique des valeurs par défaut aux propriétés manquantes.
.PARAMETER Validate
    Si spécifié, valide la configuration et génère une erreur si elle est invalide.
.EXAMPLE
    $config = Get-Configuration -ApplyDefaults
    Récupère la configuration et applique des valeurs par défaut aux propriétés manquantes.
.EXAMPLE
    $config = Get-Configuration -ConfigPath "chemin/vers/config.json" -Validate
    Récupère la configuration à partir du chemin spécifié et la valide.
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
            Write-Warning "La validation de la configuration a échoué:"
            foreach ($result in $validationResult.Results) {
                Write-Warning "  - $result"
            }
            
            if ($ApplyDefaults) {
                Write-Verbose "Application des valeurs par défaut à la configuration invalide"
                $config = Set-DefaultConfiguration -Config $config
            }
            elseif ($Validate) {
                throw "La validation de la configuration a échoué. Utilisez -ApplyDefaults pour appliquer des valeurs par défaut."
            }
            else {
                Write-Warning "La configuration est invalide. Utilisez -ApplyDefaults pour appliquer des valeurs par défaut."
            }
        }
        
        return $config
    }
    catch {
        Write-Error "Erreur lors de la récupération de la configuration: $_"
        if ($ApplyDefaults) {
            Write-Warning "Utilisation de la configuration par défaut"
            return Initialize-Configuration -CreateIfMissing -ErrorAction Stop
        }
        else {
            throw
        }
    }
}
