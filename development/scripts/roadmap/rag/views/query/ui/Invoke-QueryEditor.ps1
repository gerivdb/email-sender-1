# Invoke-QueryEditor.ps1
# Script principal pour l'interface utilisateur de saisie des requêtes
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$InitialQuery = "",
    
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath,
    
    [Parameter(Mandatory = $false)]
    [string]$SchemaPath,
    
    [Parameter(Mandatory = $false)]
    [string]$HistoryFilePath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Console", "GUI", "VSCode")]
    [string]$EditorMode = "Console",
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableSyntaxHighlighting,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableAutoCompletion,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableValidation,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Basic", "Detailed", "Semantic")]
    [string]$ValidationLevel = "Basic",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Execute", "Convert", "Save", "None")]
    [string]$Action = "Execute",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Info", "Debug", "None")]
    [string]$LogLevel = "Info"
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

# Importer les scripts nécessaires
$editQueryPath = Join-Path -Path $scriptPath -ChildPath "Edit-QueryText.ps1"
$querySuggestionsPath = Join-Path -Path $scriptPath -ChildPath "Get-QuerySuggestions.ps1"
$queryValidationPath = Join-Path -Path $scriptPath -ChildPath "Test-QueryValidation.ps1"
$parserPath = Join-Path -Path (Split-Path -Parent $parentPath) -ChildPath "parser\Parse-QueryLanguage.ps1"
$qdrantConverterPath = Join-Path -Path (Split-Path -Parent $parentPath) -ChildPath "parser\Convert-QueryToQdrant.ps1"

# Vérifier que tous les scripts nécessaires existent
$requiredScripts = @($editQueryPath, $querySuggestionsPath, $queryValidationPath, $parserPath)
foreach ($script in $requiredScripts) {
    if (-not (Test-Path -Path $script)) {
        Write-Log "Required script not found: $script" -Level "Error"
        exit 1
    }
}

# Importer les scripts
. $parserPath
. $editQueryPath
. $querySuggestionsPath
. $queryValidationPath

if (Test-Path -Path $qdrantConverterPath) {
    . $qdrantConverterPath
}

# Fonction pour exécuter la requête
function Invoke-Query {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Query,
        
        [Parameter(Mandatory = $false)]
        [string]$RoadmapPath
    )
    
    try {
        # Analyser la requête
        $parseResult = Parse-Query -QueryString $Query
        
        # Si aucun chemin de roadmap n'est spécifié, utiliser des données d'exemple
        if (-not $RoadmapPath -or -not (Test-Path -Path $RoadmapPath)) {
            Write-Log "No roadmap path specified or file not found, using sample data" -Level "Info"
            
            # Créer des données d'exemple
            $data = @(
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
                }
            )
        } else {
            # Charger les données depuis le fichier de roadmap
            $extension = [System.IO.Path]::GetExtension($RoadmapPath).ToLower()
            
            switch ($extension) {
                ".json" {
                    try {
                        $data = Get-Content -Path $RoadmapPath -Raw | ConvertFrom-Json
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
        
        # Appliquer le filtre
        $filteredResults = $data | Where-Object { & $parseResult $_ }
        
        return $filteredResults
    } catch {
        Write-Log "Error executing query: $_" -Level "Error"
        throw $_
    }
}

# Fonction pour convertir la requête en format Qdrant
function Convert-QueryToQdrantFormat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Query,
        
        [Parameter(Mandatory = $false)]
        [string]$CollectionName = "roadmap_tasks",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Object", "JSON", "Curl")]
        [string]$OutputFormat = "JSON"
    )
    
    if (-not (Test-Path -Path $qdrantConverterPath)) {
        Write-Log "Qdrant converter script not found: $qdrantConverterPath" -Level "Error"
        return $null
    }
    
    try {
        $qdrantQuery = Convert-QueryToQdrant -QueryString $Query -CollectionName $CollectionName -OutputFormat $OutputFormat
        return $qdrantQuery
    } catch {
        Write-Log "Error converting query to Qdrant format: $_" -Level "Error"
        throw $_
    }
}

# Fonction pour sauvegarder la requête
function Save-QueryToFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Query,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "JSON", "Qdrant")]
        [string]$Format = "Text"
    )
    
    try {
        switch ($Format) {
            "Text" {
                $Query | Out-File -FilePath $OutputPath -Encoding UTF8
            }
            "JSON" {
                $parseResult = Parse-Query -QueryString $Query -ReturnAST
                $json = @{
                    "Query" = $Query
                    "AST" = $parseResult
                } | ConvertTo-Json -Depth 10
                
                $json | Out-File -FilePath $OutputPath -Encoding UTF8
            }
            "Qdrant" {
                $qdrantQuery = Convert-QueryToQdrantFormat -Query $Query -OutputFormat "JSON"
                $qdrantQuery | Out-File -FilePath $OutputPath -Encoding UTF8
            }
        }
        
        Write-Log "Query saved to: $OutputPath" -Level "Info"
        return $true
    } catch {
        Write-Log "Error saving query: $_" -Level "Error"
        return $false
    }
}

