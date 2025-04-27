# Add-CrossDatabasePermissionsRule.ps1
# Ajoute une rÃ¨gle pour dÃ©tecter les comptes avec des permissions sur plusieurs bases de donnÃ©es

# Chemin du script d'ajout de rÃ¨gle
$addRuleScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\Add-SqlPermissionRule.ps1"

# Chemin de la fonction de vÃ©rification
$checkFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "CheckFunctions\Check-CrossDatabasePermissions.ps1"

# ParamÃ¨tres de la rÃ¨gle
$params = @{
    RuleId = "SVR-012"
    Name = "CrossDatabasePermissions"
    Description = "DÃ©tecte les comptes avec des permissions sur plusieurs bases de donnÃ©es"
    RuleType = "Server"
    Severity = "Moyenne"
    CheckFunctionPath = $checkFunctionPath
}

# Ajouter la rÃ¨gle
& $addRuleScriptPath @params -WhatIf

# Pour ajouter rÃ©ellement la rÃ¨gle, exÃ©cutez la commande suivante :
# & $addRuleScriptPath @params
