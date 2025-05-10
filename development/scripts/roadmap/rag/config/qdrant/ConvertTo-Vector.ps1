# ConvertTo-Vector.ps1
# Script pour vectoriser les configurations
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("OpenAI", "DeepSeek", "Local", "Mock")]
    [string]$EmbeddingProvider = "OpenAI",
    
    [Parameter(Mandatory = $false)]
    [string]$ModelName = "text-embedding-3-large",
    
    [Parameter(Mandatory = $false)]
    [string]$ApiKey,
    
    [Parameter(Mandatory = $false)]
    [string]$ApiEndpoint,
    
    [Parameter(Mandatory = $false)]
    [string]$Text,
    
    [Parameter(Mandatory = $false)]
    [string]$InputPath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$Normalize,
    
    [Parameter(Mandatory = $false)]
    [switch]$AsObject,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Info", "Debug", "None")]
    [string]$LogLevel = "Info"
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$rootPath = Split-Path -Parent $parentPath
$utilsPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $rootPath)) -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        if ($LogLevel -eq "None") {
            return
        }
        
        $logLevels = @{
            "Error" = 0
            "Warning" = 1
            "Info" = 2
            "Debug" = 3
        }
        
        if ($logLevels[$Level] -le $logLevels[$LogLevel]) {
            $color = switch ($Level) {
                "Error" { "Red" }
                "Warning" { "Yellow" }
                "Info" { "White" }
                "Debug" { "Gray" }
                default { "White" }
            }
            
            Write-Host "[$Level] $Message" -ForegroundColor $color
        }
    }
}

# Fonction pour normaliser un vecteur
function Get-NormalizedVector {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Vector
    )
    
    # Calculer la norme euclidienne
    $norm = [Math]::Sqrt(($Vector | ForEach-Object { $_ * $_ } | Measure-Object -Sum).Sum)
    
    # Éviter la division par zéro
    if ($norm -eq 0) {
        return $Vector
    }
    
    # Normaliser le vecteur
    $normalizedVector = $Vector | ForEach-Object { $_ / $norm }
    
    return $normalizedVector
}

# Fonction pour générer un vecteur aléatoire (pour les tests)
function Get-MockEmbedding {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$Dimensions = 1536,
        
        [Parameter(Mandatory = $false)]
        [switch]$Normalize
    )
    
    # Générer un vecteur aléatoire
    $random = New-Object System.Random
    $vector = 1..$Dimensions | ForEach-Object { $random.NextDouble() * 2 - 1 }
    
    # Normaliser si demandé
    if ($Normalize) {
        $vector = Get-NormalizedVector -Vector $vector
    }
    
    return $vector
}

# Fonction pour obtenir un embedding via l'API OpenAI
function Get-OpenAIEmbedding {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text,
        
        [Parameter(Mandatory = $false)]
        [string]$ModelName = "text-embedding-3-large",
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey,
        
        [Parameter(Mandatory = $false)]
        [string]$ApiEndpoint = "https://api.openai.com/v1/embeddings",
        
        [Parameter(Mandatory = $false)]
        [switch]$Normalize
    )
    
    # Vérifier si une clé API est fournie
    if ([string]::IsNullOrEmpty($ApiKey)) {
        # Essayer de récupérer la clé API depuis les variables d'environnement
        $ApiKey = $env:OPENAI_API_KEY
        
        if ([string]::IsNullOrEmpty($ApiKey)) {
            Write-Log "No API key provided and OPENAI_API_KEY environment variable not set" -Level "Error"
            return $null
        }
    }
    
    # Préparer les en-têtes de la requête
    $headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "Bearer $ApiKey"
    }
    
    # Préparer le corps de la requête
    $body = @{
        model = $ModelName
        input = $Text
    } | ConvertTo-Json
    
    # Envoyer la requête
    try {
        $response = Invoke-RestMethod -Uri $ApiEndpoint -Method Post -Headers $headers -Body $body
        
        # Extraire le vecteur d'embedding
        $vector = $response.data[0].embedding
        
        # Normaliser si demandé
        if ($Normalize) {
            $vector = Get-NormalizedVector -Vector $vector
        }
        
        Write-Log "Successfully generated embedding with OpenAI model: $ModelName" -Level "Info"
        return $vector
    } catch {
        Write-Log "Error generating embedding with OpenAI: $_" -Level "Error"
        return $null
    }
}

