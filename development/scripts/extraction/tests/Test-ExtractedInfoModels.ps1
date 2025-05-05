<#
.SYNOPSIS
    Tests unitaires pour les modÃ¨les d'informations extraites.
.DESCRIPTION
    VÃ©rifie le bon fonctionnement des classes de base, des interfaces
    et des mÃ©canismes de validation et de conversion.
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>

# Importer les dÃ©pendances
. "$PSScriptRoot\..\models\BaseExtractedInfo.ps1"
. "$PSScriptRoot\..\models\ExtractedInfoCollection.ps1"
. "$PSScriptRoot\..\models\SerializableExtractedInfo.ps1"
. "$PSScriptRoot\..\models\ValidationRule.ps1"
. "$PSScriptRoot\..\models\ValidatableExtractedInfo.ps1"
. "$PSScriptRoot\..\models\TextExtractedInfo.ps1"
. "$PSScriptRoot\..\models\StructuredDataExtractedInfo.ps1"
. "$PSScriptRoot\..\models\MediaExtractedInfo.ps1"
. "$PSScriptRoot\..\converters\FormatConverter.ps1"
. "$PSScriptRoot\..\converters\ExtractedInfoConverter.ps1"

# CrÃ©er un dossier temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "ExtractedInfoTests"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory | Out-Null
}

# Tests pour BaseExtractedInfo
Describe "BaseExtractedInfo" {
    It "Devrait crÃ©er une instance avec les valeurs par dÃ©faut" {
        $info = [BaseExtractedInfo]::new()
        $info.Id | Should -Not -BeNullOrEmpty
        $info.ExtractedAt | Should -BeOfType [datetime]
        $info.ProcessingState | Should -Be "Raw"
        $info.ConfidenceScore | Should -Be 0
        $info.IsValid | Should -Be $false
    }

    It "Devrait crÃ©er une instance avec une source" {
        $info = [BaseExtractedInfo]::new("TestSource")
        $info.Source | Should -Be "TestSource"
    }

    It "Devrait crÃ©er une instance avec une source et un extracteur" {
        $info = [BaseExtractedInfo]::new("TestSource", "TestExtractor")
        $info.Source | Should -Be "TestSource"
        $info.ExtractorName | Should -Be "TestExtractor"
    }

    It "Devrait gÃ©rer les mÃ©tadonnÃ©es correctement" {
        $info = [BaseExtractedInfo]::new()
        $info.AddMetadata("TestKey", "TestValue")
        $info.HasMetadata("TestKey") | Should -Be $true
        $info.GetMetadata("TestKey") | Should -Be "TestValue"
        $info.RemoveMetadata("TestKey")
        $info.HasMetadata("TestKey") | Should -Be $false
    }

    It "Devrait cloner correctement" {
        $info = [BaseExtractedInfo]::new("TestSource", "TestExtractor")
        $info.AddMetadata("TestKey", "TestValue")
        $info.SetConfidenceScore(75)
        $info.SetProcessingState("Processed")
        $info.SetValidity($true)

        $clone = $info.Clone()
        $clone.Id | Should -Be $info.Id
        $clone.Source | Should -Be $info.Source
        $clone.ExtractorName | Should -Be $info.ExtractorName
        $clone.ProcessingState | Should -Be $info.ProcessingState
        $clone.ConfidenceScore | Should -Be $info.ConfidenceScore
        $clone.IsValid | Should -Be $info.IsValid
        $clone.GetMetadata("TestKey") | Should -Be "TestValue"
    }
}

