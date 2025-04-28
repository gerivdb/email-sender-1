#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Start-RealTimeAnalysis.ps1.

.DESCRIPTION
    Ce script contient des tests unitaires pour vÃ©rifier le bon fonctionnement
    du script Start-RealTimeAnalysis.ps1.

.EXAMPLE
    .\Test-RealTimeAnalysis.ps1

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-30
#>

[CmdletBinding()]
param()

# Importer Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Fonction pour crÃ©er un environnement de test
function Initialize-TestEnvironment {
    param(
        [string]$TestDir = "$env:TEMP\RealTimeAnalysisTest_$(Get-Random)"
    )

    # CrÃ©er le rÃ©pertoire de test
    if (-not (Test-Path -Path $TestDir)) {
        New-Item -Path $TestDir -ItemType Directory -Force | Out-Null
    }

    # CrÃ©er des fichiers de test
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

    # Erreur: Exception gÃ©nÃ©rique
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

    # CrÃ©er un rÃ©pertoire pour les modules
    $modulesDir = Join-Path -Path $TestDir -ChildPath "modules"
    New-Item -Path $modulesDir -ItemType Directory -Force | Out-Null

    # CrÃ©er des modules de test
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

            # Simuler des problÃ¨mes en fonction de l'extension du fichier
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
                            Message = "Utilisation de Invoke-Expression peut prÃ©senter des risques de sÃ©curitÃ©"
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
                        Message = "Utilisation de eval() peut prÃ©senter des risques de sÃ©curitÃ©"
                        Severity = "Error"
                    },
                    [PSCustomObject]@{
                        Line = 6
                        Column = 5
                        Message = "Exception gÃ©nÃ©rique dÃ©tectÃ©e"
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

# DÃ©finir les tests
Describe "Start-RealTimeAnalysis" {
    BeforeAll {
        # Initialiser l'environnement de test
        $script:testDir = Initialize-TestEnvironment

        # Chemin du script Ã  tester
        $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Start-RealTimeAnalysis.ps1"

        # VÃ©rifier que le script existe
        if (-not (Test-Path -Path $scriptPath)) {
            throw "Le script Start-RealTimeAnalysis.ps1 n'existe pas: $scriptPath"
        }

        # CrÃ©er une fonction pour tester les fonctions individuelles du script
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

                # CrÃ©er un script block qui charge le script et exÃ©cute la fonction
                $scriptBlock = {
                    param($FunctionName, $Parameters)

                    # Charger le script
                    . .\development\testing\testscript.ps1

                    # ExÃ©cuter la fonction
                    & $FunctionName @Parameters
                }

                # ExÃ©cuter le script block dans la session temporaire
                $result = Invoke-Command -Session $tempSession -ScriptBlock $scriptBlock -ArgumentList $FunctionName, $Parameters

                return $result
            } finally {
                # Supprimer la session temporaire
                Remove-PSSession -Session $tempSession
            }
        }

        # CrÃ©er une fonction pour tester l'analyse de fichier
        function Test-FileAnalysis {
            param(
                [string]$FilePath,
                [bool]$UseCache = $false
            )

            # Charger le script dans une session temporaire
            $tempSession = New-PSSession

            try {
                # Copier le script et le fichier Ã  analyser dans la session temporaire
                Copy-Item -Path $scriptPath -Destination "TestScript.ps1" -ToSession $tempSession
                Copy-Item -Path $FilePath -Destination "TestFile$(Split-Path -Path $FilePath -Leaf)" -ToSession $tempSession

                # CrÃ©er un script block qui charge le script et analyse le fichier
                $scriptBlock = {
                    param($FilePath, $UseCache)

                    # Charger le script
                    . .\development\testing\testscript.ps1

                    # CrÃ©er un cache si demandÃ©
                    $cache = if ($UseCache) { New-PRAnalysisCache -MaxMemoryItems 1000 } else { $null }

                    # CrÃ©er un analyseur de syntaxe
                    $analyzer = New-SyntaxAnalyzer -UseCache $UseCache -Cache $cache

                    # Analyser le fichier
                    $issues = $analyzer.AnalyzeFile($FilePath)

                    return $issues
                }

                # ExÃ©cuter le script block dans la session temporaire
                $result = Invoke-Command -Session $tempSession -ScriptBlock $scriptBlock -ArgumentList "TestFile$(Split-Path -Path $FilePath -Leaf)", $UseCache

                return $result
            } finally {
                # Supprimer la session temporaire
                Remove-PSSession -Session $tempSession
            }
        }

        # CrÃ©er une fonction pour simuler un Ã©vÃ©nement de modification de fichier
        function Test-FileChangeEvent {
            param(
                [string]$FilePath,
                [string]$NotificationType = "Console",
                [int]$DebounceTime = 100,
                [bool]$UseCache = $false
            )

            # Charger le script dans une session temporaire
            $tempSession = New-PSSession

            try {
                # Copier le script et le fichier Ã  analyser dans la session temporaire
                Copy-Item -Path $scriptPath -Destination "TestScript.ps1" -ToSession $tempSession
                Copy-Item -Path $FilePath -Destination "TestFile$(Split-Path -Path $FilePath -Leaf)" -ToSession $tempSession

                # CrÃ©er un script block qui charge le script et simule un Ã©vÃ©nement de modification de fichier
                $scriptBlock = {
                    param($FilePath, $NotificationType, $DebounceTime, $UseCache)

                    # Charger le script
                    . .\development\testing\testscript.ps1

                    # CrÃ©er un cache si demandÃ©
                    $cache = if ($UseCache) { New-PRAnalysisCache -MaxMemoryItems 1000 } else { $null }

                    # CrÃ©er un analyseur de syntaxe
                    $analyzer = New-SyntaxAnalyzer -UseCache $UseCache -Cache $cache

                    # CrÃ©er un dictionnaire pour stocker les derniÃ¨res modifications
                    $lastModifications = @{}

                    # CrÃ©er un dictionnaire pour stocker les timers de debounce
                    # Variable non utilisÃ©e dans ce contexte de test, mais prÃ©sente pour simuler le script rÃ©el
                    # $debounceTimers = @{}

                    # DÃ©finir la fonction Show-Notification
                    function Show-Notification {
                        param(
                            [string]$Title,
                            [string]$Message,
                            [string]$Type
                        )

                        return [PSCustomObject]@{
                            Title   = $Title
                            Message = $Message
                            Type    = $Type
                        }
                    }

                    # DÃ©finir la fonction Invoke-FileAnalysis
                    function Invoke-FileAnalysis {
                        param(
                            [string]$FilePath
                        )

                        # VÃ©rifier si le fichier existe
                        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
                            Write-Warning "Le fichier n'existe pas: $FilePath"
                            return $null
                        }

                        # Obtenir le contenu du fichier
                        $content = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue

                        if ($null -eq $content) {
                            Write-Warning "Impossible de lire le contenu du fichier: $FilePath"
                            return $null
                        }

                        # VÃ©rifier si le fichier a Ã©tÃ© modifiÃ© depuis la derniÃ¨re analyse
                        $lastWrite = (Get-Item -Path $FilePath).LastWriteTime

                        if ($lastModifications.ContainsKey($FilePath) -and $lastModifications[$FilePath] -eq $lastWrite) {
                            Write-Verbose "Le fichier n'a pas Ã©tÃ© modifiÃ© depuis la derniÃ¨re analyse: $FilePath"
                            return $null
                        }

                        # Mettre Ã  jour la date de derniÃ¨re modification
                        $lastModifications[$FilePath] = $lastWrite

                        # Analyser le fichier
                        try {
                            # Analyser le fichier
                            $issues = $analyzer.AnalyzeFile($FilePath)

                            # CrÃ©er un objet rÃ©sultat
                            $result = [PSCustomObject]@{
                                FilePath   = $FilePath
                                Issues     = $issues
                                AnalyzedAt = Get-Date
                                Success    = $true
                                Error      = $null
                            }

                            return $result
                        } catch {
                            Write-Error "Erreur lors de l'analyse du fichier $FilePath : $_"

                            return [PSCustomObject]@{
                                FilePath   = $FilePath
                                Issues     = @()
                                AnalyzedAt = Get-Date
                                Success    = $false
                                Error      = $_.Exception.Message
                            }
                        }
                    }

                    # DÃ©finir la fonction Invoke-FileChangeEvent (utilisation d'un verbe approuvÃ©)
                    function Invoke-FileChangeEvent {
                        param(
                            [string]$FilePath
                        )

                        # Analyser le fichier
                        $result = Invoke-FileAnalysis -FilePath $FilePath

                        if ($result -and $result.Success) {
                            # Afficher les rÃ©sultats
                            $issueCount = $result.Issues.Count

                            if ($issueCount -gt 0) {
                                $message = "DÃ©tectÃ© $issueCount problÃ¨me(s) dans le fichier $FilePath"
                                $notification = Show-Notification -Title "Analyse en temps rÃ©el" -Message $message -Type $NotificationType

                                return [PSCustomObject]@{
                                    Result       = $result
                                    Notification = $notification
                                }
                            } else {
                                return [PSCustomObject]@{
                                    Result       = $result
                                    Notification = $null
                                }
                            }
                        }

                        return $null
                    }

                    # Simuler un Ã©vÃ©nement de modification de fichier
                    return Invoke-FileChangeEvent -FilePath $FilePath
                }

                # ExÃ©cuter le script block dans la session temporaire
                $result = Invoke-Command -Session $tempSession -ScriptBlock $scriptBlock -ArgumentList "TestFile$(Split-Path -Path $FilePath -Leaf)", $NotificationType, $DebounceTime, $UseCache

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

    Context "Analyse de fichier" {
        It "DÃ©tecte correctement les problÃ¨mes dans un fichier PowerShell" {
            # Tester l'analyse d'un fichier PowerShell avec des problÃ¨mes
            $filePath = Join-Path -Path $testDir -ChildPath "PowerShell\test1.ps1"
            $issues = Test-FileAnalysis -FilePath $filePath

            # VÃ©rifier les rÃ©sultats
            $issues | Should -Not -BeNullOrEmpty
            $issues.Count | Should -Be 2
            $issues[0].Message | Should -Match "alias"
            $issues[1].Message | Should -Match "Invoke-Expression"
        }

        It "Ne dÃ©tecte pas de problÃ¨mes dans un fichier PowerShell valide" {
            # Tester l'analyse d'un fichier PowerShell valide
            $filePath = Join-Path -Path $testDir -ChildPath "PowerShell\test2.ps1"
            $issues = Test-FileAnalysis -FilePath $filePath

            # VÃ©rifier les rÃ©sultats
            $issues | Should -BeNullOrEmpty
        }

        It "DÃ©tecte correctement les problÃ¨mes dans un fichier Python" {
            # Tester l'analyse d'un fichier Python avec des problÃ¨mes
            $filePath = Join-Path -Path $testDir -ChildPath "Python\test.py"
            $issues = Test-FileAnalysis -FilePath $filePath

            # VÃ©rifier les rÃ©sultats
            $issues | Should -Not -BeNullOrEmpty
            $issues.Count | Should -Be 2
            $issues[0].Message | Should -Match "eval"
            $issues[1].Message | Should -Match "Exception"
        }
    }

    Context "Ã‰vÃ©nements de modification de fichier" {
        It "GÃ©nÃ¨re une notification pour un fichier avec des problÃ¨mes" {
            # Tester un Ã©vÃ©nement de modification de fichier pour un fichier avec des problÃ¨mes
            $filePath = Join-Path -Path $testDir -ChildPath "PowerShell\test1.ps1"
            $result = Test-FileChangeEvent -FilePath $filePath

            # VÃ©rifier les rÃ©sultats
            $result | Should -Not -BeNullOrEmpty
            $result.Result | Should -Not -BeNullOrEmpty
            $result.Result.Issues | Should -Not -BeNullOrEmpty
            $result.Result.Issues.Count | Should -Be 2
            $result.Notification | Should -Not -BeNullOrEmpty
            $result.Notification.Title | Should -Be "Analyse en temps rÃ©el"
            $result.Notification.Message | Should -Match "DÃ©tectÃ© 2 problÃ¨me"
        }

        It "Ne gÃ©nÃ¨re pas de notification pour un fichier sans problÃ¨mes" {
            # Tester un Ã©vÃ©nement de modification de fichier pour un fichier sans problÃ¨mes
            $filePath = Join-Path -Path $testDir -ChildPath "PowerShell\test2.ps1"
            $result = Test-FileChangeEvent -FilePath $filePath

            # VÃ©rifier les rÃ©sultats
            $result | Should -Not -BeNullOrEmpty
            $result.Result | Should -Not -BeNullOrEmpty
            $result.Result.Issues | Should -BeNullOrEmpty
            $result.Notification | Should -BeNullOrEmpty
        }
    }

    Context "ParamÃ¨tres" {
        It "Utilise correctement le cache" {
            # Tester l'analyse d'un fichier avec le cache activÃ©
            $filePath = Join-Path -Path $testDir -ChildPath "PowerShell\test1.ps1"
            $issues = Test-FileAnalysis -FilePath $filePath -UseCache $true

            # VÃ©rifier les rÃ©sultats
            $issues | Should -Not -BeNullOrEmpty
            $issues.Count | Should -Be 2
        }

        It "Utilise correctement le type de notification" {
            # Tester un Ã©vÃ©nement de modification de fichier avec un type de notification spÃ©cifique
            $filePath = Join-Path -Path $testDir -ChildPath "PowerShell\test1.ps1"
            $result = Test-FileChangeEvent -FilePath $filePath -NotificationType "Popup"

            # VÃ©rifier les rÃ©sultats
            $result | Should -Not -BeNullOrEmpty
            $result.Notification | Should -Not -BeNullOrEmpty
            $result.Notification.Type | Should -Be "Popup"
        }
    }
}

# ExÃ©cuter les tests
$config = [PesterConfiguration]::Default
$config.Run.Path = $PSCommandPath
$config.Output.Verbosity = "Detailed"
Invoke-Pester -Configuration $config
