<#
.SYNOPSIS
    Fonctions pour l'analyse des stack traces PowerShell.

.DESCRIPTION
    Ce script contient des fonctions pour analyser, parser et visualiser les stack traces
    PowerShell afin de faciliter le dÃ©bogage et l'analyse des erreurs.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2025-04-25
#>

#region Parseur de stack trace

<#
.SYNOPSIS
    Parse une stack trace PowerShell et extrait les informations pertinentes.

.DESCRIPTION
    Cette fonction analyse une stack trace PowerShell et extrait les informations
    telles que les noms de fichiers, les numÃ©ros de ligne, les noms de fonctions
    et les messages d'erreur.

.PARAMETER StackTrace
    La stack trace Ã  analyser. Peut Ãªtre une chaÃ®ne ou un objet ErrorRecord.

.EXAMPLE
    $error[0] | Get-StackTraceInfo

.EXAMPLE
    Get-StackTraceInfo -StackTrace "At C:\Scripts\test.ps1:23 char:1..."

.OUTPUTS
    System.Collections.ArrayList contenant des objets avec les propriÃ©tÃ©s suivantes :
    - File: Le chemin du fichier
    - Line: Le numÃ©ro de ligne
    - Column: Le numÃ©ro de colonne
    - Function: Le nom de la fonction
    - Command: La commande exÃ©cutÃ©e
    - ErrorMessage: Le message d'erreur (uniquement pour le premier Ã©lÃ©ment)
#>
function Get-StackTraceInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [object]$StackTrace
    )

    process {
        # Initialiser la collection pour stocker les informations de stack trace
        $stackFrames = New-Object System.Collections.ArrayList

        # Extraire la stack trace si un objet ErrorRecord est fourni
        if ($StackTrace -is [System.Management.Automation.ErrorRecord]) {
            $errorMessage = $StackTrace.Exception.Message
            $stackTraceText = $StackTrace.ScriptStackTrace
            $invocationInfo = $StackTrace.InvocationInfo
            
            # Ajouter l'information sur l'erreur principale
            if ($invocationInfo) {
                $frame = [PSCustomObject]@{
                    File = $invocationInfo.ScriptName
                    Line = $invocationInfo.ScriptLineNumber
                    Column = $invocationInfo.OffsetInLine
                    Function = $invocationInfo.MyCommand.Name
                    Command = $invocationInfo.Line.Trim()
                    ErrorMessage = $errorMessage
                    IsErrorLocation = $true
                }
                [void]$stackFrames.Add($frame)
            }
        }
        else {
            # ConsidÃ©rer l'entrÃ©e comme une chaÃ®ne de stack trace
            $stackTraceText = $StackTrace.ToString()
            $errorMessage = $null
        }

        # Analyser la stack trace ligne par ligne
        $lines = $stackTraceText -split "`n"
        
        foreach ($line in $lines) {
            # Pattern pour les lignes de stack trace PowerShell
            if ($line -match 'at\s+(?<file>.+):(?<line>\d+)\s+char:(?<column>\d+)') {
                $file = $Matches['file']
                $lineNumber = [int]$Matches['line']
                $column = [int]$Matches['column']
                
                # Extraire le nom de la fonction si disponible
                $function = ""
                if ($line -match 'at\s+(?<function>[^,]+),\s+') {
                    $function = $Matches['function']
                }
                
                # Extraire la commande si disponible
                $command = ""
                if ($line -match '\+\s+(?<command>.+)') {
                    $command = $Matches['command'].Trim()
                }
                
                $frame = [PSCustomObject]@{
                    File = $file
                    Line = $lineNumber
                    Column = $column
                    Function = $function
                    Command = $command
                    ErrorMessage = $null
                    IsErrorLocation = $false
                }
                
                [void]$stackFrames.Add($frame)
            }
        }
        
        return $stackFrames
    }
}

<#
.SYNOPSIS
    Extrait les informations de ligne et de fichier Ã  partir d'une stack trace.

.DESCRIPTION
    Cette fonction analyse une stack trace et extrait les informations de ligne et de fichier
    pour chaque frame de la stack trace.

.PARAMETER StackTrace
    La stack trace Ã  analyser. Peut Ãªtre une chaÃ®ne ou un objet ErrorRecord.

