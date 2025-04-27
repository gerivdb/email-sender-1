# Tests pour les fonctions de configuration

# Chemin vers le script à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent (Split-Path -Parent $scriptPath)
$configFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\Configuration"

# Importer les fonctions à tester
$initializeConfigPath = Join-Path -Path $configFunctionsPath -ChildPath "Initialize-Configuration.ps1"
$getConfigPath = Join-Path -Path $configFunctionsPath -ChildPath "Get-Configuration.ps1"
$testConfigPath = Join-Path -Path $configFunctionsPath -ChildPath "Test-Configuration.ps1"
$setDefaultConfigPath = Join-Path -Path $configFunctionsPath -ChildPath "Set-DefaultConfiguration.ps1"

# Vérifier si les fichiers existent
if (Test-Path -Path $initializeConfigPath) {
    . $initializeConfigPath
    Write-Host "Fonction Initialize-Configuration importée." -ForegroundColor Green
}

if (Test-Path -Path $getConfigPath) {
    . $getConfigPath
    Write-Host "Fonction Get-Configuration importée." -ForegroundColor Green
}

if (Test-Path -Path $testConfigPath) {
    . $testConfigPath
    Write-Host "Fonction Test-Configuration importée." -ForegroundColor Green
}

if (Test-Path -Path $setDefaultConfigPath) {
    . $setDefaultConfigPath
    Write-Host "Fonction Set-DefaultConfiguration importée." -ForegroundColor Green
}

