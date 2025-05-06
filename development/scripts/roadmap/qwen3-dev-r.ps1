# Script pour utiliser Qwen3 en mode DEV-R
# Ce script permet d'implémenter des tâches en utilisant le modèle Qwen3 via OpenRouter

param (
    [Parameter(Mandatory = $true)]
    [string]$TaskId,
    
    [Parameter(Mandatory = $false)]
    [string]$ApiKey = "",
    
    [Parameter(Mandatory = $false)]
    [string]$Model = "qwen/qwen3-235b-a22b",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = $null,
    
    [Parameter(Mandatory = $false)]
    [switch]$SaveConfig = $false
)

# Fonction pour obtenir la clé API
function Get-ApiKey {
    param (
        [string]$ProvidedKey
    )
    
    # Si une clé est fournie en paramètre, l'utiliser
    if (-not [string]::IsNullOrEmpty($ProvidedKey)) {
        return $ProvidedKey
    }
    
    # Essayer de charger la clé depuis le fichier de configuration
    $configPath = Join-Path $PSScriptRoot "..\..\projet\config\openrouter_config.json"
    if (Test-Path $configPath) {
        try {
            $config = Get-Content $configPath -Raw | ConvertFrom-Json
            if ($config.api_key) {
                return $config.api_key
            }
        }
        catch {
            Write-Warning "Erreur lors de la lecture du fichier de configuration: $_"
        }
    }
    
    # Demander la clé à l'utilisateur
    $apiKey = Read-Host -Prompt "Entrez votre clé API OpenRouter"
    
    # Sauvegarder la configuration si demandé
    if ($SaveConfig) {
        $configDir = Split-Path $configPath -Parent
        if (-not (Test-Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        
        $config = @{
            api_key = $apiKey
            default_model = $Model
        }
        
        $config | ConvertTo-Json | Out-File -FilePath $configPath -Encoding utf8
        Write-Host "Configuration sauvegardée dans $configPath" -ForegroundColor Green
    }
    
    return $apiKey
}

# Fonction pour extraire les informations de la tâche
function Get-TaskInfo {
    param (
        [string]$TaskId
    )
    
    # Rechercher la tâche dans le fichier de roadmap
    $roadmapPath = "$PSScriptRoot\..\..\projet\roadmaps\active\roadmap_active.md"
    if (-not (Test-Path $roadmapPath)) {
        $roadmapPath = "$PSScriptRoot\..\..\development\scripts\extraction\PLAN_IMPLEMENTATION.md"
    }
    
    if (-not (Test-Path $roadmapPath)) {
        Write-Error "Fichier de roadmap non trouvé"
        return $null
    }
    
    $roadmapContent = Get-Content $roadmapPath -Raw
    
    # Rechercher la ligne contenant l'ID de tâche
    $pattern = "- \[ \] \*\*$TaskId\*\* (.*)"
    if ($roadmapContent -match $pattern) {
        $taskDescription = $matches[1]
        return @{
            Id = $TaskId
            Description = $taskDescription
        }
    }
    else {
        # Vérifier si la tâche est déjà marquée comme terminée
        $pattern = "- \[x\] \*\*$TaskId\*\* (.*)"
        if ($roadmapContent -match $pattern) {
            $taskDescription = $matches[1]
            Write-Warning "La tâche $TaskId est déjà marquée comme terminée"
            return @{
                Id = $TaskId
                Description = $taskDescription
                Completed = $true
            }
        }
        else {
            Write-Error "Tâche $TaskId non trouvée dans la roadmap"
            return $null
        }
    }
}

# Fonction pour générer le prompt système
function Get-SystemPrompt {
    return @"
Tu es un expert en développement logiciel travaillant en mode DEV-R (Développement-Réalisation).
Ta tâche est d'implémenter une fonctionnalité spécifique de manière concise et efficace.

Directives:
1. Concentre-toi UNIQUEMENT sur l'implémentation de la tâche demandée
2. Fournis du code de haute qualité, bien structuré et documenté
3. Respecte les standards de codage (PEP 8 pour Python, PSScriptAnalyzer pour PowerShell)
4. Inclus des commentaires pertinents mais pas excessifs
5. N'utilise PAS de formulations conversationnelles ou d'explications superflues
6. Fournis UNIQUEMENT le code et la documentation technique nécessaire
7. Sois direct et concis - pas d'introduction, de conclusion ou de texte superflu

Format de réponse:
- Documentation technique concise (si nécessaire)
- Code d'implémentation
- Tests unitaires (si approprié)

N'utilise pas d'emojis, de formules de politesse ou de texte conversationnel.
"@
}

# Fonction pour générer le prompt utilisateur
function Get-UserPrompt {
    param (
        [hashtable]$TaskInfo
    )
    
    return @"
Implémente la tâche suivante en mode DEV-R (développement direct sans explications superflues):

ID: $($TaskInfo.Id)
Description: $($TaskInfo.Description)

Fournis uniquement:
1. Une documentation technique concise (si nécessaire)
2. Le code d'implémentation
3. Des tests unitaires (si approprié)

N'inclus pas d'explications, d'introductions ou de conclusions. Concentre-toi uniquement sur l'implémentation.
"@
}

# Fonction pour appeler l'API OpenRouter
function Invoke-OpenRouterAPI {
    param (
        [string]$ApiKey,
        [string]$Model,
        [string]$SystemPrompt,
        [string]$UserPrompt,
        [int]$MaxTokens = 4000,
        [double]$Temperature = 0.7
    )
    
    $headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "Bearer $ApiKey"
        "HTTP-Referer" = "https://github.com/augmentcode-ai"
        "X-Title" = "DEV-R Mode Implementation"
    }
    
    $body = @{
        model = $Model
        messages = @(
            @{
                role = "system"
                content = $SystemPrompt
            },
            @{
                role = "user"
                content = $UserPrompt
            }
        )
        temperature = $Temperature
        max_tokens = $MaxTokens
    } | ConvertTo-Json -Depth 10
    
    try {
        Write-Host "Appel de l'API $Model via OpenRouter..." -ForegroundColor Yellow
        $response = Invoke-RestMethod -Uri "https://openrouter.ai/api/v1/chat/completions" -Method Post -Headers $headers -Body $body
        
        return $response.choices[0].message.content
    }
    catch {
        Write-Error "Erreur lors de l'appel à l'API: $_"
        
        # Afficher plus de détails sur l'erreur
        if ($_.Exception.Response) {
            $responseStream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($responseStream)
            $responseBody = $reader.ReadToEnd()
            Write-Error "Détails de l'erreur: $responseBody"
        }
        
        return $null
    }
}

# Fonction pour déterminer le chemin de sortie approprié
function Get-OutputFilePath {
    param (
        [hashtable]$TaskInfo,
        [string]$ProvidedPath
    )
    
    if (-not [string]::IsNullOrEmpty($ProvidedPath)) {
        return $ProvidedPath
    }
    
    # Déterminer le type de fichier en fonction de la description de la tâche
    $fileExtension = ".md"
    if ($TaskInfo.Description -match "Python|pandas|numpy|scipy") {
        $fileExtension = ".py"
    }
    elseif ($TaskInfo.Description -match "PowerShell|script|automation") {
        $fileExtension = ".ps1"
    }
    elseif ($TaskInfo.Description -match "JSON|configuration") {
        $fileExtension = ".json"
    }
    
    # Créer un nom de fichier basé sur l'ID de tâche
    $fileName = "task_$($TaskInfo.Id.Replace('.', '_'))$fileExtension"
    
    # Déterminer le dossier approprié
    $outputFolder = "$PSScriptRoot\..\..\projet\temp\dev-r"
    if (-not (Test-Path $outputFolder)) {
        New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
    }
    
    return "$outputFolder\$fileName"
}

# Fonction principale
function Invoke-Qwen3DevR {
    # Obtenir les informations de la tâche
    $taskInfo = Get-TaskInfo -TaskId $TaskId
    if ($null -eq $taskInfo) {
        return $null
    }
    
    # Vérifier si la tâche est déjà terminée
    if ($taskInfo.Completed) {
        $proceed = Read-Host "La tâche est déjà marquée comme terminée. Voulez-vous continuer? (O/N)"
        if ($proceed -ne "O" -and $proceed -ne "o") {
            return $null
        }
    }
    
    # Obtenir la clé API
    $apiKey = Get-ApiKey -ProvidedKey $ApiKey
    if ([string]::IsNullOrEmpty($apiKey)) {
        Write-Error "Aucune clé API fournie."
        return $null
    }
    
    # Générer les prompts
    $systemPrompt = Get-SystemPrompt
    $userPrompt = Get-UserPrompt -TaskInfo $taskInfo
    
    # Appeler l'API
    $generatedContent = Invoke-OpenRouterAPI -ApiKey $apiKey -Model $Model -SystemPrompt $systemPrompt -UserPrompt $userPrompt
    
    if ([string]::IsNullOrEmpty($generatedContent)) {
        Write-Error "Aucun contenu généré"
        return $null
    }
    
    # Déterminer le chemin de sortie
    $outputFilePath = Get-OutputFilePath -TaskInfo $taskInfo -ProvidedPath $OutputPath
    
    # Enregistrer le contenu généré
    $generatedContent | Out-File -FilePath $outputFilePath -Encoding utf8
    
    Write-Host "Contenu généré enregistré dans: $outputFilePath" -ForegroundColor Green
    
    # Afficher un aperçu du contenu
    Write-Host "Aperçu du contenu généré:" -ForegroundColor Cyan
    Write-Host "--------------------"
    if ($generatedContent.Length -gt 500) {
        Write-Host $generatedContent.Substring(0, 500)
        Write-Host "..."
    }
    else {
        Write-Host $generatedContent
    }
    Write-Host "--------------------"
    
    # Demander à l'utilisateur s'il souhaite implémenter le contenu généré
    $implement = Read-Host "Voulez-vous implémenter le contenu généré? (O/N)"
    if ($implement -eq "O" -or $implement -eq "o") {
        # Déterminer le chemin d'implémentation
        $defaultPath = ""
        $fileExtension = [System.IO.Path]::GetExtension($outputFilePath)
        
        switch ($fileExtension) {
            ".py" { $defaultPath = "projet\code\metrics" }
            ".ps1" { $defaultPath = "projet\scripts" }
            ".md" { $defaultPath = "projet\documentation\technical" }
            default { $defaultPath = "projet\temp\implemented" }
        }
        
        $implementPath = Read-Host "Chemin d'implémentation [$defaultPath]"
        if ([string]::IsNullOrEmpty($implementPath)) {
            $implementPath = $defaultPath
        }
        
        # Créer le dossier s'il n'existe pas
        if (-not (Test-Path $implementPath)) {
            New-Item -ItemType Directory -Path $implementPath -Force | Out-Null
        }
        
        # Demander le nom du fichier
        $defaultFileName = [System.IO.Path]::GetFileName($outputFilePath)
        $fileName = Read-Host "Nom du fichier [$defaultFileName]"
        if ([string]::IsNullOrEmpty($fileName)) {
            $fileName = $defaultFileName
        }
        
        # Copier le fichier
        $destinationPath = Join-Path $implementPath $fileName
        Copy-Item -Path $outputFilePath -Destination $destinationPath -Force
        
        Write-Host "Fichier implémenté à: $destinationPath" -ForegroundColor Green
        
        # Demander si l'utilisateur souhaite marquer la tâche comme terminée
        $markCompleted = Read-Host "Voulez-vous marquer la tâche comme terminée? (O/N)"
        if ($markCompleted -eq "O" -or $markCompleted -eq "o") {
            # Rechercher la tâche dans le fichier de roadmap
            $roadmapPath = "$PSScriptRoot\..\..\projet\roadmaps\active\roadmap_active.md"
            if (-not (Test-Path $roadmapPath)) {
                $roadmapPath = "$PSScriptRoot\..\..\development\scripts\extraction\PLAN_IMPLEMENTATION.md"
            }
            
            if (Test-Path $roadmapPath) {
                $content = Get-Content $roadmapPath -Raw
                $pattern = "- \[ \] \*\*$TaskId\*\*"
                $replacement = "- [x] **$TaskId**"
                $newContent = $content -replace $pattern, $replacement
                
                if ($content -ne $newContent) {
                    $newContent | Out-File -FilePath $roadmapPath -Encoding utf8
                    Write-Host "Tâche $TaskId marquée comme terminée dans la roadmap" -ForegroundColor Green
                }
                else {
                    Write-Warning "Tâche $TaskId non trouvée dans la roadmap ou déjà marquée comme terminée"
                }
            }
            else {
                Write-Warning "Fichier de roadmap non trouvé"
            }
        }
    }
    
    return $outputFilePath
}

# Exécuter la fonction principale
$outputFile = Invoke-Qwen3DevR

# Retourner le chemin du fichier généré
return $outputFile
