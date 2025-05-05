using namespace System.Collections.Generic
using namespace System.IO

<#
.SYNOPSIS
    Classe de base pour les informations extraites sÃ©rialisables.
.DESCRIPTION
    Ã‰tend la classe BaseExtractedInfo en implÃ©mentant l'interface ISerializable
    pour permettre la sÃ©rialisation et dÃ©sÃ©rialisation dans diffÃ©rents formats.
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>

# Importer les dÃ©pendances
. "$PSScriptRoot\BaseExtractedInfo.ps1"
. "$PSScriptRoot\..\interfaces\ISerializable.ps1"

class SerializableExtractedInfo : BaseExtractedInfo, ISerializable {
    # Constructeur par dÃ©faut
    SerializableExtractedInfo() : base() {
    }

    # Constructeur avec source
    SerializableExtractedInfo([string]$source) : base($source) {
    }

    # Constructeur avec source et extracteur
    SerializableExtractedInfo([string]$source, [string]$extractorName) : base($source, $extractorName) {
    }

    # ImplÃ©mentation de l'interface ISerializable

    # MÃ©thode pour sÃ©rialiser l'objet en JSON
    [string] ToJson([int]$depth = 10) {
        # CrÃ©er un objet personnalisÃ© pour la sÃ©rialisation
        $serializableObject = @{
            Id              = $this.Id
            Source          = $this.Source
            ExtractedAt     = $this.ExtractedAt.ToString("o")
            ExtractorName   = $this.ExtractorName
            Metadata        = $this.Metadata
            ProcessingState = $this.ProcessingState
            ConfidenceScore = $this.ConfidenceScore
            IsValid         = $this.IsValid
        }

        # SÃ©rialiser en JSON
        return ConvertTo-Json -InputObject $serializableObject -Depth $depth
    }

    # MÃ©thode pour sÃ©rialiser l'objet en XML
    [string] ToXml() {
        # CrÃ©er un objet XML
        $xmlDoc = New-Object System.Xml.XmlDocument
        $root = $xmlDoc.CreateElement("ExtractedInfo")

        # Ajouter les attributs
        $root.SetAttribute("Id", $this.Id)
        $root.SetAttribute("Source", $this.Source)
        $root.SetAttribute("ExtractedAt", $this.ExtractedAt.ToString("o"))
        $root.SetAttribute("ExtractorName", $this.ExtractorName)
        $root.SetAttribute("ProcessingState", $this.ProcessingState)
        $root.SetAttribute("ConfidenceScore", $this.ConfidenceScore.ToString())
        $root.SetAttribute("IsValid", $this.IsValid.ToString().ToLower())

        # Ajouter les mÃ©tadonnÃ©es
        $metadataElement = $xmlDoc.CreateElement("Metadata")
        foreach ($key in $this.Metadata.Keys) {
            $itemElement = $xmlDoc.CreateElement("Item")
            $itemElement.SetAttribute("Key", $key)
            $itemElement.InnerText = $this.Metadata[$key].ToString()
            $metadataElement.AppendChild($itemElement)
        }
        $root.AppendChild($metadataElement)

        # Finaliser le document XML
        $xmlDoc.AppendChild($root)

        # Retourner la chaÃ®ne XML
        return $xmlDoc.OuterXml
    }

    # MÃ©thode pour sÃ©rialiser l'objet en CSV
    [string] ToCsv() {
        # CrÃ©er l'en-tÃªte CSV
        $csv = "Id,Source,ExtractedAt,ExtractorName,ProcessingState,ConfidenceScore,IsValid`n"

        # Ajouter les donnÃ©es
        $csv += "$($this.Id),$($this.Source),$($this.ExtractedAt.ToString('o')),$($this.ExtractorName),$($this.ProcessingState),$($this.ConfidenceScore),$($this.IsValid)`n"

        # Ajouter les mÃ©tadonnÃ©es sur des lignes supplÃ©mentaires
        foreach ($key in $this.Metadata.Keys) {
            $csv += "Metadata,$key,$($this.Metadata[$key])`n"
        }

        return $csv
    }

