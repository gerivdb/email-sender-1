# Définir les fonctions nécessaires
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
                $d0[$j + 1] + 1,          # Suppression
                [Math]::Min(
                    $d1[$j] + 1,           # Insertion
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
    } elseif ($Pattern1.MessagePattern -and $Pattern2.MessagePattern) {
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
    } elseif ($Pattern1.LinePattern -and $Pattern2.LinePattern) {
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
    } else {
        return 0
    }
}

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
