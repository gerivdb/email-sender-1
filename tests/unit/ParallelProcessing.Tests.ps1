#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module ParallelProcessing.ps1.
.DESCRIPTION
    Ce script contient des tests unitaires pour le module ParallelProcessing.ps1.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-06-06
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Chemins des modules à tester
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modulesPath = Join-Path -Path $projectRoot -ChildPath "modules"
$parallelProcessingPath = Join-Path -Path $modulesPath -ChildPath "ParallelProcessing.ps1"
$unifiedSegmenterPath = Join-Path -Path $modulesPath -ChildPath "UnifiedSegmenter.ps1"

# Créer un répertoire temporaire pour les tests
$testTempDir = Join-Path -Path $env:TEMP -ChildPath "ParallelProcessingTests"
if (Test-Path -Path $testTempDir) {
    Remove-Item -Path $testTempDir -Recurse -Force
}
New-Item -Path $testTempDir -ItemType Directory -Force | Out-Null

# Créer des fichiers de test
$testFiles = @()
$inputDir = Join-Path -Path $testTempDir -ChildPath "input"
$outputDir = Join-Path -Path $testTempDir -ChildPath "output"
New-Item -Path $inputDir -ItemType Directory -Force | Out-Null
New-Item -Path $outputDir -ItemType Directory -Force | Out-Null

# Créer des fichiers CSV de test
for ($i = 1; $i -le 5; $i++) {
    $csvPath = Join-Path -Path $inputDir -ChildPath "test$i.csv"
    $csvContent = "id,name,value`n"
    for ($j = 1; $j -le 10; $j++) {
        $id = ($i - 1) * 10 + $j
        $csvContent += "$id,Name $id,Value $id`n"
    }
    Set-Content -Path $csvPath -Value $csvContent -Encoding UTF8
    $testFiles += $csvPath
}

