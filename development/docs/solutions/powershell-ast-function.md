# Implémentation d'une fonction utilisant l'AST de PowerShell

## Introduction

Ce document présente l'implémentation d'une fonction qui utilise l'Abstract Syntax Tree (AST) de PowerShell pour analyser les fichiers PowerShell et extraire des informations sur les gestionnaires. Cette fonction sera utilisée dans le Process Manager pour améliorer la découverte des gestionnaires.

## Fonction d'analyse AST pour les gestionnaires

La fonction `Get-ManagerAst` permet d'analyser un fichier PowerShell et d'extraire des informations sur les fonctions qui pourraient être des gestionnaires. Elle utilise l'AST de PowerShell pour analyser le code sans l'exécuter.

```powershell
function Get-ManagerAst {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('FullName')]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string[]]$FunctionPatterns = @('*-*Manager*', 'Start-*', 'Stop-*', 'Get-*Status'),

        [Parameter(Mandatory = $false)]
        [switch]$IncludeContent,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeParameters,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeComments
    )

    process {
        try {
            # Vérifier si le fichier existe
            if (-not (Test-Path -Path $Path -PathType Leaf)) {
                Write-Error "Le fichier '$Path' n'existe pas ou n'est pas un fichier."
                return
            }

            # Analyser le fichier PowerShell
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$errors)

            # Vérifier s'il y a des erreurs d'analyse
            if ($errors -and $errors.Count -gt 0) {
                Write-Warning "Des erreurs d'analyse ont été détectées dans le fichier '$Path':"
                foreach ($error in $errors) {
                    Write-Warning "  $($error.Extent.StartLineNumber):$($error.Extent.StartColumnNumber) - $($error.Message)"
                }
            }

            # Rechercher les fonctions qui correspondent aux modèles
            $functions = $ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                $(foreach ($pattern in $FunctionPatterns) {
                    if ($node.Name -like $pattern) {
                        return $true
                    }
                }
                return $false)
            }, $true)

            # Extraire les informations sur les fonctions
            foreach ($function in $functions) {
                $result = [PSCustomObject]@{
                    Name = $function.Name
                    Path = $Path
                    Line = $function.Extent.StartLineNumber
                    Column = $function.Extent.StartColumnNumber
                    Parameters = $null
                    Content = $null
                    Comments = $null
                    IsManager = $function.Name -like '*Manager*'
                    HasStartFunction = $function.Name -like 'Start-*'
                    HasStopFunction = $function.Name -like 'Stop-*'
                    HasStatusFunction = $function.Name -like 'Get-*Status'
                }

                # Extraire les paramètres si demandé
                if ($IncludeParameters) {
                    $result.Parameters = $function.Parameters | ForEach-Object {
                        [PSCustomObject]@{
                            Name = $_.Name.VariablePath.UserPath
                            Type = if ($_.StaticType) { $_.StaticType.FullName } else { 'System.Object' }
                            DefaultValue = if ($_.DefaultValue) { $_.DefaultValue.Extent.Text } else { $null }
                            Mandatory = $_.Attributes | Where-Object { $_.TypeName.Name -eq 'Parameter' } | ForEach-Object {
                                $_.NamedArguments | Where-Object { $_.ArgumentName -eq 'Mandatory' } | ForEach-Object {
                                    $_.Argument.Value
                                }
                            }
                        }
                    }
                }

                # Extraire le contenu si demandé
                if ($IncludeContent) {
                    $result.Content = $function.Extent.Text
                }

                # Extraire les commentaires si demandé
                if ($IncludeComments) {
                    $tokens = $null
                    $null = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$null)
                    $comments = $tokens | Where-Object { $_.Kind -eq 'Comment' }
                    $functionComments = $comments | Where-Object {
                        $_.Extent.StartLineNumber -lt $function.Extent.StartLineNumber -and
                        $_.Extent.StartLineNumber -ge ($function.Extent.StartLineNumber - 10)
                    }
                    $result.Comments = $functionComments | ForEach-Object { $_.Text }
                }

                # Retourner le résultat
                $result
            }
        }
        catch {
            Write-Error "Une erreur s'est produite lors de l'analyse du fichier '$Path': $_"
        }
    }
}
```

