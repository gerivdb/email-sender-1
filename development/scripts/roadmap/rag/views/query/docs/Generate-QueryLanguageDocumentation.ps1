# New-QueryLanguageDocumentation.ps1
# Script pour générer la documentation du langage de requête
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$SyntaxDefinitionPath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputDir,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Markdown", "HTML", "PDF")]
    [string]$OutputFormat = "Markdown",
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateFullDocumentation,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateOperatorsDoc,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateExamplesDoc,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateBestPracticesDoc
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
        
        $color = switch ($Level) {
            "Info" { "White" }
            "Warning" { "Yellow" }
            "Error" { "Red" }
            "Success" { "Green" }
            "Debug" { "Gray" }
        }
        
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

# Fonction pour charger la définition de la syntaxe
function Get-SyntaxDefinition {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$SyntaxDefinitionPath
    )
    
    Write-Log "Chargement de la définition de la syntaxe..." -Level "Info"
    
    if (-not [string]::IsNullOrEmpty($SyntaxDefinitionPath) -and (Test-Path -Path $SyntaxDefinitionPath)) {
        try {
            $syntaxDefinition = Get-Content -Path $SyntaxDefinitionPath -Raw | ConvertFrom-Json -AsHashtable
            Write-Log "Définition de la syntaxe chargée depuis : $SyntaxDefinitionPath" -Level "Success"
            return $syntaxDefinition
        } catch {
            Write-Log "Erreur lors du chargement de la définition de la syntaxe : $_" -Level "Error"
        }
    }
    
    # Si le chargement a échoué ou si aucun chemin n'a été spécifié, générer une définition par défaut
    Write-Log "Génération d'une définition de syntaxe par défaut..." -Level "Info"
    
    $defineSyntaxScript = Join-Path -Path $parentPath -ChildPath "Define-QueryLanguageSyntax.ps1"
    
    if (Test-Path -Path $defineSyntaxScript) {
        $syntaxDefinition = & $defineSyntaxScript
        Write-Log "Définition de la syntaxe générée." -Level "Success"
        return $syntaxDefinition
    } else {
        Write-Log "Script de définition de la syntaxe introuvable : $defineSyntaxScript" -Level "Error"
        return $null
    }
}

# Fonction pour créer le répertoire de sortie
function New-OutputDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputDir
    )
    
    if (-not (Test-Path -Path $OutputDir)) {
        try {
            New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
            Write-Log "Répertoire de sortie créé : $OutputDir" -Level "Success"
        } catch {
            Write-Log "Erreur lors de la création du répertoire de sortie : $_" -Level "Error"
            return $false
        }
    }
    
    return $true
}

# Fonction pour générer la documentation des opérateurs logiques
function New-LogicalOperatorsDocumentation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$SyntaxDefinition,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputDir,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputFormat
    )
    
    Write-Log "Génération de la documentation des opérateurs logiques..." -Level "Info"
    
    # Créer le répertoire de sortie pour les opérateurs
    $operatorsDir = Join-Path -Path $OutputDir -ChildPath "operators"
    
    if (-not (New-OutputDirectory -OutputDir $operatorsDir)) {
        return $false
    }
    
    # Générer la documentation pour chaque opérateur logique
    foreach ($opName in $SyntaxDefinition.LogicalOperators.Keys) {
        $op = $SyntaxDefinition.LogicalOperators[$opName]
        
        # Générer le contenu selon le format demandé
        switch ($OutputFormat) {
            "Markdown" {
                $content = New-MarkdownOperatorDocumentation -OperatorName $opName -OperatorInfo $op
                $outputPath = Join-Path -Path $operatorsDir -ChildPath "operator_$($opName.ToLower()).md"
            }
            "HTML" {
                $content = New-HtmlOperatorDocumentation -OperatorName $opName -OperatorInfo $op
                $outputPath = Join-Path -Path $operatorsDir -ChildPath "operator_$($opName.ToLower()).html"
            }
            "PDF" {
                # Pour PDF, on génère d'abord en Markdown puis on convertira plus tard
                $content = New-MarkdownOperatorDocumentation -OperatorName $opName -OperatorInfo $op
                $outputPath = Join-Path -Path $operatorsDir -ChildPath "operator_$($opName.ToLower()).md"
            }
        }
        
        # Sauvegarder le contenu
        $content | Set-Content -Path $outputPath -Encoding UTF8
        Write-Log "Documentation de l'opérateur $opName générée : $outputPath" -Level "Success"
    }
    
    # Générer un index des opérateurs
    $indexContent = New-OperatorsIndexDocumentation -SyntaxDefinition $SyntaxDefinition -OutputFormat $OutputFormat
    $indexPath = Join-Path -Path $operatorsDir -ChildPath "index.$($OutputFormat.ToLower())"
    
    $indexContent | Set-Content -Path $indexPath -Encoding UTF8
    Write-Log "Index des opérateurs généré : $indexPath" -Level "Success"
    
    return $true
}

