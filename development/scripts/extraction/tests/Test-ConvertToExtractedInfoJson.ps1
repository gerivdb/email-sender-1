# Test-ConvertToExtractedInfoJson.ps1
# Test de la fonction ConvertTo-ExtractedInfoJson avec différentes profondeurs

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Créer des objets de test avec différentes profondeurs de nesting
# Niveau 1: Objet simple
$simpleInfo = New-ExtractedInfo -Source "SimpleSource" -ExtractorName "SimpleExtractor"
$simpleInfo = Add-ExtractedInfoMetadata -Info $simpleInfo -Key "SimpleKey" -Value "SimpleValue"

# Niveau 2: Objet avec un niveau de nesting
$nestedInfo = New-StructuredDataExtractedInfo -Source "NestedSource" -ExtractorName "NestedExtractor" -Data @{
    Name = "Test"
    Value = 123
    IsActive = $true
    Date = [datetime]::Now
} -DataFormat "Hashtable"

# Niveau 3: Objet avec deux niveaux de nesting
$deepNestedInfo = New-StructuredDataExtractedInfo -Source "DeepNestedSource" -ExtractorName "DeepNestedExtractor" -Data @{
    Person = @{
        Name = "John"
        Age = 30
        Address = @{
            Street = "123 Main St"
            City = "Anytown"
            ZipCode = "12345"
        }
    }
    Items = @("Item1", "Item2", "Item3")
    Settings = @{
        Enabled = $true
        Timeout = 60
        Options = @("Option1", "Option2")
    }
} -DataFormat "Hashtable"

# Test 1: Convertir un objet simple en JSON avec profondeur par défaut
Write-Host "Test 1: Convertir un objet simple en JSON avec profondeur par défaut" -ForegroundColor Cyan
$simpleJson = ConvertTo-ExtractedInfoJson -InputObject $simpleInfo

$tests1 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $simpleJson }
    @{ Test = "Le résultat est une chaîne de caractères"; Condition = $simpleJson -is [string] }
    @{ Test = "Le JSON contient l'ID"; Condition = $simpleJson -match $simpleInfo.Id }
    @{ Test = "Le JSON contient la source"; Condition = $simpleJson -match $simpleInfo.Source }
    @{ Test = "Le JSON contient l'extracteur"; Condition = $simpleJson -match $simpleInfo.ExtractorName }
    @{ Test = "Le JSON contient la métadonnée"; Condition = $simpleJson -match "SimpleKey" -and $simpleJson -match "SimpleValue" }
)

$test1Success = $true
foreach ($test in $tests1) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $test1Success = $false
    }
}

# Test 2: Convertir un objet avec un niveau de nesting en JSON avec profondeur limitée
Write-Host "Test 2: Convertir un objet avec un niveau de nesting en JSON avec profondeur limitée" -ForegroundColor Cyan
$nestedJsonLimited = ConvertTo-ExtractedInfoJson -InputObject $nestedInfo -Depth 1

$tests2 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $nestedJsonLimited }
    @{ Test = "Le résultat est une chaîne de caractères"; Condition = $nestedJsonLimited -is [string] }
    @{ Test = "Le JSON contient l'ID"; Condition = $nestedJsonLimited -match $nestedInfo.Id }
    @{ Test = "Le JSON contient la source"; Condition = $nestedJsonLimited -match $nestedInfo.Source }
    @{ Test = "Le JSON contient l'extracteur"; Condition = $nestedJsonLimited -match $nestedInfo.ExtractorName }
    @{ Test = "Le JSON contient le format des données"; Condition = $nestedJsonLimited -match $nestedInfo.DataFormat }
    @{ Test = "Les données sont tronquées"; Condition = $nestedJsonLimited -match "System.Object" -or $nestedJsonLimited -match "..." }
)

$test2Success = $true
foreach ($test in $tests2) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $test2Success = $false
    }
}

# Test 3: Convertir un objet avec un niveau de nesting en JSON avec profondeur suffisante
Write-Host "Test 3: Convertir un objet avec un niveau de nesting en JSON avec profondeur suffisante" -ForegroundColor Cyan
$nestedJsonFull = ConvertTo-ExtractedInfoJson -InputObject $nestedInfo -Depth 5

$tests3 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $nestedJsonFull }
    @{ Test = "Le résultat est une chaîne de caractères"; Condition = $nestedJsonFull -is [string] }
    @{ Test = "Le JSON contient l'ID"; Condition = $nestedJsonFull -match $nestedInfo.Id }
    @{ Test = "Le JSON contient la source"; Condition = $nestedJsonFull -match $nestedInfo.Source }
    @{ Test = "Le JSON contient l'extracteur"; Condition = $nestedJsonFull -match $nestedInfo.ExtractorName }
    @{ Test = "Le JSON contient le format des données"; Condition = $nestedJsonFull -match $nestedInfo.DataFormat }
    @{ Test = "Le JSON contient le nom dans les données"; Condition = $nestedJsonFull -match "Test" }
    @{ Test = "Le JSON contient la valeur dans les données"; Condition = $nestedJsonFull -match "123" }
    @{ Test = "Le JSON contient le booléen dans les données"; Condition = $nestedJsonFull -match "true" -or $nestedJsonFull -match "True" }
)

