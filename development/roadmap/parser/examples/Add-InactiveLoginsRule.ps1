# Add-InactiveLoginsRule.ps1
# Exemple d'ajout d'une nouvelle rÃƒÂ¨gle pour dÃƒÂ©tecter les logins inactifs

# Chemin du script d'ajout de rÃƒÂ¨gle
$addRuleScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\development\scripts\Add-SqlPermissionRule.ps1"

# Chemin de la fonction de vÃƒÂ©rification
$checkFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "CheckFunctions\Check-InactiveLogins.ps1"

# ParamÃƒÂ¨tres de la rÃƒÂ¨gle
$params = @{
    RuleId = "SVR-007"
    Name = "InactiveLogins"
    Description = "DÃƒÂ©tecte les logins SQL qui n'ont pas ÃƒÂ©tÃƒÂ© utilisÃƒÂ©s depuis plus de 90 jours"
    RuleType = "Server"
    Severity = "Moyenne"
    CheckFunctionPath = $checkFunctionPath
}

# Ajouter la rÃƒÂ¨gle
& $addRuleScriptPath @params -WhatIf

# Pour ajouter rÃƒÂ©ellement la rÃƒÂ¨gle, exÃƒÂ©cutez la commande suivante :
# & $addRuleScriptPath @params