# Fonction pour générer la documentation d'un opérateur au format Markdown
function New-MarkdownOperatorDocumentation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OperatorName,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$OperatorInfo
    )
    
    $markdown = "# Opérateur $OperatorName`n`n"
    
    # Description
    $markdown += "## Description`n`n"
    $markdown += "$($OperatorInfo.Description)`n`n"
    
    # Syntaxe
    $markdown += "## Syntaxe`n`n"
    $markdown += "### Symboles acceptés`n`n"
    
    foreach ($symbol in $OperatorInfo.Symbols) {
        $markdown += "- `$symbol``n"
    }
    
    $markdown += "`n### Précédence`n`n"
    $markdown += "Niveau de précédence : **$($OperatorInfo.Precedence)**`n`n"
    
    if ($OperatorName -eq "AND") {
        $markdown += "L'opérateur AND a une précédence plus élevée que OR, ce qui signifie qu'il est évalué avant OR dans une expression sans parenthèses.`n`n"
        $markdown += "Exemple : `status:todo AND category:development OR priority:high``n`n"
        $markdown += "Cette expression est équivalente à : `(status:todo AND category:development) OR priority:high``n`n"
    } elseif ($OperatorName -eq "OR") {
        $markdown += "L'opérateur OR a une précédence plus faible que AND, ce qui signifie qu'il est évalué après AND dans une expression sans parenthèses.`n`n"
        $markdown += "Exemple : `status:todo AND category:development OR priority:high``n`n"
        $markdown += "Cette expression est équivalente à : `(status:todo AND category:development) OR priority:high``n`n"
    } elseif ($OperatorName -eq "NOT") {
        $markdown += "L'opérateur NOT a la précédence la plus élevée, ce qui signifie qu'il est évalué avant AND et OR dans une expression sans parenthèses.`n`n"
        $markdown += "Exemple : `NOT status:done AND priority:high``n`n"
        $markdown += "Cette expression est équivalente à : `(NOT status:done) AND priority:high``n`n"
    }
    
    # Exemples
    $markdown += "## Exemples`n`n"
    
    foreach ($example in $OperatorInfo.Examples) {
        $markdown += "- `$example``n"
    }
    
    $markdown += "`n## Utilisation avec d'autres opérateurs`n`n"
    
    if ($OperatorName -eq "AND") {
        $markdown += "### AND avec OR`n`n"
        $markdown += "````n(status:todo AND priority:high) OR (status:in_progress AND priority:medium)`n````n`n"
        $markdown += "Cette requête trouve les tâches qui sont soit (à faire et de haute priorité) soit (en cours et de priorité moyenne).`n`n"
        
        $markdown += "### AND avec NOT`n`n"
        $markdown += "````nstatus:todo AND NOT category:documentation`n````n`n"
        $markdown += "Cette requête trouve les tâches à faire qui ne sont pas dans la catégorie documentation.`n`n"
    } elseif ($OperatorName -eq "OR") {
        $markdown += "### OR avec AND`n`n"
        $markdown += "````npriority:high OR (status:in_progress AND category:development)`n````n`n"
        $markdown += "Cette requête trouve les tâches qui sont soit de haute priorité, soit en cours et dans la catégorie développement.`n`n"
        
        $markdown += "### OR avec NOT`n`n"
        $markdown += "````npriority:high OR NOT status:done`n````n`n"
        $markdown += "Cette requête trouve les tâches qui sont soit de haute priorité, soit non terminées.`n`n"
    } elseif ($OperatorName -eq "NOT") {
        $markdown += "### NOT avec AND`n`n"
        $markdown += "````nNOT status:done AND priority:high`n````n`n"
        $markdown += "Cette requête trouve les tâches non terminées et de haute priorité.`n`n"
        
        $markdown += "### NOT avec OR`n`n"
        $markdown += "````nNOT (status:done OR priority:low)`n````n`n"
        $markdown += "Cette requête trouve les tâches qui ne sont ni terminées ni de faible priorité.`n`n"
    }
    
    $markdown += "## Bonnes pratiques`n`n"
    
    if ($OperatorName -eq "AND") {
        $markdown += "- Utilisez des parenthèses pour clarifier l'ordre d'évaluation lorsque vous combinez AND avec d'autres opérateurs.`n"
        $markdown += "- Placez les conditions les plus restrictives en premier pour optimiser les performances.`n"
        $markdown += "- Préférez la syntaxe `AND` pour la lisibilité, mais `&&` peut être utilisé dans les scripts automatisés.`n"
    } elseif ($OperatorName -eq "OR") {
        $markdown += "- Utilisez des parenthèses pour clarifier l'ordre d'évaluation lorsque vous combinez OR avec d'autres opérateurs.`n"
        $markdown += "- Regroupez les conditions similaires pour améliorer la lisibilité.`n"
        $markdown += "- Préférez la syntaxe `OR` pour la lisibilité, mais `||` peut être utilisé dans les scripts automatisés.`n"
    } elseif ($OperatorName -eq "NOT") {
        $markdown += "- Utilisez NOT avec parcimonie pour maintenir la lisibilité.`n"
        $markdown += "- Préférez des conditions positives lorsque c'est possible.`n"
        $markdown += "- Utilisez des parenthèses après NOT pour clarifier la portée de la négation.`n"
    }
    
    return $markdown
}

