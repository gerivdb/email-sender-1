# Add-WeakPasswordsRule.ps1
# Ajoute une rÃƒÂ¨gle pour dÃƒÂ©tecter les comptes avec des mots de passe faibles

# Chemin du script d'ajout de rÃƒÂ¨gle
$addRuleScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\development\scripts\Add-SqlPermissionRule.ps1"

# Chemin de la fonction de vÃƒÂ©rification
$checkFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "CheckFunctions\Check-WeakPasswords.ps1"

# ParamÃƒÂ¨tres de la rÃƒÂ¨gle
$params = @{
    RuleId = "SVR-010"
    Name = "WeakPasswords"
    Description = "DÃƒÂ©tecte les comptes SQL avec des configurations de mot de passe faibles"
    RuleType = "Server"
    Severity = "Ãƒâ€°levÃƒÂ©e"
    CheckFunctionPath = $checkFunctionPath
}

# Ajouter la rÃƒÂ¨gle
& $addRuleScriptPath @params -WhatIf

# Pour ajouter rÃƒÂ©ellement la rÃƒÂ¨gle, exÃƒÂ©cutez la commande suivante :
# & $addRuleScriptPath @params
