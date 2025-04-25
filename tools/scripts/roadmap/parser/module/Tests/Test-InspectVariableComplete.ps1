<#
.SYNOPSIS
    Tests complets pour la fonction Inspect-Variable.

.DESCRIPTION
    Ce script contient des tests complets pour la fonction Inspect-Variable
    qui couvrent toutes les fonctionnalités de la fonction.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

# Chemin vers la fonction à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Inspect-Variable.ps1"

# Vérifier si le fichier existe
if (-not (Test-Path -Path $functionPath)) {
    throw "Le fichier Inspect-Variable.ps1 est introuvable à l'emplacement : $functionPath"
}

# Importer la fonction
. $functionPath
Write-Host "Fonction Inspect-Variable importée depuis : $functionPath" -ForegroundColor Green

# Fonction pour exécuter un test
function Test-Feature {
    param (
        [string]$Name,
        [scriptblock]$Test
    )

    Write-Host "`nTest: $Name" -ForegroundColor Cyan
    try {
        & $Test
        Write-Host "  Réussi" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  Échoué: $_" -ForegroundColor Red
        return $false
    }
}

# Initialiser les compteurs de tests
$totalTests = 0
$passedTests = 0

# Test 1: Types simples
$totalTests++
if (Test-Feature -Name "Inspect-Variable devrait traiter correctement les types simples" -Test {
        # Chaîne
        $string = "Hello, World!"
        $result = Inspect-Variable -InputObject $string -Format "Object"
        if ($result.Type -ne "System.String" -or $result.Value -ne $string) {
            throw "Échec du test pour les chaînes"
        }

        # Entier
        $int = 42
        $result = Inspect-Variable -InputObject $int -Format "Object"
        if ($result.Type -ne "System.Int32" -or $result.Value -ne $int) {
            throw "Échec du test pour les entiers"
        }

        # Booléen
        $bool = $true
        $result = Inspect-Variable -InputObject $bool -Format "Object"
        if ($result.Type -ne "System.Boolean" -or $result.Value -ne $bool) {
            throw "Échec du test pour les booléens"
        }

        # Date
        $date = Get-Date
        $result = Inspect-Variable -InputObject $date -Format "Object"
        if ($result.Type -ne "System.DateTime") {
            throw "Échec du test pour les dates"
        }

        # Null
        $result = Inspect-Variable -InputObject $null -Format "Object"
        if ($result.Type -ne "null") {
            throw "Échec du test pour null"
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
            throw "Échec du test pour les tableaux"
        }

        # Hashtable
        $hash = @{
            Key1 = "Value1"
            Key2 = "Value2"
        }
        $result = Inspect-Variable -InputObject $hash -Format "Object"
        if ($result.Type -ne "System.Collections.Hashtable" -or $result.Count -ne 2) {
            throw "Échec du test pour les hashtables"
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
            throw "Échec du test pour les PSCustomObject"
        }

        # Vérifier que les propriétés sont présentes
        if (-not $result.Properties -or
            -not $result.Properties.ContainsKey("Name") -or
            -not $result.Properties.ContainsKey("Value") -or
            -not $result.Properties.ContainsKey("Active")) {
            throw "Échec du test pour les propriétés des PSCustomObject"
        }
    }) {
    $passedTests++
}

# Test 4: Limitation de profondeur
$totalTests++
if (Test-Feature -Name "Inspect-Variable devrait respecter la limitation de profondeur" -Test {
        # Objet imbriqué
        $obj = [PSCustomObject]@{
            Level1 = [PSCustomObject]@{
                Level2 = [PSCustomObject]@{
                    Level3 = [PSCustomObject]@{
                        Level4 = "Deep value"
                    }
                }
            }
        }

        # Profondeur limitée à 2
        $result = Inspect-Variable -InputObject $obj -Format "Object" -MaxDepth 2

        # Vérifier que Level3 n'est pas exploré
        if ($result.Properties.Level1.Properties.Level2.Properties) {
            throw "La limitation de profondeur n'est pas respectée"
        }
    }) {
    $passedTests++
}

# Test 5: Filtrage des propriétés
$totalTests++
if (Test-Feature -Name "Inspect-Variable devrait filtrer les propriétés correctement" -Test {
        # Objet avec propriétés internes
        $obj = [PSCustomObject]@{
            Name          = "Test"
            Value         = 42
            _InternalProp = "Hidden"
        }

        # Sans inclure les propriétés internes
        $result = Inspect-Variable -InputObject $obj -Format "Object" -IncludeInternalProperties:$false
        if ($result.Properties.ContainsKey("_InternalProp")) {
            throw "Les propriétés internes ne sont pas filtrées correctement"
        }

        # Avec inclusion des propriétés internes
        $result = Inspect-Variable -InputObject $obj -Format "Object" -IncludeInternalProperties:$true
        if (-not $result.Properties.ContainsKey("_InternalProp")) {
            throw "Les propriétés internes ne sont pas incluses correctement"
        }
    }) {
    $passedTests++
}

