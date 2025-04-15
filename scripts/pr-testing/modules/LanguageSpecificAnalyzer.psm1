#
# Module LanguageSpecificAnalyzer
# Analyseurs spécialisés pour différents langages de programmation
#

# Classe de base pour les analyseurs de langage
class LanguageAnalyzer {
    [string]$Language
    [hashtable]$Rules
    [hashtable]$PerformanceMetrics
    
    LanguageAnalyzer([string]$language) {
        $this.Language = $language
        $this.Rules = @{}
        $this.PerformanceMetrics = @{
            FilesAnalyzed = 0
            TotalAnalysisTime = [System.Diagnostics.Stopwatch]::new()
            AverageTimePerFile = 0
            TotalIssuesFound = 0
            LastAnalyzedFile = ""
        }
    }
    
    [array] AnalyzeFile([string]$filePath) {
        throw "Cette méthode doit être implémentée par les classes dérivées"
    }
    
    [void] AddRule([string]$name, [scriptblock]$rule, [string]$message, [string]$severity, [string]$category) {
        $this.Rules[$name] = @{
            Rule = $rule
            Message = $message
            Severity = $severity
            Category = $category
        }
    }
    
    [void] UpdatePerformanceMetrics([string]$filePath, [timespan]$duration, [int]$issueCount) {
        $this.PerformanceMetrics.FilesAnalyzed++
        $this.PerformanceMetrics.TotalAnalysisTime.Elapsed += $duration
        $this.PerformanceMetrics.AverageTimePerFile = $this.PerformanceMetrics.TotalAnalysisTime.ElapsedMilliseconds / $this.PerformanceMetrics.FilesAnalyzed
        $this.PerformanceMetrics.TotalIssuesFound += $issueCount
        $this.PerformanceMetrics.LastAnalyzedFile = $filePath
    }
    
    [hashtable] GetPerformanceMetrics() {
        return $this.PerformanceMetrics
    }
}

