using namespace System.Collections.Generic

<#
.SYNOPSIS
    Classe statique pour la conversion entre diffÃ©rents formats.
.DESCRIPTION
    Fournit des mÃ©thodes statiques pour convertir des informations extraites
    entre diffÃ©rents formats (JSON, XML, CSV, YAML, etc.).
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>

# Importer les dÃ©pendances
. "$PSScriptRoot\..\models\BaseExtractedInfo.ps1"
. "$PSScriptRoot\..\models\SerializableExtractedInfo.ps1"

class FormatConverter {
    # MÃ©thode pour convertir un objet en JSON
    static [string] ToJson([object]$obj, [int]$depth = 10) {
        if ($null -eq $obj) {
            return "null"
        }

        # Si l'objet implÃ©mente ISerializable, utiliser sa mÃ©thode ToJson
        if ($obj -is [SerializableExtractedInfo]) {
            return $obj.ToJson($depth)
        }

        # Sinon, utiliser ConvertTo-Json
        return ConvertTo-Json -InputObject $obj -Depth $depth
    }

    # MÃ©thode pour convertir un objet en XML
    static [string] ToXml([object]$obj) {
        if ($null -eq $obj) {
            return "<null />"
        }

        # Si l'objet implÃ©mente ISerializable, utiliser sa mÃ©thode ToXml
        if ($obj -is [SerializableExtractedInfo]) {
            return $obj.ToXml()
        }

        # Sinon, utiliser Export-Clixml
        $tempFile = [System.IO.Path]::GetTempFileName()
        $obj | Export-Clixml -Path $tempFile -Encoding UTF8
        $xml = Get-Content -Path $tempFile -Raw
        Remove-Item -Path $tempFile -Force

        return $xml
    }

    # MÃ©thode pour convertir un objet en CSV
    static [string] ToCsv([object]$obj) {
        if ($null -eq $obj) {
            return ""
        }

        # Si l'objet implÃ©mente ISerializable, utiliser sa mÃ©thode ToCsv
        if ($obj -is [SerializableExtractedInfo]) {
            return $obj.ToCsv()
        }

        # Sinon, utiliser Export-Csv
        $tempFile = [System.IO.Path]::GetTempFileName()
        $obj | Export-Csv -Path $tempFile -NoTypeInformation -Encoding UTF8
        $csv = Get-Content -Path $tempFile -Raw
        Remove-Item -Path $tempFile -Force

        return $csv
    }

    # MÃ©thode pour convertir un objet en YAML (implÃ©mentation simplifiÃ©e)
    static [string] ToYaml([object]$obj) {
        if ($null -eq $obj) {
            return "null"
        }

        # Si l'objet implÃ©mente ISerializable, utiliser sa mÃ©thode ToYaml
        if ($obj -is [SerializableExtractedInfo]) {
            return $obj.ToYaml()
        }

        # Sinon, convertir en JSON puis en YAML (implÃ©mentation simplifiÃ©e)
        $json = [FormatConverter]::ToJson($obj)
        $yaml = [FormatConverter]::ConvertJsonToYaml($json)

        return $yaml
    }

    # MÃ©thode pour convertir JSON en YAML (implÃ©mentation simplifiÃ©e)
    static [string] ConvertJsonToYaml([string]$json) {
        if ([string]::IsNullOrEmpty($json)) {
            return ""
        }

        try {
            $obj = ConvertFrom-Json -InputObject $json

            # Convertir l'objet en YAML
            $yaml = "---`n"
            $yaml += [FormatConverter]::ObjectToYaml($obj, 0)

            return $yaml
        } catch {
            throw "Erreur lors de la conversion JSON vers YAML: $_"
        }
    }