.EXAMPLE
    $error[0] | Get-StackTraceLineInfo

.EXAMPLE
    Get-StackTraceLineInfo -StackTrace "At C:\Scripts\test.ps1:23 char:1..."

.OUTPUTS
    System.Collections.ArrayList contenant des objets avec les propriÃ©tÃ©s suivantes :
    - File: Le chemin du fichier
    - Line: Le numÃ©ro de ligne
    - Column: Le numÃ©ro de colonne
    - LineContent: Le contenu de la ligne (si disponible)
    - Context: Les lignes avant et aprÃ¨s la ligne d'erreur (si disponible)
#>
function Get-StackTraceLineInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [object]$StackTrace,
        
        [Parameter(Mandatory = $false)]
        [int]$ContextLines = 3
    )

    process {
        # Obtenir les informations de base de la stack trace
        $stackFrames = Get-StackTraceInfo -StackTrace $StackTrace
        
        # Enrichir chaque frame avec le contenu de la ligne et le contexte
        foreach ($frame in $stackFrames) {
            if ($frame.File -and (Test-Path -Path $frame.File -PathType Leaf)) {
                try {
                    # Lire le contenu du fichier
                    $fileContent = Get-Content -Path $frame.File -ErrorAction Stop
                    
                    # Ajouter le contenu de la ligne si disponible
                    if ($frame.Line -le $fileContent.Count) {
                        $frame | Add-Member -MemberType NoteProperty -Name "LineContent" -Value $fileContent[$frame.Line - 1]
                        
                        # Ajouter le contexte (lignes avant et aprÃ¨s)
                        $startLine = [Math]::Max(1, $frame.Line - $ContextLines)
                        $endLine = [Math]::Min($fileContent.Count, $frame.Line + $ContextLines)
                        
                        $context = @()
                        for ($i = $startLine; $i -le $endLine; $i++) {
                            $prefix = if ($i -eq $frame.Line) { ">" } else { " " }
                            $context += "$prefix $i`: $($fileContent[$i - 1])"
                        }
                        
                        $frame | Add-Member -MemberType NoteProperty -Name "Context" -Value $context
                    }
                    else {
                        $frame | Add-Member -MemberType NoteProperty -Name "LineContent" -Value "<ligne non disponible>"
                        $frame | Add-Member -MemberType NoteProperty -Name "Context" -Value @()
                    }
                }
                catch {
                    $frame | Add-Member -MemberType NoteProperty -Name "LineContent" -Value "<erreur de lecture du fichier>"
                    $frame | Add-Member -MemberType NoteProperty -Name "Context" -Value @()
                }
            }
            else {
                $frame | Add-Member -MemberType NoteProperty -Name "LineContent" -Value "<fichier non disponible>"
                $frame | Add-Member -MemberType NoteProperty -Name "Context" -Value @()
            }
        }
        
        return $stackFrames
    }
}

<#
.SYNOPSIS
    RÃ©sout les chemins de fichiers dans une stack trace.

.DESCRIPTION
    Cette fonction rÃ©sout les chemins de fichiers relatifs ou incomplets dans une stack trace
    en chemins absolus, en utilisant diffÃ©rentes stratÃ©gies de rÃ©solution.

.PARAMETER StackTrace
    La stack trace Ã  analyser. Peut Ãªtre une chaÃ®ne ou un objet ErrorRecord.

.PARAMETER BasePath
    Le chemin de base Ã  utiliser pour rÃ©soudre les chemins relatifs.
    Par dÃ©faut, utilise le rÃ©pertoire courant.

.PARAMETER SearchPaths
    Tableau de chemins supplÃ©mentaires Ã  rechercher pour rÃ©soudre les fichiers.

.EXAMPLE
    $error[0] | Resolve-StackTracePaths -BasePath "C:\Projects\MyProject"

.EXAMPLE
    Resolve-StackTracePaths -StackTrace $stackTrace -SearchPaths @("C:\Modules", "C:\Scripts")

.OUTPUTS
    System.Collections.ArrayList contenant des objets avec les propriÃ©tÃ©s de Get-StackTraceInfo
    mais avec les chemins de fichiers rÃ©solus.