# Fonction pour afficher les résultats
function Show-QueryResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Results,
        
        [Parameter(Mandatory = $true)]
        [string]$QueryString
    )
    
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

# Fonction principale
function Invoke-QueryEditor {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$InitialQuery = "",
        
        [Parameter(Mandatory = $false)]
        [string]$RoadmapPath,
        
        [Parameter(Mandatory = $false)]
        [string]$SchemaPath,
        
        [Parameter(Mandatory = $false)]
        [string]$HistoryFilePath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Console", "GUI", "VSCode")]
        [string]$EditorMode = "Console",
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableSyntaxHighlighting,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableAutoCompletion,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableValidation,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Basic", "Detailed", "Semantic")]
        [string]$ValidationLevel = "Basic",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Execute", "Convert", "Save", "None")]
        [string]$Action = "Execute",
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )
    
    # Définir le chemin par défaut pour l'historique si non spécifié
    if (-not $HistoryFilePath) {
        $HistoryFilePath = Join-Path -Path $scriptPath -ChildPath "query_history.txt"
    }
    
    # Ouvrir l'éditeur de requête
    $query = Edit-QueryText -InitialQuery $InitialQuery -HistoryFilePath $HistoryFilePath -EditorMode $EditorMode -EnableSyntaxHighlighting:$EnableSyntaxHighlighting -EnableAutoCompletion:$EnableAutoCompletion -EnableValidation:$EnableValidation
    
    # Si l'utilisateur a annulé, sortir
    if ([string]::IsNullOrWhiteSpace($query)) {
        Write-Log "Query editing cancelled by user" -Level "Info"
        return $null
    }
    
    # Valider la requête si demandé
    if ($EnableValidation) {
        $validationResult = Test-QueryValidation -Query $query -ValidationLevel $ValidationLevel -SchemaPath $SchemaPath -OutputFormat "Object"
        
        if (-not $validationResult.IsValid) {
            Write-Host "Query validation failed:" -ForegroundColor Red
            foreach ($error in $validationResult.Errors) {
                Write-Host "- $($error.Message)" -ForegroundColor Red
            }
            
            $continue = Read-Host "Continue anyway? (y/n)"
            if ($continue -ne "y") {
                Write-Log "Query execution cancelled due to validation errors" -Level "Info"
                return $null
            }
        } elseif ($validationResult.Warnings.Count -gt 0) {
            Write-Host "Query validation warnings:" -ForegroundColor Yellow
            foreach ($warning in $validationResult.Warnings) {
                Write-Host "- $($warning.Message)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "Query validation successful" -ForegroundColor Green
        }
    }
    
    # Exécuter l'action demandée
    switch ($Action) {
        "Execute" {
            $results = Invoke-Query -Query $query -RoadmapPath $RoadmapPath
            Show-QueryResults -Results $results -QueryString $query
            return $results
        }
        "Convert" {
            $qdrantQuery = Convert-QueryToQdrantFormat -Query $query -OutputFormat "JSON"
            Write-Host "Qdrant Query:" -ForegroundColor Cyan
            Write-Host $qdrantQuery
            return $qdrantQuery
        }
        "Save" {
            if (-not $OutputPath) {
                $OutputPath = Join-Path -Path $scriptPath -ChildPath "saved_query.txt"
            }
            
            $format = switch ([System.IO.Path]::GetExtension($OutputPath).ToLower()) {
                ".json" { "JSON" }
                ".qdrant" { "Qdrant" }
                default { "Text" }
            }
            
            $success = Save-QueryToFile -Query $query -OutputPath $OutputPath -Format $format
            
            if ($success) {
                Write-Host "Query saved to: $OutputPath" -ForegroundColor Green
            } else {
                Write-Host "Failed to save query" -ForegroundColor Red
            }
            
            return $success
        }
        "None" {
            return $query
        }
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Invoke-QueryEditor -InitialQuery $InitialQuery -RoadmapPath $RoadmapPath -SchemaPath $SchemaPath -HistoryFilePath $HistoryFilePath -EditorMode $EditorMode -EnableSyntaxHighlighting:$EnableSyntaxHighlighting -EnableAutoCompletion:$EnableAutoCompletion -EnableValidation:$EnableValidation -ValidationLevel $ValidationLevel -Action $Action -OutputPath $OutputPath
}