## Paramètres de la fonction

- **Path** : Chemin du fichier PowerShell à analyser. Ce paramètre est obligatoire et accepte les entrées de pipeline.
- **FunctionPatterns** : Modèles de noms de fonctions à rechercher. Par défaut, la fonction recherche les fonctions dont le nom contient "Manager" ou commence par "Start-", "Stop-" ou "Get-" et se termine par "Status".
- **IncludeContent** : Indique si le contenu des fonctions doit être inclus dans les résultats.
- **IncludeParameters** : Indique si les paramètres des fonctions doivent être inclus dans les résultats.
- **IncludeComments** : Indique si les commentaires associés aux fonctions doivent être inclus dans les résultats.

## Exemples d'utilisation

### Exemple 1 : Rechercher les fonctions de gestionnaire dans un fichier

```powershell
Get-ManagerAst -Path "C:\path\to\script.ps1"
```

### Exemple 2 : Rechercher les fonctions de gestionnaire dans plusieurs fichiers

```powershell
Get-ChildItem -Path "C:\path\to\scripts" -Filter "*.ps1" | Get-ManagerAst
```

### Exemple 3 : Rechercher les fonctions de gestionnaire avec des modèles personnalisés

```powershell
Get-ManagerAst -Path "C:\path\to\script.ps1" -FunctionPatterns "*Controller*", "*Service*"
```

### Exemple 4 : Rechercher les fonctions de gestionnaire et inclure leur contenu

```powershell
Get-ManagerAst -Path "C:\path\to\script.ps1" -IncludeContent
```

### Exemple 5 : Rechercher les fonctions de gestionnaire et inclure leurs paramètres

```powershell
Get-ManagerAst -Path "C:\path\to\script.ps1" -IncludeParameters
```

### Exemple 6 : Rechercher les fonctions de gestionnaire et inclure leurs commentaires

```powershell
Get-ManagerAst -Path "C:\path\to\script.ps1" -IncludeComments
```

## Fonction avancée pour l'extraction d'informations sur les gestionnaires

La fonction `Get-ManagerInfo` est une version plus avancée de `Get-ManagerAst` qui extrait des informations plus détaillées sur les gestionnaires. Elle utilise l'AST pour analyser le code et extraire des informations sur les fonctions, les variables, les commentaires et les dépendances.

