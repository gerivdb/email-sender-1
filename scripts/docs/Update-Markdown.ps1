# Update-Markdown.ps1
# Script pour mettre Ã  jour directement le fichier Markdown

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
$roadmapPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) -ChildPath "roadmap_perso.md"

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $roadmapPath)) {
    Write-Error "Fichier roadmap non trouvÃ©: $roadmapPath"
    exit 1
}

# Lire le contenu du fichier Markdown
$content = Get-Content -Path $roadmapPath -Encoding UTF8

# Si un ID de tÃ¢che est spÃ©cifiÃ©, mettre Ã  jour cette tÃ¢che
if ($TaskId) {
    $taskPattern = "- \[([ x])\] (.+?) \((.+?)\)"
    $taskFound = $false
    
    for ($i = 0; $i -lt $content.Length; $i++) {
        if ($content[$i] -match $taskPattern) {
            $taskDescription = $matches[2]
            $taskEstimation = $matches[3]
            
            # Extraire l'ID de la tÃ¢che Ã  partir de la description
            $taskIdFromDesc = ""
            if ($taskDescription -match "^(\d+\.\d+)") {
                $taskIdFromDesc = $matches[1]
            }
            else {
                # Essayer de dÃ©terminer l'ID de la tÃ¢che Ã  partir du contexte
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
                    Write-Host "TÃ¢che $TaskId marquÃ©e comme terminÃ©e."
                }
                
                if ($Start -and -not ($content[$i] -match " - \*Demarre le ") -and -not ($content[$i] -match " - \*Termine le ")) {
                    $content[$i] = $content[$i] + " - *Demarre le $(Get-Date -Format 'dd/MM/yyyy')*"
                    Write-Host "TÃ¢che $TaskId marquÃ©e comme dÃ©marrÃ©e."
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
                    Write-Host "Note ajoutÃ©e Ã  la tÃ¢che $TaskId."
                }
                
                # Mettre Ã  jour le pourcentage de progression de la section
                for ($j = $i - 1; $j -ge 0; $j--) {
                    if ($content[$j] -match "^## (\d+)\.") {
                        $sectionNumber = $matches[1]
                        $totalTasks = 0
                        $completedTasks = 0
                        
                        # Compter les tÃ¢ches dans cette section
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
                        
                        # Mettre Ã  jour le pourcentage
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
        Write-Error "TÃ¢che avec ID '$TaskId' non trouvÃ©e."
        exit 1
    }
}

# Mettre Ã  jour la date de derniÃ¨re mise Ã  jour
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

Write-Host "Roadmap mise Ã  jour avec succÃ¨s."
