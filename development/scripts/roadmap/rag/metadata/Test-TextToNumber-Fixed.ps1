# Test-TextToNumber-Fixed.ps1
# Script pour tester la conversion des nombres écrits en toutes lettres en valeurs numériques
# Version: 1.0
# Date: 2025-05-15

# Importer le script de conversion
. "$PSScriptRoot\Convert-TextToNumber.ps1"

# Fonction pour tester la conversion des nombres écrits en toutes lettres
function Test-TextToNumber {
    [CmdletBinding()]
    param()
    
    Write-Host "Test de conversion des nombres écrits en toutes lettres..." -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    
    # Tests en français
    $frenchTests = @(
        @{ Text = "zéro"; Expected = 0 },
        @{ Text = "un"; Expected = 1 },
        @{ Text = "deux"; Expected = 2 },
        @{ Text = "trois"; Expected = 3 },
        @{ Text = "quatre"; Expected = 4 },
        @{ Text = "cinq"; Expected = 5 },
        @{ Text = "six"; Expected = 6 },
        @{ Text = "sept"; Expected = 7 },
        @{ Text = "huit"; Expected = 8 },
        @{ Text = "neuf"; Expected = 9 },
        @{ Text = "dix"; Expected = 10 },
        @{ Text = "onze"; Expected = 11 },
        @{ Text = "douze"; Expected = 12 },
        @{ Text = "treize"; Expected = 13 },
        @{ Text = "quatorze"; Expected = 14 },
        @{ Text = "quinze"; Expected = 15 },
        @{ Text = "seize"; Expected = 16 },
        @{ Text = "dix-sept"; Expected = 17 },
        @{ Text = "dix-huit"; Expected = 18 },
        @{ Text = "dix-neuf"; Expected = 19 },
        @{ Text = "vingt"; Expected = 20 },
        @{ Text = "vingt et un"; Expected = 21 },
        @{ Text = "trente"; Expected = 30 },
        @{ Text = "quarante"; Expected = 40 },
        @{ Text = "cinquante"; Expected = 50 },
        @{ Text = "soixante"; Expected = 60 },
        @{ Text = "soixante-dix"; Expected = 70 },
        @{ Text = "quatre-vingt"; Expected = 80 },
        @{ Text = "quatre-vingt-dix"; Expected = 90 },
        @{ Text = "cent"; Expected = 100 },
        @{ Text = "cent un"; Expected = 101 },
        @{ Text = "deux cents"; Expected = 200 },
        @{ Text = "mille"; Expected = 1000 },
        @{ Text = "mille un"; Expected = 1001 },
        @{ Text = "deux mille"; Expected = 2000 },
        @{ Text = "un million"; Expected = 1000000 },
        @{ Text = "deux millions"; Expected = 2000000 },
        @{ Text = "un milliard"; Expected = 1000000000 },
        @{ Text = "deux milliards"; Expected = 2000000000 }
    )
    
    # Tests en anglais
    $englishTests = @(
        @{ Text = "zero"; Expected = 0 },
        @{ Text = "one"; Expected = 1 },
        @{ Text = "two"; Expected = 2 },
        @{ Text = "three"; Expected = 3 },
        @{ Text = "four"; Expected = 4 },
        @{ Text = "five"; Expected = 5 },
        @{ Text = "six"; Expected = 6 },
        @{ Text = "seven"; Expected = 7 },
        @{ Text = "eight"; Expected = 8 },
        @{ Text = "nine"; Expected = 9 },
        @{ Text = "ten"; Expected = 10 },
        @{ Text = "eleven"; Expected = 11 },
        @{ Text = "twelve"; Expected = 12 },
        @{ Text = "thirteen"; Expected = 13 },
        @{ Text = "fourteen"; Expected = 14 },
        @{ Text = "fifteen"; Expected = 15 },
        @{ Text = "sixteen"; Expected = 16 },
        @{ Text = "seventeen"; Expected = 17 },
        @{ Text = "eighteen"; Expected = 18 },
        @{ Text = "nineteen"; Expected = 19 },
        @{ Text = "twenty"; Expected = 20 },
        @{ Text = "twenty one"; Expected = 21 },
        @{ Text = "thirty"; Expected = 30 },
        @{ Text = "forty"; Expected = 40 },
        @{ Text = "fifty"; Expected = 50 },
        @{ Text = "sixty"; Expected = 60 },
        @{ Text = "seventy"; Expected = 70 },
        @{ Text = "eighty"; Expected = 80 },
        @{ Text = "ninety"; Expected = 90 },
        @{ Text = "one hundred"; Expected = 100 },
        @{ Text = "one hundred one"; Expected = 101 },
        @{ Text = "two hundred"; Expected = 200 },
        @{ Text = "one thousand"; Expected = 1000 },
        @{ Text = "one thousand one"; Expected = 1001 },
        @{ Text = "two thousand"; Expected = 2000 },
        @{ Text = "one million"; Expected = 1000000 },
        @{ Text = "two million"; Expected = 2000000 },
        @{ Text = "one billion"; Expected = 1000000000 },
        @{ Text = "two billion"; Expected = 2000000000 }
    )
    
    # Exécuter les tests en français
    Write-Host "`nTests en français:" -ForegroundColor Yellow
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
    
    # Exécuter les tests en anglais
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
    
    # Tests de détection dans des phrases
    Write-Host "`nTests de détection dans des phrases:" -ForegroundColor Yellow
    
    $phraseTests = @(
        @{
            Text = "Cette tâche prendra environ vingt-cinq jours à réaliser."
            Language = "French"
            ExpectedCount = 1
            ExpectedValue = 25
        },
        @{
            Text = "Le projet est estimé à deux cent cinquante heures de travail."
            Language = "French"
            ExpectedCount = 1
            ExpectedValue = 250
        },
        @{
            Text = "This task will take about twenty five days to complete."
            Language = "English"
            ExpectedCount = 1
            ExpectedValue = 25
        },
        @{
            Text = "The project is estimated at two hundred fifty hours of work."
            Language = "English"
            ExpectedCount = 1
            ExpectedValue = 250
        },
        @{
            Text = "La première tâche prendra vingt jours, la deuxième trente jours et la troisième quinze jours."
            Language = "French"
            ExpectedCount = 3
            ExpectedValues = @(20, 30, 15)
        },
        @{
            Text = "The first task will take twenty days, the second thirty days and the third fifteen days."
            Language = "English"
            ExpectedCount = 3
            ExpectedValues = @(20, 30, 15)
        }
    )
    
    $phraseSuccessCount = 0
    $phraseFailCount = 0
    
    foreach ($test in $phraseTests) {
        # Appeler la fonction Get-TextualNumbers
        $results = Get-TextualNumbers -Text $test.Text -Language $test.Language
        
        # Vérifier les résultats
        if ($results -ne $null -and $results.Count -gt 0) {
            if ($test.ExpectedCount -eq 1) {
                if ($results.Count -ge 1 -and $results[0].NumericValue -eq $test.ExpectedValue) {
                    Write-Host "[OK] Detection dans '$($test.Text)' => $($results[0].NumericValue)" -ForegroundColor Green
                    $phraseSuccessCount++
                } else {
                    Write-Host "[ERREUR] Detection dans '$($test.Text)' => $($results | ForEach-Object { $_.NumericValue }) (attendu: $($test.ExpectedValue))" -ForegroundColor Red
                    $phraseFailCount++
                }
            } else {
                $success = $true
                $foundValues = @()
                
                foreach ($expectedValue in $test.ExpectedValues) {
                    $found = $false
                    foreach ($result in $results) {
                        if ($result.NumericValue -eq $expectedValue) {
                            $found = $true
                            $foundValues += $expectedValue
                            break
                        }
                    }
                    
                    if (-not $found) {
                        $success = $false
                        break
                    }
                }
                
                if ($success -and $foundValues.Count -eq $test.ExpectedValues.Count) {
                    Write-Host "[OK] Detection multiple dans '$($test.Text)' => $($foundValues -join ', ')" -ForegroundColor Green
                    $phraseSuccessCount++
                } else {
                    Write-Host "[ERREUR] Detection multiple dans '$($test.Text)' => $($results | ForEach-Object { $_.NumericValue }) (attendu: $($test.ExpectedValues -join ', '))" -ForegroundColor Red
                    $phraseFailCount++
                }
            }
        } else {
            Write-Host "[ERREUR] Detection dans '$($test.Text)' => Aucun résultat (attendu: $($test.ExpectedCount))" -ForegroundColor Red
            $phraseFailCount++
        }
    }
    
    # Afficher les résultats
    Write-Host "`nRésumé des résultats:" -ForegroundColor Yellow
    Write-Host "- Tests en français: $frenchSuccessCount réussis, $frenchFailCount échoués" -ForegroundColor Yellow
    Write-Host "- Tests en anglais: $englishSuccessCount réussis, $englishFailCount échoués" -ForegroundColor Yellow
    Write-Host "- Tests de détection dans des phrases: $phraseSuccessCount réussis, $phraseFailCount échoués" -ForegroundColor Yellow
    
    $totalSuccess = $frenchSuccessCount + $englishSuccessCount + $phraseSuccessCount
    $totalFail = $frenchFailCount + $englishFailCount + $phraseFailCount
    $totalTests = $totalSuccess + $totalFail
    
    Write-Host "- Total: $totalSuccess/$totalTests réussis ($(($totalSuccess / $totalTests) * 100)%)" -ForegroundColor Yellow
    
    Write-Host "`nTest terminé." -ForegroundColor Cyan
}

# Exécuter les tests
Test-TextToNumber