```powershell
function Get-ManagerInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('FullName')]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string[]]$FunctionPatterns = @('*-*Manager*', 'Start-*', 'Stop-*', 'Get-*Status'),

        [Parameter(Mandatory = $false)]
        [switch]$IncludeContent,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeParameters,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeComments,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDependencies,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeVariables
    )

    process {
        try {
            # Vérifier si le fichier existe
            if (-not (Test-Path -Path $Path -PathType Leaf)) {
                Write-Error "Le fichier '$Path' n'existe pas ou n'est pas un fichier."
                return
            }

            # Analyser le fichier PowerShell
            $errors = $null
            $tokens = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)

            # Vérifier s'il y a des erreurs d'analyse
            if ($errors -and $errors.Count -gt 0) {
                Write-Warning "Des erreurs d'analyse ont été détectées dans le fichier '$Path':"
                foreach ($error in $errors) {
                    Write-Warning "  $($error.Extent.StartLineNumber):$($error.Extent.StartColumnNumber) - $($error.Message)"
                }
            }

            # Rechercher les fonctions qui correspondent aux modèles
            $functions = $ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                $(foreach ($pattern in $FunctionPatterns) {
                    if ($node.Name -like $pattern) {
                        return $true
                    }
                }
                return $false)
            }, $true)

            # Extraire les informations sur les fonctions
            foreach ($function in $functions) {
                $result = [PSCustomObject]@{
                    Name = $function.Name
                    Path = $Path
                    Line = $function.Extent.StartLineNumber
                    Column = $function.Extent.StartColumnNumber
                    Parameters = $null
                    Content = $null
                    Comments = $null
                    Dependencies = $null
                    Variables = $null
                    IsManager = $function.Name -like '*Manager*'
                    HasStartFunction = $function.Name -like 'Start-*'
                    HasStopFunction = $function.Name -like 'Stop-*'
                    HasStatusFunction = $function.Name -like 'Get-*Status'
                    HasShouldProcess = $function.Parameters | Where-Object { $_.Name.VariablePath.UserPath -eq 'WhatIf' -or $_.Name.VariablePath.UserPath -eq 'Confirm' } | Select-Object -First 1 | ForEach-Object { $true } | Select-Object -First 1
                }

                # Extraire les paramètres si demandé
                if ($IncludeParameters) {
                    $result.Parameters = $function.Parameters | ForEach-Object {
                        [PSCustomObject]@{
                            Name = $_.Name.VariablePath.UserPath
                            Type = if ($_.StaticType) { $_.StaticType.FullName } else { 'System.Object' }
                            DefaultValue = if ($_.DefaultValue) { $_.DefaultValue.Extent.Text } else { $null }
                            Mandatory = $_.Attributes | Where-Object { $_.TypeName.Name -eq 'Parameter' } | ForEach-Object {
                                $_.NamedArguments | Where-Object { $_.ArgumentName -eq 'Mandatory' } | ForEach-Object {
                                    $_.Argument.Value
                                }
                            }
                        }
                    }
                }

                # Extraire le contenu si demandé
                if ($IncludeContent) {
                    $result.Content = $function.Extent.Text
                }

                # Extraire les commentaires si demandé
                if ($IncludeComments) {
                    $comments = $tokens | Where-Object { $_.Kind -eq 'Comment' }
                    $functionComments = $comments | Where-Object {
                        $_.Extent.StartLineNumber -lt $function.Extent.StartLineNumber -and
                        $_.Extent.StartLineNumber -ge ($function.Extent.StartLineNumber - 10)
                    }
                    $result.Comments = $functionComments | ForEach-Object { $_.Text }
                }

                # Extraire les dépendances si demandé
                if ($IncludeDependencies) {
                    $commandAsts = $function.FindAll({
                        param($node)
                        $node -is [System.Management.Automation.Language.CommandAst]
                    }, $true)

                    $result.Dependencies = $commandAsts | ForEach-Object {
                        $commandName = $_.CommandElements[0].Value
                        if ($commandName -ne $function.Name) {
                            [PSCustomObject]@{
                                Name = $commandName
                                Line = $_.Extent.StartLineNumber
                                Column = $_.Extent.StartColumnNumber
                            }
                        }
                    } | Sort-Object -Property Name -Unique
                }

                # Extraire les variables si demandé
                if ($IncludeVariables) {
                    $variableAsts = $function.FindAll({
                        param($node)
                        $node -is [System.Management.Automation.Language.VariableExpressionAst]
                    }, $true)

                    $result.Variables = $variableAsts | ForEach-Object {
                        [PSCustomObject]@{
                            Name = $_.VariablePath.UserPath
                            Line = $_.Extent.StartLineNumber
                            Column = $_.Extent.StartColumnNumber
                        }
                    } | Sort-Object -Property Name -Unique
                }

                # Retourner le résultat
                $result
            }
        }
        catch {
            Write-Error "Une erreur s'est produite lors de l'analyse du fichier '$Path': $_"
        }
    }
}
```

## Paramètres supplémentaires de la fonction avancée

- **IncludeDependencies** : Indique si les dépendances des fonctions (commandes appelées) doivent être incluses dans les résultats.
- **IncludeVariables** : Indique si les variables utilisées dans les fonctions doivent être incluses dans les résultats.

## Exemples d'utilisation de la fonction avancée

### Exemple 1 : Rechercher les fonctions de gestionnaire et inclure leurs dépendances

