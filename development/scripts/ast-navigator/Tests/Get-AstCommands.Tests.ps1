<#
.SYNOPSIS
    Tests unitaires pour la fonction Get-AstCommands.

.DESCRIPTION
    Ce script contient des tests Pester pour la fonction Get-AstCommands
    qui permet d'extraire les commandes d'un script PowerShell.

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de création: 2023-12-15
#>

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".." -Resolve
Import-Module $modulePath -Force

Describe "Get-AstCommands" {
    BeforeAll {
        # Créer un script PowerShell de test avec différents types de commandes
        $sampleCode = @'
# Commandes simples
Get-Process
Get-Service -Name "BITS"
Write-Output "Hello, World!"

# Commandes avec pipeline
Get-ChildItem -Path "C:\Temp" -Filter "*.txt" | Where-Object { $_.Length -gt 1KB } | Sort-Object Length -Descending

# Commandes avec paramètres nommés et positionnels
New-Item -Path "C:\Temp\test.txt" -ItemType File -Force
Copy-Item "C:\Temp\source.txt" "C:\Temp\destination.txt" -Force

# Appels de fonctions
function Test-Function {
    param($Message)
    Write-Host $Message -ForegroundColor Green
    return $true
}

Test-Function -Message "Test message"
$result = Test-Function "Another test"

# Commandes externes
ping localhost
cmd /c "echo Hello from CMD"

# Commandes avec splatting
$params = @{
    Path = "C:\Temp\log.txt"
    Append = $true
    Force = $true
}
Add-Content @params -Value "Log entry"

# Commandes avec expressions
$serviceName = "BITS"
Restart-Service -Name $serviceName -Force
'@

        # Analyser le code avec l'AST
        $tokens = $errors = $null
        $script:ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)
    }

    Context "Extraction de base des commandes" {
        It "Devrait extraire toutes les commandes du script" {
            $commands = Get-AstCommands -Ast $script:ast
            $commands.Count | Should -BeGreaterThan 10

            # Vérifier que les commandes principales sont présentes
            $commandNames = $commands | ForEach-Object { $_.Name }
            $commandNames | Should -Contain "Get-Process"
            $commandNames | Should -Contain "Get-Service"
            $commandNames | Should -Contain "Write-Output"
            $commandNames | Should -Contain "Get-ChildItem"
            $commandNames | Should -Contain "Where-Object"
            $commandNames | Should -Contain "Sort-Object"
            $commandNames | Should -Contain "New-Item"
            $commandNames | Should -Contain "Copy-Item"
            $commandNames | Should -Contain "Write-Host"
            $commandNames | Should -Contain "Test-Function"
            $commandNames | Should -Contain "ping"
            $commandNames | Should -Contain "cmd"
            $commandNames | Should -Contain "Add-Content"
            $commandNames | Should -Contain "Restart-Service"
        }
    }

    Context "Filtrage des commandes" {
        It "Devrait filtrer les commandes par nom" {
            $commands = Get-AstCommands -Ast $script:ast -Name "Get-*"
            $commands.Count | Should -BeGreaterThan 2

            # Vérifier que seules les commandes Get-* sont présentes
            $commandNames = $commands | ForEach-Object { $_.Name }
            $commandNames | Should -Contain "Get-Process"
            $commandNames | Should -Contain "Get-Service"
            $commandNames | Should -Contain "Get-ChildItem"
            $commandNames | Should -Not -Contain "Write-Output"
            $commandNames | Should -Not -Contain "New-Item"
        }

        It "Devrait filtrer les commandes par type" {
            # Note: Cette fonctionnalité dépend de l'implémentation exacte de Get-AstCommands
            # et de sa capacité à déterminer le type de commande
            $commands = Get-AstCommands -Ast $script:ast -CommandType "Cmdlet"
            $commands.Count | Should -BeGreaterThan 5

            # Les commandes externes ne devraient pas être incluses
            $commandNames = $commands | ForEach-Object { $_.Name }
            $commandNames | Should -Not -Contain "ping"
            $commandNames | Should -Not -Contain "cmd"
        }
    }

    Context "Extraction des arguments de commandes" {
        It "Devrait inclure les arguments des commandes" {
            $commands = Get-AstCommands -Ast $script:ast -IncludeArguments

            # Vérifier les arguments de Get-Service
            $getService = $commands | Where-Object { $_.Name -eq "Get-Service" } | Select-Object -First 1
            $getService.Arguments | Should -Not -BeNullOrEmpty
            $getService.Arguments.Count | Should -Be 1
            $getService.Arguments[0].IsParameter | Should -Be $true
            $getService.Arguments[0].ParameterName | Should -Be "Name"
            $getService.Arguments[0].Value | Should -Be '"BITS"'

            # Vérifier les arguments de New-Item
            $newItem = $commands | Where-Object { $_.Name -eq "New-Item" } | Select-Object -First 1
            $newItem.Arguments | Should -Not -BeNullOrEmpty
            $newItem.Arguments.Count | Should -Be 3

            $pathParam = $newItem.Arguments | Where-Object { $_.ParameterName -eq "Path" } | Select-Object -First 1
            $pathParam | Should -Not -BeNullOrEmpty
            $pathParam.Value | Should -Be '"C:\Temp\test.txt"'

            $itemTypeParam = $newItem.Arguments | Where-Object { $_.ParameterName -eq "ItemType" } | Select-Object -First 1
            $itemTypeParam | Should -Not -BeNullOrEmpty
            $itemTypeParam.Value | Should -Be "File"

            $forceParam = $newItem.Arguments | Where-Object { $_.ParameterName -eq "Force" } | Select-Object -First 1
            $forceParam | Should -Not -BeNullOrEmpty
        }
    }

    Context "Extraction des informations de pipeline" {
        It "Devrait inclure les informations de pipeline" {
            $commands = Get-AstCommands -Ast $script:ast -IncludePipelines

            # Vérifier le pipeline Get-ChildItem | Where-Object | Sort-Object
            $getChildItem = $commands | Where-Object { $_.Name -eq "Get-ChildItem" } | Select-Object -First 1
            $getChildItem.Pipeline | Should -Not -BeNullOrEmpty
            $getChildItem.Pipeline.IsFirst | Should -Be $true
            $getChildItem.Pipeline.IsLast | Should -Be $false
            $getChildItem.Pipeline.Position | Should -Be 0
            $getChildItem.Pipeline.TotalCommands | Should -Be 3

            $whereObject = $commands | Where-Object { $_.Name -eq "Where-Object" } | Select-Object -First 1
            $whereObject.Pipeline | Should -Not -BeNullOrEmpty
            $whereObject.Pipeline.IsFirst | Should -Be $false
            $whereObject.Pipeline.IsLast | Should -Be $false
            $whereObject.Pipeline.Position | Should -Be 1
            $whereObject.Pipeline.TotalCommands | Should -Be 3

            $sortObject = $commands | Where-Object { $_.Name -eq "Sort-Object" } | Select-Object -First 1
            $sortObject.Pipeline | Should -Not -BeNullOrEmpty
            $sortObject.Pipeline.IsFirst | Should -Be $false
            $sortObject.Pipeline.IsLast | Should -Be $true
            $sortObject.Pipeline.Position | Should -Be 2
            $sortObject.Pipeline.TotalCommands | Should -Be 3
        }
    }

    Context "Gestion des erreurs" {
        It "Devrait retourner un tableau vide si aucune commande n'est trouvée" {
            # Créer un AST sans commande
            $emptyCode = "# Ceci est un commentaire sans commande"
            $emptyTokens = $emptyErrors = $null
            $emptyAst = [System.Management.Automation.Language.Parser]::ParseInput($emptyCode, [ref]$emptyTokens, [ref]$emptyErrors)

            $commands = Get-AstCommands -Ast $emptyAst
            $commands | Should -BeOfType System.Array
            $commands.Count | Should -Be 0
        }

        It "Devrait retourner un tableau vide si le filtre par nom ne correspond à aucune commande" {
            $commands = Get-AstCommands -Ast $script:ast -Name "NonExistentCommand"
            $commands | Should -BeOfType System.Array
            $commands.Count | Should -Be 0
        }
    }
}
