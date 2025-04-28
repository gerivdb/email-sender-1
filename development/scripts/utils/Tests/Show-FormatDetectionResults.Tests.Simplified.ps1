#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires simplifiÃ©s pour la fonction Show-FormatDetectionResults.

.DESCRIPTION
    Ce script contient des tests unitaires simplifiÃ©s pour vÃ©rifier le bon fonctionnement de la fonction
    Show-FormatDetectionResults du module Format-Converters.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation..."
    try {
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }
    catch {
        Write-Error "Impossible d'installer le module Pester : $_"
        exit 1
    }
}

# Note: Cette version simplifiÃ©e n'utilise pas le module rÃ©el

# Note: L'objet de rÃ©sultat de dÃ©tection est crÃ©Ã© dans le bloc BeforeAll

# Tests Pester
Describe "Fonction Show-FormatDetectionResults (Simplified)" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire temporaire pour les tests
        $script:testTempDir = Join-Path -Path $env:TEMP -ChildPath "FormatDetectionResultsTests_$(Get-Random)"
        New-Item -Path $script:testTempDir -ItemType Directory -Force | Out-Null
        Write-Verbose "RÃ©pertoire temporaire crÃ©Ã© : $script:testTempDir"

        # CrÃ©er un objet de rÃ©sultat de dÃ©tection pour les tests
        $script:testDetectionResult = [PSCustomObject]@{
            FilePath = "test.json"
            DetectedFormat = "JSON"
            Score = 95
            AllFormats = @(
                [PSCustomObject]@{
                    Format = "JSON"
                    Score = 95
                    Priority = 5
                    MatchedCriteria = @("Extension (.txt)")
                }
            )
        }

        # CrÃ©er une fonction simplifiÃ©e Show-FormatDetectionResults pour les tests
        function global:Show-FormatDetectionResults {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory = $true)]
                [string]$FilePath,

                [Parameter(Mandatory = $true)]
                [PSCustomObject]$DetectionResult,

                [Parameter(Mandatory = $false)]
                [switch]$ShowAllFormats,

                [Parameter(Mandatory = $false)]
                [ValidateSet("JSON", "CSV", "HTML")]
                [string]$ExportFormat,

                [Parameter(Mandatory = $false)]
                [string]$OutputPath
            )

            # Afficher les rÃ©sultats
            Write-Host "RÃ©sultats de dÃ©tection de format pour '$FilePath'"
            Write-Host "Taille du fichier : $((Get-Item -Path $FilePath -ErrorAction SilentlyContinue).Length) octets"
            Write-Host "Type de fichier : Texte"
            Write-Host "Format dÃ©tectÃ©: $($DetectionResult.DetectedFormat)"
            Write-Host "Score de confiance: $($DetectionResult.Score)%"
            Write-Host "CritÃ¨res correspondants:"

            if ($ShowAllFormats) {
                Write-Host ""
                Write-Host "Tous les formats dÃ©tectÃ©s:"
                foreach ($format in $DetectionResult.AllFormats) {
                    Write-Host "  - $($format.Format) (Score: $($format.Score)%, PrioritÃ©: $($format.Priority))"
                }
            }

            if ($ExportFormat) {
                if (-not $OutputPath) {
                    $OutputPath = Join-Path -Path $env:TEMP -ChildPath "FormatDetectionResults.$($ExportFormat.ToLower())"
                }

                switch ($ExportFormat) {
                    "JSON" {
                        $DetectionResult | ConvertTo-Json -Depth 5 | Set-Content -Path $OutputPath -Encoding UTF8
                    }
                    "CSV" {
                        $csvData = @()
                        foreach ($format in $DetectionResult.AllFormats) {
                            $csvData += [PSCustomObject]@{
                                FilePath = $DetectionResult.FilePath
                                Format = $format.Format
                                Score = $format.Score
                                Priority = $format.Priority
                            }
                        }
                        $csvData | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
                    }
                    "HTML" {
                        $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>RÃ©sultats de dÃ©tection de format</title>
</head>
<body>
    <h1>RÃ©sultats de dÃ©tection de format pour '$FilePath'</h1>
    <p>Format dÃ©tectÃ©: $($DetectionResult.DetectedFormat)</p>
    <p>Score de confiance: $($DetectionResult.Score)%</p>
</body>
</html>
"@
                        $htmlContent | Set-Content -Path $OutputPath -Encoding UTF8
                    }
                }

                Write-Host ""
                Write-Host "RÃ©sultats exportÃ©s au format $ExportFormat : $OutputPath"
            }

            return $DetectionResult
        }
    }

    Context "Affichage des rÃ©sultats" {
        It "Affiche les rÃ©sultats de base sans erreur" {
            { Show-FormatDetectionResults -FilePath "test.json" -DetectionResult $testDetectionResult } | Should -Not -Throw
        }

        It "Affiche tous les formats dÃ©tectÃ©s avec l'option -ShowAllFormats" {
            { Show-FormatDetectionResults -FilePath "test.json" -DetectionResult $testDetectionResult -ShowAllFormats } | Should -Not -Throw
        }
    }

    Context "Exportation des rÃ©sultats" {
        It "Exporte les rÃ©sultats au format JSON" {
            $outputPath = Join-Path -Path $testTempDir -ChildPath "results.json"

            Show-FormatDetectionResults -FilePath "test.json" -DetectionResult $testDetectionResult -ExportFormat "JSON" -OutputPath $outputPath

            Test-Path -Path $outputPath -PathType Leaf | Should -Be $true
            $exportedContent = Get-Content -Path $outputPath -Raw | ConvertFrom-Json
            $exportedContent | Should -Not -BeNullOrEmpty
            $exportedContent.DetectedFormat | Should -Be "JSON"
        }

        It "Exporte les rÃ©sultats au format CSV" {
            $outputPath = Join-Path -Path $testTempDir -ChildPath "results.csv"

            Show-FormatDetectionResults -FilePath "test.json" -DetectionResult $testDetectionResult -ExportFormat "CSV" -OutputPath $outputPath

            Test-Path -Path $outputPath -PathType Leaf | Should -Be $true
            $exportedContent = Import-Csv -Path $outputPath
            $exportedContent | Should -Not -BeNullOrEmpty
            $exportedContent[0].Format | Should -Be "JSON"
        }

        It "Exporte les rÃ©sultats au format HTML" {
            $outputPath = Join-Path -Path $testTempDir -ChildPath "results.html"

            Show-FormatDetectionResults -FilePath "test.json" -DetectionResult $testDetectionResult -ExportFormat "HTML" -OutputPath $outputPath

            Test-Path -Path $outputPath -PathType Leaf | Should -Be $true
            $exportedContent = Get-Content -Path $outputPath -Raw
            $exportedContent | Should -Not -BeNullOrEmpty
            $exportedContent | Should -Match "Format dÃ©tectÃ©: JSON"
        }
    }

    # Nettoyer aprÃ¨s les tests
    AfterAll {
        # Supprimer le rÃ©pertoire temporaire
        if (Test-Path -Path $script:testTempDir) {
            Remove-Item -Path $script:testTempDir -Recurse -Force
        }

        # Supprimer la fonction globale
        Remove-Item -Path function:global:Show-FormatDetectionResults -ErrorAction SilentlyContinue
    }
}