```powershell
Get-ManagerInfo -Path "C:\path\to\script.ps1" -IncludeDependencies
```

### Exemple 2 : Rechercher les fonctions de gestionnaire et inclure leurs variables

```powershell
Get-ManagerInfo -Path "C:\path\to\script.ps1" -IncludeVariables
```

### Exemple 3 : Rechercher les fonctions de gestionnaire et inclure toutes les informations

```powershell
Get-ManagerInfo -Path "C:\path\to\script.ps1" -IncludeContent -IncludeParameters -IncludeComments -IncludeDependencies -IncludeVariables
```

## Fonction pour extraire les manifestes des gestionnaires

La fonction `Get-ManagerManifest` permet d'extraire les manifestes des gestionnaires à partir des commentaires de fonction ou des fichiers de manifeste associés.

```powershell
function Get-ManagerManifest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('FullName')]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$ManifestPath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeContent
    )

    process {
        try {
            # Vérifier si le fichier existe
            if (-not (Test-Path -Path $Path -PathType Leaf)) {
                Write-Error "Le fichier '$Path' n'existe pas ou n'est pas un fichier."
                return
            }

            # Analyser le fichier PowerShell
            $errors = $null
            $tokens = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)

            # Vérifier s'il y a des erreurs d'analyse
            if ($errors -and $errors.Count -gt 0) {
                Write-Warning "Des erreurs d'analyse ont été détectées dans le fichier '$Path':"
                foreach ($error in $errors) {
                    Write-Warning "  $($error.Extent.StartLineNumber):$($error.Extent.StartColumnNumber) - $($error.Message)"
                }
            }

            # Extraire les commentaires de type manifeste
            $comments = $tokens | Where-Object { $_.Kind -eq 'Comment' }
            $manifestComments = $comments | Where-Object { $_.Text -match '\.MANIFEST' }

            $manifest = $null

            # Si des commentaires de type manifeste sont trouvés, les analyser
            if ($manifestComments) {
                $manifestText = ($manifestComments | ForEach-Object { $_.Text -replace '^\s*#\s*\.MANIFEST\s*', '' }) -join "`n"
                try {
                    $manifest = $manifestText | ConvertFrom-Json
                }
                catch {
                    Write-Warning "Impossible d'analyser le manifeste dans les commentaires du fichier '$Path': $_"
                }
            }

            # Si un chemin de manifeste est spécifié, essayer de le charger
            if (-not $manifest -and $ManifestPath) {
                if (Test-Path -Path $ManifestPath -PathType Leaf) {
                    try {
                        $manifest = Get-Content -Path $ManifestPath -Raw | ConvertFrom-Json
                    }
                    catch {
                        Write-Warning "Impossible d'analyser le manifeste dans le fichier '$ManifestPath': $_"
                    }
                }
                else {
                    Write-Warning "Le fichier de manifeste '$ManifestPath' n'existe pas ou n'est pas un fichier."
                }
            }

            # Si aucun manifeste n'est trouvé, essayer de trouver un fichier de manifeste associé
            if (-not $manifest) {
                $manifestPath = [System.IO.Path]::ChangeExtension($Path, "manifest.json")
                if (Test-Path -Path $manifestPath -PathType Leaf) {
                    try {
                        $manifest = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json
                    }
                    catch {
                        Write-Warning "Impossible d'analyser le manifeste dans le fichier '$manifestPath': $_"
                    }
                }
            }

            # Si un manifeste est trouvé, le retourner
            if ($manifest) {
                $result = [PSCustomObject]@{
                    Path = $Path
                    ManifestPath = if ($ManifestPath -and (Test-Path -Path $ManifestPath -PathType Leaf)) { $ManifestPath } elseif (Test-Path -Path $manifestPath -PathType Leaf) { $manifestPath } else { $null }
                    Name = $manifest.Name
                    Description = $manifest.Description
                    Version = $manifest.Version
                    Author = $manifest.Author
                    Dependencies = $manifest.Dependencies
                    Capabilities = $manifest.Capabilities
                    EntryPoint = $manifest.EntryPoint
                    StopFunction = $manifest.StopFunction
                    Content = if ($IncludeContent) { $manifest } else { $null }
                }

                return $result
            }
            else {
                Write-Warning "Aucun manifeste trouvé pour le fichier '$Path'."
            }
        }
        catch {
            Write-Error "Une erreur s'est produite lors de l'analyse du fichier '$Path': $_"
        }
    }
}
```

## Paramètres de la fonction d'extraction de manifeste

- **Path** : Chemin du fichier PowerShell à analyser. Ce paramètre est obligatoire et accepte les entrées de pipeline.
- **ManifestPath** : Chemin du fichier de manifeste à charger. Si ce paramètre n'est pas spécifié, la fonction essaiera de trouver un fichier de manifeste associé.
- **IncludeContent** : Indique si le contenu complet du manifeste doit être inclus dans les résultats.

## Exemples d'utilisation de la fonction d'extraction de manifeste

### Exemple 1 : Extraire le manifeste d'un gestionnaire

```powershell
Get-ManagerManifest -Path "C:\path\to\script.ps1"
```

### Exemple 2 : Extraire le manifeste d'un gestionnaire à partir d'un fichier de manifeste spécifique

```powershell
Get-ManagerManifest -Path "C:\path\to\script.ps1" -ManifestPath "C:\path\to\script.manifest.json"
```

### Exemple 3 : Extraire le manifeste d'un gestionnaire et inclure son contenu complet

```powershell
Get-ManagerManifest -Path "C:\path\to\script.ps1" -IncludeContent
```

## Tests

Pour valider l'implémentation des fonctions, nous recommandons de créer les tests suivants :

### Test 1 : Rechercher les fonctions de gestionnaire dans un fichier

```powershell
# Créer un fichier de test
$testFile = Join-Path -Path $env:TEMP -ChildPath "TestManager.ps1"
@"
function Start-TestManager {
    [CmdletBinding(SupportsShouldProcess = `$true)]
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$Name
    )

    if (`$PSCmdlet.ShouldProcess("TestManager", "Start")) {
        Write-Host "Starting TestManager with name: `$Name"
    }
}

function Stop-TestManager {
    [CmdletBinding()]
    param()

    Write-Host "Stopping TestManager"
}

function Get-TestManagerStatus {
    [CmdletBinding()]
    param()

    return @{
        Status = "Running"
        StartTime = Get-Date
    }
}
"@ | Set-Content -Path $testFile

# Tester la fonction Get-ManagerAst
$result = Get-ManagerAst -Path $testFile
$result | Should -Not -BeNullOrEmpty
$result.Count | Should -Be 3
$result[0].Name | Should -Be "Start-TestManager"
$result[1].Name | Should -Be "Stop-TestManager"
$result[2].Name | Should -Be "Get-TestManagerStatus"

# Nettoyer
Remove-Item -Path $testFile -Force
```

### Test 2 : Rechercher les fonctions de gestionnaire avec des paramètres

```powershell
# Créer un fichier de test
$testFile = Join-Path -Path $env:TEMP -ChildPath "TestManager.ps1"
@"
function Start-TestManager {
    [CmdletBinding(SupportsShouldProcess = `$true)]
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$Name,

        [Parameter(Mandatory = `$false)]
        [int]`$Timeout = 30
    )

    if (`$PSCmdlet.ShouldProcess("TestManager", "Start")) {
        Write-Host "Starting TestManager with name: `$Name and timeout: `$Timeout"
    }
}
"@ | Set-Content -Path $testFile

