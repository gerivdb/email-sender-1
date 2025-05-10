# New-ComparisonOperatorsDocumentation.ps1
# Script pour générer la documentation des opérateurs de comparaison
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
    [switch]$GenerateEqualityOperatorsDoc,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateContainsOperatorsDoc,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateNumericOperatorsDoc
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

# Fonction pour générer la documentation des opérateurs d'égalité et d'inégalité
function New-EqualityOperatorsDocumentation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$SyntaxDefinition,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputDir,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputFormat
    )
    
    Write-Log "Génération de la documentation des opérateurs d'égalité et d'inégalité..." -Level "Info"
    
    # Créer le répertoire de sortie pour les opérateurs
    $operatorsDir = Join-Path -Path $OutputDir -ChildPath "operators"
    
    if (-not (New-OutputDirectory -OutputDir $operatorsDir)) {
        return $false
    }
    
    # Filtrer les opérateurs d'égalité et d'inégalité
    $equalityOperators = @{
        EQUALS = $SyntaxDefinition.ComparisonOperators.EQUALS
        NOT_EQUALS = $SyntaxDefinition.ComparisonOperators.NOT_EQUALS
    }
    
    # Générer la documentation pour chaque opérateur
    foreach ($opName in $equalityOperators.Keys) {
        $op = $equalityOperators[$opName]
        
        # Générer le contenu selon le format demandé
        switch ($OutputFormat) {
            "Markdown" {
                $content = New-MarkdownEqualityOperatorDocumentation -OperatorName $opName -OperatorInfo $op
                $outputPath = Join-Path -Path $operatorsDir -ChildPath "operator_$($opName.ToLower()).md"
            }
            "HTML" {
                $content = New-HtmlEqualityOperatorDocumentation -OperatorName $opName -OperatorInfo $op
                $outputPath = Join-Path -Path $operatorsDir -ChildPath "operator_$($opName.ToLower()).html"
            }
            "PDF" {
                # Pour PDF, on génère d'abord en Markdown puis on convertira plus tard
                $content = New-MarkdownEqualityOperatorDocumentation -OperatorName $opName -OperatorInfo $op
                $outputPath = Join-Path -Path $operatorsDir -ChildPath "operator_$($opName.ToLower()).md"
            }
        }
        
        # Sauvegarder le contenu
        $content | Set-Content -Path $outputPath -Encoding UTF8
        Write-Log "Documentation de l'opérateur $opName générée : $outputPath" -Level "Success"
    }
    
    # Générer un index des opérateurs d'égalité et d'inégalité
    $indexContent = New-EqualityOperatorsIndexDocumentation -EqualityOperators $equalityOperators -OutputFormat $OutputFormat
    $indexPath = Join-Path -Path $operatorsDir -ChildPath "equality_operators_index.$($OutputFormat.ToLower())"
    
    $indexContent | Set-Content -Path $indexPath -Encoding UTF8
    Write-Log "Index des opérateurs d'égalité et d'inégalité généré : $indexPath" -Level "Success"
    
    return $true
}

