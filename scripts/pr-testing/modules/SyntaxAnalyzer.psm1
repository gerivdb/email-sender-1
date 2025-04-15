#Requires -Version 5.1
<#
.SYNOPSIS
    Module d'analyse syntaxique optimisé pour l'analyse des pull requests.
.DESCRIPTION
    Fournit des fonctionnalités d'analyse syntaxique optimisées pour différents
    langages de programmation, permettant une détection rapide des erreurs.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

# Classe pour l'analyse syntaxique
class SyntaxAnalyzer {
    [hashtable]$LanguageHandlers
    [hashtable]$RuleSet
    [bool]$UseCache
    [object]$Cache
    [int]$MaxConcurrentAnalyses

    # Constructeur
    SyntaxAnalyzer([bool]$useCache, [object]$cache, [int]$maxConcurrentAnalyses) {
        $this.LanguageHandlers = @{}
        $this.RuleSet = @{}
        $this.UseCache = $useCache
        $this.Cache = $cache
        $this.MaxConcurrentAnalyses = if ($maxConcurrentAnalyses -gt 0) { $maxConcurrentAnalyses } else { [System.Environment]::ProcessorCount }
        
        # Initialiser les gestionnaires de langages par défaut
        $this.RegisterLanguageHandler(".ps1", $this.GetPowerShellHandler())
        $this.RegisterLanguageHandler(".psm1", $this.GetPowerShellHandler())
        $this.RegisterLanguageHandler(".py", $this.GetPythonHandler())
        $this.RegisterLanguageHandler(".js", $this.GetJavaScriptHandler())
        $this.RegisterLanguageHandler(".html", $this.GetHtmlHandler())
        $this.RegisterLanguageHandler(".css", $this.GetCssHandler())
        
        # Initialiser les règles par défaut
        $this.InitializeDefaultRules()
    }

    # Enregistrer un gestionnaire de langage
    [void] RegisterLanguageHandler([string]$extension, [scriptblock]$handler) {
        $this.LanguageHandlers[$extension] = $handler
    }

