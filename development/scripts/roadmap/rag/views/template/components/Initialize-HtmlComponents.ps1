# Initialize-HtmlComponents.ps1
# Script pour initialiser les composants HTML prédéfinis
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ComponentsPath,
    
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

# Définir le chemin par défaut des composants si non spécifié
if (-not $ComponentsPath) {
    $ComponentsPath = $scriptPath
}

# Créer le répertoire des composants s'il n'existe pas
if (-not (Test-Path -Path $ComponentsPath)) {
    try {
        New-Item -Path $ComponentsPath -ItemType Directory -Force | Out-Null
        Write-Log "Created components directory: $ComponentsPath" -Level "Info"
    } catch {
        Write-Log "Failed to create components directory: $_" -Level "Error"
        exit 1
    }
}

# Définition des composants prédéfinis
$predefinedComponents = @(
    @{
        Name = "task-card"
        Description = "Carte de tâche avec détails"
        FilePath = Join-Path -Path $scriptPath -ChildPath "task-card.html"
    },
    @{
        Name = "status-chart"
        Description = "Graphique de répartition par statut"
        FilePath = Join-Path -Path $scriptPath -ChildPath "status-chart.html"
    },
    @{
        Name = "priority-chart"
        Description = "Graphique de répartition par priorité"
        FilePath = Join-Path -Path $scriptPath -ChildPath "priority-chart.html"
    },
    @{
        Name = "progress-bar"
        Description = "Barre de progression avec pourcentage"
        FilePath = Join-Path -Path $scriptPath -ChildPath "progress-bar.html"
    },
    @{
        Name = "kanban-board"
        Description = "Tableau Kanban avec colonnes par statut"
        FilePath = Join-Path -Path $scriptPath -ChildPath "kanban-board.html"
    }
)

# Fonction pour initialiser les composants
function Initialize-HtmlComponents {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ComponentsPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    Write-Log "Initializing HTML components at: $ComponentsPath" -Level "Info"
    
    # Vérifier si les composants existent déjà
    $existingComponents = Get-ChildItem -Path $ComponentsPath -Filter "*.html" | Select-Object -ExpandProperty Name
    
    # Ajouter les composants prédéfinis
    foreach ($component in $predefinedComponents) {
        $outputPath = Join-Path -Path $ComponentsPath -ChildPath "$($component.Name).html"
        
        if ((Test-Path -Path $outputPath) -and -not $Force) {
            Write-Log "Component already exists: $($component.Name). Use -Force to overwrite." -Level "Warning"
            continue
        }
        
        if (Test-Path -Path $component.FilePath) {
            try {
                Copy-Item -Path $component.FilePath -Destination $outputPath -Force
                Write-Log "Added component: $($component.Name)" -Level "Info"
            } catch {
                Write-Log "Error adding component $($component.Name): $_" -Level "Error"
            }
        } else {
            Write-Log "Component file not found: $($component.FilePath)" -Level "Warning"
        }
    }
    
    # Créer un fichier README.md pour documenter les composants
    $readmePath = Join-Path -Path $ComponentsPath -ChildPath "README.md"
    
    $readmeContent = @"
# Composants HTML prédéfinis

Ce répertoire contient des composants HTML prédéfinis pour les templates de roadmap.

## Utilisation

Pour utiliser ces composants dans vos templates HTML, vous pouvez les insérer directement ou utiliser l'éditeur de template HTML avec l'option `-EnableComponentInsertion`.

## Composants disponibles

"@
    
    foreach ($component in $predefinedComponents) {
        $readmeContent += @"

### $($component.Name)

$($component.Description)

```html
{{> $($component.Name)}}
```

"@
    }
    
    $readmeContent += @"

## Création de nouveaux composants

Pour créer un nouveau composant, créez simplement un fichier HTML dans ce répertoire avec le contenu du composant.
Le nom du fichier (sans l'extension .html) sera utilisé comme nom du composant.

"@
    
    try {
        $readmeContent | Out-File -FilePath $readmePath -Encoding UTF8
        Write-Log "Created README.md for components" -Level "Info"
    } catch {
        Write-Log "Error creating README.md: $_" -Level "Error"
    }
    
    Write-Log "HTML components initialization completed" -Level "Info"
    return $true
}

# Exécuter la fonction d'initialisation
$result = Initialize-HtmlComponents -ComponentsPath $ComponentsPath -Force:$Force

if ($result) {
    # Afficher les composants disponibles
    $components = Get-ChildItem -Path $ComponentsPath -Filter "*.html" | Where-Object { $_.Name -ne "README.md" }
    
    Write-Host "Available HTML Components:" -ForegroundColor Cyan
    Write-Host "-------------------------" -ForegroundColor Cyan
    
    foreach ($component in $components) {
        $name = [System.IO.Path]::GetFileNameWithoutExtension($component.Name)
        $predefinedComponent = $predefinedComponents | Where-Object { $_.Name -eq $name }
        
        if ($predefinedComponent) {
            Write-Host "$name" -ForegroundColor Green -NoNewline
            Write-Host " - $($predefinedComponent.Description)" -ForegroundColor Gray
        } else {
            Write-Host "$name" -ForegroundColor Green
        }
    }
}

# Retourner le résultat
return $result
