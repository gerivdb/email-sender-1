<#
.SYNOPSIS
    Initialise la clé API OpenRouter pour le mode GRAN.

.DESCRIPTION
    Ce script permet d'initialiser la clé API OpenRouter pour le mode GRAN.
    Il enregistre la clé API dans le gestionnaire de credentials.

.PARAMETER ApiKey
    La clé API OpenRouter à enregistrer.

.PARAMETER Model
    Le modèle OpenRouter à utiliser par défaut.

.EXAMPLE
    .\init-openrouter.ps1 -ApiKey "sk-or-v1-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" -Model "qwen/qwen3-32b:free"

.NOTES
    Auteur: Security Team
    Version: 1.0
    Date de création: 2025-06-02
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ApiKey,
    
    [Parameter(Mandatory = $false)]
    [string]$Model = "qwen/qwen3-32b:free"
)

# Déterminer le chemin du projet
$projectRoot = $PSScriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Error "Impossible de déterminer le chemin du projet."
        exit 1
    }
}

# Charger le gestionnaire de credentials
$credentialManagerPath = Join-Path -Path $projectRoot -ChildPath "development\tools\security\credential-manager.ps1"
if (-not (Test-Path -Path $credentialManagerPath)) {
    Write-Error "Le gestionnaire de credentials est introuvable à l'emplacement : $credentialManagerPath"
    exit 1
}

# Importer le module de gestion des credentials
. $credentialManagerPath

# Enregistrer la clé API
$result = Set-SecureCredential -Name "OPENROUTER_API_KEY" -Value $ApiKey -StorageType "Environment"
if (-not $result) {
    Write-Error "Impossible d'enregistrer la clé API OpenRouter."
    exit 1
}

# Mettre à jour la configuration pour utiliser le modèle spécifié
$aiConfigPath = Join-Path -Path $projectRoot -ChildPath "development\templates\subtasks\ai-config.json"
if (Test-Path -Path $aiConfigPath) {
    try {
        $aiConfig = Get-Content -Path $aiConfigPath -Raw | ConvertFrom-Json
        
        # Mettre à jour le modèle par défaut
        if (-not $aiConfig.models) {
            $aiConfig | Add-Member -MemberType NoteProperty -Name "models" -Value @{
                default = $Model
                alternatives = @(
                    "openai/gpt-3.5-turbo",
                    "anthropic/claude-3-haiku",
                    "google/gemini-pro",
                    "mistral/mistral-medium"
                )
            } -Force
        } else {
            $aiConfig.models.default = $Model
        }
        
        # Enregistrer la configuration mise à jour
        $aiConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $aiConfigPath -Encoding UTF8
        Write-Host "Configuration mise à jour pour utiliser le modèle : $Model" -ForegroundColor Green
    } catch {
        Write-Warning "Impossible de mettre à jour la configuration : $_"
    }
} else {
    Write-Warning "Le fichier de configuration de l'IA est introuvable à l'emplacement : $aiConfigPath"
}

Write-Host "La clé API OpenRouter a été enregistrée avec succès." -ForegroundColor Green
Write-Host "Vous pouvez maintenant utiliser le mode GRAN avec l'option -UseAI." -ForegroundColor Green
Write-Host "Exemple : .\gran-mode.ps1 -FilePath 'chemin\vers\roadmap.md' -TaskIdentifier '1.2.3' -UseAI" -ForegroundColor Yellow
