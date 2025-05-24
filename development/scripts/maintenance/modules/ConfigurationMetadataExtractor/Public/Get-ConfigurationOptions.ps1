<#
.SYNOPSIS
    DÃ©tecte les options de configuration dans un fichier de configuration.
.DESCRIPTION
    Cette fonction analyse un fichier de configuration et extrait toutes les options
    disponibles, avec leurs types, valeurs par dÃ©faut et autres mÃ©tadonnÃ©es.
.PARAMETER Path
    Chemin vers le fichier de configuration Ã  analyser.
.PARAMETER Content
    Contenu du fichier de configuration Ã  analyser. Si spÃ©cifiÃ©, Path est ignorÃ©.
.PARAMETER Format
    Format du fichier de configuration. Si non spÃ©cifiÃ©, il sera dÃ©tectÃ© automatiquement.
.PARAMETER IncludeValues
    Indique si les valeurs actuelles des options doivent Ãªtre incluses dans les rÃ©sultats.
.PARAMETER Flatten
    Indique si les options doivent Ãªtre retournÃ©es sous forme de liste plate plutÃ´t que hiÃ©rarchique.
.EXAMPLE
    Get-ConfigurationOptions -Path "config.json"
    DÃ©tecte les options de configuration dans le fichier config.json.
.EXAMPLE
    Get-ConfigurationOptions -Content '{"key": "value"}' -Format "JSON" -IncludeValues
    DÃ©tecte les options de configuration dans le contenu JSON fourni et inclut leurs valeurs.
.OUTPUTS
    System.Collections.Hashtable
#>
function Get-ConfigurationOptions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "Path")]
        [string]$Path,

        [Parameter(Mandatory = $true, ParameterSetName = "Content")]
        [string]$Content,

        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "YAML", "XML", "INI", "PSD1", "AUTO")]
        [string]$Format = "AUTO",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeValues,

        [Parameter(Mandatory = $false)]
        [switch]$Flatten
    )

    try {
        # Si le chemin est spÃ©cifiÃ©, lire le contenu du fichier
        if ($PSCmdlet.ParameterSetName -eq "Path") {
            if (-not (Test-Path -Path $Path -PathType Leaf)) {
                throw "Le fichier spÃ©cifiÃ© n'existe pas: $Path"
            }

            $Content = Get-Content -Path $Path -Raw -ErrorAction Stop
        }

        # VÃ©rifier que le contenu n'est pas vide
        if ([string]::IsNullOrWhiteSpace($Content)) {
            throw "Le contenu est vide ou ne contient que des espaces blancs."
        }

        # DÃ©terminer le format si nÃ©cessaire
        if ($Format -eq "AUTO") {
            if ($PSCmdlet.ParameterSetName -eq "Path") {
                $Format = Get-ConfigurationFormat -Path $Path
            } else {
                $Format = Get-ConfigurationFormat -Content $Content
            }

            if ($Format -eq "UNKNOWN") {
                throw "Impossible de dÃ©terminer le format de configuration."
            }
        }

        # Convertir le contenu en hashtable
        $config = Convert-ConfigToHashtable -Content $Content -Format $Format

        if ($null -eq $config) {
            throw "Erreur lors de la conversion du contenu en hashtable."
        }

        # Extraire les options
        $options = @{}

        if ($Flatten) {
            $options = Export-FlatOptions -Config $config -IncludeValues:$IncludeValues
        } else {
            $options = Export-HierarchicalOptions -Config $config -IncludeValues:$IncludeValues
        }

        return $options
    } catch {
        Write-Error "Erreur lors de la dÃ©tection des options de configuration: $_"
        return $null
    }
}

