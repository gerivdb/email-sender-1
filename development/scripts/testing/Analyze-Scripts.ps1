<#
.SYNOPSIS
    Analyse des scripts du projet
.DESCRIPTION
    Ce script analyse les rÃƒÂ©sultats de l'inventaire des scripts et propose
    une organisation basÃƒÂ©e sur leur contenu et leur fonction.
.PARAMETER InventoryPath
    Chemin du fichier d'inventaire (par dÃƒÂ©faut : ..\D)
.PARAMETER OutputPath
    Chemin du fichier de sortie (par dÃƒÂ©faut : ..\D)
.PARAMETER Verbose
    Affiche des informations dÃƒÂ©taillÃƒÂ©es
.EXAMPLE
    .\Analyze-Scripts.ps1
    Analyse les scripts ÃƒÂ  partir du fichier d'inventaire par dÃƒÂ©faut
.EXAMPLE
    .\Analyze-Scripts.ps1 -InventoryPath custom-inventory.json -OutputPath custom-analysis.json
    Analyse les scripts ÃƒÂ  partir d'un fichier d'inventaire personnalisÃƒÂ©

<#
.SYNOPSIS
    Analyse des scripts du projet
.DESCRIPTION
    Ce script analyse les rÃƒÂ©sultats de l'inventaire des scripts et propose
    une organisation basÃƒÂ©e sur leur contenu et leur fonction.
.PARAMETER InventoryPath
    Chemin du fichier d'inventaire (par dÃƒÂ©faut : ..\D)
.PARAMETER OutputPath
    Chemin du fichier de sortie (par dÃƒÂ©faut : ..\D)
.PARAMETER Verbose
    Affiche des informations dÃƒÂ©taillÃƒÂ©es
.EXAMPLE
    .\Analyze-Scripts.ps1
    Analyse les scripts ÃƒÂ  partir du fichier d'inventaire par dÃƒÂ©faut