# Tests pour ExtractedInfoCollection
Describe "ExtractedInfoCollection" {
    It "Devrait crÃ©er une collection vide" {
        $collection = [ExtractedInfoCollection]::new()
        $collection.Count() | Should -Be 0
    }

    It "Devrait ajouter et supprimer des Ã©lÃ©ments" {
        $collection = [ExtractedInfoCollection]::new("TestCollection")
        $info1 = [BaseExtractedInfo]::new("Source1")
        $info2 = [BaseExtractedInfo]::new("Source2")

        $collection.Add($info1)
        $collection.Add($info2)
        $collection.Count() | Should -Be 2

        $collection.Remove($info1)
        $collection.Count() | Should -Be 1
        $collection.Items[0].Source | Should -Be "Source2"
    }

    It "Devrait filtrer les Ã©lÃ©ments par source" {
        $collection = [ExtractedInfoCollection]::new()
        $collection.Add([BaseExtractedInfo]::new("Source1"))
        $collection.Add([BaseExtractedInfo]::new("Source2"))
        $collection.Add([BaseExtractedInfo]::new("Source1"))

        $filtered = $collection.FilterBySource("Source1")
        $filtered.Count | Should -Be 2
        $filtered[0].Source | Should -Be "Source1"
        $filtered[1].Source | Should -Be "Source1"
    }

    It "Devrait calculer des statistiques" {
        $collection = [ExtractedInfoCollection]::new()
        $info1 = [BaseExtractedInfo]::new("Source1")
        $info1.SetValidity($true)
        $info1.SetConfidenceScore(80)

        $info2 = [BaseExtractedInfo]::new("Source2")
        $info2.SetValidity($false)
        $info2.SetConfidenceScore(40)

        $collection.Add($info1)
        $collection.Add($info2)

        $stats = $collection.GetStatistics()
        $stats.TotalCount | Should -Be 2
        $stats.ValidCount | Should -Be 1
        $stats.InvalidCount | Should -Be 1
        $stats.AverageConfidence | Should -Be 60
        $stats.SourceDistribution["Source1"] | Should -Be 1
        $stats.SourceDistribution["Source2"] | Should -Be 1
    }
}

# Tests pour SerializableExtractedInfo
Describe "SerializableExtractedInfo" {
    It "Devrait sÃ©rialiser et dÃ©sÃ©rialiser en JSON" {
        $info = [SerializableExtractedInfo]::new("TestSource", "TestExtractor")
        $info.AddMetadata("TestKey", "TestValue")
        $info.SetConfidenceScore(75)
        $info.SetProcessingState("Processed")
        $info.SetValidity($true)

        $json = $info.ToJson()
        $json | Should -Not -BeNullOrEmpty

        $newInfo = [SerializableExtractedInfo]::new()
        $newInfo.FromJson($json)

        $newInfo.Id | Should -Be $info.Id
        $newInfo.Source | Should -Be $info.Source
        $newInfo.ExtractorName | Should -Be $info.ExtractorName
        $newInfo.ProcessingState | Should -Be $info.ProcessingState
        $newInfo.ConfidenceScore | Should -Be $info.ConfidenceScore
        $newInfo.IsValid | Should -Be $info.IsValid
        $newInfo.GetMetadata("TestKey") | Should -Be "TestValue"
    }

    It "Devrait sÃ©rialiser et dÃ©sÃ©rialiser en XML" {
        $info = [SerializableExtractedInfo]::new("TestSource", "TestExtractor")
        $info.AddMetadata("TestKey", "TestValue")

        $xml = $info.ToXml()
        $xml | Should -Not -BeNullOrEmpty

        $newInfo = [SerializableExtractedInfo]::new()
        $newInfo.FromXml($xml)

        $newInfo.Id | Should -Be $info.Id
        $newInfo.Source | Should -Be $info.Source
        $newInfo.GetMetadata("TestKey") | Should -Be "TestValue"
    }

    It "Devrait sauvegarder et charger depuis un fichier" {
        $info = [SerializableExtractedInfo]::new("TestSource", "TestExtractor")
        $info.AddMetadata("TestKey", "TestValue")

        $filePath = Join-Path -Path $testDir -ChildPath "test_info.json"
        $info.SaveToFile($filePath, "Json")

        $newInfo = [SerializableExtractedInfo]::new()
        $newInfo.LoadFromFile($filePath, "Json")

        $newInfo.Id | Should -Be $info.Id
        $newInfo.Source | Should -Be $info.Source
        $newInfo.GetMetadata("TestKey") | Should -Be "TestValue"
    }
}

