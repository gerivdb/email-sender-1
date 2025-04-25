<#
.SYNOPSIS
    Fonctions pour l'analyse des dépendances entre fichiers.

.DESCRIPTION
    Ce script contient des fonctions pour analyser les dépendances entre fichiers
    dans un projet, en fonction du langage de programmation.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2025-04-25
#>

# Fonction pour analyser les dépendances d'un fichier PowerShell
function Get-PowerShellDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )
    
    try {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            Write-Warning "Le fichier n'existe pas : $FilePath"
            return @()
        }
        
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw
        
        # Initialiser le tableau des dépendances
        $dependencies = @()
        
        # Rechercher les instructions d'importation
        $importMatches = [regex]::Matches($content, '(?i)(Import-Module|\.|\.\.|&|\. \$PSScriptRoot\\|\. \$PSScriptRoot/|Invoke-Expression)\s+(?:["'']?([^"'';\r\n]+)["'']?)')
        $dotSourceMatches = [regex]::Matches($content, '(?i)\.\s+(?:["'']?([^"'';\r\n]+)["'']?)')
        $requireMatches = [regex]::Matches($content, '(?i)#Requires\s+-Modules\s+(?:["'']?([^"'';\r\n]+)["'']?)')
        
        # Traiter les correspondances d'importation
        foreach ($match in $importMatches) {
            $importPath = $match.Groups[2].Value.Trim()
            
            # Ignorer les importations de modules système
            if ($importPath -match '^[A-Za-z0-9]+$') {
                continue
            }
            
            # Résoudre le chemin complet
            $resolvedPath = Resolve-DependencyPath -BasePath (Split-Path -Parent $FilePath) -DependencyPath $importPath -ProjectRoot $ProjectRoot
            
            if ($resolvedPath -and (Test-Path -Path $resolvedPath -PathType Leaf)) {
                $dependencies += $resolvedPath
            }
        }
        
        # Traiter les correspondances de dot sourcing
        foreach ($match in $dotSourceMatches) {
            $importPath = $match.Groups[1].Value.Trim()
            
            # Résoudre le chemin complet
            $resolvedPath = Resolve-DependencyPath -BasePath (Split-Path -Parent $FilePath) -DependencyPath $importPath -ProjectRoot $ProjectRoot
            
            if ($resolvedPath -and (Test-Path -Path $resolvedPath -PathType Leaf)) {
                $dependencies += $resolvedPath
            }
        }
        
        # Traiter les correspondances de #Requires
        foreach ($match in $requireMatches) {
            $moduleName = $match.Groups[1].Value.Trim()
            
            # Ignorer les modules système
            if ($moduleName -match '^[A-Za-z0-9]+$') {
                continue
            }
            
            # Rechercher le module dans le projet
            $moduleFiles = Get-ChildItem -Path $ProjectRoot -Recurse -Filter "$moduleName.ps*" -File
            
            foreach ($moduleFile in $moduleFiles) {
                $dependencies += $moduleFile.FullName
            }
        }
        
        # Retourner les dépendances uniques
        return $dependencies | Select-Object -Unique
    }
    catch {
        Write-Error "Erreur lors de l'analyse des dépendances PowerShell pour $FilePath : $_"
        return @()
    }
}

# Fonction pour analyser les dépendances d'un fichier Python
function Get-PythonDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )
    
    try {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            Write-Warning "Le fichier n'existe pas : $FilePath"
            return @()
        }
        
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw
        
        # Initialiser le tableau des dépendances
        $dependencies = @()
        
        # Rechercher les instructions d'importation
        $importMatches = [regex]::Matches($content, '(?m)^\s*(?:from\s+([.\w]+)\s+import|import\s+([.\w]+))')
        
        # Traiter les correspondances
        foreach ($match in $importMatches) {
            $moduleName = if ($match.Groups[1].Success) { $match.Groups[1].Value } else { $match.Groups[2].Value }
            
            # Ignorer les modules système
            if ($moduleName -match '^[A-Za-z0-9]+$') {
                continue
            }
            
            # Convertir le nom du module en chemin relatif
            $relativePath = $moduleName -replace '\.', [IO.Path]::DirectorySeparatorChar
            
            # Rechercher les fichiers correspondants
            $possiblePaths = @(
                "$relativePath.py",
                "$relativePath/__init__.py",
                "$relativePath.pyd",
                "$relativePath.pyo",
                "$relativePath.pyc"
            )
            
            foreach ($path in $possiblePaths) {
                $resolvedPath = Resolve-DependencyPath -BasePath (Split-Path -Parent $FilePath) -DependencyPath $path -ProjectRoot $ProjectRoot
                
                if ($resolvedPath -and (Test-Path -Path $resolvedPath -PathType Leaf)) {
                    $dependencies += $resolvedPath
                    break
                }
            }
        }
        
        # Retourner les dépendances uniques
        return $dependencies | Select-Object -Unique
    }
    catch {
        Write-Error "Erreur lors de l'analyse des dépendances Python pour $FilePath : $_"
        return @()
    }
}

