# Test-SimpleFunctions.ps1
# Script pour tester les fonctions simplifiees
# Version: 1.0
# Date: 2025-05-15

# Importer les scripts
. "$PSScriptRoot\Simple-TextToNumber.ps1"
. "$PSScriptRoot\Simple-ApproximateExpressions.ps1"

# Fonction pour tester la conversion des nombres ecrits en toutes lettres
function Test-SimpleTextToNumber {
    [CmdletBinding()]
    param()

    Write-Host "Test de conversion des nombres ecrits en toutes lettres..." -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan

    # Tests en francais
    $frenchTests = @(
        @{ Text = "zero"; Expected = 0 },
        @{ Text = "un"; Expected = 1 },
        @{ Text = "deux"; Expected = 2 },
        @{ Text = "vingt"; Expected = 20 },
        @{ Text = "vingt et un"; Expected = 21 },
        @{ Text = "cent"; Expected = 100 }
    )

    # Tests en anglais
    $englishTests = @(
        @{ Text = "zero"; Expected = 0 },
        @{ Text = "one"; Expected = 1 },
        @{ Text = "two"; Expected = 2 },
        @{ Text = "twenty"; Expected = 20 },
        @{ Text = "twenty one"; Expected = 21 },
        @{ Text = "hundred"; Expected = 100 }
    )

    # Executer les tests en francais
    Write-Host "`nTests en francais:" -ForegroundColor Yellow
    $frenchSuccessCount = 0
    $frenchFailCount = 0

    foreach ($test in $frenchTests) {
        $result = ConvertFrom-TextToNumber -Text $test.Text -Language "French"

        if ($result -eq $test.Expected) {
            Write-Host "[OK] '$($test.Text)' => $result" -ForegroundColor Green
            $frenchSuccessCount++
        } else {
            Write-Host "[ERREUR] '$($test.Text)' => $result (attendu: $($test.Expected))" -ForegroundColor Red
            $frenchFailCount++
        }
    }

    # Executer les tests en anglais
    Write-Host "`nTests en anglais:" -ForegroundColor Yellow
    $englishSuccessCount = 0
    $englishFailCount = 0

    foreach ($test in $englishTests) {
        $result = ConvertFrom-TextToNumber -Text $test.Text -Language "English"

        if ($result -eq $test.Expected) {
            Write-Host "[OK] '$($test.Text)' => $result" -ForegroundColor Green
            $englishSuccessCount++
        } else {
            Write-Host "[ERREUR] '$($test.Text)' => $result (attendu: $($test.Expected))" -ForegroundColor Red
            $englishFailCount++
        }
    }

    # Tests de detection dans des phrases
    Write-Host "`nTests de detection dans des phrases:" -ForegroundColor Yellow

    $phraseTests = @(
        @{
            Text          = "La premiere tache prendra vingt jours."
            Language      = "French"
            ExpectedCount = 1
            ExpectedValue = 20
        },
        @{
            Text          = "The first task will take twenty days."
            Language      = "English"
            ExpectedCount = 1
            ExpectedValue = 20
        }
    )

    # Afficher le texte normalisé pour le débogage
    Write-Host "`nDébogage des phrases:" -ForegroundColor Cyan
    foreach ($test in $phraseTests) {
        $normalizedText = $test.Text.ToLower() -replace '-', ' ' -replace '\s+', ' '
        Write-Host "Texte original: '$($test.Text)'" -ForegroundColor Cyan
        Write-Host "Texte normalisé: '$normalizedText'" -ForegroundColor Cyan

        # Vérifier si les mots du dictionnaire sont présents dans le texte
        $numberDict = if ($test.Language -eq "French") { $frenchNumbers } else { $englishNumbers }
        foreach ($numberWord in $numberDict.Keys) {
            if ($normalizedText -match "\b$numberWord\b") {
                Write-Host "Mot trouvé: '$numberWord' => $($numberDict[$numberWord])" -ForegroundColor Green
            }
        }
        Write-Host ""
    }

    $phraseSuccessCount = 0
    $phraseFailCount = 0

    foreach ($test in $phraseTests) {
        # Appeler la fonction Get-TextualNumbers
        $results = Get-TextualNumbers -Text $test.Text -Language $test.Language

        # Verifier les resultats
        if ($null -ne $results -and $results.Count -gt 0) {
            if ($results[0].NumericValue -eq $test.ExpectedValue) {
                Write-Host "[OK] Detection dans '$($test.Text)' => $($results[0].NumericValue)" -ForegroundColor Green
                $phraseSuccessCount++
            } else {
                Write-Host "[ERREUR] Detection dans '$($test.Text)' => $($results | ForEach-Object { $_.NumericValue }) (attendu: $($test.ExpectedValue))" -ForegroundColor Red
                $phraseFailCount++
            }
        } else {
            Write-Host "[ERREUR] Detection dans '$($test.Text)' => Aucun resultat (attendu: $($test.ExpectedCount))" -ForegroundColor Red
            $phraseFailCount++
        }
    }

    # Afficher les resultats
    Write-Host "`nResume des resultats:" -ForegroundColor Yellow
    Write-Host "- Tests en francais: $frenchSuccessCount reussis, $frenchFailCount echoues" -ForegroundColor Yellow
    Write-Host "- Tests en anglais: $englishSuccessCount reussis, $englishFailCount echoues" -ForegroundColor Yellow
    Write-Host "- Tests de detection dans des phrases: $phraseSuccessCount reussis, $phraseFailCount echoues" -ForegroundColor Yellow

    $totalSuccess = $frenchSuccessCount + $englishSuccessCount + $phraseSuccessCount
    $totalFail = $frenchFailCount + $englishFailCount + $phraseFailCount
    $totalTests = $totalSuccess + $totalFail

    Write-Host "- Total: $totalSuccess/$totalTests reussis ($(($totalSuccess / $totalTests) * 100)%)" -ForegroundColor Yellow

    Write-Host "`nTest termine." -ForegroundColor Cyan
}

