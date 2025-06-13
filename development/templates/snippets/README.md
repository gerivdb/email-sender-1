# Code Snippets for EMAIL_SENDER_1

*Version 1.0 - 2025-05-15*

Ce dossier contient des snippets de code pour faciliter le développement du projet EMAIL_SENDER_1. Ces snippets peuvent être utilisés dans Visual Studio Code ou d'autres éditeurs compatibles.

## Table des matières

1. [Installation](#installation)

2. [Snippets disponibles](#snippets-disponibles)

3. [Utilisation](#utilisation)

4. [Exemples](#exemples)

5. [Personnalisation](#personnalisation)

## Installation

### Visual Studio Code

1. Ouvrez Visual Studio Code
2. Allez dans `File > Preferences > User Snippets`
3. Sélectionnez le langage pour lequel vous souhaitez ajouter des snippets (par exemple, `powershell.json` pour PowerShell)
4. Copiez le contenu du fichier JSON correspondant dans ce fichier
5. Sauvegardez le fichier

### Autres éditeurs

Consultez la documentation de votre éditeur pour savoir comment ajouter des snippets personnalisés.

## Snippets disponibles

### PowerShell-Function-Snippets.json

Contient des snippets pour créer rapidement des fonctions PowerShell conformes aux standards du projet :

- `func-basic` : Fonction PowerShell de base avec gestion des erreurs
- `func-advanced` : Fonction PowerShell avancée avec support de pipeline et ShouldProcess
- `func-get` : Template pour les fonctions Get-*
- `func-set` : Template pour les fonctions Set-*
- `func-new` : Template pour les fonctions New-*
- `func-remove` : Template pour les fonctions Remove-*
- `func-test` : Template pour les fonctions Test-*
- `func-invoke` : Template pour les fonctions Invoke-*

### PowerShell-Test-Snippets.json

Contient des snippets pour créer des tests Pester pour PowerShell :

- `test-file` : Structure de base d'un fichier de test Pester
- `test-describe` : Bloc Describe de Pester
- `test-context` : Bloc Context de Pester
- `test-it` : Bloc It de Pester
- `test-beforeall` : Bloc BeforeAll de Pester
- `test-afterall` : Bloc AfterAll de Pester
- `test-beforeeach` : Bloc BeforeEach de Pester
- `test-aftereach` : Bloc AfterEach de Pester
- `test-mock` : Commande Mock de Pester
- `test-shouldbe` : Assertion Should -Be de Pester
- `test-shouldbeexactly` : Assertion Should -BeExactly de Pester
- `test-shouldcontain` : Assertion Should -Contain de Pester
- `test-shouldbetrue` : Assertion Should -BeTrue de Pester
- `test-shouldbefalse` : Assertion Should -BeFalse de Pester
- `test-shouldbenull` : Assertion Should -BeNull de Pester
- `test-shouldnotbenull` : Assertion Should -Not -BeNull de Pester
- `test-shouldthrow` : Assertion Should -Throw de Pester
- `test-shouldnotthrow` : Assertion Should -Not -Throw de Pester
- `test-function` : Test complet pour une fonction
- `test-module` : Test complet pour un module

### Documentation-Snippets.json

Contient des snippets pour créer de la documentation :

- `doc-function` : Documentation pour une fonction PowerShell
- `doc-module` : Documentation pour un module PowerShell
- `doc-script` : Documentation pour un script PowerShell
- `doc-md-header` : En-tête de documentation Markdown
- `doc-md-function` : Documentation Markdown pour une fonction
- `doc-md-module` : Documentation Markdown pour un module
- `doc-py-function` : Documentation pour une fonction Python (style Google)
- `doc-py-class` : Documentation pour une classe Python (style Google)
- `doc-py-module` : Documentation pour un module Python (style Google)

## Utilisation

Pour utiliser un snippet, commencez à taper son préfixe dans l'éditeur, puis appuyez sur `Tab` ou sélectionnez le snippet dans la liste d'autocomplétion.

Par exemple, pour créer une fonction PowerShell de base :

1. Ouvrez un fichier PowerShell (.ps1 ou .psm1)
2. Tapez `func-basic`
3. Appuyez sur `Tab`
4. Le snippet sera inséré et vous pourrez remplir les champs interactivement

## Exemples

### Exemple 1 : Création d'une fonction Get-*

```powershell
# Tapez func-get puis Tab

function Get-EmailStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Id,
        
        [Parameter(Mandatory = $false)]
        [switch]$All
    )
    
    begin {
        Write-Verbose "Starting $($MyInvocation.MyCommand.Name)"
        $results = @()
    }
    
    process {
        try {
            if ($All) {
                # Get all items

                $result = Get-AllEmailStatus
            }
            else {
                # Get specific item

                $result = Get-SpecificEmailStatus -Id $Id
            }
            $results += $result
        }
        catch {
            Write-Error "Error in $($MyInvocation.MyCommand.Name): $_"
        }
    }
    
    end {
        Write-Verbose "Ending $($MyInvocation.MyCommand.Name)"
        return $results
    }
}
```plaintext
### Exemple 2 : Création d'un test Pester

```powershell
# Tapez test-function puis Tab

Describe 'Get-EmailStatus' {
    BeforeAll {
        # Import the module

        $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\EmailSender.psm1'
        Import-Module -Name $modulePath -Force
    }
    
    Context 'Parameter validation' {
        It 'Should not throw when no parameters are provided' {
            { Get-EmailStatus } | Should -Not -Throw
        }
        
        It 'Should not throw with valid parameters' {
            { Get-EmailStatus -Id '12345' } | Should -Not -Throw
        }
    }
    
    Context 'Functionality' {
        It 'Should return expected results' {
            # Arrange

            Mock -CommandName Get-SpecificEmailStatus -MockWith { return @{ Id = '12345'; Status = 'Sent' } }
            
            # Act

            $result = Get-EmailStatus -Id '12345'
            
            # Assert

            $result | Should -Not -BeNull
            $result.Status | Should -Be 'Sent'
        }
    }
    
    AfterAll {
        # Clean up

        Remove-Module -Name 'EmailSender' -Force -ErrorAction SilentlyContinue
    }
}
```plaintext
### Exemple 3 : Création d'une documentation de fonction

```powershell
# Tapez doc-function puis Tab

<#

.SYNOPSIS
    Récupère le statut d'un ou plusieurs emails.

.DESCRIPTION
    Cette fonction permet de récupérer le statut d'un email spécifique ou de tous les emails.
    Elle peut être utilisée pour suivre l'état d'envoi des emails.

.PARAMETER Id
    L'identifiant de l'email dont on souhaite connaître le statut.

.PARAMETER All
    Indique si tous les statuts d'emails doivent être récupérés.

.EXAMPLE
    Get-EmailStatus -Id '12345'
    Récupère le statut de l'email avec l'ID 12345.

.EXAMPLE
    Get-EmailStatus -All
    Récupère le statut de tous les emails.

.NOTES
    Author: John Doe
    Date: 2025-05-15
    Version: 1.0
#>

```plaintext
## Personnalisation

Vous pouvez personnaliser ces snippets en modifiant les fichiers JSON correspondants. Chaque snippet est défini par :

- `prefix` : Le texte à taper pour déclencher le snippet
- `body` : Le contenu du snippet (tableau de lignes)
- `description` : Une description du snippet

Pour ajouter un nouveau snippet, suivez le format existant et ajoutez-le au fichier JSON approprié.
