<#
.SYNOPSIS
    RÃ©organisation avancÃ©e des scripts du projet
.DESCRIPTION
    Ce script implÃ©mente une rÃ©organisation complÃ¨te des scripts du projet
    selon une structure hiÃ©rarchique claire et cohÃ©rente, en respectant
    les principes SOLID, DRY et KISS.
.PARAMETER AnalysisPath
    Chemin du fichier d'analyse (par dÃ©faut : ..\D)
.PARAMETER AutoApply
    Applique automatiquement la rÃ©organisation
.PARAMETER Verbose
    Affiche des informations dÃ©taillÃ©es
.EXAMPLE
    .\Set-Scripts.ps1
    Affiche le plan de rÃ©organisation sans l'appliquer
.EXAMPLE
    .\Set-Scripts.ps1 -AutoApply
    Applique automatiquement la rÃ©organisation
#>

param (
    [string]$AnalysisPath = "..\D",
    [switch]$AutoApply
)

# DÃ©finition des couleurs pour l'affichage
$Colors = @{
    Title = "Cyan"
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
    Info = "White"
    Category = "Magenta"
    Path = "DarkYellow"
}

# Fonction pour Ã©crire des messages de log
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "TITLE")]
        [string]$Level = "INFO"
    )
    
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = $Colors.Info
        "SUCCESS" = $Colors.Success
        "WARNING" = $Colors.Warning
        "ERROR" = $Colors.Error
        "TITLE" = $Colors.Title
    }
    
    $Color = $ColorMap[$Level]
    $FormattedMessage = "[$TimeStamp] [$Level] $Message"
    
    Write-Host $FormattedMessage -ForegroundColor $Color
    
    # Ã‰crire dans un fichier de log
    $LogFile = "..\D"
    Add-Content -Path $LogFile -Value $FormattedMessage
}

# VÃ©rifier si le fichier d'analyse existe
if (-not (Test-Path -Path $AnalysisPath)) {
    Write-Log "Fichier d'analyse non trouvÃ©: $AnalysisPath" -Level "ERROR"
    exit 1
}

# Charger l'analyse
$Analysis = Get-Content -Path $AnalysisPath -Raw | ConvertFrom-Json

# Afficher la banniÃ¨re
Write-Log "=== RÃ©organisation avancÃ©e des scripts ===" -Level "TITLE"
Write-Log "Fichier d'analyse: $AnalysisPath" -Level "INFO"
Write-Log "Mode: $(if ($AutoApply) { 'Application automatique' } else { 'Simulation' })" -Level "INFO"
Write-Log ""

