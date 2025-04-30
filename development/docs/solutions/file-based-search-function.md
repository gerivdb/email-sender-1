# Fonction de recherche de fichiers de gestionnaires

## Introduction

Ce document propose une implémentation d'une fonction de recherche de fichiers de gestionnaires pour le Process Manager. L'objectif est de permettre au Process Manager de découvrir des gestionnaires implémentés directement dans des fichiers, sans nécessairement être organisés dans des répertoires spécifiques.

## Problématique

Actuellement, le mécanisme de découverte des gestionnaires du Process Manager recherche uniquement les répertoires dont le nom correspond au modèle `*-manager`. Cette limitation empêche la découverte de gestionnaires qui pourraient être implémentés directement dans des fichiers, sans être organisés dans des répertoires spécifiques.

```powershell
$managerDirs = Get-ChildItem -Path $fullSearchPath -Directory | Where-Object { $_.Name -like "*-manager" }
```

## Solution proposée

### Fonction de recherche de fichiers de gestionnaires

La fonction `Find-ManagerFiles` permettra de rechercher des fichiers qui pourraient contenir des gestionnaires, en se basant sur des critères de nommage et de contenu.

```powershell
function Find-ManagerFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string[]]$FilePatterns = @("*manager*.ps1", "*manager*.psm1"),
        
        [Parameter(Mandatory = $false)]
        [string[]]$ContentPatterns = @("function *-*Manager*", "function *Manager*"),
        
        [Parameter(Mandatory = $false)]
        [switch]$Recurse,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = -1,
        
        [Parameter(Mandatory = $false)]
        [switch]$ExcludeBackups,
        
        [Parameter(Mandatory = $false)]
        [switch]$ExcludeTests,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeContent
    )

    Write-Verbose "Recherche de fichiers de gestionnaires dans $Path..."
    
    # Vérifier si le chemin existe
    if (-not (Test-Path -Path $Path)) {
        Write-Warning "Le chemin $Path n'existe pas."
        return @()
    }
    
    # Construire les paramètres pour Get-ChildItem
    $getChildItemParams = @{
        Path = $Path
        File = $true
        Include = $FilePatterns
    }
    
    if ($Recurse) {
        $getChildItemParams.Recurse = $true
    }
    
    # Rechercher les fichiers correspondant aux modèles
    $files = Get-ChildItem @getChildItemParams
    
    # Filtrer les fichiers
    $filteredFiles = $files | Where-Object {
        $include = $true
        
        # Exclure les fichiers de sauvegarde si demandé
        if ($ExcludeBackups -and ($_.Name -like "*backup*" -or $_.Name -like "*bak*" -or $_.FullName -like "*backup*" -or $_.FullName -like "*bak*")) {
            $include = $false
        }
        
        # Exclure les fichiers de test si demandé
        if ($ExcludeTests -and ($_.Name -like "*test*" -or $_.Name -like "*Test*" -or $_.FullName -like "*test*" -or $_.FullName -like "*Test*")) {
            $include = $false
        }
        
        # Vérifier la profondeur si spécifiée
        if ($MaxDepth -ne -1) {
            $relativePath = $_.FullName.Substring($Path.Length)
            $depth = ($relativePath -split '\\').Count - 1
            if ($depth -gt $MaxDepth) {
                $include = $false
            }
        }
        
        return $include
    }
    
    # Vérifier le contenu des fichiers si demandé
    if ($IncludeContent) {
        $contentFilteredFiles = @()
        
        foreach ($file in $filteredFiles) {
            $content = Get-Content -Path $file.FullName -Raw
            $matchesContent = $false
            
            foreach ($pattern in $ContentPatterns) {
                if ($content -match $pattern) {
                    $matchesContent = $true
                    break
                }
            }
            
            if ($matchesContent) {
                $contentFilteredFiles += $file
            }
        }
        
        $filteredFiles = $contentFilteredFiles
    }
    
    Write-Verbose "Trouvé $($filteredFiles.Count) fichiers de gestionnaires."
    
    return $filteredFiles
}
```

### Paramètres de la fonction

