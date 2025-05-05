# Fonction pour simuler la gÃ©nÃ©ration de sous-tÃ¢ches avec l'IA
function Get-AIGeneratedSubTasks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskContent,
        
        [Parameter(Mandatory = $true)]
        [string]$ComplexityLevel,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Domains,
        
        [Parameter(Mandatory = $true)]
        [int]$MaxSubTasks,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )
    
    # Simuler le chargement de la configuration
    Write-Host "Chargement de la configuration de l'IA..." -ForegroundColor Gray
    
    # Extraire le titre de la tÃ¢che (tout ce qui suit l'identifiant entre ** **)
    $titleMatch = [regex]::Match($TaskContent, '\*\*[^\*]+\*\*\s+(.+)')
    $taskTitle = if ($titleMatch.Success) { $titleMatch.Groups[1].Value } else { $TaskContent }
    
    # PrÃ©parer les domaines pour le prompt
    $domainsText = if ($Domains -and $Domains.Count -gt 0) {
        $Domains -join ", "
    } else {
        "Non spÃ©cifiÃ©"
    }
    
    # Simuler l'appel Ã  l'API
    Write-Host "GÃ©nÃ©ration de sous-tÃ¢ches avec l'IA..." -ForegroundColor Yellow
    Write-Host "Utilisation de l'API : https://openrouter.ai/api/v1/chat/completions (SIMULATION)" -ForegroundColor Gray
    
    # Simuler un dÃ©lai de traitement
    Start-Sleep -Seconds 2
    
    # GÃ©nÃ©rer des sous-tÃ¢ches en fonction du domaine et de la complexitÃ©
    $generatedTasks = @()
    
    # Sous-tÃ¢ches communes Ã  tous les domaines
    $generatedTasks += "Analyser les besoins du systÃ¨me"
    
    # Sous-tÃ¢ches spÃ©cifiques au domaine Backend
    if ($Domains -contains "Backend") {
        $generatedTasks += "Concevoir l'architecture du backend"
        $generatedTasks += "ImplÃ©menter les modÃ¨les de donnÃ©es"
        $generatedTasks += "DÃ©velopper les API RESTful"
    }
    
    # Sous-tÃ¢ches spÃ©cifiques au domaine Security
    if ($Domains -contains "Security") {
        $generatedTasks += "ImplÃ©menter le systÃ¨me d'authentification"
        $generatedTasks += "Configurer les autorisations et rÃ´les"
        $generatedTasks += "Mettre en place le chiffrement des donnÃ©es sensibles"
    }
    
    # Sous-tÃ¢ches spÃ©cifiques au domaine Frontend
    if ($Domains -contains "Frontend") {
        $generatedTasks += "Concevoir l'interface utilisateur"
        $generatedTasks += "DÃ©velopper les composants React"
        $generatedTasks += "ImplÃ©menter les formulaires et validations"
    }
    
    # Sous-tÃ¢ches communes de fin
    $generatedTasks += "Tester toutes les fonctionnalitÃ©s"
    $generatedTasks += "Documenter l'API et l'utilisation"
    
    # Ajuster le nombre de sous-tÃ¢ches en fonction de la complexitÃ©
    if ($ComplexityLevel -eq "Simple") {
        # Garder seulement 3-4 tÃ¢ches pour les tÃ¢ches simples
        $generatedTasks = $generatedTasks | Select-Object -First 4
    } elseif ($ComplexityLevel -eq "Complex") {
        # Ajouter des tÃ¢ches supplÃ©mentaires pour les tÃ¢ches complexes
        $generatedTasks += "Optimiser les performances"
        $generatedTasks += "Mettre en place la surveillance et les alertes"
        $generatedTasks += "PrÃ©parer le dÃ©ploiement en production"
    }
    
    # Limiter le nombre de sous-tÃ¢ches au maximum spÃ©cifiÃ©
    if ($generatedTasks.Count -gt $MaxSubTasks) {
        $generatedTasks = $generatedTasks | Select-Object -First $MaxSubTasks
    }
    
    Write-Host "Sous-tÃ¢ches gÃ©nÃ©rÃ©es avec succÃ¨s par l'IA (simulation)." -ForegroundColor Green
    
    # Retourner les sous-tÃ¢ches gÃ©nÃ©rÃ©es
    return @{
        Content = $generatedTasks -join "`r`n"
        Level = "ai"
        Domain = if ($Domains -and $Domains.Count -gt 0) { $Domains[0] } else { $null }
        Domains = $Domains
        Description = "Sous-tÃ¢ches gÃ©nÃ©rÃ©es par IA pour $ComplexityLevel" + $(if ($Domains) { " ($($Domains -join ", "))" })
        MaxSubTasks = $MaxSubTasks
        Combined = $false
        AI = $true
    }
}

# Tester la fonction
$projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$result = Get-AIGeneratedSubTasks -TaskContent "ImplÃ©menter un systÃ¨me d'authentification" -ComplexityLevel "Medium" -Domains @("Backend", "Security") -MaxSubTasks 5 -ProjectRoot $projectRoot

# Afficher le rÃ©sultat
if ($result) {
    Write-Host "Sous-tÃ¢ches gÃ©nÃ©rÃ©es :"
    Write-Host "--------------------"
    Write-Host $result.Content
    Write-Host "--------------------"
    Write-Host "Domaine principal : $($result.Domain)"
    Write-Host "Domaines : $($result.Domains -join ", ")"
    Write-Host "Description : $($result.Description)"
} else {
    Write-Host "Impossible de gÃ©nÃ©rer des sous-tÃ¢ches avec l'IA."
}
