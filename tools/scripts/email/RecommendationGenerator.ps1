# Script pour générer des recommandations spécifiques

# Base de connaissances simplifiée
$script:KnowledgeBase = @{
    # Erreurs PowerShell courantes
    "Cannot find path" = @{
        Solution = "Vérifier si le chemin existe avec Test-Path avant d'y accéder."
        Example = "if (Test-Path -Path `$filePath) { Get-Content -Path `$filePath }"
    }
    "Access to the path is denied" = @{
        Solution = "Vérifier les permissions ou exécuter avec des privilèges élevés."
        Example = "Start-Process -FilePath 'powershell.exe' -ArgumentList `"-File `$scriptPath`" -Verb RunAs"
    }
    "Cannot bind argument to parameter" = @{
        Solution = "Vérifier que les paramètres requis ont des valeurs valides."
        Example = "if (-not [string]::IsNullOrEmpty(`$param)) { Invoke-Command -Parameter `$param }"
    }
    
    # Erreurs de fichier
    "File not found" = @{
        Solution = "Vérifier l'existence du fichier et créer le répertoire parent si nécessaire."
        Example = "if (-not (Test-Path -Path `$filePath)) { New-Item -Path (Split-Path -Path `$filePath -Parent) -ItemType Directory -Force }"
    }
    
    # Erreurs réseau
    "Network error" = @{
        Solution = "Implémenter une logique de retry avec backoff exponentiel."
        Example = "`$maxRetries = 3; `$retry = 0; do { try { Invoke-WebRequest -Uri `$url; break } catch { `$retry++ } } while (`$retry -lt `$maxRetries)"
    }
    
    # Erreurs de syntaxe
    "Syntax error" = @{
        Solution = "Utiliser un linter ou un validateur de syntaxe."
        Example = "Invoke-ScriptAnalyzer -Path `$scriptPath"
    }
}

# Fonction pour générer une recommandation
function Get-ErrorRecommendation {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ErrorMessage,
        
        [Parameter(Mandatory = $false)]
        [string]$ErrorCategory = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Language = "PowerShell"
    )
    
    # Rechercher dans la base de connaissances
    $bestMatch = $null
    $bestScore = 0
    
    foreach ($key in $script:KnowledgeBase.Keys) {
        if ($ErrorMessage -match $key) {
            $score = 1
            $bestMatch = $key
            $bestScore = $score
            break
        }
    }
    
    # Si aucune correspondance exacte n'est trouvée, rechercher la meilleure correspondance partielle
    if ($bestMatch -eq $null) {
        foreach ($key in $script:KnowledgeBase.Keys) {
            $words = $key -split '\s+'
            $matchCount = 0
            
            foreach ($word in $words) {
                if ($ErrorMessage -match $word) {
                    $matchCount++
                }
            }
            
            $score = $matchCount / $words.Count
            
            if ($score -gt $bestScore) {
                $bestMatch = $key
                $bestScore = $score
            }
        }
    }
    
    # Générer la recommandation
    if ($bestMatch -ne $null -and $bestScore -gt 0.5) {
        $recommendation = $script:KnowledgeBase[$bestMatch]
        
        return [PSCustomObject]@{
            ErrorMessage = $ErrorMessage
            Solution = $recommendation.Solution
            Example = $recommendation.Example
            Confidence = $bestScore
            MatchedPattern = $bestMatch
        }
    }
    else {
        # Recommandation générique basée sur la catégorie
        $genericSolution = switch ($ErrorCategory) {
            "FileSystem" { "Vérifier l'existence et les permissions des fichiers et répertoires." }
            "Network" { "Vérifier la connectivité réseau et implémenter une logique de retry." }
            "Syntax" { "Vérifier la syntaxe du code avec un linter ou un validateur." }
            "NullReference" { "Vérifier que les objets ne sont pas null avant d'y accéder." }
            "Permission" { "Vérifier les permissions ou exécuter avec des privilèges élevés." }
            default { "Analyser le message d'erreur et implémenter une gestion d'erreur appropriée." }
        }
        
        return [PSCustomObject]@{
            ErrorMessage = $ErrorMessage
            Solution = $genericSolution
            Example = ""
            Confidence = 0.3
            MatchedPattern = ""
        }
    }
}

# Fonction pour ajouter une solution à la base de connaissances
function Add-KnowledgeBaseSolution {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Pattern,
        
        [Parameter(Mandatory = $true)]
        [string]$Solution,
        
        [Parameter(Mandatory = $true)]
        [string]$Example
    )
    
    $script:KnowledgeBase[$Pattern] = @{
        Solution = $Solution
        Example = $Example
    }
    
    return $true
}

# Exporter les fonctions
Export-ModuleMember -Function Get-ErrorRecommendation, Add-KnowledgeBaseSolution
