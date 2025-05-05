# Importer le module
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "..\development\scripts\maintenance\error-learning\ErrorPatternAnalyzer.psm1") -Force

# VÃ©rifier que les fonctions sont disponibles
$functions = Get-Command -Module ErrorPatternAnalyzer
Write-Host "Fonctions disponibles dans le module ErrorPatternAnalyzer:"
$functions | ForEach-Object { Write-Host "- $($_.Name)" }

# Tester la fonction Get-MessagePattern
$message = "Cannot access property 'Name' of null object at C:\Scripts\Test.ps1:42"
$pattern = Get-MessagePattern -Message $message
Write-Host "`nOriginal message: $message"
Write-Host "Pattern: $pattern"

# Tester la fonction Get-LinePattern
$line = '$result = $user.Properties["Name"] + 42'
$pattern = Get-LinePattern -Line $line
Write-Host "`nOriginal line: $line"
Write-Host "Pattern: $pattern"

# Tester la fonction Measure-LevenshteinDistance
$string1 = "kitten"
$string2 = "sitting"
$distance = Measure-LevenshteinDistance -String1 $string1 -String2 $string2
Write-Host "`nDistance between '$string1' and '$string2': $distance"

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
Write-Host "`nSimilarity between identical patterns: $similarity"

$pattern3 = @{
    ExceptionType = "System.NullReferenceException"
    ErrorId = "NullReference"
    MessagePattern = "Cannot access method of <VARIABLE>"
    ScriptContext = "Test-Script.ps1"
    LinePattern = "<VARIABLE> = <VARIABLE>.<VARIABLE>()"
}

$similarity = Measure-PatternSimilarity -Pattern1 $pattern1 -Pattern2 $pattern3
Write-Host "Similarity between different patterns: $similarity"
