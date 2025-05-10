# Example-QueryParser.ps1
# Script d'exemple pour montrer comment utiliser le parser du langage de requête personnalisé
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$QueryString = "status:todo AND priority:high",
    
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Console", "Grid", "HTML", "JSON")]
    [string]$OutputFormat = "Console",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Info", "Debug", "None")]
    [string]$LogLevel = "Info",
    
    [Parameter(Mandatory = $false)]
    [switch]$ShowTokens,
    
    [Parameter(Mandatory = $false)]
    [switch]$ShowAST,
    
    [Parameter(Mandatory = $false)]
    [switch]$ShowFilterFunction
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$rootPath = Split-Path -Parent $parentPath
$utilsPath = Join-Path -Path (Split-Path -Parent $rootPath) -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        if ($LogLevel -eq "None") {
            return
        }
        
        $logLevels = @{
            "Error" = 0
            "Warning" = 1
            "Info" = 2
            "Debug" = 3
        }
        
        if ($logLevels[$Level] -le $logLevels[$LogLevel]) {
            $color = switch ($Level) {
                "Error" { "Red" }
                "Warning" { "Yellow" }
                "Info" { "White" }
                "Debug" { "Gray" }
                default { "White" }
            }
            
            Write-Host "[$Level] $Message" -ForegroundColor $color
        }
    }
}

# Importer le parser
$parserPath = Join-Path -Path $scriptPath -ChildPath "Parse-QueryLanguage.ps1"
if (-not (Test-Path -Path $parserPath)) {
    Write-Log "Parser script not found at: $parserPath" -Level "Error"
    exit 1
}

. $parserPath

# Fonction pour charger les données de la roadmap
function Get-RoadmapData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$RoadmapPath
    )
    
    if ([string]::IsNullOrEmpty($RoadmapPath)) {
        # Si aucun chemin n'est spécifié, utiliser des données d'exemple
        Write-Log "No roadmap path specified, using sample data" -Level "Info"
        
        return @(
            [PSCustomObject]@{
                id = "1.1"
                title = "Implement user interface"
                status = "todo"
                priority = "high"
                category = "development"
                due_date = "2025-06-30"
                assignee = "john"
                description = "Create the main user interface components"
                has_children = $true
                indent_level = 1
            },
            [PSCustomObject]@{
                id = "1.1.1"
                title = "Design login screen"
                status = "in_progress"
                priority = "medium"
                category = "design"
                due_date = "2025-06-15"
                assignee = "jane"
                description = "Create mockups for the login screen"
                has_children = $false
                indent_level = 2
            },
            [PSCustomObject]@{
                id = "1.1.2"
                title = "Implement authentication module"
                status = "todo"
                priority = "high"
                category = "development"
                due_date = "2025-06-20"
                assignee = "john"
                description = "Implement the authentication logic"
                has_children = $false
                indent_level = 2
            },
            [PSCustomObject]@{
                id = "1.2"
                title = "Create API documentation"
                status = "done"
                priority = "low"
                category = "documentation"
                due_date = "2025-05-30"
                assignee = "jane"
                description = "Document the REST API endpoints"
                has_children = $false
                indent_level = 1
            },
            [PSCustomObject]@{
                id = "1.3"
                title = "Implement database layer"
                status = "blocked"
                priority = "high"
                category = "development"
                due_date = "2025-07-15"
                assignee = $null
                description = "Create the database access layer"
                has_children = $true
                indent_level = 1
                has_blockers = $true
            },
            [PSCustomObject]@{
                id = "1.3.1"
                title = "Design database schema"
                status = "todo"
                priority = "high"
                category = "design"
                due_date = "2025-07-01"
                assignee = "john"
                description = "Create the database schema design"
                has_children = $false
                indent_level = 2
            }
        )
    } else {
        # Charger les données depuis le fichier de roadmap
        if (-not (Test-Path -Path $RoadmapPath)) {
            Write-Log "Roadmap file not found at: $RoadmapPath" -Level "Error"
            exit 1
        }
        
        Write-Log "Loading roadmap data from: $RoadmapPath" -Level "Info"
        
        # Déterminer le type de fichier et le charger en conséquence
        $extension = [System.IO.Path]::GetExtension($RoadmapPath).ToLower()
        
        switch ($extension) {
            ".json" {
                try {
                    $data = Get-Content -Path $RoadmapPath -Raw | ConvertFrom-Json
                    return $data
                } catch {
                    Write-Log "Error loading JSON roadmap data: $_" -Level "Error"
                    exit 1
                }
            }
            ".md" {
                # Implémenter le chargement depuis Markdown
                Write-Log "Loading from Markdown is not yet implemented" -Level "Warning"
                return $null
            }
            default {
                Write-Log "Unsupported roadmap file format: $extension" -Level "Error"
                exit 1
            }
        }
    }
}