# Fonction pour générer la documentation d'un opérateur au format HTML
function New-HtmlOperatorDocumentation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OperatorName,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$OperatorInfo
    )
    
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Opérateur $OperatorName - Documentation du langage de requête</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
        }
        code {
            background-color: #f8f9fa;
            padding: 2px 4px;
            border-radius: 4px;
            font-family: Consolas, Monaco, 'Andale Mono', monospace;
        }
        pre {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
            font-family: Consolas, Monaco, 'Andale Mono', monospace;
        }
        .example {
            margin-bottom: 10px;
        }
        .precedence {
            font-weight: bold;
            color: #e74c3c;
        }
        .best-practices {
            background-color: #e8f4f8;
            padding: 15px;
            border-radius: 5px;
            margin-top: 20px;
        }
        .best-practices h2 {
            margin-top: 0;
        }
        .best-practices ul {
            margin-bottom: 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Opérateur $OperatorName</h1>
        
        <h2>Description</h2>
        <p>$($OperatorInfo.Description)</p>
        
        <h2>Syntaxe</h2>
        <h3>Symboles acceptés</h3>
        <ul>
"@
    
    foreach ($symbol in $OperatorInfo.Symbols) {
        $html += "            <li><code>$symbol</code></li>`n"
    }
    
    $html += @"
        </ul>
        
        <h3>Précédence</h3>
        <p>Niveau de précédence : <span class="precedence">$($OperatorInfo.Precedence)</span></p>
"@
    
    if ($OperatorName -eq "AND") {
        $html += @"
        <p>L'opérateur AND a une précédence plus élevée que OR, ce qui signifie qu'il est évalué avant OR dans une expression sans parenthèses.</p>
        <p>Exemple : <code>status:todo AND category:development OR priority:high</code></p>
        <p>Cette expression est équivalente à : <code>(status:todo AND category:development) OR priority:high</code></p>
"@
    } elseif ($OperatorName -eq "OR") {
        $html += @"
        <p>L'opérateur OR a une précédence plus faible que AND, ce qui signifie qu'il est évalué après AND dans une expression sans parenthèses.</p>
        <p>Exemple : <code>status:todo AND category:development OR priority:high</code></p>
        <p>Cette expression est équivalente à : <code>(status:todo AND category:development) OR priority:high</code></p>
"@
    } elseif ($OperatorName -eq "NOT") {
        $html += @"
        <p>L'opérateur NOT a la précédence la plus élevée, ce qui signifie qu'il est évalué avant AND et OR dans une expression sans parenthèses.</p>
        <p>Exemple : <code>NOT status:done AND priority:high</code></p>
        <p>Cette expression est équivalente à : <code>(NOT status:done) AND priority:high</code></p>
"@
    }
    
    $html += @"
        
        <h2>Exemples</h2>
        <ul>
"@
    
    foreach ($example in $OperatorInfo.Examples) {
        $html += "            <li class='example'><code>$example</code></li>`n"
    }
    
    $html += @"
        </ul>
        
        <h2>Utilisation avec d'autres opérateurs</h2>
"@
    
    if ($OperatorName -eq "AND") {
        $html += @"
        <h3>AND avec OR</h3>
        <pre>(status:todo AND priority:high) OR (status:in_progress AND priority:medium)</pre>
        <p>Cette requête trouve les tâches qui sont soit (à faire et de haute priorité) soit (en cours et de priorité moyenne).</p>
        
        <h3>AND avec NOT</h3>
        <pre>status:todo AND NOT category:documentation</pre>
        <p>Cette requête trouve les tâches à faire qui ne sont pas dans la catégorie documentation.</p>
"@
    } elseif ($OperatorName -eq "OR") {
        $html += @"
        <h3>OR avec AND</h3>
        <pre>priority:high OR (status:in_progress AND category:development)</pre>
        <p>Cette requête trouve les tâches qui sont soit de haute priorité, soit en cours et dans la catégorie développement.</p>
        
        <h3>OR avec NOT</h3>
        <pre>priority:high OR NOT status:done</pre>
        <p>Cette requête trouve les tâches qui sont soit de haute priorité, soit non terminées.</p>
"@
    } elseif ($OperatorName -eq "NOT") {
        $html += @"
        <h3>NOT avec AND</h3>
        <pre>NOT status:done AND priority:high</pre>
        <p>Cette requête trouve les tâches non terminées et de haute priorité.</p>
        
        <h3>NOT avec OR</h3>
        <pre>NOT (status:done OR priority:low)</pre>
        <p>Cette requête trouve les tâches qui ne sont ni terminées ni de faible priorité.</p>
"@
    }
    
    $html += @"
        
        <div class="best-practices">
            <h2>Bonnes pratiques</h2>
            <ul>
"@
    
    if ($OperatorName -eq "AND") {
        $html += @"
                <li>Utilisez des parenthèses pour clarifier l'ordre d'évaluation lorsque vous combinez AND avec d'autres opérateurs.</li>
                <li>Placez les conditions les plus restrictives en premier pour optimiser les performances.</li>
                <li>Préférez la syntaxe <code>AND</code> pour la lisibilité, mais <code>&&</code> peut être utilisé dans les scripts automatisés.</li>
"@
    } elseif ($OperatorName -eq "OR") {
        $html += @"
                <li>Utilisez des parenthèses pour clarifier l'ordre d'évaluation lorsque vous combinez OR avec d'autres opérateurs.</li>
                <li>Regroupez les conditions similaires pour améliorer la lisibilité.</li>
                <li>Préférez la syntaxe <code>OR</code> pour la lisibilité, mais <code>||</code> peut être utilisé dans les scripts automatisés.</li>
"@
    } elseif ($OperatorName -eq "NOT") {
        $html += @"
                <li>Utilisez NOT avec parcimonie pour maintenir la lisibilité.</li>
                <li>Préférez des conditions positives lorsque c'est possible.</li>
                <li>Utilisez des parenthèses après NOT pour clarifier la portée de la négation.</li>
"@
    }
    
    $html += @"
            </ul>
        </div>
    </div>
</body>
</html>
"@
    
    return $html
}

