# Définir la fonction Measure-LevenshteinDistance
function Measure-LevenshteinDistance {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$String1 = "",

        [Parameter(Mandatory = $false)]
        [string]$String2 = ""
    )

    # Cas particuliers
    if ($String1 -eq $String2) { return 0 }
    if ($String1.Length -eq 0) { return $String2.Length }
    if ($String2.Length -eq 0) { return $String1.Length }

    # Utiliser une approche plus simple avec des tableaux 1D
    $len1 = $String1.Length
    $len2 = $String2.Length

    # Créer deux tableaux pour stocker les distances
    $d0 = New-Object int[] ($len2 + 1)
    $d1 = New-Object int[] ($len2 + 1)

    # Initialiser le premier tableau
    for ($j = 0; $j -le $len2; $j++) {
        $d0[$j] = $j
    }

    # Calculer la distance
    for ($i = 0; $i -lt $len1; $i++) {
        $d1[0] = $i + 1

        for ($j = 0; $j -lt $len2; $j++) {
            $cost = if ($String1[$i] -eq $String2[$j]) { 0 } else { 1 }
            $d1[$j + 1] = [Math]::Min(
                $d0[$j + 1] + 1, # Suppression
                [Math]::Min(
                    $d1[$j] + 1, # Insertion
                    $d0[$j] + $cost        # Substitution
                )
            )
        }

        # Échanger les tableaux pour la prochaine itération
        $temp = $d0
        $d0 = $d1
        $d1 = $temp
    }

    # Retourner la distance
    return $d0[$len2]
}

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