# Fonction pour obtenir un embedding via l'API DeepSeek
function Get-DeepSeekEmbedding {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text,
        
        [Parameter(Mandatory = $false)]
        [string]$ModelName = "deepseek-ai/deepseek-coder-6.7b-base",
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey,
        
        [Parameter(Mandatory = $false)]
        [string]$ApiEndpoint = "https://api.deepseek.com/v1/embeddings",
        
        [Parameter(Mandatory = $false)]
        [switch]$Normalize
    )
    
    # Vérifier si une clé API est fournie
    if ([string]::IsNullOrEmpty($ApiKey)) {
        # Essayer de récupérer la clé API depuis les variables d'environnement
        $ApiKey = $env:DEEPSEEK_API_KEY
        
        if ([string]::IsNullOrEmpty($ApiKey)) {
            Write-Log "No API key provided and DEEPSEEK_API_KEY environment variable not set" -Level "Error"
            return $null
        }
    }
    
    # Préparer les en-têtes de la requête
    $headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "Bearer $ApiKey"
    }
    
    # Préparer le corps de la requête
    $body = @{
        model = $ModelName
        input = $Text
    } | ConvertTo-Json
    
    # Envoyer la requête
    try {
        $response = Invoke-RestMethod -Uri $ApiEndpoint -Method Post -Headers $headers -Body $body
        
        # Extraire le vecteur d'embedding
        $vector = $response.data[0].embedding
        
        # Normaliser si demandé
        if ($Normalize) {
            $vector = Get-NormalizedVector -Vector $vector
        }
        
        Write-Log "Successfully generated embedding with DeepSeek model: $ModelName" -Level "Info"
        return $vector
    } catch {
        Write-Log "Error generating embedding with DeepSeek: $_" -Level "Error"
        return $null
    }
}

# Fonction pour obtenir un embedding via un modèle local
function Get-LocalEmbedding {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text,
        
        [Parameter(Mandatory = $false)]
        [string]$ModelName = "all-MiniLM-L6-v2",
        
        [Parameter(Mandatory = $false)]
        [string]$ModelPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Normalize
    )
    
    # Vérifier si Python est installé
    try {
        $pythonVersion = python --version
        Write-Log "Using Python: $pythonVersion" -Level "Debug"
    } catch {
        Write-Log "Python is not installed or not in PATH" -Level "Error"
        return $null
    }
    
    # Créer un script Python temporaire pour générer l'embedding
    $tempScript = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.py'
    
    $pythonCode = @"
import sys
import json
from sentence_transformers import SentenceTransformer

def get_embedding(text, model_name):
    try:
        model = SentenceTransformer(model_name)
        embedding = model.encode(text).tolist()
        return embedding
    except Exception as e:
        print(f"Error: {str(e)}", file=sys.stderr)
        return None

if __name__ == "__main__":
    text = sys.argv[1]
    model_name = sys.argv[2]
    
    embedding = get_embedding(text, model_name)
    
    if embedding:
        print(json.dumps(embedding))
    else:
        sys.exit(1)
"@
    
    $pythonCode | Out-File -FilePath $tempScript -Encoding UTF8
    
    # Exécuter le script Python
    try {
        $modelNameArg = if ([string]::IsNullOrEmpty($ModelPath)) { $ModelName } else { $ModelPath }
        $embeddingJson = python $tempScript $Text $modelNameArg
        
        # Supprimer le script temporaire
        Remove-Item -Path $tempScript -Force
        
        if ([string]::IsNullOrEmpty($embeddingJson)) {
            Write-Log "No embedding returned from local model" -Level "Error"
            return $null
        }
        
        # Convertir le JSON en objet PowerShell
        $vector = $embeddingJson | ConvertFrom-Json
        
        # Normaliser si demandé
        if ($Normalize) {
            $vector = Get-NormalizedVector -Vector $vector
        }
        
        Write-Log "Successfully generated embedding with local model: $ModelName" -Level "Info"
        return $vector
    } catch {
        Write-Log "Error generating embedding with local model: $_" -Level "Error"
        
        # Supprimer le script temporaire en cas d'erreur
        if (Test-Path -Path $tempScript) {
            Remove-Item -Path $tempScript -Force
        }
        
        return $null
    }
}