    # MÃ©thode pour sÃ©rialiser l'objet en YAML
    [string] ToYaml() {
        # CrÃ©er la chaÃ®ne YAML
        $yaml = "---`n"
        $yaml += "Id: $($this.Id)`n"
        $yaml += "Source: $($this.Source)`n"
        $yaml += "ExtractedAt: $($this.ExtractedAt.ToString('o'))`n"
        $yaml += "ExtractorName: $($this.ExtractorName)`n"
        $yaml += "ProcessingState: $($this.ProcessingState)`n"
        $yaml += "ConfidenceScore: $($this.ConfidenceScore)`n"
        $yaml += "IsValid: $($this.IsValid)`n"

        # Ajouter les mÃ©tadonnÃ©es
        if ($this.Metadata.Count -gt 0) {
            $yaml += "Metadata:`n"
            foreach ($key in $this.Metadata.Keys) {
                $yaml += "  ${key}: $($this.Metadata[$key])`n"
            }
        }

        return $yaml
    }

    # MÃ©thode pour sÃ©rialiser l'objet en format personnalisÃ©
    [string] ToCustomFormat([string]$format) {
        switch ($format) {
            "JsonMinified" {
                # JSON sans indentation
                $serializableObject = @{
                    Id              = $this.Id
                    Source          = $this.Source
                    ExtractedAt     = $this.ExtractedAt.ToString("o")
                    ExtractorName   = $this.ExtractorName
                    Metadata        = $this.Metadata
                    ProcessingState = $this.ProcessingState
                    ConfidenceScore = $this.ConfidenceScore
                    IsValid         = $this.IsValid
                }
                return ConvertTo-Json -InputObject $serializableObject -Depth 10 -Compress
            }
            "KeyValue" {
                # Format clÃ©=valeur
                $result = "Id=$($this.Id)`n"
                $result += "Source=$($this.Source)`n"
                $result += "ExtractedAt=$($this.ExtractedAt.ToString('o'))`n"
                $result += "ExtractorName=$($this.ExtractorName)`n"
                $result += "ProcessingState=$($this.ProcessingState)`n"
                $result += "ConfidenceScore=$($this.ConfidenceScore)`n"
                $result += "IsValid=$($this.IsValid)`n"

                # Ajouter les mÃ©tadonnÃ©es
                foreach ($key in $this.Metadata.Keys) {
                    $result += "Metadata.$key=$($this.Metadata[$key])`n"
                }
                return $result
            }
            default {
                throw "Format personnalisÃ© non pris en charge: $format"
            }
        }

        # Cette ligne ne devrait jamais Ãªtre atteinte, mais elle est nÃ©cessaire pour Ã©viter l'erreur de compilation
        return ""
    }

    # MÃ©thode pour dÃ©sÃ©rialiser l'objet depuis JSON
    [void] FromJson([string]$json) {
        if ([string]::IsNullOrEmpty($json)) {
            throw "La chaÃ®ne JSON est vide ou null"
        }

        try {
            $obj = ConvertFrom-Json -InputObject $json

            # Assigner les propriÃ©tÃ©s
            $this.Id = $obj.Id
            $this.Source = $obj.Source
            $this.ExtractedAt = [datetime]::Parse($obj.ExtractedAt)
            $this.ExtractorName = $obj.ExtractorName
            $this.ProcessingState = $obj.ProcessingState
            $this.ConfidenceScore = $obj.ConfidenceScore
            $this.IsValid = $obj.IsValid

            # Assigner les mÃ©tadonnÃ©es
            $this.Metadata = @{}
            if ($null -ne $obj.Metadata) {
                $metadataObj = $obj.Metadata
                foreach ($prop in $metadataObj.PSObject.Properties) {
                    $this.Metadata[$prop.Name] = $prop.Value
                }
            }
        } catch {
            throw "Erreur lors de la dÃ©sÃ©rialisation JSON: $_"
        }
    }

    # MÃ©thode pour dÃ©sÃ©rialiser l'objet depuis XML
    [void] FromXml([string]$xml) {
        if ([string]::IsNullOrEmpty($xml)) {
            throw "La chaÃ®ne XML est vide ou null"
        }

        try {
            $xmlDoc = New-Object System.Xml.XmlDocument
            $xmlDoc.LoadXml($xml)

            $root = $xmlDoc.DocumentElement

            # Assigner les propriÃ©tÃ©s
            $this.Id = $root.GetAttribute("Id")
            $this.Source = $root.GetAttribute("Source")
            $this.ExtractedAt = [datetime]::Parse($root.GetAttribute("ExtractedAt"))
            $this.ExtractorName = $root.GetAttribute("ExtractorName")
            $this.ProcessingState = $root.GetAttribute("ProcessingState")
            $this.ConfidenceScore = [int]::Parse($root.GetAttribute("ConfidenceScore"))
            $this.IsValid = [bool]::Parse($root.GetAttribute("IsValid"))

            # Assigner les mÃ©tadonnÃ©es
            $this.Metadata = @{}
            $metadataNodes = $root.SelectNodes("Metadata/Item")
            foreach ($node in $metadataNodes) {
                $key = $node.GetAttribute("Key")
                $value = $node.InnerText
                $this.Metadata[$key] = $value
            }
        } catch {
            throw "Erreur lors de la dÃ©sÃ©rialisation XML: $_"
        }
    }

