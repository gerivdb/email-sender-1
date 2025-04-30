# Solutions techniques pour la recherche récursive des gestionnaires

## Introduction

Ce document propose des solutions techniques pour permettre la recherche récursive des gestionnaires dans le Process Manager. L'objectif est de permettre au Process Manager de découvrir des gestionnaires organisés dans des sous-répertoires plus profonds que le premier niveau, ce qui n'est pas possible avec le mécanisme de découverte actuel.

## Problématique

Actuellement, le mécanisme de découverte des gestionnaires du Process Manager ne recherche que les répertoires de premier niveau dans les chemins de recherche spécifiés. Cette limitation empêche la découverte de gestionnaires qui pourraient être organisés dans des sous-répertoires plus profonds.

```powershell
$managerDirs = Get-ChildItem -Path $fullSearchPath -Directory | Where-Object { $_.Name -like "*-manager" }
```

## Solutions proposées

### Solution 1 : Ajouter un paramètre de recherche récursive

#### Description

Ajouter un paramètre `Recursive` à la fonction `Discover-Managers` pour permettre la recherche récursive des gestionnaires.

#### Implémentation

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
        [switch]$Recursive
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
            
            foreach ($managerDir in $managerDirs) {
                # Code existant pour traiter chaque répertoire de gestionnaire
            }
        }
    }

    Write-Log -Message "$managersFound gestionnaires trouvés, $managersRegistered gestionnaires enregistrés." -Level Info
    return $managersRegistered
}
```

#### Avantages

- Simple à implémenter
- Compatible avec le code existant
- Permet à l'utilisateur de choisir s'il veut une recherche récursive ou non

#### Inconvénients

- Ne résout pas les autres limitations du mécanisme de découverte
- Peut ralentir la découverte si le nombre de répertoires à parcourir est important

### Solution 2 : Utiliser une fonction de recherche récursive personnalisée

#### Description

Créer une fonction de recherche récursive personnalisée qui permet un contrôle plus fin sur la profondeur de recherche et les critères de filtrage.

#### Implémentation

```powershell
function Find-ManagerDirectories {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = -1,
        
        [Parameter(Mandatory = $false)]
        [string]$Pattern = "*-manager",
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeFiles,
        
        [Parameter(Mandatory = $false)]
        [switch]$ExcludeBackups,
        
        [Parameter(Mandatory = $false)]
        [switch]$ExcludeTests
    )

    $items = @()
    $currentDepth = 0
    
    function Search-Directory {
        param (
            [Parameter(Mandatory = $true)]
            [string]$CurrentPath,
            
            [Parameter(Mandatory = $true)]
            [int]$CurrentDepth
        )
        
        # Vérifier si la profondeur maximale est atteinte
        if ($MaxDepth -ne -1 -and $CurrentDepth -gt $MaxDepth) {
            return
        }
        
        # Rechercher les répertoires correspondant au modèle
        $directories = Get-ChildItem -Path $CurrentPath -Directory | Where-Object {
            $match = $_.Name -like $Pattern
            
            # Exclure les répertoires de sauvegarde si demandé
            if ($ExcludeBackups -and ($_.Name -like "*backup*" -or $_.Name -like "*bak*")) {
                $match = $false
            }
            
            # Exclure les répertoires de test si demandé
            if ($ExcludeTests -and ($_.Name -like "*test*" -or $_.Name -like "*Test*")) {
                $match = $false
            }
            
            return $match
        }
        
        # Ajouter les répertoires trouvés à la liste
        $items += $directories
        
        # Rechercher les fichiers correspondant au modèle si demandé
        if ($IncludeFiles) {
            $files = Get-ChildItem -Path $CurrentPath -File | Where-Object {
                $match = $_.Name -like $Pattern
                
                # Exclure les fichiers de sauvegarde si demandé
                if ($ExcludeBackups -and ($_.Name -like "*backup*" -or $_.Name -like "*bak*")) {
                    $match = $false
                }
                
                # Exclure les fichiers de test si demandé
                if ($ExcludeTests -and ($_.Name -like "*test*" -or $_.Name -like "*Test*")) {
                    $match = $false
                }
                
                return $match
            }
            
            # Ajouter les fichiers trouvés à la liste
            $items += $files
        }
        
        # Rechercher récursivement dans les sous-répertoires
        $subdirectories = Get-ChildItem -Path $CurrentPath -Directory
        foreach ($subdirectory in $subdirectories) {
            Search-Directory -CurrentPath $subdirectory.FullName -CurrentDepth ($CurrentDepth + 1)
        }
    }
    
    # Démarrer la recherche
    Search-Directory -CurrentPath $Path -CurrentDepth $currentDepth
    
    return $items
}

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
        [int]$MaxDepth = -1,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeFiles,
        
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
                $findParams = @{
                    Path = $fullSearchPath
                    Pattern = "*-manager"
                }
                
                if ($MaxDepth -ne -1) {
                    $findParams.MaxDepth = $MaxDepth
                }
                
                if ($IncludeFiles) {
                    $findParams.IncludeFiles = $true
                }
                
                if ($ExcludeBackups) {
                    $findParams.ExcludeBackups = $true
                }
                
                if ($ExcludeTests) {
                    $findParams.ExcludeTests = $true
                }
                
                $managerDirs = Find-ManagerDirectories @findParams
            } else {
                $managerDirs = Get-ChildItem -Path $fullSearchPath -Directory | Where-Object { $_.Name -like "*-manager" }
            }
            
            foreach ($managerDir in $managerDirs) {
                # Code existant pour traiter chaque répertoire de gestionnaire
            }
        }
    }

    Write-Log -Message "$managersFound gestionnaires trouvés, $managersRegistered gestionnaires enregistrés." -Level Info
    return $managersRegistered
}
```

#### Avantages

- Permet un contrôle plus fin sur la recherche récursive
- Permet de limiter la profondeur de recherche
- Permet d'inclure les fichiers dans la recherche
- Permet d'exclure les répertoires et fichiers de sauvegarde et de test

#### Inconvénients

- Plus complexe à implémenter
- Peut être plus lent que la solution 1 pour des recherches simples

### Solution 3 : Utiliser un module de recherche existant

#### Description

Utiliser un module de recherche existant, comme le module `PathManager`, pour rechercher les gestionnaires.

#### Implémentation

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
        [switch]$Recursive
    )

    Write-Log -Message "Découverte automatique des gestionnaires..." -Level Info

    $managersFound = 0
    $managersRegistered = 0

    # Vérifier si le module PathManager est disponible
    $pathManagerAvailable = $false
    try {
        if (Get-Module -Name PathManager -ListAvailable) {
            Import-Module -Name PathManager -ErrorAction Stop
            $pathManagerAvailable = $true
        }
    } catch {
        Write-Log -Message "Le module PathManager n'est pas disponible. Utilisation de la méthode de recherche standard." -Level Warning
    }

    # Parcourir les chemins de recherche
    foreach ($searchPath in $SearchPaths) {
        $fullSearchPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptPath))) -ChildPath $searchPath
        
        if (Test-Path -Path $fullSearchPath) {
            Write-Log -Message "Recherche dans $fullSearchPath..." -Level Debug
            
            # Rechercher les répertoires de gestionnaires
            if ($Recursive -and $pathManagerAvailable) {
                try {
                    $managerDirs = Find-PathItems -Path $fullSearchPath -Pattern "*-manager" -ItemType Directory -Recurse
                } catch {
                    Write-Log -Message "Erreur lors de l'utilisation du module PathManager : $_. Utilisation de la méthode de recherche standard." -Level Warning
                    if ($Recursive) {
                        $managerDirs = Get-ChildItem -Path $fullSearchPath -Directory -Recurse | Where-Object { $_.Name -like "*-manager" }
                    } else {
                        $managerDirs = Get-ChildItem -Path $fullSearchPath -Directory | Where-Object { $_.Name -like "*-manager" }
                    }
                }
            } else {
                if ($Recursive) {
                    $managerDirs = Get-ChildItem -Path $fullSearchPath -Directory -Recurse | Where-Object { $_.Name -like "*-manager" }
                } else {
                    $managerDirs = Get-ChildItem -Path $fullSearchPath -Directory | Where-Object { $_.Name -like "*-manager" }
                }
            }
            
            foreach ($managerDir in $managerDirs) {
                # Code existant pour traiter chaque répertoire de gestionnaire
            }
        }
    }

    Write-Log -Message "$managersFound gestionnaires trouvés, $managersRegistered gestionnaires enregistrés." -Level Info
    return $managersRegistered
}
```

