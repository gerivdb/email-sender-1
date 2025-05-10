# Get-GitCommitConventions.ps1
# Script pour définir les conventions de messages de commit Git
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

# Fonction pour obtenir les conventions de messages de commit
function Get-GitCommitConventions {
    [CmdletBinding()]
    param()
    
    $conventions = @{
        # Format général
        format = @{
            pattern = "^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-z0-9-]+\))?: .{1,100}$"
            description = "Format: <type>(<scope>): <subject>"
            example = "feat(templates): add new roadmap template"
            max_subject_length = 100
            max_body_line_length = 72
        }
        
        # Types de commit
        types = @(
            @{
                type = "feat"
                description = "Une nouvelle fonctionnalité"
                emoji = "✨"
                release_impact = "minor"
            },
            @{
                type = "fix"
                description = "Correction d'un bug"
                emoji = "🐛"
                release_impact = "patch"
            },
            @{
                type = "docs"
                description = "Modifications de la documentation uniquement"
                emoji = "📚"
                release_impact = "none"
            },
            @{
                type = "style"
                description = "Changements qui n'affectent pas le sens du code (espaces, formatage, etc.)"
                emoji = "💎"
                release_impact = "none"
            },
            @{
                type = "refactor"
                description = "Modification du code qui ne corrige pas un bug et n'ajoute pas de fonctionnalité"
                emoji = "📦"
                release_impact = "none"
            },
            @{
                type = "perf"
                description = "Amélioration des performances"
                emoji = "🚀"
                release_impact = "patch"
            },
            @{
                type = "test"
                description = "Ajout ou correction de tests"
                emoji = "🧪"
                release_impact = "none"
            },
            @{
                type = "build"
                description = "Modifications affectant le système de build ou les dépendances externes"
                emoji = "🔧"
                release_impact = "none"
            },
            @{
                type = "ci"
                description = "Modifications des fichiers et scripts de configuration CI"
                emoji = "⚙️"
                release_impact = "none"
            },
            @{
                type = "chore"
                description = "Autres changements qui ne modifient pas les fichiers src ou test"
                emoji = "♻️"
                release_impact = "none"
            },
            @{
                type = "revert"
                description = "Annulation d'un commit précédent"
                emoji = "⏪"
                release_impact = "patch"
            }
        )
        
        # Scopes
        scopes = @(
            @{
                name = "templates"
                description = "Configurations de templates"
            },
            @{
                name = "visualizations"
                description = "Configurations de visualisations"
            },
            @{
                name = "data-mappings"
                description = "Configurations de mappages de données"
            },
            @{
                name = "charts"
                description = "Configurations de graphiques"
            },
            @{
                name = "exports"
                description = "Configurations d'exports"
            },
            @{
                name = "searches"
                description = "Configurations de recherches"
            },
            @{
                name = "schemas"
                description = "Schémas JSON"
            },
            @{
                name = "migrations"
                description = "Scripts de migration"
            },
            @{
                name = "scripts"
                description = "Scripts utilitaires"
            },
            @{
                name = "docs"
                description = "Documentation"
            },
            @{
                name = "deps"
                description = "Dépendances"
            },
            @{
                name = "config"
                description = "Configuration"
            }
        )
        
        # Structure du message
        structure = @{
            header = @{
                required = $true
                format = "<type>(<scope>): <subject>"
                rules = @{
                    type = @{
                        required = $true
                        allowed_values = @("feat", "fix", "docs", "style", "refactor", "perf", "test", "build", "ci", "chore", "revert")
                    }
                    scope = @{
                        required = $false
                        format = "(<scope>)"
                        rules = @{
                            allowed_characters = "a-z0-9-"
                            max_length = 20
                        }
                    }
                    subject = @{
                        required = $true
                        rules = @{
                            max_length = 100
                            no_period_at_end = $true
                            imperative_mood = $true
                            lowercase_first_letter = $true
                        }
                    }
                }
            }
            body = @{
                required = $false
                rules = @{
                    blank_line_after_header = $true
                    wrap_at = 72
                    explain_what_and_why = $true
                }
            }
            footer = @{
                required = $false
                format = "<type>: <value>"
                types = @(
                    @{
                        type = "Refs"
                        format = "Refs: #{issue_id}"
                        example = "Refs: #123"
                    },
                    @{
                        type = "Closes"
                        format = "Closes: #{issue_id}"
                        example = "Closes: #123"
                    },
                    @{
                        type = "BREAKING CHANGE"
                        format = "BREAKING CHANGE: <description>"
                        example = "BREAKING CHANGE: change the API endpoint format"
                        release_impact = "major"
                    }
                )
            }
        }
        
        # Exemples complets
        examples = @(
            @{
                description = "Ajout d'une nouvelle fonctionnalité avec un scope"
                message = @"
feat(templates): add new roadmap template

Add a new template for visualizing roadmap progress with completion percentages.
The template includes color coding for different status levels.

Refs: #42
"@
            },
            @{
                description = "Correction d'un bug"
                message = @"
fix(charts): resolve data mapping issue

Fix incorrect data mapping in pie charts that was causing
visualization errors when using percentage values.

Closes: #123
"@
            },
            @{
                description = "Changement avec rupture de compatibilité"
                message = @"
feat(api): change configuration format

Update the configuration format to support nested structures
and improve type validation.

BREAKING CHANGE: The configuration format has changed and
requires migration of existing configurations.
"@
            },
            @{
                description = "Simple mise à jour de documentation"
                message = @"
docs: update README with new examples

Update the README with examples of the new visualization types
and improve the getting started guide.
"@
            }
        )
        
        # Règles de validation
        validation = @{
            script_path = "scripts/hooks/validate-commit-message.ps1"
            error_message = "Le message de commit ne respecte pas les conventions. Veuillez utiliser le format approprié."
            hook = "commit-msg"
        }
    }
    
    return $conventions
}

