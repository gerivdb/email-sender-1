<#
.SYNOPSIS
    Tests unitaires pour la fonctionnalitÃ© de validation des corrections du systÃ¨me d'apprentissage des erreurs.
.DESCRIPTION
    Ce script contient des tests unitaires pour la fonctionnalitÃ© de validation des corrections du systÃ¨me d'apprentissage des erreurs.
.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
#>

# DÃ©finir les tests Pester
Describe "Tests de validation des corrections" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire temporaire pour les tests
        $script:testRoot = Join-Path -Path $env:TEMP -ChildPath "ValidationCorrectionsTests"
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
        New-Item -Path $script:testRoot -ItemType Directory -Force | Out-Null
        
        # CrÃ©er un script valide
        $script:validScriptPath = Join-Path -Path $script:testRoot -ChildPath "ValidScript.ps1"
        $validScriptContent = @"
# Script valide
function Get-TestData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$Path
    )
    
    try {
        `$content = Get-Content -Path `$Path -ErrorAction Stop
        return `$content
    }
    catch {
        Write-Error "Erreur lors de la lecture du fichier: `$_"
        return `$null
    }
}

# Appeler la fonction
`$logPath = Join-Path -Path `$PSScriptRoot -ChildPath "logs\app.log"
`$data = Get-TestData -Path `$logPath
Write-Output "DonnÃ©es chargÃ©es: `$(`$data.Count) lignes"
"@
        Set-Content -Path $script:validScriptPath -Value $validScriptContent
        
        # CrÃ©er un script invalide
        $script:invalidScriptPath = Join-Path -Path $script:testRoot -ChildPath "InvalidScript.ps1"
        $invalidScriptContent = @"
# Script invalide
function Get-TestData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$Path
    )
    
    try {
        `$content = Get-Content -Path `$Path -ErrorAction Stop
        return `$content
    }
    catch {
        Write-Error "Erreur lors de la lecture du fichier: `$_"
        return `$null
    }
# Accolade fermante manquante

# Appeler la fonction
`$logPath = Join-Path -Path `$PSScriptRoot -ChildPath "logs\app.log"
`$data = Get-TestData -Path `$logPath
Write-Output "DonnÃ©es chargÃ©es: `$(`$data.Count) lignes"
"@
        Set-Content -Path $script:invalidScriptPath -Value $invalidScriptContent
    }
    
    Context "Validation de la syntaxe" {
        It "Devrait valider un script syntaxiquement correct" {
            # Valider la syntaxe du script
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($script:validScriptPath, [ref]$null, [ref]$errors)
            
            # VÃ©rifier que la syntaxe est valide
            $errors | Should -BeNullOrEmpty
            $ast | Should -Not -BeNullOrEmpty
        }
        
        It "Devrait dÃ©tecter les erreurs de syntaxe" {
            # Valider la syntaxe du script
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($script:invalidScriptPath, [ref]$null, [ref]$errors)
            
            # VÃ©rifier que des erreurs de syntaxe sont dÃ©tectÃ©es
            $errors | Should -Not -BeNullOrEmpty
            $errors.Count | Should -BeGreaterThan 0
        }
    }
    
    Context "Validation des bonnes pratiques" {
        It "Devrait valider les bonnes pratiques dans un script" {
            # CrÃ©er un script avec des bonnes pratiques
            $bestPracticesScriptPath = Join-Path -Path $script:testRoot -ChildPath "BestPracticesScript.ps1"
            $bestPracticesScriptContent = @"
# Script avec des bonnes pratiques
[CmdletBinding()]
param (
    [Parameter(Mandatory = `$true)]
    [string]`$Path
)

# Utiliser des variables dÃ©clarÃ©es
[string]`$logFile = Join-Path -Path `$Path -ChildPath "app.log"

# Utiliser try/catch pour la gestion des erreurs
try {
    `$content = Get-Content -Path `$logFile -ErrorAction Stop
    Write-Output "Contenu chargÃ©: `$(`$content.Count) lignes"
}
catch {
    Write-Error "Erreur lors de la lecture du fichier: `$_"
}
"@
            Set-Content -Path $bestPracticesScriptPath -Value $bestPracticesScriptContent
            
            # Valider les bonnes pratiques
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($bestPracticesScriptPath, [ref]$null, [ref]$errors)
            
            # VÃ©rifier que la syntaxe est valide
            $errors | Should -BeNullOrEmpty
            $ast | Should -Not -BeNullOrEmpty
            
            # VÃ©rifier les bonnes pratiques
            $hasCmdletBinding = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.AttributeAst] -and $args[0].TypeName.Name -eq "CmdletBinding" }, $true).Count -gt 0
            $hasParameter = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.ParameterAst] }, $true).Count -gt 0
            $hasTryCatch = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.TryStatementAst] }, $true).Count -gt 0
            $hasErrorAction = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandParameterAst] -and $args[0].ParameterName -eq "ErrorAction" }, $true).Count -gt 0
            
            $hasCmdletBinding | Should -BeTrue
            $hasParameter | Should -BeTrue
            $hasTryCatch | Should -BeTrue
            $hasErrorAction | Should -BeTrue
        }
        
        It "Devrait dÃ©tecter les mauvaises pratiques dans un script" {
            # CrÃ©er un script avec des mauvaises pratiques
            $badPracticesScriptPath = Join-Path -Path $script:testRoot -ChildPath "BadPracticesScript.ps1"
            $badPracticesScriptContent = @"
# Script avec des mauvaises pratiques
# Pas de CmdletBinding
# Pas de paramÃ¨tres

# Utiliser des chemins codÃ©s en dur
`$logFile = "C:\Logs\app.log"

# Pas de gestion des erreurs
`$content = Get-Content -Path `$logFile
Write-Host "Contenu chargÃ©: `$(`$content.Count) lignes"
"@
            Set-Content -Path $badPracticesScriptPath -Value $badPracticesScriptContent
            
            # Valider les bonnes pratiques
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($badPracticesScriptPath, [ref]$null, [ref]$errors)
            
            # VÃ©rifier que la syntaxe est valide
            $errors | Should -BeNullOrEmpty
            $ast | Should -Not -BeNullOrEmpty
            
            # VÃ©rifier les mauvaises pratiques
            $hasCmdletBinding = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.AttributeAst] -and $args[0].TypeName.Name -eq "CmdletBinding" }, $true).Count -gt 0
            $hasParameter = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.ParameterAst] }, $true).Count -gt 0
            $hasTryCatch = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.TryStatementAst] }, $true).Count -gt 0
            $hasErrorAction = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandParameterAst] -and $args[0].ParameterName -eq "ErrorAction" }, $true).Count -gt 0
            $hasHardcodedPath = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] -and $args[0].Value -match "^[A-Z]:\\" }, $true).Count -gt 0
            $hasWriteHost = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] -and $args[0].CommandElements[0].Value -eq "Write-Host" }, $true).Count -gt 0
            
            $hasCmdletBinding | Should -BeFalse
            $hasParameter | Should -BeFalse
            $hasTryCatch | Should -BeFalse
            $hasErrorAction | Should -BeFalse
            $hasHardcodedPath | Should -BeTrue
            $hasWriteHost | Should -BeTrue
        }
    }
    
    Context "Validation des corrections" {
        It "Devrait valider les corrections appliquÃ©es Ã  un script" {
            # CrÃ©er un script avec des erreurs
            $scriptWithErrorsPath = Join-Path -Path $script:testRoot -ChildPath "ScriptWithErrors.ps1"
            $scriptWithErrorsContent = @"
# Script avec des erreurs
`$logPath = "D:\Logs\app.log"
Write-Host "Log Path: `$logPath"

# Absence de gestion d'erreurs
`$content = Get-Content -Path "C:\config.txt"

# Utilisation de cmdlet obsolÃ¨te
`$processes = Get-WmiObject -Class Win32_Process
"@
            Set-Content -Path $scriptWithErrorsPath -Value $scriptWithErrorsContent
            
            # CrÃ©er un script corrigÃ©
            $correctedScriptPath = Join-Path -Path $script:testRoot -ChildPath "CorrectedScript.ps1"
            $correctedScriptContent = @"
# Script corrigÃ©
`$logPath = Join-Path -Path `$PSScriptRoot -ChildPath "logs\app.log"
Write-Output "Log Path: `$logPath"

# Ajout de gestion d'erreurs
try {
    `$content = Get-Content -Path (Join-Path -Path `$PSScriptRoot -ChildPath "config.txt") -ErrorAction Stop
}
catch {
    Write-Error "Erreur lors de la lecture du fichier: `$_"
}

# Utilisation de cmdlet moderne
`$processes = Get-CimInstance -ClassName Win32_Process
"@
            Set-Content -Path $correctedScriptPath -Value $correctedScriptContent
            
            # Valider les corrections
            $errorsOriginal = $null
            $astOriginal = [System.Management.Automation.Language.Parser]::ParseFile($scriptWithErrorsPath, [ref]$null, [ref]$errorsOriginal)
            
            $errorsCorrected = $null
            $astCorrected = [System.Management.Automation.Language.Parser]::ParseFile($correctedScriptPath, [ref]$null, [ref]$errorsCorrected)
            
            # VÃ©rifier que les scripts sont valides
            $errorsOriginal | Should -BeNullOrEmpty
            $errorsCorrected | Should -BeNullOrEmpty
            
            # VÃ©rifier les corrections
            $originalHasHardcodedPath = $astOriginal.FindAll({ $args[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] -and $args[0].Value -match "^[A-Z]:\\" }, $true).Count -gt 0
            $originalHasWriteHost = $astOriginal.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] -and $args[0].CommandElements[0].Value -eq "Write-Host" }, $true).Count -gt 0
            $originalHasWmiObject = $astOriginal.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] -and $args[0].CommandElements[0].Value -eq "Get-WmiObject" }, $true).Count -gt 0
            
            $correctedHasHardcodedPath = $astCorrected.FindAll({ $args[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] -and $args[0].Value -match "^[A-Z]:\\" }, $true).Count -gt 0
            $correctedHasWriteHost = $astCorrected.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] -and $args[0].CommandElements[0].Value -eq "Write-Host" }, $true).Count -gt 0
            $correctedHasWmiObject = $astCorrected.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] -and $args[0].CommandElements[0].Value -eq "Get-WmiObject" }, $true).Count -gt 0
            $correctedHasJoinPath = $astCorrected.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] -and $args[0].CommandElements[0].Value -eq "Join-Path" }, $true).Count -gt 0
            $correctedHasWriteOutput = $astCorrected.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] -and $args[0].CommandElements[0].Value -eq "Write-Output" }, $true).Count -gt 0
            $correctedHasCimInstance = $astCorrected.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] -and $args[0].CommandElements[0].Value -eq "Get-CimInstance" }, $true).Count -gt 0
            $correctedHasTryCatch = $astCorrected.FindAll({ $args[0] -is [System.Management.Automation.Language.TryStatementAst] }, $true).Count -gt 0
            
            $originalHasHardcodedPath | Should -BeTrue
            $originalHasWriteHost | Should -BeTrue
            $originalHasWmiObject | Should -BeTrue
            
            $correctedHasHardcodedPath | Should -BeFalse
            $correctedHasWriteHost | Should -BeFalse
            $correctedHasWmiObject | Should -BeFalse
            $correctedHasJoinPath | Should -BeTrue
            $correctedHasWriteOutput | Should -BeTrue
            $correctedHasCimInstance | Should -BeTrue
            $correctedHasTryCatch | Should -BeTrue
        }
    }
    
    AfterAll {
        # Supprimer le rÃ©pertoire de test
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
    }
}
