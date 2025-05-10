# Extract-MetadataBlocks.ps1
# Script pour extraire les blocs de métadonnées des fichiers markdown de roadmap
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath,
    
    [Parameter(Mandatory = $false)]
    [string]$Content,
    
    [Parameter(Mandatory = $false)]
    [switch]$DetectFrontMatter,
    
    [Parameter(Mandatory = $false)]
    [switch]$DetectCodeBlocks,
    
    [Parameter(Mandatory = $false)]
    [switch]$DetectCommentBlocks,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "Markdown", "YAML")]
    [string]$OutputFormat = "JSON"
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$utilsPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        $color = switch ($Level) {
            "Info" { "White" }
            "Warning" { "Yellow" }
            "Error" { "Red" }
            "Success" { "Green" }
            "Debug" { "Gray" }
        }
        
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

# Fonction pour extraire les blocs de métadonnées
function Get-MetadataBlocks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [Parameter(Mandatory = $false)]
        [switch]$DetectFrontMatter,
        
        [Parameter(Mandatory = $false)]
        [switch]$DetectCodeBlocks,
        
        [Parameter(Mandatory = $false)]
        [switch]$DetectCommentBlocks
    )
    
    Write-Log "Extraction des blocs de métadonnées..." -Level "Debug"
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $analysis = @{
        FrontMatter = $null
        CodeBlocks = @()
        CommentBlocks = @()
        Stats = @{
            HasFrontMatter = $false
            CodeBlocksCount = 0
            CommentBlocksCount = 0
        }
    }
    
    # Extraire le front matter si demandé
    if ($DetectFrontMatter) {
        # Vérifier si le contenu commence par un délimiteur de front matter
        if ($lines.Count -gt 2 -and $lines[0] -eq "---") {
            $endIndex = -1
            
            # Chercher la fin du front matter
            for ($i = 1; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -eq "---") {
                    $endIndex = $i
                    break
                }
            }
            
            if ($endIndex -gt 0) {
                # Extraire le contenu du front matter
                $frontMatterLines = $lines[1..($endIndex - 1)]
                $frontMatterContent = $frontMatterLines -join "`n"
                
                # Essayer de parser le front matter comme du YAML
                try {
                    # Utiliser une expression régulière pour extraire les paires clé-valeur
                    $frontMatterData = @{}
                    $keyValuePattern = '^\s*([^:]+):\s*(.*)$'
                    
                    foreach ($line in $frontMatterLines) {
                        if ($line -match $keyValuePattern) {
                            $key = $matches[1].Trim()
                            $value = $matches[2].Trim()
                            
                            # Gérer les valeurs entre guillemets
                            if ($value -match '^"(.*)"$' -or $value -match "^'(.*)'$") {
                                $value = $matches[1]
                            }
                            
                            # Gérer les listes
                            if ($value -match '^\[.*\]$') {
                                $listItems = $value.Trim('[]').Split(',') | ForEach-Object { $_.Trim() }
                                $frontMatterData[$key] = $listItems
                            } else {
                                $frontMatterData[$key] = $value
                            }
                        }
                    }
                    
                    $analysis.FrontMatter = @{
                        Content = $frontMatterContent
                        Data = $frontMatterData
                        StartLine = 0
                        EndLine = $endIndex
                    }
                    
                    $analysis.Stats.HasFrontMatter = $true
                } catch {
                    Write-Log "Erreur lors du parsing du front matter : $_" -Level "Warning"
                    
                    $analysis.FrontMatter = @{
                        Content = $frontMatterContent
                        Data = $null
                        StartLine = 0
                        EndLine = $endIndex
                        Error = $_.ToString()
                    }
                    
                    $analysis.Stats.HasFrontMatter = $true
                }
            }
        }
    }
    
    # Extraire les blocs de code si demandé
    if ($DetectCodeBlocks) {
        $inCodeBlock = $false
        $codeBlockStart = 0
        $codeBlockLanguage = ""
        $codeBlockContent = @()
        
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            
            if (-not $inCodeBlock -and $line -match '^```(.*)$') {
                # Début d'un bloc de code
                $inCodeBlock = $true
                $codeBlockStart = $i
                $codeBlockLanguage = $matches[1].Trim()
                $codeBlockContent = @()
            } elseif ($inCodeBlock -and $line -match '^```$') {
                # Fin d'un bloc de code
                $inCodeBlock = $false
                
                $analysis.CodeBlocks += @{
                    Language = $codeBlockLanguage
                    Content = $codeBlockContent -join "`n"
                    StartLine = $codeBlockStart
                    EndLine = $i
                }
                
                $analysis.Stats.CodeBlocksCount++
            } elseif ($inCodeBlock) {
                # Ligne à l'intérieur d'un bloc de code
                $codeBlockContent += $line
            }
        }
    }
    
    # Extraire les blocs de commentaires si demandé
    if ($DetectCommentBlocks) {
        $inCommentBlock = $false
        $commentBlockStart = 0
        $commentBlockContent = @()
        
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            
            if (-not $inCommentBlock -and $line -match '^<!--(.*)$' -and $line -notmatch '-->$') {
                # Début d'un bloc de commentaire
                $inCommentBlock = $true
                $commentBlockStart = $i
                $commentBlockContent = @($matches[1].Trim())
            } elseif ($inCommentBlock -and $line -match '(.*)-->$') {
                # Fin d'un bloc de commentaire
                $inCommentBlock = $false
                $commentBlockContent += $matches[1].Trim()
                
                $analysis.CommentBlocks += @{
                    Content = $commentBlockContent -join "`n"
                    StartLine = $commentBlockStart
                    EndLine = $i
                }
                
                $analysis.Stats.CommentBlocksCount++
            } elseif ($inCommentBlock) {
                # Ligne à l'intérieur d'un bloc de commentaire
                $commentBlockContent += $line
            } elseif ($line -match '^<!--(.*)-->$') {
                # Commentaire sur une seule ligne
                $analysis.CommentBlocks += @{
                    Content = $matches[1].Trim()
                    StartLine = $i
                    EndLine = $i
                }
                
                $analysis.Stats.CommentBlocksCount++
            }
        }
    }
    
    # Analyser les métadonnées dans les blocs de commentaires
    if ($DetectCommentBlocks -and $analysis.CommentBlocks.Count -gt 0) {
        foreach ($commentBlock in $analysis.CommentBlocks) {
            # Vérifier si le bloc de commentaire contient des métadonnées
            $content = $commentBlock.Content
            
            # Essayer de détecter les paires clé-valeur
            $keyValuePattern = '^\s*([^:]+):\s*(.*)$'
            $metadataFound = $false
            $metadata = @{}
            
            foreach ($line in $content -split "`r?`n") {
                if ($line -match $keyValuePattern) {
                    $key = $matches[1].Trim()
                    $value = $matches[2].Trim()
                    
                    $metadata[$key] = $value
                    $metadataFound = $true
                }
            }
            
            if ($metadataFound) {
                $commentBlock.Metadata = $metadata
                $commentBlock.ContainsMetadata = $true
            } else {
                $commentBlock.ContainsMetadata = $false
            }
        }
    }
    
    return $analysis
}

