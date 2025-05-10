# Manage-TemplateLibrary.ps1
# Script pour gérer la bibliothèque de templates prédéfinis
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("List", "Get", "Add", "Remove", "Export", "Import")]
    [string]$Action = "List",
    
    [Parameter(Mandatory = $false)]
    [string]$TemplateName,
    
    [Parameter(Mandatory = $false)]
    [string]$TemplateContent,
    
    [Parameter(Mandatory = $false)]
    [string]$TemplatePath,
    
    [Parameter(Mandatory = $false)]
    [string]$Category = "General",
    
    [Parameter(Mandatory = $false)]
    [string]$Description,
    
    [Parameter(Mandatory = $false)]
    [string]$Author = $env:USERNAME,
    
    [Parameter(Mandatory = $false)]
    [string]$Tags,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [string]$LibraryPath,
    
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

# Fonction pour obtenir le chemin du fichier de métadonnées
function Get-MetadataPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LibraryPath
    )
    
    return Join-Path -Path $LibraryPath -ChildPath "metadata.json"
}

# Fonction pour charger les métadonnées de la bibliothèque
function Get-TemplateMetadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LibraryPath
    )
    
    $metadataPath = Get-MetadataPath -LibraryPath $LibraryPath
    
    if (Test-Path -Path $metadataPath) {
        try {
            $metadata = Get-Content -Path $metadataPath -Raw | ConvertFrom-Json
            return $metadata
        } catch {
            Write-Log "Error loading template metadata: $_" -Level "Error"
            return @{ Templates = @() }
        }
    } else {
        return @{ Templates = @() }
    }
}

# Fonction pour sauvegarder les métadonnées de la bibliothèque
function Save-TemplateMetadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Metadata,
        
        [Parameter(Mandatory = $true)]
        [string]$LibraryPath
    )
    
    $metadataPath = Get-MetadataPath -LibraryPath $LibraryPath
    
    try {
        $Metadata | ConvertTo-Json -Depth 10 | Out-File -FilePath $metadataPath -Encoding UTF8
        Write-Log "Saved template metadata to: $metadataPath" -Level "Debug"
        return $true
    } catch {
        Write-Log "Error saving template metadata: $_" -Level "Error"
        return $false
    }
}

# Fonction pour obtenir le chemin d'un template
function Get-TemplatePath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TemplateName,
        
        [Parameter(Mandatory = $true)]
        [string]$LibraryPath
    )
    
    # Nettoyer le nom du template pour éviter les problèmes de chemin
    $safeTemplateName = $TemplateName -replace '[\\\/\:\*\?\"\<\>\|]', '_'
    
    return Join-Path -Path $LibraryPath -ChildPath "$safeTemplateName.md"
}

# Fonction pour lister tous les templates disponibles
function Get-Templates {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LibraryPath,
        
        [Parameter(Mandatory = $false)]
        [string]$Category,
        
        [Parameter(Mandatory = $false)]
        [string]$Tag
    )
    
    $metadata = Get-TemplateMetadata -LibraryPath $LibraryPath
    $templates = $metadata.Templates
    
    # Filtrer par catégorie si spécifiée
    if ($Category) {
        $templates = $templates | Where-Object { $_.Category -eq $Category }
    }
    
    # Filtrer par tag si spécifié
    if ($Tag) {
        $templates = $templates | Where-Object { $_.Tags -contains $Tag }
    }
    
    return $templates
}

# Fonction pour obtenir un template spécifique
function Get-Template {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TemplateName,
        
        [Parameter(Mandatory = $true)]
        [string]$LibraryPath
    )
    
    $metadata = Get-TemplateMetadata -LibraryPath $LibraryPath
    $templateInfo = $metadata.Templates | Where-Object { $_.Name -eq $TemplateName }
    
    if (-not $templateInfo) {
        Write-Log "Template not found: $TemplateName" -Level "Warning"
        return $null
    }
    
    $templatePath = Get-TemplatePath -TemplateName $TemplateName -LibraryPath $LibraryPath
    
    if (-not (Test-Path -Path $templatePath)) {
        Write-Log "Template file not found: $templatePath" -Level "Warning"
        return $null
    }
    
    try {
        $content = Get-Content -Path $templatePath -Raw
        
        return @{
            Name = $templateInfo.Name
            Category = $templateInfo.Category
            Description = $templateInfo.Description
            Author = $templateInfo.Author
            Tags = $templateInfo.Tags
            CreatedDate = $templateInfo.CreatedDate
            ModifiedDate = $templateInfo.ModifiedDate
            Content = $content
        }
    } catch {
        Write-Log "Error loading template content: $_" -Level "Error"
        return $null
    }
}

