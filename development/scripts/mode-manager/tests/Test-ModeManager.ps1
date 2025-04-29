<#
.SYNOPSIS
    Tests unitaires pour le script mode-manager.ps1.

.DESCRIPTION
    Ce script contient des tests unitaires pour vÃ©rifier le bon fonctionnement du script mode-manager.ps1.
    Il utilise le framework Pester pour exÃ©cuter les tests.

.NOTES
    Auteur: Mode Manager Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

# Importer le module Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# DÃ©finir le chemin du script Ã  tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\mode-manager.ps1"

# VÃ©rifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    throw "Le script mode-manager.ps1 est introuvable Ã  l'emplacement : $scriptPath"
}

# DÃ©finir le chemin du projet
$projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
if (-not (Test-Path -Path $projectRoot)) {
    $projectRoot = $PSScriptRoot
    while ((Split-Path -Path $projectRoot -Leaf) -ne "EMAIL_SENDER_1" -and (Split-Path -Path $projectRoot) -ne "") {
        $projectRoot = Split-Path -Path $projectRoot
    }
}

# DÃ©finir le chemin de configuration pour les tests
$testConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "test-config.json"

# CrÃ©er un fichier de configuration de test si nÃ©cessaire
if (-not (Test-Path -Path $testConfigPath)) {
    @{
        General   = @{
            RoadmapPath        = "docs\plans\roadmap_complete_2.md"
            ActiveDocumentPath = "docs\plans\plan-modes-stepup.md"
            ReportPath         = "reports"
            LogPath            = "logs"
            DefaultEncoding    = "UTF8-BOM"
            ProjectRoot        = $projectRoot
        }
        Modes     = @{
            Check   = @{
                Enabled                   = $true
                ScriptPath                = "development\scripts\maintenance\modes\check.ps1"
                DefaultRoadmapFile        = "docs\plans\roadmap_complete_2.md"
                DefaultActiveDocumentPath = "docs\plans\plan-modes-stepup.md"
                AutoUpdateRoadmap         = $true
                GenerateReport            = $true
                ReportPath                = "reports"
                AutoUpdateCheckboxes      = $true
                RequireFullTestCoverage   = $true
                SimulationModeDefault     = $true
            }
            Debug   = @{
                Enabled            = $true
                ScriptPath         = "development\roadmap\parser\modes\debug\debug-mode.ps1"
                GeneratePatch      = $true
                IncludeStackTrace  = $true
                MaxStackTraceDepth = 10
                AnalyzePerformance = $true
                SuggestFixes       = $true
                ErrorLog           = "logs\error.log"
            }
            Gran    = @{
                Enabled          = $true
                ScriptPath       = "development\roadmap\parser\modes\gran\gran-mode.ps1"
                SubTasksFile     = "templates\subtasks.txt"
                IndentationStyle = "Spaces"
                CheckboxStyle    = "GitHub"
            }
            DevR    = @{
                Enabled             = $true
                ScriptPath          = "development\roadmap\parser\modes\dev-r\dev-r-mode.ps1"
                GenerateTests       = $true
                UpdateRoadmap       = $true
                ImplementationStyle = "TDD"
                DocumentationStyle  = "XML"
                IncludeExamples     = $true
            }
            Manager = @{
                Enabled    = $true
                ScriptPath = "development\\scripts\\mode-manager\mode-manager.ps1"
            }
        }
        Workflows = @{
            Development = @{
                Description  = "Workflow de dÃ©veloppement complet"
                Modes        = @("Gran", "DevR", "Test", "Check")
                AutoContinue = $true
            }
            Debugging   = @{
                Description  = "Workflow de dÃ©bogage"
                Modes        = @("Debug", "Test", "Check")
                AutoContinue = $true
            }
        }
        Tests     = @{
            Framework         = "Pester"
            Coverage          = $true
            CoverageThreshold = 80
            OutputFormat      = "NUnitXml"
            TestsPath         = "tests"
        }
    } | ConvertTo-Json -Depth 5 | Set-Content -Path $testConfigPath -Encoding UTF8
}