# Analyseur pour PowerShell
class PowerShellAnalyzer : LanguageAnalyzer {
    PowerShellAnalyzer() : base("PowerShell") {
        # Règles de style
        $this.AddRule("AvoidUsingCmdletAliases", {
            param($ast)
            $aliases = @{
                "gci" = "Get-ChildItem"
                "dir" = "Get-ChildItem"
                "ls" = "Get-ChildItem"
                "cd" = "Set-Location"
                "chdir" = "Set-Location"
                "clear" = "Clear-Host"
                "cp" = "Copy-Item"
                "copy" = "Copy-Item"
                "ft" = "Format-Table"
                "fw" = "Format-Wide"
                "fl" = "Format-List"
                "gc" = "Get-Content"
                "cat" = "Get-Content"
                "type" = "Get-Content"
                "gi" = "Get-Item"
                "gl" = "Get-Location"
                "pwd" = "Get-Location"
                "gm" = "Get-Member"
                "gp" = "Get-ItemProperty"
                "gps" = "Get-Process"
                "ps" = "Get-Process"
                "gsv" = "Get-Service"
                "gu" = "Get-Unique"
                "gv" = "Get-Variable"
                "iex" = "Invoke-Expression"
                "ihy" = "Invoke-History"
                "ii" = "Invoke-Item"
                "ipal" = "Import-Alias"
                "ipcsv" = "Import-Csv"
                "ipmo" = "Import-Module"
                "irm" = "Invoke-RestMethod"
                "ise" = "powershell_ise.exe"
                "iwmi" = "Invoke-WmiMethod"
                "iwr" = "Invoke-WebRequest"
                "kill" = "Stop-Process"
                "lp" = "Out-Printer"
                "man" = "help"
                "md" = "mkdir"
                "measure" = "Measure-Object"
                "mi" = "Move-Item"
                "move" = "Move-Item"
                "mp" = "Move-ItemProperty"
                "nal" = "New-Alias"
                "ndr" = "New-PSDrive"
                "ni" = "New-Item"
                "nmo" = "New-Module"
                "npssc" = "New-PSSessionConfigurationFile"
                "nsn" = "New-PSSession"
                "nv" = "New-Variable"
                "ogv" = "Out-GridView"
                "oh" = "Out-Host"
                "popd" = "Pop-Location"
                "pushd" = "Push-Location"
                "r" = "Invoke-History"
                "rbp" = "Remove-PSBreakpoint"
                "rcjb" = "Receive-Job"
                "rcsn" = "Receive-PSSession"
                "rd" = "Remove-Item"
                "rdr" = "Remove-PSDrive"
                "ri" = "Remove-Item"
                "rm" = "Remove-Item"
                "rmdir" = "Remove-Item"
                "rmo" = "Remove-Module"
                "rni" = "Rename-Item"
                "rnp" = "Rename-ItemProperty"
                "rp" = "Remove-ItemProperty"
                "rv" = "Remove-Variable"
                "rvpa" = "Resolve-Path"
                "sajb" = "Start-Job"
                "sal" = "Set-Alias"
                "saps" = "Start-Process"
                "sasv" = "Start-Service"
                "sbp" = "Set-PSBreakpoint"
                "sc" = "Set-Content"
                "select" = "Select-Object"
                "set" = "Set-Variable"
                "si" = "Set-Item"
                "sl" = "Set-Location"
                "sleep" = "Start-Sleep"
                "sls" = "Select-String"
                "sort" = "Sort-Object"
                "sp" = "Set-ItemProperty"
                "spjb" = "Stop-Job"
                "spps" = "Stop-Process"
                "spsv" = "Stop-Service"
                "start" = "Start-Process"
                "sv" = "Set-Variable"
                "swmi" = "Set-WmiInstance"
                "tee" = "Tee-Object"
                "where" = "Where-Object"
                "write" = "Write-Output"
                "echo" = "Write-Output"
            }
            
            $commandAst = $ast -as [System.Management.Automation.Language.CommandAst]
            if ($commandAst -and $commandAst.CommandElements.Count -gt 0) {
                $commandName = $commandAst.CommandElements[0].Value
                if ($aliases.ContainsKey($commandName)) {
                    return @{
                        Message = "L'alias '$commandName' est utilisé au lieu de '$($aliases[$commandName])'"
                        Line = $commandAst.Extent.StartLineNumber
                        Column = $commandAst.Extent.StartColumnNumber
                    }
                }
            }
            
            return $null
        }, "Évitez d'utiliser des alias de cmdlet", "Warning", "Style")
        
        # Règles de sécurité
        $this.AddRule("AvoidUsingPlainTextForPassword", {
            param($ast)
            $paramAst = $ast -as [System.Management.Automation.Language.ParameterAst]
            if ($paramAst) {
                $paramName = $paramAst.Name.VariablePath.UserPath
                if ($paramName -match "password|pwd|passphrase|secret|credential" -and $paramName -notmatch "secure") {
                    return @{
                        Message = "Le paramètre '$paramName' pourrait contenir un mot de passe en texte clair"
                        Line = $paramAst.Extent.StartLineNumber
                        Column = $paramAst.Extent.StartColumnNumber
                    }
                }
            }
            
            return $null
        }, "Évitez d'utiliser du texte en clair pour les mots de passe", "Error", "Security")
        
        # Règles de performance
        $this.AddRule("AvoidUsingForEachMethod", {
            param($ast)
            $invokeMemberAst = $ast -as [System.Management.Automation.Language.InvokeMemberExpressionAst]
            if ($invokeMemberAst -and $invokeMemberAst.Member.Value -eq "ForEach") {
                return @{
                    Message = "Utilisez l'opérateur de pipeline ForEach-Object au lieu de la méthode .ForEach() pour de meilleures performances"
                    Line = $invokeMemberAst.Extent.StartLineNumber
                    Column = $invokeMemberAst.Extent.StartColumnNumber
                }
            }
            
            return $null
        }, "Évitez d'utiliser la méthode .ForEach()", "Warning", "Performance")
        
        # Règles de bonnes pratiques
        $this.AddRule("AvoidUsingPositionalParameters", {
            param($ast)
            $commandAst = $ast -as [System.Management.Automation.Language.CommandAst]
            if ($commandAst -and $commandAst.CommandElements.Count -gt 1) {
                $commandName = $commandAst.CommandElements[0].Value
                $hasPositionalParam = $false
                
                for ($i = 1; $i -lt $commandAst.CommandElements.Count; $i++) {
                    $element = $commandAst.CommandElements[$i]
                    if ($element -isnot [System.Management.Automation.Language.CommandParameterAst] -and 
                        $element -isnot [System.Management.Automation.Language.ScriptBlockExpressionAst]) {
                        $hasPositionalParam = $true
                        break
                    }
                }
                
                if ($hasPositionalParam) {
                    return @{
                        Message = "Évitez d'utiliser des paramètres positionnels pour la commande '$commandName'"
                        Line = $commandAst.Extent.StartLineNumber
                        Column = $commandAst.Extent.StartColumnNumber
                    }
                }
            }
            
            return $null
        }, "Évitez d'utiliser des paramètres positionnels", "Warning", "BestPractices")
    }
    