# Fonction pour afficher les résultats
function Show-QueryResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Results,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputFormat,
        
        [Parameter(Mandatory = $false)]
        [string]$QueryString
    )
    
    Write-Log "Displaying $($Results.Count) results" -Level "Info"
    
    switch ($OutputFormat) {
        "Console" {
            Write-Host "`nQuery: $QueryString`n" -ForegroundColor Cyan
            Write-Host "Results: $($Results.Count) items found`n" -ForegroundColor Cyan
            
            foreach ($item in $Results) {
                $indent = "  " * ($item.indent_level - 1)
                $statusColor = switch ($item.status) {
                    "todo" { "Yellow" }
                    "in_progress" { "Cyan" }
                    "done" { "Green" }
                    "blocked" { "Red" }
                    default { "White" }
                }
                
                $prioritySymbol = switch ($item.priority) {
                    "high" { "⚠️ " }
                    "medium" { "⚡ " }
                    "low" { "✓ " }
                    default { "  " }
                }
                
                Write-Host "$indent$($item.id) $prioritySymbol$($item.title)" -ForegroundColor White
                Write-Host "$indent  Status: " -NoNewline
                Write-Host "$($item.status)" -ForegroundColor $statusColor
                
                if ($item.assignee) {
                    Write-Host "$indent  Assignee: $($item.assignee)" -ForegroundColor Gray
                }
                
                if ($item.due_date) {
                    Write-Host "$indent  Due: $($item.due_date)" -ForegroundColor Gray
                }
                
                Write-Host ""
            }
        }
        "Grid" {
            $Results | Select-Object id, title, status, priority, category, due_date, assignee | Out-GridView -Title "Query Results: $QueryString"
        }
        "HTML" {
            $htmlPath = Join-Path -Path $scriptPath -ChildPath "QueryResults.html"
            
            $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Query Results</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2 {
            color: #2c3e50;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        .query {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
            font-family: monospace;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f8f9fa;
            font-weight: bold;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        .todo { color: #f39c12; }
        .in_progress { color: #3498db; }
        .done { color: #27ae60; }
        .blocked { color: #e74c3c; }
        .high { font-weight: bold; color: #e74c3c; }
        .medium { font-weight: bold; color: #f39c12; }
        .low { color: #27ae60; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Query Results</h1>
        
        <div class="query">
            <h2>Query</h2>
            <code>$QueryString</code>
            <p>Found $($Results.Count) results</p>
        </div>
        
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Title</th>
                    <th>Status</th>
                    <th>Priority</th>
                    <th>Category</th>
                    <th>Due Date</th>
                    <th>Assignee</th>
                </tr>
            </thead>
            <tbody>
"@

            foreach ($item in $Results) {
                $html += @"
                <tr>
                    <td>$($item.id)</td>
                    <td>$($item.title)</td>
                    <td class="$($item.status)">$($item.status)</td>
                    <td class="$($item.priority)">$($item.priority)</td>
                    <td>$($item.category)</td>
                    <td>$($item.due_date)</td>
                    <td>$($item.assignee)</td>
                </tr>
"@
            }

            $html += @"
            </tbody>
        </table>
    </div>
</body>
</html>
"@

            $html | Out-File -FilePath $htmlPath -Encoding UTF8
            
            Write-Log "HTML results saved to: $htmlPath" -Level "Info"
            Start-Process $htmlPath
        }
        "JSON" {
            $jsonPath = Join-Path -Path $scriptPath -ChildPath "QueryResults.json"
            $Results | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding UTF8
            Write-Log "JSON results saved to: $jsonPath" -Level "Info"
        }
    }
}

# Fonction principale
function Invoke-QueryExample {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QueryString,
        
        [Parameter(Mandatory = $false)]
        [string]$RoadmapPath,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputFormat,
        
        [Parameter(Mandatory = $false)]
        [switch]$ShowTokens,
        
        [Parameter(Mandatory = $false)]
        [switch]$ShowAST,
        
        [Parameter(Mandatory = $false)]
        [switch]$ShowFilterFunction
    )
    
    Write-Log "Processing query: $QueryString" -Level "Info"
    
    try {
        # Analyser la requête
        $parseResult = Parse-Query -QueryString $QueryString
        
        # Afficher les tokens si demandé
        if ($ShowTokens) {
            Write-Host "`nTokens:" -ForegroundColor Cyan
            foreach ($token in $parseResult.Tokens) {
                Write-Host $token.ToString()
            }
            Write-Host ""
        }
        
        # Afficher l'AST si demandé
        if ($ShowAST) {
            Write-Host "`nAbstract Syntax Tree:" -ForegroundColor Cyan
            Write-Host $parseResult.AST.ToString()
            Write-Host ""
        }
        
        # Afficher la fonction de filtre si demandé
        if ($ShowFilterFunction) {
            Write-Host "`nFilter Function:" -ForegroundColor Cyan
            Write-Host $parseResult.FilterFunction.ToString()
            Write-Host ""
        }
        
        # Charger les données de la roadmap
        $roadmapData = Get-RoadmapData -RoadmapPath $RoadmapPath
        
        if ($null -eq $roadmapData) {
            Write-Log "No roadmap data available" -Level "Error"
            return
        }
        
        # Appliquer le filtre
        $filteredResults = $roadmapData | Where-Object { & $parseResult.FilterFunction $_ }
        
        # Afficher les résultats
        Show-QueryResults -Results $filteredResults -OutputFormat $OutputFormat -QueryString $QueryString
        
        return $filteredResults
        
    } catch {
        Write-Log "Error processing query: $_" -Level "Error"
        throw $_
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Invoke-QueryExample -QueryString $QueryString -RoadmapPath $RoadmapPath -OutputFormat $OutputFormat -ShowTokens:$ShowTokens -ShowAST:$ShowAST -ShowFilterFunction:$ShowFilterFunction
}
