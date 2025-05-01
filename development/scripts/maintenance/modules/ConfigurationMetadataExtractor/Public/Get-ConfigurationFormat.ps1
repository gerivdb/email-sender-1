<#
.SYNOPSIS
    Détecte le format d'un fichier de configuration.
.DESCRIPTION
    Cette fonction analyse un fichier de configuration et détermine son format
    (JSON, YAML, XML, INI, PSD1) en se basant sur l'extension du fichier et son contenu.
.PARAMETER Path
    Chemin vers le fichier de configuration à analyser.
.PARAMETER Content
    Contenu du fichier de configuration à analyser. Si spécifié, Path est ignoré.
.EXAMPLE
    Get-ConfigurationFormat -Path "config.json"
    Détecte le format du fichier config.json.
.EXAMPLE
    Get-ConfigurationFormat -Content '{"key": "value"}'
    Détecte le format du contenu fourni (JSON dans cet exemple).
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
        # Si le chemin est spécifié, essayer d'abord de déterminer le format à partir de l'extension
        if ($PSCmdlet.ParameterSetName -eq "Path") {
            if (-not (Test-Path -Path $Path -PathType Leaf)) {
                Write-Error "Le fichier spécifié n'existe pas: $Path"
                return "UNKNOWN"
            }
            
            $formatFromExtension = Get-FileExtensionFormat -FilePath $Path
            
            # Si le format est déterminé à partir de l'extension, vérifier qu'il correspond au contenu
            if ($formatFromExtension -and $formatFromExtension -ne "UNKNOWN") {
                $Content = Get-Content -Path $Path -Raw -ErrorAction Stop
                $formatFromContent = Get-ContentFormat -Content $Content
                
                # Si les deux formats correspondent, retourner le format
                if ($formatFromExtension -eq $formatFromContent) {
                    return $formatFromExtension
                }
                
                # Si les formats ne correspondent pas, privilégier l'analyse du contenu
                Write-Verbose "Le format détecté à partir de l'extension ($formatFromExtension) ne correspond pas au format détecté à partir du contenu ($formatFromContent)."
                return $formatFromContent
            }
            
            # Si le format n'est pas déterminé à partir de l'extension, analyser le contenu
            $Content = Get-Content -Path $Path -Raw -ErrorAction Stop
        }
        
        # Déterminer le format à partir du contenu
        return Get-ContentFormat -Content $Content
    }
    catch {
        Write-Error "Erreur lors de la détection du format de configuration: $_"
        return "UNKNOWN"
    }
}