# Tests pour ValidationRule
Describe "ValidationRule" {
    It "Devrait crÃ©er une rÃ¨gle de validation" {
        $rule = [ValidationRule]::new("TestProperty", { param($target, $value) $value -eq "TestValue" })
        $rule.PropertyName | Should -Be "TestProperty"
        $rule.RuleId | Should -Not -BeNullOrEmpty
        $rule.IsEnabled | Should -Be $true
    }

    It "Devrait Ã©valuer correctement une rÃ¨gle" {
        $rule = [ValidationRule]::new("Source", { param($target, $value) $value -eq "TestSource" })
        $info = [BaseExtractedInfo]::new("TestSource")

        $result = $rule.Evaluate($info)
        $result | Should -Be $true

        $info.Source = "OtherSource"
        $result = $rule.Evaluate($info)
        $result | Should -Be $false
    }

    It "Devrait dÃ©sactiver et activer une rÃ¨gle" {
        $rule = [ValidationRule]::new("Source", { param($target, $value) $value -eq "TestSource" })
        $info = [BaseExtractedInfo]::new("OtherSource")

        $result = $rule.Evaluate($info)
        $result | Should -Be $false

        $rule.SetEnabled($false)
        $result = $rule.Evaluate($info)
        $result | Should -Be $true

        $rule.SetEnabled($true)
        $result = $rule.Evaluate($info)
        $result | Should -Be $false
    }
}

# Tests pour ValidatableExtractedInfo
Describe "ValidatableExtractedInfo" {
    It "Devrait valider correctement avec les rÃ¨gles par dÃ©faut" {
        $info = [ValidatableExtractedInfo]::new("TestSource")
        $info.ExtractedAt = [datetime]::Now.AddDays(-1)
        $info.ProcessingState = "Raw"
        $info.ConfidenceScore = 75

        $result = $info.Validate()
        $result | Should -Be $true
        $info.IsValid | Should -Be $true
    }

    It "Devrait dÃ©tecter les erreurs de validation" {
        $info = [ValidatableExtractedInfo]::new("")
        $info.ExtractedAt = [datetime]::Now.AddDays(1)  # Date future
        $info.ProcessingState = "InvalidState"
        $info.ConfidenceScore = 150  # Hors limites

        $result = $info.Validate()
        $result | Should -Be $false
        $info.IsValid | Should -Be $false

        $errors = $info.GetValidationErrors()
        $errors.Count | Should -BeGreaterThan 0
    }

    It "Devrait ajouter et supprimer des rÃ¨gles de validation" {
        $info = [ValidatableExtractedInfo]::new("TestSource")

        # Ajouter une rÃ¨gle personnalisÃ©e
        $info.AddValidationRule("Source", { param($target, $value) $value -eq "ValidSource" }, "La source doit Ãªtre 'ValidSource'")

        $result = $info.Validate()
        $result | Should -Be $false

        # Supprimer la rÃ¨gle
        # VÃ©rifier que la rÃ¨gle existe
        $info.GetPropertyValidationRules("Source").Count | Should -BeGreaterThan 0
        $info.RemoveValidationRule("Source", 1)  # Index 1 car il y a dÃ©jÃ  une rÃ¨gle par dÃ©faut

        $result = $info.Validate()
        $result | Should -Be $true
    }
}

# Tests pour TextExtractedInfo
Describe "TextExtractedInfo" {
    It "Devrait crÃ©er une instance avec du texte" {
        $info = [TextExtractedInfo]::new("TestSource", "TestExtractor", "Ceci est un texte de test.")
        $info.Text | Should -Be "Ceci est un texte de test."
        $info.CharacterCount | Should -Be 27
        $info.WordCount | Should -Be 7
    }

    It "Devrait calculer les statistiques du texte" {
        $text = "Ceci est un texte de test. Il contient deux phrases."
        $info = [TextExtractedInfo]::new("TestSource", "TestExtractor", $text)

        $info.TextStatistics.CharacterCount | Should -Be $text.Length
        $info.TextStatistics.WordCount | Should -Be 11
        $info.TextStatistics.SentenceCount | Should -Be 2
    }

    It "Devrait gÃ©nÃ©rer un rÃ©sumÃ©" {
        $text = "Ceci est un texte assez long qui devrait Ãªtre rÃ©sumÃ©. Il contient plusieurs phrases qui ne sont pas toutes nÃ©cessaires dans un rÃ©sumÃ©. Nous voulons simplement tester la fonctionnalitÃ© de rÃ©sumÃ© automatique."
        $info = [TextExtractedInfo]::new("TestSource", "TestExtractor", $text)

        $summary = $info.GenerateSummary(50)
        $summary | Should -Not -BeNullOrEmpty
        $summary.Length | Should -BeLessThan $text.Length
    }

    It "Devrait extraire des mots-clÃ©s" {
        $text = "L'extraction d'informations est un processus important pour l'analyse de donnÃ©es. L'extraction permet d'identifier des Ã©lÃ©ments clÃ©s dans un texte."
        $info = [TextExtractedInfo]::new("TestSource", "TestExtractor", $text)

        $keywords = $info.ExtractKeywords(3)
        $keywords.Count | Should -Be 3
        $keywords | Should -Contain "extraction"
    }
}

