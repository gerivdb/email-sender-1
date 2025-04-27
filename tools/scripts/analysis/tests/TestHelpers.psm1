#Requires -Version 5.1
<#
.SYNOPSIS
    Module d'aide pour les tests unitaires du systÃ¨me d'analyse de code.
.DESCRIPTION
    Ce module contient des fonctions d'aide pour les tests unitaires du systÃ¨me d'analyse de code.
#>

# Fonction pour crÃ©er un environnement de test
function New-TestEnvironment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$TestName = "DefaultTest"
    )
    
    # CrÃ©er un rÃ©pertoire temporaire pour les tests
    $testDir = Join-Path -Path $TestDrive -ChildPath $TestName
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
    
    # CrÃ©er un fichier PowerShell de test avec des problÃ¨mes connus
    $testPsPath = Join-Path -Path $testDir -ChildPath "test.ps1"
    $testPsContent = @'
# Test script with known issues
function Test-Function {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Parameter
    )
    
    # TODO: Add more robust error handling
    
    # This line has trailing whitespace    
    
    # FIXME: Fix performance issue
    
    Write-Host "This is a test message"
    
    # HACK: Temporary workaround for bug #123
    
    # NOTE: This function could be improved
}

# Missing BOM encoding
'@
    Set-Content -Path $testPsPath -Value $testPsContent -Encoding UTF8
    
    # CrÃ©er un rÃ©pertoire avec plusieurs fichiers pour tester l'analyse rÃ©cursive
    $subDir = Join-Path -Path $testDir -ChildPath "subdir"
    New-Item -Path $subDir -ItemType Directory -Force | Out-Null
    $testPs2Path = Join-Path -Path $subDir -ChildPath "test2.ps1"
    Set-Content -Path $testPs2Path -Value $testPsContent -Encoding UTF8
    
    # CrÃ©er un fichier HTML pour tester la correction d'encodage
    $testHtmlPath = Join-Path -Path $testDir -ChildPath "test.html"
    $testHtmlContent = @'
<!DOCTYPE html>
<html>
<head>
    <title>Test HTML</title>
    <meta charset="utf-8">
</head>
<body>
    <h1>Test HTML</h1>
    <p>This is a test HTML file with special characters: Ã©Ã¨ÃªÃ«Ã Ã¢Ã¤Ã´Ã¶Ã¹Ã»Ã¼Ã¿Ã§</p>
</body>
</html>
'@
    Set-Content -Path $testHtmlPath -Value $testHtmlContent -Encoding UTF8
    
    # CrÃ©er un fichier JSON pour tester l'intÃ©gration avec des outils tiers
    $testJsonPath = Join-Path -Path $testDir -ChildPath "test-results.json"
    $testJsonContent = @'
[
    {
        "ToolName": "PSScriptAnalyzer",
        "FilePath": "C:\\test\\test.ps1",
        "FileName": "test.ps1",
        "Line": 10,
        "Column": 1,
        "RuleId": "PSAvoidUsingWriteHost",
        "Severity": "Warning",
        "Message": "Avoid using Write-Host",
        "Category": "Best Practice",
        "Suggestion": "Use Write-Output instead",
        "OriginalObject": null
    },
    {
        "ToolName": "TodoAnalyzer",
        "FilePath": "C:\\test\\test.ps1",
        "FileName": "test.ps1",
        "Line": 5,
        "Column": 7,
        "RuleId": "Todo.TODO",
        "Severity": "Information",
        "Message": "TODO: Add more robust error handling",
        "Category": "Documentation",
        "Suggestion": "RÃ©solvez ce TODO ou convertissez-le en tÃ¢che dans le systÃ¨me de suivi des problÃ¨mes.",
        "OriginalObject": null
    },
    {
        "ToolName": "PSScriptAnalyzer",
        "FilePath": "C:\\test\\test.ps1",
        "FileName": "test.ps1",
        "Line": 1,
        "Column": 1,
        "RuleId": "PSUseDeclaredVarsMoreThanAssignments",
        "Severity": "Error",
        "Message": "Variable is assigned but never used",
        "Category": "Best Practice",
        "Suggestion": "Use the variable or remove it",
        "OriginalObject": null
    }
]
'@
    Set-Content -Path $testJsonPath -Value $testJsonContent -Encoding UTF8
    
    # CrÃ©er un sous-rÃ©pertoire pour les fichiers HTML
    $htmlDir = Join-Path -Path $testDir -ChildPath "html"
    New-Item -Path $htmlDir -ItemType Directory -Force | Out-Null
    $testHtml2Path = Join-Path -Path $htmlDir -ChildPath "test2.html"
    Set-Content -Path $testHtml2Path -Value $testHtmlContent -Encoding UTF8
    
    # CrÃ©er un sous-rÃ©pertoire pour les fichiers HTML rÃ©cursifs
    $htmlSubDir = Join-Path -Path $htmlDir -ChildPath "subdir"
    New-Item -Path $htmlSubDir -ItemType Directory -Force | Out-Null
    $testHtml3Path = Join-Path -Path $htmlSubDir -ChildPath "test3.html"
    Set-Content -Path $testHtml3Path -Value $testHtmlContent -Encoding UTF8
    
    # Retourner un objet avec les chemins des fichiers de test
    return [PSCustomObject]@{
        TestDirectory = $testDir
        TestPsFile = $testPsPath
        TestPs2File = $testPs2Path
        TestHtmlFile = $testHtmlPath
        TestHtml2File = $testHtml2Path
        TestHtml3File = $testHtml3Path
        TestJsonFile = $testJsonPath
        HtmlDirectory = $htmlDir
        SubDirectory = $subDir
    }
}

