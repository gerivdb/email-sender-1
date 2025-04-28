# Test-TaskIdentifiers.ps1
# Script pour tester l'analyse des identifiants de tÃ¢ches dans un fichier markdown de roadmap

param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapFilePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete_converted.md"
)

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $RoadmapFilePath)) {
    Write-Error "Le fichier '$RoadmapFilePath' n'existe pas."
    exit 1
}

# Lire le contenu du fichier
$content = Get-Content -Path $RoadmapFilePath -Encoding UTF8 -Raw

# Fonction pour analyser les identifiants de tÃ¢ches
function Get-TaskIdentifiers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $taskIdentifiers = @{
        Pattern = $null
        Examples = @()
    }

    # DÃ©tecter les identifiants de tÃ¢ches
    $taskIdPatterns = @(
        # Format numÃ©rique (1.2.3)
        '(?m)^\s*[-*+]\s*(?:\*\*)?(\d+(\.\d+)+)(?:\*\*)?\s',
        # Format alphanumÃ©rique (A.1.2)
        '(?m)^\s*[-*+]\s*(?:\*\*)?([A-Za-z]+(\.\d+)+)(?:\*\*)?\s',
        # Format avec prÃ©fixe (TASK-123)
        '(?m)^\s*[-*+]\s*(?:\*\*)?([A-Z]+-\d+)(?:\*\*)?\s'
    )

    foreach ($pattern in $taskIdPatterns) {
        $regexMatches = [regex]::Matches($Content, $pattern)
        if ($regexMatches -ne $null -and $regexMatches.Count -gt 0) {
            $taskIdentifiers.Pattern = $pattern
            $taskIdentifiers.Examples = $regexMatches | 
                                      Select-Object -First 5 | 
                                      ForEach-Object { $_.Groups[1].Value }
            break
        }
    }

    return $taskIdentifiers
}

# Analyser les identifiants de tÃ¢ches
Write-Host "Analyse des identifiants de tÃ¢ches dans: $RoadmapFilePath" -ForegroundColor Cyan
$taskIdentifiers = Get-TaskIdentifiers -Content $content

# Afficher les rÃ©sultats
Write-Host "`nIdentifiants de tÃ¢ches dÃ©tectÃ©s:" -ForegroundColor Green

if ($null -eq $taskIdentifiers.Pattern) {
    Write-Host "  Aucun format d'identifiant de tÃ¢che spÃ©cifique dÃ©tectÃ©."
} else {
    Write-Host "  Format dÃ©tectÃ©: $($taskIdentifiers.Pattern)"
    Write-Host "  Exemples:"
    foreach ($example in $taskIdentifiers.Examples) {
        Write-Host "    - $example"
    }
}

Write-Host "`nAnalyse terminÃ©e." -ForegroundColor Cyan