# Tests pour StructuredDataExtractedInfo
Describe "StructuredDataExtractedInfo" {
    It "Devrait crÃ©er une instance avec des donnÃ©es" {
        $data = @{
            Name     = "Test"
            Value    = 123
            IsActive = $true
        }

        $info = [StructuredDataExtractedInfo]::new("TestSource", "TestExtractor", $data)
        $info.DataItemCount | Should -Be 3
        $info.DataKeys | Should -Contain "Name"
        $info.DataKeys | Should -Contain "Value"
        $info.DataKeys | Should -Contain "IsActive"
    }

    It "Devrait dÃ©tecter les donnÃ©es imbriquÃ©es" {
        $data = @{
            Level1 = @{
                Level2 = @{
                    Level3 = "Value"
                }
            }
        }

        $info = [StructuredDataExtractedInfo]::new("TestSource", "TestExtractor", $data)
        $info.IsNested | Should -Be $true
        $info.MaxDepth | Should -Be 3
    }

    It "Devrait gÃ©nÃ©rer un schÃ©ma" {
        $data = @{
            Name     = "Test"
            Value    = 123
            IsActive = $true
        }

        $info = [StructuredDataExtractedInfo]::new("TestSource", "TestExtractor", $data)
        $schema = $info.GenerateSchema()

        $schema | Should -Not -BeNullOrEmpty
        $schemaObj = ConvertFrom-Json -InputObject $schema
        $schemaObj.properties.Name.type | Should -Be "string"
        $schemaObj.properties.Value.type | Should -Be "integer"
        $schemaObj.properties.IsActive.type | Should -Be "boolean"
    }

    It "Devrait manipuler les donnÃ©es correctement" {
        $info = [StructuredDataExtractedInfo]::new("TestSource", "TestExtractor")
        $info.SetValue("Name", "Test")
        $info.SetValue("Value", 123)

        $info.ContainsKey("Name") | Should -Be $true
        $info.GetValue("Name") | Should -Be "Test"

        $info.RemoveKey("Name")
        $info.ContainsKey("Name") | Should -Be $false

        $info.MergeWith(@{ NewKey = "NewValue" })
        $info.ContainsKey("NewKey") | Should -Be $true
    }
}

# Tests pour MediaExtractedInfo
Describe "MediaExtractedInfo" {
    BeforeAll {
        # CrÃ©er un fichier texte de test
        $testFilePath = Join-Path -Path $testDir -ChildPath "test_file.txt"
        "Ceci est un fichier de test." | Out-File -FilePath $testFilePath -Encoding UTF8
    }

    It "Devrait crÃ©er une instance avec un fichier mÃ©dia" {
        $info = [MediaExtractedInfo]::new("TestSource", "TestExtractor", $testFilePath)
        $info.MediaPath | Should -Be $testFilePath
        $info.FileSize | Should -BeGreaterThan 0
        $info.MediaType | Should -Be "Document"
        $info.MimeType | Should -Be "text/plain"
    }

    It "Devrait calculer le checksum" {
        $info = [MediaExtractedInfo]::new("TestSource", "TestExtractor", $testFilePath)
        $info.Checksum | Should -Not -BeNullOrEmpty

        $info.VerifyIntegrity($info.Checksum) | Should -Be $true
    }

    It "Devrait extraire les mÃ©tadonnÃ©es du fichier" {
        $info = [MediaExtractedInfo]::new("TestSource", "TestExtractor", $testFilePath)
        $info.MediaMetadata.FileName | Should -Be "test_file.txt"
        $info.MediaMetadata.Extension | Should -Be ".txt"
        $info.MediaMetadata.SizeBytes | Should -BeGreaterThan 0
    }
}