# Fonction pour ajouter un nouveau template
function Add-Template {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TemplateName,
        
        [Parameter(Mandatory = $true)]
        [string]$TemplateContent,
        
        [Parameter(Mandatory = $true)]
        [string]$LibraryPath,
        
        [Parameter(Mandatory = $false)]
        [string]$Category = "General",
        
        [Parameter(Mandatory = $false)]
        [string]$Description = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Author = $env:USERNAME,
        
        [Parameter(Mandatory = $false)]
        [string]$Tags = ""
    )
    
    # Vérifier si le template existe déjà
    $metadata = Get-TemplateMetadata -LibraryPath $LibraryPath
    $existingTemplate = $metadata.Templates | Where-Object { $_.Name -eq $TemplateName }
    
    $isUpdate = $null -ne $existingTemplate
    $currentDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Préparer les tags
    $tagArray = @()
    if (-not [string]::IsNullOrWhiteSpace($Tags)) {
        $tagArray = $Tags -split ',' | ForEach-Object { $_.Trim() }
    }
    
    # Créer ou mettre à jour les métadonnées du template
    $templateInfo = @{
        Name = $TemplateName
        Category = $Category
        Description = $Description
        Author = $Author
        Tags = $tagArray
        CreatedDate = if ($isUpdate) { $existingTemplate.CreatedDate } else { $currentDate }
        ModifiedDate = $currentDate
    }
    
    # Mettre à jour les métadonnées
    if ($isUpdate) {
        $updatedTemplates = @()
        foreach ($template in $metadata.Templates) {
            if ($template.Name -eq $TemplateName) {
                $updatedTemplates += $templateInfo
            } else {
                $updatedTemplates += $template
            }
        }
        $metadata.Templates = $updatedTemplates
    } else {
        $metadata.Templates += $templateInfo
    }
    
    # Sauvegarder les métadonnées
    $metadataSaved = Save-TemplateMetadata -Metadata $metadata -LibraryPath $LibraryPath
    
    if (-not $metadataSaved) {
        Write-Log "Failed to save template metadata" -Level "Error"
        return $false
    }
    
    # Sauvegarder le contenu du template
    $templatePath = Get-TemplatePath -TemplateName $TemplateName -LibraryPath $LibraryPath
    
    try {
        $TemplateContent | Out-File -FilePath $templatePath -Encoding UTF8
        Write-Log "Template saved to: $templatePath" -Level "Info"
        return $true
    } catch {
        Write-Log "Error saving template content: $_" -Level "Error"
        return $false
    }
}

# Fonction pour supprimer un template
function Remove-TemplateFromLibrary {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TemplateName,
        
        [Parameter(Mandatory = $true)]
        [string]$LibraryPath
    )
    
    # Vérifier si le template existe
    $metadata = Get-TemplateMetadata -LibraryPath $LibraryPath
    $existingTemplate = $metadata.Templates | Where-Object { $_.Name -eq $TemplateName }
    
    if (-not $existingTemplate) {
        Write-Log "Template not found: $TemplateName" -Level "Warning"
        return $false
    }
    
    # Supprimer le template des métadonnées
    $metadata.Templates = $metadata.Templates | Where-Object { $_.Name -ne $TemplateName }
    
    # Sauvegarder les métadonnées
    $metadataSaved = Save-TemplateMetadata -Metadata $metadata -LibraryPath $LibraryPath
    
    if (-not $metadataSaved) {
        Write-Log "Failed to update template metadata" -Level "Error"
        return $false
    }
    
    # Supprimer le fichier du template
    $templatePath = Get-TemplatePath -TemplateName $TemplateName -LibraryPath $LibraryPath
    
    if (Test-Path -Path $templatePath) {
        try {
            Remove-Item -Path $templatePath -Force
            Write-Log "Template removed: $TemplateName" -Level "Info"
            return $true
        } catch {
            Write-Log "Error removing template file: $_" -Level "Error"
            return $false
        }
    } else {
        Write-Log "Template file not found: $templatePath" -Level "Warning"
        return $true  # Considérer comme un succès car les métadonnées ont été mises à jour
    }
}

