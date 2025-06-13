# Méthodes d'analyse syntaxique disponibles dans PowerShell

## Introduction

Ce document présente les différentes méthodes d'analyse syntaxique disponibles dans PowerShell. Ces méthodes permettent d'analyser les fichiers PowerShell pour en extraire des informations sur les gestionnaires, les fonctions, les paramètres et autres éléments importants.

## Abstract Syntax Tree (AST) dans PowerShell

L'Abstract Syntax Tree (AST) est une structure de données qui représente le code source écrit dans un langage de programmation. Dans PowerShell, l'AST est utilisé pour analyser et manipuler le code PowerShell de manière programmatique.

### Qu'est-ce qu'un AST ?

Un AST est une représentation hiérarchique du code source où chaque nœud représente une construction syntaxique du langage. Par exemple, un nœud peut représenter une fonction, une variable, une expression, etc. L'AST est généralement le résultat de l'analyse syntaxique effectuée par un compilateur ou un interpréteur.

### Avantages de l'AST

L'utilisation de l'AST présente plusieurs avantages :

1. **Analyse statique du code** : L'AST permet d'analyser le code sans l'exécuter, ce qui est utile pour la détection d'erreurs, l'analyse de qualité du code, etc.
2. **Manipulation du code** : L'AST permet de modifier le code de manière programmatique, ce qui est utile pour la refactorisation, la génération de code, etc.
3. **Extraction d'informations** : L'AST permet d'extraire des informations spécifiques du code, comme les fonctions, les variables, les paramètres, etc.
4. **Transformation du code** : L'AST permet de transformer le code d'un format à un autre, comme la conversion de PowerShell en C#, etc.

## Classes AST dans PowerShell

Les classes AST dans PowerShell sont situées dans l'espace de noms `System.Management.Automation.Language`. Les principales classes pour interagir avec l'AST sont :

### Parser

La classe `Parser` fournit des méthodes pour analyser le code PowerShell et générer un AST. Les principales méthodes sont :

1. **ParseInput** : Analyse une chaîne de caractères contenant du code PowerShell et retourne un AST.
   ```powershell
   [System.Management.Automation.Language.Parser]::ParseInput($code, [ref]$tokens, [ref]$errors)
   ```

2. **ParseFile** : Analyse un fichier PowerShell et retourne un AST.
   ```powershell
   [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref]$tokens, [ref]$errors)
   ```

### ScriptBlockAst

La classe `ScriptBlockAst` est la racine de l'AST pour un script PowerShell. Elle contient des propriétés pour accéder aux différentes parties du script, comme les blocs de paramètres, les blocs de début, de processus et de fin, etc.

```powershell
$scriptBlockAst = [System.Management.Automation.Language.Parser]::ParseInput($code, [ref]$tokens, [ref]$errors)
$scriptBlockAst.BeginBlock
$scriptBlockAst.ProcessBlock
$scriptBlockAst.EndBlock
```plaintext
### Ast

La classe `Ast` est la classe de base pour tous les nœuds AST. Elle fournit des méthodes communes pour naviguer dans l'AST, comme `Find`, `FindAll` et `Visit`.

```powershell
# Trouver tous les nœuds AST qui correspondent à un prédicat

$ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
```plaintext
## Accès à l'AST

Il existe deux principales façons d'accéder à l'AST dans PowerShell :

### 1. Via la propriété Ast d'un ScriptBlock

Chaque `ScriptBlock` dans PowerShell a une propriété `Ast` qui donne accès à l'AST du bloc de script.

```powershell
$code = {
    function Get-Example {
        param($Parameter1)
        "Example: $Parameter1"
    }
}

$ast = $code.Ast
```plaintext
### 2. Via les méthodes ParseInput et ParseFile de la classe Parser

La classe `Parser` fournit des méthodes pour analyser le code PowerShell et générer un AST.

```powershell
# Analyser une chaîne de caractères

$code = 'function Get-Example { param($Parameter1) "Example: $Parameter1" }'
$tokens = $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($code, [ref]$tokens, [ref]$errors)

# Analyser un fichier

$filePath = "C:\path\to\script.ps1"
$tokens = $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref]$tokens, [ref]$errors)
```plaintext
## Types de nœuds AST

L'AST de PowerShell contient de nombreux types de nœuds qui représentent différentes constructions syntaxiques du langage. Voici quelques-uns des types de nœuds les plus couramment utilisés :

### FunctionDefinitionAst

Représente une définition de fonction dans PowerShell.

```powershell
$ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
```plaintext
### CommandAst

Représente une commande PowerShell, y compris les appels de fonction, les appels de cmdlet, etc.

```powershell
$ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true)
```plaintext
### ParameterAst

Représente un paramètre dans une définition de fonction ou de script.

```powershell
$ast.FindAll({ $args[0] -is [System.Management.Automation.Language.ParameterAst] }, $true)
```plaintext
### VariableExpressionAst

Représente une référence à une variable dans PowerShell.

```powershell
$ast.FindAll({ $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] }, $true)
```plaintext
### StringConstantExpressionAst

Représente une chaîne de caractères littérale dans PowerShell.