$test3Success = $true
foreach ($test in $tests3) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $test3Success = $false
    }
}

# Test 4: Convertir un objet avec deux niveaux de nesting en JSON avec profondeur suffisante
Write-Host "Test 4: Convertir un objet avec deux niveaux de nesting en JSON avec profondeur suffisante" -ForegroundColor Cyan
$deepNestedJsonFull = ConvertTo-ExtractedInfoJson -InputObject $deepNestedInfo -Depth 10

$tests4 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $deepNestedJsonFull }
    @{ Test = "Le résultat est une chaîne de caractères"; Condition = $deepNestedJsonFull -is [string] }
    @{ Test = "Le JSON contient l'ID"; Condition = $deepNestedJsonFull -match $deepNestedInfo.Id }
    @{ Test = "Le JSON contient la source"; Condition = $deepNestedJsonFull -match $deepNestedInfo.Source }
    @{ Test = "Le JSON contient l'extracteur"; Condition = $deepNestedJsonFull -match $deepNestedInfo.ExtractorName }
    @{ Test = "Le JSON contient le format des données"; Condition = $deepNestedJsonFull -match $deepNestedInfo.DataFormat }
    @{ Test = "Le JSON contient le nom de la personne"; Condition = $deepNestedJsonFull -match "John" }
    @{ Test = "Le JSON contient l'âge de la personne"; Condition = $deepNestedJsonFull -match "30" }
    @{ Test = "Le JSON contient la rue de l'adresse"; Condition = $deepNestedJsonFull -match "123 Main St" }
    @{ Test = "Le JSON contient la ville de l'adresse"; Condition = $deepNestedJsonFull -match "Anytown" }
    @{ Test = "Le JSON contient le code postal de l'adresse"; Condition = $deepNestedJsonFull -match "12345" }
    @{ Test = "Le JSON contient les éléments"; Condition = $deepNestedJsonFull -match "Item1" -and $deepNestedJsonFull -match "Item2" -and $deepNestedJsonFull -match "Item3" }
    @{ Test = "Le JSON contient les paramètres"; Condition = $deepNestedJsonFull -match "Enabled" -and $deepNestedJsonFull -match "Timeout" -and $deepNestedJsonFull -match "Options" }
)

$test4Success = $true
foreach ($test in $tests4) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $test4Success = $false
    }
}

# Test 5: Convertir un objet avec deux niveaux de nesting en JSON avec profondeur insuffisante
Write-Host "Test 5: Convertir un objet avec deux niveaux de nesting en JSON avec profondeur insuffisante" -ForegroundColor Cyan
$deepNestedJsonLimited = ConvertTo-ExtractedInfoJson -InputObject $deepNestedInfo -Depth 2

$tests5 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $deepNestedJsonLimited }
    @{ Test = "Le résultat est une chaîne de caractères"; Condition = $deepNestedJsonLimited -is [string] }
    @{ Test = "Le JSON contient l'ID"; Condition = $deepNestedJsonLimited -match $deepNestedInfo.Id }
    @{ Test = "Le JSON contient la source"; Condition = $deepNestedJsonLimited -match $deepNestedInfo.Source }
    @{ Test = "Le JSON contient l'extracteur"; Condition = $deepNestedJsonLimited -match $deepNestedInfo.ExtractorName }
    @{ Test = "Le JSON contient le format des données"; Condition = $deepNestedJsonLimited -match $deepNestedInfo.DataFormat }
    @{ Test = "Le JSON contient Person"; Condition = $deepNestedJsonLimited -match "Person" }
    @{ Test = "Le JSON contient Items"; Condition = $deepNestedJsonLimited -match "Items" }
    @{ Test = "Le JSON contient Settings"; Condition = $deepNestedJsonLimited -match "Settings" }
    @{ Test = "L'adresse est tronquée"; Condition = $deepNestedJsonLimited -notmatch "123 Main St" -or $deepNestedJsonLimited -match "System.Object" -or $deepNestedJsonLimited -match "..." }
)

$test5Success = $true
foreach ($test in $tests5) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $test5Success = $false
    }
}

# Résultat final
$allSuccess = $test1Success -and $test2Success -and $test3Success -and $test4Success -and $test5Success

if ($allSuccess) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}
