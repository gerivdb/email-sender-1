# Script pour améliorer la détection des patterns d'erreur

# Patterns d'erreur pour différents langages
$script:ErrorPatterns = @{
    # Patterns d'erreur PowerShell
    "PowerShell" = @(
        @{
            Pattern = "Cannot find path '([^']+)' because it does not exist"
            Description = "Chemin introuvable"
            Category = "FileSystem"
            Severity = "Error"
            Suggestion = "Vérifier si le chemin existe avant d'y accéder. Utiliser Test-Path."
        },
        @{
            Pattern = "The term '([^']+)' is not recognized as the name of a cmdlet"
            Description = "Commande introuvable"
            Category = "Command"
            Severity = "Error"
            Suggestion = "Vérifier l'orthographe de la commande ou importer le module nécessaire."
        },
        @{
            Pattern = "Cannot bind argument to parameter '([^']+)' because it is null"
            Description = "Argument null"
            Category = "Parameter"
            Severity = "Error"
            Suggestion = "Vérifier que la variable a une valeur avant de l'utiliser comme paramètre."
        },
        @{
            Pattern = "Access to the path '([^']+)' is denied"
            Description = "Accès refusé"
            Category = "Permission"
            Severity = "Error"
            Suggestion = "Vérifier les permissions du fichier ou exécuter le script avec des privilèges élevés."
        },
        @{
            Pattern = "Method invocation failed because \[([^\]]+)\] does not contain a method named '([^']+)'"
            Description = "Méthode introuvable"
            Category = "Method"
            Severity = "Error"
            Suggestion = "Vérifier que la méthode existe pour ce type d'objet."
        },
        @{
            Pattern = "Property '([^']+)' cannot be found on this object"
            Description = "Propriété introuvable"
            Category = "Property"
            Severity = "Error"
            Suggestion = "Vérifier que la propriété existe pour ce type d'objet."
        },
        @{
            Pattern = "Index was outside the bounds of the array"
            Description = "Index hors limites"
            Category = "Array"
            Severity = "Error"
            Suggestion = "Vérifier les limites du tableau avant d'accéder à un élément."
        },
        @{
            Pattern = "You cannot call a method on a null-valued expression"
            Description = "Appel de méthode sur une expression null"
            Category = "NullReference"
            Severity = "Error"
            Suggestion = "Vérifier que l'objet n'est pas null avant d'appeler une méthode."
        },
        @{
            Pattern = "The property '([^']+)' cannot be found on this object. Verify that the property exists"
            Description = "Propriété introuvable"
            Category = "Property"
            Severity = "Error"
            Suggestion = "Vérifier que la propriété existe pour ce type d'objet."
        },
        @{
            Pattern = "Cannot convert value \"([^\"]+)\" to type \"([^\"]+)\""
            Description = "Erreur de conversion de type"
            Category = "TypeConversion"
            Severity = "Error"
            Suggestion = "Vérifier que la valeur peut être convertie vers le type cible."
        }
    ),
    
    # Patterns d'erreur Python
    "Python" = @(
        @{
            Pattern = "ImportError: No module named '?([^'\s]+)'?"
            Description = "Module introuvable"
            Category = "Import"
            Severity = "Error"
            Suggestion = "Installer le module manquant avec pip: pip install $1"
        },
        @{
            Pattern = "NameError: name '([^']+)' is not defined"
            Description = "Variable non définie"
            Category = "Variable"
            Severity = "Error"
            Suggestion = "Définir la variable avant de l'utiliser."
        },
        @{
            Pattern = "TypeError: '([^']+)' object is not callable"
            Description = "Objet non appelable"
            Category = "Type"
            Severity = "Error"
            Suggestion = "Vérifier que l'objet est une fonction ou une méthode."
        },
        @{
            Pattern = "AttributeError: '([^']+)' object has no attribute '([^']+)'"
            Description = "Attribut introuvable"
            Category = "Attribute"
            Severity = "Error"
            Suggestion = "Vérifier que l'attribut existe pour ce type d'objet."
        },
        @{
            Pattern = "IndexError: list index out of range"
            Description = "Index hors limites"
            Category = "Index"
            Severity = "Error"
            Suggestion = "Vérifier les limites de la liste avant d'accéder à un élément."
        },
        @{
            Pattern = "KeyError: '([^']+)'"
            Description = "Clé introuvable"
            Category = "Dictionary"
            Severity = "Error"
            Suggestion = "Vérifier que la clé existe dans le dictionnaire avant d'y accéder."
        },
        @{
            Pattern = "FileNotFoundError: \[Errno 2\] No such file or directory: '([^']+)'"
            Description = "Fichier introuvable"
            Category = "FileSystem"
            Severity = "Error"
            Suggestion = "Vérifier que le fichier existe avant d'y accéder."
        },
        @{
            Pattern = "SyntaxError: invalid syntax"
            Description = "Erreur de syntaxe"
            Category = "Syntax"
            Severity = "Error"
            Suggestion = "Vérifier la syntaxe du code."
        },
        @{
            Pattern = "IndentationError: unexpected indent"
            Description = "Erreur d'indentation"
            Category = "Syntax"
            Severity = "Error"
            Suggestion = "Vérifier l'indentation du code."
        },
        @{
            Pattern = "ZeroDivisionError: division by zero"
            Description = "Division par zéro"
            Category = "Arithmetic"
            Severity = "Error"
            Suggestion = "Vérifier que le diviseur n'est pas zéro avant de faire une division."
        }
    ),
    
    # Patterns d'erreur JavaScript
    "JavaScript" = @(
        @{
            Pattern = "ReferenceError: ([^ ]+) is not defined"
            Description = "Variable non définie"
            Category = "Reference"
            Severity = "Error"
            Suggestion = "Définir la variable avant de l'utiliser."
        },
        @{
            Pattern = "TypeError: ([^.]+)\.(.*) is not a function"
            Description = "Méthode introuvable"
            Category = "Type"
            Severity = "Error"
            Suggestion = "Vérifier que la méthode existe pour ce type d'objet."
        },
        @{
            Pattern = "SyntaxError: Unexpected token ([^\s]+)"
            Description = "Erreur de syntaxe"
            Category = "Syntax"
            Severity = "Error"
            Suggestion = "Vérifier la syntaxe du code."
        },
        @{
            Pattern = "TypeError: Cannot read property '([^']+)' of (null|undefined)"
            Description = "Accès à une propriété d'un objet null ou undefined"
            Category = "NullReference"
            Severity = "Error"
            Suggestion = "Vérifier que l'objet n'est pas null ou undefined avant d'accéder à ses propriétés."
        },
        @{
            Pattern = "RangeError: Maximum call stack size exceeded"
            Description = "Dépassement de la pile d'appels"
            Category = "Recursion"
            Severity = "Error"
            Suggestion = "Vérifier les conditions de sortie des fonctions récursives."
        },
        @{
            Pattern = "TypeError: ([^ ]+) is not iterable"
            Description = "Objet non itérable"
            Category = "Type"
            Severity = "Error"
            Suggestion = "Vérifier que l'objet est itérable (tableau, chaîne, Map, Set, etc.)."
        },
        @{
            Pattern = "URIError: URI malformed"
            Description = "URI mal formé"
            Category = "URI"
            Severity = "Error"
            Suggestion = "Vérifier le format de l'URI."
        },
        @{
            Pattern = "Error: Network Error"
            Description = "Erreur réseau"
            Category = "Network"
            Severity = "Error"
            Suggestion = "Vérifier la connexion réseau et l'URL."
        },
        @{
            Pattern = "Uncaught PromiseRejectionWarning: Unhandled promise rejection"
            Description = "Promesse rejetée non gérée"
            Category = "Promise"
            Severity = "Warning"
            Suggestion = "Ajouter un gestionnaire catch pour gérer les rejets de promesses."
        },
        @{
            Pattern = "Warning: Failed prop type: Invalid prop `([^`]+)`"
            Description = "Type de prop invalide (React)"
            Category = "React"
            Severity = "Warning"
            Suggestion = "Vérifier le type de la prop passée au composant React."
        }
    ),
    
    # Patterns d'erreur de configuration
    "Configuration" = @(
        @{
            Pattern = "Could not find a part of the path '([^']+)'"
            Description = "Chemin de configuration incomplet"
            Category = "Path"
            Severity = "Error"
            Suggestion = "Vérifier que tous les répertoires dans le chemin existent."
        },
        @{
            Pattern = "The configuration file '([^']+)' was not found"
            Description = "Fichier de configuration introuvable"
            Category = "File"
            Severity = "Error"
            Suggestion = "Vérifier que le fichier de configuration existe à l'emplacement spécifié."
        },
        @{
            Pattern = "Invalid configuration setting '([^']+)'"
            Description = "Paramètre de configuration invalide"
            Category = "Setting"
            Severity = "Error"
            Suggestion = "Vérifier la validité du paramètre de configuration."
        },
        @{
            Pattern = "Missing required configuration setting '([^']+)'"
            Description = "Paramètre de configuration manquant"
            Category = "Setting"
            Severity = "Error"
            Suggestion = "Ajouter le paramètre de configuration requis."
        },
        @{
            Pattern = "Configuration value '([^']+)' for setting '([^']+)' is invalid"
            Description = "Valeur de configuration invalide"
            Category = "Value"
            Severity = "Error"
            Suggestion = "Corriger la valeur du paramètre de configuration."
        },
        @{
            Pattern = "Duplicate configuration setting '([^']+)'"
            Description = "Paramètre de configuration en double"
            Category = "Duplicate"
            Severity = "Warning"
            Suggestion = "Supprimer les doublons dans la configuration."
        },
        @{
            Pattern = "Configuration section '([^']+)' is missing"
            Description = "Section de configuration manquante"
            Category = "Section"
            Severity = "Error"
            Suggestion = "Ajouter la section de configuration manquante."
        },
        @{
            Pattern = "Invalid JSON in configuration file"
            Description = "JSON invalide dans le fichier de configuration"
            Category = "Syntax"
            Severity = "Error"
            Suggestion = "Vérifier la syntaxe JSON du fichier de configuration."
        },
        @{
            Pattern = "Invalid XML in configuration file"
            Description = "XML invalide dans le fichier de configuration"
            Category = "Syntax"
            Severity = "Error"
            Suggestion = "Vérifier la syntaxe XML du fichier de configuration."
        },
        @{
            Pattern = "Configuration file has invalid encoding"
            Description = "Encodage invalide du fichier de configuration"
            Category = "Encoding"
            Severity = "Error"
            Suggestion = "Vérifier l'encodage du fichier de configuration (UTF-8 recommandé)."
        }
    )
}

