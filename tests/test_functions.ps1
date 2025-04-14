# Définir la fonction Measure-LevenshteinDistance
function Measure-LevenshteinDistance {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$String1,
        
        [Parameter(Mandatory = $true)]
        [string]$String2
    )
    
    $len1 = $String1.Length
    $len2 = $String2.Length
    
    # Créer une matrice pour stocker les distances
    $matrix = New-Object 'int[,]' ($len1 + 1), ($len2 + 1)
    
    # Initialiser la première colonne
    for ($i = 0; $i -le $len1; $i++) {
        $matrix[$i, 0] = $i
    }
    
    # Initialiser la première ligne
    for ($j = 0; $j -le $len2; $j++) {
        $matrix[0, $j] = $j
    }
    
    # Remplir la matrice
    for ($i = 1; $i -le $len1; $i++) {
        for ($j = 1; $j -le $len2; $j++) {
            $cost = if ($String1[$i - 1] -eq $String2[$j - 1]) { 0 } else { 1 }
            
            $matrix[$i, $j] = [Math]::Min(
                ($matrix[$i - 1, $j] + 1),          # Suppression
                [Math]::Min(
                    ($matrix[$i, $j - 1] + 1),      # Insertion
                    ($matrix[$i - 1, $j - 1] + $cost)  # Substitution
                )
            )
        }
    }
    
    # Retourner la distance
    return $matrix[$len1, $len2]
}

# Définir la fonction Get-MessagePattern
function Get-MessagePattern {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    
    # Remplacer les valeurs spécifiques par des placeholders
    $pattern = $Message
    
    # Remplacer les chemins de fichiers
    $pattern = $pattern -replace '([A-Za-z]:\\[^"<>|:*?\\]+)+', '<PATH>'
    
    # Remplacer les nombres
    $pattern = $pattern -replace '\b\d+\b', '<NUMBER>'
    
    # Remplacer les GUID
    $pattern = $pattern -replace '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}', '<GUID>'
    
    # Remplacer les noms de variables
    $pattern = $pattern -replace '\$[a-zA-Z0-9_]+', '<VARIABLE>'
    
    return $pattern
}

# Définir la fonction Get-LinePattern
function Get-LinePattern {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Line
    )
    
    if ([string]::IsNullOrEmpty($Line)) {
        return ""
    }
    
    # Remplacer les valeurs spécifiques par des placeholders
    $pattern = $Line
    
    # Remplacer les chaînes de caractères
    $pattern = $pattern -replace '"[^"]*"', '<STRING>'
    
    # Remplacer les nombres
    $pattern = $pattern -replace '\b\d+\b', '<NUMBER>'
    
    # Remplacer les noms de variables
    $pattern = $pattern -replace '\$[a-zA-Z0-9_]+', '<VARIABLE>'
    
    return $pattern
}

# Définir la fonction Measure-PatternSimilarity
function Measure-PatternSimilarity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Pattern1,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Pattern2
    )
    
    $similarityScore = 0
    $totalFeatures = 0
    
    # Comparer les types d'exception
    if ($Pattern1.ExceptionType -eq $Pattern2.ExceptionType) {
        $similarityScore += 0.3
    }
    $totalFeatures += 0.3
    
    # Comparer les ID d'erreur
    if ($Pattern1.ErrorId -eq $Pattern2.ErrorId) {
        $similarityScore += 0.2
    }
    $totalFeatures += 0.2
    
    # Comparer les patterns de message
    if ($Pattern1.MessagePattern -eq $Pattern2.MessagePattern) {
        $similarityScore += 0.3
    }
    elseif ($Pattern1.MessagePattern -and $Pattern2.MessagePattern) {
        # Calculer la similarité de Levenshtein
        $levenshtein = Measure-LevenshteinDistance -String1 $Pattern1.MessagePattern -String2 $Pattern2.MessagePattern
        $maxLength = [Math]::Max($Pattern1.MessagePattern.Length, $Pattern2.MessagePattern.Length)
        
        if ($maxLength -gt 0) {
            $similarity = 1 - ($levenshtein / $maxLength)
            $similarityScore += 0.3 * $similarity
        }
    }
    $totalFeatures += 0.3
    
    # Comparer les contextes de script
    if ($Pattern1.ScriptContext -eq $Pattern2.ScriptContext) {
        $similarityScore += 0.1
    }
    $totalFeatures += 0.1
    
    # Comparer les patterns de ligne
    if ($Pattern1.LinePattern -eq $Pattern2.LinePattern) {
        $similarityScore += 0.1
    }
    elseif ($Pattern1.LinePattern -and $Pattern2.LinePattern) {
        # Calculer la similarité de Levenshtein
        $levenshtein = Measure-LevenshteinDistance -String1 $Pattern1.LinePattern -String2 $Pattern2.LinePattern
        $maxLength = [Math]::Max($Pattern1.LinePattern.Length, $Pattern2.LinePattern.Length)
        
        if ($maxLength -gt 0) {
            $similarity = 1 - ($levenshtein / $maxLength)
            $similarityScore += 0.1 * $similarity
        }
    }
    $totalFeatures += 0.1
    
    # Calculer le score final
    if ($totalFeatures -gt 0) {
        return $similarityScore / $totalFeatures
    }
    else {
        return 0
    }
}

# Tester la fonction Measure-LevenshteinDistance
$string1 = "kitten"
$string2 = "sitting"
$distance = Measure-LevenshteinDistance -String1 $string1 -String2 $string2
Write-Host "Distance between '$string1' and '$string2': $distance"

# Tester la fonction Get-MessagePattern
$message = "Cannot access property 'Name' of null object at C:\Scripts\Test.ps1:42"
$pattern = Get-MessagePattern -Message $message
Write-Host "Original message: $message"
Write-Host "Pattern: $pattern"

# Tester la fonction Get-LinePattern
$line = '$result = $user.Properties["Name"] + 42'
$pattern = Get-LinePattern -Line $line
Write-Host "Original line: $line"
Write-Host "Pattern: $pattern"

# Tester la fonction Measure-PatternSimilarity
$pattern1 = @{
    ExceptionType = "System.NullReferenceException"
    ErrorId = "NullReference"
    MessagePattern = "Cannot access property of <VARIABLE>"
    ScriptContext = "Test-Script.ps1"
    LinePattern = "<VARIABLE> = <VARIABLE>.<VARIABLE>"
}

$pattern2 = @{
    ExceptionType = "System.NullReferenceException"
    ErrorId = "NullReference"
    MessagePattern = "Cannot access property of <VARIABLE>"
    ScriptContext = "Test-Script.ps1"
    LinePattern = "<VARIABLE> = <VARIABLE>.<VARIABLE>"
}

$similarity = Measure-PatternSimilarity -Pattern1 $pattern1 -Pattern2 $pattern2
Write-Host "Similarity between identical patterns: $similarity"

$pattern3 = @{
    ExceptionType = "System.NullReferenceException"
    ErrorId = "NullReference"
    MessagePattern = "Cannot access method of <VARIABLE>"
    ScriptContext = "Test-Script.ps1"
    LinePattern = "<VARIABLE> = <VARIABLE>.<VARIABLE>()"
}

$similarity = Measure-PatternSimilarity -Pattern1 $pattern1 -Pattern2 $pattern3
Write-Host "Similarity between different patterns: $similarity"
