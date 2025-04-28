<#
.SYNOPSIS
    Enregistre la configuration dans un fichier.
.DESCRIPTION
    Cette fonction enregistre la configuration dans un fichier au format spÃ©cifiÃ©.
.PARAMETER Config
    La configuration Ã  enregistrer.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration. Par dÃ©faut, il s'agit de config.json dans le rÃ©pertoire config.
.PARAMETER Format
    Format du fichier de configuration. Par dÃ©faut, il s'agit de JSON.
.EXAMPLE
    Save-Configuration -Config $config -ConfigPath "config.json" -Format "JSON"
    Enregistre la configuration dans le fichier config.json au format JSON.
#>
function Save-Configuration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Config,

        [Parameter()]
        [string]$ConfigPath = "$PSScriptRoot\..\..\..\projet\config\config.json",

        [Parameter()]
        [ValidateSet("JSON", "XML", "YAML")]
        [string]$Format = "JSON"
    )

    try {
        # S'assurer que le rÃ©pertoire existe
        $configDir = Split-Path -Path $ConfigPath -Parent
        if (-not (Test-Path $configDir)) {
            New-Item -Path $configDir -ItemType Directory -Force | Out-Null
        }

        # Convertir la configuration au format spÃ©cifiÃ©
        $configString = Convert-ConfigurationToString -Config $Config -Format $Format

        # Enregistrer la configuration dans le fichier
        $configString | Out-File -FilePath $ConfigPath -Encoding UTF8
        Write-Verbose "Configuration enregistrÃ©e dans $ConfigPath au format $Format"
    }
    catch {
        Write-Error "Erreur lors de l'enregistrement de la configuration dans $ConfigPath : $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Convertit une configuration en chaÃ®ne de caractÃ¨res.
.DESCRIPTION
    Cette fonction convertit une configuration en chaÃ®ne de caractÃ¨res au format spÃ©cifiÃ©.
.PARAMETER Config
    La configuration Ã  convertir.
.PARAMETER Format
    Format de la chaÃ®ne de caractÃ¨res. Par dÃ©faut, il s'agit de JSON.
.EXAMPLE
    $configString = Convert-ConfigurationToString -Config $config -Format "JSON"
    Convertit la configuration en chaÃ®ne de caractÃ¨res au format JSON.
#>
function Convert-ConfigurationToString {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Config,

        [Parameter()]
        [ValidateSet("JSON", "XML", "YAML")]
        [string]$Format = "JSON"
    )

    switch ($Format) {
        "JSON" {
            return $Config | ConvertTo-Json -Depth 10
        }
        "XML" {
            # Convertir la configuration en XML
            # Note: Cette implÃ©mentation est simplifiÃ©e et peut ne pas fonctionner pour toutes les configurations
            $xml = New-Object System.Xml.XmlDocument
            $root = $xml.CreateElement("Configuration")
            $xml.AppendChild($root) | Out-Null

            foreach ($key in $Config.Keys) {
                $element = $xml.CreateElement($key)
                $value = $Config[$key]

                if ($value -is [hashtable] -or $value -is [System.Collections.Specialized.OrderedDictionary]) {
                    foreach ($subKey in $value.Keys) {
                        $subElement = $xml.CreateElement($subKey)
                        $subElement.InnerText = $value[$subKey]
                        $element.AppendChild($subElement) | Out-Null
                    }
                }
                else {
                    $element.InnerText = $value
                }

                $root.AppendChild($element) | Out-Null
            }

            return $xml.OuterXml
        }
        "YAML" {
            # Convertir la configuration en YAML
            # Note: Cette implÃ©mentation nÃ©cessite un module YAML tiers
            if (Get-Module -ListAvailable -Name "powershell-yaml") {
                Import-Module "powershell-yaml"
                return $Config | ConvertTo-Yaml
            }
            else {
                Write-Warning "Le module powershell-yaml n'est pas installÃ©. Utilisation du format JSON Ã  la place."
                return $Config | ConvertTo-Json -Depth 10
            }
        }
    }
}
