# Add-ImplicitPermissionsRule.ps1
# Ajoute une rÃƒÂ¨gle pour dÃƒÂ©tecter les comptes avec des permissions hÃƒÂ©ritÃƒÂ©es ou implicites

# Chemin du script d'ajout de rÃƒÂ¨gle
$addRuleScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\development\scripts\Add-SqlPermissionRule.ps1"

# Chemin de la fonction de vÃƒÂ©rification
$checkFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "CheckFunctions\Check-ImplicitPermissions.ps1"

# ParamÃƒÂ¨tres de la rÃƒÂ¨gle
$params = @{
    RuleId = "SVR-013"
    Name = "ImplicitPermissions"
    Description = "DÃƒÂ©tecte les comptes avec des permissions hÃƒÂ©ritÃƒÂ©es ou implicites"
    RuleType = "Server"
    Severity = "Moyenne"
    CheckFunctionPath = $checkFunctionPath
}

# Ajouter la rÃƒÂ¨gle
& $addRuleScriptPath @params -WhatIf

# Pour ajouter rÃƒÂ©ellement la rÃƒÂ¨gle, exÃƒÂ©cutez la commande suivante :
# & $addRuleScriptPath @params