# Fonction pour analyser les dépendances d'un fichier JavaScript/TypeScript
function Get-JavaScriptDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )
    
    try {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            Write-Warning "Le fichier n'existe pas : $FilePath"
            return @()
        }
        
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw
        
        # Initialiser le tableau des dépendances
        $dependencies = @()
        
        # Rechercher les instructions d'importation
        $importMatches = [regex]::Matches($content, '(?m)(?:import\s+(?:.+\s+from\s+)?["'']([^"'']+)["'']|require\s*\(\s*["'']([^"'']+)["'']\s*\))')
        
        # Traiter les correspondances
        foreach ($match in $importMatches) {
            $importPath = if ($match.Groups[1].Success) { $match.Groups[1].Value } else { $match.Groups[2].Value }
            
            # Ignorer les modules npm
            if (-not $importPath.StartsWith('.') -and -not $importPath.StartsWith('/')) {
                continue
            }
            
            # Ajouter les extensions possibles si nécessaire
            if (-not $importPath.Contains('.')) {
                $possibleExtensions = @('.js', '.jsx', '.ts', '.tsx', '.json')
                
                foreach ($ext in $possibleExtensions) {
                    $pathWithExt = "$importPath$ext"
                    $resolvedPath = Resolve-DependencyPath -BasePath (Split-Path -Parent $FilePath) -DependencyPath $pathWithExt -ProjectRoot $ProjectRoot
                    
                    if ($resolvedPath -and (Test-Path -Path $resolvedPath -PathType Leaf)) {
                        $dependencies += $resolvedPath
                        break
                    }
                }
                
                # Vérifier s'il s'agit d'un répertoire avec un fichier index
                $indexFiles = @('index.js', 'index.jsx', 'index.ts', 'index.tsx')
                
                foreach ($indexFile in $indexFiles) {
                    $indexPath = "$importPath/$indexFile"
                    $resolvedPath = Resolve-DependencyPath -BasePath (Split-Path -Parent $FilePath) -DependencyPath $indexPath -ProjectRoot $ProjectRoot
                    
                    if ($resolvedPath -and (Test-Path -Path $resolvedPath -PathType Leaf)) {
                        $dependencies += $resolvedPath
                        break
                    }
                }
            }
            else {
                # Le chemin a déjà une extension
                $resolvedPath = Resolve-DependencyPath -BasePath (Split-Path -Parent $FilePath) -DependencyPath $importPath -ProjectRoot $ProjectRoot
                
                if ($resolvedPath -and (Test-Path -Path $resolvedPath -PathType Leaf)) {
                    $dependencies += $resolvedPath
                }
            }
        }
        
        # Retourner les dépendances uniques
        return $dependencies | Select-Object -Unique
    }
    catch {
        Write-Error "Erreur lors de l'analyse des dépendances JavaScript/TypeScript pour $FilePath : $_"
        return @()
    }
}

