# Configuration
$config = @{
    MaxItems = 100
    DefaultColor = "Blue"
    EnableLogging = $true
    LogPath = "C:\Logs\app.log"
}

# Variables dÃ©rivÃ©es
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
        
        # Variable non dÃ©finie
        if ($showProgress) {
            Write-Progress -Activity "Traitement" -Status "Traitement de l'Ã©lÃ©ment $i" -PercentComplete (($i / $count) * 100)
        }
    }
    
    # Variable dÃ©finie mais non utilisÃ©e
    $endTime = Get-Date
    
    return [PSCustomObject]@{
        ProcessedCount = $processedItems
        Items = $results
    }
}

# Utilisation de la fonction
$result = Process-Items -count 10
Write-Output "Nombre d'Ã©lÃ©ments traitÃ©s: $($result.ProcessedCount)"

# Ã‰criture du log
if ($config.EnableLogging) {
    $logMessage = "Traitement terminÃ© Ã  $(Get-Date) - $($result.ProcessedCount) Ã©lÃ©ments traitÃ©s"
    Add-Content -Path $logFile -Value $logMessage
}
