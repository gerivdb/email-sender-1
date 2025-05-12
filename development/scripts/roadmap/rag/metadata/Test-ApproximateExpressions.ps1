# Test-ApproximateExpressions.ps1
# Script pour tester l'analyse des expressions numériques approximatives
# Version: 1.0
# Date: 2025-05-15

# Importer le script d'analyse
. "$PSScriptRoot\Analyze-ApproximateExpressions.ps1"

# Fonction pour tester l'analyse des expressions numériques approximatives
function Test-ApproximateExpressions {
    [CmdletBinding()]
    param()
    
    Write-Host "Test d'analyse des expressions numériques approximatives..." -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    
    # Tests en français
    $frenchTests = @(
        @{ 
            Text = "Cette tâche prendra environ 10 jours à réaliser."; 
            ExpectedCount = 1;
            ExpectedType = "MarkerNumber";
            ExpectedValue = 10;
            ExpectedMarker = "environ"
        },
        @{ 
            Text = "Le projet est estimé à approximativement 250 heures de travail."; 
            ExpectedCount = 1;
            ExpectedType = "MarkerNumber";
            ExpectedValue = 250;
            ExpectedMarker = "approximativement"
        },
        @{ 
            Text = "Le coût sera de 1000 euros environ."; 
            ExpectedCount = 1;
            ExpectedType = "NumberMarker";
            ExpectedValue = 1000;
            ExpectedMarker = "environ"
        },
        @{ 
            Text = "Le délai est de 15 jours plus ou moins 2 jours."; 
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
            Text = "La durée varie de 3 à 5 semaines selon la disponibilité."; 
            ExpectedCount = 1;
            ExpectedType = "Interval";
            ExpectedValue = 4;
            ExpectedMarker = "de"
        },
        @{ 
            Text = "Le projet nécessite environ 10 jours et coûtera approximativement 5000 euros."; 
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
    
    # Exécuter les tests en français
    Write-Host "`nTests en français:" -ForegroundColor Yellow
    $frenchSuccessCount = 0
    $frenchFailCount = 0
    
    foreach ($test in $frenchTests) {
        Write-Host "`nTexte: '$($test.Text)'" -ForegroundColor Magenta
        
        $results = Get-ApproximateExpressions -Text $test.Text -Language "French"
        
        Write-Host "Nombre d'expressions trouvées: $($results.Count)" -ForegroundColor Cyan
        
        if ($results.Count -eq $test.ExpectedCount) {
            $success = $true
            
            if ($test.ExpectedCount -eq 1) {
                # Vérifier le type, la valeur et le marqueur
                if ($results[0].Info.Type -eq $test.ExpectedType -and 
                    [math]::Abs($results[0].Info.Value - $test.ExpectedValue) -lt 0.01 -and 
                    $results[0].Info.Marker -eq $test.ExpectedMarker) {
                    
                    Write-Host "[OK] Expression trouvée: '$($results[0].Expression)'" -ForegroundColor Green
                    Write-Host "  Type: $($results[0].Info.Type)" -ForegroundColor Green
                    Write-Host "  Valeur: $($results[0].Info.Value)" -ForegroundColor Green
                    Write-Host "  Marqueur: $($results[0].Info.Marker)" -ForegroundColor Green
                    Write-Host "  Borne inférieure: $($results[0].Info.LowerBound)" -ForegroundColor Green
                    Write-Host "  Borne supérieure: $($results[0].Info.UpperBound)" -ForegroundColor Green
                    
                    # Afficher les différents formats normalisés
                    Write-Host "  Format standard: $(Get-NormalizedApproximateExpression -ApproximationInfo $results[0] -Format 'Standard')" -ForegroundColor Green
                    Write-Host "  Format plage: $(Get-NormalizedApproximateExpression -ApproximationInfo $results[0] -Format 'Range')" -ForegroundColor Green
                    Write-Host "  Format pourcentage: $(Get-NormalizedApproximateExpression -ApproximationInfo $results[0] -Format 'Percentage')" -ForegroundColor Green
                    Write-Host "  Format plus-moins: $(Get-NormalizedApproximateExpression -ApproximationInfo $results[0] -Format 'PlusMinus')" -ForegroundColor Green
                } else {
                    $success = $false
                    Write-Host "[ERREUR] Expression trouvée: '$($results[0].Expression)'" -ForegroundColor Red
                    Write-Host "  Type: $($results[0].Info.Type) (attendu: $($test.ExpectedType))" -ForegroundColor Red
                    Write-Host "  Valeur: $($results[0].Info.Value) (attendu: $($test.ExpectedValue))" -ForegroundColor Red
                    Write-Host "  Marqueur: $($results[0].Info.Marker) (attendu: $($test.ExpectedMarker))" -ForegroundColor Red
                }
            } else {
                # Vérifier plusieurs expressions
                for ($i = 0; $i -lt $test.ExpectedCount; $i++) {
                    if ($results[$i].Info.Type -eq $test.ExpectedTypes[$i] -and 
                        [math]::Abs($results[$i].Info.Value - $test.ExpectedValues[$i]) -lt 0.01 -and 
                        $results[$i].Info.Marker -eq $test.ExpectedMarkers[$i]) {
                        
                        Write-Host "[OK] Expression $($i+1) trouvée: '$($results[$i].Expression)'" -ForegroundColor Green
                        Write-Host "  Type: $($results[$i].Info.Type)" -ForegroundColor Green
                        Write-Host "  Valeur: $($results[$i].Info.Value)" -ForegroundColor Green
                        Write-Host "  Marqueur: $($results[$i].Info.Marker)" -ForegroundColor Green
                    } else {
                        $success = $false
                        Write-Host "[ERREUR] Expression $($i+1) trouvée: '$($results[$i].Expression)'" -ForegroundColor Red
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
            Write-Host "[ERREUR] Nombre d'expressions trouvées: $($results.Count) (attendu: $($test.ExpectedCount))" -ForegroundColor Red
            $frenchFailCount++
        }
    }
    
    # Exécuter les tests en anglais
    Write-Host "`nTests en anglais:" -ForegroundColor Yellow
    $englishSuccessCount = 0
    $englishFailCount = 0
    
    foreach ($test in $englishTests) {
        Write-Host "`nTexte: '$($test.Text)'" -ForegroundColor Magenta
        
        $results = Get-ApproximateExpressions -Text $test.Text -Language "English"
        
        Write-Host "Nombre d'expressions trouvées: $($results.Count)" -ForegroundColor Cyan
        
        if ($results.Count -eq $test.ExpectedCount) {
            $success = $true
            
            if ($test.ExpectedCount -eq 1) {
                # Vérifier le type, la valeur et le marqueur
                if ($results[0].Info.Type -eq $test.ExpectedType -and 
                    [math]::Abs($results[0].Info.Value - $test.ExpectedValue) -lt 0.01 -and 
                    $results[0].Info.Marker -eq $test.ExpectedMarker) {
                    
                    Write-Host "[OK] Expression trouvée: '$($results[0].Expression)'" -ForegroundColor Green
                    Write-Host "  Type: $($results[0].Info.Type)" -ForegroundColor Green
                    Write-Host "  Valeur: $($results[0].Info.Value)" -ForegroundColor Green
                    Write-Host "  Marqueur: $($results[0].Info.Marker)" -ForegroundColor Green
                    Write-Host "  Borne inférieure: $($results[0].Info.LowerBound)" -ForegroundColor Green
                    Write-Host "  Borne supérieure: $($results[0].Info.UpperBound)" -ForegroundColor Green
                    
                    # Afficher les différents formats normalisés
                    Write-Host "  Format standard: $(Get-NormalizedApproximateExpression -ApproximationInfo $results[0] -Format 'Standard')" -ForegroundColor Green
                    Write-Host "  Format plage: $(Get-NormalizedApproximateExpression -ApproximationInfo $results[0] -Format 'Range')" -ForegroundColor Green
                    Write-Host "  Format pourcentage: $(Get-NormalizedApproximateExpression -ApproximationInfo $results[0] -Format 'Percentage')" -ForegroundColor Green
                    Write-Host "  Format plus-moins: $(Get-NormalizedApproximateExpression -ApproximationInfo $results[0] -Format 'PlusMinus')" -ForegroundColor Green
                } else {
                    $success = $false
                    Write-Host "[ERREUR] Expression trouvée: '$($results[0].Expression)'" -ForegroundColor Red
                    Write-Host "  Type: $($results[0].Info.Type) (attendu: $($test.ExpectedType))" -ForegroundColor Red
                    Write-Host "  Valeur: $($results[0].Info.Value) (attendu: $($test.ExpectedValue))" -ForegroundColor Red
                    Write-Host "  Marqueur: $($results[0].Info.Marker) (attendu: $($test.ExpectedMarker))" -ForegroundColor Red
                }
            } else {
                # Vérifier plusieurs expressions
                for ($i = 0; $i -lt $test.ExpectedCount; $i++) {
                    if ($results[$i].Info.Type -eq $test.ExpectedTypes[$i] -and 
                        [math]::Abs($results[$i].Info.Value - $test.ExpectedValues[$i]) -lt 0.01 -and 
                        $results[$i].Info.Marker -eq $test.ExpectedMarkers[$i]) {
                        
                        Write-Host "[OK] Expression $($i+1) trouvée: '$($results[$i].Expression)'" -ForegroundColor Green
                        Write-Host "  Type: $($results[$i].Info.Type)" -ForegroundColor Green
                        Write-Host "  Valeur: $($results[$i].Info.Value)" -ForegroundColor Green
                        Write-Host "  Marqueur: $($results[$i].Info.Marker)" -ForegroundColor Green
                    } else {
                        $success = $false
                        Write-Host "[ERREUR] Expression $($i+1) trouvée: '$($results[$i].Expression)'" -ForegroundColor Red
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
            Write-Host "[ERREUR] Nombre d'expressions trouvées: $($results.Count) (attendu: $($test.ExpectedCount))" -ForegroundColor Red
            $englishFailCount++
        }
    }
    
    # Afficher les résultats
    Write-Host "`nRésumé des résultats:" -ForegroundColor Yellow
    Write-Host "- Tests en français: $frenchSuccessCount réussis, $frenchFailCount échoués" -ForegroundColor Yellow
    Write-Host "- Tests en anglais: $englishSuccessCount réussis, $englishFailCount échoués" -ForegroundColor Yellow
    
    $totalSuccess = $frenchSuccessCount + $englishSuccessCount
    $totalFail = $frenchFailCount + $englishFailCount
    $totalTests = $totalSuccess + $totalFail
    
    Write-Host "- Total: $totalSuccess/$totalTests réussis ($(($totalSuccess / $totalTests) * 100)%)" -ForegroundColor Yellow
    
    Write-Host "`nTest terminé." -ForegroundColor Cyan
}

# Exécuter les tests
Test-ApproximateExpressions
