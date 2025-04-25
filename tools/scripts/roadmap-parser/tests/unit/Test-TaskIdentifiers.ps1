# Test-TaskIdentifiers.ps1
# Script pour tester l'analyse des identifiants de tâches dans un fichier markdown de roadmap

param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapFilePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete_converted.md"
)

# Vérifier si le fichier existe
if (-not (Test-Path -Path $RoadmapFilePath)) {
    Write-Error "Le fichier '$RoadmapFilePath' n'existe pas."
    exit 1
}

# Lire le contenu du fichier
$content = Get-Content -Path $RoadmapFilePath -Encoding UTF8 -Raw

# Fonction pour analyser les identifiants de tâches
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

    # Détecter les identifiants de tâches
    $taskIdPatterns = @(
        # Format numérique (1.2.3)
        '(?m)^\s*[-*+]\s*(?:\*\*)?(\d+(\.\d+)+)(?:\*\*)?\s',
        # Format alphanumérique (A.1.2)
        '(?m)^\s*[-*+]\s*(?:\*\*)?([A-Za-z]+(\.\d+)+)(?:\*\*)?\s',
        # Format avec préfixe (TASK-123)
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

# Analyser les identifiants de tâches
Write-Host "Analyse des identifiants de tâches dans: $RoadmapFilePath" -ForegroundColor Cyan
$taskIdentifiers = Get-TaskIdentifiers -Content $content

# Afficher les résultats
Write-Host "`nIdentifiants de tâches détectés:" -ForegroundColor Green

if ($null -eq $taskIdentifiers.Pattern) {
    Write-Host "  Aucun format d'identifiant de tâche spécifique détecté."
} else {
    Write-Host "  Format détecté: $($taskIdentifiers.Pattern)"
    Write-Host "  Exemples:"
    foreach ($example in $taskIdentifiers.Examples) {
        Write-Host "    - $example"
    }
}

Write-Host "`nAnalyse terminée." -ForegroundColor Cyan