# Fonction pour générer la sortie au format demandé
function Format-MetadataBlocksOutput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Analysis,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "Markdown", "YAML")]
        [string]$Format = "JSON"
    )
    
    Write-Log "Génération de la sortie au format $Format..." -Level "Debug"
    
    switch ($Format) {
        "JSON" {
            return $Analysis | ConvertTo-Json -Depth 10
        }
        "Markdown" {
            $markdown = "# Analyse des blocs de métadonnées`n`n"
            
            # Statistiques générales
            $markdown += "## Statistiques`n`n"
            $markdown += "- Front matter : $($Analysis.Stats.HasFrontMatter)`n"
            $markdown += "- Blocs de code : $($Analysis.Stats.CodeBlocksCount)`n"
            $markdown += "- Blocs de commentaires : $($Analysis.Stats.CommentBlocksCount)`n`n"
            
            # Front matter
            if ($Analysis.Stats.HasFrontMatter) {
                $markdown += "## Front Matter`n`n"
                $markdown += "```yaml`n$($Analysis.FrontMatter.Content)`n````n`n"
                
                if ($Analysis.FrontMatter.Data) {
                    $markdown += "### Données extraites`n`n"
                    $markdown += "| Clé | Valeur |`n"
                    $markdown += "|-----|--------|`n"
                    
                    foreach ($key in $Analysis.FrontMatter.Data.Keys | Sort-Object) {
                        $value = $Analysis.FrontMatter.Data[$key]
                        
                        if ($value -is [array]) {
                            $value = $value -join ", "
                        }
                        
                        $markdown += "| $key | $value |`n"
                    }
                    
                    $markdown += "`n"
                }
            }
            
            # Blocs de code
            if ($Analysis.CodeBlocks.Count -gt 0) {
                $markdown += "## Blocs de code`n`n"
                
                for ($i = 0; $i -lt $Analysis.CodeBlocks.Count; $i++) {
                    $codeBlock = $Analysis.CodeBlocks[$i]
                    $markdown += "### Bloc de code $($i + 1) ($($codeBlock.Language))`n`n"
                    $markdown += "- Lignes : $($codeBlock.StartLine) - $($codeBlock.EndLine)`n`n"
                    $markdown += "```$($codeBlock.Language)`n$($codeBlock.Content)`n````n`n"
                }
            }
            
            # Blocs de commentaires
            if ($Analysis.CommentBlocks.Count -gt 0) {
                $markdown += "## Blocs de commentaires`n`n"
                
                for ($i = 0; $i -lt $Analysis.CommentBlocks.Count; $i++) {
                    $commentBlock = $Analysis.CommentBlocks[$i]
                    $markdown += "### Bloc de commentaire $($i + 1)`n`n"
                    $markdown += "- Lignes : $($commentBlock.StartLine) - $($commentBlock.EndLine)`n"
                    
                    if ($commentBlock.ContainsKey("ContainsMetadata")) {
                        $markdown += "- Contient des métadonnées : $($commentBlock.ContainsMetadata)`n"
                    }
                    
                    $markdown += "`n"
                    $markdown += "````n$($commentBlock.Content)`n````n`n"
                    
                    if ($commentBlock.ContainsKey("Metadata") -and $commentBlock.Metadata.Count -gt 0) {
                        $markdown += "#### Métadonnées extraites`n`n"
                        $markdown += "| Clé | Valeur |`n"
                        $markdown += "|-----|--------|`n"
                        
                        foreach ($key in $commentBlock.Metadata.Keys | Sort-Object) {
                            $value = $commentBlock.Metadata[$key]
                            $markdown += "| $key | $value |`n"
                        }
                        
                        $markdown += "`n"
                    }
                }
            }
            
            return $markdown
        }
        "YAML" {
            $yaml = "# Analyse des blocs de métadonnées`n`n"
            
            # Statistiques
            $yaml += "stats:`n"
            $yaml += "  hasFrontMatter: $($Analysis.Stats.HasFrontMatter.ToString().ToLower())`n"
            $yaml += "  codeBlocksCount: $($Analysis.Stats.CodeBlocksCount)`n"
            $yaml += "  commentBlocksCount: $($Analysis.Stats.CommentBlocksCount)`n`n"
            
            # Front matter
            if ($Analysis.Stats.HasFrontMatter) {
                $yaml += "frontMatter:`n"
                $yaml += "  startLine: $($Analysis.FrontMatter.StartLine)`n"
                $yaml += "  endLine: $($Analysis.FrontMatter.EndLine)`n"
                
                if ($Analysis.FrontMatter.Data) {
                    $yaml += "  data:`n"
                    
                    foreach ($key in $Analysis.FrontMatter.Data.Keys | Sort-Object) {
                        $value = $Analysis.FrontMatter.Data[$key]
                        
                        if ($value -is [array]) {
                            $yaml += "    $key:`n"
                            foreach ($item in $value) {
                                $yaml += "      - ""$item""`n"
                            }
                        } else {
                            $yaml += "    $key: ""$value""`n"
                        }
                    }
                }
                
                $yaml += "`n"
            }
            
            # Blocs de code
            if ($Analysis.CodeBlocks.Count -gt 0) {
                $yaml += "codeBlocks:`n"
                
                for ($i = 0; $i -lt $Analysis.CodeBlocks.Count; $i++) {
                    $codeBlock = $Analysis.CodeBlocks[$i]
                    $yaml += "  - language: ""$($codeBlock.Language)""`n"
                    $yaml += "    startLine: $($codeBlock.StartLine)`n"
                    $yaml += "    endLine: $($codeBlock.EndLine)`n"
                    $yaml += "    content: |-`n"
                    
                    foreach ($line in $codeBlock.Content -split "`r?`n") {
                        $yaml += "      $line`n"
                    }
                    
                    $yaml += "`n"
                }
            }
            
            # Blocs de commentaires
            if ($Analysis.CommentBlocks.Count -gt 0) {
                $yaml += "commentBlocks:`n"
                
                for ($i = 0; $i -lt $Analysis.CommentBlocks.Count; $i++) {
                    $commentBlock = $Analysis.CommentBlocks[$i]
                    $yaml += "  - startLine: $($commentBlock.StartLine)`n"
                    $yaml += "    endLine: $($commentBlock.EndLine)`n"
                    
                    if ($commentBlock.ContainsKey("ContainsMetadata")) {
                        $yaml += "    containsMetadata: $($commentBlock.ContainsMetadata.ToString().ToLower())`n"
                    }
                    
                    $yaml += "    content: |-`n"
                    
                    foreach ($line in $commentBlock.Content -split "`r?`n") {
                        $yaml += "      $line`n"
                    }
                    
                    if ($commentBlock.ContainsKey("Metadata") -and $commentBlock.Metadata.Count -gt 0) {
                        $yaml += "    metadata:`n"
                        
                        foreach ($key in $commentBlock.Metadata.Keys | Sort-Object) {
                            $value = $commentBlock.Metadata[$key]
                            $yaml += "      $key: ""$value""`n"
                        }
                    }
                    
                    $yaml += "`n"
                }
            }
            
            return $yaml
        }
    }
}

