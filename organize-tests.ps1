# Déplace tous les dossiers commençant par "test" (hors "tests") dans le dossier "tests".
$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
$target = Join-Path $root 'tests'

if (-not (Test-Path $target)) {
    New-Item -ItemType Directory -Path $target | Out-Null
}

Get-ChildItem -Path $root -Directory | Where-Object {
    $_.Name -match '^(?i)test' -and $_.Name -ne 'tests'
} | ForEach-Object {
    $dest = Join-Path $target $_.Name
    if (-not (Test-Path $dest)) {
        Move-Item $_.FullName $target
        Write-Host "Déplacé: $($_.Name) -> $target"
    } else {
        Write-Warning "Le dossier $($_.Name) existe déjà dans 'tests/'. Fusion manuelle recommandée."
    }
}
Write-Host "Organisation terminée."
