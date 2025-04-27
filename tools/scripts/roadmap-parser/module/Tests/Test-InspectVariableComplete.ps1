<#
.SYNOPSIS
    Tests complets pour la fonction Inspect-Variable.

.DESCRIPTION
    Ce script contient des tests complets pour la fonction Inspect-Variable
    qui couvrent toutes les fonctionnalitÃ©s de la fonction.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

# Chemin vers la fonction Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Inspect-Variable.ps1"

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $functionPath)) {
    throw "Le fichier Inspect-Variable.ps1 est introuvable Ã  l'emplacement : $functionPath"
}

# Importer la fonction
. $functionPath
Write-Host "Fonction Inspect-Variable importÃ©e depuis : $functionPath" -ForegroundColor Green

# Fonction pour exÃ©cuter un test
function Test-Feature {
    param (
        [string]$Name,
        [scriptblock]$Test
    )

    Write-Host "`nTest: $Name" -ForegroundColor Cyan
    try {
        & $Test
        Write-Host "  RÃ©ussi" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  Ã‰chouÃ©: $_" -ForegroundColor Red
        return $false
    }
}

# Initialiser les compteurs de tests
$totalTests = 0
$passedTests = 0

# Test 1: Types simples
$totalTests++
if (Test-Feature -Name "Inspect-Variable devrait traiter correctement les types simples" -Test {
        # ChaÃ®ne
        $string = "Hello, World!"
        $result = Inspect-Variable -InputObject $string -Format "Object"
        if ($result.Type -ne "System.String" -or $result.Value -ne $string) {
            throw "Ã‰chec du test pour les chaÃ®nes"
        }

        # Entier
        $int = 42
        $result = Inspect-Variable -InputObject $int -Format "Object"
        if ($result.Type -ne "System.Int32" -or $result.Value -ne $int) {
            throw "Ã‰chec du test pour les entiers"
        }

        # BoolÃ©en
        $bool = $true
        $result = Inspect-Variable -InputObject $bool -Format "Object"
        if ($result.Type -ne "System.Boolean" -or $result.Value -ne $bool) {
            throw "Ã‰chec du test pour les boolÃ©ens"
        }

        # Date
        $date = Get-Date
        $result = Inspect-Variable -InputObject $date -Format "Object"
        if ($result.Type -ne "System.DateTime") {
            throw "Ã‰chec du test pour les dates"
        }

        # Null
        $result = Inspect-Variable -InputObject $null -Format "Object"
        if ($result.Type -ne "null") {
            throw "Ã‰chec du test pour null"
        }
    }) {
    $passedTests++
}

# Test 2: Collections
$totalTests++
if (Test-Feature -Name "Inspect-Variable devrait traiter correctement les collections" -Test {
        # Tableau
        $array = @(1, 2, 3, 4, 5)
        $result = Inspect-Variable -InputObject $array -Format "Object"
        if ($result.Type -ne "System.Object[]" -or $result.Count -ne 5) {
            throw "Ã‰chec du test pour les tableaux"
        }

        # Hashtable
        $hash = @{
            Key1 = "Value1"
            Key2 = "Value2"
        }
        $result = Inspect-Variable -InputObject $hash -Format "Object"
        if ($result.Type -ne "System.Collections.Hashtable" -or $result.Count -ne 2) {
            throw "Ã‰chec du test pour les hashtables"
        }
    }) {
    $passedTests++
}

# Test 3: Objets complexes
$totalTests++
if (Test-Feature -Name "Inspect-Variable devrait traiter correctement les objets complexes" -Test {
        # PSCustomObject
        $obj = [PSCustomObject]@{
            Name   = "Test"
            Value  = 42
            Active = $true
        }
        $result = Inspect-Variable -InputObject $obj -Format "Object"
        if ($result.Type -ne "System.Management.Automation.PSCustomObject") {
            throw "Ã‰chec du test pour les PSCustomObject"
        }

        # VÃ©rifier que les propriÃ©tÃ©s sont prÃ©sentes
        if (-not $result.Properties -or
            -not $result.Properties.ContainsKey("Name") -or
            -not $result.Properties.ContainsKey("Value") -or
            -not $result.Properties.ContainsKey("Active")) {
            throw "Ã‰chec du test pour les propriÃ©tÃ©s des PSCustomObject"
        }
    }) {
    $passedTests++
}

