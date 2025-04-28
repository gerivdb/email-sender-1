#
# Module SyntaxAnalyzer
# Analyseur de syntaxe pour diffÃ©rents langages de programmation
#

# Classe SyntaxAnalyzer
class SyntaxAnalyzer {
    [bool]$UseCache
    [object]$Cache
    [hashtable]$LanguageAnalyzers
    
    SyntaxAnalyzer([bool]$useCache, [object]$cache) {
        $this.UseCache = $useCache
        $this.Cache = $cache
        $this.LanguageAnalyzers = @{}
    }
    
    [array] AnalyzeFile([string]$filePath) {
        # VÃ©rifier si le fichier existe
        if (-not (Test-Path -Path $filePath -PathType Leaf)) {
            Write-Warning "Le fichier n'existe pas: $filePath"
            return @()
        }
        
        # VÃ©rifier le cache si activÃ©
        if ($this.UseCache -and $this.Cache) {
            $cachedResult = $this.Cache.GetItem($filePath)
            if ($cachedResult) {
                return $cachedResult
            }
        }
        
        # DÃ©terminer le langage en fonction de l'extension du fichier
        $extension = [System.IO.Path]::GetExtension($filePath).ToLower()
        $language = switch ($extension) {
            { $_ -in @(".ps1", ".psm1", ".psd1") } { "PowerShell" }
            ".py" { "Python" }
            { $_ -in @(".js", ".jsx", ".ts", ".tsx") } { "JavaScript" }
            { $_ -in @(".html", ".htm") } { "HTML" }
            { $_ -in @(".css", ".scss", ".sass") } { "CSS" }
            default { $null }
        }
        
        if (-not $language) {
            Write-Warning "Extension de fichier non prise en charge: $extension"
            return @()
        }
        
        # Obtenir l'analyseur de langage appropriÃ©
        $analyzer = $this.GetLanguageAnalyzer($language)
        
        # Analyser le fichier
        $issues = @()
        
        try {
            # Lire le contenu du fichier
            $content = Get-Content -Path $filePath -Raw -ErrorAction Stop
            
            # Analyser la syntaxe en fonction du langage
            switch ($language) {
                "PowerShell" { $issues = $this.AnalyzePowerShell($filePath, $content, $analyzer) }
                "Python" { $issues = $this.AnalyzePython($filePath, $content, $analyzer) }
                "JavaScript" { $issues = $this.AnalyzeJavaScript($filePath, $content, $analyzer) }
                "HTML" { $issues = $this.AnalyzeHTML($filePath, $content) }
                "CSS" { $issues = $this.AnalyzeCSS($filePath, $content) }
            }
        }
        catch {
            Write-Error "Erreur lors de l'analyse du fichier $filePath : $_"
        }
        
        # Mettre en cache le rÃ©sultat si le cache est activÃ©
        if ($this.UseCache -and $this.Cache) {
            $this.Cache.SetItem($filePath, $issues)
        }
        
        return $issues
    }
    
    [object] GetLanguageAnalyzer([string]$language) {
        if (-not $this.LanguageAnalyzers.ContainsKey($language)) {
            try {
                # Essayer d'importer le module LanguageSpecificAnalyzer
                $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "LanguageSpecificAnalyzer.psm1"
                if (Test-Path -Path $modulePath) {
                    Import-Module $modulePath -Force
                    $this.LanguageAnalyzers[$language] = New-LanguageAnalyzer -Language $language
                }
                else {
                    Write-Warning "Module LanguageSpecificAnalyzer non trouvÃ©: $modulePath"
                    $this.LanguageAnalyzers[$language] = $null
                }
            }
            catch {
                Write-Error "Erreur lors de la crÃ©ation de l'analyseur de langage pour $language : $_"
                $this.LanguageAnalyzers[$language] = $null
            }
        }
        
        return $this.LanguageAnalyzers[$language]
    }
    
    [array] AnalyzePowerShell([string]$filePath, [string]$content, [object]$analyzer) {
        $issues = @()
        
        if ($analyzer) {
            # Utiliser l'analyseur spÃ©cifique au langage
            $issues = $analyzer.AnalyzeFile($filePath)
        }
        else {
            # Analyse de base
            $tokens = $null
            $parseErrors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$tokens, [ref]$parseErrors)
            
            foreach ($error in $parseErrors) {
                $issues += [PSCustomObject]@{
                    Line = $error.Extent.StartLineNumber
                    Column = $error.Extent.StartColumnNumber
                    Message = $error.Message
                    Severity = "Error"
                    Type = "SyntaxError"
                    Category = "Syntax"
                }
            }
        }
        
