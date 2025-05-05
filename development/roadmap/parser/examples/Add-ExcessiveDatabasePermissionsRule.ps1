# Add-ExcessiveDatabasePermissionsRule.ps1
# Ajoute une rÃƒÂ¨gle pour dÃƒÂ©tecter les comptes avec des permissions excessives au niveau base de donnÃƒÂ©es

# Chemin du script d'ajout de rÃƒÂ¨gle
$addRuleScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\development\scripts\Add-SqlPermissionRule.ps1"

# Chemin de la fonction de vÃƒÂ©rification
$checkFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "CheckFunctions\Check-ExcessiveDatabasePermissions.ps1"

# ParamÃƒÂ¨tres de la rÃƒÂ¨gle
$params = @{
    RuleId = "DB-006"
    Name = "ExcessiveDatabasePermissions"
    Description = "DÃƒÂ©tecte les utilisateurs avec des permissions excessives au niveau base de donnÃƒÂ©es"
    RuleType = "Database"
    Severity = "Ãƒâ€°levÃƒÂ©e"
    CheckFunctionPath = $checkFunctionPath
}

# Ajouter la rÃƒÂ¨gle
& $addRuleScriptPath @params -WhatIf

# Pour ajouter rÃƒÂ©ellement la rÃƒÂ¨gle, exÃƒÂ©cutez la commande suivante :
# & $addRuleScriptPath @params
