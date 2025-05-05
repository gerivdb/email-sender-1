<#
.SYNOPSIS
    Fonctions auxiliaires pour la dÃ©tection et l'analyse des formats de configuration.
.DESCRIPTION
    Ce fichier contient des fonctions privÃ©es utilisÃ©es pour dÃ©tecter le format
    des fichiers de configuration et analyser leur structure.
#>

function Get-FileExtensionFormat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()

    switch ($extension) {
        ".json" { return "JSON" }
        ".yaml" { return "YAML" }
        ".yml" { return "YAML" }
        ".xml" { return "XML" }
        ".ini" { return "INI" }
        ".psd1" { return "PSD1" }
        default { return $null }
    }
}

function Test-JsonContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    try {
        $null = ConvertFrom-Json -InputObject $Content -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Test-YamlContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    # VÃ©rifier si le contenu commence par des indicateurs YAML typiques
    if ($Content -match '^\s*---' -or
        $Content -match '^\s*[a-zA-Z0-9_-]+\s*:' -or
        $Content -match '^\s*-\s+[a-zA-Z0-9_-]+\s*:') {

        # Si le module PowerShell-Yaml est disponible, essayer de parser le contenu
        if (Get-Module -ListAvailable -Name 'powershell-yaml') {
            try {
                Import-Module -Name 'powershell-yaml' -ErrorAction Stop
                $null = ConvertFrom-Yaml -Yaml $Content -ErrorAction Stop
                return $true
            } catch {
                # Si l'analyse Ã©choue, ce n'est probablement pas du YAML valide
                return $false
            }
        }

        # Si le module n'est pas disponible, se fier aux indicateurs
        return $true
    }

    return $false
}

function Test-XmlContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    try {
        $null = [xml]$Content
        return $true
    } catch {
        return $false
    }
}

function Test-IniContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    # VÃ©rifier si le contenu correspond au format INI (sections entre crochets suivies de paires clÃ©=valeur)
    # Utiliser le multiline mode pour que ^ et $ correspondent au dÃ©but et Ã  la fin de chaque ligne
    return $Content -match '(?m)^\s*\[[^\]]+\]\s*$' -and $Content -match '(?m)^\s*[^=]+=.*$'
}

function Test-Psd1Content {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    # VÃ©rifier si le contenu ressemble Ã  un fichier de donnÃ©es PowerShell
    return $Content -match '@\s*{' -and $Content -match '}'
}

function Get-ContentFormat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    # Tester chaque format dans l'ordre de prioritÃ©
    if (Test-JsonContent -Content $Content) {
        return "JSON"
    } elseif (Test-YamlContent -Content $Content) {
        return "YAML"
    } elseif (Test-XmlContent -Content $Content) {
        return "XML"
    } elseif (Test-Psd1Content -Content $Content) {
        return "PSD1"
    } elseif (Test-IniContent -Content $Content) {
        return "INI"
    }

    return "UNKNOWN"
}

function Convert-ConfigToHashtable {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [string]$Format
    )

    switch ($Format) {
        "JSON" {
            try {
                $json = ConvertFrom-Json -InputObject $Content -ErrorAction Stop
                return ConvertTo-Hashtable -InputObject $json
            } catch {
                throw "Erreur lors de la conversion du contenu JSON en hashtable: $_"
            }
        }
        "YAML" {
            try {
                if (-not (Get-Module -ListAvailable -Name 'powershell-yaml')) {
                    throw "Le module PowerShell-Yaml est requis pour traiter les fichiers YAML."
                }

                Import-Module -Name 'powershell-yaml' -ErrorAction Stop
                $yaml = ConvertFrom-Yaml -Yaml $Content -ErrorAction Stop
                return ConvertTo-Hashtable -InputObject $yaml
            } catch {
                throw "Erreur lors de la conversion du contenu YAML en hashtable: $_"
            }
        }
        "XML" {
            try {
                $xml = [xml]$Content
                return ConvertTo-Hashtable -InputObject $xml
            } catch {
                throw "Erreur lors de la conversion du contenu XML en hashtable: $_"
            }
        }
        "INI" {
            try {
                return ConvertFrom-Ini -Content $Content
            } catch {
                throw "Erreur lors de la conversion du contenu INI en hashtable: $_"
            }
        }
        "PSD1" {
            try {
                $tempFile = [System.IO.Path]::GetTempFileName() + ".psd1"
                Set-Content -Path $tempFile -Value $Content
                $data = Import-PowerShellDataFile -Path $tempFile -ErrorAction Stop
                Remove-Item -Path $tempFile -Force
                return $data
            } catch {
                throw "Erreur lors de la conversion du contenu PSD1 en hashtable: $_"
            }
        }
        default {
            throw "Format non pris en charge: $Format"
        }
    }
}

function ConvertTo-Hashtable {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$InputObject
    )

    # Si l'objet est dÃ©jÃ  un hashtable, le retourner tel quel
    if ($InputObject -is [hashtable]) {
        return $InputObject
    }

    # Si l'objet est un PSCustomObject, le convertir en hashtable
    if ($InputObject -is [PSCustomObject]) {
        $hashtable = @{}
        foreach ($property in $InputObject.PSObject.Properties) {
            $hashtable[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
        }
        return $hashtable
    }

    # Si l'objet est un tableau, convertir chaque Ã©lÃ©ment
    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        $array = @()
        foreach ($item in $InputObject) {
            $array += ConvertTo-Hashtable -InputObject $item
        }
        return $array
    }

    # Pour les autres types, retourner l'objet tel quel
    return $InputObject
}

function ConvertFrom-Ini {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $ini = @{}
    $currentSection = $ini

    # Diviser le contenu en lignes et traiter chaque ligne
    $lines = $Content -split "`r`n|`r|`n"

    foreach ($line in $lines) {
        # Ignorer les lignes vides et les commentaires
        if ([string]::IsNullOrWhiteSpace($line) -or $line.Trim().StartsWith(';') -or $line.Trim().StartsWith('#')) {
            continue
        }

        # Traiter les sections
        if ($line -match '^\s*\[([^\]]+)\]\s*$') {
            $sectionName = $matches[1].Trim()
            if (-not $ini.ContainsKey($sectionName)) {
                $ini[$sectionName] = @{}
            }
            $currentSection = $ini[$sectionName]
            continue
        }

        # Traiter les paires clÃ©=valeur
        if ($line -match '^\s*([^=]+?)\s*=\s*(.*?)\s*$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()

            # Convertir la valeur si possible
            if ($value -eq 'true' -or $value -eq 'yes') {
                $value = $true
            } elseif ($value -eq 'false' -or $value -eq 'no') {
                $value = $false
            } elseif ($value -match '^\d+$') {
                $value = [int]$value
            } elseif ($value -match '^\d+\.\d+$') {
                $value = [double]$value
            }

            $currentSection[$key] = $value
        }
    }

    return $ini
}
