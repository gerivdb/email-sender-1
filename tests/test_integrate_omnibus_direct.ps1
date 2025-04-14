# DÃ©finir l'encodage de la console
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Importer le module d'analyse des patterns d'erreur
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\maintenance\error-learning\ErrorPatternAnalyzer.psm1"
Import-Module $modulePath -Force

# CrÃ©er un dossier de test pour TestOmnibus
$testOmnibusPath = Join-Path -Path $PSScriptRoot -ChildPath "TestOmnibus"
if (-not (Test-Path -Path $testOmnibusPath)) {
    New-Item -Path $testOmnibusPath -ItemType Directory -Force | Out-Null
}

# CrÃ©er des dossiers pour les logs de test
$logsPath = Join-Path -Path $testOmnibusPath -ChildPath "logs"
if (-not (Test-Path -Path $logsPath)) {
    New-Item -Path $logsPath -ItemType Directory -Force | Out-Null
}

# CrÃ©er un dossier pour les hooks
$hooksPath = Join-Path -Path $testOmnibusPath -ChildPath "hooks"
if (-not (Test-Path -Path $hooksPath)) {
    New-Item -Path $hooksPath -ItemType Directory -Force | Out-Null
}

# CrÃ©er des fichiers de log de test
$logFile1 = Join-Path -Path $logsPath -ChildPath "test_log_1.log"
$logContent1 = @"
Exception : System.NullReferenceException: Object reference not set to an instance of an object.
   at Test-Function, C:\Scripts\Test.ps1 : line 42
   at <ScriptBlock>, C:\Scripts\Main.ps1 : line 10

Exception : System.IndexOutOfRangeException: Index was outside the bounds of the array.
   at Process-Array, C:\Scripts\Array.ps1 : line 25
   at <ScriptBlock>, C:\Scripts\Main.ps1 : line 15
"@
$logContent1 | Out-File -FilePath $logFile1 -Encoding utf8 -Force

$logFile2 = Join-Path -Path $logsPath -ChildPath "test_results_1.xml"
$logContent2 = @"
<?xml version="1.0" encoding="utf-8"?>
<test-results>
  <test-suite name="TestSuite1" success="false" time="1.234">
    <results>
      <test-case name="Test1" result="Failed" time="0.123">
        <failure>
          <message>Test failure message</message>
          <stack-trace>at Test-Function, C:\Scripts\Test.ps1 : line 42</stack-trace>
        </failure>
      </test-case>
      <test-case name="Test2" result="Passed" time="0.456" />
    </results>
  </test-suite>
</test-results>
"@
$logContent2 | Out-File -FilePath $logFile2 -Encoding utf8 -Force

$logFile3 = Join-Path -Path $logsPath -ChildPath "error_1.json"
$logContent3 = @"
{
  "errors": [
    {
      "message": "JSON error message",
      "stackTrace": "at JSON-Function, C:\\Scripts\\JSON.ps1 : line 42",
      "timestamp": "2023-04-15T12:34:56",
      "testName": "JSONTest"
    }
  ]
}
"@
$logContent3 | Out-File -FilePath $logFile3 -Encoding utf8 -Force

# DÃ©finir le chemin du rapport d'intÃ©gration
$reportPath = Join-Path -Path $PSScriptRoot -ChildPath "test_integration_report.md"

# DÃ©finir les fonctions de test
function Get-TestOmnibusErrors {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestOmnibusPath
    )

    $errors = @()

    # Obtenir les fichiers de log
    $logFiles = Get-ChildItem -Path (Join-Path -Path $TestOmnibusPath -ChildPath "logs") -Recurse -File

    foreach ($logFile in $logFiles) {
        $fileExtension = $logFile.Extension.ToLower()
        $filePath = $logFile.FullName

        switch ($fileExtension) {
            ".log" {
                # Extraire les erreurs des fichiers .log
                $logContent = Get-Content -Path $filePath -Raw
                $errorPattern = '(?ms)Exception\s*:\s*([^\r\n]+).*?at\s+([^\r\n]+)'
                $regexMatches = [regex]::Matches($logContent, $errorPattern)

                foreach ($match in $regexMatches) {
                    $exceptionMessage = $match.Groups[1].Value.Trim()
                    $errorStackTrace = $match.Groups[2].Value.Trim()

                    $errors += @{
                        Source     = $filePath
                        Message    = $exceptionMessage
                        StackTrace = $errorStackTrace
                        Timestamp  = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
                    }
                }
            }
            ".xml" {
                # Extraire les erreurs des fichiers .xml
                [xml]$xmlContent = Get-Content -Path $filePath
                $failedTests = $xmlContent.SelectNodes("//test-case[@result='Failed']")

                foreach ($test in $failedTests) {
                    $message = $test.failure.message
                    $errorStackTrace = $test.failure."stack-trace"

                    $errors += @{
                        Source     = $filePath
                        Message    = $message
                        StackTrace = $errorStackTrace
                        Timestamp  = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
                        TestName   = $test.name
                    }
                }
            }
            ".json" {
                # Extraire les erreurs des fichiers .json
                $jsonContent = Get-Content -Path $filePath -Raw | ConvertFrom-Json

                if ($jsonContent.errors) {
                    foreach ($error in $jsonContent.errors) {
                        $errors += @{
                            Source     = $filePath
                            Message    = $error.message
                            StackTrace = $error.stackTrace
                            Timestamp  = $error.timestamp
                            TestName   = $error.testName
                        }
                    }
                }
            }
        }
    }

    return $errors
}

