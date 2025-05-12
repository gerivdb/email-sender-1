# Test-AllFunctions.ps1
# Script pour tester toutes les fonctions de conversion et d'analyse
# Version: 1.0
# Date: 2025-05-15

# Importer les scripts
. "$PSScriptRoot\Convert-TextToNumber-Fixed.ps1"
. "$PSScriptRoot\Analyze-ApproximateExpressions-Fixed.ps1"

# Fonction pour tester la conversion des nombres ecrits en toutes lettres
function Test-TextToNumber {
    [CmdletBinding()]
    param()
    
    Write-Host "Test de conversion des nombres ecrits en toutes lettres..." -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    
    # Tests en francais
    $frenchTests = @(
        @{ Text = "zero"; Expected = 0 },
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
            Text = "Cette tache prendra environ vingt-cinq jours a realiser."
            Language = "French"
            ExpectedCount = 1
            ExpectedValue = 25
        },
        @{
            Text = "Le projet est estime a deux cent cinquante heures de travail."
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
            Text = "La premiere tache prendra vingt jours, la deuxieme trente jours et la troisieme quinze jours."
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
        
        # Verifier les resultats
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
function Test-ApproximateExpressions {
    [CmdletBinding()]
    param()
    
    Write-Host "Test d'analyse des expressions numeriques approximatives..." -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    
    # Tests en francais
    $frenchTests = @(
        @{ 
            Text = "Cette tache prendra environ 10 jours a realiser."; 
            ExpectedCount = 1;
            ExpectedType = "MarkerNumber";
            ExpectedValue = 10;
            ExpectedMarker = "environ"
        },
        @{ 
            Text = "Le projet est estime a approximativement 250 heures de travail."; 
            ExpectedCount = 1;
            ExpectedType = "MarkerNumber";
            ExpectedValue = 250;
            ExpectedMarker = "approximativement"
        },
        @{ 
            Text = "Le cout sera de 1000 euros environ."; 
            ExpectedCount = 1;
            ExpectedType = "NumberMarker";
            ExpectedValue = 1000;
            ExpectedMarker = "environ"
        },
        @{ 
            Text = "Le delai est de 15 jours plus ou moins 2 jours."; 
            ExpectedCount = 1;
            ExpectedType = "ExplicitPrecision";
            ExpectedValue = 15;
            ExpectedMarker = "plus ou moins"
        },
        @{ 
            Text = "Le budget est entre 5000 et 6000 euros."; 
            ExpectedCount = 1;
            ExpectedType = "Interval";
            ExpectedValue = 5500;
            ExpectedMarker = "entre"
        },
        @{ 
            Text = "La duree varie de 3 a 5 semaines selon la disponibilite."; 
            ExpectedCount = 1;
            ExpectedType = "Interval";
            ExpectedValue = 4;
            ExpectedMarker = "de"
        },
        @{ 
            Text = "Le projet necessite environ 10 jours et coutera approximativement 5000 euros."; 
            ExpectedCount = 2;
            ExpectedTypes = @("MarkerNumber", "MarkerNumber");
            ExpectedValues = @(10, 5000);
            ExpectedMarkers = @("environ", "approximativement")
        }
    )
    
    # Tests en anglais
    $englishTests = @(
        @{ 
            Text = "This task will take about 10 days to complete."; 
            ExpectedCount = 1;
            ExpectedType = "MarkerNumber";
            ExpectedValue = 10;
            ExpectedMarker = "about"
        },
        @{ 
            Text = "The project is estimated at approximately 250 hours of work."; 
            ExpectedCount = 1;
            ExpectedType = "MarkerNumber";
            ExpectedValue = 250;
            ExpectedMarker = "approximately"
        },
        @{ 
            Text = "The cost will be 1000 dollars approximately."; 
            ExpectedCount = 1;
            ExpectedType = "NumberMarker";
            ExpectedValue = 1000;
            ExpectedMarker = "approximately"
        },
        @{ 
            Text = "The deadline is 15 days plus or minus 2 days."; 
            ExpectedCount = 1;
            ExpectedType = "ExplicitPrecision";
            ExpectedValue = 15;
            ExpectedMarker = "plus or minus"
        },
        @{ 
            Text = "The budget is between 5000 and 6000 dollars."; 
            ExpectedCount = 1;
            ExpectedType = "Interval";
            ExpectedValue = 5500;
            ExpectedMarker = "between"
        },
        @{ 
            Text = "The duration varies from 3 to 5 weeks depending on availability."; 
            ExpectedCount = 1;
            ExpectedType = "Interval";
            ExpectedValue = 4;
            ExpectedMarker = "from"
        },
        @{ 
            Text = "The project requires about 10 days and will cost approximately 5000 dollars."; 
            ExpectedCount = 2;
            ExpectedTypes = @("MarkerNumber", "MarkerNumber");
            ExpectedValues = @(10, 5000);
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
                    Write-Host "  Borne inferieure: $($results[0].Info.LowerBound)" -ForegroundColor Green
                    Write-Host "  Borne superieure: $($results[0].Info.UpperBound)" -ForegroundColor Green
                    
                    # Afficher les differents formats normalises
                    Write-Host "  Format standard: $(Get-NormalizedApproximateExpression -ApproximationInfo $results[0] -Format 'Standard')" -ForegroundColor Green
                    Write-Host "  Format plage: $(Get-NormalizedApproximateExpression -ApproximationInfo $results[0] -Format 'Range')" -ForegroundColor Green
                    Write-Host "  Format pourcentage: $(Get-NormalizedApproximateExpression -ApproximationInfo $results[0] -Format 'Percentage')" -ForegroundColor Green
                    Write-Host "  Format plus-moins: $(Get-NormalizedApproximateExpression -ApproximationInfo $results[0] -Format 'PlusMinus')" -ForegroundColor Green
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
                    Write-Host "  Borne inferieure: $($results[0].Info.LowerBound)" -ForegroundColor Green
                    Write-Host "  Borne superieure: $($results[0].Info.UpperBound)" -ForegroundColor Green
                    
                    # Afficher les differents formats normalises
                    Write-Host "  Format standard: $(Get-NormalizedApproximateExpression -ApproximationInfo $results[0] -Format 'Standard')" -ForegroundColor Green
                    Write-Host "  Format plage: $(Get-NormalizedApproximateExpression -ApproximationInfo $results[0] -Format 'Range')" -ForegroundColor Green
                    Write-Host "  Format pourcentage: $(Get-NormalizedApproximateExpression -ApproximationInfo $results[0] -Format 'Percentage')" -ForegroundColor Green
                    Write-Host "  Format plus-moins: $(Get-NormalizedApproximateExpression -ApproximationInfo $results[0] -Format 'PlusMinus')" -ForegroundColor Green
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

# Executer les tests
Write-Host "Tests des fonctions de conversion et d'analyse..." -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

Write-Host "`n1. Test de conversion des nombres ecrits en toutes lettres" -ForegroundColor Magenta
Test-TextToNumber

Write-Host "`n2. Test d'analyse des expressions numeriques approximatives" -ForegroundColor Magenta
Test-ApproximateExpressions

Write-Host "`nTous les tests sont termines." -ForegroundColor Cyan
