# Test-TagFormatLearning.ps1
# Tests unitaires pour l'apprentissage des nouveaux formats de tags
# Version: 1.0
# Date: 2025-05-15

# Importer Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer le module Pester
Import-Module Pester

# Définir le chemin du script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\metadata\Learn-NewTagFormats.ps1"

# Définir le chemin du fichier de configuration de test
$testConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "TestTagFormats.config.json"

# Créer un fichier de configuration de test
$testConfig = @{
    name = "Tag Formats Configuration"
    description = "Configuration des formats de tags pour les tests"
    version = "1.0.0"
    updated_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    tag_formats = @{
        duration = @{
            name = "Duration"
            description = "Tags pour la durée en anglais"
            formats = @(
                @{
                    name = "DurationDays"
                    pattern = "#duration:(\\d+(?:\\.\\d+)?)d\\b"
                    description = "Format #duration:Xd (jours)"
                    example = "#duration:5d"
                    value_group = 1
                    unit = "days"
                }
            )
        }
    }
} | ConvertTo-Json -Depth 10

# Écrire le fichier de configuration de test
$testConfig | Set-Content -Path $testConfigPath -Encoding UTF8

# Créer un contenu de test avec des tâches et des nouveaux formats de tags
$testContent = @"
# Roadmap de test

## Section 1

- [ ] **1.1** Tâche sans tag
- [ ] **1.2** Tâche avec tag connu #duration:3d
- [x] **1.3** Tâche avec nouveau tag #temps:2j
- [ ] **1.4** Tâche avec nouveau format composite #duration:2d4h
- [ ] **1.5** Tâche avec nouveau format parenthèses #duration(5w)
- [ ] **1.6** Tâche avec nouveau type de tag #priority:high
- [ ] **1.7** Tâche avec nouveau type de tag et format numérique #complexity:3
"@

