#
# Module SimpleFileContentIndexer
# Compatible avec PowerShell 5.1 et PowerShell 7
#

# Variables globales du module
$script:fileIndices = @{}
$script:symbolMap = @{}
$script:indexPath = ""
$script:persistIndices = $false
$script:maxConcurrentIndexing = 4
$script:enableIncrementalIndexing = $true

# Fonction pour crÃ©er un nouvel indexeur
function New-FileContentIndexer {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$IndexPath = "",

        [Parameter()]
        [bool]$PersistIndices = $false,

        [Parameter()]
        [int]$MaxConcurrentIndexing = 4,

        [Parameter()]
        [bool]$EnableIncrementalIndexing = $true
    )

    # Initialiser les variables globales
    $script:indexPath = $IndexPath
    $script:persistIndices = $PersistIndices
    $script:maxConcurrentIndexing = $MaxConcurrentIndexing
    $script:enableIncrementalIndexing = $EnableIncrementalIndexing
    $script:fileIndices = @{}
    $script:symbolMap = @{}

    # CrÃ©er et retourner un objet indexeur
    $indexer = [PSCustomObject]@{
        IndexPath                 = $IndexPath
        PersistIndices            = $PersistIndices
        MaxConcurrentIndexing     = $MaxConcurrentIndexing
        EnableIncrementalIndexing = $EnableIncrementalIndexing
        PSTypeName                = "FileContentIndexer"
    }

    # Ajouter des mÃ©thodes Ã  l'indexeur
    $indexer | Add-Member -MemberType ScriptMethod -Name "GetFileIndices" -Value {
        return $script:fileIndices
    }

    $indexer | Add-Member -MemberType ScriptMethod -Name "GetSymbolMap" -Value {
        return $script:symbolMap
    }

    $indexer | Add-Member -MemberType ScriptMethod -Name "ClearIndices" -Value {
        $script:fileIndices = @{}
        $script:symbolMap = @{}
    }

    return $indexer
}

# Fonction pour indexer un fichier
function New-FileIndex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$Indexer,

        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    # VÃ©rifier que le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Error "Le fichier n'existe pas: $FilePath"
        return $null
    }

    # Obtenir l'extension du fichier
    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()

    # CrÃ©er un objet index
    $index = [PSCustomObject]@{
        FilePath         = $FilePath
        IndexedAt        = Get-Date
        FileSize         = (Get-Item -Path $FilePath).Length
        Extension        = $extension
        Symbols          = @{}
        Functions        = @()
        Classes          = @()
        Variables        = @()
        Lines            = @()
        Content          = $null
        IsPartialIndex   = $false
        ChangedLines     = @()
        ChangedFunctions = @()
    }

    # Lire le contenu du fichier
    try {
        $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
        $index.Content = $content
        $index.Lines = $content -split "`n"
    } catch {
        Write-Error "Erreur lors de la lecture du fichier $FilePath : $_"
        return $null
    }

    # Indexer le fichier selon son extension
    switch ($extension) {
        ".ps1" { $index = Add-PowerShellIndex -Index $index }
        ".psm1" { $index = Add-PowerShellIndex -Index $index }
        ".py" { $index = Add-PythonIndex -Index $index }
        ".js" { $index = Add-JavaScriptIndex -Index $index }
        ".html" { $index = Add-HTMLIndex -Index $index }
        ".css" { $index = Add-CSSIndex -Index $index }
        default { $index = Add-GenericIndex -Index $index }
    }

    # Ajouter l'index au dictionnaire
    $script:fileIndices[$FilePath] = $index

    # Mettre Ã  jour la carte des symboles
    foreach ($symbol in $index.Symbols.Keys) {
        if (-not $script:symbolMap.ContainsKey($symbol)) {
            $script:symbolMap[$symbol] = @{}
        }
        $script:symbolMap[$symbol][$FilePath] = $index.Symbols[$symbol]
    }

    # Persister l'index si demandÃ©
    if ($script:persistIndices -and $script:indexPath) {
        $indexFileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath) + "_index.xml"
        $indexFilePath = Join-Path -Path $script:indexPath -ChildPath $indexFileName

        # CrÃ©er le rÃ©pertoire s'il n'existe pas
        if (-not (Test-Path -Path $script:indexPath)) {
            New-Item -Path $script:indexPath -ItemType Directory -Force | Out-Null
        }

        # Sauvegarder l'index
        $index | Export-Clixml -Path $indexFilePath -Force
    }

    return $index
}