# Fonction pour générer l'index des opérateurs
function New-OperatorsIndexDocumentation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$SyntaxDefinition,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputFormat
    )
    
    switch ($OutputFormat) {
        "Markdown" {
            $content = "# Index des opérateurs logiques`n`n"
            $content += "Ce document liste tous les opérateurs logiques disponibles dans le langage de requête.`n`n"
            
            $content += "| Opérateur | Symboles | Description | Précédence |`n"
            $content += "|-----------|----------|-------------|------------|`n"
            
            foreach ($opName in $SyntaxDefinition.LogicalOperators.Keys | Sort-Object { $SyntaxDefinition.LogicalOperators[$_].Precedence } -Descending) {
                $op = $SyntaxDefinition.LogicalOperators[$opName]
                $symbols = $op.Symbols -join ", "
                $content += "| [$opName](operator_$($opName.ToLower()).md) | $symbols | $($op.Description) | $($op.Precedence) |`n"
            }
        }
        "HTML" {
            $content = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Index des opérateurs logiques - Documentation du langage de requête</title>
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
            max-width: 800px;
            margin: 0 auto;
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
        a {
            color: #3498db;
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Index des opérateurs logiques</h1>
        <p>Ce document liste tous les opérateurs logiques disponibles dans le langage de requête.</p>
        
        <table>
            <thead>
                <tr>
                    <th>Opérateur</th>
                    <th>Symboles</th>
                    <th>Description</th>
                    <th>Précédence</th>
                </tr>
            </thead>
            <tbody>
"@
            
            foreach ($opName in $SyntaxDefinition.LogicalOperators.Keys | Sort-Object { $SyntaxDefinition.LogicalOperators[$_].Precedence } -Descending) {
                $op = $SyntaxDefinition.LogicalOperators[$opName]
                $symbols = $op.Symbols -join ", "
                $content += @"
                <tr>
                    <td><a href="operator_$($opName.ToLower()).html">$opName</a></td>
                    <td>$symbols</td>
                    <td>$($op.Description)</td>
                    <td>$($op.Precedence)</td>
                </tr>
"@
            }
            
            $content += @"
            </tbody>
        </table>
    </div>
</body>
</html>
"@
        }
        "PDF" {
            # Pour PDF, on génère d'abord en Markdown
            $content = "# Index des opérateurs logiques`n`n"
            $content += "Ce document liste tous les opérateurs logiques disponibles dans le langage de requête.`n`n"
            
            $content += "| Opérateur | Symboles | Description | Précédence |`n"
            $content += "|-----------|----------|-------------|------------|`n"
            
            foreach ($opName in $SyntaxDefinition.LogicalOperators.Keys | Sort-Object { $SyntaxDefinition.LogicalOperators[$_].Precedence } -Descending) {
                $op = $SyntaxDefinition.LogicalOperators[$opName]
                $symbols = $op.Symbols -join ", "
                $content += "| $opName | $symbols | $($op.Description) | $($op.Precedence) |`n"
            }
        }
    }
    
    return $content
}

