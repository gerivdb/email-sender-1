#
# Test-RoadmapStringOperation.ps1
#
# Script pour tester la fonction Invoke-RoadmapStringOperation
#

# Importer la fonction Invoke-RoadmapStringOperation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\StringManipulation\Invoke-RoadmapStringOperation.ps1"

# Créer le répertoire s'il n'existe pas
$functionDir = Split-Path -Parent $functionPath
if (-not (Test-Path -Path $functionDir)) {
    New-Item -Path $functionDir -ItemType Directory -Force | Out-Null
}

# Importer la fonction
. $functionPath

# Ajouter les références nécessaires pour les opérations d'encodage/décodage
Add-Type -AssemblyName System.Web

Write-Host "Début des tests de la fonction Invoke-RoadmapStringOperation..." -ForegroundColor Cyan

# Test 1: Opérations de base
Write-Host "`nTest 1: Opérations de base" -ForegroundColor Cyan

$testCases = @(
    @{ Text = "Hello World"; Operation = "Split"; Expected = @("Hello", "World"); Description = "Split" }
    @{ Text = "Hello`r`nWorld"; Operation = "Join"; Delimiter = " - "; Expected = "Hello - World"; Description = "Join" }
    @{ Text = "Hello World"; Operation = "Extract"; Pattern = "Hello"; Expected = "Hello"; Description = "Extract avec Pattern" }
    @{ Text = "Hello World"; Operation = "Extract"; StartIndex = 6; Expected = "World"; Description = "Extract avec StartIndex" }
    @{ Text = "Hello World"; Operation = "Extract"; StartIndex = 0; Length = 5; Expected = "Hello"; Description = "Extract avec StartIndex et Length" }
    @{ Text = "Hello World Hello"; Operation = "Count"; Pattern = "Hello"; Expected = 2; Description = "Count" }
    @{ Text = "Hello World"; Operation = "Measure"; Expected = 11; Description = "Measure" }
    @{ Text = "Hello"; Operation = "Compare"; Pattern = "hello"; Expected = 1; Description = "Compare (sensible à la casse)" }
    @{ Text = "Hello"; Operation = "Compare"; Pattern = "hello"; IgnoreCase = $true; Expected = 0; Description = "Compare (insensible à la casse)" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Text      = $testCase.Text
        Operation = $testCase.Operation
    }

    if ($testCase.ContainsKey("Delimiter")) {
        $params["Delimiter"] = $testCase.Delimiter
    }

    if ($testCase.ContainsKey("Pattern")) {
        $params["Pattern"] = $testCase.Pattern
    }

    if ($testCase.ContainsKey("StartIndex")) {
        $params["StartIndex"] = $testCase.StartIndex
    }

    if ($testCase.ContainsKey("Length")) {
        $params["Length"] = $testCase.Length
    }

    if ($testCase.ContainsKey("IgnoreCase")) {
        $params["IgnoreCase"] = $testCase.IgnoreCase
    }

    $result = Invoke-RoadmapStringOperation @params

    # Vérifier le résultat
    $success = $false

    if ($testCase.Operation -eq "Split") {
        $success = ($result -join ",") -eq ($testCase.Expected -join ",")
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
        Write-Host "    Résultat attendu: '$($testCase.Expected)'" -ForegroundColor Red
        Write-Host "    Résultat obtenu: '$result'" -ForegroundColor Red
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 2: Opérations de manipulation de texte
Write-Host "`nTest 2: Opérations de manipulation de texte" -ForegroundColor Cyan

$testCases = @(
    @{ Text = "Hello`r`nWorld`r`nHello"; Operation = "Sort"; Expected = "Hello`r`nHello`r`nWorld"; Description = "Sort" }
    @{ Text = "Hello`r`nWorld`r`nHello"; Operation = "Unique"; Expected = "Hello`r`nWorld"; Description = "Unique" }
    @{ Text = "Hello"; Operation = "Reverse"; Expected = "olleH"; Description = "Reverse (caractères)" }
    @{ Text = "Hello`r`nWorld"; Operation = "Reverse"; ByLine = $true; Expected = "World`r`nHello"; Description = "Reverse (lignes)" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Text      = $testCase.Text
        Operation = $testCase.Operation
    }

    if ($testCase.ContainsKey("ByLine")) {
        $params["ByLine"] = $testCase.ByLine
    }

    if ($testCase.ContainsKey("Descending")) {
        $params["Descending"] = $testCase.Descending
    }

    $result = Invoke-RoadmapStringOperation @params

    # Vérifier le résultat
    $success = $false

    # Normaliser les sauts de ligne pour la comparaison
    $normalizedResult = $result -replace "`r`n|`r|`n", "`r`n"
    $normalizedExpected = $testCase.Expected -replace "`r`n|`r|`n", "`r`n"
    $success = $normalizedResult -eq $normalizedExpected

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

# Test 3: Opérations d'encodage/décodage
Write-Host "`nTest 3: Opérations d'encodage/décodage" -ForegroundColor Cyan

$testCases = @(
    @{ Text = "Hello World"; Operation = "Base64Encode"; Expected = "SGVsbG8gV29ybGQ="; Description = "Base64Encode" }
    @{ Text = "SGVsbG8gV29ybGQ="; Operation = "Base64Decode"; Expected = "Hello World"; Description = "Base64Decode" }
    @{ Text = "Hello World"; Operation = "UrlEncode"; Expected = "Hello+World"; Description = "UrlEncode" }
    @{ Text = "Hello+World"; Operation = "UrlDecode"; Expected = "Hello World"; Description = "UrlDecode" }
    @{ Text = "<Hello>"; Operation = "HtmlEncode"; Expected = "&lt;Hello&gt;"; Description = "HtmlEncode" }
    @{ Text = "&lt;Hello&gt;"; Operation = "HtmlDecode"; Expected = "<Hello>"; Description = "HtmlDecode" }
    @{ Text = "<Hello>"; Operation = "XmlEncode"; Expected = "&lt;Hello&gt;"; Description = "XmlEncode" }
    @{ Text = "&lt;Hello&gt;"; Operation = "XmlDecode"; Expected = "<Hello>"; Description = "XmlDecode" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Text      = $testCase.Text
        Operation = $testCase.Operation
    }

    $result = Invoke-RoadmapStringOperation @params

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

# Test 4: Opérations de chiffrement/déchiffrement
Write-Host "`nTest 4: Opérations de chiffrement/déchiffrement" -ForegroundColor Cyan

$testCases = @(
    @{ Text = "Hello World"; Operation = "Hash"; Expected = "a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e"; Description = "Hash (SHA256)" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Text      = $testCase.Text
        Operation = $testCase.Operation
    }

    if ($testCase.ContainsKey("Algorithm")) {
        $params["Algorithm"] = $testCase.Algorithm
    }

    if ($testCase.ContainsKey("Key")) {
        $params["Key"] = $testCase.Key
    }

    $result = Invoke-RoadmapStringOperation @params

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

# Test de chiffrement/déchiffrement
$text = "Hello World"
$key = "MySecretKey"

$encrypted = Invoke-RoadmapStringOperation -Text $text -Operation "Encrypt" -Key $key
$decrypted = Invoke-RoadmapStringOperation -Text $encrypted -Operation "Decrypt" -Key $key

$success = $decrypted -eq $text

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Encrypt/Decrypt: $status" -ForegroundColor $color

if ($success) {
    $successCount++
} else {
    $failureCount++
    Write-Host "    Texte original: '$text'" -ForegroundColor Red
    Write-Host "    Texte déchiffré: '$decrypted'" -ForegroundColor Red
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 5: Opération personnalisée
Write-Host "`nTest 5: Opération personnalisée" -ForegroundColor Cyan

$customOperation = {
    param($Text)

    # Inverser l'ordre des mots
    $words = $Text -split '\s+'
    [array]::Reverse($words)
    $result = $words -join " "

    return $result
}

$testCases = @(
    @{ Text = "Hello World"; Operation = "Custom"; CustomOperation = $customOperation; Expected = "World Hello"; Description = "Opération personnalisée" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Text            = $testCase.Text
        Operation       = $testCase.Operation
        CustomOperation = $testCase.CustomOperation
    }

    $result = Invoke-RoadmapStringOperation @params

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

# Test 6: Gestion des erreurs
Write-Host "`nTest 6: Gestion des erreurs" -ForegroundColor Cyan

$testCases = @(
    @{ Test = "Invoke-RoadmapStringOperation sans Pattern pour Extract"; Function = { Invoke-RoadmapStringOperation -Text "Hello" -Operation "Extract" -ThrowOnFailure }; ShouldThrow = $true; Description = "Extract sans Pattern ni StartIndex" }
    @{ Test = "Invoke-RoadmapStringOperation sans Pattern pour Compare"; Function = { Invoke-RoadmapStringOperation -Text "Hello" -Operation "Compare" -ThrowOnFailure }; ShouldThrow = $true; Description = "Compare sans Pattern" }
    @{ Test = "Invoke-RoadmapStringOperation sans Key pour Encrypt"; Function = { Invoke-RoadmapStringOperation -Text "Hello" -Operation "Encrypt" -ThrowOnFailure }; ShouldThrow = $true; Description = "Encrypt sans Key" }
    @{ Test = "Invoke-RoadmapStringOperation sans Key pour Decrypt"; Function = { Invoke-RoadmapStringOperation -Text "Hello" -Operation "Decrypt" -ThrowOnFailure }; ShouldThrow = $true; Description = "Decrypt sans Key" }
    @{ Test = "Invoke-RoadmapStringOperation sans CustomOperation pour Custom"; Function = { Invoke-RoadmapStringOperation -Text "Hello" -Operation "Custom" -ThrowOnFailure }; ShouldThrow = $true; Description = "Custom sans CustomOperation" }
    @{ Test = "Invoke-RoadmapStringOperation avec erreur sans ThrowOnFailure"; Function = { Invoke-RoadmapStringOperation -Text "Hello" -Operation "Extract" }; ShouldThrow = $false; Description = "Erreur sans ThrowOnFailure" }
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

Write-Host "`nTests de la fonction Invoke-RoadmapStringOperation terminés." -ForegroundColor Cyan
