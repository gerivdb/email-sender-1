<#
.SYNOPSIS
    Réorganise les scripts de roadmap-parser dans une nouvelle structure de dossiers.

.DESCRIPTION
    Ce script déplace les fichiers existants dans le dossier scripts/roadmap-parser vers la nouvelle structure
    de dossiers organisée par catégories et sous-catégories.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

# Créer la structure de dossiers
$basePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\roadmap-parser"

# Catégories principales
$categories = @("core", "modes", "analysis", "utils", "tests", "docs")

# Sous-catégories
$subcategories = @{
    "core" = @("parser", "model", "converter", "structure")
    "modes" = @("debug", "test", "archi", "check", "gran", "dev-r", "review", "opti")
    "analysis" = @("dependencies", "performance", "validation", "reporting")
    "utils" = @("encoding", "export", "import", "helpers")
    "tests" = @("unit", "integration", "performance", "validation")
    "docs" = @("examples", "guides", "api")
}

# Créer les dossiers
foreach ($category in $categories) {
    $categoryPath = Join-Path -Path $basePath -ChildPath $category
    
    if (-not (Test-Path -Path $categoryPath)) {
        New-Item -Path $categoryPath -ItemType Directory -Force | Out-Null
        Write-Host "Dossier créé : $categoryPath"
    }
    
    foreach ($subcategory in $subcategories[$category]) {
        $subcategoryPath = Join-Path -Path $categoryPath -ChildPath $subcategory
        
        if (-not (Test-Path -Path $subcategoryPath)) {
            New-Item -Path $subcategoryPath -ItemType Directory -Force | Out-Null
            Write-Host "Dossier créé : $subcategoryPath"
        }
    }
}

# Définir les mappages de fichiers vers les nouveaux emplacements
$fileMappings = @{
    # Modes
    "archi-mode.ps1" = "modes/archi/archi-mode.ps1"
    "debug-mode.ps1" = "modes/debug/debug-mode.ps1"
    "test-mode.ps1" = "modes/test/test-mode.ps1"
    
    # Core - Parser
    "RoadmapParser.ps1" = "core/parser/RoadmapParser.ps1"
    "RoadmapParser.psd1" = "core/parser/RoadmapParser.psd1"
    "RoadmapParser.psm1" = "core/parser/RoadmapParser.psm1"
    "RoadmapParser3.ps1" = "core/parser/RoadmapParser3.ps1"
    "RoadmapParser3.psd1" = "core/parser/RoadmapParser3.psd1"
    "RoadmapParser3.psm1" = "core/parser/RoadmapParser3.psm1"
    "RoadmapParser3Simple.ps1" = "core/parser/RoadmapParser3Simple.ps1"
    "RoadmapParser3Simple.psm1" = "core/parser/RoadmapParser3Simple.psm1"
    
    # Core - Model
    "RoadmapModel.psd1" = "core/model/RoadmapModel.psd1"
    "RoadmapModel.psm1" = "core/model/RoadmapModel.psm1"
    "RoadmapModel2.psd1" = "core/model/RoadmapModel2.psd1"
    "RoadmapModel2.psm1" = "core/model/RoadmapModel2.psm1"
    "SimpleModule.psm1" = "core/model/SimpleModule.psm1"
    
    # Core - Structure
    "Analyze-RoadmapStructure.ps1" = "core/structure/Analyze-RoadmapStructure.ps1"
    "Export-RoadmapStructure.ps1" = "core/structure/Export-RoadmapStructure.ps1"
    
    # Analysis - Dependencies
    "Find-Dependencies.ps1" = "analysis/dependencies/Find-Dependencies.ps1"
    
    # Analysis - Performance
    "Analyze-RoadmapFile.ps1" = "analysis/performance/Analyze-RoadmapFile.ps1"
    
    # Analysis - Reporting
    "Generate-ConventionReport.ps1" = "analysis/reporting/Generate-ConventionReport.ps1"
    "Generate-ProgressReport.ps1" = "analysis/reporting/Generate-ProgressReport.ps1"
    "Generate-RoadmapSummary.ps1" = "analysis/reporting/Generate-RoadmapSummary.ps1"
    "Run-RoadmapAnalysis.ps1" = "analysis/reporting/Run-RoadmapAnalysis.ps1"
    
    # Utils - Helpers
    "Get-ProjectSpecificSettings.ps1" = "utils/helpers/Get-ProjectSpecificSettings.ps1"
    
    # Tests - Unit
    "Test-ConvertFromMarkdown.ps1" = "tests/unit/Test-ConvertFromMarkdown.ps1"
    "Test-ExportFunctions.ps1" = "tests/unit/Test-ExportFunctions.ps1"
    "Test-MarkdownParsing.ps1" = "tests/unit/Test-MarkdownParsing.ps1"
    "Test-ProjectConventions.ps1" = "tests/unit/Test-ProjectConventions.ps1"
    "Test-RoadmapModel.ps1" = "tests/unit/Test-RoadmapModel.ps1"
    "Test-RoadmapModel2.ps1" = "tests/unit/Test-RoadmapModel2.ps1"
    "Test-RoadmapModel3.ps1" = "tests/unit/Test-RoadmapModel3.ps1"
    "Test-RoadmapModel5.ps1" = "tests/unit/Test-RoadmapModel5.ps1"
    "Test-RoadmapParser.ps1" = "tests/unit/Test-RoadmapParser.ps1"
    "Test-RoadmapParser3.ps1" = "tests/unit/Test-RoadmapParser3.ps1"
    "Test-RoadmapParser3Simple.ps1" = "tests/unit/Test-RoadmapParser3Simple.ps1"
    "Test-RoadmapStructure.ps1" = "tests/unit/Test-RoadmapStructure.ps1"
    "Test-SimpleModule.ps1" = "tests/unit/Test-SimpleModule.ps1"
    "Test-StatusMarkers.ps1" = "tests/unit/Test-StatusMarkers.ps1"
    "Test-TaskIdentifiers.ps1" = "tests/unit/Test-TaskIdentifiers.ps1"
    
    # Tests - Performance
    "Test-RoadmapModel-Dependencies.ps1" = "tests/performance/Test-RoadmapModel-Dependencies.ps1"
    "Test-RoadmapModel2-Dependencies.ps1" = "tests/performance/Test-RoadmapModel2-Dependencies.ps1"
}

