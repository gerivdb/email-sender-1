# Add-InactiveLoginsRule.ps1
# Exemple d'ajout d'une nouvelle règle pour détecter les logins inactifs

# Chemin du script d'ajout de règle
$addRuleScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\Add-SqlPermissionRule.ps1"

# Chemin de la fonction de vérification
$checkFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "CheckFunctions\Check-InactiveLogins.ps1"

# Paramètres de la règle
$params = @{
    RuleId = "SVR-007"
    Name = "InactiveLogins"
    Description = "Détecte les logins SQL qui n'ont pas été utilisés depuis plus de 90 jours"
    RuleType = "Server"
    Severity = "Moyenne"
    CheckFunctionPath = $checkFunctionPath
}

# Ajouter la règle
& $addRuleScriptPath @params -WhatIf

# Pour ajouter réellement la règle, exécutez la commande suivante :
# & $addRuleScriptPath @params
