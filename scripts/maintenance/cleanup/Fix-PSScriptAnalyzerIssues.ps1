# Script pour corriger automatiquement les problÃ¨mes courants dÃ©tectÃ©s par PSScriptAnalyzer
# Ce script analyse les fichiers PowerShell et corrige automatiquement les problÃ¨mes courants


# Script pour corriger automatiquement les problÃ¨mes courants dÃ©tectÃ©s par PSScriptAnalyzer
# Ce script analyse les fichiers PowerShell et corrige automatiquement les problÃ¨mes courants

param (
    [Parameter(Mandatory = $false)

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal
]
    [string]$Path = ".",
    [Parameter(Mandatory = $false)]
    [string[]]$Include = @("*.ps1"),
    [Parameter(Mandatory = $false)]
    [switch]$Recurse,
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# VÃ©rifier si le module PSScriptAnalyzer est installÃ©
if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Write-Host "Le module PSScriptAnalyzer n'est pas installÃ©. Installation en cours..." -ForegroundColor Yellow
    Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
}

# Importer le module PSScriptAnalyzer
Import-Module PSScriptAnalyzer

# Fonction pour corriger les problÃ¨mes de comparaison avec $null
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

# Fonction pour corriger les verbes non approuvÃ©s
function Fix-UnapprovedVerbs {
    param (
        [string]$Content
    )
    
    # Dictionnaire de correspondance entre verbes non approuvÃ©s et verbes approuvÃ©s
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
    
    # Remplacer les fonctions avec des verbes non approuvÃ©s
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
            
            # Remplacer la dÃ©finition de la fonction
            $newContent = $newContent -replace "function\s+$oldFunctionName", "function $newFunctionName"
            
            # Remplacer les appels Ã  la fonction
            $newContent = $newContent -replace "(?<!\w)$oldFunctionName(?!\w)", $newFunctionName
        }
    }
    
    return $newContent
}

# Fonction pour corriger les paramÃ¨tres switch avec valeur par dÃ©faut
function Fix-SwitchDefaultValue {
    param (
        [string]$Content
    )
    
    # Remplacer les paramÃ¨tres switch avec valeur par dÃ©faut
    $pattern = '(\[switch\])\$(\w+)\s*=\s*\$true'
    $replacement = '$1$$$2'
    $newContent = $Content -replace $pattern, $replacement
    
    # Ajouter une vÃ©rification pour dÃ©finir la valeur par dÃ©faut
    $matches = [regex]::Matches($Content, $pattern)
    foreach ($match in $matches) {
        $paramName = $match.Groups[2].Value
        $checkCode = "    # DÃ©finir la valeur par dÃ©faut pour $paramName`n    if (-not `$PSBoundParameters.ContainsKey('$paramName')) {`n        `$$paramName = `$true`n    }"
        
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

# Fonction pour corriger les variables dÃ©clarÃ©es mais non utilisÃ©es
function Fix-UnusedVariables {
    param (
        [string]$Content
    )
    
    # Remplacer les variables dÃ©clarÃ©es mais non utilisÃ©es
    $pattern = '(\$\w+)\s*=\s*([^;]+)(?:;|\r?\n)'
    $matches = [regex]::Matches($Content, $pattern)
    
    $newContent = $Content
    foreach ($match in $matches) {
        $varName = $match.Groups[1].Value
        $varValue = $match.Groups[2].Value.Trim()
        
        # VÃ©rifier si la variable est utilisÃ©e ailleurs dans le code
        $varUsagePattern = "(?<!\w)$([regex]::Escape($varName))(?!\w)"
        $varUsageMatches = [regex]::Matches($Content, $varUsagePattern)
        
        if ($varUsageMatches.Count -eq 1) {
            # La variable n'est utilisÃ©e qu'une seule fois (lors de sa dÃ©claration)
            # Remplacer par $null = expression pour supprimer l'avertissement
            $newContent = $newContent -replace [regex]::Escape($match.Value), "`$null = $varValue`n"
        }
    }
    
    return $newContent
}

# Fonction pour corriger tous les problÃ¨mes dans un fichier
function Fix-PSScriptAnalyzerIssues {
    param (
        [string]$FilePath,
        [switch]$WhatIf
    )
    
    Write-Host "Analyse du fichier: $FilePath" -ForegroundColor Cyan
    
    # Analyser le fichier avec PSScriptAnalyzer
    $issues = Invoke-ScriptAnalyzer -Path $FilePath
    
    if ($issues.Count -eq 0) {
        Write-Host "  Aucun problÃ¨me dÃ©tectÃ©." -ForegroundColor Green
        return
    }
    
    Write-Host "  $($issues.Count) problÃ¨mes dÃ©tectÃ©s." -ForegroundColor Yellow
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Raw
    $originalContent = $content
    
    # Corriger les problÃ¨mes
    $issueTypes = $issues | Group-Object -Property RuleName
    
    foreach ($issueType in $issueTypes) {
        $ruleName = $issueType.Name
        $count = $issueType.Count
        
        Write-Host "  Correction de $count problÃ¨mes de type '$ruleName'..." -ForegroundColor Yellow
        
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
                Write-Host "    Le type de problÃ¨me '$ruleName' n'est pas pris en charge pour la correction automatique." -ForegroundColor Yellow
            }
        }
    }
    
    # VÃ©rifier si le contenu a Ã©tÃ© modifiÃ©
    if ($content -ne $originalContent) {
        if ($WhatIf) {
            Write-Host "  Le fichier serait modifiÃ© (WhatIf)." -ForegroundColor Yellow
        }
        else {
            # Enregistrer les modifications
            Set-Content -Path $FilePath -Value $content -Encoding UTF8
            Write-Host "  Le fichier a Ã©tÃ© modifiÃ©." -ForegroundColor Green
            
            # VÃ©rifier si des problÃ¨mes subsistent
            $remainingIssues = Invoke-ScriptAnalyzer -Path $FilePath
            if ($remainingIssues.Count -gt 0) {
                Write-Host "  $($remainingIssues.Count) problÃ¨mes subsistent aprÃ¨s correction." -ForegroundColor Yellow
            }
            else {
                Write-Host "  Tous les problÃ¨mes ont Ã©tÃ© corrigÃ©s." -ForegroundColor Green
            }
        }
    }
    else {
        Write-Host "  Aucune modification n'a Ã©tÃ© apportÃ©e au fichier." -ForegroundColor Yellow
    }
}

# Fonction principale
function Start-PSScriptAnalyzerFix {
    # Obtenir la liste des fichiers Ã  analyser
    $files = Get-ChildItem -Path $Path -Include $Include -Recurse:$Recurse -File
    
    Write-Host "Analyse de $($files.Count) fichiers..." -ForegroundColor Cyan
    
    foreach ($file in $files) {
        Fix-PSScriptAnalyzerIssues -FilePath $file.FullName -WhatIf:$WhatIf
    }
    
    Write-Host "Analyse terminÃ©e." -ForegroundColor Green
}

# DÃ©marrer l'analyse
Start-PSScriptAnalyzerFix

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
