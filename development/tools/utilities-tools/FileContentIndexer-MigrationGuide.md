# Guide de migration vers PowerShell 7 pour le module FileContentIndexer

Ce guide explique comment migrer votre code du module FileContentIndexer de PowerShell 5.1 vers PowerShell 7, en mettant en Ã©vidence les diffÃ©rences clÃ©s et les meilleures pratiques.

## DiffÃ©rences de syntaxe et de comportement

### 1. OpÃ©rateurs et expressions

PowerShell 7 introduit plusieurs nouveaux opÃ©rateurs qui simplifient le code :

- **OpÃ©rateur ternaire** : Disponible uniquement dans PowerShell 7
  - PS5: if (condition) { valeurSiVrai } else { valeurSiFaux }
  - PS7: condition ? valeurSiVrai : valeurSiFaux

- **Null-coalescing** : Disponible uniquement dans PowerShell 7
  - PS5: if ( -eq ) {  } else {  }
  - PS7: $var ?? 

- **ChaÃ®nage de pipeline** : Disponible uniquement dans PowerShell 7
  - PS5: $result = cmd1;  | cmd2
  - PS7: cmd1 |> cmd2

### 2. Classes et objets

PowerShell 7 offre un meilleur support pour les classes :

- **Classes de base** : Support amÃ©liorÃ© dans PowerShell 7
- **HÃ©ritage** : Mieux gÃ©rÃ© dans PowerShell 7
- **Interfaces** : SupportÃ© uniquement dans PowerShell 7
- **Constructeurs** : Options avancÃ©es dans PowerShell 7

### 3. ParallÃ©lisation

PowerShell 7 simplifie la parallÃ©lisation :

- **ForEach parallÃ¨le** :
  - PS5: Runspaces manuels
  - PS7: ForEach-Object -Parallel

- **Throttling** :
  - PS5: ImplÃ©mentation manuelle
  - PS7: ParamÃ¨tre -ThrottleLimit

- **Variables partagÃ©es** :
  - PS5: ImplÃ©mentation complexe
  - PS7: PrÃ©fixe 'using:'

## StratÃ©gies de migration

### Approche 1: Code conditionnel

Utilisez des conditions pour exÃ©cuter diffÃ©rent code selon la version:

`powershell
if (System.Management.Automation.PSVersionHashTable.PSVersion.Major -ge 7) {
    # Code PowerShell 7
} else {
    # Code PowerShell 5.1
}
`

### Approche 2: Factory functions

Utilisez des factory functions au lieu de classes pour une meilleure compatibilitÃ©:

`powershell
function New-MyObject {
    param([string])

     = [PSCustomObject]@{
        Name = 
    }

    # Ajouter des mÃ©thodes
     | Add-Member -MemberType ScriptMethod -Name "DoSomething" -Value {
        param([string])
        # ImplÃ©mentation
    }

    return 
}
`

### Approche 3: Wrappers de fonctionnalitÃ©s

CrÃ©ez des wrappers pour les fonctionnalitÃ©s spÃ©cifiques Ã  une version:

`powershell
function Invoke-Parallel {
    param(
        [scriptblock],
        [object[]],
        [int] = 5
    )

    if (System.Management.Automation.PSVersionHashTable.PSVersion.Major -ge 7) {
        # Utiliser ForEach-Object -Parallel
        return  | ForEach-Object -Parallel  -ThrottleLimit 
    } else {
        # ImplÃ©mentation compatible PS 5.1 avec Runspaces
        # ...
    }
}
`

## Meilleures pratiques

1. **Tester sur les deux versions**: Assurez-vous que votre code fonctionne correctement sur PowerShell 5.1 et 7.
2. **Utiliser des factory functions**: PrÃ©fÃ©rez les factory functions aux classes pour une meilleure compatibilitÃ©.
3. **Ã‰viter les fonctionnalitÃ©s exclusives**: Ã‰vitez d'utiliser des fonctionnalitÃ©s exclusives Ã  PowerShell 7 si la compatibilitÃ© avec PowerShell 5.1 est requise.
4. **Documenter les diffÃ©rences**: Documentez clairement les diffÃ©rences de comportement entre les versions.
5. **Utiliser des wrappers**: CrÃ©ez des wrappers pour les fonctionnalitÃ©s spÃ©cifiques Ã  une version.

## Ressources supplÃ©mentaires

- [Documentation officielle PowerShell 7](https://docs.microsoft.com/en-us/powershell/scripting/whats-new/what-s-new-in-powershell-70)
- [Guide de migration PowerShell 7](https://docs.microsoft.com/en-us/powershell/scripting/whats-new/migrating-from-windows-powershell-51-to-powershell-7)
- [NouveautÃ©s de PowerShell 7](https://docs.microsoft.com/en-us/powershell/scripting/whats-new/what-s-new-in-powershell-70)
