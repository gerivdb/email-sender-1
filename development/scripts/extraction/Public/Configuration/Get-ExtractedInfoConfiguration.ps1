<#
.SYNOPSIS
    Récupère la configuration actuelle du module.
.DESCRIPTION
    Cette fonction permet de récupérer la configuration actuelle du module,
    soit complète, soit pour une clé spécifique.
.PARAMETER Key
    Clé de configuration spécifique à récupérer. Si non spécifiée, retourne toute la configuration.
.EXAMPLE
    Get-ExtractedInfoConfiguration
    Retourne toute la configuration du module.
.EXAMPLE
    Get-ExtractedInfoConfiguration -Key "DefaultLanguage"
    Retourne la valeur de la clé DefaultLanguage.
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de création: 2025-05-15
#>
function Get-ExtractedInfoConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [string]$Key
    )
    
    # Vérifier si la clé est spécifiée
    if ([string]::IsNullOrEmpty($Key)) {
        # Retourner toute la configuration
        return $script:ModuleData.Config
    }
    else {
        # Vérifier si la clé existe
        if ($script:ModuleData.Config.ContainsKey($Key)) {
            # Retourner la valeur de la clé
            return $script:ModuleData.Config[$Key]
        }
        else {
            Write-Warning "La clé de configuration '$Key' n'existe pas."
            return $null
        }
    }
}
