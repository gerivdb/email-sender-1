# Tests unitaires pour le mode manager

# Importer le module Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Définir le chemin du script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\mode-manager.ps1"

# Vérifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    Write-Error "Le script mode-manager.ps1 est introuvable à l'emplacement : $scriptPath"
    exit 1
}

Describe "Mode Manager - Tests unitaires" {
    BeforeAll {
        # Créer un répertoire temporaire pour les tests
        $testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
        if (-not (Test-Path -Path $testDir)) {
            New-Item -Path $testDir -ItemType Directory -Force | Out-Null
        }
        
        # Créer un fichier de configuration pour les tests
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
        
        # Créer des scripts de mode simulés
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

# Créer un fichier de sortie pour vérifier que le script a été exécuté
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

# Créer un fichier de sortie pour vérifier que le script a été exécuté
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

# Créer un fichier de sortie pour vérifier que le script a été exécuté
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
        
        # Créer un fichier de roadmap de test
        $testRoadmapPath = Join-Path -Path $testDir -ChildPath "test-roadmap.md"
        @"
# Test Roadmap

## Tâche 1.2.3

### Description
Cette tâche est utilisée pour les tests unitaires.

### Sous-tâches
- [ ] Sous-tâche 1
- [ ] Sous-tâche 2
- [ ] Sous-tâche 3
"@ | Set-Content -Path $testRoadmapPath -Encoding UTF8
        
        # Définir les variables globales pour les tests
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
    
    Context "Paramètres" {
        It "Devrait accepter le paramètre Mode" {
            $result = Get-Command -Name $scriptPath | Select-Object -ExpandProperty Parameters
            $result.ContainsKey("Mode") | Should -Be $true
        }
        
        It "Devrait accepter le paramètre FilePath" {
            $result = Get-Command -Name $scriptPath | Select-Object -ExpandProperty Parameters
            $result.ContainsKey("FilePath") | Should -Be $true
        }
        
        It "Devrait accepter le paramètre TaskIdentifier" {
            $result = Get-Command -Name $scriptPath | Select-Object -ExpandProperty Parameters
            $result.ContainsKey("TaskIdentifier") | Should -Be $true
        }
        
        It "Devrait accepter le paramètre Force" {
            $result = Get-Command -Name $scriptPath | Select-Object -ExpandProperty Parameters
            $result.ContainsKey("Force") | Should -Be $true
        }
        
        It "Devrait accepter le paramètre ConfigPath" {
            $result = Get-Command -Name $scriptPath | Select-Object -ExpandProperty Parameters
            $result.ContainsKey("ConfigPath") | Should -Be $true
        }
    }
    
    Context "Exécution du mode CHECK" {
        It "Devrait exécuter le mode CHECK avec succès" {
            $result = & $scriptPath -Mode "CHECK" -FilePath $script:testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $script:configPath
            $LASTEXITCODE | Should -Be 0
            
            $outputPath = Join-Path -Path $script:testDir -ChildPath "check-mode-output.txt"
            Test-Path -Path $outputPath | Should -Be $true
            
            $output = Get-Content -Path $outputPath -Raw
            $output | Should -Match "FilePath : $([regex]::Escape($script:testRoadmapPath))"
            $output | Should -Match "TaskIdentifier : 1.2.3"
        }
    }
    
    Context "Exécution du mode GRAN" {
        It "Devrait exécuter le mode GRAN avec succès" {
            $result = & $scriptPath -Mode "GRAN" -FilePath $script:testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $script:configPath
            $LASTEXITCODE | Should -Be 0
            
            $outputPath = Join-Path -Path $script:testDir -ChildPath "gran-mode-output.txt"
            Test-Path -Path $outputPath | Should -Be $true
            
            $output = Get-Content -Path $outputPath -Raw
            $output | Should -Match "FilePath : $([regex]::Escape($script:testRoadmapPath))"
            $output | Should -Match "TaskIdentifier : 1.2.3"
        }
    }
    
    Context "Exécution d'un mode désactivé" {
        It "Devrait échouer lors de l'exécution d'un mode désactivé" {
            $result = & $scriptPath -Mode "DISABLED" -FilePath $script:testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $script:configPath
            $LASTEXITCODE | Should -Not -Be 0
            
            $outputPath = Join-Path -Path $script:testDir -ChildPath "disabled-mode-output.txt"
            Test-Path -Path $outputPath | Should -Be $false
        }
    }
    
    Context "Exécution d'un mode inexistant" {
        It "Devrait échouer lors de l'exécution d'un mode inexistant" {
            $result = & $scriptPath -Mode "NONEXISTENT" -FilePath $script:testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $script:configPath
            $LASTEXITCODE | Should -Not -Be 0
        }
    }
    
    Context "Exécution sans configuration" {
        It "Devrait échouer lors de l'exécution sans configuration" {
            $result = & $scriptPath -Mode "CHECK" -FilePath $script:testRoadmapPath -TaskIdentifier "1.2.3"
            $LASTEXITCODE | Should -Not -Be 0
        }
    }
    
    Context "Exécution avec une configuration invalide" {
        It "Devrait échouer lors de l'exécution avec une configuration invalide" {
            $invalidConfigPath = Join-Path -Path $script:testDir -ChildPath "invalid-config.json"
            "Invalid JSON" | Set-Content -Path $invalidConfigPath -Encoding UTF8
            
            $result = & $scriptPath -Mode "CHECK" -FilePath $script:testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $invalidConfigPath
            $LASTEXITCODE | Should -Not -Be 0
        }
    }
    
    Context "Exécution avec un fichier de roadmap inexistant" {
        It "Devrait échouer lors de l'exécution avec un fichier de roadmap inexistant" {
            $result = & $scriptPath -Mode "CHECK" -FilePath "nonexistent.md" -TaskIdentifier "1.2.3" -ConfigPath $script:configPath
            $LASTEXITCODE | Should -Not -Be 0
        }
    }
    
    Context "Exécution avec un identifiant de tâche invalide" {
        It "Devrait échouer lors de l'exécution avec un identifiant de tâche invalide" {
            $result = & $scriptPath -Mode "CHECK" -FilePath $script:testRoadmapPath -TaskIdentifier "invalid" -ConfigPath $script:configPath
            $LASTEXITCODE | Should -Not -Be 0
        }
    }
    
    Context "Exécution avec le paramètre Force" {
        It "Devrait exécuter le mode CHECK avec le paramètre Force" {
            $result = & $scriptPath -Mode "CHECK" -FilePath $script:testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $script:configPath -Force
            $LASTEXITCODE | Should -Be 0
            
            $outputPath = Join-Path -Path $script:testDir -ChildPath "check-mode-output.txt"
            Test-Path -Path $outputPath | Should -Be $true
            
            $output = Get-Content -Path $outputPath -Raw
            $output | Should -Match "Force : True"
        }
    }
}