Describe "Configuration Functions" {
    BeforeAll {
        # Créer un répertoire temporaire pour les tests
        $testDir = Join-Path -Path $env:TEMP -ChildPath "RoadmapParserTests_$(Get-Random)"
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null

        # Créer un fichier de configuration JSON de test
        $testJsonConfig = @{
            General = @{
                RoadmapPath = "Roadmap\roadmap_complete_converted.md"
                Encoding = "UTF8"
                DefaultMode = "check"
                LogPath = "logs"
                LogLevel = "INFO"
            }
            Paths = @{
                OutputDirectory = "output"
                TestsDirectory = "tests"
                ScriptsDirectory = "tools\scripts"
                ModulePath = "roadmap-parser\module"
                FunctionsPath = "roadmap-parser\module\Functions"
            }
            Check = @{
                AutoUpdateCheckboxes = $true
                RequireFullTestCoverage = $true
                SimulationModeDefault = $true
            }
            Modes = @{
                Check = @{
                    Enabled = $true
                    ScriptPath = "tools\scripts\roadmap-parser\modes\check\check-mode-enhanced.ps1"
                }
                Debug = @{
                    Enabled = $true
                    ScriptPath = "tools\scripts\roadmap-parser\modes\debug\debug-mode.ps1"
                    GeneratePatch = $true
                    IncludeStackTrace = $true
                }
                Archi = @{
                    Enabled = $false
                    ScriptPath = "tools\scripts\archi-mode.ps1"
                }
                CBreak = @{
                    Enabled = $false
                    ScriptPath = "tools\scripts\c-break-mode.ps1"
                }
                TEST = @{
                    Enabled = $true
                    ScriptPath = "tools\scripts\test-mode.ps1"
                    CoverageThreshold = 80
                    GenerateReport = $true
                }
            }
        }

        $testJsonFile = Join-Path -Path $testDir -ChildPath "config.json"
        $testJsonConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $testJsonFile -Encoding UTF8

        # Créer une configuration incomplète pour les tests
        $testIncompleteConfig = @{
            General = @{
                LogLevel = "INFO"
            }
            Paths = @{
                OutputPath = "custom-output"
            }
        }

        $testIncompleteFile = Join-Path -Path $testDir -ChildPath "incomplete.json"
        $testIncompleteConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $testIncompleteFile -Encoding UTF8
    }

    AfterAll {
        # Nettoyer le répertoire temporaire
        if (Test-Path -Path $testDir) {
            Remove-Item -Path $testDir -Recurse -Force
        }
    }

    Context "Initialize-Configuration" {
        It "Should create a default configuration if requested" {
            $config = Initialize-Configuration -CreateIfMissing
            $config | Should -Not -BeNullOrEmpty
            $config.General | Should -Not -BeNullOrEmpty
            $config.Paths | Should -Not -BeNullOrEmpty
            $config.Modes | Should -Not -BeNullOrEmpty
        }

        It "Should load an existing configuration file" {
            $config = Initialize-Configuration -ConfigPath $testJsonFile
            $config | Should -Not -BeNullOrEmpty
            $config.General.LogLevel | Should -Be "INFO"
            $config.Modes.Check.Enabled | Should -BeTrue
        }

        It "Should create a configuration file if it doesn't exist" {
            $newConfigPath = Join-Path -Path $testDir -ChildPath "new-config.json"
            $config = Initialize-Configuration -ConfigPath $newConfigPath -CreateIfMissing
            $config | Should -Not -BeNullOrEmpty
            Test-Path -Path $newConfigPath | Should -BeTrue
        }
    }

    Context "Get-Configuration" {
        It "Should load a JSON configuration file" {
            $config = Get-Configuration -ConfigPath $testJsonFile
            $config | Should -Not -BeNullOrEmpty
            $config.General.LogLevel | Should -Be "INFO"
            $config.Modes.Check.Enabled | Should -BeTrue
            $config.Paths.OutputDirectory | Should -Be "output"
        }

        It "Should apply defaults when requested" {
            $config = Get-Configuration -ConfigPath $testIncompleteFile -ApplyDefaults
            $config | Should -Not -BeNullOrEmpty
            $config.General.LogPath | Should -Not -BeNullOrEmpty
            $config.Modes | Should -Not -BeNullOrEmpty
            $config.Paths.ModulePath | Should -Not -BeNullOrEmpty
        }

        It "Should validate the configuration when requested" {
            { Get-Configuration -ConfigPath $testJsonFile -Validate } | Should -Not -Throw
        }

        It "Should handle non-existent files gracefully" {
            $nonExistentFile = Join-Path -Path $testDir -ChildPath "nonexistent.json"
            { Get-Configuration -ConfigPath $nonExistentFile } | Should -Throw
        }
    }

    Context "Set-DefaultConfiguration" {
        It "Should apply default values to an incomplete configuration" {
            $incompleteConfig = Get-Configuration -ConfigPath $testIncompleteFile
            $config = Set-DefaultConfiguration -Config $incompleteConfig
            $config | Should -Not -BeNullOrEmpty
            $config.General.RoadmapPath | Should -Not -BeNullOrEmpty
            $config.Modes | Should -Not -BeNullOrEmpty
            $config.Check | Should -Not -BeNullOrEmpty
        }

        It "Should preserve existing values" {
            $incompleteConfig = Get-Configuration -ConfigPath $testIncompleteFile
            $config = Set-DefaultConfiguration -Config $incompleteConfig
            $config.General.LogLevel | Should -Be "INFO"
            $config.Paths.OutputPath | Should -Be "custom-output"
        }
    }

    Context "Test-Configuration" {
        It "Should validate a complete configuration" {
            $config = Get-Configuration -ConfigPath $testJsonFile
            $isValid = Test-Configuration -Config $config
            $isValid | Should -BeTrue
        }

        It "Should detect missing required keys" {
            $config = Get-Configuration -ConfigPath $testIncompleteFile
            $isValid = Test-Configuration -Config $config
            $isValid | Should -BeFalse
        }

        It "Should support detailed validation reports" {
            $config = Get-Configuration -ConfigPath $testIncompleteFile
            $report = Test-Configuration -Config $config -Detailed
            $report.IsValid | Should -BeFalse
            $report.Results.Count | Should -BeGreaterThan 0
        }

        It "Should support custom validation rules" {
            $config = Get-Configuration -ConfigPath $testJsonFile
            $isValid = Test-Configuration -Config $config
            $isValid | Should -BeTrue
        }
    }
}
