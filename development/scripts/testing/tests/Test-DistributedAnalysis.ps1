#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Start-DistributedAnalysis.ps1.

.DESCRIPTION
    Ce script contient des tests unitaires pour vÃƒÂ©rifier le bon fonctionnement
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
    Write-Warning "Le module Pester n'est pas installÃƒÂ©. Installation..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Fonction pour crÃƒÂ©er un environnement de test
function Initialize-TestEnvironment {
    param(
        [string]$TestDir = "$env:TEMP\DistributedAnalysisTest_$(Get-Random)"
    )

    # CrÃƒÂ©er le rÃƒÂ©pertoire de test
    if (-not (Test-Path -Path $TestDir)) {
        New-Item -Path $TestDir -ItemType Directory -Force | Out-Null
    }

    # CrÃƒÂ©er des fichiers de test
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

    # Erreur: Exception gÃƒÂ©nÃƒÂ©rique
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

    # CrÃƒÂ©er un rÃƒÂ©pertoire pour les modules
    $modulesDir = Join-Path -Path $TestDir -ChildPath "modules"
    New-Item -Path $modulesDir -ItemType Directory -Force | Out-Null

    # CrÃƒÂ©er des modules de test
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

            # Simuler des problÃƒÂ¨mes en fonction de l'extension du fichier
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
                            Message = "Utilisation de Invoke-Expression peut prÃƒÂ©senter des risques de sÃƒÂ©curitÃƒÂ©"
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
                        Message = "Utilisation de eval() peut prÃƒÂ©senter des risques de sÃƒÂ©curitÃƒÂ©"
                        Severity = "Error"
                    },
                    [PSCustomObject]@{
                        Line = 6
                        Column = 5
                        Message = "Exception gÃƒÂ©nÃƒÂ©rique dÃƒÂ©tectÃƒÂ©e"
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

# DÃƒÂ©finir les tests
Describe "Start-DistributedAnalysis" {
    BeforeAll {
        # Initialiser l'environnement de test
        $script:testDir = Initialize-TestEnvironment

        # Chemin du script ÃƒÂ  tester
        $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Start-DistributedAnalysis.ps1"

        # VÃƒÂ©rifier que le script existe
        if (-not (Test-Path -Path $scriptPath)) {
            throw "Le script Start-DistributedAnalysis.ps1 n'existe pas: $scriptPath"
        }

        # CrÃƒÂ©er une fonction de test qui exÃƒÂ©cute le script avec des paramÃƒÂ¨tres spÃƒÂ©cifiques
        function Invoke-DistributedAnalysisTest {
            param(
                [string]$RepositoryPath,
                [string]$OutputPath,
                [string[]]$ComputerNames,
                [int]$MaxConcurrentJobs,
                [int]$ChunkSize,
                [switch]$UseCache
            )

            # CrÃƒÂ©er un script block qui exÃƒÂ©cute le script avec les paramÃƒÂ¨tres spÃƒÂ©cifiÃƒÂ©s
            $scriptBlock = {
                param($ScriptPath, $RepositoryPath, $OutputPath, $ComputerNames, $MaxConcurrentJobs, $ChunkSize, $UseCache)

                # ExÃƒÂ©cuter le script
                & $ScriptPath -RepositoryPath $RepositoryPath -OutputPath $OutputPath -ComputerNames $ComputerNames -MaxConcurrentJobs $MaxConcurrentJobs -ChunkSize $ChunkSize -UseCache:$UseCache
            }

            # ExÃƒÂ©cuter le script block dans un job pour ÃƒÂ©viter de polluer l'environnement de test
            $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $scriptPath, $RepositoryPath, $OutputPath, $ComputerNames, $MaxConcurrentJobs, $ChunkSize, $UseCache

            # Attendre que le job soit terminÃƒÂ©
            $job | Wait-Job | Out-Null

            # RÃƒÂ©cupÃƒÂ©rer les rÃƒÂ©sultats
            $result = $job | Receive-Job

            # Supprimer le job
            $job | Remove-Job

            return $result
        }

        # CrÃƒÂ©er une fonction pour tester les fonctions individuelles du script
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

                # CrÃƒÂ©er un script block qui charge le script et exÃƒÂ©cute la fonction
                $scriptBlock = {
                    param($FunctionName, $Parameters)

                    # Charger le script
                    . .\development\testing\testscript.ps1

                    # ExÃƒÂ©cuter la fonction
                    & $FunctionName @Parameters
                }

                # ExÃƒÂ©cuter le script block dans la session temporaire
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
            # CrÃƒÂ©er des fichiers de test
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

            # VÃƒÂ©rifier les rÃƒÂ©sultats
            $result.Count | Should -Be 3
            $result[0].Count | Should -Be 2
            $result[1].Count | Should -Be 2
            $result[2].Count | Should -Be 1
        }

        It "Merge-AnalysisResults fusionne correctement les rÃƒÂ©sultats" {
            # CrÃƒÂ©er des rÃƒÂ©sultats de test
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

            # VÃƒÂ©rifier les rÃƒÂ©sultats
            $result.Count | Should -Be 3
            $result["$testDir\file1.ps1"].Issues.Count | Should -Be 2
            $result["$testDir\file2.ps1"].Issues.Count | Should -Be 1
            $result["$testDir\file3.ps1"].Issues.Count | Should -Be 1
        }
    }

    Context "ExÃƒÂ©cution complÃƒÂ¨te" {
        It "Analyse correctement un dÃƒÂ©pÃƒÂ´t" {
            # ExÃƒÂ©cuter le script avec des paramÃƒÂ¨tres de test
            $outputPath = "$testDir\report.html"
            $result = Invoke-DistributedAnalysisTest -RepositoryPath $testDir -OutputPath $outputPath -ComputerNames "localhost" -MaxConcurrentJobs 2 -ChunkSize 1 -UseCache

            # VÃƒÂ©rifier les rÃƒÂ©sultats
            $result | Should -Not -BeNullOrEmpty
            $result.Results | Should -Not -BeNullOrEmpty
            $result.ReportPath | Should -Be $outputPath

            # VÃƒÂ©rifier que le rapport a ÃƒÂ©tÃƒÂ© gÃƒÂ©nÃƒÂ©rÃƒÂ©
            Test-Path -Path $outputPath | Should -Be $true

            # VÃƒÂ©rifier le contenu du rapport
            $reportContent = Get-Content -Path $outputPath -Raw
            $reportContent | Should -Match "Rapport d'analyse distribuÃƒÂ©e"
            $reportContent | Should -Match "Nombre de fichiers analysÃƒÂ©s"
        }

        It "Utilise correctement le cache" {
            # ExÃƒÂ©cuter le script avec le cache activÃƒÂ©
            $outputPath = "$testDir\report_cache.html"
            $result = Invoke-DistributedAnalysisTest -RepositoryPath $testDir -OutputPath $outputPath -ComputerNames "localhost" -MaxConcurrentJobs 2 -ChunkSize 1 -UseCache

            # VÃƒÂ©rifier les rÃƒÂ©sultats
            $result | Should -Not -BeNullOrEmpty
            $result.Results | Should -Not -BeNullOrEmpty
            $result.ReportPath | Should -Be $outputPath

            # VÃƒÂ©rifier que le rapport a ÃƒÂ©tÃƒÂ© gÃƒÂ©nÃƒÂ©rÃƒÂ©
            Test-Path -Path $outputPath | Should -Be $true
        }

        It "GÃƒÂ¨re correctement plusieurs ordinateurs" {
            # ExÃƒÂ©cuter le script avec plusieurs ordinateurs
            $outputPath = "$testDir\report_multi.html"
            $result = Invoke-DistributedAnalysisTest -RepositoryPath $testDir -OutputPath $outputPath -ComputerNames "localhost", "localhost" -MaxConcurrentJobs 2 -ChunkSize 1 -UseCache

            # VÃƒÂ©rifier les rÃƒÂ©sultats
            $result | Should -Not -BeNullOrEmpty
            $result.Results | Should -Not -BeNullOrEmpty
            $result.ReportPath | Should -Be $outputPath

            # VÃƒÂ©rifier que le rapport a ÃƒÂ©tÃƒÂ© gÃƒÂ©nÃƒÂ©rÃƒÂ©
            Test-Path -Path $outputPath | Should -Be $true
        }
    }
}

# ExÃƒÂ©cuter les tests
$config = [PesterConfiguration]::Default
$config.Run.Path = $PSCommandPath
$config.Output.Verbosity = "Detailed"
Invoke-Pester -Configuration $config
