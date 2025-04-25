# Extrait les métadonnées depuis les commentaires du script
static [ScriptMetadata] ExtractMetadata([string]$content, [ScriptMetadata]$metadata) {
    # Patterns pour extraire les métadonnées des commentaires
    $patterns = @{
        PowerShell = @{
            Author      = '(?i)\.AUTHOR\s*(.*?)(?=\r?\n|\.|$)'
            Version     = '(?i)\.VERSION\s*(.*?)(?=\r?\n|\.|$)'
            Description = '(?i)\.DESCRIPTION\s*(.*?)(?=\r?\n\.|$)'
            Tags        = '(?i)\.TAGS\s*(.*?)(?=\r?\n\.|$)'
        }
        Python = @{
            Author      = '(?i)@author\s*:\s*(.*?)(?=\r?\n|$)'
            Version     = '(?i)@version\s*:\s*(.*?)(?=\r?\n|$)'
            Description = '(?i)"""(.*?)"""'
            Tags        = '(?i)@tags\s*:\s*(.*?)(?=\r?\n|$)'
        }
        Batch = @{
            Author      = '(?i)::.*?[aA]uthor\s*:\s*(.*?)(?=\r?\n|$)'
            Version     = '(?i)::.*?[vV]ersion\s*:\s*(.*?)(?=\r?\n|$)'
            Description = '(?i)::.*?[dD]escription\s*:\s*(.*?)(?=\r?\n|$)'
            Tags        = '(?i)::.*?[tT]ags\s*:\s*(.*?)(?=\r?\n|$)'
        }
    }
    
    $patternSet = $null
    
    if ($metadata.Language -like 'PowerShell*') {
        $patternSet = $patterns.PowerShell
    }
    elseif ($metadata.Language -eq 'Python') {
        $patternSet = $patterns.Python
    }
    elseif ($metadata.Language -like 'Batch*') {
        $patternSet = $patterns.Batch
    }
    else {
        # Utiliser PowerShell comme fallback
        $patternSet = $patterns.PowerShell
    }
    
    if ($patternSet) {
        $authorMatch = [regex]::Match($content, $patternSet.Author)
        if ($authorMatch.Success) {
            $metadata.Author = $authorMatch.Groups[1].Value.Trim()
        }
        
        $versionMatch = [regex]::Match($content, $patternSet.Version)
        if ($versionMatch.Success) {
            $metadata.Version = $versionMatch.Groups[1].Value.Trim()
        }
        
        $descriptionMatch = [regex]::Match($content, $patternSet.Description)
        if ($descriptionMatch.Success) {
            $metadata.Description = $descriptionMatch.Groups[1].Value.Trim()
        }
        
        $tagsMatch = [regex]::Match($content, $patternSet.Tags)
        if ($tagsMatch.Success) {
            $metadata.Tags = $tagsMatch.Groups[1].Value -split ',' | ForEach-Object { $_.Trim() }
        }
    }
    
    return $metadata
}
