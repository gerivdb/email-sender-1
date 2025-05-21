# Déplace les fichiers non essentiels de la racine dans le dossier 'misc'

$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
$misc = Join-Path $root 'misc'

# Liste des fichiers à préserver (à adapter selon le projet)
$aPreserver = @(
    'README.md',
    '.gitignore',
    'package.json',
    'organize-tests.ps1',
    'organize-root-files.ps1',
    'LICENSE'
)

if (-not (Test-Path $misc)) {
    New-Item -ItemType Directory -Path $misc | Out-Null
}

Get-ChildItem -Path $root -File | Where-Object {
    $aPreserver -notcontains $_.Name
} | ForEach-Object {
    Move-Item $_.FullName $misc
    Write-Host "Déplacé: $($_.Name) -> $misc"
}

Write-Host "Fichiers non essentiels déplacés dans 'misc/'."