#>
function Resolve-StackTracePaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [object]$StackTrace,
        
        [Parameter(Mandatory = $false)]
        [string]$BasePath = (Get-Location).Path,
        
        [Parameter(Mandatory = $false)]
        [string[]]$SearchPaths = @()
    )

    process {
        # Obtenir les informations de base de la stack trace
        $stackFrames = Get-StackTraceInfo -StackTrace $StackTrace
        
        # Ajouter le rÃ©pertoire courant et le rÃ©pertoire du script aux chemins de recherche
        $allSearchPaths = @($BasePath) + $SearchPaths
        
        # Si $PSScriptRoot est dÃ©fini, l'ajouter aux chemins de recherche
        if ($PSScriptRoot) {
            $allSearchPaths += $PSScriptRoot
        }
        
        # RÃ©soudre les chemins de fichiers pour chaque frame
        foreach ($frame in $stackFrames) {
            if ($frame.File) {
                # Si le chemin est dÃ©jÃ  absolu et existe, le conserver
                if ([System.IO.Path]::IsPathRooted($frame.File) -and (Test-Path -Path $frame.File -PathType Leaf)) {
                    continue
                }
                
                # Essayer de rÃ©soudre le chemin relatif
                $fileName = Split-Path -Leaf $frame.File
                $resolvedPath = $null
                
                # Essayer chaque chemin de recherche
                foreach ($searchPath in $allSearchPaths) {
                    # Essayer le chemin direct
                    $testPath = Join-Path -Path $searchPath -ChildPath $frame.File
                    if (Test-Path -Path $testPath -PathType Leaf) {
                        $resolvedPath = $testPath
                        break
                    }
                    
                    # Essayer juste avec le nom de fichier
                    $testPath = Join-Path -Path $searchPath -ChildPath $fileName
                    if (Test-Path -Path $testPath -PathType Leaf) {
                        $resolvedPath = $testPath
                        break
                    }
                    
                    # Rechercher rÃ©cursivement (limitÃ© Ã  3 niveaux pour Ã©viter une recherche trop longue)
                    try {
                        $foundFiles = Get-ChildItem -Path $searchPath -Filter $fileName -Recurse -Depth 3 -ErrorAction Stop
                        if ($foundFiles.Count -gt 0) {
                            $resolvedPath = $foundFiles[0].FullName
                            break
                        }
                    }
                    catch {
                        # Ignorer les erreurs de recherche
                    }
                }
                
                # Mettre Ã  jour le chemin du fichier s'il a Ã©tÃ© rÃ©solu
                if ($resolvedPath) {
                    $frame.File = $resolvedPath
                }
            }
        }
        
        return $stackFrames
    }
}

<#
.SYNOPSIS
    Analyse la sÃ©quence d'appels dans une stack trace.

.DESCRIPTION
    Cette fonction analyse la sÃ©quence d'appels dans une stack trace pour identifier
    les patterns d'appels, les rÃ©cursions et les chemins d'exÃ©cution.

.PARAMETER StackTrace
    La stack trace Ã  analyser. Peut Ãªtre une chaÃ®ne ou un objet ErrorRecord.

.EXAMPLE
    $error[0] | Get-StackTraceCallSequence

.EXAMPLE
    Get-StackTraceCallSequence -StackTrace $stackTrace

.OUTPUTS
    PSCustomObject contenant les propriÃ©tÃ©s suivantes :
    - CallPath: La sÃ©quence d'appels sous forme de chaÃ®ne
    - CallDepth: La profondeur de la pile d'appels
    - RecursionDetected: Indique si une rÃ©cursion a Ã©tÃ© dÃ©tectÃ©e
    - RecursionPoints: Les points de rÃ©cursion dÃ©tectÃ©s
    - CallGraph: Un graphe des appels au format DOT
