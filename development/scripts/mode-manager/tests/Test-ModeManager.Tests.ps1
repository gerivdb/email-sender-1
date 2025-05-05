# Tests unitaires pour le mode manager

# Importer le module Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# DÃ©finir le chemin du script Ã  tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\mode-manager.ps1"

# VÃ©rifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    Write-Error "Le script mode-manager.ps1 est introuvable Ã  l'emplacement : $scriptPath"
    exit 1
}

Describe "Mode Manager - Tests unitaires" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire temporaire pour les tests
        $testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
        if (-not (Test-Path -Path $testDir)) {
            New-Item -Path $testDir -ItemType Directory -Force | Out-Null
        }
        
        # CrÃ©er un fichier de configuration pour les tests
        $configPath = Join-Path -Path $testDir -ChildPath "test-config.json"
        @{
            General = @{
                RoadmapPath = "docs\plans\roadmap_complete_2.md"
                ActiveDocumentPath = "docs\plans\plan-modes-stepup.md"
                ReportPath = "reports"
            }
            Modes = @{
                Check = @{
                    Enabled = $true
                    ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "mock-check-mode.ps1"
                }
                Gran = @{
                    Enabled = $true
                    ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "mock-gran-mode.ps1"
                }
                Disabled = @{
                    Enabled = $false
                    ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "mock-disabled-mode.ps1"
                }
            }
        } | ConvertTo-Json -Depth 5 | Set-Content -Path $configPath -Encoding UTF8
        
        # CrÃ©er des scripts de mode simulÃ©s
        $mockCheckModePath = Join-Path -Path $PSScriptRoot -ChildPath "mock-check-mode.ps1"
        $mockCheckContent = @'
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [string]$ActiveDocumentPath,

    [Parameter(Mandatory = $false)]
    [switch]$CheckActiveDocument,

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath
)

# CrÃ©er un fichier de sortie pour vÃ©rifier que le script a Ã©tÃ© exÃ©cutÃ©
$outputPath = Join-Path -Path "$PSScriptRoot\temp" -ChildPath "check-mode-output.txt"
@"
FilePath : $FilePath
TaskIdentifier : $TaskIdentifier
Force : $Force
ActiveDocumentPath : $ActiveDocumentPath
CheckActiveDocument : $CheckActiveDocument
ConfigPath : $ConfigPath
"@ | Set-Content -Path $outputPath -Encoding UTF8

exit 0
'@
        Set-Content -Path $mockCheckModePath -Value $mockCheckContent -Encoding UTF8
        
        $mockGranModePath = Join-Path -Path $PSScriptRoot -ChildPath "mock-gran-mode.ps1"
        $mockGranContent = @'
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath
)

# CrÃ©er un fichier de sortie pour vÃ©rifier que le script a Ã©tÃ© exÃ©cutÃ©
$outputPath = Join-Path -Path "$PSScriptRoot\temp" -ChildPath "gran-mode-output.txt"
@"
FilePath : $FilePath
TaskIdentifier : $TaskIdentifier
Force : $Force
ConfigPath : $ConfigPath
"@ | Set-Content -Path $outputPath -Encoding UTF8

exit 0
'@
        Set-Content -Path $mockGranModePath -Value $mockGranContent -Encoding UTF8
        
        $mockDisabledModePath = Join-Path -Path $PSScriptRoot -ChildPath "mock-disabled-mode.ps1"
        $mockDisabledContent = @'
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath
)

# CrÃ©er un fichier de sortie pour vÃ©rifier que le script a Ã©tÃ© exÃ©cutÃ©
$outputPath = Join-Path -Path "$PSScriptRoot\temp" -ChildPath "disabled-mode-output.txt"
@"
FilePath : $FilePath
TaskIdentifier : $TaskIdentifier
Force : $Force
ConfigPath : $ConfigPath
"@ | Set-Content -Path $outputPath -Encoding UTF8

exit 0
'@
        Set-Content -Path $mockDisabledModePath -Value $mockDisabledContent -Encoding UTF8
        
        # CrÃ©er un fichier de roadmap de test
        $testRoadmapPath = Join-Path -Path $testDir -ChildPath "test-roadmap.md"
        @"
# Test Roadmap

## TÃ¢che 1.2.3

### Description
Cette tÃ¢che est utilisÃ©e pour les tests unitaires.

