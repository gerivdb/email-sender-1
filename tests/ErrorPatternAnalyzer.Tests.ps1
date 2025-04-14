BeforeAll {
    # Importer le module à tester
    $global:modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\maintenance\error-learning\ErrorPatternAnalyzer.psm1"

    # Charger le contenu du module directement plutôt que de l'importer
    . $global:modulePath

    # Créer un dossier temporaire pour les tests
    $global:testFolder = Join-Path -Path $TestDrive -ChildPath "ErrorPatternAnalyzerTests"
    New-Item -Path $global:testFolder -ItemType Directory -Force | Out-Null

    # Rediriger les chemins de base de données et de journal pour les tests
    $script:ErrorDatabasePath = Join-Path -Path $global:testFolder -ChildPath "test_error_database.json"
    $script:ErrorLogPath = Join-Path -Path $global:testFolder -ChildPath "test_error_log.md"

    # Fonction pour créer une erreur de test
    function New-TestErrorRecord {
        param (
            [Parameter(Mandatory = $false)]
            [string]$Message = "Test error message",

            [Parameter(Mandatory = $false)]
            [string]$ScriptName = "Test-Script.ps1",

            [Parameter(Mandatory = $false)]
            [int]$LineNumber = 42,

            [Parameter(Mandatory = $false)]
            [string]$Line = '$result = $null.Property',

            [Parameter(Mandatory = $false)]
            [string]$ErrorId = "NullReference"
        )

        $exception = New-Object System.NullReferenceException $Message
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            $exception,
            $ErrorId,
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            $null
        )

        # Ajouter des informations supplémentaires
        $errorRecord | Add-Member -NotePropertyName ScriptName -NotePropertyValue $ScriptName -Force
        $errorRecord | Add-Member -NotePropertyName ScriptLineNumber -NotePropertyValue $LineNumber -Force
        $errorRecord | Add-Member -NotePropertyName Line -NotePropertyValue $Line -Force
        $errorRecord | Add-Member -NotePropertyName PositionMessage -NotePropertyValue "At ${ScriptName}:${LineNumber}" -Force
        $errorRecord | Add-Member -NotePropertyName ScriptStackTrace -NotePropertyValue "at <ScriptBlock>, ${ScriptName}: line ${LineNumber}" -Force

        return $errorRecord
    }
}