- **Path** : Chemin de base pour la recherche.
- **FilePatterns** : Modèles de noms de fichiers à rechercher. Par défaut, recherche les fichiers dont le nom contient "manager" et qui ont l'extension .ps1 ou .psm1.
- **ContentPatterns** : Modèles de contenu à rechercher dans les fichiers. Par défaut, recherche les fonctions dont le nom suit le format `*-*Manager*` ou `*Manager*`.
- **Recurse** : Indique si la recherche doit être récursive.
- **MaxDepth** : Profondeur maximale de recherche. -1 signifie pas de limite.
- **ExcludeBackups** : Indique si les fichiers de sauvegarde doivent être exclus.
- **ExcludeTests** : Indique si les fichiers de test doivent être exclus.
- **IncludeContent** : Indique si le contenu des fichiers doit être vérifié.

### Exemples d'utilisation

#### Exemple 1 : Recherche simple

```powershell
$managerFiles = Find-ManagerFiles -Path "development\managers"
```

#### Exemple 2 : Recherche récursive

```powershell
$managerFiles = Find-ManagerFiles -Path "development\managers" -Recurse
```

#### Exemple 3 : Recherche avec vérification du contenu

```powershell
$managerFiles = Find-ManagerFiles -Path "development\managers" -Recurse -IncludeContent
```

#### Exemple 4 : Recherche avec exclusion des fichiers de sauvegarde et de test

```powershell
$managerFiles = Find-ManagerFiles -Path "development\managers" -Recurse -ExcludeBackups -ExcludeTests
```

#### Exemple 5 : Recherche avec profondeur limitée

```powershell
$managerFiles = Find-ManagerFiles -Path "development\managers" -Recurse -MaxDepth 2
```

#### Exemple 6 : Recherche avec modèles personnalisés

```powershell
$managerFiles = Find-ManagerFiles -Path "development\managers" -Recurse -FilePatterns @("*controller*.ps1", "*service*.ps1") -ContentPatterns @("function *-*Controller*", "function *-*Service*")
```

## Optimisations possibles

### Optimisation 1 : Utilisation de la parallélisation

Pour améliorer les performances de la recherche, nous pouvons utiliser la parallélisation pour traiter plusieurs fichiers simultanément.

```powershell
# Vérifier le contenu des fichiers si demandé
if ($IncludeContent) {
    $contentFilteredFiles = @()
    
    # Utiliser ForEach-Object -Parallel si PowerShell 7+
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        $contentFilteredFiles = $filteredFiles | ForEach-Object -Parallel {
            $file = $_
            $content = Get-Content -Path $file.FullName -Raw
            $matchesContent = $false
            
            foreach ($pattern in $using:ContentPatterns) {
                if ($content -match $pattern) {
                    $matchesContent = $true
                    break
                }
            }
            
            if ($matchesContent) {
                $file
            }
        }
    } else {
        # Utiliser la méthode séquentielle pour PowerShell 5.1
        foreach ($file in $filteredFiles) {
            $content = Get-Content -Path $file.FullName -Raw
            $matchesContent = $false
            
            foreach ($pattern in $ContentPatterns) {
                if ($content -match $pattern) {
                    $matchesContent = $true
                    break
                }
            }
            
            if ($matchesContent) {
                $contentFilteredFiles += $file
            }
        }
    }
    
    $filteredFiles = $contentFilteredFiles
}
```

### Optimisation 2 : Utilisation de la mise en cache

Pour éviter de relire le contenu des fichiers à chaque recherche, nous pouvons mettre en cache les résultats.

```powershell
# Utiliser une variable statique pour la mise en cache
if (-not $script:ManagerFilesCache) {
    $script:ManagerFilesCache = @{}
}

# Vérifier si le résultat est déjà en cache
$cacheKey = "$Path|$($FilePatterns -join ',')|$($ContentPatterns -join ',')|$Recurse|$MaxDepth|$ExcludeBackups|$ExcludeTests|$IncludeContent"
if ($script:ManagerFilesCache.ContainsKey($cacheKey)) {
    Write-Verbose "Utilisation du cache pour la recherche de fichiers de gestionnaires."
    return $script:ManagerFilesCache[$cacheKey]
}

# Code de recherche existant...

# Mettre le résultat en cache
$script:ManagerFilesCache[$cacheKey] = $filteredFiles

return $filteredFiles
```

