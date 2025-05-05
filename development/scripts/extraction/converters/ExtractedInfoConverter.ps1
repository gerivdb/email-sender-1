using namespace System.Collections.Generic

<#
.SYNOPSIS
    Classe pour la conversion entre diffÃ©rents types d'informations extraites.
.DESCRIPTION
    Fournit des mÃ©thodes pour convertir entre les diffÃ©rents types d'informations
    extraites (TextExtractedInfo, StructuredDataExtractedInfo, MediaExtractedInfo).
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>

# Importer les dÃ©pendances
. "$PSScriptRoot\..\models\BaseExtractedInfo.ps1"
. "$PSScriptRoot\..\models\TextExtractedInfo.ps1"
. "$PSScriptRoot\..\models\StructuredDataExtractedInfo.ps1"
. "$PSScriptRoot\..\models\MediaExtractedInfo.ps1"
. "$PSScriptRoot\FormatConverter.ps1"

class ExtractedInfoConverter {
    # MÃ©thode pour convertir BaseExtractedInfo en TextExtractedInfo
    static [TextExtractedInfo] ToTextInfo([BaseExtractedInfo]$info, [string]$text = "") {
        if ($null -eq $info) {
            throw "L'information source ne peut pas Ãªtre null"
        }

        $textInfo = [TextExtractedInfo]::new()

        # Copier les propriÃ©tÃ©s de base
        $textInfo.Id = $info.Id
        $textInfo.Source = $info.Source
        $textInfo.ExtractedAt = $info.ExtractedAt
        $textInfo.ExtractorName = $info.ExtractorName
        $textInfo.ProcessingState = $info.ProcessingState
        $textInfo.ConfidenceScore = $info.ConfidenceScore
        $textInfo.IsValid = $info.IsValid

        # Copier les mÃ©tadonnÃ©es
        foreach ($key in $info.Metadata.Keys) {
            $textInfo.Metadata[$key] = $info.Metadata[$key]
        }

        # DÃ©finir le texte si fourni
        if (-not [string]::IsNullOrEmpty($text)) {
            $textInfo.SetText($text)
        }

        return $textInfo
    }

    # MÃ©thode pour convertir BaseExtractedInfo en StructuredDataExtractedInfo
    static [StructuredDataExtractedInfo] ToStructuredDataInfo([BaseExtractedInfo]$info, [hashtable]$data = $null) {
        if ($null -eq $info) {
            throw "L'information source ne peut pas Ãªtre null"
        }

        $structuredInfo = [StructuredDataExtractedInfo]::new()

        # Copier les propriÃ©tÃ©s de base
        $structuredInfo.Id = $info.Id
        $structuredInfo.Source = $info.Source
        $structuredInfo.ExtractedAt = $info.ExtractedAt
        $structuredInfo.ExtractorName = $info.ExtractorName
        $structuredInfo.ProcessingState = $info.ProcessingState
        $structuredInfo.ConfidenceScore = $info.ConfidenceScore
        $structuredInfo.IsValid = $info.IsValid

        # Copier les mÃ©tadonnÃ©es
        foreach ($key in $info.Metadata.Keys) {
            $structuredInfo.Metadata[$key] = $info.Metadata[$key]
        }

        # DÃ©finir les donnÃ©es si fournies
        if ($null -ne $data) {
            $structuredInfo.SetData($data)
        }

        return $structuredInfo
    }

    # MÃ©thode pour convertir BaseExtractedInfo en MediaExtractedInfo
    static [MediaExtractedInfo] ToMediaInfo([BaseExtractedInfo]$info, [string]$mediaPath = "") {
        if ($null -eq $info) {
            throw "L'information source ne peut pas Ãªtre null"
        }

        $mediaInfo = [MediaExtractedInfo]::new()

        # Copier les propriÃ©tÃ©s de base
        $mediaInfo.Id = $info.Id
        $mediaInfo.Source = $info.Source
        $mediaInfo.ExtractedAt = $info.ExtractedAt
        $mediaInfo.ExtractorName = $info.ExtractorName
        $mediaInfo.ProcessingState = $info.ProcessingState
        $mediaInfo.ConfidenceScore = $info.ConfidenceScore
        $mediaInfo.IsValid = $info.IsValid

        # Copier les mÃ©tadonnÃ©es
        foreach ($key in $info.Metadata.Keys) {
            $mediaInfo.Metadata[$key] = $info.Metadata[$key]
        }

        # DÃ©finir le chemin du mÃ©dia si fourni
        if (-not [string]::IsNullOrEmpty($mediaPath) -and (Test-Path -Path $mediaPath)) {
            $mediaInfo.SetMediaPath($mediaPath)
        }

        return $mediaInfo
    }

