# Script de test pour la détection des instructions using module
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath = (Join-Path -Path $PSScriptRoot -ChildPath "TestImport.ps1")
)

# Afficher le contenu du fichier
Write-Host "Contenu du fichier $FilePath :"
$content = Get-Content -Path $FilePath -Raw
Write-Host $content

# Utiliser une expression régulière simple pour détecter les instructions using module
$regex = [regex]'using\s+module\s+(\S+)'
$matches = $regex.Matches($content)

Write-Host "`nNombre d'instructions using module trouvées : $($matches.Count)"
foreach ($match in $matches) {
    $moduleName = $match.Groups[1].Value
    Write-Host "  Module : $moduleName"
}

# Utiliser une expression régulière pour détecter les instructions Import-Module
$regex = [regex]'Import-Module\s+(\S+)'
$matches = $regex.Matches($content)

Write-Host "`nNombre d'instructions Import-Module trouvées : $($matches.Count)"
foreach ($match in $matches) {
    $moduleName = $match.Groups[1].Value
    Write-Host "  Module : $moduleName"
}
