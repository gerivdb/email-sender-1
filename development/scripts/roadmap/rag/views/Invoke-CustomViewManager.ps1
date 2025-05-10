# Invoke-CustomViewManager.ps1
# Script pour gérer les vues personnalisées existantes
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ViewsDir,
    
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("List", "Show", "Edit", "Delete", "Export", "Import")]
    [string]$Action = "List",
    
    [Parameter(Mandatory = $false)]
    [string]$ViewName,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Console", "HTML", "Markdown")]
    [string]$OutputFormat = "Console"
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$utilsPath = Join-Path -Path $parentPath -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        $color = switch ($Level) {
            "Info" { "White" }
            "Warning" { "Yellow" }
            "Error" { "Red" }
            "Success" { "Green" }
            "Debug" { "Gray" }
        }
        
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

# Fonction pour obtenir la liste des vues personnalisées
function Get-CustomViews {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ViewsDir
    )
    
    Write-Log "Recherche des vues personnalisées dans : $ViewsDir" -Level "Info"
    
    if (-not (Test-Path -Path $ViewsDir)) {
        Write-Log "Le répertoire des vues n'existe pas : $ViewsDir" -Level "Error"
        return @()
    }
    
    $viewFiles = Get-ChildItem -Path $ViewsDir -Filter "custom_view_*.json" -File
    
    if ($viewFiles.Count -eq 0) {
        Write-Log "Aucune vue personnalisée trouvée." -Level "Warning"
        return @()
    }
    
    $views = @()
    
    foreach ($file in $viewFiles) {
        try {
            $config = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json -AsHashtable
            
            $view = @{
                Name = $config.Name
                FilePath = $file.FullName
                FileName = $file.Name
                CreatedAt = if ($config.ContainsKey("CreatedAt")) { $config.CreatedAt } else { "Inconnue" }
                FinalizedAt = if ($config.ContainsKey("FinalizedAt")) { $config.FinalizedAt } else { "Inconnue" }
                CriteriaCount = if ($config.ContainsKey("Criteria")) { $config.Criteria.Count } else { 0 }
                CombinationMode = if ($config.ContainsKey("Combination")) { $config.Combination.Mode } else { "Inconnu" }
                Configuration = $config
            }
            
            $views += $view
        } catch {
            Write-Log "Erreur lors du chargement de la vue : $($file.Name) - $_" -Level "Error"
        }
    }
    
    Write-Log "$($views.Count) vues personnalisées trouvées." -Level "Success"
    
    return $views
}

# Fonction pour afficher la liste des vues personnalisées
function Show-CustomViewsList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Views
    )
    
    Write-Host "`n=== VUES PERSONNALISÉES DISPONIBLES ===`n" -ForegroundColor Cyan
    
    if ($Views.Count -eq 0) {
        Write-Host "Aucune vue personnalisée disponible." -ForegroundColor Yellow
        return
    }
    
    for ($i = 0; $i -lt $Views.Count; $i++) {
        $view = $Views[$i]
        
        Write-Host "$($i+1). $($view.Name)" -ForegroundColor Green
        Write-Host "   Créée le : $($view.CreatedAt)"
        Write-Host "   Finalisée le : $($view.FinalizedAt)"
        Write-Host "   Critères : $($view.CriteriaCount)"
        Write-Host "   Mode de combinaison : $($view.CombinationMode)"
        Write-Host "   Fichier : $($view.FileName)"
        Write-Host ""
    }
}

# Fonction pour afficher une vue personnalisée
function Show-CustomView {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$View,
        
        [Parameter(Mandatory = $false)]
        [string]$RoadmapPath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Console", "HTML", "Markdown")]
        [string]$OutputFormat = "Console"
    )
    
    Write-Log "Affichage de la vue personnalisée : $($View.Name)" -Level "Info"
    
    $previewScript = Join-Path -Path $scriptPath -ChildPath "Show-ViewPreview.ps1"
    
    if (-not (Test-Path -Path $previewScript)) {
        Write-Log "Script de prévisualisation introuvable : $previewScript" -Level "Error"
        return $false
    }
    
    $previewParams = @{
        ConfigPath = $View.FilePath
        OutputFormat = $OutputFormat
    }
    
    if (-not [string]::IsNullOrEmpty($RoadmapPath)) {
        $previewParams.RoadmapPath = $RoadmapPath
    }
    
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        $previewParams.OutputPath = $OutputPath
    }
    
    $previewResult = & $previewScript @previewParams
    
    return $previewResult
}