# Fonction pour générer la documentation d'un opérateur d'égalité au format Markdown
function New-MarkdownEqualityOperatorDocumentation {
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
    
    $markdown += "`n## Exemples`n`n"
    
    foreach ($example in $OperatorInfo.Examples) {
        $markdown += "- `$example``n"
    }
    
    $markdown += "`n## Utilisation avec différents types de champs`n`n"
    
    if ($OperatorName -eq "EQUALS") {
        $markdown += "### Avec des champs de type énumération`n`n"
        $markdown += "````nstatus:todo`n````n`n"
        $markdown += "Cette requête trouve les tâches dont le statut est exactement 'todo'.`n`n"
        
        $markdown += "### Avec des champs de type chaîne de caractères`n`n"
        $markdown += "````ncategory:development`n````n`n"
        $markdown += "Cette requête trouve les tâches dont la catégorie est exactement 'development'.`n`n"
        
        $markdown += "### Avec des champs de type booléen`n`n"
        $markdown += "````nhas_children:true`n````n`n"
        $markdown += "Cette requête trouve les tâches qui ont des sous-tâches.`n`n"
    } elseif ($OperatorName -eq "NOT_EQUALS") {
        $markdown += "### Avec des champs de type énumération`n`n"
        $markdown += "````nstatus!=done`n````n`n"
        $markdown += "Cette requête trouve les tâches dont le statut n'est pas 'done'.`n`n"
        
        $markdown += "### Avec des champs de type chaîne de caractères`n`n"
        $markdown += "````ncategory<>documentation`n````n`n"
        $markdown += "Cette requête trouve les tâches dont la catégorie n'est pas 'documentation'.`n`n"
        
        $markdown += "### Avec des champs de type booléen`n`n"
        $markdown += "````nhas_children!=false`n````n`n"
        $markdown += "Cette requête trouve les tâches qui ont des sous-tâches.`n`n"
    }
    
    $markdown += "## Combinaison avec d'autres opérateurs`n`n"
    
    if ($OperatorName -eq "EQUALS") {
        $markdown += "### Avec des opérateurs logiques`n`n"
        $markdown += "````nstatus:todo AND priority:high`n````n`n"
        $markdown += "Cette requête trouve les tâches dont le statut est 'todo' et la priorité est 'high'.`n`n"
        
        $markdown += "````nstatus:todo OR status:in_progress`n````n`n"
        $markdown += "Cette requête trouve les tâches dont le statut est 'todo' ou 'in_progress'.`n`n"
        
        $markdown += "````nNOT status:done`n````n`n"
        $markdown += "Cette requête trouve les tâches dont le statut n'est pas 'done'.`n`n"
    } elseif ($OperatorName -eq "NOT_EQUALS") {
        $markdown += "### Avec des opérateurs logiques`n`n"
        $markdown += "````nstatus!=done AND priority!=low`n````n`n"
        $markdown += "Cette requête trouve les tâches dont le statut n'est pas 'done' et la priorité n'est pas 'low'.`n`n"
        
        $markdown += "````nstatus!=done OR priority:high`n````n`n"
        $markdown += "Cette requête trouve les tâches dont le statut n'est pas 'done' ou la priorité est 'high'.`n`n"
        
        $markdown += "````nNOT (status!=todo)`n````n`n"
        $markdown += "Cette requête trouve les tâches dont le statut est 'todo' (double négation).`n`n"
    }
    
    $markdown += "## Bonnes pratiques`n`n"
    
    if ($OperatorName -eq "EQUALS") {
        $markdown += "- Utilisez `:` comme opérateur d'égalité par défaut pour sa lisibilité.`n"
        $markdown += "- Pour les valeurs contenant des espaces, utilisez des guillemets : `title:\"Implement feature\"`.`n"
        $markdown += "- Pour les champs booléens, utilisez `true` ou `false` comme valeurs.`n"
    } elseif ($OperatorName -eq "NOT_EQUALS") {
        $markdown += "- Préférez `!=` pour sa lisibilité, mais `<>` peut être utilisé dans certains contextes.`n"
        $markdown += "- Considérez l'utilisation de `NOT field:value` comme alternative à `field!=value`.`n"
        $markdown += "- Évitez les doubles négations qui peuvent rendre les requêtes difficiles à comprendre.`n"
    }
    
    return $markdown
}