    # MÃ©thode rÃ©cursive pour convertir un objet en YAML
    static hidden [string] ObjectToYaml([object]$obj, [int]$indent = 0) {
        $yaml = ""
        $indentStr = " " * $indent

        if ($null -eq $obj) {
            return "${indentStr}null`n"
        }

        if ($obj -is [string] -or $obj -is [int] -or $obj -is [double] -or $obj -is [bool]) {
            return "${indentStr}$obj`n"
        }

        if ($obj -is [array]) {
            if ($obj.Count -eq 0) {
                return "${indentStr}[]`n"
            }

            foreach ($item in $obj) {
                $yaml += "${indentStr}- "
                $yaml += [FormatConverter]::ObjectToYaml($item, $indent + 2).TrimStart()
            }

            return $yaml
        }

        if ($obj -is [hashtable] -or $obj -is [PSCustomObject]) {
            $properties = if ($obj -is [hashtable]) { $obj.Keys } else { $obj.PSObject.Properties.Name }

            foreach ($prop in $properties) {
                $value = if ($obj -is [hashtable]) { $obj[$prop] } else { $obj.$prop }

                if ($value -is [array] -or $value -is [hashtable] -or $value -is [PSCustomObject]) {
                    $yaml += "${indentStr}${prop}:`n"
                    $yaml += [FormatConverter]::ObjectToYaml($value, $indent + 2)
                } else {
                    $yaml += "${indentStr}${prop}: "
                    $yaml += [FormatConverter]::ObjectToYaml($value, 0).Trim()
                }
            }

            return $yaml
        }

        return "${indentStr}$obj`n"
    }

    # MÃ©thode pour convertir YAML en JSON (implÃ©mentation simplifiÃ©e)
    static [string] ConvertYamlToJson([string]$yaml) {
        if ([string]::IsNullOrEmpty($yaml)) {
            return ""
        }

        try {
            # Convertir YAML en objet (implÃ©mentation simplifiÃ©e)
            $obj = [FormatConverter]::YamlToObject($yaml)

            # Convertir l'objet en JSON
            return [FormatConverter]::ToJson($obj)
        } catch {
            throw "Erreur lors de la conversion YAML vers JSON: $_"
        }
    }

    # MÃ©thode pour convertir YAML en objet (implÃ©mentation simplifiÃ©e)
    static hidden [object] YamlToObject([string]$yaml) {
        # Note: Dans une implÃ©mentation rÃ©elle, on utiliserait une bibliothÃ¨que YAML
        # comme YamlDotNet. Cette implÃ©mentation est trÃ¨s simplifiÃ©e.

        $result = [PSCustomObject]@{}
        $lines = $yaml -split "`n" | Where-Object { $_ -ne "" -and $_ -ne "---" }

        $currentObject = $result
        $stack = @()
        $currentIndent = 0

        foreach ($line in $lines) {
            if ($line -match "^\s*#") {
                continue  # Ignorer les commentaires
            }

            if ($line -match "^(\s*)") {
                $indent = $Matches[1].Length
            } else {
                $indent = 0
            }
            $line = $line.TrimStart()

            if ($indent -lt $currentIndent) {
                # Remonter dans la pile
                while ($stack.Count -gt 0 -and $indent -lt $currentIndent) {
                    $currentObject = $stack[-1]
                    $stack = $stack[0..($stack.Count - 2)]
                    $currentIndent -= 2
                }
            }

            if ($line -match "^([^:]+):\s*(.*)$") {
                $key = $Matches[1].Trim()
                $value = $Matches[2].Trim()

                if ([string]::IsNullOrEmpty($value)) {
                    # Nouvelle section
                    $newObj = [PSCustomObject]@{}
                    $currentObject | Add-Member -MemberType NoteProperty -Name $key -Value $newObj
                    $stack += $currentObject
                    $currentObject = $newObj
                    $currentIndent = $indent + 2
                } else {
                    # Valeur simple
                    $currentObject | Add-Member -MemberType NoteProperty -Name $key -Value $value
                }
            } elseif ($line -match "^- (.*)$") {
                # Ã‰lÃ©ment de liste
                $value = $Matches[1].Trim()
                # Note: Cette implÃ©mentation simplifiÃ©e ne gÃ¨re pas correctement les listes
            }
        }

        return $result
    }

    # MÃ©thode pour convertir XML en JSON
    static [string] ConvertXmlToJson([string]$xml) {
        if ([string]::IsNullOrEmpty($xml)) {
            return ""
        }

        try {
            $xmlDoc = New-Object System.Xml.XmlDocument
            $xmlDoc.LoadXml($xml)

            # Convertir XML en objet
            $obj = [FormatConverter]::XmlToObject($xmlDoc.DocumentElement)

            # Convertir l'objet en JSON
            return [FormatConverter]::ToJson($obj)
        } catch {
            throw "Erreur lors de la conversion XML vers JSON: $_"
        }
    }