# Fonction pour éditer une vue personnalisée
function Edit-CustomView {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$View,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )
    
    Write-Log "Édition de la vue personnalisée : $($View.Name)" -Level "Info"
    
    # Charger la configuration
    $config = $View.Configuration
    
    # Afficher les options d'édition
    Write-Host "`n=== ÉDITION DE LA VUE : $($View.Name) ===`n" -ForegroundColor Cyan
    Write-Host "Options d'édition :"
    Write-Host "  1. Modifier le nom"
    Write-Host "  2. Modifier les critères"
    Write-Host "  3. Modifier le mode de combinaison"
    Write-Host "  4. Annuler"
    Write-Host "`nChoisissez une option (1-4) :"
    
    $option = Read-Host
    
    switch ($option) {
        "1" {
            Write-Host "`nNom actuel : $($config.Name)"
            Write-Host "Nouveau nom :"
            $newName = Read-Host
            
            if (-not [string]::IsNullOrEmpty($newName)) {
                $config.Name = $newName
                Write-Log "Nom modifié : $newName" -Level "Success"
            }
        }
        "2" {
            # Modifier les critères
            Write-Host "`nCritères actuels :"
            
            $criteriaTypes = @($config.Criteria.Keys)
            
            for ($i = 0; $i -lt $criteriaTypes.Count; $i++) {
                $criteriaType = $criteriaTypes[$i]
                $values = $config.Criteria[$criteriaType] -join ", "
                Write-Host "  $($i+1). $criteriaType : $values"
            }
            
            Write-Host "`nOptions :"
            Write-Host "  A. Ajouter un critère"
            Write-Host "  M. Modifier un critère existant"
            Write-Host "  S. Supprimer un critère"
            Write-Host "  R. Retour"
            Write-Host "`nChoisissez une option (A/M/S/R) :"
            
            $criteriaOption = Read-Host
            
            switch ($criteriaOption.ToUpper()) {
                "A" {
                    Write-Host "`nType de critère à ajouter :"
                    Write-Host "  1. Status"
                    Write-Host "  2. Priority"
                    Write-Host "  3. Category"
                    Write-Host "  4. Tags"
                    Write-Host "`nChoisissez un type (1-4) :"
                    
                    $typeOption = Read-Host
                    $newType = switch ($typeOption) {
                        "1" { "Status" }
                        "2" { "Priority" }
                        "3" { "Category" }
                        "4" { "Tags" }
                        default { $null }
                    }
                    
                    if ($null -ne $newType) {
                        Write-Host "`nValeurs (séparées par des virgules) :"
                        $valuesInput = Read-Host
                        
                        if (-not [string]::IsNullOrEmpty($valuesInput)) {
                            $newValues = $valuesInput.Split(',') | ForEach-Object { $_.Trim() }
                            $config.Criteria[$newType] = $newValues
                            Write-Log "Critère ajouté : $newType" -Level "Success"
                        }
                    }
                }
                "M" {
                    Write-Host "`nNuméro du critère à modifier :"
                    $criteriaIndex = [int](Read-Host) - 1
                    
                    if ($criteriaIndex -ge 0 -and $criteriaIndex -lt $criteriaTypes.Count) {
                        $typeToModify = $criteriaTypes[$criteriaIndex]
                        $currentValues = $config.Criteria[$typeToModify] -join ", "
                        
                        Write-Host "`nValeurs actuelles : $currentValues"
                        Write-Host "Nouvelles valeurs (séparées par des virgules) :"
                        $valuesInput = Read-Host
                        
                        if (-not [string]::IsNullOrEmpty($valuesInput)) {
                            $newValues = $valuesInput.Split(',') | ForEach-Object { $_.Trim() }
                            $config.Criteria[$typeToModify] = $newValues
                            Write-Log "Critère modifié : $typeToModify" -Level "Success"
                        }
                    } else {
                        Write-Log "Index de critère invalide." -Level "Error"
                    }
                }
                "S" {
                    Write-Host "`nNuméro du critère à supprimer :"
                    $criteriaIndex = [int](Read-Host) - 1
                    
                    if ($criteriaIndex -ge 0 -and $criteriaIndex -lt $criteriaTypes.Count) {
                        $typeToRemove = $criteriaTypes[$criteriaIndex]
                        $config.Criteria.Remove($typeToRemove)
                        Write-Log "Critère supprimé : $typeToRemove" -Level "Success"
                    } else {
                        Write-Log "Index de critère invalide." -Level "Error"
                    }
                }
            }
        }
        "3" {
            # Modifier le mode de combinaison
            Write-Host "`nMode de combinaison actuel : $($config.Combination.Mode)"
            Write-Host "Nouveau mode de combinaison :"
            Write-Host "  1. ET logique (AND)"
            Write-Host "  2. OU logique (OR)"
            Write-Host "  3. Personnalisé (CUSTOM)"
            Write-Host "`nChoisissez un mode (1-3) :"
            
            $modeOption = Read-Host
            
            $newMode = switch ($modeOption) {
                "1" { "AND" }
                "2" { "OR" }
                "3" { "CUSTOM" }
                default { $null }
            }
            
            if ($null -ne $newMode) {
                $config.Combination.Mode = $newMode
                
                # Si le mode est personnalisé, demander les règles
                if ($newMode -eq "CUSTOM") {
                    $config.Combination.Rules = @{}
                    
                    $criteriaTypes = @($config.Criteria.Keys)
                    
                    for ($i = 0; $i -lt $criteriaTypes.Count; $i++) {
                        for ($j = $i + 1; $j -lt $criteriaTypes.Count; $j++) {
                            $criteria1 = $criteriaTypes[$i]
                            $criteria2 = $criteriaTypes[$j]
                            
                            Write-Host "`nRelation entre '$criteria1' et '$criteria2' :"
                            Write-Host "  1. ET (AND)"
                            Write-Host "  2. OU (OR)"
                            Write-Host "Choisissez une relation (1-2) :"
                            
                            $ruleOption = Read-Host
                            
                            $rule = switch ($ruleOption) {
                                "2" { "OR" }
                                default { "AND" }
                            }
                            
                            $config.Combination.Rules["$criteria1-$criteria2"] = $rule
                        }
                    }
                } else {
                    # Supprimer les règles personnalisées si le mode n'est pas CUSTOM
                    $config.Combination.Remove("Rules")
                }
                
                Write-Log "Mode de combinaison modifié : $newMode" -Level "Success"
            }
        }
        "4" {
            Write-Log "Édition annulée." -Level "Info"
            return $false
        }
    }
    
    # Mettre à jour la date de modification
    $config.ModifiedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Sauvegarder la configuration
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $OutputPath = $View.FilePath
    }
    
    try {
        $config | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
        Write-Log "Configuration modifiée sauvegardée dans : $OutputPath" -Level "Success"
        return $true
    } catch {
        Write-Log "Erreur lors de la sauvegarde de la configuration modifiée : $_" -Level "Error"
        return $false
    }
}

