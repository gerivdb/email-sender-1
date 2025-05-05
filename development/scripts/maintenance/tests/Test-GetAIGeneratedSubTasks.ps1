<#
.SYNOPSIS
    Tests unitaires pour la fonction Get-AIGeneratedSubTasks.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Get-AIGeneratedSubTasks
    qui permet de gÃ©nÃ©rer des sous-tÃ¢ches Ã  l'aide de l'IA.

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
}

# Chemin vers le script Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$granModePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "modes\gran-mode.ps1"

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $granModePath)) {
    throw "Le fichier gran-mode.ps1 est introuvable Ã  l'emplacement : $granModePath"
}

# Extraire la fonction Get-AIGeneratedSubTasks du script
$content = Get-Content -Path $granModePath -Raw
$functionMatch = [regex]::Match($content, '(?s)function Get-AIGeneratedSubTasks\s*\{.*?\n\}')
if (-not $functionMatch.Success) {
    throw "La fonction Get-AIGeneratedSubTasks n'a pas Ã©tÃ© trouvÃ©e dans le fichier gran-mode.ps1"
}

# Ã‰valuer la fonction pour la rendre disponible dans ce script
$functionCode = $functionMatch.Value
Invoke-Expression $functionCode

# CrÃ©er un fichier temporaire pour les tests
$testConfigPath = Join-Path -Path $env:TEMP -ChildPath "ai-config_$(Get-Random).json"

# VÃ©rifier que le rÃ©pertoire temporaire existe
if (-not (Test-Path -Path $env:TEMP)) {
    throw "Le rÃ©pertoire temporaire $env:TEMP n'existe pas."
}

# Afficher le chemin du fichier temporaire pour le dÃ©bogage
Write-Host "Fichier de configuration temporaire : $testConfigPath"