# Fonction pour analyser un fichier à la recherche de patterns d'erreur
function Find-ErrorPatterns {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Languages = @("PowerShell", "Python", "JavaScript", "Configuration"),
        
        [Parameter(Mandatory = $false)]
        [string[]]$Categories = @(),
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Error", "Warning", "Info")]
        [string[]]$Severities = @("Error", "Warning", "Info")
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Error "Le fichier '$FilePath' n'existe pas."
        return $null
    }
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Raw
    
    # Résultats
    $results = @()
    
    # Analyser le contenu pour chaque langage spécifié
    foreach ($language in $Languages) {
        if (-not $script:ErrorPatterns.ContainsKey($language)) {
            Write-Warning "Langage non pris en charge: $language"
            continue
        }
        
        $patterns = $script:ErrorPatterns[$language]
        
        # Filtrer par catégorie si spécifié
        if ($Categories.Count -gt 0) {
            $patterns = $patterns | Where-Object { $Categories -contains $_.Category }
        }
        
        # Filtrer par sévérité si spécifié
        if ($Severities.Count -gt 0) {
            $patterns = $patterns | Where-Object { $Severities -contains $_.Severity }
        }
        
        # Rechercher chaque pattern
        foreach ($pattern in $patterns) {
            $matches = [regex]::Matches($content, $pattern.Pattern)
            
            foreach ($match in $matches) {
                # Trouver le numéro de ligne
                $lineNumber = ($content.Substring(0, $match.Index).Split("`n")).Length
                
                # Extraire la ligne complète
                $lines = $content.Split("`n")
                $line = if ($lineNumber -le $lines.Length) { $lines[$lineNumber - 1].Trim() } else { "" }
                
                # Créer le résultat
                $result = [PSCustomObject]@{
                    FilePath = $FilePath
                    Language = $language
                    LineNumber = $lineNumber
                    Line = $line
                    Pattern = $pattern.Pattern
                    Description = $pattern.Description
                    Category = $pattern.Category
                    Severity = $pattern.Severity
                    Suggestion = $pattern.Suggestion
                    Match = $match.Value
                }
                
                $results += $result
            }
        }
    }
    
    return $results
}