    # MÃ©thode pour convertir un nÅ“ud XML en objet
    static hidden [object] XmlToObject([System.Xml.XmlNode]$node) {
        $obj = [PSCustomObject]@{}

        # Ajouter les attributs
        foreach ($attr in $node.Attributes) {
            $obj | Add-Member -MemberType NoteProperty -Name "@$($attr.Name)" -Value $attr.Value
        }

        # Ajouter les nÅ“uds enfants
        $childNodes = $node.ChildNodes | Where-Object { $_.NodeType -ne [System.Xml.XmlNodeType]::Comment }

        if ($childNodes.Count -eq 0) {
            # NÅ“ud feuille
            return $node.InnerText
        }

        $childGroups = $childNodes | Group-Object -Property Name

        foreach ($group in $childGroups) {
            if ($group.Count -eq 1) {
                # NÅ“ud unique
                $childNode = $group.Group[0]
                $childObj = [FormatConverter]::XmlToObject($childNode)
                $obj | Add-Member -MemberType NoteProperty -Name $childNode.Name -Value $childObj
            } else {
                # Liste de nÅ“uds
                $list = @()
                foreach ($childNode in $group.Group) {
                    $childObj = [FormatConverter]::XmlToObject($childNode)
                    $list += $childObj
                }
                $obj | Add-Member -MemberType NoteProperty -Name $group.Name -Value $list
            }
        }

        return $obj
    }

    # MÃ©thode pour convertir JSON en XML
    static [string] ConvertJsonToXml([string]$json, [string]$rootName = "root") {
        if ([string]::IsNullOrEmpty($json)) {
            return "<$rootName />"
        }

        try {
            $obj = ConvertFrom-Json -InputObject $json

            $xmlDoc = New-Object System.Xml.XmlDocument
            $root = $xmlDoc.CreateElement($rootName)
            $xmlDoc.AppendChild($root) | Out-Null

            [FormatConverter]::ObjectToXml($obj, $root, $xmlDoc)

            return $xmlDoc.OuterXml
        } catch {
            throw "Erreur lors de la conversion JSON vers XML: $_"
        }
    }

    # MÃ©thode rÃ©cursive pour convertir un objet en XML
    static hidden [void] ObjectToXml([object]$obj, [System.Xml.XmlNode]$parent, [System.Xml.XmlDocument]$xmlDoc) {
        if ($null -eq $obj) {
            return
        }

        if ($obj -is [string] -or $obj -is [int] -or $obj -is [double] -or $obj -is [bool]) {
            $parent.InnerText = "$obj"
            return
        }

        if ($obj -is [array]) {
            foreach ($item in $obj) {
                $itemName = "item"
                $itemElement = $xmlDoc.CreateElement($itemName)
                $parent.AppendChild($itemElement) | Out-Null
                [FormatConverter]::ObjectToXml($item, $itemElement, $xmlDoc)
            }
            return
        }

        if ($obj -is [hashtable] -or $obj -is [PSCustomObject]) {
            $properties = if ($obj -is [hashtable]) { $obj.Keys } else { $obj.PSObject.Properties.Name }

            foreach ($prop in $properties) {
                $value = if ($obj -is [hashtable]) { $obj[$prop] } else { $obj.$prop }

                # Traiter les attributs (propriÃ©tÃ©s commenÃ§ant par @)
                if ($prop -match "^@(.+)$") {
                    $attrName = $Matches[1]
                    $parent.SetAttribute($attrName, "$value")
                } else {
                    $propElement = $xmlDoc.CreateElement($prop)
                    $parent.AppendChild($propElement) | Out-Null
                    [FormatConverter]::ObjectToXml($value, $propElement, $xmlDoc)
                }
            }
            return
        }

        $parent.InnerText = "$obj"
    }

