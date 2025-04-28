#Requires -Version 5.1
<#
.SYNOPSIS
    Corrige les problÃ¨mes d'encodage dans les rapports HTML d'analyse.
.PARAMETER Path
    Chemin du fichier HTML Ã  corriger ou du rÃ©pertoire contenant les fichiers HTML.
.PARAMETER Recurse
    Rechercher rÃ©cursivement les fichiers HTML dans les sous-rÃ©pertoires.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $false)][switch]$Recurse
)

# VÃ©rifier si le chemin existe
if (-not (Test-Path -Path $Path)) { throw "Le chemin '$Path' n'existe pas." }

# Fonction pour corriger l'encodage d'un fichier HTML
function Repair-FileEncoding([string]$FilePath) {
    try {
        # Lire le contenu et rÃ©Ã©crire avec UTF-8 avec BOM
        $content = Get-Content -Path $FilePath -Raw
        [System.IO.File]::WriteAllText($FilePath, $content, [System.Text.Encoding]::UTF8)
        Write-Host "Encodage corrige: '$FilePath'" -ForegroundColor Green
    } catch { Write-Error "Erreur de correction d'encodage pour '$FilePath': $_" }
}

# Traiter fichier ou rÃ©pertoire
if ((Get-Item -Path $Path) -is [System.IO.DirectoryInfo]) {
    # RÃ©cupÃ©rer tous les fichiers HTML
    $files = Get-ChildItem -Path $Path -Include "*.html" -File -Recurse:$Recurse

    # Corriger l'encodage de chaque fichier
    foreach ($file in $files) { Repair-FileEncoding -FilePath $file.FullName }
    Write-Host "Correction terminee pour $($files.Count) fichier(s)." -ForegroundColor Cyan
} else {
    # Corriger l'encodage du fichier spÃ©cifiÃ©
    Repair-FileEncoding -FilePath $Path
}
