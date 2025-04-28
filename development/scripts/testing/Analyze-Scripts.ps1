<#
.SYNOPSIS
    Analyse des scripts du projet
.DESCRIPTION
    Ce script analyse les rÃ©sultats de l'inventaire des scripts et propose
    une organisation basÃ©e sur leur contenu et leur fonction.
.PARAMETER InventoryPath
    Chemin du fichier d'inventaire (par dÃ©faut : ..\D)
.PARAMETER OutputPath
    Chemin du fichier de sortie (par dÃ©faut : ..\D)
.PARAMETER Verbose
    Affiche des informations dÃ©taillÃ©es
.EXAMPLE
    .\Analyze-Scripts.ps1
    Analyse les scripts Ã  partir du fichier d'inventaire par dÃ©faut
.EXAMPLE
    .\Analyze-Scripts.ps1 -InventoryPath custom-inventory.json -OutputPath custom-analysis.json
    Analyse les scripts Ã  partir d'un fichier d'inventaire personnalisÃ©

<#
.SYNOPSIS
    Analyse des scripts du projet
.DESCRIPTION
    Ce script analyse les rÃ©sultats de l'inventaire des scripts et propose
    une organisation basÃ©e sur leur contenu et leur fonction.
.PARAMETER InventoryPath
    Chemin du fichier d'inventaire (par dÃ©faut : ..\D)
.PARAMETER OutputPath
    Chemin du fichier de sortie (par dÃ©faut : ..\D)
.PARAMETER Verbose
    Affiche des informations dÃ©taillÃ©es
.EXAMPLE
    .\Analyze-Scripts.ps1
    Analyse les scripts Ã  partir du fichier d'inventaire par dÃ©faut
.EXAMPLE
    .\Analyze-Scripts.ps1 -InventoryPath custom-inventory.json -OutputPath custom-analysis.json
    Analyse les scripts Ã  partir d'un fichier d'inventaire personnalisÃ©
#>

param (
    [string]$InventoryPath = "..\D",
    [string]$OutputPath = "..\D"
)

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal


# CrÃ©er le dossier de sortie s'il n'existe pas
$OutputDir = Split-Path -Path $OutputPath -Parent
if (-not (Test-Path -Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    Write-Host "Dossier crÃ©Ã©: $OutputDir" -ForegroundColor Green
}

# Fonction pour dÃ©terminer la catÃ©gorie d'un script en fonction de son contenu et de son chemin
function Get-ScriptCategory {
    param (
        [string]$Path,
        [string]$Content,
        [string]$ScriptType
    )

    # DÃ©finir les catÃ©gories et les mots-clÃ©s associÃ©s
    $Categories = @{
        "Maintenance" = @("maintenance", "cleanup", "fix", "repair", "update", "clean", "remove", "delete")
        "Setup" = @("setup", "install", "configure", "config", "installation", "configuration")
        "Workflow" = @("workflow", "process", "flow", "pipeline", "automation")
        "Utils" = @("util", "utility", "helper", "tool", "fonction", "function")
        "API" = @("api", "rest", "http", "endpoint", "request", "response")
        "Documentation" = @("doc", "documentation", "readme", "guide", "manuel", "manual")
        "Roadmap" = @("roadmap", "plan", "task", "tÃ¢che", "planning")
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

    # Initialiser le score pour chaque catÃ©gorie
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

    # DÃ©terminer la catÃ©gorie avec le score le plus Ã©levÃ©
    $BestCategory = $CategoryScores.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1

    # Si aucune catÃ©gorie n'a de score, utiliser "Divers"
    if ($BestCategory.Value -eq 0) {
        return "Divers"
    }

    return $BestCategory.Name
}

# Fonction pour dÃ©terminer la sous-catÃ©gorie d'un script en fonction de son contenu et de son chemin
function Get-ScriptSubCategory {
    param (
        [string]$Category,
        [string]$Path,
        [string]$Content,
        [string]$ScriptType
    )

    # DÃ©finir les sous-catÃ©gories pour chaque catÃ©gorie
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

    # Si la catÃ©gorie n'a pas de sous-catÃ©gories dÃ©finies, retourner "General"
    if (-not $SubCategories.ContainsKey($Category)) {
        return "General"
    }

    # Initialiser le score pour chaque sous-catÃ©gorie
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

    # DÃ©terminer la sous-catÃ©gorie avec le score le plus Ã©levÃ©
    $BestSubCategory = $SubCategoryScores.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1

    # Si aucune sous-catÃ©gorie n'a de score, utiliser "General"
    if ($BestSubCategory.Value -eq 0) {
        return "General"
    }

    return $BestSubCategory.Name
}

# Fonction pour dÃ©terminer le dossier cible pour un script
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
        return "development/scripts/$TypeFolder$($Category.ToLower())"
    } else {
        return "development/scripts/$TypeFolder$($Category.ToLower())/$($SubCategory.ToLower())"
    }
}

# Afficher la banniÃ¨re
Write-Host "=== Analyse des scripts ===" -ForegroundColor Cyan
Write-Host "Fichier d'inventaire: $InventoryPath" -ForegroundColor Yellow
Write-Host "Fichier de sortie: $OutputPath" -ForegroundColor Yellow
Write-Host ""

# VÃ©rifier si le fichier d'inventaire existe
if (-not (Test-Path -Path $InventoryPath)) {
    Write-Host "Fichier d'inventaire non trouvÃ©: $InventoryPath" -ForegroundColor Red
    exit 1
}

# Charger l'inventaire
$Inventory = Get-Content -Path $InventoryPath -Raw | ConvertFrom-Json

Write-Host "Nombre de scripts Ã  analyser: $($Inventory.TotalScripts)" -ForegroundColor Cyan

# CrÃ©er un tableau pour stocker les rÃ©sultats de l'analyse
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

    # DÃ©terminer la catÃ©gorie et la sous-catÃ©gorie du script
    $Category = Get-ScriptCategory -Path $Script.Path -Content $Content -ScriptType $Script.Type
    $SubCategory = Get-ScriptSubCategory -Category $Category -Path $Script.Path -Content $Content -ScriptType $Script.Type

    # DÃ©terminer le dossier cible
    $TargetFolder = Get-TargetFolder -Category $Category -SubCategory $SubCategory -ScriptType $Script.Type

    # CrÃ©er un objet avec les rÃ©sultats de l'analyse
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

# CrÃ©er un objet avec les rÃ©sultats de l'analyse
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
Write-Host "=== Analyse terminÃ©e ===" -ForegroundColor Green
Write-Host "Nombre total de scripts: $($Analysis.TotalScripts)" -ForegroundColor Cyan

# Afficher les statistiques par catÃ©gorie
Write-Host ""
Write-Host "Statistiques par catÃ©gorie:" -ForegroundColor Yellow
foreach ($CategoryStat in $Analysis.ScriptsByCategory) {
    Write-Host "- $($CategoryStat.Category): $($CategoryStat.Count) script(s)" -ForegroundColor Cyan
}

# Afficher le nombre de scripts Ã  dÃ©placer
Write-Host ""
Write-Host "Nombre de scripts Ã  dÃ©placer: $($Analysis.ScriptsToMove)" -ForegroundColor Magenta

Write-Host ""
Write-Host "RÃ©sultats enregistrÃ©s dans: $OutputPath" -ForegroundColor Green


}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