    [array] AnalyzeFile([string]$filePath) {
        $issues = @()
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        try {
            # Vérifier que le fichier existe
            if (-not (Test-Path -Path $filePath -PathType Leaf)) {
                Write-Warning "Le fichier n'existe pas: $filePath"
                return $issues
            }
            
            # Vérifier l'extension du fichier
            $extension = [System.IO.Path]::GetExtension($filePath).ToLower()
            if ($extension -notin @(".ps1", ".psm1", ".psd1")) {
                Write-Warning "Le fichier n'est pas un script PowerShell: $filePath"
                return $issues
            }
            
            # Lire le contenu du fichier
            $content = Get-Content -Path $filePath -Raw
            
            # Parser le script
            $tokens = $null
            $parseErrors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$tokens, [ref]$parseErrors)
            
            # Ajouter les erreurs de syntaxe
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
            
            # Appliquer les règles
            $astVisitor = {
                param($ast)
                
                foreach ($ruleName in $this.Rules.Keys) {
                    $rule = $this.Rules[$ruleName]
                    $result = & $rule.Rule $ast
                    
                    if ($result) {
                        $issues += [PSCustomObject]@{
                            Line = $result.Line
                            Column = $result.Column
                            Message = $result.Message
                            Severity = $rule.Severity
                            Type = $ruleName
                            Category = $rule.Category
                        }
                    }
                }
                
                return $true
            }
            
            # Visiter tous les nœuds de l'AST
            $ast.Visit($astVisitor)
        }
        catch {
            Write-Error "Erreur lors de l'analyse du fichier $filePath : $_"
        }
        finally {
            $stopwatch.Stop()
            $this.UpdatePerformanceMetrics($filePath, $stopwatch.Elapsed, $issues.Count)
        }
        
        return $issues
    }
}