#### Avantages

- Réutilise un module existant
- Peut bénéficier des optimisations et des fonctionnalités du module
- Maintient la cohérence avec le reste du système

#### Inconvénients

- Dépend de la disponibilité du module
- Peut nécessiter des adaptations si le module change

### Solution 4 : Utiliser une approche hybride

#### Description

Combiner les différentes approches pour créer une solution hybride qui s'adapte aux différentes situations.

#### Implémentation

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
        [int]$MaxDepth = -1,
        
        [Parameter(Mandatory = $false)]
        [switch]$UsePathManager,
        
        [Parameter(Mandatory = $false)]
        [switch]$UseCustomSearch
    )

    Write-Log -Message "Découverte automatique des gestionnaires..." -Level Info

    $managersFound = 0
    $managersRegistered = 0

    # Vérifier si le module PathManager est disponible
    $pathManagerAvailable = $false
    if ($UsePathManager) {
        try {
            if (Get-Module -Name PathManager -ListAvailable) {
                Import-Module -Name PathManager -ErrorAction Stop
                $pathManagerAvailable = $true
            }
        } catch {
            Write-Log -Message "Le module PathManager n'est pas disponible. Utilisation de la méthode de recherche standard." -Level Warning
        }
    }

    # Parcourir les chemins de recherche
    foreach ($searchPath in $SearchPaths) {
        $fullSearchPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptPath))) -ChildPath $searchPath
        
        if (Test-Path -Path $fullSearchPath) {
            Write-Log -Message "Recherche dans $fullSearchPath..." -Level Debug
            
            # Rechercher les répertoires de gestionnaires
            if ($Recursive) {
                if ($UseCustomSearch) {
                    # Utiliser la recherche personnalisée
                    $managerDirs = Find-ManagerDirectories -Path $fullSearchPath -Pattern "*-manager" -MaxDepth $MaxDepth
                } elseif ($pathManagerAvailable) {
                    # Utiliser le module PathManager
                    try {
                        $managerDirs = Find-PathItems -Path $fullSearchPath -Pattern "*-manager" -ItemType Directory -Recurse
                    } catch {
                        Write-Log -Message "Erreur lors de l'utilisation du module PathManager : $_. Utilisation de la méthode de recherche standard." -Level Warning
                        $managerDirs = Get-ChildItem -Path $fullSearchPath -Directory -Recurse | Where-Object { $_.Name -like "*-manager" }
                    }
                } else {
                    # Utiliser la méthode standard
                    $managerDirs = Get-ChildItem -Path $fullSearchPath -Directory -Recurse | Where-Object { $_.Name -like "*-manager" }
                }
            } else {
                # Utiliser la méthode standard non récursive
                $managerDirs = Get-ChildItem -Path $fullSearchPath -Directory | Where-Object { $_.Name -like "*-manager" }
            }
            
            foreach ($managerDir in $managerDirs) {
                # Code existant pour traiter chaque répertoire de gestionnaire
            }
        }
    }

    Write-Log -Message "$managersFound gestionnaires trouvés, $managersRegistered gestionnaires enregistrés." -Level Info
    return $managersRegistered
}
```

#### Avantages

- Combine les avantages des différentes approches
- S'adapte aux différentes situations
- Offre plus de flexibilité à l'utilisateur

#### Inconvénients

- Plus complexe à implémenter et à maintenir
- Peut être difficile à comprendre pour les nouveaux développeurs

## Recommandation

Nous recommandons d'implémenter la **Solution 1** dans un premier temps, car elle est simple à mettre en œuvre et répond au besoin principal de recherche récursive. Si des besoins plus avancés se manifestent, nous pourrons envisager d'implémenter les autres solutions.

## Tests

Pour valider l'implémentation de la solution choisie, nous recommandons de créer les tests suivants :

### Test 1 : Recherche non récursive

```powershell
# Créer une structure de test
$testDir = Join-Path -Path $env:TEMP -ChildPath "ProcessManagerTest"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null
$managerDir = Join-Path -Path $testDir -ChildPath "test-manager"
New-Item -Path $managerDir -ItemType Directory -Force | Out-Null
$scriptsDir = Join-Path -Path $managerDir -ChildPath "scripts"
New-Item -Path $scriptsDir -ItemType Directory -Force | Out-Null
$scriptPath = Join-Path -Path $scriptsDir -ChildPath "test-manager.ps1"
@"
function Start-TestManager {
    [CmdletBinding()]
    param()
    
    Write-Host "Démarrage du gestionnaire de test..."
}
"@ | Set-Content -Path $scriptPath -Encoding UTF8

