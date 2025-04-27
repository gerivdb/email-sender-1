#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Update-PRCacheSelectively.ps1.
.DESCRIPTION
    Ce fichier contient des tests unitaires pour le script Update-PRCacheSelectively.ps1
    qui met Ã  jour ou invalide sÃ©lectivement des Ã©lÃ©ments du cache d'analyse des pull requests.
.NOTES
    Author: Augment Agent
    Version: 1.0
    Requires: Pester v5.0+, PRAnalysisCache.psm1
#>

# Importer Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Chemin du script Ã  tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Update-PRCacheSelectively.ps1"

# VÃ©rifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    throw "Script Update-PRCacheSelectively.ps1 non trouvÃ© Ã  l'emplacement: $scriptPath"
}

# Chemin du module de cache
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\PRAnalysisCache.psm1"

# VÃ©rifier que le module existe
if (-not (Test-Path -Path $modulePath)) {
    throw "Module PRAnalysisCache.psm1 non trouvÃ© Ã  l'emplacement: $modulePath"
}

# Importer le module
Import-Module $modulePath -Force

# Variables globales pour les tests
$script:testCachePath = Join-Path -Path $env:TEMP -ChildPath "PRCacheSelectively"

# CrÃ©er des donnÃ©es de test
BeforeAll {
    # CrÃ©er le rÃ©pertoire de cache de test
    New-Item -Path $script:testCachePath -ItemType Directory -Force | Out-Null

    # Fonction pour exÃ©cuter le script avec des paramÃ¨tres
    function Invoke-UpdateScript {
        param(
            [string]$CachePath,
            [string]$Pattern,
            [string[]]$Keys,
            [switch]$RemoveMatching,
            [switch]$Force
        )

        $params = @{
            CachePath = $CachePath
        }

        if ($Pattern) {
            $params.Add("Pattern", $Pattern)
        }

        if ($Keys) {
            $params.Add("Keys", $Keys)
        }

        if ($RemoveMatching) {
            $params.Add("RemoveMatching", $true)
        }

        if ($Force) {
            $params.Add("Force", $true)
        }

        & $scriptPath @params
    }

    # CrÃ©er un cache pour les tests
    $script:cache = New-PRAnalysisCache
    $script:cache.DiskCachePath = $script:testCachePath

    # Ajouter des Ã©lÃ©ments au cache avec des prÃ©fixes diffÃ©rents
    $script:cache.SetItem("PR:42:File:script1.ps1", "Content1", (New-TimeSpan -Hours 1))
    $script:cache.SetItem("PR:42:File:script2.ps1", "Content2", (New-TimeSpan -Hours 1))
    $script:cache.SetItem("PR:42:File:module.psm1", "Module Content", (New-TimeSpan -Hours 1))
    $script:cache.SetItem("PR:43:File:script1.ps1", "Content3", (New-TimeSpan -Hours 1))
    $script:cache.SetItem("PR:43:File:script3.ps1", "Content4", (New-TimeSpan -Hours 1))
}