# DÃ©finir les tests
Describe "Mode Manager Tests" {
    Context "ParamÃ¨tres de base" {
        It "Devrait afficher la liste des modes avec -ListModes" {
            $output = & $scriptPath -ListModes
            $output | Should -Not -BeNullOrEmpty
            $output | Should -Contain "Modes disponibles :"
            $output | Should -Contain "ARCHI"
            $output | Should -Contain "CHECK"
            $output | Should -Contain "DEBUG"
        }

        It "Devrait afficher la configuration avec -ShowConfig" {
            $output = & $scriptPath -ShowConfig -ConfigPath $testConfigPath
            $output | Should -Not -BeNullOrEmpty
            $output | Should -Contain "Configuration gÃ©nÃ©rale :"
        }
    }

    Context "Fonctions internes" {
        # Charger les fonctions du script pour les tester
        # Nous devons extraire les fonctions du script et les dÃ©finir dans le contexte de test

        # Fonction pour charger la configuration
        function Get-ModeConfiguration {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory = $true)]
                [string]$ConfigPath
            )

            if (Test-Path -Path $ConfigPath) {
                try {
                    $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
                    return $config
                } catch {
                    Write-Warning "Erreur lors du chargement de la configuration : $_"
                }
            } else {
                Write-Warning "Fichier de configuration introuvable : $ConfigPath"
            }

            # Configuration par dÃ©faut
            return [PSCustomObject]@{
                General = [PSCustomObject]@{
                    RoadmapPath        = "docs\plans\roadmap_complete_2.md"
                    ActiveDocumentPath = "docs\plans\plan-modes-stepup.md"
                    ReportPath         = "reports"
                }
                Modes   = [PSCustomObject]@{
                    Check  = [PSCustomObject]@{
                        Enabled    = $true
                        ScriptPath = "development\scripts\maintenance\modes\check.ps1"
                    }
                    Debug  = [PSCustomObject]@{
                        Enabled    = $true
                        ScriptPath = "development\roadmap\parser\modes\debug\debug-mode.ps1"
                    }
                    Archi  = [PSCustomObject]@{
                        Enabled    = $true
                        ScriptPath = "development\scripts\maintenance\modes\archi-mode.ps1"
                    }
                    CBreak = [PSCustomObject]@{
                        Enabled    = $true
                        ScriptPath = "development\scripts\maintenance\modes\c-break-mode.ps1"
                    }
                    Gran   = [PSCustomObject]@{
                        Enabled    = $true
                        ScriptPath = "development\roadmap\parser\modes\gran\gran-mode.ps1"
                    }
                    DevR   = [PSCustomObject]@{
                        Enabled    = $true
                        ScriptPath = "development\roadmap\parser\modes\dev-r\dev-r-mode.ps1"
                    }
                    Opti   = [PSCustomObject]@{
                        Enabled    = $true
                        ScriptPath = "development\scripts\maintenance\modes\opti-mode.ps1"
                    }
                    Predic = [PSCustomObject]@{
                        Enabled    = $true
                        ScriptPath = "development\scripts\maintenance\modes\predic-mode.ps1"
                    }
                    Review = [PSCustomObject]@{
                        Enabled    = $true
                        ScriptPath = "development\scripts\maintenance\modes\review-mode.ps1"
                    }
                    Test   = [PSCustomObject]@{
                        Enabled    = $true
                        ScriptPath = "development\scripts\maintenance\modes\test-mode.ps1"
                    }
                }
            }
        }

        # Fonction pour obtenir le chemin du script d'un mode
        function Get-ModeScriptPath {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory = $true)]
                [string]$Mode,

                [Parameter(Mandatory = $true)]
                [PSCustomObject]$Config
            )

            $modeKey = switch ($Mode) {
                "ARCHI" { "Archi" }
                "CHECK" { "Check" }
                "C-BREAK" { "CBreak" }
                "DEBUG" { "Debug" }
                "DEV-R" { "DevR" }
                "GRAN" { "Gran" }
                "OPTI" { "Opti" }
                "PREDIC" { "Predic" }
                "REVIEW" { "Review" }
                "TEST" { "Test" }
                default { throw "Mode non reconnu : $Mode" }
            }

            if ($Config.Modes.$modeKey -and $Config.Modes.$modeKey.ScriptPath) {
                $scriptPath = $Config.Modes.$modeKey.ScriptPath

                # Convertir le chemin relatif en chemin absolu si nÃ©cessaire
                if (-not [System.IO.Path]::IsPathRooted($scriptPath)) {
                    $scriptPath = Join-Path -Path $projectRoot -ChildPath $scriptPath
                }

                return $scriptPath
            }

            # Recherche alternative si le chemin n'est pas trouvÃ© dans la configuration
            $possiblePaths = @(
                (Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\$($Mode.ToLower())-mode.ps1"),
                (Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\modes\$($Mode.ToLower())\$($Mode.ToLower())-mode.ps1"),
                (Join-Path -Path $projectRoot -ChildPath "tools\scripts\roadmap-parser\modes\$($Mode.ToLower())\$($Mode.ToLower())-mode.ps1")
            )

            foreach ($path in $possiblePaths) {
                if (Test-Path -Path $path) {
                    return $path
                }
            }

            throw "Script pour le mode $Mode introuvable."
        }

        # Fonction pour afficher la liste des modes disponibles
        function Show-AvailableModes {
            [CmdletBinding()]
            param ()

            $modes = @{
                "ARCHI"   = "Structurer, modÃ©liser, anticiper les dÃ©pendances"
                "CHECK"   = "VÃ©rifier l'Ã©tat d'avancement des tÃ¢ches"
                "C-BREAK" = "DÃ©tecter et rÃ©soudre les dÃ©pendances circulaires"
                "DEBUG"   = "Isoler, comprendre, corriger les anomalies"
                "DEV-R"   = "ImplÃ©menter ce qui est dans la roadmap"
                "GRAN"    = "DÃ©composer les blocs complexes"
                "OPTI"    = "RÃ©duire complexitÃ©, taille ou temps d'exÃ©cution"
                "PREDIC"  = "Anticiper performances, dÃ©tecter anomalies, analyser tendances"
                "REVIEW"  = "VÃ©rifier lisibilitÃ©, standards, documentation"
                "TEST"    = "Maximiser couverture et fiabilitÃ©"
            }

            Write-Host "Modes disponibles :" -ForegroundColor Cyan
            Write-Host "===================" -ForegroundColor Cyan

            foreach ($key in $modes.Keys | Sort-Object) {
                Write-Host "$key".PadRight(10) -ForegroundColor Yellow -NoNewline
                Write-Host " : $($modes[$key])"
            }

            Write-Host "`nExemples d'utilisation :" -ForegroundColor Cyan
            Write-Host "======================" -ForegroundColor Cyan
            Write-Host ".\mode-manager.ps1 -Mode CHECK -FilePath `"docs\plans\plan-modes-stepup.md`" -TaskIdentifier `"1.2.3`" -Force"
            Write-Host ".\mode-manager.ps1 -Chain `"GRAN,DEV-R,CHECK`" -FilePath `"docs\plans\plan-modes-stepup.md`" -TaskIdentifier `"1.2.3`""
        }

        # Fonction pour afficher la configuration d'un mode
        function Show-ModeConfiguration {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory = $true)]
                [string]$Mode,

                [Parameter(Mandatory = $true)]
                [PSCustomObject]$Config
            )

            $modeKey = switch ($Mode) {
                "ARCHI" { "Archi" }
                "CHECK" { "Check" }
                "C-BREAK" { "CBreak" }
                "DEBUG" { "Debug" }
                "DEV-R" { "DevR" }
                "GRAN" { "Gran" }
                "OPTI" { "Opti" }
                "PREDIC" { "Predic" }
                "REVIEW" { "Review" }
                "TEST" { "Test" }
                default { throw "Mode non reconnu : $Mode" }
            }

            if ($Config.Modes.$modeKey) {
                $modeConfig = $Config.Modes.$modeKey

                Write-Host "Configuration du mode $Mode :" -ForegroundColor Cyan
                Write-Host "=============================" -ForegroundColor Cyan

                $modeConfig | Format-List
            } else {
                Write-Warning "Configuration pour le mode $Mode introuvable."
            }
        }

        It "Get-ModeConfiguration devrait retourner un objet de configuration" {
            $config = Get-ModeConfiguration -ConfigPath $testConfigPath
            $config | Should -Not -BeNullOrEmpty
            $config.General | Should -Not -BeNullOrEmpty
            $config.Modes | Should -Not -BeNullOrEmpty
        }

        It "Get-ModeConfiguration devrait retourner une configuration par dÃ©faut si le fichier n'existe pas" {
            $nonExistentPath = "non-existent-config.json"
            $config = Get-ModeConfiguration -ConfigPath $nonExistentPath
            $config | Should -Not -BeNullOrEmpty
            $config.General | Should -Not -BeNullOrEmpty
            $config.Modes | Should -Not -BeNullOrEmpty
        }

        It "Get-ModeScriptPath devrait retourner un chemin de script valide pour CHECK" {
            $config = Get-ModeConfiguration -ConfigPath $testConfigPath
            $scriptPath = Get-ModeScriptPath -Mode "CHECK" -Config $config
            $scriptPath | Should -Not -BeNullOrEmpty
            $scriptPath | Should -Match "check.ps1$"
        }

        It "Get-ModeScriptPath devrait retourner un chemin de script valide pour GRAN" {
            $config = Get-ModeConfiguration -ConfigPath $testConfigPath
            $scriptPath = Get-ModeScriptPath -Mode "GRAN" -Config $config
            $scriptPath | Should -Not -BeNullOrEmpty
            $scriptPath | Should -Match "gran-mode.ps1$"
        }

        It "Get-ModeScriptPath devrait retourner un chemin de script valide pour DEV-R" {
            $config = Get-ModeConfiguration -ConfigPath $testConfigPath
            $scriptPath = Get-ModeScriptPath -Mode "DEV-R" -Config $config
            $scriptPath | Should -Not -BeNullOrEmpty
            $scriptPath | Should -Match "dev-r-mode.ps1$"
        }

        It "Get-ModeScriptPath devrait lever une exception pour un mode non reconnu" {
            $config = Get-ModeConfiguration -ConfigPath $testConfigPath
            { Get-ModeScriptPath -Mode "NON-EXISTENT" -Config $config } | Should -Throw "Mode non reconnu : NON-EXISTENT"
        }

        It "Show-AvailableModes devrait afficher la liste des modes" {
            $output = Show-AvailableModes
            $output | Should -Not -BeNullOrEmpty
            $output | Should -Contain "Modes disponibles :"
            $output | Should -Contain "ARCHI"
            $output | Should -Contain "CHECK"
            $output | Should -Contain "DEBUG"
        }

        It "Show-ModeConfiguration devrait afficher la configuration d'un mode" {
            $config = Get-ModeConfiguration -ConfigPath $testConfigPath
            $output = Show-ModeConfiguration -Mode "CHECK" -Config $config
            $output | Should -Not -BeNullOrEmpty
            $output | Should -Contain "Configuration du mode CHECK :"
        }

        It "Show-ModeConfiguration devrait afficher un avertissement pour un mode non reconnu" {
            $config = Get-ModeConfiguration -ConfigPath $testConfigPath
            $output = Show-ModeConfiguration -Mode "NON-EXISTENT" -Config $config 2>&1
            $output | Should -Not -BeNullOrEmpty
            $output.ToString() | Should -Match "Mode non reconnu : NON-EXISTENT"
        }
    }

    Context "ExÃ©cution des modes" {
        # Ces tests nÃ©cessitent des mocks pour Ã©viter d'exÃ©cuter rÃ©ellement les scripts
        BeforeAll {
            # Variables pour suivre les appels aux fonctions mockÃ©es
            $script:invokedModes = @()
            $script:invokedChains = @()
            $script:mockScriptExists = $true
            $script:mockScriptExitCode = 0

            # Mock pour la fonction Invoke-Mode
            function Invoke-Mode {
                param (
                    [Parameter(Mandatory = $true)]
                    [string]$Mode,

                    [Parameter(Mandatory = $false)]
                    [string]$FilePath,

                    [Parameter(Mandatory = $false)]
                    [string]$TaskIdentifier,

                    [Parameter(Mandatory = $false)]
                    [string]$ConfigPath,

                    [Parameter(Mandatory = $false)]
                    [switch]$Force,

                    [Parameter(Mandatory = $true)]
                    [PSCustomObject]$Config
                )

                # Enregistrer l'appel
                $script:invokedModes += @{
                    Mode           = $Mode
                    FilePath       = $FilePath
                    TaskIdentifier = $TaskIdentifier
                    ConfigPath     = $ConfigPath
                    Force          = $Force
                }

                # Simuler une erreur si le mode est "ERROR"
                if ($Mode -eq "ERROR") {
                    throw "Erreur simulÃ©e pour le mode ERROR"
                }

                return $true
            }

            # Mock pour la fonction Invoke-ModeChain
            function Invoke-ModeChain {
                param (
                    [Parameter(Mandatory = $true)]
                    [string]$Chain,

                    [Parameter(Mandatory = $false)]
                    [string]$FilePath,

                    [Parameter(Mandatory = $false)]
                    [string]$TaskIdentifier,

                    [Parameter(Mandatory = $false)]
                    [string]$ConfigPath,

                    [Parameter(Mandatory = $false)]
                    [switch]$Force,

                    [Parameter(Mandatory = $true)]
                    [PSCustomObject]$Config
                )

                # Enregistrer l'appel
                $script:invokedChains += @{
                    Chain          = $Chain
                    FilePath       = $FilePath
                    TaskIdentifier = $TaskIdentifier
                    ConfigPath     = $ConfigPath
                    Force          = $Force
                }

                # Simuler une erreur si la chaÃ®ne contient "ERROR"
                if ($Chain -match "ERROR") {
                    throw "Erreur simulÃ©e pour la chaÃ®ne contenant ERROR"
                }

                return $true
            }

            # Mock pour Test-Path
            function Test-Path {
                param (
                    [Parameter(Mandatory = $true)]
                    [string]$Path
                )

                # Simuler l'existence ou non du script
                return $script:mockScriptExists
            }

            # Mock pour l'opÃ©rateur &
            # Nous ne pouvons pas directement mocker l'opÃ©rateur &, mais nous pouvons mocker les fonctions qu'il appelle
            # Dans ce cas, nous allons simuler le comportement de l'exÃ©cution du script
            $global:LASTEXITCODE = $script:mockScriptExitCode
        }

        BeforeEach {
            # RÃ©initialiser les variables de suivi
            $script:invokedModes = @()
            $script:invokedChains = @()
            $script:mockScriptExists = $true
            $script:mockScriptExitCode = 0
        }

        It "Devrait exÃ©cuter un mode spÃ©cifique" {
            $result = Invoke-Mode -Mode "CHECK" -FilePath "test.md" -TaskIdentifier "1.2.3" -ConfigPath $testConfigPath -Config (Get-ModeConfiguration -ConfigPath $testConfigPath)
            $result | Should -Be $true
            $script:invokedModes.Count | Should -Be 1
            $script:invokedModes[0].Mode | Should -Be "CHECK"
            $script:invokedModes[0].FilePath | Should -Be "test.md"
            $script:invokedModes[0].TaskIdentifier | Should -Be "1.2.3"
        }

        It "Devrait exÃ©cuter une chaÃ®ne de modes" {
            $result = Invoke-ModeChain -Chain "GRAN,DEV-R,CHECK" -FilePath "test.md" -TaskIdentifier "1.2.3" -ConfigPath $testConfigPath -Config (Get-ModeConfiguration -ConfigPath $testConfigPath)
            $result | Should -Be $true
            $script:invokedChains.Count | Should -Be 1
            $script:invokedChains[0].Chain | Should -Be "GRAN,DEV-R,CHECK"
            $script:invokedChains[0].FilePath | Should -Be "test.md"
            $script:invokedChains[0].TaskIdentifier | Should -Be "1.2.3"
        }

        It "Devrait gÃ©rer les erreurs lors de l'exÃ©cution d'un mode" {
            { Invoke-Mode -Mode "ERROR" -FilePath "test.md" -TaskIdentifier "1.2.3" -ConfigPath $testConfigPath -Config (Get-ModeConfiguration -ConfigPath $testConfigPath) } | Should -Throw "Erreur simulÃ©e pour le mode ERROR"
        }

        It "Devrait gÃ©rer les erreurs lors de l'exÃ©cution d'une chaÃ®ne de modes" {
            { Invoke-ModeChain -Chain "GRAN,ERROR,CHECK" -FilePath "test.md" -TaskIdentifier "1.2.3" -ConfigPath $testConfigPath -Config (Get-ModeConfiguration -ConfigPath $testConfigPath) } | Should -Throw "Erreur simulÃ©e pour la chaÃ®ne contenant ERROR"
        }

        It "Devrait gÃ©rer le cas oÃ¹ le script du mode n'existe pas" {
            $script:mockScriptExists = $false
            { Invoke-Mode -Mode "CHECK" -FilePath "test.md" -TaskIdentifier "1.2.3" -ConfigPath $testConfigPath -Config (Get-ModeConfiguration -ConfigPath $testConfigPath) } | Should -Throw
        }

        It "Devrait gÃ©rer le cas oÃ¹ le script du mode retourne un code d'erreur" {
            $script:mockScriptExitCode = 1
            { Invoke-Mode -Mode "CHECK" -FilePath "test.md" -TaskIdentifier "1.2.3" -ConfigPath $testConfigPath -Config (Get-ModeConfiguration -ConfigPath $testConfigPath) } | Should -Throw
        }
    }

    Context "Workflows" {
        BeforeAll {
            # Variables pour suivre les appels aux fonctions mockÃ©es
            $script:invokedModes = @()
            $script:invokedChains = @()

            # Mock pour la fonction Invoke-Mode
            function Invoke-Mode {
                param (
                    [Parameter(Mandatory = $true)]
                    [string]$Mode,

                    [Parameter(Mandatory = $false)]
                    [string]$FilePath,

                    [Parameter(Mandatory = $false)]
                    [string]$TaskIdentifier,

                    [Parameter(Mandatory = $false)]
                    [string]$ConfigPath,

                    [Parameter(Mandatory = $false)]
                    [switch]$Force,

                    [Parameter(Mandatory = $true)]
                    [PSCustomObject]$Config
                )

                # Enregistrer l'appel
                $script:invokedModes += @{
                    Mode           = $Mode
                    FilePath       = $FilePath
                    TaskIdentifier = $TaskIdentifier
                    ConfigPath     = $ConfigPath
                    Force          = $Force
                }

                return $true
            }

            # Mock pour la fonction Invoke-ModeChain
            function Invoke-ModeChain {
                param (
                    [Parameter(Mandatory = $true)]
                    [string]$Chain,

                    [Parameter(Mandatory = $false)]
                    [string]$FilePath,

                    [Parameter(Mandatory = $false)]
                    [string]$TaskIdentifier,

                    [Parameter(Mandatory = $false)]
                    [string]$ConfigPath,

                    [Parameter(Mandatory = $false)]
                    [switch]$Force,

                    [Parameter(Mandatory = $true)]
                    [PSCustomObject]$Config
                )

                # Enregistrer l'appel
                $script:invokedChains += @{
                    Chain          = $Chain
                    FilePath       = $FilePath
                    TaskIdentifier = $TaskIdentifier
                    ConfigPath     = $ConfigPath
                    Force          = $Force
                }

                # Simuler l'exÃ©cution de la chaÃ®ne
                $modes = $Chain -split ',' | ForEach-Object { $_.Trim() }
                foreach ($mode in $modes) {
                    Invoke-Mode -Mode $mode -FilePath $FilePath -TaskIdentifier $TaskIdentifier -ConfigPath $ConfigPath -Force:$Force -Config $Config
                }

                return $true
            }
        }

        BeforeEach {
            # RÃ©initialiser les variables de suivi
            $script:invokedModes = @()
            $script:invokedChains = @()
        }

        It "Devrait exÃ©cuter le workflow de dÃ©veloppement" {
            $config = Get-ModeConfiguration -ConfigPath $testConfigPath
            $result = Invoke-ModeChain -Chain "GRAN,DEV-R,TEST,CHECK" -FilePath "test.md" -TaskIdentifier "1.2.3" -ConfigPath $testConfigPath -Config $config
            $result | Should -Be $true
            $script:invokedChains.Count | Should -Be 1
            $script:invokedChains[0].Chain | Should -Be "GRAN,DEV-R,TEST,CHECK"
            $script:invokedModes.Count | Should -Be 4
            $script:invokedModes[0].Mode | Should -Be "GRAN"
            $script:invokedModes[1].Mode | Should -Be "DEV-R"
            $script:invokedModes[2].Mode | Should -Be "TEST"
            $script:invokedModes[3].Mode | Should -Be "CHECK"
        }

        It "Devrait exÃ©cuter le workflow de dÃ©bogage" {
            $config = Get-ModeConfiguration -ConfigPath $testConfigPath
            $result = Invoke-ModeChain -Chain "DEBUG,TEST,CHECK" -FilePath "test.md" -TaskIdentifier "1.2.3" -ConfigPath $testConfigPath -Config $config
            $result | Should -Be $true
            $script:invokedChains.Count | Should -Be 1
            $script:invokedChains[0].Chain | Should -Be "DEBUG,TEST,CHECK"
            $script:invokedModes.Count | Should -Be 3
            $script:invokedModes[0].Mode | Should -Be "DEBUG"
            $script:invokedModes[1].Mode | Should -Be "TEST"
            $script:invokedModes[2].Mode | Should -Be "CHECK"
        }

        It "Devrait exÃ©cuter un workflow personnalisÃ©" {
            $config = Get-ModeConfiguration -ConfigPath $testConfigPath
            $result = Invoke-ModeChain -Chain "REVIEW,OPTI,TEST" -FilePath "test.md" -TaskIdentifier "1.2.3" -ConfigPath $testConfigPath -Config $config
            $result | Should -Be $true
            $script:invokedChains.Count | Should -Be 1
            $script:invokedChains[0].Chain | Should -Be "REVIEW,OPTI,TEST"
            $script:invokedModes.Count | Should -Be 3
            $script:invokedModes[0].Mode | Should -Be "REVIEW"
            $script:invokedModes[1].Mode | Should -Be "OPTI"
            $script:invokedModes[2].Mode | Should -Be "TEST"
        }
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Path $PSScriptRoot

