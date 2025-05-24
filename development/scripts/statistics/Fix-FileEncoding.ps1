# Encoding: UTF-8 with BOM
#Requires -Version 5.1
<#
.SYNOPSIS
    Corrige l'encodage des fichiers PowerShell pour utiliser UTF-8 avec BOM.

.DESCRIPTION
    Ce script lit les fichiers spécifiés et les réécrit avec l'encodage UTF-8 avec BOM,
    ce qui est recommandé pour les scripts PowerShell contenant des caractères accentués.

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  2023-05-15
#>

# Définir l'encodage de sortie en UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Fonction pour corriger l'encodage d'un fichier
function Repair-FileEncoding {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            Write-Error "Le fichier '$FilePath' n'existe pas."
            return $false
        }

        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw

        # Écrire le contenu avec l'encodage UTF-8 avec BOM
        $utf8WithBom = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllText($FilePath, $content, $utf8WithBom)

        Write-Host "L'encodage du fichier '$FilePath' a été corrigé en UTF-8 avec BOM." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Une erreur s'est produite lors de la correction de l'encodage du fichier '$FilePath': $_"
        return $false
    }
}

# Fichiers à corriger
$filesToFix = @(
    (Join-Path -Path $PSScriptRoot -ChildPath "HypothesisTestQualityMetrics.psm1"),
    (Join-Path -Path $PSScriptRoot -ChildPath "Test-HypothesisTestQualityMetrics.ps1")
)

# Corriger l'encodage de chaque fichier
$success = $true
foreach ($file in $filesToFix) {
    $result = Repair-FileEncoding -FilePath $file
    if (-not $result) {
        $success = $false
    }
}

# Afficher un message de résumé
if ($success) {
    Write-Host "Tous les fichiers ont été corrigés avec succès." -ForegroundColor Green
} else {
    Write-Host "Des erreurs se sont produites lors de la correction de certains fichiers." -ForegroundColor Red
}

