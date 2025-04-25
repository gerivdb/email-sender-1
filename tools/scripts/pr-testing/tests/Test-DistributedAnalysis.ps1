#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Start-DistributedAnalysis.ps1.

.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement
    du script Start-DistributedAnalysis.ps1.

.EXAMPLE
    .\Test-DistributedAnalysis.ps1

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-30
#>

[CmdletBinding()]
param()

# Importer Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Fonction pour créer un environnement de test
function Initialize-TestEnvironment {
    param(
        [string]$TestDir = "$env:TEMP\DistributedAnalysisTest_$(Get-Random)"
    )

    # Créer le répertoire de test
    if (-not (Test-Path -Path $TestDir)) {
        New-Item -Path $TestDir -ItemType Directory -Force | Out-Null
    }

    # Créer des fichiers de test
    $testFiles = @(
        @{
            Path    = "PowerShell\test1.ps1"
            Content = @"
function Test-Function {
    param([string]`$param1)

    # Erreur: Utilisation d'un alias
    gci -Path "C:\" | Where { `$_.Name -like "*.txt" }

    # Erreur: Utilisation de Invoke-Expression
    Invoke-Expression "Get-Process"
}
"@
        },
        @{
            Path    = "PowerShell\test2.ps1"
            Content = @"
function Test-Function2 {
    param([string]`$param1)

    # Code valide
    Get-ChildItem -Path "C:\" | Where-Object { `$_.Name -like "*.txt" }
}
"@
        },
        @{
            Path    = "Python\test.py"
            Content = @"
def test_function(param1):
    # Erreur: Utilisation de eval()
    result = eval("2 + 2")

    # Erreur: Exception générique
    try:
        x = 1 / 0
    except:
        pass
"@
        }
    )

    foreach ($file in $testFiles) {
        $filePath = Join-Path -Path $TestDir -ChildPath $file.Path
        $directory = Split-Path -Path $filePath -Parent

        if (-not (Test-Path -Path $directory)) {
            New-Item -Path $directory -ItemType Directory -Force | Out-Null
        }

        Set-Content -Path $filePath -Value $file.Content -Encoding UTF8
    }

    # Créer un répertoire pour les modules
    $modulesDir = Join-Path -Path $TestDir -ChildPath "modules"
    New-Item -Path $modulesDir -ItemType Directory -Force | Out-Null

    # Créer des modules de test
    $moduleFiles = @(
        @{
            Path    = "FileContentIndexer.psm1"
            Content = @"
function New-FileContentIndexer {
    param([string]`$IndexPath, [bool]`$PersistIndices)

    return [PSCustomObject]@{
        IndexPath = `$IndexPath
        PersistIndices = `$PersistIndices
    }
}

function New-FileIndex {
    param([PSObject]`$Indexer, [string]`$FilePath)

    return [PSCustomObject]@{
        FilePath = `$FilePath
        IndexedAt = Get-Date
    }
}

Export-ModuleMember -Function New-FileContentIndexer, New-FileIndex
"@
        },
        @{
            Path    = "SyntaxAnalyzer.psm1"
            Content = @"
function New-SyntaxAnalyzer {
    param([bool]`$UseCache, [PSObject]`$Cache)

    return [PSCustomObject]@{
        UseCache = `$UseCache
        Cache = `$Cache
        AnalyzeFile = {
            param([string]`$FilePath)

            # Simuler des problèmes en fonction de l'extension du fichier
            `$extension = [System.IO.Path]::GetExtension(`$FilePath)

            if (`$extension -eq ".ps1") {
                if (`$FilePath -like "*test1.ps1") {
                    return @(
                        [PSCustomObject]@{
                            Line = 5
                            Column = 5
                            Message = "Utilisation d'un alias (gci) au lieu du nom complet (Get-ChildItem)"
                            Severity = "Warning"
                        },
                        [PSCustomObject]@{
                            Line = 8
                            Column = 5
                            Message = "Utilisation de Invoke-Expression peut présenter des risques de sécurité"
                            Severity = "Error"
                        }
                    )
                } else {
                    return @()
                }
            } elseif (`$extension -eq ".py") {
                return @(
                    [PSCustomObject]@{
                        Line = 3
                        Column = 13
                        Message = "Utilisation de eval() peut présenter des risques de sécurité"
                        Severity = "Error"
                    },
                    [PSCustomObject]@{
                        Line = 6
                        Column = 5
                        Message = "Exception générique détectée"
                        Severity = "Warning"
                    }
                )
            } else {
                return @()
            }
        }.GetNewClosure()
    }
}

Export-ModuleMember -Function New-SyntaxAnalyzer
"@
        },
        @{
            Path    = "PRAnalysisCache.psm1"
            Content = @"
function New-PRAnalysisCache {
    param([int]`$MaxMemoryItems)

    return [PSCustomObject]@{
        MaxMemoryItems = `$MaxMemoryItems
        Items = @{}
        Add = {
            param([string]`$Key, [PSObject]`$Value)
            `$this.Items[`$Key] = `$Value
        }.GetNewClosure()
        Get = {
            param([string]`$Key)
            if (`$this.Items.ContainsKey(`$Key)) {
                return `$this.Items[`$Key]
            }
            return `$null
        }.GetNewClosure()
        Remove = {
            param([string]`$Key)
            if (`$this.Items.ContainsKey(`$Key)) {
                `$this.Items.Remove(`$Key)
            }
        }.GetNewClosure()
        Clear = {
            `$this.Items.Clear()
        }.GetNewClosure()
    }
}

Export-ModuleMember -Function New-PRAnalysisCache
"@
        }
    )

    foreach ($file in $moduleFiles) {
        $filePath = Join-Path -Path $modulesDir -ChildPath $file.Path
        Set-Content -Path $filePath -Value $file.Content -Encoding UTF8
    }

    return $TestDir
}

# Fonction pour nettoyer l'environnement de test
function Remove-TestEnvironment {
    param(
        [string]$TestDir
    )

    if (Test-Path -Path $TestDir) {
        Remove-Item -Path $TestDir -Recurse -Force
    }
}

# Définir les tests
Describe "Start-DistributedAnalysis" {
    BeforeAll {
        # Initialiser l'environnement de test
        $script:testDir = Initialize-TestEnvironment

        # Chemin du script à tester
        $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Start-DistributedAnalysis.ps1"

        # Vérifier que le script existe
        if (-not (Test-Path -Path $scriptPath)) {
            throw "Le script Start-DistributedAnalysis.ps1 n'existe pas: $scriptPath"
        }

        # Créer une fonction de test qui exécute le script avec des paramètres spécifiques
        function Invoke-DistributedAnalysisTest {
            param(
                [string]$RepositoryPath,
                [string]$OutputPath,
                [string[]]$ComputerNames,
                [int]$MaxConcurrentJobs,
                [int]$ChunkSize,
                [switch]$UseCache
            )

            # Créer un script block qui exécute le script avec les paramètres spécifiés
            $scriptBlock = {
                param($ScriptPath, $RepositoryPath, $OutputPath, $ComputerNames, $MaxConcurrentJobs, $ChunkSize, $UseCache)

                # Exécuter le script
                & $ScriptPath -RepositoryPath $RepositoryPath -OutputPath $OutputPath -ComputerNames $ComputerNames -MaxConcurrentJobs $MaxConcurrentJobs -ChunkSize $ChunkSize -UseCache:$UseCache
            }

            # Exécuter le script block dans un job pour éviter de polluer l'environnement de test
            $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $scriptPath, $RepositoryPath, $OutputPath, $ComputerNames, $MaxConcurrentJobs, $ChunkSize, $UseCache

            # Attendre que le job soit terminé
            $job | Wait-Job | Out-Null

            # Récupérer les résultats
            $result = $job | Receive-Job

            # Supprimer le job
            $job | Remove-Job

            return $result
        }

        # Créer une fonction pour tester les fonctions individuelles du script
        function Test-ScriptFunction {
            param(
                [string]$FunctionName,
                [hashtable]$Parameters
            )

            # Charger le script dans une session temporaire
            $tempSession = New-PSSession

            try {
                # Copier le script dans la session temporaire
                Copy-Item -Path $scriptPath -Destination "TestScript.ps1" -ToSession $tempSession

                # Créer un script block qui charge le script et exécute la fonction
                $scriptBlock = {
                    param($FunctionName, $Parameters)

                    # Charger le script
                    . .\TestScript.ps1

                    # Exécuter la fonction
                    & $FunctionName @Parameters
                }

                # Exécuter le script block dans la session temporaire
                $result = Invoke-Command -Session $tempSession -ScriptBlock $scriptBlock -ArgumentList $FunctionName, $Parameters

                return $result
            } finally {
                # Supprimer la session temporaire
                Remove-PSSession -Session $tempSession
            }
        }
    }

    AfterAll {
        # Nettoyer l'environnement de test
        Remove-TestEnvironment -TestDir $testDir
    }

    Context "Fonctions individuelles" {
        It "Split-FilesIntoChunks divise correctement les fichiers en lots" {
            # Créer des fichiers de test
            $files = @(
                "$testDir\file1.ps1",
                "$testDir\file2.ps1",
                "$testDir\file3.ps1",
                "$testDir\file4.ps1",
                "$testDir\file5.ps1"
            )

            # Tester la fonction Split-FilesIntoChunks
            $result = Test-ScriptFunction -FunctionName "Split-FilesIntoChunks" -Parameters @{
                FilePaths = $files
                ChunkSize = 2
            }

            # Vérifier les résultats
            $result.Count | Should -Be 3
            $result[0].Count | Should -Be 2
            $result[1].Count | Should -Be 2
            $result[2].Count | Should -Be 1
        }

        It "Merge-AnalysisResults fusionne correctement les résultats" {
            # Créer des résultats de test
            $results = @(
                @(
                    [PSCustomObject]@{
                        FilePath = "$testDir\file1.ps1"
                        Issues   = @(
                            [PSCustomObject]@{
                                Line     = 1
                                Column   = 1
                                Message  = "Issue 1"
                                Severity = "Error"
                            }
                        )
                        Success  = $true
                        Error    = $null
                    },
                    [PSCustomObject]@{
                        FilePath = "$testDir\file2.ps1"
                        Issues   = @(
                            [PSCustomObject]@{
                                Line     = 2
                                Column   = 2
                                Message  = "Issue 2"
                                Severity = "Warning"
                            }
                        )
                        Success  = $true
                        Error    = $null
                    }
                ),
                @(
                    [PSCustomObject]@{
                        FilePath = "$testDir\file1.ps1"
                        Issues   = @(
                            [PSCustomObject]@{
                                Line     = 3
                                Column   = 3
                                Message  = "Issue 3"
                                Severity = "Info"
                            }
                        )
                        Success  = $true
                        Error    = $null
                    },
                    [PSCustomObject]@{
                        FilePath = "$testDir\file3.ps1"
                        Issues   = @(
                            [PSCustomObject]@{
                                Line     = 4
                                Column   = 4
                                Message  = "Issue 4"
                                Severity = "Error"
                            }
                        )
                        Success  = $true
                        Error    = $null
                    }
                )
            )

            # Tester la fonction Merge-AnalysisResults
            $result = Test-ScriptFunction -FunctionName "Merge-AnalysisResults" -Parameters @{
                Results = $results
            }

            # Vérifier les résultats
            $result.Count | Should -Be 3
            $result["$testDir\file1.ps1"].Issues.Count | Should -Be 2
            $result["$testDir\file2.ps1"].Issues.Count | Should -Be 1
            $result["$testDir\file3.ps1"].Issues.Count | Should -Be 1
        }
    }

    Context "Exécution complète" {
        It "Analyse correctement un dépôt" {
            # Exécuter le script avec des paramètres de test
            $outputPath = "$testDir\report.html"
            $result = Invoke-DistributedAnalysisTest -RepositoryPath $testDir -OutputPath $outputPath -ComputerNames "localhost" -MaxConcurrentJobs 2 -ChunkSize 1 -UseCache

            # Vérifier les résultats
            $result | Should -Not -BeNullOrEmpty
            $result.Results | Should -Not -BeNullOrEmpty
            $result.ReportPath | Should -Be $outputPath

            # Vérifier que le rapport a été généré
            Test-Path -Path $outputPath | Should -Be $true

            # Vérifier le contenu du rapport
            $reportContent = Get-Content -Path $outputPath -Raw
            $reportContent | Should -Match "Rapport d'analyse distribuée"
            $reportContent | Should -Match "Nombre de fichiers analysés"
        }

        It "Utilise correctement le cache" {
            # Exécuter le script avec le cache activé
            $outputPath = "$testDir\report_cache.html"
            $result = Invoke-DistributedAnalysisTest -RepositoryPath $testDir -OutputPath $outputPath -ComputerNames "localhost" -MaxConcurrentJobs 2 -ChunkSize 1 -UseCache

            # Vérifier les résultats
            $result | Should -Not -BeNullOrEmpty
            $result.Results | Should -Not -BeNullOrEmpty
            $result.ReportPath | Should -Be $outputPath

            # Vérifier que le rapport a été généré
            Test-Path -Path $outputPath | Should -Be $true
        }

        It "Gère correctement plusieurs ordinateurs" {
            # Exécuter le script avec plusieurs ordinateurs
            $outputPath = "$testDir\report_multi.html"
            $result = Invoke-DistributedAnalysisTest -RepositoryPath $testDir -OutputPath $outputPath -ComputerNames "localhost", "localhost" -MaxConcurrentJobs 2 -ChunkSize 1 -UseCache

            # Vérifier les résultats
            $result | Should -Not -BeNullOrEmpty
            $result.Results | Should -Not -BeNullOrEmpty
            $result.ReportPath | Should -Be $outputPath

            # Vérifier que le rapport a été généré
            Test-Path -Path $outputPath | Should -Be $true
        }
    }
}

# Exécuter les tests
$config = [PesterConfiguration]::Default
$config.Run.Path = $PSCommandPath
$config.Output.Verbosity = "Detailed"
Invoke-Pester -Configuration $config