# Fonction pour exÃ©cuter un script avec des paramÃ¨tres
function Invoke-ScriptWithParams {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{}
    )
    
    # VÃ©rifier si le script existe
    if (-not (Test-Path -Path $ScriptPath)) {
        throw "Le script '$ScriptPath' n'existe pas."
    }
    
    # Construire la commande
    $command = "& '$ScriptPath'"
    
    # Ajouter les paramÃ¨tres
    foreach ($key in $Parameters.Keys) {
        $value = $Parameters[$key]
        
        # Traiter les valeurs en fonction de leur type
        if ($value -is [switch]) {
            if ($value) {
                $command += " -$key"
            }
        }
        elseif ($value -is [string]) {
            $command += " -$key '$value'"
        }
        elseif ($value -is [array]) {
            $arrayStr = $value -join "', '"
            $command += " -$key '$arrayStr'"
        }
        else {
            $command += " -$key $value"
        }
    }
    
    # CrÃ©er un bloc de script Ã  partir de la commande
    $scriptBlock = [ScriptBlock]::Create($command)
    
    # ExÃ©cuter le bloc de script
    return & $scriptBlock
}

# Fonction pour crÃ©er un mock de PSScriptAnalyzer
function New-PSScriptAnalyzerMock {
    [CmdletBinding()]
    param ()
    
    # CrÃ©er un mock pour Invoke-ScriptAnalyzer
    function Invoke-ScriptAnalyzer {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [string]$Path,
            
            [Parameter(Mandatory = $false)]
            [string[]]$IncludeRule,
            
            [Parameter(Mandatory = $false)]
            [string[]]$ExcludeRule,
            
            [Parameter(Mandatory = $false)]
            [switch]$Recurse
        )
        
        # Retourner des rÃ©sultats simulÃ©s
        return @(
            [PSCustomObject]@{
                ScriptPath = $Path
                Line = 10
                Column = 1
                RuleName = "PSAvoidUsingWriteHost"
                Severity = "Warning"
                Message = "Avoid using Write-Host"
                RuleSuppressionID = "Best Practice"
            },
            [PSCustomObject]@{
                ScriptPath = $Path
                Line = 1
                Column = 1
                RuleName = "PSUseDeclaredVarsMoreThanAssignments"
                Severity = "Error"
                Message = "Variable is assigned but never used"
                RuleSuppressionID = "Best Practice"
            }
        )
    }
    
    # Exporter la fonction
    Export-ModuleMember -Function Invoke-ScriptAnalyzer
}

# Fonction pour crÃ©er un mock de New-UnifiedAnalysisResult
function New-UnifiedAnalysisResultMock {
    [CmdletBinding()]
    param ()
    
    # CrÃ©er un mock pour New-UnifiedAnalysisResult
    function New-UnifiedAnalysisResult {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [string]$ToolName,
            
            [Parameter(Mandatory = $true)]
            [string]$FilePath,
            
            [Parameter(Mandatory = $true)]
            [int]$Line,
            
            [Parameter(Mandatory = $true)]
            [int]$Column,
            
            [Parameter(Mandatory = $true)]
            [string]$RuleId,
            
            [Parameter(Mandatory = $true)]
            [string]$Severity,
            
            [Parameter(Mandatory = $true)]
            [string]$Message,
            
            [Parameter(Mandatory = $false)]
            [string]$Category,
            
            [Parameter(Mandatory = $false)]
            [string]$Suggestion,
            
            [Parameter(Mandatory = $false)]
            [object]$OriginalObject
        )
        
        # Retourner un objet simulÃ©
        return [PSCustomObject]@{
            ToolName = $ToolName
            FilePath = $FilePath
            FileName = [System.IO.Path]::GetFileName($FilePath)
            Line = $Line
            Column = $Column
            RuleId = $RuleId
            Severity = $Severity
            Message = $Message
            Category = $Category
            Suggestion = $Suggestion
            OriginalObject = $OriginalObject
        }
    }
    
    # Exporter la fonction
    Export-ModuleMember -Function New-UnifiedAnalysisResult
}

# Exporter les fonctions
Export-ModuleMember -Function New-TestEnvironment, Invoke-ScriptWithParams, New-PSScriptAnalyzerMock, New-UnifiedAnalysisResultMock