function Export-FlatOptions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Config,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeValues,

        [Parameter(Mandatory = $false)]
        [string]$Prefix = ""
    )

    $options = @{}

    # Si l'objet est un hashtable ou un PSCustomObject, extraire ses propriÃ©tÃ©s
    if ($Config -is [hashtable] -or $Config -is [PSCustomObject]) {
        $properties = @()

        if ($Config -is [hashtable]) {
            $properties = $Config.Keys
        } else {
            $properties = $Config.PSObject.Properties.Name
        }

        foreach ($key in $properties) {
            $value = if ($Config -is [hashtable]) { $Config[$key] } else { $Config.$key }
            $fullKey = if ($Prefix -eq "") { $key } else { "$Prefix.$key" }

            # Si la valeur est un hashtable ou un PSCustomObject, extraire rÃ©cursivement
            if ($value -is [hashtable] -or $value -is [PSCustomObject]) {
                $nestedOptions = Export-FlatOptions -Config $value -IncludeValues:$IncludeValues -Prefix $fullKey
                foreach ($nestedKey in $nestedOptions.Keys) {
                    $options[$nestedKey] = $nestedOptions[$nestedKey]
                }
            }
            # Si la valeur est un tableau, extraire chaque Ã©lÃ©ment si nÃ©cessaire
            elseif ($value -is [array]) {
                $option = @{
                    Type        = "Array"
                    ElementType = if ($value.Count -gt 0) { $value[0].GetType().Name } else { "Unknown" }
                    IsComplex   = $false
                }

                if ($value.Count -gt 0 -and ($value[0] -is [hashtable] -or $value[0] -is [PSCustomObject])) {
                    $option.IsComplex = $true
                    $option.ElementType = "Object"

                    # Extraire les options pour le premier Ã©lÃ©ment du tableau comme exemple
                    $elementOptions = Export-FlatOptions -Config $value[0] -IncludeValues:$IncludeValues -Prefix "$fullKey[0]"
                    foreach ($elementKey in $elementOptions.Keys) {
                        $options[$elementKey] = $elementOptions[$elementKey]
                    }
                }

                if ($IncludeValues) {
                    $option.Value = $value
                }

                $options[$fullKey] = $option
            }
            # Sinon, ajouter l'option directement
            else {
                $option = @{
                    Type = if ($null -eq $value) { "null" } else { $value.GetType().Name }
                }

                if ($IncludeValues) {
                    $option.Value = $value
                }

                $options[$fullKey] = $option
            }
        }
    }
    # Si l'objet est un tableau, extraire chaque Ã©lÃ©ment
    elseif ($Config -is [array]) {
        $option = @{
            Type        = "Array"
            ElementType = if ($Config.Count -gt 0) { $Config[0].GetType().Name } else { "Unknown" }
            IsComplex   = $false
        }

        if ($Config.Count -gt 0 -and ($Config[0] -is [hashtable] -or $Config[0] -is [PSCustomObject])) {
            $option.IsComplex = $true
            $option.ElementType = "Object"

            # Extraire les options pour le premier Ã©lÃ©ment du tableau comme exemple
            $elementOptions = Export-FlatOptions -Config $Config[0] -IncludeValues:$IncludeValues -Prefix "$Prefix[0]"
            foreach ($elementKey in $elementOptions.Keys) {
                $options[$elementKey] = $elementOptions[$elementKey]
            }
        }

        if ($IncludeValues) {
            $option.Value = $Config
        }

        $options[$Prefix] = $option
    }
    # Sinon, ajouter l'option directement
    else {
        $option = @{
            Type = if ($null -eq $Config) { "null" } else { $Config.GetType().Name }
        }

        if ($IncludeValues) {
            $option.Value = $Config
        }

        $options[$Prefix] = $option
    }

    return $options
}

function Export-HierarchicalOptions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Config,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeValues
    )

    # Si l'objet est un hashtable ou un PSCustomObject, extraire ses propriÃ©tÃ©s
    if ($Config -is [hashtable] -or $Config -is [PSCustomObject]) {
        $options = @{}
        $properties = @()

        if ($Config -is [hashtable]) {
            $properties = $Config.Keys
        } else {
            $properties = $Config.PSObject.Properties.Name
        }

        foreach ($key in $properties) {
            $value = if ($Config -is [hashtable]) { $Config[$key] } else { $Config.$key }

            # Si la valeur est un hashtable ou un PSCustomObject, extraire rÃ©cursivement
            if ($value -is [hashtable] -or $value -is [PSCustomObject]) {
                $options[$key] = @{
                    Type       = "Object"
                    Properties = Export-HierarchicalOptions -Config $value -IncludeValues:$IncludeValues
                }

                if ($IncludeValues) {
                    $options[$key].Value = $value
                }
            }
            # Si la valeur est un tableau, extraire chaque Ã©lÃ©ment si nÃ©cessaire
            elseif ($value -is [array]) {
                $options[$key] = @{
                    Type        = "Array"
                    ElementType = if ($value.Count -gt 0) { $value[0].GetType().Name } else { "Unknown" }
                    IsComplex   = $false
                }

                if ($value.Count -gt 0 -and ($value[0] -is [hashtable] -or $value[0] -is [PSCustomObject])) {
                    $options[$key].IsComplex = $true
                    $options[$key].ElementType = "Object"
                    $options[$key].ElementProperties = Export-HierarchicalOptions -Config $value[0] -IncludeValues:$IncludeValues
                }

                if ($IncludeValues) {
                    $options[$key].Value = $value
                }
            }
            # Sinon, ajouter l'option directement
            else {
                $options[$key] = @{
                    Type = if ($null -eq $value) { "null" } else { $value.GetType().Name }
                }

                if ($IncludeValues) {
                    $options[$key].Value = $value
                }
            }
        }

        return $options
    }
    # Si l'objet est un tableau, extraire chaque Ã©lÃ©ment
    elseif ($Config -is [array]) {
        $options = @{
            Type        = "Array"
            ElementType = if ($Config.Count -gt 0) { $Config[0].GetType().Name } else { "Unknown" }
            IsComplex   = $false
        }

        if ($Config.Count -gt 0 -and ($Config[0] -is [hashtable] -or $Config[0] -is [PSCustomObject])) {
            $options.IsComplex = $true
            $options.ElementType = "Object"
            $options.ElementProperties = Export-HierarchicalOptions -Config $Config[0] -IncludeValues:$IncludeValues
        }

        if ($IncludeValues) {
            $options.Value = $Config
        }

        return $options
    }
    # Sinon, retourner directement les informations sur l'objet
    else {
        $options = @{
            Type = if ($null -eq $Config) { "null" } else { $Config.GetType().Name }
        }

        if ($IncludeValues) {
            $options.Value = $Config
        }

        return $options
    }
}