# Tests pour FormatConverter
Describe "FormatConverter" {
    It "Devrait convertir un objet en JSON" {
        $obj = @{
            Name  = "Test"
            Value = 123
        }

        $json = [FormatConverter]::ToJson($obj)
        $json | Should -Not -BeNullOrEmpty

        $newObj = ConvertFrom-Json -InputObject $json
        $newObj.Name | Should -Be "Test"
        $newObj.Value | Should -Be 123
    }

    It "Devrait convertir entre JSON et XML" {
        $json = '{"Name":"Test","Value":123}'
        $xml = [FormatConverter]::ConvertJsonToXml($json)
        $xml | Should -Not -BeNullOrEmpty

        $newJson = [FormatConverter]::ConvertXmlToJson($xml)
        $newObj = ConvertFrom-Json -InputObject $newJson
        $newObj.Name | Should -Be "Test"
        $newObj.Value | Should -Be 123
    }

    It "Devrait dÃ©tecter le format d'une chaÃ®ne" {
        $json = '{"Name":"Test"}'
        $xml = '<root><Name>Test</Name></root>'
        $csv = "Name,Value`nTest,123"

        [FormatConverter]::DetectFormat($json) | Should -Be "Json"
        [FormatConverter]::DetectFormat($xml) | Should -Be "Xml"
        [FormatConverter]::DetectFormat($csv) | Should -Be "Csv"
    }

    It "Devrait convertir entre diffÃ©rents formats" {
        $json = '{"Name":"Test","Value":123}'

        $xml = [FormatConverter]::Convert($json, "Json", "Xml")
        $xml | Should -Not -BeNullOrEmpty

        $newJson = [FormatConverter]::Convert($xml, "Xml", "Json")
        $newObj = ConvertFrom-Json -InputObject $newJson
        $newObj.Name | Should -Be "Test"
        $newObj.Value | Should -Be 123
    }
}

# Tests pour ExtractedInfoConverter
Describe "ExtractedInfoConverter" {
    It "Devrait convertir BaseExtractedInfo en TextExtractedInfo" {
        $base = [BaseExtractedInfo]::new("TestSource", "TestExtractor")
        $base.AddMetadata("TestKey", "TestValue")

        $text = [ExtractedInfoConverter]::ToTextInfo($base, "Ceci est un texte de test.")
        $text.Source | Should -Be "TestSource"
        $text.ExtractorName | Should -Be "TestExtractor"
        $text.GetMetadata("TestKey") | Should -Be "TestValue"
        $text.Text | Should -Be "Ceci est un texte de test."
    }

    It "Devrait convertir TextExtractedInfo en StructuredDataExtractedInfo" {
        $text = [TextExtractedInfo]::new("TestSource", "TestExtractor", "Ceci est un texte de test.")
        $text.SetCategory("Test")
        $text.AddKeyword("texte")

        $structured = [ExtractedInfoConverter]::TextToStructuredData($text)
        $structured.Source | Should -Be "TestSource"
        $structured.GetValue("Text") | Should -Be "Ceci est un texte de test."
        $structured.GetValue("Category") | Should -Be "Test"
        $structured.GetValue("Keywords") | Should -Contain "texte"
    }

    It "Devrait convertir StructuredDataExtractedInfo en TextExtractedInfo" {
        $data = @{
            Text     = "Ceci est un texte de test."
            Language = "fr"
            Category = "Test"
        }

        $structured = [StructuredDataExtractedInfo]::new("TestSource", "TestExtractor", $data)
        $text = [ExtractedInfoConverter]::StructuredDataToText($structured)

        $text.Source | Should -Be "TestSource"
        $text.Text | Should -Be "Ceci est un texte de test."
        $text.Language | Should -Be "fr"
        $text.Category | Should -Be "Test"
    }

    It "Devrait convertir une collection en JSON et vice versa" {
        $collection = [ExtractedInfoCollection]::new("TestCollection")
        $collection.Add([BaseExtractedInfo]::new("Source1"))
        $collection.Add([BaseExtractedInfo]::new("Source2"))

        $json = [ExtractedInfoConverter]::CollectionToJson($collection)
        $json | Should -Not -BeNullOrEmpty

        $newCollection = [ExtractedInfoConverter]::JsonToCollection($json)
        $newCollection.Name | Should -Be "TestCollection"
        $newCollection.Count() | Should -Be 2
        $newCollection.Items[0].Source | Should -Be "Source1"
        $newCollection.Items[1].Source | Should -Be "Source2"
    }
}

# Nettoyer aprÃ¨s les tests
Remove-Item -Path $testDir -Recurse -Force
