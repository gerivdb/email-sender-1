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

    # Vérifier que les fichiers existent
    if (-not (Test-Path -Path $script:granModeUnifiedPath)) {
        throw "Script gran-mode-unified.ps1 introuvable: $script:granModeUnifiedPath"
    }
    if (-not (Test-Path -Path $script:granModeRecursivePath)) {
        throw "Script gran-mode-recursive-unified.ps1 introuvable: $script:granModeRecursivePath"
    }
    if (-not (Test-Path -Path $script:configPath)) {
        throw "Fichier de configuration gran-unified.json introuvable: $script:configPath"
    }

    # Créer un fichier de roadmap temporaire pour les tests d'intégration
    $script:tempRoadmapPath = Join-Path -Path $TestDrive -ChildPath "test_roadmap_integration.md"
    @"
# Test Roadmap Integration

## 1. Section de test
- [ ] **1.1** Tâche simple de documentation
- [ ] **1.2** Tâche moyenne d'implémentation frontend
- [ ] **1.3** Tâche complexe d'algorithme backend
- [ ] **1.4** Tâche très complexe de système distribué
"@ | Set-Content -Path $script:tempRoadmapPath -Encoding UTF8
}

Describe "Tests d'intégration des scripts gran-mode" {
    It "Le script gran-mode-unified.ps1 existe et est valide" {
        $script:granModeUnifiedPath | Should -Exist
        { . $script:granModeUnifiedPath -FilePath $script:tempRoadmapPath -TaskIdentifier "1.1" -WhatIf } | Should -Not -Throw
    }

    It "Le script gran-mode-recursive-unified.ps1 existe et est valide" {
        $script:granModeRecursivePath | Should -Exist
        { . $script:granModeRecursivePath -FilePath $script:tempRoadmapPath -TaskIdentifier "1.1" -WhatIf } | Should -Not -Throw
    }

    It "Le fichier de configuration gran-unified.json est valide" {
        $script:configPath | Should -Exist
        $config = Get-Content -Path $script:configPath -Raw | ConvertFrom-Json
        $config.modes | Should -Not -BeNullOrEmpty
        $config.modes.GRAN | Should -Not -BeNullOrEmpty
        $config.modes.'GRAN-R' | Should -Not -BeNullOrEmpty
    }
}

Describe "Tests d'intégration avec le mode-manager" {
    BeforeEach {
        # Créer une copie du fichier de roadmap pour chaque test
        $script:testRoadmapPath = Join-Path -Path $TestDrive -ChildPath "test_roadmap_integration_copy.md"
        Copy-Item -Path $script:tempRoadmapPath -Destination $script:testRoadmapPath -Force
    }

    It "La configuration du mode GRAN est correcte" {
        $config = Get-Content -Path $script:configPath -Raw | ConvertFrom-Json
        $config.modes.GRAN.script | Should -Be "development\\scripts\\maintenance\\modes\\gran-mode-unified.ps1"
        $config.modes.GRAN.parameters.FilePath.required | Should -Be $true
        $config.modes.GRAN.parameters.TaskIdentifier.required | Should -Be $true
        $config.modes.GRAN.parameters.AdaptiveGranularity.default | Should -Be $true
    }

    It "La configuration du mode GRAN-R est correcte" {
        $config = Get-Content -Path $script:configPath -Raw | ConvertFrom-Json
        $config.modes.'GRAN-R'.script | Should -Be "development\\scripts\\maintenance\\modes\\gran-mode-recursive-unified.ps1"
        $config.modes.'GRAN-R'.parameters.FilePath.required | Should -Be $true
        $config.modes.'GRAN-R'.parameters.TaskIdentifier.required | Should -Be $true
        $config.modes.'GRAN-R'.parameters.RecursionDepth.default | Should -Be 2
        $config.modes.'GRAN-R'.parameters.AdaptiveGranularity.default | Should -Be $true
    }

    It "Les paramètres du mode GRAN sont cohérents avec le script" {
        $config = Get-Content -Path $script:configPath -Raw | ConvertFrom-Json
        $scriptContent = Get-Content -Path $script:granModeUnifiedPath -Raw
        
        # Vérifier que tous les paramètres obligatoires du script sont dans la configuration
        $paramMatches = [regex]::Matches($scriptContent, '\[Parameter\(Mandatory\s*=\s*\$true\)\]\s*\[([^\]]+)\]\$([A-Za-z0-9_]+)')
        foreach ($match in $paramMatches) {
            $paramName = $match.Groups[2].Value
            $config.modes.GRAN.parameters.$paramName.required | Should -Be $true
        }
    }

    It "Les paramètres du mode GRAN-R sont cohérents avec le script" {
        $config = Get-Content -Path $script:configPath -Raw | ConvertFrom-Json
        $scriptContent = Get-Content -Path $script:granModeRecursivePath -Raw
        
        # Vérifier que tous les paramètres obligatoires du script sont dans la configuration
        $paramMatches = [regex]::Matches($scriptContent, '\[Parameter\(Mandatory\s*=\s*\$true\)\]\s*\[([^\]]+)\]\$([A-Za-z0-9_]+)')
        foreach ($match in $paramMatches) {
            $paramName = $match.Groups[2].Value
            $config.modes.'GRAN-R'.parameters.$paramName.required | Should -Be $true
        }
    }
}

Describe "Tests d'intégration avec la configuration de granularité adaptative" {
    BeforeEach {
        # Créer une copie du fichier de roadmap pour chaque test
        $script:testRoadmapPath = Join-Path -Path $TestDrive -ChildPath "test_roadmap_integration_copy.md"
        Copy-Item -Path $script:tempRoadmapPath -Destination $script:testRoadmapPath -Force
    }

    It "Le script gran-mode-unified.ps1 charge correctement la configuration de granularité adaptative" {
        # Mock pour éviter de modifier réellement le fichier
        Mock Invoke-RoadmapGranularization { return $true }
        
        # Exécuter le script avec granularité adaptative
        $result = & $script:granModeUnifiedPath -FilePath $script:testRoadmapPath -TaskIdentifier "1.1" -AdaptiveGranularity -WhatIf
        
        # Vérifier que le script s'est exécuté sans erreur
        $result | Should -Not -BeNullOrEmpty
    }

    It "Le script gran-mode-recursive-unified.ps1 charge correctement la configuration de granularité adaptative" {
        # Mock pour éviter de modifier réellement le fichier
        Mock Invoke-RecursiveGranularization { return $true }
        
        # Exécuter le script avec granularité adaptative
        $result = & $script:granModeRecursivePath -FilePath $script:testRoadmapPath -TaskIdentifier "1.1" -AdaptiveGranularity -WhatIf
        
        # Vérifier que le script s'est exécuté sans erreur
        $result | Should -Not -BeNullOrEmpty
    }
}

AfterAll {
    # Nettoyer les fichiers temporaires
    if (Test-Path -Path $script:tempRoadmapPath) {
        Remove-Item -Path $script:tempRoadmapPath -Force
    }
    if (Test-Path -Path $script:testRoadmapPath) {
        Remove-Item -Path $script:testRoadmapPath -Force
    }
}
