# Script simple pour tester la détection des instructions Import-Module et using module

# Chemin du fichier à analyser
$filePath = Join-Path -Path $PSScriptRoot -ChildPath "TestImport.ps1"

# Lire le contenu du fichier
$content = Get-Content -Path $filePath -Raw

# Afficher le contenu du fichier
Write-Host "Contenu du fichier :"
Write-Host $content

# 1. Détecter les instructions Import-Module
$importModuleRegex = [regex]'(?m)^\s*Import-Module\s+([^\s;#]+)'
$importModuleMatches = $importModuleRegex.Matches($content)

Write-Host "Instructions Import-Module trouvées : $($importModuleMatches.Count)"
foreach ($match in $importModuleMatches) {
    $moduleName = $match.Groups[1].Value.Trim()
    $position = $match.Index
    $lines = $content.Substring(0, $position).Split("`n")
    $lineNumber = $lines.Count

    Write-Host "  Module : $moduleName, Ligne : $lineNumber"
}

# 2. Détecter les instructions using module
$usingModuleRegex = [regex]'(?m)^\s*using\s+module\s+([^\s;#]+)'
$usingModuleMatches = $usingModuleRegex.Matches($content)

Write-Host "`nInstructions using module trouvées : $($usingModuleMatches.Count)"
foreach ($match in $usingModuleMatches) {
    $moduleName = $match.Groups[1].Value.Trim()
    $position = $match.Index
    $lines = $content.Substring(0, $position).Split("`n")
    $lineNumber = $lines.Count

    Write-Host "  Module : $moduleName, Ligne : $lineNumber"
}
