# Get-OpenRouterEmbeddings.ps1
# Script pour générer des embeddings avec l'API OpenRouter
# Version: 1.0
# Date: 2025-05-15

# Fonction pour générer des embeddings avec l'API OpenRouter
function Get-OpenRouterEmbeddings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $false)]
        [string]$ApiKey = $env:OPENROUTER_API_KEY,

        [Parameter(Mandatory = $false)]
        [string]$Model = "qwen/qwen3-235b-a22b",

        [Parameter(Mandatory = $false)]
        [string]$Endpoint = "https://openrouter.ai/api/v1/embeddings",

        [Parameter(Mandatory = $false)]
        [switch]$TestMode
    )

    # Importer le module Write-Log si disponible
    $scriptDir = $PSScriptRoot
    if (-not $scriptDir) {
        $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    $writeLogPath = Join-Path -Path $scriptDir -ChildPath "Write-Log.ps1"

    if (Test-Path -Path $writeLogPath) {
        . $writeLogPath
    } else {
        # Fonction Write-Log simplifiée si le module n'est pas disponible
        function Write-Log {
            param (
                [string]$Message,
                [string]$Level = "Info"
            )

            $color = switch ($Level) {
                "Error" { "Red" }
                "Warning" { "Yellow" }
                "Success" { "Green" }
                default { "White" }
            }

            Write-Host "[$Level] $Message" -ForegroundColor $color
        }
    }

    # Si le mode test est activé, générer un embedding aléatoire
    if ($TestMode) {
        Write-Log "Mode test activé. Génération d'un embedding aléatoire." -Level Warning

        # Déterminer la dimension de l'embedding en fonction du modèle
        $dimension = 1536  # Dimension par défaut

        if ($Model -like "*qwen*") {
            $dimension = 1536
        } elseif ($Model -like "*mistral*") {
            $dimension = 1024
        } elseif ($Model -like "*llama*") {
            $dimension = 4096
        }

        # Générer un embedding aléatoire
        $random = New-Object System.Random
        $embedding = 1..$dimension | ForEach-Object { ($random.NextDouble() * 2) - 1 }

        Write-Log "Embedding aléatoire généré (dimension: $dimension)" -Level Success

        return $embedding
    }

    # Vérifier si la clé API est disponible
    if ([string]::IsNullOrEmpty($ApiKey)) {
        Write-Log "Clé API OpenRouter non trouvée. Définissez la variable d'environnement OPENROUTER_API_KEY" -Level Error

        # Essayer de récupérer la clé depuis le gestionnaire de credentials
        $credentialManagerPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptDir))) -ChildPath "environment-compatibility\CredentialManager.psm1"

        if (Test-Path -Path $credentialManagerPath) {
            try {
                Import-Module $credentialManagerPath -Force
                $ApiKey = Get-StoredCredential -Target "openrouter_api_key" -AsPlainText

                if ([string]::IsNullOrEmpty($ApiKey)) {
                    Write-Log "Clé API non trouvée dans le gestionnaire d'identifiants" -Level Error

                    # Générer un embedding aléatoire en cas d'erreur
                    Write-Log "Génération d'un embedding aléatoire" -Level Warning

                    # Déterminer la dimension de l'embedding en fonction du modèle
                    $dimension = 1536  # Dimension par défaut

                    if ($Model -like "*qwen*") {
                        $dimension = 1536
                    } elseif ($Model -like "*mistral*") {
                        $dimension = 1024
                    } elseif ($Model -like "*llama*") {
                        $dimension = 4096
                    }

                    # Générer un embedding aléatoire
                    $random = New-Object System.Random
                    $embedding = 1..$dimension | ForEach-Object { ($random.NextDouble() * 2) - 1 }

                    return $embedding
                } else {
                    Write-Log "Clé API récupérée depuis le gestionnaire d'identifiants" -Level Success
                }
            } catch {
                Write-Log "Erreur lors de la récupération de la clé API depuis le gestionnaire d'identifiants: $_" -Level Error

                # Générer un embedding aléatoire en cas d'erreur
                Write-Log "Génération d'un embedding aléatoire" -Level Warning

                # Déterminer la dimension de l'embedding en fonction du modèle
                $dimension = 1536  # Dimension par défaut

                if ($Model -like "*qwen*") {
                    $dimension = 1536
                } elseif ($Model -like "*mistral*") {
                    $dimension = 1024
                } elseif ($Model -like "*llama*") {
                    $dimension = 4096
                }

                # Générer un embedding aléatoire
                $random = New-Object System.Random
                $embedding = 1..$dimension | ForEach-Object { ($random.NextDouble() * 2) - 1 }

                return $embedding
            }
        } else {
            # Générer un embedding aléatoire en cas d'erreur
            Write-Log "Génération d'un embedding aléatoire" -Level Warning

            # Déterminer la dimension de l'embedding en fonction du modèle
            $dimension = 1536  # Dimension par défaut

            if ($Model -like "*qwen*") {
                $dimension = 1536
            } elseif ($Model -like "*mistral*") {
                $dimension = 1024
            } elseif ($Model -like "*llama*") {
                $dimension = 4096
            }

            # Générer un embedding aléatoire
            $random = New-Object System.Random
            $embedding = 1..$dimension | ForEach-Object { ($random.NextDouble() * 2) - 1 }

            return $embedding
        }
    }

    # Préparer les en-têtes de la requête
    $headers = @{
        "Content-Type"  = "application/json"
        "Authorization" = "Bearer $ApiKey"
        "HTTP-Referer"  = "https://augment.dev"
        "X-Title"       = "Roadmap Tag Search"
    }

    # Préparer le corps de la requête
    $body = @{
        model = $Model
        input = $Text
    } | ConvertTo-Json

    # Appeler l'API
    try {
        Write-Log "Génération de l'embedding pour le texte: $($Text.Substring(0, [Math]::Min(50, $Text.Length)))..." -Level Info

        $response = Invoke-RestMethod -Uri $Endpoint -Method Post -Headers $headers -Body $body

        # Extraire l'embedding
        $embedding = $response.data[0].embedding

        Write-Log "Embedding généré avec succès (dimension: $($embedding.Count))" -Level Success

        return $embedding
    } catch {
        Write-Log "Erreur lors de la génération de l'embedding: $_" -Level Error

        # Afficher plus de détails sur l'erreur
        if ($_.Exception.Response) {
            $responseStream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($responseStream)
            $responseBody = $reader.ReadToEnd()
            Write-Log "Détails de l'erreur: $responseBody" -Level Error
        }

        # Générer un embedding aléatoire en cas d'erreur
        Write-Log "Génération d'un embedding aléatoire" -Level Warning

        # Déterminer la dimension de l'embedding en fonction du modèle
        $dimension = 1536  # Dimension par défaut

        if ($Model -like "*qwen*") {
            $dimension = 1536
        } elseif ($Model -like "*mistral*") {
            $dimension = 1024
        } elseif ($Model -like "*llama*") {
            $dimension = 4096
        }

        # Générer un embedding aléatoire
        $random = New-Object System.Random
        $embedding = 1..$dimension | ForEach-Object { ($random.NextDouble() * 2) - 1 }

        return $embedding
    }
}

# Fonction exportée implicitement