### Optimisation 3 : Utilisation de l'analyse statique

Pour éviter de lire le contenu complet des fichiers, nous pouvons utiliser l'analyse statique pour extraire les informations nécessaires.

```powershell
# Utiliser l'analyse statique pour extraire les fonctions
$ast = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$null)
$functions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)

$matchesContent = $false
foreach ($function in $functions) {
    foreach ($pattern in $ContentPatterns) {
        if ($function.Name -match $pattern) {
            $matchesContent = $true
            break
        }
    }
    
    if ($matchesContent) {
        break
    }
}
```

## Tests

Pour valider l'implémentation de la fonction `Find-ManagerFiles`, nous recommandons de créer les tests suivants :

### Test 1 : Recherche de fichiers par nom

```powershell
# Créer une structure de test
$testDir = Join-Path -Path $env:TEMP -ChildPath "ProcessManagerTest"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null
$managerFile = Join-Path -Path $testDir -ChildPath "TestManager.ps1"
@"
function Start-TestManager {
    [CmdletBinding()]
    param()
    
    Write-Host "Démarrage du gestionnaire de test..."
}
"@ | Set-Content -Path $managerFile -Encoding UTF8

# Exécuter la fonction Find-ManagerFiles
$result = Find-ManagerFiles -Path $testDir

# Vérifier que le fichier a été trouvé
$found = $result | Where-Object { $_.Name -eq "TestManager.ps1" }

# Nettoyer
Remove-Item -Path $testDir -Recurse -Force

# Le test est réussi si le fichier a été trouvé
return $found -ne $null
```

### Test 2 : Recherche de fichiers par contenu

```powershell
# Créer une structure de test
$testDir = Join-Path -Path $env:TEMP -ChildPath "ProcessManagerTest"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null
$managerFile = Join-Path -Path $testDir -ChildPath "CustomFile.ps1"
@"
function Start-CustomManager {
    [CmdletBinding()]
    param()
    
    Write-Host "Démarrage du gestionnaire personnalisé..."
}
"@ | Set-Content -Path $managerFile -Encoding UTF8

# Exécuter la fonction Find-ManagerFiles
$result = Find-ManagerFiles -Path $testDir -IncludeContent

# Vérifier que le fichier a été trouvé
$found = $result | Where-Object { $_.Name -eq "CustomFile.ps1" }

# Nettoyer
Remove-Item -Path $testDir -Recurse -Force

# Le test est réussi si le fichier a été trouvé
return $found -ne $null
```

### Test 3 : Exclusion des fichiers de sauvegarde

```powershell
# Créer une structure de test
$testDir = Join-Path -Path $env:TEMP -ChildPath "ProcessManagerTest"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null
$managerFile = Join-Path -Path $testDir -ChildPath "TestManager.ps1"
@"
function Start-TestManager {
    [CmdletBinding()]
    param()
    
    Write-Host "Démarrage du gestionnaire de test..."
}
"@ | Set-Content -Path $managerFile -Encoding UTF8
$backupFile = Join-Path -Path $testDir -ChildPath "TestManager.backup.ps1"
@"
function Start-TestManager {
    [CmdletBinding()]
    param()
    
    Write-Host "Démarrage du gestionnaire de test (sauvegarde)..."
}
"@ | Set-Content -Path $backupFile -Encoding UTF8

# Exécuter la fonction Find-ManagerFiles
$result = Find-ManagerFiles -Path $testDir -ExcludeBackups

# Vérifier que seul le fichier principal a été trouvé
$foundMain = $result | Where-Object { $_.Name -eq "TestManager.ps1" }
$foundBackup = $result | Where-Object { $_.Name -eq "TestManager.backup.ps1" }

# Nettoyer
Remove-Item -Path $testDir -Recurse -Force

# Le test est réussi si le fichier principal a été trouvé et le fichier de sauvegarde non
return $foundMain -ne $null -and $foundBackup -eq $null
```

### Test 4 : Recherche récursive