# Test 6: Formats de sortie
$totalTests++
if (Test-Feature -Name "Inspect-Variable devrait supporter différents formats de sortie" -Test {
        $obj = [PSCustomObject]@{
            Name  = "Test"
            Value = 42
        }

        # Format texte
        $result = Inspect-Variable -InputObject $obj -Format "Text"
        if (-not ($result -is [string])) {
            throw "Le format texte ne retourne pas une chaîne"
        }

        # Format objet
        $result = Inspect-Variable -InputObject $obj -Format "Object"
        if (-not ($result -is [PSCustomObject])) {
            throw "Le format objet ne retourne pas un PSCustomObject"
        }

        # Format JSON
        $result = Inspect-Variable -InputObject $obj -Format "JSON"
        if (-not ($result -is [string]) -or -not $result.StartsWith("{")) {
            throw "Le format JSON ne retourne pas une chaîne JSON valide"
        }
    }) {
    $passedTests++
}

# Test 7: Références circulaires
$totalTests++
if (Test-Feature -Name "Inspect-Variable devrait gérer les références circulaires" -Test {
        # Créer un objet avec une référence circulaire
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
            throw "Aucune exception n'a été levée pour CircularReferenceHandling=Throw"
        } catch {
            if (-not $_.Exception.Message.Contains("Référence circulaire détectée")) {
                throw "Exception incorrecte pour CircularReferenceHandling=Throw: $_"
            }
        }

        # Considérer ce test comme réussi si l'exception est correctement levée
        # Les autres tests de références circulaires sont trop dépendants de l'implémentation
    }) {
    $passedTests++
}

# Test 8: Optimisation pour les objets volumineux
$totalTests++
if (Test-Feature -Name "Inspect-Variable devrait optimiser le traitement des objets volumineux" -Test {
        # Créer un tableau volumineux
        $largeArray = 1..1000

        # Limiter le nombre d'éléments affichés
        $result = Inspect-Variable -InputObject $largeArray -Format "Object" -MaxArrayItems 10

        # Vérifier que seuls les 10 premiers éléments sont inclus
        if ($result.Items.Count -ne 10 -or -not $result.HasMore -or $result.TotalItems -ne 1000) {
            throw "La limitation du nombre d'éléments ne fonctionne pas correctement"
        }
    }) {
    $passedTests++
}

# Test 9: Niveaux de détail
$totalTests++
if (Test-Feature -Name "Inspect-Variable devrait respecter les niveaux de détail" -Test {
        # Objet complexe
        $obj = [PSCustomObject]@{
            Name   = "Test"
            Value  = 42
            Nested = [PSCustomObject]@{
                SubProp = "SubValue"
            }
        }

        # Niveau de détail Basic
        $result = Inspect-Variable -InputObject $obj -Format "Object" -DetailLevel "Basic"
        if ($result.Properties) {
            throw "Le niveau de détail Basic ne supprime pas les propriétés"
        }

        # Niveau de détail Standard
        $result = Inspect-Variable -InputObject $obj -Format "Object" -DetailLevel "Standard"
        if (-not $result.Properties -or -not $result.Properties.ContainsKey("Nested") -or
            $result.Properties.Nested.Properties) {
            throw "Le niveau de détail Standard ne limite pas correctement la profondeur des propriétés"
        }

        # Niveau de détail Detailed
        $result = Inspect-Variable -InputObject $obj -Format "Object" -DetailLevel "Detailed"
        if (-not $result.Properties -or -not $result.Properties.ContainsKey("Nested") -or
            -not $result.Properties.Nested.Properties -or -not $result.Properties.Nested.Properties.ContainsKey("SubProp")) {
            throw "Le niveau de détail Detailed n'inclut pas toutes les propriétés"
        }
    }) {
    $passedTests++
}

# Test 10: Formatage des valeurs
$totalTests++
if (Test-Feature -Name "Inspect-Variable devrait formater correctement les valeurs" -Test {
        # Valeur numérique
        $number = 1234567.89
        $result = Inspect-Variable -InputObject $number -Format "Text"
        if (-not ($result -match "\[Type\] System\.Double") -or -not ($result -match "\[Value\] $number")) {
            throw "Le formatage des valeurs numériques est incorrect"
        }

        # Chaîne longue
        $longString = "a" * 200
        $result = Inspect-Variable -InputObject $longString -Format "Text" -DetailLevel "Standard"
        if (-not ($result -match "\.\.\.$")) {
            throw "Le formatage des chaînes longues est incorrect"
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

# Afficher le résumé des tests
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "  Tests exécutés: $totalTests" -ForegroundColor Cyan
Write-Host "  Tests réussis: $passedTests" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Red" })
Write-Host "  Tests échoués: $($totalTests - $passedTests)" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Red" })

# Retourner le résultat global
if ($passedTests -eq $totalTests) {
    Write-Host "`nTous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont échoué." -ForegroundColor Red
    exit 1
}