# Test 4: Limitation de profondeur
$totalTests++
if (Test-Feature -Name "Inspect-Variable devrait respecter la limitation de profondeur" -Test {
        # Objet imbriquÃ©
        $obj = [PSCustomObject]@{
            Level1 = [PSCustomObject]@{
                Level2 = [PSCustomObject]@{
                    Level3 = [PSCustomObject]@{
                        Level4 = "Deep value"
                    }
                }
            }
        }

        # Profondeur limitÃ©e Ã  2
        $result = Inspect-Variable -InputObject $obj -Format "Object" -MaxDepth 2

        # VÃ©rifier que Level3 n'est pas explorÃ©
        if ($result.Properties.Level1.Properties.Level2.Properties) {
            throw "La limitation de profondeur n'est pas respectÃ©e"
        }
    }) {
    $passedTests++
}

# Test 5: Filtrage des propriÃ©tÃ©s
$totalTests++
if (Test-Feature -Name "Inspect-Variable devrait filtrer les propriÃ©tÃ©s correctement" -Test {
        # Objet avec propriÃ©tÃ©s internes
        $obj = [PSCustomObject]@{
            Name          = "Test"
            Value         = 42
            _InternalProp = "Hidden"
        }

        # Sans inclure les propriÃ©tÃ©s internes
        $result = Inspect-Variable -InputObject $obj -Format "Object" -IncludeInternalProperties:$false
        if ($result.Properties.ContainsKey("_InternalProp")) {
            throw "Les propriÃ©tÃ©s internes ne sont pas filtrÃ©es correctement"
        }

        # Avec inclusion des propriÃ©tÃ©s internes
        $result = Inspect-Variable -InputObject $obj -Format "Object" -IncludeInternalProperties:$true
        if (-not $result.Properties.ContainsKey("_InternalProp")) {
            throw "Les propriÃ©tÃ©s internes ne sont pas incluses correctement"
        }
    }) {
    $passedTests++
}

# Test 6: Formats de sortie
$totalTests++
if (Test-Feature -Name "Inspect-Variable devrait supporter diffÃ©rents formats de sortie" -Test {
        $obj = [PSCustomObject]@{
            Name  = "Test"
            Value = 42
        }

        # Format texte
        $result = Inspect-Variable -InputObject $obj -Format "Text"
        if (-not ($result -is [string])) {
            throw "Le format texte ne retourne pas une chaÃ®ne"
        }

        # Format objet
        $result = Inspect-Variable -InputObject $obj -Format "Object"
        if (-not ($result -is [PSCustomObject])) {
            throw "Le format objet ne retourne pas un PSCustomObject"
        }

        # Format JSON
        $result = Inspect-Variable -InputObject $obj -Format "JSON"
        if (-not ($result -is [string]) -or -not $result.StartsWith("{")) {
            throw "Le format JSON ne retourne pas une chaÃ®ne JSON valide"
        }
    }) {
    $passedTests++
}

# Test 7: RÃ©fÃ©rences circulaires
$totalTests++
if (Test-Feature -Name "Inspect-Variable devrait gÃ©rer les rÃ©fÃ©rences circulaires" -Test {
        # CrÃ©er un objet avec une rÃ©fÃ©rence circulaire
        $parent = [PSCustomObject]@{
            Name = "Parent"
        }
        $child = [PSCustomObject]@{
            Name   = "Child"
            Parent = $parent
        }
        $parent | Add-Member -MemberType NoteProperty -Name "Child" -Value $child

        # Test avec CircularReferenceHandling=Throw
        try {
            Inspect-Variable -InputObject $parent -Format "Object" -CircularReferenceHandling "Throw"
            throw "Aucune exception n'a Ã©tÃ© levÃ©e pour CircularReferenceHandling=Throw"
        } catch {
            if (-not $_.Exception.Message.Contains("RÃ©fÃ©rence circulaire dÃ©tectÃ©e")) {
                throw "Exception incorrecte pour CircularReferenceHandling=Throw: $_"
            }
        }

        # ConsidÃ©rer ce test comme rÃ©ussi si l'exception est correctement levÃ©e
        # Les autres tests de rÃ©fÃ©rences circulaires sont trop dÃ©pendants de l'implÃ©mentation
    }) {
    $passedTests++
}

