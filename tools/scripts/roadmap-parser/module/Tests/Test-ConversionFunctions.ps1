#
# Test-ConversionFunctions.ps1
#
# Script pour tester les fonctions de conversion
#

# Importer les fonctions de conversion
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$conversionPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\Conversion"
$publicPath = Join-Path -Path $modulePath -ChildPath "Functions\Public"

# Créer les répertoires s'ils n'existent pas
if (-not (Test-Path -Path $conversionPath)) {
    New-Item -Path $conversionPath -ItemType Directory -Force | Out-Null
}

# Importer les fonctions de conversion
. "$conversionPath\ConvertTo-Type.ps1"
. "$conversionPath\ConvertTo-ComplexType.ps1"
. "$conversionPath\ConvertTo-SerializedFormat.ps1"
. "$conversionPath\ConvertFrom-SerializedFormat.ps1"
. "$publicPath\ConvertTo-RoadmapFormat.ps1"
. "$publicPath\ConvertFrom-RoadmapFormat.ps1"

Write-Host "Début des tests des fonctions de conversion..." -ForegroundColor Cyan

# Test 1: ConvertTo-Type
Write-Host "`nTest 1: ConvertTo-Type" -ForegroundColor Cyan

$testCases = @(
    @{ Value = "42"; Type = "Integer"; Expected = 42; Description = "Chaîne vers entier" }
    @{ Value = 42; Type = "String"; Expected = "42"; Description = "Entier vers chaîne" }
    @{ Value = "3.14"; Type = "Decimal"; Expected = 3.14; Description = "Chaîne vers décimal" }
    @{ Value = "true"; Type = "Boolean"; Expected = $true; Description = "Chaîne vers booléen" }
    @{ Value = "2023-01-01"; Type = "DateTime"; Format = "yyyy-MM-dd"; Expected = [datetime]::ParseExact("2023-01-01", "yyyy-MM-dd", [System.Globalization.CultureInfo]::InvariantCulture); Description = "Chaîne vers date/heure avec format" }
    @{ Value = "1,2,3"; Type = "Array"; Expected = @("1,2,3"); Description = "Chaîne vers tableau" }
    @{ Value = [PSCustomObject]@{ Name = "John"; Age = 30 }; Type = "Hashtable"; Expected = @{ Name = "John"; Age = 30 }; Description = "PSObject vers hashtable" }
    @{ Value = @{ Name = "John"; Age = 30 }; Type = "PSObject"; Expected = [PSCustomObject]@{ Name = "John"; Age = 30 }; Description = "Hashtable vers PSObject" }
    @{ Value = "{ Write-Host 'Hello' }"; Type = "ScriptBlock"; Expected = { Write-Host 'Hello' }; Description = "Chaîne vers bloc de script" }
    @{ Value = "123e4567-e89b-12d3-a456-426614174000"; Type = "Guid"; Expected = [guid]::Parse("123e4567-e89b-12d3-a456-426614174000"); Description = "Chaîne vers GUID" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Value = $testCase.Value
        Type  = $testCase.Type
    }

    if ($testCase.ContainsKey("Format")) {
        $params["Format"] = $testCase.Format
    }

    $result = ConvertTo-Type @params

    # Vérifier le résultat
    $success = $false
    if ($testCase.Type -eq "PSObject") {
        $success = ($result.PSObject.Properties.Name -join ",") -eq ($testCase.Expected.PSObject.Properties.Name -join ",")
    } elseif ($testCase.Type -eq "Hashtable") {
        $success = ($result.Keys -join ",") -eq ($testCase.Expected.Keys -join ",")
    } elseif ($testCase.Type -eq "ScriptBlock") {
        $success = $result -is [scriptblock]
    } elseif ($testCase.Type -eq "Array") {
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
        Write-Host "    Attendu: $($testCase.Expected)" -ForegroundColor Red
        Write-Host "    Obtenu: $result" -ForegroundColor Red
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 2: ConvertTo-ComplexType
Write-Host "`nTest 2: ConvertTo-ComplexType" -ForegroundColor Cyan

$testCases = @(
    @{ Value = "<root><item>value</item></root>"; Type = "XmlDocument"; Description = "Chaîne vers document XML" }
    @{ Value = '{"name":"John","age":30}'; Type = "JsonObject"; Description = "Chaîne JSON vers objet JSON" }
    @{ Value = "Name,Age`nJohn,30"; Type = "CsvData"; Description = "Chaîne CSV vers données CSV" }
    @{ Value = "# Titre`n## Sous-titre"; Type = "MarkdownDocument"; Description = "Chaîne vers document Markdown" }
    @{ Value = "<html><body><h1>Titre</h1></body></html>"; Type = "HtmlDocument"; Description = "Chaîne vers document HTML" }
    @{ Value = "name: John`nage: 30"; Type = "YamlDocument"; Description = "Chaîne YAML vers document YAML" }
    @{ Value = "Hello World"; Type = "Base64"; Description = "Chaîne vers Base64" }
    @{ Value = "Password123"; Type = "SecureString"; Description = "Chaîne vers chaîne sécurisée" }
    @{ Value = @{ UserName = "user"; Password = "pass" }; Type = "Credential"; Description = "Hashtable vers objet d'identification" }
    @{ Value = "https://www.example.com"; Type = "Uri"; Description = "Chaîne vers URI" }
    @{ Value = "1.0.0"; Type = "Version"; Description = "Chaîne vers version" }
    @{ Value = "42"; Type = "Custom"; CustomType = "System.Int32"; Description = "Chaîne vers type personnalisé" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Value = $testCase.Value
        Type  = $testCase.Type
    }

    if ($testCase.ContainsKey("CustomType")) {
        $params["CustomType"] = $testCase.CustomType
    }

    $result = ConvertTo-ComplexType @params

    # Vérifier le résultat
    $success = $false
    if ($testCase.Type -eq "XmlDocument") {
        $success = $result -is [System.Xml.XmlDocument]
    } elseif ($testCase.Type -eq "JsonObject") {
        $success = $result -is [PSObject] -or $result -is [hashtable]
    } elseif ($testCase.Type -eq "CsvData") {
        $success = $result -is [array] -or $result -is [PSObject]
    } elseif ($testCase.Type -eq "MarkdownDocument" -or $testCase.Type -eq "HtmlDocument") {
        $success = $result -is [string]
    } elseif ($testCase.Type -eq "YamlDocument") {
        $success = $result -is [PSObject] -or $result -is [hashtable]
    } elseif ($testCase.Type -eq "Base64") {
        $success = $result -is [string] -and $result -match "^[A-Za-z0-9+/=]+$"
    } elseif ($testCase.Type -eq "SecureString") {
        $success = $result -is [System.Security.SecureString]
    } elseif ($testCase.Type -eq "Credential") {
        $success = $result -is [System.Management.Automation.PSCredential]
    } elseif ($testCase.Type -eq "Uri") {
        $success = $result -is [System.Uri]
    } elseif ($testCase.Type -eq "Version") {
        $success = $result -is [System.Version]
    } elseif ($testCase.Type -eq "Custom") {
        $success = $result -is [int]
    }

    $status = if ($success) { "Réussi" } else { "Échoué" }
    $color = if ($success) { "Green" } else { "Red" }

    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color

    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    Type attendu: $($testCase.Type)" -ForegroundColor Red
        Write-Host "    Type obtenu: $($result.GetType().FullName)" -ForegroundColor Red
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 3: ConvertTo-SerializedFormat
Write-Host "`nTest 3: ConvertTo-SerializedFormat" -ForegroundColor Cyan

$testObject = [PSCustomObject]@{
    Name    = "John"
    Age     = 30
    Address = [PSCustomObject]@{
        Street  = "123 Main St"
        City    = "Anytown"
        ZipCode = "12345"
    }
}

$testCases = @(
    @{ Format = "Json"; Description = "Objet vers JSON" }
    @{ Format = "Xml"; Description = "Objet vers XML" }
    @{ Format = "Csv"; Description = "Objet vers CSV" }
    @{ Format = "Yaml"; Description = "Objet vers YAML" }
    @{ Format = "Psd1"; Description = "Objet vers PSD1" }
    @{ Format = "Base64"; Description = "Objet vers Base64" }
    @{ Format = "Clixml"; Description = "Objet vers CLIXML" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        InputObject = $testObject
        Format      = $testCase.Format
    }

    $result = ConvertTo-SerializedFormat @params

    # Vérifier le résultat
    $success = $false
    if ($testCase.Format -eq "Json") {
        $success = $result -match '"Name":\s*"John"' -and $result -match '"Age":\s*30'
    } elseif ($testCase.Format -eq "Xml" -or $testCase.Format -eq "Clixml") {
        $success = $result -match "<Name>John</Name>" -or $result -match "John" -and $result -match "30"
    } elseif ($testCase.Format -eq "Csv") {
        $success = $result -match "Name" -and $result -match "Age" -and $result -match "John" -and $result -match "30"
    } elseif ($testCase.Format -eq "Yaml") {
        $success = $result -match "Name: John" -and $result -match "Age: 30"
    } elseif ($testCase.Format -eq "Psd1") {
        $success = $result -match "Name = 'John'" -and $result -match "Age = 30"
    } elseif ($testCase.Format -eq "Base64") {
        $success = $result -match "^[A-Za-z0-9+/=]+$"
    }

    $status = if ($success) { "Réussi" } else { "Échoué" }
    $color = if ($success) { "Green" } else { "Red" }

    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color

    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    Résultat: $result" -ForegroundColor Red
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 4: ConvertFrom-SerializedFormat
Write-Host "`nTest 4: ConvertFrom-SerializedFormat" -ForegroundColor Cyan

$testCases = @(
    @{ InputObject = '{"Name":"John","Age":30}'; Format = "Json"; Description = "JSON vers objet" }
    @{ InputObject = "<Objs Version=`"1.1.0.1`" xmlns=`"http://schemas.microsoft.com/powershell/2004/04`"><Obj S=`"System.Management.Automation.PSCustomObject`"><MS><S N=`"Name`">John</S><I32 N=`"Age`">30</I32></MS></Obj></Objs>"; Format = "Clixml"; Description = "CLIXML vers objet" }
    @{ InputObject = "Name,Age`nJohn,30"; Format = "Csv"; Description = "CSV vers objet" }
    @{ InputObject = "---`nName: John`nAge: 30"; Format = "Yaml"; Description = "YAML vers objet" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        InputObject = $testCase.InputObject
        Format      = $testCase.Format
    }

    $result = ConvertFrom-SerializedFormat @params

    # Vérifier le résultat
    $success = $false
    if ($result -is [PSObject] -or $result -is [hashtable] -or $result -is [array]) {
        if ($result.Name -eq "John" -and $result.Age -eq 30) {
            $success = $true
        } elseif ($result -is [array] -and $result.Count -gt 0 -and $result[0].Name -eq "John" -and $result[0].Age -eq 30) {
            $success = $true
        }
    }

    $status = if ($success) { "Réussi" } else { "Échoué" }
    $color = if ($success) { "Green" } else { "Red" }

    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color

    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    Résultat: $result" -ForegroundColor Red
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 5: ConvertTo-RoadmapFormat
Write-Host "`nTest 5: ConvertTo-RoadmapFormat" -ForegroundColor Cyan

$testCases = @(
    @{ Value = "42"; TargetType = "Integer"; Expected = 42; Description = "Chaîne vers entier" }
    @{ Value = [PSCustomObject]@{ Name = "John"; Age = 30 }; TargetType = "JsonObject"; Serialize = $true; SerializationFormat = "Json"; Description = "Objet vers JSON sérialisé" }
    @{ Value = "Hello World"; TargetType = "Base64"; Description = "Chaîne vers Base64" }
    @{ Value = "2023-01-01"; TargetType = "DateTime"; Format = "yyyy-MM-dd"; Description = "Chaîne vers date/heure avec format" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        Value      = $testCase.Value
        TargetType = $testCase.TargetType
    }

    if ($testCase.ContainsKey("Format")) {
        $params["Format"] = $testCase.Format
    }

    if ($testCase.ContainsKey("Serialize") -and $testCase.Serialize) {
        $params["Serialize"] = $true
        $params["SerializationFormat"] = $testCase.SerializationFormat
    }

    $result = ConvertTo-RoadmapFormat @params

    # Vérifier le résultat
    $success = $false
    if ($testCase.TargetType -eq "Integer" -and $result -eq 42) {
        $success = $true
    } elseif ($testCase.TargetType -eq "JsonObject" -and $testCase.Serialize -and $result -match '"Name":\s*"John"' -and $result -match '"Age":\s*30') {
        $success = $true
    } elseif ($testCase.TargetType -eq "Base64" -and $result -match "^[A-Za-z0-9+/=]+$") {
        $success = $true
    } elseif ($testCase.TargetType -eq "DateTime" -and $result -is [datetime] -and $result.ToString("yyyy-MM-dd") -eq "2023-01-01") {
        $success = $true
    }

    $status = if ($success) { "Réussi" } else { "Échoué" }
    $color = if ($success) { "Green" } else { "Red" }

    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color

    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    Résultat: $result" -ForegroundColor Red
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 6: ConvertFrom-RoadmapFormat
Write-Host "`nTest 6: ConvertFrom-RoadmapFormat" -ForegroundColor Cyan

$testCases = @(
    @{ InputObject = '{"Name":"John","Age":30}'; SourceFormat = "Json"; Description = "JSON vers objet" }
    @{ InputObject = '{"Name":"John","Age":30}'; SourceFormat = "Json"; TargetType = "Hashtable"; Description = "JSON vers hashtable" }
    @{ InputObject = "Name,Age`nJohn,30"; SourceFormat = "Csv"; Description = "CSV vers objet" }
    @{ InputObject = "---`nName: John`nAge: 30"; SourceFormat = "Yaml"; Description = "YAML vers objet" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $params = @{
        InputObject  = $testCase.InputObject
        SourceFormat = $testCase.SourceFormat
    }

    if ($testCase.ContainsKey("TargetType")) {
        $params["TargetType"] = $testCase.TargetType
    }

    $result = ConvertFrom-RoadmapFormat @params

    # Vérifier le résultat
    $success = $false
    if ($testCase.SourceFormat -eq "Json" -and -not $testCase.ContainsKey("TargetType")) {
        $success = $result.Name -eq "John" -and $result.Age -eq 30
    } elseif ($testCase.SourceFormat -eq "Json" -and $testCase.TargetType -eq "Hashtable") {
        $success = $result -is [hashtable] -and $result.Name -eq "John" -and $result.Age -eq 30
    } elseif ($testCase.SourceFormat -eq "Csv") {
        $success = ($result -is [array] -and $result.Count -gt 0 -and $result[0].Name -eq "John" -and $result[0].Age -eq 30) -or
                  ($result -is [PSObject] -and $result.Name -eq "John" -and $result.Age -eq 30)
    } elseif ($testCase.SourceFormat -eq "Yaml") {
        $success = $result.Name -eq "John" -and $result.Age -eq 30
    }

    $status = if ($success) { "Réussi" } else { "Échoué" }
    $color = if ($success) { "Green" } else { "Red" }

    Write-Host "  $($testCase.Description): $status" -ForegroundColor $color

    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    Résultat: $result" -ForegroundColor Red
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 7: Gestion des erreurs
Write-Host "`nTest 7: Gestion des erreurs" -ForegroundColor Cyan

$testCases = @(
    @{ Test = "ConvertTo-Type avec valeur invalide"; Function = { ConvertTo-Type -Value "abc" -Type "Integer" }; ShouldThrow = $false; Description = "ConvertTo-Type avec valeur invalide sans ThrowOnFailure" }
    @{ Test = "ConvertTo-Type avec valeur invalide et ThrowOnFailure"; Function = { ConvertTo-Type -Value "abc" -Type "Integer" -ThrowOnFailure }; ShouldThrow = $true; Description = "ConvertTo-Type avec valeur invalide et ThrowOnFailure" }
    @{ Test = "ConvertTo-Type avec valeur invalide et DefaultValue"; Function = { ConvertTo-Type -Value "abc" -Type "Integer" -DefaultValue 0 }; ShouldThrow = $false; ExpectedResult = 0; Description = "ConvertTo-Type avec valeur invalide et DefaultValue" }
    @{ Test = "ConvertTo-ComplexType avec valeur invalide"; Function = { ConvertTo-ComplexType -Value "invalid" -Type "JsonObject" }; ShouldThrow = $false; Description = "ConvertTo-ComplexType avec valeur invalide sans ThrowOnFailure" }
    @{ Test = "ConvertTo-ComplexType avec valeur invalide et ThrowOnFailure"; Function = { ConvertTo-ComplexType -Value "invalid" -Type "JsonObject" -ThrowOnFailure }; ShouldThrow = $true; Description = "ConvertTo-ComplexType avec valeur invalide et ThrowOnFailure" }
    @{ Test = "ConvertTo-SerializedFormat avec valeur valide"; Function = { ConvertTo-SerializedFormat -InputObject @{Name = "John" } -Format "Json" }; ShouldThrow = $false; Description = "ConvertTo-SerializedFormat avec valeur valide sans ThrowOnFailure" }
    @{ Test = "ConvertTo-SerializedFormat avec valeur invalide et ThrowOnFailure"; Function = { ConvertTo-SerializedFormat -InputObject @{$null = "value" } -Format "Json" -ThrowOnFailure }; ShouldThrow = $true; Description = "ConvertTo-SerializedFormat avec valeur invalide et ThrowOnFailure" }
    @{ Test = "ConvertFrom-SerializedFormat avec valeur valide"; Function = { ConvertFrom-SerializedFormat -InputObject '{"Name":"John"}' -Format "Json" }; ShouldThrow = $false; Description = "ConvertFrom-SerializedFormat avec valeur valide sans ThrowOnFailure" }
    @{ Test = "ConvertFrom-SerializedFormat avec valeur invalide et ThrowOnFailure"; Function = { ConvertFrom-SerializedFormat -InputObject "invalid" -Format "Json" -ThrowOnFailure }; ShouldThrow = $true; Description = "ConvertFrom-SerializedFormat avec valeur invalide et ThrowOnFailure" }
    @{ Test = "ConvertTo-RoadmapFormat avec valeur invalide"; Function = { ConvertTo-RoadmapFormat -Value "abc" -TargetType "Integer" }; ShouldThrow = $false; Description = "ConvertTo-RoadmapFormat avec valeur invalide sans ThrowOnFailure" }
    @{ Test = "ConvertTo-RoadmapFormat avec valeur invalide et ThrowOnFailure"; Function = { ConvertTo-RoadmapFormat -Value "abc" -TargetType "Integer" -ThrowOnFailure }; ShouldThrow = $true; Description = "ConvertTo-RoadmapFormat avec valeur invalide et ThrowOnFailure" }
    @{ Test = "ConvertFrom-RoadmapFormat avec valeur invalide"; Function = { ConvertFrom-RoadmapFormat -InputObject "invalid" -SourceFormat "Json" }; ShouldThrow = $false; Description = "ConvertFrom-RoadmapFormat avec valeur invalide sans ThrowOnFailure" }
    @{ Test = "ConvertFrom-RoadmapFormat avec valeur invalide et ThrowOnFailure"; Function = { ConvertFrom-RoadmapFormat -InputObject "invalid" -SourceFormat "Json" -ThrowOnFailure }; ShouldThrow = $true; Description = "ConvertFrom-RoadmapFormat avec valeur invalide et ThrowOnFailure" }
)

$successCount = 0
$failureCount = 0

foreach ($testCase in $testCases) {
    $exceptionThrown = $false
    $result = $null

    try {
        $result = & $testCase.Function
    } catch {
        $exceptionThrown = $true
    }

    # Vérifier le résultat
    $success = $false
    if ($testCase.ShouldThrow -and $exceptionThrown) {
        $success = $true
    } elseif (-not $testCase.ShouldThrow -and -not $exceptionThrown) {
        if ($testCase.ContainsKey("ExpectedResult")) {
            $success = $result -eq $testCase.ExpectedResult
        } else {
            $success = $true
        }
    }

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

Write-Host "`nTests des fonctions de conversion terminés." -ForegroundColor Cyan
