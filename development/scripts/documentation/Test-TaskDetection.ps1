# Test-TaskDetection.ps1
# Script pour tester la dÃ©tection des balises de tÃ¢ches dans un texte

param (
    [Parameter(Mandatory = $false)]
    [string]$InputFile,
    
    [Parameter(Mandatory = $false)]
    [string]$InputText
)

# VÃ©rifier qu'au moins un des paramÃ¨tres est fourni
if (-not $InputFile -and -not $InputText) {
    Write-Error "Vous devez fournir soit un fichier d'entrÃ©e, soit un texte Ã  analyser."
    exit 1
}

# Lire le texte Ã  partir du fichier si spÃ©cifiÃ©
if ($InputFile) {
    if (-not (Test-Path -Path $InputFile)) {
        Write-Error "Le fichier d'entrÃ©e '$InputFile' n'existe pas."
        exit 1
    }
    
    $InputText = Get-Content -Path $InputFile -Raw
}

# Fonction pour extraire les tÃ¢ches du texte
function Export-Tasks {
    param (
        [string]$Text
    )
    
    $tasks = @()
    $pattern = '<task\s+([^>]*)>(.*?)</task>'
    $matches = [regex]::Matches($Text, $pattern, 'Singleline')
    
    foreach ($match in $matches) {
        $attributes = $match.Groups[1].Value
        $description = $match.Groups[2].Value.Trim()
        
        # Extraire les attributs
        $category = [regex]::Match($attributes, 'category="([^"]*)"').Groups[1].Value
        $priority = [regex]::Match($attributes, 'priority="([^"]*)"').Groups[1].Value
        $estimate = [regex]::Match($attributes, 'estimate="([^"]*)"').Groups[1].Value
        $start = [regex]::Match($attributes, 'start="([^"]*)"').Groups[1].Value
        
        # Valeurs par dÃ©faut
        if (-not $category) { $category = "7" }
        if (-not $priority) { $priority = "medium" }
        if (-not $estimate) { $estimate = "1-3" }
        if (-not $start) { $start = "false" }
        
        $task = @{
            Category = $category
            Priority = $priority
            Estimate = $estimate
            Start = $start -eq "true"
            Description = $description
        }
        
        $tasks += $task
    }
    
    return $tasks
}

# Extraire les tÃ¢ches du texte
$tasks = Export-Tasks -Text $InputText

# Afficher les rÃ©sultats
if ($tasks.Count -eq 0) {
    Write-Host "Aucune tÃ¢che dÃ©tectÃ©e dans le texte."
}
else {
    Write-Host "TÃ¢ches dÃ©tectÃ©es : $($tasks.Count)"
    Write-Host ""
    
    foreach ($task in $tasks) {
        Write-Host "TÃ¢che :"
        Write-Host "  CatÃ©gorie : $($task.Category)"
        Write-Host "  PrioritÃ©  : $($task.Priority)"
        Write-Host "  Estimation: $($task.Estimate) jours"
        Write-Host "  DÃ©marrer  : $($task.Start)"
        Write-Host "  Description: $($task.Description)"
        Write-Host ""
    }
}

# Retourner les tÃ¢ches (utile pour les tests automatisÃ©s)
return $tasks

