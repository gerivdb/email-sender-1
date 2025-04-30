<#
.SYNOPSIS
    Test d'intégration pour le script gran-mode.ps1.

.DESCRIPTION
    Ce script effectue un test d'intégration pour le script gran-mode.ps1,
    en vérifiant que les nouvelles fonctionnalités d'estimation de temps et
    de génération de sous-tâches par IA fonctionnent correctement.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2025-06-02
#>

# Importer Pester si disponible
if (Get-Module -ListAvailable -Name Pester) {
    Import-Module Pester
} else {
    Write-Warning "Le module Pester n'est pas installé. Les tests ne seront pas exécutés avec le framework Pester."
    exit 1
}

# Chemin vers le script à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$granModePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "modes\gran-mode.ps1"

# Vérifier si le fichier existe
if (-not (Test-Path -Path $granModePath)) {
    throw "Le fichier gran-mode.ps1 est introuvable à l'emplacement : $granModePath"
}

# Créer des fichiers temporaires pour les tests
$testRoadmapPath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"
$testTimeEstimatesPath = Join-Path -Path $env:TEMP -ChildPath "time-estimates_$(Get-Random).json"
$testAIConfigPath = Join-Path -Path $env:TEMP -ChildPath "ai-config_$(Get-Random).json"

Describe "Gran-Mode Integration" {
    BeforeEach {
        # Créer un fichier de roadmap de test
        @"
# Roadmap de test

## Section 1

- [ ] **1.1** Tâche 1
- [ ] **1.2** Tâche 2
  - [ ] **1.2.1** Sous-tâche 1
  - [ ] **1.2.2** Sous-tâche 2
- [ ] **1.3** Tâche à décomposer

## Section 2

- [ ] **2.1** Autre tâche
"@ | Set-Content -Path $testRoadmapPath -Encoding UTF8

        # Créer un répertoire pour les fichiers de configuration
        $templatesDir = Join-Path -Path $env:TEMP -ChildPath "templates\subtasks"
        New-Item -Path $templatesDir -ItemType Directory -Force | Out-Null

        # Créer un fichier de configuration pour les estimations de temps
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
    "analysis": ["analyser", "analyse", "étudier", "évaluer", "comprendre", "identifier", "rechercher"],
    "design": ["concevoir", "conception", "architecture", "modéliser", "planifier", "structurer"],
    "implementation": ["implémenter", "développer", "coder", "programmer", "créer", "mettre en place", "intégrer"],
    "testing": ["tester", "vérifier", "valider", "contrôler", "qualité", "test"],
    "documentation": ["documenter", "documentation", "guide", "manuel", "référence"]
  }
}
"@ | Set-Content -Path $testTimeEstimatesPath -Encoding UTF8

        # Créer un fichier de configuration pour l'IA
        @"
{
  "enabled": true,
  "api_key_env_var": "OPENAI_API_KEY",
  "model": "gpt-3.5-turbo",
  "temperature": 0.7,
  "max_tokens": 1000,
  "prompt_template": "Je dois décomposer une tâche de développement en sous-tâches. Voici les informations :\n\nTâche principale : {task}\nNiveau de complexité : {complexity}\nDomaines techniques : {domains}\nNombre maximum de sous-tâches : {max_subtasks}\n\nGénère une liste de sous-tâches pertinentes pour cette tâche, en tenant compte du niveau de complexité et des domaines techniques. Chaque sous-tâche doit être concise et commencer par un verbe d'action. N'inclus pas de numéros ou de tirets au début des lignes. Limite-toi à {max_subtasks} sous-tâches maximum. Retourne uniquement la liste des sous-tâches, une par ligne."
}
"@ | Set-Content -Path $testAIConfigPath -Encoding UTF8

        # Créer des mocks pour les fonctions externes
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
            # Simuler une réponse de l'API OpenAI
            return @{
                choices = @(
                    @{
                        message = @{
                            content = "Analyser les besoins du système`nConcevoir l'architecture`nDévelopper le module d'authentification`nIntégrer avec la base de données`nTester les fonctionnalités"
                        }
                    }
                )
            }
        }

        # Créer un mock pour Invoke-RoadmapGranularization
        Mock Invoke-RoadmapGranularization {
            param (
                [string]$FilePath,
                [string]$TaskIdentifier,
                [string]$SubTasksInput,
                [string]$IndentationStyle,
                [string]$CheckboxStyle
            )

            # Simuler la décomposition de la tâche
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

        # Créer un mock pour Invoke-RoadmapGranularizationWithTimeEstimation
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

            # Simuler la décomposition de la tâche avec estimations de temps
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
                                $subTaskTitle = "$subTaskTitle [⏱️ 2 h]"
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

    It "Devrait décomposer une tâche en sous-tâches sans estimations de temps" {
        # Appeler le script
        & $granModePath -FilePath $testRoadmapPath -TaskIdentifier "1.3" -SubTasksInput "Analyser les besoins`nConcevoir la solution" -WhatIf

        # Vérifier que la fonction Invoke-RoadmapGranularization a été appelée
        Should -Invoke Invoke-RoadmapGranularization -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq $testRoadmapPath -and
            $TaskIdentifier -eq "1.3" -and
            $SubTasksInput -match "Analyser les besoins"
        }
    }

    It "Devrait décomposer une tâche en sous-tâches avec estimations de temps" {
        # Appeler le script
        & $granModePath -FilePath $testRoadmapPath -TaskIdentifier "1.3" -SubTasksInput "Analyser les besoins`nConcevoir la solution" -AddTimeEstimation -WhatIf

        # Vérifier que la fonction Invoke-RoadmapGranularizationWithTimeEstimation a été appelée
        Should -Invoke Invoke-RoadmapGranularizationWithTimeEstimation -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq $testRoadmapPath -and
            $TaskIdentifier -eq "1.3" -and
            $SubTasksInput -match "Analyser les besoins" -and
            $AddTimeEstimation -eq $true
        }
    }

    It "Devrait décomposer une tâche en sous-tâches avec estimations de temps et un domaine spécifique" {
        # Appeler le script
        & $granModePath -FilePath $testRoadmapPath -TaskIdentifier "1.3" -SubTasksInput "Analyser les besoins`nConcevoir la solution" -AddTimeEstimation -Domain "Backend" -WhatIf

        # Vérifier que la fonction Invoke-RoadmapGranularizationWithTimeEstimation a été appelée
        Should -Invoke Invoke-RoadmapGranularizationWithTimeEstimation -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq $testRoadmapPath -and
            $TaskIdentifier -eq "1.3" -and
            $SubTasksInput -match "Analyser les besoins" -and
            $AddTimeEstimation -eq $true -and
            $Domain -eq "Backend"
        }
    }

    It "Devrait décomposer une tâche en sous-tâches avec l'IA" {
        # Appeler le script
        & $granModePath -FilePath $testRoadmapPath -TaskIdentifier "1.3" -UseAI -WhatIf

        # Vérifier que la fonction Invoke-RestMethod a été appelée (pour l'API OpenAI)
        Should -Invoke Invoke-RestMethod -Times 1 -Exactly
    }

    It "Devrait décomposer une tâche en sous-tâches avec l'IA et des estimations de temps" {
        # Appeler le script
        & $granModePath -FilePath $testRoadmapPath -TaskIdentifier "1.3" -UseAI -AddTimeEstimation -WhatIf

        # Vérifier que la fonction Invoke-RestMethod a été appelée (pour l'API OpenAI)
        Should -Invoke Invoke-RestMethod -Times 1 -Exactly

        # Vérifier que la fonction Invoke-RoadmapGranularizationWithTimeEstimation a été appelée
        Should -Invoke Invoke-RoadmapGranularizationWithTimeEstimation -Times 1 -Exactly -ParameterFilter {
            $AddTimeEstimation -eq $true
        }
    }
}

# Exécuter les tests si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Invoke-Pester -Script $MyInvocation.MyCommand.Path
}
