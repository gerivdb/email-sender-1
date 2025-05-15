#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Check-FileLengths.ps1.

.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement
    du script Check-FileLengths.ps1 qui analyse la longueur des fichiers dans un projet.

.NOTES
    Version: 1.0
    Auteur: Généré automatiquement
    Date de création: 2025-05-25
#>

# Importer Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Chemin vers le script à tester
$scriptPath = "$PSScriptRoot\..\Check-FileLengths.ps1"

# Créer un dossier temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "TestProject_$(Get-Random)"
$testConfigDir = Join-Path -Path $testDir -ChildPath ".augment"
$testReportsDir = Join-Path -Path $testDir -ChildPath "reports"

# Fonction pour créer un fichier de test avec un nombre spécifique de lignes
function New-TestFile {
    param (
        [string]$Path,
        [string]$Name,
        [int]$Lines,
        [string]$Extension
    )

    $filePath = Join-Path -Path $Path -ChildPath "$Name.$Extension"
    $content = 1..$Lines | ForEach-Object { "Line $_" }
    Set-Content -Path $filePath -Value $content

    return $filePath
}

# Fonction pour créer un fichier de configuration de test
function New-TestConfig {
    param (
        [string]$Path,
        [hashtable]$Limits
    )

    $configContent = @{
        agent_auto = @{
            code_quality = @{
                file_length_limits = $Limits
            }
        }
    } | ConvertTo-Json -Depth 5

    $configPath = Join-Path -Path $Path -ChildPath "config.json"
    Set-Content -Path $configPath -Value $configContent

    return $configPath
}

Describe "Check-FileLengths.ps1" {
    BeforeAll {
        # Créer la structure de test
        New-Item -Path $testDir -ItemType Directory -Force
        New-Item -Path $testConfigDir -ItemType Directory -Force
        New-Item -Path $testReportsDir -ItemType Directory -Force

        # Créer un fichier de configuration de test
        $testLimits = @{
            enabled = $true
            ps1     = 100
            py      = 150
            js      = 80
            md      = 200
        }

        $configPath = New-TestConfig -Path $testConfigDir -Limits $testLimits

        # Créer des fichiers de test
        $testFiles = @(
            @{ Name = "ShortScript"; Lines = 50; Extension = "ps1" }
            @{ Name = "LongScript"; Lines = 150; Extension = "ps1" }
            @{ Name = "ShortPython"; Lines = 100; Extension = "py" }
            @{ Name = "LongPython"; Lines = 200; Extension = "py" }
            @{ Name = "ShortJS"; Lines = 40; Extension = "js" }
            @{ Name = "LongJS"; Lines = 120; Extension = "js" }
            @{ Name = "ShortMarkdown"; Lines = 100; Extension = "md" }
            @{ Name = "LongMarkdown"; Lines = 250; Extension = "md" }
        )

        foreach ($file in $testFiles) {
            New-TestFile -Path $testDir -Name $file.Name -Lines $file.Lines -Extension $file.Extension
        }

        # Créer des dossiers à exclure avec des fichiers
        $excludeDirs = @("node_modules", ".git", "dist", "build", "__pycache__")

        foreach ($dir in $excludeDirs) {
            $excludePath = Join-Path -Path $testDir -ChildPath $dir
            New-Item -Path $excludePath -ItemType Directory -Force
            New-TestFile -Path $excludePath -Name "ExcludedFile" -Lines 500 -Extension "ps1"
        }
    }

    AfterAll {
        # Nettoyer les fichiers de test
        Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Context "Tests des fonctions individuelles" {
        BeforeAll {
            # Dot-sourcer le script pour accéder aux fonctions
            . $scriptPath
        }

        It "Get-FileLengthLimits devrait charger les limites depuis la configuration" {
            $configPath = Join-Path -Path $testConfigDir -ChildPath "config.json"
            $limits = Get-FileLengthLimits -ConfigPath $configPath

            $limits | Should -Not -BeNullOrEmpty
            $limits.ps1 | Should -Be 100
            $limits.py | Should -Be 150
            $limits.js | Should -Be 80
            $limits.md | Should -Be 200
        }

        It "Get-FileLengthLimits devrait retourner des valeurs par défaut si la configuration n'existe pas" {
            $limits = Get-FileLengthLimits -ConfigPath "chemin/inexistant/config.json"

            $limits | Should -Not -BeNullOrEmpty
            $limits.ps1 | Should -Be 300
            $limits.py | Should -Be 500
            $limits.js | Should -Be 300
            $limits.md | Should -Be 600
        }

        It "Measure-FileLengths devrait analyser correctement les fichiers" {
            $configPath = Join-Path -Path $testConfigDir -ChildPath "config.json"
            $limits = Get-FileLengthLimits -ConfigPath $configPath
            $results = Measure-FileLengths -Path $testDir -Limits $limits

            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0

            # Vérifier que les fichiers exclus ne sont pas inclus
            $results | Where-Object { $_.Path -match "node_modules|\.git|dist|build|__pycache__" } | Should -BeNullOrEmpty

            # Vérifier que les statuts sont corrects
            $shortPs1 = $results | Where-Object { $_.Path -match "ShortScript.ps1" }
            $longPs1 = $results | Where-Object { $_.Path -match "LongScript.ps1" }

            $shortPs1.Status | Should -Be "OK"
            $longPs1.Status | Should -Be "Dépasse"
        }

        It "Get-RefactoringStrategy devrait suggérer des stratégies appropriées" {
            # Test pour PS1 avec petit dépassement
            $strategy1 = Get-RefactoringStrategy -Extension "ps1" -LineCount 110 -Limit 100
            $strategy1 | Should -Be "Extraire les fonctions auxiliaires dans un module séparé"

            # Test pour PS1 avec dépassement moyen
            $strategy2 = Get-RefactoringStrategy -Extension "ps1" -LineCount 140 -Limit 100
            $strategy2 | Should -Be "Diviser en scripts thématiques distincts"

            # Test pour PS1 avec grand dépassement
            $strategy3 = Get-RefactoringStrategy -Extension "ps1" -LineCount 200 -Limit 100
            $strategy3 | Should -Be "Refactoriser en module complet avec structure Public/Private"

            # Test pour une extension non spécifiée
            $strategy4 = Get-RefactoringStrategy -Extension "unknown" -LineCount 150 -Limit 100
            $strategy4 | Should -Be "Diviser en fichiers plus petits et plus spécifiques"
        }
    }

    Context "Tests d'intégration" {
        It "Le script devrait s'exécuter sans erreur" {
            $reportPath = Join-Path -Path $testReportsDir -ChildPath "test-report.md"
            $configPath = Join-Path -Path $testConfigDir -ChildPath "config.json"

            { & $scriptPath -Path $testDir -ReportPath $reportPath -ConfigPath $configPath } | Should -Not -Throw

            # Vérifier que le rapport a été généré
            Test-Path $reportPath | Should -Be $true
        }

        It "Le rapport généré devrait contenir les informations attendues" {
            $reportPath = Join-Path -Path $testReportsDir -ChildPath "test-report.md"
            $reportContent = Get-Content -Path $reportPath -Raw

            $reportContent | Should -Match "Rapport d'analyse de longueur des fichiers"
            $reportContent | Should -Match "Fichiers analysés"
            $reportContent | Should -Match "Fichiers dépassant les limites"
            $reportContent | Should -Match "LongScript.ps1"
            $reportContent | Should -Match "LongPython.py"
            $reportContent | Should -Match "LongJS.js"
        }
    }
}
