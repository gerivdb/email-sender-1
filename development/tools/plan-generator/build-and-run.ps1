# Script pour compiler et exécuter le générateur de plans en Go

# Aller dans le répertoire du script
Set-Location -Path "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/development/tools/plan-generator"

# Compiler le générateur Go
Write-Output "Compilation du générateur de plans en Go..."
go build -o goplangen.exe ./cmd/main.go

if (-not $?) {
    Write-Error "Erreur lors de la compilation du générateur Go"
    exit 1
}

Write-Output "Compilation terminée avec succès!"

# Exemples de différentes façons d'exécuter le générateur

# 1. Génération simple avec les arguments nécessaires
$version = "v35a"
$title = "MCP Manager Centralisé"
$description = "Ce plan vise à concevoir, développer et intégrer un MCP Manager centralisé pour orchestrer les serveurs MCP, gérer leurs capacités, et faciliter la communication avec le MCP Gateway."
$phases = 5
$phaseDetails = "{}"
$outputDir = "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/projet/roadmaps/plans/consolidated"

Write-Output "Génération du plan de développement..."
& ./goplangen.exe -version $version -title $title -description $description -phases $phases -phaseDetails $phaseDetails -output $outputDir

# 2. Génération avec export JSON
# Décommentez pour utiliser cette option
# Write-Output "Génération du plan avec export JSON..."
# & ./goplangen.exe -version "v35b" -title "Plan avec JSON" -description "Ce plan est exporté aussi en JSON" -phases 3 -output $outputDir -exportJSON

# 3. Génération interactive
# Décommentez pour utiliser cette option
# Write-Output "Génération interactive du plan..."
# & ./goplangen.exe -interactive -output $outputDir

# 4. Import depuis Markdown existant
# Décommentez et ajustez le chemin pour utiliser cette option
# $existingPlan = Join-Path -Path $outputDir -ChildPath "plan-dev-v35a-mcp-manager-centralis.md" 
# Write-Output "Import et mise à jour du plan depuis $existingPlan..."
# & ./goplangen.exe -importMD $existingPlan -version "v35c" -output $outputDir

if (-not $?) {
    Write-Error "Erreur lors de la génération du plan"
    exit 1
}

Write-Output "Génération terminée avec succès!"