# Définir les tests
Describe "Learn-NewTagFormats" {
    BeforeAll {
        # Charger les fonctions du script
        . $scriptPath
    }
    
    AfterAll {
        # Nettoyer les fichiers de test
        if (Test-Path -Path $testConfigPath) {
            Remove-Item -Path $testConfigPath -Force
        }
    }
    
    Context "Get-TagFormatsConfig" {
        It "Devrait charger correctement la configuration" {
            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath
            $config | Should -Not -BeNullOrEmpty
            $config.tag_formats.duration | Should -Not -BeNullOrEmpty
            $config.tag_formats.duration.formats.Count | Should -Be 1
        }
        
        It "Devrait retourner null si le fichier n'existe pas" {
            $config = Get-TagFormatsConfig -ConfigPath "fichier_inexistant.json"
            $config | Should -BeNullOrEmpty
        }
    }
    
    Context "Save-TagFormatsConfig" {
        It "Devrait sauvegarder correctement la configuration" {
            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath
            $config.tag_formats.duration.description = "Description modifiée"
            
            $result = Save-TagFormatsConfig -Config $config -ConfigPath $testConfigPath
            $result | Should -Be $true
            
            $newConfig = Get-TagFormatsConfig -ConfigPath $testConfigPath
            $newConfig.tag_formats.duration.description | Should -Be "Description modifiée"
        }
    }
    
    Context "Get-TasksFromContent" {
        It "Devrait détecter correctement les tâches dans le contenu" {
            $tasks = Get-TasksFromContent -Content $testContent
            
            $tasks | Should -Not -BeNullOrEmpty
            $tasks.Count | Should -Be 7
            $tasks["1.1"] | Should -Not -BeNullOrEmpty
            $tasks["1.1"].Status | Should -Be $false
            $tasks["1.3"] | Should -Not -BeNullOrEmpty
            $tasks["1.3"].Status | Should -Be $true
        }
        
        It "Devrait retourner un dictionnaire vide si aucune tâche n'est détectée" {
            $tasks = Get-TasksFromContent -Content "# Contenu sans tâche"
            
            $tasks | Should -Not -BeNullOrEmpty
            $tasks.Count | Should -Be 0
        }
    }
    
    Context "Detect-PotentialTagFormats" {
        It "Devrait détecter correctement les potentiels nouveaux formats de tags" {
            $tasks = Get-TasksFromContent -Content $testContent
            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath
            
            $detectedFormats = Detect-PotentialTagFormats -Tasks $tasks -TagFormats $config
            
            $detectedFormats | Should -Not -BeNullOrEmpty
            $detectedFormats.Count | Should -BeGreaterThan 0
            $detectedFormats.ContainsKey("temps") | Should -Be $true
            $detectedFormats.ContainsKey("priority") | Should -Be $true
            $detectedFormats.ContainsKey("complexity") | Should -Be $true
            
            # Vérifier que le format connu n'est pas détecté comme nouveau
            $detectedFormats.duration.Formats.ContainsKey("#duration:3d") | Should -Be $false
            
            # Vérifier que les nouveaux formats sont détectés
            $detectedFormats.temps.Formats.ContainsKey("#temps:2j") | Should -Be $true
            $detectedFormats.duration.Formats.ContainsKey("#duration:2d4h") | Should -Be $true
            $detectedFormats.duration.Formats.ContainsKey("#duration(5w)") | Should -Be $true
            $detectedFormats.priority.Formats.ContainsKey("#priority:high") | Should -Be $true
            $detectedFormats.complexity.Formats.ContainsKey("#complexity:3") | Should -Be $true
        }
    }
    
    Context "Create-RegexPatterns" {
        It "Devrait créer correctement des patterns regex pour les nouveaux formats" {
            $tasks = Get-TasksFromContent -Content $testContent
            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath
            $detectedFormats = Detect-PotentialTagFormats -Tasks $tasks -TagFormats $config
            
            $newPatterns = Create-RegexPatterns -DetectedFormats $detectedFormats
            
            $newPatterns | Should -Not -BeNullOrEmpty
            $newPatterns.Count | Should -BeGreaterThan 0
            $newPatterns.ContainsKey("temps") | Should -Be $true
            $newPatterns.ContainsKey("priority") | Should -Be $true
            $newPatterns.ContainsKey("complexity") | Should -Be $true
            
            # Vérifier les patterns créés
            $tempsPattern = $newPatterns.temps.Patterns | Where-Object { $_.Original -eq "#temps:2j" }
            $tempsPattern | Should -Not -BeNullOrEmpty
            $tempsPattern.Pattern | Should -Be "#temps:(\d+(?:\.\d+)?)j\b"
            $tempsPattern.Unit | Should -Be "days"
            
            $durationCompositePattern = $newPatterns.duration.Patterns | Where-Object { $_.Original -eq "#duration:2d4h" }
            $durationCompositePattern | Should -Not -BeNullOrEmpty
            $durationCompositePattern.IsComposite | Should -Be $true
            $durationCompositePattern.ValueGroups.Count | Should -Be 2
            $durationCompositePattern.Units.Count | Should -Be 2
            
            $priorityPattern = $newPatterns.priority.Patterns | Where-Object { $_.Original -eq "#priority:high" }
            $priorityPattern | Should -Not -BeNullOrEmpty
            $priorityPattern.Pattern | Should -Be "#priority:([a-zA-Z0-9_.-]+)"
        }
    }
    
    Context "Add-NewFormatsToConfig" {
        It "Devrait ajouter correctement les nouveaux formats à la configuration en mode Silent" {
            $tasks = Get-TasksFromContent -Content $testContent
            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath
            $detectedFormats = Detect-PotentialTagFormats -Tasks $tasks -TagFormats $config
            $newPatterns = Create-RegexPatterns -DetectedFormats $detectedFormats
            
            $addedFormats = Add-NewFormatsToConfig -Config $config -NewPatterns $newPatterns -Mode "Silent"
            
            $addedFormats | Should -Not -BeNullOrEmpty
            $addedFormats.Count | Should -BeGreaterThan 0
            
            # Vérifier que les nouveaux types de tags ont été ajoutés
            $config.tag_formats.PSObject.Properties.Name -contains "temps" | Should -Be $true
            $config.tag_formats.PSObject.Properties.Name -contains "priority" | Should -Be $true
            $config.tag_formats.PSObject.Properties.Name -contains "complexity" | Should -Be $true
            
            # Vérifier que les nouveaux formats ont été ajoutés
            $config.tag_formats.temps.formats.Count | Should -BeGreaterThan 0
            $config.tag_formats.priority.formats.Count | Should -BeGreaterThan 0
            $config.tag_formats.complexity.formats.Count | Should -BeGreaterThan 0
            
            # Vérifier que les nouveaux formats de duration ont été ajoutés
            $durationFormatsCount = $config.tag_formats.duration.formats.Count
            $durationFormatsCount | Should -BeGreaterThan 1
        }
        
        It "Devrait ajouter correctement les nouveaux formats à la configuration en mode Auto avec seuil" {
            # Réinitialiser la configuration
            $testConfig | Set-Content -Path $testConfigPath -Encoding UTF8
            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath
            
            $tasks = Get-TasksFromContent -Content $testContent
            $detectedFormats = Detect-PotentialTagFormats -Tasks $tasks -TagFormats $config
            $newPatterns = Create-RegexPatterns -DetectedFormats $detectedFormats
            
            # Modifier les compteurs pour simuler des occurrences multiples
            foreach ($tagName in $newPatterns.Keys) {
                foreach ($pattern in $newPatterns[$tagName].Patterns) {
                    $pattern.Count = 3
                }
            }
            
            $addedFormats = Add-NewFormatsToConfig -Config $config -NewPatterns $newPatterns -Mode "Auto" -ConfidenceThreshold 0.7
            
            $addedFormats | Should -Not -BeNullOrEmpty
            $addedFormats.Count | Should -BeGreaterThan 0
        }
    }
    
    Context "Invoke-TagFormatLearning" {
        It "Devrait apprendre et ajouter correctement les nouveaux formats de tags à partir du contenu" {
            # Réinitialiser la configuration
            $testConfig | Set-Content -Path $testConfigPath -Encoding UTF8
            
            $result = Invoke-TagFormatLearning -Content $testContent -ConfigPath $testConfigPath -Mode "Silent"
            
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
            
            # Vérifier que les nouveaux formats ont été ajoutés à la configuration
            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath
            $config.tag_formats.PSObject.Properties.Name.Count | Should -BeGreaterThan 1
        }
        
        It "Devrait apprendre et ajouter correctement les nouveaux formats de tags à partir d'un fichier" {
            # Réinitialiser la configuration
            $testConfig | Set-Content -Path $testConfigPath -Encoding UTF8
            
            # Créer un fichier temporaire
            $tempFilePath = Join-Path -Path $PSScriptRoot -ChildPath "TempTestFile.md"
            $testContent | Set-Content -Path $tempFilePath -Encoding UTF8
            
            $result = Invoke-TagFormatLearning -FilePath $tempFilePath -ConfigPath $testConfigPath -Mode "Silent"
            
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
            
            # Nettoyer
            if (Test-Path -Path $tempFilePath) {
                Remove-Item -Path $tempFilePath -Force
            }
        }
        
        It "Devrait enregistrer un rapport si demandé" {
            # Réinitialiser la configuration
            $testConfig | Set-Content -Path $testConfigPath -Encoding UTF8
            
            $outputPath = Join-Path -Path $PSScriptRoot -ChildPath "TestLearningReport.md"
            
            Invoke-TagFormatLearning -Content $testContent -ConfigPath $testConfigPath -Mode "Silent" -OutputPath $outputPath
            
            Test-Path -Path $outputPath | Should -Be $true
            
            # Nettoyer
            if (Test-Path -Path $outputPath) {
                Remove-Item -Path $outputPath -Force
            }
        }
    }
}

# Exécuter les tests
Invoke-Pester -Path $PSScriptRoot\Test-TagFormatLearning.ps1 -Output Detailed
