<#
.SYNOPSIS
    Convertisseur de formats pour le partage des vues.

.DESCRIPTION
    Ce module implémente le convertisseur de formats qui permet de convertir
    les vues entre différents formats (JSON, XML, YAML).

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Classe pour représenter le convertisseur de formats
class FormatConverter {
    # Propriétés
    [hashtable]$SupportedFormats
    [bool]$Debug

    # Constructeur par défaut
    FormatConverter() {
        $this.SupportedFormats = @{
            "JSON" = @{
                Extension      = ".json"
                ContentType    = "application/json"
                ImportFunction = { param($content) return $content | ConvertFrom-Json }
                ExportFunction = { param($object) return $object | ConvertTo-Json -Depth 10 }
            }
            "XML"  = @{
                Extension      = ".xml"
                ContentType    = "application/xml"
                ImportFunction = { param($content) return [xml]$content }
                ExportFunction = {
                    param($object)
                    $xmlSettings = New-Object System.Xml.XmlWriterSettings
                    $xmlSettings.Indent = $true
                    $xmlSettings.IndentChars = "  "
                    $stringBuilder = New-Object System.Text.StringBuilder
                    $xmlWriter = [System.Xml.XmlWriter]::Create($stringBuilder, $xmlSettings)

                    # Convertir l'objet en XML
                    $this.ConvertObjectToXml($xmlWriter, "Root", $object)

                    $xmlWriter.Flush()
                    $xmlWriter.Close()
                    return $stringBuilder.ToString()
                }
            }
            "YAML" = @{
                Extension      = ".yaml"
                ContentType    = "application/yaml"
                ImportFunction = {
                    param($content)
                    # Utiliser PowerShell-YAML si disponible
                    if (Get-Module -ListAvailable -Name "powershell-yaml") {
                        Import-Module -Name "powershell-yaml"
                        return ConvertFrom-Yaml -Yaml $content
                    } else {
                        # Fallback vers JSON si YAML n'est pas disponible
                        return $content | ConvertFrom-Json
                    }
                }
                ExportFunction = {
                    param($object)
                    # Utiliser PowerShell-YAML si disponible
                    if (Get-Module -ListAvailable -Name "powershell-yaml") {
                        Import-Module -Name "powershell-yaml"
                        return ConvertTo-Yaml -Data $object
                    } else {
                        # Fallback vers JSON si YAML n'est pas disponible
                        return $object | ConvertTo-Json -Depth 10
                    }
                }
            }
        }
        $this.Debug = $false
    }

    # Constructeur avec paramètres
    FormatConverter([bool]$debug) {
        $this.SupportedFormats = @{
            "JSON" = @{
                Extension      = ".json"
                ContentType    = "application/json"
                ImportFunction = { param($content) return $content | ConvertFrom-Json }
                ExportFunction = { param($object) return $object | ConvertTo-Json -Depth 10 }
            }
            "XML"  = @{
                Extension      = ".xml"
                ContentType    = "application/xml"
                ImportFunction = { param($content) return [xml]$content }
                ExportFunction = {
                    param($object)
                    $xmlSettings = New-Object System.Xml.XmlWriterSettings
                    $xmlSettings.Indent = $true
                    $xmlSettings.IndentChars = "  "
                    $stringBuilder = New-Object System.Text.StringBuilder
                    $xmlWriter = [System.Xml.XmlWriter]::Create($stringBuilder, $xmlSettings)

                    # Convertir l'objet en XML
                    $this.ConvertObjectToXml($xmlWriter, "Root", $object)

                    $xmlWriter.Flush()
                    $xmlWriter.Close()
                    return $stringBuilder.ToString()
                }
            }
            "YAML" = @{
                Extension      = ".yaml"
                ContentType    = "application/yaml"
                ImportFunction = {
                    param($content)
                    # Utiliser PowerShell-YAML si disponible
                    if (Get-Module -ListAvailable -Name "powershell-yaml") {
                        Import-Module -Name "powershell-yaml"
                        return ConvertFrom-Yaml -Yaml $content
                    } else {
                        # Fallback vers JSON si YAML n'est pas disponible
                        return $content | ConvertFrom-Json
                    }
                }
                ExportFunction = {
                    param($object)
                    # Utiliser PowerShell-YAML si disponible
                    if (Get-Module -ListAvailable -Name "powershell-yaml") {
                        Import-Module -Name "powershell-yaml"
                        return ConvertTo-Yaml -Data $object
                    } else {
                        # Fallback vers JSON si YAML n'est pas disponible
                        return $object | ConvertTo-Json -Depth 10
                    }
                }
            }
        }
        $this.Debug = $debug
    }

    # Méthode pour écrire des messages de débogage
    [void] WriteDebug([string]$message) {
        if ($this.Debug) {
            Write-Host "[DEBUG] [FormatConverter] $message" -ForegroundColor Cyan
        }
    }

    # Méthode pour convertir un objet en XML
    [void] ConvertObjectToXml([System.Xml.XmlWriter]$writer, [string]$elementName, [object]$value) {
        if ($null -eq $value) {
            $writer.WriteStartElement($elementName)
            $writer.WriteAttributeString("xsi:nil", "true")
            $writer.WriteEndElement()
            return
        }

        $writer.WriteStartElement($elementName)

        if ($value -is [hashtable] -or $value -is [System.Collections.IDictionary]) {
            foreach ($key in $value.Keys) {
                $this.ConvertObjectToXml($writer, $key, $value[$key])
            }
        } elseif ($value -is [System.Collections.IEnumerable] -and $value -isnot [string]) {
            $index = 0
            foreach ($item in $value) {
                $this.ConvertObjectToXml($writer, "Item", $item)
                $index++
            }
        } elseif ($value -is [PSCustomObject]) {
            foreach ($property in $value.PSObject.Properties) {
                $this.ConvertObjectToXml($writer, $property.Name, $property.Value)
            }
        } else {
            $writer.WriteString($value.ToString())
        }

        $writer.WriteEndElement()
    }