    # MÃ©thode pour dÃ©sÃ©rialiser l'objet depuis CSV
    [void] FromCsv([string]$csv) {
        if ([string]::IsNullOrEmpty($csv)) {
            throw "La chaÃ®ne CSV est vide ou null"
        }

        try {
            $lines = $csv -split "`n" | Where-Object { $_ -ne "" }

            # VÃ©rifier l'en-tÃªte
            $header = $lines[0]
            if ($header -ne "Id,Source,ExtractedAt,ExtractorName,ProcessingState,ConfidenceScore,IsValid") {
                throw "Format CSV invalide: en-tÃªte incorrect"
            }

            # Traiter la premiÃ¨re ligne de donnÃ©es
            $dataLine = $lines[1]
            $values = $dataLine -split ","

            if ($values.Count -lt 7) {
                throw "Format CSV invalide: nombre de colonnes incorrect"
            }

            # Assigner les propriÃ©tÃ©s
            $this.Id = $values[0]
            $this.Source = $values[1]
            $this.ExtractedAt = [datetime]::Parse($values[2])
            $this.ExtractorName = $values[3]
            $this.ProcessingState = $values[4]
            $this.ConfidenceScore = [int]::Parse($values[5])
            $this.IsValid = [bool]::Parse($values[6])

            # Traiter les mÃ©tadonnÃ©es
            $this.Metadata = @{}
            for ($i = 2; $i -lt $lines.Count; $i++) {
                $metadataLine = $lines[$i]
                $metadataValues = $metadataLine -split ","

                if ($metadataValues[0] -eq "Metadata" -and $metadataValues.Count -ge 3) {
                    $key = $metadataValues[1]
                    $value = $metadataValues[2]
                    $this.Metadata[$key] = $value
                }
            }
        } catch {
            throw "Erreur lors de la dÃ©sÃ©rialisation CSV: $_"
        }
    }

    # MÃ©thode pour dÃ©sÃ©rialiser l'objet depuis YAML
    [void] FromYaml([string]$yaml) {
        if ([string]::IsNullOrEmpty($yaml)) {
            throw "La chaÃ®ne YAML est vide ou null"
        }

        try {
            # Analyser le YAML manuellement (implÃ©mentation simplifiÃ©e)
            $lines = $yaml -split "`n" | Where-Object { $_ -ne "" -and $_ -ne "---" }

            $inMetadata = $false
            $this.Metadata = @{}

            foreach ($line in $lines) {
                if ($line -match "^Metadata:") {
                    $inMetadata = $true
                    continue
                }

                if ($inMetadata -and $line -match "^\s\s(\w+):\s(.+)$") {
                    $key = $Matches[1]
                    $value = $Matches[2]
                    $this.Metadata[$key] = $value
                } elseif ($line -match "^(\w+):\s(.+)$") {
                    $key = $Matches[1]
                    $value = $Matches[2]

                    switch ($key) {
                        "Id" { $this.Id = $value }
                        "Source" { $this.Source = $value }
                        "ExtractedAt" { $this.ExtractedAt = [datetime]::Parse($value) }
                        "ExtractorName" { $this.ExtractorName = $value }
                        "ProcessingState" { $this.ProcessingState = $value }
                        "ConfidenceScore" { $this.ConfidenceScore = [int]::Parse($value) }
                        "IsValid" { $this.IsValid = [bool]::Parse($value) }
                    }
                }
            }
        } catch {
            throw "Erreur lors de la dÃ©sÃ©rialisation YAML: $_"
        }
    }

