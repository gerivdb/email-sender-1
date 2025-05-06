# Script pour utiliser Qwen3 en mode DEV-R
# Ce script permet d'implémenter des tâches en utilisant le modèle Qwen3 via OpenRouter

param (
    [Parameter(Mandatory = $true)]
    [string]$TaskId,
    
    [Parameter(Mandatory = $false)]
    [string]$Model = "qwen/qwen3-235b-a22b",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = $null,
    
    [Parameter(Mandatory = $false)]
    [switch]$UseCredentialManager = $true
)

# Importer les modules nécessaires
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootPath = (Get-Item $ScriptPath).Parent.Parent.Parent.FullName
Import-Module "$RootPath\scripts\environment-compatibility\CredentialManager.psm1" -Force

# Fonction pour obtenir la clé API OpenRouter
function Get-OpenRouterApiKey {
    if ($UseCredentialManager) {
        try {
            $apiKey = Get-StoredCredential -Target "openrouter_api_key" -AsPlainText
            if ([string]::IsNullOrEmpty($apiKey)) {
                throw "Clé API non trouvée dans le gestionnaire d'identifiants"
            }
            return $apiKey
        }
        catch {
            Write-Warning "Erreur lors de la récupération de la clé API depuis le gestionnaire d'identifiants: $_"
            $apiKey = Read-Host -Prompt "Entrez votre clé API OpenRouter" -AsSecureString
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiKey)
            $plainApiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
            
            # Stocker la clé pour une utilisation future
            Set-StoredCredential -Target "openrouter_api_key" -UserName "api" -Password $plainApiKey
            
            return $plainApiKey
        }
    }
    else {
        $apiKey = Read-Host -Prompt "Entrez votre clé API OpenRouter" -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiKey)
        $plainApiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        return $plainApiKey
    }
}

# Fonction pour extraire les informations de la tâche
function Get-TaskInfo {
    param (
        [string]$TaskId
    )
    
    # Rechercher la tâche dans le fichier de roadmap
    $roadmapPath = "$RootPath\projet\roadmaps\active\roadmap_active.md"
    if (-not (Test-Path $roadmapPath)) {
        $roadmapPath = "$RootPath\development\scripts\extraction\PLAN_IMPLEMENTATION.md"
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
        Write-Error "Tâche $TaskId non trouvée dans la roadmap"
        return $null
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
    $outputFolder = "$RootPath\projet\temp\dev-r"
    if (-not (Test-Path $outputFolder)) {
        New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
    }
    
    return "$outputFolder\$fileName"
}

# Fonction principale
function Invoke-Qwen3DevR {
    param (
        [string]$TaskId,
        [string]$Model,
        [string]$OutputPath
    )
    
    # Obtenir les informations de la tâche
    $taskInfo = Get-TaskInfo -TaskId $TaskId
    if ($null -eq $taskInfo) {
        return
    }
    
    # Obtenir la clé API
    $apiKey = Get-OpenRouterApiKey
    if ([string]::IsNullOrEmpty($apiKey)) {
        Write-Error "Impossible d'obtenir la clé API OpenRouter"
        return
    }
    
    # Générer les prompts
    $systemPrompt = Get-SystemPrompt
    $userPrompt = Get-UserPrompt -TaskInfo $taskInfo
    
    # Appeler l'API
    $generatedContent = Invoke-OpenRouterAPI -ApiKey $apiKey -Model $Model -SystemPrompt $systemPrompt -UserPrompt $userPrompt
    
    if ([string]::IsNullOrEmpty($generatedContent)) {
        Write-Error "Aucun contenu généré"
        return
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
    
    return $outputFilePath
}

# Exécuter la fonction principale
$outputFile = Invoke-Qwen3DevR -TaskId $TaskId -Model $Model -OutputPath $OutputPath

# Retourner le chemin du fichier généré
return $outputFile