Describe "ErrorPatternAnalyzer" {
    BeforeEach {
        # Réinitialiser la base de données pour chaque test
        Initialize-ErrorDatabase -DatabasePath $script:ErrorDatabasePath -Force
    }

    It "Ajoute une erreur à la base de données" {
        $errorRecord = New-TestErrorRecord
        $patternId = Add-ErrorRecord -ErrorRecord $errorRecord -Source "Test"

        $patternId | Should -Not -BeNullOrEmpty

        $patterns = Get-ErrorPattern
        $patterns.Count | Should -Be 1
        $patterns[0].Id | Should -Be $patternId
    }

    It "Identifie des patterns similaires" {
        # Ajouter une première erreur
        $errorRecord1 = New-TestErrorRecord -Message "Cannot access property of null object"
        $patternId1 = Add-ErrorRecord -ErrorRecord $errorRecord1 -Source "Test"

        # Ajouter une erreur similaire
        $errorRecord2 = New-TestErrorRecord -Message "Cannot access property of null object" -LineNumber 43
        $patternId2 = Add-ErrorRecord -ErrorRecord $errorRecord2 -Source "Test"

        # Les deux erreurs devraient être associées au même pattern
        $patternId1 | Should -Be $patternId2

        $patterns = Get-ErrorPattern
        $patterns.Count | Should -Be 1
        $patterns[0].Occurrences | Should -Be 2
    }

    It "Crée des patterns distincts pour des erreurs différentes" {
        # Ajouter une première erreur
        $errorRecord1 = New-TestErrorRecord -Message "Cannot access property of null object"
        $patternId1 = Add-ErrorRecord -ErrorRecord $errorRecord1 -Source "Test"

        # Ajouter une erreur différente
        $errorRecord2 = New-TestErrorRecord -Message "Index out of range" -ErrorId "IndexOutOfRange" -Line '$array[$index]'
        $patternId2 = Add-ErrorRecord -ErrorRecord $errorRecord2 -Source "Test"

        # Les deux erreurs devraient avoir des patterns différents
        $patternId1 | Should -Not -Be $patternId2

        $patterns = Get-ErrorPattern
        $patterns.Count | Should -Be 2
    }

    It "Extrait correctement les patterns de message" {
        $message = "Cannot access property 'Name' of null object at C:\Scripts\Test.ps1:42"
        $pattern = Get-MessagePattern -Message $message

        $pattern | Should -Not -Be $message
        $pattern | Should -Match "<PATH>"
        $pattern | Should -Match "<NUMBER>"
    }

    It "Extrait correctement les patterns de ligne" {
        $line = '$result = $user.Properties["Name"] + 42'
        $pattern = Get-LinePattern -Line $line

        $pattern | Should -Not -Be $line
        $pattern | Should -Match "<VARIABLE>"
        $pattern | Should -Match "<STRING>"
        $pattern | Should -Match "<NUMBER>"
    }

    It "Calcule correctement la distance de Levenshtein" {
        $string1 = "kitten"
        $string2 = "sitting"

        $distance = Measure-LevenshteinDistance -String1 $string1 -String2 $string2

        $distance | Should -Be 3
    }

    It "Mesure correctement la similarité entre patterns" {
        $pattern1 = @{
            ExceptionType  = "System.NullReferenceException"
            ErrorId        = "NullReference"
            MessagePattern = "Cannot access property of <VARIABLE>"
            ScriptContext  = "Test-Script.ps1"
            LinePattern    = "<VARIABLE> = <VARIABLE>.<VARIABLE>"
        }

        $pattern2 = @{
            ExceptionType  = "System.NullReferenceException"
            ErrorId        = "NullReference"
            MessagePattern = "Cannot access property of <VARIABLE>"
            ScriptContext  = "Test-Script.ps1"
            LinePattern    = "<VARIABLE> = <VARIABLE>.<VARIABLE>"
        }

        $similarity = Measure-PatternSimilarity -Pattern1 $pattern1 -Pattern2 $pattern2

        $similarity | Should -Be 1.0

        # Pattern légèrement différent
        $pattern3 = @{
            ExceptionType  = "System.NullReferenceException"
            ErrorId        = "NullReference"
            MessagePattern = "Cannot access method of <VARIABLE>"
            ScriptContext  = "Test-Script.ps1"
            LinePattern    = "<VARIABLE> = <VARIABLE>.<VARIABLE>()"
        }

        $similarity = Measure-PatternSimilarity -Pattern1 $pattern1 -Pattern2 $pattern3

        $similarity | Should -BeLessThan 1.0
        $similarity | Should -BeGreaterThan 0.5
    }

    It "Valide correctement un pattern d'erreur" {
        $errorRecord = New-TestErrorRecord
        $patternId = Add-ErrorRecord -ErrorRecord $errorRecord -Source "Test"

        $pattern = Confirm-ErrorPattern -PatternId $patternId -ValidationStatus "Valid" -Name "Test Pattern" -Description "Test Description" -IsInedited

        $pattern.ValidationStatus | Should -Be "Valid"
        $pattern.Name | Should -Be "Test Pattern"
        $pattern.Description | Should -Be "Test Description"
        $pattern.IsInedited | Should -Be $true

        # Vérifier que le pattern a été mis à jour dans la base de données
        $patterns = Get-ErrorPattern
        $patterns[0].ValidationStatus | Should -Be "Valid"
        $patterns[0].Name | Should -Be "Test Pattern"
    }

    It "Génère un rapport d'analyse" {
        # Ajouter quelques erreurs
        $errorRecord1 = New-TestErrorRecord -Message "Cannot access property of null object"
        $patternId1 = Add-ErrorRecord -ErrorRecord $errorRecord1 -Source "Test"

        $errorRecord2 = New-TestErrorRecord -Message "Index out of range" -ErrorId "IndexOutOfRange" -Line '$array[$index]'
        $patternId2 = Add-ErrorRecord -ErrorRecord $errorRecord2 -Source "Test"

        # Valider les patterns
        Confirm-ErrorPattern -PatternId $patternId1 -ValidationStatus "Valid" -IsInedited
        Confirm-ErrorPattern -PatternId $patternId2 -ValidationStatus "Invalid" -IsInedited $false

        # Générer un rapport
        $reportPath = Join-Path -Path $global:testFolder -ChildPath "test_report.md"
        $result = New-ErrorPatternReport -OutputPath $reportPath

        $result | Should -Be $reportPath
        Test-Path -Path $reportPath | Should -Be $true

        $reportContent = Get-Content -Path $reportPath -Raw
        $reportContent | Should -Match "Patterns d'erreur inédits"
        $reportContent | Should -Match "Corrélations entre patterns"
    }
}

