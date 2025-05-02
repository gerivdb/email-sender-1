# Configuration
$config = @{
    MaxItems = 100
    DefaultColor = "Blue"
    EnableLogging = $true
    LogPath = "C:\Logs\app.log"
}

# Variables dérivées
$maxItems = $config.MaxItems
$defaultColor = $config.DefaultColor
$logFile = $config.LogPath

# Fonction de traitement
function Process-Items {
    param (
        [int]$count = $maxItems,
        [string]$color = $defaultColor
    )
    
    $processedItems = 0
    $results = @()
    
    for ($i = 0; $i -lt $count; $i++) {
        $item = [PSCustomObject]@{
            Id = $i
            Name = "Item-$i"
            Color = $color
            ProcessedOn = Get-Date
        }
        
        $results += $item
        $processedItems++
        
        # Variable non définie
        if ($showProgress) {
            Write-Progress -Activity "Traitement" -Status "Traitement de l'élément $i" -PercentComplete (($i / $count) * 100)
        }
    }
    
    # Variable définie mais non utilisée
    $endTime = Get-Date
    
    return [PSCustomObject]@{
        ProcessedCount = $processedItems
        Items = $results
    }
}

# Utilisation de la fonction
$result = Process-Items -count 10
Write-Output "Nombre d'éléments traités: $($result.ProcessedCount)"

# Écriture du log
if ($config.EnableLogging) {
    $logMessage = "Traitement terminé à $(Get-Date) - $($result.ProcessedCount) éléments traités"
    Add-Content -Path $logFile -Value $logMessage
}
