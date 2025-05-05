# Script de test pour la dÃ©tection des instructions using module
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath = (Join-Path -Path $PSScriptRoot -ChildPath "TestImport.ps1")
)

# Afficher le contenu du fichier
Write-Host "Contenu du fichier $FilePath :"
$content = Get-Content -Path $FilePath -Raw
Write-Host $content

# Utiliser une expression rÃ©guliÃ¨re simple pour dÃ©tecter les instructions using module
$regex = [regex]'using\s+module\s+(\S+)'
$matches = $regex.Matches($content)

Write-Host "`nNombre d'instructions using module trouvÃ©es : $($matches.Count)"
foreach ($match in $matches) {
    $moduleName = $match.Groups[1].Value
    Write-Host "  Module : $moduleName"
}

# Utiliser une expression rÃ©guliÃ¨re pour dÃ©tecter les instructions Import-Module
$regex = [regex]'Import-Module\s+(\S+)'
$matches = $regex.Matches($content)

Write-Host "`nNombre d'instructions Import-Module trouvÃ©es : $($matches.Count)"
foreach ($match in $matches) {
    $moduleName = $match.Groups[1].Value
    Write-Host "  Module : $moduleName"
}