    # MÃ©thode pour convertir CSV en JSON
    static [string] ConvertCsvToJson([string]$csv) {
        if ([string]::IsNullOrEmpty($csv)) {
            return "[]"
        }

        try {
            $tempFile = [System.IO.Path]::GetTempFileName()
            $csv | Out-File -FilePath $tempFile -Encoding UTF8

            $objects = Import-Csv -Path $tempFile
            Remove-Item -Path $tempFile -Force

            return [FormatConverter]::ToJson($objects)
        } catch {
            throw "Erreur lors de la conversion CSV vers JSON: $_"
        }
    }

    # MÃ©thode pour convertir JSON en CSV
    static [string] ConvertJsonToCsv([string]$json) {
        if ([string]::IsNullOrEmpty($json)) {
            return ""
        }

        try {
            $objects = ConvertFrom-Json -InputObject $json

            $tempFile = [System.IO.Path]::GetTempFileName()
            $objects | Export-Csv -Path $tempFile -NoTypeInformation -Encoding UTF8

            $csv = Get-Content -Path $tempFile -Raw
            Remove-Item -Path $tempFile -Force

            return $csv
        } catch {
            throw "Erreur lors de la conversion JSON vers CSV: $_"
        }
    }

    # MÃ©thode pour dÃ©tecter le format d'une chaÃ®ne
    static [string] DetectFormat([string]$content) {
        if ([string]::IsNullOrEmpty($content)) {
            return "Unknown"
        }

        $content = $content.Trim()

        # DÃ©tecter JSON
        if (($content.StartsWith("{") -and $content.EndsWith("}")) -or
            ($content.StartsWith("[") -and $content.EndsWith("]"))) {
            try {
                ConvertFrom-Json -InputObject $content -ErrorAction Stop | Out-Null
                return "Json"
            } catch {}
        }

        # DÃ©tecter XML
        if ($content.StartsWith("<") -and $content.EndsWith(">")) {
            try {
                [xml]$content | Out-Null
                return "Xml"
            } catch {}
        }

        # DÃ©tecter CSV
        if ($content -match "^[^,]+,[^,]+") {
            try {
                $tempFile = [System.IO.Path]::GetTempFileName()
                $content | Out-File -FilePath $tempFile -Encoding UTF8
                Import-Csv -Path $tempFile -ErrorAction Stop | Out-Null
                Remove-Item -Path $tempFile -Force
                return "Csv"
            } catch {}
        }

        # DÃ©tecter YAML
        if ($content.StartsWith("---") -or $content -match "^[a-zA-Z0-9_-]+:\s") {
            return "Yaml"
        }

        return "Unknown"
    }

    # MÃ©thode pour convertir entre formats
    static [string] Convert([string]$content, [string]$sourceFormat, [string]$targetFormat) {
        if ([string]::IsNullOrEmpty($content)) {
            return ""
        }

        # DÃ©tecter le format source si non spÃ©cifiÃ©
        if ([string]::IsNullOrEmpty($sourceFormat) -or $sourceFormat -eq "Auto") {
            $sourceFormat = [FormatConverter]::DetectFormat($content)
        }

        # Convertir en JSON comme format intermÃ©diaire
        $json = ""

        switch ($sourceFormat) {
            "Json" {
                $json = $content
            }
            "Xml" {
                $json = [FormatConverter]::ConvertXmlToJson($content)
            }
            "Csv" {
                $json = [FormatConverter]::ConvertCsvToJson($content)
            }
            "Yaml" {
                $json = [FormatConverter]::ConvertYamlToJson($content)
            }
            default {
                throw "Format source non pris en charge: $sourceFormat"
            }
        }

        # Convertir de JSON vers le format cible
        switch ($targetFormat) {
            "Json" {
                return $json
            }
            "Xml" {
                return [FormatConverter]::ConvertJsonToXml($json)
            }
            "Csv" {
                return [FormatConverter]::ConvertJsonToCsv($json)
            }
            "Yaml" {
                return [FormatConverter]::ConvertJsonToYaml($json)
            }
            default {
                throw "Format cible non pris en charge: $targetFormat"
            }
        }

        # Cette ligne ne devrait jamais Ãªtre atteinte, mais elle est nÃ©cessaire pour Ã©viter l'erreur de compilation
        return ""
    }
}
