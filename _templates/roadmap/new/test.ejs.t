<#
---
to: D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/scripts/roadmap/tests/<%= category %>/<%= h.changeCase.param(name) %>.Tests.ps1
---
<#
.SYNOPSIS
    Tests pour <%= name %>.ps1

.DESCRIPTION
    Tests unitaires pour le script <%= name %>.ps1

.NOTES
    Auteur: <%= author || 'RoadmapTools Team' %>
    Version: 1.0
    Date de création: <%= new Date().toISOString().split('T')[0] %>
#>

# Importer Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer le script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\<%= category %>\<%= subcategory %>\<%= name %>.ps1"
. $scriptPath

# Tests
Describe "<%= name %>" {
    BeforeAll {
        # Créer des fichiers temporaires pour les tests
        $testInputPath = Join-Path -Path $TestDrive -ChildPath "input.md"
        $testOutputPath = Join-Path -Path $TestDrive -ChildPath "output.md"
        
        # Créer un contenu de test
        $testContent = @"
# Test Roadmap

- [ ] **1** Tâche 1
  - [ ] **1.1** Sous-tâche 1.1
  - [ ] **1.2** Sous-tâche 1.2
- [ ] **2** Tâche 2
  - [ ] **2.1** Sous-tâche 2.1
"@
        
        Set-Content -Path $testInputPath -Value $testContent -Encoding UTF8
    }
    
    It "Vérifie que le script s'exécute sans erreur" {
        { <%= h.changeCase.camel(name) %> -InputPath $testInputPath -OutputPath $testOutputPath } | Should -Not -Throw
    }
    
    It "Vérifie que le fichier de sortie est créé" {
        <%= h.changeCase.camel(name) %> -InputPath $testInputPath -OutputPath $testOutputPath
        Test-Path -Path $testOutputPath | Should -Be $true
    }
    
    # Ajouter d'autres tests spécifiques à la fonctionnalité du script
    
    AfterAll {
        # Nettoyer les fichiers temporaires si nécessaire
    }
}
