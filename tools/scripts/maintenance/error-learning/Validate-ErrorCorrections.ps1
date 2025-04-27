<#
.SYNOPSIS
    Script de validation des corrections d'erreurs PowerShell.
.DESCRIPTION
    Ce script valide les corrections appliquÃ©es aux scripts PowerShell
    en vÃ©rifiant leur syntaxe et en exÃ©cutant des tests unitaires.
.PARAMETER ScriptPath
    Chemin du script Ã  valider.
.PARAMETER TestPath
    Chemin du script de test unitaire associÃ©.
.PARAMETER GenerateTestScript
    Si spÃ©cifiÃ©, gÃ©nÃ¨re un script de test unitaire pour le script spÃ©cifiÃ©.
.PARAMETER Interactive
    Si spÃ©cifiÃ©, active le mode interactif qui demande confirmation avant d'appliquer les corrections.
.EXAMPLE
    .\Validate-ErrorCorrections.ps1 -ScriptPath "C:\Scripts\MonScript.ps1" -TestPath "C:\Scripts\Tests\MonScript.Tests.ps1"
    Valide les corrections appliquÃ©es au script en exÃ©cutant les tests unitaires.
.EXAMPLE
    .\Validate-ErrorCorrections.ps1 -ScriptPath "C:\Scripts\MonScript.ps1" -GenerateTestScript
    GÃ©nÃ¨re un script de test unitaire pour le script spÃ©cifiÃ©.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$ScriptPath,
    
    [Parameter(Mandatory = $false)]
    [string]$TestPath = "",
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateTestScript,
    
    [Parameter(Mandatory = $false)]
    [switch]$Interactive
)

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "ErrorLearningSystem.psm1"
Import-Module $modulePath -Force

# Initialiser le systÃ¨me
Initialize-ErrorLearningSystem

# VÃ©rifier si le script existe
if (-not (Test-Path -Path $ScriptPath)) {
    Write-Error "Le script spÃ©cifiÃ© n'existe pas : $ScriptPath"
    exit 1
}

# DÃ©finir le chemin du script de test par dÃ©faut
if (-not $TestPath) {
    $scriptDir = Split-Path -Path $ScriptPath -Parent
    $scriptName = [System.IO.Path]::GetFileNameWithoutExtension($ScriptPath)
    $TestPath = Join-Path -Path $scriptDir -ChildPath "Tests\$scriptName.Tests.ps1"
}

# Fonction pour valider la syntaxe d'un script
function Test-ScriptSyntax {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )
    
    try {
        # Lire le contenu du script
        $scriptContent = Get-Content -Path $ScriptPath -Raw -ErrorAction Stop
        
        # Analyser le script avec l'analyseur de syntaxe PowerShell
        $errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize($scriptContent, [ref]$errors)
        
        if ($errors -and $errors.Count -gt 0) {
            Write-Host "Erreurs de syntaxe dÃ©tectÃ©es :" -ForegroundColor Red
            
            foreach ($error in $errors) {
                Write-Host "  Ligne $($error.Token.StartLine), colonne $($error.Token.StartColumn) : $($error.Message)" -ForegroundColor Red
            }
            
            return $false
        }
        
        # VÃ©rifier la syntaxe avec le compilateur PowerShell
        $null = [ScriptBlock]::Create($scriptContent)
        
        return $true
    }
    catch {
        Write-Host "Erreur lors de la validation de la syntaxe : $_" -ForegroundColor Red
        return $false
    }
}

# Fonction pour exÃ©cuter des tests unitaires
function Invoke-UnitTests {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestPath
    )
    
    # VÃ©rifier si le script de test existe
    if (-not (Test-Path -Path $TestPath)) {
        Write-Warning "Le script de test spÃ©cifiÃ© n'existe pas : $TestPath"
        return $false
    }
    
    # VÃ©rifier si Pester est installÃ©
    if (-not (Get-Module -Name Pester -ListAvailable)) {
        Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }
    
    # Importer Pester
    Import-Module Pester -Force
    
    try {
        # ExÃ©cuter les tests
        $testResults = Invoke-Pester -Path $TestPath -PassThru
        
        if ($testResults.FailedCount -eq 0) {
            Write-Host "Tous les tests ont rÃ©ussi." -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "Certains tests ont Ã©chouÃ© :" -ForegroundColor Red
            Write-Host "  Tests rÃ©ussis : $($testResults.PassedCount)" -ForegroundColor Green
            Write-Host "  Tests Ã©chouÃ©s : $($testResults.FailedCount)" -ForegroundColor Red
            
            return $false
        }
    }
    catch {
        Write-Host "Erreur lors de l'exÃ©cution des tests : $_" -ForegroundColor Red
        return $false
    }
}

# Fonction pour gÃ©nÃ©rer un script de test unitaire
function Generate-UnitTestScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $true)]
        [string]$TestPath
    )
    
    # Lire le contenu du script
    $scriptContent = Get-Content -Path $ScriptPath -Raw
    
    # Extraire le nom du script
    $scriptName = [System.IO.Path]::GetFileNameWithoutExtension($ScriptPath)
    
    # Analyser le script pour extraire les fonctions
    $functions = @()
    $matches = [regex]::Matches($scriptContent, "function\s+([a-zA-Z0-9_-]+)\s*\{")
    
    foreach ($match in $matches) {
        $functionName = $match.Groups[1].Value
        $functions += $functionName
    }
    
    # CrÃ©er le contenu du script de test
    $testContent = @"
<#
.SYNOPSIS
    Tests unitaires pour le script $scriptName.
.DESCRIPTION
    Ce script contient des tests unitaires pour le script $scriptName
    en utilisant le framework Pester.
#>

# Importer le script Ã  tester
. "$ScriptPath"

