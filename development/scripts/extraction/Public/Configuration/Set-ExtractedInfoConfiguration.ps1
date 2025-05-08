<#
.SYNOPSIS
    Modifie la configuration du module.
.DESCRIPTION
    Cette fonction permet de modifier la configuration du module,
    soit en définissant une clé spécifique, soit en remplaçant toute la configuration.
.PARAMETER Key
    Clé de configuration à modifier.
.PARAMETER Value
    Nouvelle valeur pour la clé spécifiée.
.PARAMETER Config
    Hashtable contenant la configuration complète à appliquer.
.PARAMETER PassThru
    Si spécifié, retourne la configuration mise à jour.
.EXAMPLE
    Set-ExtractedInfoConfiguration -Key "DefaultLanguage" -Value "en"
    Définit la langue par défaut à "en".
.EXAMPLE
    Set-ExtractedInfoConfiguration -Config @{ DefaultLanguage = "en"; DefaultSerializationFormat = "Xml" } -PassThru
    Remplace la configuration par celle spécifiée et retourne la nouvelle configuration.
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de création: 2025-05-15
#>
function Set-ExtractedInfoConfiguration {
    [CmdletBinding(DefaultParameterSetName = "ByKey")]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "ByKey")]
        [string]$Key,
        
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = "ByKey")]
        [object]$Value,
        
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "ByConfig")]
        [hashtable]$Config,
        
        [Parameter(ParameterSetName = "ByKey")]
        [Parameter(ParameterSetName = "ByConfig")]
        [switch]$PassThru
    )
    
    # Modifier la configuration selon le paramètre spécifié
    if ($PSCmdlet.ParameterSetName -eq "ByKey") {
        # Modifier une clé spécifique
        $script:ModuleData.Config[$Key] = $Value
        Write-Verbose "Configuration mise à jour: $Key = $Value"
    }
    else {
        # Remplacer toute la configuration
        $script:ModuleData.Config = $Config.Clone()
        Write-Verbose "Configuration complète remplacée"
    }
    
    # Ajouter un timestamp de dernière modification
    $script:ModuleData.Config["_LastModified"] = [datetime]::Now.ToString("o")
    
    # Retourner la configuration si PassThru est spécifié
    if ($PassThru) {
        return $script:ModuleData.Config
    }
}
