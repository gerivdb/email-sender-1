# Add-ContradictoryPermissionsRule.ps1
# Ajoute une règle pour détecter les comptes avec des permissions contradictoires ou redondantes

# Chemin du script d'ajout de règle
$addRuleScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\Add-SqlPermissionRule.ps1"

# Chemin de la fonction de vérification
$checkFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "CheckFunctions\Check-ContradictoryPermissions.ps1"

# Paramètres de la règle
$params = @{
    RuleId = "SVR-011"
    Name = "ContradictoryPermissions"
    Description = "Détecte les comptes avec des permissions contradictoires ou redondantes"
    RuleType = "Server"
    Severity = "Moyenne"
    CheckFunctionPath = $checkFunctionPath
}

# Ajouter la règle
& $addRuleScriptPath @params -WhatIf

# Pour ajouter réellement la règle, exécutez la commande suivante :
# & $addRuleScriptPath @params
