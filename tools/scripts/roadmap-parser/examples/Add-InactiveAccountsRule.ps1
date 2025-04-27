# Add-InactiveAccountsRule.ps1
# Ajoute une règle pour détecter les comptes inactifs

# Chemin du script d'ajout de règle
$addRuleScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\Add-SqlPermissionRule.ps1"

# Chemin de la fonction de vérification
$checkFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "CheckFunctions\Check-InactiveAccounts.ps1"

# Paramètres de la règle
$params = @{
    RuleId = "SVR-009"
    Name = "InactiveAccounts"
    Description = "Détecte les comptes SQL qui sont inactifs ou qui n'ont jamais été utilisés"
    RuleType = "Server"
    Severity = "Moyenne"
    CheckFunctionPath = $checkFunctionPath
}

# Ajouter la règle
& $addRuleScriptPath @params -WhatIf

# Pour ajouter réellement la règle, exécutez la commande suivante :
# & $addRuleScriptPath @params
