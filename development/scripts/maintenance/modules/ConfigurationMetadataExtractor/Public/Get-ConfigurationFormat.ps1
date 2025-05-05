<#
.SYNOPSIS
    DÃ©tecte le format d'un fichier de configuration.
.DESCRIPTION
    Cette fonction analyse un fichier de configuration et dÃ©termine son format
    (JSON, YAML, XML, INI, PSD1) en se basant sur l'extension du fichier et son contenu.
.PARAMETER Path
    Chemin vers le fichier de configuration Ã  analyser.
.PARAMETER Content
    Contenu du fichier de configuration Ã  analyser. Si spÃ©cifiÃ©, Path est ignorÃ©.
.EXAMPLE
    Get-ConfigurationFormat -Path "config.json"
    DÃ©tecte le format du fichier config.json.
.EXAMPLE
    Get-ConfigurationFormat -Content '{"key": "value"}'
    DÃ©tecte le format du contenu fourni (JSON dans cet exemple).
.OUTPUTS
    System.String
#>
function Get-ConfigurationFormat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "Path")]
        [string]$Path,
        
        [Parameter(Mandatory = $true, ParameterSetName = "Content")]
        [string]$Content
    )
    
    try {
        # Si le chemin est spÃ©cifiÃ©, essayer d'abord de dÃ©terminer le format Ã  partir de l'extension
        if ($PSCmdlet.ParameterSetName -eq "Path") {
            if (-not (Test-Path -Path $Path -PathType Leaf)) {
                Write-Error "Le fichier spÃ©cifiÃ© n'existe pas: $Path"
                return "UNKNOWN"
            }
            
            $formatFromExtension = Get-FileExtensionFormat -FilePath $Path
            
            # Si le format est dÃ©terminÃ© Ã  partir de l'extension, vÃ©rifier qu'il correspond au contenu
            if ($formatFromExtension -and $formatFromExtension -ne "UNKNOWN") {
                $Content = Get-Content -Path $Path -Raw -ErrorAction Stop
                $formatFromContent = Get-ContentFormat -Content $Content
                
                # Si les deux formats correspondent, retourner le format
                if ($formatFromExtension -eq $formatFromContent) {
                    return $formatFromExtension
                }
                
                # Si les formats ne correspondent pas, privilÃ©gier l'analyse du contenu
                Write-Verbose "Le format dÃ©tectÃ© Ã  partir de l'extension ($formatFromExtension) ne correspond pas au format dÃ©tectÃ© Ã  partir du contenu ($formatFromContent)."
                return $formatFromContent
            }
            
            # Si le format n'est pas dÃ©terminÃ© Ã  partir de l'extension, analyser le contenu
            $Content = Get-Content -Path $Path -Raw -ErrorAction Stop
        }
        
        # DÃ©terminer le format Ã  partir du contenu
        return Get-ContentFormat -Content $Content
    }
    catch {
        Write-Error "Erreur lors de la dÃ©tection du format de configuration: $_"
        return "UNKNOWN"
    }
}