# Exécuter la fonction Discover-Managers sans l'option Recursive
$result = & $processManagerPath -Command Discover -SearchPaths $testDir

# Vérifier que le gestionnaire a été découvert
$registeredManager = & $processManagerPath -Command List | Where-Object { $_ -like "*TestManager*" }

# Nettoyer
Remove-Item -Path $testDir -Recurse -Force

# Le test est réussi si le gestionnaire a été découvert
return $registeredManager -ne $null
```

### Test 2 : Recherche récursive

```powershell
# Créer une structure de test
$testDir = Join-Path -Path $env:TEMP -ChildPath "ProcessManagerTest"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null
$subDir = Join-Path -Path $testDir -ChildPath "subdir"
New-Item -Path $subDir -ItemType Directory -Force | Out-Null
$managerDir = Join-Path -Path $subDir -ChildPath "test-manager"
New-Item -Path $managerDir -ItemType Directory -Force | Out-Null
$scriptsDir = Join-Path -Path $managerDir -ChildPath "scripts"
New-Item -Path $scriptsDir -ItemType Directory -Force | Out-Null
$scriptPath = Join-Path -Path $scriptsDir -ChildPath "test-manager.ps1"
@"
function Start-TestManager {
    [CmdletBinding()]
    param()
    
    Write-Host "Démarrage du gestionnaire de test..."
}
"@ | Set-Content -Path $scriptPath -Encoding UTF8

