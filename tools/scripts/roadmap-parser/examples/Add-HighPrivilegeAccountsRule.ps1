# Add-HighPrivilegeAccountsRule.ps1
# Ajoute une règle pour détecter les comptes à privilèges élevés

# Chemin du script d'ajout de règle
$addRuleScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\Add-SqlPermissionRule.ps1"

# Chemin de la fonction de vérification
$checkFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "CheckFunctions\Check-HighPrivilegeAccounts.ps1"

# Paramètres de la règle
$params = @{
    RuleId = "SVR-008"
    Name = "HighPrivilegeAccountsExtended"
    Description = "Détecte les comptes avec des privilèges élevés ou des permissions équivalentes"
    RuleType = "Server"
    Severity = "Élevée"
    CheckFunctionPath = $checkFunctionPath
}

# Ajouter la règle
& $addRuleScriptPath @params -WhatIf

# Pour ajouter réellement la règle, exécutez la commande suivante :
# & $addRuleScriptPath @params