# Fonction pour extraire les caractéristiques d'une configuration
function Get-ConfigurationFeatures {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Configuration,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType
    )
    
    # Déterminer le type de configuration si non spécifié
    if ([string]::IsNullOrEmpty($ConfigType)) {
        if ($Configuration.PSObject.Properties.Name.Contains("content") -and $Configuration.PSObject.Properties.Name.Contains("type")) {
            $ConfigType = "Template"
        } elseif ($Configuration.PSObject.Properties.Name.Contains("chart_configuration") -and $Configuration.PSObject.Properties.Name.Contains("data_mapping")) {
            $ConfigType = "Visualization"
        } elseif ($Configuration.PSObject.Properties.Name.Contains("mappings") -and $Configuration.PSObject.Properties.Name.Contains("version")) {
            $ConfigType = "DataMapping"
        } elseif ($Configuration.PSObject.Properties.Name.Contains("chart_type") -and $Configuration.PSObject.Properties.Name.Contains("data_field")) {
            $ConfigType = "Chart"
        } elseif ($Configuration.PSObject.Properties.Name.Contains("export_type")) {
            $ConfigType = "Export"
        } elseif ($Configuration.PSObject.Properties.Name.Contains("search_type") -and $Configuration.PSObject.Properties.Name.Contains("query")) {
            $ConfigType = "Search"
        } else {
            Write-Log "Could not determine configuration type" -Level "Warning"
            $ConfigType = "Unknown"
        }
    }
    
    # Extraire les caractéristiques selon le type de configuration
    $features = ""
    
    switch ($ConfigType) {
        "Template" {
            $features = @(
                "Template: $($Configuration.name)",
                "Description: $($Configuration.description)",
                "Type: $($Configuration.type)",
                "Version: $($Configuration.version)",
                "Content: $($Configuration.content)"
            ) -join "`n"
        }
        "Visualization" {
            $features = @(
                "Visualization: $($Configuration.name)",
                "Description: $($Configuration.description)",
                "Version: $($Configuration.version)",
                "Chart Type: $($Configuration.chart_configuration.chart_type)",
                "Data Field: $($Configuration.chart_configuration.data_field)",
                "Title: $($Configuration.chart_configuration.title)"
            ) -join "`n"
            
            # Ajouter les mappages de données si disponibles
            if ($null -ne $Configuration.data_mapping -and $null -ne $Configuration.data_mapping.mappings) {
                $mappingDescriptions = $Configuration.data_mapping.mappings | ForEach-Object {
                    "Mapping: $($_.name) - $($_.description) - Type: $($_.type) - GroupBy: $($_.group_by)"
                }
                
                $features += "`n" + ($mappingDescriptions -join "`n")
            }
        }
        "DataMapping" {
            $features = @(
                "Data Mapping Version: $($Configuration.version)",
                "Created: $($Configuration.created_date)",
                "Modified: $($Configuration.modified_date)"
            ) -join "`n"
            
            # Ajouter les mappages si disponibles
            if ($null -ne $Configuration.mappings) {
                $mappingDescriptions = $Configuration.mappings | ForEach-Object {
                    "Mapping: $($_.name) - $($_.description) - Type: $($_.type) - GroupBy: $($_.group_by) - ValueField: $($_.value_field)"
                }
                
                $features += "`n" + ($mappingDescriptions -join "`n")
            }
        }
        "Chart" {
            $features = @(
                "Chart Type: $($Configuration.chart_type)",
                "Data Field: $($Configuration.data_field)",
                "Title: $($Configuration.title)",
                "Show Legend: $($Configuration.show_legend)",
                "Enable Animation: $($Configuration.enable_animation)"
            ) -join "`n"
            
            # Ajouter les options si disponibles
            if ($null -ne $Configuration.options) {
                $features += "`nOptions: " + ($Configuration.options | ConvertTo-Json -Compress)
            }
        }
        "Export" {
            $features = @(
                "Export Type: $($Configuration.export_type)",
                "Format: $($Configuration.format)",
                "Export Name: $($Configuration.export_name)",
                "Export Description: $($Configuration.export_description)",
                "Source Type: $($Configuration.source_type)",
                "Source ID: $($Configuration.source_id)"
            ) -join "`n"
        }
        "Search" {
            $features = @(
                "Search Type: $($Configuration.search_type)",
                "Query: $($Configuration.query)",
                "Include Archived: $($Configuration.include_archived)",
                "Limit: $($Configuration.limit)"
            ) -join "`n"
            
            # Ajouter les filtres si disponibles
            if ($null -ne $Configuration.filters) {
                $features += "`nFilters: " + ($Configuration.filters | ConvertTo-Json -Compress)
            }
            
            # Ajouter les options de tri si disponibles
            if ($null -ne $Configuration.sort) {
                $features += "`nSort: " + ($Configuration.sort | ConvertTo-Json -Compress)
            }
        }
        default {
            # Pour les types inconnus, convertir toute la configuration en JSON
            $features = $Configuration | ConvertTo-Json -Depth 5
        }
    }
    
    return $features
}

