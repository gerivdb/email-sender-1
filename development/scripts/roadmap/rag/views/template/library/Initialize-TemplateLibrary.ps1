# Initialize-TemplateLibrary.ps1
# Script pour initialiser la bibliothèque de templates prédéfinis
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$LibraryPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
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

# Importer le script de gestion de la bibliothèque
$libraryManagerPath = Join-Path -Path $scriptPath -ChildPath "Manage-TemplateLibrary.ps1"
if (-not (Test-Path -Path $libraryManagerPath)) {
    Write-Log "Library manager script not found: $libraryManagerPath" -Level "Error"
    exit 1
}

. $libraryManagerPath

# Définir le chemin par défaut de la bibliothèque si non spécifié
if (-not $LibraryPath) {
    $LibraryPath = Join-Path -Path $scriptPath -ChildPath "templates"
}

# Créer le répertoire de la bibliothèque s'il n'existe pas
if (-not (Test-Path -Path $LibraryPath)) {
    try {
        New-Item -Path $LibraryPath -ItemType Directory -Force | Out-Null
        Write-Log "Created template library directory: $LibraryPath" -Level "Info"
    } catch {
        Write-Log "Failed to create template library directory: $_" -Level "Error"
        exit 1
    }
}

# Définition des templates prédéfinis
$predefinedTemplates = @(
    @{
        Name = "Simple_List"
        Category = "Basic"
        Description = "Un template simple pour afficher une liste de tâches avec leurs détails"
        Author = "System"
        Tags = "liste,simple,basique"
        FilePath = Join-Path -Path $scriptPath -ChildPath "templates\Simple_List.md"
    },
    @{
        Name = "Task_Table"
        Category = "Basic"
        Description = "Un template pour afficher les tâches sous forme de tableau avec des statistiques"
        Author = "System"
        Tags = "tableau,statistiques,basique"
        FilePath = Join-Path -Path $scriptPath -ChildPath "templates\Task_Table.md"
    },
    @{
        Name = "Kanban_Board"
        Category = "Advanced"
        Description = "Un template pour afficher les tâches sous forme de tableau Kanban"
        Author = "System"
        Tags = "kanban,avancé,visualisation"
        FilePath = Join-Path -Path $scriptPath -ChildPath "templates\Kanban_Board.md"
    }
)

# Fonction pour initialiser la bibliothèque
function Initialize-TemplateLibrary {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LibraryPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    Write-Log "Initializing template library at: $LibraryPath" -Level "Info"
    
    # Vérifier si la bibliothèque existe déjà
    $metadataPath = Join-Path -Path $LibraryPath -ChildPath "metadata.json"
    $libraryExists = Test-Path -Path $metadataPath
    
    if ($libraryExists -and -not $Force) {
        Write-Log "Template library already exists. Use -Force to reinitialize." -Level "Warning"
        return $false
    }
    
    # Initialiser les métadonnées
    $metadata = @{
        Templates = @()
        CreatedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        ModifiedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    # Ajouter les templates prédéfinis
    foreach ($template in $predefinedTemplates) {
        if (Test-Path -Path $template.FilePath) {
            try {
                $content = Get-Content -Path $template.FilePath -Raw
                
                $result = Add-Template -TemplateName $template.Name -TemplateContent $content -LibraryPath $LibraryPath -Category $template.Category -Description $template.Description -Author $template.Author -Tags $template.Tags
                
                if ($result) {
                    Write-Log "Added template: $($template.Name)" -Level "Info"
                } else {
                    Write-Log "Failed to add template: $($template.Name)" -Level "Error"
                }
            } catch {
                Write-Log "Error adding template $($template.Name): $_" -Level "Error"
            }
        } else {
            Write-Log "Template file not found: $($template.FilePath)" -Level "Warning"
        }
    }
    
    Write-Log "Template library initialization completed" -Level "Info"
    return $true
}

# Exécuter la fonction d'initialisation
$result = Initialize-TemplateLibrary -LibraryPath $LibraryPath -Force:$Force

if ($result) {
    # Afficher les templates disponibles
    $templates = Get-Templates -LibraryPath $LibraryPath
    Show-Templates -Templates $templates
}

# Retourner le résultat
return $result