```powershell
# Créer une structure de test
$testDir = Join-Path -Path $env:TEMP -ChildPath "ProcessManagerTest"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null
$subDir = Join-Path -Path $testDir -ChildPath "subdir"
New-Item -Path $subDir -ItemType Directory -Force | Out-Null
$managerFile = Join-Path -Path $subDir -ChildPath "TestManager.ps1"
@"
function Start-TestManager {
    [CmdletBinding()]
    param()
    
    Write-Host "Démarrage du gestionnaire de test..."
}
"@ | Set-Content -Path $managerFile -Encoding UTF8

# Exécuter la fonction Find-ManagerFiles
$result = Find-ManagerFiles -Path $testDir -Recurse

# Vérifier que le fichier a été trouvé
$found = $result | Where-Object { $_.Name -eq "TestManager.ps1" }

# Nettoyer
Remove-Item -Path $testDir -Recurse -Force

# Le test est réussi si le fichier a été trouvé
return $found -ne $null
```

### Test 5 : Recherche avec profondeur limitée

```powershell
# Créer une structure de test
$testDir = Join-Path -Path $env:TEMP -ChildPath "ProcessManagerTest"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null
$subDir1 = Join-Path -Path $testDir -ChildPath "subdir1"
New-Item -Path $subDir1 -ItemType Directory -Force | Out-Null
$managerFile1 = Join-Path -Path $subDir1 -ChildPath "TestManager1.ps1"
@"
function Start-TestManager1 {
    [CmdletBinding()]
    param()
    
    Write-Host "Démarrage du gestionnaire de test 1..."
}
"@ | Set-Content -Path $managerFile1 -Encoding UTF8
$subDir2 = Join-Path -Path $subDir1 -ChildPath "subdir2"
New-Item -Path $subDir2 -ItemType Directory -Force | Out-Null
$managerFile2 = Join-Path -Path $subDir2 -ChildPath "TestManager2.ps1"
@"
function Start-TestManager2 {
    [CmdletBinding()]
    param()
    
    Write-Host "Démarrage du gestionnaire de test 2..."
}
"@ | Set-Content -Path $managerFile2 -Encoding UTF8

# Exécuter la fonction Find-ManagerFiles
$result = Find-ManagerFiles -Path $testDir -Recurse -MaxDepth 1

# Vérifier que seul le premier fichier a été trouvé
$found1 = $result | Where-Object { $_.Name -eq "TestManager1.ps1" }
$found2 = $result | Where-Object { $_.Name -eq "TestManager2.ps1" }

# Nettoyer
Remove-Item -Path $testDir -Recurse -Force

# Le test est réussi si le premier fichier a été trouvé et le second non
return $found1 -ne $null -and $found2 -eq $null
```

## Intégration avec le Process Manager

Pour intégrer la fonction `Find-ManagerFiles` au Process Manager, nous recommandons de l'ajouter au module `ProcessManager` et de l'utiliser dans la fonction `Discover-Managers`.

