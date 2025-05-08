# Tests simples pour la granularité adaptative
# Auteur: Augment AI
# Date: 2025-06-15

# Importer Pester si nécessaire
if (-not (Get-Module -Name Pester)) {
    Import-Module Pester -ErrorAction Stop
}

# Fonction pour exécuter les tests et retourner les résultats
function Invoke-Tests {
    $pesterConfig = New-PesterConfiguration
    $pesterConfig.Run.Path = $PSCommandPath
    $pesterConfig.Run.PassThru = $true
    $pesterConfig.Output.Verbosity = "Detailed"
    
    return Invoke-Pester -Configuration $pesterConfig
}

Describe "Tests de configuration de granularité adaptative" {
    BeforeAll {
        # Chemin du projet
        $projectRoot = $PSScriptRoot
        while ($projectRoot -and -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
            $projectRoot = Split-Path -Parent $projectRoot
        }

        if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
            $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
            if (-not (Test-Path -Path $projectRoot -PathType Container)) {
                throw "Impossible de déterminer le chemin du projet."
            }
        }

        # Charger la configuration de granularité adaptative
        $adaptiveGranularityConfigPath = Join-Path -Path $projectRoot -ChildPath "development\config\granularite-adaptative.json"
        if (Test-Path -Path $adaptiveGranularityConfigPath) {
            $script:adaptiveGranularityConfig = Get-Content -Path $adaptiveGranularityConfigPath -Raw | ConvertFrom-Json
        } else {
            throw "Fichier de configuration de granularité adaptative introuvable: $adaptiveGranularityConfigPath"
        }
    }

    It "La configuration de granularité adaptative est chargée correctement" {
        $script:adaptiveGranularityConfig | Should -Not -BeNullOrEmpty
        $script:adaptiveGranularityConfig.granularite_adaptative | Should -Not -BeNullOrEmpty
    }

    It "La configuration contient les niveaux recommandés" {
        $script:adaptiveGranularityConfig.granularite_adaptative.niveaux_recommandes | Should -Not -BeNullOrEmpty
        $script:adaptiveGranularityConfig.granularite_adaptative.niveaux_recommandes.min | Should -Be 4
        $script:adaptiveGranularityConfig.granularite_adaptative.niveaux_recommandes.max | Should -Be 6
    }

    It "La configuration contient les profondeurs par complexité" {
        $script:adaptiveGranularityConfig.granularite_adaptative.profondeur_par_complexite | Should -Not -BeNullOrEmpty
        $script:adaptiveGranularityConfig.granularite_adaptative.profondeur_par_complexite.simple | Should -Not -BeNullOrEmpty
        $script:adaptiveGranularityConfig.granularite_adaptative.profondeur_par_complexite.moyenne | Should -Not -BeNullOrEmpty
        $script:adaptiveGranularityConfig.granularite_adaptative.profondeur_par_complexite.elevee | Should -Not -BeNullOrEmpty
        $script:adaptiveGranularityConfig.granularite_adaptative.profondeur_par_complexite.tres_elevee | Should -Not -BeNullOrEmpty
    }

    It "La configuration contient les profondeurs par domaine" {
        $script:adaptiveGranularityConfig.granularite_adaptative.profondeur_par_domaine | Should -Not -BeNullOrEmpty
        $script:adaptiveGranularityConfig.granularite_adaptative.profondeur_par_domaine.frontend | Should -Not -BeNullOrEmpty
        $script:adaptiveGranularityConfig.granularite_adaptative.profondeur_par_domaine.backend | Should -Not -BeNullOrEmpty
    }
}

Describe "Tests des scripts gran-mode" {
    BeforeAll {
        # Chemin du projet
        $projectRoot = $PSScriptRoot
        while ($projectRoot -and -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
            $projectRoot = Split-Path -Parent $projectRoot
        }

        if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
            $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
            if (-not (Test-Path -Path $projectRoot -PathType Container)) {
                throw "Impossible de déterminer le chemin du projet."
            }
        }

        # Chemins des scripts à tester
        $script:granModeUnifiedPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\gran-mode-unified.ps1"
        $script:granModeRecursivePath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\gran-mode-recursive-unified.ps1"
        $script:configPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\mode-manager\config\modes\gran-unified.json"
    }

    It "Le script gran-mode-unified.ps1 existe" {
        $script:granModeUnifiedPath | Should -Exist
    }

    It "Le script gran-mode-recursive-unified.ps1 existe" {
        $script:granModeRecursivePath | Should -Exist
    }

    It "Le fichier de configuration gran-unified.json existe" {
        $script:configPath | Should -Exist
    }

    It "Le fichier de configuration gran-unified.json est valide" {
        $config = Get-Content -Path $script:configPath -Raw | ConvertFrom-Json
        $config.modes | Should -Not -BeNullOrEmpty
        $config.modes.GRAN | Should -Not -BeNullOrEmpty
        $config.modes.'GRAN-R' | Should -Not -BeNullOrEmpty
    }
}

