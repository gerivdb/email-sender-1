<#
.SYNOPSIS
    GÃ©nÃ¨re un fichier de test pour un nouveau mode.

.DESCRIPTION
    Ce script gÃ©nÃ¨re un fichier de test pour un nouveau mode en utilisant le template de test.
    Il permet de crÃ©er rapidement des tests pour les nouveaux modes qui seront implÃ©mentÃ©s.

.PARAMETER ModeName
    Nom du mode pour lequel gÃ©nÃ©rer un test (ex: Archi, Debug, Test, etc.).

.PARAMETER FunctionName
    Nom de la fonction principale du mode (ex: Invoke-RoadmapArchitecture, Invoke-RoadmapDebug, etc.).

.PARAMETER OutputPath
    Chemin oÃ¹ sera gÃ©nÃ©rÃ© le fichier de test. Par dÃ©faut, le fichier est gÃ©nÃ©rÃ© dans le rÃ©pertoire courant.

.EXAMPLE
    .\New-ModeTest.ps1 -ModeName "Secure" -FunctionName "Invoke-RoadmapSecurity"

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
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

# VÃ©rifier si le nom du mode est valide
if ([string]::IsNullOrWhiteSpace($ModeName)) {
    Write-Error "Le nom du mode ne peut pas Ãªtre vide."
    exit 1
}

# VÃ©rifier si le nom de la fonction est valide
if ([string]::IsNullOrWhiteSpace($FunctionName)) {
    Write-Error "Le nom de la fonction ne peut pas Ãªtre vide."
    exit 1
}

# Normaliser le nom du mode
$normalizedModeName = $ModeName.Trim()
$normalizedModeName = $normalizedModeName.Substring(0, 1).ToUpper() + $normalizedModeName.Substring(1).ToLower()

# Chemin vers le template de test
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$templatePath = Join-Path -Path $scriptPath -ChildPath "Templates\Test-ModeTemplate.ps1"

# VÃ©rifier si le template existe
if (-not (Test-Path -Path $templatePath)) {
    # CrÃ©er le rÃ©pertoire Templates s'il n'existe pas
    $templatesDir = Join-Path -Path $scriptPath -ChildPath "Templates"
    if (-not (Test-Path -Path $templatesDir)) {
        New-Item -Path $templatesDir -ItemType Directory -Force | Out-Null
    }
    
    # CrÃ©er le template de test
    @"
<#
.SYNOPSIS
    Tests pour le script mode-name.ps1.

.DESCRIPTION
    Ce script contient des tests unitaires et d'intÃ©gration pour le script mode-name.ps1
    qui implÃ©mente le mode MODE_NAME.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

# Importer Pester si disponible
if (Get-Module -ListAvailable -Name Pester) {
    Import-Module Pester
} else {
    Write-Warning "Le module Pester n'est pas installÃ©. Les tests ne seront pas exÃ©cutÃ©s avec le framework Pester."
}

# Chemin vers le script Ã  tester
`$scriptPath = Split-Path -Parent `$MyInvocation.MyCommand.Path
`$modulePath = Split-Path -Parent (Split-Path -Parent `$scriptPath)
`$projectRoot = Split-Path -Parent (Split-Path -Parent `$modulePath)
`$modeScriptPath = Join-Path -Path `$projectRoot -ChildPath "mode-name.ps1"

# Chemin vers les fonctions Ã  tester
`$invokeModeFunctionPath = Join-Path -Path `$modulePath -ChildPath "Functions\Public\Invoke-ModeNameFunction.ps1"

