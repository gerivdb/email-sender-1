# Test script pour valider la structure modulaire
# Ce script contient intentionnellement des violations pour tester le validateur

function Create-TestFile {
    param([string]$Path)
    Write-Host "Creating test file at $Path"
}

function Generate-Report {
    param([string]$Data)
    Write-Host "Generating report with $Data"
}

function Process-Data {
    param([array]$Items)
    foreach ($item in $Items) {
        Write-Host "Processing $item"
    }
}

function Fix-Issues {
    param([string]$FilePath)
    Write-Host "Fixing issues in $FilePath"
}

function ValidFunction-Name {
    # Cette fonction a un nom valide
    Write-Host "This function has a valid name"
}

# Fonction avec nom invalide (ne suit pas le pattern Verb-Noun)
function invalidfunctionname {
    Write-Host "This function has an invalid name"
}

Export-ModuleMember -Function @(
    'Create-TestFile',
    'Generate-Report', 
    'Process-Data',
    'Fix-Issues',
    'ValidFunction-Name',
    'invalidfunctionname'
)