### Sous-tÃ¢ches
- [ ] Sous-tÃ¢che 1
- [ ] Sous-tÃ¢che 2
- [ ] Sous-tÃ¢che 3
"@ | Set-Content -Path $testRoadmapPath -Encoding UTF8
        
        # DÃ©finir les variables globales pour les tests
        $script:testDir = $testDir
        $script:configPath = $configPath
        $script:testRoadmapPath = $testRoadmapPath
    }
    
    AfterAll {
        # Nettoyer les fichiers temporaires
        if (Test-Path -Path $script:testDir) {
            Remove-Item -Path $script:testDir -Recurse -Force
        }
        
        $mockFiles = @(
            "mock-check-mode.ps1",
            "mock-gran-mode.ps1",
            "mock-disabled-mode.ps1"
        )
        
        foreach ($file in $mockFiles) {
            $filePath = Join-Path -Path $PSScriptRoot -ChildPath $file
            if (Test-Path -Path $filePath) {
                Remove-Item -Path $filePath -Force
            }
        }
    }
    
    Context "ParamÃ¨tres" {
        It "Devrait accepter le paramÃ¨tre Mode" {
            $result = Get-Command -Name $scriptPath | Select-Object -ExpandProperty Parameters
            $result.ContainsKey("Mode") | Should -Be $true
        }
        
        It "Devrait accepter le paramÃ¨tre FilePath" {
            $result = Get-Command -Name $scriptPath | Select-Object -ExpandProperty Parameters
            $result.ContainsKey("FilePath") | Should -Be $true
        }
        
        It "Devrait accepter le paramÃ¨tre TaskIdentifier" {
            $result = Get-Command -Name $scriptPath | Select-Object -ExpandProperty Parameters
            $result.ContainsKey("TaskIdentifier") | Should -Be $true
        }
        
        It "Devrait accepter le paramÃ¨tre Force" {
            $result = Get-Command -Name $scriptPath | Select-Object -ExpandProperty Parameters
            $result.ContainsKey("Force") | Should -Be $true
        }
        
        It "Devrait accepter le paramÃ¨tre ConfigPath" {
            $result = Get-Command -Name $scriptPath | Select-Object -ExpandProperty Parameters
            $result.ContainsKey("ConfigPath") | Should -Be $true
        }
    }
    
    Context "ExÃ©cution du mode CHECK" {
        It "Devrait exÃ©cuter le mode CHECK avec succÃ¨s" {
            $result = & $scriptPath -Mode "CHECK" -FilePath $script:testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $script:configPath
            $LASTEXITCODE | Should -Be 0
            
            $outputPath = Join-Path -Path $script:testDir -ChildPath "check-mode-output.txt"
            Test-Path -Path $outputPath | Should -Be $true
            
            $output = Get-Content -Path $outputPath -Raw
            $output | Should -Match "FilePath : $([regex]::Escape($script:testRoadmapPath))"
            $output | Should -Match "TaskIdentifier : 1.2.3"
        }
    }
    
    Context "ExÃ©cution du mode GRAN" {
        It "Devrait exÃ©cuter le mode GRAN avec succÃ¨s" {
            $result = & $scriptPath -Mode "GRAN" -FilePath $script:testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $script:configPath
            $LASTEXITCODE | Should -Be 0
            
            $outputPath = Join-Path -Path $script:testDir -ChildPath "gran-mode-output.txt"
            Test-Path -Path $outputPath | Should -Be $true
            
            $output = Get-Content -Path $outputPath -Raw
            $output | Should -Match "FilePath : $([regex]::Escape($script:testRoadmapPath))"
            $output | Should -Match "TaskIdentifier : 1.2.3"
        }
    }
    
    Context "ExÃ©cution d'un mode dÃ©sactivÃ©" {
        It "Devrait Ã©chouer lors de l'exÃ©cution d'un mode dÃ©sactivÃ©" {
            $result = & $scriptPath -Mode "DISABLED" -FilePath $script:testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $script:configPath
            $LASTEXITCODE | Should -Not -Be 0
            
            $outputPath = Join-Path -Path $script:testDir -ChildPath "disabled-mode-output.txt"
            Test-Path -Path $outputPath | Should -Be $false
        }
    }
    
    Context "ExÃ©cution d'un mode inexistant" {
        It "Devrait Ã©chouer lors de l'exÃ©cution d'un mode inexistant" {
            $result = & $scriptPath -Mode "NONEXISTENT" -FilePath $script:testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $script:configPath
            $LASTEXITCODE | Should -Not -Be 0
        }
    }
    
    Context "ExÃ©cution sans configuration" {
        It "Devrait Ã©chouer lors de l'exÃ©cution sans configuration" {
            $result = & $scriptPath -Mode "CHECK" -FilePath $script:testRoadmapPath -TaskIdentifier "1.2.3"
            $LASTEXITCODE | Should -Not -Be 0
        }
    }
    
    Context "ExÃ©cution avec une configuration invalide" {
        It "Devrait Ã©chouer lors de l'exÃ©cution avec une configuration invalide" {
            $invalidConfigPath = Join-Path -Path $script:testDir -ChildPath "invalid-config.json"
            "Invalid JSON" | Set-Content -Path $invalidConfigPath -Encoding UTF8
            
            $result = & $scriptPath -Mode "CHECK" -FilePath $script:testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $invalidConfigPath
            $LASTEXITCODE | Should -Not -Be 0
        }
    }
    
    Context "ExÃ©cution avec un fichier de roadmap inexistant" {
        It "Devrait Ã©chouer lors de l'exÃ©cution avec un fichier de roadmap inexistant" {
            $result = & $scriptPath -Mode "CHECK" -FilePath "nonexistent.md" -TaskIdentifier "1.2.3" -ConfigPath $script:configPath
            $LASTEXITCODE | Should -Not -Be 0
        }
    }
    
    Context "ExÃ©cution avec un identifiant de tÃ¢che invalide" {
        It "Devrait Ã©chouer lors de l'exÃ©cution avec un identifiant de tÃ¢che invalide" {
            $result = & $scriptPath -Mode "CHECK" -FilePath $script:testRoadmapPath -TaskIdentifier "invalid" -ConfigPath $script:configPath
            $LASTEXITCODE | Should -Not -Be 0
        }
    }
    
    Context "ExÃ©cution avec le paramÃ¨tre Force" {
        It "Devrait exÃ©cuter le mode CHECK avec le paramÃ¨tre Force" {
            $result = & $scriptPath -Mode "CHECK" -FilePath $script:testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $script:configPath -Force
            $LASTEXITCODE | Should -Be 0
            
            $outputPath = Join-Path -Path $script:testDir -ChildPath "check-mode-output.txt"
            Test-Path -Path $outputPath | Should -Be $true
            
            $output = Get-Content -Path $outputPath -Raw
            $output | Should -Match "Force : True"
        }
    }
}
