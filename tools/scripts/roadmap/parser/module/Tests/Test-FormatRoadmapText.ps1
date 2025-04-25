#
# Test-FormatRoadmapText.ps1
#
# Script pour tester la fonction Format-RoadmapText
#

# Importer la fonction Format-RoadmapText
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\StringManipulation\Format-RoadmapText.ps1"

# Créer le répertoire s'il n'existe pas
$functionDir = Split-Path -Parent $functionPath
if (-not (Test-Path -Path $functionDir)) {
    New-Item -Path $functionDir -ItemType Directory -Force | Out-Null
}

# Importer la fonction
. $functionPath

Write-Host "Début des tests de la fonction Format-RoadmapText..." -ForegroundColor Cyan

# Test 1: Formatage de base
Write-Host "`nTest 1: Formatage de base" -ForegroundColor Cyan

$testCases = @(
    @{ Text = "hello world"; FormatType = "Capitalize"; Expected = "Hello World"; Description = "Capitalize" }
    @{ Text = "hello world"; FormatType = "UpperCase"; Expected = "HELLO WORLD"; Description = "UpperCase" }
    @{ Text = "HELLO WORLD"; FormatType = "LowerCase"; Expected = "hello world"; Description = "LowerCase" }
    @{ Text = "hello world"; FormatType = "TitleCase"; Expected = "Hello World"; Description = "TitleCase" }
    @{ Text = "hello world. this is a test."; FormatType = "SentenceCase"; Expected = "Hello world. This is a test."; Description = "SentenceCase" }
    @{ Text = "hello world"; FormatType = "CamelCase"; Expected = "helloWorld"; Description = "CamelCase" }
    @{ Text = "hello world"; FormatType = "PascalCase"; Expected = "HelloWorld"; Description = "PascalCase" }
    @{ Text = "hello world"; FormatType = "SnakeCase"; Expected = "hello_world"; Description = "SnakeCase" }
    @{ Text = "hello world"; FormatType = "KebabCase"; Expected = "hello-world"; Description = "KebabCase" }
    @{ Text = "  hello world  "; FormatType = "Trim"; Expected = "hello world"; Description = "Trim" }
    @{ Text = "  hello world"; FormatType = "TrimStart"; Expected = "hello world"; Description = "TrimStart" }
    @{ Text = "hello world  "; FormatType = "TrimEnd"; Expected = "hello world"; Description = "TrimEnd" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Text       = $testCase.Text
        FormatType = $testCase.FormatType
    }

    $result = Format-RoadmapText @params

    # Vérifier le résultat
    $success = $result -eq $testCase.Expected

    $status = if ($success) { "Réussi" } else { "Échoué" }
    $color = if ($success) { "Green" } else { "Red" }

    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color

    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    Attendu: '$($testCase.Expected)'" -ForegroundColor Red
        Write-Host "    Obtenu: '$result'" -ForegroundColor Red
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 2: Formatage avancé
Write-Host "`nTest 2: Formatage avancé" -ForegroundColor Cyan

$testCases = @(
    @{ Text = "hello world"; FormatType = "Indent"; IndentLevel = 1; Expected = "    hello world"; Description = "Indent (niveau 1)" }
    @{ Text = "hello world"; FormatType = "Indent"; IndentLevel = 2; Expected = "        hello world"; Description = "Indent (niveau 2)" }
    @{ Text = "hello world"; FormatType = "Truncate"; Length = 5; Expected = "hello"; Description = "Truncate" }
    @{ Text = "hello"; FormatType = "Pad"; Length = 10; PadCharacter = "*"; Expected = "hello*****"; Description = "Pad" }
    @{ Text = "This is a long text that should be wrapped at a specific width"; FormatType = "Wrap"; Length = 20; Expected = "This is a long text`r`nthat should be`r`nwrapped at a`r`nspecific width"; Description = "Wrap" }
    @{ Text = "hello"; FormatType = "Align"; Length = 10; Alignment = "Left"; Expected = "hello     "; Description = "Align (gauche)" }
    @{ Text = "hello"; FormatType = "Align"; Length = 10; Alignment = "Right"; Expected = "     hello"; Description = "Align (droite)" }
    @{ Text = "hello"; FormatType = "Align"; Length = 10; Alignment = "Center"; Expected = "  hello   "; Description = "Align (centre)" }
    @{ Text = "hello world"; FormatType = "Align"; Length = 15; Alignment = "Justify"; Expected = "hello     world"; Description = "Align (justifié)" }
    @{ Text = "hello {0}"; FormatType = "Custom"; CustomFormat = "world"; Expected = "hello world"; Description = "Custom" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Text       = $testCase.Text
        FormatType = $testCase.FormatType
    }

    if ($testCase.ContainsKey("IndentLevel")) {
        $params["IndentLevel"] = $testCase.IndentLevel
    }

    if ($testCase.ContainsKey("Length")) {
        $params["Length"] = $testCase.Length
    }

    if ($testCase.ContainsKey("PadCharacter")) {
        $params["PadCharacter"] = $testCase.PadCharacter
    }

    if ($testCase.ContainsKey("Alignment")) {
        $params["Alignment"] = $testCase.Alignment
    }

    if ($testCase.ContainsKey("CustomFormat")) {
        $params["CustomFormat"] = $testCase.CustomFormat
    }

    $result = Format-RoadmapText @params

    # Vérifier le résultat
    $success = $false

    if ($testCase.FormatType -eq "Wrap") {
        # Pour Wrap, nous devons normaliser les sauts de ligne pour la comparaison
        $normalizedResult = $result -replace "`r`n|`r|`n", "`r`n"
        $normalizedExpected = $testCase.Expected -replace "`r`n|`r|`n", "`r`n"
        $success = $normalizedResult -eq $normalizedExpected
    } else {
        $success = $result -eq $testCase.Expected
    }

    $status = if ($success) { "Réussi" } else { "Échoué" }
    $color = if ($success) { "Green" } else { "Red" }

    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color

    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    Attendu: '$($testCase.Expected)'" -ForegroundColor Red
        Write-Host "    Obtenu: '$result'" -ForegroundColor Red
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 3: Gestion des cas spéciaux
Write-Host "`nTest 3: Gestion des cas spéciaux" -ForegroundColor Cyan

$testCases = @(
    @{ Text = ""; FormatType = "Capitalize"; Expected = ""; Description = "Texte vide" }
    @{ Text = $null; FormatType = "Capitalize"; Expected = ""; Description = "Texte null" }
    @{ Text = "hello`r`nworld"; FormatType = "Capitalize"; Expected = "Hello`r`nWorld"; Description = "Texte avec sauts de ligne" }
    @{ Text = "hello`r`nworld"; FormatType = "Indent"; IndentLevel = 1; Expected = "    hello`r`n    world"; Description = "Indentation avec sauts de ligne" }
    @{ Text = "hello world"; FormatType = "TitleCase"; Expected = "Hello World"; Description = "TitleCase avec mots courts" }
    @{ Text = "the quick brown fox"; FormatType = "TitleCase"; Expected = "The Quick Brown Fox"; Description = "TitleCase avec 'the'" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Text       = $testCase.Text
        FormatType = $testCase.FormatType
    }

    if ($testCase.ContainsKey("IndentLevel")) {
        $params["IndentLevel"] = $testCase.IndentLevel
    }

    $result = Format-RoadmapText @params

    # Vérifier le résultat
    $success = $false

    if ($testCase.Description -eq "Texte avec sauts de ligne" -or $testCase.Description -eq "Indentation avec sauts de ligne") {
        # Pour les textes avec sauts de ligne, nous devons normaliser les sauts de ligne pour la comparaison
        $normalizedResult = $result -replace "`r`n|`r|`n", "`r`n"
        $normalizedExpected = $testCase.Expected -replace "`r`n|`r|`n", "`r`n"
        $success = $normalizedResult -eq $normalizedExpected
    } else {
        $success = $result -eq $testCase.Expected
    }

    $status = if ($success) { "Réussi" } else { "Échoué" }
    $color = if ($success) { "Green" } else { "Red" }

    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color

    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    Attendu: '$($testCase.Expected)'" -ForegroundColor Red
        Write-Host "    Obtenu: '$result'" -ForegroundColor Red
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 4: Gestion des erreurs
Write-Host "`nTest 4: Gestion des erreurs" -ForegroundColor Cyan

$testCases = @(
    @{ Test = "Format-RoadmapText sans Length pour Truncate"; Function = { Format-RoadmapText -Text "hello" -FormatType "Truncate" -ThrowOnFailure }; ShouldThrow = $true; Description = "Truncate sans Length" }
    @{ Test = "Format-RoadmapText sans Length pour Pad"; Function = { Format-RoadmapText -Text "hello" -FormatType "Pad" -ThrowOnFailure }; ShouldThrow = $true; Description = "Pad sans Length" }
    @{ Test = "Format-RoadmapText sans Length pour Wrap"; Function = { Format-RoadmapText -Text "hello" -FormatType "Wrap" -ThrowOnFailure }; ShouldThrow = $true; Description = "Wrap sans Length" }
    @{ Test = "Format-RoadmapText sans Length pour Align"; Function = { Format-RoadmapText -Text "hello" -FormatType "Align" -ThrowOnFailure }; ShouldThrow = $true; Description = "Align sans Length" }
    @{ Test = "Format-RoadmapText sans CustomFormat pour Custom"; Function = { Format-RoadmapText -Text "hello" -FormatType "Custom" -ThrowOnFailure }; ShouldThrow = $true; Description = "Custom sans CustomFormat" }
    @{ Test = "Format-RoadmapText avec erreur et ThrowOnFailure"; Function = { Format-RoadmapText -Text "hello" -FormatType "Truncate" -ThrowOnFailure }; ShouldThrow = $true; Description = "Erreur avec ThrowOnFailure" }
    @{ Test = "Format-RoadmapText avec erreur sans ThrowOnFailure"; Function = { Format-RoadmapText -Text "hello" -FormatType "Truncate" }; ShouldThrow = $false; Description = "Erreur sans ThrowOnFailure" }
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

Write-Host "`nTests de la fonction Format-RoadmapText terminés." -ForegroundColor Cyan
