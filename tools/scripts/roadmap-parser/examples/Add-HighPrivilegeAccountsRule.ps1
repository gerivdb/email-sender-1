# Add-HighPrivilegeAccountsRule.ps1
# Ajoute une rÃ¨gle pour dÃ©tecter les comptes Ã  privilÃ¨ges Ã©levÃ©s

# Chemin du script d'ajout de rÃ¨gle
$addRuleScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\Add-SqlPermissionRule.ps1"

# Chemin de la fonction de vÃ©rification
$checkFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "CheckFunctions\Check-HighPrivilegeAccounts.ps1"

# ParamÃ¨tres de la rÃ¨gle
$params = @{
    RuleId = "SVR-008"
    Name = "HighPrivilegeAccountsExtended"
    Description = "DÃ©tecte les comptes avec des privilÃ¨ges Ã©levÃ©s ou des permissions Ã©quivalentes"
    RuleType = "Server"
    Severity = "Ã‰levÃ©e"
    CheckFunctionPath = $checkFunctionPath
}

# Ajouter la rÃ¨gle
& $addRuleScriptPath @params -WhatIf

# Pour ajouter rÃ©ellement la rÃ¨gle, exÃ©cutez la commande suivante :
# & $addRuleScriptPath @params
