# Guide des bonnes pratiques et particularités de PowerShell 5.1

Ce document regroupe les conseils, astuces et particularités spécifiques à PowerShell 5.1, qui est la version par défaut installée sur Windows 10 et Windows Server 2016/2019.

## Différences syntaxiques avec PowerShell 7+

### Opérateurs logiques

#### Opérateur ET logique (&&)

En PowerShell 5.1, l'opérateur `&&` (ET logique) n'est pas pris en charge, car il a été introduit dans PowerShell 7.0 et versions ultérieures. 

Pour obtenir un comportement équivalent à `&&` dans PowerShell 5.1, vous devez utiliser une des approches suivantes :

1. Utiliser une structure conditionnelle :
```powershell
# Au lieu de :
# command1 && command2

# Utilisez :
if (command1) { command2 }
```

2. Pour des conditions logiques, utilisez l'opérateur `-and` :
```powershell
# Au lieu de :
# $condition1 && $condition2

# Utilisez :
$condition1 -and $condition2
```

#### Opérateur OU logique (||)

De même, l'opérateur `||` (OU logique) n'est pas disponible en PowerShell 5.1 :

```powershell
# Au lieu de :
# command1 || command2

# Utilisez :
if (-not (command1)) { command2 }

# Ou pour des conditions logiques :
$condition1 -or $condition2
```

### Opérateur de pipeline nul (??)

L'opérateur de pipeline nul `??` n'est pas disponible en PowerShell 5.1 :

```powershell
# Au lieu de :
# $result = $nullable ?? $default

# Utilisez :
$result = if ($null -ne $nullable) { $nullable } else { $default }
```

## Encodage des fichiers

PowerShell 5.1 utilise par défaut l'encodage "ASCII" pour les fichiers texte, ce qui peut causer des problèmes avec les caractères non-ASCII (comme les accents). Pour éviter ces problèmes :

1. Utilisez toujours l'encodage UTF-8 avec BOM pour les scripts PowerShell :
```powershell
# Pour lire un fichier avec l'encodage UTF-8
$content = Get-Content -Path "chemin\vers\fichier.txt" -Encoding UTF8

# Pour écrire dans un fichier avec l'encodage UTF-8
$content | Set-Content -Path "chemin\vers\fichier.txt" -Encoding UTF8
```

2. Pour les fichiers de configuration ou les fichiers JSON, utilisez UTF-8 sans BOM :
```powershell
# Nécessite le module NuGet 'UTF8Encoding'
$utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText("chemin\vers\fichier.json", $jsonContent, $utf8NoBomEncoding)
```

## Performances et parallélisme

PowerShell 5.1 offre des options limitées pour le parallélisme par rapport à PowerShell 7+ :

### Utilisation de ForEach-Object -Parallel

L'option `-Parallel` pour `ForEach-Object` n'est pas disponible en PowerShell 5.1. Utilisez plutôt :

1. `Start-Job` pour les tâches parallèles simples (mais avec un surcoût important) :
```powershell
$jobs = 1..10 | ForEach-Object { Start-Job -ScriptBlock { param($num) $num * 2 } -ArgumentList $_ }
$results = $jobs | Wait-Job | Receive-Job
$jobs | Remove-Job
```

2. Runspace Pools pour de meilleures performances :
```powershell
$runspacePool = [runspacefactory]::CreateRunspacePool(1, 10)
$runspacePool.Open()

$scriptBlock = {
    param($num)
    $num * 2
}

$runspaces = @()
1..10 | ForEach-Object {
    $runspace = [powershell]::Create().AddScript($scriptBlock).AddArgument($_)
    $runspace.RunspacePool = $runspacePool
    $runspaces += [PSCustomObject]@{
        Runspace = $runspace
        Handle = $runspace.BeginInvoke()
    }
}

$results = @()
$runspaces | ForEach-Object {
    $results += $_.Runspace.EndInvoke($_.Handle)
}

$runspacePool.Close()
$runspacePool.Dispose()
```

## Modules et compatibilité

### Vérification de la version de PowerShell

Pour s'assurer qu'un script est exécuté avec la bonne version de PowerShell :

```powershell
#Requires -Version 5.1
```

### Compatibilité des modules

Certains modules récents peuvent ne pas être compatibles avec PowerShell 5.1. Vérifiez toujours la compatibilité avant d'installer un module :

```powershell
Find-Module -Name "NomDuModule" | Select-Object -Property Name, Version, PowerShellGetFormatVersion
```

## Bonnes pratiques spécifiques à PowerShell 5.1

### Utilisation des verbes approuvés

Utilisez toujours des verbes approuvés pour vos fonctions et cmdlets :

```powershell
# Pour obtenir la liste des verbes approuvés
Get-Verb

# Exemple de fonction avec un verbe approuvé
function Get-CustomData {
    # ...
}
```

### Attribut CmdletBinding pour ShouldProcess

Lorsque vous utilisez `ShouldProcess` ou `ShouldContinue` dans vos fonctions, assurez-vous d'ajouter l'attribut `CmdletBinding` avec `SupportsShouldProcess=$true` :

```powershell
function Remove-CustomData {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    
    if ($PSCmdlet.ShouldProcess($Name, "Remove")) {
        # Effectuer la suppression
    }
}
```

### Éviter d'assigner des valeurs aux variables automatiques

N'assignez pas de valeurs aux variables automatiques comme `$_`, `$matches`, `$PSItem`, etc. :

```powershell
# Incorrect
$matches = "Something"

# Correct
$myMatches = "Something"
```

### Utilisation de Try-Catch-Finally

Utilisez toujours des blocs Try-Catch-Finally pour gérer les erreurs :

```powershell
try {
    # Code qui peut générer une erreur
}
catch [System.IO.FileNotFoundException] {
    # Gestion spécifique pour les fichiers non trouvés
}
catch {
    # Gestion générale des erreurs
    Write-Error "Une erreur s'est produite : $_"
}
finally {
    # Code qui s'exécute toujours, qu'il y ait une erreur ou non
    # Utile pour le nettoyage des ressources
}
```

## Ressources utiles

- [Documentation officielle de PowerShell 5.1](https://docs.microsoft.com/en-us/powershell/scripting/overview?view=powershell-5.1)
- [PowerShell Gallery](https://www.powershellgallery.com/)
- [PowerShell Community](https://powershell.org/)