# DÃ©finir la nouvelle structure de dossiers
$FolderStructure = @{
    "core" = @{
        "Description" = "FonctionnalitÃ©s essentielles et modules de base"
        "SubFolders" = @{
            "config" = "Configuration du systÃ¨me"
            "logging" = "Journalisation et rapports"
            "utils" = "Utilitaires gÃ©nÃ©riques"
        }
    }
    "api" = @{
        "Description" = "Scripts d'interaction avec les APIs"
        "SubFolders" = @{
            "n8n" = "API N8N"
            "external" = "Autres APIs externes"
        }
    }
    "workflow" = @{
        "Description" = "Gestion des workflows"
        "SubFolders" = @{
            "import" = "Import de workflows"
            "export" = "Export de workflows"
            "validation" = "Validation de workflows"
            "templates" = "Templates de workflows"
            "monitoring" = "Surveillance des workflows"
        }
    }
    "maintenance" = @{
        "Description" = "Scripts de maintenance"
        "SubFolders" = @{
            "cleanup" = "Nettoyage"
            "encoding" = "Gestion d'encodage"
            "monitoring" = "Surveillance du systÃ¨me"
            "repo" = "Maintenance du dÃ©pÃ´t"
        }
    }
    "setup" = @{
        "Description" = "Scripts d'installation et configuration"
        "SubFolders" = @{
            "env" = "Configuration d'environnement"
            "mcp" = "Configuration MCP"
            "git" = "Configuration Git"
        }
    }
    "journal" = @{
        "Description" = "SystÃ¨me de journal"
        "SubFolders" = @{
            "rag" = "FonctionnalitÃ©s RAG"
            "web" = "Interface web"
            "analysis" = "Analyse des journaux"
            "integrations" = "IntÃ©grations avec d'autres systÃ¨mes"
        }
    }
    "manager" = @{
        "Description" = "SystÃ¨me de gestion des scripts"
        "SubFolders" = @{
            "modules" = "Modules du gestionnaire"
            "config" = "Configuration"
            "data" = "DonnÃ©es gÃ©nÃ©rÃ©es"
        }
    }
    "docs" = @{
        "Description" = "Documentation"
        "SubFolders" = @{
            "guides" = "Guides d'utilisation"
            "references" = "Documentation de rÃ©fÃ©rence"
        }
    }
    "email" = @{
        "Description" = "FonctionnalitÃ©s liÃ©es aux emails"
        "SubFolders" = @{
            "templates" = "Templates d'emails"
            "sending" = "Envoi d'emails"
            "processing" = "Traitement d'emails"
        }
    }
    "testing" = @{
        "Description" = "Tests et validation"
        "SubFolders" = @{
            "unit" = "Tests unitaires"
            "integration" = "Tests d'intÃ©gration"
            "performance" = "Tests de performance"
        }
    }
    "utils" = @{
        "Description" = "Utilitaires divers"
        "SubFolders" = @{
            "git" = "Utilitaires Git"
            "json" = "Manipulation de JSON"
            "markdown" = "Manipulation de Markdown"
            "automation" = "Automatisation"
        }
    }
    "mcp" = @{
        "Description" = "Model Context Protocol"
        "SubFolders" = @{
            "config" = "Configuration MCP"
            "server" = "Serveurs MCP"
            "integrations" = "IntÃ©grations MCP"
        }
    }
    "python" = @{
        "Description" = "Scripts Python"
        "SubFolders" = @{
            "journal" = "Journal en Python"
            "utils" = "Utilitaires Python"
        }
    }
}

# CrÃ©er les dossiers s'ils n'existent pas
function New-FolderStructure {
    param (
        [string]$BasePath = "scripts"
    )
    
    Write-Log "CrÃ©ation de la structure de dossiers..." -Level "INFO"
    
    # CrÃ©er le dossier de base s'il n'existe pas
    if (-not (Test-Path -Path $BasePath)) {
        if ($AutoApply) {
            New-Item -ItemType Directory -Path $BasePath -Force | Out-Null
            Write-Log "Dossier crÃ©Ã©: $BasePath" -Level "SUCCESS"
        } else {
            Write-Log "[SIMULATION] Dossier Ã  crÃ©er: $BasePath" -Level "INFO"
        }
    }
    
    # CrÃ©er les dossiers principaux et leurs sous-dossiers
    foreach ($MainFolder in $FolderStructure.Keys) {
        $MainFolderPath = Join-Path -Path $BasePath -ChildPath $MainFolder
        
        if (-not (Test-Path -Path $MainFolderPath)) {
            if ($AutoApply) {
                New-Item -ItemType Directory -Path $MainFolderPath -Force | Out-Null
                Write-Log "Dossier crÃ©Ã©: $MainFolderPath" -Level "SUCCESS"
            } else {
                Write-Log "[SIMULATION] Dossier Ã  crÃ©er: $MainFolderPath" -Level "INFO"
            }
        }
        
        # CrÃ©er les sous-dossiers
        foreach ($SubFolder in $FolderStructure[$MainFolder].SubFolders.Keys) {
            $SubFolderPath = Join-Path -Path $MainFolderPath -ChildPath $SubFolder
            
            if (-not (Test-Path -Path $SubFolderPath)) {
                if ($AutoApply) {
                    New-Item -ItemType Directory -Path $SubFolderPath -Force | Out-Null
                    Write-Log "Sous-dossier crÃ©Ã©: $SubFolderPath" -Level "SUCCESS"
                } else {
                    Write-Log "[SIMULATION] Sous-dossier Ã  crÃ©er: $SubFolderPath" -Level "INFO"
                }
            }
        }
    }
    
    Write-Log "Structure de dossiers crÃ©Ã©e avec succÃ¨s" -Level "SUCCESS"
}

