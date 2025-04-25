<#
.SYNOPSIS
    Tests unitaires pour les fonctions d'analyse de stack trace.

.DESCRIPTION
    Ce script contient des tests unitaires pour les fonctions d'analyse de stack trace
    du mode DEBUG.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2025-04-25
#>

# Importer le module Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Chemin vers le fichier de fonctions à tester
$functionsPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) -ChildPath "module\Functions\Private\Debugging\StackTraceAnalysisFunctions.ps1"

# Vérifier si le fichier existe
if (-not (Test-Path -Path $functionsPath)) {
    throw "Le fichier de fonctions n'existe pas : $functionsPath"
}

# Importer les fonctions à tester
. $functionsPath

# Créer un fichier temporaire pour les tests
$testScriptPath = Join-Path -Path $env:TEMP -ChildPath "TestScript.ps1"
@"
function Test-Function1 {
    param([int]`$value)
    Test-Function2 -value `$value
}

function Test-Function2 {
    param([int]`$value)
    Test-Function3 -value `$value
}

function Test-Function3 {
    param([int]`$value)
    1 / `$value
}

# Appeler la fonction avec une valeur qui provoquera une erreur
Test-Function1 -value 0
"@ | Out-File -FilePath $testScriptPath -Encoding UTF8

# Créer une stack trace de test
$testStackTrace = @"
At C:\Temp\TestScript.ps1:13 char:1
+ Test-Function1 -value 0
+ ~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [], RuntimeException
    + FullyQualifiedErrorId : RuntimeException

At C:\Temp\TestScript.ps1:3 char:5
+     Test-Function2 -value `$value
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [], RuntimeException
    + FullyQualifiedErrorId : RuntimeException

At C:\Temp\TestScript.ps1:8 char:5
+     Test-Function3 -value `$value
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [], RuntimeException
    + FullyQualifiedErrorId : RuntimeException

At C:\Temp\TestScript.ps1:13 char:5
+     1 / `$value
+     ~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [], RuntimeException
    + FullyQualifiedErrorId : RuntimeException
"@

# Créer un objet ErrorRecord de test
$testException = New-Object System.DivideByZeroException "Tentative de division par zéro."
$testErrorRecord = New-Object System.Management.Automation.ErrorRecord(
    $testException,
    "DivideByZero",
    [System.Management.Automation.ErrorCategory]::InvalidOperation,
    $null
)
$testErrorRecord.InvocationInfo = New-Object System.Management.Automation.InvocationInfo(
    (New-Object System.Management.Automation.CommandInfo("Test-Function3", [System.Management.Automation.CommandTypes]::Function)),
    (New-Object System.Management.Automation.PSToken)
)
$testErrorRecord.InvocationInfo.ScriptName = $testScriptPath
$testErrorRecord.InvocationInfo.ScriptLineNumber = 13
$testErrorRecord.InvocationInfo.OffsetInLine = 5
$testErrorRecord.InvocationInfo.Line = "    1 / `$value"
$testErrorRecord.ScriptStackTrace = $testStackTrace

# Exécuter les tests
Describe "Tests des fonctions d'analyse de stack trace" {
    Context "Get-StackTraceInfo" {
        It "Devrait parser une stack trace sous forme de chaîne" {
            $result = Get-StackTraceInfo -StackTrace $testStackTrace
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
            $result[0].File | Should -Be "C:\Temp\TestScript.ps1"
            $result[0].Line | Should -Be 13
        }

        It "Devrait parser un objet ErrorRecord" {
            $result = Get-StackTraceInfo -StackTrace $testErrorRecord
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
            $result[0].ErrorMessage | Should -Not -BeNullOrEmpty
        }
    }

    Context "Get-StackTraceLineInfo" {
        It "Devrait extraire les informations de ligne" {
            # Remplacer le chemin du fichier dans la stack trace
            $modifiedStackTrace = $testStackTrace -replace "C:\\Temp\\TestScript\.ps1", $testScriptPath
            
            $result = Get-StackTraceLineInfo -StackTrace $modifiedStackTrace
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
            
            # Vérifier si le contenu de la ligne est extrait
            $result[0].LineContent | Should -Not -BeNullOrEmpty
            $result[0].Context | Should -Not -BeNullOrEmpty
        }
    }

    Context "Resolve-StackTracePaths" {
        It "Devrait résoudre les chemins de fichiers" {
            # Créer une stack trace avec un chemin relatif
            $relativeStackTrace = $testStackTrace -replace "C:\\Temp\\TestScript\.ps1", "TestScript.ps1"
            
            $result = Resolve-StackTracePaths -StackTrace $relativeStackTrace -BasePath $env:TEMP
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
            
            # Vérifier si le chemin a été résolu
            $result[0].File | Should -Be $testScriptPath
        }
    }

    Context "Get-StackTraceCallSequence" {
        It "Devrait analyser la séquence d'appels" {
            $result = Get-StackTraceCallSequence -StackTrace $testStackTrace
            $result | Should -Not -BeNullOrEmpty
            $result.CallPath | Should -Not -BeNullOrEmpty
            $result.CallDepth | Should -BeGreaterThan 0
            $result.CallGraph | Should -Not -BeNullOrEmpty
        }
    }

    Context "Show-StackTraceHierarchy" {
        It "Devrait générer une visualisation en format texte" {
            $result = Show-StackTraceHierarchy -StackTrace $testStackTrace -Format "Text"
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match "Stack Trace Hierarchy"
        }

        It "Devrait générer une visualisation en format HTML" {
            $result = Show-StackTraceHierarchy -StackTrace $testStackTrace -Format "HTML"
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match "<div class='stack-trace'>"
        }

        It "Devrait générer une visualisation en format Markdown" {
            $result = Show-StackTraceHierarchy -StackTrace $testStackTrace -Format "Markdown"
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match "# Stack Trace Hierarchy"
        }
    }
}

# Nettoyer les fichiers temporaires
Remove-Item -Path $testScriptPath -Force -ErrorAction SilentlyContinue