Describe "$scriptName" {
    BeforeAll {
        # Code d'initialisation
    }
    
    AfterAll {
        # Code de nettoyage
    }
    
"@
    
    # Ajouter des tests pour chaque fonction
    foreach ($function in $functions) {
        $testContent += @"
    Context "$function" {
        It "Devrait exÃ©cuter $function sans erreur" {
            # Arrange
            
            # Act
            { $function } | Should -Not -Throw
            
            # Assert
            # Ajoutez vos assertions ici
        }
    }
    
"@
    }
    
    # Fermer le bloc Describe
    $testContent += "}"
    
    # CrÃ©er le rÃ©pertoire parent si nÃ©cessaire
    $testDir = Split-Path -Path $TestPath -Parent
    if (-not (Test-Path -Path $testDir)) {
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
    }
    
    # Enregistrer le script de test
    $testContent | Out-File -FilePath $TestPath -Encoding utf8
    
    Write-Host "Script de test gÃ©nÃ©rÃ© : $TestPath" -ForegroundColor Green
    
    return $true
}

# Fonction pour valider les corrections
function Validate-Corrections {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $true)]
        [string]$TestPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Interactive
    )
    
    # Valider la syntaxe du script
    Write-Host "Validation de la syntaxe du script : $ScriptPath" -ForegroundColor Cyan
    $syntaxValid = Test-ScriptSyntax -ScriptPath $ScriptPath
    
    if (-not $syntaxValid) {
        Write-Host "La syntaxe du script est invalide." -ForegroundColor Red
        
        if ($Interactive) {
            $response = Read-Host "Voulez-vous restaurer la sauvegarde ? (O/N)"
            
            if ($response -eq "O" -or $response -eq "o") {
                $backupPath = "$ScriptPath.bak"
                
                if (Test-Path -Path $backupPath) {
                    Copy-Item -Path $backupPath -Destination $ScriptPath -Force
                    Write-Host "Sauvegarde restaurÃ©e." -ForegroundColor Green
                }
                else {
                    Write-Warning "Aucune sauvegarde trouvÃ©e."
                }
            }
        }
        
        return $false
    }
    
    Write-Host "La syntaxe du script est valide." -ForegroundColor Green
    
    # ExÃ©cuter les tests unitaires
    if (Test-Path -Path $TestPath) {
        Write-Host "ExÃ©cution des tests unitaires : $TestPath" -ForegroundColor Cyan
        $testsValid = Invoke-UnitTests -TestPath $TestPath
        
        if (-not $testsValid) {
            Write-Host "Les tests unitaires ont Ã©chouÃ©." -ForegroundColor Red
            
            if ($Interactive) {
                $response = Read-Host "Voulez-vous restaurer la sauvegarde ? (O/N)"
                
                if ($response -eq "O" -or $response -eq "o") {
                    $backupPath = "$ScriptPath.bak"
                    
                    if (Test-Path -Path $backupPath) {
                        Copy-Item -Path $backupPath -Destination $ScriptPath -Force
                        Write-Host "Sauvegarde restaurÃ©e." -ForegroundColor Green
                    }
                    else {
                        Write-Warning "Aucune sauvegarde trouvÃ©e."
                    }
                }
            }
            
            return $false
        }
        
        Write-Host "Les tests unitaires ont rÃ©ussi." -ForegroundColor Green
    }
    else {
        Write-Warning "Aucun script de test trouvÃ© : $TestPath"
    }
    
    # Enregistrer les corrections validÃ©es
    $backupPath = "$ScriptPath.bak"
    
    if (Test-Path -Path $backupPath) {
        # Lire le contenu du script original et du script corrigÃ©
        $originalContent = Get-Content -Path $backupPath -Raw
        $correctedContent = Get-Content -Path $ScriptPath -Raw
        
        # CrÃ©er un ErrorRecord factice pour l'enregistrement
        $exception = New-Object System.Exception("Corrections validÃ©es")
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            $exception,
            "ValidatedCorrection",
            [System.Management.Automation.ErrorCategory]::NotSpecified,
            $null
        )
        
        # Enregistrer les corrections validÃ©es
        Register-PowerShellError -ErrorRecord $errorRecord -Source "ValidationSystem" -Category "ValidatedCorrection" -Solution "Corrections validÃ©es pour le script : $ScriptPath"
        
        Write-Host "Corrections validÃ©es et enregistrÃ©es." -ForegroundColor Green
        
        # Supprimer la sauvegarde si les corrections sont validÃ©es
        Remove-Item -Path $backupPath -Force
        Write-Host "Sauvegarde supprimÃ©e." -ForegroundColor Yellow
    }
    
    return $true
}

# GÃ©nÃ©rer un script de test si demandÃ©
if ($GenerateTestScript) {
    Write-Host "GÃ©nÃ©ration d'un script de test unitaire..." -ForegroundColor Cyan
    
    $result = Generate-UnitTestScript -ScriptPath $ScriptPath -TestPath $TestPath
    
    if ($result) {
        Write-Host "Script de test gÃ©nÃ©rÃ© avec succÃ¨s." -ForegroundColor Green
    }
    else {
        Write-Host "Ã‰chec de la gÃ©nÃ©ration du script de test." -ForegroundColor Red
    }
    
    exit 0
}

# Valider les corrections
Write-Host "Validation des corrections..." -ForegroundColor Cyan

$result = Validate-Corrections -ScriptPath $ScriptPath -TestPath $TestPath -Interactive:$Interactive

if ($result) {
    Write-Host "Validation rÃ©ussie." -ForegroundColor Green
}
else {
    Write-Host "Validation Ã©chouÃ©e." -ForegroundColor Red
}

Write-Host "Validation terminÃ©e." -ForegroundColor Cyan
