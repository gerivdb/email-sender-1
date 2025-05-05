# DÃ©finir les paramÃ¨tres
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\development\scripts\maintenance\error-learning\Integrate-WithTestOmnibus.ps1"

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
$logContent1 | Out-File -FilePath $logFile1 -Encoding utf8

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
$logContent2 | Out-File -FilePath $logFile2 -Encoding utf8

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
$logContent3 | Out-File -FilePath $logFile3 -Encoding utf8

# CrÃ©er une base de donnÃ©es de test
$databasePath = Join-Path -Path $PSScriptRoot -ChildPath "test_error_database.json"
$reportPath = Join-Path -Path $PSScriptRoot -ChildPath "test_integration_report.md"

# Tester la fonction Get-TestOmnibusErrors
Write-Host "Tester Get-TestOmnibusErrors:"
$errors = Get-TestOmnibusErrors -TestOmnibusPath $testOmnibusPath
Write-Host "Erreurs extraites: $($errors.Count)"
$errors | ForEach-Object {
  Write-Host "Source: $($_.Source), Message: $($_.Message)"
}

# Tester la fonction Add-TestOmnibusErrors
Write-Host "`nTester Add-TestOmnibusErrors:"
$patternIds = Add-TestOmnibusErrors -Errors $errors
Write-Host "Patterns crÃ©Ã©s: $($patternIds.Count)"

# Tester la fonction New-TestOmnibusHook
Write-Host "`nTester New-TestOmnibusHook:"
$hookPath = New-TestOmnibusHook -TestOmnibusPath $testOmnibusPath
Write-Host "Hook crÃ©Ã©: $hookPath"
if (Test-Path -Path $hookPath) {
  Write-Host "Le hook existe."
}

# Tester la fonction New-IntegrationReport
Write-Host "`nTester New-IntegrationReport:"
$result = New-IntegrationReport -PatternIds $patternIds -ReportPath $reportPath
Write-Host "Rapport d'intÃ©gration gÃ©nÃ©rÃ©: $result"
if (Test-Path -Path $reportPath) {
  Write-Host "Le rapport existe."
}
