<#
.SYNOPSIS
    Test d'intÃ©gration pour le script gran-mode.ps1.

.DESCRIPTION
    Ce script effectue un test d'intÃ©gration pour le script gran-mode.ps1,
    en vÃ©rifiant que les nouvelles fonctionnalitÃ©s d'estimation de temps et
    de gÃ©nÃ©ration de sous-tÃ¢ches par IA fonctionnent correctement.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2025-06-02
#>

# Importer Pester si disponible
if (Get-Module -ListAvailable -Name Pester) {
    Import-Module Pester
} else {
    Write-Warning "Le module Pester n'est pas installÃ©. Les tests ne seront pas exÃ©cutÃ©s avec le framework Pester."
    exit 1
}

# Chemin vers le script Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$granModePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "modes\gran-mode.ps1"

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $granModePath)) {
    throw "Le fichier gran-mode.ps1 est introuvable Ã  l'emplacement : $granModePath"
}

# CrÃ©er des fichiers temporaires pour les tests
$testRoadmapPath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"
$testTimeEstimatesPath = Join-Path -Path $env:TEMP -ChildPath "time-estimates_$(Get-Random).json"
$testAIConfigPath = Join-Path -Path $env:TEMP -ChildPath "ai-config_$(Get-Random).json"

Describe "Gran-Mode Integration" {
    BeforeEach {
        # CrÃ©er un fichier de roadmap de test
        @"
# Roadmap de test

## Section 1

- [ ] **1.1** TÃ¢che 1
- [ ] **1.2** TÃ¢che 2
  - [ ] **1.2.1** Sous-tÃ¢che 1
  - [ ] **1.2.2** Sous-tÃ¢che 2
- [ ] **1.3** TÃ¢che Ã  dÃ©composer

## Section 2

- [ ] **2.1** Autre tÃ¢che
"@ | Set-Content -Path $testRoadmapPath -Encoding UTF8

        # CrÃ©er un rÃ©pertoire pour les fichiers de configuration
        $templatesDir = Join-Path -Path $env:TEMP -ChildPath "templates\subtasks"
        New-Item -Path $templatesDir -ItemType Directory -Force | Out-Null

        # CrÃ©er un fichier de configuration pour les estimations de temps
        @"
{
  "complexity_multipliers": {
    "simple": 0.5,
    "medium": 1.0,
    "complex": 2.0
  },
  "domain_multipliers": {
    "frontend": 1.0,
    "backend": 1.2,
    "database": 1.1,
    "testing": 0.9,
    "devops": 1.3,
    "security": 1.4,
    "ai-ml": 1.5,
    "documentation": 0.8
  },
  "base_times": {
    "analysis": {
      "unit": "h",
      "value": 2
    },
    "design": {
      "unit": "h",
      "value": 3
    },
    "implementation": {
      "unit": "h",
      "value": 4
    },
    "testing": {
      "unit": "h",
      "value": 2
    },
    "documentation": {
      "unit": "h",
      "value": 1
    },
    "default": {
      "unit": "h",
      "value": 2
    }
  },
  "task_keywords": {
    "analysis": ["analyser", "analyse", "Ã©tudier", "Ã©valuer", "comprendre", "identifier", "rechercher"],
    "design": ["concevoir", "conception", "architecture", "modÃ©liser", "planifier", "structurer"],
    "implementation": ["implÃ©menter", "dÃ©velopper", "coder", "programmer", "crÃ©er", "mettre en place", "intÃ©grer"],
    "testing": ["tester", "vÃ©rifier", "valider", "contrÃ´ler", "qualitÃ©", "test"],
    "documentation": ["documenter", "documentation", "guide", "manuel", "rÃ©fÃ©rence"]
  }
}
"@ | Set-Content -Path $testTimeEstimatesPath -Encoding UTF8

        # CrÃ©er un fichier de configuration pour l'IA
        @"
{
  "enabled": true,
  "api_key_env_var": "OPENAI_API_KEY",
  "model": "gpt-3.5-turbo",
  "temperature": 0.7,
  "max_tokens": 1000,
  "prompt_template": "Je dois dÃ©composer une tÃ¢che de dÃ©veloppement en sous-tÃ¢ches. Voici les informations :\n\nTÃ¢che principale : {task}\nNiveau de complexitÃ© : {complexity}\nDomaines techniques : {domains}\nNombre maximum de sous-tÃ¢ches : {max_subtasks}\n\nGÃ©nÃ¨re une liste de sous-tÃ¢ches pertinentes pour cette tÃ¢che, en tenant compte du niveau de complexitÃ© et des domaines techniques. Chaque sous-tÃ¢che doit Ãªtre concise et commencer par un verbe d'action. N'inclus pas de numÃ©ros ou de tirets au dÃ©but des lignes. Limite-toi Ã  {max_subtasks} sous-tÃ¢ches maximum. Retourne uniquement la liste des sous-tÃ¢ches, une par ligne."
}
"@ | Set-Content -Path $testAIConfigPath -Encoding UTF8

        # CrÃ©er des mocks pour les fonctions externes
        Mock Join-Path {
            if ($ChildPath -eq "development\templates\subtasks\time-estimates.json") {
                return $testTimeEstimatesPath
            } elseif ($ChildPath -eq "development\templates\subtasks\ai-config.json") {
                return $testAIConfigPath
            } else {
                return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(
                    (Join-Path -Path $Path -ChildPath $ChildPath)
                )
            }
        }

        Mock [Environment]::GetEnvironmentVariable {
            if ($args[0] -eq "OPENAI_API_KEY") {
                return "sk-fake-api-key-for-testing"
            } else {
                return $null
            }
        }

        Mock Invoke-RestMethod {
            # Simuler une rÃ©ponse de l'API OpenAI
            return @{
                choices = @(
                    @{
                        message = @{
                            content = "Analyser les besoins du systÃ¨me`nConcevoir l'architecture`nDÃ©velopper le module d'authentification`nIntÃ©grer avec la base de donnÃ©es`nTester les fonctionnalitÃ©s"
                        }
                    }
                )
            }
        }

        # CrÃ©er un mock pour Invoke-RoadmapGranularization
        Mock Invoke-RoadmapGranularization {
            param (
                [string]$FilePath,
                [string]$TaskIdentifier,
                [string]$SubTasksInput,
                [string]$IndentationStyle,
                [string]$CheckboxStyle
            )

            # Simuler la dÃ©composition de la tÃ¢che
            $subTasks = $SubTasksInput -split "`n" | Where-Object { $_ -match '\S' }
            $content = Get-Content -Path $FilePath -Encoding UTF8
            $taskLineIndex = -1
            $taskLinePattern = ".*\b$([regex]::Escape($TaskIdentifier))\b.*"

            for ($i = 0; $i -lt $content.Count; $i++) {
                if ($content[$i] -match $taskLinePattern) {
                    $taskLineIndex = $i
                    break
                }
            }

            if ($taskLineIndex -ne -1) {
                $taskLine = $content[$taskLineIndex]
                $indentation = ""
                if ($taskLine -match "^(\s+)") {
                    $indentation = $matches[1]
                }
                $subTaskIndentation = $indentation + "  "

                $newContent = @()
                for ($i = 0; $i -lt $content.Count; $i++) {
                    $newContent += $content[$i]
                    if ($i -eq $taskLineIndex) {
                        foreach ($j in 1..$subTasks.Count) {
                            $subTaskId = "$TaskIdentifier.$j"
                            $subTaskTitle = $subTasks[$j - 1]
                            $newContent += "$subTaskIndentation- [ ] **$subTaskId** $subTaskTitle"
                        }
                    }
                }

                $newContent | Set-Content -Path $FilePath -Encoding UTF8
            }

            return @{
                Success = $true
                FilePath = $FilePath
                TaskIdentifier = $TaskIdentifier
                SubTasksAdded = $subTasks.Count
            }
        }

        # CrÃ©er un mock pour Invoke-RoadmapGranularizationWithTimeEstimation
        Mock Invoke-RoadmapGranularizationWithTimeEstimation {
            param (
                [string]$FilePath,
                [string]$TaskIdentifier,
                [string]$SubTasksInput,
                [string]$IndentationStyle,
                [string]$CheckboxStyle,
                [switch]$AddTimeEstimation,
                [string]$ComplexityLevel,
                [string]$Domain
            )

            # Simuler la dÃ©composition de la tÃ¢che avec estimations de temps
            $subTasks = $SubTasksInput -split "`n" | Where-Object { $_ -match '\S' }
            $content = Get-Content -Path $FilePath -Encoding UTF8
            $taskLineIndex = -1
            $taskLinePattern = ".*\b$([regex]::Escape($TaskIdentifier))\b.*"

            for ($i = 0; $i -lt $content.Count; $i++) {
                if ($content[$i] -match $taskLinePattern) {
                    $taskLineIndex = $i
                    break
                }
            }

            if ($taskLineIndex -ne -1) {
                $taskLine = $content[$taskLineIndex]
                $indentation = ""
                if ($taskLine -match "^(\s+)") {
                    $indentation = $matches[1]
                }
                $subTaskIndentation = $indentation + "  "

                $newContent = @()
                for ($i = 0; $i -lt $content.Count; $i++) {
                    $newContent += $content[$i]
                    if ($i -eq $taskLineIndex) {
                        foreach ($j in 1..$subTasks.Count) {
                            $subTaskId = "$TaskIdentifier.$j"
                            $subTaskTitle = $subTasks[$j - 1]
                            if ($AddTimeEstimation) {
                                $subTaskTitle = "$subTaskTitle [â±ï¸ 2 h]"
                            }
                            $newContent += "$subTaskIndentation- [ ] **$subTaskId** $subTaskTitle"
                        }
                    }
                }

                $newContent | Set-Content -Path $FilePath -Encoding UTF8
            }

            return @{
                Success = $true
                FilePath = $FilePath
                TaskIdentifier = $TaskIdentifier
                SubTasksAdded = $subTasks.Count
            }
        }
    }

    AfterEach {
        # Supprimer les fichiers temporaires
        if (Test-Path -Path $testRoadmapPath) {
            Remove-Item -Path $testRoadmapPath -Force
        }
        if (Test-Path -Path $testTimeEstimatesPath) {
            Remove-Item -Path $testTimeEstimatesPath -Force
        }
        if (Test-Path -Path $testAIConfigPath) {
            Remove-Item -Path $testAIConfigPath -Force
        }
        $templatesDir = Join-Path -Path $env:TEMP -ChildPath "templates"
        if (Test-Path -Path $templatesDir) {
            Remove-Item -Path $templatesDir -Recurse -Force
        }
    }

    It "Devrait dÃ©composer une tÃ¢che en sous-tÃ¢ches sans estimations de temps" {
        # Appeler le script
        & $granModePath -FilePath $testRoadmapPath -TaskIdentifier "1.3" -SubTasksInput "Analyser les besoins`nConcevoir la solution" -WhatIf

        # VÃ©rifier que la fonction Invoke-RoadmapGranularization a Ã©tÃ© appelÃ©e
        Should -Invoke Invoke-RoadmapGranularization -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq $testRoadmapPath -and
            $TaskIdentifier -eq "1.3" -and
            $SubTasksInput -match "Analyser les besoins"
        }
    }

    It "Devrait dÃ©composer une tÃ¢che en sous-tÃ¢ches avec estimations de temps" {
        # Appeler le script
        & $granModePath -FilePath $testRoadmapPath -TaskIdentifier "1.3" -SubTasksInput "Analyser les besoins`nConcevoir la solution" -AddTimeEstimation -WhatIf

        # VÃ©rifier que la fonction Invoke-RoadmapGranularizationWithTimeEstimation a Ã©tÃ© appelÃ©e
        Should -Invoke Invoke-RoadmapGranularizationWithTimeEstimation -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq $testRoadmapPath -and
            $TaskIdentifier -eq "1.3" -and
            $SubTasksInput -match "Analyser les besoins" -and
            $AddTimeEstimation -eq $true
        }
    }

    It "Devrait dÃ©composer une tÃ¢che en sous-tÃ¢ches avec estimations de temps et un domaine spÃ©cifique" {
        # Appeler le script
        & $granModePath -FilePath $testRoadmapPath -TaskIdentifier "1.3" -SubTasksInput "Analyser les besoins`nConcevoir la solution" -AddTimeEstimation -Domain "Backend" -WhatIf

        # VÃ©rifier que la fonction Invoke-RoadmapGranularizationWithTimeEstimation a Ã©tÃ© appelÃ©e
        Should -Invoke Invoke-RoadmapGranularizationWithTimeEstimation -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq $testRoadmapPath -and
            $TaskIdentifier -eq "1.3" -and
            $SubTasksInput -match "Analyser les besoins" -and
            $AddTimeEstimation -eq $true -and
            $Domain -eq "Backend"
        }
    }

    It "Devrait dÃ©composer une tÃ¢che en sous-tÃ¢ches avec l'IA" {
        # Appeler le script
        & $granModePath -FilePath $testRoadmapPath -TaskIdentifier "1.3" -UseAI -WhatIf

        # VÃ©rifier que la fonction Invoke-RestMethod a Ã©tÃ© appelÃ©e (pour l'API OpenAI)
        Should -Invoke Invoke-RestMethod -Times 1 -Exactly
    }

    It "Devrait dÃ©composer une tÃ¢che en sous-tÃ¢ches avec l'IA et des estimations de temps" {
        # Appeler le script
        & $granModePath -FilePath $testRoadmapPath -TaskIdentifier "1.3" -UseAI -AddTimeEstimation -WhatIf

        # VÃ©rifier que la fonction Invoke-RestMethod a Ã©tÃ© appelÃ©e (pour l'API OpenAI)
        Should -Invoke Invoke-RestMethod -Times 1 -Exactly

        # VÃ©rifier que la fonction Invoke-RoadmapGranularizationWithTimeEstimation a Ã©tÃ© appelÃ©e
        Should -Invoke Invoke-RoadmapGranularizationWithTimeEstimation -Times 1 -Exactly -ParameterFilter {
            $AddTimeEstimation -eq $true
        }
    }
}

# ExÃ©cuter les tests si le script est exÃ©cutÃ© directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Invoke-Pester -Script $MyInvocation.MyCommand.Path
}
