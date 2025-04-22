<#
.SYNOPSIS
    Script pour copier le fichier LICENSE dans la nouvelle structure.

.DESCRIPTION
    Ce script copie le fichier LICENSE de la racine du projet vers la nouvelle structure n8n.

.EXAMPLE
    .\copy-license.ps1
#>

# Définir les chemins
$rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$n8nPath = Join-Path -Path $rootPath -ChildPath "n8n-new"

# Copier le fichier LICENSE
$licensePath = Join-Path -Path $rootPath -ChildPath "LICENSE"
$n8nLicensePath = Join-Path -Path $n8nPath -ChildPath "LICENSE"

if (Test-Path -Path $licensePath) {
    Copy-Item -Path $licensePath -Destination $n8nLicensePath -Force
    Write-Host "Fichier LICENSE copié: $licensePath -> $n8nLicensePath"
} else {
    Write-Warning "Le fichier LICENSE n'existe pas: $licensePath"
}

Write-Host ""
Write-Host "Copie du fichier LICENSE terminée."
