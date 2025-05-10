# Get-GitBranchingConventions.ps1
# Script pour établir les conventions de nommage des branches Git
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$AsObject,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Info", "Debug", "None")]
    [string]$LogLevel = "Info"
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$rootPath = Split-Path -Parent $parentPath
$utilsPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $rootPath)) -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        if ($LogLevel -eq "None") {
            return
        }
        
        $logLevels = @{
            "Error" = 0
            "Warning" = 1
            "Info" = 2
            "Debug" = 3
        }
        
        if ($logLevels[$Level] -le $logLevels[$LogLevel]) {
            $color = switch ($Level) {
                "Error" { "Red" }
                "Warning" { "Yellow" }
                "Info" { "White" }
                "Debug" { "Gray" }
                default { "White" }
            }
            
            Write-Host "[$Level] $Message" -ForegroundColor $color
        }
    }
}

# Fonction pour obtenir les conventions de nommage des branches
function Get-GitBranchingConventions {
    [CmdletBinding()]
    param()
    
    $conventions = @{
        # Branches principales
        main_branches = @{
            main = @{
                description = "Branche principale contenant le code de production stable"
                pattern = "^main$"
                protected = $true
                require_pull_request = $true
                require_approvals = 1
                allow_direct_push = $false
                auto_delete = $false
            }
            development = @{
                description = "Branche de développement pour l'intégration continue"
                pattern = "^(dev|develop|development)$"
                protected = $true
                require_pull_request = $true
                require_approvals = 1
                allow_direct_push = $false
                auto_delete = $false
            }
        }
        
        # Branches de fonctionnalités
        feature_branches = @{
            description = "Branches pour le développement de nouvelles fonctionnalités"
            pattern = "^feature/([a-z0-9]+(?:-[a-z0-9]+)*)$"
            examples = @(
                "feature/add-visualization-export",
                "feature/improve-search-performance",
                "feature/user-dashboard"
            )
            base_branch = "development"
            naming_rules = @{
                prefix = "feature/"
                body = @{
                    pattern = "^[a-z0-9]+(?:-[a-z0-9]+)*$"
                    description = "Utiliser des minuscules, des chiffres et des tirets uniquement"
                    max_length = 50
                }
            }
            lifecycle = @{
                creation = "git checkout -b feature/name development"
                updates = "git pull origin development"
                completion = "Pull request vers development"
                cleanup = "Suppression automatique après fusion"
            }
            allow_direct_push = $true
            auto_delete = $true
        }
        
        # Branches de correction de bugs
        bugfix_branches = @{
            description = "Branches pour la correction de bugs"
            pattern = "^bugfix/([a-z0-9]+(?:-[a-z0-9]+)*)$"
            examples = @(
                "bugfix/fix-search-crash",
                "bugfix/correct-visualization-colors",
                "bugfix/resolve-data-mapping-issue"
            )
            base_branch = "development"
            naming_rules = @{
                prefix = "bugfix/"
                body = @{
                    pattern = "^[a-z0-9]+(?:-[a-z0-9]+)*$"
                    description = "Utiliser des minuscules, des chiffres et des tirets uniquement"
                    max_length = 50
                }
            }
            lifecycle = @{
                creation = "git checkout -b bugfix/name development"
                updates = "git pull origin development"
                completion = "Pull request vers development"
                cleanup = "Suppression automatique après fusion"
            }
            allow_direct_push = $true
            auto_delete = $true
        }
        
        # Branches de version
        release_branches = @{
            description = "Branches pour la préparation des versions"
            pattern = "^release/v(\d+\.\d+\.\d+)$"
            examples = @(
                "release/v1.0.0",
                "release/v1.2.3",
                "release/v2.0.0"
            )
            base_branch = "development"
            naming_rules = @{
                prefix = "release/v"
                body = @{
                    pattern = "^\d+\.\d+\.\d+$"
                    description = "Utiliser le format de versionnage sémantique (MAJOR.MINOR.PATCH)"
                }
            }
            lifecycle = @{
                creation = "git checkout -b release/vX.Y.Z development"
                updates = "Corrections de bugs uniquement, pas de nouvelles fonctionnalités"
                completion = "Pull request vers main et development"
                cleanup = "Suppression après fusion et création de tag"
            }
            allow_direct_push = $true
            auto_delete = $true
        }
        
        # Branches de correctif urgent
        hotfix_branches = @{
            description = "Branches pour les corrections urgentes en production"
            pattern = "^hotfix/([a-z0-9]+(?:-[a-z0-9]+)*)$"
            examples = @(
                "hotfix/critical-security-fix",
                "hotfix/fix-production-crash",
                "hotfix/resolve-data-loss-issue"
            )
            base_branch = "main"
            naming_rules = @{
                prefix = "hotfix/"
                body = @{
                    pattern = "^[a-z0-9]+(?:-[a-z0-9]+)*$"
                    description = "Utiliser des minuscules, des chiffres et des tirets uniquement"
                    max_length = 50
                }
            }
            lifecycle = @{
                creation = "git checkout -b hotfix/name main"
                updates = "Corrections minimales uniquement"
                completion = "Pull request vers main et development"
                cleanup = "Suppression après fusion et création de tag"
            }
            allow_direct_push = $true
            auto_delete = $true
        }
        
        # Branches de documentation
        docs_branches = @{
            description = "Branches pour les mises à jour de documentation"
            pattern = "^docs/([a-z0-9]+(?:-[a-z0-9]+)*)$"
            examples = @(
                "docs/update-readme",
                "docs/add-api-documentation",
                "docs/improve-user-guide"
            )
            base_branch = "development"
            naming_rules = @{
                prefix = "docs/"
                body = @{
                    pattern = "^[a-z0-9]+(?:-[a-z0-9]+)*$"
                    description = "Utiliser des minuscules, des chiffres et des tirets uniquement"
                    max_length = 50
                }
            }
            lifecycle = @{
                creation = "git checkout -b docs/name development"
                updates = "git pull origin development"
                completion = "Pull request vers development"
                cleanup = "Suppression automatique après fusion"
            }
            allow_direct_push = $true
            auto_delete = $true
        }
        
        # Branches de refactoring
        refactor_branches = @{
            description = "Branches pour le refactoring du code"
            pattern = "^refactor/([a-z0-9]+(?:-[a-z0-9]+)*)$"
            examples = @(
                "refactor/improve-code-structure",
                "refactor/optimize-performance",
                "refactor/clean-up-technical-debt"
            )
            base_branch = "development"
            naming_rules = @{
                prefix = "refactor/"
                body = @{
                    pattern = "^[a-z0-9]+(?:-[a-z0-9]+)*$"
                    description = "Utiliser des minuscules, des chiffres et des tirets uniquement"
                    max_length = 50
                }
            }
            lifecycle = @{
                creation = "git checkout -b refactor/name development"
                updates = "git pull origin development"
                completion = "Pull request vers development"
                cleanup = "Suppression automatique après fusion"
            }
            allow_direct_push = $true
            auto_delete = $true
        }
        
        # Branches de test
        test_branches = @{
            description = "Branches pour l'ajout ou la mise à jour de tests"
            pattern = "^test/([a-z0-9]+(?:-[a-z0-9]+)*)$"
            examples = @(
                "test/add-unit-tests",
                "test/improve-integration-tests",
                "test/fix-flaky-tests"
            )
            base_branch = "development"
            naming_rules = @{
                prefix = "test/"
                body = @{
                    pattern = "^[a-z0-9]+(?:-[a-z0-9]+)*$"
                    description = "Utiliser des minuscules, des chiffres et des tirets uniquement"
                    max_length = 50
                }
            }
            lifecycle = @{
                creation = "git checkout -b test/name development"
                updates = "git pull origin development"
                completion = "Pull request vers development"
                cleanup = "Suppression automatique après fusion"
            }
            allow_direct_push = $true
            auto_delete = $true
        }
        
        # Branches expérimentales
        experimental_branches = @{
            description = "Branches pour les expérimentations"
            pattern = "^experimental/([a-z0-9]+(?:-[a-z0-9]+)*)$"
            examples = @(
                "experimental/new-visualization-technique",
                "experimental/ai-powered-search",
                "experimental/alternative-ui"
            )
            base_branch = "development"
            naming_rules = @{
                prefix = "experimental/"
                body = @{
                    pattern = "^[a-z0-9]+(?:-[a-z0-9]+)*$"
                    description = "Utiliser des minuscules, des chiffres et des tirets uniquement"
                    max_length = 50
                }
            }
            lifecycle = @{
                creation = "git checkout -b experimental/name development"
                updates = "git pull origin development"
                completion = "Pull request vers development ou abandon"
                cleanup = "Suppression manuelle"
            }
            allow_direct_push = $true
            auto_delete = $false
        }
        
        # Règles générales
        general_rules = @{
            max_branch_name_length = 80
            forbidden_characters = @("<", ">", ":", "\"", "/", "\\", "|", "?", "*", " ")
            reserved_names = @("HEAD", "master", "origin")
            branch_description = @{
                required = $true
                format = "Issue: #{issue_number} - {description}"
                max_length = 100
            }
            branch_lifetime = @{
                feature = "2 weeks"
                bugfix = "1 week"
                release = "1 week"
                hotfix = "3 days"
                docs = "1 week"
                refactor = "1 week"
                test = "1 week"
                experimental = "1 month"
            }
        }
        
        # Workflow de branchement
        workflow = @{
            feature_development = @{
                steps = @(
                    "Créer une branche feature/ à partir de development",
                    "Développer et tester les changements",
                    "Créer une pull request vers development",
                    "Revue de code et approbation",
                    "Fusion dans development"
                )
            }
            bugfix = @{
                steps = @(
                    "Créer une branche bugfix/ à partir de development",
                    "Corriger et tester le bug",
                    "Créer une pull request vers development",
                    "Revue de code et approbation",
                    "Fusion dans development"
                )
            }
            release = @{
                steps = @(
                    "Créer une branche release/ à partir de development",
                    "Finaliser et tester",
                    "Créer une pull request vers main",
                    "Revue de code et approbation",
                    "Fusion dans main",
                    "Créer un tag de version",
                    "Fusion dans development"
                )
            }
            hotfix = @{
                steps = @(
                    "Créer une branche hotfix/ à partir de main",
                    "Corriger et tester",
                    "Créer une pull request vers main",
                    "Revue de code et approbation",
                    "Fusion dans main",
                    "Créer un tag de version hotfix",
                    "Fusion dans development"
                )
            }
        }
        
        # Validation des noms de branches
        validation = @{
            script_path = "scripts/hooks/validate-branch-name.ps1"
            error_message = "Le nom de la branche ne respecte pas les conventions. Veuillez utiliser le format approprié."
            hook = "pre-push"
        }
    }
    
    return $conventions
}

