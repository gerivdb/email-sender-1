#Requires -Version 5.1
<#
.SYNOPSIS
    Crée des chemins de code alternatifs pour PowerShell 5.1 et 7.
.DESCRIPTION
    Ce script génère des modèles de code compatibles avec PowerShell 5.1 et 7,
    en implémentant des wrappers de fonctions et des techniques de sélection de code.
.PARAMETER OutputPath
    Chemin où enregistrer les modèles de code générés.
.PARAMETER ModuleName
    Nom du module pour lequel générer des modèles de code.
.EXAMPLE
    .\New-VersionCompatibleCode.ps1 -ModuleName "FileContentIndexer" -OutputPath "D:\Projets\ModuleCompatible"
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-30
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ModuleName,

    [Parameter()]
    [string]$OutputPath = "$PSScriptRoot\CompatibleCode"
)

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Fonction pour générer un modèle de module compatible
function New-CompatibleModuleTemplate {
    param(
        [string]$ModuleName,
        [string]$OutputPath
    )

    $modulePath = Join-Path -Path $OutputPath -ChildPath "$ModuleName.psm1"

    $moduleContent = @"
#
# Module $ModuleName
# Compatible avec PowerShell 5.1 et PowerShell 7+
#

# Détecter la version de PowerShell
`$script:isPowerShell7 = `$PSVersionTable.PSVersion.Major -ge 7
`$script:isPowerShell5 = `$PSVersionTable.PSVersion.Major -eq 5

# Fonction pour obtenir la version de PowerShell
function Get-PSVersionInfo {
    [CmdletBinding()]
    param()

    return [PSCustomObject]@{
        Major = `$PSVersionTable.PSVersion.Major
        Minor = `$PSVersionTable.PSVersion.Minor
        IsPowerShell7 = `$script:isPowerShell7
        IsPowerShell5 = `$script:isPowerShell5
        Edition = `$PSVersionTable.PSEdition
        FullVersion = `$PSVersionTable.PSVersion.ToString()
    }
}

# Fonction pour vérifier si une fonctionnalité est disponible
function Test-FeatureAvailability {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = `$true)]
        [string]`$FeatureName
    )

    `$featureMap = @{
        'Classes' = `$script:isPowerShell5 -or `$script:isPowerShell7
        'AdvancedClasses' = `$script:isPowerShell7
        'Ternary' = `$script:isPowerShell7
        'PipelineChain' = `$script:isPowerShell7
        'NullCoalescing' = `$script:isPowerShell7
        'ForEachParallel' = `$script:isPowerShell7
        'UsingVariables' = `$script:isPowerShell5 -or `$script:isPowerShell7
    }

    if (`$featureMap.ContainsKey(`$FeatureName)) {
        return `$featureMap[`$FeatureName]
    }

    return `$false
}

#
# Implémentation compatible avec les deux versions
#

# Exemple de factory function au lieu d'une classe
function New-$ModuleName {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]`$Name = "$ModuleName",

        [Parameter()]
        [hashtable]`$Properties = @{}
    )

    # Créer un objet de base
    `$instance = [PSCustomObject]@{
        Name = `$Name
        Properties = `$Properties
        CreatedAt = Get-Date
        PSTypeName = "$ModuleName"
    }

    # Ajouter des méthodes en fonction de la version de PowerShell
    if (`$script:isPowerShell7) {
        # Utiliser des fonctionnalités PowerShell 7
        `$instance | Add-Member -MemberType ScriptMethod -Name "Process" -Value {
            param([string]`$input)
            return `$input ?? "Default" # Utilisation de l'opérateur null-coalescing
        }
    } else {
        # Version compatible PowerShell 5.1
        `$instance | Add-Member -MemberType ScriptMethod -Name "Process" -Value {
            param([string]`$input)
            if (`$null -eq `$input) { return "Default" } else { return `$input }
        }
    }

    # Ajouter une méthode commune
    `$instance | Add-Member -MemberType ScriptMethod -Name "ToString" -Value {
        return "`$(`$this.Name) [Created: `$(`$this.CreatedAt)]"
    }

    return `$instance
}

# Fonction wrapper pour la parallélisation
function Invoke-Parallel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = `$true)]
        [scriptblock]`$ScriptBlock,

        [Parameter(Mandatory = `$true)]
        [object[]]`$InputObject,

        [Parameter()]
        [int]`$ThrottleLimit = 5
    )

    if (`$script:isPowerShell7) {
        # Utiliser ForEach-Object -Parallel en PowerShell 7
        return `$InputObject | ForEach-Object -Parallel `$ScriptBlock -ThrottleLimit `$ThrottleLimit
    } else {
        # Utiliser une approche compatible avec PowerShell 5.1
        `$results = @()

        # Créer un pool de runspaces
        `$sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        `$pool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, `$ThrottleLimit, `$sessionState, `$Host)
        `$pool.Open()

        try {
            `$runspaces = @()

            # Créer un runspace pour chaque élément d'entrée
            foreach (`$item in `$InputObject) {
                `$powershell = [System.Management.Automation.PowerShell]::Create()
                `$powershell.RunspacePool = `$pool
                [void]`$powershell.AddScript(`$ScriptBlock)
                [void]`$powershell.AddArgument(`$item)

                `$runspaces += [PSCustomObject]@{
                    PowerShell = `$powershell
                    AsyncResult = `$powershell.BeginInvoke()
                    Item = `$item
                }
            }

            # Collecter les résultats
            foreach (`$runspace in `$runspaces) {
                `$results += `$runspace.PowerShell.EndInvoke(`$runspace.AsyncResult)
                `$runspace.PowerShell.Dispose()
            }
        }
        finally {
            # Nettoyer les ressources
            `$pool.Close()
            `$pool.Dispose()
        }

        return `$results
    }
}

# Exporter les fonctions
Export-ModuleMember -Function New-$ModuleName, Invoke-Parallel, Get-PSVersionInfo, Test-FeatureAvailability
"@

    $moduleContent | Out-File -FilePath $modulePath -Encoding UTF8
    return $modulePath
}

