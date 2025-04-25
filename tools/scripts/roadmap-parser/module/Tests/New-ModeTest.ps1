<#
.SYNOPSIS
    Génère un fichier de test pour un nouveau mode.

.DESCRIPTION
    Ce script génère un fichier de test pour un nouveau mode en utilisant le template de test.
    Il permet de créer rapidement des tests pour les nouveaux modes qui seront implémentés.

.PARAMETER ModeName
    Nom du mode pour lequel générer un test (ex: Archi, Debug, Test, etc.).

.PARAMETER FunctionName
    Nom de la fonction principale du mode (ex: Invoke-RoadmapArchitecture, Invoke-RoadmapDebug, etc.).

.PARAMETER OutputPath
    Chemin où sera généré le fichier de test. Par défaut, le fichier est généré dans le répertoire courant.

.EXAMPLE
    .\New-ModeTest.ps1 -ModeName "Secure" -FunctionName "Invoke-RoadmapSecurity"

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ModeName,
    
    [Parameter(Mandatory = $true)]
    [string]$FunctionName,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = $null
)

# Vérifier si le nom du mode est valide
if ([string]::IsNullOrWhiteSpace($ModeName)) {
    Write-Error "Le nom du mode ne peut pas être vide."
    exit 1
}

# Vérifier si le nom de la fonction est valide
if ([string]::IsNullOrWhiteSpace($FunctionName)) {
    Write-Error "Le nom de la fonction ne peut pas être vide."
    exit 1
}

# Normaliser le nom du mode
$normalizedModeName = $ModeName.Trim()
$normalizedModeName = $normalizedModeName.Substring(0, 1).ToUpper() + $normalizedModeName.Substring(1).ToLower()

# Chemin vers le template de test
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$templatePath = Join-Path -Path $scriptPath -ChildPath "Templates\Test-ModeTemplate.ps1"

# Vérifier si le template existe
if (-not (Test-Path -Path $templatePath)) {
    # Créer le répertoire Templates s'il n'existe pas
    $templatesDir = Join-Path -Path $scriptPath -ChildPath "Templates"
    if (-not (Test-Path -Path $templatesDir)) {
        New-Item -Path $templatesDir -ItemType Directory -Force | Out-Null
    }
    
    # Créer le template de test
    @"
<#
.SYNOPSIS
    Tests pour le script mode-name.ps1.

.DESCRIPTION
    Ce script contient des tests unitaires et d'intégration pour le script mode-name.ps1
    qui implémente le mode MODE_NAME.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

# Importer Pester si disponible
if (Get-Module -ListAvailable -Name Pester) {
    Import-Module Pester
} else {
    Write-Warning "Le module Pester n'est pas installé. Les tests ne seront pas exécutés avec le framework Pester."
}

# Chemin vers le script à tester
`$scriptPath = Split-Path -Parent `$MyInvocation.MyCommand.Path
`$modulePath = Split-Path -Parent (Split-Path -Parent `$scriptPath)
`$projectRoot = Split-Path -Parent (Split-Path -Parent `$modulePath)
`$modeScriptPath = Join-Path -Path `$projectRoot -ChildPath "mode-name.ps1"

# Chemin vers les fonctions à tester
`$invokeModeFunctionPath = Join-Path -Path `$modulePath -ChildPath "Functions\Public\Invoke-ModeNameFunction.ps1"

