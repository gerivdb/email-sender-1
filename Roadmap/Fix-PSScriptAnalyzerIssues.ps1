# Script pour corriger automatiquement les problèmes courants détectés par PSScriptAnalyzer
# Ce script analyse les fichiers PowerShell et corrige automatiquement les problèmes courants

param (
    [Parameter(Mandatory = $false)]
    [string]$Path = ".",
    [Parameter(Mandatory = $false)]
    [string[]]$Include = @("*.ps1"),
    [Parameter(Mandatory = $false)]
    [switch]$Recurse,
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# Vérifier si le module PSScriptAnalyzer est installé
if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Write-Host "Le module PSScriptAnalyzer n'est pas installé. Installation en cours..." -ForegroundColor Yellow
    Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
}

# Importer le module PSScriptAnalyzer
Import-Module PSScriptAnalyzer

# Fonction pour corriger les problèmes de comparaison avec $null
function Fix-NullComparison {
    param (
        [string]$Content
    )
    
    # Remplacer les comparaisons incorrectes avec $null
    $pattern = '(\$\w+)\s+-(?:eq|ne)\s+\$null'
    $replacement = '$null -$2 $1'
    $newContent = $Content -replace $pattern, $replacement
    
    return $newContent
}

# Fonction pour corriger les verbes non approuvés
function Fix-UnapprovedVerbs {
    param (
        [string]$Content
    )
    
    # Dictionnaire de correspondance entre verbes non approuvés et verbes approuvés
    $verbMapping = @{
        'Parse' = 'Get'
        'Format' = 'Format'
        'Create' = 'New'
        'Delete' = 'Remove'
        'Check' = 'Test'
        'Verify' = 'Test'
        'Print' = 'Write'
        'Display' = 'Show'
        'Execute' = 'Invoke'
        'Run' = 'Invoke'
        'Launch' = 'Start'
        'Kill' = 'Stop'
        'Terminate' = 'Stop'
        'Modify' = 'Set'
        'Change' = 'Set'
        'Update' = 'Set'
        'Alter' = 'Set'
        'Find' = 'Find'
        'Search' = 'Find'
        'Locate' = 'Find'
        'List' = 'Get'
        'Enumerate' = 'Get'
        'Query' = 'Get'
        'Fetch' = 'Get'
        'Retrieve' = 'Get'
        'Load' = 'Import'
        'Save' = 'Export'
        'Store' = 'Export'
        'Dump' = 'Export'
        'Backup' = 'Backup'
        'Restore' = 'Restore'
        'Copy' = 'Copy'
        'Move' = 'Move'
        'Rename' = 'Rename'
        'Convert' = 'ConvertTo'
        'Transform' = 'ConvertTo'
        'Translate' = 'ConvertTo'
        'Map' = 'ConvertTo'
        'Join' = 'Join'
        'Split' = 'Split'
        'Merge' = 'Merge'
        'Combine' = 'Merge'
        'Compare' = 'Compare'
        'Diff' = 'Compare'
        'Sort' = 'Sort'
        'Order' = 'Sort'
        'Group' = 'Group'
        'Categorize' = 'Group'
        'Filter' = 'Where'
        'Select' = 'Select'
        'Choose' = 'Select'
        'Pick' = 'Select'
        'Exclude' = 'Exclude'
        'Omit' = 'Exclude'
        'Skip' = 'Exclude'
        'Include' = 'Include'
        'Add' = 'Add'
        'Append' = 'Add'
        'Insert' = 'Add'
        'Remove' = 'Remove'
        'Delete' = 'Remove'
        'Erase' = 'Remove'
        'Clear' = 'Clear'
        'Reset' = 'Reset'
        'Initialize' = 'Initialize'
        'Setup' = 'Initialize'
        'Configure' = 'Set'
        'Enable' = 'Enable'
        'Disable' = 'Disable'
        'Start' = 'Start'
        'Begin' = 'Start'
        'Stop' = 'Stop'
        'End' = 'Stop'
        'Pause' = 'Suspend'
        'Resume' = 'Resume'
        'Continue' = 'Resume'
        'Wait' = 'Wait'
        'Sleep' = 'Wait'
        'Delay' = 'Wait'
        'Connect' = 'Connect'
        'Disconnect' = 'Disconnect'
        'Open' = 'Open'
        'Close' = 'Close'
        'Read' = 'Read'
        'Write' = 'Write'
        'Send' = 'Send'
        'Receive' = 'Receive'
        'Get' = 'Get'
        'Set' = 'Set'
        'New' = 'New'
        'Test' = 'Test'
        'Invoke' = 'Invoke'
        'Show' = 'Show'
        'Hide' = 'Hide'
        'Watch' = 'Watch'
        'Monitor' = 'Watch'
        'Observe' = 'Watch'
        'Measure' = 'Measure'
        'Ping' = 'Test'
        'Trace' = 'Trace'
        'Debug' = 'Debug'
        'Log' = 'Write'
        'Record' = 'Write'
        'Register' = 'Register'
        'Unregister' = 'Unregister'
        'Install' = 'Install'
        'Uninstall' = 'Uninstall'
        'Deploy' = 'Deploy'
        'Undeploy' = 'Undeploy'
        'Publish' = 'Publish'
        'Unpublish' = 'Unpublish'
        'Submit' = 'Submit'
        'Approve' = 'Approve'
        'Reject' = 'Deny'
        'Deny' = 'Deny'
        'Block' = 'Block'
        'Unblock' = 'Unblock'
        'Lock' = 'Lock'
        'Unlock' = 'Unlock'
        'Protect' = 'Protect'
        'Unprotect' = 'Unprotect'
        'Encrypt' = 'Protect'
        'Decrypt' = 'Unprotect'
        'Sign' = 'Sign'
        'Verify' = 'Test'
        'Validate' = 'Test'
        'Confirm' = 'Confirm'
        'Deny' = 'Deny'
        'Grant' = 'Grant'
        'Revoke' = 'Revoke'
        'Trust' = 'Approve'
        'Distrust' = 'Deny'
        'Mount' = 'Mount'
        'Dismount' = 'Dismount'
        'Attach' = 'Mount'
        'Detach' = 'Dismount'
        'Bind' = 'Mount'
        'Unbind' = 'Dismount'
        'Enter' = 'Enter'
        'Exit' = 'Exit'
        'Push' = 'Push'
        'Pop' = 'Pop'
        'Undo' = 'Undo'
        'Redo' = 'Redo'
        'Repair' = 'Repair'
        'Fix' = 'Repair'
        'Optimize' = 'Optimize'
        'Compress' = 'Compress'
        'Expand' = 'Expand'
        'Zip' = 'Compress'
        'Unzip' = 'Expand'
        'Pack' = 'Compress'
        'Unpack' = 'Expand'
        'Archive' = 'Compress'
        'Unarchive' = 'Expand'
        'Backup' = 'Backup'
        'Restore' = 'Restore'
        'Import' = 'Import'
        'Export' = 'Export'
        'Sync' = 'Sync'
        'Synchronize' = 'Sync'
        'Update' = 'Update'
        'Upgrade' = 'Update'
        'Downgrade' = 'Update'
        'Patch' = 'Update'
        'Refresh' = 'Update'
        'Reload' = 'Update'
    }
    
    # Remplacer les fonctions avec des verbes non approuvés
    $pattern = 'function\s+(\w+)-(\w+)'
    $newContent = $Content
    
    $matches = [regex]::Matches($Content, $pattern)
    foreach ($match in $matches) {
        $verb = $match.Groups[1].Value
        $noun = $match.Groups[2].Value
        
        if ($verbMapping.ContainsKey($verb) -and $verbMapping[$verb] -ne $verb) {
            $approvedVerb = $verbMapping[$verb]
            $oldFunctionName = "$verb-$noun"
            $newFunctionName = "$approvedVerb-$noun"
            
            # Remplacer la définition de la fonction
            $newContent = $newContent -replace "function\s+$oldFunctionName", "function $newFunctionName"
            
            # Remplacer les appels à la fonction
            $newContent = $newContent -replace "(?<!\w)$oldFunctionName(?!\w)", $newFunctionName
        }
    }
    
    return $newContent
}