# Analyseur pour Python
class PythonAnalyzer : LanguageAnalyzer {
    PythonAnalyzer() : base("Python") {
        # Règles de style
        $this.AddRule("UseConsistentIndentation", {
            param($line, $lineNumber, $content)
            if ($line -match "^\s+") {
                $indentation = $matches[0]
                if ($indentation -match " " -and $indentation -match "\t") {
                    return @{
                        Message = "Mélange d'espaces et de tabulations dans l'indentation"
                        Line = $lineNumber
                        Column = 1
                    }
                }
            }
            
            return $null
        }, "Utilisez une indentation cohérente", "Warning", "Style")
        
        # Règles de sécurité
        $this.AddRule("AvoidUsingEval", {
            param($line, $lineNumber, $content)
            if ($line -match "\beval\s*\(") {
                return @{
                    Message = "Évitez d'utiliser eval() pour des raisons de sécurité"
                    Line = $lineNumber
                    Column = $line.IndexOf("eval")
                }
            }
            
            return $null
        }, "Évitez d'utiliser eval()", "Error", "Security")
        
        # Règles de performance
        $this.AddRule("AvoidUsingGlobals", {
            param($line, $lineNumber, $content)
            if ($line -match "\bglobal\b") {
                return @{
                    Message = "Évitez d'utiliser des variables globales pour de meilleures performances"
                    Line = $lineNumber
                    Column = $line.IndexOf("global")
                }
            }
            
            return $null
        }, "Évitez d'utiliser des variables globales", "Warning", "Performance")
        
        # Règles de bonnes pratiques
        $this.AddRule("UseWithForFileOperations", {
            param($line, $lineNumber, $content)
            if ($line -match "\bopen\s*\(" -and $content -notmatch "with\s+open\s*\(") {
                return @{
                    Message = "Utilisez 'with open()' pour les opérations sur les fichiers"
                    Line = $lineNumber
                    Column = $line.IndexOf("open")
                }
            }
            
            return $null
        }, "Utilisez 'with' pour les opérations sur les fichiers", "Warning", "BestPractices")
    }
    
    [array] AnalyzeFile([string]$filePath) {
        $issues = @()
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        try {
            # Vérifier que le fichier existe
            if (-not (Test-Path -Path $filePath -PathType Leaf)) {
                Write-Warning "Le fichier n'existe pas: $filePath"
                return $issues
            }
            
            # Vérifier l'extension du fichier
            $extension = [System.IO.Path]::GetExtension($filePath).ToLower()
            if ($extension -ne ".py") {
                Write-Warning "Le fichier n'est pas un script Python: $filePath"
                return $issues
            }
            
            # Lire le contenu du fichier
            $content = Get-Content -Path $filePath -Raw
            $lines = $content -split "`n"
            
            # Appliquer les règles
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $lineNumber = $i + 1
                $line = $lines[$i]
                
                foreach ($ruleName in $this.Rules.Keys) {
                    $rule = $this.Rules[$ruleName]
                    $result = & $rule.Rule $line $lineNumber $content
                    
                    if ($result) {
                        $issues += [PSCustomObject]@{
                            Line = $result.Line
                            Column = $result.Column
                            Message = $result.Message
                            Severity = $rule.Severity
                            Type = $ruleName
                            Category = $rule.Category
                        }
                    }
                }
            }
        }
        catch {
            Write-Error "Erreur lors de l'analyse du fichier $filePath : $_"
        }
        finally {
            $stopwatch.Stop()
            $this.UpdatePerformanceMetrics($filePath, $stopwatch.Elapsed, $issues.Count)
        }
        
        return $issues
    }
}

# Analyseur pour JavaScript
class JavaScriptAnalyzer : LanguageAnalyzer {
    JavaScriptAnalyzer() : base("JavaScript") {
        # Règles de style
        $this.AddRule("UseSemicolons", {
            param($line, $lineNumber, $content)
            if ($line -match "^\s*\w.*[^;,{}\[\]]\s*$" -and $line -notmatch "^\s*\/\/") {
                return @{
                    Message = "Utilisez des points-virgules à la fin des instructions"
                    Line = $lineNumber
                    Column = $line.Length
                }
            }
            
            return $null
        }, "Utilisez des points-virgules", "Warning", "Style")
        
        # Règles de sécurité
        $this.AddRule("AvoidUsingEval", {
            param($line, $lineNumber, $content)
            if ($line -match "\beval\s*\(") {
                return @{
                    Message = "Évitez d'utiliser eval() pour des raisons de sécurité"
                    Line = $lineNumber
                    Column = $line.IndexOf("eval")
                }
            }
            
            return $null
        }, "Évitez d'utiliser eval()", "Error", "Security")
        
        # Règles de performance
        $this.AddRule("AvoidUsingDocumentWrite", {
            param($line, $lineNumber, $content)
            if ($line -match "\bdocument\.write\s*\(") {
                return @{
                    Message = "Évitez d'utiliser document.write() pour de meilleures performances"
                    Line = $lineNumber
                    Column = $line.IndexOf("document.write")
                }
            }
            
            return $null
        }, "Évitez d'utiliser document.write()", "Warning", "Performance")
        
        # Règles de bonnes pratiques
        $this.AddRule("UseStrictMode", {
            param($line, $lineNumber, $content)
            if ($lineNumber -eq 1 -and $content -notmatch "^\s*['\"]use strict['\"];") {
                return @{
                    Message = "Utilisez 'use strict' au début du fichier"
                    Line = $lineNumber
                    Column = 1
                }
            }
            
            return $null
        }, "Utilisez le mode strict", "Warning", "BestPractices")
    }
    
