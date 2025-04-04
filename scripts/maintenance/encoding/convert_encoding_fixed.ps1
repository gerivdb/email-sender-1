# Script PowerShell pour convertir l'encodage des fichiers Markdown
# Ce script prend un fichier source, detecte son encodage et le convertit en UTF-8

param (
    [Parameter(Mandatory=$true)]
    [string]$SourceFile,
    
    [Parameter(Mandatory=$true)]
    [string]$DestinationFile
)

# Verifier si le fichier source existe
if (-not (Test-Path $SourceFile)) {
    Write-Error "Le fichier source n'existe pas: $SourceFile"
    exit 1
}

try {
    # Lire le contenu du fichier source
    $content = Get-Content -Path $SourceFile -Raw -Encoding Default
    
    # Corriger les caracteres mal encodes
    $content = $content -replace "Ã©", "e"
    $content = $content -replace "Ã¨", "e"
    $content = $content -replace "Ã ", "a"
    $content = $content -replace "Ã§", "c"
    $content = $content -replace "Ãª", "e"
    $content = $content -replace "Ã®", "i"
    $content = $content -replace "Ã´", "o"
    $content = $content -replace "Ã»", "u"
    $content = $content -replace "Ã¹", "u"
    $content = $content -replace "Ã¢", "a"
    $content = $content -replace "Ã«", "e"
    $content = $content -replace "Ã¯", "i"
    $content = $content -replace "Ã¼", "u"
    $content = $content -replace "Ã¶", "o"
    $content = $content -replace "Ã±", "ñ"
    $content = $content -replace "Ã‰", "É"
    $content = $content -replace "Ã€", "À"
    $content = $content -replace "Ã‡", "Ç"
    $content = $content -replace "ÃŠ", "Ê"
    # Utiliser des apostrophes simples pour eviter les problemes avec les guillemets doubles
    $content = $content -replace 'Ã"', 'Ô'
    $content = $content -replace 'Ã›', 'Û'
    
    # Corriger les caracteres speciaux
    $content = $content -replace "\\\-", "-"
    $content = $content -replace "\\\*", "*"
    $content = $content -replace "\\\[", "["
    $content = $content -replace "\\\]", "]"
    $content = $content -replace "\\\(", "("
    $content = $content -replace "\\\)", ")"
    
    # Écrire le contenu dans le fichier de destination avec encodage UTF-8
    $content | Out-File -FilePath $DestinationFile -Encoding utf8
    
    Write-Output "Conversion reussie: $SourceFile -> $DestinationFile"
} 
catch {
    Write-Error "Erreur lors de la conversion: $_"
    exit 1
}

