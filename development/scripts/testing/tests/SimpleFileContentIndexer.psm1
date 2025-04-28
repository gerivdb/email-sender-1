# Module simplifiÃ© pour les tests

# Fonction pour crÃ©er un nouvel indexeur
function New-SimpleFileContentIndexer {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$IndexPath = "",
        
        [Parameter()]
        [bool]$PersistIndices = $false
    )
    
    return [PSCustomObject]@{
        IndexPath = $IndexPath
        PersistIndices = $PersistIndices
        FileIndices = @{}
        SymbolMap = @{}
    }
}

# Fonction pour indexer un fichier
function New-SimpleFileIndex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$Indexer,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "Le fichier n'existe pas: $FilePath"
        return $null
    }
    
    $index = [PSCustomObject]@{
        FilePath = $FilePath
        IndexedAt = Get-Date
        LineCount = (Get-Content -Path $FilePath).Count
        FileSize = (Get-Item -Path $FilePath).Length
    }
    
    $Indexer.FileIndices[$FilePath] = $index
    
    return $index
}

# Exporter les fonctions
Export-ModuleMember -Function New-SimpleFileContentIndexer, New-SimpleFileIndex