# Fonction pour générer un script de validation de nom de branche
function Get-BranchValidationScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Conventions
    )
    
    $script = @"
#!/usr/bin/env pwsh
# validate-branch-name.ps1
# Script pour valider les noms de branches selon les conventions
# Version: 1.0
# Date: $(Get-Date -Format "yyyy-MM-dd")

# Obtenir le nom de la branche actuelle
`$currentBranch = git rev-parse --abbrev-ref HEAD

# Définir les patterns de validation
`$patterns = @{
"@
    
    # Ajouter les patterns pour chaque type de branche
    foreach ($branchType in @("main_branches", "feature_branches", "bugfix_branches", "release_branches", "hotfix_branches", "docs_branches", "refactor_branches", "test_branches", "experimental_branches")) {
        if ($Conventions.ContainsKey($branchType)) {
            $branch = $Conventions[$branchType]
            if ($branch.ContainsKey("pattern")) {
                $script += "`n    '$branchType' = '$($branch.pattern)'"
            }
        }
    }
    
    $script += @"
}

# Vérifier si le nom de la branche correspond à l'un des patterns
`$isValid = `$false
foreach (`$pattern in `$patterns.Values) {
    if (`$currentBranch -match `$pattern) {
        `$isValid = `$true
        break
    }
}

