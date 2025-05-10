# Get-GitRepositoryStructure.ps1
# Script pour définir la structure du dépôt Git pour les configurations
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

# Fonction pour obtenir la structure du dépôt Git
function Get-GitRepositoryStructure {
    [CmdletBinding()]
    param()
    
    $structure = @{
        # Structure de base du dépôt
        repository = @{
            name = "roadmap-configurations"
            description = "Repository for roadmap configurations"
            default_branch = "main"
            ignore_patterns = @(
                "*.log",
                "*.tmp",
                "*.temp",
                "*.bak",
                "node_modules/",
                ".vscode/",
                ".idea/",
                "__pycache__/",
                "*.pyc",
                "*.pyo",
                "*.pyd"
            )
        }
        
        # Structure des branches
        branches = @{
            main = @{
                description = "Main branch containing stable configurations"
                protected = $true
                require_pull_request = $true
                require_approvals = 1
            }
            development = @{
                description = "Development branch for ongoing work"
                protected = $false
                base_branch = "main"
            }
            feature = @{
                description = "Feature branches for new configurations"
                naming_convention = "feature/{feature-name}"
                base_branch = "development"
            }
            release = @{
                description = "Release branches for version preparation"
                naming_convention = "release/v{major}.{minor}.{patch}"
                base_branch = "development"
                merge_to = @("main", "development")
            }
            hotfix = @{
                description = "Hotfix branches for urgent fixes"
                naming_convention = "hotfix/{issue-id}"
                base_branch = "main"
                merge_to = @("main", "development")
            }
        }
        
        # Structure des tags
        tags = @{
            release = @{
                description = "Release tags for versioned configurations"
                naming_convention = "v{major}.{minor}.{patch}"
                annotated = $true
            }
            milestone = @{
                description = "Milestone tags for significant achievements"
                naming_convention = "milestone-{name}"
                annotated = $true
            }
        }
        
        # Structure des répertoires
        directories = @{
            templates = @{
                path = "templates"
                description = "Template configurations"
                subdirectories = @{
                    markdown = @{
                        path = "markdown"
                        description = "Markdown templates"
                    }
                    html = @{
                        path = "html"
                        description = "HTML templates"
                    }
                    text = @{
                        path = "text"
                        description = "Text templates"
                    }
                }
            }
            visualizations = @{
                path = "visualizations"
                description = "Visualization configurations"
                subdirectories = @{
                    charts = @{
                        path = "charts"
                        description = "Chart visualizations"
                    }
                    graphs = @{
                        path = "graphs"
                        description = "Graph visualizations"
                    }
                    maps = @{
                        path = "maps"
                        description = "Map visualizations"
                    }
                }
            }
            data_mappings = @{
                path = "data_mappings"
                description = "Data mapping configurations"
            }
            charts = @{
                path = "charts"
                description = "Chart configurations"
            }
            exports = @{
                path = "exports"
                description = "Export configurations"
            }
            searches = @{
                path = "searches"
                description = "Search configurations"
            }
            schemas = @{
                path = "schemas"
                description = "JSON schemas for validation"
            }
            migrations = @{
                path = "migrations"
                description = "Migration scripts for version upgrades"
            }
            scripts = @{
                path = "scripts"
                description = "Utility scripts"
                subdirectories = @{
                    hooks = @{
                        path = "hooks"
                        description = "Git hooks"
                    }
                    validation = @{
                        path = "validation"
                        description = "Validation scripts"
                    }
                    migration = @{
                        path = "migration"
                        description = "Migration scripts"
                    }
                }
            }
            docs = @{
                path = "docs"
                description = "Documentation"
            }
        }
        
        # Conventions de nommage des fichiers
        file_naming = @{
            templates = "{name}_v{version}.json"
            visualizations = "{name}_v{version}.json"
            data_mappings = "{name}_v{version}.json"
            charts = "{name}_v{version}.json"
            exports = "{name}_v{version}.json"
            searches = "{name}_v{version}.json"
            schemas = "{type}_schema_v{version}.json"
            migrations = "migrate_{from_version}_to_{to_version}.ps1"
        }
        
        # Conventions pour les messages de commit
        commit_messages = @{
            types = @(
                @{
                    type = "feat"
                    description = "A new feature"
                },
                @{
                    type = "fix"
                    description = "A bug fix"
                },
                @{
                    type = "docs"
                    description = "Documentation only changes"
                },
                @{
                    type = "style"
                    description = "Changes that do not affect the meaning of the code"
                },
                @{
                    type = "refactor"
                    description = "A code change that neither fixes a bug nor adds a feature"
                },
                @{
                    type = "perf"
                    description = "A code change that improves performance"
                },
                @{
                    type = "test"
                    description = "Adding missing tests or correcting existing tests"
                },
                @{
                    type = "build"
                    description = "Changes that affect the build system or external dependencies"
                },
                @{
                    type = "ci"
                    description = "Changes to our CI configuration files and scripts"
                },
                @{
                    type = "chore"
                    description = "Other changes that don't modify src or test files"
                }
            )
            format = "{type}({scope}): {subject}"
            example = "feat(templates): add new roadmap template"
            body_format = "
{subject}

{body}

{footer}"
            footer_format = "Refs: #{issue_id}"
        }
        
        # Hooks Git
        hooks = @{
            pre_commit = @{
                description = "Run before committing"
                actions = @(
                    "Validate JSON schemas",
                    "Check file naming conventions",
                    "Run linting"
                )
            }
            pre_push = @{
                description = "Run before pushing"
                actions = @(
                    "Run tests",
                    "Validate all configurations"
                )
            }
            commit_msg = @{
                description = "Validate commit messages"
                actions = @(
                    "Check commit message format"
                )
            }
        }
        
        # Workflow d'intégration
        workflow = @{
            feature_development = @{
                steps = @(
                    "Create feature branch from development",
                    "Develop and test changes",
                    "Create pull request to development",
                    "Review and approve",
                    "Merge to development"
                )
            }
            release = @{
                steps = @(
                    "Create release branch from development",
                    "Finalize and test",
                    "Create pull request to main",
                    "Review and approve",
                    "Merge to main",
                    "Tag release",
                    "Merge back to development"
                )
            }
            hotfix = @{
                steps = @(
                    "Create hotfix branch from main",
                    "Fix and test",
                    "Create pull request to main",
                    "Review and approve",
                    "Merge to main",
                    "Tag hotfix release",
                    "Merge to development"
                )
            }
        }
    }
    
    return $structure
}