# Fonction pour tester l'analyse des expressions numeriques approximatives
function Test-SimpleApproximateExpressions {
    [CmdletBinding()]
    param()

    Write-Host "Test d'analyse des expressions numeriques approximatives..." -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan

    # Tests en francais
    $frenchTests = @(
        @{
            Text           = "Cette tache prendra environ 10 jours a realiser.";
            ExpectedCount  = 1;
            ExpectedType   = "MarkerNumber";
            ExpectedValue  = 10;
            ExpectedMarker = "environ"
        },
        @{
            Text            = "Le projet necessite environ 10 jours et coutera approximativement 5000 euros.";
            ExpectedCount   = 2;
            ExpectedTypes   = @("MarkerNumber", "MarkerNumber");
            ExpectedValues  = @(10, 5000);
            ExpectedMarkers = @("environ", "approximativement")
        }
    )

    # Tests en anglais
    $englishTests = @(
        @{
            Text           = "This task will take about 10 days to complete.";
            ExpectedCount  = 1;
            ExpectedType   = "MarkerNumber";
            ExpectedValue  = 10;
            ExpectedMarker = "about"
        },
        @{
            Text            = "The project requires about 10 days and will cost approximately 5000 dollars.";
            ExpectedCount   = 2;
            ExpectedTypes   = @("MarkerNumber", "MarkerNumber");
            ExpectedValues  = @(10, 5000);
            ExpectedMarkers = @("about", "approximately")
        }
    )

    # Executer les tests en francais
    Write-Host "`nTests en francais:" -ForegroundColor Yellow
    $frenchSuccessCount = 0
    $frenchFailCount = 0

    foreach ($test in $frenchTests) {
        Write-Host "`nTexte: '$($test.Text)'" -ForegroundColor Magenta

        $results = Get-ApproximateExpressions -Text $test.Text -Language "French"

        Write-Host "Nombre d'expressions trouvees: $($results.Count)" -ForegroundColor Cyan

        if ($results.Count -eq $test.ExpectedCount) {
            $success = $true

            if ($test.ExpectedCount -eq 1) {
                # Verifier le type, la valeur et le marqueur
                if ($results[0].Info.Type -eq $test.ExpectedType -and
                    [math]::Abs($results[0].Info.Value - $test.ExpectedValue) -lt 0.01 -and
                    $results[0].Info.Marker -eq $test.ExpectedMarker) {

                    Write-Host "[OK] Expression trouvee: '$($results[0].Expression)'" -ForegroundColor Green
                    Write-Host "  Type: $($results[0].Info.Type)" -ForegroundColor Green
                    Write-Host "  Valeur: $($results[0].Info.Value)" -ForegroundColor Green
                    Write-Host "  Marqueur: $($results[0].Info.Marker)" -ForegroundColor Green
                } else {
                    $success = $false
                    Write-Host "[ERREUR] Expression trouvee: '$($results[0].Expression)'" -ForegroundColor Red
                    Write-Host "  Type: $($results[0].Info.Type) (attendu: $($test.ExpectedType))" -ForegroundColor Red
                    Write-Host "  Valeur: $($results[0].Info.Value) (attendu: $($test.ExpectedValue))" -ForegroundColor Red
                    Write-Host "  Marqueur: $($results[0].Info.Marker) (attendu: $($test.ExpectedMarker))" -ForegroundColor Red
                }
            } else {
                # Verifier plusieurs expressions
                for ($i = 0; $i -lt $test.ExpectedCount; $i++) {
                    if ($results[$i].Info.Type -eq $test.ExpectedTypes[$i] -and
                        [math]::Abs($results[$i].Info.Value - $test.ExpectedValues[$i]) -lt 0.01 -and
                        $results[$i].Info.Marker -eq $test.ExpectedMarkers[$i]) {

                        Write-Host "[OK] Expression $($i+1) trouvee: '$($results[$i].Expression)'" -ForegroundColor Green
                        Write-Host "  Type: $($results[$i].Info.Type)" -ForegroundColor Green
                        Write-Host "  Valeur: $($results[$i].Info.Value)" -ForegroundColor Green
                        Write-Host "  Marqueur: $($results[$i].Info.Marker)" -ForegroundColor Green
                    } else {
                        $success = $false
                        Write-Host "[ERREUR] Expression $($i+1) trouvee: '$($results[$i].Expression)'" -ForegroundColor Red
                        Write-Host "  Type: $($results[$i].Info.Type) (attendu: $($test.ExpectedTypes[$i]))" -ForegroundColor Red
                        Write-Host "  Valeur: $($results[$i].Info.Value) (attendu: $($test.ExpectedValues[$i]))" -ForegroundColor Red
                        Write-Host "  Marqueur: $($results[$i].Info.Marker) (attendu: $($test.ExpectedMarkers[$i]))" -ForegroundColor Red
                    }
                }
            }

            if ($success) {
                $frenchSuccessCount++
            } else {
                $frenchFailCount++
            }
        } else {
            Write-Host "[ERREUR] Nombre d'expressions trouvees: $($results.Count) (attendu: $($test.ExpectedCount))" -ForegroundColor Red
            $frenchFailCount++
        }
    }

    # Executer les tests en anglais
    Write-Host "`nTests en anglais:" -ForegroundColor Yellow
    $englishSuccessCount = 0
    $englishFailCount = 0

    foreach ($test in $englishTests) {
        Write-Host "`nTexte: '$($test.Text)'" -ForegroundColor Magenta

        $results = Get-ApproximateExpressions -Text $test.Text -Language "English"

        Write-Host "Nombre d'expressions trouvees: $($results.Count)" -ForegroundColor Cyan

        if ($results.Count -eq $test.ExpectedCount) {
            $success = $true

            if ($test.ExpectedCount -eq 1) {
                # Verifier le type, la valeur et le marqueur
                if ($results[0].Info.Type -eq $test.ExpectedType -and
                    [math]::Abs($results[0].Info.Value - $test.ExpectedValue) -lt 0.01 -and
                    $results[0].Info.Marker -eq $test.ExpectedMarker) {

                    Write-Host "[OK] Expression trouvee: '$($results[0].Expression)'" -ForegroundColor Green
                    Write-Host "  Type: $($results[0].Info.Type)" -ForegroundColor Green
                    Write-Host "  Valeur: $($results[0].Info.Value)" -ForegroundColor Green
                    Write-Host "  Marqueur: $($results[0].Info.Marker)" -ForegroundColor Green
                } else {
                    $success = $false
                    Write-Host "[ERREUR] Expression trouvee: '$($results[0].Expression)'" -ForegroundColor Red
                    Write-Host "  Type: $($results[0].Info.Type) (attendu: $($test.ExpectedType))" -ForegroundColor Red
                    Write-Host "  Valeur: $($results[0].Info.Value) (attendu: $($test.ExpectedValue))" -ForegroundColor Red
                    Write-Host "  Marqueur: $($results[0].Info.Marker) (attendu: $($test.ExpectedMarker))" -ForegroundColor Red
                }
            } else {
                # Verifier plusieurs expressions
                for ($i = 0; $i -lt $test.ExpectedCount; $i++) {
                    if ($results[$i].Info.Type -eq $test.ExpectedTypes[$i] -and
                        [math]::Abs($results[$i].Info.Value - $test.ExpectedValues[$i]) -lt 0.01 -and
                        $results[$i].Info.Marker -eq $test.ExpectedMarkers[$i]) {

                        Write-Host "[OK] Expression $($i+1) trouvee: '$($results[$i].Expression)'" -ForegroundColor Green
                        Write-Host "  Type: $($results[$i].Info.Type)" -ForegroundColor Green
                        Write-Host "  Valeur: $($results[$i].Info.Value)" -ForegroundColor Green
                        Write-Host "  Marqueur: $($results[$i].Info.Marker)" -ForegroundColor Green
                    } else {
                        $success = $false
                        Write-Host "[ERREUR] Expression $($i+1) trouvee: '$($results[$i].Expression)'" -ForegroundColor Red
                        Write-Host "  Type: $($results[$i].Info.Type) (attendu: $($test.ExpectedTypes[$i]))" -ForegroundColor Red
                        Write-Host "  Valeur: $($results[$i].Info.Value) (attendu: $($test.ExpectedValues[$i]))" -ForegroundColor Red
                        Write-Host "  Marqueur: $($results[$i].Info.Marker) (attendu: $($test.ExpectedMarkers[$i]))" -ForegroundColor Red
                    }
                }
            }

            if ($success) {
                $englishSuccessCount++
            } else {
                $englishFailCount++
            }
        } else {
            Write-Host "[ERREUR] Nombre d'expressions trouvees: $($results.Count) (attendu: $($test.ExpectedCount))" -ForegroundColor Red
            $englishFailCount++
        }
    }

    # Afficher les resultats
    Write-Host "`nResume des resultats:" -ForegroundColor Yellow
    Write-Host "- Tests en francais: $frenchSuccessCount reussis, $frenchFailCount echoues" -ForegroundColor Yellow
    Write-Host "- Tests en anglais: $englishSuccessCount reussis, $englishFailCount echoues" -ForegroundColor Yellow

    $totalSuccess = $frenchSuccessCount + $englishSuccessCount
    $totalFail = $frenchFailCount + $englishFailCount
    $totalTests = $totalSuccess + $totalFail

    Write-Host "- Total: $totalSuccess/$totalTests reussis ($(($totalSuccess / $totalTests) * 100)%)" -ForegroundColor Yellow

    Write-Host "`nTest termine." -ForegroundColor Cyan
}