# Fonction pour indexer un fichier de maniÃ¨re incrÃ©mentale
function New-IncrementalFileIndex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$Indexer,

        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$OldContent,

        [Parameter(Mandatory = $true)]
        [string]$NewContent
    )

    # VÃ©rifier que l'indexation incrÃ©mentale est activÃ©e
    if (-not $script:enableIncrementalIndexing) {
        return New-FileIndex -Indexer $Indexer -FilePath $FilePath
    }

    # CrÃ©er un objet index partiel
    $index = [PSCustomObject]@{
        FilePath         = $FilePath
        IndexedAt        = Get-Date
        FileSize         = $NewContent.Length
        Extension        = [System.IO.Path]::GetExtension($FilePath).ToLower()
        Symbols          = @{}
        Functions        = @()
        Classes          = @()
        Variables        = @()
        Lines            = $NewContent -split "`n"
        Content          = $NewContent
        IsPartialIndex   = $true
        ChangedLines     = @()
        ChangedFunctions = @()
    }

    # Trouver les lignes modifiÃ©es
    $oldLines = $OldContent -split "`n"
    $newLines = $NewContent -split "`n"

    # Utiliser un algorithme simple pour dÃ©tecter les lignes modifiÃ©es
    $changedLines = @()
    $maxLines = [Math]::Max($oldLines.Count, $newLines.Count)

    for ($i = 0; $i -lt $maxLines; $i++) {
        $oldLine = if ($i -lt $oldLines.Count) { $oldLines[$i] } else { $null }
        $newLine = if ($i -lt $newLines.Count) { $newLines[$i] } else { $null }

        if ($oldLine -ne $newLine) {
            $changedLines += $i + 1  # Lignes numÃ©rotÃ©es Ã  partir de 1
        }
    }

    $index.ChangedLines = $changedLines

    # Indexer le fichier selon son extension
    switch ($index.Extension) {
        ".ps1" { $index = Add-PowerShellIndex -Index $index -IncrementalMode $true }
        ".psm1" { $index = Add-PowerShellIndex -Index $index -IncrementalMode $true }
        ".py" { $index = Add-PythonIndex -Index $index -IncrementalMode $true }
        ".js" { $index = Add-JavaScriptIndex -Index $index -IncrementalMode $true }
        ".html" { $index = Add-HTMLIndex -Index $index -IncrementalMode $true }
        ".css" { $index = Add-CSSIndex -Index $index -IncrementalMode $true }
        default { $index = Add-GenericIndex -Index $index -IncrementalMode $true }
    }

    # Ajouter l'index au dictionnaire
    $script:fileIndices[$FilePath] = $index

    # Mettre Ã  jour la carte des symboles
    foreach ($symbol in $index.Symbols.Keys) {
        if (-not $script:symbolMap.ContainsKey($symbol)) {
            $script:symbolMap[$symbol] = @{}
        }
        $script:symbolMap[$symbol][$FilePath] = $index.Symbols[$symbol]
    }

    return $index
}

# Fonction pour indexer plusieurs fichiers en parallÃ¨le
function New-ParallelFileIndices {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$Indexer,

        [Parameter(Mandatory = $true)]
        [string[]]$FilePaths
    )

    # Initialiser les rÃ©sultats
    $results = @{}

    # MÃ©thode simple et compatible avec toutes les versions
    foreach ($filePath in $FilePaths) {
        # Indexer le fichier
        $index = New-FileIndex -Indexer $Indexer -FilePath $filePath

        # Ajouter le rÃ©sultat
        $results[$filePath] = $index
    }

    return $results
}

# Fonction pour indexer un fichier PowerShell
function Add-PowerShellIndex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$Index,

        [Parameter()]
        [bool]$IncrementalMode = $false
    )

    # Expressions rÃ©guliÃ¨res pour trouver les fonctions, classes et variables
    $functionRegex = '(?i)function\s+([a-z0-9_-]+)'
    $classRegex = '(?i)class\s+([a-z0-9_-]+)'
    $variableRegex = '(?i)\$([a-z0-9_]+)\s*='

    # Analyser le contenu
    $content = $Index.Content
    $lineNumber = 0

    # Trouver les fonctions
    $functionMatches = [regex]::Matches($content, $functionRegex)
    foreach ($match in $functionMatches) {
        $functionName = $match.Groups[1].Value
        $lineNumber = $content.Substring(0, $match.Index).Split("`n").Count

        $Index.Functions += $functionName
        $Index.Symbols[$functionName] = $lineNumber

        # VÃ©rifier si cette fonction a Ã©tÃ© modifiÃ©e (pour l'indexation incrÃ©mentale)
        if ($IncrementalMode -and $Index.ChangedLines -contains $lineNumber) {
            $Index.ChangedFunctions += $functionName
        }
    }

    # Trouver les classes
    $classMatches = [regex]::Matches($content, $classRegex)
    foreach ($match in $classMatches) {
        $className = $match.Groups[1].Value
        $lineNumber = $content.Substring(0, $match.Index).Split("`n").Count

        $Index.Classes += $className
        $Index.Symbols[$className] = $lineNumber
    }

    # Trouver les variables
    $variableMatches = [regex]::Matches($content, $variableRegex)
    foreach ($match in $variableMatches) {
        $variableName = $match.Groups[1].Value
        $lineNumber = $content.Substring(0, $match.Index).Split("`n").Count

        $Index.Variables += $variableName
        $Index.Symbols[$variableName] = $lineNumber
    }

    return $Index
}