# Fonction principale
function New-QueryLanguageDocumentation {
    [CmdletBinding()]
    param (
        [string]$SyntaxDefinitionPath,
        [string]$OutputDir,
        [string]$OutputFormat,
        [switch]$GenerateFullDocumentation,
        [switch]$GenerateOperatorsDoc,
        [switch]$GenerateExamplesDoc,
        [switch]$GenerateBestPracticesDoc
    )
    
    Write-Log "Démarrage de la génération de la documentation du langage de requête..." -Level "Info"
    
    # Charger la définition de la syntaxe
    $syntaxDefinition = Get-SyntaxDefinition -SyntaxDefinitionPath $SyntaxDefinitionPath
    
    if ($null -eq $syntaxDefinition) {
        Write-Log "Impossible de charger ou générer la définition de la syntaxe." -Level "Error"
        return $false
    }
    
    # Définir le répertoire de sortie par défaut si non spécifié
    if ([string]::IsNullOrEmpty($OutputDir)) {
        $OutputDir = Join-Path -Path $scriptPath -ChildPath "output"
    }
    
    # Créer le répertoire de sortie
    if (-not (New-OutputDirectory -OutputDir $OutputDir)) {
        return $false
    }
    
    # Générer la documentation selon les options spécifiées
    if ($GenerateFullDocumentation -or $GenerateOperatorsDoc) {
        New-LogicalOperatorsDocumentation -SyntaxDefinition $syntaxDefinition -OutputDir $OutputDir -OutputFormat $OutputFormat
    }
    
    if ($GenerateFullDocumentation -or $GenerateExamplesDoc) {
        # TODO: Implémenter la génération de la documentation des exemples
        Write-Log "Génération de la documentation des exemples non implémentée." -Level "Warning"
    }
    
    if ($GenerateFullDocumentation -or $GenerateBestPracticesDoc) {
        # TODO: Implémenter la génération de la documentation des bonnes pratiques
        Write-Log "Génération de la documentation des bonnes pratiques non implémentée." -Level "Warning"
    }
    
    Write-Log "Génération de la documentation terminée." -Level "Success"
    
    return $true
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    # Si aucune option spécifique n'est sélectionnée, générer la documentation complète
    if (-not $GenerateOperatorsDoc -and -not $GenerateExamplesDoc -and -not $GenerateBestPracticesDoc) {
        $GenerateFullDocumentation = $true
    }
    
    New-QueryLanguageDocumentation -SyntaxDefinitionPath $SyntaxDefinitionPath -OutputDir $OutputDir -OutputFormat $OutputFormat -GenerateFullDocumentation:$GenerateFullDocumentation -GenerateOperatorsDoc:$GenerateOperatorsDoc -GenerateExamplesDoc:$GenerateExamplesDoc -GenerateBestPracticesDoc:$GenerateBestPracticesDoc
}

