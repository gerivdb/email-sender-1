# Script pour tester la détection des instructions using module

# Lire le contenu du fichier
$filePath = Join-Path -Path $PSScriptRoot -ChildPath "TestImport.ps1"
$content = Get-Content -Path $filePath -Raw

# Utiliser une expression régulière pour trouver les instructions using module
$regex = [regex]'(?m)^\s*using\s+module\s+([^\s;#]+)'
$matches = $regex.Matches($content)

Write-Host "Contenu du fichier (premiers 100 caractères) :"
Write-Host $content.Substring(0, [Math]::Min(100, $content.Length))

Write-Host "`nNombre d'instructions using module trouvées : $($matches.Count)"

foreach ($match in $matches) {
    $moduleName = $match.Groups[1].Value.Trim()
    $position = $match.Index
    $lines = $content.Substring(0, $position).Split("`n")
    $lineNumber = $lines.Count
    
    Write-Host "Module : $moduleName, Ligne : $lineNumber"
}