# Fonction pour corriger les paramètres switch avec valeur par défaut
function Fix-SwitchDefaultValue {
    param (
        [string]$Content
    )
    
    # Remplacer les paramètres switch avec valeur par défaut
    $pattern = '(\[switch\])\$(\w+)\s*=\s*\$true'
    $replacement = '$1$$$2'
    $newContent = $Content -replace $pattern, $replacement
    
    # Ajouter une vérification pour définir la valeur par défaut
    $matches = [regex]::Matches($Content, $pattern)
    foreach ($match in $matches) {
        $paramName = $match.Groups[2].Value
        $checkCode = "    # Définir la valeur par défaut pour $paramName`n    if (-not `$PSBoundParameters.ContainsKey('$paramName')) {`n        `$$paramName = `$true`n    }"
        
        # Trouver la fin du bloc param
        $paramEndPattern = "param\s*\([^)]*\)\s*"
        $paramEndMatch = [regex]::Match($Content, $paramEndPattern)
        if ($paramEndMatch.Success) {
            $insertPosition = $paramEndMatch.Index + $paramEndMatch.Length
            $newContent = $newContent.Insert($insertPosition, "`n$checkCode`n")
        }
    }
    
    return $newContent
}

# Fonction pour corriger les variables déclarées mais non utilisées
function Fix-UnusedVariables {
    param (
        [string]$Content
    )
    
    # Remplacer les variables déclarées mais non utilisées
    $pattern = '(\$\w+)\s*=\s*([^;]+)(?:;|\r?\n)'
    $matches = [regex]::Matches($Content, $pattern)
    
    $newContent = $Content
    foreach ($match in $matches) {
        $varName = $match.Groups[1].Value
        $varValue = $match.Groups[2].Value.Trim()
        
        # Vérifier si la variable est utilisée ailleurs dans le code
        $varUsagePattern = "(?<!\w)$([regex]::Escape($varName))(?!\w)"
        $varUsageMatches = [regex]::Matches($Content, $varUsagePattern)
        
        if ($varUsageMatches.Count -eq 1) {
            # La variable n'est utilisée qu'une seule fois (lors de sa déclaration)
            # Remplacer par $null = expression pour supprimer l'avertissement
            $newContent = $newContent -replace [regex]::Escape($match.Value), "`$null = $varValue`n"
        }
    }
    
    return $newContent
}

