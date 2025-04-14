# Importer le module
. (Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\maintenance\error-learning\ErrorPatternAnalyzer.psm1")

# Tester la fonction Measure-LevenshteinDistance
$string1 = "kitten"
$string2 = "sitting"
$distance = Measure-LevenshteinDistance -String1 $string1 -String2 $string2
Write-Host "Distance between '$string1' and '$string2': $distance"

# Tester avec des chaînes identiques
$string1 = "test"
$string2 = "test"
$distance = Measure-LevenshteinDistance -String1 $string1 -String2 $string2
Write-Host "Distance between '$string1' and '$string2': $distance"

# Tester avec une chaîne vide
$string1 = ""
$string2 = "test"
$distance = Measure-LevenshteinDistance -String1 $string1 -String2 $string2
Write-Host "Distance between '$string1' and '$string2': $distance"

# Tester avec des chaînes longues
$string1 = "This is a long string to test the Levenshtein distance algorithm"
$string2 = "This is another long string to test the algorithm"
$distance = Measure-LevenshteinDistance -String1 $string1 -String2 $string2
Write-Host "Distance between long strings: $distance"