# Vérifier si les fichiers existent
if (-not (Test-Path -Path `$modeScriptPath)) {
    Write-Warning "Le script mode-name.ps1 est introuvable à l'emplacement : `$modeScriptPath"
}

if (-not (Test-Path -Path `$invokeModeFunctionPath)) {
    Write-Warning "Le fichier Invoke-ModeNameFunction.ps1 est introuvable à l'emplacement : `$invokeModeFunctionPath"
}

# Importer les fonctions si elles existent
if (Test-Path -Path `$invokeModeFunctionPath) {
    . `$invokeModeFunctionPath
    Write-Host "Fonction Invoke-ModeNameFunction importée." -ForegroundColor Green
}

# Créer un fichier temporaire pour les tests
`$testFilePath = Join-Path -Path `$env:TEMP -ChildPath "TestRoadmap_`$(Get-Random).md"

# Créer un fichier de test avec une structure de roadmap simple
@"
# Roadmap de test

## Section 1

- [ ] **1.1** Tâche 1
  - [ ] **1.1.1** Sous-tâche 1
  - [ ] **1.1.2** Sous-tâche 2
- [ ] **1.2** Tâche 2
  - [ ] **1.2.1** Sous-tâche 1
  - [ ] **1.2.2** Sous-tâche 2

## Section 2

- [ ] **2.1** Autre tâche
"@ | Set-Content -Path `$testFilePath -Encoding UTF8

Write-Host "Fichier de roadmap créé : `$testFilePath" -ForegroundColor Green

# Créer des répertoires temporaires pour les tests
`$testOutputPath = Join-Path -Path `$env:TEMP -ChildPath "TestOutput_`$(Get-Random)"
New-Item -Path `$testOutputPath -ItemType Directory -Force | Out-Null

Write-Host "Répertoire de sortie créé : `$testOutputPath" -ForegroundColor Green

# Tests unitaires avec Pester
Describe "Invoke-ModeNameFunction" {
    BeforeEach {
        # Préparation avant chaque test
    }

    AfterEach {
        # Nettoyage après chaque test
    }

    It "Devrait exécuter correctement avec des paramètres valides" {
        # Appeler la fonction
        if (Get-Command -Name Invoke-ModeNameFunction -ErrorAction SilentlyContinue) {
            `$result = Invoke-ModeNameFunction -FilePath `$testFilePath -TaskIdentifier "1.1" -OutputPath `$testOutputPath
            `$result | Should -Not -BeNullOrEmpty
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-ModeNameFunction n'est pas disponible"
        }
    }

    It "Devrait lever une exception si le fichier n'existe pas" {
        # Appeler la fonction avec un fichier inexistant
        if (Get-Command -Name Invoke-ModeNameFunction -ErrorAction SilentlyContinue) {
            { Invoke-ModeNameFunction -FilePath "FichierInexistant.md" -TaskIdentifier "1.1" -OutputPath `$testOutputPath } | Should -Throw
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-ModeNameFunction n'est pas disponible"
        }
    }

    It "Devrait lever une exception si l'identifiant de tâche est invalide" {
        # Appeler la fonction avec un identifiant de tâche invalide
        if (Get-Command -Name Invoke-ModeNameFunction -ErrorAction SilentlyContinue) {
            { Invoke-ModeNameFunction -FilePath `$testFilePath -TaskIdentifier "9.9" -OutputPath `$testOutputPath } | Should -Throw
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-ModeNameFunction n'est pas disponible"
        }
    }

    It "Devrait créer les fichiers de sortie attendus" {
        # Appeler la fonction et vérifier les fichiers de sortie
        if (Get-Command -Name Invoke-ModeNameFunction -ErrorAction SilentlyContinue) {
            `$result = Invoke-ModeNameFunction -FilePath `$testFilePath -TaskIdentifier "1.1" -OutputPath `$testOutputPath
            
            # Vérifier que les fichiers attendus existent
            `$expectedFile = Join-Path -Path `$testOutputPath -ChildPath "expected_output_file.txt"
            Test-Path -Path `$expectedFile | Should -Be `$true
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-ModeNameFunction n'est pas disponible"
        }
    }
}

# Test d'intégration du script mode-name.ps1
Describe "mode-name.ps1 Integration" {
    It "Devrait s'exécuter correctement avec des paramètres valides" {
        if (Test-Path -Path `$modeScriptPath) {
            # Exécuter le script
            `$output = & `$modeScriptPath -FilePath `$testFilePath -TaskIdentifier "1.1" -OutputPath `$testOutputPath
            
            # Vérifier que le script s'est exécuté sans erreur
            `$LASTEXITCODE | Should -Be 0
            
            # Vérifier que les fichiers attendus existent
            `$expectedFile = Join-Path -Path `$testOutputPath -ChildPath "expected_output_file.txt"
            Test-Path -Path `$expectedFile | Should -Be `$true
        } else {
            Set-ItResult -Skipped -Because "Le script mode-name.ps1 n'est pas disponible"
        }
    }
}

# Nettoyage
if (Test-Path -Path `$testFilePath) {
    Remove-Item -Path `$testFilePath -Force
    Write-Host "Fichier de roadmap supprimé." -ForegroundColor Gray
}

if (Test-Path -Path `$testOutputPath) {
    Remove-Item -Path `$testOutputPath -Recurse -Force
    Write-Host "Répertoire de sortie supprimé." -ForegroundColor Gray
}

# Exécuter les tests si Pester est disponible
if (Get-Command -Name Invoke-Pester -ErrorAction SilentlyContinue) {
    Invoke-Pester -Path `$MyInvocation.MyCommand.Path
} else {
    Write-Host "Tests terminés. Utilisez Invoke-Pester pour exécuter les tests avec le framework Pester." -ForegroundColor Yellow
}
"@ | Set-Content -Path $templatePath -Encoding UTF8
    
    Write-Host "Template de test créé : $templatePath" -ForegroundColor Green
}

# Lire le contenu du template
$templateContent = Get-Content -Path $templatePath -Raw

# Remplacer les valeurs dans le template
$scriptContent = $templateContent -replace "mode-name", "$($normalizedModeName.ToLower())-mode"
$scriptContent = $scriptContent -replace "MODE_NAME", $normalizedModeName.ToUpper()
$scriptContent = $scriptContent -replace "Invoke-ModeNameFunction", $FunctionName

# Déterminer le chemin de sortie
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = $scriptPath
}

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Host "Répertoire de sortie créé : $OutputPath" -ForegroundColor Green
}

# Générer le fichier de test
$testFileName = "Test-$($normalizedModeName)Mode.ps1"
$testFilePath = Join-Path -Path $OutputPath -ChildPath $testFileName

# Vérifier si le fichier existe déjà
if (Test-Path -Path $testFilePath) {
    $overwrite = Read-Host "Le fichier $testFileName existe déjà. Voulez-vous le remplacer ? (O/N)"
    if ($overwrite -ne "O" -and $overwrite -ne "o") {
        Write-Host "Génération du fichier de test annulée." -ForegroundColor Yellow
        exit 0
    }
}

# Écrire le contenu dans le fichier
$scriptContent | Set-Content -Path $testFilePath -Encoding UTF8

Write-Host "Fichier de test généré : $testFilePath" -ForegroundColor Green