# Fonction principale
function Extract-MetadataBlocks {
    [CmdletBinding()]
    param (
        [string]$FilePath,
        [string]$Content,
        [switch]$DetectFrontMatter,
        [switch]$DetectCodeBlocks,
        [switch]$DetectCommentBlocks,
        [string]$OutputPath,
        [string]$OutputFormat
    )
    
    # Vérifier les paramètres
    if ([string]::IsNullOrEmpty($Content) -and [string]::IsNullOrEmpty($FilePath)) {
        Write-Log "Vous devez spécifier soit un chemin de fichier, soit un contenu à analyser." -Level "Error"
        return $null
    }
    
    # Lire le contenu du fichier si nécessaire
    if ([string]::IsNullOrEmpty($Content) -and -not [string]::IsNullOrEmpty($FilePath)) {
        if (-not (Test-Path -Path $FilePath)) {
            Write-Log "Le fichier spécifié n'existe pas : $FilePath" -Level "Error"
            return $null
        }
        
        try {
            $Content = Get-Content -Path $FilePath -Raw
        } catch {
            Write-Log "Erreur lors de la lecture du fichier : $_" -Level "Error"
            return $null
        }
    }
    
    # Extraire les blocs de métadonnées
    $analysis = Get-MetadataBlocks -Content $Content -DetectFrontMatter:$DetectFrontMatter -DetectCodeBlocks:$DetectCodeBlocks -DetectCommentBlocks:$DetectCommentBlocks
    
    # Afficher les résultats de l'analyse
    Write-Log "Extraction des blocs de métadonnées terminée :" -Level "Info"
    Write-Log "  - Front matter : $($analysis.Stats.HasFrontMatter)" -Level "Info"
    Write-Log "  - Blocs de code : $($analysis.Stats.CodeBlocksCount)" -Level "Info"
    Write-Log "  - Blocs de commentaires : $($analysis.Stats.CommentBlocksCount)" -Level "Info"
    
    # Générer la sortie au format demandé
    $output = Format-MetadataBlocksOutput -Analysis $analysis -Format $OutputFormat
    
    # Enregistrer la sortie si un chemin de sortie est spécifié
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        try {
            $output | Set-Content -Path $OutputPath -Encoding UTF8
            Write-Log "Sortie enregistrée dans : $OutputPath" -Level "Success"
        } catch {
            Write-Log "Erreur lors de l'enregistrement de la sortie : $_" -Level "Error"
        }
    }
    
    return @{
        Analysis = $analysis
        Output = $output
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Extract-MetadataBlocks -FilePath $FilePath -Content $Content -DetectFrontMatter:$DetectFrontMatter -DetectCodeBlocks:$DetectCodeBlocks -DetectCommentBlocks:$DetectCommentBlocks -OutputPath $OutputPath -OutputFormat $OutputFormat
}
