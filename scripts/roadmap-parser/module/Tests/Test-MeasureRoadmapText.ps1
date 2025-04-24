#
# Test-MeasureRoadmapText.ps1
#
# Script pour tester la fonction Measure-RoadmapText
#

# Importer la fonction Measure-RoadmapText
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\StringManipulation\Measure-RoadmapText.ps1"

# Créer le répertoire s'il n'existe pas
$functionDir = Split-Path -Parent $functionPath
if (-not (Test-Path -Path $functionDir)) {
    New-Item -Path $functionDir -ItemType Directory -Force | Out-Null
}

# Importer la fonction
. $functionPath

Write-Host "Début des tests de la fonction Measure-RoadmapText..." -ForegroundColor Cyan

# Test 1: Mesures de base
Write-Host "`nTest 1: Mesures de base" -ForegroundColor Cyan

$testText = "Hello World. This is a test. It has three sentences."

$testCases = @(
    @{ MeasureType = "Length"; Expected = 52; Description = "Length" }
    @{ MeasureType = "Words"; Expected = 10; Description = "Words" }
    @{ MeasureType = "Lines"; Expected = 1; Description = "Lines" }
    @{ MeasureType = "Characters"; Expected = 52; Description = "Characters" }
    @{ MeasureType = "Paragraphs"; Expected = 1; Description = "Paragraphs" }
    @{ MeasureType = "Sentences"; Expected = 3; Description = "Sentences" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Text        = $testText
        MeasureType = $testCase.MeasureType
    }

    $result = Measure-RoadmapText @params

    # Vérifier le résultat
    $success = $result -eq $testCase.Expected

    $status = if ($success) { "Réussi" } else { "Échoué" }
    $color = if ($success) { "Green" } else { "Red" }

    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color

    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    Résultat attendu: $($testCase.Expected)" -ForegroundColor Red
        Write-Host "    Résultat obtenu: $result" -ForegroundColor Red
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 2: Mesures avancées
Write-Host "`nTest 2: Mesures avancées" -ForegroundColor Cyan

$testCases = @(
    @{ MeasureType = "ReadingTime"; Expected = 3; Description = "ReadingTime" }  # 10 mots à 200 mots par minute = 3 secondes
    @{ MeasureType = "ReadingLevel"; Description = "ReadingLevel" }  # Pas de valeur attendue précise, juste vérifier qu'il n'y a pas d'erreur
    @{ MeasureType = "Sentiment"; Description = "Sentiment" }  # Pas de valeur attendue précise, juste vérifier qu'il n'y a pas d'erreur
    @{ MeasureType = "Keywords"; Description = "Keywords" }  # Pas de valeur attendue précise, juste vérifier qu'il n'y a pas d'erreur
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Text        = $testText
        MeasureType = $testCase.MeasureType
    }

    $result = Measure-RoadmapText @params

    # Vérifier le résultat
    $success = $false

    if ($testCase.ContainsKey("Expected")) {
        $success = $result -eq $testCase.Expected
    } else {
        $success = $null -ne $result
    }

    $status = if ($success) { "Réussi" } else { "Échoué" }
    $color = if ($success) { "Green" } else { "Red" }

    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color

    if ($success) {
        $successCount++
    } else {
        $failureCount++
        if ($testCase.ContainsKey("Expected")) {
            Write-Host "    Résultat attendu: $($testCase.Expected)" -ForegroundColor Red
            Write-Host "    Résultat obtenu: $result" -ForegroundColor Red
        } else {
            Write-Host "    Résultat obtenu: $result" -ForegroundColor Red
        }
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 3: Mesures avec options
Write-Host "`nTest 3: Mesures avec options" -ForegroundColor Cyan

$testText = "Hello World`r`n`r`nThis is a test."

$testCases = @(
    @{ MeasureType = "Lines"; IncludeEmptyLines = $true; Expected = 3; Description = "Lines avec lignes vides" }
    @{ MeasureType = "Lines"; IncludeEmptyLines = $false; Expected = 2; Description = "Lines sans lignes vides" }
    @{ MeasureType = "Characters"; IncludeWhitespace = $false; Expected = 22; Description = "Characters sans espaces" }
    @{ MeasureType = "Characters"; IncludePunctuation = $false; Expected = 29; Description = "Characters sans ponctuation" }
    @{ MeasureType = "Frequency"; IgnoreCase = $true; Description = "Frequency insensible à la casse" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Text        = $testText
        MeasureType = $testCase.MeasureType
    }

    if ($testCase.ContainsKey("IncludeEmptyLines")) {
        $params["IncludeEmptyLines"] = $testCase.IncludeEmptyLines
    }

    if ($testCase.ContainsKey("IncludeWhitespace")) {
        $params["IncludeWhitespace"] = $testCase.IncludeWhitespace
    }

    if ($testCase.ContainsKey("IncludePunctuation")) {
        $params["IncludePunctuation"] = $testCase.IncludePunctuation
    }

    if ($testCase.ContainsKey("IgnoreCase")) {
        $params["IgnoreCase"] = $testCase.IgnoreCase
    }

    $result = Measure-RoadmapText @params

    # Vérifier le résultat
    $success = $false

    if ($testCase.ContainsKey("Expected")) {
        $success = $result -eq $testCase.Expected
    } else {
        $success = $null -ne $result
    }

    $status = if ($success) { "Réussi" } else { "Échoué" }
    $color = if ($success) { "Green" } else { "Red" }

    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color

    if ($success) {
        $successCount++
    } else {
        $failureCount++
        if ($testCase.ContainsKey("Expected")) {
            Write-Host "    Résultat attendu: $($testCase.Expected)" -ForegroundColor Red
            Write-Host "    Résultat obtenu: $result" -ForegroundColor Red
        } else {
            Write-Host "    Résultat obtenu: $result" -ForegroundColor Red
        }
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 4: Statistiques
Write-Host "`nTest 4: Statistiques" -ForegroundColor Cyan

$result = Measure-RoadmapText -Text $testText -MeasureType Statistics

$success = $null -ne $result -and
$result.Length -eq $testText.Length -and
$result.WordCount -gt 0 -and
$result.LineCount -gt 0 -and
$result.CharacterCount -gt 0 -and
$result.ParagraphCount -gt 0 -and
$result.SentenceCount -gt 0 -and
$result.AverageWordLength -gt 0 -and
$result.AverageSentenceLength -gt 0 -and
$result.ReadingTime -ge 0 -and
$result.ReadingLevel -ne 0

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Statistiques: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Résultat obtenu: $result" -ForegroundColor Red
}

# Test 5: Mesure personnalisée
Write-Host "`nTest 5: Mesure personnalisée" -ForegroundColor Cyan

$customMeasure = {
    param($Text)

    # Compter le nombre de voyelles
    $vowels = $Text -split '' | Where-Object { $_ -match '[aeiou]' }
    return $vowels.Count
}

$result = Measure-RoadmapText -Text "Hello World" -MeasureType Custom -CustomMeasure $customMeasure

$success = $result -eq 3  # "Hello World" contient 3 voyelles (e, o, o)

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Mesure personnalisée: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Résultat attendu: 3" -ForegroundColor Red
    Write-Host "    Résultat obtenu: $result" -ForegroundColor Red
}

# Test 6: Gestion des erreurs
Write-Host "`nTest 6: Gestion des erreurs" -ForegroundColor Cyan

$testCases = @(
    @{ Test = "Measure-RoadmapText sans CustomMeasure pour Custom"; Function = { Measure-RoadmapText -Text "Hello" -MeasureType "Custom" -ThrowOnFailure }; ShouldThrow = $true; Description = "Mesure personnalisée sans CustomMeasure" }
    @{ Test = "Measure-RoadmapText avec erreur sans ThrowOnFailure"; Function = {
            # Ce test est censé générer un warning, c'est normal
            Write-Host "Note: Le warning suivant est attendu dans le cadre du test:" -ForegroundColor Yellow
            $result = Measure-RoadmapText -Text "Hello" -MeasureType "Custom"
            return $result
        }; ShouldThrow = $false; Description = "Erreur sans ThrowOnFailure" 
    }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $exceptionThrown = $false

    try {
        & $testCase.Function
    } catch {
        $exceptionThrown = $true
    }

    # Vérifier le résultat
    $success = $testCase.ShouldThrow -eq $exceptionThrown

    $status = if ($success) { "Réussi" } else { "Échoué" }
    $color = if ($success) { "Green" } else { "Red" }

    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color

    if ($success) {
        $successCount++
    } else {
        $failureCount++
        if ($testCase.ShouldThrow) {
            Write-Host "    Exception attendue mais non levée" -ForegroundColor Red
        } else {
            Write-Host "    Exception non attendue mais levée" -ForegroundColor Red
        }
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

Write-Host "`nTests de la fonction Measure-RoadmapText terminés." -ForegroundColor Cyan