    # Obtenir le gestionnaire PowerShell
    [scriptblock] GetPowerShellHandler() {
        return {
            param($content, $rules)
            
            $results = [System.Collections.Generic.List[object]]::new()
            
            # Analyser avec PSParser
            try {
                $errors = $null
                $tokens = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors)
                
                # Ajouter les erreurs de syntaxe
                foreach ($error in $errors) {
                    $results.Add([PSCustomObject]@{
                        Type = "Syntax"
                        Line = $error.Token.StartLine
                        Column = $error.Token.StartColumn
                        Message = $error.Message
                        Severity = "Error"
                        Rule = "PSParser"
                    })
                }
                
                # Appliquer les règles spécifiques
                foreach ($rule in $rules.GetEnumerator()) {
                    if ($rule.Value.Language -eq "PowerShell" -or $rule.Value.Language -eq "All") {
                        $ruleResults = & $rule.Value.Handler $content $tokens
                        foreach ($result in $ruleResults) {
                            $result | Add-Member -MemberType NoteProperty -Name "Rule" -Value $rule.Key -Force
                            $results.Add($result)
                        }
                    }
                }
            } catch {
                $results.Add([PSCustomObject]@{
                    Type = "Analyzer"
                    Line = 0
                    Column = 0
                    Message = "Erreur lors de l'analyse: $_"
                    Severity = "Error"
                    Rule = "PSParser"
                })
            }
            
            return $results
        }
    }

    # Obtenir le gestionnaire Python
    [scriptblock] GetPythonHandler() {
        return {
            param($content, $rules)
            
            $results = [System.Collections.Generic.List[object]]::new()
            
            # Vérifier si pylint est disponible
            $pylintAvailable = $null -ne (Get-Command -Name "pylint" -ErrorAction SilentlyContinue)
            
            if ($pylintAvailable) {
                # Créer un fichier temporaire
                $tempFile = [System.IO.Path]::GetTempFileName() + ".py"
                Set-Content -Path $tempFile -Value $content -Encoding UTF8
                
                try {
                    # Exécuter pylint
                    $pylintOutput = & pylint --output-format=json $tempFile 2>&1
                    
                    # Analyser la sortie JSON
                    if ($pylintOutput -is [string]) {
                        try {
                            $pylintResults = $pylintOutput | ConvertFrom-Json
                            
                            foreach ($issue in $pylintResults) {
                                $results.Add([PSCustomObject]@{
                                    Type = "Lint"
                                    Line = $issue.line
                                    Column = $issue.column
                                    Message = $issue.message
                                    Severity = switch ($issue.type) {
                                        "error" { "Error" }
                                        "warning" { "Warning" }
                                        "convention" { "Information" }
                                        "refactor" { "Information" }
                                        default { "Information" }
                                    }
                                    Rule = $issue.symbol
                                })
                            }
                        } catch {
                            # Ignorer les erreurs de conversion JSON
                        }
                    }
                } catch {
                    $results.Add([PSCustomObject]@{
                        Type = "Analyzer"
                        Line = 0
                        Column = 0
                        Message = "Erreur lors de l'exécution de pylint: $_"
                        Severity = "Error"
                        Rule = "Pylint"
                    })
                } finally {
                    # Supprimer le fichier temporaire
                    if (Test-Path -Path $tempFile) {
                        Remove-Item -Path $tempFile -Force
                    }
                }
            } else {
                # Analyse basique sans pylint
                $lines = $content -split "`n"
                
                # Vérifier les indentations
                $indentLevel = 0
                for ($i = 0; $i -lt $lines.Count; $i++) {
                    $line = $lines[$i]
                    $lineNumber = $i + 1
                    
                    # Vérifier les indentations
                    $indent = [regex]::Match($line, '^\s*').Length
                    $expectedIndent = $indentLevel * 4
                    
                    if ($indent % 4 -ne 0 -and -not [string]::IsNullOrWhiteSpace($line)) {
                        $results.Add([PSCustomObject]@{
                            Type = "Style"
                            Line = $lineNumber
                            Column = 1
                            Message = "Indentation incorrecte. Utilisez des multiples de 4 espaces."
                            Severity = "Warning"
                            Rule = "Indentation"
                        })
                    }
                    
                    # Mettre à jour le niveau d'indentation
                    if ($line -match ':$') {
                        $indentLevel++
                    } elseif ($indent -lt $expectedIndent -and $indentLevel -gt 0) {
                        $indentLevel = [Math]::Max(0, [Math]::Floor($indent / 4))
                    }
                }
            }
            
            # Appliquer les règles spécifiques
            foreach ($rule in $rules.GetEnumerator()) {
                if ($rule.Value.Language -eq "Python" -or $rule.Value.Language -eq "All") {
                    $ruleResults = & $rule.Value.Handler $content $null
                    foreach ($result in $ruleResults) {
                        $result | Add-Member -MemberType NoteProperty -Name "Rule" -Value $rule.Key -Force
                        $results.Add($result)
                    }
                }
            }
            
            return $results
        }
    }

    # Obtenir le gestionnaire JavaScript
    [scriptblock] GetJavaScriptHandler() {
        return {
            param($content, $rules)
            
            $results = [System.Collections.Generic.List[object]]::new()
            
            # Vérifier si eslint est disponible
            $eslintAvailable = $null -ne (Get-Command -Name "eslint" -ErrorAction SilentlyContinue)
            
            if ($eslintAvailable) {
                # Créer un fichier temporaire
                $tempFile = [System.IO.Path]::GetTempFileName() + ".js"
                Set-Content -Path $tempFile -Value $content -Encoding UTF8
                
                try {
                    # Exécuter eslint
                    $eslintOutput = & eslint --format json $tempFile 2>&1
                    
                    # Analyser la sortie JSON
                    if ($eslintOutput -is [string]) {
                        try {
                            $eslintResults = $eslintOutput | ConvertFrom-Json
                            
                            foreach ($file in $eslintResults) {
                                foreach ($message in $file.messages) {
                                    $results.Add([PSCustomObject]@{
                                        Type = "Lint"
                                        Line = $message.line
                                        Column = $message.column
                                        Message = $message.message
                                        Severity = if ($message.severity -eq 2) { "Error" } else { "Warning" }
                                        Rule = $message.ruleId
                                    })
                                }
                            }
                        } catch {
                            # Ignorer les erreurs de conversion JSON
                        }
                    }
                } catch {
                    $results.Add([PSCustomObject]@{
                        Type = "Analyzer"
                        Line = 0
                        Column = 0
                        Message = "Erreur lors de l'exécution de eslint: $_"
                        Severity = "Error"
                        Rule = "ESLint"
                    })
                } finally {
                    # Supprimer le fichier temporaire
                    if (Test-Path -Path $tempFile) {
                        Remove-Item -Path $tempFile -Force
                    }
                }
            } else {
                # Analyse basique sans eslint
                $lines = $content -split "`n"
                
                # Vérifier les points-virgules manquants
                for ($i = 0; $i -lt $lines.Count; $i++) {
                    $line = $lines[$i]
                    $lineNumber = $i + 1
                    
                    # Ignorer les lignes vides, les commentaires et les lignes se terminant par {, }, [, ], (, )
                    if ([string]::IsNullOrWhiteSpace($line) -or $line -match '^\s*//') {
                        continue
                    }
                    
                    if ($line -match '[^{}\[\]();]\s*$') {
                        $results.Add([PSCustomObject]@{
                            Type = "Style"
                            Line = $lineNumber
                            Column = $line.Length
                            Message = "Point-virgule manquant à la fin de la ligne."
                            Severity = "Warning"
                            Rule = "SemicolonRequired"
                        })
                    }
                }
            }
            
            # Appliquer les règles spécifiques
            foreach ($rule in $rules.GetEnumerator()) {
                if ($rule.Value.Language -eq "JavaScript" -or $rule.Value.Language -eq "All") {
                    $ruleResults = & $rule.Value.Handler $content $null
                    foreach ($result in $ruleResults) {
                        $result | Add-Member -MemberType NoteProperty -Name "Rule" -Value $rule.Key -Force
                        $results.Add($result)
                    }
                }
            }
            
            return $results
        }
    }

    # Obtenir le gestionnaire HTML
    [scriptblock] GetHtmlHandler() {
        return {
            param($content, $rules)
            
            $results = [System.Collections.Generic.List[object]]::new()
            
            # Analyse basique
            $lines = $content -split "`n"
            
            # Vérifier les balises non fermées
            $openTags = [System.Collections.Generic.Stack[PSCustomObject]]::new()
            
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $line = $lines[$i]
                $lineNumber = $i + 1
                
                # Trouver les balises ouvrantes
                $openingTags = [regex]::Matches($line, '<([a-zA-Z][a-zA-Z0-9]*)[^>]*>')
                foreach ($tag in $openingTags) {
                    $tagName = $tag.Groups[1].Value
                    
                    # Ignorer les balises auto-fermantes
                    if ($tag.Value -match '/>$' -or $tagName -in @('img', 'br', 'hr', 'input', 'meta', 'link')) {
                        continue
                    }
                    
                    $openTags.Push([PSCustomObject]@{
                        Name = $tagName
                        Line = $lineNumber
                        Column = $tag.Index + 1
                    })
                }
                
                # Trouver les balises fermantes
                $closingTags = [regex]::Matches($line, '</([a-zA-Z][a-zA-Z0-9]*)>')
                foreach ($tag in $closingTags) {
                    $tagName = $tag.Groups[1].Value
                    
                    if ($openTags.Count -eq 0) {
                        $results.Add([PSCustomObject]@{
                            Type = "Syntax"
                            Line = $lineNumber
                            Column = $tag.Index + 1
                            Message = "Balise fermante '$tagName' sans balise ouvrante correspondante."
                            Severity = "Error"
                            Rule = "UnmatchedTag"
                        })
                        continue
                    }
                    
                    $lastOpenTag = $openTags.Pop()
                    if ($lastOpenTag.Name -ne $tagName) {
                        $results.Add([PSCustomObject]@{
                            Type = "Syntax"
                            Line = $lineNumber
                            Column = $tag.Index + 1
                            Message = "Balise fermante '$tagName' ne correspond pas à la dernière balise ouvrante '$($lastOpenTag.Name)'."
                            Severity = "Error"
                            Rule = "MismatchedTag"
                        })
                        
                        # Remettre la balise ouvrante dans la pile
                        $openTags.Push($lastOpenTag)
                    }
                }
            }
            
            # Vérifier les balises non fermées à la fin
            while ($openTags.Count -gt 0) {
                $tag = $openTags.Pop()
                $results.Add([PSCustomObject]@{
                    Type = "Syntax"
                    Line = $tag.Line
                    Column = $tag.Column
                    Message = "Balise ouvrante '$($tag.Name)' sans balise fermante correspondante."
                    Severity = "Error"
                    Rule = "UnclosedTag"
                })
            }
            
            # Appliquer les règles spécifiques
            foreach ($rule in $rules.GetEnumerator()) {
                if ($rule.Value.Language -eq "HTML" -or $rule.Value.Language -eq "All") {
                    $ruleResults = & $rule.Value.Handler $content $null
                    foreach ($result in $ruleResults) {
                        $result | Add-Member -MemberType NoteProperty -Name "Rule" -Value $rule.Key -Force
                        $results.Add($result)
                    }
                }
            }
            
            return $results
        }
    }

    # Obtenir le gestionnaire CSS
    [scriptblock] GetCssHandler() {
        return {
            param($content, $rules)
            
            $results = [System.Collections.Generic.List[object]]::new()
            
            # Analyse basique
            $lines = $content -split "`n"
            
            # Vérifier les accolades non fermées
            $openBraces = 0
            
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $line = $lines[$i]
                $lineNumber = $i + 1
                
                # Compter les accolades
                $openCount = ($line | Select-String -Pattern '{' -AllMatches).Matches.Count
                $closeCount = ($line | Select-String -Pattern '}' -AllMatches).Matches.Count
                
                $openBraces += $openCount - $closeCount
                
                # Vérifier les points-virgules manquants
                if ($line -match '[^{}]\s*$' -and $line -match ':[^;{}]*$') {
                    $results.Add([PSCustomObject]@{
                        Type = "Syntax"
                        Line = $lineNumber
                        Column = $line.Length
                        Message = "Point-virgule manquant à la fin de la déclaration."
                        Severity = "Error"
                        Rule = "MissingSemicolon"
                    })
                }
            }
            
            # Vérifier les accolades non fermées à la fin
            if ($openBraces -ne 0) {
                $results.Add([PSCustomObject]@{
                    Type = "Syntax"
                    Line = $lines.Count
                    Column = 1
                    Message = "Accolades non équilibrées. Il manque $openBraces accolade(s) fermante(s)."
                    Severity = "Error"
                    Rule = "UnbalancedBraces"
                })
            }
            
            # Appliquer les règles spécifiques
            foreach ($rule in $rules.GetEnumerator()) {
                if ($rule.Value.Language -eq "CSS" -or $rule.Value.Language -eq "All") {
                    $ruleResults = & $rule.Value.Handler $content $null
                    foreach ($result in $ruleResults) {
                        $result | Add-Member -MemberType NoteProperty -Name "Rule" -Value $rule.Key -Force
                        $results.Add($result)
                    }
                }
            }
            
            return $results
        }
    }

    # Initialiser les règles par défaut
    [void] InitializeDefaultRules() {
        # Règles PowerShell
        $this.RegisterRule("PS001", "PowerShell", "Utilisation de variables non déclarées", {
            param($content, $tokens)
            
            $results = [System.Collections.Generic.List[object]]::new()
            $declaredVars = [System.Collections.Generic.HashSet[string]]::new()
            $usedVars = [System.Collections.Generic.List[PSCustomObject]]::new()
            
            # Trouver les variables déclarées
            $varDeclarations = [regex]::Matches($content, '\$([a-zA-Z0-9_]+)\s*=')
            foreach ($var in $varDeclarations) {
                $varName = $var.Groups[1].Value
                $declaredVars.Add($varName) | Out-Null
            }
            
            # Trouver les variables utilisées
            $varUsages = [regex]::Matches($content, '\$([a-zA-Z0-9_]+)')
            foreach ($var in $varUsages) {
                $varName = $var.Groups[1].Value
                $lineNumber = $content.Substring(0, $var.Index).Split("`n").Count
                
                # Ignorer les variables spéciales
                if ($varName -in @('_', 'PSItem', 'args', 'input', 'PSCmdlet', 'MyInvocation', 'PSBoundParameters', 'PSScriptRoot', 'PSCommandPath')) {
                    continue
                }
                
                $usedVars.Add([PSCustomObject]@{
                    Name = $varName
                    Line = $lineNumber
                    Index = $var.Index
                })
            }
            
            # Vérifier les variables non déclarées
            foreach ($var in $usedVars) {
                if (-not $declaredVars.Contains($var.Name)) {
                    $results.Add([PSCustomObject]@{
                        Type = "Style"
                        Line = $var.Line
                        Column = 1
                        Message = "Variable '$($var.Name)' utilisée mais non déclarée."
                        Severity = "Warning"
                    })
                    
                    # Ajouter la variable à la liste des déclarées pour éviter les doublons
                    $declaredVars.Add($var.Name) | Out-Null
                }
            }
            
            return $results
        })
        
        $this.RegisterRule("PS002", "PowerShell", "Lignes trop longues", {
            param($content, $tokens)
            
            $results = [System.Collections.Generic.List[object]]::new()
            $lines = $content -split "`n"
            $maxLength = 120
            
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $line = $lines[$i]
                $lineNumber = $i + 1
                
                if ($line.Length -gt $maxLength) {
                    $results.Add([PSCustomObject]@{
                        Type = "Style"
                        Line = $lineNumber
                        Column = $maxLength + 1
                        Message = "Ligne trop longue ($($line.Length) caractères, maximum recommandé: $maxLength)."
                        Severity = "Information"
                    })
                }
            }
            
            return $results
        })
        
        # Règles Python
        $this.RegisterRule("PY001", "Python", "Lignes trop longues", {
            param($content, $tokens)
            
            $results = [System.Collections.Generic.List[object]]::new()
            $lines = $content -split "`n"
            $maxLength = 79
            
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $line = $lines[$i]
                $lineNumber = $i + 1
                
                if ($line.Length -gt $maxLength) {
                    $results.Add([PSCustomObject]@{
                        Type = "Style"
                        Line = $lineNumber
                        Column = $maxLength + 1
                        Message = "Ligne trop longue ($($line.Length) caractères, maximum recommandé: $maxLength)."
                        Severity = "Information"
                    })
                }
            }
            
            return $results
        })
    }

    # Enregistrer une règle
    [void] RegisterRule([string]$id, [string]$language, [string]$description, [scriptblock]$handler) {
        $this.RuleSet[$id] = [PSCustomObject]@{
            ID = $id
            Language = $language
            Description = $description
            Handler = $handler
        }
    }

    # Analyser un fichier
    [object[]] AnalyzeFile([string]$filePath) {
        if (-not (Test-Path -Path $filePath)) {
            Write-Error "Le fichier n'existe pas: $filePath"
            return @()
        }
        
        try {
            # Vérifier le cache
            if ($this.UseCache -and $null -ne $this.Cache) {
                $cacheKey = "SyntaxAnalysis:$filePath:$((Get-FileHash -Path $filePath -Algorithm SHA256).Hash)"
                $cachedResults = $this.Cache.Get($cacheKey)
                
                if ($null -ne $cachedResults) {
                    return $cachedResults
                }
            }
            
            # Déterminer le gestionnaire à utiliser
            $extension = [System.IO.Path]::GetExtension($filePath)
            $handler = $null
            
            if ($this.LanguageHandlers.ContainsKey($extension)) {
                $handler = $this.LanguageHandlers[$extension]
            } else {
                # Utiliser un gestionnaire générique
                $handler = {
                    param($content, $rules)
                    return @()
                }
            }
            
            # Lire le contenu du fichier
            $content = Get-Content -Path $filePath -Raw
            
            # Analyser le contenu
            $results = & $handler $content $this.RuleSet
            
            # Mettre en cache les résultats
            if ($this.UseCache -and $null -ne $this.Cache) {
                $this.Cache.Set($cacheKey, $results)
            }
            
            return $results
        } catch {
            Write-Error "Erreur lors de l'analyse du fichier $filePath : $_"
            return @()
        }
    }

    # Analyser plusieurs fichiers en parallèle
    [hashtable] AnalyzeFiles([string[]]$filePaths) {
        $results = @{}
        
        if ($filePaths.Count -eq 0) {
            return $results
        }
        
        if ($filePaths.Count -eq 1) {
            $results[$filePaths[0]] = $this.AnalyzeFile($filePaths[0])
            return $results
        }
        
        # Utiliser des runspaces pour l'analyse parallèle
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $pool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $this.MaxConcurrentAnalyses, $sessionState, $Host)
        $pool.Open()
        
        $runspaces = @()
        
        foreach ($filePath in $filePaths) {
            $powershell = [System.Management.Automation.PowerShell]::Create()
            $powershell.RunspacePool = $pool
            
            # Créer un script pour analyser le fichier
            $script = {
                param($filePath, $analyzer)
                
                try {
                    $fileResults = $analyzer.AnalyzeFile($filePath)
                    return [PSCustomObject]@{
                        FilePath = $filePath
                        Results = $fileResults
                        Success = $true
                        Error = $null
                    }
                } catch {
                    return [PSCustomObject]@{
                        FilePath = $filePath
                        Results = @()
                        Success = $false
                        Error = $_
                    }
                }
            }
            
            # Ajouter les paramètres
            $powershell.AddScript($script).AddArgument($filePath).AddArgument($this) | Out-Null
            
            # Démarrer l'exécution asynchrone
            $runspaces += [PSCustomObject]@{
                PowerShell = $powershell
                Runspace = $powershell.BeginInvoke()
                FilePath = $filePath
            }
        }
        
        # Attendre et récupérer les résultats
        foreach ($runspace in $runspaces) {
            $result = $runspace.PowerShell.EndInvoke($runspace.Runspace)
            
            if ($result.Success) {
                $results[$result.FilePath] = $result.Results
            } else {
                Write-Warning "Erreur lors de l'analyse du fichier $($result.FilePath): $($result.Error)"
                $results[$result.FilePath] = @()
            }
            
            $runspace.PowerShell.Dispose()
        }
        
        $pool.Close()
        $pool.Dispose()
        
        return $results
    }
}