# Fonction pour supprimer une vue personnalisée
function Remove-CustomView {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$View
    )
    
    Write-Log "Suppression de la vue personnalisée : $($View.Name)" -Level "Info"
    
    Write-Host "`n=== SUPPRESSION DE LA VUE : $($View.Name) ===`n" -ForegroundColor Cyan
    Write-Host "Êtes-vous sûr de vouloir supprimer cette vue ? (O/N)"
    
    $confirmation = Read-Host
    
    if ($confirmation -eq "O" -or $confirmation -eq "o") {
        try {
            Remove-Item -Path $View.FilePath -Force
            Write-Log "Vue supprimée avec succès." -Level "Success"
            return $true
        } catch {
            Write-Log "Erreur lors de la suppression de la vue : $_" -Level "Error"
            return $false
        }
    } else {
        Write-Log "Suppression annulée." -Level "Info"
        return $false
    }
}

# Fonction pour exporter une vue personnalisée
function Export-CustomView {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$View,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    Write-Log "Exportation de la vue personnalisée : $($View.Name)" -Level "Info"
    
    try {
        Copy-Item -Path $View.FilePath -Destination $OutputPath -Force
        Write-Log "Vue exportée avec succès vers : $OutputPath" -Level "Success"
        return $true
    } catch {
        Write-Log "Erreur lors de l'exportation de la vue : $_" -Level "Error"
        return $false
    }
}