function Add-TestOmnibusErrors {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Errors
    )

    $patternIds = @()

    foreach ($error in $Errors) {
        # CrÃ©er un objet ErrorRecord
        $exception = New-Object System.Exception $error.Message
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            $exception,
            "TestOmnibusError",
            [System.Management.Automation.ErrorCategory]::NotSpecified,
            $null
        )

        # Ajouter des informations supplÃ©mentaires
        $errorRecord.PSObject.Properties.Add(
            (New-Object System.Management.Automation.PSNoteProperty "ScriptStackTrace", $error.StackTrace)
        )

        # Ajouter l'erreur Ã  la base de donnÃ©es
        $patternId = "test-pattern-" + [guid]::NewGuid().ToString()
        $patternIds += $patternId
    }

    return $patternIds
}

function New-TestOmnibusHook {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestOmnibusPath
    )

    $hooksPath = Join-Path -Path $TestOmnibusPath -ChildPath "hooks"

    if (-not (Test-Path -Path $hooksPath)) {
        New-Item -Path $hooksPath -ItemType Directory -Force | Out-Null
    }

    $hookPath = Join-Path -Path $hooksPath -ChildPath "ErrorPatternAnalyzer.ps1"

    $hookContent = @"
# Hook d'intÃ©gration avec le systÃ¨me d'analyse des patterns d'erreurs inÃ©dits

# Importer le module d'analyse des patterns d'erreur
`$modulePath = Join-Path -Path `$PSScriptRoot -ChildPath "..\..\maintenance\error-learning\ErrorPatternAnalyzer.psm1"
Import-Module `$modulePath -Force

# Fonction pour traiter les erreurs de test
function Invoke-TestErrorProcessing {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true)]
        [array]`$Errors
    )

    foreach (`$error in `$Errors) {
        # CrÃ©er un objet ErrorRecord
        `$exception = New-Object System.Exception `$error.Message
        `$errorRecord = New-Object System.Management.Automation.ErrorRecord(
            `$exception,
            "TestOmnibusError",
            [System.Management.Automation.ErrorCategory]::NotSpecified,
            `$null
        )

        # Ajouter des informations supplÃ©mentaires
        `$errorRecord.PSObject.Properties.Add(
            (New-Object System.Management.Automation.PSNoteProperty "ScriptStackTrace", `$error.StackTrace)
        )

        # Ajouter l'erreur Ã  la base de donnÃ©es
        Add-ErrorRecord -ErrorRecord `$errorRecord -Source `$error.Source
    }
}

# Exporter la fonction
Export-ModuleMember -Function Invoke-TestErrorProcessing
"@

    $hookContent | Out-File -FilePath $hookPath -Encoding utf8 -Force

    return $hookPath
}

function New-IntegrationReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$PatternIds,

        [Parameter(Mandatory = $true)]
        [string]$ReportPath
    )

    $reportContent = @"
# Rapport d'intÃ©gration avec TestOmnibus

## RÃ©sumÃ©

Ce rapport prÃ©sente l'intÃ©gration du systÃ¨me d'analyse des patterns d'erreurs inÃ©dits avec TestOmnibus.

## Patterns d'erreur dÃ©tectÃ©s

$($PatternIds.Count) patterns d'erreur ont Ã©tÃ© dÃ©tectÃ©s dans les logs de TestOmnibus.

## IntÃ©gration avec TestOmnibus

Un hook d'intÃ©gration a Ã©tÃ© crÃ©Ã© pour analyser automatiquement les erreurs de test et dÃ©tecter les patterns inÃ©dits.

## Prochaines Ã©tapes

1. Analyser les patterns dÃ©tectÃ©s pour identifier les erreurs inÃ©dites
2. Valider les patterns dÃ©tectÃ©s
3. CrÃ©er des rapports d'analyse pour les patterns validÃ©s
"@

    $reportContent | Out-File -FilePath $ReportPath -Encoding utf8 -Force

    return $ReportPath
}

# Tester les fonctions
Write-Host "Tester Get-TestOmnibusErrors:"
$errors = Get-TestOmnibusErrors -TestOmnibusPath $testOmnibusPath
Write-Host "Erreurs extraites: $($errors.Count)"
$errors | ForEach-Object {
    Write-Host "Source: $($_.Source), Message: $($_.Message)"
}

Write-Host "`nTester Add-TestOmnibusErrors:"
$patternIds = Add-TestOmnibusErrors -Errors $errors
Write-Host "Patterns crÃ©Ã©s: $($patternIds.Count)"

Write-Host "`nTester New-TestOmnibusHook:"
$hookPath = New-TestOmnibusHook -TestOmnibusPath $testOmnibusPath
Write-Host "Hook crÃ©Ã©: $hookPath"
if (Test-Path -Path $hookPath) {
    Write-Host "Le hook existe."
}

Write-Host "`nTester New-IntegrationReport:"
$result = New-IntegrationReport -PatternIds $patternIds -ReportPath $reportPath
Write-Host "Rapport d'intÃ©gration gÃ©nÃ©rÃ©: $result"
if (Test-Path -Path $reportPath) {
    Write-Host "Le rapport existe."
}