# Fonction pour indexer un fichier Python
function Add-PythonIndex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$Index,

        [Parameter()]
        [bool]$IncrementalMode = $false
    )

    # Expressions rÃ©guliÃ¨res pour trouver les fonctions, classes et variables
    $functionRegex = '(?i)def\s+([a-z0-9_]+)'
    $classRegex = '(?i)class\s+([a-z0-9_]+)'
    $variableRegex = '(?i)([a-z0-9_]+)\s*='

    # Analyser le contenu
    $content = $Index.Content
    $lineNumber = 0

    # Trouver les fonctions
    $functionMatches = [regex]::Matches($content, $functionRegex)
    foreach ($match in $functionMatches) {
        $functionName = $match.Groups[1].Value
        $lineNumber = $content.Substring(0, $match.Index).Split("`n").Count

        $Index.Functions += $functionName
        $Index.Symbols[$functionName] = $lineNumber

        # VÃ©rifier si cette fonction a Ã©tÃ© modifiÃ©e (pour l'indexation incrÃ©mentale)
        if ($IncrementalMode -and $Index.ChangedLines -contains $lineNumber) {
            $Index.ChangedFunctions += $functionName
        }
    }

    # Trouver les classes
    $classMatches = [regex]::Matches($content, $classRegex)
    foreach ($match in $classMatches) {
        $className = $match.Groups[1].Value
        $lineNumber = $content.Substring(0, $match.Index).Split("`n").Count

        $Index.Classes += $className
        $Index.Symbols[$className] = $lineNumber
    }

    # Trouver les variables
    $variableMatches = [regex]::Matches($content, $variableRegex)
    foreach ($match in $variableMatches) {
        $variableName = $match.Groups[1].Value
        $lineNumber = $content.Substring(0, $match.Index).Split("`n").Count

        # Ignorer les mots-clÃ©s Python
        $pythonKeywords = @("if", "else", "elif", "for", "while", "try", "except", "finally", "with", "as", "def", "class", "return", "import", "from")
        if ($pythonKeywords -notcontains $variableName) {
            $Index.Variables += $variableName
            $Index.Symbols[$variableName] = $lineNumber
        }
    }

    return $Index
}

# Fonction pour indexer un fichier JavaScript
function Add-JavaScriptIndex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$Index,

        [Parameter()]
        [bool]$IncrementalMode = $false
    )

    # Expressions rÃ©guliÃ¨res pour trouver les fonctions, classes et variables
    $functionRegex = '(?i)function\s+([a-z0-9_$]+)|([a-z0-9_$]+)\s*=\s*function'
    $classRegex = '(?i)class\s+([a-z0-9_$]+)'
    $variableRegex = '(?i)(let|var|const)\s+([a-z0-9_$]+)\s*='

    # Analyser le contenu
    $content = $Index.Content
    $lineNumber = 0

    # Trouver les fonctions
    $functionMatches = [regex]::Matches($content, $functionRegex)
    foreach ($match in $functionMatches) {
        $functionName = if ($match.Groups[1].Success) { $match.Groups[1].Value } else { $match.Groups[2].Value }
        $lineNumber = $content.Substring(0, $match.Index).Split("`n").Count

        $Index.Functions += $functionName
        $Index.Symbols[$functionName] = $lineNumber

        # VÃ©rifier si cette fonction a Ã©tÃ© modifiÃ©e (pour l'indexation incrÃ©mentale)
        if ($IncrementalMode -and $Index.ChangedLines -contains $lineNumber) {
            $Index.ChangedFunctions += $functionName
        }
    }

    # Trouver les classes
    $classMatches = [regex]::Matches($content, $classRegex)
    foreach ($match in $classMatches) {
        $className = $match.Groups[1].Value
        $lineNumber = $content.Substring(0, $match.Index).Split("`n").Count

        $Index.Classes += $className
        $Index.Symbols[$className] = $lineNumber
    }

    # Trouver les variables
    $variableMatches = [regex]::Matches($content, $variableRegex)
    foreach ($match in $variableMatches) {
        $variableName = $match.Groups[2].Value
        $lineNumber = $content.Substring(0, $match.Index).Split("`n").Count

        $Index.Variables += $variableName
        $Index.Symbols[$variableName] = $lineNumber
    }

    return $Index
}

