# Add-SensitiveObjectPermissionsRule.ps1
# Ajoute une règle pour détecter les comptes avec des permissions sur des objets sensibles

# Chemin du script d'ajout de règle
$addRuleScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\Add-SqlPermissionRule.ps1"

# Chemin de la fonction de vérification
$checkFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "CheckFunctions\Check-SensitiveObjectPermissions.ps1"

# Paramètres de la règle
$params = @{
    RuleId = "OBJ-006"
    Name = "SensitiveObjectPermissions"
    Description = "Détecte les utilisateurs avec des permissions sur des objets contenant des données sensibles"
    RuleType = "Object"
    Severity = "Élevée"
    CheckFunctionPath = $checkFunctionPath
}

# Ajouter la règle
& $addRuleScriptPath @params -WhatIf

# Pour ajouter réellement la règle, exécutez la commande suivante :
# & $addRuleScriptPath @params
