<#
.SYNOPSIS
    Tests unitaires pour la fonctionnalité d'apprentissage adaptatif du système d'apprentissage des erreurs.
.DESCRIPTION
    Ce script contient des tests unitaires pour la fonctionnalité d'apprentissage adaptatif du système d'apprentissage des erreurs.
.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date création:  09/04/2025
#>

# Définir les tests Pester
Describe "Tests d'apprentissage adaptatif" {
    BeforeAll {
        # Créer un répertoire temporaire pour les tests
        $script:testRoot = Join-Path -Path $env:TEMP -ChildPath "AdaptiveLearningTests"
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
        New-Item -Path $script:testRoot -ItemType Directory -Force | Out-Null
        
        # Créer un fichier de modèle de correction
        $script:modelPath = Join-Path -Path $script:testRoot -ChildPath "correction-model.json"
        $modelContent = @"
{
    "Metadata": {
        "Version": "1.0",
        "CreationDate": "$(Get-Date -Format 'yyyy-MM-dd')",
        "LastUpdated": "$(Get-Date -Format 'yyyy-MM-dd')"
    },
    "Patterns": [
        {
            "ErrorType": "HardcodedPath",
            "Pattern": "['\"](D|C|E):\\\\[^'\"]+['\"]",
            "Replacement": "(Join-Path -Path `$PSScriptRoot -ChildPath \"CHEMIN_RELATIF\")",
            "Description": "Remplace les chemins codés en dur par des chemins relatifs"
        },
        {
            "ErrorType": "NoErrorHandling",
            "Pattern": "(Get-Content|Invoke-RestMethod|Invoke-WebRequest)(?!\\s+-ErrorAction)",
            "Replacement": "`$1 -ErrorAction Stop",
            "Description": "Ajoute une gestion d'erreurs aux cmdlets qui peuvent échouer"
        },
        {
            "ErrorType": "ObsoleteCmdlet",
            "Pattern": "Get-WmiObject",
            "Replacement": "Get-CimInstance",
            "Description": "Remplace les cmdlets obsolètes par des cmdlets modernes"
        }
    ]
}
"@
        Set-Content -Path $script:modelPath -Value $modelContent
        
        # Créer un script avec des erreurs
        $script:scriptPath = Join-Path -Path $script:testRoot -ChildPath "TestScript.ps1"
        $scriptContent = @"
# Script de test avec plusieurs problèmes
`$logPath = "D:\Logs\app.log"
Write-Host "Log Path: `$logPath"

# Absence de gestion d'erreurs
`$content = Get-Content -Path "C:\config.txt"

# Utilisation de cmdlet obsolète
`$processes = Get-WmiObject -Class Win32_Process
"@
        Set-Content -Path $script:scriptPath -Value $scriptContent
    }
    
    Context "Chargement et application du modèle de correction" {
        It "Devrait charger un modèle de correction" {
            # Charger le modèle de correction
            $model = Get-Content -Path $script:modelPath -Raw | ConvertFrom-Json
            
            # Vérifier que le modèle a été chargé correctement
            $model | Should -Not -BeNullOrEmpty
            $model.Metadata | Should -Not -BeNullOrEmpty
            $model.Patterns | Should -Not -BeNullOrEmpty
            $model.Patterns.Count | Should -Be 3
        }
        
        It "Devrait identifier les erreurs dans un script" {
            # Lire le contenu du script
            $scriptContent = Get-Content -Path $script:scriptPath -Raw
            
            # Charger le modèle de correction
            $model = Get-Content -Path $script:modelPath -Raw | ConvertFrom-Json
            
            # Identifier les erreurs
            $errors = @()
            foreach ($pattern in $model.Patterns) {
                if ($scriptContent -match $pattern.Pattern) {
                    $errors += $pattern.ErrorType
                }
            }
            
            # Vérifier que les erreurs ont été identifiées correctement
            $errors | Should -Not -BeNullOrEmpty
            $errors.Count | Should -Be 3
            $errors | Should -Contain "HardcodedPath"
            $errors | Should -Contain "NoErrorHandling"
            $errors | Should -Contain "ObsoleteCmdlet"
        }
        
        It "Devrait appliquer des corrections à un script" {
            # Lire le contenu du script
            $scriptContent = Get-Content -Path $script:scriptPath -Raw
            
            # Charger le modèle de correction
            $model = Get-Content -Path $script:modelPath -Raw | ConvertFrom-Json
            
            # Appliquer les corrections
            $correctedContent = $scriptContent
            foreach ($pattern in $model.Patterns) {
                $correctedContent = $correctedContent -replace $pattern.Pattern, $pattern.Replacement
            }
            
            # Écrire le contenu corrigé dans un nouveau fichier
            $correctedPath = Join-Path -Path $script:testRoot -ChildPath "CorrectedScript.ps1"
            Set-Content -Path $correctedPath -Value $correctedContent
            
            # Vérifier que les corrections ont été appliquées correctement
            $correctedContent | Should -Not -Match "D:\\Logs\\app.log"
            $correctedContent | Should -Match "Join-Path"
            $correctedContent | Should -Match "Get-Content -ErrorAction Stop"
            $correctedContent | Should -Not -Match "Get-WmiObject"
            $correctedContent | Should -Match "Get-CimInstance"
        }
    }
    
    Context "Apprentissage à partir des erreurs" {
        It "Devrait apprendre de nouvelles corrections" {
            # Créer un nouveau modèle de correction
            $newModel = @{
                Metadata = @{
                    Version = "1.0"
                    CreationDate = (Get-Date -Format 'yyyy-MM-dd')
                    LastUpdated = (Get-Date -Format 'yyyy-MM-dd')
                }
                Patterns = @(
                    @{
                        ErrorType = "WriteHostUsage"
                        Pattern = "Write-Host\s+(.+)"
                        Replacement = "Write-Output `$1"
                        Description = "Remplace Write-Host par Write-Output"
                    }
                )
            }
            
            # Convertir le modèle en JSON
            $newModelJson = $newModel | ConvertTo-Json -Depth 3
            
            # Écrire le modèle dans un fichier
            $newModelPath = Join-Path -Path $script:testRoot -ChildPath "new-model.json"
            Set-Content -Path $newModelPath -Value $newModelJson
            
            # Charger le modèle
            $loadedModel = Get-Content -Path $newModelPath -Raw | ConvertFrom-Json
            
            # Vérifier que le modèle a été chargé correctement
            $loadedModel | Should -Not -BeNullOrEmpty
            $loadedModel.Patterns | Should -Not -BeNullOrEmpty
            $loadedModel.Patterns.Count | Should -Be 1
            $loadedModel.Patterns[0].ErrorType | Should -Be "WriteHostUsage"
            
            # Appliquer la correction au script
            $scriptContent = Get-Content -Path $script:scriptPath -Raw
            $correctedContent = $scriptContent -replace $loadedModel.Patterns[0].Pattern, $loadedModel.Patterns[0].Replacement
            
            # Vérifier que la correction a été appliquée correctement
            $correctedContent | Should -Not -Match "Write-Host"
            $correctedContent | Should -Match "Write-Output"
        }
        
        It "Devrait fusionner des modèles de correction" {
            # Charger les deux modèles
            $model1 = Get-Content -Path $script:modelPath -Raw | ConvertFrom-Json
            $model2Path = Join-Path -Path $script:testRoot -ChildPath "new-model.json"
            $model2 = Get-Content -Path $model2Path -Raw | ConvertFrom-Json
            
            # Fusionner les modèles
            $mergedModel = @{
                Metadata = @{
                    Version = "1.0"
                    CreationDate = $model1.Metadata.CreationDate
                    LastUpdated = (Get-Date -Format 'yyyy-MM-dd')
                }
                Patterns = @()
            }
            
            # Ajouter les patterns du premier modèle
            foreach ($pattern in $model1.Patterns) {
                $mergedModel.Patterns += $pattern
            }
            
            # Ajouter les patterns du deuxième modèle
            foreach ($pattern in $model2.Patterns) {
                # Vérifier si le pattern existe déjà
                $existingPattern = $mergedModel.Patterns | Where-Object { $_.ErrorType -eq $pattern.ErrorType }
                if (-not $existingPattern) {
                    $mergedModel.Patterns += $pattern
                }
            }
            
            # Convertir le modèle fusionné en JSON
            $mergedModelJson = $mergedModel | ConvertTo-Json -Depth 3
            
            # Écrire le modèle fusionné dans un fichier
            $mergedModelPath = Join-Path -Path $script:testRoot -ChildPath "merged-model.json"
            Set-Content -Path $mergedModelPath -Value $mergedModelJson
            
            # Charger le modèle fusionné
            $loadedMergedModel = Get-Content -Path $mergedModelPath -Raw | ConvertFrom-Json
            
            # Vérifier que le modèle fusionné a été créé correctement
            $loadedMergedModel | Should -Not -BeNullOrEmpty
            $loadedMergedModel.Patterns | Should -Not -BeNullOrEmpty
            $loadedMergedModel.Patterns.Count | Should -Be 4
            $loadedMergedModel.Patterns.ErrorType | Should -Contain "HardcodedPath"
            $loadedMergedModel.Patterns.ErrorType | Should -Contain "NoErrorHandling"
            $loadedMergedModel.Patterns.ErrorType | Should -Contain "ObsoleteCmdlet"
            $loadedMergedModel.Patterns.ErrorType | Should -Contain "WriteHostUsage"
        }
    }
    
    AfterAll {
        # Supprimer le répertoire de test
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
    }
}
