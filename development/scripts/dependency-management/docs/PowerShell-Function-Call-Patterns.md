# Analyse des patterns d'appels de fonctions dans PowerShell

## Introduction

Ce document analyse les différentes syntaxes d'appels de fonctions dans PowerShell et définit les règles de détection des appels de fonctions externes pour le module de détection des dépendances.

## Syntaxes d'appels de fonctions

### 1. Appel direct

```powershell
Get-Process
Get-ChildItem -Path C:\
```

### 2. Appel avec namespace/module

```powershell
Microsoft.PowerShell.Management\Get-Process
Microsoft.PowerShell.Utility\Write-Host "Hello"
```

### 3. Appel avec alias

```powershell
gps  # Alias de Get-Process
dir  # Alias de Get-ChildItem
```

### 4. Appel avec variable

```powershell
$command = "Get-Process"
& $command
Invoke-Expression $command
```

### 5. Appel avec paramètres dynamiques

```powershell
$params = @{
    Path = "C:\"
    Recurse = $true
}
Get-ChildItem @params
```

### 6. Appel de méthode statique

```powershell
[System.IO.Path]::Combine("C:\", "folder")
[System.Math]::Max(10, 20)
```

### 7. Appel de méthode d'instance

```powershell
$string = "Hello, World"
$string.ToUpper()
```

### 8. Appel via pipeline

```powershell
Get-Process | Where-Object { $_.CPU -gt 10 }
```

### 9. Appel via script block

```powershell
& { Get-Process }
```

### 10. Appel via dot-sourcing

```powershell
. .\Get-CustomFunction.ps1
```

## Cas particuliers

### 1. Fonctions définies dans le même script

```powershell
function Get-CustomData {
    # ...
}

Get-CustomData  # Appel à une fonction définie localement
```

### 2. Fonctions importées via dot-sourcing

```powershell
. .\Helper-Functions.ps1
Get-HelperData  # Fonction importée via dot-sourcing
```

### 3. Fonctions dynamiques

```powershell
$functionName = "Get-" + $type + "Data"
& $functionName
```

### 4. Fonctions avec paramètres positionnels

```powershell
Get-Content C:\file.txt  # Paramètre positionnel sans nom
```

## Règles de détection

Pour détecter efficacement les appels de fonctions externes, nous devons suivre ces règles:

1. **Identifier les appels directs**: Rechercher les motifs `Verb-Noun` suivis de paramètres optionnels.
2. **Détecter les appels avec namespace**: Rechercher les motifs `Namespace\Verb-Noun`.
3. **Résoudre les alias**: Maintenir une table de correspondance des alias standards et résoudre les appels d'alias.
4. **Analyser les appels dynamiques**: Détecter les appels via `&` et `Invoke-Expression`.
5. **Identifier les appels de méthodes statiques**: Rechercher les motifs `[Namespace.Class]::Method()`.
6. **Exclure les fonctions définies localement**: Maintenir une liste des fonctions définies dans le script.
7. **Traiter les fonctions dot-sourcées**: Analyser les fichiers dot-sourcés pour extraire leurs fonctions.

## Implémentation

Pour implémenter cette détection, nous utiliserons l'AST (Abstract Syntax Tree) de PowerShell qui permet une analyse précise du code source. L'AST nous permettra d'identifier:

- Les appels de commandes (`CommandAst`)
- Les appels de méthodes (`MemberExpressionAst`)
- Les appels d'opérateurs (`BinaryExpressionAst`)
- Les appels dynamiques (`InvocationExpressionAst`)

## Exemples d'utilisation de l'AST

```powershell
$ast = [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref]$null, [ref]$null)

# Trouver tous les appels de commandes
$commandCalls = $ast.FindAll({
    param($node)
    $node -is [System.Management.Automation.Language.CommandAst]
}, $true)

# Trouver tous les appels de méthodes
$methodCalls = $ast.FindAll({
    param($node)
    $node -is [System.Management.Automation.Language.MemberExpressionAst] -and
    $node.Member -is [System.Management.Automation.Language.StringConstantExpressionAst]
}, $true)
```

## Conclusion

L'analyse des patterns d'appels de fonctions dans PowerShell est complexe en raison de la variété des syntaxes possibles. L'utilisation de l'AST de PowerShell nous permettra d'identifier avec précision les appels de fonctions externes et de déterminer les dépendances de modules non explicitement importés.