    # MÃ©thode pour dÃ©sÃ©rialiser l'objet depuis un format personnalisÃ©
    [void] FromCustomFormat([string]$data, [string]$format) {
        if ([string]::IsNullOrEmpty($data)) {
            throw "Les donnÃ©es sont vides ou null"
        }

        try {
            switch ($format) {
                "JsonMinified" {
                    # Utiliser la mÃ©thode FromJson existante
                    $this.FromJson($data)
                }
                "KeyValue" {
                    # Format clÃ©=valeur
                    $lines = $data -split "`n" | Where-Object { $_ -ne "" }

                    $this.Metadata = @{}

                    foreach ($line in $lines) {
                        if ($line -match "^([^=]+)=(.*)$") {
                            $key = $Matches[1]
                            $value = $Matches[2]

                            if ($key -match "^Metadata\.(.+)$") {
                                $metadataKey = $Matches[1]
                                $this.Metadata[$metadataKey] = $value
                            } else {
                                switch ($key) {
                                    "Id" { $this.Id = $value }
                                    "Source" { $this.Source = $value }
                                    "ExtractedAt" { $this.ExtractedAt = [datetime]::Parse($value) }
                                    "ExtractorName" { $this.ExtractorName = $value }
                                    "ProcessingState" { $this.ProcessingState = $value }
                                    "ConfidenceScore" { $this.ConfidenceScore = [int]::Parse($value) }
                                    "IsValid" { $this.IsValid = [bool]::Parse($value) }
                                }
                            }
                        }
                    }
                }
                default {
                    throw "Format personnalisÃ© non pris en charge: $format"
                }
            }
        } catch {
            throw "Erreur lors de la dÃ©sÃ©rialisation au format $format : $_"
        }
    }

    # MÃ©thode pour sauvegarder l'objet dans un fichier
    [void] SaveToFile([string]$filePath, [string]$format = "Json") {
        try {
            $content = ""

            # Obtenir le contenu selon le format
            switch ($format) {
                "Json" { $content = $this.ToJson() }
                "Xml" { $content = $this.ToXml() }
                "Csv" { $content = $this.ToCsv() }
                "Yaml" { $content = $this.ToYaml() }
                "JsonMinified" { $content = $this.ToCustomFormat("JsonMinified") }
                "KeyValue" { $content = $this.ToCustomFormat("KeyValue") }
                default { throw "Format non pris en charge: $format" }
            }

            # DÃ©terminer l'encodage
            $encoding = [System.Text.Encoding]::UTF8

            # Ã‰crire dans le fichier
            [System.IO.File]::WriteAllText($filePath, $content, $encoding)
        } catch {
            throw "Erreur lors de la sauvegarde dans le fichier $filePath : $_"
        }
    }

    # MÃ©thode pour charger l'objet depuis un fichier
    [void] LoadFromFile([string]$filePath, [string]$format = "Json") {
        if (-not [System.IO.File]::Exists($filePath)) {
            throw "Le fichier $filePath n'existe pas"
        }

        try {
            # Lire le contenu du fichier
            $content = [System.IO.File]::ReadAllText($filePath)

            # DÃ©sÃ©rialiser selon le format
            switch ($format) {
                "Json" { $this.FromJson($content) }
                "Xml" { $this.FromXml($content) }
                "Csv" { $this.FromCsv($content) }
                "Yaml" { $this.FromYaml($content) }
                "JsonMinified" { $this.FromCustomFormat($content, "JsonMinified") }
                "KeyValue" { $this.FromCustomFormat($content, "KeyValue") }
                default { throw "Format non pris en charge: $format" }
            }
        } catch {
            throw "Erreur lors du chargement depuis le fichier $filePath : $_"
        }
    }

    # Surcharge de la mÃ©thode Clone pour retourner un SerializableExtractedInfo
    [SerializableExtractedInfo] Clone() {
        $clone = [SerializableExtractedInfo]::new()
        $clone.Id = $this.Id
        $clone.Source = $this.Source
        $clone.ExtractedAt = $this.ExtractedAt
        $clone.ExtractorName = $this.ExtractorName
        $clone.ProcessingState = $this.ProcessingState
        $clone.ConfidenceScore = $this.ConfidenceScore
        $clone.IsValid = $this.IsValid

        # Cloner les mÃ©tadonnÃ©es
        foreach ($key in $this.Metadata.Keys) {
            $clone.Metadata[$key] = $this.Metadata[$key]
        }

        return $clone
    }
}