```powershell
$ast.FindAll({ $args[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] }, $true)
```plaintext
### ScriptBlockExpressionAst

Représente un bloc de script dans PowerShell.

```powershell
$ast.FindAll({ $args[0] -is [System.Management.Automation.Language.ScriptBlockExpressionAst] }, $true)
```plaintext
## Méthodes de navigation dans l'AST

L'AST fournit plusieurs méthodes pour naviguer dans l'arbre et trouver des nœuds spécifiques.

### Find

La méthode `Find` permet de trouver le premier nœud dans l'arbre qui correspond à un prédicat donné.

```powershell
$ast.Find({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $args[0].Name -eq 'Get-Example' }, $true)
```plaintext
### FindAll

La méthode `FindAll` permet de trouver tous les nœuds dans l'arbre qui correspondent à un prédicat donné.

```powershell
$ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
```plaintext
### Visit

La méthode `Visit` permet de visiter chaque nœud dans l'arbre et d'exécuter une action sur chaque nœud.

```powershell
$visitor = [PSCustomObject]@{
    VisitFunctionDefinition = {
        param($functionDefinitionAst)
        Write-Host "Found function: $($functionDefinitionAst.Name)"
        return $functionDefinitionAst
    }
}

$ast.Visit($visitor)
```plaintext
## Exemples d'utilisation de l'AST

### Exemple 1 : Trouver toutes les fonctions dans un script

```powershell
function Get-ScriptFunction {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )

    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)
    $functions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)

    foreach ($function in $functions) {
        [PSCustomObject]@{
            Name = $function.Name
            Parameters = $function.Parameters.Name
            Line = $function.Extent.StartLineNumber
            Column = $function.Extent.StartColumnNumber
        }
    }
}
```plaintext
### Exemple 2 : Trouver toutes les variables dans un script

```powershell
function Get-ScriptVariable {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )

    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$errors)
    $variables = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] }, $true)

    foreach ($variable in $variables) {
        [PSCustomObject]@{
            Name = $variable.VariablePath.UserPath
            Line = $variable.Extent.StartLineNumber
            Column = $variable.Extent.StartColumnNumber
        }
    }
}
```plaintext
### Exemple 3 : Trouver toutes les commandes dans un script

```powershell
function Get-ScriptCommand {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )

    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)
    $commands = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true)

    foreach ($command in $commands) {
        [PSCustomObject]@{
            Name = $command.GetCommandName()
            Line = $command.Extent.StartLineNumber
            Column = $command.Extent.StartColumnNumber
        }
    }
}
```plaintext
## Outils et modules basés sur l'AST

### PSScriptAnalyzer

[PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) est un module qui utilise l'AST pour analyser le code PowerShell et détecter les problèmes potentiels. Il fournit un ensemble de règles qui peuvent être configurées pour vérifier différents aspects du code.

```powershell
Install-Module -Name PSScriptAnalyzer
Invoke-ScriptAnalyzer -Path script.ps1
```plaintext
### ShowPSAst

[ShowPSAst](https://github.com/lzybkr/ShowPSAst) est un module qui fournit une interface graphique pour explorer l'AST d'un script PowerShell.

```powershell
Install-Module -Name ShowPSAst
Show-Ast -InputObject "C:\path\to\script.ps1"
```plaintext
### PSParser (obsolète)

Avant PowerShell 3.0, l'analyse syntaxique était effectuée à l'aide de la classe `PSParser`. Cette classe est maintenant obsolète et ne doit plus être utilisée. Elle a été remplacée par les classes AST mentionnées ci-dessus.

```powershell
# Obsolète - Ne pas utiliser

[System.Management.Automation.PSParser]::Tokenize($code, [ref]$null)
```plaintext
## Conclusion

L'AST de PowerShell est un outil puissant pour analyser et manipuler le code PowerShell de manière programmatique. Il permet d'extraire des informations sur les fonctions, les variables, les commandes et d'autres éléments du code sans avoir à l'exécuter. Les classes AST fournissent des méthodes pour naviguer dans l'arbre et trouver des nœuds spécifiques, ce qui facilite l'analyse du code.

Pour notre projet de découverte des gestionnaires, l'AST sera particulièrement utile pour analyser les fichiers PowerShell et extraire des informations sur les fonctions qui pourraient être des gestionnaires. Nous pourrons utiliser les méthodes `FindAll` et `Find` pour rechercher des fonctions spécifiques, et la propriété `Extent` pour obtenir des informations sur la position de ces fonctions dans le code.

## Ressources supplémentaires

- [Documentation officielle de l'AST dans PowerShell](https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.language?view=pscore-6.2.0)
- [Learning about the PowerShell abstract syntax tree ast (series)](https://mikefrobbins.com/2018/09/28/learning-about-the-powershell-abstract-syntax-tree-ast/) par Mike F. Robbins
- [Abstract Syntax Tree - powershell.one](https://powershell.one/powershell-internals/parsing-and-tokenization/abstract-syntax-tree)
- [Introduction to AST in PowerShell](https://renehernandez.io/tutorials/introduction-to-ast-in-powershell/) par Rene Hernandez