# Tester la fonction Get-ManagerAst avec IncludeParameters
$result = Get-ManagerAst -Path $testFile -IncludeParameters
$result | Should -Not -BeNullOrEmpty
$result.Parameters | Should -Not -BeNullOrEmpty
$result.Parameters.Count | Should -Be 2
$result.Parameters[0].Name | Should -Be "Name"
$result.Parameters[0].Mandatory | Should -Be $true
$result.Parameters[1].Name | Should -Be "Timeout"
$result.Parameters[1].DefaultValue | Should -Be "30"

# Nettoyer
Remove-Item -Path $testFile -Force
```

### Test 3 : Rechercher les fonctions de gestionnaire avec des commentaires

```powershell
# Créer un fichier de test
$testFile = Join-Path -Path $env:TEMP -ChildPath "TestManager.ps1"
@"
# This is a test manager
# It manages tests

<#
.SYNOPSIS
    Starts the test manager.
.DESCRIPTION
    This function starts the test manager with the specified name.
.PARAMETER Name
    The name of the test manager.
.EXAMPLE
    Start-TestManager -Name "Test"
#>
function Start-TestManager {
    [CmdletBinding(SupportsShouldProcess = `$true)]
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$Name
    )

    if (`$PSCmdlet.ShouldProcess("TestManager", "Start")) {
        Write-Host "Starting TestManager with name: `$Name"
    }
}
"@ | Set-Content -Path $testFile

# Tester la fonction Get-ManagerAst avec IncludeComments
$result = Get-ManagerAst -Path $testFile -IncludeComments
$result | Should -Not -BeNullOrEmpty
$result.Comments | Should -Not -BeNullOrEmpty
$result.Comments.Count | Should -BeGreaterThan 0
$result.Comments[0] | Should -Match "This is a test manager"

# Nettoyer
Remove-Item -Path $testFile -Force
```

### Test 4 : Extraire le manifeste d'un gestionnaire

```powershell
# Créer un fichier de test
$testFile = Join-Path -Path $env:TEMP -ChildPath "TestManager.ps1"
@"
<#
.SYNOPSIS
    Test manager.
.DESCRIPTION
    This is a test manager.
.MANIFEST
{
    "Name": "TestManager",
    "Description": "Test manager",
    "Version": "1.0.0",
    "Author": "Test Author",
    "Dependencies": [
        {
            "Name": "OtherManager",
            "MinimumVersion": "1.0.0",
            "Required": true
        }
    ],
    "Capabilities": [
        "Startable",
        "Stoppable",
        "StatusReporting"
    ],
    "EntryPoint": "Start-TestManager",
    "StopFunction": "Stop-TestManager"
}
#>
function Start-TestManager {
    [CmdletBinding(SupportsShouldProcess = `$true)]
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$Name
    )

    if (`$PSCmdlet.ShouldProcess("TestManager", "Start")) {
        Write-Host "Starting TestManager with name: `$Name"
    }
}
"@ | Set-Content -Path $testFile

# Tester la fonction Get-ManagerManifest
$result = Get-ManagerManifest -Path $testFile
$result | Should -Not -BeNullOrEmpty
$result.Name | Should -Be "TestManager"
$result.Version | Should -Be "1.0.0"
$result.Dependencies | Should -Not -BeNullOrEmpty
$result.Dependencies.Count | Should -Be 1
$result.Dependencies[0].Name | Should -Be "OtherManager"

# Nettoyer
Remove-Item -Path $testFile -Force
```

## Conclusion

Les fonctions présentées dans ce document permettent d'analyser les fichiers PowerShell et d'extraire des informations sur les gestionnaires en utilisant l'AST de PowerShell. Ces fonctions peuvent être intégrées au Process Manager pour améliorer la découverte des gestionnaires.

La fonction `Get-ManagerAst` permet de rechercher les fonctions qui pourraient être des gestionnaires en se basant sur des modèles de noms. La fonction `Get-ManagerInfo` est une version plus avancée qui extrait des informations plus détaillées sur les gestionnaires, y compris leurs dépendances et les variables qu'ils utilisent. La fonction `Get-ManagerManifest` permet d'extraire les manifestes des gestionnaires à partir des commentaires de fonction ou des fichiers de manifeste associés.

Ces fonctions peuvent être utilisées ensemble pour créer un système de découverte de gestionnaires plus robuste et flexible, capable de s'adapter à différentes conventions de nommage et structures de dossiers.
