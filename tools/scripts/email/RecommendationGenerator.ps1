# Script pour gÃ©nÃ©rer des recommandations spÃ©cifiques

# Base de connaissances simplifiÃ©e
$script:KnowledgeBase = @{
    # Erreurs PowerShell courantes
    "Cannot find path" = @{
        Solution = "VÃ©rifier si le chemin existe avec Test-Path avant d'y accÃ©der."
        Example = "if (Test-Path -Path `$filePath) { Get-Content -Path `$filePath }"
    }
    "Access to the path is denied" = @{
        Solution = "VÃ©rifier les permissions ou exÃ©cuter avec des privilÃ¨ges Ã©levÃ©s."
        Example = "Start-Process -FilePath 'powershell.exe' -ArgumentList `"-File `$scriptPath`" -Verb RunAs"
    }
    "Cannot bind argument to parameter" = @{
        Solution = "VÃ©rifier que les paramÃ¨tres requis ont des valeurs valides."
        Example = "if (-not [string]::IsNullOrEmpty(`$param)) { Invoke-Command -Parameter `$param }"
    }
    
    # Erreurs de fichier
    "File not found" = @{
        Solution = "VÃ©rifier l'existence du fichier et crÃ©er le rÃ©pertoire parent si nÃ©cessaire."
        Example = "if (-not (Test-Path -Path `$filePath)) { New-Item -Path (Split-Path -Path `$filePath -Parent) -ItemType Directory -Force }"
    }
    
    # Erreurs rÃ©seau
    "Network error" = @{
        Solution = "ImplÃ©menter une logique de retry avec backoff exponentiel."
        Example = "`$maxRetries = 3; `$retry = 0; do { try { Invoke-WebRequest -Uri `$url; break } catch { `$retry++ } } while (`$retry -lt `$maxRetries)"
    }
    
    # Erreurs de syntaxe
    "Syntax error" = @{
        Solution = "Utiliser un linter ou un validateur de syntaxe."
        Example = "Invoke-ScriptAnalyzer -Path `$scriptPath"
    }
}

# Fonction pour gÃ©nÃ©rer une recommandation
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
    
    # Si aucune correspondance exacte n'est trouvÃ©e, rechercher la meilleure correspondance partielle
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
    
    # GÃ©nÃ©rer la recommandation
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
        # Recommandation gÃ©nÃ©rique basÃ©e sur la catÃ©gorie
        $genericSolution = switch ($ErrorCategory) {
            "FileSystem" { "VÃ©rifier l'existence et les permissions des fichiers et rÃ©pertoires." }
            "Network" { "VÃ©rifier la connectivitÃ© rÃ©seau et implÃ©menter une logique de retry." }
            "Syntax" { "VÃ©rifier la syntaxe du code avec un linter ou un validateur." }
            "NullReference" { "VÃ©rifier que les objets ne sont pas null avant d'y accÃ©der." }
            "Permission" { "VÃ©rifier les permissions ou exÃ©cuter avec des privilÃ¨ges Ã©levÃ©s." }
            default { "Analyser le message d'erreur et implÃ©menter une gestion d'erreur appropriÃ©e." }
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

# Fonction pour ajouter une solution Ã  la base de connaissances
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