# Fonction pour indexer un fichier HTML
function Add-HTMLIndex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$Index,

        [Parameter()]
        [bool]$IncrementalMode = $false
    )

    # Expressions rÃ©guliÃ¨res pour trouver les balises et les identifiants
    $tagRegex = '<([a-z][a-z0-9]*)\b[^>]*>'
    $idRegex = 'id=["'']([a-z0-9_-]+)["'']'
    $classRegex = 'class=["'']([a-z0-9_\s-]+)["'']'

    # Analyser le contenu
    $content = $Index.Content
    $lineNumber = 0

    # Trouver les balises
    $tagMatches = [regex]::Matches($content, $tagRegex)
    foreach ($match in $tagMatches) {
        $tagName = $match.Groups[1].Value
        $lineNumber = $content.Substring(0, $match.Index).Split("`n").Count

        $Index.Symbols["tag:$tagName"] = $lineNumber
    }

    # Trouver les identifiants
    $idMatches = [regex]::Matches($content, $idRegex)
    foreach ($match in $idMatches) {
        $idName = $match.Groups[1].Value
        $lineNumber = $content.Substring(0, $match.Index).Split("`n").Count

        $Index.Symbols["id:$idName"] = $lineNumber
    }

    # Trouver les classes
    $classMatches = [regex]::Matches($content, $classRegex)
    foreach ($match in $classMatches) {
        $className = $match.Groups[1].Value
        $lineNumber = $content.Substring(0, $match.Index).Split("`n").Count

        # SÃ©parer les classes multiples
        $classNames = $className -split '\s+'
        foreach ($name in $classNames) {
            $Index.Symbols["class:$name"] = $lineNumber
        }
    }

    return $Index
}

# Fonction pour indexer un fichier CSS
function Add-CSSIndex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$Index,

        [Parameter()]
        [bool]$IncrementalMode = $false
    )

    # Expressions rÃ©guliÃ¨res pour trouver les sÃ©lecteurs
    $selectorRegex = '([.#]?[a-z0-9_-]+)\s*\{'

    # Analyser le contenu
    $content = $Index.Content
    $lineNumber = 0

    # Trouver les sÃ©lecteurs
    $selectorMatches = [regex]::Matches($content, $selectorRegex)
    foreach ($match in $selectorMatches) {
        $selectorName = $match.Groups[1].Value
        $lineNumber = $content.Substring(0, $match.Index).Split("`n").Count

        $Index.Symbols[$selectorName] = $lineNumber
    }

    return $Index
}

# Fonction pour indexer un fichier gÃ©nÃ©rique
function Add-GenericIndex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$Index,

        [Parameter()]
        [bool]$IncrementalMode = $false
    )

    # Pour les fichiers gÃ©nÃ©riques, nous indexons simplement les lignes
    for ($i = 0; $i -lt $Index.Lines.Count; $i++) {
        $lineNumber = $i + 1
        $Index.Symbols["line:$lineNumber"] = $lineNumber
    }

    return $Index
}

# Fonction pour crÃ©er un nouvel indexeur de contenu de fichier
function New-FileContentIndexer {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$IndexPath = "",

        [Parameter()]
        [bool]$PersistIndices = $false,

        [Parameter()]
        [int]$MaxConcurrentIndexing = 4,

        [Parameter()]
        [bool]$EnableIncrementalIndexing = $true
    )

    # Initialiser les variables globales
    $script:indexPath = $IndexPath
    $script:persistIndices = $PersistIndices
    $script:maxConcurrentIndexing = $MaxConcurrentIndexing
    $script:enableIncrementalIndexing = $EnableIncrementalIndexing
    $script:fileIndices = @{}
    $script:symbolMap = @{}

    # CrÃ©er et retourner un objet indexeur
    $indexer = [PSCustomObject]@{
        IndexPath                 = $IndexPath
        PersistIndices            = $PersistIndices
        MaxConcurrentIndexing     = $MaxConcurrentIndexing
        EnableIncrementalIndexing = $EnableIncrementalIndexing
        PSTypeName                = "FileContentIndexer"
    }

    # Ajouter des mÃ©thodes Ã  l'indexeur
    $indexer | Add-Member -MemberType ScriptMethod -Name "GetFileIndices" -Value {
        return $script:fileIndices
    }

    $indexer | Add-Member -MemberType ScriptMethod -Name "GetSymbolMap" -Value {
        return $script:symbolMap
    }

    $indexer | Add-Member -MemberType ScriptMethod -Name "ClearIndices" -Value {
        $script:fileIndices = @{}
        $script:symbolMap = @{}
    }

    return $indexer
}

# Exporter les fonctions
Export-ModuleMember -Function New-FileContentIndexer, New-FileIndex, New-IncrementalFileIndex, New-ParallelFileIndices
