<#
.SYNOPSIS
    Corrige les problemes d'encodage dans un fichier Markdown.

.DESCRIPTION
    Ce script corrige les problemes d'encodage des caracteres accentues dans un fichier Markdown.

.PARAMETER Path
    Chemin vers le fichier Markdown a corriger.

.PARAMETER OutputPath
    Chemin ou le fichier corrige sera enregistre. Si non specifie, le fichier original sera remplace.

.EXAMPLE
    .\Fix-RoadmapEncoding.ps1 -Path "Roadmap/roadmap_complete_new.md"

.NOTES
    Auteur: Equipe DevOps
    Date: 2025-04-20
    Version: 1.0.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$Path,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = $null
)

# Definir le chemin de sortie
if (-not $OutputPath) {
    $OutputPath = $Path
}

try {
    # Lire le contenu du fichier
    $content = Get-Content -Path $Path -Raw -Encoding UTF8
    
    # Definir les remplacements
    $replacements = @{
        'fonctionnalitÃƒÂ©s' = 'fonctionnalites'
        'ComplexitÃƒÂ©' = 'Complexite'
        'estimÃƒÂ©' = 'estime'
        'DÃƒÂ©pendances' = 'Dependances'
        'SÃƒÂ©curitÃƒÂ©' = 'Securite'
        'ÃƒÂ©viter' = 'eviter'
        'donnÃƒÂ©es' = 'donnees'
        'Ãƒâ€°quipe' = 'Equipe'
        'dÃƒÂ©veloppement' = 'developpement'
        'approuvÃƒÂ©s' = 'approuves'
        'Modules et fonctionnalitÃƒÂ©s' = 'Modules et fonctionnalites'
        'Ãƒâ€°quipe de dÃƒÂ©veloppement' = 'Equipe de developpement'
    }
    
    # Appliquer les remplacements
    foreach ($key in $replacements.Keys) {
        $content = $content -replace [regex]::Escape($key), $replacements[$key]
    }
    
    # Enregistrer le contenu corrige
    $content | Out-File -FilePath $OutputPath -Encoding UTF8
    
    Write-Host "Encodage corrige avec succes: $OutputPath"
}
catch {
    Write-Error "Erreur lors de la correction de l'encodage: $_"
}