# Vérifier la longueur du nom de la branche
`$maxLength = $($Conventions.general_rules.max_branch_name_length)
if (`$currentBranch.Length -gt `$maxLength) {
    Write-Host "Erreur: Le nom de la branche est trop long (maximum $($Conventions.general_rules.max_branch_name_length) caractères)" -ForegroundColor Red
    exit 1
}

# Vérifier les caractères interdits
`$forbiddenChars = @($($Conventions.general_rules.forbidden_characters | ForEach-Object { "'$_'" } | Join-String -Separator ", "))
foreach (`$char in `$forbiddenChars) {
    if (`$currentBranch.Contains(`$char)) {
        Write-Host "Erreur: Le nom de la branche contient un caractère interdit: `$char" -ForegroundColor Red
        exit 1
    }
}

# Vérifier les noms réservés
`$reservedNames = @($($Conventions.general_rules.reserved_names | ForEach-Object { "'$_'" } | Join-String -Separator ", "))
if (`$reservedNames -contains `$currentBranch) {
    Write-Host "Erreur: Le nom de la branche est réservé" -ForegroundColor Red
    exit 1
}

# Afficher le résultat
if (-not `$isValid) {
    Write-Host "$($Conventions.validation.error_message)" -ForegroundColor Red
    Write-Host "Formats valides:" -ForegroundColor Yellow
"@
    
    # Ajouter des exemples pour chaque type de branche
    foreach ($branchType in @("feature_branches", "bugfix_branches", "release_branches", "hotfix_branches", "docs_branches", "refactor_branches", "test_branches", "experimental_branches")) {
        if ($Conventions.ContainsKey($branchType) -and $Conventions[$branchType].ContainsKey("examples") -and $Conventions[$branchType].examples.Count -gt 0) {
            $script += "`n    Write-Host '  $($Conventions[$branchType].description):' -ForegroundColor Cyan"
            foreach ($example in $Conventions[$branchType].examples) {
                $script += "`n    Write-Host '    - $example' -ForegroundColor Gray"
            }
        }
    }
    
    $script += @"

    exit 1
}

