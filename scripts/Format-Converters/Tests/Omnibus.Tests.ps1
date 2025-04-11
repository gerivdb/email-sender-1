#Requires -Version 5.1
<#
.SYNOPSIS
    Tests omnibus pour le module Format-Converters.

.DESCRIPTION
    Ce fichier contient des tests qui couvrent plusieurs fonctions du module Format-Converters
    pour améliorer rapidement la couverture de test.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Format-Converters.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module -Name $modulePath -Force
}

BeforeAll {
    # S'assurer que le module est importé
    if (-not (Get-Module -Name Format-Converters)) {
        $modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Format-Converters.psm1"
        if (Test-Path -Path $modulePath) {
            Import-Module -Name $modulePath -Force
        }
    }

    # Créer un répertoire temporaire pour les tests
    $testTempDir = Join-Path -Path $env:TEMP -ChildPath "FormatConvertersTests_$(Get-Random)"
    New-Item -Path $testTempDir -ItemType Directory -Force | Out-Null
    Write-Host "Répertoire temporaire créé : $testTempDir"

    # Créer des fichiers de test pour différents formats
    $jsonFilePath = Join-Path -Path $testTempDir -ChildPath "test.json"
    $jsonContent = '{"name":"Test","version":"1.0.0"}'
    $jsonContent | Set-Content -Path $jsonFilePath -Encoding UTF8
    Write-Host "Fichier JSON créé : $jsonFilePath"

    $xmlFilePath = Join-Path -Path $testTempDir -ChildPath "test.xml"
    $xmlContent = '<root><name>Test</name><version>1.0.0</version></root>'
    $xmlContent | Set-Content -Path $xmlFilePath -Encoding UTF8
    Write-Host "Fichier XML créé : $xmlFilePath"

    $htmlFilePath = Join-Path -Path $testTempDir -ChildPath "test.html"
    $htmlContent = '<html><head><title>Test</title></head><body><h1>Test</h1><p>Version 1.0.0</p></body></html>'
    $htmlContent | Set-Content -Path $htmlFilePath -Encoding UTF8
    Write-Host "Fichier HTML créé : $htmlFilePath"

    $csvFilePath = Join-Path -Path $testTempDir -ChildPath "test.csv"
    $csvContent = "Name,Version`nTest,1.0.0"
    $csvContent | Set-Content -Path $csvFilePath -Encoding UTF8
    Write-Host "Fichier CSV créé : $csvFilePath"

    $textFilePath = Join-Path -Path $testTempDir -ChildPath "test.txt"
    $textContent = "Name: Test`nVersion: 1.0.0"
    $textContent | Set-Content -Path $textFilePath -Encoding UTF8
    Write-Host "Fichier texte créé : $textFilePath"

    # Vérifier que les fichiers ont été créés
    Write-Host "Vérification des fichiers créés :"
    Write-Host "JSON : $jsonFilePath - $(Test-Path -Path $jsonFilePath)"
    Write-Host "XML : $xmlFilePath - $(Test-Path -Path $xmlFilePath)"
    Write-Host "HTML : $htmlFilePath - $(Test-Path -Path $htmlFilePath)"
    Write-Host "CSV : $csvFilePath - $(Test-Path -Path $csvFilePath)"
    Write-Host "Texte : $textFilePath - $(Test-Path -Path $textFilePath)"

    # Créer un fichier de sortie pour les conversions
    $outputDir = Join-Path -Path $testTempDir -ChildPath "Output"
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null

    # Créer un fichier ambigu (qui peut être interprété comme JSON ou XML)
    $ambiguousFilePath = Join-Path -Path $testTempDir -ChildPath "ambiguous.txt"
    $ambiguousContent = '<root>{"name":"Test"}</root>'
    $ambiguousContent | Set-Content -Path $ambiguousFilePath -Encoding UTF8

    # Créer un fichier vide
    $emptyFilePath = Join-Path -Path $testTempDir -ChildPath "empty.txt"
    "" | Set-Content -Path $emptyFilePath -Encoding UTF8

    # Créer un fichier avec un format invalide
    $invalidFilePath = Join-Path -Path $testTempDir -ChildPath "invalid.json"
    $invalidContent = '{"name":"Test",}'
    $invalidContent | Set-Content -Path $invalidFilePath -Encoding UTF8

    # Créer un fichier avec un format non pris en charge
    $unsupportedFilePath = Join-Path -Path $testTempDir -ChildPath "unsupported.xyz"
    $unsupportedContent = "Contenu non pris en charge"
    $unsupportedContent | Set-Content -Path $unsupportedFilePath -Encoding UTF8

    # Créer un fichier pour les tests de rapport
    $reportDir = Join-Path -Path $testTempDir -ChildPath "Reports"
    New-Item -Path $reportDir -ItemType Directory -Force | Out-Null

    # Créer un mock pour la fonction Read-Host
    function global:MockReadHost { return "1" }

    # Sauvegarder la fonction originale dans une variable script pour pouvoir la restaurer dans AfterAll
    $script:originalReadHost = Get-Command -Name Read-Host -CommandType Cmdlet

    # Remplacer Read-Host par notre mock
    New-Item -Path function:Read-Host -Value $function:global:MockReadHost -Force | Out-Null
}