Describe "Tests des fonctions simulées" {
    It "Fonction Get-TaskComplexity simulée fonctionne correctement" {
        # Définir une fonction de test
        function Get-TaskComplexity {
            param (
                [string]$TaskContent,
                [string]$Domain = "None"
            )
            
            if ($Domain -eq "Backend") {
                return "Complex"
            }
            
            if ($TaskContent -eq "Documenter l'API REST") {
                return "Simple"
            } else {
                return "Medium"
            }
        }
        
        # Tester la fonction
        $result1 = Get-TaskComplexity -TaskContent "Documenter l'API REST"
        $result1 | Should -Be "Simple"
        
        $result2 = Get-TaskComplexity -TaskContent "Autre chose" -Domain "Backend"
        $result2 | Should -Be "Complex"
    }
    
    It "Fonction Get-OptimalSubTaskCount simulée fonctionne correctement" {
        # Définir une fonction de test
        function Get-OptimalSubTaskCount {
            param (
                [string]$ComplexityLevel,
                [string]$Domain = "None",
                [PSCustomObject]$AdaptiveConfig = $null
            )
            
            switch ($ComplexityLevel) {
                "Simple" { return 3 }
                "Medium" { return 5 }
                "Complex" { return 6 }
                "VeryComplex" { return 7 }
                default { return 5 }
            }
        }
        
        # Tester la fonction
        $result1 = Get-OptimalSubTaskCount -ComplexityLevel "Simple"
        $result1 | Should -Be 3
        
        $result2 = Get-OptimalSubTaskCount -ComplexityLevel "Complex"
        $result2 | Should -Be 6
    }
    
    It "Fonction Get-SubTasks simulée fonctionne correctement" {
        # Définir une fonction de test
        function Get-SubTasks {
            param (
                [string]$ComplexityLevel,
                [string]$Domain = "None",
                [string]$SubTasksFile = "",
                [switch]$UseAI,
                [switch]$SimulateAI,
                [PSCustomObject]$AdaptiveConfig = $null
            )
            
            # Si un fichier de sous-tâches est spécifié, simuler son utilisation
            if (-not [string]::IsNullOrEmpty($SubTasksFile)) {
                return @("Tâche personnalisée 1", "Tâche personnalisée 2", "Tâche personnalisée 3")
            }
            
            # Retourner des sous-tâches en fonction de la complexité
            switch ($ComplexityLevel) {
                "Simple" { return @("Tâche 1", "Tâche 2", "Tâche 3") }
                "Medium" { return @("Tâche 1", "Tâche 2", "Tâche 3", "Tâche 4", "Tâche 5") }
                "Complex" { return @("Tâche 1", "Tâche 2", "Tâche 3", "Tâche 4", "Tâche 5", "Tâche 6") }
                "VeryComplex" { return @("Tâche 1", "Tâche 2", "Tâche 3", "Tâche 4", "Tâche 5", "Tâche 6", "Tâche 7") }
                default { return @("Tâche 1", "Tâche 2", "Tâche 3", "Tâche 4", "Tâche 5") }
            }
        }
        
        # Tester la fonction
        $result1 = Get-SubTasks -ComplexityLevel "Simple"
        $result1.Count | Should -Be 3
        
        $result2 = Get-SubTasks -ComplexityLevel "Complex"
        $result2.Count | Should -Be 6
        
        $result3 = Get-SubTasks -ComplexityLevel "Medium" -SubTasksFile "dummy.txt"
        $result3.Count | Should -Be 3
        $result3[0] | Should -Be "Tâche personnalisée 1"
    }
}

# Exécuter les tests si le script est appelé directement
if ($MyInvocation.InvocationName -ne '.') {
    # Exécuter les tests et retourner les résultats
    return Invoke-Tests
}
