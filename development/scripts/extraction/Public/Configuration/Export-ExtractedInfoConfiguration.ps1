<#
.SYNOPSIS
    Exporte la configuration du module vers un fichier.
.DESCRIPTION
    Cette fonction permet d'exporter la configuration du module vers un fichier
    au format JSON, YAML, XML ou PSD1.
.PARAMETER Path
    Chemin du fichier de destination pour l'exportation.
.PARAMETER Format
    Format du fichier de sortie (JSON, YAML, XML, PSD1).
    Si non spécifié, le format est déterminé à partir de l'extension du fichier.
.PARAMETER Force
    Si spécifié, écrase le fichier s'il existe déjà.
.PARAMETER IncludeTimestamp
    Si spécifié, inclut un timestamp dans le fichier de configuration.
.PARAMETER ExcludeSystemKeys
    Si spécifié, exclut les clés système (commençant par '_') de l'exportation.
.EXAMPLE
    Export-ExtractedInfoConfiguration -Path "config.json"
    Exporte la configuration vers le fichier config.json au format JSON.
.EXAMPLE
    Export-ExtractedInfoConfiguration -Path "config.xml" -Format "XML" -Force -IncludeTimestamp
    Exporte la configuration vers le fichier config.xml au format XML,
    écrase le fichier s'il existe déjà et inclut un timestamp.
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de création: 2025-05-15
#>
function Export-ExtractedInfoConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,
        
        [Parameter(Position = 1)]
        [ValidateSet("JSON", "YAML", "XML", "PSD1", "AUTO")]
        [string]$Format = "AUTO",
        
        [Parameter()]
        [switch]$Force,
        
        [Parameter()]
        [switch]$IncludeTimestamp,
        
        [Parameter()]
        [switch]$ExcludeSystemKeys
    )
    
    try {
        # Vérifier si le fichier existe déjà
        if (Test-Path -Path $Path -PathType Leaf) {
            if (-not $Force) {
                throw "Le fichier $Path existe déjà. Utilisez -Force pour écraser."
            }
        }
        
        # Déterminer le format si AUTO est spécifié
        if ($Format -eq "AUTO") {
            $extension = [System.IO.Path]::GetExtension($Path).ToLower()
            
            switch ($extension) {
                ".json" { $Format = "JSON" }
                ".yaml" { $Format = "YAML" }
                ".yml"  { $Format = "YAML" }
                ".xml"  { $Format = "XML" }
                ".psd1" { $Format = "PSD1" }
                default {
                    # Format par défaut si l'extension n'est pas reconnue
                    $Format = "JSON"
                    Write-Warning "Extension non reconnue. Utilisation du format JSON par défaut."
                }
            }
        }
        
        # Préparer la configuration à exporter
        $configToExport = $script:ModuleData.Config.Clone()
        
        # Exclure les clés système si demandé
        if ($ExcludeSystemKeys) {
            $keysToRemove = @()
            
            foreach ($key in $configToExport.Keys) {
                if ($key.StartsWith("_")) {
                    $keysToRemove += $key
                }
            }
            
            foreach ($key in $keysToRemove) {
                $configToExport.Remove($key)
            }
        }
        
        # Ajouter un timestamp si demandé
        if ($IncludeTimestamp) {
            $configToExport["ExportedAt"] = [datetime]::Now.ToString("o")
        }
        
        # Exporter la configuration selon le format
        switch ($Format) {
            "JSON" {
                $json = ConvertTo-Json -InputObject $configToExport -Depth 10
                Set-Content -Path $Path -Value $json -Force:$Force
            }
            "YAML" {
                # Vérifier si le module PowerShell-Yaml est installé
                if (-not (Get-Module -ListAvailable -Name "powershell-yaml")) {
                    throw "Le module PowerShell-Yaml est requis pour exporter en YAML. Installez-le avec : Install-Module -Name powershell-yaml -Force"
                }
                
                Import-Module -Name "powershell-yaml" -ErrorAction Stop
                $yaml = ConvertTo-Yaml -Data $configToExport
                Set-Content -Path $Path -Value $yaml -Force:$Force
            }
            "XML" {
                $xml = ConvertTo-Xml -InputObject $configToExport
                $xml.Save($Path)
            }
            "PSD1" {
                $psd1Content = "@{`n"
                
                foreach ($key in $configToExport.Keys) {
                    $value = $configToExport[$key]
                    
                    # Formater la valeur selon son type
                    if ($value -is [string]) {
                        $psd1Content += "    $key = '$value'`n"
                    }
                    elseif ($value -is [bool]) {
                        $psd1Content += "    $key = `$$value`n"
                    }
                    elseif ($value -is [int] -or $value -is [double]) {
                        $psd1Content += "    $key = $value`n"
                    }
                    elseif ($value -is [array] -or $value -is [System.Collections.IList]) {
                        $psd1Content += "    $key = @("
                        
                        foreach ($item in $value) {
                            if ($item -is [string]) {
                                $psd1Content += "'$item', "
                            }
                            else {
                                $psd1Content += "$item, "
                            }
                        }
                        
                        $psd1Content = $psd1Content.TrimEnd(", ")
                        $psd1Content += ")`n"
                    }
                    elseif ($value -is [hashtable] -or $value -is [System.Collections.IDictionary]) {
                        $psd1Content += "    $key = @{`n"
                        
                        foreach ($subKey in $value.Keys) {
                            $subValue = $value[$subKey]
                            
                            if ($subValue -is [string]) {
                                $psd1Content += "        $subKey = '$subValue'`n"
                            }
                            else {
                                $psd1Content += "        $subKey = $subValue`n"
                            }
                        }
                        
                        $psd1Content += "    }`n"
                    }
                    else {
                        $psd1Content += "    $key = '$value'`n"
                    }
                }
                
                $psd1Content += "}"
                
                Set-Content -Path $Path -Value $psd1Content -Force:$Force
            }
        }
        
        Write-Verbose "Configuration exportée vers $Path au format $Format"
    }
    catch {
        Write-Error "Erreur lors de l'exportation de la configuration: $_"
    }
}

# Fonction auxiliaire pour convertir un objet en XML
function ConvertTo-Xml {
    param (
        [Parameter(Mandatory = $true)]
        [object]$InputObject
    )
    
    $xml = New-Object System.Xml.XmlDocument
    $root = $xml.CreateElement("Configuration")
    $xml.AppendChild($root) | Out-Null
    
    # Ajouter chaque élément de la configuration
    foreach ($key in $InputObject.Keys) {
        $value = $InputObject[$key]
        
        # Créer un élément pour la clé
        $element = $xml.CreateElement($key)
        
        # Ajouter la valeur selon son type
        if ($value -is [hashtable] -or $value -is [System.Collections.IDictionary]) {
            # Traiter récursivement les hashtables
            foreach ($subKey in $value.Keys) {
                $subElement = $xml.CreateElement($subKey)
                $subElement.InnerText = $value[$subKey]
                $element.AppendChild($subElement) | Out-Null
            }
        }
        elseif ($value -is [array] -or $value -is [System.Collections.IList]) {
            # Traiter les tableaux
            foreach ($item in $value) {
                $itemElement = $xml.CreateElement("Item")
                $itemElement.InnerText = $item
                $element.AppendChild($itemElement) | Out-Null
            }
        }
        else {
            # Valeur simple
            $element.InnerText = $value
        }
        
        $root.AppendChild($element) | Out-Null
    }
    
    return $xml
}
