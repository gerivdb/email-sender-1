# Script pour corriger les problèmes d'encodage dans les fichiers PowerShell
# Ce script convertit tous les fichiers PowerShell en UTF-8 avec BOM

# Définir les extensions de fichiers à traiter
$extensions = @("*.ps1", "*.psm1", "*.psd1", "*.md")

# Définir les répertoires à traiter
$directories = @(
    "development\roadmap\parser\module\Functions\Public",
    "development\roadmap\parser\module\Functions\Common",
    "development\roadmap\parser\modes\dev-r",
    "development\scripts\augment"
)

# Fonction pour convertir un fichier en UTF-8 avec BOM
function Convert-FileToUTF8WithBOM {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw
        
        # Écrire le contenu dans le fichier avec l'encodage UTF-8 avec BOM
        [System.IO.File]::WriteAllText($FilePath, $content, [System.Text.UTF8Encoding]::new($true))
        
        Write-Host "Fichier converti en UTF-8 avec BOM : $FilePath" -ForegroundColor Green
    } catch {
        Write-Host "Erreur lors de la conversion du fichier $FilePath : $_" -ForegroundColor Red
    }
}

# Traiter tous les fichiers dans les répertoires spécifiés
foreach ($directory in $directories) {
    if (Test-Path -Path $directory -PathType Container) {
        Write-Host "Traitement du répertoire : $directory" -ForegroundColor Cyan
        
        foreach ($extension in $extensions) {
            $files = Get-ChildItem -Path $directory -Filter $extension -Recurse
            
            foreach ($file in $files) {
                Convert-FileToUTF8WithBOM -FilePath $file.FullName
            }
        }
    } else {
        Write-Host "Le répertoire $directory n'existe pas." -ForegroundColor Yellow
    }
}

Write-Host "Conversion terminée." -ForegroundColor Green
