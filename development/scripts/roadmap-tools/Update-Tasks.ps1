# Script pour mettre à jour les tâches dans un fichier de roadmap

$roadmapPath = "test_roadmap.md"
$lineNumbers = @(20, 21, 26, 27)

# Lire le contenu du fichier de roadmap
$content = Get-Content -Path $roadmapPath -Encoding UTF8

# Mettre à jour les tâches
foreach ($lineNumber in $lineNumbers) {
    $line = $content[$lineNumber - 1]
    if ($line -match '^\s*-\s+\[ \]\s+(\d+(\.\d+)*)\s+(.+)$') {
        $content[$lineNumber - 1] = $line -replace '\[ \]', '[x]'
        Write-Host "Tâche mise à jour à la ligne $lineNumber : $($content[$lineNumber - 1])" -ForegroundColor Green
    }
    else {
        Write-Host "Ligne $lineNumber : $line" -ForegroundColor Yellow
        Write-Host "  La ligne ne correspond pas à une tâche non cochée." -ForegroundColor Red
    }
}

# Sauvegarder le contenu mis à jour
$content | Set-Content -Path $roadmapPath -Encoding UTF8
Write-Host "`nLe fichier de roadmap a été mis à jour." -ForegroundColor Green