# Fonction pour exporter un template
function Export-Template {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TemplateName,
        
        [Parameter(Mandatory = $true)]
        [string]$LibraryPath,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    # Obtenir le template
    $template = Get-Template -TemplateName $TemplateName -LibraryPath $LibraryPath
    
    if (-not $template) {
        Write-Log "Template not found: $TemplateName" -Level "Error"
        return $false
    }
    
    # Créer l'objet d'export
    $exportObject = @{
        Template = $template
        ExportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        ExportedBy = $env:USERNAME
    }
    
    # Sauvegarder l'export
    try {
        $exportObject | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Log "Template exported to: $OutputPath" -Level "Info"
        return $true
    } catch {
        Write-Log "Error exporting template: $_" -Level "Error"
        return $false
    }
}

# Fonction pour importer un template
function Import-Template {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TemplatePath,
        
        [Parameter(Mandatory = $true)]
        [string]$LibraryPath
    )
    
    if (-not (Test-Path -Path $TemplatePath)) {
        Write-Log "Template file not found: $TemplatePath" -Level "Error"
        return $false
    }
    
    try {
        $importObject = Get-Content -Path $TemplatePath -Raw | ConvertFrom-Json
        $template = $importObject.Template
        
        # Ajouter le template à la bibliothèque
        $result = Add-Template -TemplateName $template.Name -TemplateContent $template.Content -LibraryPath $LibraryPath -Category $template.Category -Description $template.Description -Author $template.Author -Tags ($template.Tags -join ',')
        
        if ($result) {
            Write-Log "Template imported: $($template.Name)" -Level "Info"
        } else {
            Write-Log "Failed to import template: $($template.Name)" -Level "Error"
        }
        
        return $result
    } catch {
        Write-Log "Error importing template: $_" -Level "Error"
        return $false
    }
}

# Fonction pour afficher les templates dans un format lisible
function Show-Templates {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Templates
    )
    
    if ($Templates.Count -eq 0) {
        Write-Host "No templates found." -ForegroundColor Yellow
        return
    }
    
    Write-Host "Available Templates:" -ForegroundColor Cyan
    Write-Host "-------------------" -ForegroundColor Cyan
    
    foreach ($template in $Templates) {
        Write-Host "Name: " -NoNewline -ForegroundColor White
        Write-Host $template.Name -ForegroundColor Green
        
        Write-Host "Category: " -NoNewline -ForegroundColor White
        Write-Host $template.Category -ForegroundColor Yellow
        
        if ($template.Description) {
            Write-Host "Description: " -NoNewline -ForegroundColor White
            Write-Host $template.Description -ForegroundColor Gray
        }
        
        Write-Host "Author: " -NoNewline -ForegroundColor White
        Write-Host $template.Author -ForegroundColor Gray
        
        if ($template.Tags -and $template.Tags.Count -gt 0) {
            Write-Host "Tags: " -NoNewline -ForegroundColor White
            Write-Host ($template.Tags -join ", ") -ForegroundColor Gray
        }
        
        Write-Host "Created: " -NoNewline -ForegroundColor White
        Write-Host $template.CreatedDate -ForegroundColor Gray
        
        Write-Host "Modified: " -NoNewline -ForegroundColor White
        Write-Host $template.ModifiedDate -ForegroundColor Gray
        
        Write-Host "-------------------" -ForegroundColor Cyan
    }
}