Describe "Get-AIGeneratedSubTasks" {
    BeforeEach {
        # CrÃ©er un fichier de configuration de test
        @"
{
  "enabled": true,
  "api_key_env_var": "OPENAI_API_KEY",
  "model": "gpt-3.5-turbo",
  "temperature": 0.7,
  "max_tokens": 1000,
  "prompt_template": "Je dois dÃ©composer une tÃ¢che de dÃ©veloppement en sous-tÃ¢ches. Voici les informations :\n\nTÃ¢che principale : {task}\nNiveau de complexitÃ© : {complexity}\nDomaines techniques : {domains}\nNombre maximum de sous-tÃ¢ches : {max_subtasks}\n\nGÃ©nÃ¨re une liste de sous-tÃ¢ches pertinentes pour cette tÃ¢che, en tenant compte du niveau de complexitÃ© et des domaines techniques. Chaque sous-tÃ¢che doit Ãªtre concise et commencer par un verbe d'action. N'inclus pas de numÃ©ros ou de tirets au dÃ©but des lignes. Limite-toi Ã  {max_subtasks} sous-tÃ¢ches maximum. Retourne uniquement la liste des sous-tÃ¢ches, une par ligne."
}
"@ | Set-Content -Path $testConfigPath -Encoding UTF8

        # CrÃ©er un mock pour la fonction Join-Path
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

        # CrÃ©er un mock pour la fonction Get-Content
        Mock Get-Content {
            if ($Path -eq $testConfigPath) {
                return Get-Content -Path $testConfigPath -Raw
            } else {
                return Microsoft.PowerShell.Management\Get-Content -Path $Path
            }
        }

        # CrÃ©er un mock pour la fonction [Environment]::GetEnvironmentVariable
        Mock [Environment]::GetEnvironmentVariable {
            if ($args[0] -eq "OPENAI_API_KEY") {
                return "sk-fake-api-key-for-testing"
            } else {
                return $null
            }
        }

        # CrÃ©er un mock pour la fonction Invoke-RestMethod
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
        $result = Get-AIGeneratedSubTasks -TaskContent "ImplÃ©menter un systÃ¨me d'authentification" -ComplexityLevel "Medium" -MaxSubTasks 5 -ProjectRoot "C:\Temp"

        # VÃ©rifier le rÃ©sultat
        $result | Should -Be $null
    }

    It "Devrait retourner null si l'IA est dÃ©sactivÃ©e dans la configuration" {
        # Modifier la configuration pour dÃ©sactiver l'IA
        $config = Get-Content -Path $testConfigPath -Raw | ConvertFrom-Json
        $config.enabled = $false
        $config | ConvertTo-Json | Set-Content -Path $testConfigPath -Encoding UTF8

        # Appeler la fonction
        $result = Get-AIGeneratedSubTasks -TaskContent "ImplÃ©menter un systÃ¨me d'authentification" -ComplexityLevel "Medium" -MaxSubTasks 5 -ProjectRoot "C:\Temp"

        # VÃ©rifier le rÃ©sultat
        $result | Should -Be $null
    }

    It "Devrait retourner null si la clÃ© API n'est pas dÃ©finie" {
        # Modifier le mock pour simuler une clÃ© API non dÃ©finie
        Mock [Environment]::GetEnvironmentVariable {
            return $null
        }

        # Appeler la fonction
        $result = Get-AIGeneratedSubTasks -TaskContent "ImplÃ©menter un systÃ¨me d'authentification" -ComplexityLevel "Medium" -MaxSubTasks 5 -ProjectRoot "C:\Temp"

        # VÃ©rifier le rÃ©sultat
        $result | Should -Be $null
    }

    It "Devrait gÃ©nÃ©rer des sous-tÃ¢ches Ã  partir de l'IA" {
        # Appeler la fonction
        $result = Get-AIGeneratedSubTasks -TaskContent "ImplÃ©menter un systÃ¨me d'authentification" -ComplexityLevel "Medium" -MaxSubTasks 5 -ProjectRoot "C:\Temp"

        # VÃ©rifier le rÃ©sultat
        $result | Should -Not -Be $null
        $result.Content | Should -Not -Be $null
        $result.Level | Should -Be "ai"
        $result.AI | Should -Be $true
        $result.Combined | Should -Be $false
        $result.MaxSubTasks | Should -Be 5

        # VÃ©rifier que le contenu contient les sous-tÃ¢ches gÃ©nÃ©rÃ©es
        $result.Content | Should -Match "Analyser les besoins du systÃ¨me"
        $result.Content | Should -Match "Concevoir l'architecture"
        $result.Content | Should -Match "DÃ©velopper le module d'authentification"
        $result.Content | Should -Match "IntÃ©grer avec la base de donnÃ©es"
        $result.Content | Should -Match "Tester les fonctionnalitÃ©s"
    }

    It "Devrait limiter le nombre de sous-tÃ¢ches au maximum spÃ©cifiÃ©" {
        # Modifier le mock pour simuler une rÃ©ponse avec plus de sous-tÃ¢ches que le maximum
        Mock Invoke-RestMethod {
            # Simuler une rÃ©ponse de l'API OpenAI avec plus de sous-tÃ¢ches
            return @{
                choices = @(
                    @{
                        message = @{
                            content = "Analyser les besoins du systÃ¨me`nConcevoir l'architecture`nDÃ©velopper le module d'authentification`nIntÃ©grer avec la base de donnÃ©es`nTester les fonctionnalitÃ©s`nDocumenter l'API`nOptimiser les performances`nDÃ©ployer en production"
                        }
                    }
                )
            }
        }

        # Appeler la fonction avec un maximum de 3 sous-tÃ¢ches
        $result = Get-AIGeneratedSubTasks -TaskContent "ImplÃ©menter un systÃ¨me d'authentification" -ComplexityLevel "Medium" -MaxSubTasks 3 -ProjectRoot "C:\Temp"

        # VÃ©rifier le rÃ©sultat
        $result | Should -Not -Be $null
        $result.Content | Should -Not -Be $null

        # Compter le nombre de sous-tÃ¢ches
        $subTasks = $result.Content -split "`r`n"
        $subTasks.Count | Should -Be 3
    }

    It "Devrait nettoyer les sous-tÃ¢ches gÃ©nÃ©rÃ©es (supprimer les numÃ©ros, tirets, etc.)" {
        # Modifier le mock pour simuler une rÃ©ponse avec des numÃ©ros et des tirets
        Mock Invoke-RestMethod {
            # Simuler une rÃ©ponse de l'API OpenAI avec des numÃ©ros et des tirets
            return @{
                choices = @(
                    @{
                        message = @{
                            content = "1. Analyser les besoins du systÃ¨me`n2. Concevoir l'architecture`n- DÃ©velopper le module d'authentification`n- IntÃ©grer avec la base de donnÃ©es`n3. Tester les fonctionnalitÃ©s"
                        }
                    }
                )
            }
        }

        # Appeler la fonction
        $result = Get-AIGeneratedSubTasks -TaskContent "ImplÃ©menter un systÃ¨me d'authentification" -ComplexityLevel "Medium" -MaxSubTasks 5 -ProjectRoot "C:\Temp"

        # VÃ©rifier le rÃ©sultat
        $result | Should -Not -Be $null
        $result.Content | Should -Not -Be $null

        # VÃ©rifier que les numÃ©ros et les tirets ont Ã©tÃ© supprimÃ©s
        $result.Content | Should -Not -Match "^1\."
        $result.Content | Should -Not -Match "^2\."
        $result.Content | Should -Not -Match "^3\."
        $result.Content | Should -Not -Match "^-"

        # VÃ©rifier que le contenu contient les sous-tÃ¢ches nettoyÃ©es
        $result.Content | Should -Match "Analyser les besoins du systÃ¨me"
        $result.Content | Should -Match "Concevoir l'architecture"
        $result.Content | Should -Match "DÃ©velopper le module d'authentification"
        $result.Content | Should -Match "IntÃ©grer avec la base de donnÃ©es"
        $result.Content | Should -Match "Tester les fonctionnalitÃ©s"
    }

    It "Devrait gÃ©rer correctement les domaines spÃ©cifiÃ©s" {
        # Appeler la fonction avec des domaines spÃ©cifiÃ©s
        $result = Get-AIGeneratedSubTasks -TaskContent "ImplÃ©menter un systÃ¨me d'authentification" -ComplexityLevel "Medium" -Domains @("Frontend", "Backend") -MaxSubTasks 5 -ProjectRoot "C:\Temp"

        # VÃ©rifier le rÃ©sultat
        $result | Should -Not -Be $null
        $result.Domain | Should -Be "Frontend"
        $result.Domains | Should -Contain "Frontend"
        $result.Domains | Should -Contain "Backend"
        $result.Description | Should -Match "Frontend"
        $result.Description | Should -Match "Backend"
    }

    It "Devrait gÃ©rer correctement l'erreur lors de l'appel Ã  l'API" {
        # Modifier le mock pour simuler une erreur lors de l'appel Ã  l'API
        Mock Invoke-RestMethod {
            throw "Erreur de connexion Ã  l'API"
        }

        # Appeler la fonction
        $result = Get-AIGeneratedSubTasks -TaskContent "ImplÃ©menter un systÃ¨me d'authentification" -ComplexityLevel "Medium" -MaxSubTasks 5 -ProjectRoot "C:\Temp"

        # VÃ©rifier le rÃ©sultat
        $result | Should -Be $null
    }
}

# ExÃ©cuter les tests si le script est exÃ©cutÃ© directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Invoke-Pester -Script $MyInvocation.MyCommand.Path
}
