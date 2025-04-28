# Réorganisation des dossiers development/tools et development/scripts/utils

# Définir les chemins
$toolsRoot = Join-Path -Path (Get-Location).Path -ChildPath "development\tools"
$utilsRoot = Join-Path -Path (Get-Location).Path -ChildPath "development\scripts\utils"

# Vérifier que les dossiers existent
if (-not (Test-Path $toolsRoot)) {
    Write-Error "Le dossier development\tools n'existe pas : $toolsRoot"
    exit 1
}

if (-not (Test-Path $utilsRoot)) {
    Write-Error "Le dossier development\scripts\utils n'existe pas : $utilsRoot"
    exit 1
}

# Définir la nouvelle structure de dossiers dans tools
$newFolders = @(
    "analysis",
    "augment",
    "cache",
    "converters",
    "detectors",
    "documentation",
    "error-handling",
    "examples",
    "git",
    "integrations",
    "json",
    "markdown",
    "optimization",
    "reports",
    "roadmap",
    "testing",
    "utilities"
)

# Créer les nouveaux dossiers dans tools
foreach ($folder in $newFolders) {
    $folderPath = Join-Path -Path $toolsRoot -ChildPath $folder
    
    if (-not (Test-Path $folderPath)) {
        New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
        Write-Host "  Dossier créé : $folderPath" -ForegroundColor Yellow
    }
}

# Mettre à jour le fichier README.md dans tools
$readmePath = Join-Path -Path $toolsRoot -ChildPath "README.md"
$readmeContent = "# Outils de développement`n`nCe dossier contient tous les outils utilisés pour le développement du projet.`n`n## Structure`n`n"

foreach ($folder in $newFolders | Sort-Object) {
    $description = ""
    switch ($folder) {
        "analysis" { $description = "Outils d'analyse de code et de performance" }
        "augment" { $description = "Configuration et outils pour Augment" }
        "cache" { $description = "Gestionnaires de cache et outils de mise en cache" }
        "converters" { $description = "Convertisseurs de formats (CSV, YAML, JSON, etc.)" }
        "detectors" { $description = "Détecteurs de problèmes et d'anomalies" }
        "documentation" { $description = "Outils de génération de documentation" }
        "error-handling" { $description = "Outils de gestion des erreurs" }
        "examples" { $description = "Exemples d'utilisation des outils" }
        "git" { $description = "Outils pour Git" }
        "integrations" { $description = "Intégrations avec d'autres systèmes" }
        "json" { $description = "Outils de manipulation de JSON" }
        "markdown" { $description = "Outils de manipulation de Markdown" }
        "optimization" { $description = "Outils d'optimisation" }
        "reports" { $description = "Générateurs de rapports" }
        "roadmap" { $description = "Outils pour la roadmap" }
        "testing" { $description = "Outils de test" }
        "utilities" { $description = "Utilitaires divers" }
        default { $description = "Outils divers" }
    }
    
    $readmeContent += "- **$folder/** - $description`n"
}

$readmeContent += "`n## Utilisation`n`nLes outils de ce dossier sont utilisés par les scripts du projet. Ils peuvent également être utilisés directement par les développeurs.`n`n## Développement`n`nPour ajouter un nouvel outil, créez un fichier dans le sous-dossier approprié et documentez son utilisation dans le README.md du sous-dossier."

Set-Content -Path $readmePath -Value $readmeContent -Force
Write-Host "  Fichier README.md mis à jour : $readmePath" -ForegroundColor Green

# Créer un fichier README.md dans utils pour expliquer la migration
$utilsReadmePath = Join-Path -Path $utilsRoot -ChildPath "README.md"
$utilsReadmeContent = "# Utilitaires (Déprécié)`n`nCe dossier est déprécié. Tous les utilitaires ont été déplacés vers le dossier `development/tools`.`n`nVeuillez utiliser les outils dans le dossier `development/tools` à la place.`n`n## Migration`n`nLes fichiers de ce dossier ont été migrés vers les sous-dossiers suivants dans `development/tools` :`n`n"

$utilsReadmeContent += "- **analysis/** -> `development/tools/analysis-tools/``n"
$utilsReadmeContent += "- **automation/** -> `development/tools/utilities-tools/``n"
$utilsReadmeContent += "- **cache/** -> `development/tools/cache-tools/``n"
$utilsReadmeContent += "- **CompatibleCode/** -> `development/tools/utilities-tools/``n"
$utilsReadmeContent += "- **Converters/** -> `development/tools/converters-tools/``n"
$utilsReadmeContent += "- **Detectors/** -> `development/tools/detectors-tools/``n"
$utilsReadmeContent += "- **Docs/** -> `development/tools/documentation-tools/``n"
$utilsReadmeContent += "- **ErrorHandling/** -> `development/tools/error-handling-tools/``n"
$utilsReadmeContent += "- **Examples/** -> `development/tools/examples-tools/``n"
$utilsReadmeContent += "- **git/** -> `development/tools/git-tools/``n"
$utilsReadmeContent += "- **Integrations/** -> `development/tools/integrations-tools/``n"
$utilsReadmeContent += "- **json/** -> `development/tools/json-tools/``n"
$utilsReadmeContent += "- **markdown/** -> `development/tools/markdown-tools/``n"
$utilsReadmeContent += "- **ProactiveOptimization/** -> `development/tools/optimization-tools/``n"
$utilsReadmeContent += "- **PSCacheManager/** -> `development/tools/cache-tools/``n"
$utilsReadmeContent += "- **roadmap/** -> `development/tools/roadmap-tools/``n"
$utilsReadmeContent += "- **samples/** -> `development/tools/examples-tools/``n"
$utilsReadmeContent += "- **TestOmnibus/** -> `development/tools/testing-tools/``n"
$utilsReadmeContent += "- **TestOmnibusOptimizer/** -> `development/tools/testing-tools/``n"
$utilsReadmeContent += "- **Tests/** -> `development/tools/testing-tools/``n"
$utilsReadmeContent += "- **UsageMonitor/** -> `development/tools/utilities-tools/``n"
$utilsReadmeContent += "- **utils/** -> `development/tools/utilities-tools/``n"

Set-Content -Path $utilsReadmePath -Value $utilsReadmeContent -Force
Write-Host "  Fichier README.md créé : $utilsReadmePath" -ForegroundColor Green

Write-Host "`nRéorganisation des dossiers terminée !" -ForegroundColor Cyan

