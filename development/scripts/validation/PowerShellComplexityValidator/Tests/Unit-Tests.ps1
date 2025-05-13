#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module PowerShellComplexityValidator.
.DESCRIPTION
    Ce script contient des tests unitaires pour les fonctions du module
    PowerShellComplexityValidator, en utilisant le framework Pester.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>

[CmdletBinding()]
param()

# Vérifier si Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module -Name Pester -Force

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\PowerShellComplexityValidator.psm1'
Import-Module -Name $modulePath -Force

# Créer un dossier temporaire pour les tests
$tempDir = Join-Path -Path $PSScriptRoot -ChildPath 'temp'
if (-not (Test-Path -Path $tempDir)) {
    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
    Write-Verbose "Dossier temporaire créé : $tempDir"
}

# Créer un fichier de test simple
$testFilePath = Join-Path -Path $tempDir -ChildPath 'TestFile.ps1'
$testFileContent = @'
function Test-SimpleFunction {
    param (
        [string]$Parameter1
    )
    
    Write-Output "Test: $Parameter1"
}

function Test-ComplexFunction {
    param (
        [string]$Parameter1,
        [int]$Parameter2,
        [bool]$Parameter3
    )
    
    if ($Parameter1 -eq "Test") {
        Write-Output "Test"
    }
    elseif ($Parameter1 -eq "Debug") {
        Write-Output "Debug"
    }
    else {
        Write-Output "Unknown"
    }
    
    for ($i = 0; $i -lt $Parameter2; $i++) {
        if ($i % 2 -eq 0) {
            Write-Output "Even: $i"
        }
        else {
            Write-Output "Odd: $i"
        }
    }
    
    switch ($Parameter3) {
        $true { Write-Output "True" }
        $false { Write-Output "False" }
        default { Write-Output "Unknown" }
    }
}
'@

$testFileContent | Out-File -FilePath $testFilePath -Encoding utf8

# Créer des résultats de test fictifs pour la génération du rapport
$mockResults = @(
    [PSCustomObject]@{
        Path = $testFilePath
        Line = 10
        Function = "Test-SimpleFunction"
        Metric = "CyclomaticComplexity"
        Value = 1
        Threshold = 10
        Severity = "Information"
        Message = "Complexité cyclomatique acceptable"
        Rule = "CyclomaticComplexity_LowComplexity"
    },
    [PSCustomObject]@{
        Path = $testFilePath
        Line = 20
        Function = "Test-ComplexFunction"
        Metric = "CyclomaticComplexity"
        Value = 8
        Threshold = 10
        Severity = "Information"
        Message = "Complexité cyclomatique acceptable"
        Rule = "CyclomaticComplexity_LowComplexity"
    },
    [PSCustomObject]@{
        Path = $testFilePath
        Line = 20
        Function = "Test-ComplexFunction"
        Metric = "NestingDepth"
        Value = 3
        Threshold = 5
        Severity = "Information"
        Message = "Profondeur d'imbrication acceptable"
        Rule = "NestingDepth_LowNesting"
    }
)