exit 0
"@
    
    return $script
}

# Fonction pour générer un document de référence sur les conventions de branchement
function Get-BranchingConventionsDocument {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Conventions
    )
    
    $document = @"
# Conventions de nommage des branches Git

Ce document décrit les conventions de nommage des branches Git utilisées dans ce projet.

## Branches principales

"@
    
    # Ajouter les branches principales
    foreach ($branch in $Conventions.main_branches.Keys) {
        $branchInfo = $Conventions.main_branches[$branch]
        $document += "`n### $branch`n`n$($branchInfo.description)`n"
    }
    
    # Ajouter les autres types de branches
    $document += "`n## Types de branches`n"
    
    foreach ($branchType in @("feature_branches", "bugfix_branches", "release_branches", "hotfix_branches", "docs_branches", "refactor_branches", "test_branches", "experimental_branches")) {
        if ($Conventions.ContainsKey($branchType)) {
            $branch = $Conventions[$branchType]
            $typeName = $branchType -replace "_branches", ""
            
            $document += "`n### Branches $typeName`n`n$($branch.description)`n"
            
            if ($branch.ContainsKey("naming_rules")) {
                $document += "`n**Format:** `$($branch.naming_rules.prefix){nom}`n"
                
                if ($branch.naming_rules.body.ContainsKey("description")) {
                    $document += "`n**Règles de nommage:** $($branch.naming_rules.body.description)`n"
                }
                
                if ($branch.naming_rules.body.ContainsKey("max_length")) {
                    $document += "`n**Longueur maximale du nom:** $($branch.naming_rules.body.max_length) caractères`n"
                }
            }
            
            if ($branch.ContainsKey("examples") -and $branch.examples.Count -gt 0) {
                $document += "`n**Exemples:**`n"
                foreach ($example in $branch.examples) {
                    $document += "`n- `$example`"
                }
                $document += "`n"
            }
            
            if ($branch.ContainsKey("lifecycle")) {
                $document += "`n**Cycle de vie:**`n"
                foreach ($step in $branch.lifecycle.Keys) {
                    $document += "`n- **$($step):** $($branch.lifecycle[$step])"
                }
                $document += "`n"
            }
        }
    }
    
    # Ajouter les règles générales
    $document += @"