# Fonction pour dÃ©terminer le dossier cible pour un script
function Get-TargetFolder {
    param (
        [string]$Category,
        [string]$SubCategory,
        [string]$Path,
        [string]$Name,
        [string]$ScriptType
    )
    
    # Mapper les catÃ©gories aux dossiers principaux
    $CategoryToMainFolder = @{
        "Email" = "email"
        "Documentation" = "docs"
        "Git" = "utils\git"
        "Journal" = "journal"
        "Roadmap" = "docs"
        "Setup" = "setup"
        "Utils" = "utils"
        "Testing" = "testing"
        "Workflow" = "workflow"
        "Encoding" = "maintenance\encoding"
        "Database" = "core\config"
        "N8N" = "workflow"
        "API" = "api"
        "Maintenance" = "maintenance"
        "Security" = "core"
        "MCP" = "mcp"
        "Divers" = "utils"
    }
    
    # Mapper les sous-catÃ©gories aux sous-dossiers
    $SubCategoryToSubFolder = @{
        "General" = ""
        "Repository" = "repo"
        "Encoding" = "encoding"
        "Cleanup" = "cleanup"
        "MCP" = "mcp"
        "Environment" = "env"
        "Dependencies" = "env"
        "Validation" = "validation"
        "Testing" = "testing"
        "Monitoring" = "monitoring"
        "Markdown" = "markdown"
        "JSON" = "json"
        "XML" = "utils"
        "HTML" = "utils"
        "Automation" = "automation"
        "N8N" = "n8n"
        "Google" = "external"
        "REST" = "external"
    }
    
    # DÃ©terminer le dossier principal
    $MainFolder = $CategoryToMainFolder[$Category]
    if (-not $MainFolder) {
        $MainFolder = "utils"
    }
    
    # DÃ©terminer le sous-dossier
    $SubFolder = $SubCategoryToSubFolder[$SubCategory]
    if (-not $SubFolder) {
        $SubFolder = ""
    }
    
    # Cas spÃ©ciaux basÃ©s sur le chemin ou le nom du fichier
    if ($Path -match "python" -or $ScriptType -eq "Python") {
        if ($Path -match "journal") {
            $MainFolder = "python\journal"
            $SubFolder = ""
        } else {
            $MainFolder = "python"
            $SubFolder = "utils"
        }
    }
    
    if ($Path -match "workflow" -and $Path -match "import") {
        $MainFolder = "workflow"
        $SubFolder = "import"
    }
    
    if ($Path -match "workflow" -and $Path -match "export") {
        $MainFolder = "workflow"
        $SubFolder = "export"
    }
    
    if ($Path -match "workflow" -and $Path -match "validation") {
        $MainFolder = "workflow"
        $SubFolder = "validation"
    }
    
    if ($Path -match "workflow" -and $Path -match "monitoring") {
        $MainFolder = "workflow"
        $SubFolder = "monitoring"
    }
    
    if ($Path -match "maintenance" -and $Path -match "encoding") {
        $MainFolder = "maintenance"
        $SubFolder = "encoding"
    }
    
    if ($Path -match "maintenance" -and $Path -match "cleanup") {
        $MainFolder = "maintenance"
        $SubFolder = "cleanup"
    }
    
    if ($Path -match "maintenance" -and $Path -match "repo") {
        $MainFolder = "maintenance"
        $SubFolder = "repo"
    }
    
    if ($Path -match "setup" -and $Path -match "mcp") {
        $MainFolder = "setup"
        $SubFolder = "mcp"
    }
    
    if ($Path -match "setup" -and $Path -match "git") {
        $MainFolder = "setup"
        $SubFolder = "git"
    }
    
    if ($Path -match "setup" -and $Path -match "env") {
        $MainFolder = "setup"
        $SubFolder = "env"
    }
    
    if ($Path -match "journal" -and $Path -match "rag") {
        $MainFolder = "journal"
        $SubFolder = "rag"
    }
    
    if ($Path -match "journal" -and $Path -match "web") {
        $MainFolder = "journal"
        $SubFolder = "web"
    }
    
    if ($Path -match "journal" -and $Path -match "analysis") {
        $MainFolder = "journal"
        $SubFolder = "analysis"
    }
    
    if ($Path -match "manager" -and $Path -match "modules") {
        $MainFolder = "manager"
        $SubFolder = "modules"
    }
    
    if ($Path -match "manager" -and $Path -match "config") {
        $MainFolder = "manager"
        $SubFolder = "config"
    }
    
    if ($Path -match "manager" -and $Path -match "data") {
        $MainFolder = "manager"
        $SubFolder = "data"
    }
    
    if ($Path -match "mcp" -and $Path -match "config") {
        $MainFolder = "mcp"
        $SubFolder = "config"
    }
    
    if ($Path -match "mcp" -and $Path -match "server") {
        $MainFolder = "mcp"
        $SubFolder = "server"
    }
    
    if ($Path -match "mcp" -and $Path -match "integrations") {
        $MainFolder = "mcp"
        $SubFolder = "integrations"
    }
    
    if ($Path -match "utils" -and $Path -match "git") {
        $MainFolder = "utils"
        $SubFolder = "git"
    }
    
    if ($Path -match "utils" -and $Path -match "json") {
        $MainFolder = "utils"
        $SubFolder = "json"
    }
    
    if ($Path -match "utils" -and $Path -match "markdown") {
        $MainFolder = "utils"
        $SubFolder = "markdown"
    }
    
    if ($Path -match "utils" -and $Path -match "automation") {
        $MainFolder = "utils"
        $SubFolder = "automation"
    }
    
    # Construire le chemin complet
    if ($SubFolder) {
        return "scripts\$MainFolder\$SubFolder"
    } else {
        return "scripts\$MainFolder"
    }
}