# VÃ©rifier si les fichiers existent
if (-not (Test-Path -Path `$modeScriptPath)) {
    Write-Warning "Le script mode-name.ps1 est introuvable Ã  l'emplacement : `$modeScriptPath"
}

if (-not (Test-Path -Path `$invokeModeFunctionPath)) {
    Write-Warning "Le fichier Invoke-ModeNameFunction.ps1 est introuvable Ã  l'emplacement : `$invokeModeFunctionPath"
}

# Importer les fonctions si elles existent
if (Test-Path -Path `$invokeModeFunctionPath) {
    . `$invokeModeFunctionPath
    Write-Host "Fonction Invoke-ModeNameFunction importÃ©e." -ForegroundColor Green
}

# CrÃ©er un fichier temporaire pour les tests
`$testFilePath = Join-Path -Path `$env:TEMP -ChildPath "TestRoadmap_`$(Get-Random).md"

# CrÃ©er un fichier de test avec une structure de roadmap simple
@"
# Roadmap de test

## Section 1

- [ ] **1.1** TÃ¢che 1
  - [ ] **1.1.1** Sous-tÃ¢che 1
  - [ ] **1.1.2** Sous-tÃ¢che 2
- [ ] **1.2** TÃ¢che 2
  - [ ] **1.2.1** Sous-tÃ¢che 1
  - [ ] **1.2.2** Sous-tÃ¢che 2

## Section 2

- [ ] **2.1** Autre tÃ¢che
"@ | Set-Content -Path `$testFilePath -Encoding UTF8

Write-Host "Fichier de roadmap crÃ©Ã© : `$testFilePath" -ForegroundColor Green

# CrÃ©er des rÃ©pertoires temporaires pour les tests
`$testOutputPath = Join-Path -Path `$env:TEMP -ChildPath "TestOutput_`$(Get-Random)"
New-Item -Path `$testOutputPath -ItemType Directory -Force | Out-Null

Write-Host "RÃ©pertoire de sortie crÃ©Ã© : `$testOutputPath" -ForegroundColor Green

# Tests unitaires avec Pester
Describe "Invoke-ModeNameFunction" {
    BeforeEach {
        # PrÃ©paration avant chaque test
    }

    AfterEach {
        # Nettoyage aprÃ¨s chaque test
    }

    It "Devrait exÃ©cuter correctement avec des paramÃ¨tres valides" {
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

    It "Devrait lever une exception si l'identifiant de tÃ¢che est invalide" {
        # Appeler la fonction avec un identifiant de tÃ¢che invalide
        if (Get-Command -Name Invoke-ModeNameFunction -ErrorAction SilentlyContinue) {
            { Invoke-ModeNameFunction -FilePath `$testFilePath -TaskIdentifier "9.9" -OutputPath `$testOutputPath } | Should -Throw
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-ModeNameFunction n'est pas disponible"
        }
    }

    It "Devrait crÃ©er les fichiers de sortie attendus" {
        # Appeler la fonction et vÃ©rifier les fichiers de sortie
        if (Get-Command -Name Invoke-ModeNameFunction -ErrorAction SilentlyContinue) {
            `$result = Invoke-ModeNameFunction -FilePath `$testFilePath -TaskIdentifier "1.1" -OutputPath `$testOutputPath
            
            # VÃ©rifier que les fichiers attendus existent
            `$expectedFile = Join-Path -Path `$testOutputPath -ChildPath "expected_output_file.txt"
            Test-Path -Path `$expectedFile | Should -Be `$true
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-ModeNameFunction n'est pas disponible"
        }
    }
}

# Test d'intÃ©gration du script mode-name.ps1
Describe "mode-name.ps1 Integration" {
    It "Devrait s'exÃ©cuter correctement avec des paramÃ¨tres valides" {
        if (Test-Path -Path `$modeScriptPath) {
            # ExÃ©cuter le script
            `$output = & `$modeScriptPath -FilePath `$testFilePath -TaskIdentifier "1.1" -OutputPath `$testOutputPath
            
            # VÃ©rifier que le script s'est exÃ©cutÃ© sans erreur
            `$LASTEXITCODE | Should -Be 0
            
            # VÃ©rifier que les fichiers attendus existent
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
    Write-Host "Fichier de roadmap supprimÃ©." -ForegroundColor Gray
}

if (Test-Path -Path `$testOutputPath) {
    Remove-Item -Path `$testOutputPath -Recurse -Force
    Write-Host "RÃ©pertoire de sortie supprimÃ©." -ForegroundColor Gray
}

# ExÃ©cuter les tests si Pester est disponible
if (Get-Command -Name Invoke-Pester -ErrorAction SilentlyContinue) {
    Invoke-Pester -Path `$MyInvocation.MyCommand.Path
} else {
    Write-Host "Tests terminÃ©s. Utilisez Invoke-Pester pour exÃ©cuter les tests avec le framework Pester." -ForegroundColor Yellow
}
"@ | Set-Content -Path $templatePath -Encoding UTF8
    
    Write-Host "Template de test crÃ©Ã© : $templatePath" -ForegroundColor Green
}

# Lire le contenu du template
$templateContent = Get-Content -Path $templatePath -Raw

# Remplacer les valeurs dans le template
$scriptContent = $templateContent -replace "mode-name", "$($normalizedModeName.ToLower())-mode"
$scriptContent = $scriptContent -replace "MODE_NAME", $normalizedModeName.ToUpper()
$scriptContent = $scriptContent -replace "Invoke-ModeNameFunction", $FunctionName

# DÃ©terminer le chemin de sortie
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = $scriptPath
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Host "RÃ©pertoire de sortie crÃ©Ã© : $OutputPath" -ForegroundColor Green
}

# GÃ©nÃ©rer le fichier de test
$testFileName = "Test-$($normalizedModeName)Mode.ps1"
$testFilePath = Join-Path -Path $OutputPath -ChildPath $testFileName

# VÃ©rifier si le fichier existe dÃ©jÃ 
if (Test-Path -Path $testFilePath) {
    $overwrite = Read-Host "Le fichier $testFileName existe dÃ©jÃ . Voulez-vous le remplacer ? (O/N)"
    if ($overwrite -ne "O" -and $overwrite -ne "o") {
        Write-Host "GÃ©nÃ©ration du fichier de test annulÃ©e." -ForegroundColor Yellow
        exit 0
    }
}

# Ã‰crire le contenu dans le fichier
$scriptContent | Set-Content -Path $testFilePath -Encoding UTF8

Write-Host "Fichier de test gÃ©nÃ©rÃ© : $testFilePath" -ForegroundColor Green
