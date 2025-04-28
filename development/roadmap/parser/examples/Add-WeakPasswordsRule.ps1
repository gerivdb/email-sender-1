# Add-WeakPasswordsRule.ps1
# Ajoute une rÃ¨gle pour dÃ©tecter les comptes avec des mots de passe faibles

# Chemin du script d'ajout de rÃ¨gle
$addRuleScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\development\scripts\Add-SqlPermissionRule.ps1"

# Chemin de la fonction de vÃ©rification
$checkFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "CheckFunctions\Check-WeakPasswords.ps1"

# ParamÃ¨tres de la rÃ¨gle
$params = @{
    RuleId = "SVR-010"
    Name = "WeakPasswords"
    Description = "DÃ©tecte les comptes SQL avec des configurations de mot de passe faibles"
    RuleType = "Server"
    Severity = "Ã‰levÃ©e"
    CheckFunctionPath = $checkFunctionPath
}

# Ajouter la rÃ¨gle
& $addRuleScriptPath @params -WhatIf

# Pour ajouter rÃ©ellement la rÃ¨gle, exÃ©cutez la commande suivante :
# & $addRuleScriptPath @params
