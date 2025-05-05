# Fonction pour estimer le temps nÃ©cessaire pour une sous-tÃ¢che
function Get-TaskTimeEstimate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskContent,
        
        [Parameter(Mandatory = $true)]
        [string]$ComplexityLevel,
        
        [Parameter(Mandatory = $false)]
        [string]$Domain = $null,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )
    
    # Charger la configuration des estimations de temps
    $timeConfigPath = Join-Path -Path $ProjectRoot -ChildPath "development\templates\subtasks\time-estimates.json"
    
    if (-not (Test-Path -Path $timeConfigPath)) {
        Write-Warning "Fichier de configuration des estimations de temps introuvable : $timeConfigPath"
        return $null
    }
    
    try {
        $timeConfig = Get-Content -Path $timeConfigPath -Raw | ConvertFrom-Json
    } catch {
        Write-Warning "Erreur lors du chargement de la configuration des estimations de temps : $_"
        return $null
    }
    
    # Normaliser le contenu de la tÃ¢che
    $normalizedContent = $TaskContent.ToLower()
    
    # DÃ©terminer le type de tÃ¢che (analyse, conception, implÃ©mentation, test, documentation)
    $taskType = "default"
    $maxScore = 0
    
    foreach ($type in $timeConfig.task_keywords.PSObject.Properties.Name) {
        $score = 0
        foreach ($keyword in $timeConfig.task_keywords.$type) {
            if ($normalizedContent -match $keyword) {
                $score += 1
            }
        }
        
        if ($score -gt $maxScore) {
            $maxScore = $score
            $taskType = $type
        }
    }
    
    # Obtenir le temps de base pour ce type de tÃ¢che
    $baseTime = $timeConfig.base_times.$taskType.value
    $timeUnit = $timeConfig.base_times.$taskType.unit
    
    # Appliquer le multiplicateur de complexitÃ©
    $complexityMultiplier = $timeConfig.complexity_multipliers.($ComplexityLevel.ToLower())
    $estimatedTime = $baseTime * $complexityMultiplier
    
    # Appliquer le multiplicateur de domaine si spÃ©cifiÃ©
    if ($Domain -and $timeConfig.domain_multipliers.PSObject.Properties.Name -contains $Domain.ToLower()) {
        $domainMultiplier = $timeConfig.domain_multipliers.($Domain.ToLower())
        $estimatedTime = $estimatedTime * $domainMultiplier
    }
    
    # Arrondir Ã  0.5 prÃ¨s
    $estimatedTime = [Math]::Round($estimatedTime * 2) / 2
    
    # Retourner l'estimation
    return @{
        Time = $estimatedTime
        Unit = $timeUnit
        Type = $taskType
        Formatted = "$estimatedTime $timeUnit"
    }
}

# Tester la fonction
$projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$result = Get-TaskTimeEstimate -TaskContent "Analyser les besoins du systÃ¨me" -ComplexityLevel "Medium" -ProjectRoot $projectRoot

# Afficher le rÃ©sultat
if ($result) {
    Write-Host "Estimation de temps : $($result.Formatted)"
    Write-Host "Type de tÃ¢che : $($result.Type)"
} else {
    Write-Host "Impossible d'estimer le temps pour cette tÃ¢che."
}
