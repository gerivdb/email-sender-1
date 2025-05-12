# Test-TagsDetection.ps1
# Tests unitaires pour la détection des tags avec expressions régulières
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
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\metadata\Detect-TagsWithRegex.ps1"

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
                },
                @{
                    name = "DurationWeeks"
                    pattern = "#duration:(\\d+(?:\\.\\d+)?)w\\b"
                    description = "Format #duration:Xw (semaines)"
                    example = "#duration:2w"
                    value_group = 1
                    unit = "weeks"
                },
                @{
                    name = "DurationDaysHours"
                    pattern = "#duration:(\\d+(?:\\.\\d+)?)d[-_]?(\\d+(?:\\.\\d+)?)h\\b"
                    description = "Format #duration:XdYh (jours et heures)"
                    example = "#duration:5d3h"
                    value_groups = @(1, 2)
                    units = @("days", "hours")
                    composite = $true
                }
            )
        },
        temps = @{
            name = "Temps"
            description = "Tags pour le temps en français"
            formats = @(
                @{
                    name = "TempsDays"
                    pattern = "#temps:(\\d+(?:\\.\\d+)?)j\\b"
                    description = "Format #temps:Xj (jours)"
                    example = "#temps:5j"
                    value_group = 1
                    unit = "days"
                }
            )
        }
    }
} | ConvertTo-Json -Depth 10

# Écrire le fichier de configuration de test
$testConfig | Set-Content -Path $testConfigPath -Encoding UTF8

# Créer un contenu de test avec des tâches et des tags
$testContent = @"
# Roadmap de test

## Section 1

- [ ] **1.1** Tâche sans tag
- [ ] **1.2** Tâche avec tag simple #duration:3d
- [x] **1.3** Tâche complétée avec tag #temps:2j
- [ ] **1.4** Tâche avec tag composite #duration:2d4h
- [ ] **1.5** Tâche avec plusieurs tags #duration:1w #temps:5j

## Section 2

- [ ] **2.1** Autre tâche sans tag
- [x] **2.2** Autre tâche complétée avec tag #duration:10d
"@