# Fonction pour déplacer un fichier
function Move-FileToNewLocation {
    param (
        [string]$SourceFile,
        [string]$DestinationPath
    )
    
    $sourcePath = Join-Path -Path $basePath -ChildPath $SourceFile
    $destinationPath = Join-Path -Path $basePath -ChildPath $DestinationPath
    
    # Vérifier si le fichier source existe
    if (-not (Test-Path -Path $sourcePath)) {
        Write-Warning "Le fichier source n'existe pas : $sourcePath"
        return
    }
    
    # Créer le dossier de destination s'il n'existe pas
    $destinationDir = Split-Path -Path $destinationPath -Parent
    if (-not (Test-Path -Path $destinationDir)) {
        New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
        Write-Host "Dossier créé : $destinationDir"
    }
    
    # Déplacer le fichier
    try {
        Copy-Item -Path $sourcePath -Destination $destinationPath -Force
        Write-Host "Fichier copié : $SourceFile -> $DestinationPath"
    }
    catch {
        Write-Error "Erreur lors de la copie du fichier $SourceFile : $_"
    }
}

# Déplacer les fichiers
foreach ($file in $fileMappings.Keys) {
    Move-FileToNewLocation -SourceFile $file -DestinationPath $fileMappings[$file]
}

# Créer un README.md pour chaque sous-catégorie
foreach ($category in $categories) {
    foreach ($subcategory in $subcategories[$category]) {
        $readmePath = Join-Path -Path $basePath -ChildPath "$category\$subcategory\README.md"
        
        if (-not (Test-Path -Path $readmePath)) {
            $readmeContent = @"
# $subcategory - $category

Cette section contient les scripts liés à $subcategory dans la catégorie $category.

## Scripts disponibles

$(
    $files = $fileMappings.GetEnumerator() | Where-Object { $_.Value -like "$category/$subcategory/*" }
    $filesList = ""
    foreach ($file in $files) {
        $fileName = Split-Path -Path $file.Value -Leaf
        $filesList += "- `$fileName`n"
    }
    if (-not $filesList) {
        $filesList = "Aucun script n'est encore disponible dans cette section."
    }
    $filesList
)

## Utilisation

```powershell
# Exemple d'utilisation
.\<nom-du-script>.ps1 -InputPath "Roadmap/roadmap.md" -OutputPath "Roadmap/output.md"
```

## Dépendances

Ces scripts peuvent dépendre des modules suivants :
- `roadmap-parser` - Module principal de parsing de roadmap

## Tests

Les tests unitaires pour ces scripts se trouvent dans le dossier `tests/unit`.
"@
            
            Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
            Write-Host "README.md créé : $readmePath"
        }
    }
}

Write-Host "Réorganisation terminée. Les fichiers ont été copiés vers leurs nouveaux emplacements."
Write-Host "Vous pouvez maintenant vérifier que tout fonctionne correctement avant de supprimer les fichiers originaux."
