# Script pour corriger l'erreur de token $null inattendu dans le fichier RoadmapAdmin.ps1 du dossier Roadmap

# Chemin du fichier à corriger
$filePath = "D:/DO/WEB/N8N_tests/scripts_ json_a_ tester/EMAIL_SENDER_1/Roadmap/RoadmapAdmin.ps1"

# Vérifier si le fichier existe
if (-not (Test-Path -Path $filePath)) {
    Write-Host "Le fichier n'existe pas: $filePath" -ForegroundColor Red
    exit 1
}

# Lire le contenu du fichier ligne par ligne
$lines = Get-Content -Path $filePath

# Afficher la ligne problématique (ligne 435)
Write-Host "Ligne problématique (435): $($lines[434])" -ForegroundColor Yellow

# Corriger la ligne problématique
# Le problème est que la ligne contient "$null" au début d'une expression
if ($lines[434] -like "*`$null*") {
    # Remplacer la ligne par une version corrigée
    $originalLine = $lines[434]

    # Si la ligne commence par $null sans 'if', c'est probablement une affectation
    if ($originalLine.Trim().StartsWith('$null')) {
        # Vérifier si c'est une affectation à $null
        if ($originalLine -match '\$null\s*=\s*(.+)') {
            # C'est une affectation à $null, on peut la garder telle quelle
            Write-Host "La ligne est une affectation à `$null, pas besoin de correction." -ForegroundColor Green
        }
        else {
            # C'est une utilisation incorrecte de $null, corriger en ajoutant une affectation
            $lines[434] = $originalLine.Replace('$null', '[void]')
            Write-Host "Ligne corrigée: $($lines[434])" -ForegroundColor Green
        }
    }
    else {
        # Autre cas, essayer de comprendre le contexte
        Write-Host "Contexte non reconnu, affichage des lignes environnantes pour analyse:" -ForegroundColor Yellow
        for ($i = [Math]::Max(0, 434-5); $i -lt [Math]::Min($lines.Count, 434+5); $i++) {
            Write-Host "[$i] $($lines[$i])" -ForegroundColor $(if ($i -eq 434) { "Yellow" } else { "Gray" })
        }

        # Appliquer la correction automatiquement
        $lines[434] = $originalLine.Replace('$null', '[void]')
        Write-Host "Ligne corrigée: $($lines[434])" -ForegroundColor Green
    }
}

# Enregistrer les modifications
Set-Content -Path $filePath -Value $lines -Encoding UTF8

Write-Host "Correction appliquée au fichier: $filePath" -ForegroundColor Green
