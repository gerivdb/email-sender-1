# Add-HighPrivilegeAccountsRule.ps1
# Ajoute une rÃƒÂ¨gle pour dÃƒÂ©tecter les comptes ÃƒÂ  privilÃƒÂ¨ges ÃƒÂ©levÃƒÂ©s

# Chemin du script d'ajout de rÃƒÂ¨gle
$addRuleScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\development\scripts\Add-SqlPermissionRule.ps1"

# Chemin de la fonction de vÃƒÂ©rification
$checkFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "CheckFunctions\Check-HighPrivilegeAccounts.ps1"

# ParamÃƒÂ¨tres de la rÃƒÂ¨gle
$params = @{
    RuleId = "SVR-008"
    Name = "HighPrivilegeAccountsExtended"
    Description = "DÃƒÂ©tecte les comptes avec des privilÃƒÂ¨ges ÃƒÂ©levÃƒÂ©s ou des permissions ÃƒÂ©quivalentes"
    RuleType = "Server"
    Severity = "Ãƒâ€°levÃƒÂ©e"
    CheckFunctionPath = $checkFunctionPath
}

# Ajouter la rÃƒÂ¨gle
& $addRuleScriptPath @params -WhatIf

# Pour ajouter rÃƒÂ©ellement la rÃƒÂ¨gle, exÃƒÂ©cutez la commande suivante :
# & $addRuleScriptPath @params
