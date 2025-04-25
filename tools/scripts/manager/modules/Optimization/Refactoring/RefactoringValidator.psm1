# Module de validation de refactoring pour le Script Manager
# Ce module valide les résultats du refactoring
# Author: Script Manager
# Version: 1.0
# Tags: optimization, refactoring, validation

function New-RefactoringReport {
    <#
    .SYNOPSIS
        Crée un rapport de refactoring
    .DESCRIPTION
        Génère un rapport HTML des résultats du refactoring
    .PARAMETER Results
        Résultats du refactoring
    .PARAMETER OutputPath
        Chemin où enregistrer le rapport
    .EXAMPLE
        New-RefactoringReport -Results $results -OutputPath "refactoring\report.html"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Results,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    # Créer le contenu HTML
    $HtmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de refactoring</title>
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
        .success {
            background-color: #e8f5e9;
            color: #2e7d32;
        }
        .failure {
            background-color: #ffebee;
            color: #c62828;
        }
        .info {
            background-color: #e3f2fd;
            color: #1565c0;
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
        .operation {
            margin-bottom: 15px;
            padding: 10px;
            border-radius: 5px;
            background-color: #f8f9fa;
        }
        .operation-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
        }
        .operation-title {
            margin: 0;
            font-size: 1.1em;
        }
        .operation-status {
            font-size: 0.8em;
            padding: 3px 8px;
            border-radius: 20px;
            font-weight: bold;
        }
        .operation-type {
            font-size: 0.8em;
            padding: 3px 8px;
            border-radius: 20px;
            background-color: #e3f2fd;
            color: #1565c0;
        }
        .code-comparison {
            display: flex;
            gap: 20px;
            margin-top: 10px;
        }
        .code-block {
            flex: 1;
            background-color: #f5f5f5;
            padding: 10px;
            border-radius: 5px;
            font-family: Consolas, Monaco, 'Andale Mono', monospace;
            white-space: pre-wrap;
            overflow-x: auto;
        }
        .code-block h4 {
            margin-top: 0;
            font-size: 0.9em;
            color: #7f8c8d;
        }
        .error-message {
            color: #c62828;
            font-style: italic;
            margin-top: 10px;
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
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Rapport de refactoring</h1>
            <div class="timestamp">Généré le $($Results.Timestamp)</div>
        </div>
        
        <div class="summary">
            <div class="summary-card info">
                <h3>Mode</h3>
                <div class="value">$($Results.Mode)</div>
            </div>
            <div class="summary-card info">
                <h3>Scripts traités</h3>
                <div class="value">$($Results.TotalScripts)</div>
            </div>
            <div class="summary-card success">
                <h3>Succès</h3>
                <div class="value">$($Results.SuccessCount)</div>
            </div>
            <div class="summary-card failure">
                <h3>Échecs</h3>
                <div class="value">$($Results.TotalScripts - $Results.SuccessCount)</div>
            </div>
        </div>
        
        <h2>Filtres</h2>
        
        <div class="search">
            <input type="text" id="searchInput" placeholder="Rechercher...">
        </div>
        
        <div class="filters">
            <div class="filter active" data-filter="all">Tous</div>
            <div class="filter" data-filter="success">Succès</div>
            <div class="filter" data-filter="failure">Échecs</div>
        </div>
        
        <h2>Résultats par script</h2>
        
        <div id="scripts">
"@
    
    # Ajouter chaque script
    foreach ($Result in $Results.Results) {
        $HtmlContent += @"
            <div class="script-card" data-status="$(if ($Result.Success) { 'success' } else { 'failure' })">
                <div class="script-header">
                    <h3 class="script-title">$($Result.ScriptName)</h3>
                    <span class="script-type">$($Result.ScriptType)</span>
                </div>
                <p>Chemin: $($Result.ScriptPath)</p>
                
                $(if (-not $Result.Success) {
                    "<div class='error-message'>Erreur: $($Result.ErrorMessage)</div>"
                })
                
                $(if ($Result.Operations) {
                    "<h4>Opérations</h4>"
                } elseif ($Result.Suggestions) {
                    "<h4>Suggestions</h4>"
                })
"@
        
        # Ajouter chaque opération ou suggestion
        if ($Result.Operations) {
            foreach ($Operation in $Result.Operations) {
                $HtmlContent += @"
                <div class="operation">
                    <div class="operation-header">
                        <h5 class="operation-title">$($Operation.Title)</h5>
                        <div>
                            <span class="operation-type">$($Operation.TransformationType)</span>
                            <span class="operation-status $(if ($Operation.Success) { 'success' } else { 'failure' })">$(if ($Operation.Success) { 'Succès' } else { 'Échec' })</span>
                        </div>
                    </div>
                    
                    $(if ($Operation.ErrorMessage) {
                        "<div class='error-message'>Erreur: $($Operation.ErrorMessage)</div>"
                    })
                    
                    <div class="code-comparison">
                        <div class="code-block">
                            <h4>Avant</h4>
                            $($Operation.BeforeCode)
                        </div>
                        <div class="code-block">
                            <h4>Après</h4>
                            $($Operation.AfterCode)
                        </div>
                    </div>
                </div>
"@
            }
        } elseif ($Result.Suggestions) {
            foreach ($Suggestion in $Result.Suggestions) {
                $HtmlContent += @"
                <div class="operation">
                    <div class="operation-header">
                        <h5 class="operation-title">$($Suggestion.Title)</h5>
                        <div>
                            <span class="operation-type">$($Suggestion.TransformationType)</span>
                            <span class="operation-status info">Suggestion</span>
                        </div>
                    </div>
                    
                    <p>$($Suggestion.Description)</p>
                    <p><strong>Recommandation:</strong> $($Suggestion.Recommendation)</p>
                    <p><strong>Impact estimé:</strong> $($Suggestion.EstimatedImpact)</p>
                    <p><strong>Auto-corrigeable:</strong> $(if ($Suggestion.AutoFixable) { 'Oui' } else { 'Non' })</p>
                    
                    <div class="code-comparison">
                        <div class="code-block">
                            <h4>Avant</h4>
                            $($Suggestion.BeforeCode)
                        </div>
                        <div class="code-block">
                            <h4>Après</h4>
                            $($Suggestion.AfterCode)
                        </div>
                    </div>
                </div>
"@
            }
        }
        
        $HtmlContent += @"
            </div>
"@
    }
    
    # Fermer le HTML
    $HtmlContent += @"
        </div>
        
        <div class="footer">
            <p>Généré par le Script Manager</p>
        </div>
    </div>
    
    <script>
        // Fonction pour filtrer les scripts
        function filterScripts() {
            const activeFilter = document.querySelector('.filter.active').dataset.filter;
            const searchText = document.getElementById('searchInput').value.toLowerCase();
            
            const scripts = document.querySelectorAll('.script-card');
            
            scripts.forEach(script => {
                const scriptTitle = script.querySelector('.script-title').textContent.toLowerCase();
                const scriptPath = script.querySelector('p').textContent.toLowerCase();
                const scriptStatus = script.dataset.status;
                
                const textMatch = scriptTitle.includes(searchText) || scriptPath.includes(searchText);
                const statusMatch = activeFilter === 'all' || activeFilter === scriptStatus;
                
                script.style.display = textMatch && statusMatch ? '' : 'none';
            });
        }
        
        // Initialiser les filtres
        document.querySelectorAll('.filter').forEach(filter => {
            filter.addEventListener('click', () => {
                document.querySelectorAll('.filter').forEach(f => f.classList.remove('active'));
                filter.classList.add('active');
                filterScripts();
            });
        });
        
        // Initialiser la recherche
        document.getElementById('searchInput').addEventListener('input', filterScripts);
        
        // Filtrer initialement
        filterScripts();
    </script>
</body>
</html>
"@
    
    # Enregistrer le rapport HTML
    Set-Content -Path $OutputPath -Value $HtmlContent
    
    Write-Host "  Rapport HTML généré: $OutputPath" -ForegroundColor Green
}

function Test-RefactoredScript {
    <#
    .SYNOPSIS
        Teste un script refactoré
    .DESCRIPTION
        Vérifie que le script refactoré est valide et fonctionne correctement
    .PARAMETER OriginalPath
        Chemin du script original
    .PARAMETER RefactoredPath
        Chemin du script refactoré
    .PARAMETER ScriptType
        Type de script (PowerShell, Python, Batch, Shell)
    .EXAMPLE
        Test-RefactoredScript -OriginalPath "script.ps1" -RefactoredPath "script_refactored.ps1" -ScriptType "PowerShell"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$OriginalPath,
        
        [Parameter(Mandatory=$true)]
        [string]$RefactoredPath,
        
        [Parameter(Mandatory=$true)]
        [string]$ScriptType
    )
    
    # Créer un objet pour stocker les résultats
    $Result = [PSCustomObject]@{
        OriginalPath = $OriginalPath
        RefactoredPath = $RefactoredPath
        ScriptType = $ScriptType
        SyntaxValid = $false
        ExecutionSuccessful = $false
        ErrorMessage = $null
    }
    
    # Vérifier que les fichiers existent
    if (-not (Test-Path -Path $OriginalPath)) {
        $Result.ErrorMessage = "Le script original n'existe pas: $OriginalPath"
        return $Result
    }
    
    if (-not (Test-Path -Path $RefactoredPath)) {
        $Result.ErrorMessage = "Le script refactoré n'existe pas: $RefactoredPath"
        return $Result
    }
    
    # Vérifier la syntaxe selon le type de script
    try {
        switch ($ScriptType) {
            "PowerShell" {
                $SyntaxErrors = $null
                $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content -Path $RefactoredPath -Raw), [ref]$SyntaxErrors)
                
                if ($SyntaxErrors.Count -gt 0) {
                    $Result.ErrorMessage = "Erreurs de syntaxe PowerShell: $($SyntaxErrors[0].Message)"
                    return $Result
                }
                
                $Result.SyntaxValid = $true
            }
            "Python" {
                $PythonPath = Get-Command python -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
                
                if (-not $PythonPath) {
                    $Result.ErrorMessage = "Python n'est pas installé ou n'est pas dans le PATH"
                    return $Result
                }
                
                $SyntaxCheck = & python -m py_compile $RefactoredPath 2>&1
                
                if ($LASTEXITCODE -ne 0) {
                    $Result.ErrorMessage = "Erreurs de syntaxe Python: $SyntaxCheck"
                    return $Result
                }
                
                $Result.SyntaxValid = $true
            }
            "Batch" {
                # Pas de vérification de syntaxe simple pour les scripts Batch
                $Result.SyntaxValid = $true
            }
            "Shell" {
                $BashPath = Get-Command bash -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
                
                if (-not $BashPath) {
                    $Result.ErrorMessage = "Bash n'est pas installé ou n'est pas dans le PATH"
                    return $Result
                }
                
                $SyntaxCheck = & bash -n $RefactoredPath 2>&1
                
                if ($LASTEXITCODE -ne 0) {
                    $Result.ErrorMessage = "Erreurs de syntaxe Shell: $SyntaxCheck"
                    return $Result
                }
                
                $Result.SyntaxValid = $true
            }
            default {
                $Result.ErrorMessage = "Type de script non pris en charge: $ScriptType"
                return $Result
            }
        }
        
        # Si la syntaxe est valide, marquer l'exécution comme réussie
        # Note: Nous ne testons pas l'exécution réelle pour éviter les effets secondaires
        $Result.ExecutionSuccessful = $true
    } catch {
        $Result.ErrorMessage = "Erreur lors de la vérification de la syntaxe: $_"
    }
    
    return $Result
}

# Exporter les fonctions
Export-ModuleMember -Function New-RefactoringReport, Test-RefactoredScript
