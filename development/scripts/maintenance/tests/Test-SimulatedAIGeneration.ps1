# Fonction pour simuler la génération de sous-tâches avec l'IA
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
    
    # Extraire le titre de la tâche (tout ce qui suit l'identifiant entre ** **)
    $titleMatch = [regex]::Match($TaskContent, '\*\*[^\*]+\*\*\s+(.+)')
    $taskTitle = if ($titleMatch.Success) { $titleMatch.Groups[1].Value } else { $TaskContent }
    
    # Préparer les domaines pour le prompt
    $domainsText = if ($Domains -and $Domains.Count -gt 0) {
        $Domains -join ", "
    } else {
        "Non spécifié"
    }
    
    # Simuler l'appel à l'API
    Write-Host "Génération de sous-tâches avec l'IA..." -ForegroundColor Yellow
    Write-Host "Utilisation de l'API : https://openrouter.ai/api/v1/chat/completions (SIMULATION)" -ForegroundColor Gray
    
    # Simuler un délai de traitement
    Start-Sleep -Seconds 2
    
    # Générer des sous-tâches en fonction du domaine et de la complexité
    $generatedTasks = @()
    
    # Sous-tâches communes à tous les domaines
    $generatedTasks += "Analyser les besoins du système"
    
    # Sous-tâches spécifiques au domaine Backend
    if ($Domains -contains "Backend") {
        $generatedTasks += "Concevoir l'architecture du backend"
        $generatedTasks += "Implémenter les modèles de données"
        $generatedTasks += "Développer les API RESTful"
    }
    
    # Sous-tâches spécifiques au domaine Security
    if ($Domains -contains "Security") {
        $generatedTasks += "Implémenter le système d'authentification"
        $generatedTasks += "Configurer les autorisations et rôles"
        $generatedTasks += "Mettre en place le chiffrement des données sensibles"
    }
    
    # Sous-tâches spécifiques au domaine Frontend
    if ($Domains -contains "Frontend") {
        $generatedTasks += "Concevoir l'interface utilisateur"
        $generatedTasks += "Développer les composants React"
        $generatedTasks += "Implémenter les formulaires et validations"
    }
    
    # Sous-tâches communes de fin
    $generatedTasks += "Tester toutes les fonctionnalités"
    $generatedTasks += "Documenter l'API et l'utilisation"
    
    # Ajuster le nombre de sous-tâches en fonction de la complexité
    if ($ComplexityLevel -eq "Simple") {
        # Garder seulement 3-4 tâches pour les tâches simples
        $generatedTasks = $generatedTasks | Select-Object -First 4
    } elseif ($ComplexityLevel -eq "Complex") {
        # Ajouter des tâches supplémentaires pour les tâches complexes
        $generatedTasks += "Optimiser les performances"
        $generatedTasks += "Mettre en place la surveillance et les alertes"
        $generatedTasks += "Préparer le déploiement en production"
    }
    
    # Limiter le nombre de sous-tâches au maximum spécifié
    if ($generatedTasks.Count -gt $MaxSubTasks) {
        $generatedTasks = $generatedTasks | Select-Object -First $MaxSubTasks
    }
    
    Write-Host "Sous-tâches générées avec succès par l'IA (simulation)." -ForegroundColor Green
    
    # Retourner les sous-tâches générées
    return @{
        Content = $generatedTasks -join "`r`n"
        Level = "ai"
        Domain = if ($Domains -and $Domains.Count -gt 0) { $Domains[0] } else { $null }
        Domains = $Domains
        Description = "Sous-tâches générées par IA pour $ComplexityLevel" + $(if ($Domains) { " ($($Domains -join ", "))" })
        MaxSubTasks = $MaxSubTasks
        Combined = $false
        AI = $true
    }
}

# Tester la fonction
$projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$result = Get-AIGeneratedSubTasks -TaskContent "Implémenter un système d'authentification" -ComplexityLevel "Medium" -Domains @("Backend", "Security") -MaxSubTasks 5 -ProjectRoot $projectRoot

# Afficher le résultat
if ($result) {
    Write-Host "Sous-tâches générées :"
    Write-Host "--------------------"
    Write-Host $result.Content
    Write-Host "--------------------"
    Write-Host "Domaine principal : $($result.Domain)"
    Write-Host "Domaines : $($result.Domains -join ", ")"
    Write-Host "Description : $($result.Description)"
} else {
    Write-Host "Impossible de générer des sous-tâches avec l'IA."
}
