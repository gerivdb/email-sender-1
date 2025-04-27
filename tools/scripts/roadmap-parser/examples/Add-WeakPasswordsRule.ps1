# Add-WeakPasswordsRule.ps1
# Ajoute une règle pour détecter les comptes avec des mots de passe faibles

# Chemin du script d'ajout de règle
$addRuleScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\Add-SqlPermissionRule.ps1"

# Chemin de la fonction de vérification
$checkFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "CheckFunctions\Check-WeakPasswords.ps1"

# Paramètres de la règle
$params = @{
    RuleId = "SVR-010"
    Name = "WeakPasswords"
    Description = "Détecte les comptes SQL avec des configurations de mot de passe faibles"
    RuleType = "Server"
    Severity = "Élevée"
    CheckFunctionPath = $checkFunctionPath
}

# Ajouter la règle
& $addRuleScriptPath @params -WhatIf

# Pour ajouter réellement la règle, exécutez la commande suivante :
# & $addRuleScriptPath @params
