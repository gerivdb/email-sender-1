# Script pour mettre à jour les références à la roadmap dans les scripts existants
# Ce script remplace les références directes au fichier "Roadmap\roadmap_perso.md" par des appels au script centralisé

param (
    [Parameter(Mandatory = $false)]
    [string]$ScriptsDirectory = (Join-Path -Path (Get-Location) -ChildPath "scripts"),
    
    [Parameter(Mandatory = $false)]
    [switch]$CreateBackup,
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf,
    
    [Parameter(Mandatory = $false)]
    [string]$LogFilePath = (Join-Path -Path (Get-Location) -ChildPath "logs\roadmap_references_update.log")
)

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
    
    # Créer le répertoire de logs si nécessaire
    $logDir = Split-Path -Path $LogFilePath -Parent
    if (-not (Test-Path -Path $logDir -PathType Container)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    
    Add-Content -Path $LogFilePath -Value $logEntry -Encoding UTF8
}

try {
    # Fonction pour trouver les scripts qui font référence à "Roadmap\roadmap_perso.md"
    function Find-RoadmapReferences {
        param (
            [string]$Directory
        )
        
        Write-Log "Recherche des scripts faisant référence à "Roadmap\roadmap_perso.md" dans $Directory"
        
        $results = @()
        
        # Récupérer tous les scripts PowerShell dans le répertoire
        $scripts = Get-ChildItem -Path $Directory -Recurse -File -Filter "*.ps1" | Where-Object { -not $_.FullName.Contains(".bak") }
        Write-Log "Nombre de scripts trouvés : $($scripts.Count)"
        
        foreach ($script in $scripts) {
            Write-Verbose "Analyse du script : $($script.FullName)"
            
            # Lire le contenu du script
            $content = Get-Content -Path $script.FullName -Raw -ErrorAction SilentlyContinue
            
            if ($null -eq $content) {
                Write-Log "Impossible de lire le contenu du script : $($script.FullName)" -Level "WARNING"
                continue
            }
            
            # Vérifier les références à "Roadmap\roadmap_perso.md"
            if ($content -match "roadmap_perso\.md") {
                $results += $script.FullName
            }
        }
        
        return $results
    }

    # Fonction pour mettre à jour les références à "Roadmap\roadmap_perso.md" dans un script
    function Update-RoadmapReference {
        param (
            [string]$Path,
            [switch]$CreateBackup,
            [switch]$WhatIf
        )
        
        Write-Verbose "Mise à jour des références à "Roadmap\roadmap_perso.md" dans $Path"
        
        # Créer une sauvegarde si demandé
        if ($CreateBackup) {
            $backupPath = "$Path.bak"
            Copy-Item -Path $Path -Destination $backupPath -Force
            Write-Verbose "Sauvegarde créée : $backupPath"
        }
        
        # Lire le contenu du script
        $content = Get-Content -Path $Path -Raw
        
        # Vérifier si le script importe déjà Get-RoadmapPath.ps1
        $importsRoadmapPath = $content -match "Get-RoadmapPath\.ps1"
        
        # Remplacer les références directes à "Roadmap\roadmap_perso.md"
        $newContent = $content
        
        # 1. Remplacer les chemins relatifs simples
        $newContent = $newContent -replace '(?<!\w)roadmap_perso\.md(?!\w)', '(& (Join-Path -Path $PSScriptRoot -ChildPath "..\..\utils\roadmap\Get-RoadmapPath.ps1"))'
        
        # 2. Remplacer les chemins avec Join-Path
        $newContent = $newContent -replace 'Join-Path\s+-Path\s+[^-]+\s+-ChildPath\s+[''"]roadmap_perso\.md[''"]', '(& (Join-Path -Path $PSScriptRoot -ChildPath "..\..\utils\roadmap\Get-RoadmapPath.ps1"))'
        
        # 3. Remplacer les paramètres par défaut
        $newContent = $newContent -replace '\[string\]\$RoadmapPath\s*=\s*[''"]roadmap_perso\.md[''"]', '[string]$RoadmapPath = (& (Join-Path -Path $PSScriptRoot -ChildPath "..\..\utils\roadmap\Get-RoadmapPath.ps1"))'
        
        # Ajouter l'importation de Get-RoadmapPath.ps1 si nécessaire
        if (-not $importsRoadmapPath -and $newContent -ne $content) {
            $importStatement = @"
# Importer le module de gestion de la roadmap
`$roadmapPathScript = Join-Path -Path `$PSScriptRoot -ChildPath "..\..\utils\roadmap\Get-RoadmapPath.ps1"
if (Test-Path -Path `$roadmapPathScript) {
    . `$roadmapPathScript
}
else {
    Write-Warning "Le module de gestion de la roadmap est introuvable: `$roadmapPathScript"
}

"@
            
            # Trouver l'endroit où insérer l'importation
            $paramMatch = [regex]::Match($newContent, "(?s)^.*?param\s*\((.*?)\)", [System.Text.RegularExpressions.RegexOptions]::Singleline)
            if ($paramMatch.Success) {
                $newContent = $newContent.Insert($paramMatch.Length, "`n$importStatement")
            } else {
                $newContent = "$importStatement`n$newContent"
            }
        }
        
        # Écrire le nouveau contenu dans le fichier si des modifications ont été apportées
        if ($newContent -ne $content) {
            if (-not $WhatIf) {
                Set-Content -Path $Path -Value $newContent -Encoding UTF8
                return $true
            } else {
                Write-Log "WhatIf: Le script $Path serait mis à jour" -Level "INFO"
                return $false
            }
        } else {
            Write-Verbose "Aucune modification nécessaire pour $Path"
            return $false
        }
    }

    # Fonction principale
    function Start-RoadmapReferencesUpdate {
        Write-Log "Démarrage de la mise à jour des références à la roadmap"
        
        # Vérifier si le répertoire utils\roadmap existe
        $roadmapUtilsDir = Join-Path -Path $ScriptsDirectory -ChildPath "utils\roadmap"
        if (-not (Test-Path -Path $roadmapUtilsDir -PathType Container)) {
            New-Item -Path $roadmapUtilsDir -ItemType Directory -Force | Out-Null
            Write-Log "Répertoire utils\roadmap créé" -Level "INFO"
        }
        
        # Vérifier si le script Get-RoadmapPath.ps1 existe
        $roadmapPathScript = Join-Path -Path $roadmapUtilsDir -ChildPath "Get-RoadmapPath.ps1"
        if (-not (Test-Path -Path $roadmapPathScript -PathType Leaf)) {
            Write-Log "Le script Get-RoadmapPath.ps1 n'existe pas. Veuillez le créer d'abord." -Level "ERROR"
            return
        }
        
        # Trouver les scripts qui font référence à "Roadmap\roadmap_perso.md"
        $scriptsWithReferences = Find-RoadmapReferences -Directory $ScriptsDirectory
        
        Write-Log "Nombre de scripts faisant référence à "Roadmap\roadmap_perso.md" : $($scriptsWithReferences.Count)"
        
        $results = @{
            Total = $scriptsWithReferences.Count
            Succeeded = 0
            Failed = 0
            Details = @()
        }
        
        # Mettre à jour les références dans les scripts
        foreach ($script in $scriptsWithReferences) {
            Write-Log "Traitement du script : $script"
            
            try {
                $success = Update-RoadmapReference -Path $script -CreateBackup:$CreateBackup -WhatIf:$WhatIf
                
                if ($success) {
                    Write-Log "Références mises à jour avec succès dans : $script" -Level "INFO"
                    $results.Succeeded++
                    $results.Details += [PSCustomObject]@{
                        Path = $script
                        Status = "Success"
                        Message = "Références mises à jour avec succès"
                    }
                }
                else {
                    if ($WhatIf) {
                        $results.Succeeded++
                        $results.Details += [PSCustomObject]@{
                            Path = $script
                            Status = "WhatIf"
                            Message = "Le script serait mis à jour"
                        }
                    } else {
                        Write-Log "Aucune modification nécessaire pour : $script" -Level "INFO"
                        $results.Succeeded++
                        $results.Details += [PSCustomObject]@{
                            Path = $script
                            Status = "NoChange"
                            Message = "Aucune modification nécessaire"
                        }
                    }
                }
            }
            catch {
                Write-Log "Erreur lors du traitement du script $script : $_" -Level "ERROR"
                $results.Failed++
                $results.Details += [PSCustomObject]@{
                    Path = $script
                    Status = "Failed"
                    Message = "Erreur : $_"
                }
            }
        }
        
        # Générer un rapport
        $reportPath = Join-Path -Path (Split-Path -Parent $LogFilePath) -ChildPath "roadmap_references_report.json"
        $results | ConvertTo-Json -Depth 3 | Set-Content -Path $reportPath -Encoding UTF8
        
        Write-Log "Rapport généré : $reportPath"
        
        # Afficher un résumé
        Write-Host "`nRésumé de la mise à jour des références à la roadmap :" -ForegroundColor Cyan
        Write-Host "----------------------------------------" -ForegroundColor Cyan
        Write-Host "Scripts analysés : $($results.Total)" -ForegroundColor White
        Write-Host "Mises à jour réussies : $($results.Succeeded)" -ForegroundColor Green
        Write-Host "Échecs : $($results.Failed)" -ForegroundColor Red
        
        return $results
    }

    # Exécuter la fonction principale
    Start-RoadmapReferencesUpdate
}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "Exécution du script terminée."
}
