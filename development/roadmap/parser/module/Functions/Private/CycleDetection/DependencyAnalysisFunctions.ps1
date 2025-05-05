<#
.SYNOPSIS
    Fonctions pour l'analyse des dÃ©pendances entre fichiers.

.DESCRIPTION
    Ce script contient des fonctions pour analyser les dÃ©pendances entre fichiers
    dans un projet, en fonction du langage de programmation.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2025-04-25
#>

# Fonction pour analyser les dÃ©pendances d'un fichier PowerShell
function Get-PowerShellDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )
    
    try {
        # VÃ©rifier si le fichier existe
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            Write-Warning "Le fichier n'existe pas : $FilePath"
            return @()
        }
        
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw
        
        # Initialiser le tableau des dÃ©pendances
        $dependencies = @()
        
        # Rechercher les instructions . (dot sourcing)
        $dotMatches = [regex]::Matches($content, '(?m)^\s*\.\s+["''](.*?)["'']')
        
        foreach ($match in $dotMatches) {
            $path = $match.Groups[1].Value
            
            # Convertir le chemin relatif en chemin absolu
            if (-not [System.IO.Path]::IsPathRooted($path)) {
                $directory = [System.IO.Path]::GetDirectoryName($FilePath)
                $path = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($directory, $path))
            }
            
            # VÃ©rifier si le fichier existe
            if (Test-Path -Path $path -PathType Leaf) {
                $dependencies += $path
            }
            # Si le fichier n'existe pas, essayer d'ajouter l'extension .ps1
            elseif (Test-Path -Path "$path.ps1" -PathType Leaf) {
                $dependencies += "$path.ps1"
            }
        }
        
        # Rechercher les instructions Import-Module
        $importMatches = [regex]::Matches($content, '(?m)^\s*Import-Module\s+(?:-Name\s+)?["''](.*?)["'']')
        
        foreach ($match in $importMatches) {
            $moduleName = $match.Groups[1].Value
            
            # Rechercher le module dans le projet
            $moduleFiles = Get-ChildItem -Path $ProjectRoot -Recurse -Filter "$moduleName.psm1" -File
            
            foreach ($moduleFile in $moduleFiles) {
                $dependencies += $moduleFile.FullName
            }
        }
        
        # Rechercher les instructions using module
        $usingMatches = [regex]::Matches($content, '(?m)^\s*using\s+module\s+["''](.*?)["'']')
        
        foreach ($match in $usingMatches) {
            $moduleName = $match.Groups[1].Value
            
            # Rechercher le module dans le projet
            $moduleFiles = Get-ChildItem -Path $ProjectRoot -Recurse -Filter "$moduleName.psm1" -File
            
            foreach ($moduleFile in $moduleFiles) {
                $dependencies += $moduleFile.FullName
            }
        }
        
        # Retourner les dÃ©pendances uniques
        return $dependencies | Select-Object -Unique
    }
    catch {
        Write-Error "Erreur lors de l'analyse des dÃ©pendances PowerShell pour $FilePath : $_"
        return @()
    }
}

# Fonction pour analyser les dÃ©pendances d'un fichier Python
function Get-PythonDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )
    
    try {
        # VÃ©rifier si le fichier existe
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            Write-Warning "Le fichier n'existe pas : $FilePath"
            return @()
        }
        
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw
        
        # Initialiser le tableau des dÃ©pendances
        $dependencies = @()
        
        # Rechercher les instructions import
        $importMatches = [regex]::Matches($content, '(?m)^\s*import\s+([A-Za-z0-9_.]+)')
        
        foreach ($match in $importMatches) {
            $moduleName = $match.Groups[1].Value
            
            # Rechercher le module dans le projet
            $moduleFiles = Get-ChildItem -Path $ProjectRoot -Recurse -Filter "$moduleName.py" -File
            
            foreach ($moduleFile in $moduleFiles) {
                $dependencies += $moduleFile.FullName
            }
        }
        
        # Rechercher les instructions from ... import
        $fromMatches = [regex]::Matches($content, '(?m)^\s*from\s+([A-Za-z0-9_.]+)\s+import')
        
        foreach ($match in $fromMatches) {
            $moduleName = $match.Groups[1].Value
            
            # Rechercher le module dans le projet
            $moduleFiles = Get-ChildItem -Path $ProjectRoot -Recurse -Filter "$moduleName.py" -File
            
            foreach ($moduleFile in $moduleFiles) {
                $dependencies += $moduleFile.FullName
            }
            
            # Rechercher Ã©galement les packages
            $packagePath = $moduleName.Replace(".", [System.IO.Path]::DirectorySeparatorChar)
            $initFiles = Get-ChildItem -Path $ProjectRoot -Recurse -Filter "__init__.py" -File | Where-Object {
                $_.DirectoryName -like "*$packagePath"
            }
            
            foreach ($initFile in $initFiles) {
                $dependencies += $initFile.FullName
            }
        }
        
        # Retourner les dÃ©pendances uniques
        return $dependencies | Select-Object -Unique
    }
    catch {
        Write-Error "Erreur lors de l'analyse des dÃ©pendances Python pour $FilePath : $_"
        return @()
    }
}

