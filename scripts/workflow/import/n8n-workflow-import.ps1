# Script PowerShell pour importer un workflow n8n avec journalisation automatique

param (
    [Parameter(Mandatory=$true)]
    [string]$WorkflowFile
)

$ScriptsDir = Join-Path (Split-Path -Parent $PSScriptRoot) "python\journal"
$N8nApiUrl = "http://localhost:5678/api/v1"

# Fonction pour importer un workflow via l'API n8n
function Import-N8nWorkflow {
    param (
        [string]$FilePath
    )
    
    try {
        # VÃ©rifier si le fichier existe
        if (-not (Test-Path $FilePath)) {
            Write-Error "Le fichier $FilePath n'existe pas."
            return $false, "Le fichier n'existe pas."
        }
        
        # Lire le contenu du fichier
        $WorkflowJson = Get-Content -Path $FilePath -Raw
        
        # Appeler l'API n8n pour importer le workflow
        $Headers = @{
            "Content-Type" = "application/json"
        }
        
        $Response = Invoke-RestMethod -Uri "$N8nApiUrl/workflows" -Method Post -Headers $Headers -Body $WorkflowJson -ErrorAction Stop
        
        # Retourner le succÃ¨s et l'ID du workflow
        return $true, $null, $Response.id, $Response.name
    }
    catch {
        # Retourner l'Ã©chec et le message d'erreur
        return $false, $_.Exception.Message, $null, $null
    }
}

# Importer le workflow
Write-Host "Importation du workflow $WorkflowFile..."
$ImportResult = Import-N8nWorkflow -FilePath $WorkflowFile

# Journaliser le rÃ©sultat
if ($ImportResult[0]) {
    Write-Host "Importation rÃ©ussie. ID du workflow: $($ImportResult[2])" -ForegroundColor Green
    
    # Journaliser le succÃ¨s
    python "$ScriptsDir\n8n_journal_integration.py" import --file $WorkflowFile --success
}
else {
    Write-Host "Erreur lors de l'importation: $($ImportResult[1])" -ForegroundColor Red
    
    # Journaliser l'Ã©chec
    python "$ScriptsDir\n8n_journal_integration.py" import --file $WorkflowFile --error $ImportResult[1]
}
