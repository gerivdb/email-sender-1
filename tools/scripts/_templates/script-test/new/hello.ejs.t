---
to: scripts/tests/<%= name %>.Tests.ps1
---
#Requires -Version 5.1
<#
.SYNOPSIS
    <%= description %>

.DESCRIPTION
    <%= description %>
    <%= additionalDescription ? additionalDescription : '' %>

.NOTES
    Auteur: <%= author || 'EMAIL_SENDER_1' %>
    Version: 1.0
    Date de création: <%= new Date().toISOString().split('T')[0] %>
    Tags: <%= tags || 'tests, pester, scripts' %>
    Requires: Pester v5.0+
#>

BeforeAll {
    # Obtenir le répertoire du script de test
    $scriptDir = Split-Path -Parent $PSCommandPath
    
    # Chemin vers le script à tester
    $scriptToTest = Join-Path -Path $scriptDir -ChildPath "..\<%= scriptToTest || 'path/to/script.ps1' %>"
    
    # Vérifier que le script existe
    if (-not (Test-Path -Path $scriptToTest)) {
        throw "Script à tester non trouvé: $scriptToTest"
    }
    
    # Importer le script à tester dans la portée du test
    . $scriptToTest
}

Describe "<%= name %>" {
    Context "Validation du script" {
        It "Le script à tester existe" {
            Test-Path -Path $scriptToTest | Should -BeTrue
        }
        
        It "Le script à tester est un script PowerShell valide" {
            $errors = $null
            $tokens = $null
            [System.Management.Automation.Language.Parser]::ParseFile($scriptToTest, [ref]$tokens, [ref]$errors)
            $errors.Count | Should -Be 0
        }
    }
    
    Context "Fonctionnalités de base" {
        It "La fonction principale existe" {
            # Remplacez 'Start-Example' par le nom de la fonction principale du script à tester
            Get-Command -Name "Start-<%= functionName || 'Example' %>" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "La fonction principale retourne un résultat valide" {
            # Exemple de test de la fonction principale
            # Remplacez 'Start-Example' par le nom de la fonction principale et ajustez les paramètres
            $result = Start-<%= functionName || 'Example' %> -TestMode
            $result | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Cas d'utilisation spécifiques" {
        It "Gère correctement les entrées valides" {
            # TODO: Ajoutez des tests pour les cas d'utilisation valides
            $true | Should -BeTrue
        }
        
        It "Gère correctement les entrées invalides" {
            # TODO: Ajoutez des tests pour les cas d'utilisation invalides
            $true | Should -BeTrue
        }
        
        It "Gère correctement les cas limites" {
            # TODO: Ajoutez des tests pour les cas limites
            $true | Should -BeTrue
        }
    }
    
    Context "Gestion des erreurs" {
        It "Gère correctement les erreurs" {
            # TODO: Ajoutez des tests pour la gestion des erreurs
            $true | Should -BeTrue
        }
    }
}

# Fonction pour exécuter les tests
function Invoke-<%= h.changeCase.pascal(name) %>Tests {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$OutputXml,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "TestResults"
    )
    
    # Vérifier si Pester est installé
    if (-not (Get-Module -Name Pester -ListAvailable)) {
        Write-Host "Pester n'est pas installé. Installation en cours..." -ForegroundColor Yellow
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }
    
    # Importer Pester
    Import-Module -Name Pester -Force
    
    # Configurer Pester
    $pesterConfig = New-PesterConfiguration
    $pesterConfig.Run.Path = $PSCommandPath
    $pesterConfig.Output.Verbosity = "Detailed"
    
    if ($OutputXml) {
        # Créer le répertoire de sortie s'il n'existe pas
        if (-not (Test-Path -Path $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }
        
        $pesterConfig.TestResult.Enabled = $true
        $pesterConfig.TestResult.OutputPath = Join-Path -Path $OutputPath -ChildPath "<%= name %>-TestResults.xml"
    }
    
    # Exécuter les tests
    Invoke-Pester -Configuration $pesterConfig
}

# Si le script est exécuté directement (pas importé), exécuter les tests
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Invoke-<%= h.changeCase.pascal(name) %>Tests
}