# Fonction pour analyser les dépendances d'un fichier C#
function Get-CSharpDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )
    
    try {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            Write-Warning "Le fichier n'existe pas : $FilePath"
            return @()
        }
        
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw
        
        # Initialiser le tableau des dépendances
        $dependencies = @()
        
        # Rechercher les instructions using
        $usingMatches = [regex]::Matches($content, '(?m)^\s*using\s+([A-Za-z0-9_.]+);')
        
        # Traiter les correspondances
        foreach ($match in $usingMatches) {
            $namespace = $match.Groups[1].Value
            
            # Ignorer les namespaces système
            if ($namespace -match '^System\.') {
                continue
            }
            
            # Rechercher les fichiers qui définissent ce namespace
            $files = Get-ChildItem -Path $ProjectRoot -Recurse -Filter "*.cs" -File | Where-Object {
                $fileContent = Get-Content -Path $_.FullName -Raw
                $fileContent -match "namespace\s+$([regex]::Escape($namespace))"
            }
            
            foreach ($file in $files) {
                if ($file.FullName -ne $FilePath) {
                    $dependencies += $file.FullName
                }
            }
        }
        
        # Retourner les dépendances uniques
        return $dependencies | Select-Object -Unique
    }
    catch {
        Write-Error "Erreur lors de l'analyse des dépendances C# pour $FilePath : $_"
        return @()
    }
}

# Fonction pour analyser les dépendances d'un fichier Java
function Get-JavaDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )
    
    try {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            Write-Warning "Le fichier n'existe pas : $FilePath"
            return @()
        }
        
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw
        
        # Initialiser le tableau des dépendances
        $dependencies = @()
        
        # Rechercher les instructions import
        $importMatches = [regex]::Matches($content, '(?m)^\s*import\s+([A-Za-z0-9_.]+)(?:\.\*)?;')
        
        # Traiter les correspondances
        foreach ($match in $importMatches) {
            $packageName = $match.Groups[1].Value
            
            # Ignorer les packages système
            if ($packageName -match '^java\.' -or $packageName -match '^javax\.') {
                continue
            }
            
            # Convertir le nom du package en chemin relatif
            $relativePath = $packageName -replace '\.', [IO.Path]::DirectorySeparatorChar
            
            # Rechercher les fichiers correspondants
            $files = Get-ChildItem -Path $ProjectRoot -Recurse -Filter "*.java" -File | Where-Object {
                $fileContent = Get-Content -Path $_.FullName -Raw
                $fileContent -match "package\s+$([regex]::Escape($packageName))"
            }
            
            foreach ($file in $files) {
                if ($file.FullName -ne $FilePath) {
                    $dependencies += $file.FullName
                }
            }
        }
        
        # Retourner les dépendances uniques
        return $dependencies | Select-Object -Unique
    }
    catch {
        Write-Error "Erreur lors de l'analyse des dépendances Java pour $FilePath : $_"
        return @()
    }
}

# Fonction pour résoudre le chemin d'une dépendance
function Resolve-DependencyPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath,
        
        [Parameter(Mandatory = $true)]
        [string]$DependencyPath,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )
    
    try {
        # Normaliser les chemins
        $BasePath = $BasePath.Replace('/', '\')
        $DependencyPath = $DependencyPath.Replace('/', '\')
        $ProjectRoot = $ProjectRoot.Replace('/', '\')
        
        # Vérifier si le chemin est absolu
        if ([System.IO.Path]::IsPathRooted($DependencyPath)) {
            # Vérifier si le chemin est dans le projet
            if ($DependencyPath.StartsWith($ProjectRoot)) {
                return $DependencyPath
            }
            return $null
        }
        
        # Résoudre le chemin relatif
        $resolvedPath = $null
        
        # Gérer les chemins relatifs avec .. et .
        if ($DependencyPath.StartsWith('..') -or $DependencyPath.StartsWith('.')) {
            $resolvedPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($BasePath, $DependencyPath))
        }
        else {
            # Essayer de résoudre par rapport à la racine du projet
            $resolvedPath = [System.IO.Path]::Combine($ProjectRoot, $DependencyPath)
        }
        
        # Vérifier si le chemin résolu est dans le projet
        if ($resolvedPath -and $resolvedPath.StartsWith($ProjectRoot)) {
            return $resolvedPath
        }
        
        return $null
    }
    catch {
        Write-Error "Erreur lors de la résolution du chemin de dépendance : $_"
        return $null
    }
}

# Fonction principale pour analyser les dépendances d'un fichier
function Get-FileDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )
    
    try {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            Write-Warning "Le fichier n'existe pas : $FilePath"
            return @()
        }
        
        # Déterminer le type de fichier
        $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
        
        # Analyser les dépendances en fonction du type de fichier
        switch ($extension) {
            { $_ -in '.ps1', '.psm1', '.psd1' } {
                return Get-PowerShellDependencies -FilePath $FilePath -ProjectRoot $ProjectRoot
            }
            { $_ -in '.py', '.pyw' } {
                return Get-PythonDependencies -FilePath $FilePath -ProjectRoot $ProjectRoot
            }
            { $_ -in '.js', '.jsx', '.ts', '.tsx' } {
                return Get-JavaScriptDependencies -FilePath $FilePath -ProjectRoot $ProjectRoot
            }
            { $_ -in '.cs', '.csx' } {
                return Get-CSharpDependencies -FilePath $FilePath -ProjectRoot $ProjectRoot
            }
            { $_ -in '.java' } {
                return Get-JavaDependencies -FilePath $FilePath -ProjectRoot $ProjectRoot
            }
            default {
                Write-Warning "Type de fichier non pris en charge : $extension"
                return @()
            }
        }
    }
    catch {
        Write-Error "Erreur lors de l'analyse des dépendances pour $FilePath : $_"
        return @()
    }
}