# Fonction pour importer une vue personnalisée
function Import-CustomView {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ImportPath,
        
        [Parameter(Mandatory = $true)]
        [string]$ViewsDir
    )
    
    Write-Log "Importation d'une vue personnalisée depuis : $ImportPath" -Level "Info"
    
    if (-not (Test-Path -Path $ImportPath)) {
        Write-Log "Le fichier d'importation n'existe pas : $ImportPath" -Level "Error"
        return $false
    }
    
    try {
        # Vérifier que le fichier est une configuration valide
        $config = Get-Content -Path $ImportPath -Raw | ConvertFrom-Json -AsHashtable
        
        if (-not $config.ContainsKey("Name") -or -not $config.ContainsKey("Criteria")) {
            Write-Log "Le fichier ne contient pas une configuration de vue valide." -Level "Error"
            return $false
        }
        
        # Générer un nom de fichier unique
        $fileName = "custom_view_$($config.Name -replace '\s+', '_')_imported_$([DateTime]::Now.ToString('yyyyMMdd_HHmmss')).json"
        $outputPath = Join-Path -Path $ViewsDir -ChildPath $fileName
        
        # Copier le fichier
        Copy-Item -Path $ImportPath -Destination $outputPath -Force
        Write-Log "Vue importée avec succès : $($config.Name)" -Level "Success"
        return $true
    } catch {
        Write-Log "Erreur lors de l'importation de la vue : $_" -Level "Error"
        return $false
    }
}

