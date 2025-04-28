# Fonction simplifiÃ©e pour convertir un fichier markdown en objet PowerShell
function ConvertFrom-MarkdownToObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata
    )
    
    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier '$FilePath' n'existe pas."
    }
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Raw
    $lines = $content -split "`n"
    
    # CrÃ©er l'objet racine
    $rootObject = [PSCustomObject]@{
        Title = "Document"
        Description = ""
        Items = @()
        Metadata = @{}
    }
    
    # Extraire le titre et la description
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        
        # Extraire le titre (premiÃ¨re ligne commenÃ§ant par #)
        if ($line -match '^#\s+(.+)$') {
            $rootObject.Title = $matches[1]
            
            # Extraire la description (lignes non vides aprÃ¨s le titre jusqu'Ã  la premiÃ¨re section)
            $descLines = @()
            $j = $i + 1
            while ($j -lt $lines.Count -and -not ($lines[$j] -match '^#{2,}\s+')) {
                if (-not [string]::IsNullOrWhiteSpace($lines[$j])) {
                    $descLines += $lines[$j]
                }
                $j++
            }
            
            if ($descLines.Count -gt 0) {
                $rootObject.Description = $descLines -join "`n"
            }
            
            break
        }
    }
    
    # Extraire les sections
    $sections = @()
    foreach ($line in $lines) {
        if ($line -match '^##\s+(.+)$') {
            $sections += [PSCustomObject]@{
                Title = $matches[1]
                Items = @()
            }
        }
    }
    
    $rootObject.Items = $sections
    
    return $rootObject
}