# Test direct des dictionnaires
Write-Host "Test direct des dictionnaires..." -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Vérifier si les mots "vingt" et "twenty" sont dans les dictionnaires
Write-Host "Vérification des dictionnaires:" -ForegroundColor Yellow
Write-Host "  - 'vingt' est dans frenchNumbers: $($frenchNumbers.ContainsKey('vingt'))" -ForegroundColor Yellow
Write-Host "  - 'twenty' est dans englishNumbers: $($englishNumbers.ContainsKey('twenty'))" -ForegroundColor Yellow

# Test simple de normalisation de texte
$text1 = "La premiere tache prendra vingt jours."
$text2 = "The first task will take twenty days."

Write-Host "`nTest de normalisation:" -ForegroundColor Yellow
$normalizedText1 = $text1.ToLower() -replace '-', ' ' -replace '\s+', ' ' -replace '[.,;:!?]', ''
$normalizedText2 = $text2.ToLower() -replace '-', ' ' -replace '\s+', ' ' -replace '[.,;:!?]', ''

Write-Host "  - Texte 1 normalisé: '$normalizedText1'" -ForegroundColor Yellow
Write-Host "  - Texte 2 normalisé: '$normalizedText2'" -ForegroundColor Yellow

# Test de recherche directe
Write-Host "`nTest de recherche directe:" -ForegroundColor Yellow
$containsVingt = $normalizedText1.Contains("vingt")
$containsTwenty = $normalizedText2.Contains("twenty")