#>
function Get-StackTraceCallSequence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [object]$StackTrace
    )

    process {
        # Obtenir les informations de base de la stack trace
        $stackFrames = Get-StackTraceInfo -StackTrace $StackTrace
        
        # Extraire la sÃ©quence d'appels
        $callSequence = @()
        $functionCalls = @{}
        $recursionPoints = @()
        
        for ($i = $stackFrames.Count - 1; $i -ge 0; $i--) {
            $frame = $stackFrames[$i]
            $functionName = if ($frame.Function) { $frame.Function } else { "Script" }
            
            # Ajouter Ã  la sÃ©quence d'appels
            $callSequence += $functionName
            
            # VÃ©rifier la rÃ©cursion
            if ($functionCalls.ContainsKey($functionName)) {
                $functionCalls[$functionName] += 1
                $recursionPoints += @{
                    Function = $functionName
                    Depth = $stackFrames.Count - $i
                    Count = $functionCalls[$functionName]
                }
            }
            else {
                $functionCalls[$functionName] = 1
            }
        }
        
        # CrÃ©er le chemin d'appel
        $callPath = $callSequence -join " -> "
        
        # DÃ©tecter la rÃ©cursion
        $recursionDetected = $recursionPoints.Count -gt 0
        
        # CrÃ©er un graphe DOT pour visualiser les appels
        $dotGraph = "digraph CallGraph {`n"
        $dotGraph += "  rankdir=LR;`n"
        $dotGraph += "  node [shape=box, style=filled, fillcolor=lightblue];`n`n"
        
        for ($i = 0; $i -lt $callSequence.Count - 1; $i++) {
            $source = $callSequence[$i]
            $target = $callSequence[$i + 1]
            $dotGraph += "  `"$source`" -> `"$target`";`n"
        }
        
        # Mettre en Ã©vidence les rÃ©cursions
        if ($recursionDetected) {
            $dotGraph += "`n  // Recursion points`n"
            foreach ($point in $recursionPoints) {
                $dotGraph += "  `"$($point.Function)`" [fillcolor=orange];`n"
            }
        }
        
        $dotGraph += "}`n"
        
        # CrÃ©er l'objet rÃ©sultat
        $result = [PSCustomObject]@{
            CallPath = $callPath
            CallDepth = $callSequence.Count
            RecursionDetected = $recursionDetected
            RecursionPoints = $recursionPoints
            CallGraph = $dotGraph
        }
        
        return $result
    }
}

<#
.SYNOPSIS
    GÃ©nÃ¨re une visualisation hiÃ©rarchique d'une stack trace.

.DESCRIPTION
    Cette fonction gÃ©nÃ¨re une visualisation hiÃ©rarchique d'une stack trace pour
    faciliter la comprÃ©hension de la sÃ©quence d'appels et des erreurs.

.PARAMETER StackTrace
    La stack trace Ã  visualiser. Peut Ãªtre une chaÃ®ne ou un objet ErrorRecord.

.PARAMETER Format
    Le format de sortie. Les valeurs possibles sont : Text, HTML, Markdown.
    Par dÃ©faut, le format est Text.

.PARAMETER IncludeLineContent
    Indique si le contenu des lignes doit Ãªtre inclus dans la visualisation.

.PARAMETER IncludeContext
    Indique si le contexte des lignes doit Ãªtre inclus dans la visualisation.

.EXAMPLE
    $error[0] | Show-StackTraceHierarchy

.EXAMPLE
    Show-StackTraceHierarchy -StackTrace $stackTrace -Format HTML -IncludeLineContent $true

.OUTPUTS
    String contenant la visualisation hiÃ©rarchique de la stack trace.