    # MÃ©thode pour convertir TextExtractedInfo en StructuredDataExtractedInfo
    static [StructuredDataExtractedInfo] TextToStructuredData([TextExtractedInfo]$textInfo) {
        if ($null -eq $textInfo) {
            throw "L'information texte ne peut pas Ãªtre null"
        }

        $structuredInfo = [ExtractedInfoConverter]::ToStructuredDataInfo($textInfo)

        # CrÃ©er des donnÃ©es structurÃ©es Ã  partir du texte
        $data = @{
            Text           = $textInfo.Text
            Language       = $textInfo.Language
            CharacterCount = $textInfo.CharacterCount
            WordCount      = $textInfo.WordCount
            Keywords       = $textInfo.Keywords
            Category       = $textInfo.Category
            Summary        = $textInfo.Summary
            Statistics     = $textInfo.TextStatistics
        }

        $structuredInfo.SetData($data)

        return $structuredInfo
    }

    # MÃ©thode pour convertir StructuredDataExtractedInfo en TextExtractedInfo
    static [TextExtractedInfo] StructuredDataToText([StructuredDataExtractedInfo]$structuredInfo) {
        if ($null -eq $structuredInfo) {
            throw "L'information structurÃ©e ne peut pas Ãªtre null"
        }

        $textInfo = [ExtractedInfoConverter]::ToTextInfo($structuredInfo)

        # Extraire le texte des donnÃ©es structurÃ©es
        $text = ""

        if ($structuredInfo.ContainsKey("Text")) {
            $text = $structuredInfo.GetValue("Text").ToString()
        } else {
            # GÃ©nÃ©rer un texte Ã  partir des donnÃ©es structurÃ©es
            $text = [FormatConverter]::ToJson($structuredInfo.Data)
        }

        $textInfo.SetText($text)

        # DÃ©finir la langue si disponible
        if ($structuredInfo.ContainsKey("Language")) {
            $textInfo.Language = $structuredInfo.GetValue("Language").ToString()
        }

        # DÃ©finir les mots-clÃ©s si disponibles
        if ($structuredInfo.ContainsKey("Keywords")) {
            $keywords = $structuredInfo.GetValue("Keywords")
            if ($keywords -is [array]) {
                $textInfo.Keywords = $keywords
            }
        }

        # DÃ©finir la catÃ©gorie si disponible
        if ($structuredInfo.ContainsKey("Category")) {
            $textInfo.Category = $structuredInfo.GetValue("Category").ToString()
        }

        # DÃ©finir le rÃ©sumÃ© si disponible
        if ($structuredInfo.ContainsKey("Summary")) {
            $textInfo.Summary = $structuredInfo.GetValue("Summary").ToString()
        }

        return $textInfo
    }

    # MÃ©thode pour convertir MediaExtractedInfo en StructuredDataExtractedInfo
    static [StructuredDataExtractedInfo] MediaToStructuredData([MediaExtractedInfo]$mediaInfo) {
        if ($null -eq $mediaInfo) {
            throw "L'information mÃ©dia ne peut pas Ãªtre null"
        }

        $structuredInfo = [ExtractedInfoConverter]::ToStructuredDataInfo($mediaInfo)

        # CrÃ©er des donnÃ©es structurÃ©es Ã  partir des informations mÃ©dia
        $data = @{
            MediaPath        = $mediaInfo.MediaPath
            MediaType        = $mediaInfo.MediaType
            MimeType         = $mediaInfo.MimeType
            FileSize         = $mediaInfo.FileSize
            FileCreatedDate  = $mediaInfo.FileCreatedDate
            FileModifiedDate = $mediaInfo.FileModifiedDate
            Checksum         = $mediaInfo.Checksum
            MediaMetadata    = $mediaInfo.MediaMetadata
            TechnicalInfo    = $mediaInfo.TechnicalInfo
        }

        $structuredInfo.SetData($data)

        return $structuredInfo
    }