# Fonction pour générer la documentation d'un opérateur d'égalité au format HTML
function New-HtmlEqualityOperatorDocumentation {
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
        
        <h2>Exemples</h2>
        <ul>
"@
    
    foreach ($example in $OperatorInfo.Examples) {
        $html += "            <li class='example'><code>$example</code></li>`n"
    }
    
    $html += @"
        </ul>
        
        <h2>Utilisation avec différents types de champs</h2>
"@
    
    if ($OperatorName -eq "EQUALS") {
        $html += @"
        <h3>Avec des champs de type énumération</h3>
        <pre>status:todo</pre>
        <p>Cette requête trouve les tâches dont le statut est exactement 'todo'.</p>
        
        <h3>Avec des champs de type chaîne de caractères</h3>
        <pre>category:development</pre>
        <p>Cette requête trouve les tâches dont la catégorie est exactement 'development'.</p>
        
        <h3>Avec des champs de type booléen</h3>
        <pre>has_children:true</pre>
        <p>Cette requête trouve les tâches qui ont des sous-tâches.</p>
"@
    } elseif ($OperatorName -eq "NOT_EQUALS") {
        $html += @"
        <h3>Avec des champs de type énumération</h3>
        <pre>status!=done</pre>
        <p>Cette requête trouve les tâches dont le statut n'est pas 'done'.</p>
        
        <h3>Avec des champs de type chaîne de caractères</h3>
        <pre>category<>documentation</pre>
        <p>Cette requête trouve les tâches dont la catégorie n'est pas 'documentation'.</p>
        
        <h3>Avec des champs de type booléen</h3>
        <pre>has_children!=false</pre>
        <p>Cette requête trouve les tâches qui ont des sous-tâches.</p>
"@
    }
    
    $html += @"
        
        <h2>Combinaison avec d'autres opérateurs</h2>
"@
    
    if ($OperatorName -eq "EQUALS") {
        $html += @"
        <h3>Avec des opérateurs logiques</h3>
        <pre>status:todo AND priority:high</pre>
        <p>Cette requête trouve les tâches dont le statut est 'todo' et la priorité est 'high'.</p>
        
        <pre>status:todo OR status:in_progress</pre>
        <p>Cette requête trouve les tâches dont le statut est 'todo' ou 'in_progress'.</p>
        
        <pre>NOT status:done</pre>
        <p>Cette requête trouve les tâches dont le statut n'est pas 'done'.</p>
"@
    } elseif ($OperatorName -eq "NOT_EQUALS") {
        $html += @"
        <h3>Avec des opérateurs logiques</h3>
        <pre>status!=done AND priority!=low</pre>
        <p>Cette requête trouve les tâches dont le statut n'est pas 'done' et la priorité n'est pas 'low'.</p>
        
        <pre>status!=done OR priority:high</pre>
        <p>Cette requête trouve les tâches dont le statut n'est pas 'done' ou la priorité est 'high'.</p>
        
        <pre>NOT (status!=todo)</pre>
        <p>Cette requête trouve les tâches dont le statut est 'todo' (double négation).</p>
"@
    }
    
    $html += @"
        
        <div class="best-practices">
            <h2>Bonnes pratiques</h2>
            <ul>
"@
    
    if ($OperatorName -eq "EQUALS") {
        $html += @"
                <li>Utilisez <code>:</code> comme opérateur d'égalité par défaut pour sa lisibilité.</li>
                <li>Pour les valeurs contenant des espaces, utilisez des guillemets : <code>title:"Implement feature"</code>.</li>
                <li>Pour les champs booléens, utilisez <code>true</code> ou <code>false</code> comme valeurs.</li>
"@
    } elseif ($OperatorName -eq "NOT_EQUALS") {
        $html += @"
                <li>Préférez <code>!=</code> pour sa lisibilité, mais <code><></code> peut être utilisé dans certains contextes.</li>
                <li>Considérez l'utilisation de <code>NOT field:value</code> comme alternative à <code>field!=value</code>.</li>
                <li>Évitez les doubles négations qui peuvent rendre les requêtes difficiles à comprendre.</li>
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

# Fonction pour générer l'index des opérateurs d'égalité et d'inégalité
function New-EqualityOperatorsIndexDocumentation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$EqualityOperators,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputFormat
    )
    
    switch ($OutputFormat) {
        "Markdown" {
            $content = "# Index des opérateurs d'égalité et d'inégalité`n`n"
            $content += "Ce document liste tous les opérateurs d'égalité et d'inégalité disponibles dans le langage de requête.`n`n"
            
            $content += "| Opérateur | Symboles | Description |`n"
            $content += "|-----------|----------|-------------|`n"
            
            foreach ($opName in $EqualityOperators.Keys) {
                $op = $EqualityOperators[$opName]
                $symbols = $op.Symbols -join ", "
                $content += "| [$opName](operator_$($opName.ToLower()).md) | $symbols | $($op.Description) |`n"
            }
        }
        "HTML" {
            $content = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Index des opérateurs d'égalité et d'inégalité - Documentation du langage de requête</title>
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
        <h1>Index des opérateurs d'égalité et d'inégalité</h1>
        <p>Ce document liste tous les opérateurs d'égalité et d'inégalité disponibles dans le langage de requête.</p>
        
        <table>
            <thead>
                <tr>
                    <th>Opérateur</th>
                    <th>Symboles</th>
                    <th>Description</th>
                </tr>
            </thead>
            <tbody>
"@
            
            foreach ($opName in $EqualityOperators.Keys) {
                $op = $EqualityOperators[$opName]
                $symbols = $op.Symbols -join ", "
                $content += @"
                <tr>
                    <td><a href="operator_$($opName.ToLower()).html">$opName</a></td>
                    <td>$symbols</td>
                    <td>$($op.Description)</td>
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
            $content = "# Index des opérateurs d'égalité et d'inégalité`n`n"
            $content += "Ce document liste tous les opérateurs d'égalité et d'inégalité disponibles dans le langage de requête.`n`n"
            
            $content += "| Opérateur | Symboles | Description |`n"
            $content += "|-----------|----------|-------------|`n"
            
            foreach ($opName in $EqualityOperators.Keys) {
                $op = $EqualityOperators[$opName]
                $symbols = $op.Symbols -join ", "
                $content += "| $opName | $symbols | $($op.Description) |`n"
            }
        }
    }
    
    return $content
}

# Fonction principale
function New-ComparisonOperatorsDocumentation {
    [CmdletBinding()]
    param (
        [string]$SyntaxDefinitionPath,
        [string]$OutputDir,
        [string]$OutputFormat,
        [switch]$GenerateEqualityOperatorsDoc,
        [switch]$GenerateContainsOperatorsDoc,
        [switch]$GenerateNumericOperatorsDoc
    )
    
    Write-Log "Démarrage de la génération de la documentation des opérateurs de comparaison..." -Level "Info"
    
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
    if ($GenerateEqualityOperatorsDoc) {
        New-EqualityOperatorsDocumentation -SyntaxDefinition $syntaxDefinition -OutputDir $OutputDir -OutputFormat $OutputFormat
    }
    
    if ($GenerateContainsOperatorsDoc) {
        # TODO: Implémenter la génération de la documentation des opérateurs de contenance
        Write-Log "Génération de la documentation des opérateurs de contenance non implémentée." -Level "Warning"
    }
    
    if ($GenerateNumericOperatorsDoc) {
        # TODO: Implémenter la génération de la documentation des opérateurs numériques
        Write-Log "Génération de la documentation des opérateurs numériques non implémentée." -Level "Warning"
    }
    
    # Si aucune option spécifique n'est sélectionnée, générer la documentation complète
    if (-not $GenerateEqualityOperatorsDoc -and -not $GenerateContainsOperatorsDoc -and -not $GenerateNumericOperatorsDoc) {
        New-EqualityOperatorsDocumentation -SyntaxDefinition $syntaxDefinition -OutputDir $OutputDir -OutputFormat $OutputFormat
        
        # TODO: Implémenter la génération de la documentation des opérateurs de contenance et numériques
        Write-Log "Génération de la documentation des opérateurs de contenance et numériques non implémentée." -Level "Warning"
    }
    
    Write-Log "Génération de la documentation des opérateurs de comparaison terminée." -Level "Success"
    
    return $true
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    New-ComparisonOperatorsDocumentation -SyntaxDefinitionPath $SyntaxDefinitionPath -OutputDir $OutputDir -OutputFormat $OutputFormat -GenerateEqualityOperatorsDoc:$GenerateEqualityOperatorsDoc -GenerateContainsOperatorsDoc:$GenerateContainsOperatorsDoc -GenerateNumericOperatorsDoc:$GenerateNumericOperatorsDoc
}