## Règles générales

- **Longueur maximale d'un nom de branche:** $($Conventions.general_rules.max_branch_name_length) caractères
- **Caractères interdits:** $($Conventions.general_rules.forbidden_characters -join ", ")
- **Noms réservés:** $($Conventions.general_rules.reserved_names -join ", ")

## Durée de vie des branches

"@
    
    foreach ($branchType in $Conventions.general_rules.branch_lifetime.Keys) {
        $document += "`n- **$branchType:** $($Conventions.general_rules.branch_lifetime[$branchType])"
    }
    
    # Ajouter les workflows
    $document += "`n`n## Workflows`n"
    
    foreach ($workflowType in $Conventions.workflow.Keys) {
        $workflow = $Conventions.workflow[$workflowType]
        $document += "`n### Workflow $workflowType`n"
        
        for ($i = 0; $i -lt $workflow.steps.Count; $i++) {
            $document += "`n$($i + 1). $($workflow.steps[$i])"
        }
        
        $document += "`n"
    }
    
    return $document
}

# Fonction principale
function Get-GitBranchingConventionsFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$AsObject
    )
    
    # Obtenir les conventions de branchement
    $conventions = Get-GitBranchingConventions
    
    # Générer les fichiers
    $files = @{
        conventions = $conventions
        validation_script = Get-BranchValidationScript -Conventions $conventions
        documentation = Get-BranchingConventionsDocument -Conventions $conventions
    }
    
    # Sauvegarder les fichiers si un chemin de sortie est spécifié
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        try {
            # Créer le répertoire de sortie s'il n'existe pas
            if (-not (Test-Path -Path $OutputPath)) {
                New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
            }
            
            # Créer le répertoire pour les hooks
            $hooksPath = Join-Path -Path $OutputPath -ChildPath "hooks"
            if (-not (Test-Path -Path $hooksPath)) {
                New-Item -Path $hooksPath -ItemType Directory -Force | Out-Null
            }
            
            # Sauvegarder les conventions en JSON
            $conventions | ConvertTo-Json -Depth 10 | Out-File -FilePath (Join-Path -Path $OutputPath -ChildPath "branching-conventions.json") -Encoding UTF8
            Write-Log "Branching conventions saved to: $(Join-Path -Path $OutputPath -ChildPath "branching-conventions.json")" -Level "Info"
            
            # Sauvegarder le script de validation
            $files.validation_script | Out-File -FilePath (Join-Path -Path $hooksPath -ChildPath "validate-branch-name.ps1") -Encoding UTF8
            Write-Log "Validation script saved to: $(Join-Path -Path $hooksPath -ChildPath "validate-branch-name.ps1")" -Level "Info"
            
            # Sauvegarder la documentation
            $files.documentation | Out-File -FilePath (Join-Path -Path $OutputPath -ChildPath "BRANCHING.md") -Encoding UTF8
            Write-Log "Documentation saved to: $(Join-Path -Path $OutputPath -ChildPath "BRANCHING.md")" -Level "Info"
        } catch {
            Write-Log "Error saving files: $_" -Level "Error"
        }
    }
    
    # Retourner les fichiers selon le format demandé
    if ($AsObject) {
        return $files
    } else {
        return $files | ConvertTo-Json -Depth 10
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Get-GitBranchingConventionsFiles -OutputPath $OutputPath -AsObject:$AsObject
}
