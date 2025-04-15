#Requires -Version 5.1
<#
.SYNOPSIS
    Module d'indexation rapide du contenu des fichiers pour l'analyse des pull requests.
.DESCRIPTION
    Fournit des fonctionnalités pour indexer et rechercher rapidement dans le contenu
    des fichiers, permettant une analyse incrémentale et partielle efficace.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

# Structure pour stocker les index
class FileIndex {
    [string]$FilePath
    [string]$FileHash
    [datetime]$IndexedAt
    [hashtable]$Tokens
    [hashtable]$Lines
    [hashtable]$Symbols
    [System.Collections.Generic.List[object]]$Imports
    [System.Collections.Generic.List[object]]$Functions
    [System.Collections.Generic.List[object]]$Classes
    [System.Collections.Generic.List[object]]$Variables
    [int]$LineCount
    [long]$FileSize

    FileIndex([string]$path) {
        $this.FilePath = $path
        $this.IndexedAt = Get-Date
        $this.Tokens = @{}
        $this.Lines = @{}
        $this.Symbols = @{}
        $this.Imports = [System.Collections.Generic.List[object]]::new()
        $this.Functions = [System.Collections.Generic.List[object]]::new()
        $this.Classes = [System.Collections.Generic.List[object]]::new()
        $this.Variables = [System.Collections.Generic.List[object]]::new()
        $this.LineCount = 0
        $this.FileSize = 0
    }
}

# Classe pour gérer l'indexation des fichiers
class FileContentIndexer {
    [hashtable]$FileIndices
    [hashtable]$SymbolMap
    [string]$IndexPath
    [bool]$PersistIndices

    FileContentIndexer([string]$indexPath, [bool]$persistIndices) {
        $this.FileIndices = @{}
        $this.SymbolMap = @{}
        $this.IndexPath = $indexPath
        $this.PersistIndices = $persistIndices

        # Créer le répertoire d'index s'il n'existe pas
        if ($persistIndices -and -not [string]::IsNullOrEmpty($indexPath)) {
            if (-not (Test-Path -Path $indexPath)) {
                New-Item -Path $indexPath -ItemType Directory -Force | Out-Null
            }
        }
    }

    # Indexer un fichier
    [FileIndex] IndexFile([string]$filePath) {
        if (-not (Test-Path -Path $filePath)) {
            Write-Error "Le fichier n'existe pas: $filePath"
            return $null
        }

        try {
            # Créer un nouvel index
            $index = [FileIndex]::new($filePath)
            
            # Obtenir les informations de base sur le fichier
            $fileInfo = Get-Item -Path $filePath
            $index.FileSize = $fileInfo.Length
            
            # Calculer le hash du fichier
            $index.FileHash = (Get-FileHash -Path $filePath -Algorithm SHA256).Hash
            
            # Lire le contenu du fichier
            $content = Get-Content -Path $filePath -Raw
            
            # Indexer le contenu en fonction du type de fichier
            $extension = [System.IO.Path]::GetExtension($filePath)
            switch ($extension) {
                ".ps1" { $this.IndexPowerShellFile($index, $content) }
                ".psm1" { $this.IndexPowerShellFile($index, $content) }
                ".py" { $this.IndexPythonFile($index, $content) }
                default { $this.IndexGenericFile($index, $content) }
            }
            
            # Stocker l'index
            $this.FileIndices[$filePath] = $index
            
            # Mettre à jour la carte des symboles
            foreach ($symbol in $index.Symbols.Keys) {
                if (-not $this.SymbolMap.ContainsKey($symbol)) {
                    $this.SymbolMap[$symbol] = [System.Collections.Generic.List[string]]::new()
                }
                
                if (-not $this.SymbolMap[$symbol].Contains($filePath)) {
                    $this.SymbolMap[$symbol].Add($filePath)
                }
            }
            
            # Persister l'index si nécessaire
            if ($this.PersistIndices) {
                $this.SaveIndex($index)
            }
            
            return $index
        } catch {
            Write-Error "Erreur lors de l'indexation du fichier $filePath : $_"
            return $null
        }
    }