# Définir les tests
Describe "Detect-TagsWithRegex" {
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
            $config.tag_formats.duration.formats.Count | Should -Be 3
            $config.tag_formats.temps | Should -Not -BeNullOrEmpty
            $config.tag_formats.temps.formats.Count | Should -Be 1
        }
        
        It "Devrait retourner null si le fichier n'existe pas" {
            $config = Get-TagFormatsConfig -ConfigPath "fichier_inexistant.json"
            $config | Should -BeNullOrEmpty
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
            $tasks["2.2"] | Should -Not -BeNullOrEmpty
            $tasks["2.2"].Status | Should -Be $true
        }
        
        It "Devrait retourner un dictionnaire vide si aucune tâche n'est détectée" {
            $tasks = Get-TasksFromContent -Content "# Contenu sans tâche"
            
            $tasks | Should -Not -BeNullOrEmpty
            $tasks.Count | Should -Be 0
        }
    }
    
    Context "Detect-TagsInTasks" {
        It "Devrait détecter correctement les tags dans les tâches" {
            $tasks = Get-TasksFromContent -Content $testContent
            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath
            
            $tasksWithTags = Detect-TagsInTasks -Tasks $tasks -TagFormats $config
            
            $tasksWithTags | Should -Not -BeNullOrEmpty
            $tasksWithTags["1.1"].Tags.duration.Count | Should -Be 0
            $tasksWithTags["1.2"].Tags.duration.Count | Should -Be 1
            $tasksWithTags["1.2"].Tags.duration[0].Value | Should -Be "3"
            $tasksWithTags["1.2"].Tags.duration[0].Unit | Should -Be "days"
            $tasksWithTags["1.3"].Tags.temps.Count | Should -Be 1
            $tasksWithTags["1.3"].Tags.temps[0].Value | Should -Be "2"
            $tasksWithTags["1.3"].Tags.temps[0].Unit | Should -Be "days"
            $tasksWithTags["1.4"].Tags.duration.Count | Should -Be 1
            $tasksWithTags["1.4"].Tags.duration[0].IsComposite | Should -Be $true
            $tasksWithTags["1.4"].Tags.duration[0].Values[0] | Should -Be "2"
            $tasksWithTags["1.4"].Tags.duration[0].Values[1] | Should -Be "4"
            $tasksWithTags["1.4"].Tags.duration[0].Units[0] | Should -Be "days"
            $tasksWithTags["1.4"].Tags.duration[0].Units[1] | Should -Be "hours"
            $tasksWithTags["1.5"].Tags.duration.Count | Should -Be 1
            $tasksWithTags["1.5"].Tags.temps.Count | Should -Be 1
        }
        
        It "Devrait filtrer correctement par type de tag" {
            $tasks = Get-TasksFromContent -Content $testContent
            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath
            
            $tasksWithTags = Detect-TagsInTasks -Tasks $tasks -TagFormats $config -TagTypes @("duration")
            
            $tasksWithTags | Should -Not -BeNullOrEmpty
            $tasksWithTags["1.3"].Tags.ContainsKey("temps") | Should -Be $false
            $tasksWithTags["1.3"].Tags.ContainsKey("duration") | Should -Be $true
            $tasksWithTags["1.5"].Tags.ContainsKey("temps") | Should -Be $false
            $tasksWithTags["1.5"].Tags.ContainsKey("duration") | Should -Be $true
        }
    }
    
    Context "Format-DetectionResults" {
        It "Devrait formater correctement les résultats en JSON" {
            $tasks = Get-TasksFromContent -Content $testContent
            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath
            $tasksWithTags = Detect-TagsInTasks -Tasks $tasks -TagFormats $config
            
            $output = Format-DetectionResults -Tasks $tasksWithTags -Format "JSON"
            
            $output | Should -Not -BeNullOrEmpty
            { $output | ConvertFrom-Json } | Should -Not -Throw
        }
        
        It "Devrait formater correctement les résultats en Markdown" {
            $tasks = Get-TasksFromContent -Content $testContent
            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath
            $tasksWithTags = Detect-TagsInTasks -Tasks $tasks -TagFormats $config
            
            $output = Format-DetectionResults -Tasks $tasksWithTags -Format "Markdown"
            
            $output | Should -Not -BeNullOrEmpty
            $output | Should -Match "# Rapport de détection des tags"
            $output | Should -Match "## Résumé"
            $output | Should -Match "## Détails par tâche"
        }
        
        It "Devrait formater correctement les résultats en CSV" {
            $tasks = Get-TasksFromContent -Content $testContent
            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath
            $tasksWithTags = Detect-TagsInTasks -Tasks $tasks -TagFormats $config
            
            $output = Format-DetectionResults -Tasks $tasksWithTags -Format "CSV"
            
            $output | Should -Not -BeNullOrEmpty
            $output | Should -Match "TaskId,Title,Status,LineNumber,TagType,Format,Value,Unit,Original"
        }
        
        It "Devrait formater correctement les résultats en Text" {
            $tasks = Get-TasksFromContent -Content $testContent
            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath
            $tasksWithTags = Detect-TagsInTasks -Tasks $tasks -TagFormats $config
            
            $output = Format-DetectionResults -Tasks $tasksWithTags -Format "Text"
            
            $output | Should -Not -BeNullOrEmpty
            $output | Should -Match "Rapport de détection des tags"
            $output | Should -Match "Résumé:"
            $output | Should -Match "Détails par tâche:"
        }
        
        It "Devrait inclure le contenu des tâches si demandé" {
            $tasks = Get-TasksFromContent -Content $testContent
            $config = Get-TagFormatsConfig -ConfigPath $testConfigPath
            $tasksWithTags = Detect-TagsInTasks -Tasks $tasks -TagFormats $config
            
            $output = Format-DetectionResults -Tasks $tasksWithTags -Format "Text" -IncludeTaskContent
            
            $output | Should -Not -BeNullOrEmpty
            $output | Should -Match "Contenu:"
        }
    }
    
    Context "Invoke-TagDetection" {
        It "Devrait détecter et formater correctement les tags à partir du contenu" {
            $result = Invoke-TagDetection -Content $testContent -ConfigPath $testConfigPath -OutputFormat "JSON"
            
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 7
            $result["1.2"].Tags.duration.Count | Should -Be 1
        }
        
        It "Devrait détecter et formater correctement les tags à partir d'un fichier" {
            # Créer un fichier temporaire
            $tempFilePath = Join-Path -Path $PSScriptRoot -ChildPath "TempTestFile.md"
            $testContent | Set-Content -Path $tempFilePath -Encoding UTF8
            
            $result = Invoke-TagDetection -FilePath $tempFilePath -ConfigPath $testConfigPath -OutputFormat "JSON"
            
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 7
            
            # Nettoyer
            if (Test-Path -Path $tempFilePath) {
                Remove-Item -Path $tempFilePath -Force
            }
        }
        
        It "Devrait enregistrer les résultats dans un fichier si demandé" {
            $outputPath = Join-Path -Path $PSScriptRoot -ChildPath "TestOutput.json"
            
            Invoke-TagDetection -Content $testContent -ConfigPath $testConfigPath -OutputFormat "JSON" -OutputPath $outputPath
            
            Test-Path -Path $outputPath | Should -Be $true
            
            # Nettoyer
            if (Test-Path -Path $outputPath) {
                Remove-Item -Path $outputPath -Force
            }
        }
        
        It "Devrait filtrer correctement par type de tag" {
            $result = Invoke-TagDetection -Content $testContent -ConfigPath $testConfigPath -OutputFormat "JSON" -TagTypes @("temps")
            
            $result | Should -Not -BeNullOrEmpty
            $result["1.2"].Tags.ContainsKey("duration") | Should -Be $false
            $result["1.2"].Tags.ContainsKey("temps") | Should -Be $true
        }
    }
}

# Exécuter les tests
Invoke-Pester -Path $PSScriptRoot\Test-TagsDetection.ps1 -Output Detailed