# Fonction principale
function Invoke-CustomViewManager {
    [CmdletBinding()]
    param (
        [string]$ViewsDir,
        [string]$RoadmapPath,
        [string]$Action,
        [string]$ViewName,
        [string]$OutputPath,
        [string]$OutputFormat
    )
    
    Write-Log "Démarrage du gestionnaire de vues personnalisées..." -Level "Info"
    
    # Définir le répertoire des vues par défaut si non spécifié
    if ([string]::IsNullOrEmpty($ViewsDir)) {
        $ViewsDir = Join-Path -Path (Get-Location) -ChildPath "custom_views"
    }
    
    # Créer le répertoire des vues s'il n'existe pas
    if (-not (Test-Path -Path $ViewsDir)) {
        try {
            New-Item -Path $ViewsDir -ItemType Directory -Force | Out-Null
            Write-Log "Répertoire des vues créé : $ViewsDir" -Level "Success"
        } catch {
            Write-Log "Erreur lors de la création du répertoire des vues : $_" -Level "Error"
            return $false
        }
    }
    
    # Obtenir la liste des vues
    $views = Get-CustomViews -ViewsDir $ViewsDir
    
    # Exécuter l'action demandée
    switch ($Action) {
        "List" {
            Show-CustomViewsList -Views $views
            return $true
        }
        "Show" {
            if ([string]::IsNullOrEmpty($ViewName)) {
                # Afficher la liste des vues et demander laquelle afficher
                Show-CustomViewsList -Views $views
                
                Write-Host "`nNuméro de la vue à afficher (1-$($views.Count)) :"
                $viewIndex = [int](Read-Host) - 1
                
                if ($viewIndex -ge 0 -and $viewIndex -lt $views.Count) {
                    $selectedView = $views[$viewIndex]
                    return Show-CustomView -View $selectedView -RoadmapPath $RoadmapPath -OutputPath $OutputPath -OutputFormat $OutputFormat
                } else {
                    Write-Log "Index de vue invalide." -Level "Error"
                    return $false
                }
            } else {
                # Rechercher la vue par nom
                $selectedView = $views | Where-Object { $_.Name -eq $ViewName } | Select-Object -First 1
                
                if ($null -ne $selectedView) {
                    return Show-CustomView -View $selectedView -RoadmapPath $RoadmapPath -OutputPath $OutputPath -OutputFormat $OutputFormat
                } else {
                    Write-Log "Vue non trouvée : $ViewName" -Level "Error"
                    return $false
                }
            }
        }
        "Edit" {
            if ([string]::IsNullOrEmpty($ViewName)) {
                # Afficher la liste des vues et demander laquelle éditer
                Show-CustomViewsList -Views $views
                
                Write-Host "`nNuméro de la vue à éditer (1-$($views.Count)) :"
                $viewIndex = [int](Read-Host) - 1
                
                if ($viewIndex -ge 0 -and $viewIndex -lt $views.Count) {
                    $selectedView = $views[$viewIndex]
                    return Edit-CustomView -View $selectedView -OutputPath $OutputPath
                } else {
                    Write-Log "Index de vue invalide." -Level "Error"
                    return $false
                }
            } else {
                # Rechercher la vue par nom
                $selectedView = $views | Where-Object { $_.Name -eq $ViewName } | Select-Object -First 1
                
                if ($null -ne $selectedView) {
                    return Edit-CustomView -View $selectedView -OutputPath $OutputPath
                } else {
                    Write-Log "Vue non trouvée : $ViewName" -Level "Error"
                    return $false
                }
            }
        }
        "Delete" {
            if ([string]::IsNullOrEmpty($ViewName)) {
                # Afficher la liste des vues et demander laquelle supprimer
                Show-CustomViewsList -Views $views
                
                Write-Host "`nNuméro de la vue à supprimer (1-$($views.Count)) :"
                $viewIndex = [int](Read-Host) - 1
                
                if ($viewIndex -ge 0 -and $viewIndex -lt $views.Count) {
                    $selectedView = $views[$viewIndex]
                    return Remove-CustomView -View $selectedView
                } else {
                    Write-Log "Index de vue invalide." -Level "Error"
                    return $false
                }
            } else {
                # Rechercher la vue par nom
                $selectedView = $views | Where-Object { $_.Name -eq $ViewName } | Select-Object -First 1
                
                if ($null -ne $selectedView) {
                    return Remove-CustomView -View $selectedView
                } else {
                    Write-Log "Vue non trouvée : $ViewName" -Level "Error"
                    return $false
                }
            }
        }
        "Export" {
            if ([string]::IsNullOrEmpty($ViewName)) {
                # Afficher la liste des vues et demander laquelle exporter
                Show-CustomViewsList -Views $views
                
                Write-Host "`nNuméro de la vue à exporter (1-$($views.Count)) :"
                $viewIndex = [int](Read-Host) - 1
                
                if ($viewIndex -ge 0 -and $viewIndex -lt $views.Count) {
                    $selectedView = $views[$viewIndex]
                    
                    if ([string]::IsNullOrEmpty($OutputPath)) {
                        $OutputPath = Join-Path -Path (Get-Location) -ChildPath "exported_view_$($selectedView.Name -replace '\s+', '_')_$([DateTime]::Now.ToString('yyyyMMdd_HHmmss')).json"
                    }
                    
                    return Export-CustomView -View $selectedView -OutputPath $OutputPath
                } else {
                    Write-Log "Index de vue invalide." -Level "Error"
                    return $false
                }
            } else {
                # Rechercher la vue par nom
                $selectedView = $views | Where-Object { $_.Name -eq $ViewName } | Select-Object -First 1
                
                if ($null -ne $selectedView) {
                    if ([string]::IsNullOrEmpty($OutputPath)) {
                        $OutputPath = Join-Path -Path (Get-Location) -ChildPath "exported_view_$($selectedView.Name -replace '\s+', '_')_$([DateTime]::Now.ToString('yyyyMMdd_HHmmss')).json"
                    }
                    
                    return Export-CustomView -View $selectedView -OutputPath $OutputPath
                } else {
                    Write-Log "Vue non trouvée : $ViewName" -Level "Error"
                    return $false
                }
            }
        }
        "Import" {
            if ([string]::IsNullOrEmpty($OutputPath)) {
                Write-Log "Chemin du fichier à importer non spécifié." -Level "Error"
                return $false
            }
            
            return Import-CustomView -ImportPath $OutputPath -ViewsDir $ViewsDir
        }
    }
    
    return $true
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Invoke-CustomViewManager -ViewsDir $ViewsDir -RoadmapPath $RoadmapPath -Action $Action -ViewName $ViewName -OutputPath $OutputPath -OutputFormat $OutputFormat
}
