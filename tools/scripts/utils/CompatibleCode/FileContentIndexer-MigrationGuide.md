# Guide de migration vers PowerShell 7 pour le module FileContentIndexer

Ce guide explique comment migrer votre code du module FileContentIndexer de PowerShell 5.1 vers PowerShell 7, en mettant en évidence les différences clés et les meilleures pratiques.

## Différences de syntaxe et de comportement

### 1. Opérateurs et expressions

PowerShell 7 introduit plusieurs nouveaux opérateurs qui simplifient le code :

- **Opérateur ternaire** : Disponible uniquement dans PowerShell 7
  - PS5: if (condition) { valeurSiVrai } else { valeurSiFaux }
  - PS7: condition ? valeurSiVrai : valeurSiFaux

- **Null-coalescing** : Disponible uniquement dans PowerShell 7
  - PS5: if ( -eq ) {  } else {  }
  - PS7: $var ?? 

- **Chaînage de pipeline** : Disponible uniquement dans PowerShell 7
  - PS5: $result = cmd1;  | cmd2
  - PS7: cmd1 |> cmd2

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
  - PS7: ForEach-Object -Parallel

- **Throttling** :
  - PS5: Implémentation manuelle
  - PS7: Paramètre -ThrottleLimit

- **Variables partagées** :
  - PS5: Implémentation complexe
  - PS7: Préfixe 'using:'

## Stratégies de migration

### Approche 1: Code conditionnel

Utilisez des conditions pour exécuter différent code selon la version:

`powershell
if (System.Management.Automation.PSVersionHashTable.PSVersion.Major -ge 7) {
    # Code PowerShell 7
} else {
    # Code PowerShell 5.1
}
`

### Approche 2: Factory functions

Utilisez des factory functions au lieu de classes pour une meilleure compatibilité:

`powershell
function New-MyObject {
    param([string])

     = [PSCustomObject]@{
        Name = 
    }

    # Ajouter des méthodes
     | Add-Member -MemberType ScriptMethod -Name "DoSomething" -Value {
        param([string])
        # Implémentation
    }

    return 
}
`

### Approche 3: Wrappers de fonctionnalités

Créez des wrappers pour les fonctionnalités spécifiques à une version:

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
        # Implémentation compatible PS 5.1 avec Runspaces
        # ...
    }
}
`

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