    # Indexer un fichier PowerShell
    [void] IndexPowerShellFile([FileIndex]$index, [string]$content) {
        # Diviser le contenu en lignes
        $lines = $content -split "`n"
        $index.LineCount = $lines.Count
        
        # Indexer chaque ligne
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $lineNumber = $i + 1
            $line = $lines[$i]
            $index.Lines[$lineNumber] = $line
            
            # Analyser les tokens PowerShell
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                try {
                    $tokens = [System.Management.Automation.PSParser]::Tokenize($line, [ref]$null)
                    foreach ($token in $tokens) {
                        $tokenType = $token.Type
                        $tokenContent = $token.Content
                        
                        # Stocker le token
                        if (-not $index.Tokens.ContainsKey($tokenType)) {
                            $index.Tokens[$tokenType] = [System.Collections.Generic.List[object]]::new()
                        }
                        
                        $index.Tokens[$tokenType].Add([PSCustomObject]@{
                            Content = $tokenContent
                            Line = $lineNumber
                            Start = $token.Start
                            Length = $token.Length
                        })
                        
                        # Détecter les symboles importants
                        switch ($tokenType) {
                            "Command" {
                                $index.Symbols[$tokenContent] = $lineNumber
                            }
                            "Variable" {
                                $varName = $tokenContent -replace '^\$', ''
                                $index.Variables.Add([PSCustomObject]@{
                                    Name = $varName
                                    Line = $lineNumber
                                })
                            }
                        }
                    }
                } catch {
                    # Ignorer les erreurs de tokenization
                }
            }
        }
        
        # Détecter les fonctions
        $functionPattern = '(?i)function\s+([a-z0-9_-]+)'
        $matches = [regex]::Matches($content, $functionPattern)
        foreach ($match in $matches) {
            $functionName = $match.Groups[1].Value
            $lineNumber = $content.Substring(0, $match.Index).Split("`n").Count
            
            $index.Functions.Add([PSCustomObject]@{
                Name = $functionName
                Line = $lineNumber
            })
            
            $index.Symbols[$functionName] = $lineNumber
        }
        
        # Détecter les imports
        $importPattern = '(?i)Import-Module\s+([a-z0-9_.-]+)'
        $matches = [regex]::Matches($content, $importPattern)
        foreach ($match in $matches) {
            $moduleName = $match.Groups[1].Value
            $lineNumber = $content.Substring(0, $match.Index).Split("`n").Count
            
            $index.Imports.Add([PSCustomObject]@{
                Name = $moduleName
                Line = $lineNumber
            })
        }
    }

    # Indexer un fichier Python
    [void] IndexPythonFile([FileIndex]$index, [string]$content) {
        # Diviser le contenu en lignes
        $lines = $content -split "`n"
        $index.LineCount = $lines.Count
        
        # Indexer chaque ligne
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $lineNumber = $i + 1
            $line = $lines[$i]
            $index.Lines[$lineNumber] = $line
        }
        
        # Détecter les fonctions
        $functionPattern = '(?i)def\s+([a-z0-9_]+)'
        $matches = [regex]::Matches($content, $functionPattern)
        foreach ($match in $matches) {
            $functionName = $match.Groups[1].Value
            $lineNumber = $content.Substring(0, $match.Index).Split("`n").Count
            
            $index.Functions.Add([PSCustomObject]@{
                Name = $functionName
                Line = $lineNumber
            })
            
            $index.Symbols[$functionName] = $lineNumber
        }
        
        # Détecter les classes
        $classPattern = '(?i)class\s+([a-z0-9_]+)'
        $matches = [regex]::Matches($content, $classPattern)
        foreach ($match in $matches) {
            $className = $match.Groups[1].Value
            $lineNumber = $content.Substring(0, $match.Index).Split("`n").Count
            
            $index.Classes.Add([PSCustomObject]@{
                Name = $className
                Line = $lineNumber
            })
            
            $index.Symbols[$className] = $lineNumber
        }
        
        # Détecter les imports
        $importPattern = '(?i)import\s+([a-z0-9_.]+)|from\s+([a-z0-9_.]+)\s+import'
        $matches = [regex]::Matches($content, $importPattern)
        foreach ($match in $matches) {
            $moduleName = if ($match.Groups[1].Success) { $match.Groups[1].Value } else { $match.Groups[2].Value }
            $lineNumber = $content.Substring(0, $match.Index).Split("`n").Count
            
            $index.Imports.Add([PSCustomObject]@{
                Name = $moduleName
                Line = $lineNumber
            })
        }
    }

    # Indexer un fichier générique
    [void] IndexGenericFile([FileIndex]$index, [string]$content) {
        # Diviser le contenu en lignes
        $lines = $content -split "`n"
        $index.LineCount = $lines.Count
        
        # Indexer chaque ligne
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $lineNumber = $i + 1
            $line = $lines[$i]
            $index.Lines[$lineNumber] = $line
        }
        
        # Créer un index de mots simples
        $words = [regex]::Matches($content, '\b\w+\b')
        foreach ($word in $words) {
            $wordValue = $word.Value
            $lineNumber = $content.Substring(0, $word.Index).Split("`n").Count
            
            if (-not $index.Tokens.ContainsKey("Word")) {
                $index.Tokens["Word"] = [System.Collections.Generic.List[object]]::new()
            }
            
            $index.Tokens["Word"].Add([PSCustomObject]@{
                Content = $wordValue
                Line = $lineNumber
                Start = $word.Index
                Length = $word.Length
            })
        }
    }

    # Rechercher dans les index
    [System.Collections.Generic.List[object]] Search([string]$query, [string[]]$fileTypes = @()) {
        $results = [System.Collections.Generic.List[object]]::new()
        
        # Rechercher dans les symboles
        if ($this.SymbolMap.ContainsKey($query)) {
            foreach ($filePath in $this.SymbolMap[$query]) {
                $index = $this.FileIndices[$filePath]
                $lineNumber = $index.Symbols[$query]
                
                $results.Add([PSCustomObject]@{
                    FilePath = $filePath
                    LineNumber = $lineNumber
                    Line = $index.Lines[$lineNumber]
                    MatchType = "Symbol"
                    MatchValue = $query
                })
            }
        }
        
        # Rechercher dans le contenu des fichiers
        foreach ($filePath in $this.FileIndices.Keys) {
            # Filtrer par type de fichier si spécifié
            if ($fileTypes.Count -gt 0) {
                $extension = [System.IO.Path]::GetExtension($filePath)
                if (-not $fileTypes.Contains($extension)) {
                    continue
                }
            }
            
            $index = $this.FileIndices[$filePath]
            
            # Rechercher dans les tokens
            foreach ($tokenType in $index.Tokens.Keys) {
                $matchingTokens = $index.Tokens[$tokenType] | Where-Object { $_.Content -like "*$query*" }
                foreach ($token in $matchingTokens) {
                    $results.Add([PSCustomObject]@{
                        FilePath = $filePath
                        LineNumber = $token.Line
                        Line = $index.Lines[$token.Line]
                        MatchType = "Token"
                        MatchValue = $token.Content
                    })
                }
            }
            
            # Rechercher dans les lignes
            foreach ($lineNumber in $index.Lines.Keys) {
                $line = $index.Lines[$lineNumber]
                if ($line -like "*$query*") {
                    $results.Add([PSCustomObject]@{
                        FilePath = $filePath
                        LineNumber = $lineNumber
                        Line = $line
                        MatchType = "Line"
                        MatchValue = $query
                    })
                }
            }
        }
        
        return $results
    }

    # Comparer deux versions d'un fichier
    [PSCustomObject] CompareVersions([string]$filePath, [string]$oldContent, [string]$newContent) {
        # Créer des index temporaires
        $oldIndex = [FileIndex]::new($filePath)
        $newIndex = [FileIndex]::new($filePath)
        
        # Indexer les contenus
        $extension = [System.IO.Path]::GetExtension($filePath)
        switch ($extension) {
            ".ps1" { 
                $this.IndexPowerShellFile($oldIndex, $oldContent)
                $this.IndexPowerShellFile($newIndex, $newContent)
            }
            ".psm1" { 
                $this.IndexPowerShellFile($oldIndex, $oldContent)
                $this.IndexPowerShellFile($newIndex, $newContent)
            }
            ".py" { 
                $this.IndexPythonFile($oldIndex, $oldContent)
                $this.IndexPythonFile($newIndex, $newContent)
            }
            default { 
                $this.IndexGenericFile($oldIndex, $oldContent)
                $this.IndexGenericFile($newIndex, $newContent)
            }
        }
        
        # Comparer les fonctions
        $addedFunctions = $newIndex.Functions | Where-Object { 
            $func = $_
            -not ($oldIndex.Functions | Where-Object { $_.Name -eq $func.Name })
        }
        
        $removedFunctions = $oldIndex.Functions | Where-Object { 
            $func = $_
            -not ($newIndex.Functions | Where-Object { $_.Name -eq $func.Name })
        }
        
        $modifiedFunctions = $newIndex.Functions | Where-Object { 
            $func = $_
            $oldFunc = $oldIndex.Functions | Where-Object { $_.Name -eq $func.Name }
            $null -ne $oldFunc -and $oldFunc.Line -ne $func.Line
        }
        
        # Comparer les classes
        $addedClasses = $newIndex.Classes | Where-Object { 
            $class = $_
            -not ($oldIndex.Classes | Where-Object { $_.Name -eq $class.Name })
        }
        
        $removedClasses = $oldIndex.Classes | Where-Object { 
            $class = $_
            -not ($newIndex.Classes | Where-Object { $_.Name -eq $class.Name })
        }
        
        # Comparer les imports
        $addedImports = $newIndex.Imports | Where-Object { 
            $import = $_
            -not ($oldIndex.Imports | Where-Object { $_.Name -eq $import.Name })
        }
        
        $removedImports = $oldIndex.Imports | Where-Object { 
            $import = $_
            -not ($newIndex.Imports | Where-Object { $_.Name -eq $import.Name })
        }
        
        # Calculer les différences de lignes
        $oldLines = $oldContent -split "`n"
        $newLines = $newContent -split "`n"
        
        $diff = Compare-Object -ReferenceObject $oldLines -DifferenceObject $newLines
        $addedLines = ($diff | Where-Object { $_.SideIndicator -eq "=>" }).Count
        $removedLines = ($diff | Where-Object { $_.SideIndicator -eq "<=" }).Count
        
        # Créer l'objet de résultat
        $result = [PSCustomObject]@{
            FilePath = $filePath
            OldLineCount = $oldIndex.LineCount
            NewLineCount = $newIndex.LineCount
            AddedLines = $addedLines
            RemovedLines = $removedLines
            ModifiedLines = [Math]::Max($addedLines, $removedLines)
            AddedFunctions = $addedFunctions
            RemovedFunctions = $removedFunctions
            ModifiedFunctions = $modifiedFunctions
            AddedClasses = $addedClasses
            RemovedClasses = $removedClasses
            AddedImports = $addedImports
            RemovedImports = $removedImports
            SignificantChanges = ($addedFunctions.Count -gt 0) -or ($removedFunctions.Count -gt 0) -or ($modifiedFunctions.Count -gt 0) -or ($addedClasses.Count -gt 0) -or ($removedClasses.Count -gt 0)
            ChangeRatio = if ($oldIndex.LineCount -gt 0) { [Math]::Round(($addedLines + $removedLines) / $oldIndex.LineCount, 2) } else { 1.0 }
        }
        
        return $result
    }

    # Sauvegarder un index
    [void] SaveIndex([FileIndex]$index) {
        if (-not $this.PersistIndices -or [string]::IsNullOrEmpty($this.IndexPath)) {
            return
        }
        
        try {
            $fileName = [System.IO.Path]::GetFileName($index.FilePath)
            $hashPart = $index.FileHash.Substring(0, 8)
            $indexFileName = "$fileName.$hashPart.index.xml"
            $indexFilePath = Join-Path -Path $this.IndexPath -ChildPath $indexFileName
            
            # Sérialiser l'index au format XML
            $index | Export-Clixml -Path $indexFilePath -Force
        } catch {
            Write-Warning "Erreur lors de la sauvegarde de l'index pour $($index.FilePath): $_"
        }
    }

    # Charger un index
    [FileIndex] LoadIndex([string]$filePath) {
        if (-not $this.PersistIndices -or [string]::IsNullOrEmpty($this.IndexPath)) {
            return $null
        }
        
        try {
            # Calculer le hash du fichier actuel
            $currentHash = (Get-FileHash -Path $filePath -Algorithm SHA256).Hash
            
            # Rechercher un index correspondant
            $fileName = [System.IO.Path]::GetFileName($filePath)
            $hashPart = $currentHash.Substring(0, 8)
            $indexFileName = "$fileName.$hashPart.index.xml"
            $indexFilePath = Join-Path -Path $this.IndexPath -ChildPath $indexFileName
            
            if (Test-Path -Path $indexFilePath) {
                # Charger l'index
                $index = Import-Clixml -Path $indexFilePath
                
                # Vérifier que l'index correspond au fichier actuel
                if ($index.FileHash -eq $currentHash) {
                    # Mettre à jour la carte des symboles
                    foreach ($symbol in $index.Symbols.Keys) {
                        if (-not $this.SymbolMap.ContainsKey($symbol)) {
                            $this.SymbolMap[$symbol] = [System.Collections.Generic.List[string]]::new()
                        }
                        
                        if (-not $this.SymbolMap[$symbol].Contains($filePath)) {
                            $this.SymbolMap[$symbol].Add($filePath)
                        }
                    }
                    
                    # Stocker l'index
                    $this.FileIndices[$filePath] = $index
                    
                    return $index
                }
            }
        } catch {
            Write-Warning "Erreur lors du chargement de l'index pour $filePath: $_"
        }
        
        return $null
    }

    # Obtenir un index
    [FileIndex] GetIndex([string]$filePath) {
        # Vérifier si l'index existe déjà
        if ($this.FileIndices.ContainsKey($filePath)) {
            return $this.FileIndices[$filePath]
        }
        
        # Essayer de charger l'index
        $index = $this.LoadIndex($filePath)
        if ($null -ne $index) {
            return $index
        }
        
        # Créer un nouvel index
        return $this.IndexFile($filePath)
    }
}

