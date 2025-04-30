<#
.SYNOPSIS
    Tests unitaires pour la fonction Get-AIGeneratedSubTasks.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Get-AIGeneratedSubTasks
    qui permet de générer des sous-tâches à l'aide de l'IA.

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
}

# Chemin vers le script à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$granModePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "modes\gran-mode.ps1"

# Vérifier si le fichier existe
if (-not (Test-Path -Path $granModePath)) {
    throw "Le fichier gran-mode.ps1 est introuvable à l'emplacement : $granModePath"
}

# Extraire la fonction Get-AIGeneratedSubTasks du script
$content = Get-Content -Path $granModePath -Raw
$functionMatch = [regex]::Match($content, '(?s)function Get-AIGeneratedSubTasks\s*\{.*?\n\}')
if (-not $functionMatch.Success) {
    throw "La fonction Get-AIGeneratedSubTasks n'a pas été trouvée dans le fichier gran-mode.ps1"
}

# Évaluer la fonction pour la rendre disponible dans ce script
$functionCode = $functionMatch.Value
Invoke-Expression $functionCode

# Créer un fichier temporaire pour les tests
$testConfigPath = Join-Path -Path $env:TEMP -ChildPath "ai-config_$(Get-Random).json"

# Vérifier que le répertoire temporaire existe
if (-not (Test-Path -Path $env:TEMP)) {
    throw "Le répertoire temporaire $env:TEMP n'existe pas."
}

# Afficher le chemin du fichier temporaire pour le débogage
Write-Host "Fichier de configuration temporaire : $testConfigPath"

