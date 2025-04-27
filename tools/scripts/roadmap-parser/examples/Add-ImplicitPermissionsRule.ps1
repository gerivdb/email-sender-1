# Add-ImplicitPermissionsRule.ps1
# Ajoute une règle pour détecter les comptes avec des permissions héritées ou implicites

# Chemin du script d'ajout de règle
$addRuleScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\Add-SqlPermissionRule.ps1"

# Chemin de la fonction de vérification
$checkFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "CheckFunctions\Check-ImplicitPermissions.ps1"

# Paramètres de la règle
$params = @{
    RuleId = "SVR-013"
    Name = "ImplicitPermissions"
    Description = "Détecte les comptes avec des permissions héritées ou implicites"
    RuleType = "Server"
    Severity = "Moyenne"
    CheckFunctionPath = $checkFunctionPath
}

# Ajouter la règle
& $addRuleScriptPath @params -WhatIf

# Pour ajouter réellement la règle, exécutez la commande suivante :
# & $addRuleScriptPath @params
