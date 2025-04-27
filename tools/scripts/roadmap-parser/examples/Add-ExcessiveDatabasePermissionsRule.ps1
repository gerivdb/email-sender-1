# Add-ExcessiveDatabasePermissionsRule.ps1
# Ajoute une règle pour détecter les comptes avec des permissions excessives au niveau base de données

# Chemin du script d'ajout de règle
$addRuleScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\Add-SqlPermissionRule.ps1"

# Chemin de la fonction de vérification
$checkFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "CheckFunctions\Check-ExcessiveDatabasePermissions.ps1"

# Paramètres de la règle
$params = @{
    RuleId = "DB-006"
    Name = "ExcessiveDatabasePermissions"
    Description = "Détecte les utilisateurs avec des permissions excessives au niveau base de données"
    RuleType = "Database"
    Severity = "Élevée"
    CheckFunctionPath = $checkFunctionPath
}

# Ajouter la règle
& $addRuleScriptPath @params -WhatIf

# Pour ajouter réellement la règle, exécutez la commande suivante :
# & $addRuleScriptPath @params