    [array] AnalyzeFile([string]$filePath) {
        $issues = @()
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        try {
            # Vérifier que le fichier existe
            if (-not (Test-Path -Path $filePath -PathType Leaf)) {
                Write-Warning "Le fichier n'existe pas: $filePath"
                return $issues
            }
            
            # Vérifier l'extension du fichier
            $extension = [System.IO.Path]::GetExtension($filePath).ToLower()
            if ($extension -notin @(".js", ".jsx", ".ts", ".tsx")) {
                Write-Warning "Le fichier n'est pas un script JavaScript: $filePath"
                return $issues
            }
            
            # Lire le contenu du fichier
            $content = Get-Content -Path $filePath -Raw
            $lines = $content -split "`n"
            
            # Appliquer les règles
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $lineNumber = $i + 1
                $line = $lines[$i]
                
                foreach ($ruleName in $this.Rules.Keys) {
                    $rule = $this.Rules[$ruleName]
                    $result = & $rule.Rule $line $lineNumber $content
                    
                    if ($result) {
                        $issues += [PSCustomObject]@{
                            Line = $result.Line
                            Column = $result.Column
                            Message = $result.Message
                            Severity = $rule.Severity
                            Type = $ruleName
                            Category = $rule.Category
                        }
                    }
                }
            }
        }
        catch {
            Write-Error "Erreur lors de l'analyse du fichier $filePath : $_"
        }
        finally {
            $stopwatch.Stop()
            $this.UpdatePerformanceMetrics($filePath, $stopwatch.Elapsed, $issues.Count)
        }
        
        return $issues
    }
}

# Fonction pour créer un analyseur de langage
function New-LanguageAnalyzer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("PowerShell", "Python", "JavaScript")]
        [string]$Language
    )
    
    switch ($Language) {
        "PowerShell" { return [PowerShellAnalyzer]::new() }
        "Python" { return [PythonAnalyzer]::new() }
        "JavaScript" { return [JavaScriptAnalyzer]::new() }
        default { throw "Langage non pris en charge: $Language" }
    }
}

# Fonction pour analyser un fichier avec l'analyseur approprié
function Invoke-LanguageSpecificAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter()]
        [object]$Analyzer = $null
    )
    
    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Error "Le fichier n'existe pas: $FilePath"
        return @()
    }
    
    # Déterminer le langage en fonction de l'extension du fichier
    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    $language = switch ($extension) {
        { $_ -in @(".ps1", ".psm1", ".psd1") } { "PowerShell" }
        ".py" { "Python" }
        { $_ -in @(".js", ".jsx", ".ts", ".tsx") } { "JavaScript" }
        default { $null }
    }
    
    if (-not $language) {
        Write-Warning "Extension de fichier non prise en charge: $extension"
        return @()
    }
    
    # Créer l'analyseur si nécessaire
    if (-not $Analyzer -or $Analyzer.Language -ne $language) {
        $Analyzer = New-LanguageAnalyzer -Language $language
    }
    
    # Analyser le fichier
    $issues = $Analyzer.AnalyzeFile($FilePath)
    
    return $issues
}

# Exporter les fonctions
Export-ModuleMember -Function New-LanguageAnalyzer, Invoke-LanguageSpecificAnalysis
