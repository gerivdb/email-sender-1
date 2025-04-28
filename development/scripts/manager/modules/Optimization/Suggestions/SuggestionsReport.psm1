# Module de rapport de suggestions pour le Script Manager
# Ce module gÃ©nÃ¨re des rapports HTML pour les suggestions d'amÃ©lioration
# Author: Script Manager
# Version: 1.0
# Tags: optimization, suggestions, report

function New-SuggestionsReport {
    <#
    .SYNOPSIS
        GÃ©nÃ¨re un rapport HTML des suggestions d'amÃ©lioration
    .DESCRIPTION
        CrÃ©e un rapport HTML dÃ©taillÃ© des suggestions d'amÃ©lioration pour les scripts
    .PARAMETER Suggestions
        Objet contenant les suggestions d'amÃ©lioration
    .PARAMETER OutputPath
        Chemin oÃ¹ enregistrer le rapport HTML
    .EXAMPLE
        New-SuggestionsReport -Suggestions $suggestions -OutputPath "optimization\suggestions_report.html"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Suggestions,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    # CrÃ©er le contenu HTML
    $HtmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de suggestions d'amÃ©lioration</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
            color: #333;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: #fff;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
        }
        h1, h2, h3, h4 {
            color: #2c3e50;
        }
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        .timestamp {
            font-size: 0.9em;
            color: #7f8c8d;
        }
        .summary {
            display: flex;
            flex-wrap: wrap;
            gap: 20px;
            margin-bottom: 30px;
        }
        .summary-card {
            flex: 1;
            min-width: 200px;
            padding: 15px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
            text-align: center;
        }
        .summary-card h3 {
            margin-top: 0;
            font-size: 1.2em;
        }
        .summary-card .value {
            font-size: 2em;
            font-weight: bold;
            margin: 10px 0;
        }
        .high {
            background-color: #ffebee;
            color: #c62828;
        }
        .medium {
            background-color: #fff8e1;
            color: #f57f17;
        }
        .low {
            background-color: #e8f5e9;
            color: #2e7d32;
        }
        .script-card {
            margin-bottom: 20px;
            padding: 15px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
            background-color: #fff;
        }
        .script-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        .script-title {
            margin: 0;
            font-size: 1.2em;
        }
        .script-type {
            font-size: 0.9em;
            padding: 5px 10px;
            border-radius: 20px;
            background-color: #e3f2fd;
            color: #1565c0;
        }
        .suggestion {
            margin-bottom: 15px;
            padding: 10px;
            border-radius: 5px;
            background-color: #f8f9fa;
        }
        .suggestion-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
        }
        .suggestion-title {
            margin: 0;
            font-size: 1.1em;
        }
        .suggestion-severity {
            font-size: 0.8em;
            padding: 3px 8px;
            border-radius: 20px;
            font-weight: bold;
        }
        .suggestion-category {
            font-size: 0.8em;
            padding: 3px 8px;
            border-radius: 20px;
            background-color: #e3f2fd;
            color: #1565c0;
        }
        .suggestion-description {
            margin-bottom: 10px;
        }
        .suggestion-recommendation {
            font-style: italic;
            color: #2c3e50;
        }
        .code-snippet {
            background-color: #f5f5f5;
            padding: 10px;
            border-radius: 5px;
            font-family: Consolas, Monaco, 'Andale Mono', monospace;
            white-space: pre-wrap;
            margin: 10px 0;
        }
        .filters {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
        }
        .filter {
            padding: 8px 15px;
            border: 1px solid #ddd;
            border-radius: 20px;
            background-color: #fff;
            cursor: pointer;
            transition: all 0.2s;
        }
        .filter:hover, .filter.active {
            background-color: #2c3e50;
            color: #fff;
            border-color: #2c3e50;
        }
        .search {
            margin-bottom: 20px;
        }
        .search input {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 5px;
            font-size: 1em;
        }
        .footer {
            margin-top: 30px;
            text-align: center;
            font-size: 0.9em;
            color: #7f8c8d;
        }
        .auto-fixable {
            display: inline-block;
            padding: 3px 8px;
            border-radius: 20px;
            background-color: #e8f5e9;
            color: #2e7d32;
            font-size: 0.8em;
            margin-left: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Rapport de suggestions d'amÃ©lioration</h1>
            <div class="timestamp">GÃ©nÃ©rÃ© le $($Suggestions.Timestamp)</div>
        </div>
        
        <div class="summary">
            <div class="summary-card">
                <h3>Scripts analysÃ©s</h3>
                <div class="value">$($Suggestions.TotalScripts)</div>
            </div>
            <div class="summary-card">
                <h3>Scripts avec suggestions</h3>
                <div class="value">$($Suggestions.ScriptsWithSuggestions)</div>
            </div>
            <div class="summary-card">
                <h3>Total des suggestions</h3>
                <div class="value">$($Suggestions.TotalSuggestions)</div>
            </div>
        </div>
        
        <h2>Filtres</h2>
        
        <div class="search">
            <input type="text" id="searchInput" placeholder="Rechercher...">
        </div>
        
        <div class="filters">
            <div class="filter active" data-filter="all">Tous</div>
            <div class="filter" data-filter="high">SÃ©vÃ©ritÃ© haute</div>
            <div class="filter" data-filter="medium">SÃ©vÃ©ritÃ© moyenne</div>
            <div class="filter" data-filter="low">SÃ©vÃ©ritÃ© basse</div>
            <div class="filter" data-filter="auto-fixable">Auto-corrigeable</div>
        </div>
        
        <h2>Suggestions par script</h2>
        
        <div id="scripts">
"@
    
    # Ajouter chaque script avec des suggestions
    foreach ($Script in $Suggestions.Results) {
        $HtmlContent += @"
            <div class="script-card">
                <div class="script-header">
                    <h3 class="script-title">$($Script.Name)</h3>
                    <span class="script-type">$($Script.Type)</span>
                </div>
                <p>Chemin: $($Script.Path)</p>
                <p>Nombre de suggestions: $($Script.SuggestionCount)</p>
                
                <h4>Suggestions</h4>
"@
        
        # Ajouter chaque suggestion
        foreach ($Suggestion in $Script.Suggestions) {
            $HtmlContent += @"
                <div class="suggestion" data-severity="$($Suggestion.Severity.ToLower())" data-auto-fixable="$($Suggestion.AutoFixable)">
                    <div class="suggestion-header">
                        <h5 class="suggestion-title">$($Suggestion.Title)</h5>
                        <div>
                            <span class="suggestion-category">$($Suggestion.Category)</span>
                            <span class="suggestion-severity $($Suggestion.Severity.ToLower())">$($Suggestion.Severity)</span>
                            $(if ($Suggestion.AutoFixable) { '<span class="auto-fixable">Auto-corrigeable</span>' })
                        </div>
                    </div>
                    <div class="suggestion-description">$($Suggestion.Description)</div>
                    <div class="suggestion-recommendation">Recommandation: $($Suggestion.Recommendation)</div>
                    
                    $(if ($Suggestion.CodeSnippet) { '<div class="code-snippet">' + $Suggestion.CodeSnippet + '</div>' })
                    
                    $(if ($Suggestion.LineNumbers) { '<div>Lignes: ' + ($Suggestion.LineNumbers -join ', ') + '</div>' })
                </div>
"@
        }
        
        $HtmlContent += @"
            </div>
"@
    }
    
    # Fermer le HTML
    $HtmlContent += @"
        </div>
        
        <div class="footer">
            <p>GÃ©nÃ©rÃ© par le Script Manager</p>
        </div>
    </div>
    
    <script>
        // Fonction pour filtrer les suggestions
        function filterSuggestions() {
            const activeFilter = document.querySelector('.filter.active').dataset.filter;
            const searchText = document.getElementById('searchInput').value.toLowerCase();
            
            const scripts = document.querySelectorAll('.script-card');
            
            scripts.forEach(script => {
                const scriptTitle = script.querySelector('.script-title').textContent.toLowerCase();
                const scriptPath = script.querySelector('p').textContent.toLowerCase();
                const scriptMatches = scriptTitle.includes(searchText) || scriptPath.includes(searchText);
                
                const suggestions = script.querySelectorAll('.suggestion');
                let visibleSuggestions = 0;
                
                suggestions.forEach(suggestion => {
                    const suggestionTitle = suggestion.querySelector('.suggestion-title').textContent.toLowerCase();
                    const suggestionDescription = suggestion.querySelector('.suggestion-description').textContent.toLowerCase();
                    const suggestionMatches = suggestionTitle.includes(searchText) || suggestionDescription.includes(searchText) || scriptMatches;
                    
                    const severity = suggestion.dataset.severity;
                    const autoFixable = suggestion.dataset.autoFixable === 'true';
                    
                    let visible = suggestionMatches;
                    
                    if (activeFilter === 'high') {
                        visible = visible && severity === 'high';
                    } else if (activeFilter === 'medium') {
                        visible = visible && severity === 'medium';
                    } else if (activeFilter === 'low') {
                        visible = visible && severity === 'low';
                    } else if (activeFilter === 'auto-fixable') {
                        visible = visible && autoFixable;
                    }
                    
                    suggestion.style.display = visible ? '' : 'none';
                    
                    if (visible) {
                        visibleSuggestions++;
                    }
                });
                
                script.style.display = visibleSuggestions > 0 ? '' : 'none';
            });
        }
        
        // Initialiser les filtres
        document.querySelectorAll('.filter').forEach(filter => {
            filter.addEventListener('click', () => {
                document.querySelectorAll('.filter').forEach(f => f.classList.remove('active'));
                filter.classList.add('active');
                filterSuggestions();
            });
        });
        
        // Initialiser la recherche
        document.getElementById('searchInput').addEventListener('input', filterSuggestions);
        
        // Filtrer initialement
        filterSuggestions();
    </script>
</body>
</html>
"@
    
    # Enregistrer le rapport HTML
    Set-Content -Path $OutputPath -Value $HtmlContent
    
    Write-Host "  Rapport HTML gÃ©nÃ©rÃ©: $OutputPath" -ForegroundColor Green
}

# Exporter les fonctions
Export-ModuleMember -Function New-SuggestionsReport