# Fonction pour analyser les dÃ©pendances d'un fichier JavaScript/TypeScript
function Get-JavaScriptDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )
    
    try {
        # VÃ©rifier si le fichier existe
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            Write-Warning "Le fichier n'existe pas : $FilePath"
            return @()
        }
        
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw
        
        # Initialiser le tableau des dÃ©pendances
        $dependencies = @()
        
        # Rechercher les instructions import
        $importMatches = [regex]::Matches($content, '(?m)^\s*import\s+.*?from\s+["''](.*?)["'']')
        
        foreach ($match in $importMatches) {
            $path = $match.Groups[1].Value
            
            # Ignorer les modules externes
            if ($path.StartsWith(".")) {
                # Convertir le chemin relatif en chemin absolu
                $directory = [System.IO.Path]::GetDirectoryName($FilePath)
                $absolutePath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($directory, $path))
                
                # VÃ©rifier si le fichier existe
                if (Test-Path -Path $absolutePath -PathType Leaf) {
                    $dependencies += $absolutePath
                }
                # Si le fichier n'existe pas, essayer d'ajouter les extensions
                else {
                    $extensions = @(".js", ".jsx", ".ts", ".tsx")
                    
                    foreach ($ext in $extensions) {
                        if (Test-Path -Path "$absolutePath$ext" -PathType Leaf) {
                            $dependencies += "$absolutePath$ext"
                            break
                        }
                    }
                }
            }
        }
        
        # Rechercher les instructions require
        $requireMatches = [regex]::Matches($content, '(?m)require\s*\(\s*["''](.*?)["'']\s*\)')
        
        foreach ($match in $requireMatches) {
            $path = $match.Groups[1].Value
            
            # Ignorer les modules externes
            if ($path.StartsWith(".")) {
                # Convertir le chemin relatif en chemin absolu
                $directory = [System.IO.Path]::GetDirectoryName($FilePath)
                $absolutePath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($directory, $path))
                
                # VÃ©rifier si le fichier existe
                if (Test-Path -Path $absolutePath -PathType Leaf) {
                    $dependencies += $absolutePath
                }
                # Si le fichier n'existe pas, essayer d'ajouter les extensions
                else {
                    $extensions = @(".js", ".jsx", ".ts", ".tsx")
                    
                    foreach ($ext in $extensions) {
                        if (Test-Path -Path "$absolutePath$ext" -PathType Leaf) {
                            $dependencies += "$absolutePath$ext"
                            break
                        }
                    }
                }
            }
        }
        
        # Retourner les dÃ©pendances uniques
        return $dependencies | Select-Object -Unique
    }
    catch {
        Write-Error "Erreur lors de l'analyse des dÃ©pendances JavaScript/TypeScript pour $FilePath : $_"
        return @()
    }
}

# Fonction pour analyser les dÃ©pendances d'un fichier C#
function Get-CSharpDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )
    
    try {
        # VÃ©rifier si le fichier existe
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            Write-Warning "Le fichier n'existe pas : $FilePath"
            return @()
        }
        
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw
        
        # Initialiser le tableau des dÃ©pendances
        $dependencies = @()
        
        # Rechercher les instructions using
        $usingMatches = [regex]::Matches($content, '(?m)^\s*using\s+([A-Za-z0-9_.]+);')
        
        # Traiter les correspondances
        foreach ($match in $usingMatches) {
            $namespace = $match.Groups[1].Value
            
            # Ignorer les namespaces systÃ¨me
            if ($namespace -match '^System\.') {
                continue
            }
            
            # Rechercher les fichiers qui dÃ©finissent ce namespace
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
        
        # Retourner les dÃ©pendances uniques
        return $dependencies | Select-Object -Unique
    }
    catch {
        Write-Error "Erreur lors de l'analyse des dÃ©pendances C# pour $FilePath : $_"
        return @()
    }
}

