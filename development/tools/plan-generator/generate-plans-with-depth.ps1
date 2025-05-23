# Ce script génère des plans de développement avec différentes profondeurs de tâches
# Il démontre l'utilisation du paramètre -taskDepth du générateur goplangen

# Chemin du binaire
$goplangen = ".\goplangen.exe"

# Répertoire de sortie
$outputDir = "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\projet\roadmaps\plans\consolidated"

# Version de base pour les plans
$baseVersion = "depth-demo"

# Tableau de profondeurs à tester
$depths = @(1, 2, 3, 4, 5, 6, 7)

Write-Host "Génération de plans avec différentes profondeurs de tâches..." -ForegroundColor Green

foreach ($depth in $depths) {
    $version = "$baseVersion-$depth"
    $title = "Plan avec profondeur $depth"
    $description = "Ce plan démontre la génération de tâches avec une profondeur de niveau $depth."
    
    Write-Host "Génération du plan avec profondeur $depth..." -ForegroundColor Yellow
    
    # Make sure we're running in non-interactive mode
    $command = "$goplangen -version $version -title `"$title`" -description `"$description`" -taskDepth $depth -output `"$outputDir`" -phases 3"
    Write-Host "Commande: $command" -ForegroundColor Cyan
    
    Invoke-Expression $command
}

Write-Host "Génération des plans terminée." -ForegroundColor Green
Write-Host "Plans générés dans: $outputDir" -ForegroundColor Green