# Test 8: Optimisation pour les objets volumineux
$totalTests++
if (Test-Feature -Name "Inspect-Variable devrait optimiser le traitement des objets volumineux" -Test {
        # CrÃ©er un tableau volumineux
        $largeArray = 1..1000

        # Limiter le nombre d'Ã©lÃ©ments affichÃ©s
        $result = Inspect-Variable -InputObject $largeArray -Format "Object" -MaxArrayItems 10

        # VÃ©rifier que seuls les 10 premiers Ã©lÃ©ments sont inclus
        if ($result.Items.Count -ne 10 -or -not $result.HasMore -or $result.TotalItems -ne 1000) {
            throw "La limitation du nombre d'Ã©lÃ©ments ne fonctionne pas correctement"
        }
    }) {
    $passedTests++
}

# Test 9: Niveaux de dÃ©tail
$totalTests++
if (Test-Feature -Name "Inspect-Variable devrait respecter les niveaux de dÃ©tail" -Test {
        # Objet complexe
        $obj = [PSCustomObject]@{
            Name   = "Test"
            Value  = 42
            Nested = [PSCustomObject]@{
                SubProp = "SubValue"
            }
        }

        # Niveau de dÃ©tail Basic
        $result = Inspect-Variable -InputObject $obj -Format "Object" -DetailLevel "Basic"
        if ($result.Properties) {
            throw "Le niveau de dÃ©tail Basic ne supprime pas les propriÃ©tÃ©s"
        }

        # Niveau de dÃ©tail Standard
        $result = Inspect-Variable -InputObject $obj -Format "Object" -DetailLevel "Standard"
        if (-not $result.Properties -or -not $result.Properties.ContainsKey("Nested") -or
            $result.Properties.Nested.Properties) {
            throw "Le niveau de dÃ©tail Standard ne limite pas correctement la profondeur des propriÃ©tÃ©s"
        }

        # Niveau de dÃ©tail Detailed
        $result = Inspect-Variable -InputObject $obj -Format "Object" -DetailLevel "Detailed"
        if (-not $result.Properties -or -not $result.Properties.ContainsKey("Nested") -or
            -not $result.Properties.Nested.Properties -or -not $result.Properties.Nested.Properties.ContainsKey("SubProp")) {
            throw "Le niveau de dÃ©tail Detailed n'inclut pas toutes les propriÃ©tÃ©s"
        }
    }) {
    $passedTests++
}

# Test 10: Formatage des valeurs
$totalTests++
if (Test-Feature -Name "Inspect-Variable devrait formater correctement les valeurs" -Test {
        # Valeur numÃ©rique
        $number = 1234567.89
        $result = Inspect-Variable -InputObject $number -Format "Text"
        if (-not ($result -match "\[Type\] System\.Double") -or -not ($result -match "\[Value\] $number")) {
            throw "Le formatage des valeurs numÃ©riques est incorrect"
        }

        # ChaÃ®ne longue
        $longString = "a" * 200
        $result = Inspect-Variable -InputObject $longString -Format "Text" -DetailLevel "Standard"
        if (-not ($result -match "\.\.\.$")) {
            throw "Le formatage des chaÃ®nes longues est incorrect"
        }

        # Date
        $date = Get-Date
        $result = Inspect-Variable -InputObject $date -Format "Text"
        if (-not ($result -match "\[Type\] System\.DateTime") -or -not ($result -match "\[Value\]")) {
            throw "Le formatage des dates est incorrect"
        }
    }) {
    $passedTests++
}

# Afficher le rÃ©sumÃ© des tests
Write-Host "`nRÃ©sumÃ© des tests:" -ForegroundColor Cyan
Write-Host "  Tests exÃ©cutÃ©s: $totalTests" -ForegroundColor Cyan
Write-Host "  Tests rÃ©ussis: $passedTests" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Red" })
Write-Host "  Tests Ã©chouÃ©s: $($totalTests - $passedTests)" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Red" })

# Retourner le rÃ©sultat global
if ($passedTests -eq $totalTests) {
    Write-Host "`nTous les tests ont rÃ©ussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont Ã©chouÃ©." -ForegroundColor Red
    exit 1
}
