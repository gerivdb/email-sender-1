# Script pour tester la détection des instructions using module
$testFilePath = Join-Path -Path $PSScriptRoot -ChildPath "TestImport.ps1"

# Lire le contenu du fichier
$content = Get-Content -Path $testFilePath -Raw

# Afficher le contenu du fichier
Write-Host "Contenu du fichier :"
Write-Host $content

# Utiliser une expression régulière pour détecter les instructions using module
$regex = [regex]::new('using\s+module\s+(\S+)')
$matches = $regex.Matches($content)

Write-Host "`nNombre d'instructions using module trouvées : $($matches.Count)"
foreach ($match in $matches) {
    $moduleName = $match.Groups[1].Value
    Write-Host "  Module : $moduleName"
}

# Créer un fichier temporaire avec une instruction using module
$tempFilePath = Join-Path -Path $env:TEMP -ChildPath "TestUsingModule.ps1"
Set-Content -Path $tempFilePath -Value "using module PSScriptAnalyzer`nImport-Module Pester"

# Lire le contenu du fichier temporaire
$tempContent = Get-Content -Path $tempFilePath -Raw

# Afficher le contenu du fichier temporaire
Write-Host "`nContenu du fichier temporaire :"
Write-Host $tempContent

# Utiliser une expression régulière pour détecter les instructions using module dans le fichier temporaire
$matches = $regex.Matches($tempContent)

Write-Host "`nNombre d'instructions using module trouvées dans le fichier temporaire : $($matches.Count)"
foreach ($match in $matches) {
    $moduleName = $match.Groups[1].Value
    Write-Host "  Module : $moduleName"
}

# Nettoyer
Remove-Item -Path $tempFilePath -Force