# Exécuter la fonction Discover-Managers avec l'option Recursive
$result = & $processManagerPath -Command Discover -SearchPaths $testDir -Recursive

# Vérifier que le gestionnaire a été découvert
$registeredManager = & $processManagerPath -Command List | Where-Object { $_ -like "*TestManager*" }

# Nettoyer
Remove-Item -Path $testDir -Recurse -Force

# Le test est réussi si le gestionnaire a été découvert
return $registeredManager -ne $null
```

### Test 3 : Recherche récursive avec profondeur limitée

```powershell
# Créer une structure de test
$testDir = Join-Path -Path $env:TEMP -ChildPath "ProcessManagerTest"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null
$subDir1 = Join-Path -Path $testDir -ChildPath "subdir1"
New-Item -Path $subDir1 -ItemType Directory -Force | Out-Null
$managerDir1 = Join-Path -Path $subDir1 -ChildPath "test-manager1"
New-Item -Path $managerDir1 -ItemType Directory -Force | Out-Null
$scriptsDir1 = Join-Path -Path $managerDir1 -ChildPath "scripts"
New-Item -Path $scriptsDir1 -ItemType Directory -Force | Out-Null
$scriptPath1 = Join-Path -Path $scriptsDir1 -ChildPath "test-manager1.ps1"
@"
function Start-TestManager1 {
    [CmdletBinding()]
    param()
    
    Write-Host "Démarrage du gestionnaire de test 1..."
}
"@ | Set-Content -Path $scriptPath1 -Encoding UTF8

$subDir2 = Join-Path -Path $subDir1 -ChildPath "subdir2"
New-Item -Path $subDir2 -ItemType Directory -Force | Out-Null
$managerDir2 = Join-Path -Path $subDir2 -ChildPath "test-manager2"
New-Item -Path $managerDir2 -ItemType Directory -Force | Out-Null
$scriptsDir2 = Join-Path -Path $managerDir2 -ChildPath "scripts"
New-Item -Path $scriptsDir2 -ItemType Directory -Force | Out-Null
$scriptPath2 = Join-Path -Path $scriptsDir2 -ChildPath "test-manager2.ps1"
@"
function Start-TestManager2 {
    [CmdletBinding()]
    param()
    
    Write-Host "Démarrage du gestionnaire de test 2..."
}
"@ | Set-Content -Path $scriptPath2 -Encoding UTF8

# Exécuter la fonction Discover-Managers avec l'option Recursive et MaxDepth=1
$result = & $processManagerPath -Command Discover -SearchPaths $testDir -Recursive -MaxDepth 1

# Vérifier que seul le premier gestionnaire a été découvert
$registeredManager1 = & $processManagerPath -Command List | Where-Object { $_ -like "*TestManager1*" }
$registeredManager2 = & $processManagerPath -Command List | Where-Object { $_ -like "*TestManager2*" }

# Nettoyer
Remove-Item -Path $testDir -Recurse -Force

# Le test est réussi si le premier gestionnaire a été découvert et le second non
return $registeredManager1 -ne $null -and $registeredManager2 -eq $null
```

## Conclusion

La recherche récursive des gestionnaires est une fonctionnalité importante pour améliorer la flexibilité et la robustesse du Process Manager. Les solutions proposées dans ce document permettent d'implémenter cette fonctionnalité de différentes manières, en fonction des besoins et des contraintes du système.

Nous recommandons d'implémenter la Solution 1 dans un premier temps, car elle est simple à mettre en œuvre et répond au besoin principal de recherche récursive. Si des besoins plus avancés se manifestent, nous pourrons envisager d'implémenter les autres solutions.