Describe "Update-PRCacheSelectively Script Tests" {
    Context "Script Execution" {
        It "Le script s'exÃ©cute sans erreur avec un modÃ¨le" {
            # Act & Assert
            { Invoke-UpdateScript -CachePath $script:testCachePath -Pattern "PR:42:*" -Force } | Should -Not -Throw
        }

        It "Le script s'exÃ©cute sans erreur avec des clÃ©s spÃ©cifiques" {
            # Act & Assert
            { Invoke-UpdateScript -CachePath $script:testCachePath -Keys "PR:42:File:script1.ps1", "PR:42:File:script2.ps1" -Force } | Should -Not -Throw
        }
    }

    Context "Pattern Matching" {
        BeforeEach {
            # RecrÃ©er le cache pour chaque test
            Remove-Item -Path $script:testCachePath -Recurse -Force -ErrorAction SilentlyContinue
            New-Item -Path $script:testCachePath -ItemType Directory -Force | Out-Null

            $script:cache = New-PRAnalysisCache
            $script:cache.DiskCachePath = $script:testCachePath

            $script:cache.SetItem("PR:42:File:script1.ps1", "Content1", (New-TimeSpan -Hours 1))
            $script:cache.SetItem("PR:42:File:script2.ps1", "Content2", (New-TimeSpan -Hours 1))
            $script:cache.SetItem("PR:42:File:module.psm1", "Module Content", (New-TimeSpan -Hours 1))
            $script:cache.SetItem("PR:43:File:script1.ps1", "Content3", (New-TimeSpan -Hours 1))
            $script:cache.SetItem("PR:43:File:script3.ps1", "Content4", (New-TimeSpan -Hours 1))
        }

        It "Met Ã  jour les Ã©lÃ©ments correspondant au modÃ¨le" {
            # Act
            Invoke-UpdateScript -CachePath $script:testCachePath -Pattern "PR:42:*" -Force

            # Assert - VÃ©rifier que les Ã©lÃ©ments ont Ã©tÃ© mis Ã  jour (supprimÃ©s puis recrÃ©Ã©s)
            $diskCacheFiles = Get-ChildItem -Path $script:testCachePath -Filter "*.xml"
            $diskCacheFiles.Count | Should -Be 5 # Tous les fichiers devraient Ãªtre prÃ©sents
        }

        It "Supprime les Ã©lÃ©ments correspondant au modÃ¨le avec RemoveMatching" {
            # Act
            Invoke-UpdateScript -CachePath $script:testCachePath -Pattern "PR:42:*" -RemoveMatching -Force

            # Assert - VÃ©rifier que les Ã©lÃ©ments ont Ã©tÃ© supprimÃ©s
            $diskCacheFiles = Get-ChildItem -Path $script:testCachePath -Filter "*.xml"
            $diskCacheFiles.Count | Should -Be 2 # Seuls les fichiers PR:43:* devraient rester

            $fileNames = $diskCacheFiles | ForEach-Object { $_.Name }
            $fileNames -join "," | Should -Not -Match "PR:42:"
        }
    }

    Context "Specific Keys" {
        BeforeEach {
            # RecrÃ©er le cache pour chaque test
            Remove-Item -Path $script:testCachePath -Recurse -Force -ErrorAction SilentlyContinue
            New-Item -Path $script:testCachePath -ItemType Directory -Force | Out-Null

            $script:cache = New-PRAnalysisCache
            $script:cache.DiskCachePath = $script:testCachePath

            $script:cache.SetItem("PR:42:File:script1.ps1", "Content1", (New-TimeSpan -Hours 1))
            $script:cache.SetItem("PR:42:File:script2.ps1", "Content2", (New-TimeSpan -Hours 1))
            $script:cache.SetItem("PR:42:File:module.psm1", "Module Content", (New-TimeSpan -Hours 1))
            $script:cache.SetItem("PR:43:File:script1.ps1", "Content3", (New-TimeSpan -Hours 1))
            $script:cache.SetItem("PR:43:File:script3.ps1", "Content4", (New-TimeSpan -Hours 1))
        }

        It "Met Ã  jour les clÃ©s spÃ©cifiques" {
            # Act
            Invoke-UpdateScript -CachePath $script:testCachePath -Keys "PR:42:File:script1.ps1", "PR:43:File:script3.ps1" -Force

            # Assert - VÃ©rifier que les Ã©lÃ©ments ont Ã©tÃ© mis Ã  jour (supprimÃ©s puis recrÃ©Ã©s)
            $diskCacheFiles = Get-ChildItem -Path $script:testCachePath -Filter "*.xml"
            $diskCacheFiles.Count | Should -Be 5 # Tous les fichiers devraient Ãªtre prÃ©sents
        }

        It "Supprime les clÃ©s spÃ©cifiques avec RemoveMatching" {
            # Act
            Invoke-UpdateScript -CachePath $script:testCachePath -Keys "PR:42:File:script1.ps1", "PR:43:File:script3.ps1" -RemoveMatching -Force

            # Assert - VÃ©rifier que les Ã©lÃ©ments ont Ã©tÃ© supprimÃ©s
            $diskCacheFiles = Get-ChildItem -Path $script:testCachePath -Filter "*.xml"
            $diskCacheFiles.Count | Should -Be 3 # Seuls les fichiers non spÃ©cifiÃ©s devraient rester

            $fileNames = $diskCacheFiles | ForEach-Object { $_.Name }
            $fileNames -join "," | Should -Not -Match ($script:cache.NormalizeKey("PR:42:File:script1.ps1"))
            $fileNames -join "," | Should -Not -Match ($script:cache.NormalizeKey("PR:43:File:script3.ps1"))
        }
    }

    Context "Force Parameter" {
        It "Demande confirmation si Force n'est pas spÃ©cifiÃ©" {
            # Arrange - Mock de la fonction de confirmation
            Mock -CommandName Read-Host -MockWith { return "n" }

            # Act
            Invoke-UpdateScript -CachePath $script:testCachePath -Pattern "PR:42:*"

            # Assert
            Should -Invoke -CommandName Read-Host -Times 1
        }

        It "Ne demande pas confirmation si Force est spÃ©cifiÃ©" {
            # Arrange - Mock de la fonction de confirmation
            Mock -CommandName Read-Host -MockWith { return "n" }

            # Act
            Invoke-UpdateScript -CachePath $script:testCachePath -Pattern "PR:42:*" -Force

            # Assert
            Should -Not -Invoke -CommandName Read-Host
        }
    }
}