    # Méthode pour convertir un contenu d'un format à un autre
    [string] ConvertFormat([string]$content, [string]$sourceFormat, [string]$targetFormat) {
        $this.WriteDebug("Conversion du format $sourceFormat vers $targetFormat")

        # Vérifier si les formats sont supportés
        if (-not $this.SupportedFormats.ContainsKey($sourceFormat)) {
            throw "Format source non supporté: $sourceFormat"
        }

        if (-not $this.SupportedFormats.ContainsKey($targetFormat)) {
            throw "Format cible non supporté: $targetFormat"
        }

        # Si les formats sont identiques, retourner le contenu tel quel
        if ($sourceFormat -eq $targetFormat) {
            return $content
        }

        try {
            # Importer le contenu dans le format source
            $importFunction = $this.SupportedFormats[$sourceFormat].ImportFunction
            $object = & $importFunction $content

            # Exporter l'objet dans le format cible
            $exportFunction = $this.SupportedFormats[$targetFormat].ExportFunction
            $result = & $exportFunction $object

            return $result
        } catch {
            $this.WriteDebug("Erreur lors de la conversion: $_")
            throw "Erreur lors de la conversion de $sourceFormat vers $targetFormat - $($_.Exception.Message)"
        }
    }

    # Méthode pour convertir un fichier d'un format à un autre
    [string] ConvertFile([string]$inputPath, [string]$outputPath, [string]$targetFormat) {
        $this.WriteDebug("Conversion du fichier $inputPath vers $targetFormat")

        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $inputPath)) {
            throw "Le fichier spécifié n'existe pas: $inputPath"
        }

        # Déterminer le format source à partir de l'extension du fichier
        $extension = [System.IO.Path]::GetExtension($inputPath).ToLower()
        $sourceFormat = $null

        foreach ($format in $this.SupportedFormats.Keys) {
            if ($this.SupportedFormats[$format].Extension -eq $extension) {
                $sourceFormat = $format
                break
            }
        }

        if ($null -eq $sourceFormat) {
            throw "Format source non reconnu pour l'extension: $extension"
        }

        # Vérifier si le format cible est supporté
        if (-not $this.SupportedFormats.ContainsKey($targetFormat)) {
            throw "Format cible non supporté: $targetFormat"
        }

        try {
            # Lire le contenu du fichier
            $content = Get-Content -Path $inputPath -Raw

            # Convertir le contenu
            $result = $this.ConvertFormat($content, $sourceFormat, $targetFormat)

            # Si le chemin de sortie n'est pas spécifié, générer un nom de fichier
            if ([string]::IsNullOrEmpty($outputPath)) {
                $directory = [System.IO.Path]::GetDirectoryName($inputPath)
                $fileName = [System.IO.Path]::GetFileNameWithoutExtension($inputPath)
                $targetExtension = $this.SupportedFormats[$targetFormat].Extension
                $outputPath = Join-Path -Path $directory -ChildPath "$fileName$targetExtension"
            }

            # Écrire le résultat dans le fichier de sortie
            $result | Out-File -FilePath $outputPath -Encoding utf8

            return $outputPath
        } catch {
            $this.WriteDebug("Erreur lors de la conversion du fichier: $_")
            throw "Erreur lors de la conversion du fichier $inputPath vers $targetFormat - $($_.Exception.Message)"
        }
    }

    # Méthode pour détecter automatiquement le format d'un contenu
    [string] DetectFormat([string]$content) {
        $this.WriteDebug("Détection automatique du format")

        # Vérifier si le contenu est au format JSON
        try {
            $content | ConvertFrom-Json | Out-Null
            return "JSON"
        } catch {}

        # Vérifier si le contenu est au format XML
        try {
            [xml]$content | Out-Null
            return "XML"
        } catch {}

        # Vérifier si le contenu est au format YAML
        if (Get-Module -ListAvailable -Name "powershell-yaml") {
            try {
                Import-Module -Name "powershell-yaml"
                ConvertFrom-Yaml -Yaml $content | Out-Null
                return "YAML"
            } catch {}
        }

        # Format non reconnu
        return $null
    }
}

# Fonction pour créer un nouveau convertisseur de formats
function New-FormatConverter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    return [FormatConverter]::new($EnableDebug)
}

# Fonction pour convertir un contenu d'un format à un autre
function Convert-Format {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [string]$SourceFormat,

        [Parameter(Mandatory = $true)]
        [string]$TargetFormat,

        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    $converter = New-FormatConverter -EnableDebug:$EnableDebug
    return $converter.ConvertFormat($Content, $SourceFormat, $TargetFormat)
}

# Fonction pour convertir un fichier d'un format à un autre
function Convert-FormatFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputPath,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $true)]
        [string]$TargetFormat,

        [Parameter(Mandatory = $false)]
        [switch]$EnableDebug
    )

    $converter = New-FormatConverter -EnableDebug:$EnableDebug
    return $converter.ConvertFile($InputPath, $OutputPath, $TargetFormat)
}

# Exporter les fonctions
# Export-ModuleMember -Function New-FormatConverter, Convert-Format, Convert-FormatFile