Describe "Tests omnibus pour le module Format-Converters" {
    Context "Test-FileFormat" {
        It "Détecte correctement le format d'un fichier JSON" {
            $result = Test-FileFormat -FilePath $jsonFilePath
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "JSON"
        }

        It "Détecte correctement le format d'un fichier XML" {
            $result = Test-FileFormat -FilePath $xmlFilePath
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "XML"
        }

        It "Détecte correctement le format d'un fichier HTML" {
            $result = Test-FileFormat -FilePath $htmlFilePath
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "HTML"
        }

        It "Détecte correctement le format d'un fichier CSV" {
            $result = Test-FileFormat -FilePath $csvFilePath
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "CSV"
        }

        It "Détecte correctement le format d'un fichier texte" {
            $result = Test-FileFormat -FilePath $textFilePath
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "TEXT"
        }

        It "Vérifie si un format attendu correspond" {
            $result = Test-FileFormat -FilePath $jsonFilePath -ExpectedFormat "JSON"
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "JSON"
            $result.FormatMatches | Should -BeTrue
        }

        It "Vérifie si un format attendu ne correspond pas" {
            $result = Test-FileFormat -FilePath $jsonFilePath -ExpectedFormat "XML"
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "JSON"
            $result.FormatMatches | Should -BeFalse
        }

        It "Inclut tous les formats détectés si demandé" {
            $result = Test-FileFormat -FilePath $ambiguousFilePath -IncludeAllFormats
            $result | Should -Not -BeNullOrEmpty
            $result.AllFormats | Should -Not -BeNullOrEmpty
            $result.AllFormats.Count | Should -BeGreaterThan 1
        }

        It "Gère correctement les fichiers inexistants" {
            $nonExistentPath = Join-Path -Path $testTempDir -ChildPath "nonexistent.txt"
            { Test-FileFormat -FilePath $nonExistentPath } | Should -Throw
        }
    }

    Context "Test-FileFormatWithConfirmation" {
        It "Confirme automatiquement le format si AutoResolve est spécifié" {
            $result = Test-FileFormatWithConfirmation -FilePath $jsonFilePath -AutoResolve
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "JSON"
        }

        It "Affiche les détails si ShowDetails est spécifié" {
            $result = Test-FileFormatWithConfirmation -FilePath $jsonFilePath -ShowDetails
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "JSON"
        }

        It "Mémorise les choix si RememberChoices est spécifié" {
            $result = Test-FileFormatWithConfirmation -FilePath $jsonFilePath -RememberChoices
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "JSON"

            # Tester à nouveau avec le même fichier
            $result2 = Test-FileFormatWithConfirmation -FilePath $jsonFilePath -RememberChoices
            $result2 | Should -Not -BeNullOrEmpty
            $result2.DetectedFormat | Should -Be "JSON"
        }
    }

    Context "Get-FileFormatAnalysis" {
        It "Analyse correctement un fichier avec un format spécifié" {
            $result = Get-FileFormatAnalysis -FilePath $jsonFilePath -Format "JSON"
            $result | Should -Not -BeNullOrEmpty
            $result.Format | Should -Be "JSON"
        }

        It "Détecte automatiquement le format si AutoDetect est spécifié" {
            $result = Get-FileFormatAnalysis -FilePath $jsonFilePath -AutoDetect
            $result | Should -Not -BeNullOrEmpty
            $result.Format | Should -Be "JSON"
        }

        It "Inclut le contenu du fichier si IncludeContent est spécifié" {
            $result = Get-FileFormatAnalysis -FilePath $jsonFilePath -IncludeContent
            $result | Should -Not -BeNullOrEmpty
            $result.Content | Should -Not -BeNullOrEmpty
        }

        It "Exporte un rapport si ExportReport est spécifié" {
            $reportPath = Join-Path -Path $reportDir -ChildPath "report.json"
            $result = Get-FileFormatAnalysis -FilePath $jsonFilePath -ExportReport -ReportPath $reportPath
            $result | Should -Not -BeNullOrEmpty
            Test-Path -Path $reportPath | Should -BeTrue
        }
    }

    Context "Convert-FileFormat" {
        It "Convertit un fichier JSON en XML" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "json_to_xml.xml"
            $result = Convert-FileFormat -InputPath $jsonFilePath -OutputPath $outputPath -InputFormat "JSON" -OutputFormat "XML"
            $result | Should -Not -BeNullOrEmpty
            Test-Path -Path $outputPath | Should -BeTrue
        }

        It "Convertit un fichier XML en JSON" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "xml_to_json.json"
            $result = Convert-FileFormat -InputPath $xmlFilePath -OutputPath $outputPath -InputFormat "XML" -OutputFormat "JSON"
            $result | Should -Not -BeNullOrEmpty
            Test-Path -Path $outputPath | Should -BeTrue
        }

        It "Détecte automatiquement le format d'entrée si AutoDetect est spécifié" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "auto_to_xml.xml"
            $result = Convert-FileFormat -InputPath $jsonFilePath -OutputPath $outputPath -OutputFormat "XML" -AutoDetect
            $result | Should -Not -BeNullOrEmpty
            Test-Path -Path $outputPath | Should -BeTrue
        }

        It "Écrase un fichier existant si Force est spécifié" {
            $outputPath = Join-Path -Path $outputDir -ChildPath "force_test.xml"
            "Contenu existant" | Set-Content -Path $outputPath -Encoding UTF8

            $result = Convert-FileFormat -InputPath $jsonFilePath -OutputPath $outputPath -InputFormat "JSON" -OutputFormat "XML" -Force
            $result | Should -Not -BeNullOrEmpty
            Test-Path -Path $outputPath | Should -BeTrue
            Get-Content -Path $outputPath -Raw | Should -Not -Be "Contenu existant"
        }
    }

    Context "Handle-AmbiguousFormats" {
        It "Gère les formats ambigus avec ShowConfidenceScores" {
            $detectedFormats = @(
                [PSCustomObject]@{ Format = "JSON"; Score = 80; Priority = 5 },
                [PSCustomObject]@{ Format = "XML"; Score = 75; Priority = 4 }
            )

            $result = Handle-AmbiguousFormats -DetectedFormats $detectedFormats -ShowConfidenceScores
            $result | Should -Not -BeNullOrEmpty
            $result.Format | Should -Be "JSON"
        }

        It "Sélectionne automatiquement le format avec le score le plus élevé si AutoSelectHighest est spécifié" {
            $detectedFormats = @(
                [PSCustomObject]@{ Format = "JSON"; Score = 80; Priority = 5 },
                [PSCustomObject]@{ Format = "XML"; Score = 85; Priority = 4 }
            )

            $result = Handle-AmbiguousFormats -DetectedFormats $detectedFormats -AutoSelectHighest
            $result | Should -Not -BeNullOrEmpty
            $result.Format | Should -Be "XML"
        }

        It "Utilise le choix par défaut si DefaultChoice est spécifié" {
            $detectedFormats = @(
                [PSCustomObject]@{ Format = "JSON"; Score = 80; Priority = 5 },
                [PSCustomObject]@{ Format = "XML"; Score = 75; Priority = 4 }
            )

            $result = Handle-AmbiguousFormats -DetectedFormats $detectedFormats -DefaultChoice 2
            $result | Should -Not -BeNullOrEmpty
            $result.Format | Should -Be "XML"
        }

        It "Gère correctement les listes vides" {
            $result = Handle-AmbiguousFormats -DetectedFormats @()
            $result | Should -BeNullOrEmpty
        }
    }

    Context "Show-FormatDetectionResults" {
        It "Affiche les résultats de détection" {
            $detectionResults = [PSCustomObject]@{
                FilePath = $jsonFilePath
                FileSize = (Get-Item -Path $jsonFilePath).Length
                FileType = "Text"
                DetectedFormat = "JSON"
                ConfidenceScore = 95
                AllFormats = @(
                    [PSCustomObject]@{ Format = "JSON"; Score = 95; Priority = 5 },
                    [PSCustomObject]@{ Format = "TEXT"; Score = 60; Priority = 1 }
                )
            }

            $result = Show-FormatDetectionResults -DetectionResults $detectionResults
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "JSON"
        }

        It "Inclut tous les formats si IncludeAllFormats est spécifié" {
            $detectionResults = [PSCustomObject]@{
                FilePath = $jsonFilePath
                FileSize = (Get-Item -Path $jsonFilePath).Length
                FileType = "Text"
                DetectedFormat = "JSON"
                ConfidenceScore = 95
                AllFormats = @(
                    [PSCustomObject]@{ Format = "JSON"; Score = 95; Priority = 5 },
                    [PSCustomObject]@{ Format = "TEXT"; Score = 60; Priority = 1 }
                )
            }

            $result = Show-FormatDetectionResults -DetectionResults $detectionResults -IncludeAllFormats
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "JSON"
        }

        It "Exporte les résultats au format JSON si ExportToJson est spécifié" {
            $detectionResults = [PSCustomObject]@{
                FilePath = $jsonFilePath
                FileSize = (Get-Item -Path $jsonFilePath).Length
                FileType = "Text"
                DetectedFormat = "JSON"
                ConfidenceScore = 95
                AllFormats = @(
                    [PSCustomObject]@{ Format = "JSON"; Score = 95; Priority = 5 },
                    [PSCustomObject]@{ Format = "TEXT"; Score = 60; Priority = 1 }
                )
            }

            $result = Show-FormatDetectionResults -DetectionResults $detectionResults -ExportToJson -OutputDirectory $reportDir
            $result | Should -Not -BeNullOrEmpty
            $jsonReportPath = Join-Path -Path $reportDir -ChildPath "results.json"
            Test-Path -Path $jsonReportPath | Should -BeTrue
        }

        It "Exporte les résultats au format CSV si ExportToCsv est spécifié" {
            $detectionResults = [PSCustomObject]@{
                FilePath = $jsonFilePath
                FileSize = (Get-Item -Path $jsonFilePath).Length
                FileType = "Text"
                DetectedFormat = "JSON"
                ConfidenceScore = 95
                AllFormats = @(
                    [PSCustomObject]@{ Format = "JSON"; Score = 95; Priority = 5 },
                    [PSCustomObject]@{ Format = "TEXT"; Score = 60; Priority = 1 }
                )
            }

            $result = Show-FormatDetectionResults -DetectionResults $detectionResults -ExportToCsv -OutputDirectory $reportDir
            $result | Should -Not -BeNullOrEmpty
            $csvReportPath = Join-Path -Path $reportDir -ChildPath "results.csv"
            Test-Path -Path $csvReportPath | Should -BeTrue
        }

        It "Exporte les résultats au format HTML si ExportToHtml est spécifié" {
            $detectionResults = [PSCustomObject]@{
                FilePath = $jsonFilePath
                FileSize = (Get-Item -Path $jsonFilePath).Length
                FileType = "Text"
                DetectedFormat = "JSON"
                ConfidenceScore = 95
                AllFormats = @(
                    [PSCustomObject]@{ Format = "JSON"; Score = 95; Priority = 5 },
                    [PSCustomObject]@{ Format = "TEXT"; Score = 60; Priority = 1 }
                )
            }

            $result = Show-FormatDetectionResults -DetectionResults $detectionResults -ExportToHtml -OutputDirectory $reportDir
            $result | Should -Not -BeNullOrEmpty
            $htmlReportPath = Join-Path -Path $reportDir -ChildPath "results.html"
            Test-Path -Path $htmlReportPath | Should -BeTrue
        }
    }

    Context "Register-FormatConverter et Get-RegisteredConverters" {
        It "Enregistre un convertisseur et le récupère" {
            # Enregistrer un convertisseur de test
            $sourceFormat = "TEST"
            $targetFormat = "XML"
            $conversionScript = { param($SourcePath, $TargetPath) return $true }
            $priority = 10

            $result = Register-FormatConverter -SourceFormat $sourceFormat -TargetFormat $targetFormat -ConversionScript $conversionScript -Priority $priority
            $result | Should -Not -BeNullOrEmpty
            $result.SourceFormat | Should -Be $sourceFormat
            $result.TargetFormat | Should -Be $targetFormat
            $result.Priority | Should -Be $priority

            # Récupérer les convertisseurs
            $converters = Get-RegisteredConverters
            $converters | Should -Not -BeNullOrEmpty

            # Récupérer les convertisseurs filtrés par format source
            $sourceConverters = Get-RegisteredConverters -SourceFormat "JSON"
            $sourceConverters | Should -Not -BeNullOrEmpty
            $sourceConverters | ForEach-Object { $_.SourceFormat | Should -Be "JSON" }

            # Récupérer les convertisseurs filtrés par format cible
            $targetConverters = Get-RegisteredConverters -TargetFormat "XML"
            $targetConverters | Should -Not -BeNullOrEmpty
            $targetConverters | ForEach-Object { $_.TargetFormat | Should -Be "XML" }

            # Récupérer les convertisseurs filtrés par format source et cible
            $filteredConverters = Get-RegisteredConverters -SourceFormat "JSON" -TargetFormat "XML"
            $filteredConverters | Should -Not -BeNullOrEmpty
            $filteredConverters | ForEach-Object {
                $_.SourceFormat | Should -Be "JSON"
                $_.TargetFormat | Should -Be "XML"
            }
        }
    }
}

AfterAll {
    # Restaurer la fonction Read-Host originale
    if ($script:originalReadHost) {
        New-Item -Path function:Read-Host -Value $script:originalReadHost.ScriptBlock -Force | Out-Null
    }

    # Supprimer le répertoire temporaire
    if (Test-Path -Path $testTempDir) {
        Remove-Item -Path $testTempDir -Recurse -Force
        Write-Host "Répertoire temporaire supprimé : $testTempDir"
    }
}