.EXAMPLE
    .\Analyze-Scripts.ps1 -InventoryPath custom-inventory.json -OutputPath custom-analysis.json
    Analyse les scripts ÃƒÂ  partir d'un fichier d'inventaire personnalisÃƒÂ©
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
    
    # Ãƒâ€°crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃƒÂ©er le rÃƒÂ©pertoire de logs si nÃƒÂ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'ÃƒÂ©criture dans le journal
    }
}
try {
    # Script principal


# CrÃƒÂ©er le dossier de sortie s'il n'existe pas
$OutputDir = Split-Path -Path $OutputPath -Parent
if (-not (Test-Path -Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    Write-Host "Dossier crÃƒÂ©ÃƒÂ©: $OutputDir" -ForegroundColor Green
}

# Fonction pour dÃƒÂ©terminer la catÃƒÂ©gorie d'un script en fonction de son contenu et de son chemin
function Get-ScriptCategory {
    param (
        [string]$Path,
        [string]$Content,
        [string]$ScriptType
    )

    # DÃƒÂ©finir les catÃƒÂ©gories et les mots-clÃƒÂ©s associÃƒÂ©s
    $Categories = @{
        "Maintenance" = @("maintenance", "cleanup", "fix", "repair", "update", "clean", "remove", "delete")
        "Setup" = @("setup", "install", "configure", "config", "installation", "configuration")
        "Workflow" = @("workflow", "process", "flow", "pipeline", "automation")
        "Utils" = @("util", "utility", "helper", "tool", "fonction", "function")
        "API" = @("api", "rest", "http", "endpoint", "request", "response")
        "Documentation" = @("doc", "documentation", "readme", "guide", "manuel", "manual")
        "Roadmap" = @("roadmap", "plan", "task", "tÃƒÂ¢che", "planning")
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

    # Initialiser le score pour chaque catÃƒÂ©gorie
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

    # DÃƒÂ©terminer la catÃƒÂ©gorie avec le score le plus ÃƒÂ©levÃƒÂ©
    $BestCategory = $CategoryScores.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1

    # Si aucune catÃƒÂ©gorie n'a de score, utiliser "Divers"
    if ($BestCategory.Value -eq 0) {
        return "Divers"
    }

    return $BestCategory.Name
}

# Fonction pour dÃƒÂ©terminer la sous-catÃƒÂ©gorie d'un script en fonction de son contenu et de son chemin
function Get-ScriptSubCategory {
    param (
        [string]$Category,
        [string]$Path,
        [string]$Content,
        [string]$ScriptType
    )

    # DÃƒÂ©finir les sous-catÃƒÂ©gories pour chaque catÃƒÂ©gorie
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

    # Si la catÃƒÂ©gorie n'a pas de sous-catÃƒÂ©gories dÃƒÂ©finies, retourner "General"
    if (-not $SubCategories.ContainsKey($Category)) {
        return "General"
    }

    # Initialiser le score pour chaque sous-catÃƒÂ©gorie
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

    # DÃƒÂ©terminer la sous-catÃƒÂ©gorie avec le score le plus ÃƒÂ©levÃƒÂ©
    $BestSubCategory = $SubCategoryScores.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1

    # Si aucune sous-catÃƒÂ©gorie n'a de score, utiliser "General"
    if ($BestSubCategory.Value -eq 0) {
        return "General"
    }

    return $BestSubCategory.Name
}

# Fonction pour dÃƒÂ©terminer le dossier cible pour un script
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

# Afficher la banniÃƒÂ¨re
Write-Host "=== Analyse des scripts ===" -ForegroundColor Cyan
Write-Host "Fichier d'inventaire: $InventoryPath" -ForegroundColor Yellow
Write-Host "Fichier de sortie: $OutputPath" -ForegroundColor Yellow
Write-Host ""

# VÃƒÂ©rifier si le fichier d'inventaire existe
if (-not (Test-Path -Path $InventoryPath)) {
    Write-Host "Fichier d'inventaire non trouvÃƒÂ©: $InventoryPath" -ForegroundColor Red
    exit 1
}

# Charger l'inventaire
$Inventory = Get-Content -Path $InventoryPath -Raw | ConvertFrom-Json

Write-Host "Nombre de scripts ÃƒÂ  analyser: $($Inventory.TotalScripts)" -ForegroundColor Cyan

# CrÃƒÂ©er un tableau pour stocker les rÃƒÂ©sultats de l'analyse
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

    # DÃƒÂ©terminer la catÃƒÂ©gorie et la sous-catÃƒÂ©gorie du script
    $Category = Get-ScriptCategory -Path $Script.Path -Content $Content -ScriptType $Script.Type
    $SubCategory = Get-ScriptSubCategory -Category $Category -Path $Script.Path -Content $Content -ScriptType $Script.Type

    # DÃƒÂ©terminer le dossier cible
    $TargetFolder = Get-TargetFolder -Category $Category -SubCategory $SubCategory -ScriptType $Script.Type

    # CrÃƒÂ©er un objet avec les rÃƒÂ©sultats de l'analyse
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

# CrÃƒÂ©er un objet avec les rÃƒÂ©sultats de l'analyse
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
Write-Host "=== Analyse terminÃƒÂ©e ===" -ForegroundColor Green
Write-Host "Nombre total de scripts: $($Analysis.TotalScripts)" -ForegroundColor Cyan

# Afficher les statistiques par catÃƒÂ©gorie
Write-Host ""
Write-Host "Statistiques par catÃƒÂ©gorie:" -ForegroundColor Yellow
foreach ($CategoryStat in $Analysis.ScriptsByCategory) {
    Write-Host "- $($CategoryStat.Category): $($CategoryStat.Count) script(s)" -ForegroundColor Cyan
}

# Afficher le nombre de scripts ÃƒÂ  dÃƒÂ©placer
Write-Host ""
Write-Host "Nombre de scripts ÃƒÂ  dÃƒÂ©placer: $($Analysis.ScriptsToMove)" -ForegroundColor Magenta

Write-Host ""
Write-Host "RÃƒÂ©sultats enregistrÃƒÂ©s dans: $OutputPath" -ForegroundColor Green


}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃƒÂ©cution du script terminÃƒÂ©e."
}