# Fonction pour analyser un répertoire à la recherche de patterns d'erreur
function Find-ErrorPatternsInDirectory {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string]$Filter = "*.*",
        
        [Parameter(Mandatory = $false)]
        [switch]$Recurse,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Languages = @("PowerShell", "Python", "JavaScript", "Configuration"),
        
        [Parameter(Mandatory = $false)]
        [string[]]$Categories = @(),
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Error", "Warning", "Info")]
        [string[]]$Severities = @("Error", "Warning", "Info")
    )
    
    # Vérifier si le répertoire existe
    if (-not (Test-Path -Path $Path -PathType Container)) {
        Write-Error "Le répertoire '$Path' n'existe pas."
        return $null
    }
    
    # Obtenir la liste des fichiers à analyser
    $files = Get-ChildItem -Path $Path -Filter $Filter -File -Recurse:$Recurse
    
    # Résultats
    $results = @()
    
    # Analyser chaque fichier
    foreach ($file in $files) {
        $fileResults = Find-ErrorPatterns -FilePath $file.FullName -Languages $Languages -Categories $Categories -Severities $Severities
        $results += $fileResults
    }
    
    return $results
}

# Fonction pour ajouter un nouveau pattern d'erreur
function Add-ErrorPattern {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Language,
        
        [Parameter(Mandatory = $true)]
        [string]$Pattern,
        
        [Parameter(Mandatory = $true)]
        [string]$Description,
        
        [Parameter(Mandatory = $true)]
        [string]$Category,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Error", "Warning", "Info")]
        [string]$Severity = "Error",
        
        [Parameter(Mandatory = $true)]
        [string]$Suggestion
    )
    
    # Vérifier si le langage existe
    if (-not $script:ErrorPatterns.ContainsKey($Language)) {
        $script:ErrorPatterns[$Language] = @()
    }
    
    # Créer le nouveau pattern
    $newPattern = @{
        Pattern = $Pattern
        Description = $Description
        Category = $Category
        Severity = $Severity
        Suggestion = $Suggestion
    }
    
    # Ajouter le pattern à la liste
    $script:ErrorPatterns[$Language] += $newPattern
    
    return $newPattern
}