# Fonction principale
function Manage-TemplateLibrary {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("List", "Get", "Add", "Remove", "Export", "Import")]
        [string]$Action = "List",
        
        [Parameter(Mandatory = $false)]
        [string]$TemplateName,
        
        [Parameter(Mandatory = $false)]
        [string]$TemplateContent,
        
        [Parameter(Mandatory = $false)]
        [string]$TemplatePath,
        
        [Parameter(Mandatory = $false)]
        [string]$Category = "General",
        
        [Parameter(Mandatory = $false)]
        [string]$Description,
        
        [Parameter(Mandatory = $false)]
        [string]$Author = $env:USERNAME,
        
        [Parameter(Mandatory = $false)]
        [string]$Tags,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [string]$LibraryPath
    )
    
    # Exécuter l'action demandée
    switch ($Action) {
        "List" {
            $templates = Get-Templates -LibraryPath $LibraryPath -Category $Category -Tag $Tags
            Show-Templates -Templates $templates
            return $templates
        }
        "Get" {
            if (-not $TemplateName) {
                Write-Log "Template name is required for Get action" -Level "Error"
                return $null
            }
            
            $template = Get-Template -TemplateName $TemplateName -LibraryPath $LibraryPath
            
            if ($template) {
                Write-Host "Template: $TemplateName" -ForegroundColor Cyan
                Write-Host "-------------------" -ForegroundColor Cyan
                Write-Host "Category: $($template.Category)" -ForegroundColor Yellow
                
                if ($template.Description) {
                    Write-Host "Description: $($template.Description)" -ForegroundColor Gray
                }
                
                Write-Host "Author: $($template.Author)" -ForegroundColor Gray
                
                if ($template.Tags -and $template.Tags.Count -gt 0) {
                    Write-Host "Tags: $($template.Tags -join ", ")" -ForegroundColor Gray
                }
                
                Write-Host "Created: $($template.CreatedDate)" -ForegroundColor Gray
                Write-Host "Modified: $($template.ModifiedDate)" -ForegroundColor Gray
                
                Write-Host "`nContent:" -ForegroundColor Cyan
                Write-Host "-------------------" -ForegroundColor Cyan
                Write-Host $template.Content
            }
            
            return $template
        }
        "Add" {
            if (-not $TemplateName) {
                Write-Log "Template name is required for Add action" -Level "Error"
                return $false
            }
            
            if (-not $TemplateContent -and $TemplatePath) {
                if (Test-Path -Path $TemplatePath) {
                    try {
                        $TemplateContent = Get-Content -Path $TemplatePath -Raw
                    } catch {
                        Write-Log "Error reading template file: $_" -Level "Error"
                        return $false
                    }
                } else {
                    Write-Log "Template file not found: $TemplatePath" -Level "Error"
                    return $false
                }
            }
            
            if (-not $TemplateContent) {
                Write-Log "Template content is required for Add action" -Level "Error"
                return $false
            }
            
            return Add-Template -TemplateName $TemplateName -TemplateContent $TemplateContent -LibraryPath $LibraryPath -Category $Category -Description $Description -Author $Author -Tags $Tags
        }
        "Remove" {
            if (-not $TemplateName) {
                Write-Log "Template name is required for Remove action" -Level "Error"
                return $false
            }
            
            return Remove-TemplateFromLibrary -TemplateName $TemplateName -LibraryPath $LibraryPath
        }
        "Export" {
            if (-not $TemplateName) {
                Write-Log "Template name is required for Export action" -Level "Error"
                return $false
            }
            
            if (-not $OutputPath) {
                $OutputPath = Join-Path -Path (Get-Location) -ChildPath "$TemplateName.json"
            }
            
            return Export-Template -TemplateName $TemplateName -LibraryPath $LibraryPath -OutputPath $OutputPath
        }
        "Import" {
            if (-not $TemplatePath) {
                Write-Log "Template path is required for Import action" -Level "Error"
                return $false
            }
            
            return Import-Template -TemplatePath $TemplatePath -LibraryPath $LibraryPath
        }
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Manage-TemplateLibrary -Action $Action -TemplateName $TemplateName -TemplateContent $TemplateContent -TemplatePath $TemplatePath -Category $Category -Description $Description -Author $Author -Tags $Tags -OutputPath $OutputPath -LibraryPath $LibraryPath
}