# Fonction pour créer un nouvel indexeur
function New-FileContentIndexer {
    [CmdletBinding()]
    [OutputType([FileContentIndexer])]
    param(
        [Parameter()]
        [string]$IndexPath = "",
        
        [Parameter()]
        [bool]$PersistIndices = $false
    )
    
    try {
        $indexer = [FileContentIndexer]::new($IndexPath, $PersistIndices)
        return $indexer
    } catch {
        Write-Error "Erreur lors de la création de l'indexeur: $_"
        return $null
    }
}

# Fonction pour indexer un fichier
function New-FileIndex {
    [CmdletBinding()]
    [OutputType([FileIndex])]
    param(
        [Parameter(Mandatory = $true)]
        [FileContentIndexer]$Indexer,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        $index = $Indexer.IndexFile($FilePath)
        return $index
    } catch {
        Write-Error "Erreur lors de l'indexation du fichier: $_"
        return $null
    }
}

# Fonction pour rechercher dans les index
function Search-FileIndex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [FileContentIndexer]$Indexer,
        
        [Parameter(Mandatory = $true)]
        [string]$Query,
        
        [Parameter()]
        [string[]]$FileTypes = @()
    )
    
    try {
        $results = $Indexer.Search($Query, $FileTypes)
        return $results
    } catch {
        Write-Error "Erreur lors de la recherche: $_"
        return @()
    }
}

# Fonction pour comparer deux versions d'un fichier
function Compare-FileVersions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [FileContentIndexer]$Indexer,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$OldContent,
        
        [Parameter(Mandatory = $true)]
        [string]$NewContent
    )
    
    try {
        $result = $Indexer.CompareVersions($FilePath, $OldContent, $NewContent)
        return $result
    } catch {
        Write-Error "Erreur lors de la comparaison des versions: $_"
        return $null
    }
}

# Exporter les fonctions
Export-ModuleMember -Function New-FileContentIndexer, New-FileIndex, Search-FileIndex, Compare-FileVersions