# Fonction pour corriger tous les problèmes dans un fichier
function Fix-PSScriptAnalyzerIssues {
    param (
        [string]$FilePath,
        [switch]$WhatIf
    )
    
    Write-Host "Analyse du fichier: $FilePath" -ForegroundColor Cyan
    
    # Analyser le fichier avec PSScriptAnalyzer
    $issues = Invoke-ScriptAnalyzer -Path $FilePath
    
    if ($issues.Count -eq 0) {
        Write-Host "  Aucun problème détecté." -ForegroundColor Green
        return
    }
    
    Write-Host "  $($issues.Count) problèmes détectés." -ForegroundColor Yellow
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Raw
    $originalContent = $content
    
    # Corriger les problèmes
    $issueTypes = $issues | Group-Object -Property RuleName
    
    foreach ($issueType in $issueTypes) {
        $ruleName = $issueType.Name
        $count = $issueType.Count
        
        Write-Host "  Correction de $count problèmes de type '$ruleName'..." -ForegroundColor Yellow
        
        switch ($ruleName) {
            "PSPossibleIncorrectComparisonWithNull" {
                $content = Fix-NullComparison -Content $content
            }
            "PSUseApprovedVerbs" {
                $content = Fix-UnapprovedVerbs -Content $content
            }
            "PSAvoidDefaultValueSwitchParameter" {
                $content = Fix-SwitchDefaultValue -Content $content
            }
            "PSUseDeclaredVarsMoreThanAssignments" {
                $content = Fix-UnusedVariables -Content $content
            }
            default {
                Write-Host "    Le type de problème '$ruleName' n'est pas pris en charge pour la correction automatique." -ForegroundColor Yellow
            }
        }
    }
    
    # Vérifier si le contenu a été modifié
    if ($content -ne $originalContent) {
        if ($WhatIf) {
            Write-Host "  Le fichier serait modifié (WhatIf)." -ForegroundColor Yellow
        }
        else {
            # Enregistrer les modifications
            Set-Content -Path $FilePath -Value $content -Encoding UTF8
            Write-Host "  Le fichier a été modifié." -ForegroundColor Green
            
            # Vérifier si des problèmes subsistent
            $remainingIssues = Invoke-ScriptAnalyzer -Path $FilePath
            if ($remainingIssues.Count -gt 0) {
                Write-Host "  $($remainingIssues.Count) problèmes subsistent après correction." -ForegroundColor Yellow
            }
            else {
                Write-Host "  Tous les problèmes ont été corrigés." -ForegroundColor Green
            }
        }
    }
    else {
        Write-Host "  Aucune modification n'a été apportée au fichier." -ForegroundColor Yellow
    }
}

# Fonction principale
function Start-PSScriptAnalyzerFix {
    # Obtenir la liste des fichiers à analyser
    $files = Get-ChildItem -Path $Path -Include $Include -Recurse:$Recurse -File
    
    Write-Host "Analyse de $($files.Count) fichiers..." -ForegroundColor Cyan
    
    foreach ($file in $files) {
        Fix-PSScriptAnalyzerIssues -FilePath $file.FullName -WhatIf:$WhatIf
    }
    
    Write-Host "Analyse terminée." -ForegroundColor Green
}

# Démarrer l'analyse
Start-PSScriptAnalyzerFix