Describe "Get-AIGeneratedSubTasks" {
    BeforeEach {
        # Créer un fichier de configuration de test
        @"
{
  "enabled": true,
  "api_key_env_var": "OPENAI_API_KEY",
  "model": "gpt-3.5-turbo",
  "temperature": 0.7,
  "max_tokens": 1000,
  "prompt_template": "Je dois décomposer une tâche de développement en sous-tâches. Voici les informations :\n\nTâche principale : {task}\nNiveau de complexité : {complexity}\nDomaines techniques : {domains}\nNombre maximum de sous-tâches : {max_subtasks}\n\nGénère une liste de sous-tâches pertinentes pour cette tâche, en tenant compte du niveau de complexité et des domaines techniques. Chaque sous-tâche doit être concise et commencer par un verbe d'action. N'inclus pas de numéros ou de tirets au début des lignes. Limite-toi à {max_subtasks} sous-tâches maximum. Retourne uniquement la liste des sous-tâches, une par ligne."
}
"@ | Set-Content -Path $testConfigPath -Encoding UTF8

        # Créer un mock pour la fonction Join-Path
        Mock Join-Path {
            param($Path, $ChildPath)
            if ($ChildPath -eq "development\templates\subtasks\ai-config.json") {
                return $testConfigPath
            } else {
                # Utiliser la fonction originale pour les autres cas
                $originalJoinPath = Get-Command Join-Path -CommandType Cmdlet
                & $originalJoinPath -Path $Path -ChildPath $ChildPath
            }
        }

        # Créer un mock pour la fonction Get-Content
        Mock Get-Content {
            if ($Path -eq $testConfigPath) {
                return Get-Content -Path $testConfigPath -Raw
            } else {
                return Microsoft.PowerShell.Management\Get-Content -Path $Path
            }
        }

        # Créer un mock pour la fonction [Environment]::GetEnvironmentVariable
        Mock [Environment]::GetEnvironmentVariable {
            if ($args[0] -eq "OPENAI_API_KEY") {
                return "sk-fake-api-key-for-testing"
            } else {
                return $null
            }
        }

        # Créer un mock pour la fonction Invoke-RestMethod
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
    }

    AfterEach {
        # Supprimer le fichier temporaire
        if ($testConfigPath -and (Test-Path -Path $testConfigPath)) {
            Remove-Item -Path $testConfigPath -Force
        }
    }

    It "Devrait retourner null si le fichier de configuration n'existe pas" {
        # Supprimer le fichier de configuration
        if ($testConfigPath -and (Test-Path -Path $testConfigPath)) {
            Remove-Item -Path $testConfigPath -Force
        }

        # Appeler la fonction
        $result = Get-AIGeneratedSubTasks -TaskContent "Implémenter un système d'authentification" -ComplexityLevel "Medium" -MaxSubTasks 5 -ProjectRoot "C:\Temp"

        # Vérifier le résultat
        $result | Should -Be $null
    }

    It "Devrait retourner null si l'IA est désactivée dans la configuration" {
        # Modifier la configuration pour désactiver l'IA
        $config = Get-Content -Path $testConfigPath -Raw | ConvertFrom-Json
        $config.enabled = $false
        $config | ConvertTo-Json | Set-Content -Path $testConfigPath -Encoding UTF8

        # Appeler la fonction
        $result = Get-AIGeneratedSubTasks -TaskContent "Implémenter un système d'authentification" -ComplexityLevel "Medium" -MaxSubTasks 5 -ProjectRoot "C:\Temp"

        # Vérifier le résultat
        $result | Should -Be $null
    }

    It "Devrait retourner null si la clé API n'est pas définie" {
        # Modifier le mock pour simuler une clé API non définie
        Mock [Environment]::GetEnvironmentVariable {
            return $null
        }

        # Appeler la fonction
        $result = Get-AIGeneratedSubTasks -TaskContent "Implémenter un système d'authentification" -ComplexityLevel "Medium" -MaxSubTasks 5 -ProjectRoot "C:\Temp"

        # Vérifier le résultat
        $result | Should -Be $null
    }

    It "Devrait générer des sous-tâches à partir de l'IA" {
        # Appeler la fonction
        $result = Get-AIGeneratedSubTasks -TaskContent "Implémenter un système d'authentification" -ComplexityLevel "Medium" -MaxSubTasks 5 -ProjectRoot "C:\Temp"

        # Vérifier le résultat
        $result | Should -Not -Be $null
        $result.Content | Should -Not -Be $null
        $result.Level | Should -Be "ai"
        $result.AI | Should -Be $true
        $result.Combined | Should -Be $false
        $result.MaxSubTasks | Should -Be 5

        # Vérifier que le contenu contient les sous-tâches générées
        $result.Content | Should -Match "Analyser les besoins du système"
        $result.Content | Should -Match "Concevoir l'architecture"
        $result.Content | Should -Match "Développer le module d'authentification"
        $result.Content | Should -Match "Intégrer avec la base de données"
        $result.Content | Should -Match "Tester les fonctionnalités"
    }

    It "Devrait limiter le nombre de sous-tâches au maximum spécifié" {
        # Modifier le mock pour simuler une réponse avec plus de sous-tâches que le maximum
        Mock Invoke-RestMethod {
            # Simuler une réponse de l'API OpenAI avec plus de sous-tâches
            return @{
                choices = @(
                    @{
                        message = @{
                            content = "Analyser les besoins du système`nConcevoir l'architecture`nDévelopper le module d'authentification`nIntégrer avec la base de données`nTester les fonctionnalités`nDocumenter l'API`nOptimiser les performances`nDéployer en production"
                        }
                    }
                )
            }
        }

        # Appeler la fonction avec un maximum de 3 sous-tâches
        $result = Get-AIGeneratedSubTasks -TaskContent "Implémenter un système d'authentification" -ComplexityLevel "Medium" -MaxSubTasks 3 -ProjectRoot "C:\Temp"

        # Vérifier le résultat
        $result | Should -Not -Be $null
        $result.Content | Should -Not -Be $null

        # Compter le nombre de sous-tâches
        $subTasks = $result.Content -split "`r`n"
        $subTasks.Count | Should -Be 3
    }

    It "Devrait nettoyer les sous-tâches générées (supprimer les numéros, tirets, etc.)" {
        # Modifier le mock pour simuler une réponse avec des numéros et des tirets
        Mock Invoke-RestMethod {
            # Simuler une réponse de l'API OpenAI avec des numéros et des tirets
            return @{
                choices = @(
                    @{
                        message = @{
                            content = "1. Analyser les besoins du système`n2. Concevoir l'architecture`n- Développer le module d'authentification`n- Intégrer avec la base de données`n3. Tester les fonctionnalités"
                        }
                    }
                )
            }
        }

        # Appeler la fonction
        $result = Get-AIGeneratedSubTasks -TaskContent "Implémenter un système d'authentification" -ComplexityLevel "Medium" -MaxSubTasks 5 -ProjectRoot "C:\Temp"

        # Vérifier le résultat
        $result | Should -Not -Be $null
        $result.Content | Should -Not -Be $null

        # Vérifier que les numéros et les tirets ont été supprimés
        $result.Content | Should -Not -Match "^1\."
        $result.Content | Should -Not -Match "^2\."
        $result.Content | Should -Not -Match "^3\."
        $result.Content | Should -Not -Match "^-"

        # Vérifier que le contenu contient les sous-tâches nettoyées
        $result.Content | Should -Match "Analyser les besoins du système"
        $result.Content | Should -Match "Concevoir l'architecture"
        $result.Content | Should -Match "Développer le module d'authentification"
        $result.Content | Should -Match "Intégrer avec la base de données"
        $result.Content | Should -Match "Tester les fonctionnalités"
    }

    It "Devrait gérer correctement les domaines spécifiés" {
        # Appeler la fonction avec des domaines spécifiés
        $result = Get-AIGeneratedSubTasks -TaskContent "Implémenter un système d'authentification" -ComplexityLevel "Medium" -Domains @("Frontend", "Backend") -MaxSubTasks 5 -ProjectRoot "C:\Temp"

        # Vérifier le résultat
        $result | Should -Not -Be $null
        $result.Domain | Should -Be "Frontend"
        $result.Domains | Should -Contain "Frontend"
        $result.Domains | Should -Contain "Backend"
        $result.Description | Should -Match "Frontend"
        $result.Description | Should -Match "Backend"
    }

    It "Devrait gérer correctement l'erreur lors de l'appel à l'API" {
        # Modifier le mock pour simuler une erreur lors de l'appel à l'API
        Mock Invoke-RestMethod {
            throw "Erreur de connexion à l'API"
        }

        # Appeler la fonction
        $result = Get-AIGeneratedSubTasks -TaskContent "Implémenter un système d'authentification" -ComplexityLevel "Medium" -MaxSubTasks 5 -ProjectRoot "C:\Temp"

        # Vérifier le résultat
        $result | Should -Be $null
    }
}

# Exécuter les tests si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Invoke-Pester -Script $MyInvocation.MyCommand.Path
}