    # MÃ©thode pour convertir StructuredDataExtractedInfo en MediaExtractedInfo
    static [MediaExtractedInfo] StructuredDataToMedia([StructuredDataExtractedInfo]$structuredInfo) {
        if ($null -eq $structuredInfo) {
            throw "L'information structurÃ©e ne peut pas Ãªtre null"
        }

        $mediaInfo = [ExtractedInfoConverter]::ToMediaInfo($structuredInfo)

        # Extraire le chemin du mÃ©dia des donnÃ©es structurÃ©es
        if ($structuredInfo.ContainsKey("MediaPath")) {
            $mediaPath = $structuredInfo.GetValue("MediaPath").ToString()

            if (-not [string]::IsNullOrEmpty($mediaPath) -and (Test-Path -Path $mediaPath)) {
                $mediaInfo.SetMediaPath($mediaPath)
            }
        }

        # DÃ©finir les propriÃ©tÃ©s supplÃ©mentaires si disponibles
        if ($structuredInfo.ContainsKey("MediaType")) {
            $mediaInfo.MediaType = $structuredInfo.GetValue("MediaType").ToString()
        }

        if ($structuredInfo.ContainsKey("MimeType")) {
            $mediaInfo.MimeType = $structuredInfo.GetValue("MimeType").ToString()
        }

        if ($structuredInfo.ContainsKey("Checksum")) {
            $mediaInfo.Checksum = $structuredInfo.GetValue("Checksum").ToString()
        }

        return $mediaInfo
    }

    # MÃ©thode pour convertir TextExtractedInfo en MediaExtractedInfo
    static [MediaExtractedInfo] TextToMedia([TextExtractedInfo]$textInfo, [string]$outputPath) {
        if ($null -eq $textInfo) {
            throw "L'information texte ne peut pas Ãªtre null"
        }

        if ([string]::IsNullOrEmpty($outputPath)) {
            throw "Le chemin de sortie ne peut pas Ãªtre vide"
        }

        # CrÃ©er un fichier texte temporaire
        $tempFile = [System.IO.Path]::Combine($outputPath, "$($textInfo.Id).txt")
        $textInfo.Text | Out-File -FilePath $tempFile -Encoding UTF8

        # CrÃ©er l'information mÃ©dia
        $mediaInfo = [ExtractedInfoConverter]::ToMediaInfo($textInfo, $tempFile)

        return $mediaInfo
    }

    # MÃ©thode pour convertir MediaExtractedInfo en TextExtractedInfo
    static [TextExtractedInfo] MediaToText([MediaExtractedInfo]$mediaInfo) {
        if ($null -eq $mediaInfo) {
            throw "L'information mÃ©dia ne peut pas Ãªtre null"
        }

        $textInfo = [ExtractedInfoConverter]::ToTextInfo($mediaInfo)

        # Extraire le texte du fichier mÃ©dia si possible
        if (-not [string]::IsNullOrEmpty($mediaInfo.MediaPath) -and (Test-Path -Path $mediaInfo.MediaPath)) {
            try {
                # Pour les fichiers texte, lire directement le contenu
                if ($mediaInfo.MediaType -eq "Document" -or
                    $mediaInfo.MimeType -eq "text/plain" -or
                    [System.IO.Path]::GetExtension($mediaInfo.MediaPath) -eq ".txt") {
                    $text = Get-Content -Path $mediaInfo.MediaPath -Raw
                    $textInfo.SetText($text)
                } else {
                    # Pour les autres types de mÃ©dias, crÃ©er une description
                    $description = "Fichier mÃ©dia: $($mediaInfo.GetFileName())`n"
                    $description += "Type: $($mediaInfo.MediaType)`n"
                    $description += "MIME: $($mediaInfo.MimeType)`n"
                    $description += "Taille: $([math]::Round($mediaInfo.FileSize / 1024, 2)) KB`n"
                    $description += "CrÃ©Ã© le: $($mediaInfo.FileCreatedDate.ToString('yyyy-MM-dd HH:mm:ss'))`n"
                    $description += "ModifiÃ© le: $($mediaInfo.FileModifiedDate.ToString('yyyy-MM-dd HH:mm:ss'))`n"

                    if ($mediaInfo.TechnicalInfo.Count -gt 0) {
                        $description += "`nInformations techniques:`n"
                        foreach ($key in $mediaInfo.TechnicalInfo.Keys) {
                            $description += "- ${key}: $($mediaInfo.TechnicalInfo[$key])`n"
                        }
                    }

                    $textInfo.SetText($description)
                }
            } catch {
                $textInfo.SetText("Erreur lors de l'extraction du texte: $_")
            }
        } else {
            $textInfo.SetText("Aucun fichier mÃ©dia disponible")
        }

        return $textInfo
    }

