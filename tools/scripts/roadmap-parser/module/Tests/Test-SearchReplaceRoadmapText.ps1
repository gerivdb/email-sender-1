#
# Test-SearchReplaceRoadmapText.ps1
#
# Script pour tester les fonctions Search-RoadmapText et Replace-RoadmapText
#

# Importer les fonctions Search-RoadmapText et Replace-RoadmapText
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$searchFunctionPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\StringManipulation\Search-RoadmapText.ps1"
$replaceFunctionPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\StringManipulation\Replace-RoadmapText.ps1"

# Créer les répertoires s'ils n'existent pas
$functionDir = Split-Path -Parent $searchFunctionPath
if (-not (Test-Path -Path $functionDir)) {
    New-Item -Path $functionDir -ItemType Directory -Force | Out-Null
}

# Importer les fonctions
. $searchFunctionPath
. $replaceFunctionPath

Write-Host "Début des tests des fonctions Search-RoadmapText et Replace-RoadmapText..." -ForegroundColor Cyan

# Test 1: Recherche de base
Write-Host "`nTest 1: Recherche de base" -ForegroundColor Cyan

$testCases = @(
    @{ Text = "Hello World"; Pattern = "World"; SearchType = "Simple"; ExpectedCount = 1; Description = "Recherche simple" }
    @{ Text = "Hello World"; Pattern = "world"; SearchType = "Simple"; ExpectedCount = 0; Description = "Recherche simple (sensible à la casse)" }
    @{ Text = "Hello World"; Pattern = "world"; SearchType = "CaseInsensitive"; ExpectedCount = 1; Description = "Recherche insensible à la casse" }
    @{ Text = "Hello World"; Pattern = "^Hello"; SearchType = "Regex"; ExpectedCount = 1; Description = "Recherche par expression régulière" }
    @{ Text = "Hello World"; Pattern = "Hello*"; SearchType = "Wildcard"; ExpectedCount = 1; Description = "Recherche avec caractères génériques" }
    @{ Text = "Hello World"; Pattern = "World"; SearchType = "WholeWord"; ExpectedCount = 1; Description = "Recherche de mots entiers" }
    @{ Text = "Hello World"; Pattern = "Hello"; SearchType = "StartsWith"; ExpectedCount = 1; Description = "Recherche au début du texte" }
    @{ Text = "Hello World"; Pattern = "World"; SearchType = "EndsWith"; ExpectedCount = 1; Description = "Recherche à la fin du texte" }
    @{ Text = "Hello World"; Pattern = "llo Wo"; SearchType = "Contains"; ExpectedCount = 1; Description = "Recherche dans tout le texte" }
    @{ Text = "Hello World"; Pattern = "Hello World"; SearchType = "Exact"; ExpectedCount = 1; Description = "Recherche exacte" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Text       = $testCase.Text
        Pattern    = $testCase.Pattern
        SearchType = $testCase.SearchType
    }

    $results = Search-RoadmapText @params

    # Vérifier le résultat
    $success = $results.Count -eq $testCase.ExpectedCount

    $status = if ($success) { "Réussi" } else { "Échoué" }
    $color = if ($success) { "Green" } else { "Red" }

    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color

    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    Nombre de résultats attendu: $($testCase.ExpectedCount)" -ForegroundColor Red
        Write-Host "    Nombre de résultats obtenu: $($results.Count)" -ForegroundColor Red
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 2: Recherche avancée
Write-Host "`nTest 2: Recherche avancée" -ForegroundColor Cyan

$testText = "Line 1: Hello World`r`nLine 2: Hello Universe`r`nLine 3: Goodbye World"

$testCases = @(
    @{ Pattern = "Hello"; SearchType = "Simple"; IncludeLineNumbers = $true; ExpectedCount = 2; Description = "Recherche avec numéros de ligne" }
    @{ Pattern = "Hello"; SearchType = "Simple"; MaxResults = 1; ExpectedCount = 1; Description = "Recherche avec limite de résultats" }
    @{ Pattern = "World"; SearchType = "WholeWord"; IncludeLineNumbers = $true; ExpectedCount = 2; Description = "Recherche de mots entiers avec numéros de ligne" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Text       = $testText
        Pattern    = $testCase.Pattern
        SearchType = $testCase.SearchType
    }

    if ($testCase.ContainsKey("IncludeLineNumbers")) {
        $params["IncludeLineNumbers"] = $testCase.IncludeLineNumbers
    }

    if ($testCase.ContainsKey("IncludeContext")) {
        $params["IncludeContext"] = $testCase.IncludeContext
    }

    if ($testCase.ContainsKey("ContextLines")) {
        $params["ContextLines"] = $testCase.ContextLines
    }

    if ($testCase.ContainsKey("MaxResults")) {
        $params["MaxResults"] = $testCase.MaxResults
    }

    $results = Search-RoadmapText @params

    # Vérifier le résultat
    $success = $results.Count -eq $testCase.ExpectedCount

    if ($success -and $testCase.ContainsKey("IncludeLineNumbers") -and $testCase.IncludeLineNumbers) {
        $success = $success -and ($results | ForEach-Object { $_.PSObject.Properties.Name -contains "LineNumber" })
    }

    if ($success -and $testCase.ContainsKey("IncludeContext") -and $testCase.IncludeContext) {
        $success = $success -and ($results | ForEach-Object { $_.PSObject.Properties.Name -contains "Context" })
    }

    $status = if ($success) { "Réussi" } else { "Échoué" }
    $color = if ($success) { "Green" } else { "Red" }

    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color

    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    Nombre de résultats attendu: $($testCase.ExpectedCount)" -ForegroundColor Red
        Write-Host "    Nombre de résultats obtenu: $($results.Count)" -ForegroundColor Red

        if ($testCase.ContainsKey("IncludeLineNumbers") -and $testCase.IncludeLineNumbers) {
            $hasLineNumbers = $results | ForEach-Object { $_.PSObject.Properties.Name -contains "LineNumber" }
            Write-Host "    Numéros de ligne inclus: $hasLineNumbers" -ForegroundColor Red
        }

        if ($testCase.ContainsKey("IncludeContext") -and $testCase.IncludeContext) {
            $hasContext = $results | ForEach-Object { $_.PSObject.Properties.Name -contains "Context" }
            Write-Host "    Contexte inclus: $hasContext" -ForegroundColor Red
        }
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 3: Recherche personnalisée
Write-Host "`nTest 3: Recherche personnalisée" -ForegroundColor Cyan

$customSearch = {
    param($Text, $Pattern)

    # Rechercher les mots qui commencent par le motif
    $regex = [regex]::new("\b" + [regex]::Escape($Pattern) + "\w*\b")
    $regexMatches = $regex.Matches($Text)

    $results = $regexMatches | ForEach-Object {
        [PSCustomObject]@{
            Match  = $_.Value
            Index  = $_.Index
            Length = $_.Length
        }
    }

    return $results
}

$testCases = @(
    @{ Text = "Hello World Welcome"; Pattern = "W"; CustomSearch = $customSearch; ExpectedCount = 2; Description = "Recherche personnalisée" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Text         = $testCase.Text
        Pattern      = $testCase.Pattern
        SearchType   = "Custom"
        CustomSearch = $testCase.CustomSearch
    }

    $results = Search-RoadmapText @params

    # Vérifier le résultat
    $success = $results.Count -eq $testCase.ExpectedCount

    $status = if ($success) { "Réussi" } else { "Échoué" }
    $color = if ($success) { "Green" } else { "Red" }

    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color

    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    Nombre de résultats attendu: $($testCase.ExpectedCount)" -ForegroundColor Red
        Write-Host "    Nombre de résultats obtenu: $($results.Count)" -ForegroundColor Red
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 4: Remplacement de base
Write-Host "`nTest 4: Remplacement de base" -ForegroundColor Cyan

$testCases = @(
    @{ Text = "Hello World"; Pattern = "World"; Replacement = "Universe"; ReplaceType = "Simple"; Expected = "Hello Universe"; Description = "Remplacement simple" }
    @{ Text = "Hello World"; Pattern = "world"; Replacement = "Universe"; ReplaceType = "Simple"; Expected = "Hello World"; Description = "Remplacement simple (sensible à la casse)" }
    @{ Text = "Hello World"; Pattern = "world"; Replacement = "Universe"; ReplaceType = "CaseInsensitive"; Expected = "Hello Universe"; Description = "Remplacement insensible à la casse" }
    @{ Text = "Hello World"; Pattern = "^Hello"; Replacement = "Hi"; ReplaceType = "Regex"; Expected = "Hi World"; Description = "Remplacement par expression régulière" }
    @{ Text = "Hello World"; Pattern = "Hello*"; Replacement = "Hi"; ReplaceType = "Wildcard"; Expected = "Hi"; Description = "Remplacement avec caractères génériques" }
    @{ Text = "Hello World"; Pattern = "World"; Replacement = "Universe"; ReplaceType = "WholeWord"; Expected = "Hello Universe"; Description = "Remplacement de mots entiers" }
    @{ Text = "Hello World Hello"; Pattern = "Hello"; Replacement = "Hi"; ReplaceType = "FirstOccurrence"; Expected = "Hi World Hello"; Description = "Remplacement de la première occurrence" }
    @{ Text = "Hello World Hello"; Pattern = "Hello"; Replacement = "Hi"; ReplaceType = "LastOccurrence"; Expected = "Hello World Hi"; Description = "Remplacement de la dernière occurrence" }
    @{ Text = "Hello World Hello"; Pattern = "Hello"; Replacement = "Hi"; ReplaceType = "AllOccurrences"; Expected = "Hi World Hi"; Description = "Remplacement de toutes les occurrences" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Text        = $testCase.Text
        Pattern     = $testCase.Pattern
        Replacement = $testCase.Replacement
        ReplaceType = $testCase.ReplaceType
    }

    $result = Replace-RoadmapText @params

    # Vérifier le résultat
    $success = $result -eq $testCase.Expected

    $status = if ($success) { "Réussi" } else { "Échoué" }
    $color = if ($success) { "Green" } else { "Red" }

    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color

    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    Résultat attendu: '$($testCase.Expected)'" -ForegroundColor Red
        Write-Host "    Résultat obtenu: '$result'" -ForegroundColor Red
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 5: Remplacement avancé
Write-Host "`nTest 5: Remplacement avancé" -ForegroundColor Cyan

$testCases = @(
    @{ Text = "Hello World Hello"; Pattern = "Hello"; Replacement = "Hi"; ReplaceType = "AllOccurrences"; MaxReplacements = 1; Expected = "Hi World Hello"; Description = "Remplacement avec limite" }
    @{ Text = "Hello World Hello World"; Pattern = "World"; Replacement = "Universe"; ReplaceType = "WholeWord"; MaxReplacements = 1; Expected = "Hello Universe Hello World"; Description = "Remplacement de mots entiers avec limite" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Text        = $testCase.Text
        Pattern     = $testCase.Pattern
        Replacement = $testCase.Replacement
        ReplaceType = $testCase.ReplaceType
    }

    if ($testCase.ContainsKey("MaxReplacements")) {
        $params["MaxReplacements"] = $testCase.MaxReplacements
    }

    $result = Replace-RoadmapText @params

    # Vérifier le résultat
    $success = $result -eq $testCase.Expected

    $status = if ($success) { "Réussi" } else { "Échoué" }
    $color = if ($success) { "Green" } else { "Red" }

    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color

    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    Résultat attendu: '$($testCase.Expected)'" -ForegroundColor Red
        Write-Host "    Résultat obtenu: '$result'" -ForegroundColor Red
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 6: Remplacement personnalisé
Write-Host "`nTest 6: Remplacement personnalisé" -ForegroundColor Cyan

$customReplace = {
    param($Text, $Pattern, $Replacement)

    # Remplacer les mots qui commencent par le motif
    $regex = [regex]::new("\b" + [regex]::Escape($Pattern) + "\w*\b")
    $result = $regex.Replace($Text, $Replacement)

    return $result
}

$testCases = @(
    @{ Text = "Hello World Welcome"; Pattern = "W"; Replacement = "X"; CustomReplace = $customReplace; Expected = "Hello X X"; Description = "Remplacement personnalisé" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Text          = $testCase.Text
        Pattern       = $testCase.Pattern
        Replacement   = $testCase.Replacement
        ReplaceType   = "Custom"
        CustomReplace = $testCase.CustomReplace
    }

    $result = Replace-RoadmapText @params

    # Vérifier le résultat
    $success = $result -eq $testCase.Expected

    $status = if ($success) { "Réussi" } else { "Échoué" }
    $color = if ($success) { "Green" } else { "Red" }

    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color

    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    Résultat attendu: '$($testCase.Expected)'" -ForegroundColor Red
        Write-Host "    Résultat obtenu: '$result'" -ForegroundColor Red
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 7: Gestion des erreurs
Write-Host "`nTest 7: Gestion des erreurs" -ForegroundColor Cyan

$testCases = @(
    @{ Test = "Search-RoadmapText sans CustomSearch pour Custom"; Function = { Search-RoadmapText -Text "Hello" -Pattern "H" -SearchType "Custom" -ThrowOnFailure }; ShouldThrow = $true; Description = "Recherche personnalisée sans CustomSearch" }
    @{ Test = "Search-RoadmapText avec erreur sans ThrowOnFailure"; Function = {
            # Ce test est censé générer un warning, c'est normal
            Write-Host "Note: Le warning suivant est attendu dans le cadre du test:" -ForegroundColor Yellow
            $result = Search-RoadmapText -Text "Hello" -Pattern "H" -SearchType "Custom"
            return $result
        }; ShouldThrow = $false; Description = "Recherche avec erreur sans ThrowOnFailure"
    }
    @{ Test = "Replace-RoadmapText sans CustomReplace pour Custom"; Function = { Replace-RoadmapText -Text "Hello" -Pattern "H" -Replacement "X" -ReplaceType "Custom" -ThrowOnFailure }; ShouldThrow = $true; Description = "Remplacement personnalisé sans CustomReplace" }
    @{ Test = "Replace-RoadmapText avec erreur sans ThrowOnFailure"; Function = {
            # Ce test est censé générer un warning, c'est normal
            Write-Host "Note: Le warning suivant est attendu dans le cadre du test:" -ForegroundColor Yellow
            $result = Replace-RoadmapText -Text "Hello" -Pattern "H" -Replacement "X" -ReplaceType "Custom"
            return $result
        }; ShouldThrow = $false; Description = "Remplacement avec erreur sans ThrowOnFailure"
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

Write-Host "`nTests des fonctions Search-RoadmapText et Replace-RoadmapText terminés." -ForegroundColor Cyan