# Fonction pour générer un fichier .gitignore
function Get-GitignoreContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Structure
    )
    
    $ignorePatterns = $Structure.repository.ignore_patterns
    
    $content = @"
# Gitignore for roadmap configurations repository
# Generated on $(Get-Date -Format "yyyy-MM-dd")

# Project-specific ignores
"@
    
    foreach ($pattern in $ignorePatterns) {
        $content += "`n$pattern"
    }
    
    $content += @"

# OS-specific files
.DS_Store
Thumbs.db
desktop.ini

# Editor files
*.swp
*.swo
*~

# Logs and databases
*.log
*.sqlite

# Environment files
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Dependency directories
node_modules/
jspm_packages/
bower_components/

# Distribution directories
dist/
build/
out/

# Cache directories
.npm
.eslintcache
.stylelintcache
.cache/

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual environments
venv/
ENV/
env/
"@
    
    return $content
}

# Fonction pour générer un README.md
function Get-ReadmeContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Structure
    )
    
    $content = @"
# ${$Structure.repository.name}

${$Structure.repository.description}

## Repository Structure

### Branches

- **main**: ${$Structure.branches.main.description}
- **development**: ${$Structure.branches.development.description}
- **feature branches**: ${$Structure.branches.feature.description}
  - Naming convention: `${$Structure.branches.feature.naming_convention}`
- **release branches**: ${$Structure.branches.release.description}
  - Naming convention: `${$Structure.branches.release.naming_convention}`
- **hotfix branches**: ${$Structure.branches.hotfix.description}
  - Naming convention: `${$Structure.branches.hotfix.naming_convention}`

### Directories

"@
    
    foreach ($dir in $Structure.directories.Keys) {
        $dirInfo = $Structure.directories[$dir]
        $content += "- **$($dirInfo.path)**: $($dirInfo.description)`n"
        
        if ($dirInfo.PSObject.Properties.Name.Contains("subdirectories")) {
            foreach ($subdir in $dirInfo.subdirectories.Keys) {
                $subdirInfo = $dirInfo.subdirectories[$subdir]
                $content += "  - **$($subdirInfo.path)**: $($subdirInfo.description)`n"
            }
        }
    }
    
    $content += @"

### File Naming Conventions

"@
    
    foreach ($type in $Structure.file_naming.Keys) {
        $convention = $Structure.file_naming[$type]
        $content += "- **$type**: `$convention``n"
    }
    
    $content += @"

### Commit Message Format

Format: `${$Structure.commit_messages.format}`

Example: `${$Structure.commit_messages.example}`

Types:
"@
    
    foreach ($type in $Structure.commit_messages.types) {
        $content += "`n- **$($type.type)**: $($type.description)"
    }
    
    $content += @"

## Workflows

### Feature Development

"@
    
    foreach ($step in $Structure.workflow.feature_development.steps) {
        $content += "`n1. $step"
    }
    
    $content += @"

### Release Process

"@
    
    foreach ($step in $Structure.workflow.release.steps) {
        $content += "`n1. $step"
    }
    
    $content += @"

### Hotfix Process

"@
    
    foreach ($step in $Structure.workflow.hotfix.steps) {
        $content += "`n1. $step"
    }
    
    return $content
}

# Fonction principale
function Get-GitRepositoryStructureFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$AsObject
    )
    
    # Obtenir la structure du dépôt
    $structure = Get-GitRepositoryStructure
    
    # Générer les fichiers de base
    $files = @{
        structure = $structure
        gitignore = Get-GitignoreContent -Structure $structure
        readme = Get-ReadmeContent -Structure $structure
    }
    
    # Sauvegarder les fichiers si un chemin de sortie est spécifié
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        try {
            # Créer le répertoire de sortie s'il n'existe pas
            if (-not (Test-Path -Path $OutputPath)) {
                New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
            }
            
            # Sauvegarder la structure en JSON
            $structure | ConvertTo-Json -Depth 10 | Out-File -FilePath (Join-Path -Path $OutputPath -ChildPath "repository-structure.json") -Encoding UTF8
            Write-Log "Repository structure saved to: $(Join-Path -Path $OutputPath -ChildPath "repository-structure.json")" -Level "Info"
            
            # Sauvegarder le .gitignore
            $files.gitignore | Out-File -FilePath (Join-Path -Path $OutputPath -ChildPath ".gitignore") -Encoding UTF8
            Write-Log "Gitignore saved to: $(Join-Path -Path $OutputPath -ChildPath ".gitignore")" -Level "Info"
            
            # Sauvegarder le README.md
            $files.readme | Out-File -FilePath (Join-Path -Path $OutputPath -ChildPath "README.md") -Encoding UTF8
            Write-Log "README saved to: $(Join-Path -Path $OutputPath -ChildPath "README.md")" -Level "Info"
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
    Get-GitRepositoryStructureFiles -OutputPath $OutputPath -AsObject:$AsObject
}
