<#
.SYNOPSIS
    Enregistre la configuration dans un fichier.
.DESCRIPTION
    Cette fonction enregistre la configuration dans un fichier au format spÃƒÂ©cifiÃƒÂ©.
.PARAMETER Config
    La configuration ÃƒÂ  enregistrer.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration. Par dÃƒÂ©faut, il s'agit de config.json dans le rÃƒÂ©pertoire config.
.PARAMETER Format
    Format du fichier de configuration. Par dÃƒÂ©faut, il s'agit de JSON.
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
        # S'assurer que le rÃƒÂ©pertoire existe
        $configDir = Split-Path -Path $ConfigPath -Parent
        if (-not (Test-Path $configDir)) {
            New-Item -Path $configDir -ItemType Directory -Force | Out-Null
        }

        # Convertir la configuration au format spÃƒÂ©cifiÃƒÂ©
        $configString = Convert-ConfigurationToString -Config $Config -Format $Format

        # Enregistrer la configuration dans le fichier
        $configString | Out-File -FilePath $ConfigPath -Encoding UTF8
        Write-Verbose "Configuration enregistrÃƒÂ©e dans $ConfigPath au format $Format"
    }
    catch {
        Write-Error "Erreur lors de l'enregistrement de la configuration dans $ConfigPath : $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Convertit une configuration en chaÃƒÂ®ne de caractÃƒÂ¨res.
.DESCRIPTION
    Cette fonction convertit une configuration en chaÃƒÂ®ne de caractÃƒÂ¨res au format spÃƒÂ©cifiÃƒÂ©.
.PARAMETER Config
    La configuration ÃƒÂ  convertir.
.PARAMETER Format
    Format de la chaÃƒÂ®ne de caractÃƒÂ¨res. Par dÃƒÂ©faut, il s'agit de JSON.
.EXAMPLE
    $configString = Convert-ConfigurationToString -Config $config -Format "JSON"
    Convertit la configuration en chaÃƒÂ®ne de caractÃƒÂ¨res au format JSON.
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
            # Note: Cette implÃƒÂ©mentation est simplifiÃƒÂ©e et peut ne pas fonctionner pour toutes les configurations
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
            # Note: Cette implÃƒÂ©mentation nÃƒÂ©cessite un module YAML tiers
            if (Get-Module -ListAvailable -Name "powershell-yaml") {
                Import-Module "powershell-yaml"
                return $Config | ConvertTo-Yaml
            }
            else {
                Write-Warning "Le module powershell-yaml n'est pas installÃƒÂ©. Utilisation du format JSON ÃƒÂ  la place."
                return $Config | ConvertTo-Json -Depth 10
            }
        }
    }
}
