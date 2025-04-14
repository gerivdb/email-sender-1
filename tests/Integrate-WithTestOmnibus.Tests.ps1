BeforeAll {
  # Importer le module à tester
  $global:scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\maintenance\error-learning\Integrate-WithTestOmnibus.ps1"
  $global:modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\maintenance\error-learning\ErrorPatternAnalyzer.psm1"

  # Créer un dossier temporaire pour les tests
  $global:testFolder = Join-Path -Path $TestDrive -ChildPath "TestOmnibusIntegrationTests"
  New-Item -Path $global:testFolder -ItemType Directory -Force | Out-Null

  # Créer une base de données de test
  $global:databasePath = Join-Path -Path $global:testFolder -ChildPath "test_error_database.json"
  $global:reportPath = Join-Path -Path $global:testFolder -ChildPath "test_integration_report.md"

  # Créer un dossier TestOmnibus de test
  $global:testOmnibusPath = Join-Path -Path $global:testFolder -ChildPath "TestOmnibus"
  New-Item -Path $global:testOmnibusPath -ItemType Directory -Force | Out-Null

  # Créer des dossiers pour les logs de test
  $global:logsPath = Join-Path -Path $global:testOmnibusPath -ChildPath "logs"
  New-Item -Path $global:logsPath -ItemType Directory -Force | Out-Null

  # Créer des fichiers de log de test
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

    # Initialiser la base de données
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

    # Vérifier que les erreurs ont été extraites correctement
    $errors | Where-Object { $_.Source -like "*test_log_1.log" } | Should -Not -BeNullOrEmpty
    $errors | Where-Object { $_.Source -like "*test_results_1.xml" } | Should -Not -BeNullOrEmpty
    $errors | Where-Object { $_.Source -like "*error_1.json" } | Should -Not -BeNullOrEmpty
  }

  It "Ajoute correctement les erreurs à la base de données" {
    # Charger le script
    . $global:scriptPath -TestOmnibusPath $global:testOmnibusPath -ErrorDatabasePath $global:databasePath -ReportPath $global:reportPath

    # Extraire les erreurs
    $errors = Get-TestOmnibusErrors -TestOmnibusPath $global:testOmnibusPath

    # Ajouter les erreurs à la base de données
    $patternIds = Add-TestOmnibusErrors -Errors $errors

    $patternIds | Should -Not -BeNullOrEmpty
    $patternIds.Count | Should -Be $errors.Count

    # Vérifier que les patterns ont été créés
    $patterns = Get-ErrorPattern
    $patterns.Count | Should -BeGreaterThan 0
  }

  It "Crée correctement un hook d'intégration" {
    # Charger le script
    . $global:scriptPath -TestOmnibusPath $global:testOmnibusPath -ErrorDatabasePath $global:databasePath -ReportPath $global:reportPath

    # Créer un hook d'intégration
    $hookPath = New-TestOmnibusHook -TestOmnibusPath $global:testOmnibusPath

    $hookPath | Should -Not -BeNullOrEmpty
    Test-Path -Path $hookPath | Should -Be $true

    # Vérifier que le hook contient les fonctions nécessaires
    $hookContent = Get-Content -Path $hookPath -Raw
    $hookContent | Should -Match "Process-TestErrors"
    $hookContent | Should -Match "ErrorPatternAnalyzer"
  }

  It "Crée correctement un rapport d'intégration" {
    # Charger le script
    . $global:scriptPath -TestOmnibusPath $global:testOmnibusPath -ErrorDatabasePath $global:databasePath -ReportPath $global:reportPath

    # Extraire les erreurs
    $errors = Get-TestOmnibusErrors -TestOmnibusPath $global:testOmnibusPath

    # Ajouter les erreurs à la base de données
    $patternIds = Add-TestOmnibusErrors -Errors $errors

    # Créer un rapport d'intégration
    $reportPath = New-IntegrationReport -PatternIds $patternIds -ReportPath $global:reportPath

    $reportPath | Should -Be $global:reportPath
    Test-Path -Path $reportPath | Should -Be $true

    # Vérifier que le rapport contient les sections nécessaires
    $reportContent = Get-Content -Path $reportPath -Raw
    $reportContent | Should -Match "Rapport d'intégration avec TestOmnibus"
    $reportContent | Should -Match "Résumé"
    $reportContent | Should -Match "Patterns d'erreur détectés"
    $reportContent | Should -Match "Intégration avec TestOmnibus"
  }
}

Describe "Integrate-WithTestOmnibus Integration" {
  BeforeAll {
    # Charger le module ErrorPatternAnalyzer
    . $global:modulePath

    # Initialiser la base de données
    $script:ErrorDatabasePath = $global:databasePath
    Initialize-ErrorDatabase -DatabasePath $global:databasePath -Force
  }

  It "Exécute correctement le script complet" {
    # Exécuter le script
    & $global:scriptPath -TestOmnibusPath $global:testOmnibusPath -ErrorDatabasePath $global:databasePath -ReportPath $global:reportPath

    # Vérifier que le rapport a été généré
    Test-Path -Path $global:reportPath | Should -Be $true

    # Vérifier que le hook a été créé
    $hookPath = Join-Path -Path $global:testOmnibusPath -ChildPath "hooks\ErrorPatternAnalyzer.ps1"
    Test-Path -Path $hookPath | Should -Be $true

    # Vérifier que la base de données contient des patterns
    $database = Get-Content -Path $global:databasePath -Raw | ConvertFrom-Json
    $database.Patterns.Count | Should -BeGreaterThan 0
  }
}
