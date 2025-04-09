<#
.SYNOPSIS
    Analyse des scripts du projet
.DESCRIPTION
    Ce script analyse les résultats de l'inventaire des scripts et propose
    une organisation basée sur leur contenu et leur fonction.
.PARAMETER InventoryPath
    Chemin du fichier d'inventaire (par défaut : ..\D)
.PARAMETER OutputPath
    Chemin du fichier de sortie (par défaut : ..\D)
.PARAMETER Verbose
    Affiche des informations détaillées
.EXAMPLE
    .\Analyze-Scripts.ps1
    Analyse les scripts à partir du fichier d'inventaire par défaut
.EXAMPLE
    .\Analyze-Scripts.ps1 -InventoryPath custom-inventory.json -OutputPath custom-analysis.json
    Analyse les scripts à partir d'un fichier d'inventaire personnalisé
#>

param (
    [string]$InventoryPath = "..\D",
    [string]$OutputPath = "..\D"
)

# Créer le dossier de sortie s'il n'existe pas
$OutputDir = Split-Path -Path $OutputPath -Parent
if (-not (Test-Path -Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    Write-Host "Dossier créé: $OutputDir" -ForegroundColor Green
}

# Fonction pour déterminer la catégorie d'un script en fonction de son contenu et de son chemin
function Get-ScriptCategory {
    param (
        [string]$Path,
        [string]$Content,
        [string]$ScriptType
    )

    # Définir les catégories et les mots-clés associés
    $Categories = @{
        "Maintenance" = @("maintenance", "cleanup", "fix", "repair", "update", "clean", "remove", "delete")
        "Setup" = @("setup", "install", "configure", "config", "installation", "configuration")
        "Workflow" = @("workflow", "process", "flow", "pipeline", "automation")
        "Utils" = @("util", "utility", "helper", "tool", "fonction", "function")
        "API" = @("api", "rest", "http", "endpoint", "request", "response")
        "Documentation" = @("doc", "documentation", "readme", "guide", "manuel", "manual")
        "Roadmap" = @("roadmap", "plan", "task", "tâche", "planning")
        "Journal" = @("journal", "log", "entry", "rag", "rapport", "report")
        "MCP" = @("mcp", "model", "context", "protocol", "modelcontextprotocol")
        "N8N" = @("n8n", "workflow", "node", "nodered")
        "Git" = @("git", "commit", "push", "pull", "merge", "branch", "hook")
        "Encoding" = @("encoding", "charset", "utf", "bom", "encodage")
        "Email" = @("email", "mail", "smtp", "imap", "message", "courriel")
        "Testing" = @("test", "testing", "unittest", "pytest", "assert", "validation")
        "Security" = @("security", "secure", "auth", "authentication", "authorization")
        "Database" = @("database", "db", "sql", "query", "base de donnees")
    }

    # Initialiser le score pour chaque catégorie
    $CategoryScores = @{}
    foreach ($Category in $Categories.Keys) {
        $CategoryScores[$Category] = 0
    }

    # Analyser le chemin du script
    foreach ($Category in $Categories.Keys) {
        foreach ($Keyword in $Categories[$Category]) {
            if ($Path -match $Keyword) {
                $CategoryScores[$Category] += 2
            }
        }
    }

    # Analyser le contenu du script
    if ($Content) {
        foreach ($Category in $Categories.Keys) {
            foreach ($Keyword in $Categories[$Category]) {
                $RegexMatches = [regex]::Matches($Content, $Keyword, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                $CategoryScores[$Category] += $RegexMatches.Count
            }
        }
    }

    # Déterminer la catégorie avec le score le plus élevé
    $BestCategory = $CategoryScores.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1

    # Si aucune catégorie n'a de score, utiliser "Divers"
    if ($BestCategory.Value -eq 0) {
        return "Divers"
    }

    return $BestCategory.Name
}

# Fonction pour déterminer la sous-catégorie d'un script en fonction de son contenu et de son chemin
function Get-ScriptSubCategory {
    param (
        [string]$Category,
        [string]$Path,
        [string]$Content,
        [string]$ScriptType
    )

    # Définir les sous-catégories pour chaque catégorie
    $SubCategories = @{
        "Maintenance" = @{
            "Repository" = @("repo", "repository", "git", "organize")
            "Encoding" = @("encoding", "charset", "utf", "bom")
            "Cleanup" = @("cleanup", "clean", "remove", "delete")
        }
        "Setup" = @{
            "MCP" = @("mcp", "model", "context", "protocol")
            "Environment" = @("env", "environment", "path", "variable")
            "Dependencies" = @("dependency", "dependencies", "package", "module")
        }
        "Workflow" = @{
            "Validation" = @("validation", "validate", "check", "verify")
            "Testing" = @("test", "testing", "simulate")
            "Monitoring" = @("monitor", "monitoring", "watch")
        }
        "Utils" = @{
            "Markdown" = @("markdown", "md")
            "JSON" = @("json")
            "XML" = @("xml")
            "HTML" = @("html")
            "Automation" = @("auto", "automation", "batch")
        }
        "API" = @{
            "N8N" = @("n8n")
            "Google" = @("google", "gmail", "gdrive")
            "REST" = @("rest", "http", "endpoint")
        }
    }

    # Si la catégorie n'a pas de sous-catégories définies, retourner "General"
    if (-not $SubCategories.ContainsKey($Category)) {
        return "General"
    }

    # Initialiser le score pour chaque sous-catégorie
    $SubCategoryScores = @{}
    foreach ($SubCategory in $SubCategories[$Category].Keys) {
        $SubCategoryScores[$SubCategory] = 0
    }

    # Analyser le chemin du script
    foreach ($SubCategory in $SubCategories[$Category].Keys) {
        foreach ($Keyword in $SubCategories[$Category][$SubCategory]) {
            if ($Path -match $Keyword) {
                $SubCategoryScores[$SubCategory] += 2
            }
        }
    }

    # Analyser le contenu du script
    if ($Content) {
        foreach ($SubCategory in $SubCategories[$Category].Keys) {
            foreach ($Keyword in $SubCategories[$Category][$SubCategory]) {
                $RegexMatches = [regex]::Matches($Content, $Keyword, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                $SubCategoryScores[$SubCategory] += $RegexMatches.Count
            }
        }
    }

    # Déterminer la sous-catégorie avec le score le plus élevé
    $BestSubCategory = $SubCategoryScores.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1

    # Si aucune sous-catégorie n'a de score, utiliser "General"
    if ($BestSubCategory.Value -eq 0) {
        return "General"
    }

    return $BestSubCategory.Name
}

# Fonction pour déterminer le dossier cible pour un script
function Get-TargetFolder {
    param (
        [string]$Category,
        [string]$SubCategory,
        [string]$ScriptType
    )

    $TypeFolder = switch ($ScriptType) {
        "PowerShell" { "" }
        "Python" { "python/" }
        "Batch" { "batch/" }
        "Shell" { "shell/" }
        default { "" }
    }

    if ($SubCategory -eq "General") {
        return "scripts/$TypeFolder$($Category.ToLower())"
    } else {
        return "scripts/$TypeFolder$($Category.ToLower())/$($SubCategory.ToLower())"
    }
}

# Afficher la bannière
Write-Host "=== Analyse des scripts ===" -ForegroundColor Cyan
Write-Host "Fichier d'inventaire: $InventoryPath" -ForegroundColor Yellow
Write-Host "Fichier de sortie: $OutputPath" -ForegroundColor Yellow
Write-Host ""

# Vérifier si le fichier d'inventaire existe
if (-not (Test-Path -Path $InventoryPath)) {
    Write-Host "Fichier d'inventaire non trouvé: $InventoryPath" -ForegroundColor Red
    exit 1
}

# Charger l'inventaire
$Inventory = Get-Content -Path $InventoryPath -Raw | ConvertFrom-Json

Write-Host "Nombre de scripts à analyser: $($Inventory.TotalScripts)" -ForegroundColor Cyan

# Créer un tableau pour stocker les résultats de l'analyse
$AnalysisResults = @()

# Traiter chaque script
$Counter = 0
$Total = $Inventory.Scripts.Count

foreach ($Script in $Inventory.Scripts) {
    $Counter++
    $Progress = [math]::Round(($Counter / $Total) * 100)
    Write-Progress -Activity "Analyse des scripts" -Status "$Counter / $Total ($Progress%)" -PercentComplete $Progress

    # Lire le contenu du script
    $Content = Get-Content -Path $Script.Path -Raw -ErrorAction SilentlyContinue

    # Déterminer la catégorie et la sous-catégorie du script
    $Category = Get-ScriptCategory -Path $Script.Path -Content $Content -ScriptType $Script.Type
    $SubCategory = Get-ScriptSubCategory -Category $Category -Path $Script.Path -Content $Content -ScriptType $Script.Type

    # Déterminer le dossier cible
    $TargetFolder = Get-TargetFolder -Category $Category -SubCategory $SubCategory -ScriptType $Script.Type

    # Créer un objet avec les résultats de l'analyse
    $AnalysisResult = [PSCustomObject]@{
        Path = $Script.Path
        Name = $Script.Name
        Type = $Script.Type
        Category = $Category
        SubCategory = $SubCategory
        TargetFolder = $TargetFolder
        CurrentFolder = Split-Path -Path $Script.Path -Parent
        NeedsMove = (Split-Path -Path $Script.Path -Parent) -ne $TargetFolder
    }

    # Ajouter l'objet au tableau
    $AnalysisResults += $AnalysisResult
}

Write-Progress -Activity "Analyse des scripts" -Completed

# Créer un objet avec les résultats de l'analyse
$Analysis = [PSCustomObject]@{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TotalScripts = $AnalysisResults.Count
    ScriptsByCategory = $AnalysisResults | Group-Object -Property Category | ForEach-Object {
        [PSCustomObject]@{
            Category = $_.Name
            Count = $_.Count
        }
    }
    ScriptsBySubCategory = $AnalysisResults | Group-Object -Property Category, SubCategory | ForEach-Object {
        $CategoryParts = $_.Name -split ", "
        [PSCustomObject]@{
            Category = $CategoryParts[0]
            SubCategory = $CategoryParts[1]
            Count = $_.Count
        }
    }
    ScriptsToMove = $AnalysisResults | Where-Object { $_.NeedsMove } | Measure-Object | Select-Object -ExpandProperty Count
    Scripts = $AnalysisResults
}

# Convertir l'objet en JSON et l'enregistrer dans un fichier
$Analysis | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath

Write-Host ""
Write-Host "=== Analyse terminée ===" -ForegroundColor Green
Write-Host "Nombre total de scripts: $($Analysis.TotalScripts)" -ForegroundColor Cyan

# Afficher les statistiques par catégorie
Write-Host ""
Write-Host "Statistiques par catégorie:" -ForegroundColor Yellow
foreach ($CategoryStat in $Analysis.ScriptsByCategory) {
    Write-Host "- $($CategoryStat.Category): $($CategoryStat.Count) script(s)" -ForegroundColor Cyan
}

# Afficher le nombre de scripts à déplacer
Write-Host ""
Write-Host "Nombre de scripts à déplacer: $($Analysis.ScriptsToMove)" -ForegroundColor Magenta

Write-Host ""
Write-Host "Résultats enregistrés dans: $OutputPath" -ForegroundColor Green

