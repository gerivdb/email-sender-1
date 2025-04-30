# Fonction pour générer des sous-tâches avec l'IA
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
    
    # Vérifier si l'IA est activée
    if (-not $aiConfig.enabled) {
        Write-Warning "La génération de sous-tâches par IA est désactivée dans la configuration."
        return $null
    }
    
    # Vérifier si la clé API est définie
    $apiKeyVarName = $aiConfig.api_key_env_var
    $apiKey = [Environment]::GetEnvironmentVariable($apiKeyVarName)
    if (-not $apiKey) {
        Write-Warning "Clé API non définie dans la variable d'environnement $apiKeyVarName"
        return $null
    }
    
    # Extraire le titre de la tâche (tout ce qui suit l'identifiant entre ** **)
    $titleMatch = [regex]::Match($TaskContent, '\*\*[^\*]+\*\*\s+(.+)')
    $taskTitle = if ($titleMatch.Success) { $titleMatch.Groups[1].Value } else { $TaskContent }
    
    # Préparer les domaines pour le prompt
    $domainsText = if ($Domains -and $Domains.Count -gt 0) {
        $Domains -join ", "
    } else {
        "Non spécifié"
    }
    
    # Préparer le prompt
    $prompt = $aiConfig.prompt_template -replace "{task}", $taskTitle -replace "{complexity}", $ComplexityLevel -replace "{domains}", $domainsText -replace "{max_subtasks}", $MaxSubTasks
    
    # Préparer la requête API
    $headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "Bearer $apiKey"
    }
    
    $body = @{
        model = $aiConfig.model
        messages = @(
            @{
                role = "system"
                content = "Tu es un expert en gestion de projet et en décomposition de tâches. Tu vas générer une liste de sous-tâches pour une tâche donnée."
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
        Write-Host "Génération de sous-tâches avec l'IA..." -ForegroundColor Yellow
        
        $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" -Method Post -Headers $headers -Body $body
        
        # Traiter la réponse
        $generatedContent = $response.choices[0].message.content
        
        # Nettoyer le contenu généré (supprimer les numéros, les tirets, etc.)
        $lines = $generatedContent -split "`n" | ForEach-Object { 
            $line = $_.Trim()
            # Supprimer les numéros et les tirets au début de la ligne
            $line = $line -replace "^(\d+[\.\)]\s*|\-\s*)", ""
            # Ignorer les lignes vides
            if ($line) { $line }
        }
        
        # Limiter le nombre de sous-tâches
        if ($lines.Count -gt $MaxSubTasks) {
            $lines = $lines[0..($MaxSubTasks-1)]
        }
        
        Write-Host "Sous-tâches générées avec succès par l'IA." -ForegroundColor Green
        
        # Retourner les sous-tâches générées
        return @{
            Content = $lines -join "`r`n"
            Level = "ai"
            Domain = if ($Domains -and $Domains.Count -gt 0) { $Domains[0] } else { $null }
            Domains = $Domains
            Description = "Sous-tâches générées par IA pour $ComplexityLevel" + $(if ($Domains) { " ($($Domains -join ", "))" })
            MaxSubTasks = $MaxSubTasks
            Combined = $false
            AI = $true
        }
    } catch {
        Write-Warning "Erreur lors de l'appel à l'API IA : $_"
        return $null
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