# Fonction pour crÃ©er un fichier README pour chaque dossier
function New-ReadmeFiles {
    param (
        [string]$BasePath = "scripts"
    )
    
    Write-Log "CrÃ©ation des fichiers README..." -Level "INFO"
    
    # CrÃ©er le README principal
    $MainReadmePath = Join-Path -Path $BasePath -ChildPath "README.md"
    $MainReadmeContent = @"
# Scripts du projet

Ce dossier contient tous les scripts du projet, organisÃ©s de maniÃ¨re hiÃ©rarchique selon leur fonction.

## Structure des dossiers

"@
    
    # Ajouter la description de chaque dossier principal
    foreach ($MainFolder in $FolderStructure.Keys | Sort-Object) {
        $MainReadmeContent += "`n### $MainFolder`n`n"
        $MainReadmeContent += "$($FolderStructure[$MainFolder].Description)`n`n"
        
        # Ajouter la description des sous-dossiers
        foreach ($SubFolder in $FolderStructure[$MainFolder].SubFolders.Keys | Sort-Object) {
            $MainReadmeContent += "- **$SubFolder**: $($FolderStructure[$MainFolder].SubFolders[$SubFolder])`n"
        }
    }
    
    # Ajouter des informations sur l'utilisation
    $MainReadmeContent += @"

## Utilisation

Pour gÃ©rer ces scripts, utilisez le systÃ¨me de gestion de scripts dans le dossier `manager`.

Exemple:
```powershell
.\manager\ScriptManager.ps1 -Action inventory
```

## Principes de dÃ©veloppement

Les scripts de ce projet suivent les principes suivants:

- **SOLID**: Chaque script a une responsabilitÃ© unique et bien dÃ©finie
- **DRY** (Don't Repeat Yourself): Ã‰vite la duplication de code
- **KISS** (Keep It Simple, Stupid): PrivilÃ©gie les solutions simples et comprÃ©hensibles
- **Clean Code**: Code lisible, bien commentÃ© et facile Ã  maintenir
"@
    
    if ($AutoApply) {
        Set-Content -Path $MainReadmePath -Value $MainReadmeContent
        Write-Log "Fichier README principal crÃ©Ã©: $MainReadmePath" -Level "SUCCESS"
    } else {
        Write-Log "[SIMULATION] Fichier README principal Ã  crÃ©er: $MainReadmePath" -Level "INFO"
    }
    
    # CrÃ©er un README pour chaque dossier principal
    foreach ($MainFolder in $FolderStructure.Keys) {
        $MainFolderPath = Join-Path -Path $BasePath -ChildPath $MainFolder
        $ReadmePath = Join-Path -Path $MainFolderPath -ChildPath "README.md"
        
        $ReadmeContent = @"
# $MainFolder

$($FolderStructure[$MainFolder].Description)

## Sous-dossiers

"@
        
        # Ajouter la description des sous-dossiers
        foreach ($SubFolder in $FolderStructure[$MainFolder].SubFolders.Keys | Sort-Object) {
            $ReadmeContent += "`n### $SubFolder`n`n"
            $ReadmeContent += "$($FolderStructure[$MainFolder].SubFolders[$SubFolder])`n"
        }
        
        if ($AutoApply) {
            Set-Content -Path $ReadmePath -Value $ReadmeContent
            Write-Log "Fichier README crÃ©Ã©: $ReadmePath" -Level "SUCCESS"
        } else {
            Write-Log "[SIMULATION] Fichier README Ã  crÃ©er: $ReadmePath" -Level "INFO"
        }
        
        # CrÃ©er un README pour chaque sous-dossier
        foreach ($SubFolder in $FolderStructure[$MainFolder].SubFolders.Keys) {
            $SubFolderPath = Join-Path -Path $MainFolderPath -ChildPath $SubFolder
            $SubReadmePath = Join-Path -Path $SubFolderPath -ChildPath "README.md"
            
            $SubReadmeContent = @"
# $SubFolder

$($FolderStructure[$MainFolder].SubFolders[$SubFolder])

Ce dossier fait partie de la section [$MainFolder](..) qui contient $($FolderStructure[$MainFolder].Description.ToLower()).
"@
            
            if ($AutoApply) {
                Set-Content -Path $SubReadmePath -Value $SubReadmeContent
                Write-Log "Fichier README crÃ©Ã©: $SubReadmePath" -Level "SUCCESS"
            } else {
                Write-Log "[SIMULATION] Fichier README Ã  crÃ©er: $SubReadmePath" -Level "INFO"
            }
        }
    }
    
    Write-Log "Fichiers README crÃ©Ã©s avec succÃ¨s" -Level "SUCCESS"
}

# Fonction pour rÃ©organiser les scripts
function Set-Scripts {
    param (
        [array]$Scripts
    )
    
    Write-Log "RÃ©organisation des scripts..." -Level "INFO"
    
    # CrÃ©er un tableau pour stocker les rÃ©sultats de la rÃ©organisation
    $ReorganizationResults = @()
    
    # Traiter chaque script
    $Counter = 0
    $Total = $Scripts.Count
    
    foreach ($Script in $Scripts) {
        $Counter++
        $Progress = [math]::Round(($Counter / $Total) * 100)
        Write-Progress -Activity "RÃ©organisation des scripts" -Status "$Counter / $Total ($Progress%)" -PercentComplete $Progress
        
        # DÃ©terminer le dossier cible
        $TargetFolder = Get-TargetFolder -Category $Script.Category -SubCategory $Script.SubCategory -Path $Script.Path -Name $Script.Name -ScriptType $Script.Type
        
        # DÃ©terminer le chemin source et le chemin cible
        $SourcePath = $Script.Path
        $TargetPath = Join-Path -Path $TargetFolder -ChildPath $Script.Name
        
        # CrÃ©er un objet avec les rÃ©sultats de la rÃ©organisation
        $ReorganizationResult = [PSCustomObject]@{
            Name = $Script.Name
            SourcePath = $SourcePath
            TargetPath = $TargetPath
            Category = $Script.Category
            SubCategory = $Script.SubCategory
            Type = $Script.Type
            Success = $false
            Error = $null
        }
        
        # Afficher les informations sur le dÃ©placement
        Write-Host "DÃ©placement de " -NoNewline
        Write-Host $SourcePath -ForegroundColor $Colors.Path -NoNewline
        Write-Host " vers " -NoNewline
        Write-Host $TargetPath -ForegroundColor $Colors.Path
        
        # Si AutoApply est activÃ©, dÃ©placer le script
        if ($AutoApply) {
            try {
                # CrÃ©er le dossier cible s'il n'existe pas
                $TargetDir = Split-Path -Path $TargetPath -Parent
                if (-not (Test-Path -Path $TargetDir)) {
                    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
                    Write-Log "  Dossier crÃ©Ã©: $TargetDir" -Level "SUCCESS"
                }
                
                # DÃ©placer le script
                Move-Item -Path $SourcePath -Destination $TargetPath -Force
                
                # Mettre Ã  jour l'objet de rÃ©sultat
                $ReorganizationResult.Success = $true
                
                Write-Log "  DÃ©placement rÃ©ussi" -Level "SUCCESS"
            } catch {
                # Mettre Ã  jour l'objet de rÃ©sultat
                $ReorganizationResult.Success = $false
                $ReorganizationResult.Error = $_.Exception.Message
                
                Write-Log "  Erreur: $($_.Exception.Message)" -Level "ERROR"
            }
        } else {
            Write-Log "  [SIMULATION] Le script ne sera pas dÃ©placÃ©" -Level "INFO"
        }
        
        # Ajouter l'objet au tableau
        $ReorganizationResults += $ReorganizationResult
    }
    
    Write-Progress -Activity "RÃ©organisation des scripts" -Completed
    
    # CrÃ©er un objet avec les rÃ©sultats de la rÃ©organisation
    $Reorganization = [PSCustomObject]@{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TotalScripts = $ReorganizationResults.Count
        SuccessCount = ($ReorganizationResults | Where-Object { $_.Success } | Measure-Object).Count
        ErrorCount = ($ReorganizationResults | Where-Object { -not $_.Success } | Measure-Object).Count
        AutoApply = $AutoApply
        Results = $ReorganizationResults
    }
    
    # Convertir l'objet en JSON et l'enregistrer dans un fichier
    $OutputPath = "..\D"
    $Reorganization | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath
    
    Write-Log "RÃ©organisation terminÃ©e" -Level "SUCCESS"
    Write-Log "Nombre total de scripts: $($Reorganization.TotalScripts)" -Level "INFO"
    Write-Log "Nombre de scripts dÃ©placÃ©s avec succÃ¨s: $($Reorganization.SuccessCount)" -Level "SUCCESS"
    Write-Log "Nombre d'erreurs: $($Reorganization.ErrorCount)" -Level "WARNING"
    
    Write-Log "RÃ©sultats enregistrÃ©s dans: $OutputPath" -Level "INFO"
    
    return $Reorganization
}

# ExÃ©cuter la rÃ©organisation
New-FolderStructure
New-ReadmeFiles
$Reorganization = Set-Scripts -Scripts $Analysis.Scripts

# Afficher un rÃ©sumÃ©
Write-Log "" -Level "INFO"
Write-Log "=== RÃ©sumÃ© de la rÃ©organisation ===" -Level "TITLE"
Write-Log "Nombre total de scripts: $($Reorganization.TotalScripts)" -Level "INFO"
Write-Log "Nombre de scripts dÃ©placÃ©s avec succÃ¨s: $($Reorganization.SuccessCount)" -Level "SUCCESS"
Write-Log "Nombre d'erreurs: $($Reorganization.ErrorCount)" -Level "WARNING"

# Si AutoApply n'est pas activÃ©, afficher un message pour expliquer comment appliquer les recommandations
if (-not $AutoApply) {
    Write-Log "" -Level "INFO"
    Write-Log "Pour appliquer la rÃ©organisation, exÃ©cutez la commande suivante:" -Level "WARNING"
    Write-Log ".\Set-Scripts.ps1 -AutoApply" -Level "INFO"
}



