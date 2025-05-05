BeforeAll {
  # Importer le module Ã  tester
  $global:scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\development\scripts\maintenance\error-learning\Integrate-WithTestOmnibus.ps1"
  $global:modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\development\scripts\maintenance\error-learning\ErrorPatternAnalyzer.psm1"

  # CrÃ©er un dossier temporaire pour les tests
  $global:testFolder = Join-Path -Path $TestDrive -ChildPath "TestOmnibusIntegrationTests"
  New-Item -Path $global:testFolder -ItemType Directory -Force | Out-Null

  # CrÃ©er une base de donnÃ©es de test
  $global:databasePath = Join-Path -Path $global:testFolder -ChildPath "test_error_database.json"
  $global:reportPath = Join-Path -Path $global:testFolder -ChildPath "test_integration_report.md"

  # CrÃ©er un dossier TestOmnibus de test
  $global:testOmnibusPath = Join-Path -Path $global:testFolder -ChildPath "TestOmnibus"
  New-Item -Path $global:testOmnibusPath -ItemType Directory -Force | Out-Null

  # CrÃ©er des dossiers pour les logs de test
  $global:logsPath = Join-Path -Path $global:testOmnibusPath -ChildPath "logs"
  New-Item -Path $global:logsPath -ItemType Directory -Force | Out-Null

  # CrÃ©er des fichiers de log de test
  $logFile1 = Join-Path -Path $global:logsPath -ChildPath "test_log_1.log"
  $logContent1 = @"
Exception : System.NullReferenceException: Object reference not set to an instance of an object.
   at Test-Function, C:\Scripts\Test.ps1 : line 42
   at <ScriptBlock>, C:\Scripts\Main.ps1 : line 10

Exception : System.IndexOutOfRangeException: Index was outside the bounds of the array.
   at Process-Array, C:\Scripts\Array.ps1 : line 25
   at <ScriptBlock>, C:\Scripts\Main.ps1 : line 15
"@
  $logContent1 | Out-File -FilePath $logFile1 -Encoding utf8

  $logFile2 = Join-Path -Path $global:logsPath -ChildPath "test_results_1.xml"
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

  $logFile3 = Join-Path -Path $global:logsPath -ChildPath "error_1.json"
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
}

Describe "Integrate-WithTestOmnibus" {
  BeforeEach {
    # Charger le module ErrorPatternAnalyzer
    . $global:modulePath

    # Initialiser la base de donnÃ©es
    $script:ErrorDatabasePath = $global:databasePath
    Initialize-ErrorDatabase -DatabasePath $global:databasePath -Force
  }

  It "Extrait correctement les erreurs des logs de TestOmnibus" {
    # Charger le script
    . $global:scriptPath -TestOmnibusPath $global:testOmnibusPath -ErrorDatabasePath $global:databasePath -ReportPath $global:reportPath

    # Extraire les erreurs
    $errors = Get-TestOmnibusErrors -TestOmnibusPath $global:testOmnibusPath

    $errors | Should -Not -BeNullOrEmpty
    $errors.Count | Should -BeGreaterThan 0

    # VÃ©rifier que les erreurs ont Ã©tÃ© extraites correctement
    $errors | Where-Object { $_.Source -like "*test_log_1.log" } | Should -Not -BeNullOrEmpty
    $errors | Where-Object { $_.Source -like "*test_results_1.xml" } | Should -Not -BeNullOrEmpty
    $errors | Where-Object { $_.Source -like "*error_1.json" } | Should -Not -BeNullOrEmpty
  }

  It "Ajoute correctement les erreurs Ã  la base de donnÃ©es" {
    # Charger le script
    . $global:scriptPath -TestOmnibusPath $global:testOmnibusPath -ErrorDatabasePath $global:databasePath -ReportPath $global:reportPath

    # Extraire les erreurs
    $errors = Get-TestOmnibusErrors -TestOmnibusPath $global:testOmnibusPath

    # Ajouter les erreurs Ã  la base de donnÃ©es
    $patternIds = Add-TestOmnibusErrors -Errors $errors

    $patternIds | Should -Not -BeNullOrEmpty
    $patternIds.Count | Should -Be $errors.Count

    # VÃ©rifier que les patterns ont Ã©tÃ© crÃ©Ã©s
    $patterns = Get-ErrorPattern
    $patterns.Count | Should -BeGreaterThan 0
  }

  It "CrÃ©e correctement un hook d'intÃ©gration" {
    # Charger le script
    . $global:scriptPath -TestOmnibusPath $global:testOmnibusPath -ErrorDatabasePath $global:databasePath -ReportPath $global:reportPath

    # CrÃ©er un hook d'intÃ©gration
    $hookPath = New-TestOmnibusHook -TestOmnibusPath $global:testOmnibusPath

    $hookPath | Should -Not -BeNullOrEmpty
    Test-Path -Path $hookPath | Should -Be $true

    # VÃ©rifier que le hook contient les fonctions nÃ©cessaires
    $hookContent = Get-Content -Path $hookPath -Raw
    $hookContent | Should -Match "Process-TestErrors"
    $hookContent | Should -Match "ErrorPatternAnalyzer"
  }

  It "CrÃ©e correctement un rapport d'intÃ©gration" {
    # Charger le script
    . $global:scriptPath -TestOmnibusPath $global:testOmnibusPath -ErrorDatabasePath $global:databasePath -ReportPath $global:reportPath

    # Extraire les erreurs
    $errors = Get-TestOmnibusErrors -TestOmnibusPath $global:testOmnibusPath

    # Ajouter les erreurs Ã  la base de donnÃ©es
    $patternIds = Add-TestOmnibusErrors -Errors $errors

    # CrÃ©er un rapport d'intÃ©gration
    $reportPath = New-IntegrationReport -PatternIds $patternIds -ReportPath $global:reportPath

    $reportPath | Should -Be $global:reportPath
    Test-Path -Path $reportPath | Should -Be $true

    # VÃ©rifier que le rapport contient les sections nÃ©cessaires
    $reportContent = Get-Content -Path $reportPath -Raw
    $reportContent | Should -Match "Rapport d'intÃ©gration avec TestOmnibus"
    $reportContent | Should -Match "RÃ©sumÃ©"
    $reportContent | Should -Match "Patterns d'erreur dÃ©tectÃ©s"
    $reportContent | Should -Match "IntÃ©gration avec TestOmnibus"
  }
}

Describe "Integrate-WithTestOmnibus Integration" {
  BeforeAll {
    # Charger le module ErrorPatternAnalyzer
    . $global:modulePath

    # Initialiser la base de donnÃ©es
    $script:ErrorDatabasePath = $global:databasePath
    Initialize-ErrorDatabase -DatabasePath $global:databasePath -Force
  }

  It "ExÃ©cute correctement le script complet" {
    # ExÃ©cuter le script
    & $global:scriptPath -TestOmnibusPath $global:testOmnibusPath -ErrorDatabasePath $global:databasePath -ReportPath $global:reportPath

    # VÃ©rifier que le rapport a Ã©tÃ© gÃ©nÃ©rÃ©
    Test-Path -Path $global:reportPath | Should -Be $true

    # VÃ©rifier que le hook a Ã©tÃ© crÃ©Ã©
    $hookPath = Join-Path -Path $global:testOmnibusPath -ChildPath "hooks\ErrorPatternAnalyzer.ps1"
    Test-Path -Path $hookPath | Should -Be $true

    # VÃ©rifier que la base de donnÃ©es contient des patterns
    $database = Get-Content -Path $global:databasePath -Raw | ConvertFrom-Json
    $database.Patterns.Count | Should -BeGreaterThan 0
  }
}
