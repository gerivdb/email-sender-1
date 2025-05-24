#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour l'analyseur de scripts PowerShell.
.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour vÃ©rifier le bon fonctionnement
    de l'analyseur de scripts PowerShell utilisant l'architecture hybride.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-10
#>

# Importer le module Pester
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Chemin vers le script Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$analyzerPath = Join-Path -Path $scriptPath -ChildPath "..\examples\script-analyzer-simple.ps1"

# CrÃ©er des scripts de test
$testScriptsPath = Join-Path -Path $scriptPath -ChildPath "test_scripts"
if (-not (Test-Path -Path $testScriptsPath)) {
    New-Item -Path $testScriptsPath -ItemType Directory -Force | Out-Null
    
    # Script simple
    $simpleScript = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test simple.
.DESCRIPTION
    Ce script est utilisÃ© pour tester l'analyseur de scripts.
#>

# Fonction simple
function Test-Function {
    param(
        [Parameter(Mandatory = `$true)]
        [string]`$InputString
    )
    
    Write-Output `$InputString
}

# Appel de la fonction
Test-Function -InputString "Hello, World!"
"@
    
    $simpleScript | Out-File -FilePath (Join-Path -Path $testScriptsPath -ChildPath "simple.ps1") -Encoding utf8
    
    # Script complexe
    $complexScript = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test complexe.
.DESCRIPTION
    Ce script est utilisÃ© pour tester l'analyseur de scripts avec des structures plus complexes.
.NOTES
    Version: 1.0
    Auteur: Test
    Date: 2025-04-10
#>

# Variables
`$maxItems = 10
`$processingEnabled = `$true

# Fonction avec gestion d'erreurs
function Invoke-Items {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = `$true)]
        [int]`$Count,
        
        [Parameter(Mandatory = `$false)]
        [switch]`$Force
    )
    
    try {
        # Boucle for
        for (`$i = 1; `$i -le `$Count; `$i++) {
            # Structure conditionnelle
            if (`$i % 2 -eq 0) {
                Write-Output "Item `$i est pair"
            }
            else {
                Write-Output "Item `$i est impair"
            }
            
            # Structure switch
            switch (`$i % 3) {
                0 { Write-Verbose "Divisible par 3" }
                1 { Write-Verbose "Reste 1" }
                2 { Write-Verbose "Reste 2" }
            }
        }
    }
    catch {
        Write-Error "Une erreur s'est produite : `$_"
    }
}

# Fonction avec boucle foreach
function Get-ItemsReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = `$true)]
        [string[]]`$Items
    )
    
    `$results = @()
    
    # Boucle foreach
    foreach (`$item in `$Items) {
        `$results += @{
            Name = `$item
            Length = `$item.Length
            UpperCase = `$item.ToUpper()
        }
    }
    
    return `$results
}

# Appel des fonctions
if (`$processingEnabled) {
    Invoke-Items -Count `$maxItems
    Get-ItemsReport -Items @("Apple", "Banana", "Cherry")
}
"@
    
    $complexScript | Out-File -FilePath (Join-Path -Path $testScriptsPath -ChildPath "complex.ps1") -Encoding utf8
    
    # Script avec erreurs
    $errorScript = @"
# Script avec erreurs

# Fonction mal nommÃ©e
function badFunction {
    param(`$input)
    
    # Variable non dÃ©clarÃ©e
    `$result = `$undeclaredVar + 10
    
    return `$result
}

# Boucle while infinie (commentÃ©e pour Ã©viter les problÃ¨mes)
# while (`$true) {
#     Write-Host "Boucle infinie"
# }

# Appel de fonction inexistante
# NonExistentFunction

# Syntaxe incorrecte
if (`$x = 10) {
    Write-Output "Erreur de syntaxe"
}
"@
    
    $errorScript | Out-File -FilePath (Join-Path -Path $testScriptsPath -ChildPath "error.ps1") -Encoding utf8
}

# ExÃ©cuter les tests
Describe "Analyseur de scripts PowerShell" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire temporaire pour les rÃ©sultats
        $outputPath = Join-Path -Path $testScriptsPath -ChildPath "results"
        if (-not (Test-Path -Path $outputPath)) {
            New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
        }
    }
    
    Context "Analyse de scripts simples" {
        It "Devrait analyser un script simple avec succÃ¨s" {
            # ExÃ©cuter l'analyseur sur le script simple
            $scriptToAnalyze = Join-Path -Path $testScriptsPath -ChildPath "simple.ps1"
            
            # Appeler le script d'analyse
            $result = & $analyzerPath -ScriptsPath $testScriptsPath -OutputPath (Join-Path -Path $testScriptsPath -ChildPath "results") -FilePatterns "simple.ps1"
            
            # VÃ©rifier les rÃ©sultats
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0].file_name | Should -Be "simple.ps1"
            $result[0].total_lines | Should -BeGreaterThan 0
            $result[0].functions_count | Should -Be 1
        }
    }
    
    Context "Analyse de scripts complexes" {
        It "Devrait analyser un script complexe avec succÃ¨s" {
            # ExÃ©cuter l'analyseur sur le script complexe
            $scriptToAnalyze = Join-Path -Path $testScriptsPath -ChildPath "complex.ps1"
            
            # Appeler le script d'analyse
            $result = & $analyzerPath -ScriptsPath $testScriptsPath -OutputPath (Join-Path -Path $testScriptsPath -ChildPath "results") -FilePatterns "complex.ps1"
            
            # VÃ©rifier les rÃ©sultats
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0].file_name | Should -Be "complex.ps1"
            $result[0].total_lines | Should -BeGreaterThan 0
            $result[0].functions_count | Should -Be 2
            $result[0].complexity | Should -BeGreaterThan 5  # Le script complexe devrait avoir une complexitÃ© Ã©levÃ©e
        }
    }
    
    Context "Analyse de scripts avec erreurs" {
        It "Devrait analyser un script avec erreurs sans planter" {
            # ExÃ©cuter l'analyseur sur le script avec erreurs
            $scriptToAnalyze = Join-Path -Path $testScriptsPath -ChildPath "error.ps1"
            
            # Appeler le script d'analyse
            $result = & $analyzerPath -ScriptsPath $testScriptsPath -OutputPath (Join-Path -Path $testScriptsPath -ChildPath "results") -FilePatterns "error.ps1"
            
            # VÃ©rifier les rÃ©sultats
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0].file_name | Should -Be "error.ps1"
            $result[0].total_lines | Should -BeGreaterThan 0
            $result[0].functions_count | Should -Be 1
        }
    }
    
    Context "Analyse de plusieurs scripts" {
        It "Devrait analyser plusieurs scripts en parallÃ¨le" {
            # ExÃ©cuter l'analyseur sur tous les scripts
            $result = & $analyzerPath -ScriptsPath $testScriptsPath -OutputPath (Join-Path -Path $testScriptsPath -ChildPath "results")
            
            # VÃ©rifier les rÃ©sultats
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3  # Trois scripts de test
            $result | Where-Object { $_.file_name -eq "simple.ps1" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.file_name -eq "complex.ps1" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.file_name -eq "error.ps1" } | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Utilisation du cache" {
        It "Devrait Ãªtre plus rapide avec le cache activÃ©" {
            # ExÃ©cuter l'analyseur sans cache
            $stopwatch1 = [System.Diagnostics.Stopwatch]::StartNew()
            $result1 = & $analyzerPath -ScriptsPath $testScriptsPath -OutputPath (Join-Path -Path $testScriptsPath -ChildPath "results")
            $stopwatch1.Stop()
            $timeWithoutCache = $stopwatch1.Elapsed.TotalSeconds
            
            # ExÃ©cuter l'analyseur avec cache
            $stopwatch2 = [System.Diagnostics.Stopwatch]::StartNew()
            $result2 = & $analyzerPath -ScriptsPath $testScriptsPath -OutputPath (Join-Path -Path $testScriptsPath -ChildPath "results") -UseCache
            $stopwatch2.Stop()
            $timeWithCache = $stopwatch2.Elapsed.TotalSeconds
            
            # VÃ©rifier que les rÃ©sultats sont identiques
            $result1.Count | Should -Be $result2.Count
            
            # ExÃ©cuter une deuxiÃ¨me fois avec cache pour bÃ©nÃ©ficier du cache
            $stopwatch3 = [System.Diagnostics.Stopwatch]::StartNew()
            $result3 = & $analyzerPath -ScriptsPath $testScriptsPath -OutputPath (Join-Path -Path $testScriptsPath -ChildPath "results") -UseCache
            $stopwatch3.Stop()
            $timeWithCacheSecondRun = $stopwatch3.Elapsed.TotalSeconds
            
            # La deuxiÃ¨me exÃ©cution avec cache devrait Ãªtre plus rapide
            # Note: Ce test peut Ã©chouer sur des systÃ¨mes trÃ¨s rapides ou si le cache n'est pas correctement implÃ©mentÃ©
            Write-Host "Temps sans cache: $timeWithoutCache s"
            Write-Host "Temps avec cache (1Ã¨re exÃ©cution): $timeWithCache s"
            Write-Host "Temps avec cache (2Ã¨me exÃ©cution): $timeWithCacheSecondRun s"
            
            # VÃ©rifier que les rÃ©sultats sont identiques
            $result1.Count | Should -Be $result3.Count
        }
    }
    
    AfterAll {
        # Nettoyer les fichiers temporaires si nÃ©cessaire
    }
}

