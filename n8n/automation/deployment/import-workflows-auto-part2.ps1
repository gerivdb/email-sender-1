<#
.SYNOPSIS
    Script d'importation automatique des workflows n8n (Partie 2 : Fonctions d'importation).

.DESCRIPTION
    Ce script contient les fonctions d'importation pour l'importation automatique des workflows n8n.
    Il est conçu pour être utilisé avec les autres parties du script d'importation.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  22/04/2025
#>

# Importer les fonctions et variables de la partie 1
. "$PSScriptRoot\import-workflows-auto-part1.ps1"

# Fonction pour importer un workflow via l'API
function Import-WorkflowViaApi {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        
        [Parameter(Mandatory=$true)]
        [string]$ApiUrl,
        
        [Parameter(Mandatory=$true)]
        [string]$ApiKey,
        
        [Parameter(Mandatory=$false)]
        [string]$Tags = "",
        
        [Parameter(Mandatory=$false)]
        [bool]$Active = $true
    )
    
    try {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $FilePath)) {
            Write-Log "Le fichier n'existe pas: $FilePath" -Level "ERROR"
            return $null
        }
        
        # Lire le contenu du fichier
        $workflowJson = Get-Content -Path $FilePath -Raw
        
        # Convertir le JSON en objet
        $workflow = $workflowJson | ConvertFrom-Json
        
        # Préparer les données pour l'importation
        $importData = @{
            workflowData = $workflow
            tags = if ([string]::IsNullOrEmpty($Tags)) { @() } else { $Tags.Split(",") }
            active = $Active
        }
        
        # Convertir les données en JSON
        $importDataJson = $importData | ConvertTo-Json -Depth 10
        
        # Préparer les en-têtes
        $headers = @{
            "Content-Type" = "application/json"
            "Accept" = "application/json"
            "X-N8N-API-KEY" = $ApiKey
        }
        
        # Envoyer la requête
        $response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Headers $headers -Body $importDataJson
        
        return $response
    } catch {
        Write-Log "Erreur lors de l'importation du workflow via API: $_" -Level "ERROR"
        
        # Afficher des informations supplémentaires sur l'erreur
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
            $statusDescription = $_.Exception.Response.StatusDescription
            Write-Log "Code d'état HTTP: $statusCode ($statusDescription)" -Level "ERROR"
            
            # Essayer de lire le corps de la réponse d'erreur
            try {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $responseBody = $reader.ReadToEnd()
                $reader.Close()
                
                if (-not [string]::IsNullOrEmpty($responseBody)) {
                    Write-Log "Corps de la réponse: $responseBody" -Level "ERROR"
                }
            } catch {
                # Ignorer les erreurs lors de la lecture du corps de la réponse
            }
        }
        
        return $null
    }
}

# Fonction pour importer un workflow via la CLI
function Import-WorkflowViaCli {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        
        [Parameter(Mandatory=$false)]
        [string]$Tags = "",
        
        [Parameter(Mandatory=$false)]
        [bool]$Active = $true
    )
    
    try {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $FilePath)) {
            Write-Log "Le fichier n'existe pas: $FilePath" -Level "ERROR"
            return $false
        }
        
        # Préparer les arguments
        $arguments = @("import:workflow", "--file", $FilePath)
        
        if (-not [string]::IsNullOrEmpty($Tags)) {
            $arguments += "--tags"
            $arguments += $Tags
        }
        
        if ($Active) {
            $arguments += "--active"
        }
        
        # Exécuter la commande
        $process = Start-Process -FilePath "npx" -ArgumentList (@("n8n") + $arguments) -NoNewWindow -PassThru -Wait
        
        # Vérifier le code de sortie
        if ($process.ExitCode -eq 0) {
            return $true
        } else {
            Write-Log "Erreur lors de l'importation du workflow via CLI. Code de sortie: $($process.ExitCode)" -Level "ERROR"
            return $false
        }
    } catch {
        Write-Log "Erreur lors de l'importation du workflow via CLI: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour importer un workflow (API ou CLI)
function Import-Workflow {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        
        [Parameter(Mandatory=$true)]
        [string]$Method,
        
        [Parameter(Mandatory=$false)]
        [string]$ApiKey = "",
        
        [Parameter(Mandatory=$false)]
        [string]$ApiUrl = "",
        
        [Parameter(Mandatory=$false)]
        [string]$Tags = "",
        
        [Parameter(Mandatory=$false)]
        [bool]$Active = $true
    )
    
    # Valider le fichier
    if (-not (Test-WorkflowFile -FilePath $FilePath)) {
        Write-Log "Le fichier n'est pas un workflow n8n valide: $FilePath" -Level "ERROR"
        return $false
    }
    
    # Importer le workflow selon la méthode spécifiée
    if ($Method -eq "API") {
        # Importer via l'API
        $response = Import-WorkflowViaApi -FilePath $FilePath -ApiUrl $ApiUrl -ApiKey $ApiKey -Tags $Tags -Active $Active
        return ($null -ne $response)
    } else {
        # Importer via la CLI
        return Import-WorkflowViaCli -FilePath $FilePath -Tags $Tags -Active $Active
    }
}

# Exporter les fonctions pour les autres parties du script
Export-ModuleMember -Function Import-WorkflowViaApi, Import-WorkflowViaCli, Import-Workflow