        return $issues
    }
    
    [array] AnalyzePython([string]$filePath, [string]$content, [object]$analyzer) {
        $issues = @()
        
        if ($analyzer) {
            # Utiliser l'analyseur spÃ©cifique au langage
            $issues = $analyzer.AnalyzeFile($filePath)
        }
        else {
            # Analyse de base
            $lines = $content -split "`n"
            
            # VÃ©rifier l'indentation
            $indentLevel = 0
            $indentSize = 0
            $indentChar = $null
            
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $lineNumber = $i + 1
                $line = $lines[$i]
                
                # Ignorer les lignes vides et les commentaires
                if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith("#")) {
                    continue
                }
                
                # VÃ©rifier l'indentation
                if ($line -match "^\s+") {
                    $indent = $matches[0]
                    
                    # DÃ©terminer le caractÃ¨re d'indentation
                    if ($indentChar -eq $null) {
                        $indentChar = if ($indent.Contains("`t")) { "`t" } else { " " }
                        $indentSize = $indent.Length
                    }
                    
                    # VÃ©rifier la cohÃ©rence de l'indentation
                    if ($indent.Contains(" ") -and $indent.Contains("`t")) {
                        $issues += [PSCustomObject]@{
                            Line = $lineNumber
                            Column = 1
                            Message = "MÃ©lange d'espaces et de tabulations dans l'indentation"
                            Severity = "Warning"
                            Type = "IndentationError"
                            Category = "Style"
                        }
                    }
                    
                    # VÃ©rifier la taille de l'indentation
                    if ($indentSize -gt 0 -and $indent.Length % $indentSize -ne 0) {
                        $issues += [PSCustomObject]@{
                            Line = $lineNumber
                            Column = 1
                            Message = "Indentation incohÃ©rente"
                            Severity = "Warning"
                            Type = "IndentationError"
                            Category = "Style"
                        }
                    }
                }
                
                # VÃ©rifier les erreurs de syntaxe Ã©videntes
                if ($line -match ":\s*\w+") {
                    $issues += [PSCustomObject]@{
                        Line = $lineNumber
                        Column = $line.IndexOf(":") + 1
                        Message = "Erreur de syntaxe: caractÃ¨res aprÃ¨s les deux-points"
                        Severity = "Error"
                        Type = "SyntaxError"
                        Category = "Syntax"
                    }
                }
            }
        }
        
        return $issues
    }
    
    [array] AnalyzeJavaScript([string]$filePath, [string]$content, [object]$analyzer) {
        $issues = @()
        
        if ($analyzer) {
            # Utiliser l'analyseur spÃ©cifique au langage
            $issues = $analyzer.AnalyzeFile($filePath)
        }
        else {
            # Analyse de base
            $lines = $content -split "`n"
            
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $lineNumber = $i + 1
                $line = $lines[$i]
                
                # Ignorer les lignes vides et les commentaires
                if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith("//")) {
                    continue
                }
                
                # VÃ©rifier les points-virgules manquants
                if ($line -match "^\s*\w.*[^;,{}\[\]]\s*$" -and $line -notmatch "^\s*\/\/") {
                    $issues += [PSCustomObject]@{
                        Line = $lineNumber
                        Column = $line.Length
                        Message = "Point-virgule manquant Ã  la fin de l'instruction"
                        Severity = "Warning"
                        Type = "SemicolonError"
                        Category = "Style"
                    }
                }
                
                # VÃ©rifier les accolades non fermÃ©es
                $openBraces = ($line.ToCharArray() | Where-Object { $_ -eq '{' }).Count
                $closeBraces = ($line.ToCharArray() | Where-Object { $_ -eq '}' }).Count
                
                if ($openBraces -ne $closeBraces) {
                    $issues += [PSCustomObject]@{
                        Line = $lineNumber
                        Column = 1
                        Message = "Accolades non Ã©quilibrÃ©es"
                        Severity = "Warning"
                        Type = "BraceError"
                        Category = "Syntax"
                    }
                }
            }
        }
        
        return $issues
    }
    
    [array] AnalyzeHTML([string]$filePath, [string]$content) {
        $issues = @()
        
        # Analyse de base
        $lines = $content -split "`n"
        $openTags = @()
        
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $lineNumber = $i + 1
            $line = $lines[$i]
            
            # Trouver les balises ouvrantes
            $openMatches = [regex]::Matches($line, "<([a-zA-Z][a-zA-Z0-9]*)[^>]*>")
            foreach ($match in $openMatches) {
                $tagName = $match.Groups[1].Value.ToLower()
                if ($tagName -notin @("br", "hr", "img", "input", "link", "meta")) {
                    $openTags += @{
                        Tag = $tagName
                        Line = $lineNumber
                        Column = $match.Index + 1
                    }
                }
            }
            
            # Trouver les balises fermantes
            $closeMatches = [regex]::Matches($line, "</([a-zA-Z][a-zA-Z0-9]*)>")
            foreach ($match in $closeMatches) {
                $tagName = $match.Groups[1].Value.ToLower()
                
                if ($openTags.Count -eq 0) {
                    $issues += [PSCustomObject]@{
                        Line = $lineNumber
                        Column = $match.Index + 1
                        Message = "Balise fermante '$tagName' sans balise ouvrante correspondante"
                        Severity = "Error"
                        Type = "HTMLError"
                        Category = "Syntax"
                    }
                }
                elseif ($openTags[-1].Tag -ne $tagName) {
                    $issues += [PSCustomObject]@{
                        Line = $lineNumber
                        Column = $match.Index + 1
                        Message = "Balise fermante '$tagName' ne correspond pas Ã  la derniÃ¨re balise ouvrante '$($openTags[-1].Tag)'"
                        Severity = "Error"
                        Type = "HTMLError"
                        Category = "Syntax"
                    }
                }
                else {
                    $openTags = $openTags[0..($openTags.Count - 2)]
                }
            }
        }
        
        # VÃ©rifier les balises non fermÃ©es
        foreach ($tag in $openTags) {
            $issues += [PSCustomObject]@{
                Line = $tag.Line
                Column = $tag.Column
                Message = "Balise ouvrante '$($tag.Tag)' sans balise fermante correspondante"
                Severity = "Error"
                Type = "HTMLError"
                Category = "Syntax"
            }
        }
        
        return $issues
    }
    
    [array] AnalyzeCSS([string]$filePath, [string]$content) {
        $issues = @()
        
        # Analyse de base
        $lines = $content -split "`n"
        $inComment = $false
        $inSelector = $false
        $inBlock = $false
        $selectorLine = 0
        $selectorColumn = 0
        
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $lineNumber = $i + 1
            $line = $lines[$i]
            
            # GÃ©rer les commentaires
            if ($inComment) {
                if ($line -match "\*/") {
                    $inComment = $false
                }
                continue
            }
            
            if ($line -match "/\*") {
                $inComment = $true
                if ($line -match "\*/") {
                    $inComment = $false
                }
                continue
            }
            
            # Ignorer les lignes vides et les commentaires
            if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith("//")) {
                continue
            }
            
            # VÃ©rifier les accolades
            if ($line -match "{") {
                if ($inBlock) {
                    $issues += [PSCustomObject]@{
                        Line = $lineNumber
                        Column = $line.IndexOf("{") + 1
                        Message = "Accolade ouvrante inattendue"
                        Severity = "Error"
                        Type = "CSSError"
                        Category = "Syntax"
                    }
                }
                else {
                    $inBlock = $true
                    $inSelector = $false
                }
            }
            
            if ($line -match "}") {
                if (-not $inBlock) {
                    $issues += [PSCustomObject]@{
                        Line = $lineNumber
                        Column = $line.IndexOf("}") + 1
                        Message = "Accolade fermante inattendue"
                        Severity = "Error"
                        Type = "CSSError"
                        Category = "Syntax"
                    }
                }
                else {
                    $inBlock = $false
                }
            }
            
            # VÃ©rifier les propriÃ©tÃ©s
            if ($inBlock -and $line -match "([a-zA-Z-]+)\s*:") {
                $property = $matches[1]
                
                # VÃ©rifier les points-virgules manquants
                if ($line -notmatch ";") {
                    $issues += [PSCustomObject]@{
                        Line = $lineNumber
                        Column = $line.Length
                        Message = "Point-virgule manquant Ã  la fin de la propriÃ©tÃ©"
                        Severity = "Warning"
                        Type = "CSSError"
                        Category = "Style"
                    }
                }
            }
        }
        
        # VÃ©rifier les blocs non fermÃ©s
        if ($inBlock) {
            $issues += [PSCustomObject]@{
                Line = $selectorLine
                Column = $selectorColumn
                Message = "Bloc CSS non fermÃ©"
                Severity = "Error"
                Type = "CSSError"
                Category = "Syntax"
            }
        }
        
        return $issues
    }
}

# Fonction pour crÃ©er un nouvel analyseur de syntaxe
function New-SyntaxAnalyzer {
    [CmdletBinding()]
    param(
        [Parameter()]
        [bool]$UseCache = $false,
        
        [Parameter()]
        [object]$Cache = $null
    )
    
    return [SyntaxAnalyzer]::new($UseCache, $Cache)
}

# Exporter les fonctions
Export-ModuleMember -Function New-SyntaxAnalyzer