Write-Host "  - 'vingt' est dans le texte 1: $containsVingt" -ForegroundColor Yellow
Write-Host "  - 'twenty' est dans le texte 2: $containsTwenty" -ForegroundColor Yellow

# Test de split
Write-Host "`nTest de split:" -ForegroundColor Yellow
$words1 = $normalizedText1 -split '\s+'
$words2 = $normalizedText2 -split '\s+'

Write-Host "  - Mots du texte 1: $($words1 -join ', ')" -ForegroundColor Yellow
Write-Host "  - Mots du texte 2: $($words2 -join ', ')" -ForegroundColor Yellow

# Vérification manuelle
Write-Host "`nVérification manuelle:" -ForegroundColor Yellow
$foundVingt = $false
$foundTwenty = $false

foreach ($word in $words1) {
    if ($word -eq "vingt") {
        $foundVingt = $true
        break
    }
}

foreach ($word in $words2) {
    if ($word -eq "twenty") {
        $foundTwenty = $true
        break
    }
}

Write-Host "  - 'vingt' trouvé dans les mots du texte 1: $foundVingt" -ForegroundColor Yellow
Write-Host "  - 'twenty' trouvé dans les mots du texte 2: $foundTwenty" -ForegroundColor Yellow

# Test direct avec les phrases complexes
$text3 = "Le projet prendra environ vingt-cinq jours et nécessitera trente personnes."
$text4 = "The project will take about twenty-five days and will require thirty people."

Write-Host "`nTest avec des phrases complexes:" -ForegroundColor Yellow
Write-Host "  - Texte 3: $text3" -ForegroundColor Yellow
Write-Host "  - Texte 4: $text4" -ForegroundColor Yellow

Write-Host "`nTest terminé." -ForegroundColor Cyan