#>
function Show-StackTraceHierarchy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [object]$StackTrace,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "HTML", "Markdown")]
        [string]$Format = "Text",
        
        [Parameter(Mandatory = $false)]
        [bool]$IncludeLineContent = $true,
        
        [Parameter(Mandatory = $false)]
        [bool]$IncludeContext = $false
    )

    process {
        # Obtenir les informations dÃ©taillÃ©es de la stack trace
        $stackFrames = Get-StackTraceLineInfo -StackTrace $StackTrace
        
        # GÃ©nÃ©rer la visualisation selon le format demandÃ©
        switch ($Format) {
            "Text" {
                $output = "Stack Trace Hierarchy:`n"
                $output += "=====================`n"
                
                if ($stackFrames[0].ErrorMessage) {
                    $output += "Error: $($stackFrames[0].ErrorMessage)`n"
                    $output += "---------------------`n"
                }
                
                for ($i = $stackFrames.Count - 1; $i -ge 0; $i--) {
                    $frame = $stackFrames[$i]
                    $indent = " " * (($stackFrames.Count - 1 - $i) * 2)
                    $marker = if ($i -eq 0) { ">" } else { "-" }
                    
                    $functionName = if ($frame.Function) { $frame.Function } else { "Script" }
                    $location = "$($frame.File):$($frame.Line)"
                    
                    $output += "$indent$marker $functionName at $location`n"
                    
                    if ($IncludeLineContent -and $frame.LineContent) {
                        $output += "$indent  Code: $($frame.LineContent.Trim())`n"
                    }
                    
                    if ($IncludeContext -and $frame.Context -and $frame.Context.Count -gt 0) {
                        $output += "$indent  Context:`n"
                        foreach ($contextLine in $frame.Context) {
                            $output += "$indent    $contextLine`n"
                        }
                    }
                }
            }
            "HTML" {
                $output = "<div class='stack-trace'>`n"
                $output += "<h3>Stack Trace Hierarchy</h3>`n"
                
                if ($stackFrames[0].ErrorMessage) {
                    $output += "<div class='error-message'>Error: $($stackFrames[0].ErrorMessage)</div>`n"
                    $output += "<hr/>`n"
                }
                
                $output += "<ul class='call-stack'>`n"
                
                for ($i = $stackFrames.Count - 1; $i -ge 0; $i--) {
                    $frame = $stackFrames[$i]
                    $indent = " " * (($stackFrames.Count - 1 - $i) * 2)
                    $class = if ($i -eq 0) { "error-location" } else { "call-frame" }
                    
                    $functionName = if ($frame.Function) { $frame.Function } else { "Script" }
                    $location = "$($frame.File):$($frame.Line)"
                    
                    $output += "$indent<li class='$class'>`n"
                    $output += "$indent  <div class='frame-header'>$functionName at $location</div>`n"
                    
                    if ($IncludeLineContent -and $frame.LineContent) {
                        $output += "$indent  <div class='code-line'>Code: <code>$($frame.LineContent.Trim())</code></div>`n"
                    }
                    
                    if ($IncludeContext -and $frame.Context -and $frame.Context.Count -gt 0) {
                        $output += "$indent  <div class='context'>`n"
                        $output += "$indent    <pre>`n"
                        foreach ($contextLine in $frame.Context) {
                            $output += "$indent      $contextLine`n"
                        }
                        $output += "$indent    </pre>`n"
                        $output += "$indent  </div>`n"
                    }
                    
                    $output += "$indent</li>`n"
                }
                
                $output += "</ul>`n"
                $output += "</div>`n"
            }
            "Markdown" {
                $output = "# Stack Trace Hierarchy`n`n"
                
                if ($stackFrames[0].ErrorMessage) {
                    $output += "**Error:** $($stackFrames[0].ErrorMessage)`n`n"
                    $output += "---`n`n"
                }
                
                for ($i = $stackFrames.Count - 1; $i -ge 0; $i--) {
                    $frame = $stackFrames[$i]
                    $indent = "  " * (($stackFrames.Count - 1 - $i))
                    $marker = if ($i -eq 0) { "**>" } else { "-" }
                    
                    $functionName = if ($frame.Function) { $frame.Function } else { "Script" }
                    $location = "$($frame.File):$($frame.Line)"
                    
                    $output += "$indent$marker $functionName at `$location`$`n"
                    
                    if ($IncludeLineContent -and $frame.LineContent) {
                        $output += "$indent  Code: ``$($frame.LineContent.Trim())``\n"
                    }
                    
                    if ($IncludeContext -and $frame.Context -and $frame.Context.Count -gt 0) {
                        $output += "$indent  Context:```n"
                        foreach ($contextLine in $frame.Context) {
                            $output += "$contextLine`n"
                        }
                        $output += "```\n"
                    }
                }
            }
        }
        
        return $output
    }
}

#endregion

# Exporter les fonctions
Export-ModuleMember -Function Get-StackTraceInfo, Get-StackTraceLineInfo, Resolve-StackTracePaths, Get-StackTraceCallSequence, Show-StackTraceHierarchy
