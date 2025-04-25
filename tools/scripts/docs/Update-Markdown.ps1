# Update-Markdown.ps1
# Script pour mettre à jour directement le fichier Markdown

param (
    [Parameter(Mandatory = $false)]
    [string]$TaskId,
    
    [Parameter(Mandatory = $false)]
    [switch]$Complete,
    
    [Parameter(Mandatory = $false)]
    [switch]$Start,
    
    [Parameter(Mandatory = $false)]
    [string]$Note
)

# Chemins des fichiers
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$roadmapPath = "Roadmap\roadmap_perso.md"""

# Vérifier si le fichier existe
if (-not (Test-Path -Path $roadmapPath)) {
    Write-Error "Fichier roadmap non trouvé: $roadmapPath"
    exit 1
}

# Lire le contenu du fichier Markdown
$content = Get-Content -Path $roadmapPath -Encoding UTF8

# Si un ID de tâche est spécifié, mettre à jour cette tâche
if ($TaskId) {
    $taskPattern = "- \[([ x])\] (.+?) \((.+?)\)"
    $taskFound = $false
    
    for ($i = 0; $i -lt $content.Length; $i++) {
        if ($content[$i] -match $taskPattern) {
            $taskDescription = $matches[2]
            $taskEstimation = $matches[3]
            
            # Extraire l'ID de la tâche à partir de la description
            $taskIdFromDesc = ""
            if ($taskDescription -match "^(\d+\.\d+)") {
                $taskIdFromDesc = $matches[1]
            }
            else {
                # Essayer de déterminer l'ID de la tâche à partir du contexte
                for ($j = $i - 1; $j -ge 0; $j--) {
                    if ($content[$j] -match "^## (\d+)\.") {
                        $sectionNumber = $matches[1]
                        $taskCount = 1
                        for ($k = $j + 1; $k -lt $i; $k++) {
                            if ($content[$k] -match $taskPattern) {
                                $taskCount++
                            }
                        }
                        $taskIdFromDesc = "$sectionNumber.$taskCount"
                        break
                    }
                }
            }
            
            if ($taskIdFromDesc -eq $TaskId) {
                $taskFound = $true
                
                if ($Complete) {
                    $content[$i] = $content[$i] -replace "- \[ \]", "- [x]"
                    if (-not ($content[$i] -match " - \*Termine le ")) {
                        $content[$i] = $content[$i] + " - *Termine le $(Get-Date -Format 'dd/MM/yyyy')*"
                    }
                    Write-Host "Tâche $TaskId marquée comme terminée."
                }
                
                if ($Start -and -not ($content[$i] -match " - \*Demarre le ") -and -not ($content[$i] -match " - \*Termine le ")) {
                    $content[$i] = $content[$i] + " - *Demarre le $(Get-Date -Format 'dd/MM/yyyy')*"
                    Write-Host "Tâche $TaskId marquée comme démarrée."
                }
                
                if ($Note) {
                    $noteFound = $false
                    if ($i + 1 -lt $content.Length -and $content[$i + 1] -match "^\s+> \*Note:") {
                        $content[$i + 1] = "  > *Note: $Note*"
                        $noteFound = $true
                    }
                    
                    if (-not $noteFound) {
                        $content = $content[0..$i] + "  > *Note: $Note*" + $content[($i + 1)..($content.Length - 1)]
                    }
                    Write-Host "Note ajoutée à la tâche $TaskId."
                }
                
                # Mettre à jour le pourcentage de progression de la section
                for ($j = $i - 1; $j -ge 0; $j--) {
                    if ($content[$j] -match "^## (\d+)\.") {
                        $sectionNumber = $matches[1]
                        $totalTasks = 0
                        $completedTasks = 0
                        
                        # Compter les tâches dans cette section
                        for ($k = $j + 1; $k -lt $content.Length; $k++) {
                            if ($content[$k] -match "^## ") {
                                break
                            }
                            
                            if ($content[$k] -match "- \[([ x])\]") {
                                $totalTasks++
                                if ($matches[1] -eq "x") {
                                    $completedTasks++
                                }
                            }
                        }
                        
                        # Mettre à jour le pourcentage
                        if ($totalTasks -gt 0) {
                            $progress = [math]::Round(($completedTasks / $totalTasks) * 100)
                            
                            # Trouver la ligne de progression
                            for ($k = $j + 1; $k -lt $j + 5; $k++) {
                                if ($content[$k] -match "\*\*Progression\*\*: (\d+)%") {
                                    $content[$k] = $content[$k] -replace "\*\*Progression\*\*: \d+%", "**Progression**: $progress%"
                                    break
                                }
                            }
                        }
                        
                        break
                    }
                }
                
                break
            }
        }
    }
    
    if (-not $taskFound) {
        Write-Error "Tâche avec ID '$TaskId' non trouvée."
        exit 1
    }
}

# Mettre à jour la date de dernière mise à jour
$dateUpdated = $false
for ($i = 0; $i -lt $content.Length; $i++) {
    if ($content[$i] -match "\*Derniere mise a jour:") {
        $content[$i] = "*Derniere mise a jour: $(Get-Date -Format 'dd/MM/yyyy HH:mm')*"
        $dateUpdated = $true
        break
    }
}

if (-not $dateUpdated) {
    $content += "---"
    $content += "*Derniere mise a jour: $(Get-Date -Format 'dd/MM/yyyy HH:mm')*"
}

# Sauvegarder le fichier Markdown
$content | Out-File -FilePath $roadmapPath -Encoding ascii

Write-Host "Roadmap mise à jour avec succès."