# Définir les tests
Describe "Tests du module ParallelProcessing" {
    BeforeAll {
        # Importer les modules
        . $parallelProcessingPath
        . $unifiedSegmenterPath
        
        # Initialiser le segmenteur unifié
        $initResult = Initialize-UnifiedSegmenter
        $initResult | Should -Be $true
    }
    
    Context "Tests de la fonction Invoke-ParallelFileProcessing" {
        It "Traite correctement les fichiers en parallèle" {
            # Définir le script block de test
            $scriptBlock = {
                param($FilePath)
                
                # Lire le contenu du fichier
                $content = Get-Content -Path $FilePath -Raw
                
                # Retourner un objet avec le chemin du fichier et le nombre de lignes
                return [PSCustomObject]@{
                    FilePath = $FilePath
                    LineCount = ($content -split "`n").Count
                }
            }
            
            # Exécuter le traitement parallèle
            $results = Invoke-ParallelFileProcessing -FilePaths $testFiles -ScriptBlock $scriptBlock -ThrottleLimit 3
            
            # Vérifier les résultats
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be $testFiles.Count
            
            foreach ($result in $results) {
                $result.FilePath | Should -BeIn $testFiles
                $result.LineCount | Should -BeGreaterThan 10
            }
        }
        
        It "Passe correctement les paramètres au script block" {
            # Définir le script block de test
            $scriptBlock = {
                param($FilePath, $Prefix, $Suffix)
                
                # Retourner un objet avec les paramètres
                return [PSCustomObject]@{
                    FilePath = $FilePath
                    Prefix = $Prefix
                    Suffix = $Suffix
                }
            }
            
            # Définir les paramètres
            $parameters = @{
                Prefix = "Test"
                Suffix = "Suffix"
            }
            
            # Exécuter le traitement parallèle
            $results = Invoke-ParallelFileProcessing -FilePaths $testFiles -ScriptBlock $scriptBlock -ThrottleLimit 3 -Parameters $parameters
            
            # Vérifier les résultats
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be $testFiles.Count
            
            foreach ($result in $results) {
                $result.FilePath | Should -BeIn $testFiles
                $result.Prefix | Should -Be "Test"
                $result.Suffix | Should -Be "Suffix"
            }
        }
    }
    
    Context "Tests de la fonction Convert-FilesInParallel" {
        It "Convertit correctement les fichiers CSV en JSON" {
            # Exécuter la conversion parallèle
            $results = Convert-FilesInParallel -InputFiles $testFiles -OutputDir $outputDir -InputFormat "CSV" -OutputFormat "JSON" -ThrottleLimit 3
            
            # Vérifier les résultats
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be $testFiles.Count
            
            foreach ($result in $results) {
                $result.InputFile | Should -BeIn $testFiles
                $result.Success | Should -Be $true
                
                # Vérifier que le fichier de sortie existe
                Test-Path -Path $result.OutputFile | Should -Be $true
                
                # Vérifier que le fichier de sortie est un JSON valide
                $jsonContent = Get-Content -Path $result.OutputFile -Raw
                { $jsonContent | ConvertFrom-Json } | Should -Not -Throw
            }
        }
        
        It "Gère correctement les erreurs de conversion" {
            # Créer un fichier CSV invalide
            $invalidCsvPath = Join-Path -Path $inputDir -ChildPath "invalid.csv"
            $invalidCsvContent = "id,name,value`n1,Name 1,Value 1`n2,Name 2"  # Ligne invalide
            Set-Content -Path $invalidCsvPath -Value $invalidCsvContent -Encoding UTF8
            
            # Exécuter la conversion parallèle
            $results = Convert-FilesInParallel -InputFiles @($invalidCsvPath) -OutputDir $outputDir -InputFormat "CSV" -OutputFormat "JSON" -ThrottleLimit 3
            
            # Vérifier les résultats
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be 1
            $results[0].InputFile | Should -Be $invalidCsvPath
            $results[0].Success | Should -Be $false
        }
    }
    
    Context "Tests de la fonction Get-FileAnalysisInParallel" {
        It "Analyse correctement les fichiers CSV" {
            # Exécuter l'analyse parallèle
            $results = Get-FileAnalysisInParallel -FilePaths $testFiles -Format "CSV" -OutputDir $outputDir -ThrottleLimit 3
            
            # Vérifier les résultats
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be $testFiles.Count
            
            foreach ($result in $results) {
                $result.InputFile | Should -BeIn $testFiles
                $result.Success | Should -Be $true
                
                # Vérifier que le fichier de sortie existe
                Test-Path -Path $result.OutputFile | Should -Be $true
                
                # Vérifier que le fichier de sortie est un JSON valide
                $jsonContent = Get-Content -Path $result.OutputFile -Raw
                { $jsonContent | ConvertFrom-Json } | Should -Not -Throw
            }
        }
    }
    
    Context "Tests de performance" {
        It "Le traitement parallèle est plus rapide que le traitement séquentiel" {
            # Définir le script block de test
            $scriptBlock = {
                param($FilePath)
                
                # Simuler un traitement intensif
                Start-Sleep -Milliseconds 500
                
                # Retourner le chemin du fichier
                return $FilePath
            }
            
            # Mesurer le temps de traitement séquentiel
            $sequentialStart = Get-Date
            foreach ($file in $testFiles) {
                & $scriptBlock $file
            }
            $sequentialEnd = Get-Date
            $sequentialDuration = ($sequentialEnd - $sequentialStart).TotalMilliseconds
            
            # Mesurer le temps de traitement parallèle
            $parallelStart = Get-Date
            $parallelResults = Invoke-ParallelFileProcessing -FilePaths $testFiles -ScriptBlock $scriptBlock -ThrottleLimit 3
            $parallelEnd = Get-Date
            $parallelDuration = ($parallelEnd - $parallelStart).TotalMilliseconds
            
            # Vérifier que le traitement parallèle est plus rapide
            $parallelDuration | Should -BeLessThan $sequentialDuration
            
            # Vérifier que tous les fichiers ont été traités
            $parallelResults.Count | Should -Be $testFiles.Count
        }
    }
    
    AfterAll {
        # Nettoyer les fichiers de test
        if (Test-Path -Path $testTempDir) {
            Remove-Item -Path $testTempDir -Recurse -Force
        }
    }
}
