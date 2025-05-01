<#
.SYNOPSIS
    Tests unitaires pour la fonction Get-AstCommands.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Get-AstCommands
    qui permet d'extraire les commandes d'un script PowerShell.

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de création: 2023-12-15
#>

# Importer la fonction à tester
. "$PSScriptRoot\..\Public\Get-AstCommands.ps1"

# Fonction pour exécuter les tests
function Test-AstCommands {
    [CmdletBinding()]
    param()

    # Initialiser le compteur de tests
    $testCount = 0
    $passedCount = 0
    $failedCount = 0

    # Fonction pour vérifier une condition
    function Assert-Condition {
        param (
            [Parameter(Mandatory = $true)]
            [bool]$Condition,
            
            [Parameter(Mandatory = $true)]
            [string]$Message
        )
        
        $testCount++
        
        if ($Condition) {
            Write-Host "  [PASSED] $Message" -ForegroundColor Green
            $script:passedCount++
        } else {
            Write-Host "  [FAILED] $Message" -ForegroundColor Red
            $script:failedCount++
        }
    }

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
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)

    Write-Host "Test 1: Extraction de base des commandes" -ForegroundColor Cyan
    $commands = Get-AstCommands -Ast $ast
    Assert-Condition -Condition ($commands.Count -gt 10) -Message "Devrait extraire plus de 10 commandes"
    
    # Vérifier que les commandes principales sont présentes
    $commandNames = $commands | ForEach-Object { $_.Name }
    Assert-Condition -Condition ($commandNames -contains "Get-Process") -Message "Devrait contenir la commande Get-Process"
    Assert-Condition -Condition ($commandNames -contains "Get-Service") -Message "Devrait contenir la commande Get-Service"
    Assert-Condition -Condition ($commandNames -contains "Write-Output") -Message "Devrait contenir la commande Write-Output"
    Assert-Condition -Condition ($commandNames -contains "Get-ChildItem") -Message "Devrait contenir la commande Get-ChildItem"
    Assert-Condition -Condition ($commandNames -contains "Where-Object") -Message "Devrait contenir la commande Where-Object"
    Assert-Condition -Condition ($commandNames -contains "Sort-Object") -Message "Devrait contenir la commande Sort-Object"
    Assert-Condition -Condition ($commandNames -contains "New-Item") -Message "Devrait contenir la commande New-Item"
    Assert-Condition -Condition ($commandNames -contains "Copy-Item") -Message "Devrait contenir la commande Copy-Item"
    Assert-Condition -Condition ($commandNames -contains "Write-Host") -Message "Devrait contenir la commande Write-Host"
    Assert-Condition -Condition ($commandNames -contains "Test-Function") -Message "Devrait contenir la commande Test-Function"
    Assert-Condition -Condition ($commandNames -contains "ping") -Message "Devrait contenir la commande ping"
    Assert-Condition -Condition ($commandNames -contains "cmd") -Message "Devrait contenir la commande cmd"
    Assert-Condition -Condition ($commandNames -contains "Add-Content") -Message "Devrait contenir la commande Add-Content"
    Assert-Condition -Condition ($commandNames -contains "Restart-Service") -Message "Devrait contenir la commande Restart-Service"

    Write-Host "`nTest 2: Filtrage des commandes par nom" -ForegroundColor Cyan
    $filteredCommands = Get-AstCommands -Ast $ast -Name "Get-*"
    Assert-Condition -Condition ($filteredCommands.Count -ge 3) -Message "Devrait extraire au moins 3 commandes avec le filtre Get-*"
    
    $filteredNames = $filteredCommands | ForEach-Object { $_.Name }
    Assert-Condition -Condition ($filteredNames -contains "Get-Process") -Message "Les commandes filtrées devraient contenir Get-Process"
    Assert-Condition -Condition ($filteredNames -contains "Get-Service") -Message "Les commandes filtrées devraient contenir Get-Service"
    Assert-Condition -Condition ($filteredNames -contains "Get-ChildItem") -Message "Les commandes filtrées devraient contenir Get-ChildItem"
    Assert-Condition -Condition ($filteredNames -notcontains "Write-Output") -Message "Les commandes filtrées ne devraient pas contenir Write-Output"
    Assert-Condition -Condition ($filteredNames -notcontains "New-Item") -Message "Les commandes filtrées ne devraient pas contenir New-Item"

    Write-Host "`nTest 3: Extraction des arguments de commandes" -ForegroundColor Cyan
    $commandsWithArgs = Get-AstCommands -Ast $ast -IncludeArguments
    
    # Vérifier les arguments de Get-Service
    $getService = $commandsWithArgs | Where-Object { $_.Name -eq "Get-Service" } | Select-Object -First 1
    Assert-Condition -Condition ($null -ne $getService.Arguments) -Message "Les arguments de Get-Service devraient être inclus"
    Assert-Condition -Condition ($getService.Arguments.Count -eq 1) -Message "Get-Service devrait avoir 1 argument"
    Assert-Condition -Condition ($getService.Arguments[0].IsParameter -eq $true) -Message "L'argument de Get-Service devrait être un paramètre"
    Assert-Condition -Condition ($getService.Arguments[0].ParameterName -eq "Name") -Message "Le paramètre de Get-Service devrait être Name"
    Assert-Condition -Condition ($getService.Arguments[0].Value -eq '"BITS"') -Message "La valeur du paramètre Name devrait être 'BITS'"
    
    # Vérifier les arguments de New-Item
    $newItem = $commandsWithArgs | Where-Object { $_.Name -eq "New-Item" } | Select-Object -First 1
    Assert-Condition -Condition ($null -ne $newItem.Arguments) -Message "Les arguments de New-Item devraient être inclus"
    Assert-Condition -Condition ($newItem.Arguments.Count -eq 3) -Message "New-Item devrait avoir 3 arguments"
    
    $pathParam = $newItem.Arguments | Where-Object { $_.ParameterName -eq "Path" } | Select-Object -First 1
    Assert-Condition -Condition ($null -ne $pathParam) -Message "New-Item devrait avoir un paramètre Path"
    Assert-Condition -Condition ($pathParam.Value -eq '"C:\Temp\test.txt"') -Message "La valeur du paramètre Path devrait être 'C:\Temp\test.txt'"
    
    $itemTypeParam = $newItem.Arguments | Where-Object { $_.ParameterName -eq "ItemType" } | Select-Object -First 1
    Assert-Condition -Condition ($null -ne $itemTypeParam) -Message "New-Item devrait avoir un paramètre ItemType"
    Assert-Condition -Condition ($itemTypeParam.Value -eq "File") -Message "La valeur du paramètre ItemType devrait être File"
    
    $forceParam = $newItem.Arguments | Where-Object { $_.ParameterName -eq "Force" } | Select-Object -First 1
    Assert-Condition -Condition ($null -ne $forceParam) -Message "New-Item devrait avoir un paramètre Force"

    Write-Host "`nTest 4: Extraction des informations de pipeline" -ForegroundColor Cyan
    $commandsWithPipelines = Get-AstCommands -Ast $ast -IncludePipelines
    
    # Vérifier le pipeline Get-ChildItem | Where-Object | Sort-Object
    $getChildItem = $commandsWithPipelines | Where-Object { $_.Name -eq "Get-ChildItem" } | Select-Object -First 1
    Assert-Condition -Condition ($null -ne $getChildItem.Pipeline) -Message "Les informations de pipeline de Get-ChildItem devraient être incluses"
    Assert-Condition -Condition ($getChildItem.Pipeline.IsFirst -eq $true) -Message "Get-ChildItem devrait être la première commande du pipeline"
    Assert-Condition -Condition ($getChildItem.Pipeline.IsLast -eq $false) -Message "Get-ChildItem ne devrait pas être la dernière commande du pipeline"
    Assert-Condition -Condition ($getChildItem.Pipeline.Position -eq 0) -Message "La position de Get-ChildItem dans le pipeline devrait être 0"
    Assert-Condition -Condition ($getChildItem.Pipeline.TotalCommands -eq 3) -Message "Le pipeline de Get-ChildItem devrait contenir 3 commandes"
    
    $whereObject = $commandsWithPipelines | Where-Object { $_.Name -eq "Where-Object" } | Select-Object -First 1
    Assert-Condition -Condition ($null -ne $whereObject.Pipeline) -Message "Les informations de pipeline de Where-Object devraient être incluses"
    Assert-Condition -Condition ($whereObject.Pipeline.IsFirst -eq $false) -Message "Where-Object ne devrait pas être la première commande du pipeline"
    Assert-Condition -Condition ($whereObject.Pipeline.IsLast -eq $false) -Message "Where-Object ne devrait pas être la dernière commande du pipeline"
    Assert-Condition -Condition ($whereObject.Pipeline.Position -eq 1) -Message "La position de Where-Object dans le pipeline devrait être 1"
    Assert-Condition -Condition ($whereObject.Pipeline.TotalCommands -eq 3) -Message "Le pipeline de Where-Object devrait contenir 3 commandes"
    
    $sortObject = $commandsWithPipelines | Where-Object { $_.Name -eq "Sort-Object" } | Select-Object -First 1
    Assert-Condition -Condition ($null -ne $sortObject.Pipeline) -Message "Les informations de pipeline de Sort-Object devraient être incluses"
    Assert-Condition -Condition ($sortObject.Pipeline.IsFirst -eq $false) -Message "Sort-Object ne devrait pas être la première commande du pipeline"
    Assert-Condition -Condition ($sortObject.Pipeline.IsLast -eq $true) -Message "Sort-Object devrait être la dernière commande du pipeline"
    Assert-Condition -Condition ($sortObject.Pipeline.Position -eq 2) -Message "La position de Sort-Object dans le pipeline devrait être 2"
    Assert-Condition -Condition ($sortObject.Pipeline.TotalCommands -eq 3) -Message "Le pipeline de Sort-Object devrait contenir 3 commandes"

    Write-Host "`nTest 5: Gestion des erreurs" -ForegroundColor Cyan
    # Créer un AST sans commande
    $emptyCode = "# Ceci est un commentaire sans commande"
    $emptyTokens = $emptyErrors = $null
    $emptyAst = [System.Management.Automation.Language.Parser]::ParseInput($emptyCode, [ref]$emptyTokens, [ref]$emptyErrors)
    
    $emptyCommands = Get-AstCommands -Ast $emptyAst
    Assert-Condition -Condition ($emptyCommands -is [array]) -Message "Devrait retourner un tableau pour un AST sans commande"
    Assert-Condition -Condition ($emptyCommands.Count -eq 0) -Message "Devrait retourner un tableau vide pour un AST sans commande"
    
    $nonExistentCommands = Get-AstCommands -Ast $ast -Name "NonExistentCommand"
    Assert-Condition -Condition ($nonExistentCommands -is [array]) -Message "Devrait retourner un tableau pour un filtre sans correspondance"
    Assert-Condition -Condition ($nonExistentCommands.Count -eq 0) -Message "Devrait retourner un tableau vide pour un filtre sans correspondance"

    # Afficher le résumé des tests
    Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
    Write-Host "Tests exécutés: $testCount" -ForegroundColor Yellow
    Write-Host "Tests réussis: $passedCount" -ForegroundColor Green
    Write-Host "Tests échoués: $failedCount" -ForegroundColor Red
    
    # Retourner le résultat global
    return $failedCount -eq 0
}

# Exécuter les tests
$result = Test-AstCommands
if ($result) {
    Write-Host "`nTous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont échoué." -ForegroundColor Red
    exit 1
}