# Définir les tests Pester
Describe "PowerShellComplexityValidator" {
    Context "Test-PowerShellComplexity" {
        It "Devrait exister en tant que fonction" {
            Get-Command -Name Test-PowerShellComplexity -Module PowerShellComplexityValidator | Should -Not -BeNullOrEmpty
        }

        It "Devrait accepter un chemin de fichier" {
            { Test-PowerShellComplexity -Path $testFilePath } | Should -Not -Throw
        }

        It "Devrait accepter un chemin de répertoire" {
            { Test-PowerShellComplexity -Path $tempDir } | Should -Not -Throw
        }

        It "Devrait accepter des métriques spécifiques" {
            { Test-PowerShellComplexity -Path $testFilePath -Metrics "CyclomaticComplexity", "NestingDepth" } | Should -Not -Throw
        }

        It "Devrait accepter un format de sortie spécifique" {
            { Test-PowerShellComplexity -Path $testFilePath -OutputFormat "JSON" } | Should -Not -Throw
        }

        It "Devrait accepter un chemin de sortie" {
            $outputPath = Join-Path -Path $tempDir -ChildPath "output.json"
            { Test-PowerShellComplexity -Path $testFilePath -OutputFormat "JSON" -OutputPath $outputPath } | Should -Not -Throw
            Test-Path -Path $outputPath | Should -Be $false # Pas de résultats pour le moment
        }

        It "Devrait accepter un niveau de sévérité" {
            { Test-PowerShellComplexity -Path $testFilePath -Severity "Warning" } | Should -Not -Throw
        }

        It "Devrait accepter des règles à inclure" {
            { Test-PowerShellComplexity -Path $testFilePath -IncludeRule "CyclomaticComplexity_HighComplexity" } | Should -Not -Throw
        }

        It "Devrait accepter des règles à exclure" {
            { Test-PowerShellComplexity -Path $testFilePath -ExcludeRule "CyclomaticComplexity_LowComplexity" } | Should -Not -Throw
        }

        It "Devrait retourner un tableau vide pour les métriques non implémentées" {
            $results = Test-PowerShellComplexity -Path $testFilePath
            $results | Should -BeNullOrEmpty
        }
    }

    Context "New-PowerShellComplexityReport" {
        It "Devrait exister en tant que fonction" {
            Get-Command -Name New-PowerShellComplexityReport -Module PowerShellComplexityValidator | Should -Not -BeNullOrEmpty
        }

        It "Devrait accepter des résultats d'analyse" {
            { New-PowerShellComplexityReport -Results $mockResults } | Should -Not -Throw
        }

        It "Devrait générer un rapport au format texte" {
            $report = New-PowerShellComplexityReport -Results $mockResults -Format "Text"
            $report | Should -Not -BeNullOrEmpty
        }

        It "Devrait générer un rapport au format JSON" {
            $report = New-PowerShellComplexityReport -Results $mockResults -Format "JSON"
            $report | Should -Not -BeNullOrEmpty
            { $report | ConvertFrom-Json } | Should -Not -Throw
        }

        It "Devrait générer un rapport au format CSV" {
            $report = New-PowerShellComplexityReport -Results $mockResults -Format "CSV"
            $report | Should -Not -BeNullOrEmpty
            $report.Split("`n").Count | Should -BeGreaterThan 1
        }

        It "Devrait générer un rapport au format HTML" {
            $report = New-PowerShellComplexityReport -Results $mockResults -Format "HTML"
            $report | Should -Not -BeNullOrEmpty
            $report | Should -Match "<html"
            $report | Should -Match "</html>"
        }

        It "Devrait écrire un rapport dans un fichier" {
            $outputPath = Join-Path -Path $tempDir -ChildPath "report.html"
            New-PowerShellComplexityReport -Results $mockResults -Format "HTML" -OutputPath $outputPath
            Test-Path -Path $outputPath | Should -Be $true
            $content = Get-Content -Path $outputPath -Raw
            $content | Should -Match "<html"
            $content | Should -Match "</html>"
        }

        It "Devrait inclure un titre personnalisé" {
            $title = "Rapport de test"
            $report = New-PowerShellComplexityReport -Results $mockResults -Format "HTML" -Title $title
            $report | Should -Match $title
        }

        It "Devrait filtrer les métriques à inclure" {
            $report = New-PowerShellComplexityReport -Results $mockResults -Format "JSON" -IncludeMetrics "CyclomaticComplexity"
            $json = $report | ConvertFrom-Json
            $json.Count | Should -Be 2
            $json[0].Metric | Should -Be "CyclomaticComplexity"
            $json[1].Metric | Should -Be "CyclomaticComplexity"
        }

        It "Devrait filtrer les métriques à exclure" {
            $report = New-PowerShellComplexityReport -Results $mockResults -Format "JSON" -ExcludeMetrics "CyclomaticComplexity"
            $json = $report | ConvertFrom-Json
            $json.Count | Should -Be 1
            $json[0].Metric | Should -Be "NestingDepth"
        }
    }
}

# Exécuter les tests
Invoke-Pester -Output Detailed

# Nettoyer les fichiers temporaires
if (Test-Path -Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
    Write-Verbose "Dossier temporaire supprimé : $tempDir"
}
