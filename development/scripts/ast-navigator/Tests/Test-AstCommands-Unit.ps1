<#
.SYNOPSIS
    Tests unitaires pour la fonction Get-AstCommands.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Get-AstCommands
    qui permet d'extraire les commandes d'un script PowerShell.

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de crÃ©ation: 2023-12-15
#>

# Importer la fonction Ã  tester
. "$PSScriptRoot\..\Public\Get-AstCommands.ps1"

# Fonction pour exÃ©cuter les tests
function Test-AstCommands {
    [CmdletBinding()]
    param()

    # Initialiser le compteur de tests
    $testCount = 0
    $passedCount = 0
    $failedCount = 0

    # Fonction pour vÃ©rifier une condition
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

    # CrÃ©er un script PowerShell de test avec diffÃ©rents types de commandes
    $sampleCode = @'
# Commandes simples
Get-Process
Get-Service -Name "BITS"
Write-Output "Hello, World!"

# Commandes avec pipeline
Get-ChildItem -Path "C:\Temp" -Filter "*.txt" | Where-Object { $_.Length -gt 1KB } | Sort-Object Length -Descending

# Commandes avec paramÃ¨tres nommÃ©s et positionnels
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
    
    # VÃ©rifier que les commandes principales sont prÃ©sentes
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
    Assert-Condition -Condition ($filteredNames -contains "Get-Process") -Message "Les commandes filtrÃ©es devraient contenir Get-Process"
    Assert-Condition -Condition ($filteredNames -contains "Get-Service") -Message "Les commandes filtrÃ©es devraient contenir Get-Service"
    Assert-Condition -Condition ($filteredNames -contains "Get-ChildItem") -Message "Les commandes filtrÃ©es devraient contenir Get-ChildItem"
    Assert-Condition -Condition ($filteredNames -notcontains "Write-Output") -Message "Les commandes filtrÃ©es ne devraient pas contenir Write-Output"
    Assert-Condition -Condition ($filteredNames -notcontains "New-Item") -Message "Les commandes filtrÃ©es ne devraient pas contenir New-Item"

    Write-Host "`nTest 3: Extraction des arguments de commandes" -ForegroundColor Cyan
    $commandsWithArgs = Get-AstCommands -Ast $ast -IncludeArguments
    
    # VÃ©rifier les arguments de Get-Service
    $getService = $commandsWithArgs | Where-Object { $_.Name -eq "Get-Service" } | Select-Object -First 1
    Assert-Condition -Condition ($null -ne $getService.Arguments) -Message "Les arguments de Get-Service devraient Ãªtre inclus"
    Assert-Condition -Condition ($getService.Arguments.Count -eq 1) -Message "Get-Service devrait avoir 1 argument"
    Assert-Condition -Condition ($getService.Arguments[0].IsParameter -eq $true) -Message "L'argument de Get-Service devrait Ãªtre un paramÃ¨tre"
    Assert-Condition -Condition ($getService.Arguments[0].ParameterName -eq "Name") -Message "Le paramÃ¨tre de Get-Service devrait Ãªtre Name"
    Assert-Condition -Condition ($getService.Arguments[0].Value -eq '"BITS"') -Message "La valeur du paramÃ¨tre Name devrait Ãªtre 'BITS'"
    
    # VÃ©rifier les arguments de New-Item
    $newItem = $commandsWithArgs | Where-Object { $_.Name -eq "New-Item" } | Select-Object -First 1
    Assert-Condition -Condition ($null -ne $newItem.Arguments) -Message "Les arguments de New-Item devraient Ãªtre inclus"
    Assert-Condition -Condition ($newItem.Arguments.Count -eq 3) -Message "New-Item devrait avoir 3 arguments"
    
    $pathParam = $newItem.Arguments | Where-Object { $_.ParameterName -eq "Path" } | Select-Object -First 1
    Assert-Condition -Condition ($null -ne $pathParam) -Message "New-Item devrait avoir un paramÃ¨tre Path"
    Assert-Condition -Condition ($pathParam.Value -eq '"C:\Temp\test.txt"') -Message "La valeur du paramÃ¨tre Path devrait Ãªtre 'C:\Temp\test.txt'"
    
    $itemTypeParam = $newItem.Arguments | Where-Object { $_.ParameterName -eq "ItemType" } | Select-Object -First 1
    Assert-Condition -Condition ($null -ne $itemTypeParam) -Message "New-Item devrait avoir un paramÃ¨tre ItemType"
    Assert-Condition -Condition ($itemTypeParam.Value -eq "File") -Message "La valeur du paramÃ¨tre ItemType devrait Ãªtre File"
    
    $forceParam = $newItem.Arguments | Where-Object { $_.ParameterName -eq "Force" } | Select-Object -First 1
    Assert-Condition -Condition ($null -ne $forceParam) -Message "New-Item devrait avoir un paramÃ¨tre Force"

    Write-Host "`nTest 4: Extraction des informations de pipeline" -ForegroundColor Cyan
    $commandsWithPipelines = Get-AstCommands -Ast $ast -IncludePipelines
    
    # VÃ©rifier le pipeline Get-ChildItem | Where-Object | Sort-Object
    $getChildItem = $commandsWithPipelines | Where-Object { $_.Name -eq "Get-ChildItem" } | Select-Object -First 1
    Assert-Condition -Condition ($null -ne $getChildItem.Pipeline) -Message "Les informations de pipeline de Get-ChildItem devraient Ãªtre incluses"
    Assert-Condition -Condition ($getChildItem.Pipeline.IsFirst -eq $true) -Message "Get-ChildItem devrait Ãªtre la premiÃ¨re commande du pipeline"
    Assert-Condition -Condition ($getChildItem.Pipeline.IsLast -eq $false) -Message "Get-ChildItem ne devrait pas Ãªtre la derniÃ¨re commande du pipeline"
    Assert-Condition -Condition ($getChildItem.Pipeline.Position -eq 0) -Message "La position de Get-ChildItem dans le pipeline devrait Ãªtre 0"
    Assert-Condition -Condition ($getChildItem.Pipeline.TotalCommands -eq 3) -Message "Le pipeline de Get-ChildItem devrait contenir 3 commandes"
    
    $whereObject = $commandsWithPipelines | Where-Object { $_.Name -eq "Where-Object" } | Select-Object -First 1
    Assert-Condition -Condition ($null -ne $whereObject.Pipeline) -Message "Les informations de pipeline de Where-Object devraient Ãªtre incluses"
    Assert-Condition -Condition ($whereObject.Pipeline.IsFirst -eq $false) -Message "Where-Object ne devrait pas Ãªtre la premiÃ¨re commande du pipeline"
    Assert-Condition -Condition ($whereObject.Pipeline.IsLast -eq $false) -Message "Where-Object ne devrait pas Ãªtre la derniÃ¨re commande du pipeline"
    Assert-Condition -Condition ($whereObject.Pipeline.Position -eq 1) -Message "La position de Where-Object dans le pipeline devrait Ãªtre 1"
    Assert-Condition -Condition ($whereObject.Pipeline.TotalCommands -eq 3) -Message "Le pipeline de Where-Object devrait contenir 3 commandes"
    
    $sortObject = $commandsWithPipelines | Where-Object { $_.Name -eq "Sort-Object" } | Select-Object -First 1
    Assert-Condition -Condition ($null -ne $sortObject.Pipeline) -Message "Les informations de pipeline de Sort-Object devraient Ãªtre incluses"
    Assert-Condition -Condition ($sortObject.Pipeline.IsFirst -eq $false) -Message "Sort-Object ne devrait pas Ãªtre la premiÃ¨re commande du pipeline"
    Assert-Condition -Condition ($sortObject.Pipeline.IsLast -eq $true) -Message "Sort-Object devrait Ãªtre la derniÃ¨re commande du pipeline"
    Assert-Condition -Condition ($sortObject.Pipeline.Position -eq 2) -Message "La position de Sort-Object dans le pipeline devrait Ãªtre 2"
    Assert-Condition -Condition ($sortObject.Pipeline.TotalCommands -eq 3) -Message "Le pipeline de Sort-Object devrait contenir 3 commandes"

    Write-Host "`nTest 5: Gestion des erreurs" -ForegroundColor Cyan
    # CrÃ©er un AST sans commande
    $emptyCode = "# Ceci est un commentaire sans commande"
    $emptyTokens = $emptyErrors = $null
    $emptyAst = [System.Management.Automation.Language.Parser]::ParseInput($emptyCode, [ref]$emptyTokens, [ref]$emptyErrors)
    
    $emptyCommands = Get-AstCommands -Ast $emptyAst
    Assert-Condition -Condition ($emptyCommands -is [array]) -Message "Devrait retourner un tableau pour un AST sans commande"
    Assert-Condition -Condition ($emptyCommands.Count -eq 0) -Message "Devrait retourner un tableau vide pour un AST sans commande"
    
    $nonExistentCommands = Get-AstCommands -Ast $ast -Name "NonExistentCommand"
    Assert-Condition -Condition ($nonExistentCommands -is [array]) -Message "Devrait retourner un tableau pour un filtre sans correspondance"
    Assert-Condition -Condition ($nonExistentCommands.Count -eq 0) -Message "Devrait retourner un tableau vide pour un filtre sans correspondance"

    # Afficher le rÃ©sumÃ© des tests
    Write-Host "`n=== RÃ©sumÃ© des tests ===" -ForegroundColor Cyan
    Write-Host "Tests exÃ©cutÃ©s: $testCount" -ForegroundColor Yellow
    Write-Host "Tests rÃ©ussis: $passedCount" -ForegroundColor Green
    Write-Host "Tests Ã©chouÃ©s: $failedCount" -ForegroundColor Red
    
    # Retourner le rÃ©sultat global
    return $failedCount -eq 0
}

# ExÃ©cuter les tests
$result = Test-AstCommands
if ($result) {
    Write-Host "`nTous les tests ont rÃ©ussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont Ã©chouÃ©." -ForegroundColor Red
    exit 1
}
