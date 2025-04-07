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
    $content = $content -replace "ÃƒÂ©", "e"
    $content = $content -replace "ÃƒÂ¨", "e"
    $content = $content -replace "Ãƒ ", "a"
    $content = $content -replace "ÃƒÂ§", "c"
    $content = $content -replace "ÃƒÂª", "e"
    $content = $content -replace "ÃƒÂ®", "i"
    $content = $content -replace "ÃƒÂ´", "o"
    $content = $content -replace "ÃƒÂ»", "u"
    $content = $content -replace "ÃƒÂ¹", "u"
    $content = $content -replace "ÃƒÂ¢", "a"
    $content = $content -replace "ÃƒÂ«", "e"
    $content = $content -replace "ÃƒÂ¯", "i"
    $content = $content -replace "ÃƒÂ¼", "u"
    $content = $content -replace "ÃƒÂ¶", "o"
    $content = $content -replace "ÃƒÂ±", "Ã±"
    $content = $content -replace "Ãƒâ€°", "Ã‰"
    $content = $content -replace "Ãƒâ‚¬", "Ã€"
    $content = $content -replace "Ãƒâ€¡", "Ã‡"
    $content = $content -replace "ÃƒÅ ", "ÃŠ"
    $content = $content -replace "Ãƒ"", "Ã”"
    $content = $content -replace "Ãƒâ€º", "Ã›"
    
    # Corriger les caracteres speciaux
    $content = $content -replace "\\\-", "-"
    $content = $content -replace "\\\*", "*"
    $content = $content -replace "\\\[", "["
    $content = $content -replace "\\\]", "]"
    $content = $content -replace "\\\(", "("
    $content = $content -replace "\\\)", ")"
    
    # Ã‰crire le contenu dans le fichier de destination avec encodage UTF-8
    $content | Out-File -FilePath $DestinationFile -Encoding utf8
    
    Write-Output "Conversion reussie: $SourceFile -> $DestinationFile"
} 
catch {
    Write-Error "Erreur lors de la conversion: $_"
    exit 1
}