Describe "ErrorPatternAnalyzer Integration" {
    BeforeAll {
        # Réinitialiser la base de données pour les tests d'intégration
        # Charger le contenu du module directement plutôt que de l'importer
        . $global:modulePath

        # Initialiser la base de données
        Initialize-ErrorDatabase -DatabasePath $script:ErrorDatabasePath -Force

        # Créer un fichier de log de test
        $logPath = Join-Path -Path $global:testFolder -ChildPath "test_error.log"

        $logContent = @"
Exception : System.NullReferenceException: Object reference not set to an instance of an object.
   at Test-Function, C:\Scripts\Test.ps1: line 42
   at <ScriptBlock>, C:\Scripts\Main.ps1: line 10

Exception : System.IndexOutOfRangeException: Index was outside the bounds of the array.
   at Process-Array, C:\Scripts\Array.ps1: line 25
   at <ScriptBlock>, C:\Scripts\Main.ps1: line 15

Exception : System.NullReferenceException: Object reference not set to an instance of an object.
   at Test-Function, C:\Scripts\Test.ps1: line 43
   at <ScriptBlock>, C:\Scripts\Main.ps1: line 20
"@

        $logContent | Out-File -FilePath $logPath -Encoding utf8

        # Créer le script d'analyse
        $scriptPath = Join-Path -Path $global:testFolder -ChildPath "Analyze-TestErrors.ps1"

        $scriptContent = @"
# Importer le module
Import-Module "$global:modulePath" -Force

# Analyser le fichier de log
function Analyze-ErrorLog {
    param (
        [string]`$LogPath
    )

    # Lire le fichier de log
    `$logContent = Get-Content -Path `$LogPath -Raw

    # Extraire les erreurs du log
    `$errorPattern = '(?ms)Exception\s*:\s*([^\r\n]+).*?at\s+([^\r\n]+)'
    `$matches = [regex]::Matches(`$logContent, `$errorPattern)

    # Analyser chaque erreur
    foreach (`$match in `$matches) {
        `$exceptionMessage = `$match.Groups[1].Value.Trim()
        `$stackTrace = `$match.Groups[2].Value.Trim()

        # Créer un objet ErrorRecord
        `$exception = New-Object System.Exception `$exceptionMessage
        `$errorRecord = New-Object System.Management.Automation.ErrorRecord(
            `$exception,
            "LogFileError",
            [System.Management.Automation.ErrorCategory]::NotSpecified,
            `$null
        )

        # Ajouter des informations supplémentaires
        `$errorRecord.PSObject.Properties.Add(
            (New-Object System.Management.Automation.PSNoteProperty "ScriptStackTrace", `$stackTrace)
        )

        # Ajouter l'erreur à la base de données
        Add-ErrorRecord -ErrorRecord `$errorRecord -Source `$LogPath
    }
}

# Analyser le fichier de log
Analyze-ErrorLog -LogPath "$logPath"

# Générer un rapport
New-ErrorPatternReport -OutputPath "$global:testFolder\integration_report.md"
"@

        $scriptContent | Out-File -FilePath $scriptPath -Encoding utf8
    }

    It "Analyse correctement un fichier de log" {
        # Exécuter le script d'analyse
        $scriptPath = Join-Path -Path $global:testFolder -ChildPath "Analyze-TestErrors.ps1"
        & $scriptPath

        # Vérifier que les patterns ont été créés
        $patterns = Get-ErrorPattern
        $patterns.Count | Should -BeGreaterThan 0

        # Vérifier que le rapport a été généré
        $reportPath = Join-Path -Path $global:testFolder -ChildPath "integration_report.md"
        Test-Path -Path $reportPath | Should -Be $true
    }
}