```powershell
function Discover-Managers {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $false)]
        [switch]$SkipDependencyCheck,
        
        [Parameter(Mandatory = $false)]
        [switch]$SkipValidation,
        
        [Parameter(Mandatory = $false)]
        [switch]$SkipSecurityCheck,
        
        [Parameter(Mandatory = $false)]
        [string[]]$SearchPaths = @("development\managers"),
        
        [Parameter(Mandatory = $false)]
        [switch]$Recursive,
        
        [Parameter(Mandatory = $false)]
        [switch]$SearchFiles,
        
        [Parameter(Mandatory = $false)]
        [string[]]$FilePatterns = @("*manager*.ps1", "*manager*.psm1"),
        
        [Parameter(Mandatory = $false)]
        [string[]]$ContentPatterns = @("function *-*Manager*", "function *Manager*"),
        
        [Parameter(Mandatory = $false)]
        [switch]$ExcludeBackups,
        
        [Parameter(Mandatory = $false)]
        [switch]$ExcludeTests
    )

    Write-Log -Message "Découverte automatique des gestionnaires..." -Level Info

    $managersFound = 0
    $managersRegistered = 0

    # Parcourir les chemins de recherche
    foreach ($searchPath in $SearchPaths) {
        $fullSearchPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptPath))) -ChildPath $searchPath
        
        if (Test-Path -Path $fullSearchPath) {
            Write-Log -Message "Recherche dans $fullSearchPath..." -Level Debug
            
            # Rechercher les répertoires de gestionnaires
            if ($Recursive) {
                $managerDirs = Get-ChildItem -Path $fullSearchPath -Directory -Recurse | Where-Object { $_.Name -like "*-manager" }
            } else {
                $managerDirs = Get-ChildItem -Path $fullSearchPath -Directory | Where-Object { $_.Name -like "*-manager" }
            }
            
            # Traiter les répertoires de gestionnaires
            foreach ($managerDir in $managerDirs) {
                # Code existant pour traiter chaque répertoire de gestionnaire
            }
            
            # Rechercher les fichiers de gestionnaires si demandé
            if ($SearchFiles) {
                $findParams = @{
                    Path = $fullSearchPath
                    FilePatterns = $FilePatterns
                    ContentPatterns = $ContentPatterns
                    IncludeContent = $true
                }
                
                if ($Recursive) {
                    $findParams.Recurse = $true
                }
                
                if ($ExcludeBackups) {
                    $findParams.ExcludeBackups = $true
                }
                
                if ($ExcludeTests) {
                    $findParams.ExcludeTests = $true
                }
                
                $managerFiles = Find-ManagerFiles @findParams
                
                # Traiter les fichiers de gestionnaires
                foreach ($managerFile in $managerFiles) {
                    $managerName = $managerFile.BaseName -replace "-", "" -replace "manager", "Manager" -replace "^.", { $args[0].ToString().ToUpper() }
                    $managerScriptPath = $managerFile.FullName
                    $manifestPath = Join-Path -Path (Split-Path -Parent $managerScriptPath) -ChildPath "$($managerFile.BaseName).manifest.json"
                    
                    $managersFound++
                    Write-Log -Message "Gestionnaire trouvé : $managerName ($managerScriptPath)" -Level Debug
                    
                    # Préparer les paramètres d'enregistrement
                    $registerParams = @{
                        Name = $managerName
                        Path = $managerScriptPath
                        Force = $Force
                    }
                    
                    # Ajouter les paramètres optionnels
                    if ($SkipDependencyCheck) {
                        $registerParams.SkipDependencyCheck = $true
                    }
                    
                    if ($SkipValidation) {
                        $registerParams.SkipValidation = $true
                    }
                    
                    if ($SkipSecurityCheck) {
                        $registerParams.SkipSecurityCheck = $true
                    }
                    
                    # Extraire la version du manifeste si disponible
                    if ($processManagerModuleAvailable -and (Test-Path -Path $manifestPath)) {
                        try {
                            $manifest = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json
                            if ($manifest.Version) {
                                $registerParams.Version = $manifest.Version
                                Write-Log -Message "Version extraite du manifeste : $($manifest.Version)" -Level Debug
                            }
                        }
                        catch {
                            Write-Log -Message "Erreur lors de l'extraction du manifeste : $_" -Level Warning
                        }
                    }
                    
                    # Enregistrer le gestionnaire
                    if (Register-Manager @registerParams) {
                        $managersRegistered++
                    }
                }
            }
        }
    }

    Write-Log -Message "$managersFound gestionnaires trouvés, $managersRegistered gestionnaires enregistrés." -Level Info
    return $managersRegistered
}
```

## Conclusion

La fonction `Find-ManagerFiles` permet de rechercher des fichiers qui pourraient contenir des gestionnaires, en se basant sur des critères de nommage et de contenu. Cette fonction peut être intégrée au Process Manager pour améliorer sa capacité à découvrir des gestionnaires implémentés directement dans des fichiers, sans être organisés dans des répertoires spécifiques.

Les optimisations proposées permettent d'améliorer les performances de la recherche, notamment en utilisant la parallélisation, la mise en cache et l'analyse statique. Les tests proposés permettent de valider l'implémentation de la fonction et de s'assurer qu'elle fonctionne correctement dans différents scénarios.