# Fonction pour générer un rapport d'analyse
function New-ErrorAnalysisReport {
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Results,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("HTML", "CSV", "JSON", "Text")]
        [string]$Format = "HTML"
    )
    
    if ($Results.Count -eq 0) {
        Write-Warning "Aucun résultat à inclure dans le rapport."
        return $null
    }
    
    switch ($Format) {
        "HTML" {
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport d'analyse d'erreurs</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2, h3 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .error { color: #d9534f; }
        .warning { color: #f0ad4e; }
        .info { color: #5bc0de; }
        .summary { margin-bottom: 30px; }
        .file-section { margin-bottom: 40px; border-bottom: 1px solid #eee; padding-bottom: 20px; }
    </style>
</head>
<body>
    <h1>Rapport d'analyse d'erreurs</h1>
    <div class="summary">
        <h2>Résumé</h2>
        <p>Nombre total d'erreurs détectées: $($Results.Count)</p>
        <p>Erreurs: $($Results | Where-Object { $_.Severity -eq "Error" } | Measure-Object | Select-Object -ExpandProperty Count)</p>
        <p>Avertissements: $($Results | Where-Object { $_.Severity -eq "Warning" } | Measure-Object | Select-Object -ExpandProperty Count)</p>
        <p>Informations: $($Results | Where-Object { $_.Severity -eq "Info" } | Measure-Object | Select-Object -ExpandProperty Count)</p>
    </div>
    
    <h2>Détails par fichier</h2>
    
"@
            
            # Regrouper les résultats par fichier
            $fileGroups = $Results | Group-Object -Property FilePath
            
            foreach ($fileGroup in $fileGroups) {
                $html += @"
    <div class="file-section">
        <h3>$($fileGroup.Name)</h3>
        <p>Nombre d'erreurs: $($fileGroup.Count)</p>
        
        <table>
            <tr>
                <th>Ligne</th>
                <th>Sévérité</th>
                <th>Catégorie</th>
                <th>Description</th>
                <th>Suggestion</th>
            </tr>
"@
                
                foreach ($result in $fileGroup.Group) {
                    $severityClass = $result.Severity.ToLower()
                    
                    $html += @"
            <tr>
                <td>$($result.LineNumber)</td>
                <td class="$severityClass">$($result.Severity)</td>
                <td>$($result.Category)</td>
                <td>$($result.Description): $($result.Match)</td>
                <td>$($result.Suggestion)</td>
            </tr>
"@
                }
                
                $html += @"
        </table>
    </div>
"@
            }
            
            $html += @"
</body>
</html>
"@
            
            if (-not [string]::IsNullOrEmpty($OutputPath)) {
                Set-Content -Path $OutputPath -Value $html
            }
            
            return $html
        }
        "CSV" {
            $csv = $Results | Select-Object FilePath, LineNumber, Severity, Category, Description, Match, Suggestion | ConvertTo-Csv -NoTypeInformation
            
            if (-not [string]::IsNullOrEmpty($OutputPath)) {
                $csv | Set-Content -Path $OutputPath
            }
            
            return $csv
        }
        "JSON" {
            $json = $Results | ConvertTo-Json -Depth 3
            
            if (-not [string]::IsNullOrEmpty($OutputPath)) {
                $json | Set-Content -Path $OutputPath
            }
            
            return $json
        }
        "Text" {
            $text = "Rapport d'analyse d'erreurs`n"
            $text += "=========================`n`n"
            $text += "Nombre total d'erreurs détectées: $($Results.Count)`n"
            $text += "Erreurs: $($Results | Where-Object { $_.Severity -eq "Error" } | Measure-Object | Select-Object -ExpandProperty Count)`n"
            $text += "Avertissements: $($Results | Where-Object { $_.Severity -eq "Warning" } | Measure-Object | Select-Object -ExpandProperty Count)`n"
            $text += "Informations: $($Results | Where-Object { $_.Severity -eq "Info" } | Measure-Object | Select-Object -ExpandProperty Count)`n`n"
            
            $text += "Détails par fichier:`n"
            $text += "=================`n`n"
            
            # Regrouper les résultats par fichier
            $fileGroups = $Results | Group-Object -Property FilePath
            
            foreach ($fileGroup in $fileGroups) {
                $text += "Fichier: $($fileGroup.Name)`n"
                $text += "Nombre d'erreurs: $($fileGroup.Count)`n`n"
                
                foreach ($result in $fileGroup.Group) {
                    $text += "Ligne $($result.LineNumber): [$($result.Severity)] $($result.Category) - $($result.Description): $($result.Match)`n"
                    $text += "  Suggestion: $($result.Suggestion)`n`n"
                }
                
                $text += "`n"
            }
            
            if (-not [string]::IsNullOrEmpty($OutputPath)) {
                Set-Content -Path $OutputPath -Value $text
            }
            
            return $text
        }
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Find-ErrorPatterns, Find-ErrorPatternsInDirectory, Add-ErrorPattern, New-ErrorAnalysisReport