# Fonction pour générer un script de validation de message de commit
function Get-CommitValidationScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Conventions
    )
    
    $script = @"
#!/usr/bin/env pwsh
# validate-commit-message.ps1
# Script pour valider les messages de commit selon les conventions
# Version: 1.0
# Date: $(Get-Date -Format "yyyy-MM-dd")

# Récupérer le fichier contenant le message de commit
param (
    [Parameter(Mandatory = `$true)]
    [string]`$CommitMsgFile
)

# Lire le message de commit
`$commitMsg = Get-Content -Path `$CommitMsgFile -Raw

# Ignorer les messages de fusion générés automatiquement
if (`$commitMsg -match '^Merge branch|^Merge pull request|^Merge remote-tracking branch') {
    exit 0
}

# Définir le pattern de validation pour l'en-tête
`$headerPattern = '$($Conventions.format.pattern)'

# Vérifier si l'en-tête est valide
`$firstLine = (`$commitMsg -split "`n")[0]
if (-not (`$firstLine -match `$headerPattern)) {
    Write-Host "Erreur: L'en-tête du message de commit ne respecte pas le format requis" -ForegroundColor Red
    Write-Host "Format attendu: $($Conventions.format.description)" -ForegroundColor Yellow
    Write-Host "Exemple: $($Conventions.format.example)" -ForegroundColor Yellow
    Write-Host "`nTypes de commit valides:" -ForegroundColor Cyan
"@
    
    # Ajouter les types de commit valides
    foreach ($type in $Conventions.types) {
        $script += "`n    Write-Host '  $($type.type): $($type.description)' -ForegroundColor Gray"
    }
    
    $script += @"

    Write-Host "`nScopes valides:" -ForegroundColor Cyan
"@
    
    # Ajouter les scopes valides
    foreach ($scope in $Conventions.scopes) {
        $script += "`n    Write-Host '  $($scope.name): $($scope.description)' -ForegroundColor Gray"
    }
    
    $script += @"

    exit 1
}

# Vérifier la longueur du sujet
`$subject = `$firstLine -replace '^[^:]+:\s*', ''
if (`$subject.Length -gt $($Conventions.format.max_subject_length)) {
    Write-Host "Erreur: Le sujet du message de commit est trop long (maximum $($Conventions.format.max_subject_length) caractères)" -ForegroundColor Red
    exit 1
}

# Vérifier si le sujet commence par une lettre minuscule
if (`$subject -cmatch '^[A-Z]') {
    Write-Host "Erreur: Le sujet du message de commit doit commencer par une lettre minuscule" -ForegroundColor Red
    exit 1
}

# Vérifier si le sujet se termine par un point
if (`$subject -match '\.$') {
    Write-Host "Erreur: Le sujet du message de commit ne doit pas se terminer par un point" -ForegroundColor Red
    exit 1
}

# Vérifier la longueur des lignes du corps
`$lines = `$commitMsg -split "`n"
for (`$i = 1; `$i -lt `$lines.Count; `$i++) {
    `$line = `$lines[`$i]
    if (`$line.Length -gt $($Conventions.structure.body.rules.wrap_at) -and `$line -notmatch '^(Refs|Closes|BREAKING CHANGE):') {
        Write-Host "Erreur: La ligne `$(`$i + 1) du corps du message est trop longue (maximum $($Conventions.structure.body.rules.wrap_at) caractères)" -ForegroundColor Red
        exit 1
    }
}

# Vérifier si le message contient un changement avec rupture de compatibilité
if (`$commitMsg -match 'BREAKING CHANGE:') {
    # Vérifier si le type est approprié pour un changement majeur
    `$type = `$firstLine -replace '^([^(]+).*$', '$1'
    if (`$type -ne 'feat' -and `$type -ne 'fix') {
        Write-Host "Attention: Les changements avec rupture de compatibilité (BREAKING CHANGE) sont généralement associés aux types 'feat' ou 'fix'" -ForegroundColor Yellow
    }
}

# Message valide
exit 0
"@
    
    return $script
}

# Fonction pour générer un document de référence sur les conventions de commit
function Get-CommitConventionsDocument {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Conventions
    )
    
    $document = @"
# Conventions de messages de commit Git

Ce document décrit les conventions de messages de commit Git utilisées dans ce projet.

## Format général

Format: `$($Conventions.format.description)`

Exemple: `$($Conventions.format.example)`

## Types de commit

"@
    
    # Ajouter les types de commit
    foreach ($type in $Conventions.types) {
        $document += "`n- **$($type.type)** $($type.emoji): $($type.description)"
        if ($type.release_impact -ne "none") {
            $document += " *(Impact de version: $($type.release_impact))*"
        }
    }
    
    # Ajouter les scopes
    $document += "`n`n## Scopes`n"
    
    foreach ($scope in $Conventions.scopes) {
        $document += "`n- **$($scope.name)**: $($scope.description)"
    }
    
    # Ajouter la structure du message
    $document += @"

## Structure du message

### En-tête (obligatoire)

Format: `$($Conventions.structure.header.format)`

- **type**: Le type de changement (obligatoire)
- **scope**: Le scope du changement (optionnel)
- **subject**: Description concise du changement (obligatoire)
  - Maximum $($Conventions.format.max_subject_length) caractères
  - Commence par une lettre minuscule
  - Pas de point à la fin
  - À l'impératif présent

### Corps (optionnel)

- Séparé de l'en-tête par une ligne vide
- Explique le *quoi* et le *pourquoi* (pas le *comment*)
- Lignes limitées à $($Conventions.structure.body.rules.wrap_at) caractères

### Pied de page (optionnel)

"@
    
    # Ajouter les types de pied de page
    foreach ($footerType in $Conventions.structure.footer.types) {
        $document += "`n- **$($footerType.type)**: `$($footerType.format)` *(Exemple: `$($footerType.example)`)*"
        if ($footerType.PSObject.Properties.Name.Contains("release_impact")) {
            $document += " *(Impact de version: $($footerType.release_impact))*"
        }
    }
    
    # Ajouter des exemples complets
    $document += "`n`n## Exemples complets`n"
    
    foreach ($example in $Conventions.examples) {
        $document += @"

### $($example.description)

```
$($example.message)
```
"@
    }
    
    return $document
}

# Fonction principale
function Get-GitCommitConventionsFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$AsObject
    )
    
    # Obtenir les conventions de messages de commit
    $conventions = Get-GitCommitConventions
    
    # Générer les fichiers
    $files = @{
        conventions = $conventions
        validation_script = Get-CommitValidationScript -Conventions $conventions
        documentation = Get-CommitConventionsDocument -Conventions $conventions
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
            $conventions | ConvertTo-Json -Depth 10 | Out-File -FilePath (Join-Path -Path $OutputPath -ChildPath "commit-conventions.json") -Encoding UTF8
            Write-Log "Commit conventions saved to: $(Join-Path -Path $OutputPath -ChildPath "commit-conventions.json")" -Level "Info"
            
            # Sauvegarder le script de validation
            $files.validation_script | Out-File -FilePath (Join-Path -Path $hooksPath -ChildPath "validate-commit-message.ps1") -Encoding UTF8
            Write-Log "Validation script saved to: $(Join-Path -Path $hooksPath -ChildPath "validate-commit-message.ps1")" -Level "Info"
            
            # Sauvegarder la documentation
            $files.documentation | Out-File -FilePath (Join-Path -Path $OutputPath -ChildPath "COMMIT_CONVENTION.md") -Encoding UTF8
            Write-Log "Documentation saved to: $(Join-Path -Path $OutputPath -ChildPath "COMMIT_CONVENTION.md")" -Level "Info"
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
    Get-GitCommitConventionsFiles -OutputPath $OutputPath -AsObject:$AsObject
}