# Fonction pour analyser les dÃ©pendances d'un fichier Java
function Get-JavaDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )
    
    try {
        # VÃ©rifier si le fichier existe
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            Write-Warning "Le fichier n'existe pas : $FilePath"
            return @()
        }
        
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw
        
        # Initialiser le tableau des dÃ©pendances
        $dependencies = @()
        
        # Rechercher les instructions import
        $importMatches = [regex]::Matches($content, '(?m)^\s*import\s+([A-Za-z0-9_.]+)(?:\.\*)?;')
        
        foreach ($match in $importMatches) {
            $package = $match.Groups[1].Value
            
            # Rechercher les fichiers qui dÃ©finissent ce package
            $packagePath = $package.Replace(".", [System.IO.Path]::DirectorySeparatorChar)
            $files = Get-ChildItem -Path $ProjectRoot -Recurse -Filter "*.java" -File | Where-Object {
                $_.DirectoryName -like "*$packagePath"
            }
            
            foreach ($file in $files) {
                if ($file.FullName -ne $FilePath) {
                    $dependencies += $file.FullName
                }
            }
        }
        
        # Retourner les dÃ©pendances uniques
        return $dependencies | Select-Object -Unique
    }
    catch {
        Write-Error "Erreur lors de l'analyse des dÃ©pendances Java pour $FilePath : $_"
        return @()
    }
}

# Fonction pour analyser les dÃ©pendances d'un fichier
function Get-FileDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )
    
    try {
        # VÃ©rifier si le fichier existe
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            Write-Warning "Le fichier n'existe pas : $FilePath"
            return @()
        }
        
        # Obtenir l'extension du fichier
        $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
        
        # Analyser les dÃ©pendances en fonction du type de fichier
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
        Write-Error "Erreur lors de l'analyse des dÃ©pendances pour $FilePath : $_"
        return @()
    }
}

# Fonction pour construire le graphe de dÃ©pendances
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
        # Initialiser le graphe de dÃ©pendances
        $graph = @{}
        
        # Construire le graphe
        foreach ($file in $Files) {
            $filePath = $file.FullName
            
            # Initialiser l'entrÃ©e dans le graphe
            if (-not $graph.ContainsKey($filePath)) {
                $graph[$filePath] = @()
            }
            
            # Obtenir les dÃ©pendances directes
            $dependencies = Get-FileDependencies -FilePath $filePath -ProjectRoot $ProjectRoot
            
            # Ajouter les dÃ©pendances au graphe
            foreach ($dependency in $dependencies) {
                if ($dependency -ne $filePath) {
                    $graph[$filePath] += $dependency
                }
            }
        }
        
        # Limiter la profondeur des dÃ©pendances
        if ($MaxDepth -gt 0) {
            $visited = @{}
            
            function Limit-Depth {
                param(
                    [Parameter(Mandatory = $true)]
                    [string]$Node,
                    
                    [Parameter(Mandatory = $true)]
                    [int]$Depth
                )
                
                # Marquer le nÅ“ud comme visitÃ©
                $visited[$Node] = $true
                
                # Si la profondeur maximale est atteinte, arrÃªter
                if ($Depth -ge $MaxDepth) {
                    return
                }
                
                # Parcourir les dÃ©pendances
                if ($graph.ContainsKey($Node)) {
                    foreach ($dependency in $graph[$Node]) {
                        if (-not $visited.ContainsKey($dependency)) {
                            Limit-Depth -Node $dependency -Depth ($Depth + 1)
                        }
                    }
                }
            }
            
            # Limiter la profondeur pour chaque nÅ“ud
            foreach ($node in $graph.Keys) {
                $visited = @{}
                Limit-Depth -Node $node -Depth 0
            }
        }
        
        return $graph
    }
    catch {
        Write-Error "Erreur lors de la construction du graphe de dÃ©pendances : $_"
        return @{}
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Get-FileDependencies, Build-DependencyGraph
