# Fonction pour gÃ©nÃ©rer des sous-tÃ¢ches avec l'IA
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
    
    # Charger la configuration de l'IA
    $aiConfigPath = Join-Path -Path $ProjectRoot -ChildPath "development\templates\subtasks\ai-config.json"
    
    if (-not (Test-Path -Path $aiConfigPath)) {
        Write-Warning "Fichier de configuration de l'IA introuvable : $aiConfigPath"
        return $null
    }
    
    try {
        $aiConfig = Get-Content -Path $aiConfigPath -Raw | ConvertFrom-Json
    } catch {
        Write-Warning "Erreur lors du chargement de la configuration de l'IA : $_"
        return $null
    }
    
    # VÃ©rifier si l'IA est activÃ©e
    if (-not $aiConfig.enabled) {
        Write-Warning "La gÃ©nÃ©ration de sous-tÃ¢ches par IA est dÃ©sactivÃ©e dans la configuration."
        return $null
    }
    
    # VÃ©rifier si la clÃ© API est dÃ©finie
    $apiKeyVarName = $aiConfig.api_key_env_var
    $apiKey = [Environment]::GetEnvironmentVariable($apiKeyVarName)
    if (-not $apiKey) {
        Write-Warning "ClÃ© API non dÃ©finie dans la variable d'environnement $apiKeyVarName"
        return $null
    }
    
    # Extraire le titre de la tÃ¢che (tout ce qui suit l'identifiant entre ** **)
    $titleMatch = [regex]::Match($TaskContent, '\*\*[^\*]+\*\*\s+(.+)')
    $taskTitle = if ($titleMatch.Success) { $titleMatch.Groups[1].Value } else { $TaskContent }
    
    # PrÃ©parer les domaines pour le prompt
    $domainsText = if ($Domains -and $Domains.Count -gt 0) {
        $Domains -join ", "
    } else {
        "Non spÃ©cifiÃ©"
    }
    
    # PrÃ©parer le prompt
    $prompt = $aiConfig.prompt_template -replace "{task}", $taskTitle -replace "{complexity}", $ComplexityLevel -replace "{domains}", $domainsText -replace "{max_subtasks}", $MaxSubTasks
    
    # PrÃ©parer la requÃªte API
    $headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "Bearer $apiKey"
    }
    
    $body = @{
        model = $aiConfig.model
        messages = @(
            @{
                role = "system"
                content = "Tu es un expert en gestion de projet et en dÃ©composition de tÃ¢ches. Tu vas gÃ©nÃ©rer une liste de sous-tÃ¢ches pour une tÃ¢che donnÃ©e."
            },
            @{
                role = "user"
                content = $prompt
            }
        )
        temperature = $aiConfig.temperature
        max_tokens = $aiConfig.max_tokens
    } | ConvertTo-Json
    
    # Appeler l'API
    try {
        Write-Host "GÃ©nÃ©ration de sous-tÃ¢ches avec l'IA..." -ForegroundColor Yellow
        
        $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" -Method Post -Headers $headers -Body $body
        
        # Traiter la rÃ©ponse
        $generatedContent = $response.choices[0].message.content
        
        # Nettoyer le contenu gÃ©nÃ©rÃ© (supprimer les numÃ©ros, les tirets, etc.)
        $lines = $generatedContent -split "`n" | ForEach-Object { 
            $line = $_.Trim()
            # Supprimer les numÃ©ros et les tirets au dÃ©but de la ligne
            $line = $line -replace "^(\d+[\.\)]\s*|\-\s*)", ""
            # Ignorer les lignes vides
            if ($line) { $line }
        }
        
        # Limiter le nombre de sous-tÃ¢ches
        if ($lines.Count -gt $MaxSubTasks) {
            $lines = $lines[0..($MaxSubTasks-1)]
        }
        
        Write-Host "Sous-tÃ¢ches gÃ©nÃ©rÃ©es avec succÃ¨s par l'IA." -ForegroundColor Green
        
        # Retourner les sous-tÃ¢ches gÃ©nÃ©rÃ©es
        return @{
            Content = $lines -join "`r`n"
            Level = "ai"
            Domain = if ($Domains -and $Domains.Count -gt 0) { $Domains[0] } else { $null }
            Domains = $Domains
            Description = "Sous-tÃ¢ches gÃ©nÃ©rÃ©es par IA pour $ComplexityLevel" + $(if ($Domains) { " ($($Domains -join ", "))" })
            MaxSubTasks = $MaxSubTasks
            Combined = $false
            AI = $true
        }
    } catch {
        Write-Warning "Erreur lors de l'appel Ã  l'API IA : $_"
        return $null
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
