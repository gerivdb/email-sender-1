---
to: development/scripts/{{category}}/modules/{{name}}/Public/README.md
---
# Fonctions publiques du module HygenTestModule

Ce dossier contient toutes les fonctions publiques du module. Ces fonctions sont exportées et accessibles aux utilisateurs du module.

## Structure des fichiers

Chaque fonction doit être définie dans son propre fichier `.ps1` avec le même nom que la fonction.

Exemple :
- `Get-Something.ps1` contient la fonction `Get-Something`
- `Set-Something.ps1` contient la fonction `Set-Something`

## Modèle de fonction publique

```powershell
function Verb-Noun {
    <#

    .SYNOPSIS
        Description courte de la fonction.
    .DESCRIPTION
        Description détaillée de la fonction.
    .PARAMETER ParameterName
        Description du paramètre.
    .EXAMPLE
        Verb-Noun -ParameterName "Value"
        Description de ce que fait cet exemple.
    .NOTES
        Informations supplémentaires sur la fonction.
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([type])] # Spécifier le type de retour

    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [type]$ParameterName
    )

    begin {
        Write-Verbose "Début de l'exécution de Verb-Noun"
    }

    process {
        try {
            if ($PSCmdlet.ShouldProcess("Target", "Operation")) {
                # Code principal ici

            }
        }
        catch {
            Write-Error "Une erreur s'est produite dans Verb-Noun : $_"
        }
    }

    end {
        Write-Verbose "Fin de l'exécution de Verb-Noun"
    }
}
```plaintext
## Bonnes pratiques

1. Utilisez des verbes approuvés par PowerShell (Get, Set, New, Remove, etc.)
2. Documentez chaque fonction avec des commentaires d'aide
3. Utilisez `[CmdletBinding()]` et `[Parameter()]` pour une meilleure expérience utilisateur
4. Implémentez la gestion des erreurs avec try/catch
5. Utilisez `Write-Verbose` pour le logging détaillé
6. Utilisez `ShouldProcess` pour les fonctions qui modifient l'état du système

