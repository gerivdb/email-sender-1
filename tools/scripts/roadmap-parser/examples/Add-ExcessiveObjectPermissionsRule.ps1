﻿# Add-ExcessiveObjectPermissionsRule.ps1
# Ajoute une rÃ¨gle pour dÃ©tecter les comptes avec des permissions excessives au niveau objet

# Chemin du script d'ajout de rÃ¨gle
$addRuleScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\Add-SqlPermissionRule.ps1"

# Chemin de la fonction de vÃ©rification
$checkFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "CheckFunctions\Check-ExcessiveObjectPermissions.ps1"

# ParamÃ¨tres de la rÃ¨gle
$params = @{
    RuleId = "OBJ-005"
    Name = "ExcessiveObjectPermissions"
    Description = "DÃ©tecte les utilisateurs avec des permissions excessives au niveau objet"
    RuleType = "Object"
    Severity = "Ã‰levÃ©e"
    CheckFunctionPath = $checkFunctionPath
}

# Ajouter la rÃ¨gle
& $addRuleScriptPath @params -WhatIf

# Pour ajouter rÃ©ellement la rÃ¨gle, exÃ©cutez la commande suivante :
# & $addRuleScriptPath @params
