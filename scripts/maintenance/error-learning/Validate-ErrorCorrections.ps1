<#
.SYNOPSIS
    Script de validation des corrections d'erreurs PowerShell.
.DESCRIPTION
    Ce script valide les corrections appliquées aux scripts PowerShell
    en vérifiant leur syntaxe et en exécutant des tests unitaires.
.PARAMETER ScriptPath
    Chemin du script à valider.
.PARAMETER TestPath
    Chemin du script de test unitaire associé.
.PARAMETER GenerateTestScript
    Si spécifié, génère un script de test unitaire pour le script spécifié.
.PARAMETER Interactive
    Si spécifié, active le mode interactif qui demande confirmation avant d'appliquer les corrections.
.EXAMPLE
    .\Validate-ErrorCorrections.ps1 -ScriptPath "C:\Scripts\MonScript.ps1" -TestPath "C:\Scripts\Tests\MonScript.Tests.ps1"
    Valide les corrections appliquées au script en exécutant les tests unitaires.
.EXAMPLE
    .\Validate-ErrorCorrections.ps1 -ScriptPath "C:\Scripts\MonScript.ps1" -GenerateTestScript
    Génère un script de test unitaire pour le script spécifié.
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

# Initialiser le système
Initialize-ErrorLearningSystem

# Vérifier si le script existe
if (-not (Test-Path -Path $ScriptPath)) {
    Write-Error "Le script spécifié n'existe pas : $ScriptPath"
    exit 1
}

# Définir le chemin du script de test par défaut
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
            Write-Host "Erreurs de syntaxe détectées :" -ForegroundColor Red
            
            foreach ($error in $errors) {
                Write-Host "  Ligne $($error.Token.StartLine), colonne $($error.Token.StartColumn) : $($error.Message)" -ForegroundColor Red
            }
            
            return $false
        }
        
        # Vérifier la syntaxe avec le compilateur PowerShell
        $null = [ScriptBlock]::Create($scriptContent)
        
        return $true
    }
    catch {
        Write-Host "Erreur lors de la validation de la syntaxe : $_" -ForegroundColor Red
        return $false
    }
}

# Fonction pour exécuter des tests unitaires
function Invoke-UnitTests {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestPath
    )
    
    # Vérifier si le script de test existe
    if (-not (Test-Path -Path $TestPath)) {
        Write-Warning "Le script de test spécifié n'existe pas : $TestPath"
        return $false
    }
    
    # Vérifier si Pester est installé
    if (-not (Get-Module -Name Pester -ListAvailable)) {
        Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }
    
    # Importer Pester
    Import-Module Pester -Force
    
    try {
        # Exécuter les tests
        $testResults = Invoke-Pester -Path $TestPath -PassThru
        
        if ($testResults.FailedCount -eq 0) {
            Write-Host "Tous les tests ont réussi." -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "Certains tests ont échoué :" -ForegroundColor Red
            Write-Host "  Tests réussis : $($testResults.PassedCount)" -ForegroundColor Green
            Write-Host "  Tests échoués : $($testResults.FailedCount)" -ForegroundColor Red
            
            return $false
        }
    }
    catch {
        Write-Host "Erreur lors de l'exécution des tests : $_" -ForegroundColor Red
        return $false
    }
}

# Fonction pour générer un script de test unitaire
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
    
    # Créer le contenu du script de test
    $testContent = @"
<#
.SYNOPSIS
    Tests unitaires pour le script $scriptName.
.DESCRIPTION
    Ce script contient des tests unitaires pour le script $scriptName
    en utilisant le framework Pester.
#>

# Importer le script à tester
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
        It "Devrait exécuter $function sans erreur" {
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
    
    # Créer le répertoire parent si nécessaire
    $testDir = Split-Path -Path $TestPath -Parent
    if (-not (Test-Path -Path $testDir)) {
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
    }
    
    # Enregistrer le script de test
    $testContent | Out-File -FilePath $TestPath -Encoding utf8
    
    Write-Host "Script de test généré : $TestPath" -ForegroundColor Green
    
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
                    Write-Host "Sauvegarde restaurée." -ForegroundColor Green
                }
                else {
                    Write-Warning "Aucune sauvegarde trouvée."
                }
            }
        }
        
        return $false
    }
    
    Write-Host "La syntaxe du script est valide." -ForegroundColor Green
    
    # Exécuter les tests unitaires
    if (Test-Path -Path $TestPath) {
        Write-Host "Exécution des tests unitaires : $TestPath" -ForegroundColor Cyan
        $testsValid = Invoke-UnitTests -TestPath $TestPath
        
        if (-not $testsValid) {
            Write-Host "Les tests unitaires ont échoué." -ForegroundColor Red
            
            if ($Interactive) {
                $response = Read-Host "Voulez-vous restaurer la sauvegarde ? (O/N)"
                
                if ($response -eq "O" -or $response -eq "o") {
                    $backupPath = "$ScriptPath.bak"
                    
                    if (Test-Path -Path $backupPath) {
                        Copy-Item -Path $backupPath -Destination $ScriptPath -Force
                        Write-Host "Sauvegarde restaurée." -ForegroundColor Green
                    }
                    else {
                        Write-Warning "Aucune sauvegarde trouvée."
                    }
                }
            }
            
            return $false
        }
        
        Write-Host "Les tests unitaires ont réussi." -ForegroundColor Green
    }
    else {
        Write-Warning "Aucun script de test trouvé : $TestPath"
    }
    
    # Enregistrer les corrections validées
    $backupPath = "$ScriptPath.bak"
    
    if (Test-Path -Path $backupPath) {
        # Lire le contenu du script original et du script corrigé
        $originalContent = Get-Content -Path $backupPath -Raw
        $correctedContent = Get-Content -Path $ScriptPath -Raw
        
        # Créer un ErrorRecord factice pour l'enregistrement
        $exception = New-Object System.Exception("Corrections validées")
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            $exception,
            "ValidatedCorrection",
            [System.Management.Automation.ErrorCategory]::NotSpecified,
            $null
        )
        
        # Enregistrer les corrections validées
        Register-PowerShellError -ErrorRecord $errorRecord -Source "ValidationSystem" -Category "ValidatedCorrection" -Solution "Corrections validées pour le script : $ScriptPath"
        
        Write-Host "Corrections validées et enregistrées." -ForegroundColor Green
        
        # Supprimer la sauvegarde si les corrections sont validées
        Remove-Item -Path $backupPath -Force
        Write-Host "Sauvegarde supprimée." -ForegroundColor Yellow
    }
    
    return $true
}

# Générer un script de test si demandé
if ($GenerateTestScript) {
    Write-Host "Génération d'un script de test unitaire..." -ForegroundColor Cyan
    
    $result = Generate-UnitTestScript -ScriptPath $ScriptPath -TestPath $TestPath
    
    if ($result) {
        Write-Host "Script de test généré avec succès." -ForegroundColor Green
    }
    else {
        Write-Host "Échec de la génération du script de test." -ForegroundColor Red
    }
    
    exit 0
}

# Valider les corrections
Write-Host "Validation des corrections..." -ForegroundColor Cyan

$result = Validate-Corrections -ScriptPath $ScriptPath -TestPath $TestPath -Interactive:$Interactive

if ($result) {
    Write-Host "Validation réussie." -ForegroundColor Green
}
else {
    Write-Host "Validation échouée." -ForegroundColor Red
}

Write-Host "Validation terminée." -ForegroundColor Cyan
