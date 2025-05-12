# Test-Encoding.ps1
# Script pour tester l'encodage des caractères
# Version: 1.0
# Date: 2025-05-15

# Afficher l'encodage par défaut
Write-Host "Encodage par défaut de PowerShell:" -ForegroundColor Cyan
[System.Text.Encoding]::Default

# Afficher quelques caractères spéciaux
Write-Host "`nTest de caractères spéciaux:" -ForegroundColor Cyan
Write-Host "é è ê ë à â ä ù û ü ô ö î ï ÿ ç" -ForegroundColor Yellow

# Afficher des phrases de test
Write-Host "`nPhrases de test:" -ForegroundColor Cyan
$phrases = @(
    "Cette tâche prendra environ vingt-cinq jours à réaliser.",
    "Le projet est estimé à deux cent cinquante heures de travail.",
    "Le coût sera de 1000 euros environ.",
    "Le délai est de 15 jours plus ou moins 2 jours.",
    "Le budget est entre 5000 et 6000 euros."
)

foreach ($phrase in $phrases) {
    Write-Host $phrase -ForegroundColor Yellow
}

# Tester une expression régulière simple
Write-Host "`nTest d'expression régulière:" -ForegroundColor Cyan
$pattern = "environ"
foreach ($phrase in $phrases) {
    if ($phrase -match $pattern) {
        Write-Host "Correspondance trouvée dans: '$phrase'" -ForegroundColor Green
    } else {
        Write-Host "Aucune correspondance dans: '$phrase'" -ForegroundColor Red
    }
}

# Tester une expression régulière avec caractères spéciaux
Write-Host "`nTest d'expression régulière avec caractères spéciaux:" -ForegroundColor Cyan
$pattern = "à"
foreach ($phrase in $phrases) {
    if ($phrase -match $pattern) {
        Write-Host "Correspondance trouvée dans: '$phrase'" -ForegroundColor Green
    } else {
        Write-Host "Aucune correspondance dans: '$phrase'" -ForegroundColor Red
    }
}

# Afficher les caractères d'une phrase
Write-Host "`nAffichage des caractères d'une phrase:" -ForegroundColor Cyan
$phrase = "Cette tâche prendra environ vingt-cinq jours à réaliser."
Write-Host "Phrase: '$phrase'" -ForegroundColor Yellow
Write-Host "Longueur: $($phrase.Length) caractères" -ForegroundColor Yellow

Write-Host "`nCaractères:" -ForegroundColor Cyan
for ($i = 0; $i -lt $phrase.Length; $i++) {
    $char = $phrase[$i]
    $code = [int][char]$char
    Write-Host "  Position $i : '$char' (code: $code, hex: 0x$($code.ToString('X4')))" -ForegroundColor Cyan
}

Write-Host "`nTest terminé." -ForegroundColor Cyan