    # MÃ©thode pour convertir une collection d'informations en JSON
    static [string] CollectionToJson([ExtractedInfoCollection]$collection, [int]$depth = 10) {
        if ($null -eq $collection) {
            throw "La collection ne peut pas Ãªtre null"
        }

        # CrÃ©er un objet pour la sÃ©rialisation
        $serializableCollection = @{
            Name      = $collection.Name
            CreatedAt = $collection.CreatedAt.ToString("o")
            ItemCount = $collection.Items.Count
            Metadata  = $collection.Metadata
            Items     = @()
        }

        # Ajouter les items
        foreach ($item in $collection.Items) {
            if ($item -is [SerializableExtractedInfo]) {
                # Utiliser la mÃ©thode ToJson de l'item
                $itemJson = $item.ToJson($depth)
                $itemObj = ConvertFrom-Json -InputObject $itemJson
                $serializableCollection.Items += $itemObj
            } else {
                # Convertir l'item en objet sÃ©rialisable
                $serializableCollection.Items += @{
                    Id              = $item.Id
                    Source          = $item.Source
                    ExtractedAt     = $item.ExtractedAt.ToString("o")
                    ExtractorName   = $item.ExtractorName
                    ProcessingState = $item.ProcessingState
                    ConfidenceScore = $item.ConfidenceScore
                    IsValid         = $item.IsValid
                    Metadata        = $item.Metadata
                }
            }
        }

        # Convertir en JSON
        return ConvertTo-Json -InputObject $serializableCollection -Depth $depth
    }

    # MÃ©thode pour convertir JSON en collection d'informations
    static [ExtractedInfoCollection] JsonToCollection([string]$json) {
        if ([string]::IsNullOrEmpty($json)) {
            throw "La chaÃ®ne JSON ne peut pas Ãªtre vide"
        }

        try {
            $obj = ConvertFrom-Json -InputObject $json

            $collection = [ExtractedInfoCollection]::new($obj.Name)

            # DÃ©finir les propriÃ©tÃ©s de base
            if ($null -ne $obj.CreatedAt) {
                $collection.CreatedAt = [datetime]::Parse($obj.CreatedAt)
            }

            # DÃ©finir les mÃ©tadonnÃ©es
            if ($null -ne $obj.Metadata) {
                $metadataObj = $obj.Metadata
                foreach ($prop in $metadataObj.PSObject.Properties) {
                    $collection.Metadata[$prop.Name] = $prop.Value
                }
            }

            # Ajouter les items
            if ($null -ne $obj.Items -and $obj.Items -is [array]) {
                foreach ($itemObj in $obj.Items) {
                    $item = [BaseExtractedInfo]::new()

                    # DÃ©finir les propriÃ©tÃ©s de base
                    $item.Id = $itemObj.Id
                    $item.Source = $itemObj.Source
                    $item.ExtractedAt = [datetime]::Parse($itemObj.ExtractedAt)
                    $item.ExtractorName = $itemObj.ExtractorName
                    $item.ProcessingState = $itemObj.ProcessingState
                    $item.ConfidenceScore = $itemObj.ConfidenceScore
                    $item.IsValid = $itemObj.IsValid

                    # DÃ©finir les mÃ©tadonnÃ©es
                    if ($null -ne $itemObj.Metadata) {
                        foreach ($prop in $itemObj.Metadata.PSObject.Properties) {
                            $item.Metadata[$prop.Name] = $prop.Value
                        }
                    }

                    $collection.Add($item)
                }
            }

            return $collection
        } catch {
            throw "Erreur lors de la dÃ©sÃ©rialisation JSON: $_"
        }
    }
}