# Fonction principale
function ConvertTo-Vector {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("OpenAI", "DeepSeek", "Local", "Mock")]
        [string]$EmbeddingProvider = "OpenAI",
        
        [Parameter(Mandatory = $false)]
        [string]$ModelName = "text-embedding-3-large",
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey,
        
        [Parameter(Mandatory = $false)]
        [string]$ApiEndpoint,
        
        [Parameter(Mandatory = $false)]
        [string]$Text,
        
        [Parameter(Mandatory = $false)]
        [string]$InputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Normalize,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType
    )
    
    # Vérifier si un texte ou un chemin d'entrée est fourni
    if ([string]::IsNullOrEmpty($Text) -and [string]::IsNullOrEmpty($InputPath)) {
        Write-Log "Either Text or InputPath must be provided" -Level "Error"
        return $null
    }
    
    # Si un chemin d'entrée est fourni, charger le contenu
    if (-not [string]::IsNullOrEmpty($InputPath)) {
        if (-not (Test-Path -Path $InputPath)) {
            Write-Log "Input file not found: $InputPath" -Level "Error"
            return $null
        }
        
        try {
            $content = Get-Content -Path $InputPath -Raw
            
            # Vérifier si le contenu est au format JSON
            try {
                $configuration = $content | ConvertFrom-Json
                
                # Extraire les caractéristiques de la configuration
                $Text = Get-ConfigurationFeatures -Configuration $configuration -ConfigType $ConfigType
            } catch {
                # Si ce n'est pas du JSON, utiliser le contenu tel quel
                $Text = $content
            }
        } catch {
            Write-Log "Error loading input file: $_" -Level "Error"
            return $null
        }
    }
    
    # Générer l'embedding selon le fournisseur
    $vector = $null
    
    switch ($EmbeddingProvider) {
        "OpenAI" {
            $vector = Get-OpenAIEmbedding -Text $Text -ModelName $ModelName -ApiKey $ApiKey -ApiEndpoint $ApiEndpoint -Normalize:$Normalize
        }
        "DeepSeek" {
            $vector = Get-DeepSeekEmbedding -Text $Text -ModelName $ModelName -ApiKey $ApiKey -ApiEndpoint $ApiEndpoint -Normalize:$Normalize
        }
        "Local" {
            $vector = Get-LocalEmbedding -Text $Text -ModelName $ModelName -Normalize:$Normalize
        }
        "Mock" {
            $vector = Get-MockEmbedding -Normalize:$Normalize
        }
    }
    
    if ($null -eq $vector) {
        Write-Log "Failed to generate embedding" -Level "Error"
        return $null
    }
    
    return $vector
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    $vector = ConvertTo-Vector -EmbeddingProvider $EmbeddingProvider -ModelName $ModelName -ApiKey $ApiKey -ApiEndpoint $ApiEndpoint -Text $Text -InputPath $InputPath -Normalize:$Normalize
    
    # Sauvegarder le vecteur si un chemin de sortie est spécifié
    if (-not [string]::IsNullOrEmpty($OutputPath) -and $null -ne $vector) {
        try {
            $vector | ConvertTo-Json -Compress | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Log "Vector saved to: $OutputPath" -Level "Info"
        } catch {
            Write-Log "Error saving vector: $_" -Level "Error"
        }
    }
    
    # Retourner le vecteur selon le format demandé
    if ($AsObject) {
        return $vector
    } else {
        return $vector | ConvertTo-Json -Compress
    }
}