# Fonction pour générer un exemple d'utilisation
function New-UsageExampleScript {
    param(
        [string]$ModuleName,
        [string]$OutputPath
    )

    $examplePath = Join-Path -Path $OutputPath -ChildPath "Example-$ModuleName.ps1"

    $exampleContent = @"
#
# Exemple d'utilisation du module $ModuleName
# Compatible avec PowerShell 5.1 et PowerShell 7+
#

# Importer le module
Import-Module .\$ModuleName.psm1 -Force

# Afficher les informations de version
`$versionInfo = Get-PSVersionInfo
Write-Host "PowerShell Version: `$(`$versionInfo.FullVersion)" -ForegroundColor Cyan
Write-Host "Edition: `$(`$versionInfo.Edition)" -ForegroundColor Cyan
Write-Host "PowerShell 7+: `$(`$versionInfo.IsPowerShell7)" -ForegroundColor Cyan
Write-Host "PowerShell 5.1: `$(`$versionInfo.IsPowerShell5)" -ForegroundColor Cyan
Write-Host ""

# Vérifier la disponibilité des fonctionnalités
Write-Host "Vérification des fonctionnalités disponibles:" -ForegroundColor Cyan
`$features = @('Classes', 'AdvancedClasses', 'Ternary', 'PipelineChain', 'NullCoalescing', 'ForEachParallel')
foreach (`$feature in `$features) {
    `$available = Test-FeatureAvailability -FeatureName `$feature
    Write-Host "  `$feature : `$available"
}
Write-Host ""

# Créer une instance du module
Write-Host "Création d'une instance de ${ModuleName}:" -ForegroundColor Cyan
`$instance = New-$ModuleName -Name "MonInstance" -Properties @{
    Setting1 = "Valeur1"
    Setting2 = 42
}

Write-Host "Instance créée: `$(`$instance.ToString())"
Write-Host "Propriétés: `$(`$instance.Properties | ConvertTo-Json -Compress)"
Write-Host ""

# Tester la méthode Process
Write-Host "Test de la méthode Process:" -ForegroundColor Cyan
`$result1 = `$instance.Process("Test")
`$result2 = `$instance.Process(`$null)
Write-Host "  Process('Test'): `$result1"
Write-Host "  Process(null): `$result2"
Write-Host ""

# Tester la parallélisation
Write-Host "Test de parallélisation:" -ForegroundColor Cyan
`$items = 1..5
`$results = Invoke-Parallel -ScriptBlock {
    param(`$item)
    `$computerName = `$env:COMPUTERNAME
    `$processId = `$PID
    return [PSCustomObject]@{
        Item = `$item
        ComputerName = `$computerName
        ProcessId = `$processId
        Timestamp = Get-Date
    }
} -InputObject `$items -ThrottleLimit 3

Write-Host "Résultats de la parallélisation:"
`$results | Format-Table -AutoSize
"@

    $exampleContent | Out-File -FilePath $examplePath -Encoding UTF8
    return $examplePath
}

# Fonction pour générer un guide de migration
function New-MigrationGuide {
    param(
        [string]$ModuleName,
        [string]$OutputPath
    )

    $guidePath = Join-Path -Path $OutputPath -ChildPath "$ModuleName-MigrationGuide.md"

    $guideContent = @"
# Guide de migration vers PowerShell 7 pour le module $ModuleName

Ce guide explique comment migrer votre code du module $ModuleName de PowerShell 5.1 vers PowerShell 7, en mettant en évidence les différences clés et les meilleures pratiques.

## Différences de syntaxe et de comportement

### 1. Opérateurs et expressions

PowerShell 7 introduit plusieurs nouveaux opérateurs qui simplifient le code :

- **Opérateur ternaire** : Disponible uniquement dans PowerShell 7
  - PS5: `if (condition) { valeurSiVrai } else { valeurSiFaux }`
  - PS7: `condition ? valeurSiVrai : valeurSiFaux`

- **Null-coalescing** : Disponible uniquement dans PowerShell 7
  - PS5: `if ($null -eq $var) { $default } else { $var }`
  - PS7: `$var ?? $default`

- **Chaînage de pipeline** : Disponible uniquement dans PowerShell 7
  - PS5: `$result = cmd1; $result | cmd2`
  - PS7: `cmd1 |> cmd2`

### 2. Classes et objets

PowerShell 7 offre un meilleur support pour les classes :

- **Classes de base** : Support amélioré dans PowerShell 7
- **Héritage** : Mieux géré dans PowerShell 7
- **Interfaces** : Supporté uniquement dans PowerShell 7
- **Constructeurs** : Options avancées dans PowerShell 7

### 3. Parallélisation

PowerShell 7 simplifie la parallélisation :

- **ForEach parallèle** :
  - PS5: Runspaces manuels
  - PS7: `ForEach-Object -Parallel`

- **Throttling** :
  - PS5: Implémentation manuelle
  - PS7: Paramètre `-ThrottleLimit`

- **Variables partagées** :
  - PS5: Implémentation complexe
  - PS7: Préfixe 'using:'

## Stratégies de migration

### Approche 1: Code conditionnel

Utilisez des conditions pour exécuter différent code selon la version:

```powershell
if ($PSVersionTable.PSVersion.Major -ge 7) {
    # Code PowerShell 7
} else {
    # Code PowerShell 5.1
}
```

### Approche 2: Factory functions

Utilisez des factory functions au lieu de classes pour une meilleure compatibilité:

```powershell
function New-MyObject {
    param([string]$Name)

    $obj = [PSCustomObject]@{
        Name = $Name
    }

    # Ajouter des méthodes
    $obj | Add-Member -MemberType ScriptMethod -Name "DoSomething" -Value {
        param([string]$input)
        # Implémentation
    }

    return $obj
}
```

### Approche 3: Wrappers de fonctionnalités

Créez des wrappers pour les fonctionnalités spécifiques à une version:

```powershell
function Invoke-Parallel {
    param(
        [scriptblock]$ScriptBlock,
        [object[]]$InputObject,
        [int]$ThrottleLimit = 5
    )

    if ($PSVersionTable.PSVersion.Major -ge 7) {
        # Utiliser ForEach-Object -Parallel
        return $InputObject | ForEach-Object -Parallel $ScriptBlock -ThrottleLimit $ThrottleLimit
    } else {
        # Implémentation compatible PS 5.1 avec Runspaces
        # ...
    }
}
```

## Meilleures pratiques

1. **Tester sur les deux versions**: Assurez-vous que votre code fonctionne correctement sur PowerShell 5.1 et 7.
2. **Utiliser des factory functions**: Préférez les factory functions aux classes pour une meilleure compatibilité.
3. **Éviter les fonctionnalités exclusives**: Évitez d'utiliser des fonctionnalités exclusives à PowerShell 7 si la compatibilité avec PowerShell 5.1 est requise.
4. **Documenter les différences**: Documentez clairement les différences de comportement entre les versions.
5. **Utiliser des wrappers**: Créez des wrappers pour les fonctionnalités spécifiques à une version.

## Ressources supplémentaires

- [Documentation officielle PowerShell 7](https://docs.microsoft.com/en-us/powershell/scripting/whats-new/what-s-new-in-powershell-70)
- [Guide de migration PowerShell 7](https://docs.microsoft.com/en-us/powershell/scripting/whats-new/migrating-from-windows-powershell-51-to-powershell-7)
- [Nouveautés de PowerShell 7](https://docs.microsoft.com/en-us/powershell/scripting/whats-new/what-s-new-in-powershell-70)
"@

    $guideContent | Out-File -FilePath $guidePath -Encoding UTF8
    return $guidePath
}

# Générer les fichiers
$modulePath = New-CompatibleModuleTemplate -ModuleName $ModuleName -OutputPath $OutputPath
$examplePath = New-UsageExampleScript -ModuleName $ModuleName -OutputPath $OutputPath
$guidePath = New-MigrationGuide -ModuleName $ModuleName -OutputPath $OutputPath

# Afficher un résumé
Write-Host "Génération de code compatible terminée!" -ForegroundColor Green
Write-Host ""
Write-Host "Fichiers générés:" -ForegroundColor Cyan
Write-Host "  Module: $modulePath"
Write-Host "  Exemple: $examplePath"
Write-Host "  Guide de migration: $guidePath"
Write-Host ""
Write-Host "Pour tester le module:"
Write-Host "  1. Ouvrez PowerShell 5.1 ou 7"
Write-Host "  2. Naviguez vers le répertoire: $OutputPath"
Write-Host "  3. Exécutez: .\Example-$ModuleName.ps1"

# Retourner un objet avec les chemins des fichiers générés
return @{
    ModulePath  = $modulePath
    ExamplePath = $examplePath
    GuidePath   = $guidePath
    OutputPath  = $OutputPath
}
