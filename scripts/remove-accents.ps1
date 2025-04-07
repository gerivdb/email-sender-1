# Script pour remplacer les caracteres accentues par des caracteres non accentues
# Version ASCII simple pour eviter les problemes d'encodage

function Remove-Accent {
    param (
        [string]$text
    )

    # Minuscules
    $text = $text.Replace("a`u0300", "a").Replace("a`u0301", "a").Replace("a`u0302", "a").Replace("a`u0303", "a").Replace("a`u0308", "a").Replace("a`u030a", "a")
    $text = $text.Replace("c`u0327", "c")
    $text = $text.Replace("e`u0300", "e").Replace("e`u0301", "e").Replace("e`u0302", "e").Replace("e`u0308", "e")
    $text = $text.Replace("i`u0300", "i").Replace("i`u0301", "i").Replace("i`u0302", "i").Replace("i`u0308", "i")
    $text = $text.Replace("n`u0303", "n")
    $text = $text.Replace("o`u0300", "o").Replace("o`u0301", "o").Replace("o`u0302", "o").Replace("o`u0303", "o").Replace("o`u0308", "o")
    $text = $text.Replace("u`u0300", "u").Replace("u`u0301", "u").Replace("u`u0302", "u").Replace("u`u0308", "u")
    $text = $text.Replace("y`u0301", "y").Replace("y`u0308", "y")

    # Majuscules
    $text = $text.Replace("A`u0300", "A").Replace("A`u0301", "A").Replace("A`u0302", "A").Replace("A`u0303", "A").Replace("A`u0308", "A").Replace("A`u030a", "A")
    $text = $text.Replace("C`u0327", "C")
    $text = $text.Replace("E`u0300", "E").Replace("E`u0301", "E").Replace("E`u0302", "E").Replace("E`u0308", "E")
    $text = $text.Replace("I`u0300", "I").Replace("I`u0301", "I").Replace("I`u0302", "I").Replace("I`u0308", "I")
    $text = $text.Replace("N`u0303", "N")
    $text = $text.Replace("O`u0300", "O").Replace("O`u0301", "O").Replace("O`u0302", "O").Replace("O`u0303", "O").Replace("O`u0308", "O")
    $text = $text.Replace("U`u0300", "U").Replace("U`u0301", "U").Replace("U`u0302", "U").Replace("U`u0308", "U")
    $text = $text.Replace("Y`u0301", "Y").Replace("Y`u0308", "Y")

    # Caracteres composes
    $text = $text.Replace("ae", "ae").Replace("AE", "AE")
    $text = $text.Replace("oe", "oe").Replace("OE", "OE")

    return $text
}

# Creer un repertoire pour les fichiers sans accents
$outputDir = "workflows-no-accents"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
    Write-Host "Repertoire $outputDir cree."
}

# Traiter tous les fichiers JSON dans le repertoire workflows
$workflowsDir = Read-Host "Entrez le chemin du repertoire contenant les fichiers JSON (par defaut: workflows)"
if ([string]::IsNullOrEmpty($workflowsDir)) {
    $workflowsDir = "workflows"
}

if (-not (Test-Path $workflowsDir)) {
    Write-Host "Le repertoire n'existe pas: $workflowsDir" -ForegroundColor Red
    exit
}

$workflowFiles = Get-ChildItem -Path $workflowsDir -Filter "*.json"
$successCount = 0

foreach ($file in $workflowFiles) {
    Write-Host "Traitement du fichier: $($file.Name)" -NoNewline
    
    try {
        # Lire le contenu du fichier
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        
        # Remplacer les caracteres accentues dans le contenu JSON
        $fixedContent = Remove-Accent -text $content
        
        # Sauvegarder le fichier sans accents
        $outputPath = Join-Path -Path $outputDir -ChildPath $file.Name
        $fixedContent | Out-File -FilePath $outputPath -Encoding UTF8 -NoNewline
        
        Write-Host " - Succes!" -ForegroundColor Green
        $successCount++
    }
    catch {
        Write-Host " - Echec!" -ForegroundColor Red
        Write-Host "  Erreur: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nTraitement termine: $successCount/$($workflowFiles.Count) fichiers traites."
Write-Host "Les fichiers sans accents se trouvent dans le repertoire: $outputDir"
Write-Host "`nVous pouvez maintenant importer ces fichiers dans n8n."