# Fonction pour créer un nouvel analyseur syntaxique
function New-SyntaxAnalyzer {
    [CmdletBinding()]
    [OutputType([SyntaxAnalyzer])]
    param(
        [Parameter()]
        [bool]$UseCache = $false,
        
        [Parameter()]
        [object]$Cache = $null,
        
        [Parameter()]
        [int]$MaxConcurrentAnalyses = 0
    )
    
    try {
        $analyzer = [SyntaxAnalyzer]::new($UseCache, $Cache, $MaxConcurrentAnalyses)
        return $analyzer
    } catch {
        Write-Error "Erreur lors de la création de l'analyseur syntaxique: $_"
        return $null
    }
}

# Fonction pour analyser un fichier
function Invoke-SyntaxAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [SyntaxAnalyzer]$Analyzer,
        
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$FilePath
    )
    
    process {
        try {
            $results = $Analyzer.AnalyzeFile($FilePath)
            return $results
        } catch {
            Write-Error "Erreur lors de l'analyse du fichier: $_"
            return @()
        }
    }
}

# Fonction pour analyser plusieurs fichiers
function Invoke-BatchSyntaxAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [SyntaxAnalyzer]$Analyzer,
        
        [Parameter(Mandatory = $true)]
        [string[]]$FilePaths
    )
    
    try {
        $results = $Analyzer.AnalyzeFiles($FilePaths)
        return $results
    } catch {
        Write-Error "Erreur lors de l'analyse des fichiers: $_"
        return @{}
    }
}

# Fonction pour enregistrer une règle personnalisée
function Register-SyntaxRule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [SyntaxAnalyzer]$Analyzer,
        
        [Parameter(Mandatory = $true)]
        [string]$ID,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("PowerShell", "Python", "JavaScript", "HTML", "CSS", "All")]
        [string]$Language,
        
        [Parameter(Mandatory = $true)]
        [string]$Description,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$Handler
    )
    
    try {
        $Analyzer.RegisterRule($ID, $Language, $Description, $Handler)
    } catch {
        Write-Error "Erreur lors de l'enregistrement de la règle: $_"
    }
}

# Exporter les fonctions
Export-ModuleMember -Function New-SyntaxAnalyzer, Invoke-SyntaxAnalysis, Invoke-BatchSyntaxAnalysis, Register-SyntaxRule
