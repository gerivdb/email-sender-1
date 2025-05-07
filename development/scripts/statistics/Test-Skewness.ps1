# Importer le module
Import-Module .\development\scripts\statistics\ResolutionRecommendations.psm1 -Force

# Tester la fonction Get-SkewnessThreshold
$result = Get-SkewnessThreshold -SampleSize 200 -ConfidenceLevel "95%" -Application "Analyse statistique"
Write-Host "Seuil final: $($result.FinalThreshold)"