# Fonction pour construire un graphe de dépendances
function Build-DependencyGraph {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo[]]$Files,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = 10
    )
    
    try {
        # Initialiser le graphe de dépendances
        $graph = @{}
        
        # Construire le graphe
        foreach ($file in $Files) {
            $filePath = $file.FullName
            
            # Vérifier si le fichier est déjà dans le graphe
            if (-not $graph.ContainsKey($filePath)) {
                $graph[$filePath] = @()
            }
            
            # Analyser les dépendances du fichier
            $dependencies = Get-FileDependencies -FilePath $filePath -ProjectRoot $ProjectRoot
            
            # Ajouter les dépendances au graphe
            $graph[$filePath] = $dependencies
        }
        
        # Limiter la profondeur du graphe si nécessaire
        if ($MaxDepth -gt 0) {
            $graph = Limit-GraphDepth -Graph $graph -MaxDepth $MaxDepth
        }
        
        return $graph
    }
    catch {
        Write-Error "Erreur lors de la construction du graphe de dépendances : $_"
        return @{}
    }
}

# Fonction pour limiter la profondeur du graphe
function Limit-GraphDepth {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph,
        
        [Parameter(Mandatory = $true)]
        [int]$MaxDepth
    )
    
    try {
        # Initialiser le graphe limité
        $limitedGraph = @{}
        
        # Parcourir chaque nœud du graphe
        foreach ($node in $Graph.Keys) {
            # Initialiser le graphe limité pour ce nœud
            $limitedGraph[$node] = @()
            
            # Parcourir les dépendances avec une profondeur limitée
            $visited = @{}
            $queue = New-Object System.Collections.Queue
            $queue.Enqueue(@{Node = $node; Depth = 0})
            
            while ($queue.Count -gt 0) {
                $current = $queue.Dequeue()
                $currentNode = $current.Node
                $currentDepth = $current.Depth
                
                # Marquer le nœud comme visité
                $visited[$currentNode] = $true
                
                # Ajouter les dépendances directes au graphe limité
                if ($currentNode -ne $node) {
                    $limitedGraph[$node] += $currentNode
                }
                
                # Continuer si la profondeur maximale n'est pas atteinte
                if ($currentDepth -lt $MaxDepth) {
                    # Parcourir les dépendances du nœud courant
                    foreach ($dependency in $Graph[$currentNode]) {
                        # Vérifier si la dépendance existe dans le graphe
                        if ($Graph.ContainsKey($dependency) -and -not $visited.ContainsKey($dependency)) {
                            $queue.Enqueue(@{Node = $dependency; Depth = $currentDepth + 1})
                        }
                    }
                }
            }
            
            # Éliminer les doublons
            $limitedGraph[$node] = $limitedGraph[$node] | Select-Object -Unique
        }
        
        return $limitedGraph
    }
    catch {
        Write-Error "Erreur lors de la limitation de la profondeur du graphe : $_"
        return $Graph
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Get-FileDependencies, Build-DependencyGraph
