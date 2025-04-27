# Add-InactiveLoginsRule.ps1
# Exemple d'ajout d'une nouvelle rÃ¨gle pour dÃ©tecter les logins inactifs

# Chemin du script d'ajout de rÃ¨gle
$addRuleScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\Add-SqlPermissionRule.ps1"

# Chemin de la fonction de vÃ©rification
$checkFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "CheckFunctions\Check-InactiveLogins.ps1"

# ParamÃ¨tres de la rÃ¨gle
$params = @{
    RuleId = "SVR-007"
    Name = "InactiveLogins"
    Description = "DÃ©tecte les logins SQL qui n'ont pas Ã©tÃ© utilisÃ©s depuis plus de 90 jours"
    RuleType = "Server"
    Severity = "Moyenne"
    CheckFunctionPath = $checkFunctionPath
}

# Ajouter la rÃ¨gle
& $addRuleScriptPath @params -WhatIf

# Pour ajouter rÃ©ellement la rÃ¨gle, exÃ©cutez la commande suivante :
# & $addRuleScriptPath @params
